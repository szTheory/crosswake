defmodule Crosswake.Planning.MilestoneTransitionResetTest do
  use ExUnit.Case, async: true

  # This suite protects the milestone-transition reset invariant: the live
  # operational planning surfaces (STATE/REQUIREMENTS/ROADMAP/PROJECT) and the
  # .planning/milestones/ archive must stay consistent with the milestone named
  # in STATE.md frontmatter.
  #
  # The milestone is derived from STATE.md frontmatter — the operational source
  # of truth GSD rewrites on every transition — instead of being hardcoded to
  # whichever milestone happened to be active when the test was written.
  #
  # The project has two legitimate committed states, distinguished by whether a
  # live .planning/REQUIREMENTS.md exists (see between_milestones?/0):
  #
  #   • ACTIVE (mid-flight): a live REQUIREMENTS.md exists and names the active
  #     milestone, ROADMAP/PROJECT name it as the current milestone, and its
  #     snapshot is NOT yet archived.
  #   • SHIPPED (between /gsd:complete-milestone and /gsd:new-milestone):
  #     complete-milestone archives the snapshot and `git rm`s REQUIREMENTS.md,
  #     leaving STATE still naming the just-shipped milestone with status set to
  #     complete. Here the snapshot MUST be archived and REQUIREMENTS.md MUST be
  #     absent — the inverse of the active state.
  #
  # Asserting the right invariant per state keeps this meaningful across
  # rollovers without breaking on the legitimate between-milestones checkpoint.

  @root File.cwd!()
  @roadmap Path.join(@root, ".planning/ROADMAP.md")
  @requirements Path.join(@root, ".planning/REQUIREMENTS.md")
  @project Path.join(@root, ".planning/PROJECT.md")
  @state Path.join(@root, ".planning/STATE.md")
  @milestones_dir Path.join(@root, ".planning/milestones")

  test "live operational surfaces all name the milestone from STATE frontmatter" do
    {version, name} = active_milestone()
    label = "#{version} #{name}"

    assert File.read!(@roadmap) =~ label,
           "ROADMAP.md does not name the milestone #{inspect(label)}"

    assert File.read!(@project) =~ label,
           "PROJECT.md does not name the milestone #{inspect(label)}"

    assert File.read!(@state) =~ name,
           "STATE.md body does not reference the milestone name #{inspect(name)}"

    if between_milestones?() do
      # SHIPPED state: complete-milestone removed the live REQUIREMENTS.md.
      # PROJECT.md must no longer advertise it as the current (in-progress)
      # milestone — it is shipped, not active.
      refute File.read!(@project) =~ "## Current Milestone: #{label}",
             "PROJECT.md still names shipped milestone #{inspect(label)} as the current milestone"
    else
      # ACTIVE state: the live REQUIREMENTS.md and PROJECT current-milestone
      # header must name the active milestone.
      assert File.read!(@requirements) =~ label,
             "REQUIREMENTS.md header does not name the active milestone #{inspect(label)}"

      assert File.read!(@project) =~ "## Current Milestone: #{label}",
             "PROJECT.md `## Current Milestone` is not #{inspect(label)}"
    end
  end

  test "milestone archive presence matches active/shipped state" do
    {version, _name} = active_milestone()
    archived_requirements = Path.join(@milestones_dir, "#{version}-REQUIREMENTS.md")
    archived_roadmap = Path.join(@milestones_dir, "#{version}-ROADMAP.md")

    if between_milestones?() do
      # SHIPPED: the just-shipped milestone's snapshot must be archived.
      assert File.exists?(archived_requirements),
             "shipped milestone #{version} is missing its archived REQUIREMENTS snapshot"

      assert File.exists?(archived_roadmap),
             "shipped milestone #{version} is missing its archived ROADMAP snapshot"
    else
      # ACTIVE: the in-progress milestone must not be archived yet.
      refute File.exists?(archived_requirements),
             "active milestone #{version} should not have an archived REQUIREMENTS snapshot yet"

      refute File.exists?(archived_roadmap),
             "active milestone #{version} should not have an archived ROADMAP snapshot yet"
    end
  end

  test "the most recently shipped milestone was archived during transition" do
    prior = previously_shipped_milestone()

    assert File.exists?(Path.join(@milestones_dir, "#{prior}-ROADMAP.md")),
           "prior milestone #{prior} is missing its archived ROADMAP snapshot"

    assert File.exists?(Path.join(@milestones_dir, "#{prior}-REQUIREMENTS.md")),
           "prior milestone #{prior} is missing its archived REQUIREMENTS snapshot"
  end

  test "no resumed-work breadcrumb leaks into shared planning surfaces" do
    refute File.read!(@roadmap) =~ ".continue-here.md"
    refute File.read!(@state) =~ ".continue-here.md"
  end

  test "v3.8 milestone archive remains intact" do
    # Concrete historical anchor — permanently true once v3.8 shipped. Guards
    # against accidental deletion or corruption of an archived snapshot.
    archive_roadmap = Path.join(@milestones_dir, "v3.8-ROADMAP.md")
    archive_requirements = Path.join(@milestones_dir, "v3.8-REQUIREMENTS.md")
    archive_audit = Path.join(@milestones_dir, "v3.8-MILESTONE-AUDIT.md")

    assert File.exists?(archive_roadmap)
    assert File.exists?(archive_requirements)
    assert File.exists?(archive_audit)

    assert File.read!(archive_roadmap) =~ "v3.8 Full Sigra Auth and Session Machinery"
    assert File.read!(archive_requirements) =~ "HAND-01"

    audit = File.read!(archive_audit)
    assert audit =~ "milestone: v3.8"
    assert audit =~ "requirements: 16/16"
  end

  # True when the project sits between milestones: /gsd:complete-milestone has
  # archived the snapshot and removed the live REQUIREMENTS.md, and the next
  # milestone has not been started yet. REQUIREMENTS.md presence is the direct
  # operational signal — complete-milestone `git rm`s it, new-milestone recreates
  # it — so it distinguishes the two legitimate committed states.
  defp between_milestones?, do: not File.exists?(@requirements)

  # The operational active milestone, read from STATE.md frontmatter
  # (`milestone:` version + `milestone_name:`), e.g. {"v4.0", "Production Shell
  # Runtime Line"}.
  defp active_milestone do
    state = File.read!(@state)
    version = capture!(state, ~r/^milestone:\s*(\S+)\s*$/m, "milestone")
    name = capture!(state, ~r/^milestone_name:\s*(.+?)\s*$/m, "milestone_name")
    {version, name}
  end

  # The last ✅-shipped milestone in ROADMAP.md's `## Milestones` list — the one
  # the active milestone transitioned away from. Matches only the bold
  # `✅ **vX.Y …` list entries (not the collapsible `<summary>✅ vX.Y …`
  # detail blocks), which appear in chronological order.
  defp previously_shipped_milestone do
    shipped =
      @roadmap
      |> File.read!()
      |> then(&Regex.scan(~r/✅\s+\*\*(v\d+\.\d+)\b/u, &1))
      |> Enum.map(fn [_, v] -> v end)

    case List.last(shipped) do
      nil -> flunk("expected at least one ✅-shipped milestone in ROADMAP.md")
      version -> version
    end
  end

  defp capture!(content, regex, field) do
    case Regex.run(regex, content) do
      [_, value] -> String.trim(value)
      _ -> flunk("could not read `#{field}` from STATE.md frontmatter")
    end
  end
end
