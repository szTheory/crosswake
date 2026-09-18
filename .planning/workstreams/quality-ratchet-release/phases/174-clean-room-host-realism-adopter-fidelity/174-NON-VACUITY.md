# Phase 174 Non-Vacuity Record

This file is Phase 174's own evidence under the milestone's `vacuity_taxonomy` convention (see
[`VERIFICATION-CONVENTIONS.md`](../../VERIFICATION-CONVENTIONS.md)). The six shapes referenced
below (A–F) are defined at
[`../../../research/v23/PITFALLS.md`](../../../research/v23/PITFALLS.md) §"Pitfall 4" and are not
restated here, per the convention's link-never-copy rule. This document is the phase's evidence;
the `## Vacuity Taxonomy` section of `174-VERIFICATION.md` itself is authored at phase close by
the verification step and is not pre-empted here.

**Enumeration method.** The check set below is every new ExUnit `test` this phase's five sibling
plans (174-01 through 174-05) added, plus the one new mechanical shell guard (`manifest_contract
.byte_identity`) that is not itself an ExUnit test but is a distinct, independently invocable
check with its own exit-code contract. It was derived by running `git log --oneline` over each
plan's own commits (`d04397a4`/`9eea02ed`, `5a041ce0`/`1b1037b1`, `16851193`/`3de2bf47`/`414ad9fd`,
`700b806d`/`b612b59f`/`d77c1e14`, `5060314b`/`710b8578`/`ca3bd873`) and grepping each touched test
file for `test "`, cross-checked against every sibling SUMMARY's own accomplishments list — never
from memory. No new checker predicate was added to `script/check_release_workflow_integrity.exs`'s
`@roster_ids` by this phase (`git log --oneline b4ffa989 -- script/check_release_workflow_integrity.exs`
shows no phase-174 commit touching that file); the file's roster count referenced by 174-04's
SUMMARY (`73 of 73 roster checks`) is the pre-existing roster, unchanged in cardinality by this
phase.

**Row count: 7 rows**, listed in check-ID lexical order, covering **31 ExUnit tests + 1 mechanical
shell guard = 32 checks landed**, plus one deliberately-recorded unguarded measurement (finding A,
below the table, not counted as a landed check because no assertion for it exists on disk at all).

## Vacuity Taxonomy

