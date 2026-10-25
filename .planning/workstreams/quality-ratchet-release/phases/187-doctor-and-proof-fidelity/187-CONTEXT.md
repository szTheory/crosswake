# Phase 187: Doctor and proof fidelity - Context

**Gathered:** 2026-10-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Doctor and proof evidence tell a maintainer exactly what is wrong and where it came from, and the deferred first-adopter requests are recorded so they are not argued again. Four requirements: DOCTOR-01 (structured `unmanaged_routes` details, CW-REQ-E), DOCTOR-02 (offline-island filter hole and an honest "not claimed", CW-REQ-F), DOCTOR-03 (real provenance in `verify_navigation_shell`, all-zero commit rejected, CW-REQ-C), DOCTOR-04 (CW-REQ-A and CW-REQ-D deferral records).

Product edits happen only in the candidate `/private/tmp/crosswake-phase180-impl` on top of `bd294007` (`fix(186)`), left uncommitted until the phase's final commit plan, exactly as in Phases 185 and 186. Planning files in the recovery checkout stay plain uncommitted files. Phase 188 freezes the candidate and changes no code, so everything this phase needs must land here.

Out of the boundary: the compile-time `Policy.Route` rule (deferred, D-12), widening the offline check beyond `:offline_island` (D-09), any `PhysicalIphoneContract` vocabulary change (CW-REQ-A, deferred), any Swift template change (CW-REQ-D, deferred), new CI lanes, new dependencies.

</domain>

<decisions>
## Implementation Decisions

All three areas were researched in parallel (advisor mode, minimal-decisive tier) with the owner's fan-out brief; the owner asked for the synthesized recommendations to be followed without per-area questions. Research decisions C1, C8 and C14 from `.planning/research/v26/SUMMARY.md` are carried forward unchanged.

### Provenance (DOCTOR-03)
- **D-01:** Real values replace every placeholder in `Mix.Tasks.Crosswake.ProofLane.VerifyNavigationShell.evidence_input/1`:
  - `crosswake_version` comes from `Application.spec(:crosswake, :vsn)`, converted to a string.
  - `template_version` comes from the host's generated-shell manifest when it is present and valid. Otherwise it is `Mix.Tasks.Crosswake.Gen.Shell.template_version/0` (the real generator constant; the hardcoded "161" is wrong, not just a placeholder). Otherwise it is the sentinel.
  - `commit_ref` is `git-<hex>` from the host project's `git rev-parse HEAD`. The host commit is what the proof verified; the crosswake dependency revision is out of scope because `crosswake_version` already identifies the library.
  - `device_class` stays `:unknown`, the only truthful value for an advisory run that touches no device. It is never inferred from the host OS.
- **D-02:** The validator in `lib/crosswake/proof_lane/evidence.ex` accepts only a closed set of explicit sentinels, by exact match: `commit_ref: "git-unknown"`, `crosswake_version: "unknown"` and `template_version: "unknown"`. Every other value must still be in real format. `git-` followed by 40 or 64 zeros is rejected with `PL-EVIDENCE-COMMIT`. There are no entropy or repeated-digit heuristics; the requirement names the all-zero hash. — **Reversibility:** costly — the sentinel strings become part of the evidence JSON that adopters may record in ledgers; renaming them later breaks stored evidence and consumers.
- **D-03:** Evidence that carries any sentinel is still written, so the advisory lane works for hosts with no `.git`, such as tarballs or Docker CI. It is never promotable and never counts as proof.
  - A provenance predicate in `evidence.ex` (e.g. `provenance_known?/1`) is the single rule.
  - `:physical_iphone` evidence with any sentinel is rejected at validation.
  - Promotion to the physical destination refuses sentinel evidence.
  - No other gate is wired up in this phase; existing consumers only call the same predicate.
- **D-04:** A dirty host working tree yields `git-unknown`, because a HEAD that does not describe the verified code is a wrong value that looks real. There is no new schema field. Check tracked files only (e.g. `git status --porcelain --untracked-files=no`), so untracked build output does not erase the commit. The planner confirms the exact flag.
- **D-05:** Read git by running the binary directly: `System.find_executable("git")` plus `System.cmd/3`, with no shell, fixed arguments and the host project as the working directory. Any missing executable, non-zero exit or output that does not match `^[0-9a-f]{40}([0-9a-f]{24})?$` becomes the sentinel. Do not parse `.git` files (packed refs, worktrees and reftable make that fragile). Never log git's stderr, branch names, remotes, author data or paths.
- **D-06:** Negative fixtures prove the phase:
  - an all-zero commit is rejected;
  - a sentinel is accepted for advisory evidence but blocked for `:physical_iphone` and for promotion;
  - a directory with no `.git` yields `git-unknown`;
  - a dirty tracked tree yields `git-unknown`;
  - the task source no longer contains `"0.1.0"`, `"161"` or the all-zero ref.

