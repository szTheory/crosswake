# Phase 167: Documentation and Pull-Request Reconciliation - Pattern Map

**Mapped:** 2026-09-10
**Files analyzed:** 44 candidate new/modified files
**Analogs found:** 44 / 44 (five reusable tracked pattern families; modified files also preserve their in-place structure)

## Scope Rule

This is a reconciliation inventory, not a requirement to touch every candidate. The planner should
modify a conditional narrative/test surface only when the canonical-owner change or a current
package/PR observation demonstrates drift. Historical changelog entries and completed phase
records remain immutable provenance unless privacy, safety, or explicit provenance is defective.

The pattern map preserves these hard boundaries:

- public prose says **first adopter**; durable planning may say **First B2C Adopter** and
  `first_b2c_adopter`;
- no route payload, answer, transcript, credential, account/device identifier, token, private URL,
  host flag, proprietary taxonomy, or adopter identity enters output or evidence;
- Android receives no feature, template, parity, device-proof, or release-scope expansion;
- `#115` and `#57` remain open Phase 168 approval surfaces and must not be merged, closed,
  recreated, published, or treated as release candidates in Phase 167;
- recurring documentation proof extends existing owners; it does not create a workflow, required
  context, public label family, all-facts manifest, or permanent PR ledger.

## File Classification

| New/Modified File | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/capability_map.ex` | model | transform | same file: closed typed row/vocabulary contract | exact |
| `lib/crosswake/capability_map/renderer.ex` | service / renderer | transform | `lib/crosswake/support_matrix/renderer.ex` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | model | transform | `lib/crosswake/capability_map.ex` | role-match |
| `lib/crosswake/support_matrix/renderer.ex` | service / renderer | transform, file-I/O | same file: pure `render/1` plus idempotent `write/2` | exact |
| `lib/mix/tasks/crosswake.docs.sync.ex` (new) | utility / Mix task | batch, file-I/O | `lib/mix/tasks/crosswake.contract.gen.ex` | exact |
| `guides/support_matrix.md` | generated config/document | transform | `lib/crosswake/support_matrix/renderer.ex` output | exact |
| `guides/capability_map.md` | generated config/document | transform | `lib/crosswake/capability_map/renderer.ex` output | exact |
| `script/repository_artifact_policy.json` | config | batch | existing `generated_contracts` record in same file | exact |
| `script/verify_repository.mjs` | utility | batch, file-I/O | same file: closed policy and restoration loop | exact |
| `.github/workflows/crosswake-ci.yml` | config | event-driven, batch | existing `documentation-contracts` and package/ExDoc jobs in same file | exact |
| `script/ci_leaf_manifest.json` | config | event-driven | existing documentation/package proof leaves in same file | exact |
| `script/ci_docs_allowlist.json` (conditional) | config | transform | existing `planning` / `public_docs` families in same file | exact |
| `README.md` | authored document | request-response / reader navigation | same file: reader-job map | exact |
| `CONTRIBUTING.md` | authored document | request-response / maintainer guidance | same file: canonical-owner then contributor-action pattern | exact |
| `guides/install.md` | authored document | request-response | `README.md` reader-job map plus current file | role-match |
| `guides/compatibility.md` | authored document | request-response | `CONTRIBUTING.md` decision/action pattern plus current file | role-match |
| `guides/companion_compatibility.md` | authored document | request-response | `CONTRIBUTING.md` canonical vocabulary pattern plus current file | role-match |
| `guides/architecture.md` (conditional) | authored document | request-response | `README.md` outside-in guide map plus current file | role-match |
| `guides/code-walkthrough.md` (conditional) | authored document | request-response | `README.md` inside-out guide map plus current file | role-match |
| `guides/troubleshooting.md` (conditional) | authored document | request-response | `CONTRIBUTING.md` owner/action remediation pattern plus current file | role-match |
| `guides/physical_iphone_handoff.md` | authored document | request-response | capability-map blocked/promotion semantics | role-match |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | authored runbook | batch | `CONTRIBUTING.md` owner/action pattern plus current file | role-match |
| `packages/crosswake_rulestead/mix.exs` | config | CRUD / dependency resolution | `packages/crosswake_rindle/mix.exs` | exact |
| `packages/crosswake_rulestead/README.md` | authored document | request-response | `packages/crosswake_rindle/README.md` | exact |
| `packages/crosswake_rindle/mix.exs` | config | CRUD / dependency resolution | `packages/crosswake_rulestead/mix.exs` | exact |
| `packages/crosswake_rindle/README.md` | authored document | request-response | `packages/crosswake_rulestead/README.md` | exact |
| `test/crosswake/capability_map/capability_map_test.exs` | test | transform | same file: closed vocabulary and cross-row semantic assertions | exact |
| `test/crosswake/capability_map/renderer_test.exs` | test | transform, file-I/O | `test/crosswake/support_matrix/renderer_test.exs` | exact |
| `test/crosswake/support_matrix/support_matrix_test.exs` | test | transform | `test/crosswake/capability_map/capability_map_test.exs` | role-match |
| `test/crosswake/support_matrix/renderer_test.exs` | test | transform, file-I/O | same file: renderer byte parity and semantic assertions | exact |
| `test/mix/tasks/crosswake.docs.sync_test.exs` (new) | test | batch, file-I/O | `test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` | exact |
| `test/crosswake/proof/phase166_repository_quality_test.exs` | test | batch, transform | same file: artifact registry schema and exact legacy record | exact |
| `test/crosswake/guides/quick_start_adoption_drift_test.exs` | test | transform | capability-map semantic test style | role-match |
| `test/crosswake/guides/release_boundaries_test.exs` | test | transform | capability-map semantic test style | role-match |
| `test/crosswake/guides/architecture_code_walkthrough_test.exs` (conditional) | test | transform | capability-map semantic test style | role-match |
| `test/crosswake/proof/phase69_docs_contract_parity_test.exs` | test | transform | support renderer byte-parity pattern | exact |
| `test/crosswake/proof/phase165_ci_integrity_test.exs` | test | event-driven, transform | same file: repository-wide immutable action-pin assertion | exact |
| `.github/actions/setup-android-jvm/action.yml` | config | event-driven | current immutable action-pin use in same file | exact |
| `.github/workflows/phase68-proof.yml` | config | event-driven | immutable setup-java uses in `.github/workflows/crosswake-ci.yml` | exact |
| `.github/workflows/release-please.yml` | config | event-driven | immutable setup-java uses in same file | exact |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift` | test | event-driven / async | same file: actor-controlled continuation queues | exact |
| `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` | config / durable state | event-driven | current file's `Next Action` and `Blockers` sections | exact |
| `.planning/.../167-.../evidence/pr-dispositions.json` (new; exact name discretionary) | config / evidence | batch | `.planning/.../165-.../evidence/live-observation.json` | role-match |
| `script/check_phase167_default_reconciliation.py` (fix-forward recovery) | utility / validator | batch, clean-checkout + Git ancestry + GitHub boundary | `script/check_phase167_pr_dispositions.py` and Phase 166 exact-commit capture | exact |
| `.planning/.../evidence/fix-forward-failure-ledger.json` (new) | config / evidence | grouped transform | Phase 166 ownership/remediation ledger | role-match |
| `.planning/.../evidence/default-branch-dependency-closure.json` (replacement schema) | config / evidence | ancestry-preserving transform | Phase 166 immutable-tree ownership evidence | role-match |
| `.planning/.../evidence/default-branch-reconciliation-resolution.json` (replacement receipt) | config / evidence | batch | Plan 05 exact-SHA resolution receipt | exact |
| `.planning/.../evidence/phase167-closeout-scope.json` (new) | config / evidence | ordered transform | distinct payload/source candidate manifest in the PR-disposition validator | exact |
| `.planning/.../evidence/phase167-closeout-resolution.json` (new) | config / evidence | batch | Plan 05 exact-SHA resolution receipt | exact |
| `test/crosswake/proof/phase167_documentation_reconciliation_test.exs` (new; exact placement discretionary) | test | batch, transform | `test/crosswake/proof/phase166_repository_quality_test.exs` | role-match |

