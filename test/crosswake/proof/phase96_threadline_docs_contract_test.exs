defmodule Crosswake.Proof.Phase96ThreadlineDocsContractTest do
  use ExUnit.Case, async: false

  # Phase 96 docs-contract parity: assert every DOCS-01/02/03 contract string
  # appears verbatim in guides/threadline.md. Code-derived values use public
  # accessors (header name, telemetry keys); the 15 ledger columns are hardcoded
  # with a co-location comment referencing lib/crosswake/doctor/doctor.ex.

  # D-01: ledger columns are a frozen contract (LEDG-02). No public accessor.
  # Cross-reference: canonical_columns/0 extraction deferred — see
  # lib/crosswake/doctor/doctor.ex for the checked-in column list shape.
  @canonical_ledger_columns [
    "thread_id",
    "correlation_id",
    "route_id",
    "actor_ref",
    "actor_kind",
    "event_class",
    "event_type",
    "outcome",
    "provenance",
    "occurred_at",
    "recorded_at",
    "idempotency_key",
    "metadata",
    "row_hash",
    "prev_hash"
  ]

  # Ledger PII guard — 8 keys (SEPARATE from the telemetry denylist, which has 20 keys).
  # These guard the metadata map of audit ledger rows, not telemetry spans.
  @ledger_pii_keys ["email", "phone", "ip_address", "ssn", "name", "first_name", "last_name", "address"]

  # -------------------------------------------------------------------------
  # Hermetic lane self-guard
  # -------------------------------------------------------------------------

  test "hermetic lane guard: module is untagged and has no example-host dependency" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "guides/threadline.md parity test must not carry a @moduletag — remove it to keep the hermetic lane self-contained"

    refute String.contains?(source, "Crosswake" <> "Example."),
           "guides/threadline.md parity test must not reference the example-host (Crosswake.Example.*) — the hermetic lane runs without the example Phoenix host"
  end

  # -------------------------------------------------------------------------
  # Header name (DOCS-01, code-derived)
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents the plug header name (DOCS-01)" do
    guide = File.read!("guides/threadline.md")
    header = Crosswake.Plug.Threadline.init([])[:header_name]

    assert String.downcase(guide) =~ String.downcase(header),
           "guides/threadline.md must document the Threadline plug header name '#{header}' — add it to the Propagation Contract section"
  end

  # -------------------------------------------------------------------------
  # Telemetry metadata keys (DOCS-01, code-derived)
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents all telemetry metadata keys (DOCS-01)" do
    guide = File.read!("guides/threadline.md")

    for key <- Crosswake.Threadline.Telemetry.metadata_keys() do
      assert guide =~ Atom.to_string(key),
             "guides/threadline.md must document telemetry metadata key '#{key}' — add it to the Propagation Contract section"
    end
  end

  # -------------------------------------------------------------------------
  # Telemetry forbidden keys / PII denylist (DOCS-01, code-derived)
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents all 20 telemetry forbidden metadata keys (DOCS-01)" do
    guide = File.read!("guides/threadline.md")

    for key <- Crosswake.Threadline.Telemetry.forbidden_metadata_keys() do
      assert guide =~ Atom.to_string(key),
             "guides/threadline.md must document telemetry forbidden key '#{key}' in the PII-Free by Construction section (Telemetry Denylist subsection)"
    end
  end

  # -------------------------------------------------------------------------
  # Telemetry event names (DOCS-01, code-derived)
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents telemetry event name segments (DOCS-01)" do
    guide = File.read!("guides/threadline.md")

    for event_name <- Crosswake.Threadline.Telemetry.event_names() do
      for segment <- event_name do
        assert guide =~ Atom.to_string(segment),
               "guides/threadline.md must document telemetry event name segment '#{segment}' — add the event name list to the Propagation Contract section"
      end
    end

    # Belt-and-suspenders: assert the domain segments are present regardless of loop
    assert guide =~ "threadline",
           "guides/threadline.md must contain the 'threadline' event name segment"

    assert guide =~ "request",
           "guides/threadline.md must contain the 'request' event name segment"
  end

  # -------------------------------------------------------------------------
  # Audit ledger columns (DOCS-01, LEDG-02, hardcoded frozen contract)
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents all 15 canonical LEDG-02 ledger columns (DOCS-01)" do
    guide = File.read!("guides/threadline.md")

    for col <- @canonical_ledger_columns do
      assert guide =~ col,
             "guides/threadline.md must document ledger column '#{col}' in the Audit Ledger Schema (LEDG-02) table"
    end
  end

  test "canonical_ledger_columns list has exactly 15 entries (LEDG-02 frozen contract)" do
    assert length(@canonical_ledger_columns) == 15,
           "The @canonical_ledger_columns list must have exactly 15 entries per the LEDG-02 frozen contract — update both this test and guides/threadline.md if the schema changes"
  end

  # -------------------------------------------------------------------------
  # Ledger PII guard keys (DOCS-01, separate from telemetry denylist)
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents all 8 ledger PII guard keys (DOCS-01)" do
    guide = File.read!("guides/threadline.md")

    for key <- @ledger_pii_keys do
      assert guide =~ key,
             "guides/threadline.md must document ledger PII guard key '#{key}' in the PII-Free by Construction section (Ledger PII Guard subsection — distinct from the 20-key telemetry denylist)"
    end
  end

  # -------------------------------------------------------------------------
  # Anti-scope section (DOCS-02)
  # -------------------------------------------------------------------------

  test "guides/threadline.md has a What Threadline Is NOT section (DOCS-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "What Threadline Is NOT",
           "guides/threadline.md must have a 'What Threadline Is NOT' section — add it per the DOCS-02 anti-scope requirement"
  end

  test "guides/threadline.md documents APM anti-scope (DOCS-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "APM",
           "guides/threadline.md must state that Threadline is NOT an APM in the 'What Threadline Is NOT' section (DOCS-02)"
  end

  test "guides/threadline.md documents OpenTelemetry anti-scope (DOCS-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "OpenTelemetry",
           "guides/threadline.md must state that Threadline is NOT an OpenTelemetry replacement in the 'What Threadline Is NOT' section (DOCS-02)"
  end

  test "guides/threadline.md documents logging framework anti-scope (DOCS-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "logging framework",
           "guides/threadline.md must state that Threadline is NOT a logging framework in the 'What Threadline Is NOT' section (DOCS-02)"
  end

  test "guides/threadline.md documents plugin anti-scope (DOCS-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "plugin",
           "guides/threadline.md must state that Threadline is NOT a generic plugin in the 'What Threadline Is NOT' section (DOCS-02)"
  end

  test "guides/threadline.md documents session replay anti-scope (DOCS-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "session replay",
           "guides/threadline.md must document that full-session replay is NOT in scope in the 'What Threadline Is NOT' section (DOCS-02)"
  end

  # -------------------------------------------------------------------------
  # Honest limitations (DOCS-03)
  # -------------------------------------------------------------------------

  test "guides/threadline.md contains verbatim hash-chain microcopy (DOCS-03)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "Hash-chaining does not prevent tampering — it reports it.",
           "guides/threadline.md must contain the verbatim D-10 hash-chain sentence: 'Hash-chaining does not prevent tampering — it reports it.' — do not paraphrase"
  end

  test "guides/threadline.md documents zero OTel dependency coexistence (DOCS-03)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "zero OTel dependency",
           "guides/threadline.md must state 'zero OTel dependency' in the coexistence description (DOCS-03 honest limitations)"
  end

  test "guides/threadline.md documents WebView gap (DOCS-03)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "WebView",
           "guides/threadline.md must document the WebView gap in the Honest Limitations section (DOCS-03) — WebView connections do not carry the thread id"
  end

  test "guides/threadline.md documents _crosswake_thread_id connect param (DOCS-03)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "_crosswake_thread_id",
           "guides/threadline.md must document the '_crosswake_thread_id' connect param path in the Honest Limitations section (DOCS-03)"
  end

  # -------------------------------------------------------------------------
  # Task/scope names
  # -------------------------------------------------------------------------

  test "guides/threadline.md documents mix crosswake.threadline task" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "mix crosswake.threadline",
           "guides/threadline.md must document the 'mix crosswake.threadline' operator task in the Operations section"
  end

  test "guides/threadline.md documents mix crosswake.gen.audit task" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "mix crosswake.gen.audit",
           "guides/threadline.md must document the 'mix crosswake.gen.audit' scaffolding task in the Operations section"
  end

  test "guides/threadline.md documents terminal critical events scope" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "terminal critical events",
           "guides/threadline.md must state 'terminal critical events' as the reserved scope for the audit ledger — this is the key DX boundary (DOCS-01)"
  end

  # -------------------------------------------------------------------------
  # Regression guards: WR-03 (conn.assigns) and WR-02 (record_in_multi arity)
  # See .planning/v7.0-MILESTONE-AUDIT.md for the original bug reports.
  # -------------------------------------------------------------------------

  # WR-03 regression guard: The plug stores the id in Logger.metadata, never in conn.assigns.
  # The bare "Logger.metadata" string already appears at lines 7 and 15 in unrelated prose,
  # so that substring CANNOT detect the regression. This assertion checks the full read-path
  # string Logger.metadata()[:crosswake_thread_id] which is absent before the fix.
  test "guides/threadline.md documents the Logger.metadata read-path for thread id (WR-03)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "Logger.metadata()[:crosswake_thread_id]",
           "guides/threadline.md must document the read-path 'Logger.metadata()[:crosswake_thread_id]' in the Propagation Contract section — Crosswake.Plug.Threadline never calls Conn.assign/3; the id is stored in Logger.metadata under :crosswake_thread_id (WR-03)"
  end

  # WR-02 regression guard: The generated template ships record_in_multi(multi, name, attrs) — arity 3.
  # The guide previously said record_in_multi/2, which would cause a FunctionClauseError for adopters.
  test "guides/threadline.md documents record_in_multi/3 (not /2) (WR-02)" do
    guide = File.read!("guides/threadline.md")

    assert guide =~ "record_in_multi/3",
           "guides/threadline.md must document 'record_in_multi/3' in the Operations > Scaffolding the ledger section — the generated template ships record_in_multi(multi, name, attrs) with arity 3, not arity 2 (WR-02)"
  end
end
