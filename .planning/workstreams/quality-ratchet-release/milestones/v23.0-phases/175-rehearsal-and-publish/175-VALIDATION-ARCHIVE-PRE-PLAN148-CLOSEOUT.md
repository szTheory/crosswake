---
phase: "175"
slug: "rehearsal-and-publish"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-04"
---

# Phase 175 — Validation Strategy

> Focused validation contract for the proposed local follow-up to Plan 175-78's missing scanner input. This is a plan-time strategy; no command below has been run in this follow-up.

## Scope and evidence boundary

Validate the existing `script/release_candidate/assert_candidate_receipt_artifact.sh` against the scanner's expected exact roster and the existing regression cases. Track that source unchanged only if it satisfies the established contract. Then rerun the workflow-integrity scanner and only the previously blocked scanner-dependent local suite. Refresh Windows entry 36 and the affected matrix cells only when the corresponding checks provide evidence.

If source review or a check fails, stop at that boundary. Leave affected claims UNKNOWN. This validation does not authorize edits to publisher workflows or final guards, remote/provider access, CI reruns, merge, Gate 2, recovery, registry mutation, or publication. Plans 175-45 through 175-48 remain held; REL-13 and REL-17 remain OPEN; the release hold remains ACTIVE.

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | ExUnit plus the repository's Elixir workflow-integrity scanner |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Focused helper regression command** | `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1` |
| **Workflow scanner command** | `elixir script/check_release_workflow_integrity.exs` |
| **Previously blocked scanner-dependent suite** | `MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_rel17_publish_paths_test.exs test/crosswake/proof/phase175_rel17_recovery_paths_test.exs test/crosswake/proof/phase175_rel17_wiring_test.exs test/crosswake/proof/phase175_rel17_condition_paths_test.exs --max-cases 1` |
| **Estimated runtime** | Not measured; use only these focused local commands. |

## Sampling Rate

- First run the exact-roster regression module before tracking the helper.
- After tracking the unchanged helper, run the workflow-integrity scanner and the specified scanner-dependent suite.
- After Task3 updates the matrix contract and evidence text, rerun the same five-module suite. Only if it passes, mark Windows entry 36 fixed and verify the entry plus recomputed counts from a fresh read-only status response.
- Do not run the full repository suite for this bounded reconciliation.
- **Max feedback latency:** Not measured; record observed command durations in the execution summary if useful.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Fails When | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|------------|-------------|--------|
| 175-79-01 | 79 | 1 | REL-17 | T-175-79-01 | The untracked helper bytes match the planning-time candidate SHA-256 before any behavior test runs. | SHA-256 source assertion | `set -o pipefail; shasum -a 256 script/release_candidate/assert_candidate_receipt_artifact.sh \| awk '{print $1}' \| grep -Fx 'c6a00962180f740a12e73e48050f188c8b764d9403d957bfa925f9a21f1a820d'` | Nonzero pipeline exit or the current helper's SHA-256 output differs from the planning-time candidate digest. | Existing helper source | ⬜ pending |
| 175-79-01 | 79 | 1 | REL-17 | T-175-79-01 | Only the exact three-file roster is accepted; missing, extra, nested, and symlinked entries are rejected. Track the helper only after the focused behavior cases pass and source review confirms no behavior change. | ExUnit helper behavior + source inspection | `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1` | Nonzero exit, any of the five existing cases fails or is skipped, or source review finds a roster/type contract divergence. | Existing regression module | ⬜ pending |
| 175-79-02 | 79 | 1 | REL-17 | T-175-79-01 | After tracking, the current helper retains the planned SHA-256 and its worktree blob ID matches the staged index blob ID before the scanner runs. | SHA-256 + Git blob assertion | `set -o pipefail; test "$(shasum -a 256 script/release_candidate/assert_candidate_receipt_artifact.sh \| awk '{print $1}')" = c6a00962180f740a12e73e48050f188c8b764d9403d957bfa925f9a21f1a820d && test "$(git hash-object script/release_candidate/assert_candidate_receipt_artifact.sh)" = "$(git rev-parse :script/release_candidate/assert_candidate_receipt_artifact.sh)"` | Nonzero exit, worktree SHA-256 differs from the candidate digest, or worktree and staged-index Git blob IDs differ. | Tracked helper source | ⬜ pending |
| 175-79-02 | 79 | 1 | REL-17 | T-175-79-02 | Scanner assertions and the previously blocked publisher-path suite pass with the helper available; update only claims directly supported by those outputs and preserve all unrelated UNKNOWN cells. | Workflow-integrity scanner | `elixir script/check_release_workflow_integrity.exs` | Nonzero exit or a declared release.rel17 guard check is missing, reports FAIL, or lacks the scanner's successful structural result. | Existing scanner | ⬜ pending |
| 175-79-02 | 79 | 1 | REL-17 | T-175-79-02 | The scanner-dependent publisher-path suite exits successfully; any unrelated or remaining failing assertion leaves its affected matrix claim UNKNOWN. | ExUnit integration | `MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_rel17_publish_paths_test.exs test/crosswake/proof/phase175_rel17_recovery_paths_test.exs test/crosswake/proof/phase175_rel17_wiring_test.exs test/crosswake/proof/phase175_rel17_condition_paths_test.exs --max-cases 1` | Nonzero exit, any named test fails or is skipped, or a named scanner assertion/mutation does not produce its expected result. | Existing test modules | ⬜ pending |
| 175-79-03 | 79 | 1 | REL-17 | T-175-79-02 | The matrix contract suite passes against the updated workflow presence/order references before entry 36 is fixed; a failure restores matrix/test cells to UNKNOWN and leaves entry 36 open. | Post-update ExUnit matrix contract | `MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/proof/phase175_rel17_publish_paths_test.exs test/crosswake/proof/phase175_rel17_recovery_paths_test.exs test/crosswake/proof/phase175_rel17_wiring_test.exs test/crosswake/proof/phase175_rel17_condition_paths_test.exs --max-cases 1` | Nonzero exit, any named test fails or is skipped, the matrix differs from the passing named assertions, an unsupported cell is promoted, a release hold changes, or final_guard_execution is not UNKNOWN. | Existing test modules and REL-17 matrix | ⬜ pending |
| 175-79-03 | 79 | 1 | REL-17 | T-175-79-02 | A read-only ledger status response shows entry 36 fixed and dynamically recomputed counts equal the current ledger's stored counts. | Read-only ledger count assertion | `set -o pipefail; gsd_run windows status --raw \| node -e 'let input="";process.stdin.setEncoding("utf8");process.stdin.on("data",chunk=>input+=chunk);process.stdin.on("end",()=>{const response=JSON.parse(input);const ledger=response.ledger;if(response.ok!==true||!ledger||!Array.isArray(ledger.entries))throw new Error("invalid windows status response");const entry=ledger.entries.find(item=>item.id===36);if(!entry||entry.status!=="fixed")throw new Error("WINDOWS.md entry 36 is not fixed");const actual={open:0,fixed:0,waived:0};for(const item of ledger.entries){if(!["open","fixed","waived"].includes(item.status))throw new Error("unknown ledger status");actual[item.status]++;}for(const key of Object.keys(actual)){if(ledger[`${key}_count`]!==actual[key])throw new Error(`${key}_count mismatch`);}if(ledger.total_count!==ledger.entries.length)throw new Error("total_count mismatch");process.stdout.write(JSON.stringify({entry36:entry.status,...actual,total:ledger.entries.length})+"\n");});'` | Nonzero pipeline exit, malformed/unreadable status JSON, entry 36 absent or not fixed, an unknown entry status, or any recomputed open/fixed/waived/total count differing from the ledger's stored count fields. | `.planning/WINDOWS.md` | ⬜ pending |

