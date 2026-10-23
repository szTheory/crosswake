---
phase: 176-local-work-and-artifact-disposition
reviewed: 2026-10-12T01:38:08Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.test.mjs
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.md
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-VALIDATION.md
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-CONTEXT.md
findings:
  critical: 7
  warning: 4
  info: 0
  total: 11
status: issues_found
---

# Phase 176: Code Review Report

**Reviewed:** 2026-10-12T01:38:08Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the Phase 176 evidence helper and fixtures, its generated inventory and rendering, execution summaries, validation record, and plans/context as the contract. The summaries report a 115-row capture, 166 restored units, and zero restore limitations. The helper still has gaps that can accept a false final audit, skip gate conditions and staged-state checks, or read a path after its parent changes to a symlink. The validation delta also rejects required closeout edits. The documented 25/25 fixture result was not rerun as part of this review.

## Critical Issues

### CR-01 [BLOCKER]: Final audit does not detect same-status changes made after its content checks

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:664-669`
**Issue:** After validating captured files and writing a passing sidecar, the final guard hashes only porcelain status. A worktree file can change to different bytes while retaining the same ` M`/`??` status, and an index blob can change while retaining the same status class. The audit then returns a pass for bytes it did not validate after the race. This contradicts the plan's final rescan requirement.
**Fix:** After the sidecar write, re-read HEAD/tree, full index records, status records, and every captured/guard worktree snapshot (including writer paths); compare them with the validated snapshots. Remove or mark the sidecar failed if any differ.

### CR-02 [BLOCKER]: Conditional gate entries are accepted without their activation condition

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:570-591,648-652`
**Issue:** The writer ledger carries `conditionMet`, but validation never requires or checks it. Any changed allowlisted conditional path is accepted; most such paths receive no content validation at all. The UAT path is checked only for assertion shape/results, not proof that its owning gate ran. An unrun verification, security, review, or learnings gate can therefore be recorded as an owned delta and pass `audit --final`.
**Fix:** Require `conditionMet === true` for each changed conditional entry and bind it to evidence that the named gate actually ran and produced that exact artifact. Reject ledger entries whose activation evidence is missing or false.

### CR-03 [BLOCKER]: Writer-owned files bypass the captured index check

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:647-654`
**Issue:** A recognized writer path immediately `continue`s after checking its worktree delta. The audit never compares its current index stages with the captured `guard.index` or captured row index. A staged edit to STATE, ROADMAP, REQUIREMENTS, VALIDATION, or state.json can therefore be included in a passing final audit even though only the worktree edit was scoped.
**Fix:** For every writer path, require its complete index stage records to equal the frozen capture unless that writer has an explicit, separately validated index delta. Perform this check before accepting the writer's worktree delta.

### CR-04 [BLOCKER]: Path checks are vulnerable to symlink-parent replacement between check and read

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:91-98,110-116,288-311`
**Issue:** Capture checks parents with `lstat`, then opens the path later through `readFileSync`. A concurrent process can replace a checked parent directory with a symlink in between, causing capture to read and archive an outside file despite the no-follow checks. Rechecking afterward can detect some changes, but does not undo disclosure of the outside bytes already copied.
**Fix:** Read through no-follow file descriptors anchored beneath verified directory handles, checking descriptor identity against the expected in-checkout path. Where the host cannot provide that guarantee, fail closed for concurrently mutable/untrusted trees instead of reading through a path string after a separate check.

