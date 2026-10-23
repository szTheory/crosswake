---
phase: "192"
slug: "pr-ci-and-merge"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-23"
---

# Phase 192 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `192-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (`mix test`), POSIX/bash selftests, read-only `gh`/`git` assertions |
| **Config file** | none new; reuses `suite-gate-191.sh`, `selftest-scan-191.sh` |
| **Quick run command** | `sh "$S191/suite-gate-191.sh" subset "$IC" HEAD LAND-FIX "$R191/empty-red.txt" test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` |
| **Full suite command** | PR CI (`Crosswake CI`) is the full judge per D-02; no local `--all` |
| **Estimated runtime** | quick ~120 s; PR CI ~21–25 min |

---

## Sampling Rate

- **After every clone commit:** quick run command + `elixir script/inventory_collection_assertions.exs --check`
- **Before push:** `finalize-191.sh --check-binding` plus the push-gate selftest
- **Before the ask / before merge:** live re-read of PR head, mergeStateStatus, required check-run, remote `main`
- **Phase gate:** all SC1–SC4 assertions green and the recovery snapshot identical
- **Max feedback latency:** quick tier 120 s (CI polling is bounded by the CI run itself)
- **Latency exception (recorded):** the default 30 s feedback target does not hold for this phase. The selftests that take a live GitHub capture (selftest-ci/merge/postmerge-192.sh) and the affected `mix test` files need up to 120 s, so the quick tier is 120 s. The full finalize run in Plan 06 (tens of minutes) and PR CI (~21-25 min) are gate runs, not feedback samples.

---

## Per-Task Verification Map

Filled by the planner/executor against the final task IDs. Requirement-level map:

| Req / Criterion | Behavior | Test Type | Automated Command | File Exists | Status |
|-----------------|----------|-----------|-------------------|-------------|--------|
| D-01 WR-01 | C-locale snapshot equals committed ledger bytes; red on locale bug | unit + red-before | quick run command; red proof via pre-fix script `cmp` | edit existing | ⬜ pending |
| D-01 WR-02 | Missing roster phase fails; examined == 7 | unit + negative control | quick run command | edit existing | ⬜ pending |
| D-01 ledger | no ledger drift from new asserts | script | `elixir script/inventory_collection_assertions.exs --check` | ✅ | ⬜ pending |
| D-01 WR-03 | unreadable note -> scan exit 2 | selftest S33 | `bash selftest-scan-191.sh` -> `controls 33 of 33 as expected` | ❌ W0 | ⬜ pending |
| D-05/D-22 | push refused unless scan HEAD == push HEAD and scan_exit 0 | script selftest | `selftest-push-192.sh` (bare remote) | ❌ W0 | ⬜ pending |
| LAND-03 / SC1 | PR open; `Crosswake CI` success on head SHA | gh read | CI poll script (check-run name + app 15368 + head == local HEAD) | ❌ W0 | ⬜ pending |
| D-08 | head vs synthetic merge SHA/tree recorded per check | evidence assertion | poll/evidence script | ❌ W0 | ⬜ pending |
| LAND-04 / SC2 | merge only after allow, only that head | gate selftest with `gh` shim | merge-gate selftest | ❌ W0 | ⬜ pending |
| D-04 | merge commit, 2 parents, first == MAIN_SHA, second == bound head | gh read | post-merge verifier | ❌ W0 | ⬜ pending |
| LAND-04 / SC3 | main-side green (tree equality + push runs + publish jobs skipped) | gh read | post-merge verifier | ❌ W0 | ⬜ pending |
| SC4 | no release/publish/force/bypass | gh/curl read | baselines diff (releases, tags, Hex) + argv log | ❌ W0 | ⬜ pending |
| SC4 recovery | no git change in recovery checkout | digest diff | `REC_GIT="$REC/.git" sh recovery-snap-191.sh` vs `recovery-before-192.txt` | ✅ | ⬜ pending |
| Privacy | PR body and evidence free of paths/tokens | scan | fragment-pattern grep over PR body file and `192-EVIDENCE` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `selftest-scan-191.sh` control S33 plus `scan-191.sh` fix (red then green)
- [ ] `push-192.sh` + `selftest-push-192.sh` (bare-remote fixture)
- [ ] CI poll script (head-SHA check-run, labelled evidence)
- [ ] merge-gate script + `gh` shim selftest + binding record format
- [ ] post-merge verifier (parents, tree equality, push runs, baselines)
- [ ] `recovery-before-192.txt` snapshot at phase start

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Plain-language `allow` / `hold` on the displayed PR and head | LAND-04 | Irreversible merge to protected `main` needs the user's explicit choice (AGENTS.md approval gate) | Agent shows PR URL + head in plain words; user replies `allow` or `hold`; binding and evidence are automated |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s for the quick tier
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
