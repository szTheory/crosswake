package dev.crosswake.shell

import android.content.Context

class NotificationTokenProvider(
    private val resolver: () -> NotificationTokenDelegate.Result
) {
    constructor(context: Context) : this(
        resolver = {
            val permissionSnapshot = PermissionStatusProvider(context).statusPayload("notifications")
            val notificationStatus = permissionSnapshot?.get("status")

            when {
                notificationStatus == null -> {
                    NotificationTokenDelegate.Result.Denied(
                        reason = "unavailable_capability",
                        message = "The Android shell could not resolve notification authorization state for notification_token.",
                        hint = "Check permissions.status for notifications before retrying notification_token."
                    )
                }

                notificationStatus != "granted" -> {
                    NotificationTokenDelegate.Result.Denied(
                        reason = "unavailable_capability",
                        message = "Notification authorization is not granted for the configured token provider snapshot.",
                        hint = "Check permissions.status for notifications before retrying notification_token."
                    )
                }

                else -> {
                    NotificationTokenDelegate.Result.Denied(
                        reason = "unavailable_capability",
                        message = "The Android shell has no configured push-token provider for notification_token.",
                        hint = "Install and configure a provider-backed token seam before retrying."
                    )
                }
            }
        }
    )

    fun fetch(): NotificationTokenDelegate.Result = resolver()
}
