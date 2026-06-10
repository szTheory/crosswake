---
phase: 96-docs-contract-proof
plan: "03"
subsystem: example-host-proof
tags: [proof, ecto, sqlite, advisory-ci, gen-audit, threadline]
dependency_graph:
  requires: [96-01, 96-02]
  provides: [PROOF-02]
  affects: [examples/phoenix_host, .github/workflows]
tech_stack:
  added: []
  patterns:
    - Ecto.Multi + record_in_multi/3 for transactional audit event seeding
    - Mix.Shell.Process for capturing Mix task output in tests
    - Schedule/dispatch-gated advisory CI workflow (no push/pull_request triggers)
key_files:
  created:
    - examples/phoenix_host/lib/crosswake_example/audit/ledger.ex
    - examples/phoenix_host/priv/repo/migrations/20260611000000_create_crosswake_audit_events.exs
    - examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs
    - .github/workflows/phase96-proof-advisory.yml
  modified:
    - examples/phoenix_host/mix.exs
    - examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex
decisions:
  - Use Mix.Shell.Process instead of capture_io for threadline output capture (D-05)
  - Repo.delete_all in setup before body, not on_exit, to avoid SQLite write-lock race (Pitfall 5)
  - No continue-on-error in advisory workflow — if: guard is primary gate (D-06)
  - Host-optional tier column added to schema + migration for threadline grouping (RESEARCH A2)
metrics:
  duration: "5m 21s"
  completed_date: "2026-06-10"
  tasks_completed: 3
  files_changed: 6
requirements_completed: [PROOF-02]
---

# Phase 96 Plan 03: Advisory Example-Host Ledger Proof Summary

**One-liner:** PROOF-02 advisory lane — committed gen.audit output (CrosswakeExample.Audit.Ledger, 15 LEDG-02 columns + host-optional tier) with an Ecto-backed ExUnit proof seeding via record_in_multi/3 and asserting "Posture: Durable" from mix crosswake.threadline against a real SQLite ledger, gated in a schedule/dispatch-only advisory workflow.

## What Was Built

### Task 1: gen.audit output (schema + migration)

Committed the rendered output of `mix crosswake.gen.audit` for CrosswakeExample into:

- `/examples/phoenix_host/lib/crosswake_example/audit/ledger.ex` — `defmodule CrosswakeExample.Audit.Ledger` with all 15 LEDG-02 columns verbatim from the template: `thread_id`, `correlation_id`, `route_id`, `actor_ref`, `actor_kind`, `event_class`, `event_type`, `outcome`, `provenance` (Ecto.Enum `:device_claimed | :backend_accepted`), `occurred_at`, `recorded_at`, `idempotency_key`, `metadata`, `row_hash`, `prev_hash`. Plus the 8-key `@forbidden_keys` PII guard, `changeset/2` with `reject_pii_in_metadata/1` and `compute_hashes/1`, `record/1`, and `record_in_multi/3` (multi, name, attrs).

- Added `field :tier, :string` as a host-optional extension beyond the LEDG-02 contract. This enables `mix crosswake.threadline` to group seeded events under Native/Bridge/Phoenix rather than the "Other (unrecognized tier)" bucket (RESEARCH A2 / Open Question 1). Marked with a comment explicitly distinguishing it from canonical LEDG-02 columns.

- `/examples/phoenix_host/priv/repo/migrations/20260611000000_create_crosswake_audit_events.exs` — all 15 columns with correct null constraints (metadata/row_hash/prev_hash nullable), plus `:tier :string` (nullable), and `unique_index(:crosswake_audit_events, [:idempotency_key])`. Timestamp 20260611000000 sorts after the latest committed migration (20260609020457).

### Task 2: Test alias + PROOF-02 test

- Added `aliases/0` to `examples/phoenix_host/mix.exs` with `test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]`. Wired via `aliases: aliases()` in `project/0`. This provisions the SQLite DB and applies all migrations in CI where the committed `.db` is absent or stale.

- Created `examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs` (`CrosswakeExample.Threadline.Phase96ExampleHostLedgerProofTest`, `async: false`):
  - `setup` runs `Repo.delete_all(CrosswakeExample.Audit.Ledger)` as the FIRST line (Pitfall 5: SQLite serialized-write race avoidance), then sets `:crosswake, :audit_repo` and `:crosswake, :audit_ledger` via `Application.put_env`, with `on_exit` restore.
  - Seeds a durable event via `Ecto.Multi.new() |> CrosswakeExample.Audit.Ledger.record_in_multi(:audit_event, attrs) |> Repo.transaction()`. All null: false columns provided; `tier: "phoenix"` set explicitly (Pitfall 4).
  - Captures task output via `Mix.Shell.Process` (not `capture_io`). Calls `Mix.Task.reenable("crosswake.threadline")` before `Mix.Task.run` (Pitfall 3).
  - Asserts: a message `=~ "Posture: Durable"` AND a message referencing the seeded event (`"auth.step_up"` or `"proof-actor"`).

