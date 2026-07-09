# Phase 140: Family Discipline & Close - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-02
**Phase:** 140-family-discipline-close
**Areas discussed:** Publish execution scope, Version cell owner, Threadline Side-A test, Recipe guard mechanics

---

## Method

`140-RESEARCH-SYNTHESIS.md` (a prior 5-lens research-then-recommend pass) had pre-locked ~15 decisions. Rather than rubber-stamp, the user requested a fresh deep research pass across all four still-open clusters. Four parallel expert-lens subagents (release-eng/SRE, docs-DX, telemetry-testing, extraction-runbook) each verified the synthesis claims against the real repo files, applied ecosystem/cross-project lenses, and returned pros/cons/tradeoffs + a single coherent recommendation. Two corrections to the synthesis emerged (below).

---

## Publish execution scope (FAMILY-04)

| Option | Description | Selected |
|--------|-------------|----------|
| Readiness-only, separate trigger | Waves 1–3 autonomous + human-gated runbook (`autonomous:false`); user fires the batched publish separately after origin-sync + CI green. No hex publish in-phase. | ✓ |
| Execute publish inside Phase 140 | Phase does not close until all three companions are live on hex.pm; runbook executed as last step. | |

**User's choice:** Readiness-only, separate trigger.
**Notes:** Consistent with the standing "no-publish-now / batched family publish" choice and boundary-hygiene "no publish this pass." Research confirmed all pipeline primitives are correctly in place (`separate-pull-requests`, per-component `*_release_created` gates, within-run `clean-room-proof` edges, green-first `register_required_checks.sh` preflight) and that sequencing MUST be runbook discipline — cross-run GitHub `needs` edges silently skip. Research flagged (non-blocking) that "deferred" should not become "indefinite" — the family should go live once origin-sync + 137/138/139 verification are done.

---

## Version cell owner (FAMILY-01)

| Option | Description | Selected |
|--------|-------------|----------|
| `unpublished` + human write-back | Honest pre-publish placeholder; human updates post-publish from hex.pm. | ✓ |
| Pipeline write-back automation | CI edits the version cell on publish. | |
| Omit column, link hex.pm | Drop the column, rely on hexdocs link/badge. | |

**User's choice:** `unpublished` + human write-back (via the accepted synthesis recommendation).
**Notes:** Automation rejected — 5 racing CI doc-commits + a `contents: write` escalation on tagged-checkout publish jobs isn't worth it for 5 rows; hex.pm is authority. **Correction added (D-08):** research recommended a lightweight drift-test format guard (cell must be `unpublished` OR valid semver) to catch prose-creep without fencing the value — adopted.

---

## Threadline Side-A test (FAMILY-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal upgrade (~20 lines) | Catalog-iterating `for event_name <- event_names/0` test + one plug-behavior test driving `:exception` live. | ✓ |
| Skip per original synthesis | Leave phase92 as-is (D-140-11 "optional/low-priority"). | |

**User's choice:** Minimal upgrade.
**Notes:** **Correction to synthesis (D-140-11 → D-17):** research VERIFIED the synthesis overstated phase92's coverage — it hardcodes 3 event names (not catalog-driven) and the declared `:exception` event is claimed-proven but never driven live. The ~20-line upgrade closes both the declared⇒emitted guard gap and the `:exception` live gap, and makes threadline family-consistent with the new sigra/chimeway Side-A tests.

---

## Recipe guard mechanics (FAMILY-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Adopt synthesis + mechanical refinements | Step 0 numbered gate + triage table + grep exit-code fix + widened scope + module-attr pass + callouts. | ✓ |

**User's choice:** Adopted (confirmed via the consolidated recommendation).
**Notes:** grep exit-code bug VERIFIED real (1 occurrence, `&& echo FAIL || echo CLEAN` can never fail CI); module-attribute coupling class VERIFIED real (`@audit_ledger_support_truth`). Mechanical refinements over the synthesis: `if grep; then exit 1; fi` (not `|| exit 1` — `set -e` correctness); `-n` not `-q` (MTTR); `--exclude-dir=packages` before paths (BSD/macOS portability); document that widened `test/` scope legitimately flags core fail-closed contract tests → EXTRACT-03 pattern.

---

## Claude's Discretion

- Exact test file names/locations for new Side-A tests (follow each package's existing convention).
- Wave decomposition detail (synthesis's 4-wave shape is a starting point, not binding).
- Precise recipe callout wording and triage-table column headers.

## Deferred Ideas

- `CROSSWAKE_VERSION` env helper (Ash pattern); `mix test.as_a_dep` (ecto_sql); `nimble_options` config schema; Igniter generators; `mix crosswake.upgrade`; `--no-optional-deps` compile lane.
- Pipeline write-back automation for the version cell (rejected for 5 rows; revisit if family grows).
- Full catalog-driven rewrite of threadline phase92 (rejected in favor of minimal upgrade).
- Still behind the family wedge: DASH-01, SYNCP-01, NTV-01, SEED-002.
