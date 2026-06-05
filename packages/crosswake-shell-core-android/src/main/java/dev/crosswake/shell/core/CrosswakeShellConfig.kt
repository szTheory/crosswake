package dev.crosswake.shell.core

data class CrosswakeShellConfig(
    val appInfoDelegate: AppInfoDelegate? = null,
    val hapticsDelegate: HapticsDelegate? = null,
    val permissionStatusDelegate: PermissionStatusDelegate? = null,
    val notificationTokenDelegate: NotificationTokenDelegate? = null,
    val shareDelegate: ShareDelegate? = null,
    val filesPickDelegate: FilesPickDelegate? = null
)
