package dev.crosswake.shell

import dev.crosswake.shell.transfer.TransferCoordinator
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test

class BridgeChannelTest {
    @Test
    fun permissionsStatusReturnsNormalizedNotificationsPayload() {
        val channel = bridgeChannel(
            permissionStatusProvider = PermissionStatusProvider { permissionAlias ->
                if (permissionAlias != "notifications") {
                    null
                } else {
                    mapOf(
                        "alias" to "notifications",
                        "status" to "granted",
                        "detail.notifications_enabled" to "true"
                    )
                }
            }
        )

        val reply = evaluate(
            channel,
            request(
                command = "permissions.status",
                capability = "permissions.status",
                payload = mapOf("alias" to "notifications"),
                capabilities = mapOf("permissions.status" to "1.0.0")
            )
        )

        assertEquals("ok", reply.getString("status"))
        assertEquals("notifications", reply.payload().getString("alias"))
        assertEquals("granted", reply.payload().getString("status"))
    }

    @Test
    fun permissionsStatusRejectsUnsupportedAliases() {
        val channel = bridgeChannel(
            permissionStatusProvider = PermissionStatusProvider { permissionAlias ->
                if (permissionAlias == "notifications") {
                    mapOf("alias" to "notifications", "status" to "denied")
                } else {
                    null
                }
            }
        )

        val reply = evaluate(
            channel,
            request(
                command = "permissions.status",
                capability = "permissions.status",
                payload = mapOf("alias" to "camera"),
                capabilities = mapOf("permissions.status" to "1.0.0")
            )
        )

        assertEquals("deny", reply.getString("status"))
        assertEquals("unavailable_capability", reply.denialReason())
    }

    @Test
    fun notificationTokenReturnsProviderTaggedEvidenceOnlyPayload() {
        val channel = bridgeChannel(
            notificationTokenProvider = NotificationTokenProvider {
                NotificationTokenProvider.Result.Available(
                    provider = "fcm",
                    token = "fcm-token-123",
                    notificationStatus = "granted",
                    detail = mapOf("snapshot" to "cached")
                )
            }
        )

        val reply = evaluate(
            channel,
            request(
                command = "notifications.token.get",
                capability = "notification_token",
                capabilities = mapOf("notification_token" to "1.0.0")
            )
        )

        assertEquals("ok", reply.getString("status"))
        assertEquals("fcm", reply.payload().getString("provider"))
        assertEquals("fcm-token-123", reply.payload().getString("token"))
        assertEquals("granted", reply.payload().getString("notification_status"))
        assertEquals("cached", reply.payload().getString("detail.snapshot"))
    }

    @Test
    fun notificationTokenDeniesWhenProviderOrAuthorizationPrerequisitesAreMissing() {
        val providerMissingReply = evaluate(
            bridgeChannel(
                notificationTokenProvider = NotificationTokenProvider {
                    NotificationTokenProvider.Result.Denied(
                        reason = "unavailable_capability",
                        message = "The Android shell has no configured push-token provider for notification_token.",
                        hint = "Install and configure a provider-backed token seam before retrying."
                    )
                }
            ),
            request(
                command = "notifications.token.get",
                capability = "notification_token",
                capabilities = mapOf("notification_token" to "1.0.0"),
                correlationId = "notif-provider-missing"
            )
        )

        assertEquals("deny", providerMissingReply.getString("status"))
        assertEquals("unavailable_capability", providerMissingReply.denialReason())

        val authorizationMissingReply = evaluate(
            bridgeChannel(
                notificationTokenProvider = NotificationTokenProvider {
                    NotificationTokenProvider.Result.Denied(
                        reason = "unavailable_capability",
                        message = "Notification authorization is not granted for the configured token provider snapshot.",
                        hint = "Check permissions.status for notifications before retrying notification_token."
                    )
                }
            ),
            request(
                command = "notifications.token.get",
                capability = "notification_token",
                capabilities = mapOf("notification_token" to "1.0.0"),
                correlationId = "notif-auth-missing"
            )
        )

        assertEquals("deny", authorizationMissingReply.getString("status"))
        assertEquals("unavailable_capability", authorizationMissingReply.denialReason())
    }

