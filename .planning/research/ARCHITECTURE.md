# Architecture Research

**Domain:** Production Shell Runtime Line — v4.0 integration architecture
**Researched:** 2026-06-03
**Confidence:** HIGH — all findings grounded in committed source code (manifest/types, compatibility, doctor, SupportMatrix, checked-in iOS/Android shells, operator_inspection, gen.shell); no external sources needed.

---

## System Overview

The existing architecture already has most of the structure v4.0 needs. The five v4.0 feature areas all attach to existing surfaces without introducing new high-frequency bridge paths or standalone packages. The key constraint is that every new behavior must be derivable from existing canonical truth (manifest, capability registry, SupportMatrix) rather than creating a parallel policy ledger.

```
┌─────────────────────────────────────────────────────────────────────┐
│                  HOST PHOENIX APPLICATION (adopter-owned)            │
│  Route Policy DSL  →  mix crosswake.gen.shell  →  host shell proj   │
│  (NEW) runtime_line: / rebuild_policy: fields in route/capability    │
├────────────────────────────────────────────────────────────────────┤
│                   CORE ELIXIR LIBRARY (crosswake)                   │
│                                                                      │
│  ┌───────────────┐  ┌────────────────┐  ┌──────────────────────┐   │
│  │   Manifest    │  │ Compatibility  │  │  SupportMatrix       │   │
│  │   Types.Root  │  │ Types.Compat.  │  │  canonical/0         │   │
│  │  + runtime    │  │ + runtime_line │  │  + runtime_line rows │   │
│  │    _line_     │  │   _policy_     │  │  + permission rows   │   │
│  └──────┬────────┘  └───────┬────────┘  └──────────┬───────────┘   │
│         │                   │                       │               │
│  ┌──────▼───────────────────▼───────────────────────▼───────────┐  │
│  │                   Crosswake.Doctor                            │  │
│  │  (phase_3 shells + NEW phase_v4_runtime_line_findings)        │  │
│  │  (NEW phase_v4_permission_template_findings)                  │  │
│  │  (NEW phase_v4_diagnostic_export_findings)                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │          OperatorInspection  (rebuild_entry already exists)   │   │
│  │  + runtime_line_entry  + permission_template_entry            │   │
│  └──────────────────────────────────────────────────────────────┘   │
├────────────────────────────────────────────────────────────────────┤
│              CHECKED-IN NATIVE SHELLS  (examples/)                  │
│                                                                      │
│  iOS (Swift)                     Android (Kotlin/JVM)               │
│  ActivationCoordinator           ActivationCoordinator.kt            │
│  BridgeChannel.swift             BridgeChannel.kt                    │
│  (NEW) DiagnosticExport.swift    (NEW) DiagnosticExport.kt          │
│  (NEW) PermissionTemplate refs   (NEW) PermissionTemplate refs      │
│  (NEW) RuntimeLinePolicyReader   (NEW) RuntimeLinePolicyReader      │
├────────────────────────────────────────────────────────────────────┤
│              GENERATORS + PROOF SCRIPTS                             │
│                                                                      │
│  mix crosswake.gen.shell (ios|android)                              │
│   + emits permission/entitlement template stubs                     │
│   + emits runtime-line policy fixture in shell README               │
│  script/verify_generated_ios_shell.sh  (modified)                   │
│  script/verify_generated_android_shell.sh  (closure)                │
│  (NEW) CI: phase_v4_runtime_line_proof.yml (hermetic, merge-block)  │
│  (NEW) CI: advisory emulator/device lane (continue-on-error: true)  │
└────────────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

| Component | Responsibility | New vs. Modified |
|-----------|----------------|-----------------|
| `Manifest.Types.Compatibility` | Three version axes: manifest_schema, bridge_protocol, native_runtime | **Modified** — add `rebuild_policy` struct with OTA-safe vs. rebuild decision rules derived from version axes |
| `Manifest.Types.SupportMatrix` | Canonical support truth rows | **Modified** — add `runtime_line` entries, `permission_template` entries, `diagnostic_export` entry |
| `Crosswake.SupportMatrix` | `canonical/0` and all accessor functions | **Modified** — add runtime_line_truth, permission_template_truth, diagnostic_export_truth accessor functions; add new promotion_rule entries for Android verification closure |
| `Crosswake.Compatibility` | Version axis evaluation and route findings | **Modified** — `validate_native_runtime` extended to emit `:rebuild_required` vs. `:ota_safe` signal from policy |
| `Crosswake.Doctor` | Diagnostic findings pipeline | **Modified** — add `phase_v4_runtime_line_findings/2`, `phase_v4_permission_template_findings/2`, `phase_v4_diagnostic_export_findings/2`; extend `Doctor.Report` struct |
| `Crosswake.OperatorInspection` | Route-level inspection surface | **Modified** — add `runtime_line_entry/2` and `permission_template_entry/2` per route |
| `Crosswake.Shell.Fixtures` | Bundled shell fixture JSON | **Modified** — add `diagnostics_export_fixture` and `permission_template_fixture` exports |
| iOS shell `ActivationCoordinator.swift` | Native route activation | **Modified** — read runtime_line_policy from manifest fixture; enforce rebuild check |
| iOS shell `BridgeChannel.swift` | Bounded bridge dispatch | **Not modified** — diagnostic export is NOT a bridge command |
| iOS shell `DiagnosticExport.swift` | Shell-to-host diagnostic flush | **New** — fire-and-forget POST to host `/api/crosswake/diagnostic_export`; no bridge path |
| Android shell `ActivationCoordinator.kt` | Native route activation | **Modified** — read runtime_line_policy from manifest fixture; enforce rebuild check |
| Android shell `DiagnosticExport.kt` | Shell-to-host diagnostic flush | **New** — same pattern as iOS |
| Permission/entitlement template stubs | Host-owned generated artifacts | **New** — `.eex` templates emitted by `gen.shell`; not runtime code |
| `mix crosswake.gen.shell` | Shell scaffold generator | **Modified** — emit permission template stubs and runtime-line policy README section |
| `script/verify_generated_android_shell.sh` | Android JVM proof | **Modified** — add hermetic verification for runtime-line policy reader + diagnostic export seam |
| CI workflow `phase_v4_*.yml` | Merge-blocking hermetic + advisory lanes | **New** — follows phase18/phase23 two-job hermetic+advisory pattern |

---

## Architectural Patterns

### Pattern 1: Rebuild Policy Derived from Existing Version Axes (not a new field)

**What:** The OTA-safe-vs-rebuild decision is not a new manifest field. It is derived at evaluation time from the three existing version axes (`manifest_schema_version`, `bridge_protocol_version`, `native_runtime_version`) plus the `change_classes` table in `SupportMatrix`. When the required `native_runtime_version` in the manifest is newer than what the installed shell reports, a rebuild is required. The `SupportMatrix.change_classes/1` table already encodes "native or companion rebuild required" as a change class with an explicit `required_proof`. v4.0 formalizes this into a typed `RebuildPolicy` struct attached to `Compatibility` rather than adding a new top-level manifest field.

**Where it lives:** `Crosswake.Compatibility.RebuildPolicy` — new struct, derived in `Compatibility.validate_native_runtime/4`. The decision is then projected into `Doctor.Report.runtime_line` and `OperatorInspection` rebuild entries.

**Why not a new manifest field:** The manifest already carries `compatibility.native_runtime_version`. Adding a separate `rebuild_policy` top-level key would create two sources of truth for the same decision. The policy is a function of version data the manifest already has.

**Confidence:** HIGH — `validate_native_runtime/4` already emits a finding when `native_runtime_version` is incompatible. The new work is: (a) classifying the finding as `:rebuild_required` vs. `:ota_safe` with a typed result, and (b) surfacing that classification through doctor and operator inspection.

### Pattern 2: Permission/Entitlement Templates as Host-Owned Generated Artifacts

**What:** iOS entitlement (`.entitlements`) and Android permission (`AndroidManifest.xml` permission stubs) are generated by `mix crosswake.gen.shell` as commented scaffold files, not as runtime code Crosswake touches. They live alongside other generated shell artifacts in the host project. They are parity-locked to declared capabilities via a doctor check: if the manifest's `capability_registry` declares a capability with `rebuild: :native_required`, doctor verifies that the corresponding permission template stub is present in the generated shell root.

**Where it lives:** New `.eex` templates in `priv/templates/crosswake/shell/ios/` and `priv/templates/crosswake/shell/android/`. New doctor check `phase_v4_permission_template_findings/2` reads the manifest capability registry and verifies template presence. The check is analogous to the existing `@platform_definitions` artifact checks in `Doctor`.

**Why host-owned:** The capability taxonomy already classifies capabilities by `rebuild: :native_required` vs. `:none`. Permissions are the native side of that rebuild requirement. They are host-owned because only the host knows which app bundle identifier, provisioning profile, and entitlement server URL to use. Crosswake generates the scaffold; the host fills in the specifics.

**Parity lock mechanism:** `SupportMatrix` gains a `permission_template_truth/0` accessor that maps capability family → expected permission stub filename. Doctor verifies this mapping at `check_native_tools?: true` time, the same gating used for existing proof hooks.

### Pattern 3: Diagnostic Export Seam (Not a Bridge Command)

**What:** The shell emits typed diagnostic envelopes to a host-owned HTTP endpoint (`/api/crosswake/diagnostic_export`) rather than through the bounded bridge. The bridge thesis (low-frequency, typed, versioned, request/reply) is preserved because diagnostic export is fire-and-forget from the shell and does not require a LiveView reply. It is a separate native seam analogous to how Chimeway token registration uses a host-side HTTP endpoint rather than the bridge.

**Shape of the diagnostic envelope:**
```
{
  "schema_version": "1.0.0",
  "shell_platform": "ios" | "android",
  "native_runtime_version": "...",
  "crosswake_version": "...",
  "event_class": "crash_tombstone" | "activation_failure" | "bridge_denial" | "compat_mismatch",
  "route_id": "..." | null,
  "denial_code": "..." | null,
  "occurred_at": "ISO8601",
  "correlation_id": "...",
  "sanitized_context": {}
}
```

**What it must not carry:** Raw stack traces with PII, raw WebView URLs with query params, raw capability payloads, or any data that would make the endpoint a surveillance surface. The `sanitized_context` field is explicit about this: only enum-valued fields and pre-approved string labels are allowed, following the same redaction posture as Chimeway and Sigra telemetry.

**Why not a bridge command:** A new `diagnostics.export` bridge command would widen the bounded bridge vocabulary and require a LiveView response path. That violates the bounded-bridge thesis. The HTTP seam pattern already exists (token registration in Chimeway).

**Integration point:** New `DiagnosticExport.swift` / `DiagnosticExport.kt` in both shells. New `Crosswake.Shell.DiagnosticExport` Elixir module defining the typed envelope struct and `sanitize/1` helper. A new `mix crosswake.gen.shell` output section documents the endpoint contract. Doctor check `phase_v4_diagnostic_export_findings/2` verifies the shell template is present and the envelope schema version is consistent with the manifest schema version.

### Pattern 4: Compatibility Matrix Projection through SupportMatrix + Doctor

**What:** The existing `SupportMatrix.canonical/0` already holds `shells`, `release_boundaries`, and `change_classes`. v4.0 adds `runtime_line` entries that explicitly encode the current compatibility window: minimum supported `native_runtime_version`, current line, and the end-of-life posture for older lines. These entries are projected into:
1. `Doctor.Report.runtime_line` — new field, populated by `phase_v4_runtime_line_findings/2`
2. `OperatorInspection.Types.RuntimeLineEntry` — new type attached to route inspection
3. `SupportMatrix.runtime_line_truth/0` — new public accessor following the pattern of `auth_contract_truth/0` and `notification_support_truth/0`

**Derivation rule:** The runtime_line entry is derived from `manifest.compatibility.native_runtime_version` (the current line) and `SupportMatrix.release_boundaries/1` (the policy for shell artifacts). No new manifest field is introduced. The window (minimum supported version → current) is encoded in `SupportMatrix` module-level constants, not in the manifest JSON, so it stays a library-owned claim rather than a per-host manifest claim.

**Why this way:** Per the existing pattern in `SupportMatrix.validate_phase51_support_truth/1`, support truth validation lives in the SupportMatrix module as compile-time data. Runtime-line windows follow the same model.

### Pattern 5: Android Verification Closure (Hermetic + Advisory Split)

**What:** The existing Android support truth shows `status: :verification_required` in `SupportMatrix.canonical/0` with an explicit `notes` field citing the "Java-enabled BridgeChannel proof lane." v4.0 must close this by producing a hermetic CI-passable proof for the runtime-line policy reader and diagnostic export seam, and an advisory lane for emulator/device tests.

**Hermetic lane:** Adds Android JVM unit tests for `RuntimeLinePolicyReader` and `DiagnosticExport` (following the Phase 18 pattern where Android BridgeChannel tests ran in CI with `setup-java`). These tests run in the existing phase18-proof job structure — either as a new `phase_v4_android_hermetic.yml` or appended to the Android test step.

**Advisory lane:** Emulator/device connected tests remain advisory with `continue-on-error: true`, following the `phase23-proof.yml` two-job hermetic+advisory split. A new `device_uat_checklist.md` in the shell README documents the manual verification steps for real-device promotion.

**Promotion criteria:** `SupportMatrix.promotion_rules/0` gains a new `promotion_rule_entry` for `shell.android.runtime_line_policy` with explicit `required_evidence`, `minimum_consecutive_passes: 2`, and a `demotion_trigger`. This follows the existing `shell.android.generated_project` promotion rule shape.

---

## Data Flow

### Rebuild Policy Decision Flow

```
Host Route Policy DSL
    ↓
