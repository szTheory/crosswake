# Phase 165: Efficient and Maintainable CI - Pattern Map

**Mapped:** 2026-08-28
**Files analyzed:** 26 new/modified file responsibilities
**Analogs found:** 25 / 26 (one trusted-controller workflow has no exact repository analog)

## Scope Boundary

This map covers the `quality-ratchet-release` workstream only. It preserves literal proof names,
fail-closed required authority, release/recovery trust boundaries, and the frozen Android
generator/Maven/JVM/vector posture. It does not authorize Android feature or device breadth, a CI
dashboard, timing thresholds, release-semantic changes, or any attempt to identify the First B2C
Adopter. Evidence must remain aggregate, allowlisted, and free of raw API payloads, logs, cache
keys, actors, messages, credentials, adopter facts, account/device identifiers, or revealing links.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/crosswake-ci.yml` | config / orchestration | event-driven | `.github/workflows/contract-drift-gate.yml` | exact topology |
| `.github/workflows/cancel-obsolete-crosswake-ci.yml` | config / trusted controller | event-driven / request-response | `.github/workflows/required-checks-audit.yml` | trust-boundary match only |
| `script/classify_ci_change.py` | utility / policy | batch transform | `lib/crosswake/planning/first_adopter_context.ex` | data-safety match |
| `script/ci_leaf_manifest.json` | config / manifest | batch | `script/list_merge_blocking_checks.py` producer records | role-match |
| `script/check_ci_leaf_manifest.py` | utility / validator | batch transform | `script/list_merge_blocking_checks.py` | exact governance style |
| `script/select_obsolete_ci_runs.py` | utility / policy | batch transform | `script/check_aggregator_result_semantics.py` | exact pure-policy style |
| `.github/actions/setup-elixir-cache/action.yml` | config / composite action | request-response / cache I/O | same file | exact modification |
| `script/verify_generated_android_shell.sh` | utility / proof runner | process / file I/O | same file, split at the current portability seam | exact modification |
| `.github/workflows/native-behavioral-proof-gate.yml` | config / orchestration | event-driven | same file | exact modification |
| `.github/workflows/phase5-proof.yml` | config / legacy producer | event-driven | `.github/workflows/native-behavioral-proof-gate.yml` Linux JVM leaf | role-match |
| `.github/workflows/phase18-proof.yml` | config / mixed legacy producer | event-driven | `.github/workflows/native-behavioral-proof-gate.yml` Linux/Apple split | role-match |
| `.github/workflows/phase79-proof.yml` | config / mixed legacy producer | event-driven | `.github/workflows/native-behavioral-proof-gate.yml` Linux/Apple split | role-match |
| `.github/workflows/phase69-proof.yml`, `.github/workflows/phase75-closeout-gate.yml` | config / legacy classifiers | event-driven | `script/classify_ci_change.py` (new central owner) | replace, do not copy |
| `script/list_merge_blocking_checks.py` | utility / producer inventory | batch transform | same file | exact modification |
| `script/check_aggregator_result_semantics.py` | utility / policy validator | batch transform | same file | exact modification |
| `.github/workflows/aggregator-negative-control.yml` | config / integration test | event-driven | same file | exact modification |
| `script/check_required_checks_registered.sh` | utility / governance audit | request-response | same file | exact modification |
| `script/register_required_checks.sh` | utility / governance mutation | request-response | same file | exact modification |
| `scripts/ci_monitor.cjs` | utility / evidence collector | request-response + batch transform | same file | exact modification |
| `script/check_phase165_efficient_ci.sh` | utility / aggregate gate | batch / process | `script/check_phase164_dependency_security_and_gate_authority.sh` | exact role match |
| `test/crosswake/proof/phase165_ci_policy_test.exs` | test | batch | `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` | exact style match |
| `test/crosswake/proof/phase165_ci_integrity_test.exs` | test | batch / file I/O | `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` | exact style match |
| `test/crosswake/proof/phase165_evidence_test.exs` | test | batch / file I/O | `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` | exact style match |
| `test/fixtures/ci/{classifier,cancellation,manifest,evidence}/**` | test fixtures | file I/O / transform | `test/fixtures/security/advisory-bearing.lock` plus Phase 164 tmp-dir tests | role-match |
| `.../165-efficient-and-maintainable-ci/evidence/{baseline.json,after.json,comparison.md}` | evidence / generated presentation | batch transform | `scripts/ci_monitor.cjs` normalized output boundary | partial match |
| Superseded PR workflow files under `.github/workflows/*.yml` | config / legacy producers | event-driven | `crosswake-ci.yml` target graph | consolidation set |

Exact filenames are discretionary except where an existing file is modified. Keep responsibilities
separate even if the planner selects slightly different names: YAML orchestrates, pure scripts own
policy, the manifest owns inventory, and the monitor owns sanitized evidence normalization.

## Pattern Assignments

### `.github/workflows/crosswake-ci.yml` and `script/ci_leaf_manifest.json`

**Primary analog:** `.github/workflows/contract-drift-gate.yml`

Copy the literal job identity, per-job timeout, composite setup, and static aggregator topology from
`.github/workflows/contract-drift-gate.yml:49-115`:

```yaml
jobs:
  guard-01-contract-drift-test:
    name: guard-01-contract-drift-test
    runs-on: ubuntu-latest
    timeout-minutes: 20
    env:
      MIX_ENV: test
    steps:
      - uses: actions/checkout@v7
      - uses: ./.github/actions/setup-elixir-cache
        with:
          mix-env: test
      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

  merge-blocking-contract-drift:
    name: merge-blocking-contract-drift
    if: always()
    needs: [guard-01-contract-drift-test, guard-02-generate-and-diff]
    runs-on: ubuntu-latest
    timeout-minutes: 20
```

Apply this shape with these Phase 165 differences:

- `on` is `pull_request` only for recurring product proof. Do not add workflow-level `paths` or
  `paths-ignore`.
- concurrency is scoped by PR number, not `head_ref`, and built-in cancellation is not the
  monotonic cancellation authority;
- every heterogeneous proof stays a literal job with a stable `name`, timeout, logs, artifacts,
  summary, proof family, and exact local remediation command;
- the manifest records leaf job ID, display name, family, remediation command, and allowed exact
  irrelevance reason;
- the umbrella has a literal static `needs` list covering every manifest leaf, runs with
  `if: always()`, and performs no checkout, setup action, dependency install, or repository-script
  invocation;
- skipped is acceptable only when the classifier issued the leaf's exact manifest-declared
  irrelevance decision. Missing, failed, cancelled, timed out, stale, action-required, empty,
  unknown, or unexplained skipped results fail.

Do **not** copy the legacy trigger/concurrency block at
`.github/workflows/contract-drift-gate.yml:3-5,41-47`; it is the topology being replaced.

The manifest validator should parse the workflow structurally and enforce, bidirectionally:

```text
manifest leaf IDs == declared leaf jobs == umbrella static needs
manifest display names == literal workflow display names
merge-blocking producer count for the umbrella == 1
```

Dynamic matrices are inappropriate for heterogeneous leaves. A matrix is acceptable only for a
homogeneous compatibility axis whose generated check names remain stable and governable.

### Trusted cancellation controller and pure selector

**No exact workflow analog exists.** The closest repository trust boundary is
`.github/workflows/required-checks-audit.yml:50-67`, which keeps top-level permission read-only and
adds only the job-scoped permissions required by the controller:

```yaml
permissions:
  contents: read

jobs:
  audit-required-checks:
    permissions:
      contents: read
      issues: write
```

For `cancel-obsolete-crosswake-ci.yml`, use `workflow_run: {types: [requested]}` from trusted
default-branch workflow code, grant only `actions: write` (and `contents: read` only if trusted
policy code must be checked out), and never check out or consume PR code. Never use
`pull_request_target`.

Put selection in `script/select_obsolete_ci_runs.py`, following the pure dataclass/function/test
shape of `script/check_aggregator_result_semantics.py:11-63,128-168`:

```python
@dataclass(frozen=True)
class Evaluation:
    disposition: str
    classification: str

def evaluate_results(results, required_leaves, irrelevant_leaves):
    required = set(required_leaves)
    irrelevant = set(irrelevant_leaves)
    declared = set(results)
    # closed validation; return a typed decision instead of mutating external state
```

The selector accepts validated current-run and candidate records and selects only candidates with
the same literal workflow identity, exactly one identical PR number, and a strictly lower positive
run ID. Equal, greater, missing, malformed, multiple-PR, mismatched, truncated, or ambiguous input
selects nothing. Keep GitHub API cancellation in the workflow/controller layer, after the pure
selector has passed its fixtures. Ordinary cancellation should be attempted first; force-cancel is
only a bounded fallback if ordinary cancellation does not respond.

Required self-test cases mirror the table-driven subtests at
`script/check_aggregator_result_semantics.py:128-168`: lower selects; equal/newer do not; workflow
or PR mismatch does not; malformed ID, missing PR, multiple PRs, and incomplete pagination do not.

### `script/classify_ci_change.py`

**Safety analog:** `lib/crosswake/planning/first_adopter_context.ex`

Copy its argv-based Git invocation, NUL-delimited parsing, deterministic ordering, path
containment, and non-echoing fail-closed posture from lines 280-359:

```elixir
case System.cmd(
       "git",
       ["-C", root, "ls-files", "--cached", "--others", "--exclude-standard", "-z"],
       stderr_to_stdout: true
     ) do
  {output, 0} -> {:ok, String.split(output, <<0>>, trim: true) |> Enum.uniq()}
  _ -> :error
end
```

The Python classifier should use `subprocess.run([...], stdout=PIPE)` with
`git diff --name-status -z -M -C BASE MERGE`, keep filenames as data, and parse status arity
explicitly. `R`/`C` consume and evaluate both old and new paths; deletions retain their path.
Unknown status, truncated record, empty output, zero/missing/unresolvable SHA, shallow history,
mixed docs/executable paths, or any unallowlisted path returns `full_proof`.

The safe-relative-path guard at
`lib/crosswake/planning/first_adopter_context.ex:415-425` is the local convention:

```elixir
Path.type(path) == :relative and path not in ["", "."] and
  not String.contains?(path, <<0>>) and
  Enum.all?(Path.split(path), &(&1 not in ["", ".", ".."]))
```

The old inline classifiers at `.github/workflows/phase69-proof.yml:23-49` and
`.github/workflows/phase75-closeout-gate.yml:28-54` are explicit **anti-analogs**: do not copy
`files="$(git diff --name-only ...)" | grep`. Replace them with the central closed classifier.

Emit one versioned JSON object with only closed values such as `classification`, `reason`,
`scheduled_families`, and `irrelevant_leaves`. The workflow must map malformed or missing output to
`full_proof`, never to docs-only.

### Setup/cache actions and runner placement

**Primary analog:** `.github/actions/setup-elixir-cache/action.yml`

Preserve the existing cache outputs and complete compatibility key dimensions from lines 49-98:

```yaml
outputs:
  deps-cache-hit:
    value: ${{ steps.deps-cache.outputs.cache-hit }}
  build-cache-hit:
    value: ${{ steps.build-cache.outputs.cache-hit }}

- id: deps-cache
  uses: actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9
  with:
    key: deps-${{ steps.scope.outputs.value }}-${{ runner.os }}-${{ runner.arch }}-otp${{ steps.beam.outputs.otp-version }}-elixir${{ steps.beam.outputs.elixir-version }}-${{ inputs.mix-env }}-${{ hashFiles(format('{0}/mix.lock', inputs.working-directory)) }}
```

Keep compiled `deps` and `_build` scoped by workflow/job unless two lanes are proven to install the
same dependency topology. Preserve the separately shared Hex tarball cache at lines 133-139 and the
fetch-only bounded retry at lines 141-162. Never extend that retry to compilation, tests, or proof.
Expose only closed cache outcome fields needed by sanitized evidence; do not emit cache keys.

For Android/JVM, copy the official setup pattern from
`.github/workflows/native-behavioral-proof-gate.yml:58-76`:

```yaml
android-package-unit:
  runs-on: ubuntu-latest
  timeout-minutes: 20
  steps:
    - uses: actions/checkout@v7
    - uses: gradle/actions/setup-gradle@v6
    - name: Run Android JVM tests
      working-directory: packages/crosswake-shell-core-android
      run: ./gradlew test
```

Add explicit JDK 17 and wrapper/config/lock identity; do not layer a second hand-rolled Gradle
User Home cache over `setup-gradle`. The generated-shell JVM proof must also move to Linux after the
helper is split.

`script/verify_generated_android_shell.sh:4-15,49-99,102-154` identifies the portability debt:
macOS command-line-tools URLs, Homebrew JDK discovery, `Contents/Home`, and unconditional Android
SDK setup currently precede even JVM-only proof. Split portable generation/JVM verification from
optional emulator/platform provisioning so `CROSSWAKE_ANDROID_CONNECTED_TESTS=0` needs only the
configured Java/Gradle toolchain. Do not add emulator/device proof.

For Swift, retain macOS only for jobs actually invoking Swift/Xcode and improve the current cache
shape at `.github/workflows/native-behavioral-proof-gate.yml:78-95`. The key must include runner OS,
architecture, Swift/Xcode identity, and resolved package state; an absent `Package.resolved` is an
explicit identity, not permission to key only on `Package.swift`.

Apply the runner split specifically to:

- `.github/workflows/phase5-proof.yml:18-44`: Linux; its native proofs are explicitly disabled;
- `.github/workflows/phase18-proof.yml:18-64`: split Elixir/Android JVM from iOS shell proof;
- `.github/workflows/phase79-proof.yml:16-50`: split iOS and Android leaves;
- `.github/workflows/native-behavioral-proof-gate.yml:100-136`: move generated Android from macOS
  to Linux after helper portability.

Every job, including classifier, docs, leaf, controller, and umbrella jobs, receives a bounded
job-level timeout. Remove `DEVELOPER_DIR` wherever no Apple tool is invoked.

### Producer, manifest, aggregator, and branch-protection governance

**Primary analogs:** `script/list_merge_blocking_checks.py`,
`script/check_aggregator_result_semantics.py`, `script/check_required_checks_registered.sh`, and
`script/register_required_checks.sh`.

Extend the producer inventory without changing its stable diagnostics/TSV convention. Copy the
parse/type/literal-name checks from `script/list_merge_blocking_checks.py:44-55,69-83,122-176` and
the exact-one-producer failure from lines 178-196:

```python
def diagnostic(identifier: str, path: str, job: str | None, detail: str, fix: str) -> str:
    source = path if job is None else f"{path} ({job})"
    return (
        f"[crosswake] FAIL: {identifier} - {source}: {detail}\n"
        f"[crosswake]   What to do next: {fix}"
    )
```

Keep literal job IDs/display names and stable provenance. Add manifest/display-name/static-needs
parity here or in `check_ci_leaf_manifest.py`; do not create a competing producer taxonomy.

Extend the closed result evaluator at
`script/check_aggregator_result_semantics.py:24-63`:

```python
if value == "success":
    continue
if value == "skipped" and leaf in irrelevant:
    saw_irrelevant_skip = True
    continue
if value in {"failure", "cancelled", "skipped", "timed_out", "action_required", "stale"}:
    return Evaluation("fail", value)
return Evaluation("fail", "unknown")
```

Add manifest-issued irrelevance, unexpected/missing leaf, and every closed result arm. Preserve the
integration harness shape in `.github/workflows/aggregator-negative-control.yml:44-129`: synthetic
`needs`-shaped JSON, `continue-on-error` only inside the negative-control harness, an `if: always()`
assertion step, and one final call into the policy checker. Production proof leaves must not use
`continue-on-error` as a failure exemption.

Preserve local-before-live auditing from `script/check_required_checks_registered.sh:20-55` and
its bidirectional registered-context checks at lines 73-102. Evolve the registrar's dry-run/apply
boundary from `script/register_required_checks.sh:96-118`:

```bash
desired="$(jq -n --argjson cur "$current" --argjson add "$add" \
  '{ strict: $cur.strict,
     checks: (($cur.checks // []) + $add | unique_by(.context)) }')"

if [ "$DRY_RUN" = "1" ]; then
  echo "[crosswake] DRY_RUN=1 (default) — not writing. Re-run with DRY_RUN=0 to apply."
  exit 0
fi
```

The Phase 165 version needs an exact desired-context policy and exact old/new diff: additive
umbrella registration first, strict live verification with legacy contexts still present, then an
explicit trust approval before retiring old contexts. Re-read and verify protection after apply;
delete old producers only afterward. The scheduled auditor remains read-only drift detection and
must not become an automatic branch-protection writer.

### `scripts/ci_monitor.cjs` and phase-local evidence

**Primary analog:** `scripts/ci_monitor.cjs`

Keep the monitor's standard-library-only CLI, centralized failure path, positive integer
validation, and `gh` subprocess boundary from lines 20-50:

```javascript
function fail(message) {
  process.stderr.write(`ci-monitor: ${message}\n`);
  process.exit(2);
}

function gh(args, capture = false) {
  const result = spawnSync("gh", args, {
    encoding: "utf8",
    stdio: capture ? ["ignore", "pipe", "pipe"] : "inherit",
  });
  if (result.status !== 0) process.exit(result.status ?? 1);
  return capture ? result.stdout : "";
}
```

Add narrow commands for cohort capture, schema validation/self-test, aggregation, and Markdown
generation through the existing dispatch table at lines 274-298. Fetch live JSON into memory,
normalize immediately into an allowlisted canonical record, and write only canonical JSON plus
generated Markdown. Never retain raw API responses or logs.

The normalized schema includes version, repository commit SHA, run ID, attempt, event, stable
workflow/job/check identity, normalized runner class, cohort criteria, source command, sample
count, workflow/job/check counts, workflow start delay, job execution duration, critical path,
aggregate runner-seconds, and closed cache outcome. Calculate durations only from present, ordered
timestamps. Exact job queue time is always represented as `not_exposed`; unavailable cohort or
metric values are `not_measured` with a closed reason.

Use sample count plus median/range and keep timing descriptive. `baseline.json` must exist before
trigger topology changes. `after.json` uses matched cohort criteria; `comparison.md` is generated
from the two canonical files. Preserve SEED-007 only as labeled historical provenance, never as a
silent substitute for a current matched baseline.

### Phase 165 tests and aggregate gate

**Primary analogs:** `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs`
and `script/check_phase164_dependency_security_and_gate_authority.sh`.

Use `ExUnit.Case, async: true`, module attributes for owned paths/contexts, `@tag :tmp_dir` for
isolated repositories, fake executables via `System.cmd`, and exact bounded-output assertions. The
fixture pattern at the Phase 164 test's lines 106-165 is directly reusable:

```elixir
@tag :tmp_dir
test "canonical mode runs both audits and fails closed after the first audit fails", %{tmp_dir: tmp} do
  fixture_root = Path.join(tmp, "repo")
  fake_bin = Path.join(tmp, "bin")
  # copy owned script, create closed fixture inputs, inject fake executable
  {output, status} = System.cmd("bash", [@script], cd: fixture_root, env: env, stderr_to_stdout: true)
  assert status != 0
  refute output =~ "FAIL_AUDIT_DIR"
end
```

Copy its producer/topology assertions from lines 223-277: invoke the real inventory script,
compare exact TSV records, assert literal names and `if: always()`, and refute dangerous escape
hatches such as production `continue-on-error`, registration apply, or ad hoc caches.

Split test ownership as researched:

- `phase165_ci_policy_test.exs`: classifier, cancellation, aggregator, irrelevance, manifest
  negative controls;
- `phase165_ci_integrity_test.exs`: triggers, PR-number concurrency, permissions, Linux/macOS
  placement, every-job timeout, cache identity, static `needs`, and unique producers;
- `phase165_evidence_test.exs`: schema allowlist, sensitive/unknown field rejection, timing
  semantics, matched cohorts, generated Markdown, and `not_exposed`/`not_measured` truth.

Use adversarial fixtures for NUL/newline/glob paths, rename/copy/delete statuses, mixed changes,
malformed SHAs, run-order inversion, manifest omission/extra/duplicate leaves, missing results, and
sensitive evidence fields.

Copy the aggregate gate's section/trap/corrective-command pattern from
`script/check_phase164_dependency_security_and_gate_authority.sh:8-24`:

```bash
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

The gate composes stable recurring contracts only: Python self-tests, focused ExUnit files,
actionlint, shell portability checks, manifest/producer/local protection parity, and evidence schema
validation. Live cohort collection and one-time branch-protection reconciliation remain phase
evidence, not permanent merge-gate work.

## Shared Patterns

### Permissions and trust

- Ordinary PR proof is read-only and executes the synthetic merge result.
- The trusted cancellation controller is isolated on default-branch `workflow_run` code and holds
  only `actions: write`; it never executes PR code.
- Scheduled protection audit remains read-only detection with existing issue-reporting authority.
- Registration remains a maintainer-run dry-run/apply command with green-first preflight.
- Release Please, publish/recovery, schedule, and manual recovery keep their separate non-cancelling,
  secret, approval, and permission boundaries. Do not fold them into `crosswake-ci.yml`.

### Fail-closed diagnostics

Use the existing two-line convention from `script/list_merge_blocking_checks.py:44-49`:

```text
[crosswake] FAIL: <stable-id> - <source>: <bounded detail>
[crosswake]   What to do next: <exact local command or correction>
```

Do not echo untrusted paths beyond already validated safe relative paths, file contents, raw API
payloads, credentials, cache keys, or sensitive context. Unknown classification runs full proof;
unknown cancellation data cancels nothing; unknown aggregator/evidence data fails.

### Contributor summaries

Every leaf summary names the literal proof and exact local remediation command. The umbrella
summary states classification and reason, scheduled families, explicitly irrelevant families,
expected/observed leaf counts, and one exact remediation. Keep wording short and candid, with
explicit units and `observed`, `not measured`, and `not exposed` language. GitHub Checks is the only
UI; do not add a dashboard or custom rendering surface.

### Workflow consolidation rule

Retiring phase-numbered PR workflow files is allowed only after their named proof command and
literal leaf identity exist in the consolidated workflow, manifest parity passes, and the staged
branch-protection migration is verified. Release, recovery/publish, scheduled audit, and advisory
native files stay separate where triggers, permissions, secrets, or trust differ.

## No Exact Analog Found

| File | Role | Data Flow | Reason / Planner Direction |
|---|---|---|---|
| `.github/workflows/cancel-obsolete-crosswake-ci.yml` | trusted controller | event-driven / API mutation | No repository workflow currently uses `workflow_run` plus `actions: write`. Combine the permission isolation of `required-checks-audit.yml` with the new pure selector and research's strict lower-run-ID policy; do not imitate PR-executing workflows. |

The classifier also has no existing rename/copy-aware `git diff --name-status -z` implementation,
but the repository has a strong partial analog for NUL-safe Git argv invocation and fail-closed path
handling in `Crosswake.Planning.FirstAdopterContext`; use that plus the research parser contract.

## Metadata

**Analog search scope:** `.github/actions`, `.github/workflows`, `script`, `scripts`,
`lib/crosswake/planning`, `test/crosswake/proof`, and existing phase-local evidence

**Primary analog files read:** 19

**Patterns intentionally not copied:** branch-name cancellation, workflow-level path filters,
newline/grep classifiers, dynamic heterogeneous matrices, loose cache restore identities,
production `continue-on-error`, automatic branch-protection mutation, raw API/log retention, and
macOS Android device/tool provisioning

**Pattern extraction date:** 2026-08-28
