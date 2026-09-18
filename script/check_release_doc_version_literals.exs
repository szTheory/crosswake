#!/usr/bin/env elixir
# exit contract: 0 clean / 1 defect found / 3 could not verify

# This check exists because of one specific, already-happened incident, not a
# hypothetical one.
#
# `docs/COMPANION-PUBLISH-RUNBOOK.md` once carried a section titled "Before
# releasing any version other than 0.2.1," bolded **STOP — this pipeline
# currently publishes exactly one version.** That sentence was TRUE the day it
# was written: `publish-hex`, `publish-ios-core`, `publish-android-core`, and
# `exact-public-proof` really were each gated on a literal
# `needs.release-please.outputs.version == '0.2.1'`. TODO-009 later replaced
# that literal comparison with `needs.release-please.outputs.version ==
# needs.approved-release-guard.outputs.approved_version` — a dynamic,
# per-release binding — and the condition the sentence described stopped
# existing. The sentence did not. It survived, unread as false, until Phase
# 175 (DOC-04) deleted it by hand.
#
# A version literal written into runbook prose is not wrong when it is
# written. It is a ticking claim: true exactly until the next release, then
# permanently false, with nothing in the toolchain that notices. This script
# is the structural fix for the "nothing noticed" half of that failure. It
# does not, by itself, prevent someone from writing a NEW version-bound claim
# that isn't a bare X.Y.Z literal (a claim like "0.2.x" or a range) — see the
# `bare_version_literals/1` doc for exactly what pattern this catches and why
# that is a deliberate scope boundary, not an oversight.

defmodule Crosswake.ReleaseDocVersionLiterals do
  @moduledoc false

  # DECLARED, NEVER DERIVED.
  #
  # This is the scope selector for both checks below. It is a literal
  # constant on purpose, for the same reason `check_release_workflow_integrity.exs`'s
  # `@proof_lanes` is one: a roster computed by scanning `docs/` for "files
  # that look release-related" would silently shrink the day someone renames
  # or moves one of these two files, and this check would then report green
  # about a smaller claim than the one it exists to make ("the release docs
  # make no version-specific claims"). Widening this list to cover a third
  # document is a deliberate edit to this constant, reviewed like any other
  # change to what this check asserts — never a scan result.
  #
  # `docs/RELEASE-INCIDENT-RESPONSE.md` is in scope even though this plan
  # (175-05) did not author its content — 175-04 did, and DOC-19 requires it
  # never to accumulate a version-specific claim either.
  @rostered_files [
    "docs/COMPANION-PUBLISH-RUNBOOK.md",
    "docs/RELEASE-INCIDENT-RESPONSE.md"
  ]

  @invariant_sentence "This document makes no version-specific claims."

  def default_roster, do: @rostered_files

  # A rostered file that is missing is NOT the same finding as a rostered file
  # that is clean. A missing file exits 3 (could not verify) rather than
  # silently passing over zero content — the roster names two paths on
  # purpose, and a document renamed out from under this check must not read
  # as "no version literals found."
  def run(roster) do
    case missing_files(roster) do
      [] ->
        findings = bare_version_literals(roster) ++ invariant_marker_present(roster)
        report(findings)

      missing ->
        Enum.each(missing, fn path ->
          IO.puts("[crosswake] BLOCKED: rostered file is missing: #{path}")
        end)

        IO.puts(
          "[crosswake] BLOCKED: #{length(missing)} rostered file(s) could not be read; the roster is declared, never narrowed to compensate."
        )

        3
    end
  end

  defp report([]) do
    IO.puts("[crosswake] OK: no bare version literal appears outside a code fence in any rostered document.")
    IO.puts("[crosswake] OK: every rostered document states the no-version-specific-claims invariant.")
    0
  end

  defp report(findings) do
    Enum.each(findings, fn {id, where, detail} ->
      IO.puts("[crosswake] FAIL: #{id}")
      IO.puts("[crosswake]   where: #{where}")
      IO.puts("[crosswake]   what:  #{detail}")
      IO.puts("")
    end)

    IO.puts("[crosswake] FAIL: #{length(findings)} version-literal finding(s) in release documentation.")
    1
  end

  defp missing_files(roster), do: Enum.reject(roster, &File.exists?/1)

  # ── Check 1: a bare three-component version literal outside a code fence ──
  #
  # Matches `X.Y.Z` (each component one or more digits) anywhere prose is not
  # inside a fenced block. Deliberately narrow to three-component literals,
  # mirroring D-19's own wording ("bare version literals (`0\.\d+\.\d+`)") —
  # a two-component constraint like `~> 0.2` is a floor requirement that
  # stays true across many releases, not a claim bound to one release, and is
  # explicitly out of scope per the plan's action.
  defp bare_version_literals(roster) do
    Enum.flat_map(roster, fn path ->
      path
      |> File.read!()
      |> strip_fences()
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {line, line_number} ->
        ~r/\b\d+\.\d+\.\d+\b/
        |> Regex.scan(line)
        |> Enum.map(fn _match ->
          {"doc.version_literals.no_bare_literal_outside_fence", "#{path}:#{line_number}",
           "bare version literal outside a code fence: #{String.trim(line)}"}
        end)
      end)
    end)
  end

  # ── Check 2: the invariant marker must be present ──
  #
  # This is the half that keeps the first check from being satisfiable by
  # deleting all prose. A document with zero version literals AND no
  # invariant sentence has not demonstrated it makes no version-specific
  # claims; it has merely gone quiet. Only an exact, byte-identical sentence
  # counts — a paraphrase is not verifiable by grep and would let the two
  # release documents drift on wording.
  defp invariant_marker_present(roster) do
    Enum.flat_map(roster, fn path ->
      contents = File.read!(path)

      if String.contains?(contents, @invariant_sentence) do
        []
      else
        [
          {"doc.version_literals.invariant_marker_present", path,
           "missing the required sentence: #{@invariant_sentence}"}
        ]
      end
    end)
  end

  # Replace fenced-code lines with an empty string, tracking open/closed state
  # across lines that begin with three backticks — a command example inside a
  # ```bash ... ``` block is a reproduction, not a claim this document is
  # making about the current release.
  defp strip_fences(contents) do
    {stripped, _} =
      contents
      |> String.split("\n")
      |> Enum.map_reduce(false, fn line, inside? ->
        fence? = line |> String.trim_leading() |> String.starts_with?("```")

        cond do
          fence? -> {"", not inside?}
          inside? -> {"", inside?}
          true -> {line, inside?}
        end
      end)

    stripped
  end
end

# CLI: no argument uses the declared, never-derived roster above. `--roster`
# accepts a comma-separated list that NARROWS the roster for this run only —
# it exists so the fail-first demonstration in 175-05's evidence log can point
# the check at a scratch copy without ever touching the real documents, and it
# is never how the roster is widened or shrunk for real use. Narrowing the
# DEFAULT (removing a rostered file from the constant above) is the exact
# regression this check exists to make impossible; this flag cannot do that,
# because it only ever affects the one invocation that passes it.
roster =
  case System.argv() do
    ["--roster", paths] -> String.split(paths, ",")
    _ -> Crosswake.ReleaseDocVersionLiterals.default_roster()
  end

System.halt(Crosswake.ReleaseDocVersionLiterals.run(roster))