### Plan82 — Anonymous D-106 continuation

Local fixture checks never access GitHub or inspect credentials. After they pass, Task2 creates and inspects one fresh PENDING attempt without a provider request. Task3 is the sole human checkpoint: ALLOW or HOLD for the exact displayed anonymous scope. Task4 automatically consumes that reply, performs at most one bounded observe call after ALLOW (or zero requests after HOLD), inspects the terminal evidence, and closes out state. No human UAT or repeat verification is needed.

| Task ID | Requirement | Automated check | Fails when | Status |
|---------|-------------|-----------------|------------|--------|
| 175-82-01 | REL-13/17: parse official commit, workflow-run, and attempt-job shapes; validate fixed routes, pagination, and anonymous transport. | `node --check script/release_candidate/plan81_readiness.mjs && node --test script/release_candidate/plan81_readiness.test.mjs` | Any test fails/skips, any provider request occurs, any Authorization header/token source appears, documented optional omissions are rejected, mismatched bindings pass, request count exceeds 34, or raw provider data is retained. | ✅ passed 2026-10-05 (20/20; zero provider calls) |
| 175-82-02 | REL-13/17: prepare and inspect a new exact-scope PENDING authorization only after the focused local suite passes. | `node script/release_candidate/plan81_readiness.mjs --mode prepare --authorization .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-read-authorization.json --lifecycle .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-readiness.lifecycle.jsonl` followed by `node script/release_candidate/plan81_readiness.mjs --mode inspect --authorization .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-read-authorization.json --lifecycle .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-readiness.lifecycle.jsonl --expect pending` | Attempt/scope binding fails, a read-intent/request exists, prior records change, or any provider request occurs. | ✅ prepared 2026-10-05 (PENDING; zero requests; no read intent) |
| 175-82-03 | REL-13/17: preserve the PENDING state while presenting the exact one-read ALLOW/HOLD decision; this is the only human checkpoint. | `node script/release_candidate/plan81_readiness.mjs --mode inspect --authorization .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-read-authorization.json --lifecycle .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-readiness.lifecycle.jsonl --expect pending` | Decision is ambiguous, attempt/scope binding fails, any read intent/request exists, or exact scope differs from the displayed candidate tuple. | ✅ ALLOW recorded for attempt f0147212e39ac9b1fd0e7c9905d16e7a |
| 175-82-04 | REL-13/17: automatically consume the exact decision, inspect terminal evidence, and preserve release holds. | `node script/release_candidate/plan81_readiness.mjs --mode inspect --authorization .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-read-authorization.json --lifecycle .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-readiness.lifecycle.jsonl --artifact .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/evidence/175-plan82-pr219-readiness.json --expect terminal` | Artifact/lifecycle digests or request counts disagree, sensitive data appears, an ambiguous response is called ready, or release posture changes. | ✅ UNKNOWN/HTTP_UNAVAILABLE; 4 requests; terminal and release-held inspections passed |