| Check ID | Shape | Non-vacuity evidence (measured) |
|---|---|---|
| `Crosswake.Proof.Phase174CleanRoomHostRealismTest` (8 tests, 174-01) | A, mitigated | Predicate over a repository-relative real-run log — a runtime-derived, possibly-empty text collection. Mitigated by an explicit non-emptiness/cardinality gate (`"the declared marker roster has exactly nine entries"`) preceding the roster-in-log check. Measured: 8 tests, 0 failures on the real committed log (`evidence/174-legacy-rindle-local-run.log`, 1042 lines). Demonstrated red on four distinct mutations (174-01-SUMMARY.md): removing `"doctor"` from the literal `@markers` list (`expected the literal marker roster to have exactly nine entries, got 8`); stripping all `step=install` lines from a log copy (`missing == ["install"]`); passing `[]` as the log's lines (`missing == @markers`, all nine); reading a nonexistent evidence path (`assert_raise RuntimeError, ~r/evidence log not found/`). All four reverted to green. |
| `Crosswake.Proof.Phase174CleanRoomLaneParityTest` (6 tests, 174-04) | A, mitigated | Predicate over `release-please.yml`'s job list — a real-file-derived, possibly-empty collection. Mitigated by an explicit cardinality gate (`"exactly five jobs invoke the harness script"`) run before the roster-equality comparison, so a roster that shrank to zero could not compare accidentally-equal against another empty set. Measured: 6 tests, 0 failures on the real workflow files. Demonstrated red by deleting `clean-room-proof-rindle`'s job block from a fixture copy of `release-please.yml`: the equality check failed and named `crosswake_rindle` as the removed member (174-04-SUMMARY.md). A dedicated non-vacuity control test (`"an empty lane roster ... is never trivially equal"`) additionally proves an emptied roster cannot pass by accident. Reverted to green. |
| `Crosswake.Proof.Phase174CompanionFindingsTest` (7 tests, 174-05) | A, mitigated | Predicate over TODO-011's own failure table — a document-derived, possibly-empty roster. Mitigated by an explicit cardinality gate (`"TODO-011's failure table names exactly three companions"`) before filtering, plus a dedicated non-vacuity control (`"an empty roster is never trivially reported as findings-satisfied"`). Measured: 7 tests, 0 failures. Demonstrated red by mutating `check_findings_exist/2`'s body to an unconditional `{:ok, roster}`: the control test failed with a `match (=)` error and the reason (removed finding, sigra) was named in the assertion (174-05-SUMMARY.md). Reverted; `mix format --check-formatted` exit 0. |
| `Crosswake.Proof.Phase174ManifestContractImmutabilityTest` (5 tests, 174-02) | matches none of A-F, because it is a byte-identity comparison against a git-history-pinned fixed baseline, not a predicate over a possibly-empty runtime collection, a `needs:`/`if:`/matrix condition, or a shell exit-code-misuse idiom itself — the risk it guards against (an extraction that returns empty and compares equal to another empty extraction) is caught by its own internal non-emptiness assertion, not by this test's shape. | 5 tests, 0 failures, each invoking the real shell script via `System.cmd/3` (no Elixir re-implementation of the extraction rule). Demonstrated red against the real repository source for all four required failure modes plus one extra (174-02-SUMMARY.md's own measured table, reproduced here): unmodified tree → exit 0, `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`; one byte changed inside the function body → exit 4, `MANIFEST_CONTRACT_DEF_DRIFT`; function renamed → exit 3, `MANIFEST_CONTRACT_EXTRACTION_EMPTY`; call-site capture deleted → exit 3, `MANIFEST_CONTRACT_EXTRACTION_EMPTY`; empty source file → exit 3, `MANIFEST_CONTRACT_EXTRACTION_EMPTY`; call line reformatted with capture syntax intact → exit 5, `MANIFEST_CONTRACT_CALL_DRIFT` (this sixth mutation was run specifically to exercise the DRIFT path on its own, not merely as a mirror of the DEF-drift case). `doctor.ex` itself was never modified — every mutation ran against a `--source` override pointing at a throwaway copy. |
| `manifest_contract.byte_identity` (`script/assert_manifest_contract_unchanged.sh`, 174-02) | A, mitigated | The guard's own `grep -Ec`/`awk` extraction of a live source file is a possibly-empty-collection risk (a renamed or deleted function could otherwise extract empty on both sides and compare equal). Mitigated by an explicit non-emptiness-and-exact-occurrence-count assertion that runs before either byte-identity comparison. Measured directly this execution session: `bash script/assert_manifest_contract_unchanged.sh` → exit `0`, `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`, against the real, unmodified `lib/crosswake/doctor/doctor.ex`. |
| `Mix.Tasks.Crosswake.ProofLane.PhysicalIphoneTest` — the 5 tests added by 174-03 for `exit_status_for/1`/`handle_result/1` (`"a validated, complete, correctly-owned, correctly-ordered report with a non-passing outcome exits 1 and classifies as refuted"`, `"a failure where no validated report was produced exits 2 and classifies as could-not-run"`, `"a blocked readiness result exits 2 and classifies as could-not-run"`, `"a fully passing run produces no halt status"`, `"a rule id the classifier does not recognise falls through the explicit catch-all to could-not-run"`) | matches none of A-F, because it is an explicit `case` classifier's exhaustiveness proof over a closed rule-id vocabulary with an unconditional catch-all clause — a control-flow-completeness property, not a possibly-empty runtime collection, a `needs:`/`if:`/matrix condition, or a shell exit-code idiom. | TDD-demonstrated red-to-green, not a post-hoc mutation: the RED commit (`3de2bf47`) ran these 5 tests against `join_reports/3`'s pre-fix `Enum.map(expected, &Map.put(&1, :outcome, :passed))` completeness check and failed with `PI-REPORT-COMPLETE` where `PI-REPORT-OUTCOME` (exit 1) was expected — the classifier had nothing reachable to classify. The GREEN commit (`414ad9fd`) fixed the completeness comparison to `Map.take(&1, [:id, :owner])` and all 5 passed; a sixth, pre-existing test in `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs` that had asserted the old buggy `PI-REPORT-COMPLETE` outcome was updated to the corrected expectation in the same commit. Full `test/mix/tasks test/crosswake/proof_lane` suite: 219 tests, 0 failures after the fix. |
| `phase174_cleanroom_lane_parity_test.exs` — SC#4's `step=` marker-parity measurement over the captured CI logs | Finding (A): unguarded measurement, no shape assigned — recorded below the table, not as a landed check | See "Finding A" immediately below. |

