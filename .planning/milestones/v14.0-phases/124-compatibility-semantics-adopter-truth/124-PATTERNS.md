# Phase 124: Compatibility Semantics & Adopter Truth - Pattern Map

**Mapped:** 2026-06-20
**Files analyzed:** 13 new/modified files
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/SemVer.swift` | utility | transform | `lib/crosswake/compatibility/compatibility.ex` (normalize_version/1 + compatible_version?/2) | spec-port (cross-lang) |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/SemVer.kt` | utility | transform | same Elixir spec | spec-port (cross-lang) |
| `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` | service | request-response | self (lines 181-186, 215) — fix `==` to `>=` | self-modification |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt` | service | request-response | self (lines 101, 130) — fix `==` to `>=` | self-modification |
| `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt` | service | request-response | self (line 333) — fix `!=` to `<` floor | self-modification |
| `lib/crosswake/support_matrix/support_matrix.ex` | model | CRUD | self (`change_class_entries/0` lines 771-812) | exact role-match |
| `lib/crosswake/support_matrix/renderer.ex` | utility | transform | self (`change_class_section/1` lines 155-163) | exact role-match |
| `test/crosswake/guides/compatibility_test.exs` | test | request-response | `test/crosswake/guides/adopter_profiles_test.exs` | exact |
| `lib/crosswake/doctor/publish_readiness.ex` | service | request-response | self (`contract_version_parity_check` lines 594-674, `generator_coordinate_parity_check` lines 537-578) | exact role-match |
| `guides/compatibility.md` | config/doc | — | `guides/adopter_profiles.md` (decision-table-first structure) | role-match |
| `CHANGELOG.md` | config/doc | — | self (existing `## [version]` / `### Added` structure) | self-modification |
| `test/crosswake/guides/release_boundaries_test.exs` | test | request-response | self (lines 22-47, `historical_changelog_line?/1`) | exact self-extension |
| `lib/mix/tasks/crosswake.contract.gen.ex` | utility | batch | self (`seed_vectors/1` lines 121-194+) | exact self-extension |

---

## Pattern Assignments

### `SemVer.swift` + `SemVer.kt` (new utility helpers, ~30 LOC each)

**Spec to port:** `lib/crosswake/compatibility/compatibility.ex`

**Elixir `normalize_version/1`** (lines 629-641):
```elixir
defp normalize_version(value) do
  parts = String.split(value, ".")

  normalized =
    case parts do
      [major] -> "#{major}.0.0"
      [major, minor] -> "#{major}.#{minor}.0"
      [_, _, _] -> value
      _other -> value
    end

  Version.parse(normalized)
end
```

**Elixir `compatible_version?/2`** (lines 616-627):
```elixir
defp compatible_version?(available, required)
     when is_binary(available) and is_binary(required) do
  case {normalize_version(available), normalize_version(required)} do
    {{:ok, normalized_available}, {:ok, normalized_required}} ->
      Version.compare(normalized_available, normalized_required) != :lt

    _other ->
      available == required   # fail-closed fallback on malformed input
  end
end

defp compatible_version?(_available, _required), do: false
```

**Key contracts the native port MUST replicate:**
1. `"1"` → `"1.0.0"`, `"1.1"` → `"1.1.0"`, `"1.0.0"` stays unchanged.
2. Return value: tri-state comparable — the caller only needs `provides >= demands` (i.e., `compare != :lt` equivalent).
3. **Fail-closed fallback:** if either string cannot be parsed as semver, fall back to `available == required` (deny rather than allow or throw on malformed input). Do NOT return `true` on parse failure.
4. Non-string / nil inputs → `false` (deny).

**Elixir call sites that prove all three axes are floored** (for reference when writing vectors):
- manifest_schema: `compatible_version?(target.manifest_schema_version, compatibility.manifest_schema_version)` (line 283)
- bridge_protocol: `compatible_version?(target.bridge_protocol_version, compatibility.bridge_protocol_version)` (line 308)
- native_runtime: `compatible_version?(target.native_runtime_version, compatibility.native_runtime_version)` (line 333)
- capability version: `compatible_version?(available_version, required_version)` (lines 373, 585)

**Argument order is always `(provides/available, demands/required)` — `provides >= demands` = allow.**

---

