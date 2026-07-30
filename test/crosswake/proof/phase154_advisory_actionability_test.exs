defmodule Crosswake.Proof.Phase154AdvisoryActionabilityTest do
  @moduledoc """
  Phase 154 Plan 08, Task 2 check G — the automated form of "are the doctor
  advisories actionable?"

  The phase's closing gate was a `checkpoint:human-verify` that asked a person to
  run `mix crosswake.doctor` and judge whether the two new Phase 154 findings
  "read clearly and actionably" and whether either changed doctor's exit status.
  The exit-status half is a decidable fact. The actionability half is judged
  STRUCTURALLY here — an enumerated imperative verb plus a referent that resolves
  in the real capability catalog — not by vibe.

  ## Honest labelling (house style — see `Crosswake.Bridge.CatalogGuard`)

    * **exit-status neutrality — MECHANICAL.** Doctor's status rule is
      `Enum.any?(findings, &(&1.severity == :error))` (`doctor.ex:183`). This file
      pins that rule as a literal AND applies it twice over the real report — once
      with the two Phase 154 findings, once without — asserting the answer is
      identical. A finding that could flip the status would make those two
      evaluations differ.
    * **severity — MECHANICAL.** `:warning`, asserted per finding.
    * **hint presence — MECHANICAL.** Non-empty, and longer than a stub.
    * **actionability — MECHANICAL BY PROXY, and the proxy is named.** "Actionable"
      is decomposed into two decidable properties: the hint OPENS with an
      imperative verb drawn from an enumerated set, and the finding NAMES a
      capability id that actually exists in `Manifest.Builder`'s catalog. A hint
      can satisfy both and still be badly written. What this catches is the real
      regression: a hint that degrades into a restatement of the problem, or one
      that points at a capability id that no longer exists.

  ## Where the referent lives, stated rather than fudged

  For `capability.legacy_capability_id` the hint itself names the family id to
  declare instead. For `bridge.capability.native_rebuild_required` the hint names
  the ACTION (rebuild and resubmit the native shell binary) while the capability
  referent lives in the message and in `details.capability_id`. Both are asserted,
  each where it actually is. Requiring the rebuild hint to also inline a capability
  id would be requiring a worse hint in order to satisfy a uniform test.

  ## Why this file is `:requires_example_host`

  The two findings named by the checkpoint are `route:selective-native-claim-capture`
  and `route:fieldserv-job-capture` — routes that exist only in the checked-in
  example Phoenix app. A synthetic router would produce the same CODES against
  different subjects, which is what `test/crosswake/doctor/doctor_test.exs` already
  covers. This file asserts the advisories on the real routes the human was asked
  to look at.

  The tag rides the existing merge-blocking `merge-blocking-requires-example-host`
  lane. No new required check name and no new workflow file (D-47).
  """

  use ExUnit.Case, async: false

  @moduletag :requires_example_host

  alias Crosswake.Doctor
  alias Crosswake.Manifest.Builder

  # The two Phase 154 advisory codes, and the route subject the checkpoint named
  # for each. Enumerated, not discovered: a rename must break this file loudly.
  @legacy_code "capability.legacy_capability_id"
  @rebuild_code "bridge.capability.native_rebuild_required"
  @phase_154_codes [@legacy_code, @rebuild_code]

  @legacy_subject "route:selective-native-claim-capture"
  @rebuild_subject "route:fieldserv-job-capture"

  # Imperative verbs a hint may OPEN with. Enumerated so that broadening the set is
  # a reviewable diff rather than a regex loosening nobody notices.
  @imperative_verbs ~w(
    declare rebuild resubmit publish upgrade add remove replace set run install
    move rename register configure
  )

  # Hedges. A hint that hedges is describing an option, not naming a next action.
  @hedging_tokens ["consider ", "you may want", "you might want", "perhaps", "possibly"]

  # The doctor status rule, as a literal. If this expression changes, the
  # exit-status argument below stops holding and this test must be re-derived.
  @status_rule "status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok)"

  setup_all do
    Crosswake.TestSupport.ExampleHost.load!()

    report = Doctor.run(route_source: CrosswakeExample.Router, cwd: File.cwd!())

    # TWO id sets, deliberately kept apart.
    #
    # `public_catalog_ids` is `Manifest.Builder`'s shipped catalog — the vocabulary
    # Crosswake teaches. `manifest_capability_ids` additionally contains the
    # compatibility entries synthesized from a route's own legacy declarations
    # (`"camera"` is one), and is what an adopter's doctor run actually resolves
    # against. A hint that tells an adopter what to DECLARE must point into the
    # public catalog; a finding that names what an adopter ALREADY declared must
    # resolve in the compiled manifest. Collapsing these into one set would let a
    # hint recommend a legacy id and still pass.
    public_catalog_ids = [] |> Builder.capability_registry() |> Map.keys()
    manifest_capability_ids = Map.keys(report.manifest.capability_registry)

    {:ok,
     report: report,
     public_catalog_ids: public_catalog_ids,
     manifest_capability_ids: manifest_capability_ids}
  end

  describe "the two Phase 154 advisories exist on the routes the checkpoint named" do
    test "route:selective-native-claim-capture carries a legacy-capability-id advisory", %{
      report: report
    } do
      assert [finding] = findings(report, @legacy_code, @legacy_subject)
      assert finding.details.route_id == "selective-native-claim-capture"
      assert finding.details.legacy_capability_id == "camera"
      assert finding.details.family_capability_id == "media_capture"
    end

    test "route:fieldserv-job-capture carries a native-rebuild-required advisory", %{report: report} do
      assert [finding] = findings(report, @rebuild_code, @rebuild_subject)
      assert finding.details.route_id == "fieldserv-job-capture"
      assert finding.details.rebuild == "native_required"
    end
  end

  describe "severity — both advisories are :warning" do
    test "every Phase 154 advisory in the real report is :warning, never :error", %{report: report} do
      advisories = Enum.filter(report.findings, &(&1.code in @phase_154_codes))

      # Non-vacuity: an empty list would satisfy every assertion below.
      assert advisories != [],
             "the example host must produce Phase 154 advisories — an empty list makes this file vacuous"

      for finding <- advisories do
        assert finding.severity == :warning,
               "#{finding.code} at #{finding.check} must stay advisory, got #{inspect(finding.severity)}"
      end
    end
  end

  describe "exit-status neutrality — neither advisory can flip doctor's status" do
    test "doctor's status rule is the literal this file's argument depends on" do
      source = File.read!(Path.join(File.cwd!(), "lib/crosswake/doctor/doctor.ex"))

      assert String.contains?(source, @status_rule),
             """
             Crosswake.Doctor's status rule changed. This file proves the Phase 154
             advisories cannot flip the exit status BY showing they are never :error
             and that only :error contributes. If the rule is no longer

                 #{@status_rule}

             then that argument no longer holds and this test must be re-derived
             against the new rule rather than updated to match it.
             """
    end

    test "applying doctor's own rule with and without the Phase 154 advisories gives the same answer",
         %{report: report} do
      rule = fn findings -> Enum.any?(findings, &(&1.severity == :error)) end

      advisories_only = Enum.filter(report.findings, &(&1.code in @phase_154_codes))
      without_advisories = Enum.reject(report.findings, &(&1.code in @phase_154_codes))

      # Non-vacuity in both directions: the split must actually split.
      assert advisories_only != []
      assert length(without_advisories) < length(report.findings)

      # THE DISCRIMINATING FORM. A report containing ONLY the Phase 154 advisories
      # must evaluate doctor's own rule to false — that is exactly "these findings,
      # by themselves, are not enough to fail doctor". The differential below is
      # weaker on a report that already carries unrelated :error findings, which the
      # core repo's own cwd does; this one is not.
      refute rule.(advisories_only),
             "a report whose only findings are the Phase 154 advisories must NOT be :error"

      assert rule.(report.findings) == rule.(without_advisories),
             "removing the Phase 154 advisories changed doctor's status verdict — they are contributing"
    end

    test "no Phase 154 advisory appears among the report's :error findings", %{report: report} do
      error_codes =
        report.findings |> Enum.filter(&(&1.severity == :error)) |> Enum.map(& &1.code)

      for code <- @phase_154_codes do
        refute code in error_codes
      end
    end
  end

  describe "actionability — an imperative verb and a referent that resolves" do
    test "every Phase 154 advisory hint is present, substantial, and unhedged", %{report: report} do
      advisories = Enum.filter(report.findings, &(&1.code in @phase_154_codes))
      assert advisories != []

      for finding <- advisories do
        hint = finding.hint

        assert is_binary(hint) and String.trim(hint) != "",
               "#{finding.code} at #{finding.check} has no hint — an advisory with no next action is noise"

        assert String.length(hint) > 40,
               "#{finding.code} hint is a stub: #{inspect(hint)}"

        refute hint == finding.message,
               "#{finding.code} hint merely restates the message — that is a description, not a next action"

        lowered = String.downcase(hint)

        for hedge <- @hedging_tokens do
          refute String.contains?(lowered, hedge),
                 "#{finding.code} hint hedges with #{inspect(hedge)} — name the action"
        end
      end
    end

    test "every Phase 154 advisory hint OPENS with an enumerated imperative verb", %{
      report: report
    } do
      advisories = Enum.filter(report.findings, &(&1.code in @phase_154_codes))
      assert advisories != []

      for finding <- advisories do
        first_word =
          finding.hint
          |> String.trim_leading()
          |> String.split(~r/[^a-zA-Z]/, parts: 2)
          |> hd()
          |> String.downcase()

        assert first_word in @imperative_verbs,
               """
               #{finding.code} at #{finding.check} opens with #{inspect(first_word)},
               which is not in the enumerated imperative set #{inspect(@imperative_verbs)}.
               A hint that does not open with a verb is describing, not directing.
               Hint was: #{inspect(finding.hint)}
               """
      end
    end

    test "the legacy-id hint names the real family capability id to declare instead", %{
      report: report,
      public_catalog_ids: public_catalog_ids
    } do
      assert [finding] = findings(report, @legacy_code, @legacy_subject)

      family_id = finding.details.family_capability_id

      assert family_id in public_catalog_ids,
             "the hint points at #{inspect(family_id)}, which is not in the shipped public capability catalog"

      assert String.contains?(finding.hint, inspect(family_id)),
             "the hint must name the capability id an adopter should declare, verbatim and copyable"

      assert String.contains?(finding.hint, "capabilities:"),
             "the hint must name the route-policy key the adopter edits, not just the value"
    end

    test "the rebuild hint names the rebuild action, and the finding names a real capability", %{
      report: report,
      manifest_capability_ids: manifest_capability_ids
    } do
      assert [finding] = findings(report, @rebuild_code, @rebuild_subject)

      # The ACTION lives in the hint...
      assert String.contains?(finding.hint, "native shell binary")

      assert String.contains?(finding.hint, "OTA"),
             "the hint must name what will NOT satisfy the rebuild — the false path is the actionable part"

      # ...and the REFERENT lives in the message and details, which is where a
      # rebuild instruction naturally carries it. Asserted where it actually is.
      capability_id = finding.details.capability_id

      assert capability_id in manifest_capability_ids,
             "the finding names #{inspect(capability_id)}, which does not resolve in the compiled manifest's capability registry"

      assert String.contains?(finding.message, capability_id)
      assert String.contains?(finding.message, finding.details.route_id)
    end

    test "on a route where both advisories fire, they name the SAME capability id", %{
      report: report
    } do
      # Coherence, and the reason it matters: `route:fieldserv-job-capture` declares
      # the legacy id `"camera"`, so the rebuild advisory names `"camera"` too rather
      # than silently switching to the family form. Two advisories on one route that
      # named different ids would read as two unrelated problems.
      assert [legacy] = findings(report, @legacy_code, @rebuild_subject)
      assert [rebuild] = findings(report, @rebuild_code, @rebuild_subject)

      assert rebuild.details.capability_id == legacy.details.legacy_capability_id
    end

    test "the rebuild hint distinguishes the native path from the companion path", %{
      report: report
    } do
      assert [finding] = findings(report, @rebuild_code, @rebuild_subject)

      # A hint that named both paths would leave the adopter to guess which applies.
      refute String.contains?(finding.hint, "companion package"),
             "a :native_required rebuild must not offer the companion path as an alternative"
    end
  end

  defp findings(report, code, subject) do
    Enum.filter(report.findings, &(&1.code == code and &1.check == subject))
  end
end
