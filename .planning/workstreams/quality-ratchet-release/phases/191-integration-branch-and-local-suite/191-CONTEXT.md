# Phase 191: Integration branch and local suite - Context

**Gathered:** 2026-10-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Build one integration branch, cut from current GitHub `main`, in a separate durable clone (never the recovery checkout). It holds the candidate's 90 commits and the 4 FIX commits with history preserved, a small number of new fix commits needed so the branch is green, and the v23–v27 planning records. Its privacy scan is clean, and it passes the full local suite with zero failures, with every exclusion and skip named and given a reason. Requirements: LAND-01 and LAND-02. Pushing, opening the PR and the merge belong to Phase 192. Removing anything belongs to Phase 193.

Facts measured during discussion (read-only):
- `main` is still `d0dbdf7` and is an ancestor of the candidate. The candidate is 94 commits ahead (90 plus 4 FIX at `2faf15a2` in `<durable-candidate>`) and 0 behind, so the branch fast-forwards with no candidate commit rewritten.
- Main has one required check, "Crosswake CI", which aggregates 47 jobs. Those jobs run the root suite (including the Phase 180 G1 gate test), `swift test` (G4) and whole-project `mix format --check-formatted`. Any of these left red blocks Phase 192.
- The candidate touches no `.planning/` file. The recovery HEAD `d0f3e2f1` is 249 commits ahead of main and 91 behind (row R-BR-047, unclassified). 149 of those commits change only planning files, including the v23.0 archive move and the committed v24 start records. The R-PL "to land" rows list only uncommitted paths, so they miss these, and the inventory's 660-path count is now about 834 and out of date.
- Main already publishes the local username in about 360 planning files. Every author and committer email on main is a noreply address.

</domain>

<decisions>
## Implementation Decisions

The user chose all four areas and asked for multi-lens fan-out research with an adversarial pass, then one coherent set of recommendations to be followed automatically. Every decision below is that synthesis. Where two research tracks disagreed, the reconciliation is stated.

### Branch layout and commit order
- **D-01:** Make a fresh durable clone (outside the temp folder) from GitHub `main`, re-fetching `main` first. Bring in `refs/heads/candidate` from `<durable-candidate>`, then fast-forward the integration branch to it. Re-check before starting that `main` is still an ancestor; if `main` has moved, stop and replan rather than rebase. `<durable-candidate>` stays untouched as the Phase 190 record. Set the clone's repo-local `user.email` to the noreply address main already uses before any commit.
- **D-02:** The order is linear, and every commit keeps the suite green: `main` → 90 candidate commits → 4 FIX commits → new code-fix commits (D-10..D-16, one per fix, each with its test) → the planning resolver commit (D-06) → the planning carry commits (D-07) → an optional post-cut sync commit → the privacy scan (D-18), which runs last and is bound to the final HEAD.
- **D-03:** Phase 192 must merge with a merge commit, never squash or rebase-merge. Otherwise the preserved candidate history and the per-milestone carry split are lost. This is recorded here as a forward constraint for Phase 192. It is not acted on in 191. — **Reversibility:** one-way — a squash merge on the protected public `main` cannot be undone without a force push, which is forbidden.

### What the planning carry includes
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

### Known failures and the local suite
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

### Phase 190 review leftovers
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

### Privacy scan
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

### Recovery checkout stays frozen
- **D-23:** No git write in the recovery checkout. Planning records for 191 are written there only as plain files, as in Phases 189 and 190. Criterion 4 is proven by `recovery-snap-191` before and after (D-17b).

### Claude's Discretion
- Integration clone location and branch name (for example `land/v25-v27`), script names and layout in the 191 `scripts/` folder, and the exact path-to-milestone table rules.
- Whether the WR-01 and WR-06 fixes share one commit.
- Wording of the verdict notes and refusal reasons (plain language, no paths or sensitive values).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Governing rules
- `AGENTS.md` — Sensitive Data Rules, fail-closed rule, recovery-checkout freeze, plain-language handoff rule
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — v27 ordering rules; Phase 191 criteria
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — LAND-01, LAND-02 (and LAND-03/04 for the forward constraints)

### Inventory and backup (Phase 189)
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-CONTEXT.md` — D-01 (first off-machine copy after the scan), D-02 placeholders, D-05/06 classification, D-08 read-only rules, D-14/15
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-INVENTORY.md` — R-PL rows, R-BR-047
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-DECISIONS-NEEDED.md` — unclassified groups awaiting the user
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-EVIDENCE/dirty-paths.tsv` — per-path blob comparison

