import re
import os

pbx_path = "examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj"
with open(pbx_path, "r") as f:
    content = f.read()

files_to_remove = [
    "ActivationCoordinator.swift",
    "BridgeChannel.swift",
    "CrosswakeDelegates.swift",
    "CrosswakeShell.swift",
    "CrosswakeShellConfig.swift",
    "DiagnosticExportManager.swift",
    "PackStore.swift",
    "TransferCoordinator.swift",
    "ActivationCoordinatorTests.swift",
    "BridgeChannelTests.swift"
]

for old_file in files_to_remove:
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' in Sources \*/ = \{isa = PBXBuildFile; fileRef = [^\n]+\n', '', content, flags=re.MULTILINE)
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' \*/ = \{isa = PBXFileReference;[^\n]+\n', '', content, flags=re.MULTILINE)
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' \*/,\n', '', content, flags=re.MULTILINE)
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' in Sources \*/,\n', '', content, flags=re.MULTILINE)
    
    file_path = f"examples/ios_shell_host/CrosswakeShell/{old_file}"
    if os.path.exists(file_path):
        os.remove(file_path)
    test_file_path = f"examples/ios_shell_host/CrosswakeShellTests/{old_file}"
    if os.path.exists(test_file_path):
        os.remove(test_file_path)

# SPM Integration
spm_remote = """
/* Begin XCRemoteSwiftPackageReference section */
		B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git";
			requirement = {
				kind = exactVersion;
				version = "0.1.0";
			};
		};
/* End XCRemoteSwiftPackageReference section */
"""
if "XCRemoteSwiftPackageReference" not in content:
    content = content.replace("/* End PBXFileReference section */\n", "/* End PBXFileReference section */\n" + spm_remote)

pkg_product = """
/* Begin XCSwiftPackageProductDependency section */
		B10000020000000000000001 /* CrosswakeShellCore */ = {
			isa = XCSwiftPackageProductDependency;
			productName = CrosswakeShellCore;
			package = B10000010000000000000001;
		};
/* End XCSwiftPackageProductDependency section */
"""
if "XCSwiftPackageProductDependency" not in content:
    content = content.replace("/* End PBXGroup section */\n", "/* End PBXGroup section */\n" + pkg_product)

# Add to Main Target Dependencies
content = content.replace("dependencies = (\n\t\t\t);", "dependencies = (\n\t\t\t\tB10000040000000000000001 /* PBXTargetDependency */,\n\t\t\t);", 1)

target_dep = """
/* Begin PBXTargetDependency section */
		A10000360000000000000001 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			target = A100002A0000000000000001 /* CrosswakeShell */;
			targetProxy = A10000350000000000000001 /* PBXContainerItemProxy */;
		};
		B10000040000000000000001 /* PBXTargetDependency */ = {
			isa = PBXTargetDependency;
			productRef = B10000020000000000000001 /* CrosswakeShellCore */;
		};
/* End PBXTargetDependency section */
"""
content = re.sub(r'/\* Begin PBXTargetDependency section \*/.*?/\* End PBXTargetDependency section \*/', target_dep.strip(), content, flags=re.DOTALL)

# Add to Frameworks Build Phase
content = content.replace("A10000230000000000000001 /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t);", "A10000230000000000000001 /* Frameworks */ = {\n\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tfiles = (\n\t\t\t\tB10000050000000000000001 /* CrosswakeShellCore in Frameworks */,\n\t\t\t);")

# Add build file for the framework
if "CrosswakeShellCore in Frameworks" not in content:
    content = content.replace("/* Begin PBXBuildFile section */\n", "/* Begin PBXBuildFile section */\n\t\tB10000050000000000000001 /* CrosswakeShellCore in Frameworks */ = {isa = PBXBuildFile; productRef = B10000020000000000000001 /* CrosswakeShellCore */; };\n")

# Add package references to Project
if "packageReferences = (" not in content:
    content = content.replace("targets = (", "packageReferences = (\n\t\t\t\tB10000010000000000000001,\n\t\t\t);\n\t\t\ttargets = (")

with open(pbx_path, "w") as f:
    f.write(content)

print("Done updating pbxproj")
