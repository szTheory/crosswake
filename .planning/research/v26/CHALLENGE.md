# v26.0 research: adversarial challenge

Reviewer pass over BRIEF, STACK, FEATURES, ARCHITECTURE, PITFALLS. Candidate = `/private/tmp/crosswake-phase180-impl` at `50fcd57` (read-only; `git status --porcelain` empty before and after). Experiments ran in scratch repos only (git 2.41.0). "Scratch" below means a throwaway repo under the session scratchpad. Nothing was staged, committed or run in the twin/Simulator.

## Confirmed

C1. `ls-files -v` tags (scratch, git 2.41.0). After `update-index --assume-unchanged a.txt` and `--skip-worktree b.txt`, plus an edit to each, plain `git status --porcelain` printed nothing. `git ls-files -v | grep -v '^H'` printed `h a.txt` and `S b.txt`. `ls-files -v -z` with a non-`H` count gave 2. Lowercase `h` = assume-unchanged, `S` = skip-worktree. STACK/ARCH are right.

C2. `core.ignoreStat` is caught by the non-`H` count when it is set at checkout. `git clone -c core.ignoreStat=true` produced `h` on every entry. An edit to `d.txt` was then invisible to `git status`, and `-c core.ignoreStat=false` did NOT bring it back. So the tag count (not a `-c` override) is the detector. A repo that sets ignoreStat after the index was written, then `update-index --refresh`, still showed the edit (`M c.txt`), so that ordering is not a hole.

C3. `-c core.filemode=true` reveals mode-only changes when repo config says `false`. Plain status was empty; with the flag it printed ` M run.sh`. It reveals nothing about `h`/`S` files (independent fixes, as STACK says).

C4. `GIT_CONFIG_GLOBAL=/dev/null` works on 2.41.0. A global `core.excludesFile` pointing at a file containing `new*.txt` hid the untracked `newfile.txt` from `status --porcelain -uall`. With the pin, `?? newfile.txt` appeared. The `GIT_CONFIG_GLOBAL` minimum version (2.32) is therefore not an issue on this host; it stays an issue on older CI/dev gits, so the test that proves the pin should stay.

C5. The existing `-c core.excludesFile=/dev/null` ALREADY closes the global-excludes hole on its own. Scratch: with `excludesFile` in `~/.gitconfig`, the flag alone showed `?? newfile.txt`. It also overrides the default XDG ignore file (`$XDG_CONFIG_HOME/git/ignore`) when `excludesFile` is unset. The `GIT_CONFIG_GLOBAL` pin is for filemode/other keys, not for excludes. Neither document says this plainly; PITFALLS row at line 60 implies the pin is needed for excludes.

C6. `.git/info/exclude` cannot be switched off by `-c`, as stated. `status --porcelain -uall` hid `hid1.txt`; `--ignored` showed `!! hid1.txt`. The probe's existing active-rule count is the right defence.

C7. `--ignore-submodules=none` beats both `submodule.<n>.ignore=all` in config and `ignore=all` in `.gitmodules` (scratch: ` M sm` printed in both cases). No hole.

C8. SEED-018 for v25 is done. `elixir script/inventory_collection_assertions.exs --check` in the candidate: `OK: 243 classified collection-assertion site(s), ledger matches the live tree exactly`, exit 0.

C9. `script/check_absence_is_not_success.exs` is vacuous on an empty root. `elixir script/check_absence_is_not_success.exs --root <nonexistent scratch dir>` printed both `OK` lines and exited 0. Scopes are bare `Path.wildcard` (lines 78-83, 178-186); `run/1` (line 53) treats `[]` as OK. The only references to it outside itself are a test file and comments in the inventory script, so the checker is not run by CI as a script (only through that test).

C10. SEED-014 status. C is open: `crosswake.proof_lane.verify_navigation_shell.ex:101-115` hardcodes `commit_ref: "git-000...0"`, `template_version: "161"`, `status: :passed`. E is open: `doctor.ex:380-392` builds `unmanaged_routes` with no details map. F is open: `doctor.ex:469-472` filters to routes with a cache or island contract before the `Enum.all?`; the `:local_first -> route.island_contract` branch can never see a route lacking one.

C11. Other FEATURES file:line claims spot-checked and right: `twin_runtime.ex:178-190` (`stop_children` returns `:ok` for a dead registry); `doctor.ex:2477-2478` (`else _ -> []`); `ActivationCoordinator.swift:274-282` (legacy arm drops unregistered keys silently and grants any registered `host.*` key at any version).

C12. The loopback harness is an orphan: `grep -rIl verify_loopback_origin_simulator` (excluding .git/_build/deps) returns no file. Its hash check is vacuous as described: `verify_loopback_origin_simulator.sh:251-261` hashes four files then overwrites a fifth.

## Refuted/corrected

