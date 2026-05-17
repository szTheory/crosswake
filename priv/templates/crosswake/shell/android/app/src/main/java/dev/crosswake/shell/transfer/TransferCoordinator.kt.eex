package dev.crosswake.shell.transfer

import dev.crosswake.shell.ShellManifest

class TransferCoordinator(
    private val routeId: String,
    private val declaredTransfers: List<ShellManifest.TransferSeam>
) {
    enum class TransferCommand(val wireValue: String) {
        TRANSFER_IMPORT("transfer.import"),
        TRANSFER_EXPORT("transfer.export"),
        TRANSFER_DOWNLOAD("transfer.download"),
        TRANSFER_UPLOAD_PREPARE("transfer.upload.prepare");

        companion object {
            fun fromWireValue(value: String): TransferCommand? = entries.find { it.wireValue == value }
        }
    }

    enum class TransferState(val wireValue: String) {
        QUEUED("queued"),
        PREPARING("preparing"),
        TRANSFERRING("transferring"),
        AWAITING_NETWORK("awaiting_network"),
        VERIFYING("verifying"),
        COMPLETE("complete"),
        FAILED("failed"),
        CANCELED("canceled")
    }

    data class TransferRecord(
        val routeId: String,
        val transferId: String,
        val command: TransferCommand,
        val intent: String,
        val source: String?,
        val destination: String?,
        val state: TransferState,
        val detail: String,
        val stagedPath: String?
    )

    private val transfers = mutableMapOf<String, TransferRecord>()

    fun execute(command: String, payload: Map<String, String>, correlationId: String): Map<String, String>? {
        val transferCommand = TransferCommand.fromWireValue(command) ?: return null
        val transferId = payload["transfer_id"] ?: return null
        val seam = declaredTransfer(transferId, transferCommand) ?: return null

        val record = transition(transferId, transferCommand, seam, payload["staged_path"], correlationId)
        transfers[transferId] = record

        return mapOf(
            "route_id" to routeId,
            "transfer_id" to transferId,
            "state" to record.state.wireValue,
            "intent" to seam.intent,
            "detail" to record.detail,
            "correlation_id" to correlationId
        )
    }

    fun stageCapturedMedia(
        transferId: String,
        localPath: String,
        mediaType: String,
        bytes: Long
    ): Map<String, String>? {
        val seam = declaredTransfers.firstOrNull {
            it.id == transferId && it.intent == "upload" && it.source == "native_capture"
        } ?: return null

        val record = TransferRecord(
            routeId = routeId,
            transferId = transferId,
            command = TransferCommand.TRANSFER_UPLOAD_PREPARE,
            intent = seam.intent,
            source = seam.source,
            destination = seam.destination,
            state = TransferState.QUEUED,
            detail = "Captured locally. Transfer handoff stays explicit until the route starts upload preparation.",
            stagedPath = localPath
        )

        transfers[transferId] = record

        return mapOf(
            "route_id" to routeId,
            "transfer_id" to transferId,
            "state" to record.state.wireValue,
            "intent" to seam.intent,
            "staged_path" to localPath,
            "media_type" to mediaType,
            "bytes" to bytes.toString()
        )
    }

    private fun declaredTransfer(id: String, command: TransferCommand): ShellManifest.TransferSeam? {
        return declaredTransfers.firstOrNull { seam ->
            seam.id == id && commandMatchesIntent(command, seam.intent)
        }
    }

    private fun commandMatchesIntent(command: TransferCommand, intent: String): Boolean {
        return when (command to intent) {
            TransferCommand.TRANSFER_IMPORT to "import",
            TransferCommand.TRANSFER_EXPORT to "export",
            TransferCommand.TRANSFER_DOWNLOAD to "download",
            TransferCommand.TRANSFER_UPLOAD_PREPARE to "upload" -> true
            else -> false
        }
    }

    private fun transition(
        transferId: String,
        command: TransferCommand,
        seam: ShellManifest.TransferSeam,
        stagedPath: String?,
        correlationId: String
    ): TransferRecord {
        val state: TransferState
        val detail: String

        when (command) {
            TransferCommand.TRANSFER_UPLOAD_PREPARE -> {
                state = if (stagedPath == null) TransferState.FAILED else TransferState.PREPARING
                detail =
                    if (stagedPath == null) {
                        "Upload preparation requires an explicitly staged local media file."
                    } else {
                        "Upload preparation acknowledged for staged media. Foreground transfer remains route-local."
                    }
            }
            TransferCommand.TRANSFER_IMPORT -> {
                state = TransferState.PREPARING
                detail = "Import preparation acknowledged. Route-local transfer remains explicit."
            }
            TransferCommand.TRANSFER_EXPORT -> {
                state = TransferState.QUEUED
                detail = "Export request queued for the active route only."
            }
            TransferCommand.TRANSFER_DOWNLOAD -> {
                state = TransferState.TRANSFERRING
                detail = "Download started in the foreground for the active route only."
            }
        }

        return TransferRecord(
            routeId = routeId,
            transferId = transferId,
            command = command,
            intent = seam.intent,
            source = seam.source,
            destination = seam.destination,
            state = state,
            detail = "$detail [$correlationId]",
            stagedPath = stagedPath
        )
    }
}