### Fixes and review (Phase 190)
- `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/190-CONTEXT.md` — D-01 successor-script pattern, D-05 pinned `g()`, D-09 pin recount, D-10 (superseded for landing by D-11 here)
- `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/190-REVIEW.md` and `190-REVIEW-DISPOSITION.md` — the 15 findings triaged in D-17
- `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/190-EVIDENCE/baseline-dispositions.md` — the failure list, corrected by D-12..D-14
- `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/` — 190 scripts (unchanged records; models for the 191 successors)

### Phase 180 gate record
- `.planning/workstreams/quality-ratchet-release/milestones/v25.0-phases/180-bounded-digital-twin-demonstration/180-GATE.json` (or the live path if not yet archived) — the refuted G1–G6 facts the inverted tests now assert

### Code touched
- `script/verify_repository.sh`, `script/repository_verification_stages.json`, `.github/workflows/crosswake-ci.yml` — suite definition and CI mapping
- `test/test_helper.exs` — exclusion tags and reasons
- `script/inventory_collection_assertions.exs`, `script/collection_assertion_ledger.json` — ledger fix (D-12, D-13)
- `script/check_absence_is_not_success.exs` — test-file pin (D-16)
- `script/phase_evidence_path.py`, `script/phase_evidence_path.sh` — resolver model (D-06)
- `lib/crosswake/planning/first_adopter_context.ex` — `CROSSWAKE_PRIVATE_ADOPTER_TERMS` convention (D-18)
- In `<durable-candidate>`: `lib/crosswake/proof_lane/{twin_runtime,provenance,git_pins,physical_iphone_preflight}.ex`, `lib/crosswake/shell/ios_host_origin_mode.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, `test/crosswake/guides/native_shell_upgrade_test.exs`

### External
- GitHub Docs, "Removing sensitive data from a repository" — rewrite limits (forks, cached SHAs, `refs/pull/*`); rotate first
- gitleaks README — feature-frozen status, `git` mode over `--log-opts`
- Erlang stdlib "Using Unicode in Erlang" — stdout encoding follows the locale (D-12)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Phase 190 pinned git helper `g()` and the Elixir funnel `@git_env`/`@git_pins` (`twin_producers.ex`, `git_pins.ex`): every successor script uses them.
- `script/phase_evidence_path.{py,sh}`: the live-or-archived resolver pattern to copy for D-06.
- `CROSSWAKE_PRIVATE_ADOPTER_TERMS` scanner convention: matches case-insensitively and never prints terms. Its test currently passes with nothing checked when the variable is unset, which is why D-18 requires at least one term.
- `script/verify_repository.sh --all`: nine stages already mapped to CI owners; preflight reports missing tools as BLOCKED.

### Established Patterns
- One-time phase tooling lives in the phase `scripts/` folder, not `script/` (190 D-01).
- Every check must fail on an empty scope and carry a negative control for each label (185, 190 D-03/D-04).
- Expected counts come from a separate measurement, never from the check's own glob (185 D-03).
- Placeholders only in records: `<recovery-checkout>`, `<durable-candidate>`, `<backup-root>`, `<tmp>`, `<home>`, `<denylist>`.

### Integration Points
- The integration clone feeds Phase 192's push. Scan evidence (HEAD-bound) is the push precondition.
- The carry manifest tool is re-run for the post-cut sync commit.

</code_context>

<specifics>
## Specific Ideas

- The user's standing preference: "another copy-paste is better than another dep". That is why D-06 copies the resolver per caller and D-18 uses a vendored scanner plus one already-installed static binary rather than a scanner framework.
- Research should prefer primary sources. The decisions above cite GitHub Docs, the gitleaks README, the Erlang unicode guide, ExUnit/Mix docs and the Git 2.29 release notes (`bisect --first-parent`).

</specifics>

<deferred>
## Deferred Ideas

- **SEED-024 "Phase 190 review residue":** contents and triggers in D-17c. Write it during Phase 191 execution.
- **Pre-existing home paths on main** (about 360 planning files): outside LAND-01's "the change" scope. A hygiene seed, in the SEED-012 lineage.
- **Example-host suite has no CI lane:** a fact for Phase 193's working-rules decision; CI is not changed in 191.
- **Recovery AGENTS.md working rules:** input to CLEAN-04 (Phase 193); drop the consumed Phase 175 standing authorization.
- **Optional:** the user's GitHub account setting "Block command line pushes that expose my email", as a server-side backstop. An account setting, not phase work.
- **The user's answers to 189-DECISIONS-NEEDED:** answered 2026-10-19 in `189-DECISIONS-ANSWERS.md` (the backup is the keep; Phase 193 removes source copies only; nothing lands as code; the planning half of R-BR-047 lands via D-04). Not needed for 191.

</deferred>

---

*Phase: 191-integration-branch-and-local-suite*
