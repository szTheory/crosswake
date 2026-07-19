# Phase 152: Capability Map, Collateral, and v20 Handoff - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 19
**Analogs found:** 19 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/crosswake/capability_map.ex` | model | transform | `lib/crosswake/support_matrix/support_matrix.ex` | exact |
| `lib/crosswake/capability_map/renderer.ex` | utility | transform, file-I/O | `lib/crosswake/support_matrix/renderer.ex` | exact |
| `guides/capability_map.md` | docs | rendered static output | `guides/support_matrix.md` | exact |
| `test/crosswake/capability_map/capability_map_test.exs` | test | transform, validation | `test/crosswake/support_matrix/support_matrix_test.exs` | exact |
| `test/crosswake/capability_map/renderer_test.exs` | test | file-I/O, render parity | `test/crosswake/support_matrix/renderer_test.exs` | exact |
| `test/crosswake/guides/capability_claims_test.exs` | test | file-I/O, transform scanner | `test/crosswake/guides/native_evidence_drift_test.exs` | role-match |
| `test/crosswake/guides/evidence_manifest_test.exs` | test | file-I/O, schema validation | `test/crosswake/guides/evidence_manifest_test.exs` | exact-self |
| `examples/phoenix_host/e2e/support/evidence_manifest.ts` | utility | file-I/O, batch manifest | `examples/phoenix_host/e2e/support/evidence_manifest.ts` | exact-self |
| `examples/phoenix_host/evidence/evidence-manifest.example.json` | fixture | file-I/O, schema fixture | `examples/phoenix_host/evidence/evidence-manifest.example.json` | exact-self |
| `examples/phoenix_host/e2e/route_tour.spec.ts` | test | request-response, browser e2e, file-I/O | `examples/phoenix_host/e2e/route_tour.spec.ts` | exact-self |
| `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` | test | request-response, browser e2e, offline event-driven | `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` | exact-self |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | utility | event-driven browser state, request-response | `examples/phoenix_host/e2e/support/offline_route_proof.ts` | exact-self |
| `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | service | batch reset, request-response output | `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` | exact-self |
| `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | test | batch reset validation | `examples/phoenix_host/test/crosswake_example/showcase/reset_test.exs` | exact-self |
| `.github/workflows/offline-sync-e2e-gate.yml` | config | batch CI, file-I/O artifacts | `.github/workflows/offline-sync-e2e-gate.yml` | exact-self |
| `README.md` | docs | static entry point | `README.md` | exact-self |
| `examples/phoenix_host/README.md` | docs | static entry point | `examples/phoenix_host/README.md` | exact-self |
| `mix.exs` | config | docs config transform | `mix.exs` | exact-self |
| `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` | docs | planning handoff transform | `.planning/phases/151-subscription-learning-showcase/151-VERIFICATION.md` | role-match |

## Pattern Assignments

### `lib/crosswake/capability_map.ex` (model, transform)

**Analog:** `lib/crosswake/support_matrix/support_matrix.ex`

**Module and enum pattern** (lines 1-18):
```elixir
defmodule Crosswake.SupportMatrix do
  @moduledoc """
  Canonical support-matrix truth shared across manifest generation, doctor, and docs.
  """

  alias Crosswake.Manifest.Types
  alias Crosswake.Manifest.Types.Capability
  alias Crosswake.Manifest.Types.CapabilitySupportEntry
  alias Crosswake.Manifest.Types.ChangeClassEntry
  alias Crosswake.Manifest.Types.PackageSurfaceEntry
  alias Crosswake.Manifest.Types.RebuildDecisionEntry
  alias Crosswake.Manifest.Types.ReleaseBoundaryEntry
  alias Crosswake.Manifest.Types.RuntimeLineRow
  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix
  @statuses [:supported, :verification_required, :unsupported]
  @proof_classes [:merge_blocking, :advisory, :not_applicable]
  @diagnostic_severities [:error, :warning, :advisory]
```

**Typed capability metadata pattern** from `lib/crosswake/manifest/types.ex` (lines 107-130, 756-772):
```elixir
defmodule Capability do
  @moduledoc false

  @enforce_keys [:id, :version]
  defstruct [
    :id,
    :version,
    :family,
    :owner,
    :package_class,
    :proof_class,
    :rebuild,
    :denial,
    :fallback,
    :guide,
    status: :supported,
    prerequisites: [],
    legacy_ids: []
  ]

@type status :: :supported | :verification_required | :unsupported
@type owner :: :bounded_bridge | :native_screen | :backend_seam | :activation | :defer
@type package_class :: :core | :companion | :example_docs_only | :defer
@type proof_class :: :merge_blocking | :advisory
```

```elixir
def new_capability(attrs) when is_list(attrs) do
  struct!(Capability, %{
    id: Keyword.fetch!(attrs, :id),
    version: Keyword.get(attrs, :version, "1.0.0"),
    status: Keyword.get(attrs, :status, :supported),
    family: Keyword.get(attrs, :family, Keyword.fetch!(attrs, :id)),
    owner: Keyword.get(attrs, :owner, :defer),
    package_class: Keyword.get(attrs, :package_class, :defer),
    proof_class: Keyword.get(attrs, :proof_class, :advisory),
    rebuild: Keyword.get(attrs, :rebuild, :none),
    prerequisites: Keyword.get(attrs, :prerequisites, ["declared route support"]),
    denial: Keyword.get(attrs, :denial, "unavailable_capability"),
    fallback: Keyword.get(attrs, :fallback, "fail_closed"),
    guide: Keyword.get(attrs, :guide, "guides/capabilities.md"),
    legacy_ids: Keyword.get(attrs, :legacy_ids, [])
  })
