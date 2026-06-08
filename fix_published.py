import re

files = [
    "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift",
    "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift",
    "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/TransferCoordinator.swift",
    "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/PackStore.swift",
    "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/DiagnosticExportManager.swift"
]

for file_path in files:
    with open(file_path, "r") as f:
        content = f.read()

    # fix @Published
    content = re.sub(r'public\s+@Published', r'@Published public', content)

    # make nested structs/enums/classes public
    content = re.sub(r'^(\s*)(class|struct|enum|protocol)\s+(\w+)', r'\1public \2 \3', content, flags=re.MULTILINE)
    content = re.sub(r'public\s+public\s+', r'public ', content)
    
    with open(file_path, "w") as f:
        f.write(content)
