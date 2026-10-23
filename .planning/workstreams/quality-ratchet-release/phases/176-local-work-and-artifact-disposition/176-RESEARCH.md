# Phase 176: Local Work and Artifact Disposition - Research

**Researched:** 2026-10-11  
**Domain:** Git worktree inventory, private artifact recovery, and repository policy  
**Confidence:** HIGH for project contracts and Git record semantics; MEDIUM for recovery implementation until exercised against a fixture

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The user selected all three areas and delegated a coherent recommendation set, including parallel primary-source research, relevant project prompts, ecosystem lessons, tradeoffs, and an adversarial pass. Adopt the recommendations below without another preference questionnaire. This settles discussion choices; it does not grant unbounded execution, deletion, publication, or Git authority.
- **D-02:** The discussion observed checkout `recovery/phase-175-orchestrator-2026-09-27`, HEAD `d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377`, with 48 tracked modifications and 54 non-ignored untracked files before discussion artifacts. These are scope observations, not a completed inventory, merged-code comparison, or recovery proof. Execution must enumerate its fresh baseline, including later planning changes, rather than enforce the old counts.

### Complete inventory and comparison

- **D-03:** Maintain one dated phase-local inventory, with a concise human rendering and machine-readable evidence where useful. Record the canonical inspected checkout, HEAD, relevant index state, and exact committed trees used for comparison. Establish which commits actually merged; moving branch names, release numbers, stale local refs, or an older green run are insufficient. Keep private filesystem pointers out of committed evidence.
- **D-04:** Enumerate staged, unstaged, deleted, renamed, type/mode-changed, and non-ignored untracked paths with NUL-safe Git output, such as `git --no-optional-locks status --porcelain=v1 -z --untracked-files=all`. Parse rename records correctly and preserve both paths. Record unmerged entries, gitlinks/submodule state, unusual filenames, unreadable paths, and classification failures explicitly. Never silently skip a record or assume every record is a text file.
- **D-05:** Give every required path exactly one of the roadmap's five dispositions: **retain**, **already merged**, **ship as bounded maintenance**, **preserve outside the working source**, or **remove as proven transient**. Include reason, comparison or policy basis, recovery outcome where applicable, and the next owner/action. Uncertain or unreadable work is retained with its limitation explained; uncertainty never grants removal authority. No sixth “mixed” status is needed.
- **D-06:** Use path rows for complete coverage and subordinate behavior/hunk records for partial merges. A path with merged and unique changes remains **retain** until its remaining work has an evidenced bounded disposition. Compare linked source, tests, scripts, workflows, generated outputs, and evidence as independently accountable paths grouped around the same invariant. Matching names, line counts, patch IDs, tests, or similar text only aid triage.
- **D-07:** Distinguish exact byte/mode/type equality from reviewed semantic equivalence. An **already merged** claim names the exact merged commit and its supporting comparison. If local text differs despite equivalent behavior, preserve the differing bytes; semantic equivalence does not make exact local work recoverable. Bound investigation to direct ownership edges. Phase177 retains the full supported-caller and dynamic-entrypoint retirement gate; Phase176 must not label uncertain code dead prematurely.

### Recovery location, privacy, and proof

- **D-08:** Adopt hybrid preservation: keep the sanitized inventory, dispositions, safe provenance, and recovery results in the phase record; keep raw recoverable bytes in a private durable archive outside every working source checkout and outside git. Reuse the v23 original-artifact manifest/verification pattern where appropriate, without copying its historical content into a new authority store.
- **D-09:** Use a maintainer-controlled persistent location with owner-only access where supported (`0700` directories and `0600` archive/manifest files). Prefer existing protected local storage; introduce no backup service, encryption dependency, credential flow, or unreviewed sync destination. Temporary directories are restore scratch and never count as durable preservation. Do not claim external backup coverage unless it is established. If durable authorized storage is unavailable, keep source intact and report the blocked preservation step.
- **D-10:** Preserve exact changed/untracked bytes and the metadata needed to reconstruct file kind, executable mode, deletions, symlinks, and staged versus unstaged content. A file snapshot is the recovery authority; binary-capable full-index patches may aid reconstruction. A Git bundle is optional only for relevant unique local commits/refs; it cannot substitute for uncommitted or untracked material. Do not archive the whole repository history, global temporary state, or unrelated credentials.
- **D-11:** Keep raw diffs, archive contents, sensitive digests/sizes, symlink targets, credential contents, private absolute paths, and unsafe filenames out of proof, logs, and committed artifacts. Safe repository-relative paths can identify ordinary source rows; use opaque row IDs for sensitive paths, with their mapping only in the private manifest. Never follow symlinks to copy unrelated targets. Known secret-bearing material stays in its existing protected location unless separately authorized preservation can handle it safely; report its metadata/limitation without reading or printing values.
- **D-12:** Verify preservation through read-back and restoration into fresh isolated scratch. Compare actual restored content/type/mode/link metadata and reconstructed staged/unstaged state against the captured manifest. Preserve link identity rather than flattening its target. Include deleted/type-changed and binary cases where present. A successful copy command, patch creation, or archive listing alone is insufficient recovery evidence. These are automated assertions, not human UAT.
- **D-13:** Keep recovery material through Phase178 and until all affected dispositions are reconciled. Material still designated **preserve outside the working source** remains retained. Do not automatically expire or delete the recovery archive at milestone close; its later retirement needs a concrete, separately scoped decision. Store absolute recovery pointers and sensitive metadata only in the private manifest.

