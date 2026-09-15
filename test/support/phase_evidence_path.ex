defmodule Crosswake.Test.PhaseEvidencePath do
  @moduledoc """
  Resolves a phase-evidence path whether its phase directory is still live or has
  been archived by a milestone close.

  `/gsd-complete-milestone` MOVES every phase directory from
  `.planning/workstreams/<ws>/phases/<phase>` to
  `.planning/workstreams/<ws>/milestones/<version>-phases/<phase>`. Proof tests that
  hardcode the live path therefore pass for the whole life of a milestone and then
  break, all at once, the moment that milestone ships — at exactly the point where
  a red CI is least informative and most likely to be waved through.

  This resolver checks the live location first and falls back to any archived one,
  so the same literal phase-relative path keeps resolving across the archival
  boundary.

  It deliberately does NOT invent a path when neither exists: it returns the live
  path, so the caller fails with a missing-file error naming the location a reader
  would expect. Silently resolving to nothing would convert "the evidence is gone"
  into "the check found nothing to check", which is the failure shape this
  repository has already been bitten by more than once — see the v22.0
  retrospective on absence being scored as success.
  """

  @workstreams ".planning/workstreams"

  @doc """
  Resolve `phase_relative` (e.g. `"165-efficient-and-maintainable-ci/evidence/baseline.json"`)
  within `workstream`, preferring the live phases directory over an archived one.
  """
  @spec resolve(String.t(), String.t()) :: String.t()
  def resolve(workstream, phase_relative) do
    live = Path.join([@workstreams, workstream, "phases", phase_relative])

    if File.exists?(live) do
      live
    else
      archived(workstream, phase_relative) || live
    end
  end

  defp archived(workstream, phase_relative) do
    [@workstreams, workstream, "milestones", "*-phases", phase_relative]
    |> Path.join()
    |> Path.wildcard()
    # Newest milestone last by name, and a phase directory is only ever archived
    # once, so any match is the match; sorting just keeps the choice deterministic
    # if a repository ever carries two archives of the same phase.
    |> Enum.sort()
    |> List.last()
  end
end