- Test verified locally: `1 test, 0 failures` (exit 0).

### Task 3: Advisory workflow

Created `.github/workflows/phase96-proof-advisory.yml` with name `"Phase 96 Proof - Threadline Docs Contract (Advisory)"`:

- `permissions: contents: read`.
- Triggers: ONLY `workflow_dispatch` and `schedule` (`cron: "0 6 * * 1"`). No `push` or `pull_request` triggers.
- Single job `advisory-threadline-example-host-ledger-proof` with `if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}` as redundant insurance.
- No `continue-on-error` (D-06: soft-fail pattern renders failures green in PR UI).
- Pinned SHAs: `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd` (v6), `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93` (v1), elixir 1.19.5 / otp 27.3.
- Steps: checkout → setup-beam → `mix deps.get` (working-directory: examples/phoenix_host) → `mix test ...phase96_example_host_ledger_proof_test.exs` (working-directory: examples/phoenix_host) → advisory notice step (`if: always()`).

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 48354ac | feat(96-03): commit gen.audit output (schema + migration) for example host |
| 2 | 7e9ba5c | feat(96-03): add test alias + PROOF-02 Ecto-backed durable-posture test |
| 3 | 52fc5ef | feat(96-03): create advisory (schedule/dispatch-gated) workflow for PROOF-02 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed pre-existing compile warnings in step_up_challenge_live.ex**
- **Found during:** Task 1 verification (`mix compile --warnings-as-errors`)
- **Issue:** Three pre-existing warnings in `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex`: unused `session` variable in `mount/3`, unused `renewal` variable in `handle_event/3`, and unused `StepUpAuditEvent` alias. These blocked the plan's acceptance criterion of `mix compile --warnings-as-errors` succeeding.
- **Fix:** Prefixed `session` → `_session`, `renewal` → `_renewal`, removed unused `StepUpAuditEvent` alias.
- **Files modified:** `examples/phoenix_host/lib/crosswake_example/saas_portal/step_up_challenge_live.ex`
- **Commit:** 48354ac

**2. [Rule 1 - Bug] Removed "continue-on-error" text from workflow comment**
- **Found during:** Task 3 verification (grep check `! grep -q "continue-on-error"` was matching comment text)
- **Issue:** The plan's verification grep matched the string inside a comment explaining why `continue-on-error: true` is not used.
- **Fix:** Rephrased the comment to avoid the literal string `continue-on-error` while preserving the architectural explanation.
- **Files modified:** `.github/workflows/phase96-proof-advisory.yml`
- **Commit:** 52fc5ef

## Known Stubs

None. All functionality is wired end-to-end: the schema, migration, test alias, proof test, and advisory workflow form a complete working circuit.

## Threat Surface Scan

No new security-relevant surface beyond the plan's threat model:

- `T-96-06` (Information disclosure / seeded event PII): Mitigated — test seeds synthetic opaque values (`actor_ref: "proof-actor"`, no email/name/token). Schema's `reject_pii_in_metadata/1` guard is present.
- `T-96-07` (Tampering / advisory lane false-green): Mitigated — no `continue-on-error`, `push`/`pull_request` triggers absent.
- `T-96-08` (DoS / SQLite write-lock race): Mitigated — `Repo.delete_all` in setup before body, `async: false`.
- `T-96-SC` (example-host deps): Accepted — no new packages; ecto_sql/ecto_sqlite3 already in deps.

## Self-Check

### Created Files Exist

- examples/phoenix_host/lib/crosswake_example/audit/ledger.ex: FOUND
- examples/phoenix_host/priv/repo/migrations/20260611000000_create_crosswake_audit_events.exs: FOUND
- examples/phoenix_host/test/crosswake_example/threadline/phase96_example_host_ledger_proof_test.exs: FOUND
- .github/workflows/phase96-proof-advisory.yml: FOUND

### Commits Exist

- 48354ac: FOUND
- 7e9ba5c: FOUND
- 52fc5ef: FOUND

## Self-Check: PASSED
