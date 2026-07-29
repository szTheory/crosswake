defmodule Crosswake.Proof.Phase154CatalogGuardTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 154 CTRL-04 / PROOF-04 — the catalog line.

  Proves that a proposed control which is host-registrable, dynamically
  registered, external-SDK-importing, atom-minting, or divergent from either
  native command enum fails a structural test, and that the test is non-vacuous
  in the four ways D-46 requires:

    1. a multi-violation fixture reports EVERY violated criterion, not the first;
    2. one inline synthetic negative control per mechanical sub-assertion;
    3. a positive control on real shipped source, proving no false positives;
    4. the attestation check rejects gaps AND orphans.

  Runs UNTAGGED. `async: true` (read-only source scanning). Carries NO
  `@moduletag`, asserted by this file's own last test.

  ## Why there is no new workflow file (D-47)

  An untagged file in `test/crosswake/proof/` is already executed by the broad
  final step of the `core-hermetic-proof` job, and by four other merge-blocking
  contexts. Phases 142, 145, 153 and 153.1 all shipped proof tests with zero new
  workflow files. Phase 153.1 cut wall-clock time-to-green from 34.9 minutes to
  5.8 minutes; a new required check would cost the two-step
  rename-and-registration ritual and buy nothing this file does not already get
  for free. A step name is free. A check name is not.

  ## What this gate does NOT do (D-45)

  It closes the mechanical plugin-catalog road. It does not stop a maintainer
  adding forty controls one string at a time. The inoculation against that is the
  attestation criteria plus CTRL-05 making each control's rebuild cost publicly
  named — both of which shipped in Plan 02. This moduledoc says so explicitly so
  the requirement cannot quietly overclaim.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Bridge.CatalogGuard
  alias Crosswake.Bridge.Contract
  alias Crosswake.TestSupport.ProofAssertions

  # Completion-claiming outcome values. A :fire_and_forget capability that emits
  # one of these is claiming an answer it never received (D-56).
  @completion_claiming_outcomes ~w(completed accepted shared succeeded)

  @outcome_value_regex ~r/(?<![a-z_])"?outcome"?\s*(?::|=>)\s*:?"?([a-z_]+)"?/

  # ---------------------------------------------------------------------------
  # NEGATIVE CONTROL 1 — the multi-violation fixture reports the COMPLETE SET
  # ---------------------------------------------------------------------------

  describe "CTRL-04 non-vacuity kind 1 — a report, not a short-circuit (D-46)" do
    test "a source violating six criteria at once reports ALL SIX violated criteria" do
      violating = """
      defmodule ProposedControl do
        alias FirebaseMessaging.Client

        @commands ~w(app.info.get) ++ ["wallet.charge"]

        def register_command(name), do: String.to_atom(name)
        def dispatch(m, f, a), do: apply(m, f, a)
        def tail(f), do: Stream.resource(f, f, f)
      end
      """

      assert {:violation, violations} = CatalogGuard.check_source(violating)

      observed = violations |> Enum.map(&elem(&1, 0)) |> MapSet.new()

      expected =
        MapSet.new([
          :command_list_not_literal,
          :dynamic_registration,
          :runtime_apply,
          :atom_minting,
          :external_sdk,
          :streaming_seam
        ])

      assert MapSet.equal?(observed, expected),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.multi_violation_set_complete",
               "check_source/1 must report the COMPLETE SET of violated criteria",
               "CatalogGuard.check_source/1",
               "expected=#{inspect(Enum.sort(expected))} observed=#{inspect(Enum.sort(observed))}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "the guard is a report, not a short-circuit — a five-violation control must not " <>
                 "look like a one-violation control (D-46)",
               :merge_blocking
             )
    end

    test "the ORDER of the reported violations is unspecified but the SET is complete" do
      violating = """
      defmodule ProposedControl do
        def register_command(name), do: String.to_atom(name)
      end
      """

      assert {:violation, violations} = CatalogGuard.check_source(violating)

      observed = violations |> Enum.map(&elem(&1, 0)) |> Enum.sort()

      assert observed == [:atom_minting, :dynamic_registration],
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.violation_set_order_independent",
               "the violation SET is asserted, never the violation ORDER",
               "CatalogGuard.check_source/1",
               "sorted violation criteria were #{inspect(observed)}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "assert on the sorted set — prewalk accumulation order is an implementation detail",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # NEGATIVE CONTROL 2 — one inline synthetic per mechanical sub-assertion
  # ---------------------------------------------------------------------------

  describe "CTRL-04 non-vacuity kind 2 — one synthetic per mechanical sub-assertion (D-46)" do
    test "criterion (d): a runtime-constructed command list is detected" do
      assert {:violation, _} =
               CatalogGuard.check_command_list_literal(
                 "defmodule F do\n  @commands Enum.map(~w(a b), & &1)\nend\n"
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.command_list_literal",
               "the command vocabulary must be a compile-time literal",
               "CatalogGuard.check_command_list_literal/1",
               "a command list built with Enum.map/2 was accepted as a literal",
               "lib/crosswake/bridge/contract.ex",
               "a runtime-constructed vocabulary is the plugin-catalog road under another name",
               :merge_blocking
             )
    end

    test "criterion (d): a dynamic-registration function is detected" do
      assert {:violation, _} =
               CatalogGuard.check_no_dynamic_registration(
                 "defmodule F do\n  def register_control(n), do: n\nend\n"
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.dynamic_registration",
               "no register_-prefixed function may exist in the bridge tree",
               "CatalogGuard.check_no_dynamic_registration/1",
               "a def register_control/1 was not flagged",
               "lib/crosswake/bridge/catalog_guard.ex",
               "host-registrable command registration must be structurally impossible (CTRL-04)",
               :merge_blocking
             )
    end

    test "criterion (d): runtime function application is detected" do
      assert {:violation, _} =
               CatalogGuard.check_no_runtime_apply(
                 "defmodule F do\n  def go(m, f, a), do: apply(m, f, a)\nend\n"
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.runtime_apply",
               "no runtime function application in the bridge tree",
               "CatalogGuard.check_no_runtime_apply/1",
               "an apply/3 call was not flagged",
               "lib/crosswake/bridge/catalog_guard.ex",
               "apply/3 lets a wire command string become a call target (CTRL-04)",
               :merge_blocking
             )
    end

    test "criterion (d): atom minting is detected" do
      assert {:violation, _} =
               CatalogGuard.check_no_atom_minting(
                 "defmodule F do\n  def go(s), do: String.to_atom(s)\nend\n"
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.atom_minting",
               "no atom minting from wire input in the bridge tree",
               "CatalogGuard.check_no_atom_minting/1",
               "a String.to_atom/1 call was not flagged",
               "lib/crosswake/bridge/catalog_guard.ex",
               "String.to_atom/1 grows the atom table from attacker-controlled input",
               :merge_blocking
             )
    end

    test "criterion (c): an external SDK dependency is detected" do
      assert {:violation, _} =
               CatalogGuard.check_no_external_sdk(
                 "defmodule F do\n  alias FirebaseMessaging.Client\nend\n"
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.external_sdk",
               "zero external SDK dependencies in the bridge tree",
               "CatalogGuard.check_no_external_sdk/1",
               "an alias to a non-allowlisted top-level namespace was not flagged",
               "lib/crosswake/bridge/catalog_guard.ex",
               "criterion (c) is an AST allowlist walk over dependency declarations",
               :merge_blocking
             )
    end

    test "criterion (b), in the negative: a streaming seam is detected" do
      assert {:violation, _} =
               CatalogGuard.check_no_streaming_seam(
                 "defmodule F do\n  def go(f), do: Stream.resource(f, f, f)\nend\n"
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.non_vacuity.streaming_seam",
               "no streaming or back-pressure seam in the bridge tree",
               "CatalogGuard.check_no_streaming_seam/1",
               "a Stream.resource/3 reference was not flagged",
               "lib/crosswake/bridge/catalog_guard.ex",
               "criterion (b) is MECHANICAL ONLY IN THE NEGATIVE — absence of a seam is " <>
                 "provable, call-site discipline is not (D-44)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # NEGATIVE CONTROL 3 — positive control on real shipped source
  # ---------------------------------------------------------------------------

  describe "CTRL-04 non-vacuity kind 3 — the guard is not permissive by accident (D-46)" do
    test "lib/crosswake/manifest/builder.ex — the real attestation file — returns clean" do
      path = "lib/crosswake/manifest/builder.ex"

      assert :ok = CatalogGuard.check_source(File.read!(Path.join(File.cwd!(), path))),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.positive_control.builder_clean",
               "the guard must not false-positive on the real capability catalog source",
               "CatalogGuard.check_source/1",
               "check_source flagged real shipped source",
               path,
               "a guard that flags shipped code gets deleted rather than fixed",
               :merge_blocking
             )
    end

    test "every file in the real bridge tree returns clean" do
      flagged =
        Enum.filter(CatalogGuard.bridge_sources(), fn path ->
          CatalogGuard.check_source(File.read!(path)) != :ok
        end)

      assert flagged == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.positive_control.bridge_tree_clean",
               "the whole shipped bridge tree must satisfy the catalog line",
               "CatalogGuard.check_source/1 over CatalogGuard.bridge_sources/0",
               "flagged=#{inspect(flagged)}",
               "lib/crosswake/bridge/",
               "run mix test test/crosswake/bridge/catalog_guard_test.exs to see which predicate fired",
               :merge_blocking
             )
    end

    test "assert_catalog_closed!/0 does not raise on the shipped tree — the gate is GREEN today" do
      assert :ok = CatalogGuard.assert_catalog_closed!(),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.gate_green",
               "the catalog line holds over the real shipped sources",
               "CatalogGuard.assert_catalog_closed!/0",
               "the raiser raised",
               "lib/crosswake/bridge/catalog_guard.ex",
               "the raiser's message carries the six-step recipe for adding the next control (D-48)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # NEGATIVE CONTROL 4 — attestation rejects gaps AND orphans
  # ---------------------------------------------------------------------------

  describe "CTRL-04 non-vacuity kind 4 — attestation is bidirectional (D-46)" do
    test "a catalog entry with no shipped command is a GAP" do
      assert {:violation, violations} =
               CatalogGuard.check_attestation(
                 ["app.info.get"],
                 %{"app.info.get" => "app_info"},
                 ["app_info", "wallet"]
               )

      assert Enum.any?(violations, &match?({:attestation_gap, "wallet"}, &1)),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.attestation.gap_detected",
               "a catalog capability with no shipped command must be a violation",
               "CatalogGuard.check_attestation/3",
               "observed=#{inspect(violations)}",
               "lib/crosswake/manifest/builder.ex",
               "a catalog entry claiming a control that does not exist is a lie in the attestation file",
               :merge_blocking
             )
    end

    test "a shipped command with no catalog entry is an ORPHAN" do
      assert {:violation, violations} =
               CatalogGuard.check_attestation(
                 ["app.info.get", "wallet.charge"],
                 %{"app.info.get" => "app_info"},
                 ["app_info"]
               )

      assert Enum.any?(violations, &match?({:attestation_orphan, "wallet.charge"}, &1)),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.attestation.orphan_detected",
               "a shipped command with no catalog entry must be a violation",
               "CatalogGuard.check_attestation/3",
               "observed=#{inspect(violations)}",
               "lib/crosswake/bridge/registry.ex",
               "an undeclared control wearing a declared one's badge has no owner, no rebuild " <>
                 "cost, and no declared denial",
               :merge_blocking
             )
    end

    test "the REAL command vocabulary and the REAL capability catalog attest each other" do
      assert :ok =
               CatalogGuard.check_attestation(
                 Contract.commands(),
                 CatalogGuard.shipped_command_capability_map(),
                 CatalogGuard.bounded_bridge_capability_ids()
               ),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.attestation.real_sources_agree",
               "every shipped command maps to a catalog entry and back",
               "CatalogGuard.check_attestation/3 over Contract.commands/0 + Builder catalog",
               "the real command list and the real catalog disagree",
               "lib/crosswake/bridge/contract.ex",
               "add the capability to the catalog AND the command to Registry in the same PR",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Native command enum parity — BOTH sources, BOTH directions
  # ---------------------------------------------------------------------------

  describe "CTRL-04 — native command enum parity against BOTH native sources" do
    test "both native BridgeCommand enums agree with the Elixir command vocabulary" do
      failures =
        Enum.flat_map(CatalogGuard.native_command_enum_sources(), fn path ->
          case CatalogGuard.check_native_enum_parity(File.read!(path), Contract.commands()) do
            :ok -> []
            {:violation, list} -> [{path, list}]
          end
        end)

      assert failures == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.native_parity.both_enums_agree",
               "every Elixir command exists in both native enums and vice versa",
               "CatalogGuard.check_native_enum_parity/2",
               "failures=#{inspect(failures)}",
               "packages/crosswake-shell-core-{ios,android}",
               "add the case to BOTH native enums in the same PR — one-sided parity is drift with a delay",
               :merge_blocking
             )
    end

    test "an unlocatable native enum block FAILS rather than passing vacuously (Phase 134 carry-forward)" do
      assert :error = CatalogGuard.extract_native_command_enum("// the enum was renamed\n"),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.native_parity.unlocatable_is_failure",
               "a missing native enum block must be an error, not an empty success",
               "CatalogGuard.extract_native_command_enum/1",
               "the extractor returned {:ok, []} for a source with no enum block",
               "lib/crosswake/bridge/catalog_guard.ex",
               "job not found is a FAILURE, not a pass — an extractor that silently returns [] " <>
                 "turns the parity check green exactly when it should be red (D-46)",
               :merge_blocking
             )

      assert {:violation, [{:native_enum_unlocatable, _} | _]} =
               CatalogGuard.check_native_enum_parity("// renamed\n", Contract.commands())
    end

    test "non-vacuity: a synthetic native enum missing a shipped command is a GAP" do
      synthetic = """
      public enum BridgeCommand: String, CaseIterable {
          case appInfoGet = "app.info.get"
      }
      """

      assert {:violation, violations} =
               CatalogGuard.check_native_enum_parity(synthetic, Contract.commands())

      assert Enum.any?(violations, &match?({:native_enum_gap, _}, &1)),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.native_parity.non_vacuity_gap",
               "a native enum missing a shipped command must be flagged",
               "CatalogGuard.check_native_enum_parity/2",
               "observed=#{inspect(violations)}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "gap detection is what keeps a shipped command from having no native handler",
               :merge_blocking
             )
    end

    test "non-vacuity: a synthetic native enum case with no Elixir command is an ORPHAN" do
      synthetic = """
      public enum BridgeCommand: String, CaseIterable {
          case walletCharge = "wallet.charge"
      }
      """

      assert {:violation, violations} =
               CatalogGuard.check_native_enum_parity(synthetic, Contract.commands())

      assert Enum.any?(violations, &match?({:native_enum_orphan, "wallet.charge"}, &1)),
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.native_parity.non_vacuity_orphan",
               "a native enum case with no Elixir command must be flagged",
               "CatalogGuard.check_native_enum_parity/2",
               "observed=#{inspect(violations)}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "orphan detection closes the dynamic-registration hole from the native end (CTRL-04)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # CTRL-02 / D-16 — the native denial-reason subset assertion
  # Disposition: option-b with amendment. Eight enumerated, individually
  # justified, seed-tagged strings. A NINTH goes red.
  # ---------------------------------------------------------------------------

  describe "CTRL-02 / D-16 — native denial reasons are a bounded subset" do
    test "every statically extractable native denial reason is in-vocabulary or on the seeded allowlist" do
      out_of_bounds =
        Enum.flat_map(CatalogGuard.native_denial_sources(), fn path ->
          case CatalogGuard.check_native_denial_reasons(File.read!(path)) do
            :ok -> []
            {:violation, list} -> Enum.map(list, fn {_, reason} -> {path, reason} end)
          end
        end)

      assert out_of_bounds == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.native_denial.subset_holds",
               "native denial reason strings must be a subset of the closed vocabulary plus the seeded allowlist",
               "CatalogGuard.check_native_denial_reasons/1 over CatalogGuard.native_denial_sources/0",
               "out_of_bounds=#{inspect(out_of_bounds)}",
               ".planning/seeds/SEED-008-native-denial-vocabulary.md",
               "a NINTH out-of-vocabulary string is not an allowlist entry waiting to be added — " <>
                 "read SEED-008 and either use a closed-vocabulary reason or justify the addition in review",
               :merge_blocking
             )
    end

    test "non-vacuity: a NEW out-of-vocabulary string in a native source turns this assertion RED" do
      # A synthetic copy of a real emission site with one reason string changed.
      synthetic =
        ~S|completion(deny(request, reason: "wallet_locked", message: "Nope.", hint: "Retry."))|

      assert {:violation, [{:out_of_vocabulary_denial_reason, "wallet_locked"} | _]} =
               CatalogGuard.check_native_denial_reasons(synthetic),
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.native_denial.non_vacuity",
               "introducing a ninth out-of-vocabulary reason must turn the subset assertion red",
               "CatalogGuard.check_native_denial_reasons/1",
               "a novel reason string was accepted — the allowlist is behaving as an open set",
               "lib/crosswake/bridge/catalog_guard.ex",
               "the allowlist enumerates exactly eight strings; anything else is a violation (D-16, option-b)",
               :merge_blocking
             )
    end

    test "the allowlist enumerates exactly eight strings, each justified and seed-tagged" do
      allowlist = CatalogGuard.out_of_vocabulary_denial_allowlist()

      assert length(allowlist) == 8,
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.native_denial.allowlist_is_eight",
               "the out-of-vocabulary denial allowlist must enumerate exactly eight strings",
               "CatalogGuard.out_of_vocabulary_denial_allowlist/0",
               "length=#{length(allowlist)} reasons=#{inspect(Enum.map(allowlist, & &1.reason))}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "growing this list is the failure mode option-b's own cons warn about — retire " <>
                 "entries via SEED-008 rather than adding them",
               :merge_blocking
             )

      unjustified =
        Enum.filter(allowlist, fn e ->
          e.justification in [nil, ""] or e.seed != "SEED-008" or e.sites == []
        end)

      assert unjustified == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.native_denial.every_entry_justified",
               "each allowlist entry carries an individual justification, its sites, and the seed id",
               "CatalogGuard.out_of_vocabulary_denial_allowlist/0",
               "unjustified=#{inspect(Enum.map(unjustified, & &1.reason))}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "an unjustified entry is padding; adding one must cost a written explanation in review (D-16)",
               :merge_blocking
             )
    end

    test "no allowlist entry has gone stale — each is still emitted at a declared site" do
      assert :ok = CatalogGuard.check_denial_allowlist_liveness(),
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.native_denial.allowlist_liveness",
               "every allowlist entry must still be emitted by at least one of its declared sites",
               "CatalogGuard.check_denial_allowlist_liveness/0",
               "a seeded allowlist entry no longer appears in any declared native source",
               "lib/crosswake/bridge/catalog_guard.ex",
               "a stale entry makes the debt look larger than it is and quietly widens the gate — delete it",
               :merge_blocking
             )
    end

    test "the guard names all FIVE unbounded host-supplied delegate seams as a NON-MECHANICAL exclusion" do
      source = File.read!(Path.join(File.cwd!(), "lib/crosswake/bridge/catalog_guard.ex"))

      seams = [
        "core/CrosswakeDelegates.kt:39",
        "core/FilesPickResult.kt:7",
        "BridgeChannel.swift:128",
        "BridgeChannel.swift:133",
        "shell/CrosswakeDelegates.kt:39"
      ]

      missing = Enum.reject(seams, &String.contains?(source, &1))

      assert missing == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.unbounded_seam.all_five_named",
               "the guard must name all five bare-String delegate seams, not just one",
               "File.read!(lib/crosswake/bridge/catalog_guard.ex)",
               "missing=#{inspect(missing)}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "any adopter host can mint an arbitrary reason at any of the five — naming one " <>
                 "implies the other four are covered when they are not",
               :merge_blocking
             )

      assert String.contains?(source, "NOT mechanically enforceable"),
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.unbounded_seam.labelled_non_mechanical",
               "the unbounded seam must be labelled NOT mechanically enforceable",
               "File.read!(lib/crosswake/bridge/catalog_guard.ex)",
               "the moduledoc does not state that this sub-assertion is unenforceable",
               "lib/crosswake/bridge/catalog_guard.ex",
               "do not let the six-criteria block imply coverage it does not have (D-44, D-45)",
               :merge_blocking
             )
    end

    test "SEED-008 exists and carries BOTH halves of the deferral" do
      path = ".planning/seeds/SEED-008-native-denial-vocabulary.md"
      full = Path.join(File.cwd!(), path)

      assert File.exists?(full),
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.seed_008.exists",
               "the D-16 deferral must be explicit and named, never silent",
               "File.exists?(#{path})",
               "the seed file does not exist",
               path,
               "D-16 requires the deferral be carried by a named seed (CONTEXT.md)",
               :merge_blocking
             )

      body = File.read!(full)

      for needle <- CatalogGuard.out_of_vocabulary_denial_allowlist() |> Enum.map(& &1.reason) do
        assert String.contains?(body, needle),
               ProofAssertions.stable_id_message(
                 "proof.ctrl_02.seed_008.enumerates_allowlist",
                 "SEED-008 must enumerate every allowlisted string the guard tolerates",
                 "File.read!(#{path})",
                 "missing allowlist entry: #{needle}",
                 path,
                 "the seed and the guard's allowlist are two halves of one record — they must agree",
                 :merge_blocking
               )
      end

      assert String.contains?(body, "BREAKING"),
             ProofAssertions.stable_id_message(
               "proof.ctrl_02.seed_008.names_breaking_change",
               "SEED-008 must state that converting the five seams to enums is a BREAKING change",
               "File.read!(#{path})",
               "the seed does not name the breaking-change cost of the second half",
               path,
               "the five-seam half changes public adopter-implemented types on both platforms " <>
                 "and is gated on the Phase 153 mirror train",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # D-56 — the frozen outcome-vocabulary guard (~15 lines, as scoped)
  # The typed Outcome sum type is Phase 157, alongside share's iPad-crash guard.
  # ---------------------------------------------------------------------------

  describe "D-56 — :fire_and_forget capabilities may not claim completion" do
    test "no completion-claiming outcome value appears in the bridge tree or the committed vectors" do
      scanned =
        CatalogGuard.bridge_sources() ++
          [Path.join(File.cwd!(), "test/fixtures/bridge_contract_vectors.json")]

      offenders =
        Enum.flat_map(scanned, fn path ->
          @outcome_value_regex
          |> Regex.scan(File.read!(path))
          |> Enum.map(&Enum.at(&1, 1))
          |> Enum.filter(&(&1 in @completion_claiming_outcomes))
          |> Enum.map(&{path, &1})
        end)

      assert offenders == [],
             ProofAssertions.stable_id_message(
               "proof.d56.outcome_vocabulary.no_completion_claim",
               "a :fire_and_forget capability may only emit request-acknowledgement outcomes",
               "outcome-value scan over the bridge tree and the committed contract vectors",
               "offenders=#{inspect(offenders)}",
               "test/fixtures/bridge_contract_vectors.json",
               "share.invoke hands off to a native sheet and never learns what the user did — " <>
                 "\"requested\" is the only honest answer (D-56)",
               :merge_blocking
             )
    end

    test "non-vacuity: a synthetic completion-claiming outcome IS detected by the same scan" do
      synthetic = ~S|%{"outcome" => "completed"}|

      detected =
        @outcome_value_regex
        |> Regex.scan(synthetic)
        |> Enum.map(&Enum.at(&1, 1))
        |> Enum.filter(&(&1 in @completion_claiming_outcomes))

      assert detected == ["completed"],
             ProofAssertions.stable_id_message(
               "proof.d56.outcome_vocabulary.non_vacuity",
               "the outcome scan must actually detect a completion-claiming value",
               "outcome-value regex over a synthetic fixture",
               "detected=#{inspect(detected)}",
               "test/crosswake/proof/phase154_catalog_guard_test.exs",
               "a scan that finds nothing because it matches nothing is not a gate",
               :merge_blocking
             )
    end

    test "the scan does not mistake the vectors' expected_outcome field for an outcome value" do
      detected =
        @outcome_value_regex
        |> Regex.scan(~S|{"expected_outcome": "completed"}|)
        |> Enum.map(&Enum.at(&1, 1))

      assert detected == [],
             ProofAssertions.stable_id_message(
               "proof.d56.outcome_vocabulary.no_false_positive",
               "expected_outcome is a test-vector assertion field, not a wire outcome value",
               "outcome-value regex over a synthetic expected_outcome fixture",
               "detected=#{inspect(detected)}",
               "test/fixtures/bridge_contract_vectors.json",
               "the leading-underscore lookbehind is what keeps this scan honest",
               :merge_blocking
             )
    end

    test "at least one :fire_and_forget capability is declared — the guard has a subject" do
      fire_and_forget =
        []
        |> Crosswake.Manifest.Builder.capability_registry()
        |> Enum.filter(fn {_id, c} -> c.interaction == :fire_and_forget end)
        |> Enum.map(&elem(&1, 0))

      refute fire_and_forget == [],
             ProofAssertions.stable_id_message(
               "proof.d56.outcome_vocabulary.subject_exists",
               "the outcome guard must have at least one :fire_and_forget capability to constrain",
               "Manifest.Builder.capability_registry/1",
               "no capability declares interaction: :fire_and_forget",
               "lib/crosswake/manifest/builder.ex",
               "if this fires, the interaction vocabulary changed and D-56 needs rereading",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # D-48 — a gate with no documented path to yes gets deleted rather than used
  # ---------------------------------------------------------------------------

  describe "D-48 — the failure message documents the path to yes" do
    test "the raiser's message carries the stable id, the six-step recipe, and the brand-voice close" do
      source = File.read!(Path.join(File.cwd!(), "lib/crosswake/bridge/catalog_guard.ex"))

      required = [
        "posture=merge_blocking",
        "THE SIX-STEP RECIPE FOR ADDING THE NEXT CONTROL",
        "mix crosswake.contract.gen",
        "This gate does not exist to stop the next control."
      ]

      missing = Enum.reject(required, &String.contains?(source, &1))

      assert missing == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.path_to_yes.documented",
               "the failure message must name a legitimate path to adding the next control",
               "File.read!(lib/crosswake/bridge/catalog_guard.ex)",
               "missing=#{inspect(missing)}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "a gate with no documented path to approval gets deleted rather than used (D-48)",
               :merge_blocking
             )
    end

    test "the moduledoc labels which criteria are mechanical, negative-only, and hybrid (D-44)" do
      source = File.read!(Path.join(File.cwd!(), "lib/crosswake/bridge/catalog_guard.ex"))

      required = [
        "MECHANICAL ONLY IN THE NEGATIVE",
        "HYBRID",
        "MECHANICAL BY PROXY",
        "does **not** stop"
      ]

      missing = Enum.reject(required, &String.contains?(source, &1))

      assert missing == [],
             ProofAssertions.stable_id_message(
               "proof.ctrl_04.honest_labelling",
               "the guard's moduledoc must not let PROOF-04 overclaim",
               "File.read!(lib/crosswake/bridge/catalog_guard.ex)",
               "missing=#{inspect(missing)}",
               "lib/crosswake/bridge/catalog_guard.ex",
               "PROOF-04 closes the mechanical plugin-catalog road only — it does not prevent " <>
                 "gradual control sprawl (D-44, D-45)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane self-assertion (bottom of file — must always be last)
  # This proof file must carry no @moduletag (runs untagged, D-47).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: this proof file carries no @moduletag (D-47)" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "Phase 154 catalog guard proof file must not carry @moduletag: tags — it rides the " <>
             "existing merge-blocking hermetic lanes untagged, with zero new workflow files (D-47)"
  end
end
