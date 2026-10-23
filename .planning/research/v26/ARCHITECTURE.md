# Architecture Patterns: v26.0 Harden Before Trust

**Domain:** hardening of v25 proof and host code (twin source binding, host-command seam, loopback harness, doctor/proof-lane fidelity, absence guards)
**Researched:** 2026-10-15
**Evidence base:** candidate `/private/tmp/crosswake-phase180-impl` at `50fcd57` (clean tree, read-only), plus the recovery checkout's planning files. All `file:line` references below are candidate paths. Two behaviors were also reproduced in a throwaway git repo (see "Verified experiments").
**Overall confidence:** HIGH for the twin source-binding and doctor claims (read in code, reproduced), MEDIUM for the Swift seam fix and harness wiring (read, not executed; Swift was not built).

## Recommended Architecture

No new subsystem. Every item is a modification inside an existing seam, and every item must land before one final `twin-05` run. The shape is:

```
 fix layer (modify only)                      guard layer (new rules, after fixes)        seal layer
 ------------------------------------------   -----------------------------------------   ---------------------
 A. TwinProducers.probe/2 (WR-01/02)          G1. check_absence_is_not_success.exs        S. refresh handoffs
 B. grantHostCommands legacy arm (M-02)           + non-empty-collection rule (VACG-01)       (180-SEAM-HANDOFF,
 C. loopback harness + preflight (182)        G2. scope-cardinality: exact-count pins         182-FINAL-HEAD),
 D. Doctor phase_4_posture / details /            at the v25 derive-from-glob sites           new prepared record,
    provenance (SEED-014 C/E/F)                                                              ONE twin-05 run
```

Core principle for the roadmap: the twin run (`twin-05`) is the only step that is consumed. Any commit after `fix(183-03)` (`50fcd57`) invalidates the prepared record (D-16), so all code changes go first and the run goes last. The run proves the hardened commit; it must not be used to debug a fix.

### Component Boundaries (new vs modified, explicit)

| Component | Path (candidate) | Status | Change |
|-----------|------------------|--------|--------|
| Clean-tree probe `probe/2`, `clean_tree/2`, `dirty_count/2` | `lib/crosswake/proof_lane/twin_producers.ex:739-792` | MODIFIED | add `-c core.filemode=true` to the status argv; add a second `git ls-files -v -z` pass counting non-`H` tags as dirty |
| `freeze/3` | `twin_producers.ex:628-671` | UNCHANGED code, changed behavior | already calls `clean_tree/2` at `:636`; inherits the stronger probe |
| `checked_identities/3` | `twin_producers.ex:989-994` | UNCHANGED code, changed behavior | gate at `:990` inherits the probe |
| `observe_identities/2` | `twin_producers.ex:918-` | MODIFIED (IN-01) | calls `clean_tree(path)` with no `git_cmd` at `:934`; thread the injected `git_cmd` through so there is one probe configuration, not two |
| Receipt schema / joins / limits | `twin_receipt.ex:17,45-65,343` | UNCHANGED | see "Contract impacts" |
| Run-once record / run root | `twin_runtime.ex:59-72, 283-327` | MODIFIED only for IN-03 (`run_root(nil)` residue) | no protocol change |
| `grantHostCommands` legacy arm | `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift:274-281` | MODIFIED | record denials and apply version check; grant semantics for registered keys kept |
| Swift `HostCommandSeamTests` / `HostCommandWireTests` | `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/` | MODIFIED | the `legacy: true` world (`HostCommandSeamTests.swift:33`, `HostCommandWireTests.swift:24`) gets denial assertions |
| Loopback harness | `script/verify_loopback_origin_simulator.sh` (+ `script/loopback_origin_simulator/`) | MODIFIED, then WIRED (or removed) | currently referenced by nothing else in the tree |
| Physical preflight | `lib/crosswake/proof_lane/physical_iphone_preflight.ex:116-121` (`config/1`) | MODIFIED | add an origin-mode refusal alongside `Config.normalize` |
| Doctor `phase_4_posture/1` | `lib/crosswake/doctor/doctor.ex:466-` | MODIFIED | fix the filter hole at `:468-472`; coherence scoped to `:offline_island` |
| Doctor `unmanaged_routes` finding | `doctor.ex:374-392` | MODIFIED | pass structured `details` (the `check/6` call drops them) |
| `verify_navigation_shell` provenance | `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex:104-114` | MODIFIED | still hardcodes `commit_ref: "git-0000..."`, `crosswake_version: "0.1.0"`, `template_version: "161"`, `device_class: :unknown` |
| Absence scanner | `script/check_absence_is_not_success.exs` (`run/1`, `findings = mutation_controls ++ stale_citations`) | MODIFIED | add one rule; do not create a second scanner |
| Collection ledger / remediation | `script/collection_assertion_ledger.json`, `script/collection_assertion_remediation.json` | MODIFIED (sunset path) | lift detection core into the scanner per the ledger's own `sunset` text; then delete |
| New files | none required | NEW: none | the only new artifacts are tests and the new prepared record for twin-05 |

