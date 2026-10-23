# Phase 175: Rehearsal and Publish - Pattern Map

**Mapped:** 2026-09-26
**Scope:** D-43–D-49 and Plans 175-34..41: REL-17 closure, a fresh successor, same-run proof, then the already-held PR #115 behind Gate 3. The 0.2.4 and 0.2.5 PARTIAL records are immutable history.
**Files classified:** planned file groups across Plans 175-34..41. **Analogs found:** existing implementation analogs for all code roles; evidence artifacts use phase-local records.

**Follow-up supplement:** 2026-09-29, approved source-boundary response D-57..D-61 after Plan 175-53. The original map below remains historical for its stated scope; this addendum maps the distinct fresh follow-up only.

## File Classification

| New/modified file or group | Role | Data flow | Closest tracked analog | Match |
|---|---|---|---|---|
| `lib/crosswake/release_candidate/evidence_gate.ex`; `test/crosswake/release_candidate/evidence_gate_test.exs` | validator / test | transform | `workflow.ex`; `workflow_test.exs` | role + flow |
| `lib/crosswake/release_candidate/evidence_live.ex`; `test/crosswake/release_candidate/evidence_live_test.exs` | adapter / test | request-response, file I/O | `evidence_input.ex`; `workflow_test.exs` | role + flow |
| `lib/crosswake/release_candidate/companion_receipt.ex`; `lib/mix/tasks/crosswake.release.receipt.ex`; `test/crosswake/release_candidate/companion_receipt_test.exs` | service / Mix task / test | transform, file I/O | `evidence_input.ex`; `crosswake.release.status`; workflow tests | role + flow |
| `lib/mix/tasks/crosswake.release.gate.ex`; `lib/crosswake/release_status.ex`; `test/mix/tasks/crosswake_release_status_test.exs`; `script/release_candidate/require_release_evidence.sh` | operator utility / status / shell guard / tests | request-response, side-effect gate | `crosswake.release.status`; `release_candidate/ios_mirror.sh` | role + flow |
| `.github/workflows/release-please.yml`, `.github/workflows/hex-publish.yml`, `.github/workflows/ios-mirror-backfill.yml`; `script/guarded_hex_publish.sh`, `script/release_candidate/ios_mirror.sh`, `script/release_candidate/android_publication.sh`; `script/check_release_workflow_integrity.exs` | config / utility | event-driven, external side effect, batch validation | their current approval, recovery, preflight, and roster checks | exact |
| `test/crosswake/proof/phase175_rel17_publish_paths_test.exs`, `phase175_rel17_recovery_paths_test.exs`, `phase175_rel17_wiring_test.exs` | test | fixture mutation | `phase175_runbook_ancestry_test.exs`; `test/support/release_workflow_fixtures.ex` | exact |
| Phase evidence: `175-next-successor-{candidate,rehearsals,receipt,premerge,gate-2,postmerge,hex-response-postmerge,core-run,core-registry,proof}.json`; `175-second-companion-{candidate,receipt,premerge,gate-3,postmerge,run,registry,hex-public}.json`; `175-NEXT-SUCCESSOR-{CANDIDATE,PROOF}.md`; `175-SECOND-COMPANION-GATE-3.md` | evidence | file I/O, batch | existing phase-local run, PR, registry, and summary records | role + flow |
| `175-VERIFICATION.md`, `175-VALIDATION.md`, `175-SECURITY.md`, `175-KNOWN-RELEASE-BLOCKER.md`; workstream `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` | planning/status docs | transform | corresponding current phase/workstream records | role + flow |

Code analog paths above are tracked source, checked with `git ls-files`. Planned targets are concrete plan filenames. Phase evidence records are planned outputs, not source-code analogs.

## Pattern Assignments

### Pure REL-17 validator (`evidence_gate.ex`)

**Analog:** `lib/crosswake/release_candidate/workflow.ex:17-69,71-89`. It accepts explicit data, requires an exact key set, derives state, and reconstructs output to reject forged results:

