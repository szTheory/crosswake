package dev.crosswake.shell

import android.content.Context

class NotificationTokenProvider(
    private val resolver: () -> Result
) {
    sealed class Result {
        data class Available(
            val provider: String,
            val token: String,
            val notificationStatus: String,
            val detail: Map<String, String> = emptyMap()
        ) : Result() {
            fun payload(): Map<String, String> {
                val payload = linkedMapOf(
                    "provider" to provider,
                    "token" to token,
                    "notification_status" to notificationStatus
                )

                detail.forEach { (key, value) ->
                    payload["detail.$key"] = value
                }

                return payload
            }
        }

        data class Denied(
            val reason: String,
            val message: String,
            val hint: String
        ) : Result()
    }

    constructor(context: Context) : this(
        resolver = {
            val permissionSnapshot = PermissionStatusProvider(context).statusPayload("notifications")
            val notificationStatus = permissionSnapshot?.get("status")

            when {
                notificationStatus == null -> {
                    Result.Denied(
                        reason = "unavailable_capability",
                        message = "The Android shell could not resolve notification authorization state for notification_token.",
                        hint = "Check permissions.status for notifications before retrying notification_token."
                    )
                }

                notificationStatus != "granted" -> {
                    Result.Denied(
                        reason = "unavailable_capability",
                        message = "Notification authorization is not granted for the configured token provider snapshot.",
                        hint = "Check permissions.status for notifications before retrying notification_token."
                    )
                }

                else -> {
                    Result.Denied(
                        reason = "unavailable_capability",
                        message = "The Android shell has no configured push-token provider for notification_token.",
                        hint = "Install and configure a provider-backed token seam before retrying."
                    )
                }
            }
        }
    )

    fun fetch(): Result = resolver()
}
