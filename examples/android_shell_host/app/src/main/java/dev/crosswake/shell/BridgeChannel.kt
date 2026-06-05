package dev.crosswake.shell

import android.webkit.WebView
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import dev.crosswake.shell.transfer.TransferCoordinator
import org.json.JSONObject

enum class BridgeCommand(val wireValue: String) {
    APP_INFO_GET("app.info.get"),
    HAPTICS_IMPACT("haptics.impact"),
    PERMISSIONS_STATUS("permissions.status"),
    NOTIFICATIONS_TOKEN_GET("notifications.token.get"),
    SHARE_INVOKE("share.invoke"),
    FILES_PICK("files.pick"),
    TRANSFER_IMPORT("transfer.import"),
    TRANSFER_EXPORT("transfer.export"),
    TRANSFER_DOWNLOAD("transfer.download"),
    TRANSFER_UPLOAD_PREPARE("transfer.upload.prepare");

    val capability: String
        get() = when (this) {
            NOTIFICATIONS_TOKEN_GET -> "notification_token"
            FILES_PICK -> "file_picker"
            else -> wireValue
        }

    val isTransferCommand: Boolean
        get() = when (this) {
            TRANSFER_IMPORT, TRANSFER_EXPORT, TRANSFER_DOWNLOAD, TRANSFER_UPLOAD_PREPARE -> true
            else -> false
        }

    companion object {
        fun fromWireValue(value: String): BridgeCommand? = entries.find { it.wireValue == value }
    }
}