### CR-05 [BLOCKER]: Sensitive-path exclusion misses common credential and token filenames

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:12,105-109,294-300`
**Issue:** Payload exclusion is based on `.env` and a short extension list (`pem`, `p12`, `asc`, `gpg`). Files such as `credentials.json`, `token.json`, `.npmrc`, or extensionless key files are treated as ordinary payloads and copied into the private archive. That does not meet the project's rule to keep credential and token material in its existing protected location.
**Fix:** Use a reviewed, explicit sensitive-path policy that covers credential/token/key families and safe exceptions, and make unknown credential-like cases opaque and excluded by default. Add fixtures proving both excluded and explicitly safe paths without printing payloads.

### CR-06 [BLOCKER]: The private manifest is trusted without an integrity check

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:339-360,392-428`
**Issue:** The archive manifest is writable by its owner and `readManifest` checks only shape, duplicate identities, and private permissions. Its worktree payloads have no integrity value independent of the manifest. If a same-status source file changes after capture and the matching private manifest payload is edited to those new bytes, `verify` can accept the altered bytes as the captured recovery content because the baseline status class remains the same. Thus “immutable capture” is a convention, not verified integrity.
**Fix:** Bind the complete manifest and payload set to a separately recorded capture integrity value at finalization, verify it before every read/restore/audit, and fail if the archive changed. Keep that integrity record private; do not emit payload hashes or private pointers into public artifacts.

### CR-07 [BLOCKER]: Audit trusts mutable comparison, recovery, and policy claims in the public inventory

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:549-568,618-627`
**Issue:** `validatePublicRows` binds row IDs, paths, and status to the private capture, but does not validate the row's comparison, recovery, or policy facts. For `retain`, it does not require any comparison structure at all; for `already merged`, it checks only that commit/tree fields look like hashes, not that they are one of the validated candidates or match a byte comparison. Editing those fields and regenerating the Markdown still passes the audit, so downstream disposition can rely on fabricated recovery/merge evidence.
**Fix:** Validate every evidence field against frozen private facts and a closed set of independently verified candidate commit/tree identities. Store or recompute the per-path equality results; reject `already merged` unless exact captured units match the named candidate. Treat policy facts as recomputed outputs, not editable annotations.

## Warnings

### WR-01 [WARNING]: Validation sign-off allowlist rejects required closeout edits

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:813-818`
**Issue:** The validator permits only six hard-coded checkbox prefixes, while Phase 176 validation also requires updating the per-task status table, the remaining sign-off checks, and the approval text. Those legitimate GSD closeout edits make `audit --final` fail even when they accurately record completed evidence.
**Fix:** Add narrowly anchored rules for the exact task-table cells, required sign-off checkboxes, and approval field, while keeping all other validation bytes immutable. Exercise the actual final validation document delta.

### WR-02 [WARNING]: The Markdown inventory omits the evidence needed to distinguish retained rows

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:836-851`
**Issue:** The renderer prints only path, disposition, reason, and next owner. It drops each row's exact candidate comparison, recovery result/limitations, and policy classification, and provides no link to the JSON evidence. The resulting report says all rows are unknown and repeats the same retain reason, so a maintainer cannot tell from the human rendering which bytes were restored, which comparisons matched, or what residue needs a policy review.
**Fix:** Keep the summary concise, but include the per-row equality/recovery outcome and relevant policy category, and link to the machine-readable inventory for details that do not fit the rendering.

### WR-03 [WARNING]: Phase 177 actions are too generic to dispatch the retained work

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-INVENTORY.json:45-60`
**Issue:** Source rows repeat “Phase 177 source owner” and ask for review with linked tests/scripts/workflows/generated contracts, without naming the actual subsystem owner or exact linkage/action for that row. This leaves Phase 177 with a 70-row review bucket instead of the bounded owner/action handoff required by the plan. Keeping rows in `retain` is justified while semantic review is pending; the missing part is actionable ownership.
**Fix:** Assign each source row to its actual module or artifact owner and name the direct test/workflow/source edges to inspect. Keep historical and scratch residue in a separate maintainer-owned list with a specific provenance check.

### WR-04 [WARNING]: An empty UAT assertion list passes

**File:** `.planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-evidence.mjs:673-681`
**Issue:** `validateUat` accepts `{ assertions: [], humanOnlyUnmet: false }`. Since it has no required assertion set or minimum coverage check, an empty artifact can satisfy the conditional UAT writer check without proving any UAT criterion.
**Fix:** Bind UAT results to the expected assertion IDs for the phase and require every expected ID exactly once with a passing required result; retain the no-human-checkpoint behavior for fully automated assertions.

---

_Reviewed: 2026-10-12T01:38:08Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
