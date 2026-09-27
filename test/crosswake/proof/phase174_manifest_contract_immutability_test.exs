defmodule Crosswake.Proof.Phase174ManifestContractImmutabilityTest do
  @moduledoc """
  Non-vacuity proof for Phase 174 Plan 02 (ROOM-06): `script/assert_manifest_contract_unchanged.sh`
  decides whether `doctor`'s `manifest_contract` check source is byte-identical to the baseline
  committed at `test/support/fixtures/phase174/manifest_contract_baseline.txt`, pinned to git
  commit `8bc77c35157e78da0a6a8b06301cfac48f5dc301`.

  This module invokes the REAL shell guard through `System.cmd/3` for every case — it contains
  no Elixir re-implementation of the region-extraction rule, per this milestone's standing
  convention that two implementations of the same rule eventually disagree (VACG-01's sunset
  reasoning in `REQUIREMENTS.md`).

  Each of the five behaviors below is a separately named test asserting a specific exit code and
  a specific result token — never a shared truthy "it failed" assertion, because that shape would
  leave three of the four failure modes unproven (T-174-06/07/08/09).

  ## Vacuity taxonomy (recorded here for the phase-close verifier; see
  `.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`)

  - `check_id`: `manifest_contract.byte_identity`
  - `shape`: A (an `Enum.all?`/`Enum.any?`-shaped possibly-empty-collection risk: the guard's
    `grep`/`awk` extraction of Region DEF and Region CALL from a live source file could return
    empty on a renamed or deleted function, and comparing two empty extractions would otherwise
    pass silently). Mitigated by asserting non-emptiness and exact occurrence count BEFORE any
    comparison runs (`script/assert_manifest_contract_unchanged.sh` assertion 1).
  - `non_vacuity_evidence`: the five mutations exercised below, each independently authored
    against the real script rather than predicted from its source: a one-byte edit inside
    `manifest_compile_check/1` (exit 4, `MANIFEST_CONTRACT_DEF_DRIFT`), a renamed function
    (exit 3, `MANIFEST_CONTRACT_EXTRACTION_EMPTY`), a deleted call site with the function intact
    (exit 3, `MANIFEST_CONTRACT_EXTRACTION_EMPTY`, message naming the call site specifically), an
    empty source file (exit 3), and the unmodified real source (exit 0,
    `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`).

  This guard was not registered as a new `script/verify_repository.mjs` stage. That facade's
  purpose inventory is a closed, ordered list of repository-quality stages
  (`script/verify_repository.mjs`'s `stageIds` manifest check); this guard is reached by the
  ordinary `mix test` lane via this module instead, which is sufficient to make it part of CI —
  every phase's proof modules under `test/crosswake/proof/` already run there. Adding a second,
  redundant registration point for the same fact was judged unnecessary rather than omitted.
  """

  use ExUnit.Case, async: true

  @repo_root Path.expand("../../..", Path.expand(__DIR__, System.get_env("PWD") || File.cwd!()))
  @script Path.join(@repo_root, "script/assert_manifest_contract_unchanged.sh")
  @real_source Path.join(@repo_root, "lib/crosswake/doctor/doctor.ex")

  @verified_token "MANIFEST_CONTRACT_UNCHANGED_VERIFIED"
  @extraction_empty_token "MANIFEST_CONTRACT_EXTRACTION_EMPTY"
  @def_drift_token "MANIFEST_CONTRACT_DEF_DRIFT"
  @call_drift_token "MANIFEST_CONTRACT_CALL_DRIFT"

  describe "the positive case (the check the guard exists to protect)" do
    test "running the guard against the real repository source exits 0 and prints the verified token" do
      {output, exit_code} = run_guard(@real_source)

      assert exit_code == 0, output
      assert output =~ @verified_token
    end
  end

  describe "one-byte drift inside the guarded function body (T-174-09)" do
    test "a single-byte edit inside manifest_compile_check/1 exits non-zero with the Region DEF drift token" do
      mutated =
        mutate_source!(fn source ->
          String.replace(source, "\"manifest_invalid\",", "\"manifest_invalidx\",", global: false)
        end)

      {output, exit_code} = run_guard(mutated)

      assert exit_code == 4, output
      assert output =~ @def_drift_token
      refute output =~ @extraction_empty_token
    end
  end

  describe "a renamed guarded function (T-174-07)" do
    test "renaming manifest_compile_check/1 exits non-zero with the extraction-empty token, not the drift token" do
      mutated =
        mutate_source!(fn source ->
          String.replace(source, "manifest_compile_check", "manifest_compile_check_renamed")
        end)

      {output, exit_code} = run_guard(mutated)

      assert exit_code == 3, output
      assert output =~ @extraction_empty_token
      refute output =~ @def_drift_token
      refute output =~ @call_drift_token
    end
  end

  describe "a deleted call site with the function body intact (T-174-08)" do
    test "deleting the &manifest_compile_check/1 capture exits non-zero, naming the call site" do
      mutated =
        mutate_source!(fn source ->
          String.replace(
            source,
            "manifest_findings = Enum.map(errors, &manifest_compile_check/1)",
            "manifest_findings = []"
          )
        end)

      {output, exit_code} = run_guard(mutated)

      assert exit_code == 3, output
      assert output =~ @extraction_empty_token
      assert output =~ "call site", output
      refute output =~ @def_drift_token
      refute output =~ @call_drift_token
    end
  end

  describe "an empty source file (the collapse-to-empty vacuity floor)" do
    test "an empty source file exits non-zero rather than passing" do
      empty_path = unique_tmp_path("empty")
      File.write!(empty_path, "")
      on_exit(fn -> File.rm(empty_path) end)

      {output, exit_code} = run_guard(empty_path)

      refute exit_code == 0, output
      assert output =~ @extraction_empty_token
    end
  end

  # -- helpers --------------------------------------------------------------------------------

  defp run_guard(source_path) do
    System.cmd("bash", [@script, "--source", source_path], stderr_to_stdout: true)
  end

  defp mutate_source!(transform) do
    original = File.read!(@real_source)
    mutated_content = transform.(original)

    if mutated_content == original do
      flunk(
        "mutation transform produced no change against #{@real_source}; the mutation did not apply"
      )
    end

    path = unique_tmp_path("mutated_doctor")
    File.write!(path, mutated_content)
    on_exit(fn -> File.rm(path) end)
    path
  end

  defp unique_tmp_path(label) do
    Path.join(
      System.tmp_dir!(),
      "phase174_manifest_contract_#{label}_#{System.unique_integer([:positive])}.ex"
    )
  end
end
