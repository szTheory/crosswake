# Feature Landscape: v26.0 Harden Before Trust (finding inventory)

**Domain:** hardening of v25 code (host-command seam, loopback origin, reference twin) so no v25 check passes while checking nothing and no guarantee weakens quietly.
**Researched:** 2026-10-15
**Candidate code:** `/private/tmp/crosswake-phase180-impl` at `50fcd57`, clean tree, read-only. v25 base for diffs: `d0dbdf7` (the commit before Phase 179; `d0f3e2f1` named in the brief is a recovery-checkout commit that does not exist in the candidate). v25 = 155 files, +27,105/-209.
**Overall confidence:** HIGH for status claims (each re-read at file:line below); MEDIUM for the 182 WR-01 and the IN-xx cosmetics, which were not re-derived in depth (marked).

Reading guide. "Silent?" = can the defect degrade without any visible signal (yes means a check or guarantee can pass or weaken while nothing is true). Sizes: S under half a day, M about a day, L multi-day or a refactor. Paths are relative to the candidate unless prefixed `.planning/`.

## Headline findings (what changed versus the inputs)

1. **SEED-018 is already done for v25 and repo-wide.** `elixir script/inventory_collection_assertions.exs --check` exits 0: 243 classified sites, ledger matches the live tree exactly, **0 `needs-fix`** (135 safe-by-construction, 63 safe-guarded, 41 safe-cardinality-pinned, 4 compile-time-literal). 19 rows belong to v25 files and all are safe. The seed's "173 sites" figure is stale. The remaining vacuity exposure is NOT in `assert Enum.all?` tests; it is in (a) the checker script that polices absence and (b) one production helper (see GUARD-01, GUARD-02).
2. **The strongest SEED-023 target is `script/check_absence_is_not_success.exs`.** It prints "OK" when its `Path.wildcard` scopes return nothing (lines 76-82 and 178-186; no empty or cardinality guard anywhere in the file). The checker that exists to catch "green while asserting nothing" can itself go green on zero files.
3. **CW-REQ-A reopen trigger is technically met but should stay deferred** (see DEF-A).
4. **CW-REQ-C, D, E, F are all still present** in the candidate; B is closed (174-03).
5. **The loopback Simulator harness is an orphan and carries three defects that make it dishonest** (WR-03/04/05). Decide wire-or-remove first; the decision collapses or keeps six findings.

## Verification method note

`mix test`, the Simulator and the twin were not run. Status claims come from reading code and from the one read-only command that exercises a guard (`inventory_collection_assertions.exs --check`, exit code captured without a pipe).

---

## TABLE STAKES (must fix this milestone)

Each row is a path where a v25 check can pass while checking nothing, or a guarantee can quietly weaken, or a hard project rule is violated.

### Group PROBE: the clean-tree gate behind twin-05

| ID | Defect | Status in candidate (file:line) | Silent? | Impact | Size | Rec |
|----|--------|-------------------------------|---------|--------|------|-----|
| PROBE-01 (183 WR-01) | Index flags `assume-unchanged` / `skip-worktree` hide a modified file from the clean-tree probe. | PRESENT. `lib/crosswake/proof_lane/twin_producers.ex:759-783` (`probe/2`) runs only `status --porcelain=v1 -z`; no `ls-files -v` anywhere in the file. | **Yes.** A flagged modified file gives "0 dirty", the `source` and `installed_build` joins pass on code that is not the committed code. | A future twin run could attest a hidden edit. Twin-04 unaffected (3257 entries all `H`, per 183 disposition). | S-M | **TABLE STAKES** |
| PROBE-02 (183 WR-02) | `core.filemode` is not pinned, so a repo/global `false` hides mode-only changes. | PRESENT. Same `probe/2` arg list has `core.excludesFile`, `core.quotePath`, `core.fsmonitor` only (lines 760-775); `run_git` scrubs env but a global config still applies (`@git_scrub_env`, line 716-723). | **Yes.** An executable-bit change on a script the run consumes is invisible. | Same as PROBE-01. | S | **TABLE STAKES** |
| PROBE-03 (183 WR-04) | Probe tests are weak: journey test greps source, CLI leak test injects a producer that already blocks, no index-flag test. | PRESENT per review; PROBE-01/02 need new tests anyway. | Yes (tests that cannot fail). | The guard for PROBE-01/02 must be proven by a real temp repo with the flag set and a revert-to-green control. | M | **TABLE STAKES** (bundle with 01/02; use real `git init` fixtures, not only injected `git_cmd` stubs, per the AGENTS.md lesson) |
| PROBE-04 (183 WR-03) | Block message counts `.git/info/exclude` rules as "files", suggests `git status` (shows nothing in the exclude-only case), can print "0 files". | PRESENT. `dirty_count/2` adds `records + excludes` (`twin_producers.ex:751-757`). Fails closed. | No (blocks anyway), but misleading. | Operator wasted time; a misleading message is a diagnostic-as-product-surface defect. | S | **WORTH IT** (same change, two numbers reported separately) |

