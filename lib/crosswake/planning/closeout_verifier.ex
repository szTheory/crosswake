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
  @v39_phases ~w(59 60 61 62 63)
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
          prior_validation_debt_check(cwd, opts),
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
      "Preserve the v3.9-CLOSEOUT.md frontmatter contract before closeout.",
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
    requirements = requirements_source(cwd, milestone(parse_frontmatter(closeout)))

    passed =
      closeout =~ ~r/requirements_state:\s*\n\s*status:\s*(complete|archived)/ and
        requirements =~ "REL-01" and
        not Regex.match?(~r/\|\s*REL-01\s*\|\s*Phase 63\s*\|\s*Pending\s*\|/, requirements)

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
        not (roadmap =~ "Phase 63: Hermetic Proof And Advisory Promotion Criteria — align")

    check(
      "closeout.roadmap.parity",
      "roadmap closeout parity",
      ".planning/ROADMAP.md",
      passed,
      "v3.9 roadmap parity or next-step routing is stale",
      "Archive v3.9 roadmap evidence and complete Phase 63 alignment.",
      %{}
    )
  end

  defp phase_verification_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))
    fm = parse_frontmatter(closeout)
    ms = milestone(fm)
    phases = expected_phases(fm)

    missing =
      Enum.reject(phases, fn phase ->
        phase_paths(cwd, ms, phase, "*-VERIFICATION.md") != []
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
    fm = parse_frontmatter(closeout)
    ms = milestone(fm)
    phases = expected_phases(fm)

    summary_paths =
      Enum.flat_map(phases, fn phase ->
        phase_paths(cwd, ms, phase, "*-SUMMARY.md")
      end)

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
      "Ensure every v3.9 SUMMARY.md has requirements-completed frontmatter.",
      %{malformed: Enum.map(malformed, &rel(cwd, &1))}
    )
  end

  defp validation_ledger_check(cwd, opts) do
    closeout = read_file(closeout_path(cwd, opts))
    fm = parse_frontmatter(closeout)
    ms = milestone(fm)
    phases = expected_phases(fm)

    problematic =
      Enum.reject(phases, fn phase ->
        paths = phase_paths(cwd, ms, phase, "*-VALIDATION.md")
        paths != [] and Enum.all?(paths, &(read_file(&1) =~ "nyquist_compliant: true"))
      end)

    # The escape hatch only applies to an ACTIVE deferral: a deferred_with_reason
    # entry whose scope is validation-ledger-finalization and whose status is not
    # yet resolved/closed. A naive `closeout =~ "validation-ledger-finalization"`
    # would also match the same scope keyword inside a resolved_gaps entry, which
    # would silently re-open the hatch after cleanup and let a tampered ledger pass.
    deferred =
      deferred_entries(fm)
      |> Enum.any?(fn entry ->
        entry_field(entry, "scope") == "validation-ledger-finalization" and
          entry_field(entry, "status") not in ["resolved", "closed"]
      end)

    passed =
      closeout =~
        ~r/validation_ledger_status:\s*\n\s*status:\s*(complete|deferred_with_reason|archived)/ and
        (problematic == [] or deferred)

    check(
      "closeout.validation.ledger",
      "validation ledger status",
      ".planning/phases",
      passed,
      "non-compliant or missing validation ledgers for phases: #{Enum.join(problematic, ", ")}",
      "Mark validation ledgers Nyquist-compliant or defer them with owner/scope/reason evidence.",
      %{problematic: problematic}
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
    Keyword.get(opts, :closeout_path, Path.join(cwd, ".planning/milestones/v3.9-CLOSEOUT.md"))
  end

  # The live REQUIREMENTS.md is intentionally removed at milestone close and
  # recreated for the next milestone via /gsd:new-milestone. When it is absent,
  # fall back to the closing milestone's archived snapshot so closeout truth
  # survives the post-close "awaiting next milestone" interlude.
  defp requirements_source(cwd, milestone) do
    live = Path.join(cwd, ".planning/REQUIREMENTS.md")

    cond do
      File.exists?(live) -> read_file(live)
      milestone -> read_file(Path.join(cwd, ".planning/milestones/#{milestone}-REQUIREMENTS.md"))
      true -> read_file(live)
    end
  end

  defp milestone(frontmatter) do
    case Regex.run(~r/^milestone:\s*(\S+)/m, frontmatter, capture: :all_but_first) do
      [ms] -> ms
      nil -> nil
    end
  end

  defp expected_phases(frontmatter) do
    case Regex.run(~r/expected_phases:\s*(\[.*?\])/s, frontmatter, capture: :all_but_first) do
      [list_str] ->
        phases =
          ~r/"?(\d+(?:\.\d+)?)"?/
          |> Regex.scan(list_str, capture: :all_but_first)
          |> Enum.map(fn [p] -> p end)

        if phases == [], do: @v39_phases, else: phases

      nil ->
        @v39_phases
    end
  end

  defp phase_paths(cwd, milestone, phase, suffix) do
    archived =
      if milestone do
        Path.wildcard(
          Path.join(cwd, ".planning/milestones/#{milestone}-phases/#{phase}-*/#{suffix}")
        )
      else
        []
      end

    live = Path.wildcard(Path.join(cwd, ".planning/phases/#{phase}-*/#{suffix}"))
    archived ++ live
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

  defp deferred_entries(frontmatter) do
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
        end

      _ ->
        []
    end
  end

  defp malformed_deferred_entries(frontmatter) do
    frontmatter
    |> deferred_entries()
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {entry, index} ->
      missing = Enum.reject(@exception_fields, &Regex.match?(~r/(^|\n)\s*#{&1}:/, entry))
      if missing == [], do: [], else: ["entry #{index} missing #{Enum.join(missing, "/")}"]
    end)
  end

  defp entry_field(entry, field) do
    case Regex.run(
           ~r/(?:^|\n)\s*#{Regex.escape(field)}:\s*"?([^"\n]+)"?/,
           entry,
           capture: :all_but_first
         ) do
      [value] -> String.trim(value)
      nil -> nil
    end
  end

  defp stale_deferral?(cwd, entry) do
    case entry_field(entry, "revisit_phase") do
      nil ->
        false

      "" ->
        false

      revisit ->
        Path.wildcard(Path.join(cwd, ".planning/milestones/*-phases/#{revisit}-*")) != []
    end
  end

  defp prior_validation_debt_check(cwd, opts) do
    current = closeout_path(cwd, opts)

    prior_closeouts =
      Path.wildcard(Path.join(cwd, ".planning/milestones/v*-CLOSEOUT.md"))
      |> Enum.reject(&(&1 == current))

    unsatisfied =
      Enum.flat_map(prior_closeouts, fn path ->
        content = read_file(path)
        fm = parse_frontmatter(content)
        ms = milestone(fm)
        phases = expected_phases(fm)

        deferred_entries(fm)
        |> Enum.filter(fn entry ->
          entry_field(entry, "scope") == "validation-ledger-finalization" and
            entry_field(entry, "status") not in ["resolved", "closed"]
        end)
        |> Enum.reject(fn _entry ->
          Enum.all?(phases, fn phase ->
            paths = phase_paths(cwd, ms, phase, "*-VALIDATION.md")
            paths != [] and Enum.all?(paths, &(read_file(&1) =~ "nyquist_compliant: true"))
          end)
        end)
        |> Enum.map(fn entry ->
          reason = entry_field(entry, "reason") || "no reason"
          stale_note = if stale_deferral?(cwd, entry), do: " (stale)", else: ""
          "#{ms}: #{reason}#{stale_note}"
        end)
      end)

    passed = unsatisfied == []

    check(
      "closeout.validation.prior_debt",
      "prior milestone validation-ledger debt",
      ".planning/milestones/*-CLOSEOUT.md",
      passed,
      Enum.join(unsatisfied, "; "),
      "Resolve prior validation-ledger deferrals (make named ledgers nyquist_compliant: true or mark the deferral status: resolved with evidence) before closing a new milestone.",
      %{unsatisfied: unsatisfied}
    )
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
