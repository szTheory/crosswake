defmodule Crosswake.Planning.MilestoneArcCloseoutParityTest do
  use ExUnit.Case, async: true

  @arc_path Path.join(File.cwd!(), ".planning/MILESTONE-ARC.md")
  @project_path Path.join(File.cwd!(), ".planning/PROJECT.md")
  @closeout_path Path.join(File.cwd!(), ".planning/milestones/v3.6-CLOSEOUT.md")

  @shipped_milestones [
    "v1.0 Route-Policy Substrate",
    "v2.0 Adopter Stress Profiles",
    "v3.0 Capability Contract And Packaging",
    "v3.1 Native Capabilities and Bridge Expansion",
    "v3.2 Commerce And Entitlement Seams",
    "v3.3 Release Readiness",
    "v3.4 Commerce Archetype Proof",
    "v3.5 First-Party Companions"
  ]

  @queued_milestones [
    "v3.7 Commerce Provider Adapters",
    "v3.8 Full Sigra Auth and Session Machinery",
    "v3.9 Chimeway Notification Seam",
    "v4.0 Production Shell Runtime Line",
    "v4.1 Multi-SaaS Archetype Proof Lanes",
    "Threadline Audit Capstone"
  ]

  @queue_fields [
    "Objective",
    "Why now",
    "Depends on",
    "Risk tags",
    "Key outputs",
    "Non-goals",
    "Proof required"
  ]

  @closeout_keys [
    "requirements_state",
    "roadmap_parity",
    "phase_verification_coverage",
    "summary_frontmatter_coverage",
    "validation_ledger_status",
    "thread_seed_disposition",
    "release_changelog_continuity",
    "public_support_claim_changes",
    "deferred_with_reason",
    "exceptions"
  ]

  test "milestone arc records shipped milestones through v3.5 and v3.6 as active" do
    arc = File.read!(@arc_path)

    for milestone <- @shipped_milestones do
      assert arc =~ milestone,
             "MILESTONE-ARC.md is missing shipped milestone #{inspect(milestone)}"
    end

    assert arc =~ "### Active: v3.6 Operator Truth and Production Diagnostics",
           "MILESTONE-ARC.md must mark v3.6 as the active milestone"
  end

  test "queued milestone sections expose the strategic field contract" do
    arc = File.read!(@arc_path)

    for milestone <- @queued_milestones do
      section = queue_section!(arc, milestone)

      for field <- @queue_fields do
        assert section =~ "**#{field}**",
               "#{milestone} is missing required strategic field #{inspect(field)}"
      end
    end
  end

  test "strategic planning contract posture is explicit and fail closed" do
    arc = File.read!(@arc_path)

    for term <- ["explicit", "composable", "boring"] do
      assert String.contains?(String.downcase(arc), term),
             "MILESTONE-ARC.md must document D-19 planning-contract term #{inspect(term)}"
    end

    assert Regex.match?(~r/fail[- ]closed/i, arc),
           "MILESTONE-ARC.md must describe strategic artifacts as fail-closed contracts"
  end

  test "project summary points to milestone arc as queue source of truth" do
    project = File.read!(@project_path)

    assert project =~ "The strategic source of truth remains `.planning/MILESTONE-ARC.md`",
           "PROJECT.md must reference MILESTONE-ARC.md as strategic queue source"

    assert project =~ "not a second queue",
           "PROJECT.md must avoid presenting its queue summary as an independent source of truth"
  end

  test "v3.6 closeout ledger has required frontmatter keys and exception shape" do
    closeout = File.read!(@closeout_path)
    frontmatter = parse_frontmatter(closeout)

    assert frontmatter != "", "#{@closeout_path} has no YAML frontmatter block"

    for key <- @closeout_keys do
      assert Regex.match?(~r/^#{Regex.escape(key)}:/m, frontmatter),
             "#{@closeout_path} frontmatter is missing #{key}:"
    end

    for field <- ["owner", "scope", "reason", "revisit_phase", "evidence", "status"] do
      assert closeout =~ field,
             "#{@closeout_path} must document deferred_with_reason field #{inspect(field)}"
    end
  end

  test "v3.6 closeout checklist covers required artifact parity surfaces" do
    closeout = File.read!(@closeout_path)

    for term <- [
          "PROJECT.md",
          "MILESTONE-ARC.md",
          "ROADMAP.md",
          "REQUIREMENTS.md",
          "STATE.md",
          "verification",
          "requirements-completed",
          "validation ledger",
          "Thread/seed",
          "release/changelog",
          "public support-claim"
        ] do
      assert closeout =~ term,
             "#{@closeout_path} closeout checklist is missing #{inspect(term)}"
    end
  end

  test "phase 53 closeout.verify target fails closed on drift and malformed exceptions" do
    closeout = File.read!(@closeout_path)
    section = section!(closeout, "## Phase 53 Enforcement Target")

    for term <- [
          "closeout.verify",
          "missing or stale roadmap parity",
          "missing phase verification evidence",
          "malformed or missing SUMMARY frontmatter",
          "validation-ledger drift without `deferred_with_reason`",
          "unresolved thread/seed status",
          "public support-claim changes",
          "malformed `deferred_with_reason` exceptions"
        ] do
      assert section =~ term,
             "Phase 53 enforcement target is missing #{inspect(term)}"
    end
  end

  defp queue_section!(content, title) do
    case Regex.run(
           ~r/^### (?:Next|Later): #{Regex.escape(title)}\r?\n(.*?)(?=^### |\z)/ms,
           content,
           capture: :all_but_first
         ) do
      [section] -> section
      nil -> flunk("MILESTONE-ARC.md is missing queued milestone section #{inspect(title)}")
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

  defp parse_frontmatter(content) do
    case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
      [fm] -> fm
      nil -> ""
    end
  end
end