No CI workflow change: the candidate/readiness reconciliation is a one-time evidence task, while adding a permanent lane would not protect a recurring contract. No human UAT or verification checkpoint: the only human input is the unavoidable ALLOW/HOLD trust decision for the displayed external read.

## Wave 0 Requirements

Existing Mix and ExUnit infrastructure covers this follow-up. No dependency, fixture framework, workflow, or permanent CI lane is required.

## Manual-Only Verifications

None. The helper's contract, scanner output, regression cases, and evidence-document edits are machine-checkable or inspectable. Do not create a human UAT checkpoint.

## Validation Sign-Off

- [ ] Each plan task has automated verification with an observable failure condition.
- [ ] Helper roster tests pass before the unchanged helper is added to the tracked source set.
- [ ] Scanner and scanner-dependent suite pass before their corresponding claims are refreshed.
- [ ] Failed, unrun, or unrelated assertions leave affected claims UNKNOWN.
- [ ] No workflow/final-guard changes occur without a named failing assertion and a separately approved scope.
- [ ] No watch-mode flags are used.
- [ ] `nyquist_compliant: true` is set only after plan review confirms task-to-check coverage; this file remains draft until then.

**Approval:** pending

## Current Evidence and Tag-Repair Validation Refresh — 2026-10-06

The new public observation is a planning trigger, not a release pass. Any follow-up plan must
preserve these automated gates:

1. Re-fetch exact source/mirror refs successfully; prove source `ios-core-v0.2.6`, mirror `main`,
   prior mirror tag `v0.2.5`, and target `v0.2.6` states without treating failed reads as absence.
2. In an isolated full clone, recompute the source subtree split and require it to equal the
   candidate mirror object; also prove the object is present locally.
3. Re-fetch PR #219 and bind current open/unmerged state, base, and head to the fresh preflight.
   Obtain current exact push-permission and effective Git credential-helper verdict without
   printing credential material.
4. Require one successful, exact, create-only dry-run targeting only
   `refs/tags/v0.2.6` at the recomputed OID. A failed or ambiguous dry-run ends the plan with no
   write.
5. Before the irreversible write, present one exact human decision checkpoint. If approved, persist
   the one-use attempt before one native-Git push, then independently verify the target tag and
   unchanged protected refs. Never retry an ambiguous push.
6. Only after the tag is verified may a separately authorized, exact-head CI rerun be considered;
   it must bind current PR base/head, full run/check roster, `ios-mirror-parity-proof`, the aggregate,
   and the exact candidate receipt. Tag verification or a green CI run alone does not clear the
   phase requirements.

No UAT checkpoint is needed; assertion and evidence evaluation remain automated. Plan82 and its
lifecycle stay terminal and immutable. Current base, merge policy, CI receipt, and permission remain
unknown until the corresponding fresh checks run.

## Plan84 Validation Refresh — 2026-10-06 (supersedes earlier candidate-repair guidance)

Plan84 is a fresh, exact `v0.2.6` mirror-tag repair transaction after Plan83's terminal
`UNKNOWN/OBSERVATION_UNAVAILABLE`. It does not enter Plan83's preflight/apply path and never reuses
Plans81–83 attempt, receipt, or lifecycle data. The anonymous scope artifact only permits planning;
it does not establish current refs, tag policy, write permission, or CI readiness.

### Test infrastructure and sampling

Use the existing ExUnit, Node built-in test, and isolated-Git fixture patterns. Run the focused local
fake suite before any live provider or Git operation and after changes to the plan-specific runner,
classifier, receipt, or projection. Do not add a new recurring CI lane for this one-time repair.
Do not dispatch or rerun CI; after a verified tag, inspect only naturally triggered exact-head CI
evidence. No human UAT is required.

| Task ID | Plan | Requirement | Automated check | Fails when | Status |
|---|---:|---|---|---|---|
| 175-84-01 | 84 | REL-13, REL-17 | `MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs --max-cases 1` | Any injected transport, exact-scope, unknown-vs-absent, pagination, privacy, digest, lifecycle, no-side-effect, or historical-immutability case fails or is skipped. | ⬜ pending |
| 175-84-01 | 84 | REL-13, REL-17 | `node --check script/release_candidate/plan84_tag_collector.mjs && node --test script/release_candidate/plan84_tag_collector.test.mjs` | Syntax fails; a fake request leaves the fixed allowlist, sends Authorization, follows a redirect, exceeds a finite cap, leaks raw material, or produces an uncounted attempt. | ⬜ pending |
| 175-84-02 | 84 | REL-13, REL-17 | `MIX_ENV=test mix crosswake.release.mirror_tag_026 --mode plan84-inspect --expect preflight --json` | The fresh receipt/lifecycle is unreadable or inconsistent, incomplete/unavailable facts are treated as ready/absent, or inspection exposes raw provider/process/credential data. | ⬜ pending |
| 175-84-03 | 84 | REL-13, REL-17 | `MIX_ENV=test mix crosswake.release.mirror_tag_026 --mode plan84-inspect --expect decision --json` | No exact decision is bound to the fresh digest/object/ref, a held preflight is treated as eligible, HOLD permits a write, or a tag intent appears before the final prewrite check. | ⬜ pending |
| 175-84-04 | 84 | REL-13, REL-17 | `MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs --max-cases 1` | An immediate-recheck, intent-before-write, exact-ref, one-attempt, ambiguous-result, independent ref/parity, natural-CI binding, or hold-preservation test fails or is skipped. | ⬜ pending |
| 175-84-04 | 84 | REL-13, REL-17 | `MIX_ENV=test mix crosswake.release.mirror_tag_026 --mode plan84-inspect --expect terminal --json` | The independently observed tag does not equal the reviewed split, protected refs drift, a naturally triggered CI result is stale/incomplete/mismatched, or any release requirement/hold is promoted. | ⬜ pending |

