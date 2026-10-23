---
phase: "191"
slug: "integration-branch-and-local-suite"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-19"
---

# Phase 191 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `191-RESEARCH.md` § Validation Architecture. All commands run from the integration clone
> root unless stated, with `LC_ALL=C.UTF-8` for child processes, exit codes captured to files (never
> through pipes). No git write in the recovery checkout (D-23).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5), `node --test`, XCTest (`swift test`), shell self-tests with labelled controls |
| **Config file** | `test/test_helper.exs`, `mix.exs`, `script/repository_verification_stages.json` |
| **Quick run command** | `mix test test/crosswake/planning test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs test/crosswake/proof/phase17*` and `elixir script/check_release_workflow_integrity.exs` |
| **Full suite command** | `script/verify_repository.sh --all` (with `CROSSWAKE_REPOSITORY_RUN_ROOT` set and the PATH shims) then `(cd examples/phoenix_host && mix test)` |
| **Estimated runtime** | root `mix test` ~345 s; `--all` longer |

---

## Sampling Rate

- **After every task commit:** quick command plus `mix format --check-formatted` and `mix compile --warnings-as-errors`
- **After every plan wave:** full root suite at the code-fix, resolver and final-carry checkpoints
- **Before `/gsd-verify-work`:** `--all` nine PASS, example-host suite, Swift (with and without export), CI-parity extras, pin recount, privacy scan bound to HEAD, recovery before/after equal
- **Max feedback latency:** ~400 seconds (root suite)

---

## Per-Task Verification Map

| Req / criterion | Behavior | Test Type | Automated Command | File Exists | Status |
|-----------------|----------|-----------|-------------------|-------------|--------|
| LAND-01 / SC1 | Branch starts at current `main`; 94 candidate commits preserved, no merges | git checks | `merge-base --is-ancestor`; `rev-list --count main..candidate` = 94; `rev-list --merges` = 0; `merge-base --is-ancestor 2faf15a2 HEAD` | ❌ W0 | ⬜ pending |
| LAND-01 / SC1 | Carry complete, exact, no exclusion overlap | manifest equality | `carry-191.sh --verify` + `selftest-carry-191.sh` | ❌ W0 | ⬜ pending |
| LAND-01 / SC2 | Privacy scan of `main..HEAD` clean, non-zero counts, HEAD-bound | scan | `scan-191.sh --range <main>..HEAD` exit 0; `selftest-scan-191.sh`; gitleaks findings 0 | ❌ W0 | ⬜ pending |
| LAND-02 / SC3 | `--all` nine PASS records | stage run | `suite-gate-191.sh all` | ❌ W0 | ⬜ pending |
| LAND-02 / SC3 | Root 0 failures, 0 invalid, count ≥ separately measured floor | ExUnit | totals from `logs/root-proof.log` vs floor | ❌ W0 | ⬜ pending |
| LAND-02 / SC3 | G1 root gate inverted | ExUnit | `mix test test/crosswake/proof/phase180_twin_feasibility_test.exs` | ✅ edit | ⬜ pending |
| LAND-02 / SC3 | G2/G6 example host | ExUnit | `(cd examples/phoenix_host && mix test)` → 0 failures | ✅ edit | ⬜ pending |
| LAND-02 / SC3 | G4 Swift + named G3 skips | XCTest | `(cd packages/crosswake-shell-core-ios && swift test)` → 0 failures, skips named | ✅ edit | ⬜ pending |
| LAND-02 / D-12 | Ledger decodes under C locale | ExUnit + shell | `LC_ALL=C elixir script/inventory_collection_assertions.exs --check` exit 0 | ✅ edit | ⬜ pending |
| LAND-02 / D-15 | Formatting | mix | `mix format --check-formatted` exit 0 | ✅ | ⬜ pending |
| LAND-02 / D-16 | Test-file pin | guard + two counts | `elixir script/check_absence_is_not_success.exs`; `git ls-files test \| grep -c '\.exs$'` = `find test -name '*.exs' \| wc -l` = 253 | ✅ | ⬜ pending |
| LAND-02 | No silent exclusions | tag audit | closed tag set in `test/test_helper.exs`; evidence names each tag/reason/where-run; Swift skips by name | ❌ W0 | ⬜ pending |
| LAND-02 | CI-parity extras | commands | `mix crosswake.adoption_context.scan`; `mix crosswake.docs.sync --check`; `node --test test/js/*.mjs`; `elixir script/check_release_workflow_integrity.exs` | ✅ | ⬜ pending |
| SC4 | Separate durable clone; recovery unchanged | digest equality | `recovery-snap-191.sh` before == after; clone outside recovery and `<tmp>` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/git-pinned-191.sh`, `locate-191.sh`, `ensure-clone-191.sh`, `recovery-snap-191.sh` + self-tests (missing folder, tampered env mode, HEAD mismatch)
- [ ] `scripts/carry-191.sh` + self-test (dropped file, flipped byte, extra file, mode change, empty manifest, unmatched path, symlink refused, dual hashes, empty-dir tolerance)
- [ ] `scripts/suite-gate-191.sh` + self-test (MIN missing/zero, totals count wrong, excluded total wrong, 8 PASS records, dirty tree, HEAD mismatch)
- [ ] `scripts/scan-191.sh` + `selftest-scan-191.sh` (planted control per class and position; clean control; zero-term / zero-commit exit 2)
- [ ] Red-first tests for each code fix (WR-05 table, WR-01/WR-06, WR-03, extension/`$NN` cases, resolver absent-path control)
- [ ] Framework install: none

---

## Manual-Only Verifications

All phase behaviors have automated verification. (Any secret or in-history identity hit under D-20 rungs 1–2 stops for a user decision; that is a decision, not a verification.)

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 400s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
