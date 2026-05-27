package dev.crosswake.shell

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

class PermissionStatusProvider(
    private val resolver: (String) -> Map<String, String>?
) {
    constructor(context: Context) : this(
        resolver = { permissionAlias ->
            if (permissionAlias != "notifications") {
                null
            } else {
                val notificationsEnabled = NotificationManagerCompat.from(context).areNotificationsEnabled()
                val payload = mutableMapOf(
                    "alias" to "notifications",
                    "status" to if (notificationsEnabled) "granted" else "denied",
                    "detail.notifications_enabled" to notificationsEnabled.toString()
                )

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val status =
                        if (
                            ContextCompat.checkSelfPermission(
                                context,
                                Manifest.permission.POST_NOTIFICATIONS
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            "granted"
                        } else {
                            "denied"
                        }

                    payload["detail.post_notifications_permission"] = status
                }

                payload
            }
        }
    )

    fun statusPayload(permissionAlias: String): Map<String, String>? = resolver(permissionAlias)
}