Task 1 must use fakes and an isolated Git fixture only; it must complete before Task 2's bounded,
read-only live observation. Any incomplete or ambiguous source terminates as UNKNOWN/BLOCKED. The
single human action, if every preflight gate passes, is an exact one-way authorization for creating
only `refs/tags/v0.2.6` at the freshly computed object. Task 4's ref, parity, and natural-CI
assertions remain automated. No CI rerun, Gate 2, merge, recovery, registry action, or publication
is authorized. REL-13/14/15/17 remain OPEN; candidate readiness remains BLOCKED; merge policy stays
UNKNOWN; the release hold and Plans45–48 remain held; Phase175 remains incomplete.

**Nyquist status:** draft; `nyquist_compliant: false` until the independently reviewed Plan84 maps
every executable task to these checks and the implementation produces matching evidence.

## Plan85 local process-boundary twin — 2026-10-06

Plan85 is a local-only, test-owned diagnostic after Plan84's sole live attempt ended terminal
`UNKNOWN/OBSERVATION_UNAVAILABLE`. These are planned gates, not executed evidence. No Plan84
artifact, digest, request count, release eligibility or held-plan status changes. The exact next
execution command after plan checking was `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 1`; that local wave is now complete and no next command is eligible.

The tracer must traverse the test-only Mix/Elixir coordinator, the existing bounded Port runner,
the real Node collector child and a 127.0.0.1 fixture. The production API host remains fixed.
The fixture counts its received requests, including exact zero, while a failed or interrupted
observation remains unknown. The existing `release-candidate-fixtures` CI job runs
`test/crosswake/release_candidate` and provides the recurring ExUnit gate; do not add a second
workflow. The focused Node check is local unless a current-source reason calls for a narrow
addition to that existing lane.

| Task ID | Requirement | Automated check | Fails when | Status |
|---|---|---|---|---|
| 175-85-01 | REL-13, REL-17 diagnostic | `MIX_ENV=test mix test test/crosswake/release_candidate/plan85_local_twin_test.exs --max-cases 1` | Nonzero exit, zero tests, skipped test, no actual coordinator-to-real-Node-to-loopback GET, wrong method/route/auth/request count, or any dry-run/decision/tag/CI attempt. | ✅ 21 tests passed, 0 failures, 0 skipped (2026-10-06) |
| 175-85-02 | REL-13, REL-17 diagnostic | `MIX_ENV=test mix test test/crosswake/release_candidate/plan85_local_twin_test.exs --max-cases 1` | Nonzero exit, zero tests, skipped case, failure-class conflation, zero substituted for unknown, cap/order/empty boundary error, leaked child/listener, provider connection, release-side effect or sensitive value. | ✅ same run: 21 tests passed, 0 failures, 0 skipped (2026-10-06) |
| 175-85-02 | REL-17 diagnostic | `node --check script/release_candidate/plan84_tag_collector.mjs && node --check script/release_candidate/ios_tag_source_collector.mjs && node --test script/release_candidate/plan85_tag_collector.test.mjs` | Nonzero exit, zero tests, skipped case, route/redirect/cap/schema/pagination acceptance error or raw value retained. | ✅ syntax checks passed; 21 tests passed, 0 failures, 0 skipped (2026-10-06) |
| 175-85-02 | REL-13, REL-17 regression | `MIX_ENV=test mix test test/crosswake/release_candidate/plan84_mirror_tag_test.exs --max-cases 1` | Nonzero exit, zero tests, skipped case, Plan84 behavior or production host pin changes. | ✅ 46 tests passed, 0 failures, 0 skipped (2026-10-06) |
| 175-85-02 | REL-13, REL-17 source hygiene | `mix format --check-formatted lib/crosswake/release_candidate/plan84_mirror_tag.ex lib/crosswake/release_candidate/ios_mirror_tag_repair.ex lib/mix/tasks/crosswake.release.mirror_tag_026.ex test/crosswake/release_candidate/plan85_local_twin_test.exs` | Nonzero exit or a named Elixir source/test file is unformatted. | ✅ passed (2026-10-06) |

