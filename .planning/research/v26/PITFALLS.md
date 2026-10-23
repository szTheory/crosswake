# Domain Pitfalls

**Domain:** Hardening v25 proof/guard code before trusting it (v26.0 Harden Before Trust, workstream `quality-ratchet-release`, phases from 184)
**Researched:** 2026-10-15
**Overall confidence:** HIGH for repo-derived pitfalls (read from the dispositions, debt list and candidate code at `50fcd57`); HIGH for git behaviour quoted from git-scm docs; MEDIUM for ecosystem lessons marked "from knowledge".

Phase labels below are proposals, not a roadmap. Name them by what they own:
- **P-A Probe hardening:** the twin clean-tree/source-join probe (183 WR-01..04, IN-01..04) and its tests.
- **P-B Guard measurement and v25 vacuity:** SEED-018 (v25 code only), SEED-023, 182 WR-03/04/05, 181 M-03.
- **P-C Contract and privacy fixes:** 181 M-01/M-02/M-04/L-*, 182 WR-01/02/06, SEED-014 C-F re-check, CW-REQ-A decision.
- **P-D Rehearsal and twin-05:** preflight-only rehearsal, then the single run.

The suggested order is P-B measure, then P-A and P-C fixes, then P-B ratchet (make blocking), then P-D. The ordering reasons are in the pitfalls.

---

## Critical Pitfalls