## Finding A — the parity check does not guard the evidence logs; the SC#4 measurement is unguarded

`test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs` asserts roster parity between
`release-please.yml`'s `clean-room-proof-*` lane and the rehearsal workflow (the row above, with a
genuine fixture-based non-vacuity control). What it never does is read the captured CI logs that
`174-CLEANROOM-EVIDENCE.md`'s SC#4 section cites — `evidence/174-matrix-ci-run.log` and the
narrative `grep -c 'step='` counts quoted in that file are asserted by **nothing** on disk.

This was verified, not assumed, by the phase-close orchestrator: `evidence/174-matrix-ci-run.log`
was moved out of the tree, then separately truncated to zero bytes, and
`mix test test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs` reported **6 tests, 0
failures** in both cases. The `step=` marker roster and count that SC#4's verdict rests on — matrix
side: 6 distinct markers (`build`, `dry-run`, `generate`, `install-generator`, `normalize`,
`official-unpack`); legacy side: 9 distinct markers, recorded only as directional local-run context
— were measured by hand into `174-CLEANROOM-EVIDENCE.md` at authoring time and are re-derivable by
no automated check today.

**This is recorded here, not repaired here**, per this plan's own scope boundary
("if writing the record reveals a check that is vacuous, do not repair it here"). It is also
recorded as **deliberately not patched**, for a decidable reason: the legacy path's own CI log
(`evidence/174-rindle-ci-run.log`) cannot be captured until `clean-room-proof-rehearsal.yml` merges
to the default branch and the post-merge dispatch named in `174-CLEANROOM-EVIDENCE.md` is taken (see
ROOM-03's disposition below). A guard written against the log file that exists today (the matrix
log alone) would go red the moment the legacy log becomes available and needs a second roster
entered — or would need to be written twice, once now and once after the post-merge observation,
doubling the chance of the two entries drifting apart. Writing a guard now, before the pair it needs
to compare exists, would either assert a false completeness or fabricate the missing half — the
same class of error as faking a green result. The reason is recorded here so this gap reads as
"pending a real dependency," not "we forgot."

## Real-run observations this phase made

- **Rindle (legacy path, CI dispatch).** `gh workflow run clean-room-proof-rehearsal.yml --ref
  phase-174-clean-room-host-realism -f package=crosswake_rindle -f version=0.1.0 -f
  engine_package=rindle -f engine_module=Rindle` returned a verbatim `HTTP 404: workflow
  clean-room-proof-rehearsal.yml not found on the default branch`. No run id was ever created —
  there is no job-level conclusion to read, because there was no run. A search of the 60 most
  recent `release-please.yml` runs found every `clean-room-proof-*` job `skipped` in all of them,
  so no historical run exists to substitute. Full verbatim command, refusal text, and the exact
  post-merge command that closes this out are in
  [`174-CLEANROOM-EVIDENCE.md`](174-CLEANROOM-EVIDENCE.md).
- **Threadline (companion clean-room, local run).** `script/verify_companion_cleanroom.sh
  crosswake_threadline 0.1.0` against the live published package: exit 0, doctor-green, 4/4 smoke
  tests. Root cause of threadline's original CI failure named in
  [`174-FINDING-THREADLINE.md`](174-FINDING-THREADLINE.md): the pre-174-01 harness's routeless-router
  Step 4 was unconditional across every companion profile, so the `manifest_contract` failure
  TODO-011 root-caused for rindle would have reproduced identically for threadline; plan 174-01's
  fix (`d04397a4`) is likewise profile-independent.
- **Sigra (companion clean-room, local run).** `script/verify_companion_cleanroom.sh crosswake_sigra
  0.1.3` against the live published package (the same version that failed on 2026-08-09): exit 0,
  doctor-green, 4/4 smoke tests. Root cause named in
  [`174-FINDING-SIGRA.md`](174-FINDING-SIGRA.md): a distinct mechanism from threadline's — a
  package-unaware no-engine smoke-test template branch, reconstructed against pre-fix commit
  `d3e914da` and fixed at commit `d16e475a`.

