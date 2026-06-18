defmodule Crosswake.Planning.DocTruthTest do
  use ExUnit.Case, async: true

  @root File.cwd!()
  @milestones_path Path.join(@root, ".planning/MILESTONES.md")
  @audit_path Path.join(@root, ".planning/v1.0-MILESTONE-AUDIT.md")

  test "milestones document records the DOC-01 precedence rule" do
    milestones = File.read!(@milestones_path)

    assert milestones =~
             "`MILESTONES.md` curated shipped-state truth > `PROJECT.md` Requirements marks > `v*-MILESTONE-AUDIT.md` point-in-time snapshots"
  end

  test "milestones document records the v8.0 shipped-state truth" do
    milestones = File.read!(@milestones_path)

    section =
      section!(
        milestones,
        "## v8.0 Offline Sync Hardening and UI Polish (Shipped: 2026-06-11)"
      )

    for term <- [
          "Phases completed:** 99-101",
          "real network toggling",
          "advisory runtime storage budgets",
          "consolidated offline UI",
          "accepted verification debt",
          "later addressed by v12.0"
        ] do
      assert section =~ term,
             "v8.0 MILESTONES entry is missing #{inspect(term)}"
    end
  end

  test "v1.0 milestone audit is append-only annotated while preserving original snapshot" do
    audit = File.read!(@audit_path)

    assert audit =~ "status: gaps_found"
    assert audit =~ "requirements: 0/10"
    assert audit =~ ~s(id: "SYNC-01")
    assert audit =~ ~s(evidence: "Phase 99 is missing VERIFICATION.md")

    annotation =
      section!(
        audit,
        "## Append-Only Annotation: v8.0 Shipped-State Reconciliation"
      )

    for term <- [
          "point-in-time snapshot",
          "2026-06-11",
          "`requirements: 0/10`",
          "not the current shipped-state ledger",
          "v12.0"
        ] do
      assert annotation =~ term,
             "v1.0 audit annotation is missing #{inspect(term)}"
    end
  end

  defp section!(content, heading) do
    case Regex.run(
           ~r/^#{Regex.escape(heading)}\r?\n(.*?)(?=^## |\z)/ms,
           content,
           capture: :all_but_first
         ) do
      [section] -> section
      nil -> flunk("Missing section #{inspect(heading)}")
    end
  end
end