end
```

**Capability catalog source pattern** from `lib/crosswake/manifest/builder.ex` (lines 245-288, 303-335, 370-399):
```elixir
defp capability_catalog do
  [
    [
      id: "deep_link",
      family: "deep_link",
      owner: :activation,
      package_class: :core,
      proof_class: :merge_blocking,
      rebuild: :none,
      prerequisites: [
        "bundled or cached manifest",
        "shell activation support",
        "explicit route entry approval"
      ],
      denial: "route_unavailable",
      fallback:
        "show route unavailable surface that distinguishes inactive routes from routes that reject external entry",
      guide: "guides/native_shell.md#manifest-first-activation"
    ],
    [
      id: "haptics",
      family: "haptics",
      owner: :bounded_bridge,
      package_class: :core,
      proof_class: :merge_blocking,
      rebuild: :none,
      prerequisites: ["declared route capability", "bounded bridge support"],
      denial: "undeclared_capability",
      fallback: "Phoenix route continues without native confirmation feedback",
      guide: "guides/bridge.md#bounded-bridge",
      legacy_ids: ["haptics.impact"]
    ],
```

```elixir
[
  id: "notification_token",
  family: "notification_token",
  owner: :bounded_bridge,
  package_class: :companion,
  proof_class: :advisory,
  rebuild: :companion_required,
  prerequisites: [
    "declared route capability",
    "bounded bridge support",
    "notification authorization already resolved",
    "provider token snapshot available"
  ],
  denial: "unavailable_capability",
  fallback:
    "treat notification token replies as provider-tagged evidence instead of backend registration truth",
  guide: "guides/capabilities.md#bounded-bridge",
  legacy_ids: ["push.notifications"]
],
```

```elixir
[
  id: "scanner",
  family: "scanner",
  owner: :native_screen,
  package_class: :defer,
  proof_class: :advisory,
  rebuild: :companion_required,
  prerequisites: ["scanner-native runtime", "policy-heavy proof lane"],
  denial: "unavailable_capability",
  fallback: "defer scanner support until native and proof posture are explicit",
  guide: "guides/capabilities.md#explicit-defers"
],
```

**Validation pattern** from `lib/crosswake/manifest/validator.ex` (lines 363-385):
```elixir
defp capability_errors(%Types.Capability{} = capability) do
  []
  |> validate_capability_vocab(
    :owner,
    capability.owner,
    [:bounded_bridge, :native_screen, :backend_seam, :activation, :defer]
  )
  |> validate_capability_vocab(
    :package_class,
    capability.package_class,
    [:core, :companion, :example_docs_only, :defer]
  )
  |> validate_capability_vocab(:proof_class, capability.proof_class, [:merge_blocking, :advisory])
  |> validate_capability_vocab(
    :rebuild,
    capability.rebuild,
    [:none, :native_required, :companion_required]
  )
  |> validate_capability_required_string(:denial, capability.denial, capability.id)
  |> validate_capability_required_string(:fallback, capability.fallback, capability.id)
  |> validate_capability_required_string(:guide, capability.guide, capability.id)
  |> validate_capability_prerequisites(capability)
end
```

**Apply:** Create `Crosswake.CapabilityMap` with small explicit vocabularies for categories, display labels, route runtime owners, package owners, and proof postures. Keep row construction deterministic. Do not depend on private manifest catalog shape unless the module API makes that dependency explicit.

---

### `lib/crosswake/capability_map/renderer.ex` (utility, transform + file-I/O)

**Analog:** `lib/crosswake/support_matrix/renderer.ex`

**Imports/render entry pattern** (lines 1-18):
```elixir
defmodule Crosswake.SupportMatrix.Renderer do
  @moduledoc """
  Deterministic Markdown renderer for the canonical support matrix guide.
  """

  alias Crosswake.Manifest.Types.SupportEntry
  alias Crosswake.Manifest.Types.SupportMatrix
  alias Crosswake.Manifest.Types.ActionClassEntry
  alias Crosswake.Manifest.Types.ChangeClassEntry
  alias Crosswake.Manifest.Types.CapabilitySupportEntry
  alias Crosswake.Manifest.Types.PackageSurfaceEntry
  alias Crosswake.Manifest.Types.PromotionRuleEntry
  alias Crosswake.Manifest.Types.RebuildDecisionEntry
  alias Crosswake.Manifest.Types.ReleaseBoundaryEntry

  @type action :: :created | :reused | :updated

  @spec render(SupportMatrix.t()) :: String.t()
```

**Write semantics** (lines 76-96):
```elixir
@spec write(String.t(), SupportMatrix.t()) :: {:ok, action()}
def write(path, %SupportMatrix{} = support_matrix) do
  File.mkdir_p!(Path.dirname(path))

  contents = render(support_matrix)

  case File.read(path) do
    {:ok, ^contents} ->
      {:ok, :reused}

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

**Markdown table pattern** (lines 110-118):
```elixir
defp capability_family_section(entries) do
  [
    "## Capability Families",
    "",
    "| Family | Owner | Posture | Baseline | Proof Status | Package | Proof | Rebuild | Prerequisites | Denial | Fallback | Guide |",
    "|--------|-------|---------|----------|--------------|---------|-------|---------|---------------|--------|----------|-------|",
    Enum.map_join(entries, "\n", &capability_row/1)
  ]
  |> Enum.join("\n")
end
```

**Markdown escaping pattern** (lines 386-402):
```elixir
defp escape_cell(nil), do: "-"

defp escape_cell(value) when is_binary(value) do
  value
  |> String.replace("\\", "\\\\")
  |> String.replace("|", "\\|")
  |> String.replace("\n", " ")
end

defp escape_cell(value), do: escape_cell(to_string(value))
```

**Apply:** Renderer should output the UI-SPEC row order: capability/surface, display label, route/evidence source, category, route runtime owner, package owner, proof posture, denial/fallback behavior, v20 implication. Include `write/2` only if planner wants regeneration support.

---

### `guides/capability_map.md` (docs, rendered static output)

**Analogs:** `guides/support_matrix.md`, `guides/capabilities.md`

**Support truth legend pattern** from `guides/support_matrix.md` (lines 12-33):
```markdown
## Support-Truth Label Legend

Use these labels literally. Each label says what the evidence proves and what it does not prove.

| Label | What it proves | What it does not prove |
|-------|----------------|------------------------|
| merge-blocking proof | Required deterministic proof that must pass before the claim can merge. | It does not prove every platform/device path or any unsupported owner class. |
| advisory evidence | Useful evidence that informs confidence but does not block standard merge flow. | It does not widen support truth by itself. |

Support status is not device evidence: `supported` is not the same as device-verified.
Visual collateral is not correctness proof by itself.
Device/provider evidence is not backend/session authority.
Cached read-only is not offline mutation.
Bridge is not high-frequency or mutation authority.
```

**Capability framing pattern** from `guides/capabilities.md` (lines 1-20):
```markdown
# Crosswake Capability Families

Crosswake does not present capabilities as a generic plugin catalog. It classifies
candidate native affordances by who should own the route interaction loop, then
states the support posture honestly.

## Ownership-First Rubric

Start with the route owner, not the API shape.
```

**Package boundary language** from `guides/capabilities.md` (lines 119-124):
```markdown
## Package Boundary Rules

- `core` = semantic family is low-frequency, typed, route-local, and supportable without provider-specific native package sprawl
- `companion` = family needs extra native/package choreography, backend/operator coupling, or release-boundary pressure beyond core
- `example/docs-only` = family is useful for guidance and classification, but Crosswake is not claiming first-class shipped support yet
- `defer` = family is outside the current thesis, proof budget, or honest support posture
```

**Apply:** Start with "what works today", "what evidence exists", and "what v20 will do". Keep support truth in text labels, not color or screenshots. Do not add dashboard-like UI.

---

### `test/crosswake/capability_map/capability_map_test.exs` (test, transform + validation)

**Analogs:** `test/crosswake/support_matrix/support_matrix_test.exs`, `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs`

**Canonical vocab test pattern** from `test/crosswake/support_matrix/support_matrix_test.exs` (lines 180-184):
```elixir
test "phase 51 split support axes are exposed as canonical vocabularies" do
  assert SupportMatrix.proof_classes() == [:merge_blocking, :advisory, :not_applicable]
  assert SupportMatrix.diagnostic_severities() == [:error, :warning, :advisory]
  assert SupportMatrix.statuses() == [:supported, :verification_required, :unsupported]
end
```

**Derived row test pattern** from `test/crosswake/support_matrix/support_matrix_test.exs` (lines 78-126):
```elixir
test "capability family posture is derived from manifest capability entries" do
  capability_registry = %{
    "haptics" =>
      Types.new_capability(
        id: "haptics",
        family: "haptics",
        owner: :bounded_bridge,
        package_class: :core,
        proof_class: :merge_blocking,
        rebuild: :none,
        prerequisites: ["declared route capability"],
        denial: "undeclared_capability",
        fallback: "Phoenix route continues without native confirmation feedback",
        guide: "guides/bridge.md#bounded-bridge"
      )
  }

  matrix = SupportMatrix.canonical(capability_registry: capability_registry)

  assert matrix.capability_families == [
           Types.new_capability_support_entry(
             family: "haptics",
             owner: :bounded_bridge,
             posture: "bounded_bridge",
             baseline_status: :supported,
             proof_status: :verification_required,
             package_class: :core,
             proof_class: :merge_blocking,
             rebuild: :none,
             prerequisites: ["declared route capability"],
             denial: "undeclared_capability",
             fallback: "Phoenix route continues without native confirmation feedback",
             guide: "guides/bridge.md#bounded-bridge"
           )
         ]
end
```

**Label allowlist pattern** from `examples/phoenix_host/test/crosswake_example/showcase/catalog_test.exs` (lines 117-134):
```elixir
test "support and runtime labels stay visible, allowlisted, and honest" do
  assert Catalog.allowed_support_labels() == @allowed_support_labels

  for card <- Catalog.cards(), label <- Map.fetch!(card, :support_labels) do
    assert label in @allowed_support_labels,
           "D-16/D-17: #{inspect(card.id)} uses unsupported support-label category #{inspect(label)}"

    refute label =~ ~r/\bsupported\b/i,
           "D-17: #{inspect(card.id)} uses broad support wording #{inspect(label)} instead of the allowed support labels"
  end
end
```

**Apply:** Test all capability categories, display labels, package owners, proof postures, route runtime owners, fallback text, and v20 implications. Include synthetic negative cases for broad `supported` claims on advisory/deferred/example rows.

---

### `test/crosswake/capability_map/renderer_test.exs` (test, file-I/O + render parity)

**Analog:** `test/crosswake/support_matrix/renderer_test.exs`

**Determinism/write semantics** (lines 7-27):
```elixir
test "renderer emits deterministic markdown and preserves created, reused, and updated semantics" do
  matrix = SupportMatrix.canonical()

  path =
    Path.join(
      System.tmp_dir!(),
      "crosswake-support-matrix-#{System.unique_integer([:positive])}.md"
    )

  File.rm(path)

  rendered_once = Renderer.render(matrix)
  rendered_twice = Renderer.render(matrix)

  assert rendered_once == rendered_twice
  assert {:ok, :created} = Renderer.write(path, matrix)
  assert {:ok, :reused} = Renderer.write(path, matrix)

  updated_matrix = SupportMatrix.canonical(ios_version: "18.0")
  assert {:ok, :updated} = Renderer.write(path, updated_matrix)
end
```

**Byte-identical guide parity** (lines 256-270):
```elixir
test "guides/support_matrix.md is byte-identical to canonical renderer output after Plan 23-02 enrichment" do
  rendered = Renderer.render(SupportMatrix.canonical())
  on_disk = File.read!("guides/support_matrix.md")

  assert rendered == on_disk,
         "guides/support_matrix.md drifted from canonical Renderer output; regenerate before merging"

  assert rendered == Renderer.render(SupportMatrix.canonical())
end
```

**Escaping regression** (lines 272-294):
```elixir
test "renderer escapes pipe characters in support entry cells so future data cannot rip the markdown column layout" do
  base = SupportMatrix.canonical()

  risky_phoenix =
    Enum.map(base.phoenix, fn entry ->
      %{entry | notes: "alpha | beta"}
    end)

  matrix = %{base | phoenix: risky_phoenix}
  rendered = Renderer.render(matrix)

  assert rendered =~ "alpha \\| beta",
         "renderer must escape `|` in interpolated cells"

  refute rendered =~ "alpha | beta |",
         "rendered output still contains an unescaped pipe in a cell, which would break the markdown table layout"
end
```

**Apply:** Pin `guides/capability_map.md` byte-for-byte to `Crosswake.CapabilityMap.Renderer.render/0`. Add pipe/newline escaping tests using synthetic row text.

---

### `test/crosswake/guides/capability_claims_test.exs` (test, scanner)

**Analog:** `test/crosswake/guides/native_evidence_drift_test.exs`

**Scanner path pattern** (lines 6-24):
```elixir
@scanned_paths [
  "README.md",
  "examples/QUICK_START.md",
  "guides/install.md",
  "guides/native_shell.md",
  "guides/compatibility.md",
  "guides/support_matrix.md",
  "guides/android_uat.md",
  "examples/ios_shell_host/README.md",
  "examples/android_shell_host/README.md",
  "examples/ios_shell_host/CrosswakeShell.xcodeproj/project.pbxproj",
  "examples/android_shell_host/app/build.gradle",
  "priv/templates/crosswake/shell/ios/README.md.eex",
  "priv/templates/crosswake/shell/android/README.md.eex",
  "lib/crosswake/support_matrix/renderer.ex",
  "lib/crosswake/support_matrix/support_matrix.ex",
  "script/capture-native-collateral.mjs",
  ".github/workflows/native-collateral-advisory.yml",
  "examples/native_evidence/evidence-manifest.example.json"
]
```

**Forbidden claim matching pattern** (lines 300-350):
```elixir
|> maybe_line_failure(
  path,
  line,
  line_number,
  ~r/\bphysical-device support\b/i,
  :device_support_overclaim,
  "line overstates physical-device support"
)
|> maybe_line_failure(
  path,
  line,
  line_number,
  ~r/\bmerge-blocking native support\b/i,
  :merge_blocking_native_overclaim,
  "line turns advisory native collateral into merge-blocking support"
)
|> maybe_line_failure(
  path,
  line,
  line_number,
  ~r/\bscreenshot proof\b|\bscreenshot collateral described as proof\b/i,
  :screenshot_proof_overclaim,
  "line treats screenshot collateral as proof by itself"
)
|> maybe_line_failure(
  path,
  line,
  line_number,
  ~r/\b(camera support|media-upload support|provider authority|app-store readiness)\b/i,
  :native_authority_overclaim,
  "line claims native/provider authority from collateral"
)
```

**Apply:** Scan `README.md`, `examples/phoenix_host/README.md`, `guides/capability_map.md`, evidence manifest JSON, and relevant collateral metadata. Add synthetic regressions for `generic plugin support`, `everything works offline`, `native mobile with no native work`, screenshot-as-proof, StoreKit/Play Billing/RevenueCat shipped claims, purchase/subscriber/unlock authority, and deferred/example rows rendered as broad support.

---

### `test/crosswake/guides/evidence_manifest_test.exs` (test, schema validation)

**Analog:** current same file

**Field and label allowlists** (lines 8-25):
```elixir
@root_required_fields ~w(schema_version crosswake_version commit_sha source_job captured_at retention_label routes)

@route_required_fields ~w(route_id runtime_owner platform_runtime command proof_class support_label coordinate_mode source_job captured_at artifacts retention_label known_limitations status)

@expected_route_ids ~w(library bridge-proof offline-study selective-native-claim-capture)

@allowed_labels [
  "merge-blocking proof",
  "advisory evidence",
  "checked-in public-coordinate proof",
  "local-dev proof",
  "generated public-coordinate proof",
  "JVM hermetic proof",
  "emulator evidence",
  "device evidence",
  "verification-required",
  "rebuild-required"
]
```

**Validation pipeline** (lines 195-203):
```elixir
defp validate_route(route, artifact_root) do
  route_id = Map.get(route, "route_id", "<unknown>")

  required_route_field_failures(route, route_id) ++
    route_id_failures(route, route_id) ++
    label_failures(route, route_id) ++
    limitation_failures(route, route_id) ++
    unavailable_failures(route, route_id) ++
    artifact_failures(route, route_id, artifact_root)
end
```

**Limitation/artifact pattern** (lines 254-303):
```elixir
defp limitation_failures(route, route_id) do
  limitations = Map.get(route, "known_limitations")

  cond do
    not is_list(limitations) or limitations == [] ->
      ["route #{route_id} missing known_limitations"]

    not Enum.any?(limitations, &String.contains?(&1, "does not prove")) ->
      ["route #{route_id} known_limitations missing non-claim language"]

    true ->
      []
  end
end
```

**Apply:** Expand expected route IDs to hub, AdminPilot, Fieldserv, LearnLoop, bridge, offline study, native fallback, and capability-pressure entries. Add allowed `support_label` values for `Demo pressure`, `Future gap`, and `Next-pack candidate`; keep proof posture separate from support/capability labels.

---

### `examples/phoenix_host/e2e/support/evidence_manifest.ts` (utility, file-I/O)

**Analog:** current same file

**Types with optional capability metadata** (lines 5-25):
```typescript
export type EvidenceStatus = 'captured' | 'unavailable';
export type CapabilityPosture = 'shipped' | 'demo-pressure' | 'future-gap' | 'next-pack-candidate';

export type EvidenceRoute = {
  route_id: string;
  runtime_owner: string;
  platform_runtime: string;
  command: string;
  proof_class: string;
  support_label: string;
  coordinate_mode: string | null;
  source_job?: string;
  captured_at?: string;
  artifacts: string[];
  retention_label?: string;
  known_limitations: string[];
  status: EvidenceStatus;
  unavailable_reason?: string;
  capability_posture?: CapabilityPosture;
  package_owner?: string;
};
```

**Manifest write pattern** (lines 42-68):
```typescript
export function writeRouteTourEvidenceManifest(artifactDir: string, command: string) {
  const sourceJob = process.env.GITHUB_JOB || defaultSourceJob;
  const capturedAt = new Date().toISOString();
  const retentionLabel = process.env.CROSSWAKE_EVIDENCE_RETENTION_LABEL || defaultRetentionLabel;
  const routes = routeTourEntries(command);

  assertRequiredArtifacts(artifactDir, routes);
  mkdirSync(artifactDir, { recursive: true });

  const manifest: EvidenceManifest = {
    schema_version: schemaVersion,
    crosswake_version: crosswakeVersion(),
    commit_sha: commitSha(),
    source_job: sourceJob,
    captured_at: capturedAt,
    retention_label: retentionLabel,
    routes: routes.map(route => ({
      ...route,
      source_job: sourceJob,
      captured_at: capturedAt,
      retention_label: retentionLabel,
    })),
  };

  const manifestPath = path.join(artifactDir, 'evidence-manifest.json');
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  return manifestPath;
}
```

**Capability-pressure row pattern** (lines 130-149):
```typescript
function fieldservCapabilityPressure(routeId: string, capability: string, command: string): EvidenceRoute {
  return {
    route_id: routeId,
    runtime_owner: capability === 'capture' ? 'native_screen' : 'future_native_control',
    platform_runtime: 'browser-chromium',
    command,
    proof_class: 'capability-map evidence',
    support_label: 'future gap',
    coordinate_mode: null,
    artifacts: [],
    known_limitations: [
      `${capability} is represented as Fieldserv pressure for Phase 152 capability mapping, not shipped runtime support.`,
      'The browser route tour asserts this pressure before screenshots; screenshots alone are not correctness proof.',
    ],
    status: 'unavailable',
    unavailable_reason: 'Future native-control or offline-island candidate; Phase 150 intentionally does not ship this production capability.',
    capability_posture: capability === 'capture' ? 'next-pack-candidate' : 'future-gap',
    package_owner: 'deferred',
  };
}
```

**Apply:** Generalize beyond Fieldserv. Preserve `known_limitations`, `retention_label`, `unavailable_reason`, and artifact checks. Use exact display labels with capitalized spelling required by the capability map.

---

### `examples/phoenix_host/evidence/evidence-manifest.example.json` (fixture, schema fixture)

**Analog:** current same file

**Fixture row pattern** (lines 1-28):
```json
{
  "schema_version": "1.0.0",
  "crosswake_version": "0.2.0",
  "commit_sha": "example-commit-sha",
  "source_job": "route-tour-proof",
  "captured_at": "2026-06-19T00:00:00.000Z",
  "retention_label": "ci-artifact-14-days",
  "routes": [
    {
      "route_id": "library",
      "runtime_owner": "live_view",
      "platform_runtime": "browser-chromium",
      "command": "npx playwright test e2e/route_tour.spec.ts",
      "proof_class": "merge-blocking proof",
      "support_label": "advisory evidence",
      "coordinate_mode": null,
      "source_job": "route-tour-proof",
      "captured_at": "2026-06-19T00:00:00.000Z",
      "artifacts": [
        "screenshots/library.png"
      ],
      "retention_label": "ci-artifact-14-days",
      "known_limitations": [
        "Screenshots are collateral captured after semantic Playwright assertions pass.",
        "This browser evidence does not prove native share sheet execution, physical-device support, camera support, media-upload support, provider authority, or merge-blocking native support."
      ],
      "status": "captured"
    }
```

**Apply:** Keep committed sample in sync with expanded `evidence_manifest.ts` and `evidence_manifest_test.exs`. Include unavailable capability-pressure rows with empty `artifacts`, concrete `unavailable_reason`, `capability_posture`, and `package_owner`.

---

### `examples/phoenix_host/e2e/route_tour.spec.ts` (test, browser e2e + file-I/O)

**Analog:** current same file

**Semantic assertions before manifest write** (lines 28-51):
```typescript
test('@learnloop proves LiveView, bounded bridge, offline island, LearnLoop, and native-owned fallback route semantics before screenshots', async ({ page, context }) => {
  mkdirSync(routeTourScreenshotDir, { recursive: true });

  await proveShowcaseHub(page);

  await proveSaasRoute(page);
  await proveAdminPilotApprovalFlow(page);
  await proveFieldservRoute(page);
  await proveLearnLoopRoute(page, context, { screenshotDir: routeTourScreenshotDir });

  await proveLibraryRoute(page);
  await captureRouteScreenshot(page, 'library.png');

  await proveBridgeRoute(page);
  await captureRouteScreenshot(page, 'bridge-proof.png');

  await proveOfflineRoute(page, context);
  await captureRouteScreenshot(page, 'offline-study-replayed.png');

  await proveNativeOwnedRoute(page);
  await captureRouteScreenshot(page, 'selective-native-claim-capture-unavailable.png');

  writeRouteTourEvidenceManifest(screenshotDir, routeTourCommand);
});
```

**Showcase support-label assertions** (lines 124-132):
```typescript
await expect(body, ownerMessage('showcase-hub', 'domain label visible')).toContainText('SaaS/Admin');
await expect(body, ownerMessage('showcase-hub', 'domain label visible')).toContainText('Field Service');
await expect(body, ownerMessage('showcase-hub', 'domain label visible')).toContainText('Learning/Training');
await expect(body, ownerMessage('showcase-hub', 'cached read-only support label')).toContainText('Cached read-only');
await expect(body, ownerMessage('showcase-hub', 'demo pressure support label')).toContainText('Demo pressure');
await expect(body, ownerMessage('showcase-hub', 'future native-control support label')).toContainText('Future native-control candidate');
await expect(body, ownerMessage('showcase-hub', 'proof routes secondary')).toContainText('Proof routes stay one click deeper');
await expect(body, ownerMessage('showcase-hub', 'route-owner semantics before screenshots')).toContainText('route-owner semantics');
await expect(body, ownerMessage('showcase-hub', 'showcase before proof')).toContainText('after the showcase explains the product shape');
```

**Fieldserv no-overclaim pattern** (lines 321-349):
```typescript
await page.getByRole('link', { name: /Inspection|Open inspection/i }).first().click();
await expect(page, ownerMessage('fieldserv-inspection', 'inspection route')).toHaveURL(/\/fieldserv\/jobs\/job-1\/inspection$/);
await expect(page.locator('body'), ownerMessage('fieldserv-inspection', 'offline honesty')).toContainText('Future offline island candidate');
await expect(page.locator('body'), ownerMessage('fieldserv-inspection', 'offline requirements')).toContainText(/local draft storage|journal\/outbox|reconciliation proof/i);
await expect(page.locator('body'), ownerMessage('fieldserv-inspection', 'no shipped local mutation')).not.toContainText(/saved locally|queued for sync/i);

await page.getByRole('link', { name: /Capture|Native capture/i }).first().click();
await expect(page, ownerMessage('fieldserv-job-capture', 'capture route')).toHaveURL(/\/fieldserv\/jobs\/job-1\/capture$/);
await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'native runtime')).toContainText('Camera capture requires the native app runtime.');
await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'scanner future gap')).toContainText('Scanner support is a future native-control candidate.');
await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'permission pressure')).toContainText('Permission needed');
await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'backend authority')).toContainText('Device evidence is pending backend verification.');
await expect(page.locator('body'), ownerMessage('fieldserv-job-capture', 'no web capture fallback')).not.toContainText(/Use browser camera|Scan document now/i);
```

**Error message pattern** (lines 451-453):
```typescript
function ownerMessage(routeId: string, owner: string) {
  return `route-tour semantic assertion failed for route id ${routeId} (${owner}); screenshots are collateral after this assertion passes`;
}
```

**Apply:** Add any missing AdminPilot/Fieldserv/LearnLoop screenshot names to manifest artifact checks only after their semantic assertions pass. Keep screenshot capture after assertions.

---

### `examples/phoenix_host/e2e/learnloop_route_tour.spec.ts` and `examples/phoenix_host/e2e/support/offline_route_proof.ts`

**Analogs:** current same files

**Focused LearnLoop reset boundary** from `learnloop_route_tour.spec.ts` (lines 19-24):
```typescript
test('@learnloop-offline proves LearnLoop socketless study island queues, syncs, and deduplicates review events', async ({ page, context }) => {
  const reset = await page.request.post('/_e2e/showcase-reset');
  expect(reset.ok(), learnloopMessage('showcase-reset', 'server-owned learning reset')).toBe(true);
  const resetBody = await reset.json();
  expect(resetBody.browser_state_reset, learnloopMessage('showcase-reset', 'browser-owned IndexedDB is not server-reset')).toBe(false);
```

**Shared proof helper reset/route assertions** from `offline_route_proof.ts` (lines 24-49):
```typescript
export async function proveLearnLoopRoute(
  page: Page,
  context: BrowserContext,
  options: LearnLoopRouteProofOptions = {},
) {
  const captureScreenshots = options.captureScreenshots ?? true;

  await resetOfflineStudyDatabase(page, options);

  const reset = await page.request.post('/_e2e/showcase-reset');
  expect(reset.ok(), learnloopProofMessage('showcase-reset', 'deterministic LearnLoop reset')).toBe(true);
  const resetBody = await reset.json();
  expect(
    resetBody.browser_state_reset,
    learnloopProofMessage('showcase-reset', 'browser-owned IndexedDB is not server-reset'),
  ).toBe(false);

  const router = readFileSync(ROUTER_PATH, 'utf8');
  expect(router, learnloopProofMessage('learnloop-dashboard', 'live_view route')).toContain('id: "learnloop-dashboard"');
  expect(router, learnloopProofMessage('learnloop-course', 'live_view route')).toContain('id: "learnloop-course"');
  expect(router, learnloopProofMessage('learnloop-pack', 'live_view route')).toContain('id: "learnloop-pack"');
  expect(router, learnloopProofMessage('learnloop-study-session', 'offline_island route')).toContain('id: "learnloop-study-session"');
  expect(router, learnloopProofMessage('learnloop-study-session', 'offline_island route')).toContain('runtime: :offline_island');
```

**Unsupported-claim guard** from `offline_route_proof.ts` (lines 318-329):
```typescript
async function expectNoUnsupportedLearnLoopClaims(page: Page, routeId: string) {
  await expect(
    page.locator('body'),
    learnloopProofMessage(routeId, 'unsupported claims absent'),
  ).not.toContainText(
    /LiveView works offline|background sync|server reset cleared offline state|native storage shipped|native storage support|generic sync engine|generic sync helper|live storefront support|StoreKit support shipped|Play Billing support shipped|RevenueCat support shipped|purchase succeeded|subscription verified on device|storefront support shipped|device-local entitlement authority/i,
  );
}

function learnloopProofMessage(routeId: string, assertion: string) {
  return `LearnLoop route-tour semantic assertion failed for route id ${routeId} (${assertion}); screenshots are collateral after this assertion passes`;
}
```

**Apply:** If LearnLoop evidence manifest rows are added, add them through the shared helper and keep browser-state reset in Playwright, not server reset.

---

### `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` and reset test

**Analogs:** current same files

**Reset service boundary** from `showcase/reset.ex` (lines 1-25):
```elixir
defmodule CrosswakeExample.Showcase.Reset do
  @moduledoc """
  Server-side showcase reset orchestrator for the Phoenix example host.

  The reset mutates only fixed server-owned resources. Browser-owned IndexedDB
  and outbox state remain reset by the Playwright helpers that own browser state.
  """

  alias CrosswakeExample.LearnLoop
  alias CrosswakeExample.Showcase.Fixtures

  @browser_state_reset false

  def reset! do
    counts = %{
      saas_admin: Fixtures.reset_saas_admin!(),
      field_service: Fixtures.reset_field_service!(),
      learning_training: LearnLoop.reset_seed!().learning_training
    }

    %{
      counts: counts,
      digest: digest(counts),
      browser_state_reset: @browser_state_reset
    }
  end
```

**Reset test pattern** from `showcase/reset_test.exs` (lines 16-52):
```elixir
test "reset is idempotent and returns stable counts plus digest" do
  first = Reset.reset!()
  second = Reset.reset!()

  assert first.counts == second.counts,
         "D-06/D-07/D-08 require two server-side resets to produce stable lane counts"

  assert first.digest == second.digest,
         "D-12 requires the reset digest to be derived from deterministic records"

  assert is_binary(first.digest)
  assert byte_size(first.digest) == 64
end

test "reset result explicitly does not claim browser-owned offline state reset" do
  result = Reset.reset!()

  assert result.browser_state_reset == false,
         "D-10 requires the server reset to return browser_state_reset: false"
end
```

**Apply:** Preserve reset as server fixture reset only. If tests change, extend counts/digest assertions without claiming IndexedDB/local outboxes are cleared by server.

---

### `.github/workflows/offline-sync-e2e-gate.yml` (config, batch CI)

**Analog:** current same file

**Route-tour proof and manifest validation** (lines 168-186):
```yaml
- name: Run route-tour Playwright proof
  working-directory: examples/phoenix_host
  env:
    CROSSWAKE_VERSION: ${{ steps.crosswake-version.outputs.version }}
  run: npx playwright test e2e/route_tour.spec.ts
- name: Assert route-tour required evidence files
  run: |
    set -euo pipefail
    test -s examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json
    test -s examples/phoenix_host/playwright-artifacts/route-tour/screenshots/library.png
    test -s examples/phoenix_host/playwright-artifacts/route-tour/screenshots/bridge-proof.png
    test -s examples/phoenix_host/playwright-artifacts/route-tour/screenshots/offline-study-replayed.png
    test -s examples/phoenix_host/playwright-artifacts/route-tour/screenshots/selective-native-claim-capture-unavailable.png
- name: Validate route-tour evidence manifest
  run: |
    set -euo pipefail
    mix deps.get
    CROSSWAKE_EVIDENCE_MANIFEST_PATH=examples/phoenix_host/playwright-artifacts/route-tour/evidence-manifest.json \
      mix test test/crosswake/guides/evidence_manifest_test.exs
```

**Honest step summary** (lines 222-232):
```yaml
- name: Step summary
  run: |
    {
      echo "## Crosswake route-tour evidence"
      echo ""
      echo "Proven: semantic Playwright assertions covered route ids library, bridge-proof, offline-study, and selective-native-claim-capture before screenshots were captured."
      echo "Captured: evidence-manifest.json, browser screenshots, Playwright HTML report, traces when Playwright produces them, and concise test output in crosswake-route-tour-evidence."
      echo "Advisory: screenshots are route-tour collateral and support reader inspection."
      echo "Not claimed: native share sheet execution, physical-device support, camera support, media-upload support, provider authority, or merge-blocking native support."
      echo "Retention: crosswake-route-tour-evidence is retained for 14 days."
    } >> "$GITHUB_STEP_SUMMARY"
```

**Apply:** Add new screenshot checks only for captured proof routes. Update summary route IDs and non-claims when manifest expands. Keep retention 14 days unless phase explicitly changes it.

---

### `README.md`, `examples/phoenix_host/README.md`, and `mix.exs` (docs/config entry points)

**Analogs:** current same files

**README entry point pattern** from `README.md` (lines 60-86):
```markdown
Open the showcase hub first at `http://localhost:4700/`. It introduces the
SaaS/Admin, Field Service, and Learning/Training lanes with route-owner labels
before asking you to inspect proof routes.

Support-truth labels in this first run stay narrow: `Available today` and
`Proof-backed example` describe web proof surfaces, while `Demo pressure` and
`Future gap` describe native-control candidates that are not shipped broadly.
Showcase screenshots explain the product surface; route-tour assertions prove
route-owner semantics.

> **Advisory native collateral.** The iOS Simulator and Android Emulator frames above are
> `emulator evidence` — advisory, not physical-device proof.
```

**Example README entry point pattern** from `examples/phoenix_host/README.md` (lines 11-20):
```markdown
Open the showcase hub at `http://localhost:4700/` first. It is the
product-shaped entrypoint for the SaaS/Admin, Field Service, and
Learning/Training lanes; proof routes stay one click deeper and are secondary to
the showcase-first path.

Support-truth labels stay literal in this host: `Available today`,
`Proof-backed example`, `Demo pressure`, and `Future gap` separate proof-backed
behavior from future native-control pressure. Showcase screenshots explain the
product surface; route-tour assertions prove route-owner semantics before
screenshots are treated as collateral.
```

**ExDoc extras pattern** from `mix.exs` (lines 103-138, 156-183):
```elixir
defp docs do
  [
    logo: "brandbook/logo/crosswake-mark.svg",
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    formatters: ["html"],
    extras: [
      "README.md",
      "guides/see_it_run.md",
      "CHANGELOG.md",
      "LICENSE",
      "guides/install.md",
      "guides/route_policy.md",
      "guides/web_to_mobile_migration.md",
      "guides/troubleshooting.md",
      "guides/support_matrix.md",
      "guides/adopter_profiles.md",
      "guides/adoption.md",
      "guides/user_flows.md",
      "guides/capabilities.md",
```

```elixir
groups_for_extras: [
  Start: [
    "README.md",
    "guides/see_it_run.md",
    "guides/route_policy.md",
    "guides/install.md"
  ],
  Adopt: [
    "guides/web_to_mobile_migration.md",
    "guides/user_flows.md",
    "guides/adopter_profiles.md",
    "guides/adoption.md"
  ],
  "Runtime Owners": [
    "guides/native_shell.md",
    "guides/bridge.md",
    "guides/capabilities.md",
    "guides/offline.md",
    "guides/packs.md",
    "guides/tokens.md",
    "guides/commerce.md"
  ],
  Truth: [
    "guides/troubleshooting.md",
    "guides/support_matrix.md",
    "guides/compatibility.md",
    "guides/android_uat.md"
  ],
```

**Apply:** Add one short README link to `guides/capability_map.md`; do not duplicate the full map. Register the new guide in `mix.exs` extras and likely the `Truth` group.

---

### `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` (planning doc)

**Analogs:** `.planning/phases/151-subscription-learning-showcase/151-VERIFICATION.md`, `.planning/phases/150-field-service-showcase/150-07-SUMMARY.md`

**Evidence table pattern** from `151-VERIFICATION.md` (lines 20-29):
```markdown
### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | LEARN-01: User can click through a subscription learning/training domain with realistic courses, lessons, packs, learners, progress, and subscription state. | VERIFIED | `/learnloop`, `/learnloop/courses/:id`, `/learnloop/packs/:id`, `/learnloop/history`, and `/learnloop/subscription` are compiled routes in `examples/phoenix_host/lib/crosswake_example/router.ex`. `LearnLoop.Fixtures` defines 3 learners, 3 courses, 6 lessons, 2 content packs, progress checkpoints, and 4 subscription states. Dashboard/course/pack/history/subscription LiveViews render those contexts. ExUnit and Playwright passed. |

**Score:** 4/4 truths verified, 0 present-but-behavior-unverified.
```

**Summary decision pattern** from `150-07-SUMMARY.md` (lines 36-45, 83-87):
```markdown
key-decisions:
  - "Fieldserv route-tour proof treats screenshots as collateral after route-owner, support-truth, backend-verification, and no-overclaiming assertions."
  - "Capability evidence records native capture/scanner/document-scan/permission pressure for Phase 152 without claiming shipped native-control support."
  - "Bridge proof markup keeps the clicked payload inspectable because LiveView replaces the hidden pre after bridge emission."

requirements-completed: [FIELD-01, FIELD-02, FIELD-03, FIELD-04]
```

```markdown
## Decisions Made

- Kept route-tour correctness semantic-first: screenshots are generated only after assertions for route IDs, runtime ownership, support labels, cached read-only posture, permission truth, backend verification, and no shipped local mutation overclaims.
- Left Fieldserv capture as native-screen/capability-map pressure. No browser camera, scanner command, document-scan bridge, permission API, media-upload provider, or native rebuild support was claimed.
- Treated the bridge proof `hidden` attribute mismatch as a browser-proof bug because the emitted payload must remain inspectable after LiveView replaces the pre element.
```

**Apply:** Handoff should be planning-only. Use sections for Pack 1 candidates, explicit exclusions, promotion criteria, named later packs, proof sources, support-truth constraints, and open decisions. Do not add implementation tasks for native controls.

## Shared Patterns

### Canonical Labels And Enum Guardrails
**Source:** `examples/phoenix_host/lib/crosswake_example/showcase/catalog.ex` lines 11-18
**Apply to:** `Crosswake.CapabilityMap`, capability map tests, evidence manifest labels, docs scanner
```elixir
@allowed_support_labels [
  "Available today",
  "Proof-backed example",
  "Demo pressure",
  "Advisory evidence",
  "Future gap",
  "Next-pack candidate"
]
```

### Rendered Docs Parity
**Source:** `test/crosswake/support_matrix/renderer_test.exs` lines 256-270
**Apply to:** `guides/capability_map.md`, renderer test, README/docs entry points
```elixir
rendered = Renderer.render(SupportMatrix.canonical())
on_disk = File.read!("guides/support_matrix.md")

assert rendered == on_disk,
       "guides/support_matrix.md drifted from canonical Renderer output; regenerate before merging"
```

### Evidence Manifest Non-Claims
**Source:** `examples/phoenix_host/e2e/support/evidence_manifest.ts` lines 103-106
**Apply to:** Manifest rows, fixture JSON, ExUnit manifest test, CI summary
```typescript
known_limitations: [
  'Screenshots are collateral captured after semantic Playwright assertions pass.',
  'This browser evidence does not prove native share sheet execution, physical-device support, camera support, media-upload support, provider authority, or merge-blocking native support.',
],
```

### Browser-State Reset Boundary
**Source:** `examples/phoenix_host/lib/crosswake_example/showcase/reset.ex` lines 5-13
**Apply to:** Reset docs, route-tour proof, capability-map fallback text
```elixir
The reset mutates only fixed server-owned resources. Browser-owned IndexedDB
and outbox state remain reset by the Playwright helpers that own browser state.

@browser_state_reset false
```

### CI Artifact Honesty
**Source:** `.github/workflows/offline-sync-e2e-gate.yml` lines 225-231
**Apply to:** Route-tour proof workflow and handoff references
```yaml
echo "Proven: semantic Playwright assertions covered route ids library, bridge-proof, offline-study, and selective-native-claim-capture before screenshots were captured."
echo "Advisory: screenshots are route-tour collateral and support reader inspection."
echo "Not claimed: native share sheet execution, physical-device support, camera support, media-upload support, provider authority, or merge-blocking native support."
echo "Retention: crosswake-route-tour-evidence is retained for 14 days."
```

## No Analog Found

None. All planned files have exact or role-match analogs in the current codebase.

## Metadata

**Analog search scope:** `lib/`, `test/`, `examples/phoenix_host/`, `guides/`, `README.md`, `mix.exs`, `.github/workflows/`, `.planning/phases/149-*`, `.planning/phases/150-*`, `.planning/phases/151-*`
**Files scanned:** 573
**Pattern extraction date:** 2026-07-12
