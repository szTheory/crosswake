# Phase 166: Clean-Checkout Engineering Quality - Pattern Map

**Mapped:** 2026-09-09
**Files analyzed:** 23 new/modified files or file families
**Analogs found:** 23 / 23

## Scope Interpretation

The phase context explicitly requires a public clean-checkout facade and focused stages. Research
then proposes the runner, two policy manifests, recurring phase gate, two test files, negative
fixtures, and ownership ledger. The existing CI authority and the two demonstrated adjacent defects
imply modifications to the Phase 165 manifest/validator/workflow and Playwright configuration.
The Node pin is already present as an unrelated working-tree change and must be preserved and made
intentional, not overwritten.

The generated-contract task, its eight outputs, `.gitignore`, package manifests, and build output
roots are authoritative inputs to the new artifact policy. They are not assumed edits. Modify them
only if the ownership-ledger evidence establishes a direct edge and a focused regression requires
the change.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `script/verify_repository.sh` | utility / facade | batch | `script/check_phase165_efficient_ci.sh` | exact role |
| `script/verify_repository.mjs` | utility / runner | batch, event-driven | `script/automated_uat.mjs` | role + argv execution |
| `script/repository_verification_stages.json` | config | batch | `script/ci_leaf_manifest.json` | exact authority-record shape |
| `script/repository_artifact_policy.json` | config | file-I/O, transform | `script/ci_leaf_manifest.json` | schema pattern |
| `script/check_phase166_clean_checkout_engineering_quality.sh` | utility / recurring gate | batch | `script/check_phase165_efficient_ci.sh` | exact role |
| `script/capture_repository_verification_evidence.sh` | utility / exact-commit capture | batch, file-I/O | `script/retain_physical_iphone_evidence_transaction.sh` plus `script/check_example_host_isolation.sh` | commit/evidence transaction + isolation |
| `script/run_repository_evidence_environment.sh` | utility / invocation-local provisioner | batch, file-I/O | `script/verify_generated_android_shell.sh` plus `script/check_example_host_isolation.sh` | platform/artifact mechanics + isolation; global/floating behavior excluded |
| `script/repository_evidence_toolchain.json` | config / artifact lock | batch, file-I/O | `script/ci_leaf_manifest.json` | closed ordered authority records |
| `test/js/repository_verification.test.mjs` | test | batch, file-I/O | `test/js/crosswake_esm_test.mjs` | framework match |
| `test/js/playwright_repository_mode.test.mjs` | test | request-response | `test/js/crosswake_esm_test.mjs` | framework + real-module behavior |
| `test/fixtures/repository_quality/**` | test fixture | file-I/O | `script/ci_leaf_manifest.json` plus existing closed fixture conventions | structural match |
| `test/crosswake/proof/phase166_repository_quality_test.exs` | test | batch, transform | `test/crosswake/proof/phase165_ci_policy_test.exs` | exact role |
| `script/check_phase166_ownership_ledger.py` | utility / validator | batch, transform | `script/check_ci_leaf_manifest.py` | closed schema + structured problem authority |
| `.planning/.../166-ownership-ledger.md` | config / evidence ledger | batch, transform | Phase 166 decision schema `candidate -> evidence -> owner -> disposition` | contract match |
| `.tool-versions` | config | request-response preflight | existing `.tool-versions` | extend in place |
| `script/ci_leaf_manifest.json` | config | CI pub-sub authority | existing `script/ci_leaf_manifest.json` | extend in place |
| `script/check_ci_leaf_manifest.py` | utility / validator | batch, transform | existing `script/check_ci_leaf_manifest.py` | extend in place |
| `.github/workflows/crosswake-ci.yml` | config / CI workflow | event-driven | existing literal leaf jobs in the same workflow | extend in place |
| `examples/phoenix_host/playwright.config.ts` | config | request-response | existing config with explicit repository-mode override | extend in place |
| `test/crosswake/contract/contract_drift_test.exs` | test | file-I/O, transform | existing generated-surface registry in the same test | extend only if needed |
| `.planning/.../evidence/clean-checkout-run.json` | evidence / canonical JSON | batch, file-I/O | `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/after.json` | closed allowlisted evidence shape |
| `.planning/.../evidence/clean-checkout-run.md` | evidence / generated presentation | transform | `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/comparison.md` | deterministic bounded rendering |
| `.planning/.../166-VALIDATION.md` | validation ledger | batch, transform | `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-VALIDATION.md` | exact role + completed reconciliation |

