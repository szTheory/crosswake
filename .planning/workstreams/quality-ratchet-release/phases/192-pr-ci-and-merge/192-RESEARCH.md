# Phase 192: PR, CI and merge - Research

**Researched:** 2026-10-23
**Domain:** Git/GitHub landing mechanics (push gate, PR, required check, bound merge, post-merge proof) on top of the Phase 191 integration clone
**Confidence:** HIGH for repo/protection/workflow facts (read this session); MEDIUM for CI durations and "main CI" interpretation
**Mode:** read-only. No push, PR, merge or git write was performed. The only commands run were file reads, `git` reads in `<integration-clone>`, GET calls through `gh api`/`gh run`/`gh pr view`, one read-only `ls-remote`, the recovery snapshot script (reads `.git` as files plus `ls-files -s`), and a few scratch fixtures under the 191 run folder (removed).

<user_constraints>
## User Constraints (from 192-CONTEXT.md)

### Locked Decisions (verbatim)
- **D-01:** Before the push, one small commit on `land/v25-v27` fixes 191-REVIEW.md WR-01, WR-02 and WR-03:
  - **WR-01:** `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`. The C-locale ledger test must fail when the locale bug is present, so it can no longer pass vacuously.
  - **WR-02:** `test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs`. A roster phase that is missing makes the test fail instead of being dropped silently.
  - **WR-03:** `scan-191.sh:197/201`. A git note that can't be read fails the scan instead of hitting `|| continue`.
- **D-02:** Locally, run only the affected tests plus the scanner self-test. Re-run the privacy scan on the new HEAD. PR CI is the full-suite judge, so `--all` is not re-run locally.
- **D-03:** IN-01 (loopback origins) and IN-02 (inline resolver copy) are not fixed here. They go to a follow-up after landing. Update 191-REVIEW-DISPOSITION.md: WR-01..03 become `fixed` with the commit, and IN-01/02 become `deferred`.
- **D-04 (191 D-03):** merge with a merge commit, never squash or rebase-merge. No force push.
- **D-05 (191 D-22):** the push step refuses unless the recorded scan HEAD equals the push HEAD and the scan exited 0. Any new commit means a rescan. First run `finalize-191.sh` to land the post-sync planning records, then fix, then scan, then push.
- **D-06 (AGENTS.md):** if CI is red, fix forward on the branch autonomously: new commit, rescan, then push the update. Keep retries tied to the observed cause. When delivery is uncertain, read and reconcile before writing again. Ask the user only for missing credentials, an external approval, or work outside scope.
- **D-07 (LAND-04):** the merge gate shows the PR URL and the head commit in plain language. The user's `allow` or `hold` binds internally to that head only. If the head changes after `allow`, the approval is void and the user is asked again. The user never copies hashes.
- **D-08 (178 D-18/D-23):** PR CI tests GitHub's synthetic merge commit. Record which commit each check actually ran on, and don't call the PR head "merged main".

### Claude's Discretion
- PR title and description: plain language, listing the commit groups (candidate, fixes, carries, sync) and linking 191-VERIFICATION.md.
- How CI is polled and how the evidence files under `192-EVIDENCE/` are laid out.

### Deferred Ideas (OUT OF SCOPE)
- IN-01: `usable_activation_origin?/1` accepts loopback origins. A follow-up after landing.
- IN-02: the inline copy of the evidence-path resolver can drift. A follow-up after landing.

Out of bounds (domain section): package release and Hex publish; force push, protection bypass and `--admin` merge; any git operation in the recovery checkout (planning files are plain-file edits only); deleting the trial branches, the clone or the recovery checkout (Phase 193).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAND-03 | A PR to `main` is open and every required CI check passes. | One required check, `Crosswake CI` (app 15368), strict up-to-date; PR-only workflow; identify run by head SHA; synthetic merge ref recorded (sections Branch protection, CI mechanics). |
| LAND-04 | Merge only after the user answers `allow` for the displayed PR and head commit; after merge CI on `main` is green for the merge commit. | `gh pr merge --merge --match-head-commit` exists in gh 2.101.0; binding design; push-triggered runs on `main` are only Release Please (+ path-filtered See It Run Collateral); definition of "main green" needs a stated interpretation (Open Question 1). |
</phase_requirements>

## Summary