Root `mix.exs`, `CHANGELOG.md`, `.release-please-manifest.json`, and
`release-please-config.json` are current authorities/read inputs. Do not plan edits to them unless
a fresh reconciliation proves an actual current-truth defect. In particular, do not rewrite
released changelog history for stylistic consistency.

## Pattern Assignments

### Canonical claim owners and semantic tests

**Apply to:**
`lib/crosswake/capability_map.ex`, `lib/crosswake/support_matrix/support_matrix.ex`,
`test/crosswake/capability_map/capability_map_test.exs`, and
`test/crosswake/support_matrix/support_matrix_test.exs`.

**Primary analog:** `lib/crosswake/capability_map.ex` (git-tracked)

**Typed row and closed-vocabulary pattern** (lines 13-41, 44-56):

```elixir
@enforce_keys [
  :id,
  :surface,
  :route_or_evidence_source,
  :category,
  :display_label,
  :route_runtime_owner,
  :package_owner,
  :proof_posture,
  :rebuild,
  :denial_fallback,
  :adoption_implication
]

defstruct @enforce_keys

@categories [:shipped, :demoed, :missing, :deferred, :next_pack_candidate]
@proof_postures [:merge_blocking, :advisory, :not_yet_proven, :unsupported]
```

Extend the typed owner with the smallest closed internal dimensions covering evidence subject,
source binding, and activation state. Keep existing public categories, labels, proof postures,
route owners, package owners, and rebuild classes unchanged.

**Fail-closed construction pattern** (lines 487-490):

```elixir
defp row(attrs) do
  attrs
  |> Map.new()
  |> then(&struct!(Row, &1))
end
```

Use construction/validation that rejects missing fields and incoherent cross-field combinations;
do not let a renderer repair invalid source data.

**Current blocked row to preserve and refine** (lines 424-437):

```elixir
row(
  id: "first-adopter-physical-iphone",
  surface: "Physical-iPhone offline study and replay evidence",
  route_or_evidence_source: "First adopter source-bound physical exit test",
  category: :missing,
  rebuild: :native_required,
  display_label: "Future gap",
  route_runtime_owner: :offline_island,
  package_owner: :native_shell,
  proof_posture: :not_yet_proven,
  denial_fallback:
    "Simulator, generated-shell, browser, unit, and fixture evidence remain explicitly narrower than source-bound physical-device proof.",
  adoption_implication:
    "Support remains blocked until validated TODO-002 input and one signed iPhone complete the source-bound composed route, pack, replay, recovery, and evidence exit test."
)
```

The new model must distinguish reusable verified substrate, dated past-tense reference-host
evidence, and blocked adopter activation. It must mechanically reject all D-20 impossible states,
including reference-host evidence presented as adopter-bound, physical proof derived from
simulator/fixture evidence, absent source binding, silently aged evidence, and promotion while
activation is blocked.

**Semantic test pattern:** `test/crosswake/capability_map/capability_map_test.exs`
(lines 108-145, 191-233):

