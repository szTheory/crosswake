defmodule Crosswake.Planning.MilestoneTransitionResetTest do
  use ExUnit.Case, async: true

  @root File.cwd!()
  @archive_roadmap Path.join(@root, ".planning/milestones/v3.6-ROADMAP.md")
  @archive_requirements Path.join(@root, ".planning/milestones/v3.6-REQUIREMENTS.md")
  @roadmap Path.join(@root, ".planning/ROADMAP.md")
  @requirements Path.join(@root, ".planning/REQUIREMENTS.md")
  @project Path.join(@root, ".planning/PROJECT.md")
  @arc Path.join(@root, ".planning/MILESTONE-ARC.md")
  @state Path.join(@root, ".planning/STATE.md")
  @closeout Path.join(@root, ".planning/milestones/v3.6-CLOSEOUT.md")

  @queue_order [
    "v3.8 Full Sigra Auth and Session Machinery",
    "v3.9 Chimeway Notification Seam",
    "v4.0 Production Shell Runtime Line",
    "v4.1 Multi-SaaS Archetype Proof Lanes",
    "Threadline Audit Capstone"
  ]

  test "v3.6 roadmap and requirements snapshots are archived before live reset" do
    assert File.exists?(@archive_roadmap)
    assert File.exists?(@archive_requirements)

    assert File.read!(@archive_roadmap) =~ "v3.6 Operator Truth and Production Diagnostics"
    assert File.read!(@archive_requirements) =~ "REL-01"
  end

  test "live planning surfaces no longer leave v3.6 active or unfinished" do
    roadmap = File.read!(@roadmap)
    requirements = File.read!(@requirements)
    project = File.read!(@project)
    state = File.read!(@state)
    closeout = File.read!(@closeout)

    assert roadmap =~ "v3.6 Operator Truth and Production Diagnostics"
    assert roadmap =~ "Phases 48-53 shipped"
    assert File.read!(@archive_requirements) =~ "**REL-01**"
    assert requirements =~ "**Milestone:** v3.8 Full Sigra Auth and Session Machinery"
    assert project =~ "Shipped `v3.6 Operator Truth and Production Diagnostics`"
    assert state =~ "milestone: v3.8"
    assert state =~ "Status: Phase complete"
    assert closeout =~ "status: complete"

    refute roadmap =~ "Phase 53: Release Continuity and Closeout Hardening — align"
    refute requirements =~ "REL-01 | Phase 53 | Pending"
    refute project =~ "## Current Milestone: v3.6 Operator Truth and Production Diagnostics"
  end

  test "strategic queue order is preserved exactly across project and arc surfaces" do
    arc = File.read!(@arc)
    project = File.read!(@project)

    assert_in_order(arc, @queue_order)
    assert_in_order(project, @queue_order)

    assert arc =~ "### Active: v3.8 Full Sigra Auth and Session Machinery"
    assert project =~ "The strategic source of truth remains `.planning/MILESTONE-ARC.md`"
    assert project =~ "not a second queue"
  end

  test "state and roadmap route the next operator step to active v3.8 work" do
    roadmap = File.read!(@roadmap)
    state = File.read!(@state)

    assert roadmap =~ "v3.8 Full Sigra Auth and Session Machinery"
    assert state =~ "Completed Phase 57 auth-return boundaries"
    refute roadmap =~ ".continue-here.md"
    refute state =~ ".continue-here.md"
  end

  defp assert_in_order(content, ordered_terms) do
    positions =
      Enum.map(ordered_terms, fn term ->
        case :binary.match(content, term) do
          {index, _length} -> index
          :nomatch -> flunk("missing queue term #{inspect(term)}")
        end
      end)

    assert positions == Enum.sort(positions),
           "queue terms are out of order: #{inspect(ordered_terms)}"
  end
end
