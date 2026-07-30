defmodule Crosswake.Proof.Phase154RecipeFollowableTest do
  @moduledoc """
  Phase 154 Plan 08, Task 2 check H — the automated form of "is the guard's
  six-step recipe genuinely followable?"

  The phase's closing gate asked a human to read the six-step recipe that
  `Crosswake.Bridge.CatalogGuard.assert_catalog_closed!/0` prints on failure and
  judge whether it is followable — because, in that checkpoint's words, *a gate
  with no documented path to yes gets deleted*.

  `test/crosswake/proof/phase154_catalog_guard_test.exs` already asserts the recipe
  TEXT exists. That is the weak form: it proves the words are printed, not that
  following them works. This file is the strong form. It EXECUTES the recipe
  end-to-end against a synthetic control in a temp fixture tree and asserts:

    1. the guard is GREEN on the pristine fixture tree (the tree is faithful);
    2. the guard is GREEN after all followable steps are applied (the recipe works);
    3. omitting any single mechanically-enforced step leaves it RED, and the
       failure message NAMES that step's artifact.

  ## Honest labelling (house style — see `CatalogGuard`'s own moduledoc)

    * **The raiser under test is the real one.** This file calls
      `CatalogGuard.assert_catalog_closed!/1`, the same function `mix
      crosswake.doctor` and the proof lane call, with its inputs injected. It does
      not re-compose the individual predicates and hope the composition matches.
    * **SYNTHETIC-TREE CAVEAT — this is a proxy, and here is exactly what for.**
      The catalog entry, the command list, and the registry mapping are supplied as
      VALUES, not by editing `Manifest.Builder`, `Bridge.Contract`, and
      `Bridge.Registry` on disk and recompiling. So this file proves the GUARD
      accepts a correctly-followed recipe and rejects each omission. It does not
      prove that a developer's edit to those three source files produces those
      values. The native-enum steps (4) ARE real file edits in the temp tree,
      because those the guard reads from disk.
    * **Step 1 is NOT mechanically caught — asserted as such, not papered over.**
      See the "known hole" describe block. `check_attestation/3` rejects a catalog
      entry with no command and a command with no mapping, but NOT a mapping that
      points at a capability with no catalog entry — because the real tree has ten
      such mappings by design (the four transfer commands and `permissions.status`
      map to ids that are not `owner: :bounded_bridge` catalog entries). Closing
      that direction is a gate-semantics change, not a test change. The hole is
      pinned here so it is a named fact rather than a silent one.
    * **Step 6 has fail-closed DEFAULTS, not a red gate.** Also asserted as such.

  ## Why no new workflow file and no new required check (D-47)

  Untagged file in `test/crosswake/proof/`, executed by the broad final step of the
  existing hermetic lane exactly like its sibling `phase154_catalog_guard_test.exs`.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Bridge.CatalogGuard
  alias Crosswake.Bridge.Contract
  alias Crosswake.Manifest.Types

  # The synthetic control. Deliberately NOT a plausible future control name — a
  # reader grepping the repo for this string should land here and nowhere else.
  @synthetic_command "synthetic.control.invoke"
  @synthetic_capability "synthetic_control"

  # The four native denial sources the guard reads. The two enum sources are a
  # subset; both lists are copied into the fixture tree so the allowlist-liveness
  # check has its real subjects.
  @native_relative_paths [
    "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift",
    "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt",
    "examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift",
    "examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift"
  ]

  @ios_enum_relative_path "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift"
  @android_enum_relative_path "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt"

  # The recipe's steps, by the number the failure message gives them.
  @step_2_wire_command :wire_command
  @step_3_registry_mapping :registry_mapping
  @step_4_ios_enum :ios_enum
  @step_4_android_enum :android_enum
  @step_1_catalog_entry :catalog_entry

  @all_steps [
    @step_1_catalog_entry,
    @step_2_wire_command,
    @step_3_registry_mapping,
    @step_4_ios_enum,
    @step_4_android_enum
  ]

  setup do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-recipe-#{System.unique_integer([:positive])}"
      )

    build_fixture_tree!(root)
    on_exit(fn -> File.rm_rf!(root) end)

    {:ok, root: root}
  end

  # ---------------------------------------------------------------------------
  # The fixture tree is faithful — without this every result below is worthless
  # ---------------------------------------------------------------------------

  describe "fixture-tree fidelity" do
    test "the pristine fixture tree is GREEN under the real raiser", %{root: root} do
      assert CatalogGuard.assert_catalog_closed!(root: root) == :ok
    end

    test "the fixture tree contains every source the guard actually reads", %{root: root} do
      for path <- CatalogGuard.bridge_sources(root) do
        assert File.exists?(path), "fixture tree is missing bridge source #{path}"
      end

      for path <- CatalogGuard.native_denial_sources(root) do
        assert File.exists?(path), "fixture tree is missing native denial source #{path}"
      end

      # Non-vacuity: an empty bridge-source list would make the source walk pass
      # for the reason Phase 134 named — a job not found is a FAILURE, not a pass.
      assert length(CatalogGuard.bridge_sources(root)) > 3
      assert length(CatalogGuard.native_denial_sources(root)) == 4
    end

    test "the fixture native enums start out with exactly the shipped command set", %{root: root} do
      for path <- CatalogGuard.native_command_enum_sources(root) do
        assert {:ok, wire_values} = CatalogGuard.extract_native_command_enum(File.read!(path))
        assert Contract.commands() -- wire_values == []
        refute @synthetic_command in wire_values
      end
    end
  end

  # ---------------------------------------------------------------------------
  # RED -> GREEN: the recipe, followed
  # ---------------------------------------------------------------------------

  describe "following the recipe turns the gate GREEN" do
    test "a synthetic control added by every followable step passes the real raiser", %{root: root} do
      assert run_guard(root, @all_steps) == :ok
    end

    test "the gate is RED at the first step and GREEN at the last — the path to yes exists", %{
      root: root
    } do
      # Step 2 alone (a wire command with nothing else) is the state a developer is
      # in the moment they add a command string and run the suite.
      assert {:error, message} = run_guard(root, [@step_2_wire_command])
      assert message =~ @synthetic_command

      # ...and the same tree, with the remaining steps applied, is green.
      assert run_guard(root, @all_steps) == :ok
    end

    test "every failure message carries the six-step recipe — the documented path to yes", %{
      root: root
    } do
      assert {:error, message} = run_guard(root, [@step_2_wire_command])

      assert message =~ "THE SIX-STEP RECIPE FOR ADDING THE NEXT CONTROL"
      assert message =~ "Manifest.Builder"
      assert message =~ "Crosswake.Bridge.Contract"
      assert message =~ "Crosswake.Bridge.Registry"
      assert message =~ "BOTH native command enums"
      assert message =~ "mix crosswake.contract.gen"
      assert message =~ "denial and the fallback surface before the happy path"

      # The stable id on line 1 (D-48), so a failure is greppable.
      assert message =~ "[proof.ctrl_04.catalog_closed."
      assert message =~ "posture=merge_blocking"
    end
  end

  # ---------------------------------------------------------------------------
  # The negative: omitting ONE step leaves it RED, naming that step
  # ---------------------------------------------------------------------------

  describe "omitting a single mechanically-enforced step leaves the gate RED" do
    test "omitting step 2 (the literal wire command) is RED and names the command", %{root: root} do
      assert {:error, message} = run_guard(root, @all_steps -- [@step_2_wire_command])

      # Reported from BOTH directions: the registry maps a command that does not
      # ship, and both native enums carry a case the server never heard of.
      assert message =~ "attestation_orphan"
      assert message =~ "native_enum_orphan"
      assert message =~ @synthetic_command
    end

    test "omitting step 3 (the registry mapping) is RED and names both sides of the gap", %{
      root: root
    } do
      assert {:error, message} = run_guard(root, @all_steps -- [@step_3_registry_mapping])

      # The catalog entry has no command reaching it...
      assert message =~ "attestation_gap"
      assert message =~ @synthetic_capability
      # ...and the shipped command has no capability owner.
      assert message =~ "attestation_orphan"
      assert message =~ @synthetic_command
    end

    test "omitting step 4 on iOS is RED and names the iOS enum source", %{root: root} do
      assert {:error, message} = run_guard(root, @all_steps -- [@step_4_ios_enum])

      assert message =~ "native_enum_gap"
      assert message =~ @synthetic_command

      # Scoped to the reported-violations block. The message's standing "host-supplied
      # denial seam" note names both platform files unconditionally, so a whole-message
      # match would be true no matter which side actually drifted.
      violations = violation_lines(message)
      assert violations != []
      assert Enum.all?(violations, &(&1 =~ "BridgeChannel.swift"))
      refute Enum.any?(violations, &(&1 =~ "BridgeChannel.kt"))
    end

    test "omitting step 4 on Android is RED and names the Android enum source", %{root: root} do
      assert {:error, message} = run_guard(root, @all_steps -- [@step_4_android_enum])

      assert message =~ "native_enum_gap"
      assert message =~ @synthetic_command

      violations = violation_lines(message)
      assert violations != []
      assert Enum.all?(violations, &(&1 =~ "BridgeChannel.kt"))
      refute Enum.any?(violations, &(&1 =~ "BridgeChannel.swift"))
    end

    test "one-sided native parity is caught — 'drift with a delay' is the recipe's own phrase", %{
      root: root
    } do
      # Both single-sided omissions are red. Asserting them together is what makes
      # the recipe's step 4 wording ("in the same PR") mechanically true rather than
      # advisory.
      assert {:error, _} = run_guard(root, @all_steps -- [@step_4_ios_enum])
      assert {:error, _} = run_guard(root, @all_steps -- [@step_4_android_enum])
      assert run_guard(root, @all_steps) == :ok
    end
  end

  # ---------------------------------------------------------------------------
  # Step 5 — regenerate the contract vectors
  # ---------------------------------------------------------------------------

  describe "step 5 (regenerate the contract vectors) is enforced by the vectors themselves" do
    @vector_paths [
      "test/fixtures/bridge_contract_vectors.json",
      "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json",
      "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"
    ]

    test "every committed vector file's command list equals the shipped vocabulary today" do
      for relative <- @vector_paths do
        vectors = relative |> Path.expand(File.cwd!()) |> File.read!() |> Jason.decode!()

        assert vectors["commands"] == Contract.commands(),
               "#{relative} has drifted from Crosswake.Bridge.Contract.commands/0 — run mix crosswake.contract.gen"
      end
    end

    test "adding a command WITHOUT regenerating breaks that equality — step 5 is not optional" do
      # The negative control for the test above. Without this, a vectors file and a
      # command list that were both empty would satisfy the equality.
      with_synthetic = Contract.commands() ++ [@synthetic_command]

      for relative <- @vector_paths do
        vectors = relative |> Path.expand(File.cwd!()) |> File.read!() |> Jason.decode!()

        refute vectors["commands"] == with_synthetic,
               "#{relative} already carries the synthetic command — this negative control is vacuous"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Step 6 — fail-closed defaults, honestly labelled as defaults
  # ---------------------------------------------------------------------------

  describe "step 6 (write the denial and the fallback first) has fail-closed defaults" do
    test "a catalog entry that omits denial, fallback, rebuild, and interaction defaults to the most conservative values" do
      # Step 6 is NOT a red gate — `Types.new_capability/1` supplies defaults, so a
      # maintainer who skips it still gets a compilable catalog entry. What IS
      # mechanical is that every default fails CLOSED: silence can never understate
      # the rebuild cost or claim a completion the control does not provide (D-51,
      # D-54). That is the inoculation, and it is what this test pins.
      capability = Types.new_capability(id: @synthetic_capability)

      assert capability.denial == "unavailable_capability"
      assert capability.fallback == "fail_closed"
      assert capability.rebuild == :native_required
      assert capability.interaction == :fire_and_forget
    end

    test "a catalog entry written the way the recipe describes carries every field the recipe names" do
      capability = Types.new_capability(synthetic_catalog_entry())

      for field <- [
            :id,
            :owner,
            :package_class,
            :proof_class,
            :rebuild,
            :interaction,
            :prerequisites,
            :denial,
            :fallback,
            :guide
          ] do
        value = Map.fetch!(capability, field)
        refute value in [nil, "", []], "recipe step 1 names #{field}, which came back empty"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # The known hole, pinned rather than hidden
  # ---------------------------------------------------------------------------

  describe "KNOWN HOLE — step 1 is not mechanically caught" do
    @tag :known_limitation
    test "omitting step 1 (the catalog entry) does NOT turn the gate red", %{root: root} do
      # This test asserts a LIMITATION, deliberately. `check_attestation/3` rejects
      # a catalog entry with no command (gap) and a command with no mapping
      # (orphan), but not a mapping whose capability has no catalog entry — because
      # the real tree has ten such mappings by design (the four transfer commands
      # and `permissions.status` map to ids that are not `owner: :bounded_bridge`
      # catalog entries), so that direction cannot be closed without changing what
      # the gate means.
      #
      # IF YOU CLOSE THIS HOLE: delete this test and move the case up into the
      # omitting-a-single-step block. A failing assertion here is good news.
      assert run_guard(root, @all_steps -- [@step_1_catalog_entry]) == :ok,
             "step 1 is now mechanically caught — move this case into the RED block above"
    end

    test "the shipped tree really does contain mappings with no bounded-bridge catalog entry" do
      # The evidence for the paragraph above, asserted rather than asserted-in-prose.
      mapped =
        CatalogGuard.shipped_command_capability_map()
        |> Map.values()
        |> Enum.reject(&is_nil/1)
        |> Enum.uniq()

      uncatalogued = mapped -- CatalogGuard.bounded_bridge_capability_ids()

      assert uncatalogued != [],
             "no uncatalogued mappings remain — the reverse attestation direction may now be closeable"
    end
  end

  # ---------------------------------------------------------------------------
  # Fixture construction and the step applier
  # ---------------------------------------------------------------------------

  # Runs the REAL raiser against the fixture tree with `steps` applied. Returns
  # `:ok` or `{:error, message}` — the message is the raiser's own text, so every
  # assertion above is made against what a developer would actually read.
  defp run_guard(root, steps) do
    apply_native_steps!(root, steps)

    opts = [
      root: root,
      commands: commands_for(steps),
      command_capability_map: command_capability_map_for(steps),
      catalog_capability_ids: catalog_capability_ids_for(steps)
    ]

    try do
      CatalogGuard.assert_catalog_closed!(opts)
    rescue
      error in RuntimeError -> {:error, Exception.message(error)}
    end
  end

  # The "Every violated criterion, not just the first" block, and nothing else. The
  # surrounding prose (the recipe, the host-supplied-seam note) names source files
  # unconditionally, so any per-platform assertion must be scoped to this slice.
  defp violation_lines(message) do
    message
    |> String.split("Every violated criterion, not just the first:\n", parts: 2)
    |> List.last()
    |> String.split("\n\nWHY THE VOCABULARY IS CLOSED", parts: 2)
    |> hd()
    |> String.split("\n", trim: true)
  end

  defp commands_for(steps) do
    if @step_2_wire_command in steps do
      Contract.commands() ++ [@synthetic_command]
    else
      Contract.commands()
    end
  end

  defp command_capability_map_for(steps) do
    if @step_3_registry_mapping in steps do
      Map.put(
        CatalogGuard.shipped_command_capability_map(),
        @synthetic_command,
        @synthetic_capability
      )
    else
      CatalogGuard.shipped_command_capability_map()
    end
  end

  defp catalog_capability_ids_for(steps) do
    if @step_1_catalog_entry in steps do
      Enum.sort([@synthetic_capability | CatalogGuard.bounded_bridge_capability_ids()])
    else
      CatalogGuard.bounded_bridge_capability_ids()
    end
  end

  # Step 4 is a REAL file edit, because that is how the guard reads it.
  defp apply_native_steps!(root, steps) do
    ios_anchor = "    case appInfoGet = \"app.info.get\"\n"
    ios_patched = ios_anchor <> "    case syntheticControlInvoke = \"#{@synthetic_command}\"\n"

    android_anchor = "    APP_INFO_GET(\"app.info.get\"),\n"

    android_patched =
      android_anchor <> "    SYNTHETIC_CONTROL_INVOKE(\"#{@synthetic_command}\"),\n"

    write_native!(root, @ios_enum_relative_path, @step_4_ios_enum in steps, fn source ->
      String.replace(source, ios_anchor, ios_patched)
    end)

    write_native!(root, @android_enum_relative_path, @step_4_android_enum in steps, fn source ->
      String.replace(source, android_anchor, android_patched)
    end)
  end

  defp write_native!(root, relative, apply?, patcher) do
    pristine = File.read!(Path.join(File.cwd!(), relative))
    patched = if apply?, do: patcher.(pristine), else: pristine

    if apply? do
      assert patched != pristine,
             "the #{relative} enum anchor moved — the patcher silently did nothing, which would make every parity assertion vacuous"
    end

    File.write!(Path.join(root, relative), patched)
  end

  defp build_fixture_tree!(root) do
    cwd = File.cwd!()

    File.mkdir_p!(Path.join(root, "lib/crosswake"))
    File.cp_r!(Path.join(cwd, "lib/crosswake/bridge"), Path.join(root, "lib/crosswake/bridge"))
    File.cp!(Path.join(cwd, "lib/crosswake/bridge.ex"), Path.join(root, "lib/crosswake/bridge.ex"))

    for relative <- @native_relative_paths do
      target = Path.join(root, relative)
      File.mkdir_p!(Path.dirname(target))
      File.cp!(Path.join(cwd, relative), target)
    end

    :ok
  end

  defp synthetic_catalog_entry do
    [
      id: @synthetic_capability,
      family: @synthetic_capability,
      owner: :bounded_bridge,
      package_class: :core,
      proof_class: :merge_blocking,
      rebuild: :native_required,
      interaction: :device_answer,
      prerequisites: ["declared route capability", "bounded bridge support"],
      denial: "undeclared_capability",
      fallback: "Phoenix route continues without the synthetic control",
      guide: "guides/bridge.md#bounded-bridge"
    ]
  end
end
