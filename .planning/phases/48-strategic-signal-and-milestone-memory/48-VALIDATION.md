---
phase: 48
slug: strategic-signal-and-milestone-memory
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-31
---

# Phase 48 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + GSD planning queries |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/planning/summary_frontmatter_test.exs -x` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Estimated runtime** | ~60-120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/planning/summary_frontmatter_test.exs -x` when the task touches planning parity checks; otherwise run the task's targeted source/assertion command.
- **After every plan wave:** Run `gsd-sdk query roadmap.analyze` plus `mix test --exclude requires_example_host --exclude advisory_only`.
- **Before `$gsd-verify-work`:** Full suite and roadmap analysis must be green, or gaps must be documented with explicit `deferred_with_reason` exceptions.
- **Max feedback latency:** 120 seconds for targeted planning checks; full-suite latency may exceed this only at phase gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 48-01-01 | 01 | 1 | STRAT-01 | T-48-01 | Strategic queue truth stays canonical in `MILESTONE-ARC.md` | planning parity | `rg "Risk tags|Proof required|Depends on" .planning/MILESTONE-ARC.md` | ✅ | ⬜ pending |
| 48-01-02 | 01 | 1 | STRAT-02 | T-48-02 | Closeout contract includes explicit artifact parity and exception fields | planning parity | `rg "deferred_with_reason|validation ledger|thread/seed|release continuity" .planning/MILESTONE-ARC.md .planning/milestones` | ⚠️ W0 | ⬜ pending |
| 48-02-01 | 02 | 2 | STRAT-01 | T-48-03 | Future queue dependencies prevent overclaiming deferred provider/auth/notification/shell surfaces | source assertion | `rg "v3.7|v3.8|v3.9|v4.0|v4.1|Threadline" .planning/MILESTONE-ARC.md` | ✅ | ⬜ pending |
| 48-02-02 | 02 | 2 | STRAT-02 | T-48-04 | Planning checks or documented Phase 53 enforcement target cover closeout parity | automated/manual hybrid | `gsd-sdk query roadmap.analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Add or identify the canonical closeout ledger/checklist location before tasks depend on it.
- [ ] Decide whether Phase 48 implements executable parity checks now or records exact Phase 53 enforcement targets.
- [ ] Ensure all Phase 48 plans reference STRAT-01 and STRAT-02 explicitly.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strategic queue rationale reads coherently and does not duplicate roadmap phase detail | STRAT-01 | Readability and strategic judgment cannot be fully captured by grep | Read `.planning/MILESTONE-ARC.md` after implementation and verify each queued milestone has a clear objective, why-now, dependencies, non-goals, and proof posture. |
| Closeout checklist is usable by a maintainer before context clears | STRAT-02 | Maintainer workflow clarity needs human review | Walk the checklist against v3.5 audit evidence and confirm every prior gap class has an explicit check or exception path. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for targeted checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
