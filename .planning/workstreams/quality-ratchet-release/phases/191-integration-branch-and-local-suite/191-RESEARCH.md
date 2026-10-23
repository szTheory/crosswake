# Phase 191: Integration branch and local suite - Research

**Researched:** 2026-10-19
**Domain:** git branch construction, release-landing hygiene, local verification gates, privacy scanning (shell + Elixir + Node, no new dependencies)
**Confidence:** HIGH for measured facts (each was run or read this session); MEDIUM for the decomposition and the open decisions in `## Open Questions`

Placeholders used throughout (per AGENTS.md and 189 D-02): `<recovery-checkout>`, `<durable-candidate>`, `<backup-root>`, `<tmp>`, `<home>`, `<denylist>`, `<scratch>` (a throwaway copy of `<durable-candidate>` used only for the dry runs reported here; nothing in the recovery checkout or `<durable-candidate>` was written).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

The user chose all four areas and asked for multi-lens fan-out research with an adversarial pass, then one coherent set of recommendations to be followed automatically. Every decision below is that synthesis. Where two research tracks disagreed, the reconciliation is stated.

#### Branch layout and commit order
- **D-01:** Make a fresh durable clone (outside the temp folder) from GitHub `main`, re-fetching `main` first. Bring in `refs/heads/candidate` from `<durable-candidate>`, then fast-forward the integration branch to it. Re-check before starting that `main` is still an ancestor; if `main` has moved, stop and replan rather than rebase. `<durable-candidate>` stays untouched as the Phase 190 record. Set the clone's repo-local `user.email` to the noreply address main already uses before any commit.
- **D-02:** The order is linear, and every commit keeps the suite green: `main` → 90 candidate commits → 4 FIX commits → new code-fix commits (D-10..D-16, one per fix, each with its test) → the planning resolver commit (D-06) → the planning carry commits (D-07) → an optional post-cut sync commit → the privacy scan (D-18), which runs last and is bound to the final HEAD.
- **D-03:** Phase 192 must merge with a merge commit, never squash or rebase-merge. Otherwise the preserved candidate history and the per-milestone carry split are lost. This is recorded here as a forward constraint for Phase 192. It is not acted on in 191. — **Reversibility:** one-way — a squash merge on the protected public `main` cannot be undone without a force push, which is forbidden.

#### What the planning carry includes
- **D-04 (scope):** Carry the full `.planning/` delta between `main` and the recovery checkout's working tree, computed by content and not from the stale inventory list. That includes the v23.0 archive move and the committed v24 records, i.e. the planning-only half of R-BR-047. This reclassifies that half from *unclassified* to *to land*. Without it, v24–v27 records would point at archive paths that don't exist on main. Exclusions:
  - unclassified rows R-PL-04, R-PL-06 (untracked part), R-PL-07, 08, 09 and 13;
  - R-PL-14..16, byte-identical to their `milestones/` copies (record as a checked *obsolete* reason for Phase 193);
  - `.DS_Store` and `research/.cache`.

  — **Reversibility:** costly — once pushed publicly, removing carried records needs follow-up commits, and the content stays in public history.
- **D-05 (not carried):** AGENTS.md, `.tool-versions`, `.github/workflows/*` and every non-planning (R-NP) path, including the Phase 175 `release_candidate` code. On main these are the released, CI-checked versions; the recovery copies are older drafts (for example, the recovery `.tool-versions` drops nodejs and its `release-please.yml` lacks about 232 lines). They stay *unclassified* in the backup for the user's 189-DECISIONS-NEEDED answers. The 191 handoff records that CLEAN-04 (Phase 193) should take the recovery AGENTS.md's durable working rules as input and drop the consumed Phase 175 standing authorization.
- **D-06 (resolver first):** Seven files on main read live `phases/169-175` paths (12 references): `script/check_release_workflow_integrity.exs`, the phase170/174/175 proof tests and `crosswake_release_status_test.exs`. The archive move would break them. One commit before the carry gives them a live-or-archived lookup. Copy a small helper into `test/support/*.ex`, which is outside the test-file guard's `**/*.exs` glob, so pin 253 is unaffected, and give the script its own copy (copy-paste over a shared dependency). The model is `script/phase_evidence_path.{py,sh}`.
- **D-07 (commit split):** One commit per milestone, driven by a path-to-milestone table in the plan; a path the table doesn't match fails hard:
  1. v23.0 archive move and closeout, deletes and adds together so exact-rename detection pairs them;
  2. v24 (phases 176–178, v24 scope, audit, history);
  3. v25 (179–183, research/v25, v25 start, scope);
  4. v26 (184–188, research/v26, scope);
  5. v27 plus live files (189–191 folders, v27 scope, PROJECT, RETROSPECTIVE, WINDOWS, both config.json files, seeds, STATE, ROADMAP, REQUIREMENTS, MILESTONES, state.json, `.continue-here.md`, `.verification-ledger.json`, PHASE175-STANDING-AUTHORIZATION).

  Each commit:
  - carries a `Planning-Carry: vNN` trailer and the manifest digest;
  - states that it is a snapshot of the records at the cut time, not the original authorship history (the originals stay in `refs-all.bundle`);
  - touches only `.planning/`.
