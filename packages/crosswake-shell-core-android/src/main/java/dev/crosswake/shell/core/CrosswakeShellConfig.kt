package dev.crosswake.shell.core

data class CrosswakeShellConfig(
    val appInfoDelegate: AppInfoDelegate? = null,
    val hapticsDelegate: HapticsDelegate? = null,
    val permissionStatusDelegate: PermissionStatusDelegate? = null,
    val notificationTokenDelegate: NotificationTokenDelegate? = null,
    val shareDelegate: ShareDelegate? = null,
    val filesPickDelegate: FilesPickDelegate? = null,
    val routeDelegate: RouteDelegate? = null
) {
    val registeredCapabilities: List<String>
        get() {
            val caps = mutableListOf<String>()
            if (appInfoDelegate != null) caps.add("app.info.get")
            if (hapticsDelegate != null) caps.add("haptics.impact")
            if (permissionStatusDelegate != null) caps.add("permissions.status")
            if (notificationTokenDelegate != null) caps.add("notification_token")
            if (shareDelegate != null) caps.add("share.invoke")
            if (filesPickDelegate != null) caps.add("file_picker")
            routeDelegate?.let { delegate ->
                caps.addAll(delegate.registeredRoutes.map { "route.$it" })
            }
            return caps
        }
}