### Artifact authority and cleanup timing

- **D-14:** Use `script/repository_artifact_policy.json` as the existing owner of ignored transient families, intentionally tracked source/contracts, forbidden tracked residue, safe fixtures, and generated-output declarations. `.gitignore` is a convention layer; global ignores and `.git/info/exclude` are not repository policy. Ignored, obsolete, forbidden to track, and disposable are separate facts.
- **D-15:** `.tmp/` and `.planning/tmp/` do not inherit the policy's root `tmp/` rule. Old red-test output, orchestration state, numbered tag-apply experiments, debug records, and locks are not disposable because of their names or age. Inspect provenance and usage, preserve unique material, and retain uncertainty. Do not hide unique source under a new broad ignore rule to obtain clean status.
- **D-16:** Each generated-contract row names its existing canonical source, regeneration argv, outputs, and drift-check owner. Reuse `mix crosswake.contract.gen`, its `--dev` form, and `mix crosswake.docs.sync` where declared. Preserve existing changed bytes before any regeneration, and run potentially writing regeneration in isolated scratch. A generated projection cannot replace its source or justify direct hand-editing. Do not add a competing registry.
- **D-17:** Complete Phase176 with the inventory, five-disposition record, verified private recovery, and generated-contract ownership map. A disposition describes what should happen and its owner; it does not claim that a removal or maintenance change has executed. No deletion or source cleanup is required for this phase to pass. Keep the recovery checkout intact apart from scoped planning/evidence writes, with no staging, commits, branch switching, or worktree changes in it.
- **D-18:** If an execution plan includes optional cleanup, it is limited to exact invocation-created, policy-recognized scratch whose ownership and permitted write scope are proven. Recovery comes before any unique-byte removal. Recheck path containment, kind, relevant hashes, and baseline immediately before and after the grouped action; changed or escaped paths stop the remaining actions and require re-inventory. No recursive blanket cleanup, `git clean`, broad reset/restore, or retry of uncertain delivery. Existing user-owned leftovers are not invocation-owned scratch.
- **D-19:** Preserve historical artifacts and their verdicts; link to archived evidence instead of rewriting it. Phase175 remains archived at 8/9 with REL-10 breached; Phase174 remains the last fully passed phase. Do not consume or revive old approval bindings or use Phase175 release authority for maintenance deletion, merges, or publication. No adopter support promotion, Android breadth, or new companion/native/sync surface follows from cleanup.

### Maintainer experience and verification cost

- **D-20:** The maintainer's job is to learn what changed, where it belongs, how to recover it, and what happens next. Start output with coverage, findings, unknowns and their cause, whether anything was changed/removed, and the next action. Keep detailed comparison/recovery internals in linked artifacts. Use ordinary purpose-led text, safe escaped path display, textual outcomes, and one concrete correction; do not require hash copying or a prompt per read/parser/bookkeeping step.
- **D-21:** This is repository maintenance, not a runtime feature. Use Git and existing standard-library helpers and supported Mix commands. Prefer a small local evidence routine to a new dependency, Mix API, workflow, dashboard, or cleanup framework. Plug/Ecto/Phoenix runtime abstractions and product UI design are unnecessary here; preserve their supported contracts and host ownership.
- **D-22:** Verification should protect this phase's actual promises: path coverage, exact-source comparisons, declared policy mapping, privacy-safe rendering, and recovery. Exercise any new helper using the installed Git/subprocess return shapes and a temporary local fixture, with actual unusual-path, rename, staged/unstaged, binary, symlink/mode, and changed-baseline cases relevant to its behavior. Do not add tests that merely mirror a one-time implementation or promote a reconciliation lane into permanent CI. Reuse existing recurring artifact/drift guards.
- **D-23:** Hand Phase177 a bounded list of useful unique source units, uncertain candidates, known residue, and exact actions supported by the inventory. Keep source promotion/retirement there. Phase178 verifies the selected exact source with the existing complete facade and matching hosted CI; a dirty recovery checkout is not its proof target. Correct stale active instructions there, including PROJECT.md's “No new scope is selected” paragraph now that v24 scope is approved.