### `BridgeChannel.swift` fix sites (lines 181-186, 215)

**Current code at lines 181-186** (the `==` to replace):
```swift
public func evaluate(_ request: BridgeRequestEnvelope, completion: @escaping (BridgeReplyEnvelope) -> Void) {
    guard request.protocolName == Self.protocolName,
          request.version == session.bridgeProtocolVersion,
          request.nativeRuntimeVersion == session.nativeRuntimeVersion else {
        completion(deny(request, reason: "compatibility_mismatch", ...))
        return
    }
```

- `request.protocolName == Self.protocolName` — identifier check, stays `==` (protocol name is not a version).
- `request.version == session.bridgeProtocolVersion` → convert to `SemVer.compatible(provides: session.bridgeProtocolVersion, demands: request.version)` (session = what shell provides; request = what client demands).
- `request.nativeRuntimeVersion == session.nativeRuntimeVersion` → convert to `SemVer.compatible(provides: session.nativeRuntimeVersion, demands: request.nativeRuntimeVersion)`.

**Current code at line 215** (capability/pack check):
```swift
guard session.routeRequiredPacks.allSatisfy({ packRequirement in
    let parts = packRequirement.split(separator: "@", maxSplits: 1).map(String.init)
    let packID = parts[0]
    let requiredVersion = parts.count == 2 ? parts[1] : nil
    let installedVersion = session.installedPacks[packID]
    return requiredVersion == nil ? installedVersion != nil : installedVersion == requiredVersion
}) else {
    completion(deny(request, reason: "pack_incompatible", ...))
    return
}
```

- `installedVersion == requiredVersion` → convert to `SemVer.compatible(provides: installedVersion ?? "", demands: requiredVersion)` (with nil guard: if installedVersion is nil → deny).

---

### `BridgeChannel.kt` fix sites (lines 101, 130)

**Current code at line 101:**
```kotlin
if (request.protocol != PROTOCOL || request.version != session.bridgeProtocolVersion || request.nativeRuntimeVersion != session.nativeRuntimeVersion) {
    return deny(request, "compatibility_mismatch", ...)
}
```

- `request.protocol != PROTOCOL` — identifier check, stays `!=`.
- `request.version != session.bridgeProtocolVersion` → convert to `!SemVer.compatible(provides = session.bridgeProtocolVersion, demands = request.version)`.
- `request.nativeRuntimeVersion != session.nativeRuntimeVersion` → convert to `!SemVer.compatible(provides = session.nativeRuntimeVersion, demands = request.nativeRuntimeVersion)`.

**Current code at line 130:**
```kotlin
val packsCompatible = session.routeRequiredPacks.all { packRequirement ->
    val parts = packRequirement.split("@", limit = 2)
    val packId = parts[0]
    val requiredVersion = parts.getOrNull(1)
    val installedVersion = session.installedPacks[packId]
    if (requiredVersion == null) installedVersion != null else installedVersion == requiredVersion
}
```

- `installedVersion == requiredVersion` → convert to `SemVer.compatible(provides = installedVersion ?: "", demands = requiredVersion)` (with null-installed → deny).

---

### `ActivationCoordinator.kt` fix site (line 333)

**Current code:**
```kotlin
private fun resolve(request: ActivationRequest, manifest: ShellManifest): ShellPresentation {
    if (request.nativeRuntimeVersion != manifest.nativeRuntimeVersion) {
        return ShellPresentation.Denied(
            denial(
                manifest = manifest,
                reason = RouteDenialReason.COMPATIBILITY_MISMATCH,
                routeId = request.routeId,
                message = "This route requires a newer shell binary to boot.",
                hint = "The server requested a different native runtime version than this shell provides."
            )
        )
    }
```

- `request.nativeRuntimeVersion != manifest.nativeRuntimeVersion` → convert to `!SemVer.compatible(provides = manifest.nativeRuntimeVersion, demands = request.nativeRuntimeVersion)` (manifest = what shell provides; request = what server demands).
- Update the denial hint to reflect floor semantics.

