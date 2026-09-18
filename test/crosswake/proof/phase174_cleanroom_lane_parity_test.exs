defmodule Crosswake.Proof.Phase174CleanRoomLaneParityTest do
  @moduledoc """
  Non-vacuity proof for Phase 174 Task 2 (ROOM-03): the on-demand clean-room proof rehearsal
  workflow (`.github/workflows/clean-room-proof-rehearsal.yml`) must be able to run every
  companion the release lane's `clean-room-proof-*` jobs can prove — never fewer.

  The roster is discovered from `.github/workflows/release-please.yml`, an independent source,
  by keying on the `bash script/verify_companion_cleanroom.sh` invocation itself — never on the
  `clean-room-proof-*` job-name prefix. `clean-room-proof-ios` and `clean-room-proof-android`
  share that prefix but never call the harness (they run `mix crosswake.gen.shell`, `swift
  build`, and gradle, with no package argument), so a prefix-glob selector would silently
  discover seven members and either fail a cardinality-exactly-five assertion for the wrong
  reason or, worse, be trusted anyway. This is the scope-selector defect recorded as SEED-019: a
  roster derived from the thing it polices, or from an unrelated coincidence of naming, can never
  detect the omission it exists to catch.

  Deriving the roster from `clean-room-proof-rehearsal.yml` itself would be exactly that defect
  one level down — the rehearsal is the artifact UNDER TEST here, so a roster read out of it
  would shrink to whatever the rehearsal happens to list, and every companion the rehearsal
  forgot would be silently excluded from its own check.

  Per this milestone's absence-scored-as-success rule
  (`.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`), the cardinality
  assertion runs BEFORE the set-equality assertion, and the equality check is demonstrated to go
  RED against a fixture with one lane job removed.
  """

  use ExUnit.Case, async: true

  @release_workflow ".github/workflows/release-please.yml"
  @rehearsal_workflow ".github/workflows/clean-room-proof-rehearsal.yml"
  @script "script/verify_companion_cleanroom.sh"
  @expected_lane_cardinality 5
  @harness_script "script/verify_companion_cleanroom.sh"
  @expected_legacy_marker_cardinality 9
  @live_phase_dir ".planning/workstreams/quality-ratchet-release/phases/174-clean-room-host-realism-adopter-fidelity"
  @archived_phase_dir ".planning/workstreams/quality-ratchet-release/milestones/v23.0/phases/174-clean-room-host-realism-adopter-fidelity"
  @legacy_ci_log "evidence/174-rindle-ci-run.log"
  @matrix_ci_log "evidence/174-matrix-ci-run.log"

  describe "Task 2: the lane roster is discovered from release-please.yml's own script invocation" do
    test "exactly five jobs invoke the harness script with a package argument (cardinality gate before comparison)" do
      roster = discover_lane_roster(File.read!(@release_workflow))

      assert map_size(roster) == @expected_lane_cardinality,
             "expected exactly #{@expected_lane_cardinality} jobs invoking `bash #{@script}` in " <>
               "#{@release_workflow}, found #{map_size(roster)}: #{inspect(Map.keys(roster))} " <>
               "— an empty or shrunk discovery here would silently pass the equality check below " <>
               "as vacuously satisfied, so this assertion must run first and must never be skipped."

      assert roster == %{
               "clean-room-proof-rulestead" => "crosswake_rulestead",
               "clean-room-proof-rindle" => "crosswake_rindle",
               "clean-room-proof-sigra" => "crosswake_sigra",
               "clean-room-proof-chimeway" => "crosswake_chimeway",
               "clean-room-proof-threadline" => "crosswake_threadline"
             }
    end

    test "clean-room-proof-ios and clean-room-proof-android are not discovered as roster members" do
      workflow = File.read!(@release_workflow)

      assert workflow =~ "clean-room-proof-ios:",
             "expected the fixture assumption (a same-prefix, non-invoking job exists) to still hold"

      assert workflow =~ "clean-room-proof-android:",
             "expected the fixture assumption (a same-prefix, non-invoking job exists) to still hold"

      roster = discover_lane_roster(workflow)

      refute Map.has_key?(roster, "clean-room-proof-ios")
      refute Map.has_key?(roster, "clean-room-proof-android")
    end
  end

  describe "Task 2: roster equality between the lane and the rehearsal (ROOM-03)" do
    test "the rehearsal's package choice options equal the lane's discovered package set exactly" do
      lane_packages =
        File.read!(@release_workflow) |> discover_lane_roster() |> Map.values() |> MapSet.new()

      rehearsal_packages = rehearsal_package_options(File.read!(@rehearsal_workflow))

      missing_from_rehearsal = MapSet.difference(lane_packages, rehearsal_packages)
      extra_in_rehearsal = MapSet.difference(rehearsal_packages, lane_packages)

      assert MapSet.size(missing_from_rehearsal) == 0 and MapSet.size(extra_in_rehearsal) == 0,
             "lane package(s) the rehearsal cannot run: #{inspect(MapSet.to_list(missing_from_rehearsal))}; " <>
               "rehearsal package(s) absent from the lane: #{inspect(MapSet.to_list(extra_in_rehearsal))}"
    end

    test "the rehearsal invokes the same script path the lane jobs invoke" do
      rehearsal = File.read!(@rehearsal_workflow)

      assert rehearsal =~ "bash #{@script}",
             "expected #{@rehearsal_workflow} to invoke #{@script}, the same script every lane job in " <>
               "#{@release_workflow} invokes"
    end
  end

  describe "Task 2: non-vacuity control (D-14) — a lane job removed from a fixture must be caught" do
    test "deleting clean-room-proof-rindle from a fixture copy of the lane workflow makes the equality check fail and names crosswake_rindle" do
      original = File.read!(@release_workflow)
      mutated = remove_job_block(original, "clean-room-proof-rindle")

      refute mutated == original,
             "expected removing the clean-room-proof-rindle job block to actually change the fixture text"

      refute mutated =~ ~r/^  clean-room-proof-rindle:\n/m,
             "expected the job header itself to be gone from the mutated fixture " <>
               "(a later status-echo line mentions the same string and must not cause a false positive here)"

      mutated_lane_roster = discover_lane_roster(mutated)

      assert map_size(mutated_lane_roster) == @expected_lane_cardinality - 1,
             "expected the mutation to remove exactly one roster member, got #{map_size(mutated_lane_roster)}: " <>
               "#{inspect(Map.keys(mutated_lane_roster))}"

      lane_packages = mutated_lane_roster |> Map.values() |> MapSet.new()
      rehearsal_packages = rehearsal_package_options(File.read!(@rehearsal_workflow))

      missing_from_rehearsal = MapSet.difference(lane_packages, rehearsal_packages)
      extra_in_rehearsal = MapSet.difference(rehearsal_packages, lane_packages)

      refute MapSet.size(missing_from_rehearsal) == 0 and MapSet.size(extra_in_rehearsal) == 0,
             "expected the roster-removed fixture to make the equality check fail; it reported both " <>
               "sides equal instead"

      assert MapSet.member?(extra_in_rehearsal, "crosswake_rindle"),
             "expected the failure to name crosswake_rindle as the package present in the rehearsal " <>
               "but absent from the (mutated) lane, got extra_in_rehearsal=#{inspect(MapSet.to_list(extra_in_rehearsal))}"
    end

    test "an empty lane roster (all invocations stripped) is never trivially equal to the rehearsal's non-empty roster" do
      original = File.read!(@release_workflow)

      emptied =
        Regex.replace(
          ~r/bash script\/verify_companion_cleanroom\.sh\n(\s+crosswake_[a-z]+\n)/,
          original,
          "bash script/verify_companion_cleanroom.sh\n"
        )

      empty_roster = discover_lane_roster(emptied)

      assert map_size(empty_roster) == 0,
             "expected stripping every package argument to zero out the discovered roster, got: #{inspect(empty_roster)}"

      rehearsal_packages = rehearsal_package_options(File.read!(@rehearsal_workflow))

      refute MapSet.size(rehearsal_packages) == 0,
             "expected the rehearsal's own roster to be non-empty, so the comparison below is a real assertion"

      # An empty lane roster must be caught by the cardinality gate BEFORE it ever reaches an
      # equality comparison against the rehearsal's five options — asserting inequality directly
      # here demonstrates that a naive implementation skipping the cardinality gate would still
      # not silently pass on 0 == 0.
      refute MapSet.new() == rehearsal_packages
    end
  end

  describe "Task 2: SC#4 marker parity is asserted against the captured CI logs (Finding A closure)" do
    test "both captured CI logs yield a non-empty step= marker set before any comparison is made" do
      legacy = step_markers_in(read_evidence!(@legacy_ci_log))
      matrix = step_markers_in(read_evidence!(@matrix_ci_log))

      # These two assertions exist because Finding A was a measurement that scored absence as
      # success: the SC#4 comparison was recorded in prose, and this file passed unchanged when
      # `174-matrix-ci-run.log` was moved away and when it was truncated to zero bytes. A
      # zero-byte log yields an empty marker set, and `MapSet.size(empty) >= MapSet.size(empty)`
      # is true, so the comparison below would report parity against nothing at all. Both sides
      # must be proven non-empty FIRST, per this milestone's absence-scored-as-success rule.
      refute MapSet.size(legacy) == 0,
             "expected #{@legacy_ci_log} to contain at least one `step=` marker; an empty, " <>
               "missing, or truncated log would make the parity comparison below vacuously true"

      refute MapSet.size(matrix) == 0,
             "expected #{@matrix_ci_log} to contain at least one `step=` marker; an empty, " <>
               "missing, or truncated log would make the parity comparison below vacuously true"
    end

    test "the legacy path's captured CI log emits at least as many distinct step= markers as the matrix path's (SC#4)" do
      legacy = step_markers_in(read_evidence!(@legacy_ci_log))
      matrix = step_markers_in(read_evidence!(@matrix_ci_log))

      refute MapSet.size(legacy) == 0, "precondition: legacy marker set must be non-empty"
      refute MapSet.size(matrix) == 0, "precondition: matrix marker set must be non-empty"

      assert MapSet.size(legacy) >= MapSet.size(matrix),
             "SC#4 requires the legacy positional path to reach grep-able parity with the matrix " <>
               "path, but the captured CI logs show legacy=#{MapSet.size(legacy)} " <>
               "#{inspect(Enum.sort(legacy))} vs matrix=#{MapSet.size(matrix)} " <>
               "#{inspect(Enum.sort(matrix))}"
    end

    test "the legacy CI log's marker set is exactly the roster verify_companion_cleanroom.sh declares" do
      declared = declared_legacy_markers(File.read!(@harness_script))

      assert MapSet.size(declared) == @expected_legacy_marker_cardinality,
             "expected #{@expected_legacy_marker_cardinality} names in LEGACY_STEP_MARKERS in " <>
               "#{@harness_script}, found #{MapSet.size(declared)}: #{inspect(Enum.sort(declared))} " <>
               "— an empty or shrunk roster would make the set comparison below vacuously satisfied."

      observed = step_markers_in(read_evidence!(@legacy_ci_log))

      assert observed == declared,
             "the markers actually emitted by the captured legacy CI run do not match the roster " <>
               "the harness declares. Declared but never emitted: " <>
               "#{inspect(Enum.sort(MapSet.difference(declared, observed)))}; emitted but not " <>
               "declared: #{inspect(Enum.sort(MapSet.difference(observed, declared)))}"
    end

    test "a truncated evidence log is caught rather than scored as parity (non-vacuity control, D-14)" do
      # The exact mutation that exposed Finding A, run in-process against a copy so the real
      # evidence files are never touched: an emptied log must not read as parity.
      truncated = step_markers_in("")
      matrix = step_markers_in(read_evidence!(@matrix_ci_log))

      assert MapSet.size(truncated) == 0,
             "expected an empty log body to yield no markers, got #{inspect(truncated)}"

      refute MapSet.size(matrix) == 0,
             "expected the real matrix log to be non-empty, so the control below is a real assertion"

      # Without the non-emptiness gate above, this is the comparison SC#4 would have rested on --
      # and it passes, which is precisely why the gate is not optional.
      assert MapSet.size(truncated) >= MapSet.size(MapSet.new()),
             "a bare size comparison between two empty sets is satisfiable; documented here so " <>
               "that removing the non-emptiness gate cannot look harmless"

      refute MapSet.size(truncated) >= MapSet.size(matrix),
             "expected a truncated legacy log to FAIL the SC#4 comparison against the real matrix log"
    end
  end

  # --- fixture / source-reading helpers --------------------------------------

  # Scans `workflow` for every top-level job block, keeping only the ones whose body invokes
  # `bash script/verify_companion_cleanroom.sh` with a literal `crosswake_<name>` package
  # argument on the following line, and returns %{job_name => package}. This is the selector:
  # it keys on the harness invocation, never on any job-name prefix.
  defp discover_lane_roster(workflow) do
    ~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
    |> Regex.scan(workflow, capture: :all_but_first)
    |> Enum.reduce(%{}, fn [job, block], acc ->
      case Regex.run(
             ~r/bash script\/verify_companion_cleanroom\.sh\n\s+(crosswake_[a-z]+)\n/,
             block
           ) do
        [_, package] -> Map.put(acc, job, package)
        nil -> acc
      end
    end)
  end

  # Reads the `package:` workflow_dispatch input's `choice` `options:` list from the rehearsal
  # workflow text and returns it as a MapSet.
  defp rehearsal_package_options(workflow) do
    case Regex.run(~r/(?ms)^      package:\n(.*?)(?=^      [a-zA-Z_]+:\n|\z)/, workflow,
           capture: :all_but_first
         ) do
      [package_block] ->
        ~r/^\s+-\s+(crosswake_[a-z]+)\s*$/m
        |> Regex.scan(package_block, capture: :all_but_first)
        |> Enum.map(fn [package] -> package end)
        |> MapSet.new()

      nil ->
        raise "could not find a `package:` workflow_dispatch input in the rehearsal workflow text"
    end
  end

  # Returns a copy of `workflow` with the named top-level job block (header line through the
  # line before the next top-level job header) removed entirely.
  defp remove_job_block(workflow, job) do
    regex = ~r/(?ms)^  #{Regex.escape(job)}:\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/

    Regex.replace(regex, workflow, "")
  end

  # Resolves an evidence path that may live under the live phase directory or, after milestone
  # archival moves it, under the archived one. Raises with both candidates named rather than
  # returning "" -- a missing evidence file must fail loudly, never read as an empty marker set.
  defp read_evidence!(relative) do
    candidates = [
      Path.join(@live_phase_dir, relative),
      Path.join(@archived_phase_dir, relative)
    ]

    case Enum.find(candidates, &File.exists?/1) do
      nil ->
        raise "evidence file not found at any known location: #{inspect(candidates)}"

      path ->
        File.read!(path)
    end
  end

  # Returns the set of distinct `step=<name>` marker names appearing in `log`.
  defp step_markers_in(log) do
    ~r/\bstep=([a-z0-9][a-z0-9-]*)/
    |> Regex.scan(log, capture: :all_but_first)
    |> Enum.map(fn [name] -> name end)
    |> MapSet.new()
  end

  # Reads the `LEGACY_STEP_MARKERS=(...)` bash array from the harness script -- an independent
  # source from the evidence log it is compared against.
  defp declared_legacy_markers(script) do
    case Regex.run(~r/^LEGACY_STEP_MARKERS=\(([^)]*)\)/m, script, capture: :all_but_first) do
      [names] ->
        names |> String.split(~r/\s+/, trim: true) |> MapSet.new()

      nil ->
        raise "could not find a LEGACY_STEP_MARKERS=(...) array in #{@harness_script}"
    end
  end
end