All named analog paths above are Git-tracked (`git ls-files -- <path>` returned each path).

## Pattern Assignments

### `script/verify_repository.sh` and `script/check_phase166_clean_checkout_engineering_quality.sh`

**Analog:** `script/check_phase165_efficient_ci.sh`

**Strict facade and root-resolution pattern** (lines 1-6):

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"
```

**Stable section and one-correction failure pattern** (lines 8-24):

```bash
CURRENT_SECTION="startup"
CORRECTIVE_COMMAND="install the reported required tool and rerun this gate"

section() {
  CURRENT_SECTION="$1"
  CORRECTIVE_COMMAND="$2"
  printf '\n[crosswake] PHASE-165 section=%s\n' "$CURRENT_SECTION"
}

on_error() {
  status=$?
  printf '[crosswake] FAIL phase165 section=%s exit=%s\n' "$CURRENT_SECTION" "$status" >&2
  printf '[crosswake] corrective-command=%s\n' "$CORRECTIVE_COMMAND" >&2
  exit "$status"
}

trap on_error ERR
```

Copy the strict shell and exact root behavior. Replace the phase-led public labels with stable
purpose IDs. The public facade should only normalize arguments and `exec` the Node runner; keep
dependency-aware result handling in one implementation. The recurring gate should compose focused
Phase 166 controls as lines 34-76 of the analog do, without installing tools or mutating authority.

### `script/verify_repository.mjs`

**Analog:** `script/automated_uat.mjs`

**ESM imports and repository-root pattern** (lines 1-9):

```javascript
#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');
```

**Fixed argv execution pattern** (lines 209-228):

```javascript
for (const proofCommand of spec.commands) {
  const result = spawnSync(proofCommand.command[0], proofCommand.command.slice(1), {
    cwd: path.join(repoRoot, proofCommand.cwd),
    env: { ...process.env, ...(proofCommand.env ?? {}) },
    stdio: 'inherit',
  });

  if (result.error) {
    die(`${proofCommand.label} failed to start: ${result.error.message}`);
  }

  if (result.status !== 0) {
    die(`${proofCommand.label} exited with ${result.status}`);
  }
}
```

Copy array-based spawning and explicit `cwd`; never add shell evaluation or arbitrary-command
input. Unlike this fail-fast analog, Phase 166 must store a closed result per stage, propagate
`BLOCKED` through dependencies, continue independent stages, and run cleanup plus final Git
inspection in `finally`. Preserve child logs in the invocation-owned run root and render only a
bounded `PASS`/`FAIL`/`BLOCKED` summary.

**Cleanup companion analog:** `script/check_example_host_isolation.sh` lines 63-97 captures child
status without losing logs, snapshots before and after, prints at most the tail on failure, and
checks residue before declaring `PASS`. Its current top-level cleanup (lines 10-14) is deliberately
too broad to copy unchanged; Phase 166 must first validate the exact
`crosswake-repository-verify.*` prefix and clean only paths recorded as invocation-created.

### `script/repository_verification_stages.json`

**Analog:** `script/ci_leaf_manifest.json`

**Literal, ordered authority record pattern** (lines 1-16, 40-65):

```json
{
  "schema_version": 2,
  "proof_leaves": [
    {
      "leaf_id": "android-package-unit",
      "display_name": "android-package-unit",
      "family": "native_android",
      "remediation_command": "cd packages/crosswake-shell-core-android && ./gradlew test",
      "irrelevance_reason": "all_changed_paths_allowlisted"
    }
  ]
}
```

Use a closed top-level schema and lexically ordered stable IDs. Each stage record should use exact
keys for purpose ID, dependencies, required tool facts, argv, working directory, CI owner(s), one
remediation command, and owned output roots. Commands must be argv arrays or fixed script paths;
the remediation is display text, not executable input. Preserve the existing CI manifest as the
CI identity authority rather than merging the two manifests into a dynamic workflow engine.

### `script/repository_artifact_policy.json`

**Analog:** `script/ci_leaf_manifest.json` for closed schema and deterministic ordering.

Define exactly three explicit classes: ignored transient families, intentionally tracked source or
generated contracts, and forbidden tracked families. Every tracked generated record must name its
canonical source, regeneration argv, and exact output paths. Narrow safe fixtures (notably
`examples/phoenix_host/.env`) must be explicit records, not glob-wide exceptions. Diagnostics may
project only category, repository-relative path, and remediation; never file contents.

The canonical generated-output list comes from
`lib/mix/tasks/crosswake.contract.gen.ex` lines 48-55, and its default/dev write split is lines
57-96. Reuse those explicit paths rather than discovering outputs by glob.

### `test/js/repository_verification.test.mjs`

**Analog:** `test/js/crosswake_esm_test.mjs`

**Dependency-free test pattern** (lines 1-10):

```javascript
/* Node's built-in test runner ... no test framework dependency ...
 *     node --test test/js/
 */