```elixir
for row <- rows do
  for field <- @required_fields do
    assert Map.has_key?(row, field),
           "D-03: #{inspect(row.id)} missing required capability-map field #{field}"
  end

  assert row.category in @categories
  assert row.proof_posture in @proof_postures
  assert non_empty?(row.denial_fallback)
  assert non_empty?(row.adoption_implication)
end

physical_iphone = row!(rows, "first-adopter-physical-iphone")
assert physical_iphone.proof_posture == :not_yet_proven
assert physical_iphone.adoption_implication =~ "validated TODO-002 input"
assert physical_iphone.adoption_implication =~ "one signed iPhone"
```

Keep exact assertions for closed atoms and required fields. Use focused semantic assertions for
the three claims and table-driven invalid combinations; do not freeze an entire authored sentence.

---

### Projection renderers and generated guides

**Apply to:**
`lib/crosswake/capability_map/renderer.ex`, `lib/crosswake/support_matrix/renderer.ex`,
`guides/capability_map.md`, `guides/support_matrix.md`, their renderer tests, and
`test/crosswake/proof/phase69_docs_contract_parity_test.exs`.

**Primary analog:** `lib/crosswake/support_matrix/renderer.ex` (git-tracked)

**Pure render composition pattern** (lines 18-80):

```elixir
@spec render(SupportMatrix.t()) :: String.t()
def render(%SupportMatrix{} = support_matrix) do
  [
    "# Crosswake Support Matrix",
    "",
    support_truth_legend_section(),
    "",
    section("Phoenix", support_matrix.phoenix),
    "",
    first_adopter_readiness_section(),
    "",
    public_non_claims_section(),
    ""
  ]
  |> Enum.join("\n")
end
```

Both outputs should be produced from canonical typed data in memory. Generated guide bytes must
identify their canonical owner and `mix crosswake.docs.sync` regeneration command. Generated files
are never edited directly.

**Idempotent write pattern** (lines 82-103):

```elixir
@spec write(String.t(), SupportMatrix.t()) :: {:ok, action()}
def write(path, %SupportMatrix{} = support_matrix) do
  File.mkdir_p!(Path.dirname(path))
  contents = render(support_matrix)

  case File.read(path) do
    {:ok, ^contents} -> {:ok, :reused}
    {:ok, _previous} ->
      File.write!(path, contents)
      {:ok, :updated}
    {:error, :enoent} ->
      File.write!(path, contents)
      {:ok, :created}
    {:error, reason} ->
      raise "could not persist Crosswake support matrix guide #{path}: #{:file.format_error(reason)}"
  end
end
```

The sync task's default mode may reuse these writes. Its `--check` mode must not call them: render
to memory, read each target, compare bytes, and fail with canonical source, target, and exactly
`mix crosswake.docs.sync` as correction.

**Contradictory renderer section to replace from canonical claims**
(`lib/crosswake/support_matrix/renderer.ex`, lines 329-347):

```elixir
defp first_adopter_readiness_section do
  [
    "## First Adopter Readiness",
    "",
    "The policy contract is policy-contract complete, while concrete adopter-instance input remains `unknown_blocking`.",
    "",
    "| Surface | Current truth | Promotion evidence | Boundary |",
    "|---------|---------------|--------------------|----------|",
    "| physical-iPhone offline study | device evidence | A committed corrected-provenance physical-device record and deterministic authority gates support one first adopter offline-study flow. | This remains limited to one flow on one recorded iOS runtime line. ... |",
    "",
    "Generic sync is not claimed."
  ]
  |> Enum.join("\n")
end
```

Do not merely reword that hard-coded row. Render the three distinct source-backed claims and the
direct public recovery statement from valid canonical state. Preserve the Android freeze and all
generic-sync/storage/background/multiple-island/simulator/all-device non-claims.

---

### `mix crosswake.docs.sync` and task tests

**Apply to:** `lib/mix/tasks/crosswake.docs.sync.ex` and
`test/mix/tasks/crosswake.docs.sync_test.exs`.

**Primary analog:** `lib/mix/tasks/crosswake.contract.gen.ex` (git-tracked)

**Mix task/import and argument pattern** (lines 1-4, 57-64):

```elixir
defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task

  @shortdoc "Regenerates all derived non-Elixir contract surfaces from the canonical bridge version"

  @impl Mix.Task
  def run(args) do
    {opts, _argv, _invalid} = OptionParser.parse(args, strict: [dev: :boolean])
    dev? = Keyword.get(opts, :dev, false)
    Mix.Task.run("app.start")
    bridge_vsn = Crosswake.Bridge.Contract.version()
```

For docs sync, accept only `[]` and `["--check"]`; reject unknown/combined arguments rather than
silently ignoring `_invalid`. Keep this task separate from `crosswake.contract.gen`.

**Purpose-led output and idempotent write pattern** (lines 70-109, 571-592):

```elixir
Mix.shell().info("""
crosswake.contract.gen complete — bridge_protocol_version=#{bridge_vsn}
  #{@ios_activation_path}
  #{@android_activation_path}
""")

case File.read(path) do
  {:ok, existing} when existing == contents ->
    Mix.shell().info("  unchanged: #{relative_path}")
    :unchanged
  {:ok, _different} ->
    File.write!(path, contents)
    Mix.shell().info("  updated:   #{relative_path}")
    :updated
  {:error, :enoent} ->
    File.write!(path, contents)
    Mix.shell().info("  created:   #{relative_path}")
    :created
  {:error, reason} ->
    Mix.raise("could not write #{relative_path}: #{:file.format_error(reason)}")
end
```

Failure text must be calm, bounded, non-secret, and name one canonical owner, one generated target,
and one correction command. It must not echo generated contents.

**Task-test shell isolation pattern:**
`test/mix/tasks/crosswake.gen.native_controls_ui_test.exs` (lines 8-16, 56-78, 141-152):

