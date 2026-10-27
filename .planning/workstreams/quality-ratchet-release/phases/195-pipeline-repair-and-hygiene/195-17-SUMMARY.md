---
phase: 195-pipeline-repair-and-hygiene
plan: 17
subsystem: infra
tags: [ci, secret-masking, gap-closure, provider-tokens, pem, query-credentials]
requires:
  - phase: 195-16
    provides: fix/secret-mask-key-forms at c867af26 (critical round-2 mask forms)
provides:
  - "Local branch fix/secret-mask-key-forms (12 commits ahead of origin/main, not pushed) changing only script/verify_repository.mjs and test/js/ci_secret_masking.test.mjs"
  - "maskSecretShapes masks sk-, xox and npm_ provider tokens, short GitHub tokens, PEM blocks, widened userinfo, key-ID and JWT variants, query-string credentials and plural credential keys"
  - "Literal-value exemption (nil/true/false/null/undefined), left boundary on the authorization rule, relative CI timing bound, exported tail constants"
  - "GR-06 census: 0 of 7 unparsed bash forms in the live workflow tree"
  - "Evidence: mask-gr-warn-red-195.txt, mask-gr-warn-control-195.txt (committed on docs/195-closeout)"
affects: [195-18]
requirements-completed: [REL-03]
actuals:
  tokens: 5800
  tasks: 3
  commits: 6
  plan_head_before: c867af26c88c3f3f93f1638be9ab6f7799545356
  plan_head_after: 40c018a51d1b2cddd5862f01e65882738d50a173
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 17: Round-2 warning findings Summary

**The masker now covers provider-prefixed tokens, PEM key blocks, userinfo/key-ID/JWT variants and query-string credentials, leaves literal nil/true/false/null values readable, and the GR-06 deferral rests on a recorded zero census; every new test was recorded red first and replayed from its red commit.**

## What was checked and what happened

- Work continued on local branch `fix/secret-mask-key-forms` (from c867af26). Three `test(ci):` red commits each precede their `fix(ci):` commit: red 8c3f9ef/7243ab5/623d9d2, fix 9bb1963/bfa1647/40c018a. Nothing was pushed; the fix branch changes only the two source files.
- Task 1 (GR-03, tracer): 7 tests red (4 gap rows, spawned-child test, `task-runner12345 started`, short GitHub token). `kiosk-mode-settings applied` and `npm_config_cache is set` were already unchanged and are recorded `already_masked`. Fix: `gh*_` tokens of 6+, left-bounded `sk-`, `xox[abprs]-`, `npm_`+36. Mask removed: `leaked 47 of 47`.
- Task 2 (GR-04, GR-05, GR-09): 20 tests red (18 gap rows, 2 accepted over-mask pins, spawned-child). Fix: PEM rule (BEGIN marker kept, body/headers/END masked, real or literal-backslash-n breaks, no END marker leaves the next non-body line), bounded userinfo with empty user and slash passwords, key ID after underscore, two-segment JWT, query credentials, vocabulary `cookies?`, `secrets?`, `passwords?`, `tokens?`, `private[_-]?key`. Six new LINEAR rows.
- Task 3 (GR-07, GR-08, GR-06): 8 prose rows red (`token: nil`, `true`, `false`, `null`, `undefined`, the Elixir map, `preauthorization`). `literal_prefixed_value`, the three new accepted over-masks and the ANSI/CRLF test were already passing and are recorded `already_masked` (regression pins). Fix: whole-value-only literal exemption, `(?<![A-Za-z0-9])` on the authorization rule, exported `ROOT_PROOF_TAIL_LINES`/`ROOT_PROOF_TAIL_BYTES`, window test derives its numbers from them, CI bound `ms <= max(40, 10 * baselineMs())` with local evidence every row under 200 ms (slowest 27 ms).
- GR-06 census over the live `.github/workflows` tree: `decl_keyword`, `append_assign`, `read_into`, `printf_v`, `github_env_output`, `multi_assign`, `assign_and_use` all 0. The scan is non-vacuous (8 workflow files reference secrets).
- Final controls: mask removed leaks `68 of 68` gap seeds (rc 1); origin/main masker (tail constants exported) fails 52 tests including the spawned-child test; both restored clean. All log scans record `seed hits 0`.
- Full JS suite on the fix branch: 274 pass, 0 fail; `repository_verification` rc 0. Source and evidence privacy scans: clean (2 files each). Red replay from each recorded red commit (exported outside the repository) failed with the expected names and 0 seed hits; the plan's task 3 gate script exits 0.

## Heads

- Fix branch `fix/secret-mask-key-forms`: 40c018a51d1b2cddd5862f01e65882738d50a173 (12 commits ahead of origin/main, local only).
- Checkout is on `docs/195-closeout`; evidence commit 03fe1b2.

## Deviations from Plan

**1. [Rule 1 - Bug] Timing assertion text did not match the plan's literal `10 * baselineMs`**
- **Found during:** acceptance check after Task 3 commit.
- **Fix:** replaced a local `base` variable with `baselineMs()` in the assertion, amended the task-3 fix commit (unpushed), and re-ran the test file, final and pre-fix controls, full suite and privacy scans before recording the final evidence lines.

**Total deviations:** 1 auto-fixed. **Impact:** none on scope or results.

## Known Stubs

None.

## Threat Flags

None.

## Residual risk

- The masker is an enumerated list of shapes; shapes outside GR-01 to GR-09 are not proven masked.
- Accepted over-masks (pinned in `ACCEPTED_OVERMASK`): numeric values after a credential key, header-shaped `Authorization: required for route`, `stale cookie: expired at line`, `secrets: inherit`, a port before a path containing `@`.
- The JWT rule is anchored at `\beyJ` but its first segment class includes `-`, so a long `eyJ-eyJ-...` run could scan quadratically; not covered by a review finding, not measured here.
- GR-06 is deferred by evidence (zero census); plan 18 asks for the Phase 196 deferral decision.

## Next

195-18 ships `fix/secret-mask-key-forms` (not pushed here).

## Self-Check: PASSED

- Fix branch head 40c018a exists and changes exactly script/verify_repository.mjs and test/js/ci_secret_masking.test.mjs; branch is absent from the remote.
- Both evidence files are tracked on docs/195-closeout; task 3 gate passed; no seed appears in either evidence file.