No human UAT applies. Passing checks prove only the local process and sanitization contract;
Plan84's historical cause and actual provider request count remain UNKNOWN. REL-13/14/15/17
remain OPEN; candidate readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, Plans45–48
HELD and Phase175 INCOMPLETE. Other spec-less phase edge rows stay unresolved under their
historical or held owners; this addendum evaluates only local REL-13/17 diagnostics.

### Plan85 Execution Result — 2026-10-06

The real Mix/Elixir coordinator, existing bounded Port runner, outer Node launcher and Plan84
collector completed one fixed-route unauthenticated loopback GET. The local fixture observed one
request; process-fault cases returned separate closed diagnostics for launch failure, timeout,
nonzero exit, malformed output, incomplete output, oversized output, invalid outer envelope, extra
result keys, wrong result types and incomplete success metadata. The coordinator rejects those
invalid result shapes as `CHILD_ENVELOPE_INVALID` without retaining a sentinel value.

Boundary coverage verifies exact 16,384/16,385-byte HTTP body and outer input handling,
8,192/8,193-byte projected and child output handling, four ordered complete pages, 100/101
records on a page, empty/invalid/route-changing links and an 8,000 ms HTTP deadline. A listener
refuses reconnection after cleanup. A timed-out child group writes a start sentinel but cannot
write its delayed descendant sentinel. Temporary `git`, `gh` and `curl` commands remain uncalled;
the Plan84 receipt and lifecycle digests remain unchanged. The Mix local entry rejects production
mode, and a fixture environment value does not change the production API origin. Node resolution
now uses the PATH-resolved executable directly, without an unbounded discovery subprocess.

Validation: the Plan85 ExUnit suite passed 21 tests with no skips; Node TAP passed 21 tests with no
skips; Plan84 regression passed 46 tests with no skips; Node syntax and the named Elixir format
check passed. The existing `release-candidate-fixtures` workflow step runs the full
`test/crosswake/release_candidate` directory; no workflow change or dispatch was made.

Deviations: Node fetch with `redirect: "error"` exposes a generic TypeError without a structured
redirect result. The local-only branch therefore uses `redirect: "manual"` to observe and reject
the status without following it, while production collection retains its redirect-error behavior.
`ios_tag_source_collector.mjs` was extended with an exact test-only operation/envelope allowlist
because it is the required outer launcher but was omitted from the plan's declared file list. The
coordinator now enforces exact keys, types and a complete PR success projection, and Node path
resolution no longer runs outside the bounded process chain. These changes remain local
diagnostic-only and do not alter Plan84 history or release authority.

### Plan85 post-wave collection ratchet reconciliation — 2026-10-06

The initial project-wide gate exposed a stale ledger after 20 additional working-tree collection
assertions. Seventeen sites received explicit nonempty guards; the existing assertions remain.
The scanner now verifies 250 classified sites, zero needing fixes, and byte-exact ledger agreement.
Measured buckets are 135 safe by construction, 77 guarded, 34 cardinality pinned and four literals.
The corrected release fixture/ratchet bundle passed 388 tests, zero failures. Commit `11e73a7a`
contains the two isolated test fixes. Guards and ledger expectations in four files with substantial
prior edits remain local; no unrelated source was staged. These results cover the working tree;
no clean-checkout or remote CI result is claimed. See `175-85-SUMMARY.md` for the exact file list.

Last completed phase: 174. Plan85 completed both local-only Wave 1 tasks. No next GSD command is eligible. Fresh, independently verifiable current candidate facts, or new evidence supporting a materially distinct bounded observation path, must support a separately scoped plan and its required authorization before work reopens. Do not repeat Plan85 discussion/planning/execution or replay Plan84/Plans81–83. REL-13/14/15/17 remain OPEN; candidate readiness BLOCKED; merge policy UNKNOWN; release hold ACTIVE; Plans45–48 HELD; Phase175 INCOMPLETE.

### Plan85 project-wide environment gate

The first terminal full Mix run reported 2,275 tests, zero assertion failures, four invalid
(74 excluded), exit 2. All four invalidations came from the existing `DoctorRouterTest` host
fixture attempting public dependency resolution and an unwritable Hex cache. No fixture or
product source change was indicated. A task-local cache containing only public registry/package
files, with `HEX_OFFLINE=1` and no copied configuration, resolved the setup: four tests, zero
failures at the same seed. Fresh Node syntax and Plan85 TAP passed 21 tests, zero failures/skips.
Full offline Mix gate passed: 2,275 tests, zero failures or invalid tests, 74 expected exclusions; same seed 549400. Fresh Node syntax and Plan85 TAP passed 21 tests, zero failures/skips. Build, named formatting, exact collection ledger, schema and UI checks passed; codebase drift was advisory and skipped without STRUCTURE.md. These are working-tree results; no remote CI or clean-checkout result is claimed.

## Plan92 validation reconciliation — 2026-10-07

The earlier Plan79/82/85 sections are historical. This section reconciles the current D-107 context, Plan91 operation-accounting contract, and the newly identified fixed-path collision. It is a plan-time validation map; none of the Plan92 checks has run. Plan88's PENDING scope and lifecycle, its old ALLOW, and Plan89 are historical or held and cannot be selected by this map. The old ALLOW is invalid under Plan91's changed contract. Last completed phase remains 174; Phase175 and REL-13/14/15/17 remain incomplete/open, readiness BLOCKED, merge policy UNKNOWN, release hold ACTIVE, Plans45–48 HELD.