**Note on iOS ActivationCoordinator:** Codebase inspection shows `ActivationCoordinator.swift` does NOT contain an equivalent `nativeRuntimeVersion ==` equality check — the iOS coordinator passes the version fields through to the session without a version comparison guard (the check happens in `BridgeChannel.swift`). CONTEXT.md's mention of "iOS ActivationCoordinator equivalent" is likely referring to a guard that doesn't yet exist or is not needed in iOS. Planner should confirm before adding a new guard in iOS, rather than copying the Kotlin fix blindly.

---

### `lib/crosswake/support_matrix/support_matrix.ex` — new `rebuild_decision_table/0` + `RebuildDecisionEntry`

**Analog: `change_class_entries/0`** (lines 771-812):
```elixir
defp change_class_entries do
  [
    Types.new_change_class_entry(
      change_class: "docs-only",
      what_changed: "...",
      adopter_action: "Read the updated guidance and rerun docs integrity only.",
      compatibility_signal: "No compatibility-axis or capability-version change.",
      required_proof: "docs integrity only"
    ),
    Types.new_change_class_entry(
      change_class: "core-only/no native rebuild",
      ...
    ),
    Types.new_change_class_entry(
      change_class: "compatibility-bump only",
      ...
    ),
    Types.new_change_class_entry(
      change_class: "native or companion rebuild required",
      ...
    )
  ]
end
```

**Pattern for `rebuild_decision_table/0`:** Mirror this shape — a public function (not `defp`) returning a list of structs. Each struct covers one row of D-09's axis-change-type-to-rebuild-class mapping. Fields per D-08: `axis`, `change_kind` (`:additive` / `:breaking`), `rebuild_class` (string, VERBATIM from the 4-class taxonomy), `adopter_action`, `denial_signal`, `guide_anchor`.

**The 4 canonical change-class strings** (D-18 — use verbatim everywhere):
- `"docs-only"`
- `"core-only/no native rebuild"`
- `"compatibility-bump only"`
- `"native or companion rebuild required"`

**D-09 axis mapping rows to encode:**
| Axis | change_kind | rebuild_class |
|---|---|---|
| `manifest_schema_version` | `:additive` | `"compatibility-bump only"` |
| `manifest_schema_version` | `:breaking` | `"native or companion rebuild required"` |
| `bridge_protocol_version` | `:additive` | `"compatibility-bump only"` |
| `bridge_protocol_version` | `:breaking` | `"native or companion rebuild required"` |
| `native_runtime_version` | `:additive` | `"native or companion rebuild required"` (no additive-without-rebuild row) |
| `native_runtime_version` | `:breaking` | `"native or companion rebuild required"` |
| `capability_version` (core-owned) | `:additive` | `"compatibility-bump only"` |
| `capability_version` (native/companion) | `:additive` | `"native or companion rebuild required"` |
| `capability_version` | `:breaking` | `"native or companion rebuild required"` |
| `docs_wording` | `:additive` | `"docs-only"` |
| `core_elixir_behavior` | `:additive` | `"core-only/no native rebuild"` |

---

### `lib/crosswake/support_matrix/renderer.ex` — new `rebuild_decision_table_section/1`

**Analog: `change_class_section/1`** (lines 155-163):
```elixir
defp change_class_section(entries) do
  [
    "## Change Classes",
    "",
    "| Change Class | What Changed | Adopter Action | Compatibility Signal | Required Proof |",
    "|--------------|--------------|----------------|----------------------|----------------|",
    Enum.map_join(entries, "\n", &change_class_row/1)
  ]
  |> Enum.join("\n")
end
```

**Pattern for `rebuild_decision_table_section/1`:**
```elixir
defp rebuild_decision_table_section(entries) do
  [
    "## Rebuild Decision Table",
    "",
    "| Axis | Change Kind | Rebuild Class | Adopter Action | Denial Signal | Guide Anchor |",
    "|------|-------------|---------------|----------------|---------------|--------------|",
    Enum.map_join(entries, "\n", &rebuild_decision_table_row/1)
  ]
  |> Enum.join("\n")
end
```

**Insert it in `render/1`** immediately after `change_class_section/1` (around line 57-58), before `action_class_section/1`. The `render/1` function builds a list of section strings joined with `"\n"`.

**The byte-parity guard** at `test/crosswake/proof/phase52_operator_truth_test.exs:151-159` will auto-cover the new section:
```elixir
ProofAssertions.assert_file_exact(
  "proof.docs.support_matrix.byte_parity",
  "guides/support_matrix.md",
  Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical()),
  source: "Crosswake.SupportMatrix.Renderer.render/1",
  hint: "regenerate support matrix guide from canonical renderer output",
  posture: :merge_blocking
)
```