```elixir
setup do
  File.rm_rf!(@tmp_dir)
  File.mkdir_p!(@tmp_dir)
  on_exit(fn -> File.rm_rf!(@tmp_dir) end)

  Mix.shell(Mix.Shell.Process)
  on_exit(fn -> Mix.shell(Mix.Shell.IO) end)
  :ok
end

component_hash_before = :crypto.hash(:sha256, File.read!(component))
run(["--dir", @tmp_dir, "--app", "Demo"])
component_hash_after = :crypto.hash(:sha256, File.read!(component))
assert component_hash_before == component_hash_after

assert_raise Mix.Error, ~r/could not (create directory|write|read)/, fn ->
  run(["--dir", blocked_path, "--app", "Demo"])
end
```

Adapt this into tests for default write, `--check` success, drift failure, unknown args, exact
source/target/remediation output, and a real no-write assertion over bytes plus file metadata.

---

### Generated-artifact registry and recurring CI

**Apply to:** `script/repository_artifact_policy.json`, `script/verify_repository.mjs`,
`test/crosswake/proof/phase166_repository_quality_test.exs`, `.github/workflows/crosswake-ci.yml`,
`script/ci_leaf_manifest.json`, and conditionally `script/ci_docs_allowlist.json`.

**Primary analog:** `script/verify_repository.mjs` (git-tracked)

**Closed schema and safe-path pattern** (lines 18-30, 55-85):

```javascript
const generatedContractKeys = ["canonical_source", "output_paths", "regeneration_argv", "remediation_command"];

function safeRelative(value, label) {
  if (typeof value !== "string" || value === "" || path.isAbsolute(value) || value.split(/[\\/]/).includes("..")) {
    throw new Error(`${label} must stay repository-relative`);
  }
}

for (const contract of policy.generated_contracts) {
  sameKeys(contract, generatedContractKeys, "generated contract");
  safeRelative(contract.canonical_source, "generated canonical source");
  for (const argv of contract.regeneration_argv) {
    if (!Array.isArray(argv) || argv.length === 0 || argv.some(part => typeof part !== "string" || !part || /[;&|`\n\r]/.test(part))) {
      throw new Error("generated contract argv must be fixed");
    }
  }
  for (const output of contract.output_paths) safeRelative(output, "generated output");
}
```

Generalize only the invalid singleton/two-invocation assumption. Preserve exact keys, nonempty
fixed argv, safe relative paths, ordered nonempty outputs, and nonempty remediation. Add
cross-record canonical-source/output uniqueness or non-overlap if the implementation chooses that
smallest invariant; do not create another registry.

**No-residue execution/restoration pattern** (lines 229-268):

```javascript
for (const contract of policy.generated_contracts) {
  const snapshots = new Map();
  const beforePaths = gitPathSet(root);
  for (const relativePath of contract.output_paths) {
    const absolute = path.resolve(root, relativePath);
    if (!isInside(root, absolute) || !existsSync(absolute) || lstatSync(absolute).isSymbolicLink()) {
      return { category: "generated_contract_missing", path: relativePath, remediation_command: contract.remediation_command };
    }
    snapshots.set(relativePath, readFileSync(absolute));
  }
  try {
    for (const argv of contract.regeneration_argv) {
      const result = generatorSpawn(argv[0], argv.slice(1), { cwd: root, env: process.env, timeout: 300000 });
      // closed failure handling
    }
  } finally {
    for (const [relativePath, original] of snapshots) writeFileSync(path.join(root, relativePath), original);
  }
}
```

This verifier may continue exercising default write mode and restoring its own output snapshots.
That does not weaken the separate `mix crosswake.docs.sync --check` contract, which must itself be
no-write.

**Exact legacy regression pattern:**
`test/crosswake/proof/phase166_repository_quality_test.exs` (lines 166-192, 361-372):

```elixir
assert registry["canonical_source"] == "lib/mix/tasks/crosswake.contract.gen.ex"
assert registry["regeneration_argv"] == [
  ["mix", "crosswake.contract.gen"],
  ["mix", "crosswake.contract.gen", "--dev"]
]
assert registry["remediation_command"] ==
         "mix crosswake.contract.gen && mix crosswake.contract.gen --dev"

is_list(record["regeneration_argv"]) and
  Enum.all?(record["regeneration_argv"], fn argv ->
    is_list(argv) and argv != [] and Enum.all?(argv, &(is_binary(&1) and &1 != ""))
  end)
```

Replace `assert [registry]` and `length(...) == 2` with multi-record validation, but retain one
exact assertion for the old contract record and add one exact docs-sync record. Add mutation cases
for empty argv, unsafe argv, duplicate/colliding source or outputs, unordered outputs, undeclared
output, generation failure, and restoration.

Wire `mix crosswake.docs.sync --check` into the existing `documentation-contracts` owner and the
appropriate existing package/ExDoc proof. Preserve the `Crosswake CI` umbrella, the visible docs-
only result, release-input exclusion, and the rule that CI never stages generated docs.

---

### Authored current narratives and package-floor reconciliation

**Apply to:** `README.md`, `CONTRIBUTING.md`, current guides/runbook in the classification table,
both companion manifests/READMEs, and their semantic guide/package tests.

**Primary in-place analogs:** `README.md` and `CONTRIBUTING.md` (both git-tracked)

**README-as-reader-job map pattern** (`README.md`, lines 94-107, 179-212):

```markdown
## Choose your path

### Evaluating Crosswake

Start with:

- [guides/architecture.md](guides/architecture.md) for the system mental model ...
- [guides/install.md](guides/install.md) for the public install and proof path
- [guides/support_matrix.md](guides/support_matrix.md) for the current supported baseline

## Proof and support posture

