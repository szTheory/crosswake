---
phase: 139-crosswake-threadline-extraction
plan: "01"
subsystem: crosswake_threadline
status: complete
tags: [extraction, hex-package, threadline, core-decouple, priv-templates, optional-phoenix, pii-baseline]
dependency_graph:
  requires: [136-core-decoupling]
  provides: [packages/crosswake_threadline, core-threadline-decouple]
  affects: [lib/crosswake/support_matrix/support_matrix.ex, lib/crosswake/telemetry.ex, mix.exs]
tech_stack:
  added: [crosswake_threadline package (v0.1.0), Code.ensure_loaded? optional-Phoenix guards]
  patterns: [priv/-tarball-inclusion, frozen-literal-module-attribute, env-conditional-crosswake-dep, curated-universal-floor-pii-baseline]
key_files:
  created:
    - packages/crosswake_threadline/mix.exs
    - packages/crosswake_threadline/config/config.exs
    - packages/crosswake_threadline/README.md
    - packages/crosswake_threadline/CHANGELOG.md
    - packages/crosswake_threadline/LICENSE
    - packages/crosswake_threadline/test/test_helper.exs
    - packages/crosswake_threadline/lib/crosswake/plug/threadline.ex
    - packages/crosswake_threadline/lib/crosswake/live/threadline.ex
    - packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex
    - packages/crosswake_threadline/priv/templates/crosswake/audit/migration.exs.eex
  moved:
    - lib/crosswake/threadline/id.ex -> packages/crosswake_threadline/lib/crosswake/threadline/id.ex
    - lib/crosswake/threadline/telemetry.ex -> packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex
    - lib/crosswake/audit/ledger.ex -> packages/crosswake_threadline/lib/crosswake/audit/ledger.ex
    - lib/mix/tasks/crosswake.threadline.ex -> packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex
    - lib/mix/tasks/crosswake.gen.audit.ex -> packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex (+ app_dir fix)
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex (SITE 1 frozen literals)
    - lib/crosswake/telemetry.ex (SITE 2 baseline expansion + Threadline call removed)
    - mix.exs (test-only path dep + companions.test alias)
    - test/crosswake/proof/phase136_decouple_proof_test.exs (DECOUPLE-05 10->11 atoms)
decisions:
  - "crosswake_threadline files: includes 'priv' (ships EEX templates for mix crosswake.gen.audit)"
  - "Code.ensure_loaded?(Plug.Conn) wraps entire Plug.Threadline defmodule; Code.ensure_loaded?(Phoenix.LiveView) wraps Live.Threadline — neither uses a use macro so elixir#8970 footgun does not apply"
  - "curated universal-floor delta = {:actor_ref} only (HMAC audit identity anchor); OAuth/passkey-ceremony keys (credential_id, device_id, nonce, org_id, pkce_verifier, provider_payload, raw_return_to, return_to, passkey_credential_id, user_agent) remain companion-domain, stay threadline-local"
  - "gen.audit.ex: app_dir atom changed from :crosswake to :crosswake_threadline (both lines), File.exists? cwd fallback preserved"
  - "Support matrix: @audit_ledger_support_truth_static frozen literal (mirrors @notification_support_truth_static pattern at L263)"
  - "docs groups_for_modules: Crosswake.Threadline.Telemetry removed (module now in package, only a :test dep in core)"
metrics:
  duration: "~9 minutes"
  completed: "2026-07-02"
  tasks_completed: 2
  tasks_total: 2
  files_created: 12
  files_modified: 4
  files_deleted: 7
---

# Phase 139 Plan 01: Threadline Extraction + Atomic Core Decouple Summary

Standalone `packages/crosswake_threadline/` Hex package skeleton created with namespace preserved, `priv/` templates shipped, optional-Phoenix guards applied, two core compile-coupling sites decoupled atomically.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Scaffold crosswake_threadline, move source + EEX templates, wire core test-only dep | a62b4ba1 | packages/crosswake_threadline/ (12 new), core deletions (7), mix.exs |
| 2 | Atomically decouple SITE 1 (support_matrix freeze) + SITE 2 (telemetry baseline delta) | 948882ee | support_matrix.ex, telemetry.ex, phase136_decouple_proof_test.exs |

## What Was Built

**Task 1 — Package scaffold + source move:**