No new test assertion needed for the table presence — the byte-parity guard fails if the section is missing or drifts.

---

### `test/crosswake/guides/compatibility_test.exs` (new)

**Analog: `test/crosswake/guides/adopter_profiles_test.exs`**

**Full pattern to copy:**
```elixir
defmodule Crosswake.Guides.AdopterProfilesTest do
  use ExUnit.Case, async: true

  test "guide publishes exactly one locked adopter-profile matrix" do
    guide = File.read!("guides/adopter_profiles.md")

    assert count_occurrences(guide, "| #{Enum.join(@matrix_header, " | ")} |") == 1
    # ...
    for name <- @locked_names do
      assert guide =~ name
    end
  end

  test "profile guide and linked docs preserve the no-second-support-matrix boundary" do
    guide = File.read!("guides/adopter_profiles.md")
    # ...
    refute guide =~ "| Target | Version | Status | Proof | Notes |"
  end

  defp count_occurrences(content, needle) do
    content
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
```

**Assertions to implement per D-11:**
1. **Table-before-prose ordering** (load-bearing — most likely to regress silently):
   ```elixir
   assert String.contains?(guide, table_header)
   assert :binary.match(guide, table_header) < :binary.match(guide, "Crosswake keeps runtime ownership")
   ```
2. **Mirror-agrees-with-renderer** (anti-drift):
   ```elixir
   rendered = Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical())
   for class_name <- ["docs-only", "core-only/no native rebuild", "compatibility-bump only", "native or companion rebuild required"] do
     assert rendered =~ class_name
     assert guide =~ class_name
   end
   ```
3. **All three axes present in the table region.**
4. **`native_runtime_version` → `native-rebuild` asymmetry locked** (no additive-no-rebuild row for native_runtime).
5. **Refute any support-status table header** (the "no second support matrix" boundary):
   ```elixir
   refute guide =~ "| Target | Version | Status |"
   ```

Use the same `count_occurrences/2` private helper (copy verbatim from analog).

---

### `lib/crosswake/doctor/publish_readiness.ex` — new check + helpers

**Analog A: `contract_version_parity_check/1`** (lines 594-674) — closest in structure:
```elixir
defp contract_version_parity_check(cwd) do
  expected = Crosswake.Bridge.Contract.version()
  # ... collect errors ...
  errors = manifest_errors ++ generated_errors

  result_check(
    id: "contract.version_parity",
    code: if(errors == [], do: "diag.contract.version_parity_ok", else: "diag.contract.version_parity_failed"),
    category: :contract_version_parity,
    passed?: errors == [],
    message: if(errors == [], do: "...", else: "contract version parity failed: #{Enum.join(errors, "; ")}"),
    hint: "Run mix crosswake.contract.gen and commit...",
    docs_reference: "guides/compatibility.md",
    proof_class: :merge_blocking,
    claim_scope: "Contract version parity across committed surfaces",
    details: %{version: expected, surfaces: @all_contract_surfaces, errors: errors}
  )
end
```

**Analog B: `generator_coordinate_parity_check/1`** (lines 537-578) — same shape with different `id`/`category`/`details`.

**New check `compatibility_rebuild_guidance_check/0`** must use `advisory_check/1` (not `result_check/1`) since it NEVER emits `:error`:
```elixir
defp advisory_check(opts) do
  severity = Keyword.fetch!(opts, :severity)
  result = Keyword.fetch!(opts, :result)
  check(Keyword.put(opts, :blocking, severity == :error and result == :fail))
end
```

**`%ReadinessCheck{}` struct fields** (all required per `check/1` at lines 794-815):
- `id`, `code`, `category`, `severity`, `result`, `blocking`, `message`, `hint`, `docs_reference`, `proof_class`, `claim_scope`, `details`
- `rebuild_requirement` (optional, defaults to `%{native_required: false, companion_required: false, reasons: []}`)

**Severity rules per D-13:**
- Baseline (no detected drift): `severity: :advisory, result: :pass`
- Detected parity drift (shared via extracted `contract_version_parity_errors/1`): `severity: :warning, result: :fail`
- NEVER `severity: :error` (parity check owns that).

