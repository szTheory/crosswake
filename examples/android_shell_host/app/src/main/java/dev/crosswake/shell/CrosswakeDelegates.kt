package dev.crosswake.shell

interface AppInfoDelegate {
    fun getAppInfo(): Map<String, String>
}

interface HapticsDelegate {
    fun impact(style: String)
}

interface PermissionStatusDelegate {
    fun getStatus(alias: String): Map<String, String>?
}

interface NotificationTokenDelegate {
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

    fun fetch(): Result
}

interface ShareDelegate {
    fun invoke(payload: Map<String, String>)
}

interface FilesPickDelegate {
    fun pick(payload: Map<String, String>, correlationId: String): FilesPickResult
}