- [guides/support_matrix.md](guides/support_matrix.md) is the canonical support-status surface.
- [guides/troubleshooting.md](guides/troubleshooting.md) maps ... to route-owner fixes.
```

Lead with evaluator/integrator/operator answers and link to generated truth. Repeat only the
minimum volatile fact. Preserve current ExDoc guide groups and README structure.

**Canonical-owner then contributor-action pattern** (`CONTRIBUTING.md`, lines 5-20, 58-70):

```markdown
## Upgrade Impact Labels

### The four canonical change-class strings

Use one of these four strings **verbatim** ...

These strings come from the **single canonical taxonomy** in
`Crosswake.SupportMatrix.change_class_entries/0` and are documented in ...

### Link to the full compatibility guide

- [`guides/compatibility.md`](guides/compatibility.md) — the primary adopter decision guide
- [`guides/support_matrix.md#change-classes`](guides/support_matrix.md#change-classes) — the canonical Change Classes table
```

Add the compact authority map here: executable Elixir/config owner -> generated public projection
-> exact regeneration/check command -> semantic authored guidance. Do not add a governance guide.

For PR #110, reconcile both companion manifests, both package READMEs,
`guides/companion_compatibility.md`, `guides/install.md`, the publish runbook, and focused drift
fixtures/tests as one transaction. Derive version/floor facts from executable manifests and current
published-package authority. Do not preserve the known `~> 0.1` core compatibility footgun or
rewrite released historical entries.

---

### setup-java reconciliation and immutable repository assertion

**Apply to:** `.github/actions/setup-android-jvm/action.yml`, `.github/workflows/crosswake-ci.yml`,
`.github/workflows/phase68-proof.yml`, `.github/workflows/release-please.yml`, and
`test/crosswake/proof/phase165_ci_integrity_test.exs`.

**Primary in-place test analog:** `test/crosswake/proof/phase165_ci_integrity_test.exs`
(lines 592-623; git-tracked)

```elixir
test "Android JVM jobs use Ubuntu and the shared JDK 17 Gradle wrapper setup" do
  workflow = File.read!(@native_workflow)
  setup = File.read!(@android_setup)

  for job <- ["android-package-unit", "android-generated-shell-unit", "phase18-elixir-android-proof", "phase79-android-proof"] do
    body = job_body(workflow, job)
    assert body =~ "uses: ./.github/actions/setup-android-jvm"
  end

  assert setup =~ ~r|actions/setup-java@[0-9a-f]{40} # v5|
  assert setup =~ ~r|gradle/actions/setup-gradle@[0-9a-f]{40} # v6|
end
```

Refresh the official v6 commit at execution time, use the full immutable SHA in all seven live
uses, and change the assertion to exact v6/count/coherence semantics. This is dependency-security
maintenance only: it must not add Android features, device proof, parity, or release requirements.

---

### PackStore waiter-closure test cleanup

**Apply to:**
`packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift`.

**Primary analog:** same tracked file, lines 70-109 and 191-246.

```swift
let reconciliation = Task { await store.reconcileAll() }
await provider.waitForStatusEntries(1)
let invalidation = Task { await store.invalidatePack(initialStatus) }
await provider.waitForInvalidationEntries(1)

await provider.resumeNextStatus(installedResult(for: requirement))
await provider.resumeNextInvalidation(.failure(.providerFailed))
await invalidation.value
await reconciliation.value
```

```swift
private actor ControlledPackProvider: PackProvider {
    private var statusWaiters: [(Int, CheckedContinuation<Void, Never>)] = []
    private var invalidationWaiters: [(Int, CheckedContinuation<Void, Never>)] = []

    private func resumeStatusWaiters() {
        let ready = statusWaiters.filter { waiter in waiter.0 <= statusEntries }
        statusWaiters.removeAll { waiter in waiter.0 <= statusEntries }
        ready.forEach { waiter in waiter.1.resume() }
    }
}
```

Keep actor isolation and deterministic entry barriers. PR #105 should clarify closure ownership,
remain one narrow intent commit, and be verified with current Swift plus umbrella contracts; it
must not widen native behavior.

---

### Parked state and phase-local PR evidence

**Apply to:** `.planning/workstreams/first-b2c-adopter-readiness/STATE.md`, the new Phase 167 PR
disposition evidence, and its focused verifier/test.

**Primary evidence analog:**
`.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/live-observation.json`
(git-tracked), lines 1-13 and 116-130.

```json
{
  "schema_version": 1,
  "repository_sha": "9107cef628fdb1952dddb22243d91a4003b6bff4",
  "captured_at": "2026-09-08T21:46:48.715Z",
  "source_reference": "remote-default-source.json",
  "umbrella_context": "Crosswake CI",
  "docs_probe": {
    "pr_number": 140,
    "classification": "documentation_only",
    "umbrella_result": "success"
  },
  "cleanup": {
    "pull_requests_closed": true,
    "branches_deleted": true
  }
}
```

Use a closed top-level schema with capture time and source/default-branch identity, plus exactly
seven ordinary PR rows and a separate recovery-transaction collection. Each row contains only: PR
number, full observed head SHA, full observed base SHA, closed check summary, closed disposition,
bounded current reason, and next gate. Sort ordinary rows by PR number
and reject unknown keys, abbreviated/non-hex SHAs, duplicate/missing numbers, unknown values, and
privacy scan failure. Do not retain PR titles, bodies, logs, live counts, credentials, URLs, or
free-form remote content.

Before each remote action, refresh exact head/base/check state and compare it with the planned
observation. Stop on mismatch. Record the post-action observation only after current checks settle.
The evidence is dated phase-local provenance, never a live authority or recurring CI fixture.

For parked state, preserve its existing exact status and gate:

```markdown
status: parked_external_dependency

## Next Action

Resume Phase 163.1 only after real, sanitized First B2C Adopter route facts exist and pass the
committed handoff validation chain. Fixture and simulator results remain advisory and
non-promoting; no physical or support claim advances until validated TODO-002 input and a
source-bound signed-device run both pass.
```

Only reconcile contradictory current wording. Preserve the codename, independent resume point,
TODO-002, sanitized route-policy gate, and fresh source-bound signed-device requirement. Do not
infer a route, host, identity, or device fact.

---

### Fix-forward default reconciliation and closeout evidence

**Apply to:**
`script/check_phase167_default_reconciliation.py`,
`script/check_phase167_pr_dispositions.py`, and Phase 167 closure/resolution evidence.

**Primary analogs:** the existing exact-SHA resolution validator in
`script/check_phase167_pr_dispositions.py`, Phase 165 bounded live evidence, and Phase 166's
immutable-tree ownership audit.

Runs 34553181146 and 34544586854 invalidate the earlier historical-boundary topology. The exact
232-path tree was structurally correct but independently red, and its one-commit transplant made
the immutable OIDs used by Phase 166 evidence unreachable. Preserve that 232/11 analysis only as
diagnostic history. It is not a candidate recipe.

```text
remote default 74fc15cc
       |
       +-- actual local ancestry --> full source + demonstrated hermetic repairs
                                      |
                                      +-- sole manifest commit --> frozen candidate head
                                                                      |
                                         local clean proof + exact-head Crosswake CI
                                                                      |
                                           merge commit retains candidate as ancestor
```

First build a closed failure ledger. Group exact failed leaves by their shared executable owner:
generated-contract/cleanliness, Phase 166 ancestry, root contract assertions, repository
environment/output/preflight, and transitive platform jobs. Reproduce owners against the current
full source in an invocation-owned source-by-commit checkout. A repair is authorized only for a
still-reproducible root and must have a RED/GREEN owner regression. A full-source-resolved or
transitive row causes no edit. Android/iOS/browser failures do not authorize feature breadth.

The ledger carries a closed `authorized_repair_paths` universe grounded in both failed runs:
`.github/workflows/crosswake-ci.yml`, `mix.exs`, `lib/crosswake/doctor/doctor.ex`,
`lib/crosswake/telemetry.ex`, `lib/mix/tasks/crosswake.contract.gen.ex`,
`lib/mix/tasks/crosswake.docs.sync.ex`, the Rulestead companion owner,
`script/check_dependency_security.sh`, `script/check_phase166_ownership_ledger.py`,
`script/list_merge_blocking_checks.py`, repository
artifact/stage/environment/verifier owners, the example-host Playwright config, and their exact
repository-verification, Phase 166, Threadline, Rulestead, telemetry, and docs-sync tests listed in
Plan 167-06. Every emitted repair path must be in both this universe and the plan's static
`files_modified`; an out-of-set owner halts for plan revision before any edit.

Checkpoint authorization adds exactly three formatter-owned tests to that universe and no others:
`test/crosswake/proof/phase69_docs_contract_parity_test.exs`,
`test/crosswake/guides/architecture_code_walkthrough_test.exs`, and
`test/crosswake/guides/release_boundaries_test.exs`. Their owner check is `mix format
--check-formatted` followed by those three focused ExUnit files. Recovery resumes from committed RED
tracer `367f5b5491384594a652d137a03933fa3a89418a`; do not rerun or recommit the RED step.

Actual ancestry does not make historical OIDs available inside GitHub's shallow checkout. Split
Phase 166 verification deliberately: recurring `--verify-remediations` validates the closed
queue/schema and current repair inputs without Git-range resolution, while pinned source-by-commit
proof retains full `--ledger`/`--evidence` range, tree, and history validation. A shallow repository
fixture must fail before the split and pass afterward. Do not broaden dozens of jobs with full-depth
fetch unless recorded evidence proves this split unsafe.

The source-scope manifest records exact protected-default-to-payload path/mode/blob records,
required Phase 166 evidence ancestors, fixed local proof argv, and the runtime/index baseline.
Capture it after all repairs, commit it alone, then freeze HEAD. The manifest deliberately binds
its parent payload and identifies its own path as the sole self-excluded record; the post-freeze
receipt binds the resulting head/tree. Any later source change invalidates the freeze and requires
recapture plus the complete clean-checkout proof.

PR #149 head `412dc4d15bed871b4eefabc05ced4567da25c61c` and run `34626117633` are now
failed diagnostic authority, never merge authority. The run completed 47 checks with 40 successes;
the six failed leaves group into two owners and the umbrella is transitive. Four package/core/host
leaves passed their primary proof and then shared `generated_contract_generation_failed` cleanup at
`lib/mix/tasks/crosswake.contract.gen.ex`. Route-tour and e2e have a direct browser-owner failure
plus that cleanup cascade. Exact pinned local proof on 412 passes, so neither owner is locally
reproduced yet and neither symptom alone authorizes repair.

Recover in owner order. Generated cleanup traces first so it cannot mask browser evidence. Its
post-412 repair universe is exactly `script/verify_repository.mjs`,
`script/repository_artifact_policy.json`, `lib/mix/tasks/crosswake.contract.gen.ex`,
`.github/workflows/crosswake-ci.yml`, and `test/js/repository_verification.test.mjs`. A job-equivalent
RED must decide between the closed strategies `dedicated_fully_provisioned_owner` and
`explicit_per_job_prerequisite_closure`: select the former only when generation succeeds under the
supported full root toolchain but not the affected job prerequisites; select the latter only when
one explicit bounded prerequisite set makes every affected job safe. Preserve unconditional
git/status/artifact cleanup either way. Android/iOS remain transitive tests and authorize no
feature, template, device, parity, generator, Maven, JVM, or vector change.

Generated cleanup is complete at RED `24fac450`, GREEN `60d77d61`, and ledger `5a132620`; do not
rerun or recommit that tracer. Browser diagnostics follow only after that GREEN. The browser repair universe is
exactly `script/repository_verification_stages.json`, `script/verify_repository.mjs`,
`examples/phoenix_host/playwright.config.ts`, `.github/workflows/crosswake-ci.yml`, and
`test/js/repository_verification.test.mjs`. Local RED `1e3469dd` and instrumentation `a35e81ef` are
completed and must not be rerun/recommitted. The first hosted diagnostic run 34635587034 is invalid:
step-scoped activation was unavailable to the later upload condition, E2E failure evidence uploaded,
and no category is accepted; its allowance remains consumed 1/1. One user-authorized replacement
diagnostic remains. Its focused fixture first fails on that exact scope defect, then moves the closed
activation and fixed job identity to each browser job's `env`, which later steps inherit. Before the
replacement push, `actionlint` and positive/negative fixtures prove the later condition sees the
mode, diagnostic failure artifacts are suppressed, normal failure artifacts remain published,
browser proof still runs/fails, and only the closed signal can surface. The replacement remains
diagnostic-only; browser repair GREEN follows the hosted category without another push. Its exact closed
diagnostic mode retains each ordinary route-tour/e2e command and failing exit while exposing only
schema version, fixed browser owner, allowlisted low-cardinality category, and fixed job identity.
Unknown modes/categories/fields fail closed. On only that diagnostic path the workflow must suppress
Playwright report/test-result/trace/screenshot/video publication; it may not create a general skip or
weaken the required check. Private inner logs, stdout/stderr, payloads, artifact contents, URLs,
filesystem absolutes, remote prose, and environment values stay invocation-private. Before final
candidate capture, remove the one-head activation/upload diversion and re-prove ordinary required
browser proof authority; a safe recurring closed mapper/redaction assertion may remain. The empty
route-tour `CROSSWAKE_VERSION` observation is only `route_tour_version_presence_empty`; it becomes
causal only if an otherwise identical RED/GREEN regression deterministically follows that input. A
Phase41 is pre-existing hosted nondeterminism, not a35 fallout or a new owner: its unchanged observed
test surfaces authorize no edit. It remains mandatory in the 47-check gate; recurrence on replacement
or final head checkpoints without silent ignore or an extra retry. A new owner/path, failed suppression,
unsafe/inconclusive replacement diagnostic, or exhausted replacement allowance stops for plan
revision before further edit or push.

The post-412 ledger records the invalid original diagnostic as used 1/1 and permits exactly one
replacement browser diagnostic PR #149 head update plus exactly one later final-candidate update.
Neither diagnostic can merge or close/supersede any PR. After both
owners are GREEN, invalidate the 412 manifest, commit all non-manifest bytes, recapture one source
scope, and commit that manifest alone. Complete pinned proof precedes the one guarded final
fast-forward. A missing/red exact-head conclusion, Phase41 recurrence, drift, new owner, or any update
beyond the consumed original plus one replacement plus one final exhausts
the tranche and leaves PR #149/#148/#110 open and unmerged at a checkpoint.

Push the actual frozen commit ancestry. Do not create a one-commit tree transplant, squash, or
cherry-pick candidate. Require protected default and every evidence OID as ancestors of the exact
head. Merge with a merge commit and prove the tested head remains reachable from fresh default in
addition to tree identity. Keep #148 and #110 open until this proof passes; only then close both
unmerged with fixed bounded supersession markers. PR #145 remains merged historical authority.

Phase closeout uses a distinct Plan 08 scope manifest after Plan 07:

```text
payload_source_oid/tree
       |
       +-- sole commit: phase167-closeout-scope.json
                                  |
                         runtime-derived candidate OID/tree
                                  |
                 exact-head Crosswake CI -> merge -> reachable identical tree on default
```

`script/check_phase167_pr_dispositions.py --verify-closeout-candidate` consumes
`phase167-closeout-scope.json`; it must never reuse Plan 06's default-branch manifest. The scope
contains only schema version, payload source OID/tree, exact payload path/mode/blob rows, and the
precomputable self-excluded manifest path/mode/schema expectations. It contains no candidate
identity. The validator derives candidate OID/tree from `--candidate HEAD`, requires its parent to
equal `payload_source_oid`, and proves its tree equals `payload_source_tree` plus exactly that one
manifest path/mode/blob. Only the later closeout resolution records candidate OID/tree.

`.github/workflows/crosswake-ci.yml` is pull-request-triggered, so the successful PR head is CI
authority. The merge/default SHA is proven by reachability and equality of tree OIDs; never demand a
check that the workflow cannot create. The closeout PR includes every pre-closeout non-evidence
validator and known planning/evidence artifact, including the revised plans, this pattern map, the
validation map, recovery validator, fix-forward source-scope manifest, and known Plan 05-07 receipts. Prove
the two one-time validators with positive self-tests and offline/local verify modes on the exact
frozen source tree, record their blob OIDs, and require the closeout PR head tree to equal that
source tree. Hosted Crosswake CI proves recurring repository contracts on that exact PR head, not
direct invocation of those phase-local validators.

The ordinary disposition set is exactly #57, #105, #110, #115, #121, #146, and #147. Keep
#57/#115/#146/#147 open as release-only Phase 168 approval surfaces. Record #148 and the Plan 06
replacement in a separate recovery collection; recovery rows never replace ordinary rows. The
closeout merge receipt, Phase 167 verification, `167-08-SUMMARY.md`, and the final workstream
`ROADMAP.md` and `STATE.md` necessarily postdate merge/verification. During Phase 167 the closeout
receipt records only these exact five path names and the owner
`phase_168_first_reversible_landing`—no blob, presence, landing, or non-local claim. After all final
files exist, a separate Phase 168 scope/receipt binds their blobs and protected-default landing
together before candidate approval.

All Phase 167 execution and evidence commits use the dedicated unprotected branch
`agent-phase167-fixforward`; `origin/main` remains protected authority, and
`git.allow_default_branch_commits` remains unchanged. Remote PR branches may be handled only in
isolated worktrees. After each protected-default merge, first commit the bounded receipt on the
phase branch. If that merge introduced source bytes needed by a later phase candidate, fetch and
validate protected default again, then run exactly `git merge --no-ff --no-edit FETCH_HEAD` on the
still-checked-out phase branch. The integration commit must retain the receipt as first parent and
fresh protected default as second parent, preserve all prior phase ancestry, carry the exact
protected-default source blob, and leave tracked/index/runtime state clean. Only after this
integration proof, when no executor commit is pending and the phase branch is clean, may the local
`main` ref be advanced to that same protected-default OID without checking out `main`. Remain on the
integrated phase branch for every subsequent executor commit and candidate freeze.

After the closeout merge and immediately before local reconciliation, record the exact phase-branch
tip in the post-merge resolution receipt and commit that receipt alone on the phase branch. Reconcile
the local `main` ref fail closed: require fresh remote default, all scope-recorded commits, and that
receipt-recorded phase tip to remain reachable; preserve the real empty index; compare the three
runtime files to pre-merge SHA-256 records without exposing their bytes; reject tracked residue; and
require exactly those three runtime paths as untracked. The scope and resolution receipts must
already exist as tracked phase-branch handoff artifacts. The summary, verification, ROADMAP, and STATE reach their final bytes only
after merge/verification and therefore are not pre-closeout candidate inputs. The Phase 167
lifecycle validator requires only the exact five names and fixed Phase 168 owner; it must not require
their current presence, blobs, or default landing. Phase 168 owns those later checks. Implement
reconciliation as a fixed-argv, no-write validator mode; reject a protected checked-out branch,
pending executor commit, local-main executor commit, reset, clean, stash, branch switching, runtime
rewrite, or config-policy change.

## Shared Patterns

### Authority order

Apply to every task:

```text
executable owner -> validate closed semantics -> render deterministic projection
                 -> semantic authored guidance -> focused recurring proof
```

Generated Markdown is byte-authoritative only as a projection. Authored prose is guarded by
semantic invariants and stable links/examples, not broad snapshots.

### Failure and remediation shape

Source: `lib/mix/tasks/crosswake.contract.gen.ex:575` and
`script/verify_repository.mjs:165`.

```text
FAIL <purpose> [category=<closed-value>] [path=<escaped-relative-path>];
corrective-command=<one fixed command>
```

Never include artifact contents, adopter facts, environment values, PR prose, or secrets.

### CI ownership

Extend existing literal leaves and `documentation-contracts`; preserve `Crosswake CI` as the sole
required umbrella. A docs-only change receives visible documentation proof while browser, Android,
Apple, and product proof stays unscheduled. Release-sensitive runbooks remain excluded from the
docs-only allowlist.

### PR optimistic-concurrency boundary

```text
fresh structured read -> exact head/base/check comparison -> locked action -> current CI
-> bounded post-action record
```

For #121: rebase/expand/verify/merge, or supersede only if the Dependabot branch cannot carry the
coherent fix. For #110: rebase/expand every package/docs/fixture surface and merge, or supersede
only if it cannot remain reviewable. For #105: rebase/squash/verify/merge. For #115 and #57:
comment the current Phase 168 gate and stop; no release mutation.

### Privacy and platform boundary

Run `mix crosswake.adoption_context.scan` after current-doc/state/evidence changes. Public text uses
`first adopter`; durable planning uses the codename only. Preserve opaque source references and
low-cardinality outcomes. No task in this phase adds Android scope or converts retained
reference-host evidence into adopter activation.

## No Analog Found

No file lacks a usable codebase analog. The new docs-sync task composes existing renderer and Mix
task patterns; the new PR evidence combines the existing bounded live-observation shape with the
Phase 166 closed-schema validator style. There is intentionally no analog for a permanent PR
ledger, new docs workflow, generated all-facts manifest, or new public support taxonomy because
those designs are prohibited.

## Tracked-Source Verification

Every named existing analog was checked with `git ls-files -- <path>` and resolved to tracked
repository source. No `.gsd`/plugin/cache/runtime mirror path is used.

Verified tracked analogs include:

- `lib/crosswake/capability_map.ex`
- `lib/crosswake/support_matrix/renderer.ex`
- `lib/mix/tasks/crosswake.contract.gen.ex`
- `test/mix/tasks/crosswake.gen.native_controls_ui_test.exs`
- `script/verify_repository.mjs`
- `test/crosswake/proof/phase166_repository_quality_test.exs`
- `test/crosswake/capability_map/capability_map_test.exs`
- `test/crosswake/proof/phase165_ci_integrity_test.exs`
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/PackStoreTests.swift`
- `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/evidence/live-observation.json`
- `README.md`
- `CONTRIBUTING.md`

## Metadata

**Analog search scope:** `lib/crosswake`, `lib/mix/tasks`, `test/mix/tasks`, `test/crosswake`,
`script`, `.github`, `guides`, `docs`, `packages`, and prior quality-workstream evidence

**Files scanned:** 73 focused candidates plus repository-wide `rg` inventories for action pins,
package floors, current support claims, and evidence schemas

**Pattern extraction date:** 2026-09-10

**Mutable-input warning:** PR heads, bases, checks, mergeability, and the suitable official
`actions/setup-java` v6 SHA must be refreshed during execution; values observed in research are not
write authority.