R1. FEATURES/ARCH/PITFALLS assume a "preflight-only rehearsal" exists. It does not. `mix crosswake.proof_lane.verify_twin ios` accepts only `--candidate`, `--run_root`, `--identity` (`verify_twin.ex:26`). Any accepted run root ends with `receipt.json` even on a preflight block: `blocked_receipt/2` at `verify_twin.ex:144-185` writes it, and `TwinRuntime.not_reused/1` (`twin_runtime.ex:320-330`) keys consumption on `receipt.json` in the root. So a "rehearsal" today is either a full twin run on a throwaway root or new code. PITFALLS Pitfall 5 and ARCH phase 189 must say which.

R2. PITFALLS Pitfall 5 go/no-go says the check is "root `twin-05` does not exist". Wrong direction. `run_root/1` (`twin_runtime.ex:299-312`) REQUIRES an existing directory with mode `0700` and returns `:prerequisite_missing` otherwise. The name `twin-05` is a convention; nothing in code enforces it. The correct pre-run state is: directory exists, mode 0700, no `receipt.json`, outside the candidate. "Rehearsal entry point refuses that name" (PITFALLS line 78) tests nothing real; the real separation is a different directory.

R3. FEATURES headline 1 says remaining vacuity is "NOT in `assert Enum.all?` tests". True for v25 ledger rows, but STACK §2.2 still names `twin_receipt_test.exs:289` as a real vacuity (a loop over a possibly empty list with no pre-floor). FEATURES never lists it, so the plan gap is: it is in STACK integration order step 3 but absent from FEATURES' phase list. Add it to the guards phase.

R4. ARCH "Anti-Pattern 3" and STACK say do-not-add the compile-time `Policy.Route` rule for F. FEATURES recommends it ("Prefer the compile-time rule"). The doctor-time option is correct for this milestone. Evidence: `route.ex:115-135` today only enforces contract-implies-offline, and the 31 `:local_first` sites cited in STACK would change behaviour in a public DSL. FEATURES row DOC-F is the outlier.

R5. FEATURES "Twin-04 unaffected (3257 entries all `H`)" and the idea that tag counting is enough: the tag count is NOT sufficient (see Missed holes M1). It catches `h`/`S`, not `core.trustctime=false` or `core.checkStat=minimal`.

R6. PITFALLS line 61 treats in-tree `.gitignore`d files as an open design choice. Confirmed they are invisible (scratch: `ign1.txt` matched by committed `.gitignore` did not appear in `status -uall`). It is a real, silent path whenever the build consumes an ignored file (e.g. a generated Swift file). The decision should be recorded, not left as "decide".

## Missed holes

M1. Stat-trust config hides same-size/same-mtime edits, and neither tag counting nor filemode catches it. Scratch (touch -t to an old mtime, replace 4 bytes with 4 bytes, restore mtime): baseline repo reports ` M a.txt`; with repo-local `core.trustctime=false` OR `core.checkStat=minimal`, `git --no-optional-locks status --porcelain` printed nothing and `ls-files -v` showed `H a.txt`. Passing `-c core.trustctime=true -c core.checkStat=default` revealed it again. Silent, repo-local, unfixed by any proposed item.

M2. One mechanism closes M1, assume-unchanged, skip-worktree, ignoreStat and checkStat together: probe with a throwaway index. Scratch: a repo with `a.txt` assume-unchanged+edited, `b.txt` skip-worktree+edited, `core.ignoreStat=true`, and `core.filemode=false` plus a chmod. Plain status showed only ` M c.txt`. `GIT_INDEX_FILE=<tmp outside repo> git read-tree HEAD` then `GIT_INDEX_FILE=<tmp> git status --porcelain` showed ` M a.txt`, ` M b.txt`, ` M c.txt`; adding `-c core.filemode=true` also showed ` M run.sh`. The checkStat-minimal repo likewise showed ` M a.txt`. A fresh index has no stat cache or flag bits, so git must re-hash everything. Cost: re-hash ~3.3k files. Recommend this as the primary probe, keep the `ls-files -v` non-`H` count as a cheap second signal (and for the clearer message), pin `core.filemode=true`, `core.sparseCheckout=false`. Put the temp index outside the candidate (preserves read-only). Not tested: `core.sparseCheckout=true` combined with `read-tree` (set the `-c` pin and add a test).

M3. Doctor `host_commands_stale` has a second silent branch besides M-03. `doctor.ex:2453-2475`: if the generated fixture is readable but a router route is MISSING from `generated`, `Map.has_key?(generated, route_id)` is false, so no finding. A route added to the router and not regenerated reads as fresh. (Not checked whether another doctor check covers the whole-route case; FEATURES SEAM-M03 only mentions the unreadable file.)

M4. Twin-05 can be burned by an ordinary preflight block, not just a premature start. `blocked_receipt` (see R1) writes `receipt.json` on `source_dirty`, so any dirty/changed state at run time consumes the root. The go/no-go must run the same probe immediately before the run, with the same env, and must also check that the origin port (4790, from the prepared record) is free (`acquire_origin` in `prepare/1`).

M5. Hand-built `IOSHostConfig` (GEN-W02) and the legacy arm (M-02) are rated by FEATURES as "S/yes silent" but nothing ties them to the twin-attested path; fine. But `observe_identities` re-probing git a second time (183 IN-01) is a TOCTOU between two git calls inside the same preflight; FEATURES lists IN-01 as "bundle" without calling it silent. It can let HEAD/tree and the cleanliness answer come from different moments. Keep it with PROBE.

