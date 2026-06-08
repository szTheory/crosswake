import re

with open("priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex", "r") as f:
    content = f.read()

# Remove old PBXBuildFile
old_files = ["ActivationCoordinator.swift", "NativeCaptureView.swift", "TransferCoordinator.swift",
             "PackStore.swift", "RequiredPackView.swift", "BridgeChannel.swift",
             "LiveViewContainerViewController.swift", "RouteUnavailableView.swift",
             "ActivationCoordinatorTests.swift"]

for old_file in old_files:
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' in Sources \*/ = \{isa = PBXBuildFile; fileRef = [^\n]+\n', '', content, flags=re.MULTILINE)
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' \*/ = \{isa = PBXFileReference;[^\n]+\n', '', content, flags=re.MULTILINE)
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' \*/,\n', '', content, flags=re.MULTILINE)
    content = re.sub(r'^[^\n]+/\* ' + old_file + r' in Sources \*/,\n', '', content, flags=re.MULTILINE)

# Add CrosswakeCoordinator.swift
content = content.replace("/* CrosswakeShellApp.swift in Sources */,", "/* CrosswakeShellApp.swift in Sources */,\n\t\t\t\tA100000C0000000000000001 /* CrosswakeCoordinator.swift in Sources */,")
content = content.replace("/* CrosswakeShellApp.swift */,", "/* CrosswakeShellApp.swift */,\n\t\t\t\tA100001C000000000000000A /* CrosswakeCoordinator.swift */,")
content = content.replace("/* Begin PBXBuildFile section */\n", "/* Begin PBXBuildFile section */\n\t\tA100000C0000000000000001 /* CrosswakeCoordinator.swift in Sources */ = {isa = PBXBuildFile; fileRef = A100001C000000000000000A /* CrosswakeCoordinator.swift */; };\n")
content = content.replace("/* Begin PBXFileReference section */\n", "/* Begin PBXFileReference section */\n\t\tA100001C000000000000000A /* CrosswakeCoordinator.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = CrosswakeCoordinator.swift; sourceTree = \"<group>\"; };\n")

# SPM Integration
spm_remote = """
/* Begin XCRemoteSwiftPackageReference section */
		B10000010000000000000001 /* XCRemoteSwiftPackageReference "crosswake-shell-core-ios" */ = {
			isa = XCRemoteSwiftPackageReference;
			repositoryURL = "https://github.com/crosswake/crosswake-shell-core-ios.git";
			requirement = {
				kind = exactVersion;
				version = 0.1.0;
			};
		};
/* End XCRemoteSwiftPackageReference section */
"""

spm_local = """
/* Begin XCLocalSwiftPackageReference section */
		B10000030000000000000001 /* XCLocalSwiftPackageReference "crosswake-shell-core-ios" */ = {
			isa = XCLocalSwiftPackageReference;
			relativePath = "../../../packages/crosswake-shell-core-ios";
		};
/* End XCLocalSwiftPackageReference section */
"""

spm_section = """
<%= if @local do %>""" + spm_local + """<% else %>""" + spm_remote + """<% end %>
"""

content = content.replace("/* End PBXFileReference section */\n", "/* End PBXFileReference section */\n" + spm_section)

# Package product dependency
pkg_product = """
/* Begin XCSwiftPackageProductDependency section */
		B10000020000000000000001 /* CrosswakeShellCore */ = {
			isa = XCSwiftPackageProductDependency;
			productName = CrosswakeShellCore;
			package = <%= if @local do %>B10000030000000000000001<% else %>B10000010000000000000001<% end %>;
		};
/* End XCSwiftPackageProductDependency section */
"""

content = content.replace("/* End XCSwiftPackageProductDependency section */\n", "")
content = content.replace("/* End PBXGroup section */\n", "/* End PBXGroup section */\n" + pkg_product)

# Add dependency to PBXNativeTarget CrosswakeShell
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
content = content.replace("/* Begin PBXBuildFile section */\n", "/* Begin PBXBuildFile section */\n\t\tB10000050000000000000001 /* CrosswakeShellCore in Frameworks */ = {isa = PBXBuildFile; productRef = B10000020000000000000001 /* CrosswakeShellCore */; };\n")

# Add package references to Project
content = content.replace("targets = (", "packageReferences = (\n\t\t\t\t<%= if @local do %>B10000030000000000000001<% else %>B10000010000000000000001<% end %>,\n\t\t\t);\n\t\t\ttargets = (")

with open("priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex", "w") as f:
    f.write(content)

print("Done updating pbxproj")