```elixir
unless exact_map?(input, ~w(approved_ref candidate_receipt children version)a),
  do: invalid!()

state = cond do
  is_nil(failed_child) -> "COMPLETE"
  successful_coordinates == [] -> "BLOCKED"
  true -> "PARTIAL"
end
```

Make REL-17 a pure function over one immutable per-operation envelope keyed by `(receipt_digest, operation, leg_run_id)`, with candidate OIDs as subject data. Validate all six conditions and evidence source digests/locations. Pre-merge authorization and post-merge publication are distinct: only the latter binds actual merge OID. Missing/uncertain evidence is BLOCKED; READY FOR APPROVAL grants no publish permission. Existing rollup's PARTIAL and COMPLETE are transaction results, not release authorization.

### Live evidence capture (`evidence_live.ex`, gate Mix task, shell guard)

**Analog:** `lib/crosswake/release_candidate/evidence_input.ex:53-82,130-147,381-400,412-460`. It accepts exact selectors, checks file roster and size, reads bytes, parses JSON, computes SHA-256, and fails closed:

```elixir
root = safe_directory!(evidence_dir)
assert_exact_file_roster!(root)
bytes = read_file!(path)
Jason.decode!(bytes)
```

Keep raw registry response bytes beside an explicitly nonempty parse and its matching response-table row. Remote adapters re-fetch mutable GitHub/registry facts at the authorization boundary and immediately before every side effect, exhaust pagination, and block on API/parse/empty-field errors, stale identity, policy change, or bypass evidence. No caller-supplied `valid: true`.

**Ancestry analog:** `script/check_release_runbook_ancestry.sh:19-56` checks 40-hex object form, actual commits, runbook path touch, `merge-base --is-ancestor`, and path presence. Apply to fetched base/head pre-merge and base/head/actual merge post-merge. `.github/workflows/release-please.yml:96-125` shows receipt and remote artifact lookup, but its current single-page `gh api` request is placement guidance, not pagination-complete REL-17 code.

### Publisher wiring

**Ordinary:** `.github/workflows/release-please.yml:28-47,53-60,85-102,235-275,567-614,621-682` exposes approval outputs and Hex/iOS/Maven publisher jobs. Bind the actual merge and check the post-merge envelope immediately before each mutation, preserving exact-version and receipt checks.

**Recovery:** `.github/workflows/hex-publish.yml:164-200,275-303,422-485` and `.github/workflows/ios-mirror-backfill.yml:365-450,449-520` show recovery entry points. Require the same validator with `recovery` operation and fresh, distinct authorization. The Hex, iOS, and Android scripts own last preflight before side effects; guard both workflow call sites and invocable adapters.

**Companions:** `.github/workflows/release-please.yml:311-562` has five companion Hex jobs invoking `script/guarded_hex_publish.sh`. Bind `companion_publish` to its own candidate and leg run. Do not add companions to core's six-child rollup (`workflow.ex:4-14`); the held second companion needs independent registry proof.

### Structural guard scanner

**Analog:** `script/check_release_workflow_integrity.exs:4-52,156-175,466-485,1540-1581,1609-1663`. Its declared `@roster_ids` plus `roster_exact/1` detect scope drift; `release.approval.linked_graph` checks job needs, conditions, and call sites. Add explicit REL-17 checks for linked, recovery, companion, and last-adapter entry points. Require validation before credentials or mutation commands; remove/bypass each guard in a separate negative fixture. Keep scan scope independently declared so absent jobs cannot disappear from the check.

### ExUnit mutation tests

**Analogs:** `test/crosswake/release_candidate/workflow_test.exs:312-363,393-455` covers full success and child failures. `test/crosswake/proof/phase175_runbook_ancestry_test.exs:43-79,111-143` seeds exact Git-object failures and removes a workflow invocation. `test/support/release_workflow_fixtures.ex:83-105,143-151` makes a missing mutation target fail.

```elixir
if not String.contains?(text, pattern), do: raise("mutation target missing")
changed = String.replace(text, pattern, replacement, global: false)
if changed == text, do: raise("mutation did not change fixture")
```