M6. `core.attributesFile` / `.git/info/attributes` / clean filters are a theoretical content-normalising vector. I could NOT reproduce a hidden edit with a clean filter (scratch: status still printed ` M a.txt` after tampering, with and without the filter overridden), so it is not a demonstrated hole. The fresh-index probe (M2) still applies filters, so it would not close it if it exists. Record as unreproduced, do not add work.

M7. Residual that no stat-based or index-based probe closes: a deliberate edit-and-revert during the run (already DEF-SNAP / fidelity limit 5). With M2 in place the remaining gap is only that. Say so in the run record rather than leave "verifies source for the whole duration" ambiguous.

## Scope adjustments

S1. Keep as table stakes: PROBE-01/02/03 (but implement via M2 plus tags, not tags alone), SEAM-M02/M03(+M3 above)/M04, GUARD-01, GUARD-02, `twin_receipt_test.exs:289` floor, DOC-F (doctor-time), PROOF-C, 183 IN-01/03/04.

S2. Padding (fails closed or cosmetic; defer without loss): SEAM-L05 (loud crash), SEAM-L06 (wrong text, still a denial), GEN-W06 (mislabel), PROBE-04 as a standalone item (message only; ride along since the file is touched, but do not give it a requirement), DEBT-ROUTEID, SEAM-L04 (becomes a runtime denial, not silent), SEAM-L01 (accepts something wider, tiny). These can stay "rides along only if the file is already open".

S3. Deferrals that DO hide something silent and need a visible record, not just a trigger: DEBT-IDENT (twin attests a hardcoded bundle id instead of the generated identity, `twin_journey.ex:20`) and DEF-SNAP. Both are listed with triggers; add a one-line limit to the twin-05 receipt/run record text so a pass is not read as stronger than it is. DEF-L02 (one bad key fails the whole manifest) fails closed: deferral is fine.

S4. Phase count: 6 phases (ARCH) for mostly independent S-size fixes is heavy. FEATURES' 5 is closer. Merge ARCH 186 (harness+preflight) into the guards phase or drop the harness (see Conflict C3). The twin phase must stay alone and last.

S5. DEF-A (haptics, CW-REQ-A): agree with defer; the reopen condition text in the seed is about a proven release pipeline, and the brief itself notes REL-10 breached. Not silent.

## Conflict resolutions

K1. Phase layout (FEATURES 184-188 vs ARCH 184-189): use FEATURES' five, with the twin run as its own last phase; ARCH's separate "reseal" step is a task inside that last phase.

K2. DOC-F: doctor-time filter change plus the three-part test (STACK/ARCH); no compile-time rule in v26 (FEATURES loses).

K3. Harness (FEATURES "keep and wire as documented evidence" vs ARCH "wire into `phase18-ios-proof` or delete"): `phase18-ios-proof` is a required leaf in `script/check_ci_leaf_manifest.py` (line 46), so wiring a Simulator script into it is a CI change with failure modes. Recommend: fix WR-03/04/05 (all S, all silent), document it as a manual advisory in `guides/native_shell.md`, do not wire to CI; if the owner will not run it, delete it instead. Do not leave it unreferenced.

K4. SEED-018 work (ARCH 188: "SEED-018 rule in `check_absence_is_not_success.exs`, advisory then blocking" vs FEATURES/STACK: do not add VACG-01 this milestone): do not add VACG-01. The ledger is already 0 `needs-fix`; the milestone only needs the cardinality floor in the one checker plus the `twin_receipt_test.exs:289` pre-loop floor.

K5. Ordering of the guard (STACK integration order puts the checker floor early; ARCH puts guards last "after the fixes they would flag"): the floor only guards the checker's own scope and flags nothing in v25, so it can land any time before the freeze. Use STACK's order; keep it before the freeze commit.

K6. Rehearsal (PITFALLS) vs real CLI: replace "preflight-only rehearsal" with (a) a new read-only function that runs the same preflight checks with no receipt (added in the probe phase, so it lands before the freeze) and (b) a scripted go/no-go that calls it. No throwaway full twin run.

## Twin-05 protocol (answers question 4)

Safe only if all of this holds. Freeze first: candidate HEAD and tree, the prepared record (`expected_head`, `expected_tree`, `origin`, `resource_digests`, `fixture_digests`), `180-SEAM-HANDOFF.json` `repaired_head`, `182-FINAL-HEAD.json`, the `--identity` argument and the `verify_twin` task source itself. Any commit after the freeze invalidates all of it. Go/no-go (script, not memory): record head equals `git rev-parse HEAD` and tree equals `HEAD^{tree}`; M2 probe reports zero; the new preflight function passes; run-root dir exists, mode 0700, outside the candidate, no `receipt.json`; port free. Then exactly one `verify_twin ios` invocation. A blocked or failed result is reported as such, and a new root/record (twin-06) is a new decision. A rehearsal can consume the root only if it is pointed at it; use a different directory for any dry check, and never a full run.
