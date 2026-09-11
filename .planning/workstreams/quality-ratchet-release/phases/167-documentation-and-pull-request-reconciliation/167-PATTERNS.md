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
| `.planning/.../evidence/phase167-closeout-scope.json` (new) | config / evidence | ordered transform | default-branch dependency-closure manifest | exact |
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

The source-scope manifest records exact protected-default-to-payload path/mode/blob records,
required Phase 166 evidence ancestors, fixed local proof argv, and the runtime/index baseline.
Capture it after all repairs, commit it alone, then freeze HEAD. The manifest deliberately binds
its parent payload and identifies its own path as the sole self-excluded record; the post-freeze
receipt binds the resulting head/tree. Any later source change invalidates the freeze and requires
recapture plus the complete clean-checkout proof.

Push the actual frozen commit ancestry. Do not create a one-commit tree transplant, squash, or
cherry-pick candidate. Require protected default and every evidence OID as ancestors of the exact
head. Merge with a merge commit and prove the tested head remains reachable from fresh default in
addition to tree identity. Keep #148 and #110 open until this proof passes; only then close both
unmerged with fixed bounded supersession markers. PR #145 remains merged historical authority.

Phase closeout uses the same ancestry-preserving pattern after Plan 07:

```text
fresh default after #105 -> frozen local pre-closeout source -> closeout PR head
closeout PR head -- exact-head Crosswake CI --> merge -> reachable identical tree on default
```

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
closeout merge receipt, Phase 167 verification, and `167-08-SUMMARY.md` necessarily postdate the
tested source and are the only evidence-only handoff paths owned by Phase 168's first reversible
landing transaction.

After the closeout merge and immediately before local reconciliation, record the exact local tip in
the post-merge resolution receipt and commit that receipt alone. Reconcile local `main` fail closed:
require fresh remote default, all scope-recorded commits, and that receipt-recorded tip to be
ancestors of local `HEAD`; preserve the real empty index; compare the three runtime files to
pre-merge SHA-256 records without exposing their bytes; reject tracked residue; and require exactly
those three runtime paths as untracked. The scope and resolution receipts must already exist as
tracked handoff artifacts. Phase 167 verification and `167-08-SUMMARY.md` belong to a later lifecycle
and must not be required to exist during this check. Implement this as a fixed-argv, no-write
validator mode; never normalize state with reset, clean, stash, branch switching, or runtime-file
rewrites.

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