class BridgeChannel(
    private var session: LiveViewSession,
    private val transferCoordinator: TransferCoordinator?,
    private val config: CrosswakeShellConfig
) {
    companion object {
        const val JS_OBJECT = "crosswakeBridge"
        const val PROTOCOL = "crosswake.bridge"
    }

    fun update(session: LiveViewSession) {
        this.session = session
    }

    fun attach(webView: WebView, allowedOriginRules: Set<String>) {
        WebViewCompat.addWebMessageListener(
            webView,
            JS_OBJECT,
            allowedOriginRules
        ) { _, message, sourceOrigin, isMainFrame, replyProxy ->
            val request = parseRequest(message) ?: return@addWebMessageListener

            if (!isMainFrame || sourceOrigin.toString() != session.allowedOrigin) {
                replyProxy.postMessage(
                    deny(
                        request,
                        "origin_denied",
                        "The bridge request origin is not allowlisted for the active route.",
                        "Retry from the declared same-origin route surface."
                    )
                )
                return@addWebMessageListener
            }

            val reply = evaluate(request) { deferredReply ->
                replyProxy.postMessage(deferredReply)
            }
            if (reply != null) {
                replyProxy.postMessage(reply)
            }
        }
    }

    private fun parseRequest(message: WebMessageCompat): BridgeRequestEnvelope? {
        val body = message.data ?: return null
        return try {
            BridgeRequestEnvelope(JSONObject(body))
        } catch (_: Exception) {
            null
        }
    }

    private fun evaluate(
        request: BridgeRequestEnvelope,
        deferredReply: ((String) -> Unit)? = null
    ): String? {
        if (request.protocol != PROTOCOL || request.version != session.bridgeProtocolVersion || request.nativeRuntimeVersion != session.nativeRuntimeVersion) {
            return deny(request, "compatibility_mismatch", "Bridge protocol or runtime mismatch.", "Update the shell before retrying this bridge request.")
        }

        if (request.routeId != session.routeId || request.activeRouteId != session.routeId) {
            return deny(request, "inactive_route", "The bridge request is not scoped to the active route.", "Retry from the current active route only.")
        }

        if (request.origin != session.allowedOrigin) {
            return deny(request, "origin_denied", "The bridge request origin is not allowlisted for the active route.", "Retry from the declared same-origin route surface.")
        }

        val command = BridgeCommand.fromWireValue(request.command)
            ?: return deny(
                request,
                "undeclared_capability",
                "The bridge command is outside the bounded transfer contract.",
                "Use app.info.get, haptics.impact, permissions.status, notifications.token.get, share.invoke, files.pick, transfer.import, transfer.export, transfer.download, or transfer.upload.prepare only."
            )

        if (request.capability != command.capability) {
            return deny(request, "undeclared_capability", "The bridge envelope capability does not match the bounded command.", "Align the bridge envelope capability with manifest truth.")
        }

        val packsCompatible = session.routeRequiredPacks.all { packRequirement ->
            val parts = packRequirement.split("@", limit = 2)
            val packId = parts[0]
            val requiredVersion = parts.getOrNull(1)
            val installedVersion = session.installedPacks[packId]
            if (requiredVersion == null) installedVersion != null else installedVersion == requiredVersion
        }

        if (!packsCompatible) {
            return deny(request, "pack_incompatible", "The active route is missing a compatible declared pack.", "Install or update the required pack before retrying.")
        }

        return when (command) {
            BridgeCommand.APP_INFO_GET -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val delegate = config.appInfoDelegate
                    if (delegate == null) {
                        deny(request, "unavailable_capability", "The host has not configured the AppInfo capability.", "Configure AppInfoDelegate in CrosswakeShellConfig.")
                    } else {
                        ok(request, delegate.getAppInfo())
                    }
                }
            }

            BridgeCommand.HAPTICS_IMPACT -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val delegate = config.hapticsDelegate
                    if (delegate == null) {
                        deny(request, "unavailable_capability", "The host has not configured the Haptics capability.", "Configure HapticsDelegate in CrosswakeShellConfig.")
                    } else {
                        val style = request.payload["style"] ?: "medium"
                        delegate.impact(style)
                        ok(request, mapOf("style" to style))
                    }
                }
            }

            BridgeCommand.PERMISSIONS_STATUS -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val delegate = config.permissionStatusDelegate
                    if (delegate == null) {
                        return deny(request, "unavailable_capability", "The host has not configured the PermissionStatus capability.", "Configure PermissionStatusDelegate in CrosswakeShellConfig.")
                    }
                    val permissionAlias = request.payload["alias"]
                    val payload =
                        permissionAlias?.let { delegate.getStatus(it) }
                            ?: return deny(
                                request,
                                "unavailable_capability",
                                "The requested permission alias is outside the shipped read-only permissions.status scope.",
                                "Use the notifications alias only."
                            )

                    ok(request, payload)
                }
            }

            BridgeCommand.NOTIFICATIONS_TOKEN_GET -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val delegate = config.notificationTokenDelegate
                    if (delegate == null) {
                        deny(request, "unavailable_capability", "The host has not configured the NotificationToken capability.", "Configure NotificationTokenDelegate in CrosswakeShellConfig.")
                    } else {
                        when (val result = delegate.fetch()) {
                            is NotificationTokenDelegate.Result.Available -> ok(request, result.payload())
                            is NotificationTokenDelegate.Result.Denied ->
                                deny(request, result.reason, result.message, result.hint)
                        }
                    }
                }
            }

            BridgeCommand.SHARE_INVOKE -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val delegate = config.shareDelegate
                    if (delegate == null) {
                        deny(request, "unavailable_capability", "The host has not configured the Share capability.", "Configure ShareDelegate in CrosswakeShellConfig.")
                    } else {
                        delegate.invoke(request.payload)
                        ok(request, emptyMap())
                    }
                }
            }

            BridgeCommand.FILES_PICK -> {
                val requiredCapabilityVersion = session.capabilities[command.capability]
                if (requiredCapabilityVersion == null || request.capabilities[command.capability] != requiredCapabilityVersion) {
                    deny(request, "unavailable_capability", "The requested capability is not available at the manifest-backed version.", "Ship the declared capability version before retrying.")
                } else {
                    val delegate = config.filesPickDelegate
                    if (delegate == null) {
                        deny(request, "unavailable_capability", "The host has not configured the FilesPick capability.", "Configure FilesPickDelegate in CrosswakeShellConfig.")
                    } else {
                        when (val result = delegate.pick(request.payload, request.correlationId)) {
                            is FilesPickResult.Immediate -> ok(request, result.payload)
                            is FilesPickResult.Denied -> deny(request, result.reason, result.message, result.hint)
                            is FilesPickResult.Deferred -> {
                                val sink =
                                    deferredReply
                                        ?: return deny(
                                            request,
                                            "unavailable_capability",
                                            "The Android shell cannot complete files.pick without an activity-backed result channel.",
                                            "Retry from the mounted shell activity so the picker can return a staged handle reply."
                                        )

                                result.dispatch(
                                    onSuccess = { payload -> sink(ok(request, payload)) },
                                    onDenied = { denial ->
                                        sink(deny(request, denial.reason, denial.message, denial.hint))
                                    }
                                )
                                null
                            }
                        }
                    }
                }
            }

            BridgeCommand.TRANSFER_IMPORT,
            BridgeCommand.TRANSFER_EXPORT,
            BridgeCommand.TRANSFER_DOWNLOAD,
            BridgeCommand.TRANSFER_UPLOAD_PREPARE -> {
                val payload = transferCoordinator?.execute(command.wireValue, request.payload, request.correlationId)
                    ?: return deny(
                        request,
                        "undeclared_capability",
                        "This route does not declare the requested transfer seam.",
                        "Retry only with the active route's manifest-declared transfer command and transfer_id."
                    )

                ok(request, payload)
            }
        }
    }

    fun evaluateForTesting(request: BridgeRequestEnvelope): String {
        return evaluate(request)
            ?: error("Deferred bridge replies are not supported by evaluateForTesting.")
    }

    private fun ok(request: BridgeRequestEnvelope, payload: Map<String, String>): String {
        return JSONObject()
            .put("protocol", request.protocol)
            .put("version", request.version)
            .put("command", request.command)
            .put("route_id", request.routeId)
            .put("correlation_id", request.correlationId)
            .put("status", "ok")
            .put("payload", JSONObject(payload))
            .toString()
    }

    private fun deny(request: BridgeRequestEnvelope, reason: String, message: String, hint: String): String {
        return JSONObject()
            .put("protocol", request.protocol)
            .put("version", request.version)
            .put("command", request.command)
            .put("route_id", request.routeId)
            .put("correlation_id", request.correlationId)
            .put("status", "deny")
            .put("payload", JSONObject())
            .put(
                "denial",
                JSONObject()
                    .put("command", request.command)
                    .put("route_id", request.routeId)
                    .put("correlation_id", request.correlationId)
                    .put(
                        "denial",
                        JSONObject()
                            .put("reason", reason)
                            .put("code", reason)
                            .put("message", message)
                            .put("route_id", request.routeId)
                            .put("hint", hint)
                    )
            )
            .toString()
    }
}