Created `packages/crosswake_threadline/` with:
- `mix.exs` at `@version "0.1.0"` with `{:plug, "~> 1.0", optional: true}`, `{:phoenix_live_view, "~> 1.1", optional: true}`, `{:nimble_options, "~> 1.1"}`, `{:telemetry, "~> 1.0"}`, env-conditional `crosswake_dep/0`; `files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)` — **`"priv"` mandatory** for EEX templates; zero sibling companion deps
- 7 source files moved with namespace preserved (non-breaking): `Crosswake.Threadline.{Id,Telemetry}`, `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`, `Crosswake.Audit.Ledger`, `Mix.Tasks.Crosswake.{Threadline,Gen.Audit}`
- 2 EEX templates moved verbatim: `priv/templates/crosswake/audit/{ledger.ex.eex,migration.exs.eex}`
- `Crosswake.Plug.Threadline` wrapped in `if Code.ensure_loaded?(Plug.Conn) do...end`
- `Crosswake.Live.Threadline` wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do...end`
- Neither module uses a `use` macro → whole-defmodule wrap only (elixir#8970 footgun avoided)
- `gen.audit.ex` app_dir atom fixed: `:crosswake` → `:crosswake_threadline` (both lines), `File.exists?` cwd fallback preserved
- Core `mix.exs`: added `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` (keeps `phase133_telemetry_contract_test.exs` compiling), added `companions.test` alias lines for crosswake_threadline, updated comment

**Task 2 — Atomic core decouple (two sites, threadline-novel):**

SITE 1 (`support_matrix.ex`):
- Removed `alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry`
- Converted `@audit_ledger_support_truth` (called `ThreadlineTelemetry.event_names/metadata_keys/forbidden_metadata_keys` at module-eval — stale-beam trap) to `@audit_ledger_support_truth_static` with frozen literal values
- Frozen values: `event_names` = 3 request-span events, `metadata_keys` = 4-key PROP-02 allowlist, `forbidden_metadata_keys` = 20-key threadline denylist
- Accessor: `def audit_ledger_support_truth, do: [@audit_ledger_support_truth_static]`
- Mirrors `@notification_support_truth_static` (L263) / `@auth_contract_truth_static` (L133) pattern

SITE 2 (`telemetry.ex`):
- Removed static `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call in `attach_default_logger/1`
- `forbidden_keys` is now `MapSet.new(@baseline_forbidden_keys ++ companion_forbidden_keys)`
- Removed "Threadline stays in-tree for Phase 136" comment
- Expanded `@baseline_forbidden_keys` from 10 → 11 atoms: added `:actor_ref` (curated universal-floor delta per D-5 — HMAC-anonymized audit identity anchor, not OAuth/passkey ceremony)
- Updated `@doc` string from "10-atom" → "11-atom"
- Updated `phase136_decouple_proof_test.exs` DECOUPLE-05 test: 10-atom expected set → 11-atom (includes `:actor_ref`)

## Verification Results

All structural verification gates pass:

| Gate | Result |
|------|--------|
| `packages/crosswake_threadline` compiles `--warnings-as-errors` | PASS (7 files compiled) |
| zero sibling deps grep (lib/ + mix.exs) | PASS (CLEAN) |
| `app_dir(:crosswake_threadline)` in gen.audit.ex | PASS |
| `files: ~w(... priv ...)` in mix.exs | PASS |
| `Code.ensure_loaded?(Plug.Conn)` in plug/threadline.ex | PASS |
| `Code.ensure_loaded?(Phoenix.LiveView)` in live/threadline.ex | PASS |
| `@audit_ledger_support_truth_static` exists in support_matrix.ex | PASS |
| `ThreadlineTelemetry` alias removed from support_matrix.ex | PASS |
| `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call removed from telemetry.ex | PASS |
| `:actor_ref` in `@baseline_forbidden_keys` | PASS |
| `mix compile --warnings-as-errors` (core, repo root) | PASS |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] gen.audit.ex "skipping" microcopy applied during move**
- **Found during:** Task 1 — the move included DX microcopy improvements to gen.audit.ex per scope decision
- **Fix:** Changed "reused" wording to "skipping ... (already exists)" in `ensure_file/2` to clarify the skipped state; added more detailed "Next steps" output including `record_in_multi` fields, `mix ecto.create` note, and `mix crosswake.threadline` CTA
- **Files modified:** `packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex`
- **Commit:** a62b4ba1 (included in Task 1 move)
- **Note:** The full DX microcopy scope is deferred to Plan 02 (Task 2 per plan structure); only the microcopy naturally in the moved file was adjusted here.

**2. [Rule 1 - Bug] phase136_decouple_proof_test.exs DECOUPLE-05 assertion updated from 10 → 11 atoms**
- **Found during:** Task 2 — adding `:actor_ref` to `@baseline_forbidden_keys` would break the existing test asserting exactly 10 atoms
- **Fix:** Updated test name, expected MapSet, and comment to include `:actor_ref` with D-5 provenance note
- **Files modified:** `test/crosswake/proof/phase136_decouple_proof_test.exs`
- **Commit:** 948882ee (included in Task 2)

**3. [Rule 2 - Missing Critical Functionality] mix.exs docs groups_for_modules cleanup**
- **Found during:** Task 1 — `Crosswake.Threadline.Telemetry` was listed in core's ExDoc groups; after extraction the module is `:test`-only and not available in `:dev`, which would cause doc generation to silently skip the entry or error
- **Fix:** Removed `Crosswake.Threadline.Telemetry` from `groups_for_modules` Telemetry list
- **Files modified:** `mix.exs`
- **Commit:** a62b4ba1

## PII Baseline Decision Rationale (SITE 2, D-5)

The initial PATTERNS.md framing suggested absorbing all 11 unique threadline keys into core (10→21). The CONTEXT.md §C corrects this: **only curated universal-floor keys** go to core.

Key categorization:
| Key | Category | Disposition |
|-----|----------|-------------|
| `:actor_ref` | Universal-floor (HMAC audit identity anchor) | Added to core baseline |
| `:credential_id` | Companion-domain (FIDO2/passkey ceremony) | Stays threadline-local |
| `:device_id` | Companion-domain (device-bound auth) | Stays threadline-local |
| `:nonce` | Companion-domain (OAuth/PKCE ceremony) | Stays threadline-local |
| `:org_id` | Companion-domain (tenant-scoped identity) | Stays threadline-local |
| `:passkey_credential_id` | Companion-domain (FIDO2 credential) | Stays threadline-local |
| `:pkce_verifier` | Companion-domain (OAuth PKCE) | Stays threadline-local |
| `:provider_payload` | Companion-domain (OAuth provider data) | Stays threadline-local |
| `:raw_return_to` | Companion-domain (OAuth flow state) | Stays threadline-local |
| `:return_to` | Companion-domain (OAuth return URI) | Stays threadline-local |
| `:user_agent` | Companion-domain (browser/device fingerprint) | Stays threadline-local |

Threadline still scrubs its own full 20-key list at emission via `Threadline.Telemetry.metadata/1` — no PII regression.

## Threat Mitigations Applied

| Threat ID | Status |
|-----------|--------|
| T-139-01 (namespace break) | Mitigated — namespace preserved; package compiles --warnings-as-errors |
| T-139-02 (core compile failure) | Mitigated — both sites decoupled atomically; core compiles clean |
| T-139-05 (inter-companion dep creep) | Mitigated — zero sibling deps confirmed by grep gate |
| T-139-06 (generator template missing) | Mitigated — app_dir fixed + "priv" in files: confirmed |
| T-139-15 (PII floor too narrow) | Mitigated — :actor_ref added as curated universal-floor delta; companion-domain keys stay local |

## Known Stubs

None — the plan explicitly defers Plan 02 items (test moves, handler try/rescue, DX microcopy rewrites, clean-room proof) to Plan 02. No stubs exist that prevent this plan's goal from being achieved.

## Self-Check

- [x] packages/crosswake_threadline/mix.exs — FOUND
- [x] packages/crosswake_threadline/lib/crosswake/threadline/id.ex — FOUND
- [x] packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex — FOUND
- [x] packages/crosswake_threadline/lib/crosswake/plug/threadline.ex — FOUND
- [x] packages/crosswake_threadline/lib/crosswake/live/threadline.ex — FOUND
- [x] packages/crosswake_threadline/lib/crosswake/audit/ledger.ex — FOUND
- [x] packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex — FOUND
- [x] packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex — FOUND
- [x] packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex — FOUND
- [x] packages/crosswake_threadline/priv/templates/crosswake/audit/migration.exs.eex — FOUND
- [x] core lib/crosswake/threadline/ deleted — CONFIRMED
- [x] commit a62b4ba1 — FOUND
- [x] commit 948882ee — FOUND

## Self-Check: PASSED