**`action_sequence_for/1`** — takes a change-class string, returns ordered action list. Derive from `SupportMatrix.change_class_entries/0` `.adopter_action` field. For `"native or companion rebuild required"` expand to 4 steps: regenerate shell → rebuild native app → resubmit App Store/Play Store → coordinated deploy.

**`contract_version_parity_errors/1`** — extract the error-collection logic currently inlined in `contract_version_parity_check/1` (lines ~596-647) into a named private function so BOTH the parity check and the new advisory check call it. Signature: `defp contract_version_parity_errors(cwd) :: [String.t()]`.

**Add to `build_checks/0`** (lines 162-175):
```elixir
defp build_checks(cwd, support_matrix, inspection, opts) do
  [
    # ... existing checks ...
    contract_version_parity_check(cwd),
    compatibility_rebuild_guidance_check(cwd)   # append last
  ]
end
```

**`details` map shape per D-15:**
```elixir
details: %{
  active_action_sequence: action_sequence_for(detected_change_class),
  change_class_guidance: per_class_guidance_map(),
  docs_reference: "guides/compatibility.md"
}
```

**Required alias per CONTEXT.md:**
```elixir
alias Crosswake.Shell.Denial
```

---

### `test/crosswake/guides/release_boundaries_test.exs` — extend with D-19 assertions

**Existing pattern to extend** — the existing locked 4-class string assertions (lines 22-47) already establish the vocabulary contract. Extend with two new `test` blocks:

**Test 1 — structural:** every non-historical `## [x.y.z]` heading has exactly one `### Upgrade Impact` block. Use existing `historical_changelog_line?/1` (lines 456-461) for exemption:
```elixir
defp historical_changelog_line?(line) do
  trimmed = String.trim(line)
  Regex.match?(~r/^## \[\d+\.\d+\.\d+\]/, trimmed) or
    Regex.match?(~r/^\[\d+\.\d+\.\d+\]:\s+https?:\/\//, trimmed)
end
```

**Test 2 — vocabulary/legend parity:** any `### Upgrade Impact` label present in CHANGELOG.md uses one of the 4 verbatim strings AND those strings are still present in `guides/support_matrix.md`'s Change Classes table. Share the same locked 4-string list already tested in line 29-32.

---

### `lib/mix/tasks/crosswake.contract.gen.ex` — extend `seed_vectors/1`

**Existing vector shape** (lines 121-131 excerpt):
```elixir
defp seed_vectors(bridge_vsn) do
  [
    [
      {"id", "vec-001-version-mismatch-deny"},
      {"description", "Request with a stale bridge_protocol_version is denied with compatibility_mismatch"},
      {"request_override", [{"version", "1.0.0"}]},
      {"session_override", []},
      {"expected_outcome", "deny"},
      {"expected_denial_reason", "compatibility_mismatch"}
    ],
    [
      {"id", "vec-003-canonical-version-ok"},
      {"description", "Request with the canonical bridge_protocol_version and a supported command succeeds"},
      {"request_override", [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
      {"session_override", [{"capabilities", [{"app.info.get", "1.0.0"}]}]},
      {"expected_outcome", "ok"},
      {"expected_denial_reason", nil}
    ],
    ...
  ]
end
```

**New floor vectors to add** (D-05/D-06) — append to `seed_vectors/1`. Both allow AND deny directions are required for every floored axis:

For `bridge_protocol_version` floor:
- `vec-NNN-floor-bridge-shell-newer-allow`: session provides `bridge_vsn` (e.g., `"1.1.0"`), request demands older (e.g., `"1.0.0"`) → `"ok"` (this is the bugfix scenario).
- `vec-NNN-floor-bridge-shell-older-deny`: session provides older, request demands `bridge_vsn` → `"deny"` / `"compatibility_mismatch"` (fail-closed preserved).

Repeat same allow/deny pair for `native_runtime_version` and `manifest_schema_version` axes.

For capability/pack floor (D-06):
- `vec-NNN-floor-capability-shell-newer-allow`: session capability version >= required → ok.
- `vec-NNN-floor-capability-shell-older-deny`: session capability version < required → deny.
- `vec-NNN-floor-pack-shell-newer-allow`: installed pack version >= required → ok.
- `vec-NNN-floor-pack-shell-older-deny`: installed pack version < required → deny.