### the agent's Discretion

- Exact phase-local evidence filenames, row IDs, rendering, recovery layout, and bounded inspection order, using existing schemas/patterns where useful and no new permanent public contract.
- Exact persistent private storage root within available authorized filesystem scope; do not turn storage selection into a new preference interview. Lack of a safe permitted root blocks removal rather than forcing a temporary copy to qualify as durable.
- Group routine inspections and checks by the outcome they support. No additional owner preference remains unresolved in this discussion. Any genuinely missing execution authority, credential, or external trust action must be handled at its concrete boundary.

### Deferred Ideas (OUT OF SCOPE)

- Phase177: actual supported-path retirement/shipping, dynamic caller proof, active instruction repair, and open GitHub PR/issue reconciliation.
- Phase178: complete clean-checkout verification, final-source CI, and source identity agreement.
- Recovery-archive retirement requires a later concrete scoped decision; it is not automatic milestone cleanup.
- Runtime feature breadth, product UI, new dependencies/frameworks/standing CI lanes, release publication, and adopter/Android promotion remain outside v24 scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MAINT-01 | Maintainer can inspect an inventory of every local change against merged code, with the compared source commits named. | NUL-safe status and staged/worktree comparisons; fresh source commit identity proof; path/hunk evidence. |
| MAINT-02 | Maintainer can see a disposition for each inventoried change and recover unique work before any removal. | One five-way disposition per path, private exact snapshot, read-back and isolated restore assertions, fail-closed storage boundary. |
| MAINT-04 | Maintainer can distinguish tracked contracts, ignored transient files and forbidden residue using the existing repository artifact policy. | Apply the existing policy categories and safe fixture exceptions; keep ignore status separate from disposability. |
</phase_requirements>

## Summary

Implement this as a dated, phase-local inventory plus a private durable snapshot and automated restore rehearsal. The canonical comparison is byte-oriented Git status/index/worktree evidence tied to exact merged source commit trees. Status and similar diffs identify candidate relationships; they do not alone establish that behavior is already merged. [CITED: https://git-scm.com/docs/git-status] [CITED: https://git-scm.com/docs/git-diff]

Use the checked-in repository artifact policy and existing Node/Git/standard-library tooling. Keep source changes in place; Phase176 succeeds with complete coverage, dispositions, verified private recovery, and a generated-contract owner map. It does not remove source or complete Phase177 retirement or Phase178 full clean-source proof. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/176-local-work-and-artifact-disposition/176-CONTEXT.md:10-12,43-47,54-55]

**Primary recommendation:** Build one small one-time evidence routine that captures raw Git metadata and path bytes, produces a redacted committed rendering, snapshots changed payload outside source control, and proves restoration in isolated scratch. If the only writable durable roots remain the checkout and temporary storage, preservation is blocked and source stays untouched; a temporary archive does not satisfy the recovery requirement.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Changed-path inventory and exact comparison | Local Git repository | Node evidence routine | Git owns index/tree/status truth; a small local routine parses and records it. |
| Artifact classification and generated-owner map | Repository policy files | Mix generator tasks | The existing policy names classifications and declared projections; task source files identify actual generator behavior. |
| Raw recovery and restore proof | Private local filesystem | Isolated scratch checkout | Exact payload must stay outside every source checkout; restore validates materialized content and metadata. |
| Human summary and sanitized evidence | Phase176 workstream record | Private manifest | Reviewable decisions belong in git; sensitive locations and payload metadata stay private. |

## Standard Stack

### Core

| Tool | Observed version | Purpose | Why standard |
|------|------------------|---------|--------------|
| Git | 2.41.0 `[VERIFIED: local `git --version` observation]` | Status/index/tree inventory and commit comparisons. | Git porcelain, index entries, and tree diffs describe this repository's source state. |
| Node.js | 26.10.0 `[VERIFIED: local `node --version` observation]` | Small local parser, filesystem snapshot/restore helper, and built-in test runner. | The existing repository verifier and JavaScript tests use Node standard libraries; no install is needed. |
| Mix | 1.19.5 (OTP 27) `[VERIFIED: local `mix --version` observation]` | Invoke the already-declared contract/document generators only in isolated scratch. | Existing generated owners are Mix tasks; do not run them against the recovery checkout. |