### Offline posture (DOCTOR-02)
- **D-07:** Every route with `runtime: :offline_island`, `offline: :local_first` and no `island_contract` produces an `:error` finding.
  - It reuses the existing `offline_posture_incomplete` code and `:incomplete` status, and adds `incoherent_routes: [sorted route ids]` to the details.
  - The check is evaluated over all manifest routes, before the existing cache/island contract filter.
  - `:error` matches how doctor already treats an incoherent posture: the hole hid an error, not a warning. A warning would let an unbacked offline claim pass CI.
  - The doctor mix task exits non-zero on this finding, which is intended.
- **D-08:** When no route has `offline != :unavailable`, `offline.status` is `:not_claimed` (JSON `"not_claimed"`) and doctor emits an advisory `offline_posture_not_claimed` finding (exit 0).
  - The atom already exists for `support.status` (`finding_policy.ex:7`), so no new vocabulary is introduced.
  - The `states`, `telemetry` and `routes` keys stay present (`routes` is empty), so the JSON shape is stable.
  - The message says no routes declare offline behavior; the hint says cached read-only is not local mutation.
  - Add a CHANGELOG/guide line saying `offline.status` can now be `"not_claimed"`.
- **D-09:** Do not widen the check to every route with `offline != :unavailable` (C8 holds). Known gaps, recorded and not fixed:
  - `:cached_read_only` without a `cache_contract` is not a compile-time error (`Policy.Route` only checks contract ⇒ mode) and stays filtered.
  - A non-`:offline_island` runtime claiming `:local_first` without a contract stays unchecked unless `Policy.Route` rejects it; the planner confirms which.
  - Both go into the deferral record with D-12's triggers.

### Unmanaged routes (DOCTOR-01)
- **D-10:** The `unmanaged_routes` check at `doctor.ex` ~383 passes `details: %{unmanaged_paths: Enum.uniq(paths) |> Enum.sort(), router: inspect(module)}`. `Policy.Warning` already carries `unmanaged_paths` and `module`. `inspect/1` drops the `Elixir.` prefix, sorting makes the output deterministic for CI diffs, and a `nil` module stays `nil`. A test asserts the JSON output of `mix crosswake.doctor --format json`.
- **D-11:** Tests use synthetic route paths only, such as `/public`, never adopter paths. The guide gains two lines: `--router` accepts any module exporting `__routes__/0`, and doctor JSON contains the host's route patterns, so it should not be pasted into public issues.

### Deferrals (DOCTOR-02 compile-time rule, DOCTOR-04)
- **D-12:** The compile-time `Policy.Route` rule for `:local_first` without `island_contract` is deferred, and doctor is the single enforcement point. Reopen when any one of these holds:
  - (a) a second `:local_first` runtime or route family exists besides `:offline_island`;
  - (b) a host route ships with `:local_first` and no `island_contract` although doctor ran;
  - (c) the first adopter's physical-iPhone proof shows doctor is not run before a build.
- **D-13:** The canonical record is a new `187-DEFERRALS.md` in this phase directory. It uses the 174-FID-01 bullet schema (Disposition, Decided, Reason, Evidence, Reopen trigger, Date, Evidence of no source change, Recorded also in) for CW-REQ-A, CW-REQ-D and the D-12 compile-time rule, and lists the D-09 gaps. Pointers, without copying the evidence:
  - a dated Phase 187 disposition paragraph in the CW-REQ-A and CW-REQ-D sections of `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md` in the recovery checkout;
  - the `REQUIREMENTS.md` "Future Requirements (deferred)" rows rewritten to the triggers below, with a "see 187-DEFERRALS.md" pointer, which removes the wording drift between the seed and requirements.
  — **Reversibility:** reversible.
