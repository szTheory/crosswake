package dev.crosswake.shell

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import dev.crosswake.shell.transfer.TransferCoordinator
import java.io.File
import java.util.UUID

sealed class FilesPickResult {
    data class Immediate(val payload: Map<String, String>) : FilesPickResult()

    data class Denied(
        val reason: String,
        val message: String,
        val hint: String
    ) : FilesPickResult()

    class Deferred(
        private val starter: (
            onSuccess: (Map<String, String>) -> Unit,
            onDenied: (Denied) -> Unit
        ) -> Unit
    ) : FilesPickResult() {
        fun dispatch(
            onSuccess: (Map<String, String>) -> Unit,
            onDenied: (Denied) -> Unit
        ) {
            starter(onSuccess, onDenied)
        }
    }
}

class FilePickerCoordinator(
    private val context: Context,
    private val transferCoordinator: TransferCoordinator,
    private val launchPicker: (Intent) -> Unit
) {
    private data class PendingPick(
        val transferId: String,
        val correlationId: String?,
        val onSuccess: (Map<String, String>) -> Unit,
        val onDenied: (FilesPickResult.Denied) -> Unit
    )

    private var pendingPick: PendingPick? = null

    fun pick(payload: Map<String, String>, correlationId: String? = null): FilesPickResult {
        val transferId = payload["transfer_id"]
            ?: return FilesPickResult.Denied(
                reason = "undeclared_capability",
                message = "This route does not declare the requested transfer seam.",
                hint = "Retry only with the active route's manifest-declared transfer command and transfer_id."
            )

        val seam = transferCoordinator.declaredNativePickerTransfer(transferId)
            ?: return FilesPickResult.Denied(
                reason = "undeclared_capability",
                message = "This route does not declare an inbound native_picker transfer seam for files.pick.",
                hint = "Bind files.pick to a manifest-declared native_picker transfer_id before retrying."
            )

        if (pendingPick != null) {
            return FilesPickResult.Denied(
                reason = "unavailable_capability",
                message = "A native_picker transfer is already waiting for completion on this route.",
                hint = "Finish or cancel the active files.pick request before starting another one."
            )
        }

        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = primaryMimeType(seam.mediaTypes)
            val mediaTypes = seam.mediaTypes.filter { it != "*/*" }
            if (mediaTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, mediaTypes.toTypedArray())
            }

            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, payload["multiple_allowed"] == "true")
        }

        return FilesPickResult.Deferred { onSuccess, onDenied ->
            pendingPick = PendingPick(
                transferId = transferId,
                correlationId = correlationId,
                onSuccess = onSuccess,
                onDenied = onDenied
            )
            launchPicker(intent)
        }
    }

    fun consumeResult(resultCode: Int, data: Intent?) {
        val pending = pendingPick ?: return
        pendingPick = null

        if (resultCode != Activity.RESULT_OK) {
            val payload = transferCoordinator.cancelPickedFiles(pending.transferId)
                ?: mapOf(
                    "status" to "canceled",
                    "transfer_id" to pending.transferId,
                    "detail.reason" to "user_canceled"
                )
            pending.onSuccess(payload)
            return
        }

        val uris = extractUris(data)
        if (uris.isEmpty()) {
            pending.onDenied(
                FilesPickResult.Denied(
                    reason = "unavailable_capability",
                    message = "files.pick returned without any staged content.",
                    hint = "Retry the picker and select a supported document."
                )
            )
            return
        }

        val stagedItems = runCatching {
            uris.mapIndexed { index, uri ->
                stageUri(pending.transferId, index, uri)
            }
        }.getOrElse { error ->
            pending.onDenied(
                FilesPickResult.Denied(
                    reason = "unavailable_capability",
                    message = "The Android shell could not stage the selected document for transfer.",
                    hint = error.message ?: "Retry with a provider that allows temporary read access."
                )
            )
            return
        }

        val payload = transferCoordinator.stagePickedFiles(
            transferId = pending.transferId,
            items = stagedItems,
            correlationId = pending.correlationId ?: pending.transferId
        ) ?: mapOf(
            "status" to "ok",
            "transfer_id" to pending.transferId
        )

        pending.onSuccess(payload)
    }

    private fun extractUris(data: Intent?): List<Uri> {
        val clipData = data?.clipData
        if (clipData != null && clipData.itemCount > 0) {
            return List(clipData.itemCount) { index -> clipData.getItemAt(index).uri }
        }

        return listOfNotNull(data?.data)
    }

    private fun primaryMimeType(mediaTypes: List<String>): String {
        return when {
            mediaTypes.isEmpty() -> "*/*"
            mediaTypes.size == 1 -> mediaTypes.first()
            else -> {
                val topLevel = mediaTypes.mapNotNull { it.substringBefore('/', missingDelimiterValue = "").ifBlank { null } }
                    .distinct()
                if (topLevel.size == 1) "${topLevel.first()}/*" else "*/*"
            }
        }
    }

    private fun stageUri(
        transferId: String,
        index: Int,
        uri: Uri
    ): TransferCoordinator.StagedPickerItem {
        val contentResolver = context.contentResolver
        val metadata = queryMetadata(uri)
        val name = metadata.name ?: "picked-$index"
        val stageDir = File(context.cacheDir, "crosswake/native_picker/$transferId").apply { mkdirs() }
        val fileName = "${UUID.randomUUID()}-${name.replace('/', '_')}"
        val stagedFile = File(stageDir, fileName)

        contentResolver.openInputStream(uri)?.use { input ->
            stagedFile.outputStream().use { output ->
                input.copyTo(output)
            }
        } ?: error("The selected document provider did not expose a readable stream.")

        val sizeBytes = stagedFile.length().takeIf { it > 0L } ?: metadata.sizeBytes

        return TransferCoordinator.StagedPickerItem(
            handle = "staged://$transferId/${stagedFile.name}",
            localPath = stagedFile.absolutePath,
            name = metadata.name,
            mimeType = contentResolver.getType(uri),
            sizeBytes = sizeBytes,
            nativeType = uri.scheme
        )
    }

    private fun queryMetadata(uri: Uri): PickedMetadata {
        val cursor = context.contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null
        ) ?: return PickedMetadata()

        cursor.use {
            if (!it.moveToFirst()) {
                return PickedMetadata()
            }

            val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            val sizeIndex = it.getColumnIndex(OpenableColumns.SIZE)

            return PickedMetadata(
                name = nameIndex.takeIf { column -> column >= 0 }?.let(it::getString),
                sizeBytes = sizeIndex.takeIf { column -> column >= 0 && !it.isNull(column) }?.let { column ->
                    it.getLong(column)
                }
            )
        }
    }

    private data class PickedMetadata(
        val name: String? = null,
        val sizeBytes: Long? = null
    )
}
