---
phase: 121-canonical-contract-source
verified: 2026-06-20T17:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "SC-2: Both committed crosswake_manifest.json files now carry bridge_protocol_version 1.1.0 (commit ef6009f). The only remaining 1.0.0 occurrence in lib/ test/ packages/ examples/ is test/fixtures/proof/phase52_operator_inspection.json:1828, which is the known-deferred stale proof snapshot documented in deferred-items.md and explicitly excluded from SC-2 acceptance. All build/ hits are gitignored untracked files (confirmed via .gitignore:37 and git ls-files). Tracked-file SC-2 invariant passes."
    - "WR-01: The false Map.new unconditional ordering claim is removed from crosswake.contract.gen.ex. Accurate <32-key BEAM small-map dependency documented at lines 176-184 (commit 4a13de4)."
    - "CANON-05 tracking: REQUIREMENTS.md CANON-05 checkbox is [x] and traceability row reads Complete (commit f8f3b92)."
  gaps_remaining: []
  regressions: []
---

# Phase 121: Canonical Contract Source — Verification Report

**Phase Goal:** Every version surface in the system derives from one Elixir constant; the 1.1.0 / 1.0.0 divergence is resolved; all generated JSON fixtures, shell templates, and native conformance vectors are emitted by `mix crosswake.contract.gen`; the Kotlin silent fallback is gone.
**Verified:** 2026-06-20T17:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (121-04, commits ef6009f, 4a13de4, f8f3b92, fc9ea70)

---

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | `Crosswake.Bridge.Contract.version()` is the sole declared constant; `Manifest.Types` and shell fixtures derive from it at compile time with no independent literals | VERIFIED | `types.ex:652` — `@bridge_protocol_version Crosswake.Bridge.Contract.version()`. `fixtures.ex:82` — `bridge_protocol_version: Crosswake.Bridge.Contract.version()`. No alias added. `@manifest_schema_version "1.0.0"` and `@native_runtime_version "1.0.0"` are distinct axes and remain correct. `contract.ex:10` holds `@version "1.1.0"` as sole declared constant. |
| SC-2 | Each version axis has exactly one named authoritative source; `grep -rn '"bridge_protocol_version"' lib/ test/ packages/ examples/` returns a single value everywhere | VERIFIED | After gap closure, the only tracked file carrying `"1.0.0"` in these directories is `test/fixtures/proof/phase52_operator_inspection.json:1828` — the known-deferred stale proof snapshot documented in deferred-items.md (unrelated phase52 reasons; excluded from SC-2 acceptance per PLAN 04 and deferred-items.md). `build/` directory hits are gitignored untracked artifacts (.gitignore:37; confirmed via `git ls-files --error-unmatch`). All tracked source files in lib/ packages/ examples/ and all non-proof test fixtures carry `"1.1.0"`. SC-2 invariant holds on tracked source files. |
| SC-3 | Running `mix crosswake.contract.gen` regenerates all derived surfaces (JSON fixtures, generated shell templates, native conformance vectors, docs snippet) from the canonical constant in a hermetic, network-free step | VERIFIED (scoped surfaces only) | Four declared surfaces emitted idempotently: `examples/*/route_activation.json` (bridge 1.1.0), `test/fixtures/bridge_contract_vectors.json` (bridge 1.1.0), `docs/_contract_snippet.md` (bridge 1.1.0). All carry `_generated_by` / DO-NOT-EDIT markers. Gen task reads `Contract.version()` at lines 8 and 42 with no hardcoded bridge literal. `crosswake_manifest.json` files remain hand-maintained tracked fixtures (not folded into contract.gen scope per D-04 / Phase 122 handoff decision). |
| SC-4 | The 1.1.0 vs 1.0.0 protocol-version conflict is resolved to one correct current value without altering behavior visible to existing 0.1.x adopters | VERIFIED | Elixir layer: `Manifest.Types.new_compatibility().bridge_protocol_version` returns `"1.1.0"` (derived from `Contract.version()`). Both committed example manifests now carry `bridge_protocol_version: "1.1.0"`, matching their sibling `route_activation.json` files — within-bundle consistency restored. Doctor reports `bridge_protocol_version = 1.1.0`. Full test suite: 0 new failures. Compatibility test deliberate-deny cases retain `"1.0.0"` correctly. |
| SC-5 | `ActivationCoordinator.kt` line 594 no longer contains a `?: "1.0.0"` fallback; native always reads the manifest-provided value and fails closed if absent | VERIFIED | `grep -c '?: "1.0.0"' ActivationCoordinator.kt` = 0. Line 595 reads: `?: error("crosswake_manifest.json is missing native_runtime_version in the compatibility block")`. Non-nullable `String` type preserved. Commit `a05bb62` (Plan 03). |

