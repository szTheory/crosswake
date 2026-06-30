---
phase: 129
slug: stable-companion-contract-surface
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-25
validated: 2026-06-26
---

# Phase 129 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~3 seconds (quick) · full suite per project norm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~3 seconds (quick run)

---

## Per-Task Verification Map

> Task IDs are assigned by the planner. Rows below map each SEAM requirement to its
> automated proof; the planner must wire each task's `<verify>` to one of these commands.

| Req | Behavior | Wave | Test Type | Automated Command | File Exists |
|-----|----------|------|-----------|-------------------|-------------|
| SEAM-01 | 5 contract modules carry non-`false`/`:none`/`:hidden` `@moduledoc`; 4 struct types carry `@typedoc` on `t()` | 1 | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ✅ green |
| SEAM-01 | `Crosswake.Companion` callback set frozen at exactly 6 (MapSet equality) | 1 | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ✅ green |
| SEAM-02 | `guides/companion_contract.md` exists, enumerates the public surface | 1 | proof (file check) + integration | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs` | ✅ green |
| SEAM-03 | `Crosswake.Shell.Denial` ABSENT from "Companion Contract" group | 1 | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ✅ green |
| SEAM-03 | `Crosswake.Compatibility.Finding` PRESENT in "Companion Contract" group | 1 | proof | `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs` | ✅ green |
| SEAM-04 | "Companion Contract" `groups_for_modules` group + "Extension Authors" `groups_for_extras` group exist; new guide is in `extras` (orphan guard) | 1 | unit/integration | `mix test test/crosswake/hex_page_test.exs` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Post-execution result (2026-06-26):** `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs` → **16 tests, 0 failures** (7 freeze proof + 9 hex_page). Every SEAM requirement above is COVERED by a green automated assertion. The write-test-first failures noted below (3 red before 129-02) are fully resolved.

---

## Wave 0 Requirements

- [x] `test/crosswake/proof/phase129_companion_contract_freeze_test.exs` — new proof test covering SEAM-01, SEAM-02, SEAM-03 (untagged, `async: true`, auto-picked by PR-gating proof lane) — **landed (be33ecb), 7 tests green**
- Note: `test/crosswake/hex_page_test.exs` already exists and guards SEAM-04 (group presence + orphan-guide guard). No new test file for SEAM-04 — only `mix.exs` `docs/0` changes plus an assertion extension for the two new groups.

*The freeze test will FAIL until the 4 `@moduledoc false` promotions and the new guide land — that failure is the intended write-test-first forcing function (D-18), not a defect.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| hexdocs renders "Companion Contract" module group + "Extension Authors" extras group with version badges | SEAM-01, SEAM-04 | ExDoc HTML rendering / visual badge placement not asserted by ExUnit | Run `mix docs`, open `doc/index.html`, confirm both groups render with the 5 modules and the new guide; confirm `@moduledoc since:` badges appear |

*All contract-enforcement behaviors (callback freeze, moduledoc presence, boundary absence/presence, group membership, orphan guide) have automated verification. Only the visual hexdocs rendering is manual.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s (quick run ~0.06s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-26

---

## Validation Audit 2026-06-26

| Metric | Count |
|--------|-------|
| Requirements audited | 6 (SEAM-01×2, SEAM-02, SEAM-03×2, SEAM-04) |
| COVERED | 6 |
| PARTIAL | 0 |
| MISSING (gaps found) | 0 |
| Gaps resolved | 0 |
| Escalated to manual-only | 0 |

**State A audit** — VALIDATION.md pre-existed as a draft; all planned tests had already landed and passed during execution (plans 129-01, 129-02). Re-ran the quick suite to confirm: `mix test test/crosswake/proof/phase129_companion_contract_freeze_test.exs test/crosswake/hex_page_test.exs` → **16 tests, 0 failures**. No gaps to fill, so no `gsd-nyquist-auditor` spawn was required. The single manual-only item (visual hexdocs group/badge rendering) remains genuinely non-automatable and is recorded above.