The `write_if_changed/2` helper at lines 51-53 auto-copies to both native paths — no change to the write logic needed.

---

## Shared Patterns

### `result_check/1` vs `advisory_check/1` — choose based on severity intent

**Source:** `lib/crosswake/doctor/publish_readiness.ex` lines 776-792
```elixir
defp result_check(opts) do
  passed? = Keyword.fetch!(opts, :passed?)
  check(Keyword.merge(opts,
    result: if(passed?, do: :pass, else: :fail),
    severity: if(passed?, do: :advisory, else: :error),
    blocking: not passed?
  ))
end

defp advisory_check(opts) do
  severity = Keyword.fetch!(opts, :severity)
  result = Keyword.fetch!(opts, :result)
  check(Keyword.put(opts, :blocking, severity == :error and result == :fail))
end
```

- Use `result_check/1` for checks that can block (emit `:error`).
- Use `advisory_check/1` for the new `compatibility_rebuild_guidance_check` (D-13 — NEVER `:error`).

### `count_occurrences/2` — guide test idiom

**Source:** `test/crosswake/guides/adopter_profiles_test.exs` lines 81-86
```elixir
defp count_occurrences(content, needle) do
  content
  |> String.split(needle)
  |> length()
  |> Kernel.-(1)
end
```

Copy verbatim into `compatibility_test.exs`.

### `historical_changelog_line?/1` — CHANGELOG exemption idiom

**Source:** `test/crosswake/guides/release_boundaries_test.exs` lines 456-461
```elixir
defp historical_changelog_line?(line) do
  trimmed = String.trim(line)
  Regex.match?(~r/^## \[\d+\.\d+\.\d+\]/, trimmed) or
    Regex.match?(~r/^\[\d+\.\d+\.\d+\]:\s+https?:\/\//, trimmed)
end
```

Reuse in the new D-19 structural test (do not duplicate; call the same private helper).

### 4-string vocabulary lock

**Source:** locked in `release_boundaries_test.exs` lines 29-32 and `change_class_entries/0` in `support_matrix.ex` lines 773-811.

These four strings must appear verbatim in every new file that references change classes:
```
"docs-only"
"core-only/no native rebuild"
"compatibility-bump only"
"native or companion rebuild required"
```

---

## No Analog Found

None. All files have analogs or are self-modifications of existing files.

---

## Codebase Observations for Planner

1. **iOS ActivationCoordinator has no `==` version guard.** The CONTEXT.md D-03 mentions "the iOS ActivationCoordinator equivalent" but `ActivationCoordinator.swift` does not contain a `nativeRuntimeVersion ==` check — version fields are passed through to the session, and the actual version check happens in `BridgeChannel.swift`. Planner should investigate whether iOS needs a new guard added or whether the BridgeChannel fix is sufficient for iOS.

2. **`advisory_check/1` is the right builder for `compatibility_rebuild_guidance_check`.** `result_check/1` always emits `:error` on failure; the new check must use `advisory_check/1` which respects an explicit `severity:` keyword.

3. **`rebuild_decision_table/0` should be `def` not `defp`** — Renderer calls it externally (same pattern as `change_class_entries/0` is called via `SupportMatrix.change_class_entries()` in renderer). Verify whether `change_class_entries/0` is exported or if Renderer calls `canonical()` and accesses the field — check the `SupportMatrix.t()` struct fields if so.

4. **`mix crosswake.contract.gen` writes to 3 paths** (lines 51-53). Adding floor vectors to `seed_vectors/1` automatically propagates to both native resource paths via the existing `write_if_changed/2` loop — no path changes needed.

5. **The byte-parity guard at phase52:151-159** covers `guides/support_matrix.md` vs `Renderer.render(canonical())`. If `rebuild_decision_table/0` is called from `Renderer.render/1`, the guard auto-covers the new section. Hand-editing `support_matrix.md` directly will break the guard.

## Metadata

**Analog search scope:** `lib/`, `packages/`, `test/`, `guides/`
**Files scanned:** ~20 source files read, ~15 grep searches
**Pattern extraction date:** 2026-06-20
