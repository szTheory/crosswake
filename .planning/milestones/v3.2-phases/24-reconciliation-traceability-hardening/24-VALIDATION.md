---
phase: 24
slug: reconciliation-traceability-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-27
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir stdlib, no install) |
| **Config file** | `test/test_helper.exs` (exists: `ExUnit.start()`) |
| **Quick run command** | `mix test test/crosswake/planning/summary_frontmatter_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~2 seconds (single deterministic file-walk test) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/planning/summary_frontmatter_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green AND `phase23-proof.yml` (or successor merge-blocking workflow) lists the new test path
- **Max feedback latency:** ~2 seconds per task; ~30 seconds for full suite

---

## Per-Task Verification Map

> Task IDs and final plan-level mapping are filled by the planner; this table seeds the requirement → test type mapping the planner must preserve.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 1 | RECN-01 | — | Phase 21 SUMMARY files carry canonical `requirements-completed:` key listing RECN-01; REQUIREMENTS.md and audit doc reflect satisfied | parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` | ❌ Wave 0 | ⬜ pending |
| TBD | TBD | 1 | RECN-02 | — | Phase 21 SUMMARY files carry canonical `requirements-completed:` key listing RECN-02; REQUIREMENTS.md and audit doc reflect satisfied | parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` | ❌ Wave 0 | ⬜ pending |
| TBD | TBD | 1 | RECN-03 | — | Phase 21 SUMMARY files carry canonical `requirements-completed:` key listing RECN-03; REQUIREMENTS.md and audit doc reflect satisfied | parity | `mix test test/crosswake/planning/summary_frontmatter_test.exs` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/planning/` directory — does not exist; must be created
- [ ] `test/crosswake/planning/summary_frontmatter_test.exs` — covers RECN-01/02/03 via D-10(a) (`requirements:` key is forbidden in summaries) and D-10(b) (every requirement ID listed under `requirements-completed:` exists as a bullet in `.planning/REQUIREMENTS.md`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Re-audit `current_status: satisfied` row appears in `.planning/v3.2-MILESTONE-AUDIT.md` `reaudits:` frontmatter list | RECN-01/02/03 | Audit-doc-shape concern; the parity test enforces the SUMMARY/REQUIREMENTS side but the audit doc append is structural | Open the file, confirm a new entry under `reaudits:` exists with `phase: 24`, `current_status: satisfied`, and a `## Re-Audit (Phase 24)` body section is present at end-of-file. Confirm top-level `status: gaps_found` is UNCHANGED. |
| Merge-blocking CI workflow (`.github/workflows/phase23-proof.yml` or successor) lists the new test path | RECN-01/02/03 | The CI workflow enumerates explicit file paths; merge-blocking lane membership is a YAML-structural concern not covered by ExUnit | Open the workflow YAML, confirm `test/crosswake/planning/summary_frontmatter_test.exs` appears in the merge-blocking job's test list. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (the new parity test file)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30 seconds
- [ ] `nyquist_compliant: true` set in frontmatter (after planner fills task IDs and CI workflow update is included in plan scope)

**Approval:** pending
