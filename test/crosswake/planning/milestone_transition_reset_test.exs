defmodule Crosswake.Planning.MilestoneTransitionResetTest do
  use ExUnit.Case, async: true

  @root File.cwd!()
  @archive_roadmap Path.join(@root, ".planning/milestones/v3.8-ROADMAP.md")
  @archive_requirements Path.join(@root, ".planning/milestones/v3.8-REQUIREMENTS.md")
  @archive_audit Path.join(@root, ".planning/milestones/v3.8-MILESTONE-AUDIT.md")
  @roadmap Path.join(@root, ".planning/ROADMAP.md")
  @requirements Path.join(@root, ".planning/REQUIREMENTS.md")
  @project Path.join(@root, ".planning/PROJECT.md")
  @arc Path.join(@root, ".planning/MILESTONE-ARC.md")
  @state Path.join(@root, ".planning/STATE.md")

  @queue_order [
    "v3.9 Chimeway Notification Seam",
    "v4.0 Production Shell Runtime Line",
    "v4.1 Multi-SaaS Archetype Proof Lanes",
    "Threadline Audit Capstone"
  ]

  test "v3.8 roadmap, requirements, and audit snapshots are archived before live reset" do
    assert File.exists?(@archive_roadmap)
    assert File.exists?(@archive_requirements)
    assert File.exists?(@archive_audit)

    assert File.read!(@archive_roadmap) =~ "v3.8 Full Sigra Auth and Session Machinery"
    assert File.read!(@archive_requirements) =~ "HAND-01"

    audit = File.read!(@archive_audit)
    assert audit =~ "milestone: v3.8"
    assert audit =~ "requirements: 16/16"
  end

  test "live planning surfaces no longer leave v3.8 active or unfinished" do
    roadmap = File.read!(@roadmap)
    requirements = File.read!(@requirements)
    project = File.read!(@project)
    state = File.read!(@state)

    assert roadmap =~ "v3.8 Full Sigra Auth and Session Machinery"
    assert roadmap =~ "Phases 54-58 shipped"
    assert File.read!(@archive_requirements) =~ "**HAND-01**"
    assert requirements =~ "**Milestone:** v3.9 Chimeway Notification Seam"
    assert project =~ "Shipped `v3.8 Full Sigra Auth and Session Machinery`"
    assert state =~ "milestone: v3.9"

    refute requirements =~ "**Milestone:** v3.8 Full Sigra Auth and Session Machinery"
    refute project =~ "## Current Milestone: v3.8 Full Sigra Auth and Session Machinery"
  end

  test "strategic queue order is preserved exactly across project and arc surfaces" do
    arc = File.read!(@arc)
    project = File.read!(@project)

    assert_in_order(arc, @queue_order)
    assert_in_order(project, @queue_order)

    assert arc =~ "### Active: v3.9 Chimeway Notification Seam"
    assert project =~ "The strategic source of truth remains `.planning/MILESTONE-ARC.md`"
    assert project =~ "not a second queue"
  end

  test "state and roadmap route the next operator step to active v3.9 work" do
    roadmap = File.read!(@roadmap)
    state = File.read!(@state)

    assert roadmap =~ "v3.9 Chimeway Notification Seam"
    assert state =~ "Chimeway Notification Seam"
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