### Group SEAM: fail-closed gaps in the host-command seam (181)

| ID | Defect | Status (file:line) | Silent? | Impact | Size | Rec |
|----|--------|--------------------|---------|--------|------|-----|
| SEAM-M02 (181 M-02) | D-28 legacy path (manifest without `host_commands`) grants any registered `host.*` key at any version and drops unregistered keys with no diagnostic. | PRESENT. `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ActivationCoordinator.swift:274-282` (`guard let declared ... else`): loops `request.capabilities`, tests only `hasPrefix("host.")` and `registered.contains`. No `supportsCommandVersion`, no declaration check, no `HostCommandDiagnostic`. | **Yes.** | Affects manifests Crosswake did not generate (a hand-edited or out-of-tree manifest; the first adopter's own manifests if hand-written). Crosswake always emits `host_commands`, so no in-tree test reaches it. | M | **TABLE STAKES.** Needs one user decision: deny-with-diagnostic (recommended) vs warn-then-deny. It is a behaviour change for out-of-tree producers; ship a legacy-shaped fixture so the new outcome is a copyable contract. |
| SEAM-M03 (181 M-03) | Doctor stale-fixture check returns `[]` when the generated fixture is unreadable or malformed. | PRESENT. `lib/crosswake/doctor/doctor.ex:2477-2478` (`else _ -> []`) after `File.read` + `Jason.decode` at 2449-2450. A genuinely absent fixture and a corrupt one both read as "fresh". | **Yes.** Doctor stays green on a broken fixture. | A false all-clear in the self-service proof surface. | S | **TABLE STAKES** (distinguish `:enoent` skip from decode/shape failure; emit an error finding) |
| SEAM-M04 (181 M-04) | Doctor, gate and raise messages embed the expanded absolute package path (can contain a local username). | PRESENT. `doctor.ex:2529` (`package_location: package.location` in details) and message text at ~2521-2523 (`at #{package.location}`); `lib/crosswake/shell/shell_package.ex:55` builds the path with `Path.expand`; `lib/crosswake/shell/ios_host_generation.ex:95,121,126` (`shell_gate_message`) passes `package.location`. | No (it leaks, it does not degrade). | Violates the AGENTS.md sensitive-data rule (local usernames must not enter outputs). Doctor output is pasted into issues and CI logs. | S-M | **TABLE STAKES.** Report as written in the project (`relativePath`) or relative to project root; add a sentinel-username test so the fix is proven. |

### Group GUARD: absence-scored-as-success remnants

| ID | Defect | Status (file:line) | Silent? | Impact | Size | Rec |
|----|--------|--------------------|---------|--------|------|-----|
| GUARD-01 (SEED-023 sweep) | `script/check_absence_is_not_success.exs` has two derived scopes with no empty/cardinality guard. | PRESENT. `mutation_controls/1` at 76-82 (`test/**/*.exs` wildcard) and `stale_citations/1` at 178-186 (three globs under `.planning`). `run/1` (line 40-52) prints both "OK" lines when `findings == []`. No `== []` check on the scope. | **Yes.** Wrong root, moved tree or broken glob yields exit 0 with two OK lines. | The repo's own absence guard can score absence as success. Independent roster needed (a declared minimum, not derived from the same glob). | S | **TABLE STAKES** |
| GUARD-02 (v25 lib vacuity) | `TwinRuntime.stop_children/1` reports `:ok` ("every child reaped") when the registry is dead or no child was tracked. | PRESENT. `lib/crosswake/proof_lane/twin_runtime.ex:178-190`: `children = if Process.alive?(registry), do: ..., else: []`, then `Enum.all?([], ...)` is `true`. Consumed by `stop_all/1` (line 195). | **Yes, narrowly.** A cleanup that observed nothing reports success. | Twin cleanup claim ("no process left behind") can be true-by-emptiness. | S | **WORTH IT** (dead registry should return an explicit error/`:unknown`; add a test with a killed registry) |

---

## WORTH IT (cheap, coherent, rides along with a table-stakes change)

| ID | Defect | Status (file:line) | Silent? | Impact | Size | Rationale |
|----|--------|--------------------|---------|--------|------|-----------|
| SEAM-M01 + IN-01 (181 M-01) | Seam check is a floor (`provides >= demands`), the compatibility guide says the shell refuses a major mismatch. | PRESENT. `ActivationCoordinator.swift:286` (`SemVer.compatible(provides:demands:)`). | Partly: guide and code disagree, so an operator trusts a refusal that does not happen (a demand of `0.5.0` is accepted). | Guide truth. | S | **Fix the guide to say "minimum floor"** and add vectors for demand `0.5.0` and non-parseable `1.0.0-beta`. Switching the code to equal-major is itself a breaking change; not needed for one adopter. Update guide and test together. |
| SEAM-L01 (181 L-01) | Swift accepts leading-zero versions (`01.0.0`) that Elixir rejects. | PRESENT. `ActivationCoordinator.swift:880-887` checks digits only and `Int(parts[0])`. | No (accepts something wider than the contract). | Cross-language contract split. | S | One shared vector table read by both suites (Pitfall 6). Do with M-02. |
| SEAM-L03 (181 L-03) | `hostCommandDiagnostics` is never read by product code and grows without bound on two append paths. | PRESENT. `ActivationCoordinator.swift:337,624,630` append without dedup; dedup only at 647. No reader in `Sources` or `examples`. | Yes (diagnostics nobody can see). | M-02's fix adds diagnostics, so they must be readable and bounded or the fix has no output. | S | Bundle with M-02: cap, dedup, expose one documented accessor. |
| SEAM-L04 (181 L-04) | Manifest validator checks one direction: `host_commands` name must be in `capabilities`, but a `host.*` capability with no `host_commands` entry passes. | PRESENT. `lib/crosswake/manifest/validator.ex:410-428`. | Partly (becomes a denial at runtime, not at compile). | Earlier, clearer error for route authors. | S | Add reverse check; validate grammar/version via `Crosswake.HostCommands`. |
| SEAM-L05 (181 L-05) | Policy validator accepts a registry of bare names; `Builder.host_commands_for` crashes on one. | PRESENT. `lib/crosswake/policy/validator.ex:235-236` accepts binaries; `lib/crosswake/manifest/builder.ex:~166` does `Map.new(registry)`. | No (crash is loud). | Two modules disagree on registry shape. | S | Normalize once (`HostCommands.normalize_registry!`) or reject bare names. |
| SEAM-L06 (181 L-06) | A bridge request with no version gets "did not declare host command" when it was declared and granted. | PRESENT. `BridgeChannel.swift:~460-462` default arm of `hostCommandDenialText`; the gate at 408-419 fails on `capabilityAvailable` which needs a compatible request version. | No, but wrong reason. | Misleading denial for a page author. | S | Distinct text. Cheap with M-02. |
| HARN-W03 (182 WR-03) | Harness "owned hashes unchanged" assertion cannot fail. | PRESENT. `script/verify_loopback_origin_simulator.sh:251-261`: hashes `Info.plist`, `CrosswakeHostSettings.xcconfig`, `project.pbxproj`, `Fixtures/*.json`, then `cp`s the probe over `CrosswakeShell/CrosswakeShellApp.swift`, which is not in the list. | **Yes.** | A claimed narrowness/ownership proof that is vacuous. Fix by hashing the file being swapped plus a broken-state control (`before != after` when a hashed file is touched). | S | Only if the script is kept (see DEC-HARNESS). |
| HARN-W04 (182 WR-04) | Failed evidence-file write is not checked. | PRESENT. `verify_loopback_origin_simulator.sh:169-171` writes under `set +e` and ignores the result. | **Yes.** Exit 0 with no evidence file. | Evidence that "exists" in the report but not on disk. | S | Same condition. |
| HARN-W05 (182 WR-05) | Harness reports `passed` even when uninstall/shutdown cleanup failed. | PRESENT. Lines 147-162 record `APP_UNINSTALLED` / `DEVICE_LEFT_AS_FOUND` as fields only; line 174-176 exits 0 on `OUTCOME == passed`. | **Yes.** | A dirty Simulator left behind under a green result. | S | Same condition. |
| GEN-W02 (182 WR-02) | `origin_transport/1` does not re-check the loopback host allowlist for hand-built structs. | PRESENT. `lib/crosswake/shell/ios_host_generation.ex:64-72` only rejects http when mode is not `:local_loopback`; a hand-built `%IOSHostConfig{origin: "http://example.com", origin_mode: :local_loopback}` passes. | Yes (defense-in-depth hole; normal path validates). | An http non-loopback origin could be emitted into ATS config. | S | Reuse the normalize-time validator. |
| GEN-W06 (182 WR-06) | `mix crosswake.inspect` prints `host origin: <https origin>` for every declared host, not only local mode. | PRESENT. `lib/mix/tasks/crosswake.inspect.ex:59-60`. | No (it mislabels at most). | Output no longer matches what the guide promises. | S | Align code or guide; coherent with the DOC pass. |
| DOC-E (SEED-014 CW-REQ-E) | `unmanaged_routes` doctor finding drops its path list from JSON. | PRESENT. `doctor.ex:383-390` calls `check/6` with no details map; `lib/crosswake/policy/compiler.ex:75-76` already holds `paths`. | Partly (data is lost for machine consumers). | Adopters gating on doctor JSON must regex free text. | S | Pass `details: %{unmanaged_paths:, router:}`. Matches the `policy_compile_failed` sibling. |
| DOC-F (SEED-014 CW-REQ-F) | `phase_4_posture/1` filters out the exact misconfiguration it checks. | PRESENT. `doctor.ex:469-472` filters to `cache_contract != nil or island_contract != nil` before the coherence `Enum.all?` at ~492-499. A route `offline: :local_first` with no `island_contract` never reaches it, and `lib/crosswake/policy/route.ex:116-135` has no reverse rule. | **Yes.** Doctor stays green. | Same defect class as the milestone goal. | S | Prefer the compile-time rule in `Policy.Route` (symmetric with `cache_contract`); plus the filter change `offline != :unavailable` as a belt. State in docs that `--router` accepts any `__routes__/0` module. |
| PROOF-C (SEED-014 CW-REQ-C) | `verify_navigation_shell` hardcodes placeholder provenance: version `0.1.0`, template `161`, `commit_ref: "git-000...0"`, `device_class: :unknown`, `route_id: "route-0000000000000000"`, with `status: :passed`. | PRESENT. `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex:101-115`. | **Yes.** An all-zero hash reads as a real commit ref; the header says `:passed`. | Misattributed provenance in an evidence-first repo. | S-M | Derive from `git rev-parse HEAD` or an explicit sentinel (not zeros), real version/template. Same fail-closed theme; no schema change. |

---

## DEFER (with reason and reopen trigger)

| ID | Item | Status | Reason | Reopen trigger |
|----|------|--------|--------|----------------|
| DEF-A | **SEED-014 CW-REQ-A** haptics assertion in `PhysicalIphoneContract`. | Not present. `lib/crosswake/proof_lane/physical_iphone_contract.ex`: `@schema_version 2` (line 8), 19 assertion ids (lines 13-31), no `PI-BRIDGE-HAPTIC-IMPACT`. The bump would be 2 to 3. (The seed said 20 assertions; the candidate has 19.) | **Trigger evaluation.** The 174-03 reopen condition was "the v23.0 release pipeline proven end-to-end after Phase 175 publishes". PROJECT.md records 0.2.11 passing ordinary three-registry publication, exact-public proof and the six-child COMPLETE rollup, and Chimeway 0.1.2 separately. REL-10 breached = the first publish omitted the incident-response runbook (a timing/ancestry limit), not a failed pipeline proof. So the literal trigger is arguably met. **Decision: stay deferred anyway.** It is a deliberate breaking change to a closed ordered vocabulary (`validate_report/1`, `join_reports/3` require exact set and position), the adopter is not blocked (host-owned haptics gate), the physical-iPhone run is parked, and the milestone goal is removing silent weakness, not widening vocabulary. It also conflicts with the "no native-control breadth" stop list. | Resume of the physical signed-iPhone run (`first-b2c-adopter-readiness`) or an explicit adopter request, in a release whose pipeline is already proven. Record this evaluation in the v26 decision log so the trigger is not re-litigated. |
| DEF-D | **CW-REQ-D** `RouteUnavailableView` renders a monospaced route id. | Present. `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/RouteUnavailableView.swift:29-33` (`Text("Route: \(routeID)")` with `.footnote.monospaced()`); also `examples/ios_shell_host/CrosswakeShell/RouteUnavailableView.swift`. | Not silent, not a check. A user-facing copy/accessibility issue on shipped UI. It is the one UI item in scope of the brief, but it is a design opinion (SEED-005, SEED-008), the adopter already declined the shipped view, and removing the line changes a shipped surface and likely the shell template stamp (version-bump interplay with the 181 `template_version 4` decision). Cheap in code (S), expensive in re-attestation. | Adopter adopts the shipped view, or the next change that already touches the Swift shell templates. If pulled in, drop the line only and keep `routeID` on `RouteDenialPresentation`. |
| DEF-L02 | 181 L-02: one invalid `host_commands` key fails decoding of the whole manifest. | Present. `ActivationCoordinator.swift:253-256` throws `dataCorruptedError`. | Fails closed and loudly (every route denied). Blast radius, not silence. Fix touches decode semantics. | After SEAM-M02 lands and diagnostics exist; or first report from an adopter. |
| DEF-IN03 | 181 IN-03: `ShellPackage` uses regex text scraping of `project.pbxproj`. | Present. `lib/crosswake/shell/shell_package.ex:50-60`. | Works; brittle only if Xcode format changes; Phase 179 owns pbxproj parsing. | A pbxproj-format failure in generation. |
| DEF-W01 | 182 WR-01: Info.plist reconcile is not transactional with other generated outputs. | MEDIUM confidence: `crosswake.gen.shell.ex:253-266,633` show a separate `reconcile_origin_plist` step; atomicity not re-derived. | Failure window is an interrupted generation; Phase 179's interrupted-generation gate already covers managed outputs; `--check` reports drift. | An observed half-applied generation. |
| DEF-IN-182 | 182 IN-01..IN-04 (message grammar, `grep -q` under `pipefail`, no timeouts, unused var) | Harness-only, in the orphan script. | Moot if the script is removed; if kept, fix IN-02/IN-03 only while touching the file. | DEC-HARNESS = keep. |
| DEF-SNAP | Snapshot-clone run source (closes fidelity limit 5, edit-and-revert). | Disclosed limit; deferred in 183 D-12. | L-size refactor (`candidate_path` feeds freeze, build, paths, digests). After PROBE-01/02 the remaining gap is a deliberate adversarial edit-and-revert. | Any claim that a run verifies source for its whole duration. |
| DEF-REPO | Repo-wide SEED-018 sweep. | Nothing to do: ledger is 243/243 safe (see headline 1). | Already complete; tree-wide merge-blocking enforcement (VACG-01) stays deferred and must not land as a wall of red. | A new `needs-fix` row appears when the ledger is regenerated. |
| DEF-JS | Walk of other SEED-023 candidates. | `script/check_exunit_ownership.exs:18-21` and `script/list_merge_blocking_checks.py:100-108` already fail on an empty scope (no change). `script/check-collateral-size.sh:25` is a size budget where zero files is a legitimate pass. `script/release_candidate/hex_artifacts.sh:57` and `script/verify_*` use declared path lists (selector shape, leave alone). `script/inventory_collection_assertions.exs` diffs both ways and prints a count. `scripts/ci_monitor.cjs` already uses `assertFullScope` (line 310). | Only `check_absence_is_not_success.exs` is a true derive-from-tree check with no guard (GUARD-01). Do not extract `assertFullScope` to a shared module: still only one JS caller, and the Elixir/Python guards are idiomatic one-liners ("another copy and paste is better than another dep"). | A second JS caller appears. |
| DEF-MIXENV | Generator friction: drift check reports stale unless `MIX_ENV=test`. | Explained, not a bug: `crosswake.gen.shell.ex:95` selects the declared `:ios_host` path when `Mix.env() == :prod` or an `:ios_host` is configured; `guides/native_shell.md:60,85-86,99-126` documents `MIX_ENV` choice per mode. | Friction, documented. Changing env semantics would touch Phase 179 declaration rules. | Second report of confusion. A one-line doctor hint is optional. |
| DEF-LOCALPKG | `local_ios_package` resolves from the current directory. | Present. `lib/mix/tasks/crosswake.gen.shell.ex:777-780` (`Path.expand("packages/crosswake-shell-core-ios", File.cwd!())`) and `local_package_assigns` at 782-789. | Only matters for hosts outside the monorepo; those get a remote reference with no seam release yet (a delivery matter, not a code defect). Not silent: gate fails closed. | First off-monorepo host after delivery of the seam release. |
| DEF-NYQ | Nyquist validation gaps for 180-183. | `181-VALIDATION.md`, `183-VALIDATION.md` have `nyquist_compliant: false` (draft); `182-VALIDATION.md` present; Phase 180 has no VALIDATION file; 179 is compliant. | Planning bookkeeping, not product behaviour. Run `gsd-validate-phase` after the fixes, not before (the fixes change what is being validated). | Milestone closeout. Treat as a closeout task, not a requirement. |

## DROP (with reason)

| ID | Item | Reason |
|----|------|--------|
| DROP-CASE3 | Why twin-02 case 3 stalled | Unknowable: no cause was retained. Do not infer one. The current runtime records first failure (`TwinRuntime.record_failure(:child_timeout)`, `twin_runtime.ex` ~140-175), so a recurrence now carries a cause. No work item; keep the "never infer" note. |
| DROP-WK | `WKAppBoundDomains` hardcoded `example.com` | Present (`priv/templates/crosswake/shell/ios/Info.plist.eex:39-42`; also `applinks:example.com` in `CrosswakeShell.entitlements.eex:16`, `DiagnosticExportManager.swift:9`). Pre-existing, pinned by a golden (`test/fixtures/shell/ios/Info.plist.production.golden:32`) and by test (`crosswake_gen_shell_origin_mode_test.exs:340`), explicit placeholder a host edits, and the loopback guide test refuses to claim it is derived (`loopback_origin_guide_test.exs:43`). Making it origin-derived widens host-ownership of Info.plist (Phase 179 contract). Not a v25 regression; re-open only if an adopter generates a real host and the placeholder reaches a build. |
| DROP-IN02 | 181 IN-02 duplicate switch arm in the example host (`examples/ios_shell_host/CrosswakeShell/CrosswakeShellApp.swift:~447`) | Cosmetic, example host only. |
| DROP-ORPHAN-IF | (conditional) The three harness defects HARN-W03/04/05 and IN-xx | Dropped together if DEC-HARNESS chooses removal. |

---

## Debt items not yet classified above

| ID | Item | Status (file:line) | Silent? | Rec |
|----|------|--------------------|---------|-----|
| DEC-HARNESS | Orphan loopback Simulator harness: `script/verify_loopback_origin_simulator.sh` and `script/loopback_origin_simulator/{ProbeApp.swift,generate.exs,listener.py}`. | CONFIRMED ORPHAN. `grep -rIl verify_loopback_origin_simulator` finds only the script itself and the helper dir; no workflow, doc, guide or test references it. | Yes (an unreferenced script cannot protect anything; its own defects hide). | **WORTH IT: keep and wire**, default. It is the only reproducible evidence of LOOP narrowness (the http example.com control fails with -1022). Wire = one documented entry in `guides/native_shell.md` as phase evidence, not a CI lane (AGENTS.md: promote to CI only for a recurring contract). Fix HARN-W03/04/05 and prove them without a Simulator by running the script with `CROSSWAKE_IOS_XCODEBUILD_BIN` and an `xcrun` shim in broken-state mode. **Alternative: remove**, which drops six findings and the physical-evidence reproducibility. Needs one decision in discuss-phase. |
| DEBT-PREFLIGHT | Physical-iPhone preflight has no origin-mode check; refusal only at generation. | PARTLY. `lib/crosswake/proof_lane/generator.ex:677-695` refuses `origin_mode: :local_loopback` at proof-lane generation (`normalize_host!`). `lib/crosswake/proof_lane/physical_iphone_host.ex:5-25` and the task `crosswake.proof_lane.physical_iphone.ex:36,150` (`--preflight-only`) delegate to a host adapter with no origin-mode inspection. | Yes, in the sense that a hand-built or later-switched host can reach preflight in local mode. Refusal already exists upstream, and the contract is "physical lane refuses local mode". | **WORTH IT (S)** only as a regression test that preflight on a local-mode host fails closed, not a new check family. If the test already passes through the generator refusal, record that and drop the code change. |
| DEBT-ROUTEID | Route-id mismatch: example island `study-session` vs router/manifest `offline-study`. | PRESENT. `examples/phoenix_host/lib/crosswake_example_web/controllers/offline_controller.ex:20` (`route_id: "study-session"`); router and manifest use `offline-study` (`examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json:984,997`; `test/crosswake_example/host_command_seam_test.exs:30-31`). `examples/ios_shell_host` and `android_shell_host` fixtures still carry `local-first-study-session` (Android frozen; do not touch). | Not silent. A label inconsistency in example host data. | **WORTH IT (S) only if the twin or a proof reads the controller's route id**; otherwise DEFER. Check `twin_*` consumers before deciding; do not rename the Android fixtures. |
| DEBT-IDENT | Twin does not join the Phase 179 identity projection; bundle id hardcoded. | PRESENT. `lib/crosswake/proof_lane/twin_journey.ex:20` (`@bundle_id "org.crosswake.twin"`, used at 525, 533, 560, 597, 626). The seven joins in `twin_receipt.ex:45-53` have no bundle/identity projection join. | Partly: the twin attests its own fixed bundle rather than the generated candidate's effective identity. | **DEFER** (the user already deferred it in 183-CONTEXT, and joining it changes the receipt schema and run record). Reopen when the twin must attest a host that is not the fixed reference host. |

---

## Anti-features (look related, must not be pulled in)

| Anti-feature | Why not | Do instead |
|--------------|---------|-----------|
| Repo-wide merge-blocking `absence.collection_assertion_non_empty` guard (VACG-01) | Ledger already 0 needs-fix, but the SEED says the guard must follow zero findings and not become a wall of red; v26 only adds the targeted GUARD-01 floor. | Keep ledger-only; no new CI lane. |
| Moving `assertFullScope` into a shared module | One caller; speculative generality; no new dependency. | Copy a two-line non-empty/min-cardinality guard into the one Elixir checker. |
| Switching the seam check to equal-major (M-01) | Breaking behaviour change for out-of-tree producers to satisfy a guide sentence. | Correct the guide, add vectors. |
| CW-REQ-A haptics vocabulary, native menu/action breadth, capture packs | On the project stop list; adopter not blocked. | DEF-A. |
| Android anything, including the stale Android fixtures with `study-session` | Android is frozen. | Leave. |
| Running the twin, Simulator or xcodebuild inside research or as a casual check | A run root is single use; twin-05 can be burned (v26 PITFALLS 5). | Scripted go/no-go at the end (PROOF-02). |
| Snapshot-clone twin source refactor | L-size, not needed once PROBE-01/02 land. | DEF-SNAP. |
| `doctor --strict` / warnings-as-errors | Explicitly rejected in SEED-014; the host holds that policy. | None. |
| Making `WKAppBoundDomains` origin-derived | Widens generated ownership of the host plist; Phase 179 contract. | DROP-WK. |
| Delivering candidate commits into the recovery checkout / release / PR / tag | Separate authorization, outside this research and forbidden for these agents. | Keep as a stated gate (REL-DELIVERY, not in v26 scope). |
| Any adopter identity, price, geography or link while writing evidence | Sensitive-data rules. | Use the codename only. |

---

## Feature dependencies

```
DEC-HARNESS (keep/remove) -> HARN-W03/04/05, DEF-IN-182
SEAM-M02 (decision: deny-with-diagnostic) -> SEAM-L03 (diagnostics readable) -> SEAM-L06 (message)
SEAM-M01 guide fix -> SEAM-L01 shared vector table (same fixtures)
PROBE-01 + PROBE-02 + PROBE-03 (+ PROBE-04, IN-01/03/04) -> hardened candidate head
GUARD-01, GUARD-02, DOC-E, DOC-F, PROOF-C, SEAM-M03/M04, GEN-W02/W06 -> hardened candidate head
all product changes merged -> freeze commit -> scripted go/no-go + rehearsal -> twin-05 (new run root; twin-04 is consumed)
Any change to the 181 head -> 180-SEAM-HANDOFF.json (repaired_head 12f84cd) must be re-derived (181 disposition note)
Swift edits (M-01/M-02/L-01/L-03/L-06) -> `swift test` of the package + shell template stamp/golden check
```

## MVP recommendation

Prioritize: PROBE-01/02/03 (the stated reason for twin-05), SEAM-M02/M03/M04, GUARD-01. Then the WORTH IT rows that share a touched file. Defer everything in the DEFER table with its trigger recorded. Every deferred item that is silent (DEBT-IDENT partly, DEF-SNAP) keeps a visible fidelity-limit line rather than disappearing.

## Proposed phases (numbering continues at 184; requirement ids are candidates)

**Phase 184: Twin source-binding hardening (PROBE).** PROBE-01..04, 183 IN-01, IN-03, IN-04, GUARD-02. Real temp-repo fixtures on macOS and Linux CI; negative control per flag. Fixes land first because they define twin-05's gate. Avoids: git-probe fail-open, run-root burn (IN-03 leaves a refused root behind).

**Phase 185: Absence guards and harness honesty (GUARD + HARNESS).** GUARD-01 (independent minimum-cardinality floor in `check_absence_is_not_success.exs`, mutation proof that an empty scope fails), DEC-HARNESS resolution, HARN-W03/04/05 (if kept), DEF-REPO recorded as "ledger 243/243 safe, regenerated". Measure first (`--check`), report, then gate.

**Phase 186: Host-command seam fail-closed (SEAM).** SEAM-M01+IN-01, M02, M03, M04, L01, L03, L04, L05, L06; GEN-W02, GEN-W06. One user decision on M-02 up front. Legacy-shaped fixture is the contract artifact; a sentinel-username test pins M-04. Rederive the seam handoff.

**Phase 187: Doctor and proof fidelity (DOC/PROOF).** DOC-E, DOC-F, PROOF-C, DEBT-PREFLIGHT regression test, DEBT-ROUTEID (if consumed), record DEF-A decision and DEF-D deferral in the decision log; docs for `--router`. Small, independently landable items.

**Phase 188: Freeze, rehearsal and twin-05.** Freeze commit, scripted go/no-go (probe clean under the new rules, handoff digests match, rehearsal passes, `twin-05` absent), then the single twin-05 run against the hardened commit; Nyquist validation (DEF-NYQ) and closeout. Needs explicit run authorization; do not fold into earlier phases. Phases 184-187 are mutually independent except shared files; 184 should be first and 188 last.

**Research flags:** 186 needs a short discuss-phase (M-02 procedure; M-01 guide-vs-code). 184 needs a scratch-repo experiment to confirm `ls-files -v` tag letters before asserting. 185 and 187 are standard patterns.

## Sources

- Candidate code at `50fcd57` (files cited inline); `git diff --stat d0dbdf7..HEAD`.
- `elixir script/inventory_collection_assertions.exs --check` in the candidate: exit 0, "243 classified collection-assertion site(s), ledger matches the live tree exactly" (read-only).
- `.planning/workstreams/quality-ratchet-release/milestones/v25.0-closeout/debt-disposition.md`; phases 181/182/183 `*-REVIEW-DISPOSITION.md`, `181-REVIEW.md`, `183-CONTEXT.md` (deferred section).
- `.planning/seeds/SEED-014`, `SEED-018`, `SEED-023`; `.planning/research/v26/BRIEF.md` and `PITFALLS.md` (consistent: P-A probe, P-B measure/harness, P-C seam, P-D freeze).
- `.planning/PROJECT.md` (v23 0.2.11 publication and REL-10 status); `AGENTS.md`.