- **D-14:** CW-REQ-A records both readings of its Phase 174 trigger ("after Phase 175 publishes") and defers under either:
  - **Reading 1, met:** core 0.2.11 completed an ordinary three-registry publication with a six-child COMPLETE rollup, and chimeway 0.1.2 published (`milestones/v23.0-MILESTONE-AUDIT.md`).
  - **Reading 2, only qualifiedly met:** Phase 175 closed with REL-10 BREACHED (`closeout_disposition: accepted_historical_breach_requires_qualified_archive`), 8/9 for the phase and 42/43 for the milestone. The breach is a first-publish timing and ancestry limit that no later publish can repair.
  - **Verdict, defer either way:** the change is breaking, because `validate_report/1` and `join_reports/3` require an exact, ordered id set, so producers on the current 19 ids would be hard-rejected. The first adopter is not blocked, since it runs its own haptics gate. The physical-iPhone run is parked, and v26 removes silent weakness rather than widening vocabulary. The stop-list argument is secondary and weak, because the ADR has no haptics entry.
  - Use the candidate's real numbers: `@schema_version 2`, 19 assertions, a 2→3 bump if reopened. The seed's "20" is stale.
  - Reopen when any one of these holds:
    - (a) a planned release deliberately breaks the proof-lane contract, with its pipeline already proven by an earlier ordinary publish;
    - (b) the first adopter asks to retire its own haptics gate;
    - (c) the physical-iPhone run resumes under `first-b2c-adopter-readiness`.
  - Reopening is a new requirement, never a drive-by edit.
- **D-15:** CW-REQ-D (the `Text("Route: \(routeID)")` line at `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/RouteUnavailableView.swift:29-30`, plus the example copy) is deferred. Reopen when any one of these holds:
  - (a) a diff touches the shell-core Swift sources or generated template sources and already changes the template version;
  - (b) the first adopter adopts the shipped `RouteUnavailableView`.
  - If it is reopened, drop only the `Route:` line and keep `routeID` on `RouteDenialPresentation`.
  - No v26 phase touches Swift, so it has not fired.
- **D-16:** There is no new test or CI lane for the deferral records; a one-time reconciliation stays in phase evidence, per AGENTS.md. Verification instead checks the structure of the record:
  - `187-DEFERRALS.md` exists, has two reading rows for CW-REQ-A and has triggers for A, D and the compile-time rule;
  - SEED-014 and `REQUIREMENTS.md` point to it;
  - the phase diff does not touch `physical_iphone_contract.ex` or any Swift source.
- **D-17:** Only the codename "first adopter" appears in any record. No identifying detail.

### Phase mechanics (carried from 185/186)
- **D-18:** The phase follows the 185/186 shape:
  - Product edits stay uncommitted in the candidate until a final commit plan runs the full suite and makes one `fix(187)` commit with an explicit path allowlist.
  - The full-suite failure set must equal the Phase 186 baseline (only `phase180_twin_feasibility_test.exs:30`).
  - A mutation log proves each new guard: all-zero rejection, the sentinel promotion block, the filter-hole error, the not-claimed status and the unmanaged details.
  - The post-commit probe, the history manifest and the home-path scan are re-run.
  - Nothing is pushed, and no twin, Simulator or twin-05 runs.
- **D-19:** The repair for 186 review WR-01 (refuse an unreadable Info.plist in the physical-iPhone preflight) is not folded in; it stays the owner's open decision and is outside DOCTOR-01..04. Fix 186 WR-03 (the harness `--evidence ""` and bare `--evidence`) before Phase 188 uses the harness. Whether 187 carries that fix is the planner's call: it is small and makes 188 safer, but it is outside DOCTOR scope. If it is folded in, record it as a deviation.

### Claude's Discretion
- Exact function names, such as `provenance_known?/1` and the git helper module or placement.
- How the host generated-shell manifest's `template_version` is located and validated.
- Plan split and wave order, with doctor edits (DOCTOR-01/02) and provenance edits (DOCTOR-03) touching disjoint files; DOCTOR-04 is planning files only.
- Formatter text for the new `not_claimed` status.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and decisions
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: DOCTOR-01..04 and the "Future Requirements (deferred)" table (lines ~99-110).
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` (Phase 187): goal and the four success criteria.
- `.planning/research/v26/SUMMARY.md`: decisions C1, C8 and C14; risks "Doctor churn" and "status atoms allowed".
- `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md`: CW-REQ-A, C, D, E and F asks (identical copies in the recovery checkout and the candidate).
- `AGENTS.md`: fail closed, flag silent degrade, honest offline claims, sensitive-data rules, checkout rule.

### Deferral precedent and evidence
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-phases/174-clean-room-host-realism-adopter-fidelity/174-FID-01-DISPOSITION.md`: the bullet schema to reuse.
- `.planning/workstreams/quality-ratchet-release/milestones/v23.0-MILESTONE-AUDIT.md`: Phase 175 publication and the REL-10 breach (both CW-REQ-A readings).
- `.planning/workstreams/quality-ratchet-release/MILESTONES.md` (~line 77): Phase 175 archived with SC-1 breached.
- `.planning/research/v26/FEATURES.md` (DEF-A): the breach described as a timing and ancestry limit.
- `.planning/ADR-FIRST-B2C-ADOPTER.md`: no haptics stop-list entry (a secondary point only).

