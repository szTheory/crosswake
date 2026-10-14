defmodule Crosswake.Shell.IOSHostMigrationGraphTest do
  use ExUnit.Case, async: true
  alias Crosswake.Shell.{IOSHostProjectMigration, PBXProject}

  test "shell migration rejects an extra configuration regardless of line layout" do
    changed = String.replace(shell(), "/* End XCBuildConfiguration section */", "A10000000000000000000099 = {isa = XCBuildConfiguration; buildSettings = {}; name = Preview; };\n/* End XCBuildConfiguration section */")
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_contents(changed)
  end

  test "shell migration rejects a target remapped to the other target configuration list" do
    changed = String.replace(shell(), "buildConfigurationList = A10000330000000000000001", "buildConfigurationList = A10000340000000000000001")
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_contents(changed)
  end

  test "both migrations reject a settings reference redirected to another file" do
    changed_shell = String.replace(shell(), "path = CrosswakeHostSettings.xcconfig;", "path = unrelated-host-settings.xcconfig;")
    changed_proof = String.replace(proof(), "path = CrosswakeProofSettings.xcconfig;", "path = unrelated-host-settings.xcconfig;")
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_contents(changed_shell)
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_proof_contents(changed_proof)
  end

  test "both migrations reject redirected settings source trees and containing groups" do
    changed_shell = String.replace(shell(), "path = CrosswakeHostSettings.xcconfig; sourceTree = \"<group>\";", "path = CrosswakeHostSettings.xcconfig; sourceTree = SOURCE_ROOT;")
    changed_proof = String.replace(proof(), "A10000000000000000000020 = {isa = PBXGroup;", "A10000000000000000000020 = {isa = PBXGroup; path = redirected;")
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_contents(changed_shell)
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_proof_contents(changed_proof)
  end

  test "reformatted proof migration removes masks and preserves unrelated exact bytes" do
    changed = proof()
      |> String.replace("{isa = XCBuildConfiguration;", "{\n /* host configuration */ isa /* legal */ = XCBuildConfiguration;\n")
      |> String.replace("PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.prooflane;", "\"PRODUCT_BUNDLE_IDENTIFIER\" /* owned */ = org.crosswake.masked; \"CODE_SIGN_STYLE[sdk=iphoneos*]\" = Manual;")
      |> String.replace("PRODUCT_NAME = CrosswakeProofLane;", "PRODUCT_NAME = CrosswakeProofLane; /* untouched host note { } */ HOST_SETTING = \"quoted { braces }; and 🦉\";")
    assert {:ok, %{contents: migrated}} = IOSHostProjectMigration.preview_proof_contents(changed)
    refute migrated =~ "org.crosswake.masked"
    refute migrated =~ "CODE_SIGN_STYLE[sdk=iphoneos*]"
    assert migrated =~ "/* untouched host note { } */ HOST_SETTING = \"quoted { braces }; and 🦉\";"
    assert {:ok, %{contents: ^migrated}} = IOSHostProjectMigration.preview_proof_contents(migrated)
    assert {:ok, plist} = PBXProject.parse(migrated)
    assert plist["objects"]["A10000000000000000000070"]["buildSettings"]["PRODUCT_BUNDLE_IDENTIFIER"] == "$(CROSSWAKE_PROOF_APP_BUNDLE_ID)"
  end

  test "reformatted shell migration removes conditional masks and remains idempotent" do
    changed = shell()
      |> String.replace("isa = XCBuildConfiguration;", "\"isa\" /* legal */ = XCBuildConfiguration;")
      |> String.replace("PRODUCT_BUNDLE_IDENTIFIER = \"$(CROSSWAKE_APP_BUNDLE_ID)\";", "\"PRODUCT_BUNDLE_IDENTIFIER\" = org.crosswake.masked; \"DEVELOPMENT_TEAM[sdk=iphoneos*]\" = OTHERTEAM;")
    assert {:ok, %{contents: migrated}} = IOSHostProjectMigration.preview_contents(changed)
    refute migrated =~ "org.crosswake.masked"
    refute migrated =~ "DEVELOPMENT_TEAM[sdk=iphoneos*]"
    assert {:ok, %{contents: ^migrated}} = IOSHostProjectMigration.preview_contents(migrated)
  end

  test "project root and declared target membership cannot redirect migration" do
    changed_shell = String.replace(shell(), "rootObject = A10000200000000000000001", "rootObject = A100002A0000000000000001")
    changed_proof = String.replace(proof(), "targets = (A10000000000000000000030", "targets = (A10000000000000000000031")
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_contents(changed_shell)
    assert {:error, %{cause: :unrecognized_project}} = IOSHostProjectMigration.preview_proof_contents(changed_proof)
  end

  defp shell do
    EEx.eval_file("priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex", assigns: [local: true, local_ios_core_path: "/tmp/unused-local-core", version: "1.0.0"])
  end

  defp proof do
    File.read!("priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex")
  end
end