data class BridgeRequestEnvelope(
    val protocol: String,
    val version: String,
    val command: String,
    val capability: String,
    val routeId: String,
    val activeRouteId: String,
    val origin: String,
    val nativeRuntimeVersion: String,
    val correlationId: String,
    val capabilities: Map<String, String>,
    val installedPacks: Map<String, String>,
    val payload: Map<String, String>
) {
    constructor(json: JSONObject) : this(
        protocol = json.getString("protocol"),
        version = json.getString("version"),
        command = json.getString("command"),
        capability = json.getString("capability"),
        routeId = json.getString("route_id"),
        activeRouteId = json.getString("active_route_id"),
        origin = json.getString("origin"),
        nativeRuntimeVersion = json.getString("native_runtime_version"),
        correlationId = json.getString("correlation_id"),
        capabilities = json.optJSONObject("capabilities").toStringMap(),
        installedPacks = json.optJSONObject("installed_packs").toStringMap(),
        payload = json.optJSONObject("payload").toStringMap()
    )
}

private fun JSONObject?.toStringMap(): Map<String, String> {
    val objectValue = this ?: return emptyMap()
    val keys = objectValue.keys()
    val map = mutableMapOf<String, String>()

    while (keys.hasNext()) {
        val key = keys.next()
        map[key] = objectValue.optString(key)
    }

    return map
}