The Phase 191 state is exactly as STATE.md says: `<integration-clone>` is on `land/v25-v27`, clean, HEAD `98e0d3902b305089b9fe032f3036b716c2100e3e` (the SYNC commit), 112 commits ahead of `origin/main` `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, which is still the live tip of GitHub `main`. 191 left **one unfinished step by design**: `191-VERIFICATION.md`, `191-REVIEW.md` and `191-REVIEW-DISPOSITION.md` (and all of `192-*`) exist only as untracked plain files in the recovery checkout and are not in the clone, so `finalize-191.sh` (full mode) must run first and will create a second sync commit. There is **no push script in 191**: the D-22 refusal exists only as the `finalize-191.sh --check-binding` predicate; the actual push gate must be written in 192.

Three findings change how the plan must be ordered:
1. **WR-03 is a planning-file fix (the scanner lives in the recovery checkout and is carried into the clone by sync), not part of a clone code commit.** Fix and self-test it in the recovery checkout BEFORE `finalize-191.sh`, so the sync commit carries the fixed scanner. Only WR-01/WR-02 (and the `:ok =` hardening of `emit_bytes`) are a code commit in the clone.
2. **`ensure-clone-191.sh` (called by every finalize mode) refuses (`clone_diverged`) unless clone HEAD equals the last 40-hex SHA in `heads-191.txt`.** After the code commit, append one label line to `191-EVIDENCE/heads-191.txt` (plain file edit) before `finalize-191.sh --scan-only`, or the rescan cannot run.
3. **`crosswake-ci.yml` triggers on `pull_request` only.** Nothing named "Crosswake CI" runs on a push to `main`. "CI on `main` is green for the merge commit" must therefore be defined from what actually runs on the merge SHA (Release Please push run; path-filtered See It Run Collateral, which is always `cancelled` historically) plus the tree-equality link to the PR's tested synthetic merge. See Open Question 1.

**Primary recommendation:** order = WR-03 (recovery plain files + selftest control S33) -> `finalize-191.sh` -> WR-01/02 code commit in clone (red-before, affected tests, ledger `--check`) -> append head label -> `finalize-191.sh --scan-only` -> new 192 push-gate script (fixture-tested against a local bare remote) -> `--dry-run` then push `HEAD:refs/heads/land/v25-v27` -> `gh pr create` -> poll `Crosswake CI` on the head SHA -> show PR + head, bind `allow` internally -> `gh pr merge --merge --match-head-commit <bound sha>` -> verify merge commit shape, tree equality, Release Please run on the merge SHA, no publication, recovery snapshot identical.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Review-warning fixes (WR-01/02) | Integration clone (code commit) | CI | Test/script changes belong in the pushed tree. |
| Scanner fix (WR-03) and selftest | Recovery checkout (plain files) | Clone via sync commit | `scan-191.sh` is a `.planning/` script; carried by `finalize-191.sh` sync. |
| Push refusal (D-22) | New 192 gate script reading `finalize-191.sh --check-binding` | `git push` refspec discipline | No push script exists yet. |
| Required-check enforcement | GitHub branch protection | `gh pr checks --required` read | Server-side; strict up-to-date. |
| Approval binding (D-07) | Local run-folder binding record | `--match-head-commit` (server-side head match) | Two independent bindings: local record + GitHub's expected-head guard. |
| Main-side CI proof | GitHub Actions push runs on merge SHA | Tree-equality to PR synthetic merge | PR-only workflow means no Crosswake CI on `main`. |
| No-change proof for recovery checkout | `recovery-snap-191.sh` before/after | `recovery-tree-191.sh` for working tree | Reused from 191. |

## Standard Stack

No external packages are installed in this phase. Tools only.

| Tool | Version (verified) | Purpose |
|------|--------------------|---------|
| `gh` | 2.101.0 (2026-09-15) | PR create, `pr checks`, `pr view --json`, `pr merge --merge --match-head-commit`, run/check-run GETs [VERIFIED: `gh --version`, `gh pr merge --help`] |
| `git` | 2.41.0 | Pinned via `git-pinned-191.sh` `g()` |
| `gitleaks` | 8.30.1 (the scanner pins this exact version) | Inside `scan-191.sh` [VERIFIED: `gitleaks version`; scan-191.txt `gitleaks_version 8.30.1`] |
| Elixir / OTP / Node | 1.19.5 / 27 / v26.10.0 | Affected tests and the ledger script [VERIFIED: tool output] |

**Package Legitimacy Audit:** not applicable, no external packages are installed or recommended. Packages removed (SLOP): none. Packages flagged (SUS): none.

`gh pr merge` flags verbatim from `--help`: `--match-head-commit SHA   Commit SHA that the pull request head must match to allow merge`, `-m, --merge`, `-t, --subject`, `-b, --body`, `-d, --delete-branch`, `--auto`, `--admin`. Never pass `--admin`, `--auto`, `--squash`, `--rebase`.

## Phase 191 state (verified)

| Item | Finding |
|------|---------|
| Locate | `scripts/locate-191.sh` walks up from its own location to the folder holding `.planning` and `.git` (recovery checkout, `REC`), finds exactly one sibling folder containing `candidate-a53fbef-full.bundle` and `candidate-a53fbef.bundle` (backup root), derives the durable candidate as `crosswake-candidate-durable` beside it, and writes `/private/tmp/crosswake-phase191-run/env-191.sh` atomically every run. Run folder must be owned by the user with mode 700 or it exits 2 [VERIFIED: locate-191.sh]. |
| Env file | Variables in `env-191.sh` (names only; values contain private paths, never record them): `REC BR D PARENT IC DENY R191 WS P191 P190 EV S191` plus the constants `BRANCH=land/v25-v27`, `MAIN_SHA=d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, `CAND_HEAD=2faf15a255f644c869d321508c4d3f3007572138`, `BASE_A53=a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, `MERGE_BASE=52345b48bb32e25b3ec9390e81612bacc8688f5d`. `IC` is the integration clone. Usage in a script: `sh "$HERE/locate-191.sh" >/dev/null; . /private/tmp/crosswake-phase191-run/env-191.sh; . "$HERE/git-pinned-191.sh"`. In RESEARCH/PLAN/evidence write `<integration-clone>` only. |
| Clone state now | Branch `land/v25-v27`, status clean (0 porcelain lines), HEAD `98e0d3902b305089b9fe032f3036b716c2100e3e`, `rev-list --count origin/main..HEAD` = 112, local branches: `carry-trial carry-trial-2 carry-trial-3 land/v25-v27 main`, remote-tracking `candidate-src`; remote `origin` is an HTTPS GitHub URL with `tagopt = --no-tags`; clone-local identity is the public noreply identity [VERIFIED: g() reads]. Remote `main` tip = `d0dbdf7b...` (unchanged) [VERIFIED: `gh api branches/main`, `ls-remote`]. |
| Heads record | `191-EVIDENCE/heads-191.txt` lines: FORMAT, LOCALE, G1, PRIVACY, HOST-G2G6, SWIFT-G4, WR-05, WR-01-06, WR-03, ADOPTION-EXT, RESOLVER, CARRY-v23.0..v27.0, FIXTURE `7075a441...`, `SYNC 98e0d3902b305089b9fe032f3036b716c2100e3e` (last line) [VERIFIED: file read]. |
| Scan record | `191-EVIDENCE/scan-191.txt`, plain `key value` lines: `head 98e0d390...`, `main d0dbdf7b...`, `preserved 2faf15a2...`, `scan_exit 0`, `adopter_check skipped_by_user_decision A-14`, then the `scan:` labels (`commits 112`, `blocking_final 0`, `gitleaks_findings 0`, `result clean`). Written by `finalize-191.sh` step (e) via temp file + `mv -f` into `$EV` (the recovery checkout, a plain file). |
| finalize contract | Modes: `''` (sync + verify + re-checks + scan), `--scan-only` (scan only), `--check-binding` (prints `finalize: binding pass`/`binding fail`, exit 0/1). Exit 0 pass, 1 check failed, 2 scope/input error, 3 stopped before scan (`FINALIZE_STOP_BEFORE_SCAN=1`). All modes call `ensure-clone-191.sh` and require output line `ensure-clone: reused`, branch = `$BRANCH`, clean tree. Full mode: builds a `--sync` manifest of late records vs clone HEAD, applies and commits a `Planning-Carry: sync` commit when non-empty, appends label `SYNC`/`SYNC-N` to `heads-191.txt` AFTER verify, verifies full carry vs `MAIN_SHA` with an independent floor, requires that no non-`.planning/` path changed since the last non-SYNC head, and if a sync commit was made re-runs `suite-gate-191.sh root` (floor from `checkpoints-191.txt` `resolver_tests`), the planning subset, and four checks (`phase167_js`, `adoption_scan`, `integrity_script`, `ledger_check`) [VERIFIED: finalize-191.sh]. Prior run: 2660 tests / 0 failures root, 951 subset (suite-root-SYNC.txt, suite-SYNC.txt). Runtime of the full mode is not recorded; treat as tens of minutes [ASSUMED]. |
| D-22 in code | The only code is the `--check-binding` predicate, verbatim: `grep -qx "head $H" "$SC" && grep -qx "main $MAIN_SHA" "$SC" && grep -qx 'scan_exit 0' "$SC"` with `H=$(g "$IC" rev-parse HEAD)`. It is **not** wired to any push; `grep` of the 191 scripts finds no `git push`. 192 must add the gate (see Pattern 2). |
| Unfinished from 191 | (a) Post-cut records not in the clone: `191-VERIFICATION.md`, `191-REVIEW.md`, `191-REVIEW-DISPOSITION.md` are `MISSING` at clone HEAD; the whole `192-pr-ci-and-merge/` folder is untracked in the recovery checkout [VERIFIED: `cat-file -e`, `git status`]. (b) `carry-table-191.tsv` puts `phases/1@(89\|90\|91\|92\|93)-*` in the `v27.0` bucket, so one sync carries all of them as they exist at that moment. |
| Consequence for the PR | Anything written under `.planning/` after the last sync (192 EVIDENCE, SUMMARY, VERIFICATION, STATE edits, the D-03 disposition update) is NOT in the pushed tree and must not trigger another sync/push (that would change the PR head and void the approval). Recommended: freeze the PR head at the post-fix scan; land later 192 records via Phase 193's normal flow, as STATE.md already says for "the scan record for the final PR head". |

## WR-01, WR-02, WR-03: defects and minimal fixes

### WR-01 (clone code commit)
- **Defect (verified):** `phase170_vacuous_assertion_ledger_test.exs` lines 484-499 run `--emit-snapshot` under `LC_ALL=C`/`LANG=C`, assert `exit_code == 0` and `{:ok, %{"rows" => _}} = JSON.decode(output)` only.
- **Fact (verified this session):** under `LC_ALL=C LANG=C` the current script emits **bytes identical** to `LC_ALL=C.UTF-8` and to the committed `script/collection_assertion_ledger.json` (`cmp` equal; 183 raw em dashes, 0 `—` escapes). The ledger contains exactly one non-ASCII code point, U+2014.
- **Caveat on the review's claim:** running the parent of the LOCALE commit's script (`5fd65f9f^`) under `LC_ALL=C` produced output that is **not decodable JSON** ("Invalid \escape"), so the existing decode assertion would likely already have failed on that older code. The reviewer's "escaped but valid JSON" path was not reproduced. The fix is still right because byte equality is strictly stronger. Do not rely on this caveat in the plan; use byte equality as the red-before evidence instead.
- **Minimal fix:** replace the final assertion with `assert output == File.read!(@ledger)` (exact bytes of the committed ledger, the property the gate checks). Keep the exit-code assertion. Optionally also `assert output =~ "—"`.
- **Companion hardening (script):** in `script/inventory_collection_assertions.exs` `emit_bytes/1` (lines 98-101: `:io.setopts(:standard_io, encoding: :latin1)` then `IO.binwrite(data)`) change to `:ok = :io.setopts(...)`.
- **Red-before evidence:** run the pre-fix `emit_bytes` (or the version without `:latin1`) under `LC_ALL=C` and show `cmp` against the committed ledger fails; then green with the fix. Mirrors `red-WR01-191.txt` style evidence in 191-EVIDENCE.

### WR-02 (clone code commit)
- **Defect (verified):** `phase170_vacuity_taxonomy_convention_test.exs` `phase_dirs_with_verification/0` pipes the 7-entry `@v23_phases` through `Enum.filter(&File.dir?/1)` and the findings-floor test asserts `length(@v23_phases) == 7` (a literal against itself) and `length(examined) >= 1`.
- **Verified now:** all 7 roster phases resolve to a directory and each has exactly 1 `*-VERIFICATION.md` in the clone, so the strengthened test will pass.
- **Minimal fix:** resolve every roster entry with `Crosswake.Test.PhaseEvidencePath.resolve(@workstream, &1)`; assert none is missing and that `length(examined) == 7`; delete the tautology.
- **PITFALL (ledger):** do NOT use the review's suggested `assert Enum.all?(dirs, &File.dir?/1)`. `script/inventory_collection_assertions.exs` inventories `assert Enum.all?/any?` and `refute` shapes in `test/**/*.exs` (243 rows now, `--check` currently prints "OK: 243 classified collection-assertion site(s), ledger matches the live tree exactly"). A new `assert Enum.all?` site is unclassified and fails `--check`, the ledger test and the `ledger_check` in finalize. Use a non-listed shape instead: `missing = Enum.reject(dirs, &File.dir?/1)` then `assert missing == []`, plus `assert length(examined) == length(@v23_phases)`. Neither phase170 test file currently has ledger rows, so no ledger regeneration should be needed; run `elixir script/inventory_collection_assertions.exs --check` after the edit to prove it.
- **PITFALL (fixture-count test):** the ledger test asserts exactly 6 raw grep matches of the vacuity shapes inside its own fixture heredocs (test around line 479). Do not add literal `Enum.all?`/`Enum.any?` text to `phase170_vacuous_assertion_ledger_test.exs`.

### WR-03 (recovery plain files, carried by sync)
- **Defect (verified):** `scan-191.sh` line 197: `g "$REPO" notes list > "$SC/notes.ref" 2>/dev/null || : > "$SC/notes.ref"`; line ~201: `g "$REPO" cat-file blob "$no" > "$SC/notebody.txt" 2>/dev/null || continue`.
- **Fixture facts (verified in a scratch repo):** `git notes list` with no notes ref exits **0** with empty output, so the listing fallback only ever masks real errors; with a note whose blob object is deleted, `notes list` still exits 0 and lists the entry, while `cat-file blob` exits 128 (`fatal: git cat-file <sha>: bad file`).
- **Minimal fix:** `g "$REPO" notes list > "$SC/notes.ref" 2>/dev/null || fail "notes list failed"` and `... cat-file blob "$no" > "$SC/notebody.txt" 2>/dev/null || fail "cat-file failed"` (`fail` prints `scan: <msg>` and exits 2; label text fixed, no value printed).
- **Self-test:** add control `S33` to `selftest-scan-191.sh` (pattern of S01-S32: `ctl_s33` + `run_ctl S33 ctl_s33 "unreadable git note is a scope error"`): in the `mk_tree` fixture add a commit, `g "$R" -c user.name=... -c user.email=... notes add -m body HEAD`, delete the note blob's loose object file, `run_scan`, `expect 2 "scan: cat-file failed"`. The file's own end check is `[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 26 ]`; the last prior line is `selftest-scan: controls 32 of 32 as expected`, new expectation `controls 33 of 33`. Red-before: run S33 against the unfixed scanner and capture that it reports "NOT as expected" (or that the scan returns 0).
- **Command:** `bash <recovery>/.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/selftest-scan-191.sh` (output lines `Snn name: as expected`; exit 0 only when all pass). `--tracer` runs only S01-S04.
- **Deviation from D-01 wording:** D-01 says one commit fixes all three. WR-03 cannot be in the clone code commit without being a `.planning/` change; it rides the sync commit. Record this in the plan's decision trace so verification does not look for a WR-03 hash in the code commit.

### Affected-test commands (run inside `<integration-clone>`, after committing the fix)
```bash
# via the existing gate (writes evidence under $EV, floor must be >= 1; empty-red.txt already exists in the run folder)
sh "$S191/suite-gate-191.sh" subset "$IC" HEAD LAND-FIX "$R191/empty-red.txt" \
  test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs \
  test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