Versions above are observations from this research environment, not new compatibility requirements. No external package is required, so no package-legitimacy audit or installation step applies.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Exact file snapshots plus restore rehearsal | `git diff --binary --full-index` alone | Binary patches help reconstruct tracked changes but omit untracked files and are not proof that kind/mode/link/index state restores. [CITED: https://git-scm.com/docs/diff-options] |
| Existing artifact policy | `.gitignore` or global exclude alone | Ignore rules express matching behavior, not repository ownership, safe fixtures, or proof that a file is disposable. [VERIFIED: script/repository_artifact_policy.json:3-19,68-103,135-177; quote: `"ignored_transient"`, `"intentionally_tracked"`, `"safe_fixtures"`, `"forbidden_tracked"`] |
| Local private durable storage | Temporary archive under a temp root | Easy to test but it is scratch, not durable preservation under the locked decision. |

## Architecture Patterns

### Inventory pipeline

```text
fresh checkout identity + status/index snapshot
          │
          ├── verify exact merged source commit candidates and comparison trees
          ├── enumerate status, index entries, and every untracked path
          ├── compare tracked paths as HEAD→index and index→worktree
          ├── classify paths against repository_artifact_policy.json
          ├── create private payload snapshot + private manifest
          ├── restore into isolated scratch and assert bytes/kind/mode/index state
          └── emit redacted path rows + five-way dispositions + Phase177 handoff
```

### Pattern 1: Preserve NUL-delimited Git records as bytes

**What:** Invoke Git directly with fixed argv, capture stdout as a Buffer, split only on NUL, and keep path bytes through parsing/capture. For status v1 `-z`, a rename/copy record has destination then original path in separate NUL fields; do not parse with line splitting or decode the whole stream to UTF-8 before splitting. Fail the inventory if a record is malformed or a path cannot be safely represented. [CITED: https://git-scm.com/docs/git-status] [CITED: https://nodejs.org/api/child_process.html]

**Important existing boundary:** `script/verify_repository.mjs` does use Buffer subprocess output for `git status`, but its current `gitPathSet` and `trackedPaths` convert bytes to UTF-8 and split into strings. Reuse its fixed-command/error-handling conventions, not those string path parsers as the inventory's unusual-filename implementation. [VERIFIED: script/verify_repository.mjs:244-275; quote: `"encoding: null"`, `"result.stdout.toString(\"utf8\").split(\"\\0\").filter(Boolean)"`]

**Example shape:**

```js
import { spawnSync } from "node:child_process";

const result = spawnSync("git", ["--no-optional-locks", "status", "--porcelain=v1", "-z", "--untracked-files=all"], {
  cwd: checkout,
  env: { ...process.env, GIT_OPTIONAL_LOCKS: "0" },
  encoding: null,
  maxBuffer: 16 * 1024 * 1024,
});
if (result.error || result.signal || result.status !== 0 || !Buffer.isBuffer(result.stdout)) {
  throw new Error("inventory Git status failed");
}
const nulFields = splitNulBuffer(result.stdout); // Preserve Buffer slices; decode only safe display values.
```

This is an API sketch, not a claim that `splitNulBuffer` exists in the repository. Node documents `encoding: 'buffer'`/unrecognized encodings for Buffer output, process `error`/`signal`/status as distinct outcomes, and direct execution without shell interpolation. [CITED: https://nodejs.org/api/child_process.html]

### Pattern 2: Compare the three Git states separately

Record exact HEAD and index entries, then compare committed tree → index and index → working tree as separate facts. `git diff --cached` is commit-to-index; ordinary `git diff` is index-to-worktree. Include untracked payload separately because neither tracked diff includes it. Do not infer that staged and unstaged changes to one path are a single state. [CITED: https://git-scm.com/docs/git-diff]

Before using a candidate source commit, prove the commit's identity and that it is the actual merged source for the relevant supported release using archived merge evidence and available read-only remote metadata. `MILESTONES.md` provides candidate published merge IDs, but the release identities alone do not establish that every local file/hunk has landed. If merge identity cannot be verified, leave the comparison unresolved rather than guessing from a release tag or stale ref. Do not fetch or mutate Git refs in the recovery checkout. [VERIFIED: .planning/workstreams/quality-ratchet-release/MILESTONES.md:28-30; quote: `"Actual published source: core merge `6da6df6f9ddc0f48614fd99c50decc6dc23387c4`; companion merge `2dbde2d9be8adfa36009e20bf894b00a5bb63e87`; final installer repair merge `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`."`]

### Pattern 3: Snapshot first, then restore into scratch

Keep a private manifest containing the base commit, opaque row mapping where needed, changed-path payload references, file kind, executable/mode bits, symlink identity, deletion state, and staged/worktree partition. Store raw payload and sensitive digests/sizes only in the owner-protected private area. Restore into fresh isolated scratch rooted at the exact base commit; assert bytes, file kind, mode, link identity, deletions, and `git status`/index state against the capture. Never dereference symlinks while copying. Binary full-index patches can supplement a snapshot, not replace it. [CITED: https://git-scm.com/docs/git-diff] [CITED: https://git-scm.com/docs/git-status]

The v23 closeout provides a manifest/verification precedent that binds originals to source records, but Phase176 should create its own dated evidence and not copy historical rows into a competing live authority store. [VERIFIED: .planning/workstreams/quality-ratchet-release/milestones/v23.0-closeout/original-artifacts.json; quote: `"category"`, `"source"`, `"original"`, `"sha256"`]

### Pattern 4: Apply the existing artifact policy as multiple independent facts

The policy's current top-level keys are exactly `"schema_version"`, `"ignored_transient"`, `"intentionally_tracked"`, `"generated_contracts"`, `"forbidden_tracked"`, and `"safe_fixtures"`. [VERIFIED: script/repository_artifact_policy.json:1-4,68-69,104-105,135-136,171-172; quote: `"schema_version"`, `"ignored_transient"`, `"intentionally_tracked"`, `"generated_contracts"`, `"forbidden_tracked"`, `"safe_fixtures"`]

Map every inventory path to the policy row or explicitly record no match. Policy says root `tmp` is a tree matcher; the context explicitly states `.tmp/` and `.planning/tmp/` do not inherit it. [VERIFIED: script/repository_artifact_policy.json:58-65; quote: `{"kind": "tree", "value": "tmp"}`] [VERIFIED: 176-CONTEXT.md:43-45; quote: `".tmp/` and `.planning/tmp/` do not inherit the policy's root `tmp/` rule."`]

Do not collapse ignored, obsolete, forbidden-to-track, and disposable into one label. A tracked policy-safe fixture exception exists at `examples/phoenix_host/.env`; inspect the explicit safe-fixture row before classifying that path. [VERIFIED: script/repository_artifact_policy.json:160-176; quote: `"path": "examples/phoenix_host/.env"`, `"forbidden_category": "forbidden_secret"`, `"purpose": "Non-secret Compose project and fixed local port fixture"`]

### Generated-contract ownership map

The policy declares two generated-contract records. Copy the actual argv/output sets from the source of truth, add the drift-check owner, and run only after snapshotting changed bytes in an isolated source clone/scratch directory.

| Task/canonical generator owner | Regeneration argv | Declared outputs | Drift-check owner |
|---|---|---|---|
| `lib/mix/tasks/crosswake.contract.gen.ex` | `mix crosswake.contract.gen`; `mix crosswake.contract.gen --dev` | `docs/_contract_snippet.md`; `examples/android_shell_host/app/src/dev/assets/route_activation.json`; `examples/android_shell_host/app/src/main/assets/route_activation.json`; `examples/ios_shell_host/Fixtures/route_activation-dev.json`; `examples/ios_shell_host/Fixtures/route_activation.json`; `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json`; `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json`; `test/fixtures/bridge_contract_vectors.json` | Existing `repository-cleanliness` policy/drift stage |
| `lib/mix/tasks/crosswake.docs.sync.ex` | `mix crosswake.docs.sync` | `guides/capability_map.md`; `guides/support_matrix.md` | Existing `repository-cleanliness` policy/drift stage |

[VERIFIED: script/repository_artifact_policy.json:104-133; quote: `"canonical_source"`, `"regeneration_argv"`, `"output_paths"`, `"remediation_command"`] [VERIFIED: script/repository_verification_stages.json:119-127; quote: `"stage_id": "repository-cleanliness"`, `"remediation_command": "script/verify_repository.sh --stage repository-cleanliness"`]

The docs task names actual semantic source/target relationships in its projection table: `lib/crosswake/capability_map.ex` → `guides/capability_map.md`, and `lib/crosswake/support_matrix/support_matrix.ex` → `guides/support_matrix.md`. The task itself supports a non-writing `--check` form; use it as a drift check in isolated scratch if relevant. [VERIFIED: lib/mix/tasks/crosswake.docs.sync.ex:38-72,81-97; quote: `source: "lib/crosswake/capability_map.ex"`, `target: "guides/capability_map.md"`, `source: "lib/crosswake/support_matrix/support_matrix.ex"`, `target: "guides/support_matrix.md"`]

The policy's listed `canonical_source` for documentation is the task owner; the runtime projection table identifies the underlying sources. Preserve both distinctions in the ownership map. [VERIFIED: script/repository_artifact_policy.json:124-132; quote: `"canonical_source": "lib/mix/tasks/crosswake.docs.sync.ex"`, `"output_paths": ["guides/capability_map.md", "guides/support_matrix.md"]`]

The project overview still says “No new scope is selected.” v24 is now approved, but Phase176 should not edit that prose: the context explicitly assigns the stale active instruction to Phase177 alongside its other bounded instruction repairs. [VERIFIED: .planning/PROJECT.md:43-45; quote: `"No new scope is selected. Use `$gsd-new-milestone --ws quality-ratchet-release` to define fresh requirements under the existing adopter-first ADR."`] [VERIFIED: 176-CONTEXT.md:55; quote: `"Correct stale active instructions there, including PROJECT.md's “No new scope is selected” paragraph now that v24 scope is approved."`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Git state enumeration | Human `git status --short` parsing or newline split | Porcelain v1 with `-z`, `--untracked-files=all`, raw Buffer output | Rename records carry two paths; unusual filenames are unquoted and may contain newlines. [CITED: https://git-scm.com/docs/git-status] |
| Policy registry | A second ignore/disposition taxonomy | `script/repository_artifact_policy.json` plus one inventory disposition | Existing policy already owns transient, tracked, generated, forbidden, and safe fixture classes. [VERIFIED: script/repository_artifact_policy.json:1-177; quote: `"ignored_transient"`, `"intentionally_tracked"`, `"generated_contracts"`, `"forbidden_tracked"`, `"safe_fixtures"`] |
| Generated outputs | Hand-editing projections or rebuilding a generator index | Existing Mix task and policy rows | Canonical source/outputs and drift guard are already declared; preserve and compare before generation. |
| Recovery proof | Treat patch creation, copy success, or archive listing as proof | Fresh restore plus byte/kind/mode/link/index assertions | Materialized restoration is the requirement; symlinks and staged/unstaged state can be lost by naïve archives. [CITED: https://git-scm.com/docs/git-diff] |

## Common Pitfalls

1. **The NUL parser passes ordinary names but corrupts unusual paths.** Existing verifier code decodes the full stream as UTF-8 before splitting. Keep path data as bytes until safe display encoding; preserve both rename names and fail closed on malformed records. [VERIFIED: script/verify_repository.mjs:251-262; quote: `"result.stdout.toString(\"utf8\").split(\"\\0\").filter(Boolean)"`] [CITED: https://git-scm.com/docs/git-status]
2. **A filename classification becomes a deletion decision.** Ignored, forbidden-to-track, obsolete, and disposable are separate decisions. `git check-ignore` and `.gitignore` can explain matching, not prove ownership or deletion safety. [VERIFIED: 176-CONTEXT.md:43-47; quote: `"Ignored, obsolete, forbidden to track, and disposable are separate facts."`] [CITED: https://git-scm.com/docs/git-check-ignore]
3. **A guessed or stale commit makes “already merged” look proven.** Start from archived actual merge records, verify object identity and merge/reachability evidence, and cite the exact compared tree for each row. Treat local ref names and package version tags as leads only. [VERIFIED: .planning/workstreams/quality-ratchet-release/MILESTONES.md:28-30; quote: `"The local milestone tag records planning closeout; it is not a package release tag or a claim that this recovery checkout is published source."`]
4. **Restore proof follows links, loses mode, or omits index state.** Use `lstat`-style kind inspection; recreate links without reading their targets; check executable/mode bits and compare restored index/worktree partitions. Keep unresolved paths in source if read-back/restore or durable storage fails. [VERIFIED: 176-CONTEXT.md:34-39; quote: `"Never follow symlinks to copy unrelated targets."`, `"Compare actual restored content/type/mode/link metadata and reconstructed staged/unstaged state"`]
5. **The full repository gate or generator runs against the dirty recovery source.** Phase176 evidence work must use bounded Git reads and scratch source copies; Phase178 owns the complete facade on exact clean source. [VERIFIED: 176-CONTEXT.md:45-47,54-55; quote: `"run potentially writing regeneration in isolated scratch"`, `"a dirty recovery checkout is not its proof target."`]
6. **Private content leaks through failure output.** Never print raw diff/error stdout, unsafe path bytes, symlink targets, archive bytes, or secret values. Capture subprocess failure cause as a closed safe category while keeping raw process data private or discarding it. [CITED: https://nodejs.org/api/child_process.html]

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation` is `true`). [VERIFIED: .planning/config.json:10-14; quote: `"nyquist_validation": true`]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node.js built-in test runner; existing project convention |
| Config file | None required for `node --test`; existing tests are under `test/js/` |
| Focused command | `node --test test/js/repository_verification.test.mjs` (existing harness); add focused cases in the same harness or a small adjacent `.mjs` test |
| Full suite command | `node --test test/js/*.mjs` (existing CI command; run only if the phase plan determines it is needed, never as the dirty-checkout final gate) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| MAINT-01 | Inventory covers staged, unstaged, deleted, renamed, type/mode changes, non-ignored untracked, unmerged, and unusual-byte paths; exact base/source identities accompany comparisons. | Temporary Git integration fixture | `node --test test/js/repository_verification.test.mjs` plus new focused fixture cases | Existing harness; targeted cases are a Wave 0 gap if helper is introduced. |
| MAINT-02 | Private snapshot read-back restores bytes, kind, executable mode, symlink identity, deletions, and staged/unstaged distinction; baseline drift or storage failure blocks removal. | Temporary Git/filesystem integration fixture | Same focused Node command | Existing harness; targeted restore fixture is a Wave 0 gap if helper is introduced. |
| MAINT-04 | Every path is classified by the existing artifact policy or explicitly remains unclassified; root `tmp/` does not accidentally cover `.tmp/` or `.planning/tmp/`. | Unit plus temporary path fixture | Same focused Node command | Existing policy/parser tests can be extended; no new framework/config required. |

Fixture must create actual repository state and assert byte-level results, not mock Git's output: ordinary and newline/tab/non-UTF-8 path bytes where host supports them; staged and subsequent unstaged edits to one file; true rename; deletion; regular↔symlink/type change; executable-bit change; binary bytes; unmerged stages; and fresh-baseline drift. Exercise spawn failure, signal/timeout, and nonzero `status` using the installed `spawnSync` shape. Assert sanitized stdout/committed evidence contains no sentinel payload, private absolute path, symlink target, or raw digest/size. A changed/escaped path between capture and disposition must stop the affected action and demand re-inventory.

No human UAT is needed. Keep the integration fixture temporary and isolated. Do not run `script/verify_repository.sh --all`, `script/verify_repository.sh --stage repository-cleanliness`, or any production generator in the recovery checkout. Existing CI already owns recurring JS and repository cleanliness checks; do not add a permanent Phase176 CI lane. [VERIFIED: .github/workflows/crosswake-ci.yml:1306-1311; quote: `"node --test test/js/*.mjs"`] [VERIFIED: script/verify_repository.sh:8-19; quote: `"--all"`, `"--stage"`, `"--self-test"`]

## Security Domain

This phase handles potentially secret-bearing local source and evidence. Keep raw payload, unsafe path bytes, sensitive digests/sizes, absolute storage locations, and symlink targets in private owner-protected storage only. Render only safe repository-relative path text or opaque IDs. Never follow symlinks or inspect known secrets. The verifier should emit closed, non-echoing failure reasons; read-only Git/remote reads are allowed, while any source removal remains outside Phase176 success criteria.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No application authentication surface. |
| V3 Session Management | No | No session surface. |
| V4 Access Control | Yes, local filesystem | Owner-only archive/manifest permissions; verify destination containment and no symlink traversal. |
| V5 Input Validation | Yes | Treat filesystem names and subprocess output as untrusted bytes; fixed argv, NUL parsing, strict record validation, escaped rendering. |
| V6 Cryptography | No new cryptography | No encryption dependency or custom cryptography; existing protected storage only. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Git | Inventory and source comparison | ✓ | 2.41.0 | None needed. |
| Node.js | Local evidence helper and tests | ✓ | 26.10.0 | None needed. |
| Mix/Elixir | Generated-contract ownership checks in scratch | ✓ | Mix 1.19.5, OTP 27 | If unavailable during execution, record owner map and block generator verification; do not run against recovery checkout. |
| Durable owner-controlled storage outside every source checkout | Private recovery archive | Not established by this execution environment | — | Keep source intact; resolve authorized persistent root at the actual write boundary. Temporary roots are only restore scratch. |

The filesystem permissions provided for this research environment allow writes to the project checkout and temporary roots only `[VERIFIED: task execution environment permissions]`. No durable private root outside all source checkouts has been established; do not choose an arbitrary home or sync directory or claim persistence. The plan should include a grouped, concrete availability/permission check before the archive write, with source preservation as the fail-closed outcome if it cannot proceed. This is an execution boundary, not a new user preference question.

## Project Constraints (from AGENTS.md)

- Keep work in `quality-ratchet-release`; v21 adopter readiness stays parked behind its recorded external gate.
- Do not infer adopter identity or search history/external sources for it; keep sensitive adopter and offline mutation data out of diagnostics/evidence.
- Preserve historical v23 artifacts/verdicts, REL-10 breach, fail-closed behavior, and current supported contracts.
- Phase176 may inventory/recover only: no staging, commits, branch/worktree changes, broad cleanup, release, merge, or publication; Phase177 owns maintenance and Phase178 owns exact clean-source proof/CI.
- Use automated checks where possible, group routine work, and keep the maintainer-facing outcome plain, privacy-safe, and tied to next action.
- No Android breadth, new package/dependency, product UI/dashboard, new capability, or permanent one-time reconciliation workflow.

## Sources

### Primary sources

- [Git status](https://git-scm.com/docs/git-status) — porcelain v1 stability, NUL-delimited rename fields, unusual paths, unmerged entries, and submodules.
- [Git diff](https://git-scm.com/docs/git-diff) — commit/index/worktree comparison roles.
- [Git diff options](https://git-scm.com/docs/diff-options) — full-index/binary patch use as a reconstruction aid.
- [Node.js child_process](https://nodejs.org/api/child_process.html) — direct subprocess argv, Buffer output, `error`, `signal`, exit status, and maxBuffer.
- [Mix aliases](https://mix.hexdocs.pm/Mix.html) and [Mix xref](https://mix.hexdocs.pm/Mix.Tasks.Xref.html) — aliases/tasks and compiled caller analysis; broader dynamic retirement remains Phase177.
- In-repository owners: `script/repository_artifact_policy.json`, `script/verify_repository.mjs`, `script/verify_repository.sh`, `lib/mix/tasks/crosswake.contract.gen.ex`, `lib/mix/tasks/crosswake.docs.sync.ex`, and v23 closeout manifest/verification files.

### Research notes

- The Phase176 discussion log retains primary-source comparisons and tradeoffs. Hex package membership is not repository recovery coverage. Cargo archive semantics are not adopted as an archive recipe because link flattening conflicts with exact link recovery. These are bounded ecosystem lessons, not package recommendations.
- No project skills were found under `.agents/skills/` or `.codex/skills/` `[VERIFIED: project skill discovery]`; no dependency or skill-specific contract was added.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | If no durable owner-controlled root is available under the eventual execution permissions, retaining the source and reporting recovery blocked is the only compliant outcome. | Environment Availability | A valid pre-authorized private root may exist at execution time; test concrete permission and persistence before declaring blocked. |

## Open Questions

Both questions are **RESOLVED FOR PLANNING** as execution-time evidence gates, not as observed facts. Neither a private root nor a local row comparison has been established at planning time; the execution results remain unknown.

1. **[RESOLVED] Planning gate — conditional storage precondition:** Which authorized persistent private root is writable at execution time? Plan 176-02 Task 1 checks a concrete owner-controlled root outside every checkout and temporary storage at the grouped archive boundary, then requires owner-only write, read-back, and materialized restore. If no such root is permitted and durable, leave the source intact, report the exact cause, and keep MAINT-02 blocked. No root is presumed here.
2. **[RESOLVED] Planning gate — fresh comparison:** Which local rows are already merged or useful maintenance? Plan 176-02 Tasks 1-2 enumerate the live checkout at a fresh capture epoch and validate actual merged commit/tree provenance before assigning each row's five-way disposition. An unverifiable comparison remains an explained retained limitation; it cannot become an `already merged` or removal claim. No row, merge identity, or useful maintenance conclusion is asserted here.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions observed locally and tools are already present.
- Architecture: HIGH — phase boundary and code owners are explicit in context and source.
- Pitfalls: HIGH for Git record shapes and existing policy; MEDIUM for recovery implementation until real temporary Git fixtures pass.

**Research date:** 2026-10-11  
**Valid until:** 2026-11-10 for repository patterns; recheck tool versions and available private storage at execution.