Manifest.compile → Types.Root.compatibility.native_runtime_version = "1.0.0"
    ↓
Shell boot: reads bundled crosswake_manifest.json
    ↓
ActivationCoordinator → RuntimeLinePolicyReader.evaluate(manifest, shell_version)
    ↓
  shell_version >= manifest.native_runtime_version?
    YES → :ota_safe, activate normally
    NO  → :rebuild_required, activate but surface upgrade advisory OR deny per rebuild_policy
    ↓
Doctor.run → phase_v4_runtime_line_findings → Finding{code: "runtime_line.rebuild_required"}
    ↓
OperatorInspection.from_manifest → route.rebuild_entry includes runtime_line classification
```

### Permission Template Parity Flow

```
mix crosswake.gen.shell ios
    ↓
gen.shell reads manifest capability_registry
    ↓
For each capability with rebuild: :native_required → emit permission template stub
    ↓
Host owns and fills in: app bundle ID, entitlement server, provisioning profile
    ↓
Doctor.run (check_native_tools?: true)
    ↓
phase_v4_permission_template_findings reads manifest capability_registry
    ↓
For each rebuild-required capability → check permission_template stub present in shell root
    ↓
SupportMatrix.permission_template_truth() → parity lock between manifest caps + template list
```

### Diagnostic Export Flow

```
Shell native code: crash, activation failure, bridge denial
    ↓
