---
phase: "176"
slug: "local-work-and-artifact-disposition"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-11"
---

# Phase 176 — Validation Strategy

This is a planning contract. No inventory, recovery archive, restore result, or maintenance requirement is complete merely because this file exists.

## Test Infrastructure

| Property | Value |
|---|---|
| Framework | Installed Node built-in test runner plus actual Git integration fixtures |
| Config file | No additional configuration or dependency |
| Quick run command | `node --test .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs` (created by the leading tracer task) |
| Full phase suite | The focused fixture suite plus `capture`, full `verify`, provisional task audit, and `audit --final` after all GSD-owned writers; the live commands require a concrete authorized `CROSSWAKE_RECOVERY_ROOT` |
| Repository-wide final command | `script/verify_repository.sh --all` belongs to Phase178 on exact clean source; do not run it as this phase's gate on the recovery checkout |
| Estimated runtime | Target under 60 seconds for fixture feedback; live snapshot/restore time depends on inventoried material and is measured during execution |

## Sampling Rate

- After each task: run its automated assertion and the focused fixture suite when helper behavior changes. Task commits are prohibited in the recovery checkout.
- After each wave: check the produced evidence, unchanged source/index/HEAD, and the wave's restore or path-coverage promise. Include the already-created workstream `state.json` in the capture and its installed GSD writer ledger. A Plan 02 Task 3 audit is provisional until GSD has written summaries and progress/verification artifacts.
- Before phase verification: all required coverage and actual restoration checks must pass. Unavailable durable storage, incomplete capture, or skipped recovery cannot be reported as a pass. After GSD verification and its phase-completion/handoff writers, `audit --final` is the last orchestration gate; a later file write invalidates that result.
- Keep tests and evidence phase-local. No permanent reconciliation CI lane and no changes to repository runtime APIs are planned.

## Per-Task Verification Map

Each task's PLAN.md carries an automated command and an immediate observable `fails_when` signal. Live commands use the same execution-selected private root; a temporary root is valid for fixtures only.

| Outcome | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|
| 176-01 Task 1 — fixture tracer | MAINT-01, MAINT-02 | T-176-01, T-176-02 | Real capture→private preservation→restore→sanitized disposition | Actual temporary Git integration fixture | `node --test --test-name-pattern="tracer capture restore" .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs` | Yes | Pass — 1/1 |
| 176-01 Task 2 — exact record shapes | MAINT-01, MAINT-02 | T-176-01 | Both rename names and exact index/worktree kind, mode and bytes survive; adverse subprocess/drift fails | Actual Git/filesystem fixture | `node --test .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs` | Yes | Pass — 35/35 |
| 176-01 Task 3 — policy and privacy | MAINT-02, MAINT-04 | T-176-02, T-176-03 | Policy facts remain distinct; concurrent/partial archive and public leaks fail; GSD progress edits pass only their named scoped writer rules | Policy, competing-subprocess and owned-delta fixture | `node --test .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs` | Yes | Pass — 35/35 |
| 176-02 Task 1 — live capture tracer | MAINT-01, MAINT-02 | T-176-04, T-176-05 | Owner-protected durable archive; one real row read back and restored; source retained | Live capture plus materialized single-row restore | `node .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs capture --repo . --archive-root "$CROSSWAKE_RECOVERY_ROOT" --public .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json` | Yes; captured and rendered| Pass — successor capture, private read-back and real-row restore succeeded |
| 176-02 Task 2 — full restore and comparison | MAINT-01, MAINT-02 | T-176-04, T-176-06 | Every eligible unit restores; merge claims require validated commit/tree | Live private read-back, scratch restore and artifact assertions | `node .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs verify --repo . --archive-root "$CROSSWAKE_RECOVERY_ROOT" --public .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json` | Yes; captured and rendered| Pass — 170 restored units; 0 limitations; pinned default-tip provenance verified |
| 176-02 Task 3 — owner map and provisional handoff audit | MAINT-01, MAINT-02, MAINT-04 | T-176-05, T-176-07 | Complete policy/generator map, expected writer coverage, safe current rendering | Provisional artifact and live-status audit | `node .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs audit --repo . --archive-root "$CROSSWAKE_RECOVERY_ROOT" --public .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json --rendered .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.md` | Yes; captured and rendered| Pass — 119-row owner/policy rendering; provisional audit passed |
| Post-GSD orchestration gate — final writer audit | MAINT-01, MAINT-02, MAINT-04 | T-176-04, T-176-07 | Captured original bytes remain immutable; actual summary, STATE.md, ROADMAP.md, REQUIREMENTS.md, installed-GSD `state.json` projection, validation and conditional verification/review/security/learnings deltas have named owners and allowed scope; unexpected changes fail | Final full-status audit after all expected writers | `node .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs audit --final --repo . --archive-root "$CROSSWAKE_RECOVERY_ROOT" --public .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json --rendered .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.md` | Yes | Pass — bound private audit; rerun after final sign-off |

## Wave 0 Requirements