## Deliberate non-actions, with reasons

1. **The matrix path was not given a `mix crosswake.install` step.** ROADMAP SC#2 names the legacy
   path specifically; the matrix path's ten profile runs sit on the pull-request critical path,
   where adding an installer invocation to every profile run would add real wall-clock cost to
   every PR for a realism gain ROADMAP does not ask for at this phase. This leaves ROOM-02's
   broader textual wording ("the clean-room host", not "the legacy clean-room host") partially
   open — see ROOM-02's disposition row below, which states plainly which wording the verdict is
   against rather than reading the narrower success criterion as the whole requirement.
2. **`release-please.yml`'s `clean-room-proof-*` lanes were not modified.** The rehearsal workflow
   (`clean-room-proof-rehearsal.yml`) is a second, independent door onto the same
   `script/verify_companion_cleanroom.sh` invocation; the release lane's jobs keep their `needs:
   publish-hex-*` ordering guarantee byte-for-byte (`git diff --name-only HEAD --
   .github/workflows/release-please.yml` is empty across every plan in this phase).
3. **`doctor` was not touched.** `git diff --stat d04397a4~1..HEAD -- lib/crosswake/doctor/doctor.ex`
   prints nothing across the entire phase — verified directly, this session, spanning every commit
   from before 174-01 through the current tree. `script/assert_manifest_contract_unchanged.sh`'s
   `MANIFEST_CONTRACT_UNCHANGED_VERIFIED` exit-0 result (re-confirmed this session) is the evidence
   behind this non-action, not an assertion made about it.
4. **CW-REQ-A's breaking contract bump was deferred, not landed.** Recorded in full in
   `174-FID-01-DISPOSITION.md` and reflected in FID-01's disposition row below; not restated here
   beyond the pointer, per the link-never-copy discipline this convention itself asks for.

## Per-requirement disposition

Seven rows, one per phase requirement. Every row carries an explicit **satisfied** or **not
satisfied** verdict and names the artifact, run id, or check that decides it — no third verdict, no
blank.

**Preamble note on ROOM-02's wording.** `REQUIREMENTS.md`'s text for ROOM-02 reads "The clean-room
host runs `mix crosswake.install` before `doctor`" — singular, unscoped to a specific path. ROADMAP's
own Success Criterion 2 for this phase names the **legacy** path specifically. This phase changed
only the legacy path (deliberate non-action #1, above); the matrix path was not extended. The
verdict below is against **ROADMAP SC#2's narrower wording** (the legacy path), stated as such —
not against the requirement text's broader, unscoped phrasing, which remains partially open for
the matrix path.

| Requirement | Verdict | Deciding artifact / run |
|---|---|---|
| **ROOM-01** — the clean-room host declares a real Crosswake route with capability metadata before `doctor` runs | **Satisfied** | `script/verify_companion_cleanroom.sh` Step 4 (real `CleanRoomHost.Router` route with `metadata: %{crosswake: [id:, runtime:, offline:, security:]}`) + `evidence/174-legacy-rindle-local-run.log` (real run, exit 0) + `Crosswake.Proof.Phase174CleanRoomHostRealismTest` (8 tests, 0 failures), commits `d04397a4`/`9eea02ed`. |
| **ROOM-02** — the clean-room host runs `mix crosswake.install` before `doctor` | **Satisfied against ROADMAP SC#2's legacy-path wording** (see preamble note above; the requirement's broader unscoped wording is not fully closed) | `script/verify_companion_cleanroom.sh` new Step 6.5 + `evidence/174-legacy-rindle-local-run.log`'s `Crosswake install complete for clean_room_crosswake_rindle` line, commit `d04397a4`. |
| **ROOM-03** — `clean-room-proof-rindle` passes against the live published `crosswake_rindle 0.1.0` (in CI) | **NOT satisfied** | `174-CLEANROOM-EVIDENCE.md` SC#3 section: `gh workflow run clean-room-proof-rehearsal.yml --ref phase-174-clean-room-host-realism ...` returned verbatim `HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default branch`; no run id was created. Closes with: merge this phase's PR to `main`, then `gh workflow run clean-room-proof-rehearsal.yml --ref main -f package=crosswake_rindle -f version=0.1.0 -f engine_package=rindle -f engine_module=Rindle`, then read the job-level (not run-level) conclusion via `gh run view <run-id> --json jobs --jq '.jobs[] | {name, conclusion}'` and update `174-CLEANROOM-EVIDENCE.md`'s SC#3 section with the result. |
| **ROOM-04** — the legacy positional path's logging reaches grep-able parity with the matrix path's `step=` markers | **Satisfied on the requirement's own terms** (the legacy path emits nine declared, grep-able `step=` markers) — the more specific SC#4 CI-log-to-CI-log comparison this phase attempted is **PARTIALLY MEASURED**, and the measurement itself is an unguarded check (Finding A, above) | `LEGACY_STEP_MARKERS` (nine names) + `legacy_step_marker()` in `script/verify_companion_cleanroom.sh`, commit `d04397a4`; roster-in-log completeness asserted by `Crosswake.Proof.Phase174CleanRoomHostRealismTest` (8 tests, 0 failures) against the real committed log. `174-CLEANROOM-EVIDENCE.md` SC#4 section records the matrix side from a real captured CI log (6 markers) and the legacy side only from a local run (9 markers, informal comparison only, not counted toward the criterion's stated method); the legacy CI-log side is pending the same ROOM-03 post-merge dispatch. |
| **ROOM-05** — the threadline and sigra clean-room failures are diagnosed as separate findings with their own recorded root causes | **Satisfied** | `174-FINDING-THREADLINE.md` (mechanism: pre-174-01 unconditional routeless-router Step 4) + `174-FINDING-SIGRA.md` (mechanism: package-unaware no-engine smoke-test template branch, fixed at `d16e475a`) — two distinct, git-cited mechanisms, each resting on a real local run this phase took (785-line and 573-line logs, both exit 0, doctor-green). `Crosswake.Proof.Phase174CompanionFindingsTest` (7 tests, 0 failures) mechanically checks both findings exist and are not byte-identical, rostered from TODO-011 rather than the findings directory. |
| **ROOM-06** — `doctor`'s `manifest_contract` check is unchanged in strength; the harness was fixed, not the contract | **Satisfied** | `script/assert_manifest_contract_unchanged.sh` (re-run this session: exit 0, `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`) + `test/support/fixtures/phase174/manifest_contract_baseline.txt` (pinned to commit `8bc77c35157e78da0a6a8b06301cfac48f5dc301`) + `Crosswake.Proof.Phase174ManifestContractImmutabilityTest` (5 tests, 0 failures, four demonstrated failure modes) + `git diff --stat d04397a4~1..HEAD -- lib/crosswake/doctor/doctor.ex` (empty across the entire phase). |
| **FID-01** — SEED-014's two high-severity adopter gaps (CW-REQ-A, CW-REQ-B) are closed or explicitly deferred with a recorded reason | **Satisfied** | `174-FID-01-DISPOSITION.md`: CW-REQ-A `defer-with-reason` (commit `16851193`, `git diff --name-only HEAD -- lib/` empty for that commit) with a stated reopen trigger (after Phase 175 publishes); CW-REQ-B closed (`exit_status_for/1`/`handle_result/1`, commits `3de2bf47` RED / `414ad9fd` GREEN, 5 tests, 0 failures) plus the `join_reports/3` bug fix that made the outcome rule reachable at all. |

## Overall verification, re-run this session

- `bash script/assert_manifest_contract_unchanged.sh` → exit `0`, `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`.
- `mix test test/crosswake/proof --max-cases 1` (unpiped, exit code read directly) → `729 tests, 0
  failures (67 excluded)`. This is the corrected count after `b4ffa989` fixed the 9-test regression
  named in Finding (B) below — the pre-fix count was `729 tests, 9 failures`.
- `git diff --name-only d04397a4~1..HEAD -- lib/crosswake/doctor/doctor.ex` → empty.

## Finding B — a 9-test regression was introduced by this phase and initially recorded as pre-existing

Plan 174-04 added `.github/workflows/clean-room-proof-rehearsal.yml` with a job `name:` containing
`${{ inputs.package }}@${{ inputs.version }}` — an expression-bearing display name. This repository's
CI leaf-manifest policy (`script/check_ci_leaf_manifest.py`) forbids an expression-bearing display
name on any workflow that could become a required check, because a required check whose name varies
per run cannot be bound to a stable branch-protection context. The new file broke 9 CI-workflow-policy
tests spanning Phase 135/153/164/165/166/169.

Plan 174-05 reproduced the 9 failures at commit `bdc216b6` — 174-04's own tip commit, which already
contained the new workflow — and recorded them as **pre-existing**, having correctly named the new
workflow as the most plausible cause without pursuing it further (per its own stated scope boundary).
The baseline it checked against already contained the defect it was trying to rule out as a cause.

The phase-close orchestrator settled it with a control run: removing only
`.github/workflows/clean-room-proof-rehearsal.yml` from the working tree took the suite from 9
failures to 4, and those 4 were plan 174-04's own `Crosswake.Proof.Phase174CleanRoomLaneParityTest`
correctly going red at the absence of the workflow it polices. All 9 policy failures trace to the one
new file. Fixed in commit `b4ffa989`: the job's `name:` is now the stable literal `Clean-room proof
rehearsal`; package and version remain visible via the step's `REHEARSAL_PACKAGE`/`REHEARSAL_VERSION`
env vars. The policy test itself was **not** modified. Full record: `deferred-items.md`'s "RESOLVED"
section.

This belongs in the taxonomy because it is the workstream's central defect in mirror image. "Absence
scored as success" is a check green while asserting nothing; here a check went correctly **red** and
was reclassified as **inherited** — the same net effect, a true signal discarded, reached from the
opposite direction. It survived plan-level verification because plan 174-05's own verification asked
whether the suite passed at a chosen baseline commit, not whether that baseline commit was itself
already contaminated by the change under test. **The lesson recorded here for later phases:** a
plan's verification must run the suite its own artifacts can affect, not only the files it authored,
and a "pre-existing at commit X" claim needs X to actually predate the change being investigated, not
merely predate the investigating plan's own commits.

## Finding C — ROOM-03 and the legacy half of SC#4 are genuinely NOT SATISFIED

Restated plainly, because a phase record that let this read as complete would be exactly the defect
this convention exists to prevent: `gh workflow run` returned `HTTP 404: workflow
clean-room-proof-rehearsal.yml not found on the default branch`; `gh run list
--workflow=release-please.yml --limit 60` showed every `clean-room-proof-*` job `skipped` across all
60 inspected runs, so there is no historical run to substitute. No `evidence/174-rindle-ci-run.log`
was fabricated to paper over this. ROOM-03 carries an explicit **NOT SATISFIED** disposition above,
naming the exact post-merge command that closes it — this phase does not read as complete on that
requirement, and it is not.


## Post-Merge Update (2026-09-18) — Findings A and C are closed by observation

**Finding C (ROOM-03 / SC#4 not satisfied) is CLOSED.** PR #184 merged as `bb570820`, putting
`clean-room-proof-rehearsal.yml` on the default branch. The dispatch that returned
`HTTP 404: workflow clean-room-proof-rehearsal.yml not found on the default branch` throughout
the phase then succeeded: run `35366337182`, job `Clean-room proof rehearsal`, conclusion
`success`, against the live published `crosswake_rindle 0.1.0`. Log captured to
`evidence/174-rindle-ci-run.log`. SC#4's legacy-side CI log exists as a result, and the parity
measurement is now made the required way — from two captured CI logs — at 9 legacy markers
versus 6 matrix markers.

**Finding A (the SC#4 marker measurement is unguarded) REMAINS OPEN, and its reason has changed.**
During the phase it was unguarded because the legacy log could not be captured, so a guard would
have gone red over an un-completable measurement. That justification has now expired: both logs
exist and the comparison is mechanically checkable. The taxonomy entry keeps its escape form, but
the reason is no longer "cannot be measured" — it is "can now be measured and has not yet been
wired into a test."

Concretely, what would close Finding A: extend `phase174_cleanroom_lane_parity_test.exs` to read
both `evidence/174-rindle-ci-run.log` and `evidence/174-matrix-ci-run.log`, assert each carries a
non-zero `step=` marker count BEFORE comparing them (so an absent or truncated log fails loudly
rather than comparing 0 against 0), and assert legacy count >= matrix count. The non-vacuity
control is already known to be needed: moving either log out of the tree, or truncating it to
zero bytes, currently leaves that suite at 6 tests / 0 failures.

This is recorded as carried-forward work rather than done, because doing it is a code change
outside this closure's scope. It must not be described as satisfied.