# equivalent raw form (suite-gate runs: env LC_ALL=C.UTF-8 LANG=C.UTF-8 MIX_ENV=test mix test --no-color PATHS)
( cd "$IC" && LC_ALL=C.UTF-8 MIX_ENV=test mix test --no-color \
  test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs \
  test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs )
( cd "$IC" && elixir script/inventory_collection_assertions.exs --check )   # must print OK, exit 0
```
Also run `test/crosswake/planning` quickly if the sync touched planning checks (finalize already does this).

## CI, protection and merge mechanics (all read-only GET)

### Branch protection on `main` [VERIFIED: `gh api repos/szTheory/crosswake/branches/main/protection`]
- `required_status_checks`: `"strict":true`, `"contexts":["Crosswake CI"]`, `"checks":[{"context":"Crosswake CI","app_id":15368}]`. This is the **only** required check. App 15368 is GitHub Actions.
- No `required_pull_request_reviews` key (no required reviews). `enforce_admins: true`. `required_signatures: false`. `required_linear_history: false`. `allow_force_pushes: false`, `allow_deletions: false`. `required_conversation_resolution: false`. No repository rulesets (`gh api repos/.../rulesets` -> `[]`).
- Repo settings: `allow_merge_commit:true`, squash and rebase also true (so server will not stop a squash; the discipline must be in our command), `allow_auto_merge:true`, `delete_branch_on_merge:true` (the remote `land/v25-v27` is deleted automatically on merge; local branch stays), `merge_commit_title:"MERGE_MESSAGE"`, `merge_commit_message:"PR_TITLE"` (merge commit reads "Merge pull request #N from .../land/v25-v27" with the PR title as body, inferred from the API enum values). `default_workflow_permissions: write`.
- `strict:true` means the PR head must contain current `main`. If `main` moves before the merge (for example any of the open Dependabot PRs #210, #211, #239-#241, or #238 merged by someone), `mergeStateStatus` leaves CLEAN and the merge is refused. **Do not use `gh pr update-branch` or the UI "Update branch":** GitHub would create a server-side merge commit that bypasses the local scan (D-22) and changes the head (voids `allow`). Instead merge `origin/main` into the branch in the clone, rescan with the new base, push, rerun CI, ask again.
- Auth: `gh auth status` shows the account active with scopes `gist, read:org, repo, workflow`; repo permissions `admin/push true`. Branch protection read works with it. Token values never recorded.

### Push credential trap (new, verified)
`g()` from `git-pinned-191.sh` exports `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_TERMINAL_PROMPT=0` and unsets `GIT_*` config, so the user's global `credential.helper` entries are invisible to it. A read (`ls-remote`) works because the repo is public; a **push will fail to authenticate** through plain `g()`. The clone's own config has no credential helper. Use an explicit helper per command: `g "$IC" -c credential.helper= -c 'credential.helper=!gh auth git-credential' push ...` (`ls-remote` with this form verified to run; the push itself was not run). Prove the path with `push --dry-run` before the real push, and fixture-test the wrapper's argument handling against a local bare repo per the AGENTS.md lesson (exercise the real adapter, retain a privacy-safe cause for each blocked stage).

### Workflows and triggers [VERIFIED: files read at clone HEAD; `.github/` is byte-identical to `origin/main`, `diff --stat` empty]
| Workflow | Trigger | Relevance |
|----------|---------|-----------|
| `crosswake-ci.yml` (`name: Crosswake CI`) | `pull_request` only. `concurrency: group crosswake-ci-<repo>-pr-<N>`, `cancel-in-progress: false`. | Required check job id `merge-blocking-crosswake-ci`, `name: Crosswake CI`, `if: always()`, `needs:` ~49 jobs. Its `classify-change` job calls `script/classify_ci_change.py --base <PR base sha> --merge <HEAD of the merge checkout>`. |
| `cancel-obsolete-crosswake-ci.yml` | `workflow_run` of "Crosswake CI", `requested` | Cancels strictly-lower runs for the same PR after a new push; so an update push supersedes the prior run. |
| `release-please.yml` | `push` to `main`, `workflow_dispatch` | Runs on the merge SHA; see below. |
| `see-it-run-collateral.yml` | schedule, dispatch, and `push` to `main` with path filters | **Will fire on this merge**: the branch changes `examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift` and `examples/phoenix_host/lib/**` (listed paths). Permissions `contents: write`, `pull-requests: write`, `timeout-minutes` 30/35/20, concurrency `see-it-run-collateral` with `cancel-in-progress: true`. History: every recent `push` and `schedule` run ended `cancelled` (7 of 7 listed, e.g. push at 2026-10-11, schedule 2026-10-19) [VERIFIED: `gh run list --workflow`]. It is not a required check; treat it as a known-cancelled advisory and say so plainly in the main-green record rather than waiting on it. |
| `ios-tag-recovery.yml` | push to `main` on two specific paths | Not touched by the branch (diff empty) - will not fire. |
| others | `workflow_dispatch` / `schedule` / `workflow_call` | Not triggered by merge. |

### Release Please / publish on merge (success criterion 4) [VERIFIED: release-please.yml and manifest diff]
- On push to `main`: job `approved-release-guard` ("release: approved-candidate merge guard"), job `release-please` (`googleapis/release-please-action@v4.1.3`), rollup jobs, and a family of `publish-*`, `clean-room-*`, `exact-public-proof` jobs.
- The guard exits early (`parent_count -ge 2 || exit 0`) for single-parent commits (our predecessor squash PR). **Our merge commit has two parents, so the full version-comparison logic runs** for the first time on a normal merge. With no version change it reaches the final `else exit 0` branch: verified that `mix.exs`, all five `packages/*/mix.exs`, `packages/crosswake-shell-core-android/build.gradle.kts` and `.release-please-manifest.json` are **unchanged** between `origin/main` and clone HEAD (0 changed paths; manifest `".": "0.2.11"` on both). So `linked_release=false`.
- `release-please` step runs with `skip-github-release: ${{ needs.approved-release-guard.outputs.rel17_context == '' }}`, i.e. true on a normal merge: it can only create/update the release PR (currently open #236 "chore: release main", branch `release-please--branches--main`), never a GitHub release/tag.
- Every `publish-*` job requires `linked_release == 'true'` or a companion `*_release_created == 'true'` plus `rel17_operation == 'companion_publish'`; none can be true here.
- Oracle from a comparable normal push (run for `d0dbdf7b`): `success` for guard, Release Please, "release: linked release rollup", "Native release status rollup"; every job named `Publish ...`, `Mirror iOS core ...`, `Clean-room proof ...`, `release: exact-public artifact proof`, `Strip stale release-as ...`, `Alert on ...`, `Assert lockstep ...` is `skipped` [VERIFIED: `gh run view ... --json jobs`].
- Expected after-merge side effect (STATE assumption A4, still plausible): Release Please may update PR #236 with a proposed bump because 112 commits include `lib/` changes. Updating the proposal is not a release. Do not merge #236.
- **Baselines to capture BEFORE the merge and compare after (public data):** latest GitHub release `crosswake_chimeway-v0.1.2` (2026-10-11T19:22:09Z); newest tags `v22.0 v19.0 v17.0` from `/tags`; Hex latest_stable: crosswake 0.2.11, crosswake_rulestead 0.1.1, crosswake_rindle 0.1.0, crosswake_sigra 0.1.3, crosswake_chimeway 0.1.2, crosswake_threadline 0.1.0. After the merge the same GETs must return identical values.

### Identifying runs and commits
- PR event: the workflow run's `head_sha` is the **PR head**; the job checkouts use GitHub's synthetic merge ref `refs/pull/<N>/merge` (the workflow comment says "Check out the synthetic merge with full history"). Per 178 D-18, `release-candidate-full-proof` deliberately checks out the PR head instead; record those jobs as head-sourced.
- Run for a head: `gh run list -R szTheory/crosswake --workflow crosswake-ci.yml --commit <head> --json databaseId,event,conclusion,status,headSha`.
- Check-run for a head (the required one): `gh api repos/szTheory/crosswake/commits/<head>/check-runs --paginate` filter `name=="Crosswake CI"` and `app.id==15368`; `gh pr checks <N> --required --json name,state,bucket` is the CLI form (`--required` and `--watch --fail-fast` exist in 2.101.0).
- Synthetic merge SHA: `git ls-remote origin refs/pull/<N>/merge` (read) or `gh api repos/.../pulls/<N> --jq .merge_commit_sha` while open; its tree: `gh api repos/.../git/commits/<sha> --jq .tree.sha`. **Record the synthetic merge commit SHA and its tree right before asking for `allow`** (and confirm it is unchanged). After the merge, compare the real merge commit's tree to that recorded tree; with `strict:true` and an unmoved `main` they are equal, which is the evidence linking "PR CI green" to "main content". If the object is no longer retrievable after merge, the pre-merge record is the evidence (that is why it is captured first).
- Typical runtime: Crosswake CI runs for recent PRs took about 21 to 25 minutes (3e8a4b26: 23:34Z -> 23:55Z; 9be3e2bb: 19:29Z -> 19:54Z) [VERIFIED: `gh run list`]. Release Please push runs took about 3 to 8 minutes. Dependabot PRs currently show failing `Crosswake CI` (not our concern).
- Scale caveat: the PR has 112 commits and 189 non-planning changed files (3,521 paths in the scan). GitHub's PR files API and `gh pr diff` are known to refuse very large diffs (~3,000 files) [ASSUMED]; do all diffing locally with `g`, and use `gh pr view --json headRefOid,mergeStateStatus,mergeable,state,statusCheckRollup` for state.

## Architecture Patterns

### Flow
```
recovery plain files: fix scan-191.sh (WR-03) + selftest S33 + red-before
   -> finalize-191.sh (sync commit SYNC-2: VERIFICATION/REVIEW/192 records + fixed scanner; root suite + subset + 4 checks; scan at that HEAD)
   -> clone code commit: WR-01 + WR-02 (+ :ok = hardening)    [g() commit, clone only]
   -> affected tests (suite-gate subset) + ledger --check + red-before evidence
   -> append "LAND-FIX <sha>" to heads-191.txt (plain file)  [else ensure-clone says clone_diverged]
   -> finalize-191.sh --scan-only  => scan-191.txt bound to new HEAD (copy the old 98e0d390 record into 192-EVIDENCE first, it is overwritten)
   -> push gate script (new): --check-binding pass + remote main == MAIN_SHA + clean tree + branch + refspec fixed + no force
   -> push --dry-run, then push HEAD:refs/heads/land/v25-v27  (explicit refspec, credential helper per command)
   -> gh pr create -R szTheory/crosswake --base main --head land/v25-v27 --title ... --body-file ...
   -> poll head-SHA runs until "Crosswake CI" concludes (fix-forward on red: new commit -> affected tests -> rescan -> push gate -> push)
   -> record head, synthetic merge SHA + tree, mergeStateStatus CLEAN, baselines
   -> show PR URL + head in plain language; user: allow | hold
   -> allow: write internal binding {pr, head, synthetic tree, nonce, consumed:false}; re-read PR; head == bound and CLEAN and check success => mark consumed, then
        gh pr merge <N> -R ... --merge --match-head-commit <bound head>
   -> post-merge: read PR state (never re-run write on uncertain delivery), merge commit has 2 parents (first = MAIN_SHA, second = bound head), tree == recorded synthetic tree
   -> wait for push runs on merge SHA: Release Please success, publish-class jobs skipped; See It Run Collateral noted
   -> baselines unchanged (release, tags, Hex); recovery-snap-191 identical to recovery-after-191.txt