- Create the small phase-local evidence helper and fixture suite in the first tracer task before expansion.
- Exercise installed Git/subprocess output, rename's two paths, staged then unstaged content, deletion, binary, executable mode, symlink/type changes, unmerged entries, unusual pathname bytes where supported, and changed-baseline rejection.
- Exercise nonzero exit, spawn error, signal/timeout and privacy-safe failure rendering with actual subprocesses. A fixture must assert behavior rather than reproduce the parser's own expectations.
- Record unsupported fixture cases and their causes; required coverage cannot silently disappear.
- Test payload/path/link/digest sentinels must not occur in public output. Known secrets must not be read or copied.
- Exercise GSD-shaped post-capture edits to captured STATE.md and ROADMAP.md after the planner has marked the phase ready for execution. Assert that only Plan 02 Task 3's named frontmatter keys, body lines, and roadmap cells/spans may change; every other captured byte stays identical. A valid Phase 176 completion/Phase 177 handoff passes, while a historical rewrite inside the shared Exact Next Action section, an unrelated edit, an unowned artifact, or a changed captured source path fails. Exercise an exact named new verification artifact.
- Use the installed `state-contract.cjs` publisher with temporary canonical STATE.md/ROADMAP.md fixtures to make a real workstream `state.json` delta. Accept only `updated_at`, Phase 176 status, Phase 177 handoff status and `next.command`/`next.label`/`next.reason` changes under the observed six-key/three-phase shape. Reject changed contract, flavor, milestone, phase number/name, Phase 178 status, key shape/order, or unrelated history. The helper audits this existing projection; it does not publish a competing one.
- Exercise a conditional `176-UAT.md` with all required automated assertions passing and no human checkpoint; it passes the artifact gate. A failed/pending required assertion or genuinely unmet human-only assertion blocks. File existence alone never determines the verdict.
- No tool installation or new test framework is required.

## Manual-Only Verifications

All phase assertions use automated verification. Durable external storage may require a concrete filesystem permission at execution time; that permission enables a write and does not replace automated restore proof. Keep source intact if no authorized persistent root can be used. Do not ask for conversational verification of inventory or recovery.

## Validation Sign-Off

### Plan 176-01 Execution Evidence

- Before the executor spot-check repairs, the tracer command passed 1/1 and the full focused suite passed 21/21. The repaired fresh run now passes 25/25 on installed Node and Git.
- Actual CLI fixtures passed capture, verification, rendering, and provisional audit. Temporary archive use required the explicit fixture-only flag; the same CLI rejected temp storage without it.
- The real installed GSD `publishStateContract` wrote the temporary workstream projection. Tests accepted the Phase 176/177 delta and rejected changed identity, Phase 178 status, and key-shape changes.
- TDD RED evidence for duplicate private path identity and malformed required UAT assertion was accepted by `gsd_run check tdd-red-evidence`; both target tests passed after the fail-closed fixes.
- Scratch verification fetches the public base commit into an independent repository, reconstructs supported index stages and worktree entries, and compares Git status plus `ls-files --stage`; unreadable and Gitlink rows remain explicit, uncounted limitations.
- Additional fixtures prove that same-status byte races leave only a partial archive, archive roots are rejected for exposed permissions/symlinked parents/temp/shared/nested-checkout placement without auto-chmod, random opaque IDs change between attempts, and restore preflight rejects path collisions and symlink traversal.
- Plan 01's fixture proofs do not mark MAINT-01/02/04 complete; requirement completion remains gated on the live Plan 02 evidence and final writer audit.
- macOS rejected creation of an invalid UTF-8 filename with `EPERM`; a raw Git status record with an invalid UTF-8 byte was parsed losslessly and kept opaque. The filesystem round-trip case remains a host limitation.
- No durable archive or live recovery checkout was used in this plan. Plan 02 and the final orchestration audit remain pending.

- [x] Final task IDs and exact commands aligned with the checked plans
- [x] Every task has an automated assertion and observable failure signal
- [x] Leading tracer supplies all missing helper/fixture paths before dependent tasks
- [x] No three consecutive tasks without automated feedback
- [x] Actual private archive read-back and materialized restore pass
- [x] Complete changed-path coverage, policy mapping and source preservation pass
- [x] Final `audit --final` runs after both summaries, GSD progress/completion/handoff updates, and any actual validation, verification, security, review or learnings writer; private sidecar records owned deltas against the unchanged capture
- [x] The already-created workstream `state.json` is captured and its normal installed-GSD publication is audited against only the named mutable keys, with identity and other phases preserved
- [x] Any `176-UAT.md` creation is accounted for as a conditional writer; passing automated assertions can close the gate without human UAT, while failed/pending required assertions or unmet human-only assertions block completion
- [x] No watch commands, source cleanup, Git mutations or final-source CI substitution
- [x] `nyquist_compliant: true` set only when the validation audit supports it

**Approval:** Corrected capture and restore, 35/35 fixtures, 13/13 verification and post-writer audit passed. Recheck the final audit after this sign-off; keep both earlier attempts preserved as non-authoritative history.

## Validation Audit 2026-10-11

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
