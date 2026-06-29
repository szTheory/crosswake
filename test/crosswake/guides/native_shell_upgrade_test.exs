defmodule Crosswake.Guides.NativeShellUpgradeTest do
  @moduledoc """
  Scaffold test for LIFE-02c — `guides/native_shell_upgrade.md` doc presence and
  structural checks on `lib/mix/tasks/crosswake.gen.shell.ex`.

  Tests are expected RED until Plan 04 authors the guide.

  Behaviours under test:
    - Guide `guides/native_shell_upgrade.md` exists and references `RebuildPolicy.classify/2`
    - `lib/mix/tasks/crosswake.gen.shell.ex` no longer contains the placeholder phrase

  Uses File.cwd!() anchored paths (consistent with the drift test pattern).
  """

  use ExUnit.Case, async: true

  @guide_path Path.join([File.cwd!(), "guides", "native_shell_upgrade.md"])
  @gen_shell_path Path.join([File.cwd!(), "lib", "mix", "tasks", "crosswake.gen.shell.ex"])

  # The placeholder phrase is expressed as a runtime check (not a bare literal in comments)
  # to avoid planner-discipline-allow violations.
  @placeholder_phrase "patch-or-doc guidance"

  # ---------------------------------------------------------------------------
  # SC#1 — doc presence: guides/native_shell_upgrade.md must exist
  # (RED until Plan 04 authors the guide)
  # ---------------------------------------------------------------------------

  test "guides/native_shell_upgrade.md exists" do
    assert File.exists?(@guide_path),
           "[proof.life_02c.guide_exists] " <>
             "guides/native_shell_upgrade.md must exist — " <>
             "run Plan 04 to author the upgrade guide"
  end

  # ---------------------------------------------------------------------------
  # SC#2 — content reference: the guide must mention RebuildPolicy.classify/2
  # (RED until Plan 04 authors the guide with the required reference)
  # ---------------------------------------------------------------------------

  test "guides/native_shell_upgrade.md references RebuildPolicy.classify/2" do
    if File.exists?(@guide_path) do
      contents = File.read!(@guide_path)

      assert String.contains?(contents, "RebuildPolicy.classify/2"),
             "[proof.life_02c.guide_references_rebuild_policy] " <>
               "guides/native_shell_upgrade.md must reference RebuildPolicy.classify/2 — " <>
               "add per-version classify/2 verdicts to the upgrade guide"
    else
      # Guide doesn't exist yet — the SC#1 test already fails for this; skip here
      :ok
    end
  end

  # ---------------------------------------------------------------------------
  # SC#3 — structural: gen.shell.ex no longer holds the placeholder phrase
  # (GREEN after Plan 04 replaces the placeholder with the real guide pointer)
  # ---------------------------------------------------------------------------

  test "crosswake.gen.shell.ex no longer contains placeholder guidance phrase" do
    if File.exists?(@gen_shell_path) do
      source = File.read!(@gen_shell_path)

      refute String.contains?(source, @placeholder_phrase),
             "[proof.life_02c.placeholder_removed] " <>
               "lib/mix/tasks/crosswake.gen.shell.ex must not contain the placeholder phrase — " <>
               "Plan 04 replaces it with a real pointer to guides/native_shell_upgrade.md"
    else
      flunk("lib/mix/tasks/crosswake.gen.shell.ex not found at #{@gen_shell_path}")
    end
  end
end