```

### Pattern 1: gate on the live read, not the cached read
Every write (push, merge) re-reads the controlling fact immediately before: clone HEAD, `ls-remote origin refs/heads/main`, the scan record, PR `headRefOid`, `mergeStateStatus`, and the required check conclusion for that exact SHA.

### Pattern 2: push gate script (new `push-192.sh`, POSIX sh, sources locate/env/git-pinned like finalize)
Refuse (exit non-zero, fixed labels only) unless ALL hold: `sh finalize-191.sh --check-binding` prints `finalize: binding pass`; clone branch is `$BRANCH`; status porcelain empty; `ls-remote origin refs/heads/main` == `$MAIN_SHA`; target ref is exactly `refs/heads/land/v25-v27`; argument list contains no `--force`, `-f`, `--force-with-lease`, `+` refspec, `--mirror`, `--all`, `--tags`, `--delete`. For an update push after a CI fix, also require the remote branch tip to be an ancestor of local HEAD (plain fast-forward). Push `HEAD:refs/heads/land/v25-v27` only. Never push `carry-trial*`, `candidate-src`, or tags. Provide a selftest using a local bare repo as `origin` that proves: stale scan refuses, dirty tree refuses, wrong branch refuses, moved remote main refuses, force flag refuses, ok path pushes only the one ref.

### Pattern 3: merge gate with internal binding (D-07)
The user types `allow` or `hold`. The script, not the user, captures `headRefOid` at display time into a mode-600 binding file in the run folder. Merge step requirements: binding exists and is not consumed; current `headRefOid` equals bound head; `state==OPEN`; `mergeStateStatus==CLEAN`; the `Crosswake CI` check-run for that head is `success`; then mark consumed BEFORE the call and invoke `gh pr merge <N> -R szTheory/crosswake --merge --match-head-commit <bound>`. `--match-head-commit` is the server-side second guard (rejects if the head moved after the check). If the call returns an error or times out, do not repeat it: read `gh pr view --json state,mergeCommit,headRefOid` and reconcile. Fixture-test the gate with a `gh` shim returning the real JSON shapes (take shapes from a read of an existing PR such as `gh pr view 236 --json headRefOid,state,mergeStateStatus,statusCheckRollup`) and assert the shim saw exactly `--merge --match-head-commit <sha>` and never `--squash/--rebase/--admin/--auto`.

### Pattern 4: no-change proof for the recovery checkout (reuse 191)
`REC_GIT="$REC/.git" sh "$S191/recovery-snap-191.sh"` digests HEAD file, packed refs, loose refs, stash log, worktrees, config, index content (`ls-files -s`), HEAD reflog and object-file count. **Verified now:** its output is identical to `191-EVIDENCE/recovery-after-191.txt` (diff empty), so that file is a valid "before" for 192; also save a fresh `recovery-before-192.txt` at phase start and `recovery-after-192.txt` at the end, then `diff` them. Working-tree compare: `recovery-tree-191.sh` (`snapshot TOP NAMED VOLATILE [TRACKED]` / `compare BEFORE AFTER NAMED`) with `recovery-named-191.tsv` and `recovery-volatile-191.txt`; the `.planning/` files edited as plain files by this phase need to be added to a 192 named list. Do not run `git status` in the recovery checkout to prove this (reads are fine, but the snapshot is the evidence). Current recovery HEAD is `d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377`.

### Anti-Patterns to Avoid
- `gh pr update-branch`, UI "Update branch", `--admin`, `--auto`, squash/rebase merge, `--delete-branch` with extra effects (repo setting already deletes the remote head branch; do not touch trial branches).
- Pushing any ref other than the one explicit refspec. Pushing tags.
- Writing `192-EVIDENCE` content, STATE or the D-03 disposition into `.planning/` and then re-running sync+push (changes head, voids approval). Keep those as post-merge plain-file records.
- Counting the PR head as "merged main" (D-08); counting See It Run Collateral as a main CI failure or success.
- Piping a gate into `tail`/`head` and reading its exit code (project memory: pipe masks exit codes). Capture to a file, read `$?`, then `tail` the file.
- Recording `<integration-clone>` real path, backup root, home path, account name, tokens in any evidence or PR text.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sync of late planning records | A new copy/commit script | `finalize-191.sh` (full mode) | Manifest, floor, verify, suite gates and scan are already bound together. |
| HEAD-bound scan | New scanner | `finalize-191.sh --scan-only` / `scan-191.sh` | Binding file format is what `--check-binding` reads. |
| Pinned git environment | Raw `git` in the clone | `g()` from `git-pinned-191.sh` | Scrubs env/hook/config surface; add only the explicit `-c credential.helper` for push. |
| Binding approval to a head | A homemade hash prompt | `gh pr merge --match-head-commit` plus the internal binding record | User must never copy hashes (D-07). |
| Required-check state | Parsing Actions logs | Check-runs API / `gh pr checks --required --json` | Stable shape. |
| Recovery no-change proof | New digest | `recovery-snap-191.sh` | Already validated, identical output now. |

## Common Pitfalls

1. **Stale `heads-191.txt` blocks the rescan.** `ensure-clone-191.sh` compares clone HEAD with the last 40-hex SHA in `heads-191.txt`. After the code commit, append a label line first. Warning sign: `finalize: clone not reusable`.
2. **Running finalize full mode after the code commit.** The `non_planning_paths` check diffs the last non-SYNC head to HEAD and must be 0; a code commit makes it fail (`sync_checks_failed`). Run full finalize before the code commit (matches D-05), `--scan-only` after.
3. **`scan-191.txt` is overwritten** by the rescan. Copy the 98e0d390 record (and the SYNC-2 record) into `192-EVIDENCE/` first.
4. **Ledger drift** from adding `assert Enum.all?/any?` in the WR-02 fix (see above). Warning sign: `ledger_check` or the ledger test fails.
5. **Credential helper hidden by `g()`** makes the push fail with a prompt-less auth error (see above). Use `--dry-run` first; the dry run must authenticate to be meaningful.
6. **Main moves.** Strict protection blocks the merge; re-validate `ls-remote` main right before the ask and again at merge. Any base change means rescan from the new base (scan takes `BASE HEAD`; `MAIN_SHA` is hard-coded in env-191.sh and `--check-binding`, so a moved base requires updating the plan's constants deliberately, not silently).
7. **`Crosswake CI` name collision.** The workflow, the aggregator job and the required context are all "Crosswake CI". Select by check-run name AND `app.id==15368` AND head SHA, not by workflow name alone. A cancelled superseded run on an older head is not evidence for the new head.
8. **Aggregator `if: always()`** produces a check conclusion even when upstream jobs fail/skip; read the aggregator conclusion for the head, and also list non-success upstream jobs in evidence for diagnosis.
9. **Main-side "green" ambiguity** (below): an automated gate that waits for a non-existent `Crosswake CI` push run would hang; one that treats `cancelled` See It Run Collateral as red would block forever.
10. **Fix-forward loop discipline (D-06).** Each red cause gets a new commit, affected local test, rescan with the head label appended, push gate, push. Cause-keyed retries only. Rerunning a flaky job via `gh run rerun` is a write on remote CI: allowed by the standing instruction only for observed infrastructure causes and must be recorded.
11. **Privacy of PR text.** Title/body are public: no clone path, no real name of the adopter, no account name beyond the public repo owner, no home paths. Run the same fragment patterns (home path, temp path, token shapes) over the PR body file before `gh pr create`.

## Code Examples

```bash
# Source: verified this session (read-only forms)
. /private/tmp/crosswake-phase191-run/env-191.sh; . "$S191/git-pinned-191.sh"
g "$IC" rev-parse HEAD
g "$IC" rev-list --count origin/main..HEAD
g "$IC" ls-remote origin refs/heads/main
gh api repos/szTheory/crosswake/branches/main --jq '.commit.sha'
gh pr view <N> -R szTheory/crosswake --json headRefOid,state,mergeStateStatus,mergeable,statusCheckRollup
gh api repos/szTheory/crosswake/commits/<head>/check-runs --paginate --jq '.check_runs[]|select(.name=="Crosswake CI")|[.app.id,.status,.conclusion]|@tsv'
gh run list -R szTheory/crosswake --commit <merge_sha> --event push --json databaseId,name,status,conclusion,headSha
# parents of merge commit (shape check): two parents, first == MAIN_SHA, second == bound head
gh api repos/szTheory/crosswake/commits/<merge_sha> --jq '[.parents[].sha]'
```
```bash
# Source: gh pr merge --help (2.101.0) - the only merge form this phase may use
gh pr merge <N> -R szTheory/crosswake --merge --match-head-commit <bound-head-sha>
```
```bash
# Push form (to be wrapped by the gate; do not run outside it)
g "$IC" -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
  push --dry-run origin HEAD:refs/heads/land/v25-v27     # then the same without --dry-run