import { test } from "node:test";
import assert from "node:assert/strict";
```

Use `node:test`, strict assertions, temporary repositories, and direct imports from the runner.
Cover closed schema rejection, duplicate/unordered stages, missing CI owners, divergent argv,
failed-to-start tools, failed/blocked dependency chains, independent continuation, NUL-containing
status records, hostile filenames, dirty-baseline rejection, cleanup after failure/interruption,
invalid cleanup prefixes, preservation of pre-existing caches, bounded output, and non-secret
remediation. Tests should assert behavior and outputs, not merely search runner source text.

### `test/js/playwright_repository_mode.test.mjs`

**Analog:** `test/js/crosswake_esm_test.mjs`.

Use the same dependency-free `node:test` and `node:assert/strict` pattern, but import/evaluate the
real `examples/phoenix_host/playwright.config.ts` under explicit repository, ordinary local, and
current CI environments. Assert semantic config values rather than searching TypeScript source.

### `test/fixtures/repository_quality/**`

**Analogs:** closed and sorted fixture checks in
`test/crosswake/proof/phase165_ci_policy_test.exs` lines 118-133.

```elixir
names = Enum.map(fixture["cases"], & &1["name"])
assert names == Enum.sort(names)
assert Enum.uniq(names) == names
assert Enum.all?(fixture["cases"], &(&1["classification"] in ["documentation_only", "full_proof"]))
```

Create deterministic, closed negative cases for missing tools, failed/blocked chains, unusual and
malicious filenames, forbidden artifacts, the safe `.env` fixture, generated drift, and cleanup
failure. Fixtures must contain synthetic values only and must never embed credentials, payloads,
tokens, environment dumps, or adopter-identifying material.

### `test/crosswake/proof/phase166_repository_quality_test.exs`

**Analog:** `test/crosswake/proof/phase165_ci_policy_test.exs`

**Module/path authority pattern** (lines 1-17):

```elixir
defmodule Crosswake.Proof.Phase165CiPolicyTest do
  use ExUnit.Case, async: true

  @manifest "script/ci_leaf_manifest.json"
  @workflow ".github/workflows/crosswake-ci.yml"
  @aggregate "script/check_phase165_efficient_ci.sh"
end
```

**Executable parity pattern** (lines 169-178):

```elixir
{output, status} =
  System.cmd("python3", ["script/check_ci_leaf_manifest.py", "--self-test"],
    stderr_to_stdout: true
  )

assert status == 0, output
assert output =~ "ci leaf manifest self-test: pass"
```

Follow the analog's exact decoded-JSON assertions (lines 135-167) and adversarial fixture tests,
but make Phase 166 assertions behavioral. Prove bidirectional stage/CI-owner parity, artifact-policy
closure, exact eight-output generated registry, no index-mutating remediation, ownership-ledger
shape, purpose-led active output, and preservation of protected CI identities.

### `.planning/.../166-ownership-ledger.md`

**Contract source:** Phase 166 D-07 through D-12.

Use a mechanically recorded base SHA and one row per non-planning candidate with exact columns
`candidate | evidence | owner | disposition`. Record each direct ownership-cone expansion as a new
row and stop at the first missing direct edge. Accepted dispositions should distinguish retained,
changed, removed-with-proof, and unproven-retained. Do not treat all 94 pre-planning candidates as
mandatory edits or use file length/text similarity as removal evidence.

### `script/check_phase166_ownership_ledger.py`

**Analog:** `script/check_ci_leaf_manifest.py` lines 77-169.

Reuse its immutable problem record, closed-key validation, deterministic ordering, duplicate
rejection, and production-validator mutation self-tests. The Phase 166 validator additionally
owns NUL-safe Git candidate enumeration, direct-edge closure, the closed disposition vocabulary,
and all six removal-evidence classes; it must not trust a copied research-time candidate count.

### Exact-commit capture and invocation-local evidence environment

**Capture analogs:** `script/retain_physical_iphone_evidence_transaction.sh` for an immutable code
commit separated from a later evidence commit, closed evidence projection, and digest validation;
`script/check_example_host_isolation.sh` for exact temporary ownership, child-status preservation,
and before/after residue comparison. The capture tool does not copy the physical transaction's Git
staging behavior because D-16 and D-18 prohibit index mutation here.

**Provisioning analogs:** `script/verify_generated_android_shell.sh` for Darwin architecture
selection, retrying HTTPS artifact fetches, archive extraction, and Java bundle discovery, plus
`script/check_example_host_isolation.sh` for owned-root cleanup. Replace the Android analog's
user-home roots, Homebrew mutation, and floating Adoptium endpoint with
`script/repository_evidence_toolchain.json`: a closed `Darwin/arm64` lock containing immutable
release URL, authority repository/tag, archive SHA-256, archive root, executable path, and version
probe for Erlang 27.3, Elixir 1.19.5-otp-27, Node 22.14.0, and Temurin 17.0.20.1+1. Erlang precedes
Elixir on PATH; the Elixir OTP-27 archive is validated against that runtime before use. Xcode and
Swift are validated in place and are never installed.

### Canonical JSON/Markdown evidence and validation reconciliation

**JSON evidence analog:**
`.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/after.json`.
Reuse its closed, allowlisted, source-SHA-bound evidence shape while keeping the Phase 166 schema
limited to supported-stage results, repository/index snapshots, and owned-cleanup facts.

**Markdown rendering analog:**
`.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/comparison.md`.
Follow its deterministic, bounded maintainer presentation: render only canonical JSON fields,
label status explicitly, and keep source identity visible without copying logs or environment data.

**Validation reconciliation analog:**
`.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-VALIDATION.md`.
Follow its completed-row and final Nyquist audit pattern: replace planned placeholders with exact
commands and observed results, record measured runtime, and flip frontmatter/sign-off only after
every required verification is green. Preserve Phase 166's unresolved assumptions and bespoke
prohibitions rather than inheriting Phase 165 conclusions.

### `.tool-versions`

**Existing pattern** (lines 1-3):

```text
erlang 27.3
elixir 1.19.5-otp-27
nodejs 22.14.0
```

Preserve this concurrent working-tree change. Make toolchain identity and preflight validation
agree atomically; do not introduce a second version source.

### `script/ci_leaf_manifest.json`, `script/check_ci_leaf_manifest.py`, and `.github/workflows/crosswake-ci.yml`

**Validator analog:** `script/check_ci_leaf_manifest.py` lines 77-125 defines structured problems,
closed record keys, non-empty IDs, duplicate rejection, and deterministic ordering. Lines 128-169
enforce a closed top-level schema and literal fields. Extend this same validator boundary for stage
ownership; do not create a permissive second parity check.

```python
@dataclass(frozen=True)
class Problem:
    kind: str
    member: str
    detail: str

    def render(self) -> str:
        return f"ci-leaf-manifest: FAIL: {self.kind} member={self.member} detail={self.detail}"
```

The current generated-drift leaf at `.github/workflows/crosswake-ci.yml` lines 302-333 and the
matching manifest record at `script/ci_leaf_manifest.json` lines 61-65 use `git add -A`. Replace
them atomically with the shared non-staging behavioral stage. Preserve the literal
`guard-02-generate-and-diff` identity, remediation parity, manifest ordering, static umbrella
needs, and `Crosswake CI` authority. Any new recurring Phase 166 owner must be a literal job/leaf
addition whose manifest, workflow producer, validator constants/tests, remediation, and umbrella
need change together.

### `examples/phoenix_host/playwright.config.ts`

**Existing seam:** lines 5-15 and 47-50.

```typescript
export default defineConfig({
  fullyParallel: false,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  use: { trace: 'on-first-retry', serviceWorkers: 'block' },
  webServer: {
    command: 'MIX_ENV=test mix do ecto.drop --quiet + ecto.create --quiet + ecto.migrate --quiet + phx.server',
    port: 4700,
    reuseExistingServer: !process.env.CI,
  },
});
```

Preserve sequential execution, service-worker blocking, and the existing database/server owner.
Add an explicit repository-verification mode that forces zero retries and a fresh server without
changing unrelated local/CI behavior by accident. The stage manifest and CI owner must pass the
same explicit mode; do not use `CI=1` as the sole determinism switch.

### `test/crosswake/contract/contract_drift_test.exs` (conditional ownership-cone edit)

**Existing generated registry pattern** (lines 25-51): explicit prod and dev path lists, with no
glob discovery and unconditional reads. Preserve that distinction. If Phase 166 centralizes the
byte-for-byte check in the repository runner, retain this fast semantic tripwire unless evidence
proves the responsibility is duplicated over identical inputs, outputs, authority, and failure
semantics. Update stale comments such as the “three files” wording only as an invariant-first
correction, not as cosmetic phase-label cleanup.

## Shared Patterns

### Fail-Closed Schema and Parity

**Source:** `script/check_ci_leaf_manifest.py` lines 106-169.
Apply to both new JSON manifests and all CI ownership changes. Reject unknown keys, duplicates,
unordered identifiers, empty required arrays, non-literal commands, missing owners, extra owners,
and divergent commands before expensive work.

### Exact Resource Ownership and Cleanup

**Source:** `script/check_example_host_isolation.sh` lines 63-97.
Apply to the runner and its tests. Capture before state to files, run the child with explicit cwd
and status capture, snapshot after cleanup, and compare exact owned resources. Strengthen the
analog with validated prefixes, a creation ledger, unconditional finalization, and preservation of
the original failure status.

### Safe Failure Output

**Source:** `script/check_phase165_efficient_ci.sh` lines 17-30.
Apply to facade, runner, recurring gate, artifact diagnostics, and CI annotations. Emit stable
purpose/category, literal result, repository-relative path where allowed, and one root-relative
correction. Never print suspicious contents or environment values. Color cannot carry meaning.

### Generated Contract Authority

**Source:** `lib/mix/tasks/crosswake.contract.gen.ex` lines 48-96 and
`test/crosswake/contract/contract_drift_test.exs` lines 25-51.
Apply to artifact policy and generated-drift stage. Run both default and `--dev` generation, compare
the eight explicit outputs byte-for-byte outside the Git index, and never stage the worktree.

### Testing

Use Node's built-in runner for dependency graph, subprocess, path, cleanup, and rendering behavior;
use ExUnit for repository structure, CI parity, generated registry, and ownership-ledger contracts.
Every negative control must exercise the same production parser/executor as the positive path.

## No Analog Found

No proposed file is without a useful tracked analog. The new dependency-aware `BLOCKED` state graph
has no exact existing implementation; derive its semantics from D-19 through D-22 and test it with
the Node fixture harness rather than copying the fail-fast behavior of current aggregate scripts.

## Metadata

**Analog search scope:** `script/`, `test/js/`, `test/crosswake/proof/`,
`test/crosswake/contract/`, `.github/workflows/`, root tool/artifact config, example-host browser
config, and generated-contract task

**Tracked analogs used:** 5 primary pattern families; all verified through `git ls-files`

**Files scanned:** 14 implementation/config/test sources plus phase and project authority

**Pattern extraction date:** 2026-09-09
