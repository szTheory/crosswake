---
phase: 37-guides-walkthrough-and-docs-contract-lock
plan: "01"
subsystem: docs-contract
tags:
  - docs
  - test
  - commerce
  - paywall-corridor
  - exunit
dependency_graph:
  requires:
    - "Phase 33-36 shipped example host modules (locked)"
    - "guides/commerce.md Layer 1 existing structure"
    - "test/crosswake/guides/commerce_test.exs phase23 regression fences"
  provides:
    - "Paywall Corridor Walkthrough H3 in guides/commerce.md (DOCS-01)"
    - "Docs-contract test assertions locking walkthrough anchors (DOCS-02)"
    - "Live-code guard via Code.require_file + function_exported?/3 (D-06.2)"
  affects:
    - "guides/commerce.md (Layer 1 extended with walkthrough section)"
    - "test/crosswake/guides/commerce_test.exs (async: false + module-scope loads + new describe block)"
tech_stack:
  added: []
  patterns:
    - "Anchor-only walkthrough prose (no fenced code blocks)"
    - "Module-scope Code.require_file before defmodule (Phase 34/36 pattern)"
    - "function_exported?/3 live-code guard after require_file"
    - "content =~ string-presence assertion (existing idiom)"
key_files:
  created: []
  modified:
    - guides/commerce.md
    - test/crosswake/guides/commerce_test.exs
decisions:
  - "Callout text avoids 'StoreKit' and 'Play Billing' verbatim in Layer 1 to preserve existing refute reconciliation_section =~ 'storekit' regression fence — redirects to Layer 3 non-claims section instead (Rule 1 auto-fix)"
  - "async: false adopted per Phase 34/36 precedent for module-scope require_file safety"
  - "five Code.require_file calls placed at file scope before defmodule in dependency order (keys->inbox->storefront->projection->backend)"
  - "six function_exported?/3 assertions in one test block; verify_and_broadcast/2 excluded (PubSub-dependent)"
metrics:
  duration: "~20 minutes"
  completed: "2026-05-29"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 2
---

# Phase 37 Plan 01: Paywall Corridor Walkthrough And Docs-Contract Lock Summary

Inserted a `### Paywall Corridor Walkthrough` H3 into `guides/commerce.md` Layer 1 (anchor-only, six steps, mock-vs-real callout, proof citation) and extended `test/crosswake/guides/commerce_test.exs` with five module-scope `Code.require_file` calls, `async: false`, and six string-presence + six `function_exported?/3` assertions that lock the walkthrough against the shipped example host.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Insert Paywall Corridor Walkthrough H3 into guides/commerce.md (DOCS-01) | 261e1b1 | guides/commerce.md |
| 2 | Append hybrid docs-contract assertions to commerce_test.exs (DOCS-02) | 1c0603e | test/crosswake/guides/commerce_test.exs |

## Verification

- `mix test test/crosswake/guides/commerce_test.exs` — **26 tests, 0 failures** (20 existing + 6 new)
- `mix format --check-formatted test/crosswake/guides/commerce_test.exs` — **EXIT 0**
- Phase23 regression fences (`commerce guide publishes three explicit layer headings` + `non-claims section explicitly names StoreKit, Play Billing, device-local authority, and offline replay`) — **both passing unchanged**
- `grep -c '^## ' guides/commerce.md` — **returns 3** (no 4th H2 added)
- No fenced code blocks in the new walkthrough section

## Success Criteria Verification

- [x] SC#1 (DOCS-01): `guides/commerce.md` contains `### Paywall Corridor Walkthrough` H3 inside Layer 1, after `### Minimal Reconciliation Inbox Example`, before `### Backend Idempotency`
- [x] SC#2 (DOCS-01): Walkthrough opens with `provider: "mock"` callout; non-claims section names StoreKit and Play Billing
- [x] SC#3 (DOCS-02): `CrosswakeExample.Commerce.MockStorefront` named exactly; canonical fields `provider_reference` and `evidence_ref` present; six `function_exported?/3` assertions resolve after module-scope `Code.require_file`
- [x] SC#4 (DOCS-02): Phase23 three-layer heading fence still passes
- [x] SC#5 (DOCS-02): Phase23 four/five non-claims fence still passes
- [x] D-08: Proof citation `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` present in guide; `content =~` assertion locks it

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Mock-vs-real callout text avoids verbatim "StoreKit"/"Play Billing" in Layer 1 to preserve existing regression fence**

- **Found during:** Task 1 — first test run after inserting walkthrough
- **Issue:** The initial callout included "No StoreKit or Play Billing code is shipped" per plan wording. The existing `"keeps reconciliation guidance provider-neutral"` test splits from `### The Canonical Reconciliation Flow` to `## Reviewer And Storefront Playbooks` (encompassing the new walkthrough H3) and does `refute reconciliation_section =~ "storekit"`. The callout text caused this regression fence to fail.
- **Fix:** Rewrote callout to `"provider: \"mock\"". The example host ships a pure mock storefront with no native provider SDK dependency — no storefront adapter code is shipped in this example corridor. See Rough Edges And Non-Claims for the explicit non-claims, including which adapters are not shipped."` — references the non-claims section without naming StoreKit/Play Billing directly in Layer 1. The SC#2 assertions in Task 2 use `content =~` file-level checks which pass because those terms appear in Layer 2/3 (which they always have).
- **Files modified:** guides/commerce.md
- **Commit:** 261e1b1

## Known Stubs

None — all six anchored functions resolve to real exports; the proof citation is a real file path; `provider: "mock"` is the actual value in `MockStorefront`.

## Threat Flags

None. This phase adds no runtime code, no network I/O, no auth, no data persistence, and no new dependencies. The `Code.require_file` calls are hermetic (pure modules only; PubSub-dependent functions not invoked).

## Self-Check: PASSED

- FOUND: guides/commerce.md
- FOUND: test/crosswake/guides/commerce_test.exs
- FOUND commit 261e1b1 (Task 1)
- FOUND commit 1c0603e (Task 2)
- 26 tests pass, 0 failures
- mix format --check-formatted exits 0
