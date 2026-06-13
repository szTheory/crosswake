import re
import os

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

    # We need to make top-level and member declarations public.
    
    # 1. classes, structs, enums, protocols
    content = re.sub(r'^(final\s+)?(class|struct|enum|protocol)\s+(\w+)', r'public \1\2 \3', content, flags=re.MULTILINE)
    
    # 2. initializers
    content = re.sub(r'^(\s*)init\(', r'\1public init(', content, flags=re.MULTILINE)
    
    # 3. properties (let/var) inside types but not inside functions
    # For now, let's just replace `let ` and `var ` at exactly 4 spaces of indentation (since the files use 4 spaces).
    content = re.sub(r'^ {4}(let|var)\s', r'    public \1 ', content, flags=re.MULTILINE)
    
    # @Published var
    content = re.sub(r'^ {4}(@Published\s+)(private\(set\)\s+)?(var)\s', r'    public \1\2\3 ', content, flags=re.MULTILINE)

    # typealias
    content = re.sub(r'^ {4}(typealias)\s', r'    public \1 ', content, flags=re.MULTILINE)

    # functions at 4 spaces indentation
    content = re.sub(r'^ {4}(func)\s', r'    public \1 ', content, flags=re.MULTILINE)
    
    # remove duplicate public
    content = re.sub(r'public\s+public\s+', r'public ', content)

    # static properties
    content = re.sub(r'^ {4}(static\s+let|static\s+var|static\s+func)\s', r'    public \1 ', content, flags=re.MULTILINE)

    # Any `private let` or `private var` should probably stay private UNLESS they said ALL properties.
    # The prompt: "adding `public` access modifiers to all classes, structs, enums, protocols, properties, and initializers"
    # It might mean we should replace private with public? 
    # Usually "adding public access modifiers to all [...] so they can be consumed by a host app" just implies making the internal (default) ones public. I'll leave private alone for now.
    
    # In BridgeChannel, extract necessary capability closure/delegate types into public definitions.
    # "make sure things like NotificationTokenCommandSnapshot, CommandResult, FilesPickHandler in BridgeChannel are accessible/public"
    
    with open(file_path, "w") as f:
        f.write(content)