- **D-08 (who wins, plus the record's wording):** For planning paths the recovery version wins; for every other path main wins. A three-way check (merge-base `52345b48`, `main`, recovery) must show two things, or the carry stops:
  - every planning change on `main` since the merge-base is present byte-for-byte in the recovery tree, at the same path or its archive path;
  - the candidate and FIX commits touch zero `.planning/` paths.

  If that conflict list is ever non-empty, fall back to a per-file three-way merge for those files only. Records land verbatim. Wording about the frozen recovery checkout and `/private/tmp` is not rewritten; CLEAN-04 owns that. The only exception is the privacy transform in D-17. The final carry commit message notes that the records describe the frozen-recovery flow in force until CLEAN-04.
- **D-09 (proof the carry is complete):** One dependency-free script (bash, git, shasum) plus a self-test in `phases/191-*/scripts/`:
  - **Manifest:** built at a declared cut as `(status, path, mode, blob id, sha256)`, with both the source hash and the landed hash for transformed files. Symlinks are refused.
  - **Equality:** an exact sorted match against `git diff --raw --no-renames main..HEAD -- .planning`.
  - **Count floor:** never zero, and at least the to-land plus committed-only paths.
  - **Exclusions:** zero overlap with the exclusion list.
  - **Coverage:** every R-PL to-land row is covered.
  - **Commit boundaries:** carry commits touch only `.planning/`; the resolver touches only its declared files.
  - **Negative controls:** dropped file, flipped byte, extra file, mode change and empty manifest each fail with their own label.
  - **Freshness:** records written after the cut (Phase 191's own SUMMARY and VERIFICATION) land through a re-run of the same tool as one sync commit before Phase 192. The PR head does not change after the user's `allow`.

#### Known failures and the local suite
- **D-10 (definition):** "The full local suite" = `script/verify_repository.sh --all` (all nine stages PASS) plus the full `cd examples/phoenix_host && mix test`, run in the integration clone. Child processes run with a UTF-8 locale (`LC_ALL=C.UTF-8`). `LC_ALL=C` applies only to `sort`/`comm` and to the pinned git helper. CI-only commands outside these are judged by Phase 192 CI and are not duplicated here.
- **D-11 (what "pass" means):** 0 failures and 0 invalid in every run, and each run's test count is at or above a floor measured by a separate command. There is no baseline comparison. This supersedes Phase 190 D-10 for landing, because main's single aggregated required check cannot go green with known red tests. Allowed exceptions:
  - the closed tag set `advisory_only`, `collateral_binaries`, `engine_present` and `requires_example_host` (plus `phase41_nested_process`, which runs separately via `--only`), each with its reason and where it runs instead stated in evidence;
  - the Swift skips that need the export, listed by name.

  Anything else fails the gate.
- **D-12 (five Phase170 ledger tests: fix the real cause):** They fail because of the locale, not test order. `suite-gate-190.sh` exported `LC_ALL=C`; under a C locale, Erlang's stdout escapes the em dash to `\x{2014}`, so the JSON decode fails (reproduced: `{:invalid_byte, 795, 120}`). The fix:
  - `script/inventory_collection_assertions.exs` writes its JSON with `IO.binwrite`;
  - the gate stops passing `LC_ALL=C` to child processes;
  - a negative control proves the script still decodes under `LC_ALL=C`.

  The evidence records that the earlier "order-dependent" diagnosis was wrong.
- **D-13 (Phase180 G1 root gate test: invert in place):** It now asserts the current truth: `host.study.audio.play` on the offline_island route yields `errors == []`, and an unknown core capability yields exactly one `:capabilities` error. Avoid `Enum.any?/all?` forms. In the same commit, reword the G1-control override rationale in the inventory script and regenerate `script/collection_assertion_ledger.json`. The audited-site and shape counts change only from a separate measurement.
- **D-14 (Swift G4, the G3 gate, example-host G2/G6: invert in place):** Each now asserts the fact `180-GATE.json` records as decided. G3 tests that need the export stay as named skips with a reason. Record as a fact for Phase 193 that no CI lane runs the full example-host suite; CI is not changed in 191. The Phase 180 records stay unchanged, and the evidence notes that their `test_files_sha256` pins are historical (two had already drifted).
- **D-15 (format):** One format-only commit for `test/crosswake/guides/native_shell_upgrade_test.exs`. Main has it formatted; candidate commit `6dbc37ae` broke it, and CI `format-proof` (job guard-01) would fail. It is the only unformatted file of the 423 formatter inputs.
- **D-16 (test-file pin):** Recount with separate commands (`git ls-files 'test/**/*.exs' | wc -l` and `find`) on the final HEAD. Expect 253, since the planned fixes add no `.exs` test files. Change the pin only on a measured difference, and fail on any mismatch.

#### Phase 190 review leftovers
- **D-17a (fix now, as candidate-code commits):**
  - **WR-05:** the preflight's activation check requires a decoded map with a binary `"origin"` that canonicalizes, reusing `canonical_origin` through a `@doc false` helper with `observe/2` unchanged (190 D-08). Table cases `null`, `[]`, `{}`, `{"origin": 5}`, a list origin and an origin that won't canonicalize each block with PI-PREFLIGHT-CONFIG. The existing absent-file positive control stays.
  - **WR-01 + WR-06:** a distinct verdict note for `:registry_timeout`, `:child_still_alive` and `:registry_gone`, with the exit code and receipt unchanged, plus a `run/1` wiring test using an injected producer that stops the registry. If WR-06 needs more than about 30 lines, ship WR-01 alone and move WR-06 to the seed.
  - **WR-03 test half:** under each hostile config, assert `commit_ref(dir) == "git-" <> head` before the chmod.
- **D-17b (fix in Phase 191 successor scripts; the 190 scripts stay unchanged per 190 D-01):**
  - WR-09 goes into `suite-gate-191` (D-19).
  - WR-10 goes into `recovery-snap-191`:
    - fail on a missing folder, HEAD or config;
    - digest the index content with pinned `ls-files -s`, plus `logs/HEAD` and an object count;
    - take a fresh before-snapshot at Phase 191 start.
  - WR-11 goes into the 191 locate step: regenerate the env file every time in an owner-checked mode-700 folder, use pinned git plus an untracked-file check, and compare the clone HEAD with its source.
  - WR-07 and IN-02 go into the new privacy scanner (D-18).
- **D-17c (defer to one new seed, SEED-024 "Phase 190 review residue"):**
  - **Trigger "before the next twin run":** the WR-02 residual (the spawn-time registration exit at `twin_runtime.ex:171`; the main claim was refuted, since `mark_exited` already catches), WR-08, IN-01, IN-03, the `/tmp` vs `/private/tmp` path-text comparison, and WR-06 if not done.
  - **Trigger "before the physical-iPhone run resumes":** the WR-03 version guard or distinct cause, plus documenting git 2.41 as the proof-lane floor; a distinct cause and supported-layout doc for WR-04; and confirming IN-04 fails closed for a missing shell folder.
  - **Accepted as designed:** WR-04 (190 D-07), and the hard-coded counts half of IN-04 (it fails loudly).
  - **Disposition file:** update `190-REVIEW-DISPOSITION.md` rows to match, citing commits or the seed.

#### Privacy scan
- **D-18 (scanner and scope):** One new vendored scanner plus a self-test in the 191 `scripts/` folder, run in the integration clone over `main..HEAD`, with four inputs:
  1. added lines from `git log -p --no-renames -m --no-ext-diff --no-textconv`;
  2. every new blob from `rev-list --objects`, with binary blobs scanned as raw bytes;
  3. every new tree path name;
  4. every commit message, author and committer name and email, and tag and note messages.

  Do not use `scan-privacy-190` on code: its `@` and `token|secret` classes hit nearly every Elixir file. It may still serve Phase 191's own evidence files.

  Gitleaks 8.30.1 (already installed, one static binary, feature-frozen) is the secret layer: `--log-opts` over the range, redacted JSON report kept in scratch. Evidence records only its version, rule count and finding count. There is no trufflehog unless a planted secret control is missed.

  Adopter terms come from an untracked mode-0600 file outside the repo and the temp folder, recorded only as `<denylist>`, passed through the existing `CROSSWAKE_PRIVATE_ADOPTER_TERMS` convention. Zero terms is a scope error (exit 2). Evidence records the term count and the file's sha256 only, and no term is ever written into the repo.

  Classes are case-insensitive except the hex shapes. Blocking classes:
  - GitHub token shapes, PEM keys, Hex/Maven credentials;
  - adopter terms;
  - home paths and macOS per-user temp paths;
  - UDID shapes;
  - non-noreply emails, and author names not already on main.

  Generic UUIDs, bare `token`/`secret` words and bare 40-hex strings are triage only.
- **D-19 (proof the scan checked something):**
  - **Counts:** the scanner prints the commits scanned (must equal `rev-list --count main..HEAD`), added lines and bytes, text and binary blobs, paths, identities and term count, and it exits 2 on any zero.
  - **Planted controls:** the self-test plants one fragment-assembled hit per class in a temp repo, in each of these positions: added then deleted in a later commit, in a binary blob, in a commit message, in an author email, in a file name, as an upper-case credential, as a canary adopter term and as a gitleaks shape. Each must fail with its own label, and a clean control passes with nonzero counts.
  - **Real-term check:** an in-memory check that every real term matches, printing counts only.
  - **Suite-gate successor:** `suite-gate-191` follows the same rule. MIN is required and above 0; totals lines are matched strictly and their number checked; the excluded total and tag set must match; nine `--all` PASS records are required; exit codes are captured to files, never through pipes; status uses `--untracked-files=all` through pinned git; HEAD equals the recorded head; evidence is written to a temp file and renamed after validation; only parsed totals and test names are kept, never raw logs, which contain temp paths. There is no baseline mode.
- **D-20 (severity ladder):**
  1. **Secret:** rotate or revoke immediately whatever else happens. Then stop before any push and ask the user.
  2. **Adopter identity, raw sensitive payload or stable device ID:** fix in the final tree with placeholders. If the hit is inside an intermediate candidate commit, stop and ask the user with a prepared remedy: `git filter-repo --replace-text` limited to the range, with the commit map kept in evidence, and its effect on `a53fbef`, the twin-05 proof identity and LAND-01's history clause.
  3. **Personal path or username:** a new occurrence in the final tree is replaced with a placeholder in a fix commit. An occurrence only inside preserved candidate history is accepted and counted, because main already publishes the same username about 360 times and a rewrite would break LAND-01.
  4. **Benign** (placeholders, fabricated fixture tokens, test UUIDs, the public handle matching main): allowed by fingerprint in a triage file, one reason per entry.

  Never squash. Never force-push.

  — **Reversibility:** one-way — any rewrite of candidate history changes the commit IDs the v25/v26 proof records name; that is why rungs 1–2 inside history go to the user.
- **D-21 (privacy transform for carried records):** About 146 v23 files and about 100 files in phases 176–188 contain a real home path. Since the carry commits introduce these files, they are redacted in the introducing commit, with the home path replaced by `<home>`. No home path then enters public history. This is the reconciliation between "land verbatim" (D-08) and "no new exposure" (D-20): the transform is mechanical, and the manifest records both hashes per file. Raw API `.source` files and the four files with token-like patterns are triaged by the scanner and redacted the same way if flagged. Evidence folders otherwise land in full. — **Reversibility:** reversible — the unredacted originals remain in the local backup.
- **D-22 (binding):** The scan runs after the last commit and is bound to the HEAD and `main` SHAs. Phase 192's push step must refuse unless the recorded scan HEAD equals the push HEAD with exit 0. The first copy off the machine happens only after this (189 D-01). Any new commit means a rescan.

#### Recovery checkout stays frozen
- **D-23:** No git write in the recovery checkout. Planning records for 191 are written there only as plain files, as in Phases 189 and 190. Criterion 4 is proven by `recovery-snap-191` before and after (D-17b).

### Claude's Discretion
- Integration clone location and branch name (for example `land/v25-v27`), script names and layout in the 191 `scripts/` folder, and the exact path-to-milestone table rules.
- Whether the WR-01 and WR-06 fixes share one commit.
- Wording of the verdict notes and refusal reasons (plain language, no paths or sensitive values).

### Deferred Ideas (OUT OF SCOPE)
- **SEED-024 "Phase 190 review residue":** contents and triggers in D-17c. Write it during Phase 191 execution.
- **Pre-existing home paths on main** (about 360 planning files): outside LAND-01's "the change" scope. A hygiene seed, in the SEED-012 lineage.
- **Example-host suite has no CI lane:** a fact for Phase 193's working-rules decision; CI is not changed in 191.
- **Recovery AGENTS.md working rules:** input to CLEAN-04 (Phase 193); drop the consumed Phase 175 standing authorization.
- **Optional:** the user's GitHub account setting "Block command line pushes that expose my email", as a server-side backstop. An account setting, not phase work.
- **The user's answers to 189-DECISIONS-NEEDED:** answered 2026-10-19 in `189-DECISIONS-ANSWERS.md` (the backup is the keep; Phase 193 removes source copies only; nothing lands as code; the planning half of R-BR-047 lands via D-04). Not needed for 191.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LAND-01 | An integration branch cut from current GitHub `main` carries the candidate's commits with history preserved, the FIX commits and the v24-v27 planning records; privacy scan of the full change is clean | Facts F1-F3 (ancestry, 94 commits, linear, no merges, no binaries), carry delta table (`## Path-to-milestone table`), privacy findings (`## Privacy Scan Grounding`), gitleaks CLI (`## Standard Stack`), the "carry-induced red tests" list (`## Common Pitfalls`) |
| LAND-02 | The full local suite passes on the integration branch; each known pre-existing failure is fixed or listed with a reason; nothing excluded silently | Measured failure causes and fixes (G1/G2/G4/G6, locale, format, pin), `verify_repository.sh --all` stage list and environment blockers, floors measured, CI-only gates that `--all` does not cover (`## Open Questions` Q1-Q3) |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Recovery checkout is frozen: no staging, commits, branch or worktree changes there. Planning records for 191 are plain files only (D-23). All dry runs in this research used a throwaway copy of `<durable-candidate>` in `<scratch>`.
- Sensitive data: never record the adopter name, founder identity, geography, customer information, proprietary taxonomy or revealing links; never search git history or external sources to reidentify; use placeholders. Offline mutation payloads, tokens, account identifiers and stable device identifiers must not enter evidence, logs or proof artifacts.
- Fail-closed, no silent degradation: every check needs a negative control and must exit non-zero on an empty scope (the "absence scored as success" defect class).
- Piped checks mask exit codes (`cmd | tail && echo OK` is forbidden); capture exit codes to files.
- Default to zero-human verification: no `checkpoint:human-verify` for anything an automated check can decide. Human action is reserved for unavoidable credentials/approvals. Phase 191 contains no human gate (the first off-machine copy and the push belong to Phase 192).
- Write status in plain language first; explain internal codes after. Keep exactly one active handoff in STATE/ROADMAP.
- Before displaying a write proposal, exercise production adapters with real return shapes (Phase 175 lesson). Applies here to the carry/resolver tooling: run them against a temporary local fixture with real subprocess output before trusting them.
- Android is frozen. Note: `script/verify_repository.sh --all` still runs the `android-package-proof` stage (a Gradle unit test run); this is a verification of existing code, not new Android work.
- Merge must be a merge commit (D-03); no force push; no squash.

## Summary

Every fact the plan depends on was re-measured read-only this session, and the carry was prototyped end to end in `<scratch>` (a copy of `<durable-candidate>` at `2faf15a2`, a local throwaway branch, nothing pushed). The decisions in CONTEXT.md hold, but the prototype found **seven things CONTEXT.md does not know about** that would each turn the Phase 192 CI red or break a task as written. The planner must schedule them (details in `## Common Pitfalls` and `## Open Questions`):

1. **A naive carry makes 146 root tests fail** (2637 run, 78 excluded), not 7. About 100 are one cause: `script/check_release_workflow_integrity.exs:1683` reads a live `phases/175-...` file. The rest are the other six files in D-06 plus three more causes below. With the fixes below applied, the same run is 2637 tests with exactly 1 failure (the known G1 gate) under `LC_ALL=C.UTF-8`. [VERIFIED: ran full suite in `<scratch>` twice]
2. **D-06's helper already exists**: `Crosswake.Test.PhaseEvidencePath.resolve/2` in `test/support/phase_evidence_path.ex` (live first, then `milestones/*-phases/`). The six tests should call it; only the `.exs` script needs its own copy. One test (`phase174_cleanroom_lane_parity_test.exs`) already has a live-or-archived fallback but its archive path is wrong (`milestones/v23.0/phases/` instead of `milestones/v23.0-phases/`).
3. **`phase170_vacuity_taxonomy_convention_test` fails after the carry for a reason a resolver cannot fix**: it checks *every* live phase directory, and phases 176-190 (15 of them) have no `## Vacuity Taxonomy` section or addendum. It must be scoped to the closed v23 roster of seven phases (169-175), resolved live-or-archived.
4. **`mix crosswake.adoption_context.scan` (a merge-blocking CI step, outside `--all` and outside `mix test`) is already red on the candidate** with 5 `routing.unclassified_path` hits (new iOS shell files: `.xcconfig`, `.entitlements`, `.xcprivacy`, `.xctestplan` x2), and the carry adds 407 more (raw evidence extensions `.source`, `.tsv`, `.out`, `.sha256`, `.stdout`, `.stderr`, `.body`, `.patch`). Adding those 12 extensions to `@scannable_extensions` makes the scan pass and the 80 planning/adoption tests pass. D-10 says CI-only commands are Phase 192's, but this one is cheap and deterministic, and finding it in Phase 192 costs a remote cycle.
5. **Three Phase 189 plan files trip the same scanner as "commercial detail"**: awk field references such as `${10}` match the multi-digit-amount rule. A mechanical `$NN` to `${NN}` transform in those 3 files (recorded with both hashes, like the home-path transform) clears it.
6. **Carrying the workstream-level `config.json` and `state.json` (listed in D-07 item 5) breaks a CI test** (`test/js/phase167_pr_dispositions.test.mjs`, "local reconciliation accepts the tracked Phase 167 runtime authority fixture"): the Phase 167 validator pins those files as the *only untracked* planning files. Dropping both from the carry fixes it (66 of 66 pass). [VERIFIED: prototype]
7. **"Every commit keeps the suite green" (D-02) cannot hold for carry commits 1-4**: `milestone_transition_reset_test` ties archive presence to the live STATE milestone, and main's STATE still says v23.0 is active, so adding the v23.0 archive snapshot makes it red until the live files change in commit 5. Green is achievable at the code-fix checkpoint, the resolver checkpoint and the final HEAD.

Also found: the recovery tree itself fails `milestone_transition_reset_test` (REQUIREMENTS header and PROJECT heading do not carry the full milestone label that STATE names), and the local toolchain will mark two `--all` stages BLOCKED (`browser-proof`: global npm is 11.1.0 but the stage manifest requires ^10.9.2; `android-package-proof`: no Java 17 on `PATH`). Both have verified workarounds that touch nothing global.

**Primary recommendation:** Build the integration branch in a fresh clone in this order: clone, candidate fast-forward, code-fix commits (format, locale, Phase 180 inversions, WR-05/01/06/03, adoption-scan extensions), resolver commit, five carry commits with the redaction and `$NN` transforms and without the two runtime JSON files, then run `script/verify_repository.sh --all` and the example-host suite with a captured run root, add the cheap carry-sensitive CI-only commands as gate evidence, and run the HEAD-bound privacy scan last.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Branch construction, ancestry and carry equality proof | Local git (integration clone) | Phase 191 `scripts/` (bash + git + shasum) | One-time tooling lives in the phase folder (190 D-01); no repo `script/` additions |
| Code fixes (format, locale, test inversions, WR-05/01/06/03, scanner extensions) | Repo source and tests in the integration clone | `script/` Elixir scripts | These are the only parts that change shipped behavior or CI results; each is a commit with its test |
| Planning resolver | `test/support/` Elixir module (tests) | inline copy inside the one `.exs` script | `test/support` is outside the `test/**/*.exs` pin glob; script cannot load test support |
| Planning carry | Phase 191 manifest tool | git exact-rename detection | Content-based manifest, not the stale inventory |
| Full local suite | `script/verify_repository.sh --all` (Node orchestrator) + example-host `mix test` | `suite-gate-191` parser | Gate parses only totals and test names, never raw logs |
| Privacy scan | Vendored scanner (shell, over `git log -p`, `rev-list --objects`, tree names, identities) | gitleaks 8.30.1 binary | Scanner code lives in the phase folder; evidence stores counts and fingerprints only |
| Recovery-frozen proof | `recovery-snap-191` (read-only digests of the recovery `.git`) | none | Before/after equality is criterion 4 |

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| git | 2.41.0 (local) | Clone, fast-forward, commits, `rev-list`, `diff --raw`, `ls-files` | Pinned helper requires `--attr-source` (git 2.40+); 2.41 is the Phase 190 floor [VERIFIED: `git --version`] |
| POSIX sh / bash 5.2 | bash 5.2.37 | Phase scripts and self-tests | 190 pattern; no dependency [VERIFIED: `bash --version`] |
| shasum | system | Manifest and evidence digests | Already used by `recovery-snap-190.sh` [VERIFIED: read script] |
| Elixir / OTP | 1.19.5-otp-27 / 27.3 | Root suite, example host | `.tool-versions` on main; stage manifest regex requires exactly these [VERIFIED: `script/repository_verification_stages.json`] |
| Node (asdf) | 22.14.0 under main's `.tool-versions` | `verify_repository.mjs`, JS tests, Playwright | Stage manifest requires `^v22\.14\.0$` [VERIFIED: stage manifest + `asdf current` in `<durable-candidate>`] |
| gitleaks | 8.30.1 (`/opt/homebrew/bin/gitleaks`) | Secret layer of the scan | Installed, one static binary [VERIFIED: `gitleaks version`] |
| Swift / Xcode | Swift 6.3.3 / Xcode 26.6 | `ios-package-proof` stage | Stage regex `Swift version (5\.9\|6\.)` and `Xcode (1[5-9]\|[2-9][0-9])\.` [VERIFIED: probes ran] |
| Playwright | 1.60.0 (`package-lock.json`) | `browser-proof` stage | Needs `npm ci` and a matching Chromium in the fresh clone [VERIFIED: lockfile] |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| npm (private prefix) | 10.9.2 | Satisfies the stage regex without touching the global npm (11.1.0) | Prepend `<tmp>/npm10/node_modules/.bin` to `PATH` for `--all` [VERIFIED: installed to a scratch prefix, `npm --version` printed 10.9.2] |
| OpenJDK | 17.0.19 at `/opt/homebrew/opt/openjdk@17` | `android-package-proof` | Prepend its `bin` to `PATH` (stage probes `java -version` for `version "17.`) [VERIFIED: ran `java -version` and `gradlew --version` -> Gradle 8.7] |
| `CROSSWAKE_REPOSITORY_RUN_ROOT` / `CROSSWAKE_REPOSITORY_CAPTURE_ROOT` | env | Keep per-stage logs (`logs/<stage>.log`, first line `status=N`) so the gate can parse totals | The orchestrator deletes its run root unless these are supplied [VERIFIED: `script/verify_repository.mjs` lines 447-597] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Private npm 10.9.2 prefix | `npm i -g npm@10.9.2` | Mutates the user's global toolchain; avoid |
| Extending `@scannable_extensions` | Path exclusions for `.planning/**/evidence/**` | Extension add was measured (scan passes, 80 tests pass, raw evidence gets scanned, 0 privacy hits); an exclusion would also work but silently skips content |
| trufflehog | gitleaks only | D-18: add trufflehog only if a planted secret is missed |

**Installation:** none. No new dependency is added to the repository or the user's machine. The only fetches are (a) `git clone`/`fetch` of GitHub `main`, (b) `mix deps.get` (root, 5 companion packages, `examples/phoenix_host`), (c) `npm ci` in `examples/phoenix_host`, (d) a private `npm@10.9.2` prefix under `<tmp>`, and (e) possibly `npx playwright install chromium`.

**Version verification:** versions above were read from tool output this session (not training data). gitleaks rule count: **222**, obtained by writing a SARIF report on a clean range and counting `runs[0].tool.driver.rules` (the CLI has no rule-list command). [VERIFIED: ran]

## Package Legitimacy Audit

No package is added to the repository by this phase. `npm@10.9.2` is the version the repository's own stage manifest pins (it is the npm that ships with Node 22.14.0); it is installed only into a scratch prefix. gitleaks is already installed. `gsd-tools query package-legitimacy` was not run because there is no new recommendation to audit.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| npm@10.9.2 | npm | n/a (pinned by `script/repository_verification_stages.json`) | n/a | github.com/npm/cli | not run (repo-pinned) | Use only in a private prefix; `[ASSUMED]` legitimacy beyond the repo pin |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
GitHub main (d0dbdf7) --fetch--> [fresh clone <integration>] (repo-local noreply identity)
                                       |  ancestry gate: main is ancestor of candidate? else STOP (D-01)
<durable-candidate> refs/heads/candidate (2faf15a2, 94 ahead, 0 behind, linear)
        --fetch refs/heads/candidate--> [integration] --ff-only--> branch land/<name>
                                       |
        code-fix commits (each: test red -> fix -> test green)
          format | locale+G1/G2/G4/G6+ledger | WR-05 | WR-01(+06) | WR-03 test | adoption-scan extensions
                                       |
        resolver commit (6 tests call Crosswake.Test.PhaseEvidencePath; script gets inline copy;
                          phase170 vacuity test scoped to roster of 7)
                                       |
 <recovery-checkout> working tree (read-only plain-file source)
   --manifest (cut)--> path-to-milestone table --> exclusions --> redaction transform
   --> carry commits v23 | v24 | v25 | v26 | v27+live  (.planning/ only, trailers + digest)
                                       |
        suite gate: verify_repository.sh --all (RUN_ROOT kept) + examples/phoenix_host mix test
                    + carry-sensitive CI-only commands (adoption scan, js tests, script guards)
                                       |
        test-file pin recount, SEED-024, review dispositions, sync commit (records written after cut)
                                       |
        privacy scan bound to HEAD+main SHAs  --> evidence (counts, digests, fingerprints)
        recovery-snap-191 before == after  --> criterion 4
```

### Recommended Project Structure
```
.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/
├── scripts/
│   ├── git-pinned-191.sh        # g() with the repo as a parameter (190 hard-codes $CAND), commit helper
│   ├── locate-191.sh            # regenerates env file every run, owner/mode checked (WR-11)
│   ├── ensure-clone-191.sh      # clone, fetch candidate, ancestry gate, ff-only, HEAD==source compare
│   ├── recovery-snap-191.sh     # + index (ls-files -s), logs/HEAD, object count, fail on missing (WR-10)
│   ├── carry-191.sh             # manifest build, table, exclusions, transform, verify (D-09)
│   ├── suite-gate-191.sh        # strict totals parsing, MIN required, no baseline (WR-09)
│   ├── scan-191.sh              # vendored four-input scanner + gitleaks wrapper (WR-07, IN-02)
│   └── selftest-*.sh            # one controls file per tool, labelled S01..Snn
├── 191-EVIDENCE/                # counts, digests, fingerprints only (no raw logs, no paths)
└── 191-RESEARCH.md ...
```

### Pattern 1: Phase 190 successor scripts (what to copy and what changes)
**What:** Every 190 script is a POSIX shell file with `set -u`, `umask 077`, fixed labels, an env file sourced after `locate`, and a `selftest-*.sh` with labelled controls that print `Snn <name>: as expected`.
**Reusable as-is:** `git-pinned-190.sh` (scrub list, fixed env, pins incl. `--attr-source=<empty tree>`), the control harness in `selftest-scan-190.sh` (`mk_tree`, `run_ctl`, trap cleanup, `expect RC LABEL`), the evidence header shape (`head <sha>`, counts, `result pass|fail`).
**What 191 must change (all verified against the 190 source):**
| Defect | 190 script | 191 change |
|--------|-----------|------------|
| `g()` hard-codes `-C "$CAND"` | `git-pinned-190.sh` | Take the repo path as a variable name or first argument; also provide a pinned *commit* path (the scrub unsets every `GIT_*`, and `GIT_CONFIG_GLOBAL=/dev/null` removes the user identity, so commits need `-c user.name`/`-c user.email` or `GIT_AUTHOR_*` set after the scrub) |
| MIN defaults to 0; baseline written before validation; `git diff --quiet HEAD` ignores untracked files; unpinned git; `LC_ALL=C` exported to children (WR-09, D-12) | `suite-gate-190.sh` | Require MIN > 0; validate then write via temp + rename; untracked check through pinned git `status --porcelain --untracked-files=all`; no `LC_ALL=C` for child processes; no baseline mode |
| `G=${REC_GIT:?}` accepts a nonexistent folder; no index/reflog/object coverage (WR-10) | `recovery-snap-190.sh` | Fail on missing folder/HEAD/config; add `ls-files -s` digest (content, not the raw index file, because any stat refresh by another tool rewrites `.git/index` bytes), `logs/HEAD` digest, object-file count |
| `--ensure` keeps an existing env file without owner/mode check; fixed shared temp folder; unpinned git (WR-11) | `locate-190.sh`, `ensure-work-190.sh` | Regenerate every run; check owner and mode 700 on the folder; pinned git; compare clone HEAD with source HEAD |
| `\|\| pl=` hides failing probes (WR-08, deferred) | `run-once-05-190.sh` | Not reused in 191 |
| Credential class case-sensitive, most classes uncontrolled (WR-07, IN-02) | `scan-privacy-190.sh`, `selftest-scan-190.sh` | New scanner: case-insensitive classes (except hex shapes), one planted control per class and position (D-19) |

### Pattern 2: Resolver reuse
`Crosswake.Test.PhaseEvidencePath.resolve("quality-ratchet-release", "<phase-dir>/<relative>")` returns the live path if it exists, otherwise the last sorted match of `.planning/workstreams/<ws>/milestones/*-phases/<relative>`, otherwise the live path (so a missing file still fails loudly). [VERIFIED: read `test/support/phase_evidence_path.ex`]. It is already used by `phase165_evidence_test.exs` and `phase166_repository_quality_test.exs`. Use it for the six test files; copy its logic (about 12 lines) inline for `script/check_release_workflow_integrity.exs`, which runs as a plain `elixir` script and cannot load `test/support`.

### Anti-Patterns to Avoid
- **Empty directories after file moves.** `resolve/2` treats an existing live directory as present. In a git checkout, empty directories vanish, so the real branch is fine, but any prototype that deletes files without removing directories will mis-resolve.
- **Measuring the pin with a literal glob through git.** `git ls-files 'test/**/*.exs' | wc -l` prints **252** (it skips `test/test_helper.exs`), while `find test -name '*.exs'` and the guard (`Path.wildcard("test/**/*.exs")`) report **253**. Use `git ls-files test | grep -c '\.exs$'` or `git ls-files ':(glob)test/**/*.exs'` (both print 253). A literal reading of D-16 would fail on a false mismatch. [VERIFIED: ran all four]
- **`mix compile --warnings-as-errors` as the only warnings check.** It passes on an up-to-date build; add `mix compile --force --warnings-as-errors` in the fresh clone once (exit 0 at the candidate HEAD, verified).
- **Counting gitleaks "commits scanned" against `rev-list --count`.** gitleaks only counts commits with added lines ("this number might be smaller than expected due to commits with no additions" is in its own debug output; planted control: 2 commits in range, "1 commits scanned"). Apply the equality check to the vendored scanner, not to gitleaks.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Live-or-archived planning path lookup in tests | A new helper | `Crosswake.Test.PhaseEvidencePath.resolve/2` | Already exists, outside the pin glob, already used twice |
| Secret detection (token shapes, PEM, Hex/Maven keys) | Regexes for 222 rule shapes | gitleaks 8.30.1 `git --log-opts` | The vendored scanner covers only the project-specific classes (adopter terms, paths, UDIDs, identities) |
| Exact-rename pairing for the v23 archive move | A move detector | git's own rename detection on the commit (deletes and adds together) | The manifest uses `diff --raw --no-renames` for equality; renames are only a presentation benefit |
| Iterating stage results of the suite | Re-running stages | `script/verify_repository.sh --all` with `CROSSWAKE_REPOSITORY_RUN_ROOT` set | Already writes `logs/<stage>.log` with `status=N` as the first line |
| Counting JSON/rule totals by hand | Parsing gitleaks log lines | SARIF output for the rule count; JSON report length for findings | Log format is not a contract |

**Key insight:** every defect class in this phase is "a check that reports success while checking nothing" (empty scope, masked exit code, unpinned git, untracked files ignored, a locale that corrupts the data being checked). Each tool needs a labelled negative control, and counts must come from a separate measurement.

## Verified Ground Truth (facts the plan depends on)

| # | Fact | Evidence |
|---|------|----------|
| F1 | GitHub `main` is `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`; `main` is an ancestor of the candidate | `git ls-remote origin refs/heads/main` and `merge-base --is-ancestor` against `<durable-candidate>` [VERIFIED: ran] |
| F2 | Candidate `2faf15a255f644c869d321508c4d3f3007572138` is 94 ahead and 0 behind `main`; 4 ahead of `a53fbef7`; 0 merge commits; first-parent count 94; 180 files changed (+34396/-326); 0 binary files in `numstat`; 0 tags/notes; 1232 new objects | [VERIFIED: ran in `<durable-candidate>`, read-only] |
| F3 | The candidate range touches 0 `.planning/` paths | `git diff --name-only main candidate \| grep -c '^\.planning/'` = 0 [VERIFIED] |
| F4 | `<durable-candidate>` has `origin` = a local bundle (fetch) and `no-push-durable` (push); working tree clean | [VERIFIED: `git remote -v`, `status --porcelain`] -> the new clone must use the GitHub URL from the recovery checkout's `origin`, not copy this remote |
| F5 | Merge-base of `main` and the recovery HEAD is `52345b48bb32e25b3ec9390e81612bacc8688f5d`; recovery HEAD `d0f3e2f1...` is 249 ahead and 91 behind | [VERIFIED: `merge-base`, `rev-list --count`] |
| F6 | D-08 check 1 holds today: main's only planning changes since the merge-base are 5 added Phase 175 files (`175-11-SUMMARY`, `175-26-SUMMARY`, `175-27-SUMMARY`, `175-RECOVERY-GUARDS`, `175-REL17-CLOSURE`) and all 5 are byte-identical at their archive path in the recovery tree | [VERIFIED: blob compare] |
| F7 | Recovery git state equals the Phase 190 before-snapshot (HEAD, packed-refs, 22 loose refs, stash log 4 lines, 2 worktrees, config) | `recovery-snap-190.sh` re-run, `diff` empty [VERIFIED] |
| F8 | Locale cause (D-12): under `LC_ALL=C` the Phase 170 test file gives 19 tests / 5 failures (`JSON.DecodeError invalid byte 120 at position 794`); under `LC_ALL=C.UTF-8` it gives 19 / 0. `IO.write` at `script/inventory_collection_assertions.exs:86` (`--emit-snapshot`) and `:107` (`--emit-remediation`) escape non-ASCII under C; `IO.binwrite` writes the UTF-8 bytes (verified with `od -c`). `C.UTF-8` exists on this machine | [VERIFIED: ran] |
| F9 | G1 (root): with no registry given, `host.study.audio.play` on an `:offline_island` route returns `[]`; an unknown core capability returns exactly one `%Crosswake.Policy.Error{key: :capabilities, message: "unknown capability \"...\""}` | [VERIFIED: ran `Validator.validate/2` in `<scratch>`] |
| F10 | Example host suite at candidate: **167 tests, 2 failures** (G2 gate, G6 gate), 8.2 s. G2: generated activation for `offline-study` carries `%{"host.study.audio.play" => "1.0.0"}`. G6: manifest has **37 routes**; exactly one, `offline-study` (runtime `offline_island`), declares a `host.` capability: `["host.study.audio.play"]` | [VERIFIED: ran `mix test` and a manifest probe in `examples/phoenix_host`] |
| F11 | Swift package at candidate: **89 tests, 2 skipped, 1 failure** (G4 gate). With `PHASE180_EXPORT_DIR` set to the example host's `_build/phase180/probe`, the four G3 tests and the G4 control pass and only G4 gate fails. So the G3 gate test **currently passes when the export exists**; D-14's "invert the G3 gate" has no failing assertion to repair (see Open Questions Q7). `ShellPresentation` has a `.offlineIsland(LiveViewSession)` case, so the inverted G4 assertion is `guard case .offlineIsland = result` | [VERIFIED: ran `swift test`, read `ActivationCoordinator.swift:321-327, 548-566`] |
| F12 | Root suite size at the Phase 190 gate (`suite-FIX-06`): `2637 tests, 6 failures (78 excluded)`, 345 s wall clock; totals line shape `N tests, F failures (E excluded)` | [VERIFIED: read `suite-FIX-06.raw` tail] |
| F13 | Format (D-15): `mix format --check-formatted` lists exactly one file, `test/crosswake/guides/native_shell_upgrade_test.exs`; the diff only removes redundant parentheses around `(guide <> upgrade)` (`<>` binds tighter than `=~`) and splits one long line | [VERIFIED: ran in `<scratch>`] |
| F14 | `mix compile --force --warnings-as-errors` at the candidate HEAD exits 0 | [VERIFIED: ran] |
| F15 | Test-file pin: `Path.wildcard("test/**/*.exs")` = 253 = pin at `script/check_absence_is_not_success.exs:65`; the guard run on the prototype prints `scanned 253 test files, pin 253` and `seeds 23` (adding SEED-024 makes it 24; the minimum is 1, so no pin change) | [VERIFIED: ran] |
| F16 | `script/inventory_collection_assertions.exs --check` passes (243 classified sites) at the candidate and at the prototype under both `LC_ALL=C` and UTF-8 *before* the locale fix is applied to the child-process env; the G1-control override key is `sha256:af020bc44efa8111` at `script/inventory_collection_assertions.exs:446-450` and `script/collection_assertion_ledger.json:171`; the ledger row's `display` carries the test file line (`...phase180_twin_feasibility_test.exs:40`), so editing earlier lines of that test file moves it | [VERIFIED: read] |
| F17 | gitleaks 8.30.1: `gitleaks git --no-banner --redact --log-opts="<main>..HEAD" --report-format json --report-path <file> --ignore-gitleaks-allow .` over the candidate range: exit 0, "94 commits scanned", report `[]`. A planted `ghp_`-shape token added in one commit and deleted in the next: exit 1, one finding (`github-pat`), `Secret` = `REDACTED`. It runs `git log -p -U0 --full-history --all --diff-filter=tuxdb` (unpinned `git` from `PATH`, so scrub `GIT_*` in its environment). No `.gitleaks.toml` or `.gitleaksignore` is tracked | [VERIFIED: ran on `<scratch>` and a temp repo] |
| F18 | `--all` stage list (9 records): `repository-preflight`, `root-proof` (`mix verify`), `example-host-proof` (`script/check_example_host_isolation.sh --matrix-only`), `browser-proof` (`npx playwright test` in `examples/phoenix_host`), `ios-package-proof` (`swift test`), `android-package-proof` (`./gradlew --no-daemon test`), `format-proof` (`mix format --check-formatted`), `warnings-proof` (`mix compile --warnings-as-errors`), `repository-cleanliness` (`git diff --check` plus generated-contract and artifact policy). `--all` fails immediately if `git status --porcelain --untracked-files=all` is non-empty before it starts | [VERIFIED: read `repository_verification_stages.json` and `verify_repository.mjs:458-470`] |
| F19 | `mix verify` (root-proof) = `companions.test` (5 companion lanes, each `deps.get --check-locked` then `mix test`) + `mix test --only phase41_nested_process --seed 748644 --max-cases 1` + `mix test --exclude phase41_nested_process --exclude requires_example_host --exclude advisory_only --seed 748644 --max-cases 8`. Expect 7 totals lines in its log [ASSUMED from the alias; confirm on the first run] | [VERIFIED: read `mix.exs:71-93`] |
| F20 | Default exclusions in `test/test_helper.exs`: `advisory_only` (unless `MIX_INCLUDE_RULESTEAD=1`), `collateral_binaries` (unless `CROSSWAKE_INCLUDE_COLLATERAL=1`), `engine_present` (unless `MIX_ENGINE_PRESENT=1`), `requires_example_host` (unless `CROSSWAKE_INCLUDE_EXAMPLE_HOST=1`). `phase41_nested_process` is **not** excluded by the helper; it is excluded/selected only by the `mix verify` command lines (a plain `mix test` runs it, which is why 2637 includes it) | [VERIFIED: read `test/test_helper.exs`, `mix.exs`] |

## Path-to-milestone table (D-07 proposal, content-based)

Computed by hashing every file under the recovery working tree's `.planning/` (4267 files, 0 symlinks, 0 special files, 22 executable) against `git ls-tree -r main -- .planning` (1921 files) with `git hash-object` (no writes). [VERIFIED: ran]

| Class | Count |
|-------|-------|
| identical to main | 1767 |
| modified (present on both, different) | 13 |
| recovery-only (added) | 2487 |
| main-only (deleted from recovery tree) | 141 (119 pure moves into `milestones/v23.0-phases/`, byte-identical; 22 moved copies whose archived content differs from main's live copy) |
| gitignored (not addable without `-f`) among added+modified | 29 (`.DS_Store` + 28 `research/.cache` files) - all already in D-04's exclusion list; nothing else in the delta is ignored |

Added bytes across the 2487 added files: about 35.1 MB; largest single file 568 KB. 43 added files are excluded (below), so **2457 files are copied and 141 deleted**. Exclusions (explicit paths; each excluded path must be recorded with its reason):
`.planning/.DS_Store`; `.planning/research/.cache/**` (28); `.planning/agent-history.json` (R-PL-04); `.planning/debug/plan143-token-gate.md` (R-PL-06 untracked part; the other 5 debug files are committed in the recovery HEAD and are carried); `.planning/estimation-calibration.json` (R-PL-07); `.planning/forensics/**` (3, R-PL-08); `.planning/quick/261010-crw-current-read-wrapper-diagnostic/**` (2, R-PL-09 untracked; the two older quick folders are on main already); `.planning/tmp/**` (3, R-PL-13); `.planning/v25.0-MILESTONE-AUDIT.initial.md`, `.planning/v25.0-MILESTONE-AUDIT.md`, `.planning/v26.0-MILESTONE-AUDIT.md` (R-PL-14..16; confirmed byte-identical to their `milestones/` copies with `cmp`). Add to the exclusions (see Pitfall 6): `.planning/workstreams/quality-ratchet-release/config.json` and `.../state.json`.

Rules (first match wins; an unmatched path fails the run, D-07). Prefix `WS` = `.planning/workstreams/quality-ratchet-release/`:

| # | Commit | Rule (path pattern, status) | Files |
|---|--------|-----------------------------|-------|
| 1 | v23.0 | `WS phases/{169..175}-*/**` (D), `WS milestones/v23.0-*` (A: `v23.0-phases/**` 1598, `v23.0-closeout/**` 26, three `v23.0-*.md`), `WS milestones/v22.0-phases/168-0-2-1-release-candidate-readiness/{168-UAT,168-VERIFICATION}.md` (M), `.planning/debug/**` committed files (5), `WS history/workflow-reset-*` (6, dated 2026-10-11) | 141 D + about 1640 A/M |
| 2 | v24.0 | `WS phases/17[6-8]-*/**` (153), `WS v24.0-*` (`v24.0-SCOPE.md`, `v24.0-MILESTONE-AUDIT.md`, `v24.0-audit/**` 7), `WS milestones/v24.0-*` (11), `WS history/{phase177-*,phase178-*,v24.0-*}` | about 190 |
| 3 | v25.0 | `WS phases/{179..183}-*/**` (207), `.planning/research/v25/**` (20), `WS v25.0-SCOPE.md`, `WS v25.0-start/**` (4), `WS milestones/v25.0-*` (9), `WS history/v25.0-*` | about 260 |
| 4 | v26.0 | `WS phases/{184..188}-*/**` (144), `.planning/research/v26/**` (7), `WS v26.0-SCOPE.md`, `WS milestones/v26.0-*` (8), `WS history/v26.0-*` | about 170 |
| 5 | v27.0 + live | `WS phases/{189,190,191}-*/**` (177), `WS v27.0-SCOPE.md`, `WS PHASE175-STANDING-AUTHORIZATION.md`, `WS .continue-here.md`, and the modified live files: `.planning/{PROJECT,RETROSPECTIVE,WINDOWS}.md`, `.planning/config.json`, `.planning/seeds/SEED-014-*.md`, `.planning/seeds/SEED-023-*.md`, `WS {STATE,ROADMAP,REQUIREMENTS,MILESTONES}.md`, `WS .verification-ledger.json` | about 190 |

Counts per phase folder in the recovery tree: 176: 18, 177: 60, 178: 75, 179: 85, 180: 43, 181: 32, 182: 26, 183: 21, 184: 44, 185: 25, 186: 19, 187: 23, 188: 33, 189: 117, 190: 58, 191: 2 (plus `192-*`/`193-*` folders that are empty and untracked: the table must tolerate directories with no files). The v23.0-phases archive splits 24/19/19/14/16/34/1472 files across phases 169-175 (1062 of the 175 files are under `evidence/`, 31 under `attempt-roots/`).

Rule notes for the planner:
- v22.0-phases `M` files and `history/workflow-reset-*`, `debug/**` are not named in D-07; the recommended bucket is commit 1 (they are v23-era). This is a discretion call (Open Question Q8).
- File modes: 22 files are executable in the recovery tree; the manifest must store mode and the verification must compare it (a `chmod`-only change is one of D-09's negative controls).
- The carry reads from the recovery working tree, including uncommitted edits; the recovery HEAD is not the source. Hash at the declared cut and re-verify just before each commit (the user's flow may edit plain files in the recovery tree during the phase).
- Every path in the delta is a regular file or an absent path; there are 0 symlinks, so "refuse symlinks" can be a hard error with no expected exceptions.

## Privacy Scan Grounding

Measured (counts only; values were not read into this document):

| Input | Result |
|-------|--------|
| Candidate range `main..candidate`, added lines | 0 lines with a home-directory path, 0 with a per-user temp path (`/private/var/`, `/var/folders/`) |
| Candidate range identities | 1 distinct author/committer identity (the public handle already on main) with a `users.noreply.github.com` email on all 94 commits. Main's identities: 2 numbered noreply addresses, `crosswake-release@users.noreply.github.com`, `noreply@github.com`, and the handle's noreply address |
| Carried planning delta (2457 files after exclusions) | 243 files contain a home-directory path (143 in the v23 archive, about 100 in phases 176-188, 5 in other paths); 8 files contain a per-user temp path (`175-77-PLAN.md`, `176-evidence.mjs`, `184-RESEARCH.md`, `186-RESEARCH.md`, `188-03-PLAN.md`, `188-05-PLAN.md`, `188-VALIDATION.md`, `190-RESEARCH.md`) - D-21 names only the home path, so the transform must also cover `<tmp>`; 239 files contain the local username as a word, and **8 of those contain it outside any `/Users/<name>` path** (they will survive the `<home>` transform and need triage or a second rule); 127 files contain email-shaped text |
| Email shapes in the carry | Not personal addresses: `git@github.com` (ssh remotes, 96 occurrences), `noreply@github.com` (22), `noreply@anthropic.com` (co-author trailers), and reserved example domains. The "non-noreply email" class must allow `noreply@*`, `git@github.com` and the reserved example domains, or it will block on benign data |
| Token-shaped text | 1 file (`178-clean-checkout-and-final-ci/178-evidence/proposal_delivery.test.mjs`) has a `ghp_`-shape string inside a fabricated test fixture; triage as benign by fingerprint |
| Locale of the work | `LC_ALL=C` is correct for `sort`/`comm`/pinned git only |

Scanner design implications (D-18/D-19): add `/Users/<name>`, `/private/var/`, `/var/folders/` and the username word as separate labelled classes; make the email class allow-list explicit; use `git log -p --no-renames -m --no-ext-diff --no-textconv` with a pinned git; scan `rev-list --objects` blobs as raw bytes; expect the planted-control matrix to include: added-then-deleted, binary blob, commit message, author email, file name, upper-case credential, canary adopter term, gitleaks shape. The denylist input is `CROSSWAKE_PRIVATE_ADOPTER_TERMS` (comma-separated, trimmed, case-insensitive; the in-repo test at `test/crosswake/planning/first_adopter_context_test.exs:152-160` reads it and passes with zero terms, which is exactly the vacuity D-18 closes with "zero terms = exit 2"). Running the suite once with that variable set makes that existing test non-vacuous; never echo the value.

## Common Pitfalls

### Pitfall 1: The naive carry turns 146 tests red
**What goes wrong:** Running the suite after the carry alone gives `2637 tests, 146 failures`.
**Why it happens:** (a) `script/check_release_workflow_integrity.exs:1683` `File.read!`s `phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md` (about 100 tests across `Phase142ReleaseIntegrityTest` 43, `Phase173RecoveryProofConvergenceTest` 13, `Phase175ReleaseRecoveryTest` 10, `Release.StatusTest` 6, `Phase171NoBareVersionLiteralTest` 6, `Phase153IosMirrorUnblockTest` 5 - all shell out to that script); (b) the six other D-06 files; (c) `phase170_vacuity_taxonomy_convention_test` (Pitfall 2); (d) `MilestoneTransitionResetTest` x2 and its derived `Phase135CiOpsProofTest` x1 (Pitfall 4).
**How to avoid:** apply the resolver commit first; measure with the full suite, not by file.
**Warning signs:** `File.Error ... phases/17x-...: no such file or directory`.

### Pitfall 2: A resolver is not enough for the vacuity-taxonomy test
**What goes wrong:** After the resolver, `Task 2: every phase VERIFICATION.md under this workstream complies with the convention` still fails, listing phases 176-190, and `findings floor` / `non-vacuity control` fail if the phase directory is only resolved live.
**Why it happens:** `@phases_glob` is `phases/*`; after the move the live set is 176-190 and none carries `## Vacuity Taxonomy` or a `*-VACUITY-TAXONOMY.md` addendum (the convention file is titled "Milestone v23.0 Verification Convention"). The control reads `File.ls!(".../phases/169-diagnostic-legibility")`, which is gone.
**How to avoid:** scope the test to a literal roster of the seven v23 phases, resolve each through `PhaseEvidencePath`, and assert the roster length (7). Prototype diff (about 30 lines in one file) passed after this change.
**Warning signs:** the offender list names `176-local-work-and-artifact-disposition`.

### Pitfall 3: Wrong archive path in an existing fallback
`phase174_cleanroom_lane_parity_test.exs:37` has `@archived_phase_dir ".../milestones/v23.0/phases/174-..."`; the archive is `milestones/v23.0-phases/174-...`. Its fallback never matched. Replace both attributes by one `resolve/2` call.

### Pitfall 4: The recovery tree's live records disagree with the test that guards them
**What goes wrong:** `MilestoneTransitionResetTest."live operational surfaces all name the milestone from STATE frontmatter"` fails on the carried tree.
**Why it happens:** STATE says `milestone_name: Land and Clean Up (Phases 189–193) — in progress`; the test requires `"v27.0 <that name>"` in ROADMAP (present), REQUIREMENTS (header reads `# Requirements: v27.0 Land and Clean Up`, missing the suffix) and a `### v27.0 ... (active)` heading in PROJECT.md (absent; PROJECT has `### Quality Ratchet & Release — v27.0 Land and Clean Up active`). The same test would fail in the recovery tree today.
**How to avoid:** edit those two plain files in the recovery working tree before the cut (header line 1 of REQUIREMENTS; heading in PROJECT). These are plain-file writes, allowed by D-23, and the manifest then records them as ordinary content. Prototype: both edits made the test pass. After each later GSD transition (Phases 192/193) STATE's name will change and the same test must be re-run.

### Pitfall 5: `mix crosswake.adoption_context.scan` is red and is not in the D-10 suite
**What goes wrong:** CI step "Enforce first-adopter privacy gate" (crosswake-ci.yml around line 421, also line 121) fails with 5 `routing.unclassified_path` hits on the candidate and 412 after the carry (359 `.source`, 23 `.tsv`, 7 `.out`, 6 `.sha256`, 4 each `.stdout`/`.stderr`/`.body`, 1 `.patch`, plus the 5 iOS files).
**Why it happens:** `@scannable_extensions` in `lib/crosswake/planning/first_adopter_context.ex:67` lacks those extensions; unknown extensions are violations by design (fail closed).
**How to avoid:** a `fix` commit adding the 12 extensions, plus a test that each of the 12 classifies as scanned. Measured after the change: the scan prints `adoption context scan passed` and `test/crosswake/planning` + `crosswake_adoption_context_scan_test.exs` give 80 tests / 0 failures (no privacy rule fires on the raw evidence). This is a library source change in `lib/`; see Open Question Q2 for the alternative (path exclusion).

### Pitfall 6: Two workstream runtime files must stay untracked
`script/check_phase167_pr_dispositions.py` (`RUNTIME_PATHS`, `runtime_clean()` and the local-reconciliation branch near line 1606) requires `git ls-files --others` to equal exactly `WS config.json`, `WS milestone.lock`, `WS state.json`. Tracking `config.json` and `state.json` fails `test/js/phase167_pr_dispositions.test.mjs` test 33 (expected 0, actual 1). Untracking them: 66 pass / 0 fail. That test runs in the CI step `node script/check-e2e-honesty.mjs && node --test test/js/*.mjs`.

### Pitfall 7: Scanner false positive on shell field references
`FirstAdopterContext.commercial_detail?/2` flags prose-extension files that match `\$\s*(?:\d{2,}|\d+\.\d{1,2})\b`; `${10}` in an awk expression matches. Affected: `189-06-PLAN.md`, `189-08-PLAN.md`, `189-11-PLAN.md` (exactly 3 files; `FirstAdopterContextTest` x2 and the CLI scan). Mechanical `s/\$(\d{2,})/${\1}/g` on those three files cleared both.

### Pitfall 8: `--all` is BLOCKED locally without environment shims
`browser-proof` is BLOCKED because `npm --version` prints **11.1.0** (global npm was upgraded inside the asdf Node 22.14.0 install; the stage regex is `^10\.9\.2$`). `android-package-proof` is BLOCKED because `java` is not on `PATH`. Fix with `PATH` prepends only (see Environment Availability). BLOCKED stages exit the orchestrator non-zero and are a gate failure, never a skip.

### Pitfall 9: `--all` rejects a dirty tree and deletes outputs it created
It fails with `FAIL repository-cleanliness` if any tracked change or untracked (non-ignored) file exists, so every fix and carry must be committed first. It also removes `_build`/`deps` directories it created if they did not exist before the run; build once beforehand if you want to keep them for the example-host run.

### Pitfall 10: Intermediate commits cannot all be green
`MilestoneTransitionResetTest."milestone archive presence matches active/shipped state"` asserts that the milestone named by STATE (main: v23.0, active) has **no** archived `v23.0-REQUIREMENTS.md`/`v23.0-ROADMAP.md`. Carry commit 1 adds exactly those. So D-02's "every commit keeps the suite green" is satisfiable only at: after the code-fix commits, after the resolver commit, and at the final carry HEAD. Run the targeted carry-sensitive subset at each carry commit and record the single expected red test by name for commits 1-4, or reorder so the live-file group (STATE/ROADMAP/REQUIREMENTS/PROJECT) is not last (this breaks the per-milestone split; Open Question Q4).

### Pitfall 11: Test-pin measurement with a glob through git
See Anti-Patterns: 252 vs 253.

### Pitfall 12: Pinned git and commit identity
`git-pinned-190.sh` unsets all `GIT_*` and sets `GIT_CONFIG_GLOBAL=/dev/null` and `core.hooksPath=/dev/null`; a commit through it has no identity and no hooks. Pass `-c user.name` and `-c user.email` explicitly (noreply address, per D-01). Global config also contains a `url.<file-url>.insteadOf` rewrite (iOS mirror); the pinned helper ignores it, plain `git` does not - do not use plain `git clone` for the integration clone except for the initial fetch.

## Code Examples

### D-12: stdout bytes independent of locale (verified)
```elixir
# script/inventory_collection_assertions.exs, line 86 and line 107
root |> rows(scope) |> render_snapshot(scope) |> IO.binwrite()
# ...
|> render_remediation(frozen_at(root))
|> IO.binwrite()
```
Evidence: `LC_ALL=C elixir -e 'IO.write("a — b\n")' | od -c` shows `\ x { 2 0 1 4 }`; the same with `IO.binwrite` shows the UTF-8 bytes. Negative control for the test: run `LC_ALL=C elixir script/inventory_collection_assertions.exs --check` and the regenerated snapshot decode under `LC_ALL=C` (add it to an existing test file; no new `.exs`).

### D-13: G1 inverted in place (no `Enum.any?/all?`), verified values
```elixir
@tag phase180_gate: "G1"
test "G1 gate: the host audio command on an offline_island route validates without errors" do
  assert validate_with(["host.study.audio.play"]) == []
end

@tag phase180_gate: "G1"
test "G1 gate: an unknown core capability yields exactly one capabilities error" do
  assert [error] = validate_with(["not_a_core_capability"])
  assert error.key == :capabilities
  assert error.message =~ "unknown capability"
end
```
Values from F9. `validate_with/1` builds an `:offline_island` route with `offline: :local_first, security: :standard` (read from the existing test). Then edit the `@manual_overrides` rationale text for key `sha256:af020bc44efa8111` (the sentence "The paired G1 gate test ... asserts exactly one capabilities error ... for an unknown capability" must stay true) and regenerate `script/collection_assertion_ledger.json` with `elixir script/inventory_collection_assertions.exs --emit-snapshot` redirected to the ledger path; then `--check` must pass. Counts change only from a separate measurement (current: 243 sites).

### D-14: example-host G2 and G6 inverted (verified values F10)
```elixir
@tag phase180_gate: "G6"
test "G6 gate: exactly one compiled route declares the host capability" do
  manifest = manifest_map()
  declaring =
    for {id, route} <- manifest["routes"],
        Enum.any?(route["capabilities"] || [], &String.starts_with?(&1, "host.")),
        do: {id, Enum.filter(route["capabilities"], &String.starts_with?(&1, "host."))}
  assert declaring == [{"offline-study", [@command]}]
  assert manifest["routes"]["offline-study"]["runtime"] == "offline_island"
end

@tag phase180_gate: "G2"
test "G2 gate: generated activation for the probe carries the host command" do
  assert {:ok, out} = Crosswake.Shell.IOSHostGeneration.render(config(@probe))
  assert activation_capabilities(out.activation) == %{@command => "1.0.0"}
end
```
(The example host is outside the root ledger scope, so `Enum.any?` inside a comprehension filter does not change the ledger; the CONTEXT prohibition on those forms applies to root `test/**` assertions.)

### D-14: Swift G4 inverted
```swift
func test_G4_gate_bounded_shell_admits_offline_island_runtime() {
    let manifest = makeManifest(routeID: "study", runtime: "offline_island")
    let request = makeRequest(routeID: "study")
    let c = coordinator(manifest: manifest, request: request, delegate: nil)
    let result = c.resolve(request: request, manifest: manifest)
    guard case .offlineIsland = result else {
        XCTFail("Expected offlineIsland, got \(result)")
        return
    }
}
```
To exercise the export-dependent G3 tests locally: `(cd examples/phoenix_host && mix test --only phase180_export:probe)` writes `_build/phase180/probe/{route_activation.json,crosswake_manifest.json}`; then `PHASE180_EXPORT_DIR=<that dir> swift test --filter Phase180TwinFeasibilityTests` (4 G3 tests + control pass at the candidate). The default `swift test` skips exactly two tests by `XCTSkip`: `test_G3_gate_generated_activation_session_lacks_host_command` and `test_G3_control_exported_request_carrying_command_reaches_delegate` (89 total, 2 skipped).

### D-06: inline resolver for the one `.exs` script (about 12 lines)
```elixir
defp phase_evidence_path(workstream, relative) do
  live = Path.join([".planning/workstreams", workstream, "phases", relative])

  if File.exists?(live) do
    live
  else
    [".planning/workstreams", workstream, "milestones", "*-phases", relative]
    |> Path.join() |> Path.wildcard() |> Enum.sort() |> List.last() || live
  end
end
```
Test side, for example: `@evidence_log Crosswake.Test.PhaseEvidencePath.resolve("quality-ratchet-release", "174-clean-room-host-realism-adopter-fidelity/evidence/174-legacy-rindle-local-run.log")`. Complete reference list of the seven files (the 13 matching lines include 2 comment-only lines): `script/check_release_workflow_integrity.exs:1683`; `phase170_vacuity_taxonomy_convention_test.exs:117,125` (+ glob, Pitfall 2); `phase174_cleanroom_host_realism_test.exs:11 (doc),27`; `phase174_cleanroom_lane_parity_test.exs:36,37`; `phase174_companion_findings_test.exs:32`; `phase175_runbook_ancestry_test.exs:87,88,89,106`; `test/mix/tasks/crosswake_release_status_test.exs:100` (comment only; its 6 failures came from the script). Add a negative control: a resolver call on a path that exists in neither place must return the live path and make the caller fail.

### D-05 of 190 / D-17a: WR-05 seam (verified code)
`activation_refusal/1` in `lib/crosswake/proof_lane/physical_iphone_preflight.ex:186-201` accepts any value for which `Jason.decode/1` returns `{:ok, _}`. `observe_activation/1` in `lib/crosswake/shell/ios_host_origin_mode.ex` is private and already encodes the required shape: `{:ok, %{"origin" => origin}} when is_binary(origin)` and `canonical_origin(origin)` returning `{scheme, canonical}`. Expose a `@doc false` function that returns whether that shape holds (reusing `canonical_origin/1`), leave `observe/2` unchanged, and have `activation_refusal/1` return `@unreadable_activation_reason` unless it holds. Table cases: `null`, `[]`, `{}`, `{"origin": 5}`, `{"origin": ["http://127.0.0.1:4790"]}`, an origin string that does not canonicalize.

### D-17a: WR-01 seam (verified code)
`annotate_stop/2` in `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex:94-100` rewrites the verdict only for `{:error, :registry_timeout}` and has a catch-all `annotate_stop(verdict, _stop_result)`. Add one clause each for `{:error, :child_still_alive}` and `{:error, :registry_gone}` with distinct notes (cause `"first cause: none"` becomes the new cause string; the exit code and the written receipt do not change), and replace the existing "every other stop result returns the verdict unchanged" test (`test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs`, near line 752) with one assertion per result.

### The suite gate parse (D-19 shape; values from F12/F19)
Totals line: `^[0-9]+ tests?, [0-9]+ failures?(, [0-9]+ invalid)?(, [0-9]+ skipped)?( \([0-9]+ excluded\))?$` - match strictly, fail on a non-matching line that begins with a digit and contains "tests". `status=N` is the first line of each `logs/<stage>.log`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Diagnose Phase170 failures as order-dependent | Locale (`LC_ALL=C` + `IO.write`) | this research | Remove `LC_ALL=C` from the child-process env, fix with `IO.binwrite` |
| Phase 180 gates assert a blocker | The blocker is refuted (`verdict: existing_path_supported`); tests assert the decided fact | 181 seam landed | Invert G1/G2/G4/G6 |
| One scanner for code and evidence | Vendored scanner + gitleaks | D-18 | `scan-privacy-190` stays for evidence files only |

**Deprecated/outdated:** the 190 baseline-comparison gate (D-11 supersedes it for landing); the stale 660/834 inventory path counts (this research measured the content delta: 2487 + 13 + 141).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix verify` log contains 7 totals lines (5 companions + phase41 + main) | Verified Ground Truth F19 | The gate's "number of totals lines" check would hard-fail on the first real run; measure once and pin |
| A2 | Playwright 1.60.0 needs a Chromium that `npx playwright install chromium` can fetch; revisions chromium-1200..1243 exist locally but the matching revision was not checked | Standard Stack | `browser-proof` could fail on a missing browser; resolve in the first `--all` attempt |
| A3 | Android Gradle test run completes offline from `~/.gradle` caches (a `gradlew --version` succeeded; the `test` task was not run) | Environment Availability | May need network for dependency download |
| A4 | Changing `lib/crosswake/planning/first_adopter_context.ex` (a published library file) with a `fix:` commit causes release-please to propose a version bump on `main` after the merge | Open Question Q2 | If wrong, no release PR; if right, an extra release PR appears after Phase 192 (not harmful, but plan for it) |
| A5 | `npm@10.9.2` from the public registry is the same package Node 22.14.0 bundles | Package Legitimacy Audit | Low; the install only goes to a scratch prefix |
| A6 | Pre-existing red state of `script/check_ci_leaf_manifest.py --self-test` and `check_aggregator_result_semantics.py --self-test` (exit 2 here) is an invocation issue (`-I`), not a repo defect | Open Question Q3 | Unverified; do not rely on them |

## Open Questions

1. **Add carry-sensitive CI-only commands to the Phase 191 gate? (recommend yes, as evidence, not a new suite definition)**
   - What we know: D-10 limits "the full local suite" to `--all` plus the example-host `mix test`. In CI, `mix crosswake.adoption_context.scan` (red, Pitfall 5), `node --test test/js/*.mjs` (red after carry: Pitfall 6), `mix crosswake.docs.sync --check` (green), `mix closeout.verify` (green), `elixir script/check_absence_is_not_success.exs` (green, 253/253), `elixir script/check_release_workflow_integrity.exs` (green, 98 of 98 after the resolver), `elixir script/inventory_collection_assertions.exs --check` (green) are separate merge-blocking steps. Each runs in seconds.
   - What's unclear: whether the lead wants D-10 widened.
   - Recommendation: run them in the integration clone and record pass/fail (exit codes via files) in the suite evidence as "carry-sensitive CI-only commands"; D-10's definition and the nine-stage gate stay unchanged. Note the JS suite additionally needs `npm ci --prefix examples/phoenix_host`; three of its tests (`repository mode owns first-attempt server`, `ordinary local mode preserves zero retries`, `generic CI mode remains distinct`) fail only when `@playwright/test` is not installed.
2. **How to clear `routing.unclassified_path` (Pitfall 5).**
   - Option A (measured): add 12 extensions to `@scannable_extensions` (+ a classification test). Pro: the raw evidence is now scanned (0 hits). Con: a `lib/` change.
   - Option B: an explicit exclusion for `.planning/**/evidence/**` raw-capture patterns (like the existing top-level `evidence/` and `artifacts/raw/` exclusions). Pro: smaller content surface scanned. Con: skips content the project says it treats as sensitive.
   - Recommendation: Option A for the 5 iOS extensions in all cases; for the planning-evidence extensions prefer A as well (they are in the pushed history regardless, so scanning them is strictly safer).
3. **D-02 "every commit green" (Pitfall 10).** Recommend recording the checkpoint set (post-fixes, post-resolver, final HEAD) and, for carry commits 1-4, running only the targeted subset with the one known red test named. Ask the lead to confirm D-02's wording is satisfied this way.
4. **Drop `config.json`/`state.json` (workstream level) from the carry.** This amends D-07 item 5 (it names "both config.json files" and "state.json"). `.planning/config.json` (the root one) is already tracked on main and should still be carried as modified. Recommend adding the two workstream files to the exclusion list with reason "runtime authority files pinned untracked by the Phase 167 validator".
5. **Edit PROJECT.md heading and REQUIREMENTS.md header in the recovery working tree (plain files) before the cut** so `milestone_transition_reset_test` passes (Pitfall 4). Lead decision: that is a content edit to records that D-08 says land verbatim; recommend treating it as part of the "records at the cut", noted in the manifest.
6. **The three `$NN` plan files (Pitfall 7).** Recommend a recorded transform (same machinery and manifest fields as the `<home>` transform) over a scanner change.
7. **D-14 for the Swift G3 gate.** With the export present the G3 gate test and control already pass; there is nothing to invert. Recommend: leave the G3 tests unchanged, keep the two named skips when no export is configured, and add the export-enabled run (`PHASE180_EXPORT_DIR`) to the evidence so the skips are justified by an observed pass. If the lead wants the gate to assert the declared-command grant, change its manifest to `hostCommands: [command: "1.0.0"]` and assert `session.capabilities[command] == "1.0.0"` (that duplicates the control).
8. **Bucket for items D-07 does not name:** `milestones/v22.0-phases` `M` files (2), `history/workflow-reset-*` (6), the 5 committed `.planning/debug` files. Recommend commit 1 (v23.0).
9. **Extend the home-path transform** to `/private/var/**` and `/var/folders/**` per-user temp paths (8 files) and decide how to handle the 8 files with the username word outside a home path (triage list vs `<user>` placeholder).
10. **Is `192-*`/`193-*` empty-folder presence relevant?** They are untracked empties; the table must not fail on them, and `STATE`/`ROADMAP` already describe those phases.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git | everything | yes | 2.41.0 | none needed |
| gitleaks | D-18 | yes | 8.30.1 | add trufflehog only on a missed planted control |
| asdf Node 22.14.0 | stage manifest | yes (selected by main's `.tool-versions` once inside the clone) | v22.14.0 | none |
| npm 10.9.2 | `browser-proof` regex | no (global is 11.1.0) | 11.1.0 | private prefix under `<tmp>` prepended to `PATH` (verified: prints 10.9.2) |
| Java 17 | `android-package-proof` | yes, not on `PATH` | 17.0.19 at the Homebrew `openjdk@17` prefix | prepend its `bin` to `PATH` (verified `java -version`, `gradlew --version` = Gradle 8.7) |
| Swift / Xcode | `ios-package-proof` | yes | 6.3.3 / 26.6 | none; `swift test` ran in about 18 s |
| Playwright browsers | `browser-proof` | partially (several Chromium revisions cached; match to 1.60.0 not checked) | 1.60.0 in lockfile | `npx playwright install chromium` after `npm ci` |
| Port 4700 free (Playwright web server) and 4790 | `browser-proof` / twin | not checked | n/a | check before `--all` |
| Network (hex.pm, npm, Maven/Gradle, GitHub) | clones, `mix deps.get` x7, `npm ci`, Gradle | yes (GitHub reachable: `ls-remote` worked; npm registry reachable: install worked) | n/a | none; fail closed |
| `C.UTF-8` locale | D-10/D-12 | yes (`locale -a`; also the shell default) | n/a | `en_US.UTF-8` |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** npm 10.9.2 (private prefix), Java 17 (PATH prepend), Playwright browser match.

Time budget (measured): root suite about 345 s; example-host suite about 8 s after compile; Swift about 18 s; the rest (companions `deps.get` + 5 test lanes, Gradle, Playwright, `mix verify`) unmeasured - run `--all` in the background with a generous timeout and one retry-free attempt per fix, never a foreground call over 10 minutes.

## Validation Architecture

> `workflow.nyquist_validation` was not read as `false`; treat as enabled. All commands run from the integration clone root unless stated, with `LC_ALL=C.UTF-8`, exit codes captured to files (never through pipes).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5), `node --test`, XCTest (`swift test`), shell self-tests with labelled controls |
| Config file | `test/test_helper.exs`, `mix.exs` (alias `verify`), `script/repository_verification_stages.json` |
| Quick run command | `mix test test/crosswake/planning test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs test/crosswake/proof/phase17*` and `elixir script/check_release_workflow_integrity.exs` |
| Full suite command | `CROSSWAKE_REPOSITORY_RUN_ROOT=<tmp>/crosswake-repository-verify.<id> CROSSWAKE_REPOSITORY_CAPTURE_ROOT=<tmp> script/verify_repository.sh --all` (with the `PATH` shims) then `(cd examples/phoenix_host && mix test)` |

### Phase Requirements to Test Map
| Req / criterion | Behavior | Test type | Automated command | File exists? |
|-----------------|----------|-----------|-------------------|--------------|
| LAND-01 / SC1 | Branch starts at current `main`; candidate commits preserved; FIX commits and planning present | git checks | `merge-base --is-ancestor <main-sha> <branch>`; `rev-list --count <main-sha>..<candidate-sha>` = 94; `rev-list --first-parent --count` equals total; each candidate SHA reachable (`merge-base --is-ancestor 2faf15a2 HEAD`); `rev-list --merges <main>..<candidate>` = 0; carry equality via `carry-191.sh --verify` | Wave 0 (new) |
| LAND-01 / SC1 | Carry complete, exact, no overlap with exclusions | manifest vs `git diff --raw --no-renames main..HEAD -- .planning` | `carry-191.sh --verify` + `selftest-carry-191.sh` (dropped file, flipped byte, extra file, mode change, empty manifest) | Wave 0 (new) |
| LAND-01 / SC2 | Privacy scan of `main..HEAD` clean, counts non-zero, bound to HEAD | scan | `scan-191.sh --range <main-sha>..HEAD` exit 0; `selftest-scan-191.sh` all controls "as expected"; gitleaks exit 0 and findings 0; evidence records HEAD and main SHAs | Wave 0 (new) |
| LAND-02 / SC3 | `--all` nine PASS records | stage run | `suite-gate-191.sh all` parses `logs/<stage>.log` `status=0` for nine records | Wave 0 (new) |
| LAND-02 / SC3 | Root tests 0 failures, 0 invalid, count >= floor | ExUnit | the totals lines from `logs/root-proof.log`; floor from F12 (2637) plus the tests added by D-17a, measured by a second command (`mix test --trace` count or the previous run) | Wave 0 (new) |
| LAND-02 / SC3 | G1 root gate | ExUnit | `mix test test/crosswake/proof/phase180_twin_feasibility_test.exs` | exists (edit) |
| LAND-02 / SC3 | G2/G6 example host | ExUnit | `(cd examples/phoenix_host && mix test)` -> `167+ tests, 0 failures` | exists (edit) |
| LAND-02 / SC3 | G4 Swift + named G3 skips | XCTest | `(cd packages/crosswake-shell-core-ios && swift test)` -> 0 failures, skipped names = the two G3 tests; plus the export run | exists (edit) |
| LAND-02 / D-12 | Ledger JSON decodes under C locale | ExUnit + shell | `LC_ALL=C elixir script/inventory_collection_assertions.exs --check` exit 0 (negative control) and Phase170 tests under UTF-8 | edit |
| LAND-02 / D-15 | Formatting | mix | `mix format --check-formatted` exit 0 (stage `format-proof`) | n/a |
| LAND-02 / D-16 | Test-file pin | guard + two counts | `elixir script/check_absence_is_not_success.exs` exit 0; `git ls-files test \| grep -c '\.exs$'` equals `find test -name '*.exs' \| wc -l` equals the pin (253) | exists |
| LAND-02 | No silent exclusions | tag audit | `test/test_helper.exs` tags only the closed set; evidence names each tag, its reason, where it runs instead; swift skips by name | Wave 0 (new, evidence) |
| LAND-02 | CI-parity extras (Open Question Q1) | commands | `mix crosswake.adoption_context.scan`; `mix crosswake.docs.sync --check`; `mix closeout.verify`; `node --test test/js/*.mjs` (after `npm ci`); `elixir script/check_release_workflow_integrity.exs`; `elixir script/inventory_collection_assertions.exs --check` | exist |
| SC4 | Built in a separate durable clone; recovery shows no git change | digest equality | `recovery-snap-191.sh` before == after; clone path is not under the recovery checkout or `<tmp>`; clone HEAD == recorded HEAD | Wave 0 (new) |
| Forward constraint (D-03) | Merge-commit-only recorded for 192 | doc check | grep the 191 handoff for the constraint | n/a |

### Sampling Rate
- **Per task commit:** the quick command plus `mix format --check-formatted` and `mix compile --warnings-as-errors`.
- **Per wave merge:** the full root suite (`mix test`, about 6 minutes) at the code-fix, resolver and final-carry checkpoints.
- **Phase gate:** `--all` nine PASS, example-host suite, Swift (with and without export), CI-parity extras, pin recount, privacy scan bound to HEAD, recovery before/after equal.

### Wave 0 Gaps
- [ ] `scripts/git-pinned-191.sh`, `locate-191.sh`, `ensure-clone-191.sh`, `recovery-snap-191.sh` and a self-test for each (missing folder, tampered env file mode, HEAD mismatch).
- [ ] `scripts/carry-191.sh` + self-test (five negative controls from D-09, plus: unmatched path fails hard, symlink refused, transform records both hashes, empty-dir tolerance).
- [ ] `scripts/suite-gate-191.sh` + self-test (MIN missing/zero, totals line count wrong, excluded total wrong, only 8 PASS records, exit codes via files, dirty tree, HEAD mismatch).
- [ ] `scripts/scan-191.sh` + `selftest-scan-191.sh` (planted control per class and position per D-19; clean control with non-zero counts; zero-term and zero-commit scope errors exit 2).
- [ ] Failing tests first for each code fix (red evidence file per fix, as 190 did): WR-05 table, WR-01 clauses and WR-06 wiring, WR-03 positive control, `$NN`/extension classification cases, resolver absent-path control.
- [ ] Framework install: none.

## Security Domain

Applicable because the phase handles repository history that will become public and contains a secret/PII scan.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no auth code changes) | - |
| V3 Session Management | no | - |
| V4 Access Control | partly | Mode-700 owner-checked scratch folder for the env file (WR-11); denylist file mode 0600 outside the repo and `<tmp>` |
| V5 Input Validation | yes | Manifest path validation (relative, no `..`, regular files only, symlinks refused); table fails hard on unmatched paths; strict totals parsing |
| V6 Cryptography | yes (integrity only) | `shasum -a 256` and git blob ids for manifest/evidence digests; never hand-roll |
| V8 Data Protection | yes | Evidence stores counts, digests and fingerprints only; no raw logs, no paths, no denylist terms, no secrets |
| V14 Configuration | yes | Pinned git env (scrubbed `GIT_*`, no global config, hooks off); gitleaks run with `--ignore-gitleaks-allow`, no repo-controlled config |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Planted env/config file in a shared temp folder is sourced by scripts | Elevation | Regenerate every run; verify owner and mode 700 before use (WR-11) |
| Hostile git config or env changes status/diff output | Tampering | Pinned helper (`GIT_CONFIG_GLOBAL=/dev/null`, `core.fsmonitor=false`, `core.filemode=true`, scrubbed `GIT_*`) |
| Scan reports clean on an empty scope | Repudiation | Non-zero counts required; zero terms/commits/blobs exit 2; planted control per class |
| Secret or identity leaks into evidence or logs | Information disclosure | Redacted gitleaks report kept in scratch; evidence holds counts and fingerprints; no term ever written |
| Rewriting candidate history to remove a hit | Tampering | D-20 ladder: stop and ask for history hits; never force-push, never squash |
| `--all` run mutates the clone | Tampering | Clean-tree precondition and post-run snapshot are built into the orchestrator; the gate also checks `status --untracked-files=all` and HEAD afterwards |
| Push before scan | Information disclosure | D-22 binding: scan evidence names HEAD and `main` SHAs; Phase 192 refuses a mismatch |

## Plan / Wave decomposition risks

**Strictly sequential (each needs the previous result):**
1. `ensure-clone` (fetch GitHub `main`, ancestry gate, fetch candidate, ff-only) -> 2. code-fix commits (a commit order exists but fixes can be *authored* in parallel in separate scratch worktrees; they land serially, and the ledger regeneration must come after the Phase 180 root test edit) -> 3. resolver commit -> 4. carry commits (cut manifest first; recovery plain-file edits for Pitfall 4 must be done before the cut) -> 5. suite gate and CI-parity extras -> 6. pin recount, SEED-024, dispositions, sync commit -> 7. privacy scan on the final HEAD -> 8. recovery after-snapshot and handoff.

**Parallelizable (no dependency on the clone):** all five tools and their self-tests (Wave 0): `git-pinned/locate/ensure-clone`, `recovery-snap`, `carry`, `suite-gate`, `scan`; drafting SEED-024 and the `190-REVIEW-DISPOSITION.md` row edits; the before-snapshot of the recovery checkout; preparing the private npm prefix and the JDK/Playwright environment; the Phase 180 inversion tests (each can be developed against the scratch copy and replayed as commits).

**Risks to schedule explicitly:**
- The suite is long (root about 6 minutes, `--all` longer): do not interleave edits during a run; the orchestrator requires a clean tree and will fail otherwise.
- Any new commit after the scan voids it (D-22): all records written after the cut go into the single sync commit, then the scan runs.
- The Phase 180 root-test edit changes line numbers: regenerate the ledger *in the same commit* and run `--check`.
- Each carry commit's measurements should be recorded as a commit-level table (files, bytes, digest) so the evidence shows what moved.
- Transform ordering: apply the redaction/`$NN` transforms when building the staged tree, before `git add`, and record source and landed hashes (the landed hash is what `git diff --raw` will show).
- SEED-024 and 191's own SUMMARY/VERIFICATION are written in the recovery checkout as plain files and land only through the sync commit.

## Sources

### Primary (HIGH confidence) - read or executed this session
- `script/verify_repository.sh`, `script/verify_repository.mjs`, `script/repository_verification_stages.json`, `mix.exs`, `test/test_helper.exs` in `<durable-candidate>` (read)
- `test/support/phase_evidence_path.ex`, the seven D-06 files, `test/crosswake/proof/phase180_twin_feasibility_test.exs`, example-host and Swift Phase 180 tests, `ActivationCoordinator.swift` (read)
- `lib/crosswake/planning/first_adopter_context.ex`, `lib/crosswake/shell/ios_host_origin_mode.ex`, `lib/crosswake/proof_lane/physical_iphone_preflight.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `script/inventory_collection_assertions.exs`, `script/check_absence_is_not_success.exs`, `script/check_phase167_pr_dispositions.py` (read)
- Phase 190 scripts, evidence and review files; 189 inventory and delta; `180-GATE.json` (read)
- Commands run: `git` (read-only plumbing against `<durable-candidate>` and the recovery `.git`), full root suite in `<scratch>` (before and after the prototype fixes), `mix test`/`swift test` in the example host and package, `gitleaks` on `<scratch>` and a temp repo, `node --test`, `mix crosswake.*` tasks, `npm install` into a scratch prefix.

### Secondary (MEDIUM confidence)
- gitleaks `git --help` for flags (`--log-opts`, `--redact`, `--report-format`, `--ignore-gitleaks-allow`, `--exit-code`)

### Tertiary (LOW confidence)
- None used for decisions. GitHub Docs / gitleaks README / Erlang Unicode guide cited in CONTEXT.md were not re-fetched; the locale behavior was reproduced locally instead.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - every version read from tool output.
- Architecture / carry design: HIGH for the delta and exclusions (content hashed); MEDIUM for the commit bucket assignments marked as recommendations.
- Pitfalls: HIGH - each reproduced in a prototype; the prototype suite went from 146 failures to the 1 expected (G1) with the listed fixes.

**Prototype boundary:** the dry run omitted the redaction transform, the `.planning/` exclusions' manifest, the WR-05/01/06/03 fixes, and the Phase 180 inversions; it did include the resolver-class test/script fixes, the two record edits and the `$NN` transform, so the measured end state "2637 tests, 1 failure (G1)" applies to the resolver+carry portion only.

**Research date:** 2026-10-19
**Valid until:** until `main` moves off `d0dbdf7`, the recovery `.planning/` tree changes, or the candidate changes (re-run the delta hash and the ancestry gate at cut time; D-01 already requires a re-check).