### Code (candidate `/private/tmp/crosswake-phase180-impl`)
- `lib/mix/tasks/crosswake.proof_lane.verify_navigation_shell.ex` (`evidence_input/1`, ~101-117): placeholder provenance.
- `lib/crosswake/proof_lane/evidence.ex` (`valid_versions/1`, `git_ref/1` ~271, `promotion_class/2`, `@device_classes`): the validator.
- `lib/mix/tasks/crosswake.gen.shell.ex` (`template_version/0` at line 44; manifest writes ~729/895): template version source.
- `lib/crosswake/doctor/doctor.ex` (`compile_and_validate_manifest/2` ~375-390; `phase_4_posture/1` ~464-530; `check/6` ~2033; report status ~213).
- `lib/crosswake/doctor/finding_policy.ex` (line 7 and line 44): existing `:not_claimed`.
- `lib/mix/tasks/crosswake.doctor.ex` (~57): raises only on `:error`.
- `lib/crosswake/policy/route.ex` (`validate_offline_contracts/1` ~115-135): the existing contract ⇒ mode rules.
- `lib/crosswake/policy/warning.ex`, `lib/crosswake/policy/compiler.ex` (~75): `unmanaged_paths` and `module`.
- `lib/crosswake/doctor/formatter.ex` (~210-225): human `offline posture:` line.
- `lib/crosswake/proof_lane/physical_iphone_contract.ex` (`@schema_version 2`, 19 ids): must not change.
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/RouteUnavailableView.swift:29-30`: must not change.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FindingPolicy.support_claim(:not_claimed)` shows the pattern for an advisory not-claimed finding.
- `Policy.Warning{unmanaged_paths, module}` already holds DOCTOR-01's data; doctor just drops it.
- `Mix.Tasks.Crosswake.Gen.Shell.template_version/0` is a public, single source for the generator version.
- `ShellPackage.display_location/2` (Phase 186) is the path-redaction helper if any path ever reaches output.

### Established Patterns
- `check(severity, code, check_name, message, hint, details)`: details maps use snake_case keys; `policy_compile_failed` already passes structured details.
- Report status is `:error` only when a finding has severity `:error`; warnings and advisories exit 0.
- The evidence validator returns `error("PL-EVIDENCE-…", path, hint)` tuples; add new rules in that style.

### Churn (measured by research)
- 4 tests assert `offline.status == :supported`: `doctor_test.exs:138` and `:307`, `crosswake_doctor_test.exs:152`, `offline/proof_lane_test.exs:33`. All use fixtures with real offline routes and should stay green.
- 0 tests assert the `offline_posture_*` codes or `unmanaged_routes` details.
- The planner still re-runs `test/crosswake/doctor` and `test/mix/tasks` to catch fixtures with no offline routes, which now report `not_claimed`.

### Integration Points
- The JSON output of `mix crosswake.doctor --format json`, read by adopters' CI.
- Proof-lane evidence files and physical-iPhone promotion.

</code_context>

<specifics>
## Specific Ideas

- The owner's brief: fan out across stakeholder lenses, run an adversarial pass, synthesize one coherent recommendation set and follow it.
- "Another copy and paste is better than another dep": no new dependencies; git is invoked directly, never through a library.
- Precedent from SLSA and in-toto, recalled from memory and not fetched: an unknown provenance field is marked unknown or omitted, never filled with a fake digest.

</specifics>

<deferred>
## Deferred Ideas

- The compile-time `Policy.Route` rule for `:local_first` without `island_contract` (D-12).
- `:cached_read_only` without `cache_contract`, and non-`:offline_island` `:local_first` claims (D-09 known gaps).
- The CW-REQ-A haptics assertion (`PhysicalIphoneContract` 2→3) (D-14).
- CW-REQ-D: `RouteUnavailableView` debug line and platform defaults (D-15).
- 186 review WR-01 (unreadable Info.plist refusal): the owner's decision, the next preflight change.
- A durable tripwire test pinning the `PhysicalIphoneContract` version to the deferral record: considered and rejected for now (D-16).

</deferred>

---

*Phase: 187-doctor-and-proof-fidelity*
*Context gathered: 2026-10-16*