### Pitfall 1: Guards land before fixes (wall of red, then waivers)
**What goes wrong:** SEED-018/SEED-023 style guards are made merge-blocking before anyone has counted what they flag. The first run is red on many sites, the team adds a waiver/allowlist to get green, and the waiver list becomes the new "absence scored as success".
**Why it happens:** A guard feels like progress; fixing the findings is slower. Repo already has `script/collection_assertion_ledger.json` and `collection_assertion_remediation.json`, which are exactly the mechanism by which a ledger becomes a standing waiver.
**Consequences:** Check goes green while asserting nothing for every waived site. Memory note: "measure a check's findings before making it merge-blocking" (PR #173 lesson).
**Prevention:**
- Run every new or extended guard in report mode first and record the count by site (a number in the phase evidence, not a vibe).
- Fix or explicitly disposition each v25-code finding in the same phase as the guard goes blocking. A waiver entry must carry: owner, reason, and an expiry condition. A ledger entry with none of those fails the guard itself.
- Ratchet direction only: the count in the ledger may go down, never up. Guard fails if the ledger lists a site that no longer exists (stale waiver) as well as if a new site appears.
- SEED-018 scope: v25 code only, unless the measured repo-wide count is small and mechanical; record that measured count as the evidence for either choice (see Pitfall 12).
**Detection:** A PR that edits the ledger/remediation JSON and the guard in the same diff; a ledger whose size grows; "known" items with no owner.
**Owner:** P-B (measure first, make blocking last in the milestone).

### Pitfall 2: "Fixes" that pass by weakening the test
**What goes wrong:** A failing assertion is relaxed (regex loosened, count made `>= 0`, fixture trimmed, `@tag :skip`, `refute` replaced with a log line) so the suite is green. 183 WR-04 already shows weak tests exist: a journey test that greps source, and a CLI leak test that injects a producer that already blocks.
**Why it happens:** The disposition table says every finding is "open" and a fix changes the head, which forces re-run costs (181: preflight, regression, handoff; 182: simulator harness, FINAL-HEAD refresh; 183: new run root). That cost pressure rewards the cheap green.
**Consequences:** Hardening that reduces assurance; the fix looks like closure in the disposition file.
**Prevention:**
- Every fix to a guard lands with a negative control: revert/neutralise the fix in a scratch copy and show the new test fails (the eight 183 mutation controls are the model; keep `mutation-*.log` style evidence).
- Review rule: in a diff touching `test/`, any deleted or loosened assertion needs a named reason in the commit/plan, and the plan checker looks for it. Count assertions before and after for touched test files (cheap script, no new dependency).
- Prefer fixing the code under test. Tests change only to add assertions or to replace a source-grep with a behavioural check.
**Detection:** Net assertion count drops; `@tag :skip`/`@tag :pending` added; regex `.*` widened; expected value computed from the same function under test.
**Owner:** P-A and P-B (all fix plans).

### Pitfall 3: Mutation controls that do not mutate; citations to moved tests that run 0 tests
**What goes wrong:** Both are already documented in RETROSPECTIVE (v22 era): a `sed`-style negative control with `\1` followed by a digit reads as capture group 10, so the mutation silently did nothing and the control passed against an unmutated file; and `mix test path:63` against a test that moved prints `0 tests, 0 failures` and exits 0. A third: 182 WR-03, a harness hash assertion that cannot fail as written; 182 IN-02 `grep -q` under `pipefail` failing falsely is the inverse.
**Why it happens:** Success is defined as "exit 0", and absence of failures looks like success.
**Prevention (concrete):**
- Every mutation control asserts `before_digest != after_digest` (or a diff is non-empty) *before* running the guarded check, and fails loudly if equal. Use `${1}0`-style explicit group delimiting or a non-regex mutator (Elixir `String.replace/3` with a literal, then compare).
- Every cited test is run by name/line with a required count: parse `N tests` from ExUnit output and require `N >= expected` (and `>= 1`). Exit status alone is never accepted. ExUnit has no built-in "fail on zero tests" for a path filter, so the wrapper must do it; keep it a ~10-line script in `script/`, not a dependency.
- A citation is `file + test name`, not `file:line`; line numbers drift (a cited line "had drifted two lines" in v14 debt). Lines are only a convenience that the wrapper re-resolves.
- Re-run each harness assertion in a "broken" state once (hash tampered, cleanup failed, evidence write fails) to prove it can fail. This directly closes 182 WR-03, WR-04, WR-05.
**Detection:** Control logs with identical before/after digests; `0 tests` in output; a passing run time near zero.
**Owner:** P-B; the 0-test wrapper also gates P-D rehearsal.

### Pitfall 4: Git probe is wrong in ways that fail open
The candidate probe (`lib/crosswake/proof_lane/twin_producers.ex` ~L688-780 at `50fcd57`) already scrubs `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_CONFIG*`, etc., sets `GIT_OPTIONAL_LOCKS=0`, `GIT_CONFIG_NOSYSTEM=1`, `LC_ALL=C`, and runs `status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none` with `core.excludesFile=/dev/null` and `core.fsmonitor=false`. That is a good base. Gaps and how each fails:

| Hazard | Fails open how | Prevention | Confidence |
|---|---|---|---|
| Index flags: `assume-unchanged` / `skip-worktree` (183 WR-01) | Git "omit[s] any checking and assume[s] it has not changed"; a modified file carrying the bit is invisible to `status` (git-update-index docs) | Count every `git ls-files -v` entry whose tag is not `H` as dirty (lowercase = assume-unchanged, `S` = skip-worktree). Treat a legitimate sparse checkout as blocked-with-reason (fail closed; a candidate for the twin should be a full checkout). Add tests that set each bit on a modified file. | HIGH (docs) |
| `core.filemode=false` (183 WR-02) | Mode-only change (e.g. executable bit on a script) is not reported | Pass `-c core.filemode=true` and also read the effective value and block if the repo itself cannot honour it. Fix the code comment that overstates isolation. | HIGH |
| Global config still read | Only the *system* file is disabled (`GIT_CONFIG_NOSYSTEM`); `$HOME/.gitconfig` and `$XDG_CONFIG_HOME/git/config` still apply. git docs: `GIT_CONFIG_GLOBAL=/dev/null` skips global. | Also set `GIT_CONFIG_GLOBAL=/dev/null` (and `GIT_CONFIG_SYSTEM=/dev/null`) in the scrub list, then pin the few values you rely on with `-c`. Add `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_SYSTEM`, `GIT_ATTR_SOURCE`-style keys to the "must be unset or pinned" list and test by exporting a hostile value from the caller. | HIGH for docs text; MEDIUM on completeness of the variable list (the git doc page was truncated in my fetch) |
| Ignored files not counted | Probe does not use `--ignored`. A file matched by an in-tree `.gitignore` that the build consumes is invisible; `core.excludesFile=/dev/null` removes only the *global* ignore file. | Decide explicitly: either count ignored paths under the input roots (`--ignored=matching`), or assert the declared input set is all tracked (digests are already taken for lock/manifest/js files: extend to every file the run consumes). Document as a fidelity limit if left. | HIGH |
| `.git/info/exclude` | Handled by counting rules (good), but WR-03 messages are misleading ("files", "0 files" race) | Report "exclude rules" and "dirty records" as separate numbers; do not suggest `git status` for the exclude case. | HIGH |
| Status then run race / edit-and-revert | HEAD+tree are read before and after, which proves HEAD did not move but not that the working tree stayed clean (fidelity limit 5) | Never describe a run as verifying source for its whole duration. Cheap upgrade without new deps: re-run the probe immediately after the run and fail if it differs; still a disclosed limit (cannot detect edit+revert). | HIGH |
| fsmonitor / untracked cache | A fsmonitor daemon can serve stale answers; the probe sets `core.fsmonitor=false` (good) but the untracked cache is stored in the index and `core.untrackedCache` can still be set | Pin `-c core.untrackedCache=false -c core.fsmonitor=false`; test with a repo that has both enabled. git-status docs say a few runs are needed for caches to warm, so first-run vs second-run disagreement is a warning sign. | MEDIUM |
| macOS case-insensitivity | This host has `core.ignorecase=true`. A case-only rename of a tracked path, or two paths differing only in case, can look unchanged on the filesystem while the index differs; Linux CI will disagree with the Mac | From knowledge, not verified against docs: compare `git ls-files` byte-for-byte against `git ls-tree -r HEAD` names in addition to `status`; add one fixture with a case-only rename; run the probe tests on both macOS and Linux CI. | MEDIUM |
| Submodules | `--ignore-submodules=none` is set (good). A submodule at a different commit or with a dirty tree is counted, but an uninitialised submodule is not a modification | Decide: candidate must have zero submodules, or each is checked; assert the answer. | MEDIUM |
| CRLF / `core.autocrlf` | With autocrlf, a CRLF-converted tree can show clean or modified depending on config; line-ending changes also change digests the run takes of tracked files | Pin `-c core.autocrlf=false` in the probe, and compute digests from bytes, comparing to `git ls-tree` blob ids (`git hash-object --no-filters`) rather than status. | MEDIUM (from knowledge) |
| `GIT_*` env leaking | Already scrubbed for repo-redirecting vars. Hazard is a *partial* list that decays as git adds variables | Prefer an allowlist: spawn git with a minimal environment (`PATH`, `HOME` set to an empty temp dir, `LC_ALL=C`) rather than a denylist. Elixir `System.cmd` `env:` can only add/unset, so unset every `GIT_*` found in `System.get_env/0` programmatically. Test with `GIT_DIR` pointing at a decoy repo (already a pattern in the tests). | HIGH |
| Unavailable git / non-zero exit | `:unavailable` collapses to blocked (good) | Keep: a test that a missing or failing git gives blocked, never `0 dirty`. A porcelain parse of an empty string must be distinguished from exit-0-with-no-output on a *wrong repo* (assert the path is the repo toplevel via `rev-parse --show-toplevel` equal to candidate path). | HIGH |

**Owner:** P-A. Fixes WR-01 and WR-02 are required before twin-05 (debt-disposition says "fix in the next twin-touching change"). Tests must come from a real temporary repo fixture, not injected `git_cmd` stubs only (AGENTS.md lesson: exercise real subprocess output).

### Pitfall 5: Run-root consumption (twin-05 burned by a premature attempt)
**What goes wrong:** twin-04 is consumed (D-16: any fix after `fix(183-03)` needs a new prepared record and a new run root). A run root is single use. If anyone starts twin-05 before the hardened commit is final, preflight is incomplete, or WR-01/02 land afterwards, the root is burned and cannot be reused (a refused run root created by `run_root(nil)` is also left behind: 183 IN-03).
**Why it happens:** "Just try it once" and because a half-run feels recoverable. The earlier retry pass lesson in v25 PITFALLS: "Retain failed attempt/cause privately; new identified attempt only after concrete repair."
**Prevention:**
- Freeze rule: no product-code change after the commit twin-05 binds. All P-A/P-B/P-C commits merge first, then one freeze commit, then the prepared record names that head.
- Preflight-only rehearsal (P-D): run the full preflight, refusal paths and the 0-test wrapper against the frozen head with run root *absent or a throwaway name*, and assert the rehearsal cannot create or consume `twin-05` (test that the rehearsal entry point refuses that name).
- A written go/no-go checklist generated by a script (clean probe with the new WR-01/02 behaviour, handoff digests match, rehearsal passed, root `twin-05` does not exist), not by memory.
- The twin and Simulator are not run in this research or by agents without the explicit run authorization; do not interpret a standing authorization for Phase 175 release steps as covering twin runs.
- Fix IN-03 so a refused run root leaves nothing behind; otherwise a refused attempt can itself look like consumption.
- If a run is lost, keep the cause (privacy-safe) and use `twin-06`; never reuse the root and never infer why a stall happened (the case-3 stall in twin-02 is an unknown with no retained cause).
**Detection:** Existence of `twin-05` directory before the go decision; head in prepared record != head probed at run time.
**Owner:** P-D, with the freeze rule enforced by roadmap ordering.

### Pitfall 6: Breaking contract changes silently break out-of-tree producers
**What goes wrong:** 181 M-02 (legacy D-28 path grants any registered `host.*` key silently and drops unregistered keys without a diagnostic) is a *fail-open*; the natural fix is fail-closed, which changes behaviour for any manifest not generated by Crosswake. Likewise a CW-REQ-A vocabulary bump changes strings producers may emit or consumers parse. Out-of-tree producers (hosts, and the first adopter's handwritten manifest, which AGENTS.md says Crosswake does not see) learn of it at runtime as a blanket denial.
**Why it happens:** Crosswake always emits `host_commands`, so the in-tree tests never exercise the legacy path (M-02 note); the risk is invisible to CI.
**Prevention:**
- Make the break loud and early: a fail-closed denial must carry a distinct, specific diagnostic (key name and the reason) at manifest decode/doctor time, not only at command time; doctor already prints it (privacy rules apply, Pitfall 7).
- Add a version/schema marker and a deprecation step instead of a flip: first release emits the diagnostic and keeps behaviour (warn), second flips to deny. Given a single adopter, the pragmatic version is: keep deny, add a doctor finding with exact repair text, and update the compat guide. Choose one and record it as a decision; do not do it implicitly in a fix commit.
- Drive from fixtures: add a legacy-shaped manifest fixture (no `host_commands`) and assert the exact new outcome; this is the contract test an out-of-tree producer can copy.
- Seam check: M-01 (floor vs equal-major) and the guide say different things; fix the *guide or the code*, not neither. Changing to equal-major is itself a breaking change; apply the same procedure.
- CW-REQ-A decision: the reopen condition was "a release pipeline has been proven"; Phase 175 ended with REL-10 breached. Default recommendation: **remain deferred** unless a recorded run proves the pipeline; state the evidence in the decision, update requirements, roadmap, ADR and capability truth together (AGENTS.md).
- Swift/Elixir parity: L-01 (leading-zero versions accepted by Swift, rejected by Elixir) is a cross-language contract split; fix with a shared fixture table both test suites read.
**Detection:** A "fail closed" commit with no new fixture; a changed denial reason string without a changelog/guide edit.
**Owner:** P-C.

### Pitfall 7: Privacy leaks in new diagnostics (181 M-04)
**What goes wrong:** Doctor, gate and raise messages include the expanded absolute package path, which can contain a local username. A hardening fix adds *more* messages (WR-03 wording, new M-02 diagnostics, index-flag counts) and each is a new leak surface. `run_git` rescues only `ErlangError`; an argv with a NUL byte raises an `ArgumentError` whose message could contain a path (183 IN-04).
**Prevention:**
- One redaction helper (copy, no dependency): render paths relative to the project root, or as `<candidate>`/`<home>/...` tokens; never `Path.expand` into a message. Apply to every message touched in this milestone.
- A leak test per new diagnostic: run with a fixture directory whose name embeds a sentinel string (e.g. `__user_sentinel__`) and assert the sentinel does not appear in doctor output, raised messages, telemetry, evidence files or logs. Include exception messages (rescue and re-render), not only returned strings.
- Counts and closed reason atoms in output, as the existing probe does ("Output is only counted, never returned").
- Do not paste raw git output, hostnames, device ids or the real adopter's identifiers into evidence; AGENTS.md sensitive-data rules apply to proof artifacts too.
**Detection:** `Path.expand`/`File.cwd!` in any `raise`/message; a message test comparing against a path literal.
**Owner:** P-C (M-04) with P-A reusing the helper.

---

## Moderate Pitfalls

### Pitfall 8: Silent-degrade items deferred because they are "low"
**What goes wrong:** The opposite of scope creep. Items are triaged by severity label, but the milestone's purpose is silent degradation. The ones that degrade silently regardless of label: 181 M-02, M-03 (doctor stale-fixture returns `[]` on unreadable/malformed fixture, so broken equals fresh), L-04 (one-direction validator), L-05 (validator accepts what the builder crashes on), 182 WR-02 (loopback allowlist not re-checked for hand-built structs), WR-05 (`passed` despite failed cleanup), WR-03, WR-04, 183 WR-01/02, plus the unwired `verify_loopback_origin_simulator.sh` scripts that nothing calls (an unreferenced check is a check that runs never).
**Prevention:** Triage rule for the milestone: *include if the failure mode is "reports healthy while something is missing/unreadable/unchecked"*, regardless of severity label; *defer if it only fails closed* (L-02 fails closed by design; I-01..03 cosmetic; L-03 unused field). Write the rule at the top of the phase plan and cite per-item. Unwired scripts: wire into the rehearsal or delete; do not leave them.
**Owner:** P-B/P-C planning. Phase plans must show each disposition as fix, deliberately-leave-with-reason (as TELEM-04 Side B was), or deferred-with-reopen-condition.

### Pitfall 9: Scope creep ("while we're here")
**What goes wrong:** SEED-018 repo-wide (173 sites) turns a hardening milestone into a repo-wide rewrite; SEED-014 C-F drifts into UI/doctor polish; CW-REQ-D (SwiftUI denial view) becomes a design exercise; someone touches Android or generic sync; the route-id mismatch (`study-session` vs `offline-study`) or `WKAppBoundDomains` `example.com` becomes a refactor.
**Prevention:**
- Hard in/out list in the roadmap from BRIEF constraints: no Android, no new companions, no dashboards, no brand polish, no new dependencies ("another copy and paste is better than another dep").
- SEED-018: measure repo-wide count of *vacuous-prone* sites, classify, then decide by evidence: v25-only by default.
- SEED-014 C, D, E, F: re-check against candidate code first (some may already be fixed) and close with "verified already fixed" evidence before any code change. Only CW-REQ-D has a UI element; limit to the denial view states needed by the tested flow.
- Items already listed under "Deferred scope and wiring" in debt-disposition stay deferred unless they are on the silent-degrade list (Pitfall 8).
**Detection:** Plan tasks with no finding ID or requirement ID; diff touching `packages/` companions or `android/`.
**Owner:** Roadmap-level, enforced in each plan check.

### Pitfall 10: Fixing the head invalidates bound handoffs
**What goes wrong:** Per the dispositions, 181 fixes change the head bound by `180-SEAM-HANDOFF.json` (`repaired_head` 12f84cd), 182 fixes require simulator harness rerun and `182-FINAL-HEAD.json` refresh, 183 fixes require a new run root. Fixing items piecemeal means re-binding repeatedly, and a stale binding that still "matches" is a false-pass hazard.
**Prevention:** Batch all code fixes into one ordered series, then do one regeneration of handoff/final-head records at the freeze commit. Binding records are written by script from `git rev-parse`, never hand-edited, and the checker fails if a record's head is not an ancestor of, or equal to, the frozen head. Also resolve the delivery gate: product code exists only in `/private/tmp/crosswake-phase180-impl` (volatile `/private/tmp`); moving it into the authoritative tree needs its own authorization. Keep a note that a loss of `/private/tmp` loses all v25 code; record this as a risk, do not act on it without authorization.
**Owner:** P-D (freeze) with P-A..C ordering.

### Pitfall 11: Tests that depend on the test environment, not the contract
**What goes wrong:** Generator drift check reports stale unless run with `MIX_ENV=test`; `local_ios_package` resolves from the current directory; shell harnesses lack timeouts (`xcodebuild`, `mix run`, `simctl bootstatus`: 182 IN-03) so a hang looks like "no result".
**Prevention:** Run all hardening checks from a clean directory and from a different working directory once (catches cwd dependence); add explicit timeouts that fail with a named cause; a timeout is blocked, never pass.

### Pitfall 12: Measuring too late, or measuring the wrong thing
**What goes wrong:** SEED-023 (extend the scope-cardinality guard) is made blocking with a cardinality that is itself derived from the observed set (self-referential), so it cannot fail. Same shape as Pitfall 3.
**Prevention:** The expected cardinality comes from an independent declaration (the closed roster in the plan), and the guard must fail on both fewer and more. Include the "empty set" case as a first-class failing test. Measurement phase output: a table `site, kind, empty-pass?, action`, kept in phase evidence.
**Owner:** P-B.

---

## Planning-tool pitfalls already seen in this repo

| Tool pitfall | Effect on v26 | Prevention |
|---|---|---|
| Gap-analysis gate reads root `.planning/REQUIREMENTS.md` (workstream-unaware) | Every v26 REQ-ID reads as an uncovered ghost | Verify coverage by grep against the workstream REQUIREMENTS.md and record that as the gate evidence; do not edit the root file to satisfy it. |
| Decision-coverage parser false-negatives (`extracted 0 of N`) on long-bold or embedded-colon `D-NN` bullets | Blocking gate fails though coverage is real | Write CONTEXT decisions as short `D-NN: text` bullets with no embedded colon in the bold span; where unavoidable, cross-check plan-checker Dimension 7 and record the override. |
| Blocked plan leaves `NN-SUMMARY.md`, which reads as done and unlocks dependents | A blocked hardening plan (e.g. a probe fix needing a run root) looks complete | Rename to `NN-BLOCKED.md` on block (Crosswake executors dispatch with forced isolation none). |
| Dispatch isolation sentinel has a 10-minute TTL | Parallel dispatch silently serializes or errors when a long plan run exceeds TTL | Re-write the sentinel immediately before every dispatch (`record-dispatch-isolation`, read via `worktree base-check`). Treat sequential execution as the norm for P-A..D since they all touch one candidate head. |
| Audit scanner reads GFM table rows as deferred items but `audit-open acknowledge` cannot write to table spans | A table-formatted disposition (as all three review dispositions are) can hard-block milestone close with no CLI path | Plan the closeout early; keep dispositions in the table but also in a non-table list for items that must be acknowledgeable, or expect an override and record it. |
| Verification runs before the last merge (v22 Phase 168) | `stale` verification blocks close, forced override | Run verification after the freeze commit, not before. |
| Roadmap checkboxes drift from reality | Table reads 8/13 at close | Tick on completion in the same commit as the SUMMARY; check at closeout by script. |
| Piped checks mask exit codes (`cmd | tail && echo OK`) | The recurring defect itself | Use `set -o pipefail` or capture to a file, then test `$?`; the 0-test wrapper reads output *and* status. |

---

## Lessons from other ecosystems

| Ecosystem | Lesson | Maps to | Source | Confidence |
|---|---|---|---|---|
| Go | `go build` stamps VCS data into binaries: revision, commit time and a flag recording whether edited or untracked files were present (`vcs.modified`); `-buildvcs=false` omits it; the data is readable via `go version -m` / `runtime/debug.ReadBuildInfo`. Lesson: dirty state is a *recorded attribute of the artifact*, not a gate-time opinion. A claim that something ran against a clean tree should be a stored, re-checkable field (twin attestation already does this) and "omitted" must be distinguishable from "clean". | WR-01..03, Pitfall 5 | https://go.dev/doc/go1.18 (fetched) | HIGH for the existence and semantics of the flag; MEDIUM for the claim that Go computes it from `git status --porcelain` (from knowledge) |
| git describe | `--dirty` appends `-dirty` when the working tree has local modification and `--broken` appends `-broken` when git cannot tell. The docs do not state whether untracked files count, so do not rely on `describe --dirty` as a source-cleanliness gate; and note the useful three-state design: clean / dirty / cannot-determine. The probe's `:unavailable` mirrors `--broken`; keep that third state and never collapse it into clean. | Pitfall 4 | https://git-scm.com/docs/git-describe (fetched) | HIGH |
| git update-index | `assume-unchanged` is a promise by the user so git may skip `lstat`; the docs warn users who use it to "ignore" tracked changes that it does not work as expected. Any gate built on `status` inherits that promise; hence `ls-files -v` check. | WR-01 | https://git-scm.com/docs/git-update-index (fetched) | HIGH |
| git status | `--porcelain` output is stable across versions and user configuration, but untracked-file mode defaults differ by `status.showUntrackedFiles`, index refresh writes can conflict (`--no-optional-locks` / `GIT_OPTIONAL_LOCKS=0`), and untracked cache + fsmonitor give faster but cache-dependent answers. | Pitfall 4 rows | https://git-scm.com/docs/git-status (fetched) | HIGH |
| git environment | `GIT_CONFIG_GLOBAL` / `GIT_CONFIG_SYSTEM` (with `/dev/null`) and `GIT_CONFIG_NOSYSTEM` are the documented ways to make config predictable; `GIT_CONFIG_NOSYSTEM` is documented as usable "along with `$HOME` and `$XDG_CONFIG_HOME` to create a predictable environment for a picky script". Using only NOSYSTEM leaves user config in play. | WR-02 | https://git-scm.com/docs/git (fetched; page truncated, `GIT_OPTIONAL_LOCKS` entry not read) | HIGH |
| Bazel | Hermeticity: "a hermetic build system always returns the same output by isolating the build from changes to the host system". Named non-hermetic sources include host-specific binaries and absolute paths, and writing to the source tree during a build. Lesson: the twin should name its inputs and refuse ambient ones (host git config, `$HOME`, cwd, absolute paths in messages, an existing run root). | Pitfalls 4, 5, 7, 11 | https://bazel.build/basics/hermeticity (fetched) | HIGH |
| Nix flakes | A local git flake input with uncommitted changes is treated as dirty and a warning is printed; files not added to git are not fetched. Lesson: the useful behaviours are that dirtiness is surfaced to the user and that untracked content is excluded from the input set rather than silently included. The page does not mention `dirtyRev`. | Pitfall 4, input roster | https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html (fetched) | MEDIUM |
| Reproducible Builds | `SOURCE_DATE_EPOCH` is derived from the last commit (`git log -1 --pretty=%ct`), not from the working tree. The fetched page does not address dirty detection, so I draw no dirty-tree lesson from it. Lesson used: derive from committed identity, not the checkout. | Pitfall 5 | https://reproducible-builds.org/docs/source-date-epoch/ (fetched) | MEDIUM |

---

## Phase-Specific Warnings

| Phase topic | Likely pitfall | Mitigation | Owner |
|---|---|---|---|
| Measure vacuity (SEED-018 v25-only, SEED-023) | Blocking before measuring; waivers (1, 12) | Report mode, table, ratchet-down ledger, expected cardinality from independent roster | P-B |
| Harness fixes (182 WR-03/04/05) | Assertion that cannot fail; control that doesn't mutate (3) | Broken-state runs; `before != after`; 0-test wrapper | P-B |
| Probe hardening (183 WR-01/02/03/04) | Real-repo fixtures missing; global config; ignored; case; CRLF (4) | Real temp repos on macOS and Linux CI; allowlist env; negative controls | P-A |
| Seam/contract (181 M-01..04, L-*) | Breaking producers; privacy (6, 7) | Legacy fixture; specific diagnostics; redaction helper plus sentinel test | P-C |
| Loopback origin (182 WR-01/02/06) | Non-transactional plist; hand-built struct bypass; inspect prints HTTPS for all (silent mislabel) | Re-check allowlist in `origin_transport/1`; test hand-built struct; inspect only prints what mode applies | P-C |
| SEED-014 C-F, CW-REQ-A/D | Scope creep; reopening CW-REQ-A without evidence (9) | Re-check against candidate first; default CW-REQ-A stays deferred, record why | P-C |
| Triage | Deferring silent-degrade items (8) | Include-by-failure-mode rule | Roadmap |
| Freeze and rehearsal | Burning twin-05; stale handoffs (5, 10) | Freeze commit; scripted go/no-go; rehearsal that cannot create the root | P-D |
| Closeout | Planning-tool gates (table above) | Plan overrides and grep evidence early | Closeout |

## Sources

- Repo, read directly: `.planning/research/v26/BRIEF.md`; `.planning/RETROSPECTIVE.md` (absence-scored-as-success section); `.planning/research/v25/PITFALLS.md`; `.planning/workstreams/quality-ratchet-release/milestones/v25.0-closeout/debt-disposition.md`; phases 181/182/183 `*-REVIEW-DISPOSITION.md`; candidate `lib/crosswake/proof_lane/twin_producers.ex` at `50fcd57` (read only); `AGENTS.md`; user memory notes on piped checks, gap-analysis gate, blocked SUMMARY naming, isolation sentinel TTL. HIGH.
- https://git-scm.com/docs/git-update-index, /git-status, /git-describe, /git (fetched 2026-10-15). HIGH.
- https://go.dev/doc/go1.18 (fetched). HIGH for stamping; the exact computation of `vcs.modified` is from knowledge, MEDIUM.
- https://bazel.build/basics/hermeticity, https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html, https://reproducible-builds.org/docs/source-date-epoch/ (fetched). HIGH/MEDIUM as noted.
- Not verified against primary sources (stated from knowledge, flagged MEDIUM): macOS case-insensitivity behaviour of `status` for case-only renames, CRLF/autocrlf digest interaction, `ls-files -v` lowercase/`S` tag letters (the update-index page does not list the letters; confirm against git-ls-files docs or a scratch repo test before coding).

## Gaps to Address

- Run a scratch-repo experiment (read-only elsewhere, not in the candidate) to confirm `ls-files -v` tags and the case-only-rename behaviour before the P-A plan fixes exact assertions.
- Measure the SEED-018 repo-wide count of risky sites; the 173 figure is the seed's site count, not a measured vacuity count.
- Decide M-02 procedure (warn-then-deny vs deny-with-diagnostic) with the user in discuss-phase; it is the one genuinely contract-affecting choice.
