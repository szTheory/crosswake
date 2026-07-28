# Phase 153 · Plan 04 — Summary

**Requirements:** MIRROR-01, MIRROR-02
**Status:** Tasks 1–2 complete. Task 3 **carried** as a post-merge operator step (see below).

## What shipped

### Task 1 — merge-blocking iOS mirror parity gate (D-16, D-19)

- `script/check_ios_mirror_parity.sh` (new, executable) — asserts the one-directional
  invariant: for every `refs/tags/ios-core-vX` in this repo, `refs/tags/vX` must exist on
  `szTheory/crosswake-shell-core-ios`. Unauthenticated `git -c core.askPass= ls-remote`,
  3-attempt retry, `comm -23` set difference. Extra mirror tags are not a violation.
- `.github/workflows/merge-blocking-ios-mirror-parity.yml` (new) — one job that IS the
  check; job key and literal `name:` both `merge-blocking-ios-mirror-parity`;
  `fetch-depth: 0` + `fetch-tags: true`; `actions/checkout` SHA-pinned.
- **Deadlock trap avoided structurally:** keys on released `ios-core-v*` git tags, never
  `.release-please-manifest.json`. Asserted by a source-guard test, not a comment.
- **D-19 microcopy** matches the plan byte-for-byte, in adopter language, one fix command.

### Task 2 — release-truth honesty (D-18)

- `live_registry_checks/2` splits `:missing` (registry answered, definite negative →
  `release.live_registry_presence`, `:error`) from `:unavailable` (probe never answered →
  **new** `release.live_registry_unverifiable`, `:error`). Both exit 1; neither
  misreports which failure occurred.
- Retry added at the **probe** layer (`probe_with_retry/3`), so the `http_probe:` /
  `git_ref_probe:` injection seam still calls fakes exactly once.
- `exit_code/1` unchanged, as the plan required.

## Deviations from plan

1. **Bootstrap-pending carve-out (new, `release.live_registry_bootstrap_pending`,
   `:warning`).** RESEARCH §Q6's literal body escalates every definite negative to
   `:error`, which made `--live` exit 1 for `crosswake_rindle` / `crosswake_rulestead` —
   packages that still carry an unconsumed `release-as` bootstrap pin with no release tag.
   They were never published, so the registry correctly has nothing and no adopter was
   ever promised anything. This is the same manifest-baseline false positive that
   `check_release_as_staleness.sh` documents ("the git tag, not the manifest baseline, is
   the authoritative already-released signal") and that D-16 avoids by keying on released
   tags. Applying §Q6 literally would also have contradicted the plan's own acceptance
   criterion and phase Success Criterion #3. The carve-out is gated on
   `release_as == manifest_version and release_as_tag_exists == false`; core/native carry
   no `release_as` and are never exempt. Non-vacuity proven by three tests.
2. **Carve-out tightened after review (`b0e6bbe0`).** As first written the split ran
   before `:missing`/`:unavailable` were distinguished, so an unreleased package with an
   *unreachable* registry was reported as "the registry has nothing" — a definite negative
   asserted from an unknown, downgraded to `:warning`. That reproduced T-153-09 inside the
   new advisory lane. The carve-out now keys on `:missing` only; an unreachable registry
   stays `release.live_registry_unverifiable` and still exits 1. Regression test added.
3. `CROSSWAKE_IOS_PARITY_RETRY_SLEEP` test seam (default `2`) so the retry proof runs
   sub-second. Production default unchanged.
4. `[[:space:]]` instead of `\t` in the mirror-tag `sed` — BSD sed does not match `\t`, so
   the plan's pattern would have silently parsed nothing on macOS. Also strips `^{}` peel
   lines from annotated tags.
5. `read_mirror_tags` writes to a global rather than stdout: capturing via `$(...)` would
   run the retry in a subshell where `fail`'s `exit 1` kills only the subshell and the
   unreachability text is swallowed — the exact T-153-09 misreport.

## Verification

| Check | Result |
|---|---|
| `script/check_ios_mirror_parity.sh` vs **real** mirror | **exit 0** — `v0.1.2` + `v0.2.0` both present |
| `python3 script/list_merge_blocking_checks.py` | discovers `merge-blocking-ios-mirror-parity` |
| `mix crosswake.release.status --live` | **exit 0** (phase Success Criterion #3) |
| `elixir script/check_release_workflow_integrity.exs` | **exit 0** — no regression from plan 03 |
| `mix test --only phase153_ios_mirror_unblock` | 19 tests, 0 failures |
| `mix test test/mix/tasks/crosswake_release_status_test.exs` | 17 tests, 0 failures |
| `bash -n` + `test -x` on the parity script | exit 0 |

**Full suite:** 2 failures in `phase55_session_handoff_tickets_test.exs` and
`phase56_step_up_ceremony_test.exs`. **Verified pre-existing** — both fail identically on
a pristine `origin/main` worktree with example-host deps installed. Untouched by this
branch and unrelated to it (auth step-up ceremony vs. release/registry reporting).

## Success criteria (D-21)

1. ✅ Mirror `refs/tags/v0.2.0` present — verified by the parity script against the live remote.
2. ✅ `refs/tags/v0.1.2` still resolves.
3. ✅ `mix crosswake.release.status --live` exits 0.
4. ⏳ **Carried** — parity gate green and registered as a required check (Task 3).

## Carried post-merge item (Task 3)

The lane is **advisory until registered**, and advisory red is exactly what went unnoticed
for three months. `register_required_checks.sh` refuses to register a lane that has never
been green on `main`, and it cannot be green on `main` until this PR merges — the two-step
ordering is deliberate.

**After this PR merges and the lane shows green on `main`:**

```bash
script/register_required_checks.sh                 # DRY RUN — confirm the new context appears
DRY_RUN=0 script/register_required_checks.sh       # register (repo-admin rights required)
gh api repos/szTheory/crosswake/branches/main/protection/required_status_checks -q '.contexts'
```

Confirm `merge-blocking-ios-mirror-parity` appears in that list.