### Data Flow Changes

1. **Source binding.** `freeze/3` (before launch) and `checked_identities/3` (after the journey, in `TwinJourney.assemble`, `twin_journey.ex:711`) both call `clean_tree/2`. `observe_identities/2` calls it a third time (`:934`) bracketed by two `HEAD`/tree reads. The data flow does not change; the probe's definition of "dirty" widens. A run now blocks with the existing `:source_dirty` cause (`twin_receipt.ex` closed cause list, line ~40) when an index flag or mode-only change is present. No new cause atom is needed.
2. **Host-command grant.** Legacy arm (route has no `host_commands` key) now writes into the `denials` map it returned empty. That map already flows to `LiveViewSession.hostCommandDenials` (`ActivationCoordinator.swift:609`), so the denial reaches the bridge denial message with no new plumbing.
3. **Doctor.** Findings gain a `details` map; JSON consumers (`mix crosswake.doctor --format json`) see it. No change to exit semantics.
4. **Harness.** Output JSON gains truthful `outcome` when cleanup fails (WR-05); no consumer exists yet, so no compatibility concern.

## Question 1: Twin source binding

### Where the probe lives

In `Crosswake.ProofLane.TwinProducers`, private `probe/2` (`twin_producers.ex:759-784`), exposed through `clean_tree/2` (`:739`) and `dirty_count/2` (`:752`). Git runs through `run_git/2` (`:716`) with a scrubbed env (`@git_scrub_env`, `GIT_CONFIG_NOSYSTEM=1`) and an injectable `:git_cmd`. The existing status argv already pins `core.excludesFile=/dev/null`, `core.quotePath=false`, `core.fsmonitor=false`, `--untracked-files=all`, `--ignore-submodules=none`. It does not pin `core.filemode`, and it never asks git about index flags.

### WR-01 / WR-02 fix (confirmed against git)

