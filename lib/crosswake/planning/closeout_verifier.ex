defmodule Crosswake.Planning.CloseoutVerifier do
  @moduledoc """
  Deterministic closeout checks for milestone planning artifacts.

  This module validates artifact presence, frontmatter shape, traceability, and
  release-claim boundaries. It intentionally does not judge editorial quality.
  """

  @schema_version "1.0.0"
  @required_closeout_keys ~w(
    milestone
    milestone_name
    status
    shipped_date
    requirements_state
    roadmap_parity
    phase_verification_coverage
    summary_frontmatter_coverage
    validation_ledger_status
    thread_seed_disposition
    release_changelog_continuity
    public_support_claim_changes
    deferred_with_reason
    exceptions
    resolved_gaps
  )
  @exception_fields ~w(owner scope reason revisit_phase evidence status)
  @v36_phases ~w(48 49 50 51 52 53)
  @unreleased_sections [
    "Unpublished support claims",
    "Verification-required and advisory surfaces",
    "Deferred non-shipped claims",
    "Published Hex truth"
  ]
  @phase58_security_sections [
    "## Token And Locator Handling",
    "## Handoff Tickets",
    "## Step-Up Ceremony",
    "## Auth Return Boundaries",
    "## Telemetry And Diagnostics",
    "## Denial Sanitization",
    "## Session Renewal And LiveView Invalidation",
    "## Doctor Support Operator And Docs Truth",
    "## Proof And Non-Claims",
    "## Findings Disposition"
  ]
  @phase58_security_table_columns [
    "Surface",
    "STRIDE",
    "Adversarial scenario",
    "Control",
    "Evidence",
    "Residual risk",
    "Disposition"
  ]
  @phase58_security_required_phrases [
    "SessionAuthorityLane",
    "diagnostic evidence only",
    "provider/device proof remains advisory",
    "direct shell/WebView token authority"
  ]

  defmodule Report do
    @moduledoc false
    @enforce_keys [:schema_version, :status, :summary, :checks]
    defstruct [:schema_version, :status, :summary, :checks]
  end

  defmodule Check do
    @moduledoc false
    @enforce_keys [
      :id,
      :subject,
      :source,
      :result,
      :blocking,
      :observed,
      :hint,
      :posture,
      :details
    ]
    defstruct [:id, :subject, :source, :result, :blocking, :observed, :hint, :posture, :details]
  end

  @spec run(keyword()) :: Report.t()
  def run(opts \\ []) do
    cwd = Keyword.get(opts, :cwd, File.cwd!())

    checks =
      if Keyword.get(opts, :security_only?) == true do
        []
      else
        [
          closeout_frontmatter_check(cwd, opts),
          deferred_shape_check(cwd, opts),
          release_continuity_check(cwd, opts),
          requirements_state_check(cwd, opts),
          roadmap_state_check(cwd, opts),
          phase_verification_check(cwd, opts),
          summary_frontmatter_check(cwd, opts),
          validation_ledger_check(cwd, opts),
          thread_seed_disposition_check(cwd, opts)
        ]
      end
      |> maybe_security_closeout_check(cwd, opts)

    status = if Enum.any?(checks, & &1.blocking), do: :failed, else: :passed

    %Report{
      schema_version: @schema_version,
      status: status,
      summary: %{
        total_count: length(checks),
        blocking_count: Enum.count(checks, & &1.blocking),
        passed_count: Enum.count(checks, &(&1.result == :pass))
      },
      checks: checks
    }
  end

  @spec render(Report.t()) :: String.t()
  def render(%Report{} = report) do
    header = "closeout.verify #{report.status} (#{report.summary.blocking_count} blocking)"

    lines =
      Enum.map(report.checks, fn check ->
        marker = if check.blocking, do: "BLOCK", else: "PASS"

        "[#{marker}] #{check.id} subject=#{check.subject} source=#{check.source} " <>
          "observed=#{check.observed} hint=#{check.hint} posture=#{check.posture}"
      end)

    Enum.join([header | lines], "\n")
  end

  defp closeout_frontmatter_check(cwd, opts) do
    path = closeout_path(cwd, opts)
    content = read_file(path)
    frontmatter = parse_frontmatter(content)

    missing =
      if frontmatter == "" do
        @required_closeout_keys
      else
        Enum.reject(
          @required_closeout_keys,
          &Regex.match?(~r/^#{Regex.escape(&1)}:/m, frontmatter)
        )
      end

    check(
      "closeout.ledger.frontmatter",
      "closeout ledger frontmatter",
      rel(cwd, path),
      missing == [],
      "missing keys: #{Enum.join(missing, ", ")}",
      "Preserve the v3.6-CLOSEOUT.md frontmatter contract before closeout.",
      %{missing: missing}
    )
  end

  defp deferred_shape_check(cwd, opts) do
    path = closeout_path(cwd, opts)
    content = read_file(path)
    frontmatter = parse_frontmatter(content)
    malformed = malformed_deferred_entries(frontmatter)

    check(
      "closeout.exceptions.deferred_shape",
      "deferred_with_reason exception shape",
      rel(cwd, path),
      malformed == [],
      "malformed deferred entries: #{Enum.join(malformed, ", ")}",
      "Every deferred exception needs owner, scope, reason, revisit_phase, evidence, and status.",
      %{malformed: malformed}
    )
  end

  defp release_continuity_check(cwd, opts) do
    path = Keyword.get(opts, :changelog_path, Path.join(cwd, "CHANGELOG.md"))
    content = read_file(path)
    unreleased = section(content, "## [Unreleased]", ~r/^## \[/m)

    missing =
      Enum.reject(@unreleased_sections, fn heading ->
        unreleased =~ "### #{heading}"
      end)

    false_claims =
      for claim <- [
            "StoreKit provider adapter shipped",
            "Play Billing provider adapter shipped",
            "Chimeway delivery is supported",
            "standalone native shell packages are shipped"
          ],
          content =~ claim,
          do: claim

    passed =
      content =~ "## [0.1.0]" and content =~ "published Hex release" and
        content =~ "planning milestones" and missing == [] and false_claims == []

    check(
      "closeout.release.changelog_continuity",
      "published versus unreleased release truth",
      rel(cwd, path),
      passed,
      "missing sections: #{Enum.join(missing, ", ")}; false claims: #{Enum.join(false_claims, ", ")}",
      "Keep [Unreleased] split from published Hex 0.1.0 and label deferred support as non-shipped.",
      %{missing_sections: missing, false_claims: false_claims}
    )
  end

  defp requirements_state_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))
    requirements = read_file(Path.join(cwd, ".planning/REQUIREMENTS.md"))

    passed =
      closeout =~ ~r/requirements_state:\s*\n\s*status:\s*(complete|archived)/ and
        requirements =~ "REL-01" and
        not Regex.match?(~r/\|\s*REL-01\s*\|\s*Phase 53\s*\|\s*Pending\s*\|/, requirements)

    check(
      "closeout.requirements.state",
      "requirements closeout state",
      ".planning/REQUIREMENTS.md",
      passed,
      "REL-01 or closeout requirements_state is still pending",
      "Mark REL-01 validated or archive/reset requirements with explicit closeout evidence.",
      %{}
    )
  end

  defp roadmap_state_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))
    roadmap = read_file(Path.join(cwd, ".planning/ROADMAP.md"))

    passed =
      closeout =~ ~r/roadmap_parity:\s*\n\s*status:\s*(complete|archived)/ and
        roadmap =~ "$gsd-discuss-phase 48" and
        not (roadmap =~ "Phase 53: Release Continuity and Closeout Hardening — align")

    check(
      "closeout.roadmap.parity",
      "roadmap closeout parity",
      ".planning/ROADMAP.md",
      passed,
      "v3.6 roadmap parity or next-step routing is stale",
      "Archive v3.6 roadmap evidence and route the live roadmap to $gsd-discuss-phase 48.",
      %{}
    )
  end

  defp phase_verification_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))

    missing =
      Enum.reject(@v36_phases, fn phase ->
        Path.wildcard(Path.join(cwd, ".planning/phases/#{phase}-*/*-VERIFICATION.md")) != []
      end)

    passed =
      closeout =~
        ~r/phase_verification_coverage:\s*\n\s*status:\s*(complete|deferred_with_reason|archived)/ and
        (missing == [] or closeout =~ "phase-verification-finalization")

    check(
      "closeout.verification.coverage",
      "phase verification evidence",
      ".planning/phases",
      passed,
      "missing verification for phases: #{Enum.join(missing, ", ")}",
      "Add phase verification files or record a shaped deferred_with_reason exception.",
      %{missing: missing}
    )
  end

  defp summary_frontmatter_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))

    summary_paths =
      Path.wildcard(Path.join(cwd, ".planning/phases/{48,49,50,51,52,53}-*/*-SUMMARY.md"))

    malformed =
      Enum.reject(summary_paths, fn path ->
        parse_frontmatter(read_file(path)) =~
          ~r/^requirements-completed:[ \t]*(?:\[|\r?\n[ \t]+-)/m
      end)

    passed =
      closeout =~ ~r/summary_frontmatter_coverage:\s*\n\s*status:\s*(complete|archived)/ and
        malformed == []

    check(
      "closeout.summaries.frontmatter",
      "summary requirements-completed frontmatter",
      ".planning/phases",
      passed,
      "malformed summaries: #{Enum.map_join(malformed, ", ", &rel(cwd, &1))}",
      "Ensure every v3.6 SUMMARY.md has requirements-completed frontmatter.",
      %{malformed: Enum.map(malformed, &rel(cwd, &1))}
    )
  end

  defp validation_ledger_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))

    validation_paths =
      Path.wildcard(Path.join(cwd, ".planning/phases/{48,49,50,51,52,53}-*/*-VALIDATION.md"))

    problematic =
      Enum.reject(validation_paths, fn path ->
        content = read_file(path)
        content =~ "nyquist_compliant: true" or content =~ "deferred_with_reason"
      end)

    passed =
      closeout =~
        ~r/validation_ledger_status:\s*\n\s*status:\s*(complete|deferred_with_reason|archived)/ and
        (problematic == [] or closeout =~ "validation-ledger-finalization")

    check(
      "closeout.validation.ledger",
      "validation ledger status",
      ".planning/phases",
      passed,
      "non-compliant validation ledgers: #{Enum.map_join(problematic, ", ", &rel(cwd, &1))}",
      "Mark validation ledgers Nyquist-compliant or defer them with owner/scope/reason evidence.",
      %{problematic: Enum.map(problematic, &rel(cwd, &1))}
    )
  end

  defp thread_seed_disposition_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))
    passed = closeout =~ ~r/thread_seed_disposition:\s*\n\s*status:\s*(complete|routed|archived)/

    check(
      "closeout.handoff.thread_seed_disposition",
      "thread and seed disposition",
      ".planning/threads,.planning/seeds",
      passed,
      "thread_seed_disposition is still pending",
      "Route open threads/seeds to future milestone ownership or mark shipped signals closed.",
      %{}
    )
  end

  defp maybe_security_closeout_check(checks, _cwd, opts) do
    case Keyword.get(opts, :security_closeout_path) do
      nil -> checks
      "" -> checks
      _path -> checks ++ [security_closeout_check(opts)]
    end
  end

  defp security_closeout_check(opts) do
    path = Keyword.fetch!(opts, :security_closeout_path)
    content = read_file(path)

    missing_sections = Enum.reject(@phase58_security_sections, &String.contains?(content, &1))
    missing_table_sections = missing_security_table_sections(content, missing_sections)

    missing_phrases =
      Enum.reject(@phase58_security_required_phrases, &String.contains?(content, &1))

    unresolved = unresolved_security_rows(content)

    passed =
      not String.starts_with?(content, "FILE_READ_ERROR") and missing_sections == [] and
        missing_table_sections == [] and missing_phrases == [] and unresolved == []

    check(
      "closeout.security.phase58",
      "Phase 58 Sigra security closeout",
      path,
      passed,
      "missing sections: #{Enum.join(missing_sections, ", ")}; missing table sections: #{Enum.join(missing_table_sections, ", ")}; missing phrases: #{Enum.join(missing_phrases, ", ")}; unresolved high/critical findings: #{length(unresolved)}",
      "Add bounded STRIDE ledger tables for Sigra auth surfaces and close or mitigate every Critical/High finding.",
      %{
        missing_sections: missing_sections,
        missing_table_sections: missing_table_sections,
        missing_phrases: missing_phrases,
        unresolved: unresolved
      }
    )
  end

  defp missing_security_table_sections(content, missing_sections) do
    @phase58_security_sections
    |> Enum.reject(&(&1 in missing_sections))
    |> Enum.reject(fn section ->
      section_body(content, section) |> security_table_header?()
    end)
  end

  defp section_body(content, section) do
    [_before, rest] = String.split(content, section, parts: 2)

    case Regex.split(~r/\n## /, rest, parts: 2) do
      [body] -> body
      [body, _next] -> body
    end
  end

  defp security_table_header?(section_body) do
    Enum.any?(String.split(section_body, "\n"), fn line ->
      Enum.all?(@phase58_security_table_columns, &String.contains?(line, &1))
    end)
  end

  defp unresolved_security_rows(content) do
    content
    |> String.split("\n")
    |> Enum.filter(&String.starts_with?(&1, "|"))
    |> Enum.reject(&String.contains?(&1, "---"))
    |> Enum.filter(fn row ->
      cells =
        row
        |> String.trim("|")
        |> String.split("|")
        |> Enum.map(&String.trim/1)

      severity? = Enum.any?(cells, &Regex.match?(~r/\b(Critical|High)\b/i, &1))
      disposition = List.last(cells) || ""

      severity? and not Regex.match?(~r/^(Closed|Mitigated)$/i, disposition)
    end)
  end

  defp check(id, subject, source, passed?, observed, hint, details) do
    %Check{
      id: id,
      subject: subject,
      source: source,
      result: if(passed?, do: :pass, else: :fail),
      blocking: not passed?,
      observed: if(passed?, do: "ok", else: observed),
      hint: hint,
      posture: "merge-blocking",
      details: details
    }
  end

  defp closeout_path(cwd, opts) do
    Keyword.get(opts, :closeout_path, Path.join(cwd, ".planning/milestones/v3.6-CLOSEOUT.md"))
  end

  defp read_file(path) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, reason} -> "FILE_READ_ERROR: #{inspect(reason)}"
    end
  end

  defp parse_frontmatter(content) do
    case Regex.run(~r/\A---\r?\n(.*?)\r?\n---\r?\n/ms, content, capture: :all_but_first) do
      [frontmatter] -> frontmatter
      nil -> ""
    end
  end

  defp malformed_deferred_entries(frontmatter) do
    case Regex.run(~r/^deferred_with_reason:\s*\n((?:\s+-.*\n(?:\s{4,}.+\n?)*)*)/m, frontmatter,
           capture: :all_but_first
         ) do
      [block] ->
        if String.trim(block) == "" do
          []
        else
          ~r/^\s*-\s+(.*?)(?=^\s*-\s+|\z)/ms
          |> Regex.scan(block, capture: :all_but_first)
          |> Enum.map(fn [entry] -> entry end)
          |> Enum.with_index(1)
          |> Enum.flat_map(fn {entry, index} ->
            missing = Enum.reject(@exception_fields, &Regex.match?(~r/(^|\n)\s*#{&1}:/, entry))
            if missing == [], do: [], else: ["entry #{index} missing #{Enum.join(missing, "/")}"]
          end)
        end

      _ ->
        []
    end
  end

  defp section(content, heading, next_heading_regex) do
    case :binary.match(content, heading) do
      {start, _len} ->
        rest = binary_part(content, start, byte_size(content) - start)

        case Regex.run(next_heading_regex, String.replace_prefix(rest, heading, ""),
               return: :index
             ) do
          [{next_start, _}] -> binary_part(rest, 0, byte_size(heading) + next_start)
          nil -> rest
        end

      :nomatch ->
        ""
    end
  end

  defp rel(cwd, path), do: Path.relative_to(path, cwd)
end