Use one complete positive envelope, then mutate each condition and identity, empty/truncated registry body, wrong row/run, stale OID, changed policy, admin bypass, and ancestry. Remove each publisher guard independently and assert scanner failure. The current `phase175_release_recovery_test.exs:7-50` only covers receipt artifact roster; do not assume it contains the broader archived fixtures.

### Mix gate and status

**Status analog:** `lib/mix/tasks/crosswake.release.status.ex:1-25,29-70` is read-only, uses `Mix.Task`, supports JSON/live, prints before exit, and uses exit 3 for inability to verify. `lib/crosswake/release_status.ex` is the planned shared status implementation. Report BLOCKED with concise missing condition and safe next step: gather fresh evidence and request a new candidate-specific gate. Preserve historical PARTIAL. Do not print raw registry bodies, credentials, or sensitive candidate material or recommend retry/resume.

**Gate analogs:** `lib/mix/tasks/crosswake.release.status.ex` for task argument/output conventions and `script/release_candidate/require_release_evidence.sh` / the guarded publisher scripts for last-boundary enforcement. Gate capture must be fresh at authorization and at each publisher boundary; status remains read-only and READY FOR APPROVAL is not permission.

### Companion receipt

**Analog:** `lib/crosswake/release_candidate/evidence_input.ex` for exact evidence selection, canonical bytes, and source digests; `lib/crosswake/release_candidate/workflow.ex` for reconstructing a validated result from explicit input. `companion_receipt.ex` is package-scoped and pure; its Mix task writes a local record and digest, but grants no authorization and triggers no publication. Keep companion publication outside the six-child core rollup.

### Evidence records

**Analogs:** tracked phase-local `evidence/175-fresh-candidate-pr.json`, `evidence/175-fresh-core-release-run.json`, and `175-FRESH-CANDIDATE-EVIDENCE.md` show separate PR identity, ordinary-run, and readable summary roles. Plans 175-37..39 use `175-next-successor-candidate.json`, `175-next-successor-rehearsals.json`, `175-next-successor-receipt.json`, `175-next-successor-premerge.json`, `175-next-successor-gate-2.json`, `175-next-successor-postmerge.json`, `175-next-successor-core-run.json`, `175-next-successor-core-registry.json`, and `175-next-successor-proof.json`, with readable candidate/proof records. Keep historical 0.2.4/0.2.5 files untouched and PARTIAL. Preserve order: REL-17 gate closure (175-34..36), fresh successor evidence (175-37), exact Gate 2 and normal core run (175-38), same-run exact-public and six-child proof (175-39), then held PR #115 and distinct Gate 3 (175-40), followed by reconciliation (175-41). Plan 175-40 carries PR #115 identity and its actual merge OID through the companion evidence chain; it must not substitute another PR. The companion registry check remains independent of core COMPLETE.

## Shared Patterns

- **Fail closed:** `evidence_input.ex:460` and `workflow.ex:194` reject invalid evidence. Shell/API pipeline failure or partial response must never become success.
- **Exact identity:** `release-please.yml:85-125` and `check_release_runbook_ancestry.sh:19-56` bind Git objects, receipt and runbook ancestry. REL-17 adds operation/run, policy and no-bypass proof.
- **Historical truth:** `workflow.ex:43-48` keeps BLOCKED, PARTIAL, COMPLETE distinct. D-49's old Maven roster and iOS Jason faults are historical observations, not the current REL-17 repair list.

## No Analog Found

No current code implements the full six-condition REL-17 envelope, pagination-complete live policy/registry capture, or verified no-admin-bypass publication guard. The planner must design these from D-43–D-46 and prove positive plus mutated negative cases. Existing code supplies placement, parsing, identity, and fail-closed conventions.

## Metadata

**Search scope:** tracked release-candidate modules, Mix task, release workflows, publish/ancestry scripts, scanner, ExUnit fixtures, and Phase 175 evidence.
**Boundary:** REL-17 first; fresh successor and separate companion later. No Phoenix, Plug, Ecto, UI, generic retry/sync, dashboard, live publication, registry action, or reused Gate 2 token.

