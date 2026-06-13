import re

with open("examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift", "r") as f:
    content = f.read()

content = content.replace("packStore: Self.packStore\n        )", "packStore: Self.packStore,\n            config: Self.config\n        )")
content = content.replace("packStore: Self.stalePackStore\n        )", "packStore: Self.stalePackStore,\n            config: Self.config\n        )")

stubs = """
    private struct StubAppInfoDelegate: AppInfoDelegate { func getAppInfo() -> [String: String] { [:] } }
    private struct StubHapticsDelegate: HapticsDelegate { func impact(style: String) {} }
    private struct StubPermissionStatusDelegate: PermissionStatusDelegate { func status(for permissionAlias: String) -> [String: String]? { nil } }
    private struct StubNotificationTokenDelegate: NotificationTokenDelegate { func currentToken() -> BridgeChannel.NotificationTokenCommandSnapshot { .unavailable(reason: "none", detail: [:]) } }
    private struct StubShareDelegate: ShareDelegate { func invoke(payload: [String: String]) {} }
    private struct StubFilesPickDelegate: FilesPickDelegate { func pickFiles(payload: [String: String], correlationID: String, completion: @escaping (BridgeChannel.CommandResult) -> Void) {} }

    private static let config = CrosswakeShellConfig(
        appInfoDelegate: StubAppInfoDelegate(),
        hapticsDelegate: StubHapticsDelegate(),
        permissionStatusDelegate: StubPermissionStatusDelegate(),
        notificationTokenDelegate: StubNotificationTokenDelegate(),
        shareDelegate: StubShareDelegate(),
        filesPickDelegate: StubFilesPickDelegate()
    )
}"""

content = re.sub(r'}\s*$', stubs, content)

with open("examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift", "w") as f:
    f.write(content)