    @Test
    fun filesPickReturnsTransferBoundItems() {
        val channel = bridgeChannel(
            filesPickHandler = { payload ->
                mapOf(
                    "status" to "ok",
                    "transfer_id" to (payload["transfer_id"] ?: ""),
                    "items.0.handle" to "staged://lesson_import/asset-1",
                    "items.0.name" to "lesson.pdf",
                    "items.0.mime_type" to "application/pdf",
                    "items.0.size_bytes" to "2048"
                )
            }
        )

        val reply = evaluate(
            channel,
            request(
                command = "files.pick",
                capability = "file_picker",
                payload = mapOf("transfer_id" to "lesson_import"),
                capabilities = mapOf("file_picker" to "1.0.0")
            )
        )

        assertEquals("ok", reply.getString("status"))
        assertEquals("ok", reply.payload().getString("status"))
        assertEquals("lesson_import", reply.payload().getString("transfer_id"))
        assertEquals("staged://lesson_import/asset-1", reply.payload().getString("items.0.handle"))
        assertEquals("application/pdf", reply.payload().getString("items.0.mime_type"))
    }

    @Test
    fun filesPickPreservesTypedCancellationOutcome() {
        val channel = bridgeChannel(
            filesPickHandler = { payload ->
                mapOf(
                    "status" to "canceled",
                    "transfer_id" to (payload["transfer_id"] ?: ""),
                    "detail.reason" to "user_canceled"
                )
            }
        )

        val reply = evaluate(
            channel,
            request(
                command = "files.pick",
                capability = "file_picker",
                payload = mapOf("transfer_id" to "lesson_import"),
                capabilities = mapOf("file_picker" to "1.0.0"),
                correlationId = "pick-cancel"
            )
        )

        assertEquals("ok", reply.getString("status"))
        assertEquals("canceled", reply.payload().getString("status"))
        assertEquals("lesson_import", reply.payload().getString("transfer_id"))
        assertEquals("user_canceled", reply.payload().getString("detail.reason"))
    }

    private fun bridgeChannel(
        permissionStatusProvider: PermissionStatusProvider = PermissionStatusProvider { _ -> null },
        notificationTokenProvider: NotificationTokenProvider = NotificationTokenProvider {
            NotificationTokenProvider.Result.Denied(
                reason = "unavailable_capability",
                message = "The Android shell has no configured push-token provider for notification_token.",
                hint = "Install and configure a provider-backed token seam before retrying."
            )
        },
        filesPickHandler: (Map<String, String>) -> Map<String, String> = { payload -> payload },
        declaredTransfers: List<ShellManifest.TransferSeam> = listOf(
            ShellManifest.TransferSeam(
                id = "lesson_import",
                intent = "import",
                direction = "inbound",
                source = "native_picker",
                destination = null,
                verification = "required",
                mediaTypes = listOf("application/pdf"),
                states = listOf("queued", "preparing", "verifying", "complete", "failed", "canceled")
            )
        )
    ): BridgeChannel {
        return BridgeChannel(
            session = session(declaredTransfers = declaredTransfers),
            transferCoordinator = TransferCoordinator(
                routeId = "dashboard",
                declaredTransfers = declaredTransfers
            ),
            appInfoProvider = { emptyMap() },
            hapticsHandler = { _ -> },
            permissionStatusProvider = permissionStatusProvider::statusPayload,
            shareHandler = { _ -> },
            filesPickHandler = filesPickHandler
        )
    }

    private fun request(
        command: String,
        capability: String,
        payload: Map<String, String> = emptyMap(),
        capabilities: Map<String, String>,
        correlationId: String = "bridge-1"
    ): BridgeRequestEnvelope {
        return BridgeRequestEnvelope(
            protocol = BridgeChannel.PROTOCOL,
            version = "1.0.0",
            command = command,
            capability = capability,
            routeId = "dashboard",
            activeRouteId = "dashboard",
            origin = "https://example.crosswake.invalid",
            nativeRuntimeVersion = "1.0.0",
            correlationId = correlationId,
            capabilities = capabilities,
            installedPacks = emptyMap(),
            payload = payload
        )
    }

    private fun session(declaredTransfers: List<ShellManifest.TransferSeam>): LiveViewSession {
        return LiveViewSession(
            routeId = "dashboard",
            url = "https://example.crosswake.invalid/dashboard",
            allowedOrigin = "https://example.crosswake.invalid",
            bridgeProtocolVersion = "1.0.0",
            nativeRuntimeVersion = "1.0.0",
            installedPacks = emptyMap(),
            routeRequiredPacks = emptyList(),
            capabilities = mapOf(
                "permissions.status" to "1.0.0",
                "notification_token" to "1.0.0",
                "file_picker" to "1.0.0"
            ),
            declaredTransfers = declaredTransfers
        )
    }

    private fun evaluate(channel: BridgeChannel, request: BridgeRequestEnvelope): JSONObject {
        return JSONObject(channel.evaluateForTesting(request))
    }

    private fun JSONObject.payload(): JSONObject = getJSONObject("payload")

    private fun JSONObject.denialReason(): String {
        return getJSONObject("denial").getJSONObject("denial").getString("reason")
    }
}