- **WR-02:** add `-c core.filemode=true` to the status argv (the `-c` arguments sit before `-C`). The env scrub cannot do this job: `GIT_CONFIG_NOSYSTEM` removes only system config, and `GIT_CONFIG_COUNT`/`GIT_CONFIG_PARAMETERS` are being cleared, so a repo-local `core.filemode=false` is still honored today. Also fix the comment that overstates isolation (WR-02's wording finding).
- **WR-01:** add a second git call, `git -C <path> ls-files -v -z`, and count every record whose tag byte is not `H`. Tags seen in experiment: `h` = assume-unchanged, `S` = skip-worktree. Count all non-`H` (also `M`, `R`, `K`, `C`, `?`) as dirty; fail closed on anything unknown. Add the count into the same total that `dirty_count/2` returns so `@max_dirty_count` bounding still applies.
- **Extra hole found (not in the disposition):** a repo-local `core.ignoreStat=true` makes git set the valid bit on entries it writes, which then hides later edits. The experiment showed an edited file disappearing from `git status` after `git checkout` under that setting. The `ls-files -v` pass catches it (the entries show as `h`), so no extra `-c` pin is needed, but the test suite should include that case because it is the same fail-open class.
- Output remains count-only; no path text is retained (keeps the existing privacy property, and addresses the spirit of IN-04 if the argv NUL case is also made to return `:unavailable`, i.e. rescue `ArgumentError` in `run_git/2` at `:716-722`).
- WR-03 (message miscounts exclude rules as "files"): the probe returns `{records, excludes}` separately via `probe/2`; surface two counts in the message instead of summing. Message-only; no new cause atom.
- WR-04 (weak tests): replace the source-grep journey test and the pre-blocked CLI leak test with tests that use a real temp repo fixture (the pattern in `test/crosswake/proof_lane/twin_producers_test.exs`), one per tamper: index-flag, skip-worktree, filemode, ignoreStat, exclude rule, untracked file. Each must assert `{:blocked, :source_dirty}` and, as a control, that the same fixture un-tampered returns `:ok` (otherwise the test can pass because git is unavailable, which is `:prerequisite_missing`, not `:source_dirty`).
- IN-01: `observe_identities/2` should take the already-decided clean result from `checked_identities/3` rather than probing a third time without the injected `git_cmd`. Smallest change: give `observe_identities/2` an `opts` argument with `:git_cmd` and pass it from `checked_identities/3`.

### Interaction with freeze/3, checked_identities/3, receipt schema, fidelity limits

- `freeze/3` runs `clean_tree/2` after the HEAD/tree equality checks (`:632-636`) and before any hashing, so the stronger probe makes freeze fail earlier on a tampered candidate. No signature change.
- `checked_identities/3` is the post-journey gate (`:989`). Because the probe is the same function, freeze and gate stay symmetric. Keep that symmetry; do not give the two sites different probe options.
- `fidelity_limits` is a literal list compared with `literal/4` at `twin_receipt.ex:343` and emitted at `:303`; one existing limit is "source edit made and reverted during a run not detected" (`:62`). The WR-01/02 fixes do not change what the receipt claims, so the list stays as-is. Do not add a limit like "index flags not detected", because after the fix that statement is false.
- **Schema version bump: NO for WR-01/02/03/04.** `@schema_version 1` (`twin_receipt.ex:17`) is checked as a literal at `:338`. The receipt's shape (groups, joins, limits) does not change. Bump only if the join roster or the limits list changes.

### Phase 179 identity projection join (bundle id hardcoded)

`twin_journey.ex:20` has `@bundle_id "org.crosswake.twin"`, used for simctl and xcodebuild (`:525`, `:533`, `:560`). The question is whether to replace it with a projection of the generated host's configured bundle id and add that as an 8th identity join.

Recommendation: **defer; do not land it in v26.**

- It changes the receipt contract. `@identity_joins` (`twin_receipt.ex:45-53`, seven entries) is compared by exact set equality at `:553` and by ordered list equality at `:626` against roster id `TW-T10-02` (`:56`). An 8th join is a schema change: bump `@schema_version` 1 to 2, update both comparisons, the decoder (`:830`), the serializer, and the 183-era tests. That is a larger blast radius than every other item in this milestone put together.
- It does not close a fail-open path. The hardcoded id is the twin's own test identity. The existing `installed_build` join already binds installed manifest, activation, served JS, HEAD and tree (`twin_producers.ex:959-969`). A wrong bundle id would fail to install or launch (a loud failure), not pass quietly.
- A bundle-id projection also touches Phase 179's host-owned identity rules (private signing/identity values must not enter receipts), which needs a privacy decision first.
- Scheduling consequence: if the roadmapper wants it later, it is exactly one schema bump (1 to 2) plus one fixture refresh; record it as a named deferral with that reopen condition rather than leaving it implicit.

### Run-once protocol (D-16) and what it forces

Twin-04 is consumed. Any commit after `50fcd57` needs a new prepared record and a new run root `twin-05`. Concretely for the roadmap:

- Every phase in v26 that changes code under the candidate produces commits after `50fcd57`, so none of them can be validated by a twin run. Their validation is unit, integration, and artifact inspection (consistent with AGENTS.md zero-human verification).
- The twin run is exactly one phase, last, with no code change inside it. If twin-05 fails, the roadmap's rule is: fix, and a new prepared record (twin-06) is a new decision, not an automatic retry.
- The 181 and 182 review dispositions already record the same coupling: a 181 change invalidates `180-SEAM-HANDOFF.json` (`repaired_head 12f84cd`) and requires 181-10 Tasks 1-2 again; a 182 change requires the Simulator harness rerun and a refreshed `182-FINAL-HEAD.json`. Those refreshes belong in the final seal phase, once, after all code is frozen.
- The phase180 feasibility test file is SHA-pinned (`script/collection_assertion_ledger.json` records this for `test/crosswake/proof/phase180_twin_feasibility_test.exs`), so no v26 change may edit it; see Question 4 for a rule that a change would otherwise break.

## Question 2: Host-command seam M-02

### What the legacy path is

`grantHostCommands` (`ActivationCoordinator.swift:268-297`) has two arms:

- **Declared arm** (route has a `host_commands` map): per command, denials are `seam_unsupported`, `not_registered`, `version_unsupported`, otherwise granted (`:283-294`).
- **Legacy arm** (`route.hostCommands == nil`, i.e. the field is absent, decoded at `:246-247`): only for the entry route, it grants every `host.*` key in `request.capabilities` that the host registered, at the version supplied by the request, with no version check and with an always-empty `denials` return (`:274-281`). Unregistered keys are dropped with no record. This is the M-02 silent-degrade.

### Who uses it

- Crosswake-generated manifests never hit it: the Elixir serializer always emits `"host_commands"` (`lib/crosswake/manifest/types.ex:1276`), as `{}` when none are declared, and the `Enum.reject` after it (`:1278-1287`) strips only six nil-valued keys, never this one. Manifest schema is `1.2.0` (`types.ex:771`).
- It is reachable only by a hand-written or pre-1.2.0 manifest. The only in-repo users found are the Swift `legacy: true` fixtures (`HostCommandSeamTests.swift:33`, `HostCommandWireTests.swift:24-25`). I found no example host manifest without `host_commands` (the grep of example fixtures listed none that contain routes). Confidence MEDIUM on "no real consumer": an out-of-tree adopter manifest cannot be ruled out, and adopter inspection is out of bounds.
- `hostCommandDiagnostics` (`:337`) is declared public but appended to only in navigation (`:624`, `:630`, `:647`); L-03 says no product code reads it, so it is no substitute for returning denials.

### Fail-closed fix (recommended)

Keep the legacy arm's compatibility promise ("absent field keeps today's behavior, entry route only"), but stop it being silent:

1. Apply `HostCommandSeam.supportsCommandVersion(version)` to each legacy grant (the declared arm already does at `:289`).
2. Return a denial for every `host.*` key in the request that is not granted: `not_registered` or `version_unsupported`, the same strings the declared arm uses, so `RouteDenialPresentation` and the bridge message (`BridgeChannel.swift:457-462`) need no new vocabulary.
3. Add one new Swift test per denial in the existing `legacy: true` world.

Alternative considered and not recommended: remove the legacy arm (deny all `host.*` for manifests without `host_commands`). It is the strictest option, but it silently changes behavior for any out-of-tree pre-1.2.0 manifest, and the project has no evidence about whether one exists. If the roadmapper prefers it, it is a one-line change plus a compatibility-guide edit (the guide already disagrees with the code, see M-01 and I-03); decide in phase discussion, not here.

### Contract impact

- **Manifest schema 1.2.0: unchanged.** The fix reads the same fields.
- **Public API: additive only.** `LiveViewSession.hostCommandDenials` is populated in cases where it was previously empty. No signature change in the Swift package or Elixir.
- **Compatibility with existing hosts:** hosts that register exactly the keys they request see no change. Hosts requesting an unregistered `host.*` key now get an explicit denial instead of nothing.
- **Mirror/release implication:** the Swift package is mirrored to the iOS mirror repo; a package change means the shell-core is touched for any release. v26 does not release (no publish in scope), but `template_version` drift hash guards exist (182 commit `10000a0` restamped the shell template drift hash), so check whether the generated-shell template digest changes. If it does, the same restamp step applies.

### Co-located items worth one phase with M-02

Same files and same review: M-03 (doctor stale-fixture check returns `[]` on an unreadable fixture, a fail-open of the same class as WR-01), M-04 (absolute path with local username in doctor/gate/raise messages, a privacy-rule violation per AGENTS.md), L-04 (manifest validator is one-directional), L-05 (`Builder.host_commands_for` crashes on a bare-name registry that the policy validator accepts). M-01 (floor not equal-major) is a guide-vs-code disagreement; resolve by editing the guide (cheaper, no behavior change) unless a decision says otherwise.

## Question 3: Loopback harness and preflight

### Wire vs remove

`script/verify_loopback_origin_simulator.sh` is referenced by no workflow, no `script/repository_verification_stages.json` stage and no test (repo-wide search found only the script itself). It is an orphan that has never run in any gate. Its remaining value: it is the only check that a generated local-mode host can load a loopback page in a WKWebView and that ATS keys land in the built bundle.

Recommendation: **wire it into the existing generated-iOS leaf, do not create a new workflow lane.**

- `phase18-ios-proof` (`.github/workflows/crosswake-ci.yml:1211-1229`, `macos-15`, runs `script/verify_generated_ios_shell.sh`) is the natural owner; `verify_generated_ios_shell.sh` already takes mode flags (`--proof-lane`, `--reference-pack-adapter`). Add the harness as a further mode of that script or as a step in the same job. AGENTS.md says to promote checks to CI only for a recurring contract with stable feedback, and local-mode loopback is a recurring generated-output contract.
- Precondition before wiring: fix the findings that make it unfit to gate (below). A harness that can report `passed` while asserting nothing must not become merge-blocking. Measure its first CI results as advisory before making it required (the project's own lesson from PR #173).
- If the roadmapper judges Simulator CI too slow or flaky, the alternative is **remove it** and move its two cheap assertions (ATS keys; owned-bytes unchanged) into a non-Simulator ExUnit test over the generator output, leaving the WKWebView load as the twin's job. Do not leave it orphaned: an unreferenced check is a check that passes by never running.

### Harness defects to fix first (182 findings, with evidence)

- **WR-03:** `owned_hashes()` (`verify_loopback_origin_simulator.sh:251-254`) hashes `Fixtures/*.json`; the `-n "$HASH_BEFORE"` guard at `:258` is true whenever any one file hashed, so an empty `Fixtures/*.json` glob is invisible, and `HASH_BEFORE == HASH_AFTER` is trivially true when nothing in the swap touches those files. The assertion cannot fail as written because the probe copy at `:256` writes a file that is not in the hashed set. Fix: hash the probe destination's neighbors that the swap could realistically change, assert an exact expected file count, and add a negative control that mutates an owned file and expects the block.
- **WR-05:** `cleanup_and_emit` (`:137-175`) sets `APP_UNINSTALLED` and `DEVICE_LEFT_AS_FOUND` but exits 0 whenever `OUTCOME == passed` (`:172`), ignoring them. Fix: downgrade to a `cleanup_failed` outcome and non-zero exit when either is `false`.
- **WR-04:** the evidence write at `:168-170` is unchecked; fail the run if it fails.
- IN-02 (`grep -q` under `pipefail`) and IN-03 (no timeouts) are the same flake class; fix in the same pass since CI wiring turns them into red builds.

### Physical-iPhone preflight origin-mode check

`generator.ex:677-698` already refuses `:local_loopback` for the proof lane at generation time by raising `ArgumentError` (`@local_mode_refusal`, exposed by `local_mode_refusal/0`). That is correct as a last line, but it fires late and as an exception. The structured place is `PhysicalIphonePreflight.config/1` (`physical_iphone_preflight.ex:116-121`), which today calls only `Config.normalize/1`, and `check/1` maps `{:config_error, _}` to rule `PI-PREFLIGHT-CONFIG` (`:57`). Recommendation: reject loopback origin mode there, reusing `Generator.local_mode_refusal/0` text so the two cannot drift. Uncertainty: `Config` (`proof_lane/config.ex`) carries no `ios_host`/origin field (grep found none), so the check needs an explicit `:ios_host` option or must read the host config the same way the generator does; confirm in phase planning which of the two the physical flow actually has at preflight time. Doctor already reports `ios_host.local_loopback_origin` and `ios_host.origin_mode_mismatch` (`doctor.ex:2399-2415`), so preflight should add the blocking rule, not a new finding.

WR-02 (182) `IOSHostGeneration.origin_transport/1` not re-checking the loopback allowlist for hand-built structs: add the re-check at that function; it is the same fail-closed principle as the preflight check. WR-01 (plist reconcile not transactional with other generated outputs) conflicts with the v25 generation design ("detect/recover an interrupted multi-output update"); it needs a decision whether to repair now or record as a named limitation. WR-06 (`inspect` prints the HTTPS origin for every host, not only in local mode) is a small output correction.

## Question 4: Doctor and proof-lane (SEED-014)

Re-checked against the candidate; status is not what the seed says in every case:

| Item | Seed claim | Candidate status | Evidence |
|------|-----------|------------------|----------|
| A haptics assertion | defer | Reopen condition NOT met: Phase 175 ended with REL-10 breached, so the release pipeline has not been proven end-to-end. Keep deferred. Still a breaking vocabulary bump (2 to 3). | brief; seed disposition |
| B exit codes | closed | closed by 174-03 | seed |
| C placeholder provenance | open | STILL OPEN | `crosswake.proof_lane.verify_navigation_shell.ex:104-114` still hardcodes all four values |
| D denial view route id | open | out of scope here (SwiftUI, UI); only item that engages the brand book | seed |
| E structured details | open | STILL OPEN | `doctor.ex:374-392`: the `check(:warning, "unmanaged_routes", ...)` call passes no details map |
| F filter hole | open | STILL OPEN | `doctor.ex:466-472` filters on `cache_contract != nil or island_contract != nil` before the coherence `Enum.all?` at `:494-500` |

### F: compile-time vs doctor-time

The seed proposes compile-time as "stronger and symmetric with `:cached_read_only` without `cache_contract`". Two findings contradict that in the candidate:

1. The symmetry premise is false. `Policy.Route.validate_offline_contracts` (`route.ex:112-135`) only checks the reverse direction (a contract on the wrong `offline` mode). `:cached_read_only` without `cache_contract` is not rejected at compile time either (no match in `route.ex`, `policy/validator.ex`, or `manifest/validator.ex`).
2. A blanket compile-time rule would break existing code. `test/crosswake/proof/phase180_twin_feasibility_test.exs:9-15` builds an `:offline_island` + `:local_first` route with no `island_contract` through `Route.new!`, and that file is SHA-pinned and must not be edited. `test/support/router_fixtures.ex:182-184` has a `:native_screen` route with `offline: :local_first` and no island contract, which is a legitimate shape (native screens own their own local state).

Recommendation: **doctor-time**, and scoped. In `phase_4_posture/1`: examine every route with `offline != :unavailable` (drop the contract-based pre-filter), and apply the `:local_first` requires `island_contract` rule only when `runtime == :offline_island`. Also add `route.cache_contract` presence for `:cached_read_only`, which the existing coherence code already tests. This catches the exact misconfiguration without touching `Policy.Route` or any pinned test, and leaves compile-time hardening as a possible later decision with its blast radius known. A related vacuous result to fix in the same edit: `Enum.all?` over an empty route map makes `coherent?` true and the status `:supported` with zero offline routes (`doctor.ex:493-505`); that is absence scored as success, so report `:not_claimed` (or equivalent existing status) when no route claims offline behavior. Confirm which status atoms the doctor JSON schema allows before choosing.

### E: structured details

Pass `details: %{unmanaged_paths: paths, router: source_module}` to the `check/6` call. The warning struct (`policy/warning.ex:15-16`, `Compiler.build_warnings` at `compiler.ex:73-77`) already has the paths list (`Map.get(&1, :path)`), but the doctor maps only `warning.message`. Cheapest correct change: add the paths to `Warning` as a field (or a `details` map) and read it in `doctor.ex:379`; do not re-parse the message. Match the `policy_compile_failed` pattern in the same function. Details contain route paths, not user data, so no privacy concern; confirm no path contains an absolute local path (M-04 class) before shipping.

### C: provenance header sources

Populate at verification time: `crosswake_version` from the app's loaded spec (`Application.spec(:crosswake, :vsn)`), `template_version` from the generator's template constant (single source, same one the shell drift hash uses), `commit_ref` from `git rev-parse HEAD` in the project root, with an explicit sentinel (not an all-zero hash) when not a git checkout or git is unavailable, and `device_class` from the proof-lane contract's `PhysicalIphoneContract.device_class()` or `:unknown` only when genuinely unknown. The evidence-input validator must reject the all-zero ref so the placeholder cannot return (that is the missing negative control). Do not shell out with an absolute path in error text. This item bumps nothing: `schema_version: "2"` is the evidence-input schema, unchanged.

## Question 5: Guards (SEED-018 / SEED-023)

### Where they belong

- **SEED-018 (non-empty-collection guard, "VACG-01"):** extend `script/check_absence_is_not_success.exs` (the scanner whose `run/1` composes `mutation_controls(root) ++ stale_citations(root)`), as a third rule. Do not create a parallel scanner. `script/inventory_collection_assertions.exs` and the two JSON files state their own sunset (`collection_assertion_ledger.json` header: lift the detection core into the merge-blocking guard, then delete the script, both JSONs and `phase170_vacuous_assertion_ledger_test.exs`) because "two mechanisms that can silently disagree about what counts as safe are worse than one". The roadmap should schedule that lift, not another tool.
- **Scope for v25:** limit the rule's first enforcement to v25 test paths (`test/crosswake/proof_lane/twin_*`, `phase179-183` proofs, host-command tests). A quick scan of the ledger for those shapes found 12 matching rows, all classified safe (9 cardinality-pinned, 3 guarded). So the v25 test code is clean today; the value of the guard is preventing regression, and a repo-wide rule is not cheap: the ledger lists 243 rows (135 safe-by-construction, 63 guarded, 41 pinned, 4 compile-time-literal), so enforcement is feasible but should be measured as advisory first.
- **SEED-023 (scope cardinality):** the existing `assertFullScope` lives in Node (`scripts/ci_monitor.cjs:310`), reused by one caller. For the v25 Elixir/shell code, do not import it; per the repo's copy-over-dependency rule add exact-count pins at the sites below. The seed's own shape distinction applies: derive-from-tree checks must fail on shrinkage; declared rosters (`check_release_workflow_integrity.exs`) must NOT be converted.

### v25 sites that derive scope and can shrink silently (evidence)

- `lock_digests/1` (`twin_producers.ex:817-826`): `for rel <- @lock_rels, match?({:ok,_}, File.stat(...))` and a block only when the result is empty. If one of `mix.lock` / `examples/phoenix_host/mix.lock` is missing, the `dependency_lock` join silently narrows to one file. `observe_identities` repeats the pattern (`:937`, `locks != []`). Fix: require exactly `length(@lock_rels)` digests. This is a code fix, not only a guard.
- The harness `owned_hashes` glob (see Question 3).
- Telemetry: `attachment_count`-style "zero required" checks in `twin_journey.ex:472-` should assert the export itself ran (they do return `{:unavailable, :no_result_bundle}`; keep).

### Ordering: fix first, guard second

Land guard rules only after the fixes in phases A-D, in a dedicated phase, with a measurement step: run the new rule across the whole tree and record findings before making it merge-blocking (the project's lesson from the PR #173 guard). A guard introduced first would redden CI on the very sites the fixes edit, and would tempt a waiver, which the scanner's own header calls worse than no guard. Each rule must ship with a mutation control that proves it fails on a seeded vacuous case (the scanner's rule 1 requires this of everyone else; it must meet it itself).

## Verified experiments

In a throwaway repo (scratchpad, not the candidate):

1. With `git update-index --assume-unchanged` on one file, `--skip-worktree` on another, and `core.filemode=false` with a mode change on a third, plain `git status --porcelain` printed nothing. Adding `-c core.filemode=true` surfaced only the mode change. `git ls-files -v` showed `h` (assume-unchanged), `S` (skip-worktree), `H` (normal). So WR-01 and WR-02 are real and independent, and `ls-files -v` is the right detector for the first.
2. With repo-local `core.ignoreStat=true`, after a checkout the file showed as `h` in `ls-files -v`, and a subsequent edit did not appear in `git status`; `-c core.ignoreStat=false` did not restore visibility. The tag check is therefore the only detector, and is sufficient.

## Patterns to Follow

### Pattern 1: One probe, one configuration
**What:** every freeze/gate/observe site calls the same `clean_tree/2` with the same options and injectable `git_cmd`.
**Why:** WR-01/02 and IN-01 are all consequences of two near-identical probes drifting.

### Pattern 2: Fix, then guard, then seal
**What:** fixes land with a failing test that reproduces the defect (the throwaway-repo cases above are templates); guard rules after; the one consumed operation last.
**Why:** D-16 makes the last step irreversible; everything before it must be checkable without it.

### Pattern 3: Counted, closed outputs
**What:** probes return counts and closed atoms, never path text.
**Why:** existing privacy contract (`twin_producers.ex:735`) and M-04.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Debugging through the twin
**What:** running twin-05 to discover whether a fix works. **Why bad:** consumes the run, forces twin-06. **Instead:** prove each fix with unit tests and artifact inspection first.

### Anti-Pattern 2: Receipt contract growth as a side effect
**What:** adding an identity join or a limit while "fixing" the probe. **Why bad:** schema bump, decoder, pinned tests. **Instead:** defer the bundle-id join as an explicit, named deferral.

### Anti-Pattern 3: Compile-time rule that breaks a pinned test
**What:** making `:local_first` without `island_contract` a `Route.new!` error. **Why bad:** breaks the SHA-pinned Phase 180 gate and the native-screen fixture. **Instead:** doctor-time, scoped to `:offline_island`.

### Anti-Pattern 4: Orphaned checks
**What:** keeping `verify_loopback_origin_simulator.sh` unreferenced. **Why bad:** a check that never runs scores absence as success. **Instead:** wire it into `phase18-ios-proof` or delete it.

## Suggested Build Order and Phase Boundaries

Numbering continues at 184. Phases 184-188 are independent of each other at the code level (different files) and may be ordered by risk; they all precede 189. The only hard edges are: guards (188) after the fixes they would flag, and seal (189) after everything.

| Phase | Name | Scope | Depends on | Validation (no twin) |
|-------|------|-------|-----------|----------------------|
| 184 | Twin source-binding hardening | WR-01/02/03/04, IN-01..04 (183); `lock_digests` exact-count; `ArgumentError` rescue | none | ExUnit with real temp git repos; control cases; mix test of `twin_*` files |
| 185 | Host-command seam fail-closed | M-02 (legacy arm denials + version check); co-located M-03, M-04, L-04, L-05; M-01 as guide edit | none | `swift test` in `packages/crosswake-shell-core-ios`; ExUnit for doctor/validator/builder |
| 186 | Loopback harness and preflight | 182 WR-02/03/04/05/06, IN-02/03; preflight origin-mode rule; wire into `phase18-ios-proof` or remove; WR-01 decision | none (shares `generator.ex` knowledge with 185 only by reading) | harness run is a local advisory; ExUnit for preflight and generator; CI leaf reviewed as advisory first |
| 187 | Doctor and proof-lane fidelity | SEED-014 C, E, F (doctor-time, `:offline_island` scoped); empty-set `:supported` fix; record A as still deferred, D as out of scope | 185 if `doctor.ex` is edited in both (merge order only) | `doctor_test.exs`, mix task tests; evidence-input rejects all-zero ref |
| 188 | Absence and scope guards | SEED-018 rule in `check_absence_is_not_success.exs`, advisory measurement, then merge-blocking; lift/delete ledger scripts per their sunset; SEED-023 exact-count pins at the v25 sites | 184, 186 (the sites must already be fixed) | scanner self-tests with a seeded vacuous case per rule; whole-tree measurement recorded |
| 189 | Reseal and twin-05 | refresh `180-SEAM-HANDOFF.json` and `182-FINAL-HEAD.json`; rerun 181-10 Tasks 1-2 and the 180-01 gate; one new prepared record; ONE `twin-05` run; no code changes in-phase | 184-188 complete and merged to the candidate's final head | the twin's own receipt; blocked or failed is reported as such, no retry-to-green |

**Phase ordering rationale**
- 184 first because it is the item the brief calls out as able to weaken a future run silently, and it is self-contained.
- 185 and 187 both touch `doctor.ex`; sequence them to avoid a merge conflict rather than because of a dependency.
- 188 last among fixes because a guard shipped before its fixes would be red or waived.
- 189 single-purpose: the run is irreversible and uses the final head.

**Research flags**
- 185: needs a decision on remove-vs-harden the legacy arm (and whether any out-of-tree manifest exists; unknowable from this repo).
- 186: needs a decision on wire-vs-remove, and on what the physical preflight actually receives for origin mode (`Config` has no origin field).
- 187: confirm the allowed doctor status atoms before reporting `:not_claimed`.
- 184, 188: standard patterns; low research need.
- 189: depends on the exact prepared-record procedure in the 183 phase artifacts, which this research did not read in full.

## Scalability Considerations

Not applicable at product scale; the relevant limits are bounded counts. `@max_dirty_count 1_000_000` (`twin_producers.ex:712`) bounds the probe; the `ls-files -v` pass must use `-z` and the same bound. The candidate has about 3257 index entries per the 183 disposition, so cost is negligible.

## Open Items

- Whether any out-of-tree pre-1.2.0 manifest uses the legacy path (cannot be determined without adopter data; assume possible).
- Whether the generated-shell template digest changes when the Swift grant function changes (check the drift-hash test after edit).
- Exact content of the prepared-record procedure for twin-05; read the 183 plan artifacts during phase 189 planning.
- Whether `Config` or a separate host config is available at preflight time for the origin-mode check.
- The 181 and 182 candidate lineage: v26 edits must land on whatever branch becomes the new candidate head; this document does not choose it.

## Sources

- Candidate code at `50fcd57`: `lib/crosswake/proof_lane/twin_producers.ex`, `twin_receipt.ex`, `twin_journey.ex`, `twin_runtime.ex`, `generator.ex`, `physical_iphone_preflight.ex`; `lib/crosswake/doctor/doctor.ex`; `lib/crosswake/policy/route.ex`, `compiler.ex`, `warning.ex`; `lib/crosswake/manifest/types.ex`; `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift`; `script/verify_loopback_origin_simulator.sh`, `script/check_absence_is_not_success.exs`, `script/collection_assertion_ledger.json`, `script/repository_verification_stages.json`; `.github/workflows/crosswake-ci.yml`.
- Planning: `.planning/workstreams/quality-ratchet-release/phases/181-*`, `182-*`, `183-*` REVIEW-DISPOSITION files; `.planning/seeds/SEED-014`, `SEED-023`; `.planning/research/v25/SUMMARY.md`, `TWIN-ARCHITECTURE.md`.
- Git behavior: reproduced locally (assume-unchanged, skip-worktree, `core.filemode`, `core.ignoreStat`); primary documentation is `git-update-index(1)` and `git-ls-files(1)` (`-v` tag letters), not fetched.