```

## State of the Art / project-specific truths

| Old assumption | Current truth |
|----------------|---------------|
| "Crosswake CI is the main CI" | It is a PR-only workflow; `main` push runs are Release Please (+ path-filtered See It Run Collateral). |
| D-01 "one commit fixes all three" | Two code fixes in the clone; the scanner fix is a planning-file edit carried by sync. |
| 191 left only evidence | 191 left the post-cut records unsynced and no push script. |
| Prior merges were squash (single parent) | This merge commit has two parents, exercising the release guard's multi-parent path for the first time on a normal merge (expected `exit 0`; risk noted in Open Questions). |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Full `finalize-191.sh` runtime is tens of minutes (root suite 2660 tests + subset + checks); runtime not recorded. | Phase 191 state | Planner underestimates wall time; use background run and file polling. |
| A2 | GitHub PR files API / `gh pr diff` refuse ~3,000+ file diffs. | CI mechanics | If wrong, harmless; local git diffing is still preferred. |
| A3 | `merge_commit_title/message` enum values mean the merge commit reads "Merge pull request #N from ..." with the PR title as body. | Branch protection | Cosmetic only. |
| A4 | The multi-parent path of the release guard returns `exit 0` for a merge with no version change (read the logic; never observed on a real merge in this repo). | Release Please section | If the guard errors, the Release Please push run goes red on `main` after merge; recovery would be a fix-forward PR. Mitigate by treating a red Release Please run on the merge SHA as a recorded finding and reading its failing step before any rerun. |
| A5 | Release Please updating PR #236 after the merge is the only expected side effect. | Release Please section | A new release PR content is not a release; confirm no tag/release/Hex change. |
| A6 | A `gh auth git-credential` helper supplies push credentials for HTTPS pushes from the pinned environment. | Push credential trap | Push fails at `--dry-run`; then a credential gap is a genuine "missing credential" ask. |
| A7 | See It Run Collateral will start on merge and end `cancelled` again (7/7 recent runs cancelled). | Workflows | If it completes red it could look like a main failure; the main-green record names it explicitly as advisory/non-required. |

## Open Questions (RESOLVED)

1. **What exactly counts as "CI on `main` is green for the merge commit"?**
   - Known: no `Crosswake CI` run exists for pushes to `main`; branch protection requires it only on PRs; push runs are Release Please and See It Run Collateral.
   - Unclear: whether the user's LAND-04 wording intends only the Release Please push run, or expects a Crosswake CI run on the merge commit (which cannot exist without a workflow edit, out of scope).
   - Recommendation: define it in the plan as three conjunctive facts, and state it plainly in the allow prompt: (1) required `Crosswake CI` check green on the PR head and the synthetic merge it ran on; (2) merge commit tree equals that recorded synthetic-merge tree; (3) all push-triggered runs on the merge SHA that are not known-cancelled advisories conclude success (Release Please success, all publish-class jobs skipped). Name See It Run Collateral explicitly. Do not add a workflow dispatch or edit workflows.
   - RESOLVED → R-1: main green means the three conjunctive facts above, stated in the allow prompt (192-09) and decided by `postmerge-192.sh verify` (192-05, 192-10).
2. **Where do the 192 records land?**
   - Known: anything written to `.planning/` after the last sync is not in the PR; pushing again voids approval.
   - Recommendation: one sync before the push (CONTEXT, RESEARCH, PLANs, 191 verification/review, fixed scanner); everything later (192-EVIDENCE, SUMMARY, VERIFICATION, the D-03 disposition `fixed/deferred` update, STATE/ROADMAP) stays as plain files in the recovery checkout and goes to Phase 193's normal flow. Record the code-commit SHA in the disposition then.
   - RESOLVED → R-2: exactly one planning sync (SYNC-2, 192-06) before the push, with no second sync; every later 192 record stays as a plain file in the recovery checkout and lands through Phase 193.
3. **Should the PR include a preflight that `main` has not moved and the open release/Dependabot PRs are left alone?** Recommendation: yes, assert `main == MAIN_SHA` before push and before the ask; do not merge or close #210/#211/#236/#238-#241 in this phase.
   - RESOLVED → R-3: `main == MAIN_SHA` is checked live before every push (192-01) and at proposal and merge (192-04, 192-09); other open PRs are recorded before the push (192-08) and compared after the merge (192-10), with only the Release Please PR refresh expected.
4. **If `Crosswake CI` is red for a cause unrelated to this change** (for example a Dependabot-style infrastructure failure), D-06 says fix forward only for causes observed; a pure infra flake may be rerun once per observed cause with the run id recorded.
   - RESOLVED → R-4: reruns only for an observed infrastructure cause, once per cause, recorded with its run id in fixforward-192.txt; code or test causes get a fix-forward commit (192-08).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` authenticated (repo, workflow scopes) | PR, checks, merge | yes | 2.101.0 | none (credential gap = ask) |
