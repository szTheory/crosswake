---
phase: 153
slug: ios-mirror-unblock
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-13
validated: 2026-07-30
---

# Phase 153 — Validation Strategy

> Retroactive Nyquist audit of the completed iOS mirror unblock phase.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + bash/Elixir structural assertions |
| **Config file** | `mix.exs` |
| **Phase test file** | `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` |
| **Quick run command** | `mix test --only phase153_ios_mirror_unblock` |
| **Structural command** | `elixir script/check_release_workflow_integrity.exs` |
| **Release-status command** | `mix test test/mix/tasks/crosswake_release_status_test.exs` |
| **Parity discovery command** | `bash -n script/check_ios_mirror_parity.sh && test -x script/check_ios_mirror_parity.sh && python3 script/list_merge_blocking_checks.py \| grep -qx 'merge-blocking-ios-mirror-parity'` |
| **Full suite command** | `mix test` |
| **Audit result** | 19 phase tests and 17 release-status tests passed; structural scanner and parity discovery passed |

---

## Requirement Coverage

| Requirement | Automated coverage | Live/external evidence | Status |
|-------------|--------------------|------------------------|--------|
| MIRROR-01 | `phase153_ios_mirror_unblock_test.exs` exercises atomic push, explicit/stale leases, tag immutability, parity behavior, and scanner decoys; parity script is syntax-checked, executable, and merge-blocking-discoverable | Verify-only run `30316715897`; tag push `30316962777`; corrected main re-baseline `30578674382`; live mirror refs recorded in `153-02-SUMMARY.md` and `153-VERIFICATION.md` | COVERED |
| MIRROR-02 | `check_release_workflow_integrity.exs` asserts SSH transport, tag-pinned checkout, Hex gating, atomic leased push, fail-closed rollup, and native failure alerting; release-status tests assert missing/unavailable truth; phase tests prove parity and scanner non-vacuity | Branch protection includes `merge-blocking-ios-mirror-parity`; latest main lane and live parity evidence recorded in `153-VERIFICATION.md` | COVERED |

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Automated command or evidence | Status |
|---------|------|------|-------------|-------------------------------|--------|
| 153-01-01 | 01 | 1 | MIRROR-01, MIRROR-02 | `mix test --only phase153_ios_mirror_unblock` | COVERED |
| 153-01-02 | 01 | 1 | MIRROR-01, MIRROR-02 | Phase tests + `bash -n script/verify_ios_mirror_backfill.sh` | COVERED |
| 153-01-03 | 01 | 1 | MIRROR-02 | Structural scanner + phase scanner-decoy tests | COVERED |
| 153-02-01 | 02 | 2 | MIRROR-01 | Read-only deploy-key/secret evidence in `153-02-SUMMARY.md` and truth 11 in `153-VERIFICATION.md` | COVERED |
| 153-02-02 | 02 | 2 | MIRROR-01 | Successful verify-only run `30316715897`; live ref command in plan | COVERED |
| 153-02-03 | 02 | 2 | MIRROR-01 | Successful tag/main runs plus immutable-tag and stale-lease tests | COVERED |
| 153-03-01 | 03 | 3 | MIRROR-02 | Structural scanner checks release SSH transport, tag pin, Hex gate, and atomic lease | COVERED |
| 153-03-02 | 03 | 3 | MIRROR-02 | Structural scanner checks fail-closed rollup, native alerting, and secret retirement | COVERED |
| 153-03-03 | 03 | 3 | MIRROR-02 | Structural scanner + non-vacuous decoy tests | COVERED |
| 153-04-01 | 04 | 4 | MIRROR-01, MIRROR-02 | Parity script checks + `mix test --only phase153_ios_mirror_unblock` | COVERED |
| 153-04-02 | 04 | 4 | MIRROR-02 | `mix test test/mix/tasks/crosswake_release_status_test.exs` | COVERED |
| 153-04-03 | 04 | 4 | MIRROR-02 | Merge-blocking discovery test + live branch-protection evidence in `153-VERIFICATION.md` | COVERED |

---

## Manual-Only Verifications

None remain open.

The deploy-key registration, verify-only credential fire drill, one-way tag push, separately
approved `main` re-baseline, and required-check registration cannot be recreated safely as
ordinary hermetic tests. They were completed once and are backed by read-only evidence in
`153-02-SUMMARY.md` and the 31/31 passed truths in `153-VERIFICATION.md`. Their durable
behavioral invariants are covered by automated regression tests and structural guards.

---

## Sampling and Non-Vacuity

- Every implementation task has an automated command or durable external-evidence check.
- No three consecutive tasks lack automated verification.
- Bare-repository fixtures exercise successful, stale-lease, and immutable-tag branches.
- Scanner decoys prove the workflow checks fail when protected release behavior is removed.
- The parity test covers matching refs, missing refs, extra remote refs, unreachable remotes,
  source keying, and merge-blocking lane discovery.
- No watch-mode command is used.

---

## Validation Sign-Off

- [x] All tasks have automated verification or durable completed external evidence
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 dependencies exist and run green
- [x] No watch-mode flags
- [x] MIRROR-01 and MIRROR-02 are covered
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-30

---

## Validation Audit 2026-07-30

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audit commands:

- `mix test --only phase153_ios_mirror_unblock` — 19 tests, 0 failures
- `elixir script/check_release_workflow_integrity.exs` — exit 0
- `mix test test/mix/tasks/crosswake_release_status_test.exs` — 17 tests, 0 failures
- parity script syntax/executable/discovery checks — exit 0