**Score:** 5/5 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/manifest/types.ex` | `@bridge_protocol_version` derives from `Contract.version()` | VERIFIED | Line 652: `@bridge_protocol_version Crosswake.Bridge.Contract.version()`. |
| `lib/crosswake/shell/fixtures.ex` | `activation_request/1` bridge_protocol_version derived from canonical constant | VERIFIED | Line 82: `bridge_protocol_version: Crosswake.Bridge.Contract.version()`. |
| `lib/mix/tasks/crosswake.contract.gen.ex` | Mix task `mix crosswake.contract.gen`; min 40 lines; exports `run/1`; accurate key-ordering comment | VERIFIED | 241 lines. `def run(_args)` at line 39. `use Mix.Task`. Lines 176-184: `<32-key BEAM small-map dependency` documented accurately. False "OTP 26+ unconditional ordering" claim removed. Commit 4a13de4. |
| `examples/ios_shell_host/Fixtures/route_activation.json` | bridge_protocol_version = 1.1.0; _generated_by marker | VERIFIED | Line 3: `"bridge_protocol_version": "1.1.0"`. `_generated_by` marker present. |
| `examples/android_shell_host/app/src/main/assets/route_activation.json` | bridge_protocol_version = 1.1.0; _generated_by marker | VERIFIED | Line 3: `"bridge_protocol_version": "1.1.0"`. `_generated_by` marker present. |
| `test/fixtures/bridge_contract_vectors.json` | Canonical bridge contract conformance vectors; contains bridge_protocol_version 1.1.0 | VERIFIED | `"bridge_protocol_version": "1.1.0"`. 3 seed vectors. `_generated_by` marker. |
| `docs/_contract_snippet.md` | Generated docs snippet; contains 1.1.0 | VERIFIED | Line 8: `bridge_protocol_version` → `1.1.0`. DO-NOT-EDIT HTML comment header. |
| `packages/crosswake-shell-core-android/.../ActivationCoordinator.kt` | No `?: "1.0.0"` fallback; fail-closed `error()` | VERIFIED | Line 595: `compatibilityJson?.getString("native_runtime_version") ?: error(...)`. Non-nullable `String` type preserved. |
| `examples/ios_shell_host/Fixtures/crosswake_manifest.json` | bridge_protocol_version aligned to 1.1.0; non-bridge axes stay 1.0.0 | VERIFIED | Line 350: `"bridge_protocol_version": "1.1.0"` (was "1.0.0"). Lines 351-352: `manifest_schema_version` and `native_runtime_version` remain `"1.0.0"`. Commit ef6009f. |
| `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` | bridge_protocol_version aligned to 1.1.0; non-bridge axes stay 1.0.0 | VERIFIED | Line 350: `"bridge_protocol_version": "1.1.0"` (was "1.0.0"). Byte-identical to iOS manifest (diff empty). Commit ef6009f. |
| `.planning/REQUIREMENTS.md` | CANON-05 [x] checked; traceability row Complete | VERIFIED | Line 20: `- [x] **CANON-05**`. Line 82: `| CANON-05 | Phase 121 | Complete |`. Commit f8f3b92. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/crosswake/manifest/types.ex` | `lib/crosswake/bridge/contract.ex` | Compile-time `@bridge_protocol_version Crosswake.Bridge.Contract.version()` (no alias — cycle-safe) | WIRED | `grep -n '@bridge_protocol_version' types.ex` → line 652. `grep -c 'alias Crosswake.Bridge.Contract' types.ex` → 0. |
| `lib/crosswake/shell/fixtures.ex` | `lib/crosswake/bridge/contract.ex` | `bridge_protocol_version: Crosswake.Bridge.Contract.version()` in `activation_request/1` | WIRED | `grep -n 'bridge_protocol_version' fixtures.ex` → line 82. |
| `lib/mix/tasks/crosswake.contract.gen.ex` | `lib/crosswake/bridge/contract.ex` | `Mix.Task.run("app.start")` then `bridge_vsn = Crosswake.Bridge.Contract.version()` | WIRED | Lines 8 and 42 reference `Contract.version()`. |
| `examples/ios_shell_host/Fixtures/crosswake_manifest.json` | `examples/ios_shell_host/Fixtures/route_activation.json` | Both declare `bridge_protocol_version: "1.1.0"` — within-bundle manifest/activation agreement | WIRED | Both confirmed at 1.1.0 via direct grep. Within-bundle drift eliminated. |
| `examples/android_shell_host/.../crosswake_manifest.json` | `examples/android_shell_host/.../route_activation.json` | Both declare `bridge_protocol_version: "1.1.0"` — within-bundle manifest/activation agreement | WIRED | Both confirmed at 1.1.0 via direct grep. |
| `ActivationCoordinator.kt loadManifest` | `crosswake_manifest.json compatibility block` | `compatibilityJson?.getString("native_runtime_version") ?: error(...)` | WIRED (fail-closed) | Line 595: reads field; errors on absent. Non-nullable `String` preserved. |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `lib/mix/tasks/crosswake.contract.gen.ex` | `bridge_vsn` | `Crosswake.Bridge.Contract.version()` after `app.start` | Yes — live Elixir module call | FLOWING |
| `examples/*/route_activation.json` (generated) | `bridge_protocol_version` field | Gen task reads `Contract.version()`, writes via `write_if_changed` | Yes — `"1.1.0"` | FLOWING |
| `examples/ios_shell_host/Fixtures/crosswake_manifest.json` | `compatibility.bridge_protocol_version` | In-place targeted edit (1.0.0 → 1.1.0); hand-maintained tracked fixture | Yes — value is now `"1.1.0"` matching canonical | CORRECT (hand-maintained; drift-coverage deferred to Phase 122) |
| `examples/android_shell_host/.../crosswake_manifest.json` | `compatibility.bridge_protocol_version` | Same as iOS | Yes — `"1.1.0"` | CORRECT (hand-maintained; drift-coverage deferred to Phase 122) |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `types.ex` bridge attribute is `Contract.version()` | `grep -n '@bridge_protocol_version' types.ex` | Line 652: `@bridge_protocol_version Crosswake.Bridge.Contract.version()` | PASS |
| No forbidden alias in `types.ex` | `grep -c 'alias Crosswake.Bridge.Contract' types.ex` | 0 | PASS |
| Gen task reads `Contract.version()` | `grep -n 'Crosswake.Bridge.Contract.version()' crosswake.contract.gen.ex` | Lines 8, 42 | PASS |
| `?: "1.0.0"` fallback gone from Kotlin | `grep -c '?: "1.0.0"' ActivationCoordinator.kt` | 0 | PASS |
| Kotlin `error()` fail-closed present | `grep -n 'error(' ActivationCoordinator.kt` | Line 595: `error("crosswake_manifest.json is missing native_runtime_version...")` | PASS |
| iOS manifest bridge axis = 1.1.0 | `grep '"bridge_protocol_version"' examples/ios_shell_host/Fixtures/crosswake_manifest.json` | Line 350: `"1.1.0"` | PASS |
| Android manifest bridge axis = 1.1.0 | `grep '"bridge_protocol_version"' examples/android_shell_host/.../crosswake_manifest.json` | Line 350: `"1.1.0"` | PASS |
| iOS manifest native-runtime stays 1.0.0 | `grep '"native_runtime_version"' examples/ios_shell_host/Fixtures/crosswake_manifest.json` | Line 352: `"1.0.0"` | PASS |
| Android manifest schema stays 1.0.0 | `grep '"manifest_schema_version"' examples/android_shell_host/.../crosswake_manifest.json` | Line 351: `"1.0.0"` | PASS |
| Manifests byte-identical | `diff ios crosswake_manifest.json android crosswake_manifest.json` | Empty (identical) | PASS |
| SC-2 tracked files — only 1.0.0 source is deferred fixture | `git ls-files -z lib test packages examples \| xargs -0 grep -hn '"bridge_protocol_version": "1.0.0"'` | Only `test/fixtures/proof/phase52_operator_inspection.json:1828` (known-deferred) | PASS |
| build/ hits are gitignored (not tracked) | `git check-ignore -v examples/ios_shell_host/build/...` | `.gitignore:37:/**/build/` — untracked | PASS |
| WR-01 false claim removed | `grep -c 'iterates it in' crosswake.contract.gen.ex` | 0 | PASS |
| WR-01 accurate <32-key comment present | `grep -n '32\|BEAM\|fewer than' crosswake.contract.gen.ex` | Lines 176-184: `FEWER THAN 32 keys` documented | PASS |
| CANON-05 checked in REQUIREMENTS.md | `grep '\[x\] \*\*CANON-05\*\*' .planning/REQUIREMENTS.md` | Line 20: matches | PASS |
| CANON-05 traceability Complete | `grep 'CANON-05.*Complete' .planning/REQUIREMENTS.md` | Line 82: `| CANON-05 | Phase 121 | Complete |` | PASS |
| Gap-closure commits present in git | `git log --oneline ef6009f 4a13de4 f8f3b92 fc9ea70` | All 4 commits confirmed in history | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CANON-01 | Plan 01 | Single canonical Elixir source for bridge protocol version | SATISFIED | `types.ex:652` and `fixtures.ex:82` derive from `Contract.version()`. No independent literals in lib/. |
| CANON-02 | Plans 01, 02, 04 | One named source per version axis; no second hand-maintained copy | SATISFIED | Elixir source clean. Both `crosswake_manifest.json` examples now carry `bridge_protocol_version: "1.1.0"`, matching the canonical constant. No second drifted copy remains in tracked source. |
| CANON-03 | Plan 02 | `mix crosswake.contract.gen` renders canonical contract into all derived non-Elixir surfaces | SATISFIED (scoped set) | 4 declared surfaces: route_activation.json (×2), bridge_contract_vectors.json, docs/_contract_snippet.md. All idempotent, hermetic, DO-NOT-EDIT markers. `crosswake_manifest.json` remains hand-maintained per Phase 122 handoff decision. |
| CANON-04 | Plans 01, 04 | 1.1.0 vs 1.0.0 divergence resolved without breaking 0.1.x adopters | SATISFIED | Elixir system coherent at 1.1.0. Both example manifests now internally consistent (manifest bridge == activation bridge == 1.1.0). Full test suite: 0 new failures. Compatibility tests correct. |
| CANON-05 | Plan 03 | Silent `?: "1.0.0"` Kotlin fallback removed; native fails closed | SATISFIED | `?: "1.0.0"` gone (count=0). `error()` fail-closed at line 595. Non-nullable String preserved. REQUIREMENTS.md tracking synced. |

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/fixtures/proof/phase52_operator_inspection.json` | 1828 | `"bridge_protocol_version": "1.0.0"` in proof snapshot fixture | WARNING (known/deferred) | Known-stale proof fixture already in deferred-items.md; phase52 tests failing pre-Phase 121 for unrelated reasons. Explicitly excluded from SC-2 acceptance. Not a version declaration under Phase 121 scope. |

No `TBD`, `FIXME`, or `XXX` markers found in any of the four files modified by Plan 04 (crosswake_manifest.json ×2, crosswake.contract.gen.ex, REQUIREMENTS.md).

---

### Human Verification Required

None. All must-haves are verified by codebase inspection. No visual, real-time, or external-service checks are required for this phase's goal.

---

### Phase 122 Handoff Note (carried forward)

Drift-coverage of the committed `crosswake_manifest.json` files was intentionally NOT folded into `mix crosswake.contract.gen`. Phase 122's generate-and-diff CI guard must decide: (a) a parity assertion that the committed manifests' `compatibility.bridge_protocol_version` equals `Contract.version()`, or (b) giving `gen.shell` authority to re-emit the committed `examples/` manifests for diffing. Adding manifest emission to `contract.gen` would split ownership of a single file across two generators.

---

_Verified: 2026-06-20T17:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after gap-closure commits ef6009f, 4a13de4, f8f3b92, fc9ea70_