| `git` | clone ops | yes | 2.41.0 | - |
| `gitleaks` | scan | yes | 8.30.1 (exact pin) | none (scan refuses on mismatch) |
| Elixir/Mix, Node | affected tests, ledger | yes | 1.19.5/OTP 27, v26.10.0 | - |
| `/private/tmp/crosswake-phase191-run/` (mode 700) | env, empty-red.txt, run files | yes | 409 entries, owned by user | re-run `locate-191.sh` |
| Integration clone with `deps/` | affected tests | yes (clean, HEAD 98e0d390) | - | `ensure-clone-191.sh` recreates from `candidate-src` only if absent |
| HTTPS push credential via `gh auth git-credential` | push | untested (dry-run is the test) | - | ask the user for the credential only if the dry-run fails |

macOS `/private/tmp` erosion: the run folder and clone live under temp locations; the durable candidate and backups exist outside (Phase 189/190). Do not clear the run folder.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`), POSIX/bash selftests, `gh`/`git` read assertions |
| Config file | none new; reuses `suite-gate-191.sh`, `selftest-scan-191.sh` |
| Quick run command | `sh "$S191/suite-gate-191.sh" subset "$IC" HEAD LAND-FIX "$R191/empty-red.txt" test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` |
| Full suite command | PR CI (`Crosswake CI`) is the full judge per D-02; no local `--all` |

### Phase Requirements -> Test Map
| Req / Criterion | Behavior | Test Type | Automated Command | File Exists? |
|-----------------|----------|-----------|-------------------|--------------|
| D-01 WR-01 | C-locale snapshot equals committed ledger bytes; red on locale bug | unit + red-before | affected-test command above; red proof via pre-fix script `cmp` | edit existing test (Wave 0: red evidence file) |
| D-01 WR-02 | Missing roster phase fails; examined == 7 | unit + negative control | same command; add a negative control proving the helper reports a missing dir (temp fixture, predicate extracted like `taxonomy_recorded?`) | edit existing test |
| D-01 ledger safety | no ledger drift from new asserts | script | `elixir script/inventory_collection_assertions.exs --check` (exit 0, "ledger matches the live tree exactly") | exists |
| D-01 WR-03 | unreadable note -> scan exit 2 `scan: cat-file failed` | selftest control S33 | `bash selftest-scan-191.sh` -> `controls 33 of 33 as expected` | add control (Wave 0) |
| D-05/D-22 | push refused unless scan HEAD == push HEAD, scan_exit 0 | script selftest | new `selftest-push-192.sh` with local bare remote; each refusal label asserted | Wave 0 |
| LAND-03 / SC1 | PR open; `Crosswake CI` success on the head SHA | gh read | check-runs filter name + app 15368 + head == local HEAD; `gh pr view --json state` == `OPEN` | Wave 0 poll script |
| D-08 | evidence names head vs synthetic merge SHA/tree per check | evidence assertion | record both; assert synthetic tree captured pre-merge | Wave 0 |
| LAND-04 / SC2 | merge only after allow, only that head | gate selftest with `gh` shim | shim asserts args `--merge --match-head-commit <bound>`; stale/consumed binding refuses; changed head refuses | Wave 0 |
| D-04 | merge commit not squash/rebase | gh read | merge commit has 2 parents; first == `MAIN_SHA`; second == bound head | Wave 0 |
| LAND-04 / SC3 | main-side green | gh read | per Open Question 1: Release Please run on merge SHA `success`, `Publish*/Mirror*/Clean-room*/exact-public` jobs all `skipped`, tree equality | Wave 0 |
| SC4 publish/force/bypass | nothing released | gh/curl read | latest release, `/tags`, Hex `latest_stable_version` for 6 packages identical to pre-merge baselines; push refspec log shows no force; `--admin` never in argv log | Wave 0 |
| SC4 recovery | no git change | digest diff | `REC_GIT="$REC/.git" sh recovery-snap-191.sh` equals `recovery-before-192.txt` (and recovery-after-191) | exists |
| Privacy | PR body, evidence free of paths/tokens | scan | fragment-pattern grep over PR body file and 192-EVIDENCE; reuse `terms`-free classes from `scan-191.sh` | Wave 0 |

### Sampling Rate
- **Per task commit (clone):** quick run command + ledger `--check`.
- **Before push:** `finalize-191.sh --check-binding` plus push-gate selftest.
- **Before the ask / before merge:** live re-read of PR head, mergeStateStatus, check-run, remote main.
- **Phase gate:** all SC1-SC4 assertions green and recovery snapshot identical.

### Wave 0 Gaps
- [ ] `selftest-scan-191.sh` control S33 plus `scan-191.sh` fix (red then green)
- [ ] `push-192.sh` + `selftest-push-192.sh` (bare-remote fixture)
- [ ] CI poll script (head-SHA check-run, writes labelled evidence)
- [ ] merge-gate script + `gh` shim selftest + binding record format
- [ ] post-merge verifier (parents, tree equality, push runs, baselines)
- [ ] `recovery-before-192.txt` snapshot at phase start (identical to 191 after today)

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (push/merge credentials) | `gh auth git-credential` helper per command; never print or store tokens |
| V3 Session Management | no | - |
| V4 Access Control | yes | Branch protection (required check, strict, no force, enforce_admins); no `--admin` |
| V5 Input Validation | yes | Fixed refspec; SHA regex `^[0-9a-f]{40}$` before use; PR number integer-checked |
| V6 Cryptography | no | none hand-rolled; digests via `shasum -a 256` |

| Threat | STRIDE | Mitigation |
|--------|--------|------------|
| Pushing unscanned content | Tampering | Gate reads `--check-binding` immediately before push |
| Approval replay / TOCTOU on head | Tampering/Elevation | Internal binding, consumed-before-call, `--match-head-commit`, live re-read |
| Server-side branch update bypassing scan | Tampering | Forbid `update-branch`; rescan on any base change |
| Leakage of private paths/identity in PR text or evidence | Information disclosure | Fixed-label outputs, `<integration-clone>` placeholder, fragment-pattern scan of PR body |
| Accidental publish | Elevation | Versions unchanged (verified), `skip-github-release` true, publish jobs gated; baselines compared after |

## Project Constraints (from AGENTS.md)
- Zero-human verification: agent runs every check; the only human action is the plain `allow`/`hold` on the displayed PR and head (a one-use gate bound internally to that attempt; never ask the user to copy hashes).
- Standing authorization (Phase175) does NOT cover this phase; merge needs the fresh `allow`. Push and PR creation are in scope without further prompts per ROADMAP ordering rules; no force, no admin bypass, no protection change.
- Treat privacy rules as hard: no adopter identity, no home paths, no tokens in PR text, evidence, logs. Use `<integration-clone>`.
- Fail closed: any gate that cannot read its input exits non-zero with a fixed label; no silent skip (this is exactly WR-03's class).
- Before showing the merge proposal, exercise the production adapter with the dependency's actual return shape (real `gh` JSON) in a local fixture; retain a privacy-safe cause for every blocked stage.
- Do not repeat a completed GSD step; after planning, next is execute for Phase 192 (`$gsd-execute-phase 192 --ws quality-ratchet-release`) per workstream STATE once plans exist.
- Do not use piped checks that mask exit codes; write outputs to files and read `$?`.
- No staging/commit/branch/worktree/stash change in the recovery checkout; planning edits are plain files.

## Sources

### Primary (HIGH, read this session)
- `192-CONTEXT.md`, `191-CONTEXT.md` (D-03/D-22/D-23), `191-REVIEW.md`, `191-REVIEW-DISPOSITION.md`, `191-VERIFICATION.md`, `STATE.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `178-CONTEXT.md` (D-17/D-18/D-23)
- 191 scripts: `locate-191.sh`, `finalize-191.sh`, `ensure-clone-191.sh`, `git-pinned-191.sh`, `scan-191.sh` (lines 1-60, 170-260), `selftest-scan-191.sh`, `recovery-snap-191.sh`, `recovery-tree-191.sh`, `carry-table-191.tsv`, `carry-exclusions-191.tsv`, `suite-gate-191.sh` (header)
- 191-EVIDENCE: `heads-191.txt`, `scan-191.txt`, `sync-191.txt`, `suite-root-SYNC.txt`, `suite-SYNC.txt`, `recovery-after-191.txt`, `recovery-tree-check-191.txt`
- Clone files: `.github/workflows/*.yml` (triggers; full read of `release-please.yml` guard and job conditions, `crosswake-ci.yml` header and aggregator), `test/crosswake/proof/phase170_*`, `script/inventory_collection_assertions.exs`, `script/collection_assertion_ledger.json`, `test/support/phase_evidence_path.ex`
- GitHub GETs: repo settings, branch protection, rulesets, branch list, open PR list, check-runs and run list for `d0dbdf7b`, workflow run lists (`crosswake-ci.yml`, `release-please.yml`, `see-it-run-collateral.yml`), releases/tags, Hex package API
- `gh pr merge --help`, `gh pr create --help`, `gh pr checks --help`

### Tertiary (LOW)
- Runtime estimates for finalize and the large-diff API limit are from experience, tagged [ASSUMED].

## Metadata

**Confidence breakdown:**
- Standard stack/tools: HIGH (versions read)
- Architecture and ordering: HIGH for mechanics read from code; MEDIUM for the main-green definition (Open Question 1)
- Pitfalls: HIGH for items reproduced (notes behavior, heads-label coupling, credential isolation, ledger coupling); MEDIUM for A4 (guard multi-parent path)

**Research date:** 2026-10-23
**Valid until:** until `main` moves off `d0dbdf7b`, any workflow file changes, or branch protection changes (re-read before the push)