| Task | Requirement | Automated validation | Fails when | Status |
|---|---|---|---|---|
| 175-92-01 | REL-13/17 prerequisite | `MIX_ENV=test mix test test/crosswake/release_candidate/plan87_mirror_tag_test.exs --max-cases 1` and `node --test script/release_candidate/plan87_mirror_ref.test.mjs` | New attempt path-set collision, traversal, symlink, digest substitution, fixed-scope fallback, old-ALLOW reuse, unaccounted operation, skipped test, real provider/Git call, or changed historical bytes. | ⬜ planned; fake adapters and temporary roots only |
| 175-92-02 | REL-13/17 prerequisite | `mix crosswake.release.mirror_tag_026 --mode plan87-inspect --path-set <fresh sealed path-set> --expect pending --json` | Scope or path-set digest mismatch, any journal event/read intent, missing exclusive reservation, old path selected, or release posture promotion. Run only after local source tests and use no network. | ⬜ planned; one new workstream attempt only |
| 175-92-03 | REL-13/17 prerequisite | Offline D-107 trigger/decision validation followed by exact path-set inspection with `--expect held` when the signal or ALLOW is absent, or `--expect terminal` after one allowed read. | A missing/stale trigger is reported verified or reaches credentials/request intent; an inexact or absent ALLOW reaches access; terminal accounting, lifecycle, candidate binding, or privacy check fails; or a second attempt is made. Missing trigger must produce a terminal no-request HOLD. | ⬜ blocked on independent signal and separate exact ALLOW |

The D-107 signal is a new naturally triggered `Crosswake CI` artifact for version 0.2.7 and exact base `e51698528dc667ef89beb951e4eb1ec91da74981`, head `696a27a3be1fcd56efe70923dc0ce286a1c41c6d`, tree `5279cae1daa1fbff3437b673df8ca231fb07c91f`, with matching `phase168-candidate-ci-<head>` receipt/run/attempt and passing `ios-mirror-parity-proof` plus `Crosswake CI` aggregate. Historical failed run `36438452825` is insufficient. This validation does not authorize a CI rerun, Gate2, tag write, merge, recovery, registry action, publication, or a requirement closure. No human UAT applies; the only human input is a separate exact read ALLOW/HOLD if the trigger passes.

The phase's 20 spec-less edge probe rows remain unresolved, including six unclassified rows. Plan92 carries them as flagged assumptions, without treating this narrow path-contract repair as resolution of the broader release requirements. `COVERAGE.md` remains the bounded release-API decision matrix; no schema push or UI gate applies. The current `175-RESEARCH.md` and `175-PATTERNS.md` provide the local analogs, while the newer D-107 trigger and Plan91 summary control this validation boundary.

## Plan129 additive validation — 2026-10-10

This addendum applies only to the distinct Plan129 continuation after Plan128's terminal ALLOW/UNKNOWN read and verified local macOS `wc -l` padding repair. The older sections above remain historical; their probe counts and candidate assertions are not current Plan129 verdicts. No Plan129 command has run at planning time. Plan128's spent attempt, authorization, result, and all earlier evidence remain immutable. The exact next work is Wave33 after completed Plan128, under the existing Plan105 current-read modes; there is no source change task.

| Task | Requirement | Automated validation | Fails when | Planned status |
|---|---|---|---|---|
| 175-129-01 | REL-13/17 prerequisite; T-175-232/233 | `node --check script/release_candidate/plan105_mirror_tag_collector.mjs`; `node --test script/release_candidate/plan105_mirror_tag_collector.test.mjs`; `HEX_OFFLINE=1 MIX_ENV=test mix test test/crosswake/release_candidate/plan105_mirror_tag_test.exs --max-cases 1`; named Elixir format and scoped `git diff --check` in Plan129 Task1 | Any focused fake failure, skipped required case, malformed padded progress accepted, current collector/scope mismatch, or changed source after checks. All checks precede the single local prepare. | Planned, no network |
| 175-129-01 | REL-13/17 prerequisite; T-175-232 | One local `plan105-current-read-prepare`, then `plan105-current-read-inspect` and Task1's artifact/binding assertion | Other than one new random 32-hex attempt; non-PENDING or nonzero count; more than reservation-only lifecycle; absent/mismatched attempt, scope, raw-card, or collector SHA-256; authorization, result, read intent, credential/helper, provider, or remote-Git callback. | Planned, zero external access |
| 175-129-02 | REL-13/17 authorization; T-175-232/233 | Task2's offline PENDING assertion immediately at the displayed blocking ALLOW/HOLD checkpoint | The displayed card/four bindings are stale, incomplete, or no longer reservation-only; an ambiguous reply is treated as permission; a user is asked to copy hashes. | Blocking one-use choice |
| 175-129-03 | REL-13/17 prerequisite; T-175-233/234/235 | Existing ALLOW run's terminal seal or HOLD decision seal, then offline `Plan105MirrorTag.digest/1` recomputation and structured Node receipt/lifecycle assertion; scoped summary `git diff --check` | HOLD has any external access; ALLOW has other than one read intent or is retried; a sealed artifact digest/schema/event reference fails recomputation; caps or zero mutation counts fail; UNKNOWN has facts; full production-sealed OBSERVED facts are absent; raw sensitive fields appear; a safe `PROCESS_STDERR_NONEMPTY` value is wrongly rejected by a serialized substring scan. No PENDING-only inspector is invoked after decision. | Planned only after decision |