## Follow-up Pattern Assignment — D-57..D-61

### New source-boundary receipt and evidence

**Closest analog:** Plan 175-53's exact `BLOCKED_PREFLIGHT` receipt contract and
`evidence/175-ios-tag-026-plan53.json`, paired with `175-53-SUMMARY.md`. Preserve those as immutable
history. A distinct follow-up (expected Plan 175-54) should write its own versioned receipt under the
existing `evidence/175-ios-tag-026-planNN.json` convention; never change or promote Plan 175-53's
digest. Keep the new receipt bounded, canonical, digest-checked, and durably written/read back before
remote observation. Classify only observed facts: a closed split-result enum, nullable process status,
normalized Git version, and explicit known/unknown history, source-commit, OID, and split-commit
availability. Do not infer a root cause from a missing OID.

The Plan 175-53 shape is useful for stage, stable reason, zero-write/null-decision and privacy
invariants. Its fixed `FULL_CLONE_SPLIT_FAILED` reason alone is insufficient to distinguish the
observed source outcomes; add the closed result class under a new receipt schema version rather than
mutating a historic receipt or broadening the shared release status API.

### Capture boundary and classification

**Closest code patterns if a narrowly scoped helper proves necessary:**

- `lib/crosswake/release_candidate/companion_receipt.ex:1-65,199-203` for pure deterministic
  classification/building from an exact input map, closed keys, schema version, and stable generic
  errors. Its external action is explicitly absent; keep command invocation outside the classifier.
- `lib/crosswake/release_candidate/receipt.ex` and
  `lib/crosswake/release_candidate/evidence_input.ex:53-82,130-147,381-460` for canonical sanitized
  data, exact input selection, digest binding, bounded reads, and fail-closed validation. Do not reuse
  a release candidate receipt type when the source-boundary facts have a different domain.
- `lib/mix/tasks/crosswake.release.status.ex:1-70` and
  `test/mix/tasks/crosswake_release_status_test.exs` for the established Mix text/JSON surface and
  output/exit behavior. Maintain stable plain-text wording and one safe next action; no color-only
  meaning and no raw streams or command details.
- `test/crosswake/release_candidate/companion_receipt_test.exs:1-110` for positive and malformed
  exact-schema fixture style if implementation work is justified. Planning/evidence-only work does
  not itself require a new test suite or permanent CI lane.
- `script/release_candidate/ios_mirror.sh` is the nearest shell/Git adapter location. Keep direct
  Git execution at that boundary if code is actually needed; preserve stdout/stderr separation in
  ephemeral handling, and never persist raw output, argv, environment, paths, remote details,
  credentials/helper configuration, or hashes of raw streams.

Prefer recording this one-off source attempt in the phase's evidence over adding a generalized retry,
recovery, dashboard, product API, or CI subsystem. An automatic correction is permitted only if
the one fresh attempt proves a local clone/invocation setup defect; source/path/policy correction
requires a reviewed follow-up. No automatic retry follows any ambiguous outcome.

### Conditional continuation and maintainer UX

If and only if the fresh split passes, Plan 175-54 should start a complete new read-only preflight,
calculate a new digest, durably reserve, and permit at most one authenticated `git push --dry-run
--porcelain` after every gate passes. It then captures planned post-observations and an independent
audit against that new receipt. A failure or ambiguity at any stage is terminal; no old fact or
receipt is reused. This follows the ordering in Plans 175-50..53 while preserving each attempt's
identity. Even a passing audit grants no tag write, merge, Gate 2, recovery, or publication authority;
REL-13/REL-17 and the release hold remain open.

This is a maintainer-only CLI/evidence workflow, not a browser interaction. No UI spec, Phoenix,
Plug, or Ecto surface applies. Reuse Mix's existing human-readable and JSON conventions with a stable
reason, current stage, and one safe next action.