DiagnosticExport.swift / .kt: build typed envelope, sanitize, omit PII
    ↓
POST /api/crosswake/diagnostic_export  (fire-and-forget, no bridge involvement)
    ↓
Host Phoenix app handles endpoint (host-owned, not generated by Crosswake)
    ↓
Doctor.run → phase_v4_diagnostic_export_findings
    → verifies DiagnosticExport template present in shell root
    → verifies envelope schema version matches manifest schema version
```

### Compatibility Matrix Projection Flow

```
SupportMatrix.canonical(opts)
    ↓
SupportMatrix.runtime_line_truth/0  ← new module-level constant
    ↓
manifest.compatibility.native_runtime_version = current line
    ↓
Doctor.Report.runtime_line = %{current_line: "1.0.0", min_supported: "1.0.0", policy: :ota_safe | :rebuild_required}
    ↓
OperatorInspection.from_manifest → route.runtime_line entry
```

---

## Integration Points Against Existing Surfaces

### Manifest (`Manifest.Types`)

No new top-level manifest JSON fields. The three compatibility version axes already exist. The only manifest-level change is that `Compatibility.RebuildPolicy` is a new derived struct (not persisted in JSON) computed from existing `native_runtime_version` data.

**Specifically not modified:** `Types.Root`, `Types.Compatibility` struct fields, manifest JSON schema version. This is critical — adding a new manifest field would be a `manifest_schema_version` bump, which is a breaking change for all deployed shells. v4.0 should not force that.

### Doctor (`Crosswake.Doctor`)

The existing doctor pipeline uses a named-phase pattern (`phase_3_posture`, `phase_4_posture`, etc.). v4.0 adds three new named phase functions following this exact pattern:

- `phase_v4_runtime_line_findings(manifest, opts)` — emits `runtime_line.rebuild_required`, `runtime_line.window_expired`, `runtime_line.current`
- `phase_v4_permission_template_findings(manifest, opts, cwd)` — emits `permission_template.missing`, `permission_template.present` per capability family with `rebuild: :native_required`
- `phase_v4_diagnostic_export_findings(manifest, opts, cwd)` — emits `diagnostic_export.template_missing`, `diagnostic_export.schema_mismatch`

`Doctor.Report` gains a `runtime_line` field alongside existing `shells`, `bridge`, `offline`, `support` fields.

### SupportMatrix (`Crosswake.SupportMatrix`)

New public accessor functions following existing patterns:

- `runtime_line_truth/0` — returns `@runtime_line_truth` module attribute (list of maps, same shape as `@notification_support_truth`)
- `permission_template_truth/0` — maps capability family → expected permission stub filenames per platform
- `diagnostic_export_truth/0` — schema version and redaction posture for the diagnostic export seam

New `promotion_rule_entry/1` added to `promotion_rules/0` for `shell.android.runtime_line_policy`.

The existing `android` `SupportEntry` with `status: :verification_required` is updated to `status: :supported` only after the hermetic Android proof passes. This is a SupportMatrix change gated on proof, not a pre-emptive claim.

### OperatorInspection (`Crosswake.OperatorInspection`)

The existing `rebuild_entry/2` function already aggregates capability rebuild signals per route. v4.0 adds:

- `runtime_line_entry/2` — projects runtime_line classification onto the route entry (whether the current shell version is OTA-safe or requires rebuild for this route's required version)
- `permission_template_entry/2` — lists expected permission stubs for the route's declared capabilities with `rebuild: :native_required`

These attach to `Types.route/1` alongside existing `rebuild`, `support`, `denials` entries.

### Bounded Bridge (`Crosswake.Bridge.Contract`)

**Not modified.** Diagnostic export is an HTTP seam, not a bridge command. No new bridge command vocabulary is introduced. This is the most critical architectural constraint of v4.0.

### Checked-in Shells (`examples/ios_shell_host`, `examples/android_shell_host`)

iOS additions:
- `CrosswakeShell/RuntimeLinePolicyReader.swift` — reads `manifest.compatibility.native_runtime_version`, compares to shell's declared version, returns `:ota_safe` or `:rebuild_required`
- `CrosswakeShell/DiagnosticExport.swift` — typed envelope, sanitize, POST to `/api/crosswake/diagnostic_export`
- `CrosswakeShell/Info.plist` — permission template annotations added as comments (not new entitlements)

Android additions:
- `dev.crosswake.shell/RuntimeLinePolicyReader.kt` — same logic as iOS counterpart
- `dev.crosswake.shell/DiagnosticExport.kt` — same pattern as iOS counterpart
- `app/src/main/AndroidManifest.xml` — permission template annotations as comments

### Shell Generator (`mix crosswake.gen.shell`)

New `.eex` templates:
- `ios/RuntimeLinePolicyReader.swift.eex`
- `ios/DiagnosticExport.swift.eex`
- `android/.../RuntimeLinePolicyReader.kt.eex`
- `android/.../DiagnosticExport.kt.eex`
- `ios/CrosswakeShell.entitlements.eex` — permission/entitlement template stub
- `android/permission_template_stub.xml.eex` — permission template annotations

New README section generated by `shell_readme/1` in `gen.shell` covering:
- Runtime-line policy: current version, OTA-safe-vs-rebuild rules
- Permission/entitlement template ownership instructions
- Diagnostic export endpoint contract

Doctor `@platform_definitions` map gains new entries for `permission_templates` and `diagnostic_export` artifact checks on both platforms, following the existing `generated`, `manifest_first`, `bridge` check structure.

### Closeout Verifier (`mix closeout.verify`)

No changes needed. `closeout.verify` checks planning artifact presence and SUMMARY frontmatter, not specific module content. The new phase proof workflows will be discovered automatically by the existing CI proof lane detection.

---

## New vs. Modified Components — Explicit List

### New Elixir modules / types

| Module | Category |
|--------|----------|
| `Crosswake.Compatibility.RebuildPolicy` | New struct — derived rebuild decision |
| `Crosswake.Shell.DiagnosticExport` | New — typed envelope, sanitize/1, schema constants |
| `Crosswake.OperatorInspection.Types.RuntimeLineEntry` | New type |
| `Crosswake.OperatorInspection.Types.PermissionTemplateEntry` | New type |

### Modified Elixir modules

| Module | Change |
|--------|--------|
| `Crosswake.Compatibility` | `validate_native_runtime` emits `RebuildPolicy`; new `rebuild_decision/2` function |
| `Crosswake.Doctor` | Add three new phase functions; extend `Report` struct |
| `Crosswake.SupportMatrix` | Add `runtime_line_truth/0`, `permission_template_truth/0`, `diagnostic_export_truth/0`; add Android runtime-line promotion rule; update Android `SupportEntry` status after proof |
| `Crosswake.OperatorInspection` | Add `runtime_line_entry/2`, `permission_template_entry/2` |
| `Crosswake.Shell.Fixtures` | Add `diagnostics_export_fixture` and `permission_template_fixture` exports |
| `Mix.Tasks.Crosswake.Gen.Shell` | Add new `.eex` template references; extend README generation |

### New native shell files (both `examples/` and generator templates)

| File | Platform |
|------|----------|
| `RuntimeLinePolicyReader.swift` / `.kt` | iOS + Android |
| `DiagnosticExport.swift` / `.kt` | iOS + Android |
| `CrosswakeShell.entitlements.eex` | iOS only |
| `permission_template_stub.xml.eex` | Android only |

### Modified native shell files

| File | Change |
|------|--------|
| `ActivationCoordinator.swift` / `.kt` | Consume `RuntimeLinePolicyReader` output |
| `Info.plist` / `AndroidManifest.xml` | Commented permission template annotations |

### New CI workflows

| File | Purpose |
|------|---------|
| `.github/workflows/phase_v4_runtime_line_proof.yml` | Hermetic merge-blocking: runtime-line policy, permission template doctor, diagnostic export seam |
| Advisory Android emulator lane | `continue-on-error: true` job in same workflow |

### New guide sections

| File | Change |
|------|--------|
| `guides/native_shell.md` | New sections: Runtime-Line Policy, Permission Templates, Diagnostic Export Seam |
| `guides/compatibility.md` | New section: Runtime-Line Windows and OTA-Safe vs. Rebuild |
| New `guides/device_uat.md` | Android device UAT checklist |

---

## Suggested Build Order (dependency-aware)

The order respects the contracts-first posture: define the Elixir contract and support truth before touching native code or CI workflows.

### Step 1: Elixir contracts and support truth (no shell changes)

1. `Crosswake.Compatibility.RebuildPolicy` struct + `rebuild_decision/2` function
2. Extend `Compatibility.validate_native_runtime` to return a typed rebuild signal
3. `SupportMatrix.runtime_line_truth/0` module attribute + accessor
4. `SupportMatrix.permission_template_truth/0` module attribute + accessor
5. `SupportMatrix.diagnostic_export_truth/0` module attribute + accessor
6. New Android runtime-line `promotion_rule_entry` in `SupportMatrix.promotion_rules/0`
7. `Doctor.Report` struct extension + three new phase functions (stubs that return `[]` initially)
8. `OperatorInspection.Types.RuntimeLineEntry` and `PermissionTemplateEntry` types
9. `OperatorInspection.runtime_line_entry/2` and `permission_template_entry/2` functions
10. Hermetic ExUnit proof for all of the above

**Dependency:** Steps 1-2 must precede step 3 (support truth derives from compatibility behavior). Steps 3-5 must precede step 7 (doctor functions read support truth).

### Step 2: Diagnostic export seam (Elixir side)

11. `Crosswake.Shell.DiagnosticExport` module — typed envelope struct, `sanitize/1`, schema version constant
12. `Shell.Fixtures` additions for diagnostic export fixture
13. Extend doctor `phase_v4_diagnostic_export_findings/2` to check template presence
14. ExUnit proof for diagnostic export envelope sanitization and schema constants

**Dependency:** Steps 11-13 require step 1 (envelope carries `native_runtime_version` from `RebuildPolicy`).

### Step 3: Generator templates and permission template stubs

15. New `.eex` templates for `RuntimeLinePolicyReader`, `DiagnosticExport` (both platforms)
16. New `.eex` permission/entitlement template stubs (iOS `.entitlements`, Android permission comments)
17. Extend `mix crosswake.gen.shell` to emit all new templates and README section
18. Extend doctor `@platform_definitions` with permission_template and diagnostic_export artifact checks
19. ExUnit proof for `gen.shell` output presence

**Dependency:** Steps 15-17 require steps 11-14 (templates instantiate the Elixir contract shapes). Step 18 requires step 17 (doctor checks against generated artifact filenames).

### Step 4: Native shell implementation (examples/)

20. `RuntimeLinePolicyReader.swift` in `examples/ios_shell_host`
21. `DiagnosticExport.swift` in `examples/ios_shell_host`
22. Modify `ActivationCoordinator.swift` to consume `RuntimeLinePolicyReader`
23. iOS permission/entitlement template annotations in `Info.plist`
24. iOS proof: extend `verify_generated_ios_shell.sh` to check new artifacts
25. `RuntimeLinePolicyReader.kt` in `examples/android_shell_host`
26. `DiagnosticExport.kt` in `examples/android_shell_host`
27. Modify `ActivationCoordinator.kt` to consume `RuntimeLinePolicyReader`
28. Android permission template annotations in `AndroidManifest.xml`
29. Android JVM unit tests for `RuntimeLinePolicyReader` and `DiagnosticExport`
30. Extend `verify_generated_android_shell.sh` to check new artifacts

**Dependency:** Steps 20-24 require step 17 (iOS templates must exist before example implementation mirrors them). Steps 25-30 require steps 20-24 (Android mirrors iOS; iOS proves the pattern first). Step 30 (Android script) requires step 29 (tests must exist before script checks them).

### Step 5: CI proof workflows and Android verification closure

31. New `phase_v4_runtime_line_proof.yml` — hermetic merge-blocking job (Elixir + iOS shell check + Android JVM)
32. Advisory Android emulator/device job in same workflow (`continue-on-error: true`)
33. `guides/device_uat.md` — Android device UAT checklist (manual verification steps, explicit promotion criteria)
34. Update `SupportMatrix` Android `SupportEntry` from `:verification_required` to `:supported` only after step 31 passes in CI

**Dependency:** Step 31 requires steps 24 + 30 (both shell proof scripts updated). Step 34 is the last step — it is the promotion gate, not a pre-emptive claim.

### Step 6: Guide updates and docs-contract proof

35. Extend `guides/native_shell.md` — runtime-line policy section, permission templates section, diagnostic export section
36. Extend `guides/compatibility.md` — runtime-line windows and OTA-safe-vs-rebuild section
37. Add `guides/device_uat.md`
38. Extend docs-contract parity tests to cover new guide anchors in `SupportMatrix.permission_template_truth/0` and `SupportMatrix.runtime_line_truth/0`

**Dependency:** Step 38 requires steps 35-37 (parity tests check that guide sections exist and match support truth).

---

## Anti-Patterns

### Anti-Pattern 1: New `rebuild_policy:` field in manifest JSON

**What people do:** Add a `rebuild_policy` top-level key to `Types.Root` and serialize it into the manifest JSON so native shells can read it directly.

**Why it's wrong:** The manifest already carries `native_runtime_version`. A new field duplicates truth and forces a `manifest_schema_version` bump, which breaks every deployed shell. The rebuild decision is a function of version data, not new data.

**Do this instead:** Derive `RebuildPolicy` in `Compatibility.validate_native_runtime/4` from existing version axes. Surface the decision through doctor and operator inspection only.

### Anti-Pattern 2: `diagnostics.export` bridge command

**What people do:** Add a new `diagnostics.export` command to `Bridge.Contract` so the shell can report crash context through the existing WebSocket/JS bridge.

**Why it's wrong:** Diagnostic export is fire-and-forget with no reply needed. Adding it to the bridge widens the bounded bridge vocabulary and introduces a new high-frequency path (crash context can be large). The bridge thesis is "low-frequency, typed, versioned, request/reply."

**Do this instead:** Use the HTTP POST pattern from Chimeway's token registration seam. The shell emits a typed, sanitized envelope to a host-owned endpoint with no bridge involvement.

### Anti-Pattern 3: Crosswake-generated permission/entitlement values

**What people do:** Generate actual entitlement keys (Push Notifications, Associated Domains, etc.) with real values in the `.entitlements` file, or generate `<uses-permission android:name="..."/>` elements in `AndroidManifest.xml`.

**Why it's wrong:** Permission values depend on the host app bundle ID, provisioning profile, and app-store entitlements — all host-owned, not Crosswake-owned. Generating wrong values silently causes app review rejections.

**Do this instead:** Generate commented stubs that list required permissions by capability, with explicit instructions for the host to fill in correct values. Doctor checks for stub presence, not for specific permission values.

### Anti-Pattern 4: Updating Android `SupportEntry` to `:supported` before hermetic proof

**What people do:** Update `SupportMatrix.canonical/0` Android entry from `:verification_required` to `:supported` as part of writing the implementation, before CI passes.

**Why it's wrong:** Support truth is evidence-backed. The Android entry is currently `:verification_required` precisely because hermetic JVM proof is incomplete. Updating the claim before the proof fires makes the support matrix dishonest.

**Do this instead:** Keep Android at `:verification_required` through steps 1-30. Update to `:supported` only after the hermetic CI proof job in step 31 passes and the promotion criteria in the new promotion_rule_entry are satisfied.

### Anti-Pattern 5: Standalone shell packages before release choreography

**What people do:** Split `RuntimeLinePolicyReader`, `DiagnosticExport`, and the permission templates into a separately published Swift package or Android library, reasoning that "production hardening" implies package promotion.

**Why it's wrong:** The existing `SupportMatrix` explicitly marks "Standalone public shell packages" as `package_class: :defer` with the note "No first-class package commitment yet; any future promotion must land with runtime-line rules and rebuild guidance." The release choreography (versioned compatibility ranges, supported platform windows, companion compatibility declarations) is not yet defined.

**Do this instead:** Keep all v4.0 shell code as `example/docs-only` artifacts in `examples/`. The `gen.shell` task copies these patterns into host-owned projects. No standalone package promotion in v4.0.

---

## Scaling Considerations

These are not scalability concerns in the user-count sense — Crosswake is a library, not a service. The relevant scale axis is the number of adopters using the shell templates and the number of capability families that may require permission templates.

| Concern | Current scale | v4.0 posture |
|---------|---------------|--------------|
| Capability families requiring rebuild | 3-4 families today | Permission template truth stays in SupportMatrix module attributes, O(families). No new query path. |
| Doctor check performance | Linear over routes | New phase_v4 checks are O(routes * capabilities). Equivalent to existing phase_19 commerce check. |
| Android proof lane speed | JVM tests: ~5min | New RuntimeLinePolicyReader + DiagnosticExport unit tests add ~1-2min. Acceptable. |
| Device UAT frequency | Currently ad-hoc | Checklist codifies it; advisory CI lane runs on PR but does not block. |

---

## Sources

- `lib/crosswake/manifest/types.ex` — `Compatibility`, `SupportMatrix`, `CapabilitySupportEntry`, `ReleaseBoundaryEntry`, `ChangeClassEntry` structs
- `lib/crosswake/support_matrix/support_matrix.ex` — `canonical/0`, `promotion_rules/0`, `action_classes/0`, existing `@notification_support_truth` and `@auth_contract_truth` patterns
- `lib/crosswake/doctor/doctor.ex` — named-phase pattern, `@platform_definitions`, `Doctor.Report` struct
- `lib/crosswake/compatibility/compatibility.ex` — `validate_native_runtime/4`, `route_findings/4`
- `lib/crosswake/compatibility/route_gate.ex` — gate evaluation pipeline
- `lib/crosswake/operator_inspection.ex` — `rebuild_entry/2` existing aggregation pattern
- `lib/crosswake/shell/fixtures.ex` — fixture export shape
- `lib/mix/tasks/crosswake.gen.shell.ex` — template list and generation pattern
- `examples/ios_shell_host/CrosswakeShell/*.swift` — existing iOS shell surface
- `examples/android_shell_host/app/src/main/java/dev/crosswake/shell/*.kt` — existing Android shell surface
- `.github/workflows/phase18-proof.yml` — hermetic+advisory CI split reference
- `.planning/MILESTONE-ARC.md` — dependency graph, v4.0 non-goals, support truth requirements
- `.planning/PROJECT.md` — key decisions, locked guardrails

---

*Architecture research for: v4.0 Production Shell Runtime Line*
*Researched: 2026-06-03*