The supplied spec-less fallback report has 23 unresolved rows, five unclassified, and no resolved rows. Eight REL-13/17 rows are flagged assumptions for this additive path; the remaining fifteen stay with historical or held phase owners. No probe row is promoted merely because a local test passes, and the descriptor-less prohibitions in Plan129 remain flagged-unverified. No human UAT applies to automatable checks; the one human checkpoint is the external read authorization. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. This addendum authorizes no dry-run, test-push, tag, push, CI, merge, recovery, registry, publication, or release operation.

## Plan131 additive local validation — 2026-10-10

Plan131/Wave35 follows completed Plan130/Wave34. At planning time, no Plan131 implementation or product test had run; the map below is historical and the execution reconciliation follows. Older validation entries retain their historical scope and cannot authorize a new read. The exact commands and stated failure directions are in `175-131-PLAN.md`; the independent plan review passed.

| Task | Requirement | Automated validation | Fails when | Planned status |
|---|---|---|---|---|
| 175-131-01 | REL-13/17 prerequisite; T-175-241/242/243/244 | Named temp-root ExUnit tracer through the real Elixir production adapter and real Node collector with injected credential/fetch/process fakes; exact named Node TAP-line guard | Required case absent/skipped; invalid/HOLD/legacy/replay decision reaches callbacks; unrelated route receives policy authentication; missing reviewed policy header; unsafe output; nonzero test exit | Planned, no network; gates Task2 |
| 175-131-02 | REL-13/17 prerequisite; T-175-241..245 | Both full focused fake suites; named redaction/legacy-compatibility presence guards; Node syntax, named Mix format, scoped whitespace checks; summary hold/version assertions | Omitted bypass becomes complete; unsupported policy or unverified identity/role reaches policy reads; legacy authentication changes; scope/schema/count/cap/one-use/privacy assertion fails; summary omits holds/version UNKNOWN; nonzero check exit | Planned, local-only after tracer |

All fake roots are temporary and isolated from workstream evidence. This execution prepares no real scope/card/attempt or authorization and invokes no credential/helper, provider, remote Git, dry run, tag, CI, merge, registry, or release operation. Version acquisition is outside scope. The official redaction fixture supports a local acquisition repair but does not establish Plan129's live cause. Plan106 and Plans46–48/89 remain HELD; its Plan119-pinned precondition is not satisfied. REL-13/14/15/17 remain OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Later external reads require separately reviewed scope/card and a fresh plain-language allow/hold. No human UAT or new CI lane is added.

The phase-wide fallback report remains 23 unresolved rows (five unclassified, zero resolved). Eight REL-13/17 rows are flagged assumptions in this local plan; the other fifteen retain historical/held phase owners. Local fake success cannot promote any live requirement. Descriptor-less prohibitions remain flagged-unverified.

## Plan131 execution reconciliation — 2026-10-10

Both local tasks passed with synthetic temporary roots and injected credential/fetch/process implementations. No real scope/card/attempt, authorization, provider request, remote Git, dry run, tag, CI, merge, registry, publication, or release action occurred.

| Gate | Executed evidence | Result |
|---|---|---|
| Task1 production seam | Exact named Node TAP guard; named ExUnit ALLOW tracer using the real coordinator, production adapter, and Node collector with fake transport | PASS; exact route/header order, sanitized result, digest bindings and one-use behavior |
| Task2 compatibility and denial | Full Node collector file plus exact named redaction guard; all 37 focused ExUnit cases within the 72-test affected-module rerun, with both required name guards present | PASS; 114 Node and 72 affected ExUnit, zero failures |
| Full offline integration | `HEX_HOME=/private/tmp/crosswake-phase175-hex HEX_OFFLINE=1 MIX_ENV=test mix test --trace --max-cases 1`; then `mix test --failed --trace --max-cases 1` under the same offline cache | Initial 2,370 tests / six failures / 74 excluded; all six failed tests reran PASS after bounded reconciliation |
| Affected-module reconciliation | Full Plan105, Phase170 ledger, milestone transition, Phase161.1 navigation-integrity and Phase135 proof modules under the same offline cache | PASS; 72 tests, zero failures; includes all six original failing checks |
| Assertion inventory | `elixir script/inventory_collection_assertions.exs --check` | PASS; 255 sites; two new lifecycle assertions pinned to exactly four events; prior shifted row refreshed |
| Source hygiene | Node syntax, warnings-as-errors compile, format for the three Plan131 Elixir files and the affected ledger test, global `git diff --check` | PASS; existing planning whitespace and state resume breadcrumb reconciled |
| Artifact preservation | Before/after SHA-256 comparison against the Wave35 baseline | PASS; all 493 pre-existing phase plan/summary/evidence files unchanged; no real Plan131 evidence added |

Card integrity and mixed known/UNKNOWN policy completeness first failed under local regression assertions, then passed after repair. Omitted/malformed bypass and unsupported policy remain UNKNOWN; legacy v1 ruleset GETs stay anonymous. No live requirement is promoted by these fake results. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; candidate version and effective write UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Five incomplete held plans remain, so phase-wide verification/completion remains ineligible. No human UAT or permanent CI lane was added. See `175-131-SUMMARY.md`.

## Plan132 additive authenticated-policy validation — 2026-10-10

Plan132/Wave36 depends only on completed Plan131/Wave35. Research was skipped; older validation remains historical. The plan passed independent review after one bounded revision that closed the terminal audit's unknown-field/count gap. Frontmatter and three-task structure passed; all seven verify commands have stated failure signals. Their compound-command path probe is not_applicable and supplies no path-resolution proof. Inline Elixir/Node syntax and a synthetic extra-counter rejection check passed at planning time. No execution gate below has run, and no real scope/card/attempt or authorization exists.

| Task | Requirement | Planned automated validation | Fails when | Status |
|---|---|---|---|---|
| 175-132-01 | REL-13/17 prerequisite; T-175-246/247 | Existing named fake ExUnit/Node cases and suites, then exactly one local policy-read prepare and PENDING inspector plus four-binding/count/cap check | Required fake absent/skipped or failing; stale/mismatched scope/card/collector; non-PENDING state; prior attempt; authorization/result/read intent or nonzero counts before display | Planned; no network |
| 175-132-02 | REL-13/17 authorization; T-175-246/247 | Same-attempt PENDING inspection immediately before the complete just-displayed allow/hold choice | Incomplete/stale card, mismatched bytes, reused or ambiguous choice, or request for copied hashes | Planned; one-use trust decision, not UAT |
| 175-132-03 | REL-13/17 prerequisite; T-175-248/249/250 | Offline canonical digest and exact schema/key-set checks over scope/auth/all events/result/nested facts/diagnostics, seven-key bounded counts, recursive privacy, state-specific HELD/UNKNOWN/OBSERVED checks, and summary hold assertions | Extra or private field/count, binding/hash/lifecycle/cap mismatch, HOLD access, UNKNOWN facts, invalid OBSERVED shape, absent/unsealed evidence, mutation counts, retry, or authority promotion | Planned; only after decision |

All 23 fallback edge rows remain explicitly flagged (eight current REL-13/17 rows, fifteen historical/held-owner rows); no phase-wide requirement is promoted. Descriptor-less prohibitions remain flagged-unverified. No human UAT or new CI lane is added. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; candidate version/effective write UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. See 175-132-PLAN.md for exact grounded commands and 175-132-PLAN-CHECK.md for the independent verdict.

## Plan136 additive local-contract validation — planned 2026-10-10

Plan136/Wave39 depends only on completed135/Wave38. Research was skipped; older validation remains historical. The independently reviewed plan SHA-256 is `deb2df2958b9b0569b5a2aa9388a82cf0ff9b831ffd66311bd963028fab806c8`; zero current findings remain after one revision. Frontmatter/structure, five stated failure directions, all four embedded Python syntax checks, and the five actual Plan135 raw-file hashes passed parent planning checks. The report parser passed ten synthetic output cases (complete, empty, missing/skipped/duplicate/failed Node and ExUnit cases). No application suite or execution task has run at planning time.

| Task | Requirement | Planned automated validation | Fails when | Status |
|---|---|---|---|---|
| 175-136-01 | REL-13/17 prerequisite; T-175-136-01/02/03 | Named Node TAP tracer and completed timed ExUnit production-process tracer; RED before source edits and GREEN after | Named tracer absent, skipped, duplicated, failing or crossing a real external boundary; scope/card/collector/lifecycle/provenance/credential mismatch | Planned; synthetic-only |
| 175-136-02 | REL-13/17 prerequisite; T-175-136-01 through07 | Complete fake suites plus plan-owned roster gate requiring 36 Node and16 ExUnit cases each completed once without skip; exact schema/provenance/auth/policy/ref/cap/privacy/legacy/replay denials | Either runner nonzero, missing/malformed roster, required case absent/skipped/duplicate/failing, hostile input ready or old contract changed | Planned; no network |
| 175-136-02 | Historical integrity and release holds | Raw SHA-256 equality for scope/card/authorization/lifecycle/result; summary’s exact held posture; named syntax/format and scoped whitespace | Any sealed file absent/changed, release hold omitted or syntax/format/whitespace nonzero | Planned; read-only artifact checks |

The path probes are not_applicable for compound verification commands and give no path-resolvability claim. All23 fallback edge rows remain explicit flagged assumptions (eight current REL-13/17, fifteen historical/held owners); descriptor-less prohibitions remain flagged-unverified. No human UAT or recurring CI lane applies. Plan106 and Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Last completed phase174; Phase175 incomplete. Exact next command: `$gsd-execute-phase 175 --ws quality-ratchet-release --wave 39`. See175-136-PLAN-REVIEW.md.
