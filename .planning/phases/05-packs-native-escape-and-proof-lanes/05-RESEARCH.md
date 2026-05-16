# Phase 5: Packs, Native Escape, And Proof Lanes - Research

**Researched:** 2026-05-17
**Domain:** Pack lifecycle contracts, first native-screen escape hatch, explicit media transfer seams, and deterministic example-host proof lanes
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PACK-01 | Crosswake supports versioned content pack or media pack declarations in route policy and manifest output. | Keep `packs` route-local in policy, but add a manifest-level typed pack registry so route entries reference immutable `pack_id@version` truth instead of loose strings alone. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| PACK-02 | Crosswake provides a pack lifecycle contract covering install, availability checks, and invalidation for declared packs. | Reuse the existing fail-closed compatibility posture and `pack_incompatible` denial vocabulary, then add typed install inventory, integrity, and invalidation metadata instead of widening route activation into a generic asset loader. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/shell/denial.ex] [VERIFIED: lib/crosswake/shell/activation.ex] |
| PACK-03 | Crosswake provides one documented native screen or adapter escape hatch for a device-heavy flow such as camera or media capture. | Choose one `:native_screen` capture flow as the first escape hatch; the repo already models capture/camera as `:native_screen`, and Android/iOS platform docs both point toward dedicated capture/picker APIs instead of generic WebView ownership. [VERIFIED: test/support/router_fixtures.ex] [VERIFIED: lib/crosswake/policy/schema.ex] [CITED: https://developer.apple.com/documentation/avfoundation/avcapturesession] [CITED: https://developer.apple.com/documentation/photosui/phpickerviewcontroller?language=objc] [CITED: https://developer.android.com/media/camera/camerax?authuser=01] [CITED: https://developer.android.com/jetpack/androidx/releases/camera?hl=en] |
| PACK-04 | Crosswake provides explicit media transfer seams for upload/download flows rather than treating them as generic WebView behavior. | Keep transfer separate from route activation and separate from generic WebView file controls; use explicit picker/capture/download contracts that return typed file handles or content URIs. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/bridge/registry.ex] [CITED: https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc] [CITED: https://developer.android.com/reference/android/webkit/WebChromeClient] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en] [CITED: https://developer.android.com/reference/androidx/core/content/FileProvider] [CITED: https://developer.apple.com/documentation/foundation/urlsession?changes=_4_2%2C_4_2] |
| DX-03 | Crosswake ships example-host proof lanes and deterministic CI that verify the public install path across Phoenix, iOS, and Android surfaces. | Keep support claims tied to real generated or example host artifacts, not just repo-local unit tests. The repo already uses explicit proof hooks and `verification required` support posture, and current local environment checks show iOS proof is runnable but still failing at simulator launch while Android host tooling is still absent locally. [VERIFIED: guides/support_matrix.md] [VERIFIED: guides/native_shell.md] [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh] [VERIFIED: local command check on 2026-05-17: `xcodebuild -version`, `xcrun simctl list devices`, `bash script/verify_generated_ios_shell.sh`, `java -version`, `command -v adb`, `command -v sdkmanager`, `command -v gradle`] [CITED: https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results?changes=_9] [CITED: https://developer.android.com/studio/test/gradle-managed-devices] |
</phase_requirements>

## Summary

Phase 5 should be planned as a contract-tightening phase, not as a capability-breadth phase. The repo already has the right primitives: route-local `packs`, fail-closed pack compatibility checks, a shared denial vocabulary, a bounded `files.pick` command, explicit `:native_screen` runtime support, and proof language that blocks support claims until native hooks pass. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/shell/denial.ex] [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/bridge/registry.ex] [VERIFIED: test/support/router_fixtures.ex] [VERIFIED: guides/support_matrix.md]

The strict first native escape-hatch choice should be: one route-owned media capture native screen, not a generic adapter layer and not a broader bridge/plugin registry. That matches the existing taxonomy (`:native_screen` already exists, `:adapter` is still reserved), it matches the repo fixtures that already treat camera/capture as native-owned, and it matches Apple and Android platform guidance, where capture and media selection are exposed through dedicated system APIs rather than generic embedded web affordances. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: test/support/router_fixtures.ex] [CITED: https://developer.apple.com/documentation/avfoundation/avcapturesession] [CITED: https://developer.apple.com/documentation/photosui/phpickerviewcontroller?language=objc] [CITED: https://developer.android.com/media/camera/camerax?authuser=01] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en]

Pack lifecycle and media transfer should stay Phoenix-first and route-policy-first by making Phoenix declare the truth and native shells only execute it. The plan should add one typed pack registry and lifecycle contract, one typed transfer contract for upload/download/import/export seams, and one proof-lane shape that uses example hosts plus deterministic scripts while keeping public shell support at `verification required` until both platform runtime lanes pass. [VERIFIED: .planning/PROJECT.md] [VERIFIED: guides/install.md] [VERIFIED: guides/compatibility.md] [VERIFIED: guides/support_matrix.md] [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh]

**Primary recommendation:** Plan Phase 5 in five slices: manifest-owned pack registry, pack installer/inventory/invalidation service, one media-capture native screen, one explicit transfer contract for upload/download/import/export, and repo-owned example-host proof lanes that preserve the current proof-first support posture. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/crosswake/compatibility/compatibility.ex]

## Project Constraints (from CLAUDE.md)

No `./CLAUDE.md` file was present in the repo root during this research session, so there are no extra project-local directives beyond `AGENTS.md` and the `.planning/*` artifacts. [VERIFIED: filesystem check in repo root on 2026-05-17]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Route-level pack declarations and pack registry compilation | API / Backend | Database / Storage | Crosswake already compiles manifest truth in Elixir from route policy, so pack truth should be emitted there rather than discovered in native code. [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: lib/crosswake/manifest/types.ex] |
| Pack installation, on-device inventory, and availability checks | Browser / Client | API / Backend | The shell owns installed files and availability, but it should only enforce manifest-declared pack ids, versions, and integrity truth from Phoenix. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/shell/activation.ex] |
| Native media capture flow | Browser / Client | API / Backend | Camera and picker hardware ownership belongs in the native shell, while Phoenix still owns the route declaration, upload seam, and post-transfer workflow. [VERIFIED: test/support/router_fixtures.ex] [CITED: https://developer.apple.com/documentation/avfoundation/avcapturesession] [CITED: https://developer.android.com/media/camera/camerax?authuser=01] |
| Upload/download/import/export transfer contract | API / Backend | Browser / Client | Phoenix should define transfer intent, auth, and destination policy; the shell should handle picker/capture/download execution and return typed results. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/bridge/registry.ex] [CITED: https://developer.apple.com/documentation/foundation/urlsession?changes=_4_2%2C_4_2] [CITED: https://developer.android.com/reference/android/app/DownloadManager.html] |
| Denial vocabulary and fail-closed posture | API / Backend | Browser / Client | The denial model already lives in shared Elixir-side contract code and should remain a single vocabulary consumed by native surfaces. [VERIFIED: lib/crosswake/shell/denial.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] |
| Example-host proof lanes and support gating | Browser / Client | API / Backend | Runtime proof requires native shells and host tools, while doctor/support docs remain the public contract surface emitted from repo truth. [VERIFIED: lib/crosswake/doctor/doctor.ex] [VERIFIED: guides/support_matrix.md] [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh] |

## Standard Stack

### Core

| Library / Surface | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `~> 1.19` | Canonical route, manifest, compatibility, pack, and doctor truth. | This is the repo baseline and all current contract surfaces are already authored here. [VERIFIED: mix.exs] |
| Phoenix | `~> 1.8` | Phoenix-first host and route-policy source of truth. | Crosswake is explicitly Phoenix-first, not a framework replacement. [VERIFIED: mix.exs] [VERIFIED: .planning/PROJECT.md] |
| Phoenix LiveView | `~> 1.1` | Server-owned routes that still need explicit transfer seams around media flows. | Phase 5 adds explicit seams around LiveView-hosted routes instead of replacing them. [VERIFIED: mix.exs] [VERIFIED: .planning/ROADMAP.md] |
| `Crosswake.Manifest.Types` + `Crosswake.Manifest.Builder` | repo surface | Typed manifest root and route-first compilation. | Packs should extend this exact typed manifest pattern instead of adding a parallel config system. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] |
| `Crosswake.Compatibility` + `Crosswake.Shell.Denial` | repo surface | Pack/version/origin/runtime gating and stable denial vocabulary. | Pack lifecycle and transfer denial should reuse the existing fail-closed contract. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/shell/denial.ex] |
| iOS `AVCaptureSession` + `PHPickerViewController` + `URLSessionDownloadTask` | Platform SDK | Native capture, explicit media import, and explicit file download. | Apple documents `AVCaptureSession` for real-time capture, `PHPickerViewController` as the media-library picker, and `URLSession` download tasks for file downloads. [CITED: https://developer.apple.com/documentation/avfoundation/avcapturesession] [CITED: https://developer.apple.com/documentation/photosui/phpickerviewcontroller?language=objc] [CITED: https://developer.apple.com/documentation/foundation/urlsession?changes=_4_2%2C_4_2] |
| Android CameraX | `1.5.3` stable | Native capture on Android. | Android’s current stable CameraX release is `1.5.3`, which is the right narrow capture surface for a first native-screen escape hatch. [CITED: https://developer.android.com/jetpack/androidx/releases/camera?hl=en] |
| Android Photo Picker via `ActivityResultContracts.PickVisualMedia` | `androidx.activity 1.6.0+` and docs recommend `1.7.0+` integration helpers | Explicit visual media import without broad storage permission. | Android’s official picker contract prefers the system photo picker and falls back consistently across older devices. [CITED: https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en] |

### Supporting

| Library / Surface | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AndroidX WebKit | `1.15.0` | Existing bounded WebView hosting for LiveView routes. | Reuse for Phase 5 LiveView-hosted routes that need explicit transfer seams but are still web-owned. [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs] [CITED: https://developer.android.com/reference/androidx/webkit/WebViewCompat] |
| Android `FileProvider` | AndroidX Core | Safe app-owned file sharing through `content://` URIs. | Use when upload/export seams need to hand native-captured files back to the app or to other Android components. [CITED: https://developer.android.com/reference/androidx/core/content/FileProvider] |
| Android `DownloadManager` | Platform SDK | Explicit file download execution and progress. | Use for shell-owned downloads that should not be delegated to generic WebView behavior. [CITED: https://developer.android.com/reference/android/app/DownloadManager.html] |
| `mix crosswake.gen.shell` + native proof scripts | repo surface | Generated shell baselines and platform proof hooks. | Extend the existing generator/proof posture rather than adding a separate native bootstrap path. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh] |
| `mix crosswake.doctor` | repo surface | Public support/diagnostics surface. | Keep proof and support claims visible here rather than creating a second diagnostics product surface. [VERIFIED: lib/mix/tasks/crosswake.doctor.ex] [VERIFIED: lib/crosswake/doctor/doctor.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One `:native_screen` media-capture flow | Generic adapter/plugin registry | Reject the registry first. The current project thesis and current route taxonomy already favor explicit native screens over broad adapter creep. [VERIFIED: .planning/PROJECT.md] [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: test/support/router_fixtures.ex] |
| Explicit picker/capture/download transfer contract | Generic WebView file chooser handling | Reject generic chooser handling as the primary plan. Apple and Android both expose WebView file upload callbacks, but that path turns transfer into container behavior instead of route truth. [CITED: https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc] [CITED: https://developer.android.com/reference/android/webkit/WebChromeClient] |
| Immutable `pack_id@version` replacement with integrity | Overlay/patch-style pack mutation | Reject mutable overlays. Crosswake already rejects overlay-style remote manifest updates, and packs should inherit the same contract discipline. [VERIFIED: guides/compatibility.md] [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] |
| Repo-owned example hosts plus generator smoke | Tmpdir-generated proofs only | Reject generator smoke as the only public proof. There is no checked-in `examples/` host today, so CI cannot currently prove the same artifact class adopters will inspect and patch. [VERIFIED: filesystem search on 2026-05-17 found no `examples/` directory] [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh] |

**Installation target for planning:**
```bash
mix deps.get
mix test
mix crosswake.gen.shell ios
mix crosswake.gen.shell android
```
The Android example host should add CameraX and Photo Picker dependencies inside the generated Gradle app module, while iOS uses platform frameworks only. [VERIFIED: mix.exs] [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex] [CITED: https://developer.android.com/jetpack/androidx/releases/camera?hl=en] [CITED: https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia]

**Version verification notes:** CameraX `1.5.3` is the latest stable release shown on the AndroidX release page as of 2026-05-17, and `ActivityResultContracts.PickVisualMedia` is documented as added in `androidx.activity` `1.6.0`, with the Photo Picker guide recommending `1.7.0+` to simplify integration. [CITED: https://developer.android.com/jetpack/androidx/releases/camera?hl=en] [CITED: https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en]

## Architecture Patterns

### System Architecture Diagram

```text
Phoenix Router + Crosswake Policy DSL
  -> normalized %Route{} values with runtime/offline/capabilities/packs/sync/security
  -> Crosswake.Manifest.Builder
  -> route-first manifest
       -> compatibility truth
       -> capability registry
       -> pack registry + pack lifecycle metadata
       -> route entries referencing pack ids and transfer seams
  -> generated/example hosts consume bundled manifest

Bundled/example host activation
  -> activation request (cold start / deep link / in-app nav)
  -> Crosswake.Compatibility + RouteGate
       -> allow -> mount LiveView or native screen
       -> deny -> shared denial envelope / route unavailable UI

Native media capture route (:native_screen)
  -> OS capture/picker API
  -> app-owned temp file / content URI
  -> explicit Crosswake transfer result
  -> Phoenix upload or download seam
  -> manifest/doctor/support truth updated by proof lanes
```
This flow keeps Phoenix authoritative for declarations, native authoritative for device work, and proof authoritative for support claims. [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/manifest/builder.ex] [VERIFIED: guides/support_matrix.md]

### Recommended Project Structure

```text
lib/
├── crosswake/
│   ├── packs/               # typed pack registry, inventory, installer, invalidator
│   ├── transfer/            # explicit upload/download/import/export contracts
│   ├── native_escape/       # typed native-screen request/result contracts
│   ├── manifest/            # extend manifest types and builder with pack truth
│   ├── compatibility/       # extend pack/transfer gating, keep fail-closed
│   └── doctor/              # expose pack/transfer/proof posture
examples/
├── phoenix_host/            # minimal example Phoenix app Crosswake installs into
├── ios_shell_host/          # checked-in example iOS host artifact
└── android_shell_host/      # checked-in example Android host artifact
script/
├── verify_generated_ios_shell.sh
├── verify_generated_android_shell.sh
└── verify_phase5_example_hosts.sh
```
The `examples/` tree is recommended because no checked-in example hosts exist today, while DX-03 requires proof of the public install path across all surfaces. [VERIFIED: filesystem search on 2026-05-17 found no `examples/` directory] [VERIFIED: .planning/REQUIREMENTS.md]

### Pattern 1: Manifest-Owned Pack Registry

**What:** Add a typed pack registry at the manifest root and keep route entries referencing immutable `pack_id@version` requirements. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/manifest/builder.ex]

**When to use:** Use for content bundles, media model bundles, shell-owned chrome bundles, and other route-scoped assets that must be versioned and availability-checked before activation. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: test/crosswake/compatibility/compatibility_test.exs]

**Example:**
```elixir
# Source inspiration:
# - lib/crosswake/manifest/types.ex
# - lib/crosswake/compatibility/compatibility.ex

defmodule Crosswake.Packs.Contract do
  defmodule Pack do
    @enforce_keys [:id, :version, :kind, :source, :integrity, :install_root, :invalidation]
    defstruct [:id, :version, :kind, :source, :integrity, :install_root, :invalidation]
  end
end
```
This follows the repo’s existing typed nested-struct pattern and keeps pack truth explicit. [VERIFIED: lib/crosswake/manifest/types.ex]

### Pattern 2: Native Screen Owns Media Capture

**What:** Make the first device-heavy escape hatch one `:native_screen` route that owns camera/media capture end to end. [VERIFIED: test/support/router_fixtures.ex] [VERIFIED: lib/crosswake/policy/schema.ex]

**When to use:** Use when the route needs camera hardware, preview, or high-trust device interaction. Do not route this through the bounded bridge. [VERIFIED: guides/bridge.md] [VERIFIED: test/crosswake/bridge/registry_test.exs]

**Example:**
```elixir
# Source: test/support/router_fixtures.ex
live "/capture", Crosswake.TestSupport.CameraLive, :capture,
  crosswake: [
    id: "capture",
    runtime: :native_screen,
    offline: :local_first,
    capabilities: ["camera.capture"],
    packs: ["capture.pack"],
    sync: ["uploads"],
    security: :sensitive
  ]
```
The important planning point is not the exact fixture name; it is the route-owned runtime boundary. [VERIFIED: test/support/router_fixtures.ex]

### Pattern 3: Transfer Contract Returns File Handles, Not UI Side Effects

**What:** Represent media import/export/upload/download as a typed transfer request and typed transfer result that carry route id, transfer intent, file handle or URI, MIME, size, and completion status. [VERIFIED: lib/crosswake/bridge/contract.ex] [VERIFIED: lib/crosswake/shell/activation.ex] [CITED: https://developer.android.com/reference/androidx/core/content/FileProvider] [CITED: https://developer.apple.com/documentation/foundation/urlsession?changes=_4_2%2C_4_2]

**When to use:** Use on LiveView routes that need explicit media transfer without giving the WebView generic file authority, and on native-screen flows when a captured asset needs to cross back into Phoenix. [VERIFIED: guides/bridge.md] [VERIFIED: guides/native_shell.md]

**Example:**
```elixir
# Source inspiration:
# - lib/crosswake/bridge/contract.ex
# - official picker/download docs

%Crosswake.Transfer.Request{
  route_id: "library",
  intent: :upload_media,
  source: :native_picker,
  accept: ["image/*", "video/*"]
}
```

### Anti-Patterns to Avoid

- **Generic adapter creep:** Do not turn Phase 5 into a plugin catalog for camera, gallery, share sheet, and downloads. The repo deliberately keeps `:adapter` reserved and already narrowed the bridge command set. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/bridge/registry.ex]
- **Generic WebView file ownership:** Do not treat `WKUIDelegate` upload panels or `WebChromeClient.onShowFileChooser` as the primary public contract. Those APIs exist, but using them as the main seam would collapse explicit transfer truth into container behavior. [CITED: https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc] [CITED: https://developer.android.com/reference/android/webkit/WebChromeClient]
- **Mutable pack overlays:** Do not allow unversioned patching, in-place mutation, or implicit reuse across manifest versions. Crosswake already rejects overlay-style manifest updates, and pack invalidation should inherit that discipline. [VERIFIED: guides/compatibility.md] [VERIFIED: lib/crosswake/manifest/types.ex]
- **Support claims without runtime proof:** Do not upgrade support docs from `verification required` to `supported` based on generator smoke alone. [VERIFIED: guides/support_matrix.md] [VERIFIED: lib/crosswake/doctor/doctor.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Native media capture | A custom JS-to-native camera plugin bus | A dedicated `:native_screen` capture flow backed by `AVCaptureSession` on iOS and CameraX on Android | Capture is device-heavy, permission-heavy, and preview-heavy; platform capture APIs already solve those edges. [VERIFIED: test/support/router_fixtures.ex] [CITED: https://developer.apple.com/documentation/avfoundation/avcapturesession] [CITED: https://developer.android.com/media/camera/camerax?authuser=01] |
| Media picking | A custom in-WebView file chooser policy | `PHPickerViewController` and Android Photo Picker / `PickVisualMedia` | These system pickers minimize permission blast radius and keep media selection explicit. [CITED: https://developer.apple.com/documentation/photosui/phpickerviewcontroller?language=objc] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en] [CITED: https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia] |
| Android native bridge security | Broad `addJavascriptInterface` exposure | Keep the existing bounded request/reply posture and prefer modern constrained listeners or explicit activity contracts | Android warns that `addJavascriptInterface` is available to every frame and should not be the modern default. [CITED: https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge] [CITED: https://developer.android.com/guide/topics/security/security] |
| Pack updates | Ad hoc mutable asset directories | Immutable `pack_id@version` install roots plus integrity checks and explicit invalidation | Mutable packs are hard to reason about, hard to deny safely, and drift from the project’s versioned-contract posture. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: guides/compatibility.md] |
| Runtime proof | Human-only “works on my machine” native testing | `xcodebuild test` and Gradle managed-device or emulator-backed scripts against example hosts | The requirement is deterministic install proof, not informal spot checks. [CITED: https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results?changes=_9] [CITED: https://developer.android.com/studio/test/gradle-managed-devices] |

**Key insight:** Phase 5 credibility comes from narrowing ownership boundaries, not from hiding them. Crosswake should let Phoenix declare what native work exists, then use OS-native surfaces for that work instead of simulating native behavior through a generic container. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md]

## Common Pitfalls

### Pitfall 1: Adapter Creep Starts With “Just One More Media Command”

**What goes wrong:** A narrowly scoped capture feature expands into a plugin-style registry for gallery, scanner, recorder, share sheet, and background uploads. [VERIFIED: .planning/PROJECT.md] [VERIFIED: guides/bridge.md]

**Why it happens:** The route taxonomy already exposes `:native_screen`, but teams try to reuse the bridge because it feels cheaper in the short term. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/bridge/registry.ex]

**How to avoid:** Lock Phase 5 to one media-capture native screen and force any further device-heavy flows to justify themselves as separate later phases. [VERIFIED: .planning/STATE.md] [VERIFIED: .planning/ROADMAP.md]

**Warning signs:** New bridge commands start looking like UI workflows or permission brokers rather than single semantic requests. [VERIFIED: guides/bridge.md]

### Pitfall 2: Pack Truth Splits Between Phoenix And Native

**What goes wrong:** The manifest says one thing, but the shell invents its own inventory or invalidation logic, so route denials and support docs drift. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex]

**Why it happens:** Current route `packs` are only strings, so it is tempting to add pack logic natively without formalizing a typed registry first. [VERIFIED: lib/crosswake/manifest/types.ex] [VERIFIED: lib/crosswake/policy/schema.ex]

**How to avoid:** Introduce one typed manifest pack registry before building any installer or invalidator. [VERIFIED: lib/crosswake/manifest/types.ex]

**Warning signs:** Native templates hardcode pack ids or versions that are not derivable from the manifest. [VERIFIED: lib/crosswake/shell/fixtures.ex]

### Pitfall 3: Transfer Falls Back To Generic WebView Behavior

**What goes wrong:** Upload/download/media handling leaks into WebView callbacks, which turns route-level security and auditability into container heuristics. [CITED: https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc] [CITED: https://developer.android.com/reference/android/webkit/WebChromeClient]

**Why it happens:** Both iOS and Android WebView stacks do expose file chooser hooks, so teams treat them as a convenient shortcut. [CITED: https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc] [CITED: https://developer.android.com/reference/android/webkit/WebChromeClient]

**How to avoid:** Require typed Crosswake transfer requests and results for import, upload, export, and download. [VERIFIED: lib/crosswake/bridge/contract.ex]

**Warning signs:** A plan item mentions “file inputs working in the WebView” without naming a Crosswake transfer contract. [VERIFIED: guides/native_shell.md]

### Pitfall 4: Proof Lanes Prove The Wrong Artifact Class

**What goes wrong:** CI proves a tempdir scaffold or unit tests but not the example host artifact an adopter would actually inspect, patch, and ship. [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh]

**Why it happens:** Generated-project smoke tests are easier to script than checked-in example hosts. [VERIFIED: lib/mix/tasks/crosswake.gen.shell.ex]

**How to avoid:** Keep generator smoke tests, but add repo-owned example hosts and one phase-level verification script that runs Phoenix, iOS, and Android lanes together. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: filesystem search on 2026-05-17 found no `examples/` directory]

**Warning signs:** Support claims are widened because generation succeeded even though simulator/emulator runtime proof still fails. [VERIFIED: guides/support_matrix.md] [VERIFIED: .planning/STATE.md]

## Code Examples

Verified patterns from current repo and official docs:

### Route-First Native Capture Declaration
```elixir
# Source: test/support/router_fixtures.ex
live "/capture", Crosswake.TestSupport.CameraLive, :capture,
  crosswake: [
    id: "capture",
    runtime: :native_screen,
    offline: :local_first,
    capabilities: ["camera.capture"],
    packs: ["capture.pack"],
    sync: ["uploads"],
    security: :sensitive
  ]
```
[VERIFIED: test/support/router_fixtures.ex]

### Fail-Closed Pack Gating
```elixir
# Source: lib/crosswake/compatibility/compatibility.ex
Enum.reduce(route.packs, errors, fn pack_requirement, acc ->
  {pack_id, required_version} = parse_pack_requirement(pack_requirement)
  available_version = Map.get(target.packs, pack_id)
  ...
end)
```
[VERIFIED: lib/crosswake/compatibility/compatibility.ex]

### Android Explicit Picker Contract
```kotlin
// Source inspiration:
// https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia
val pickMedia = registerForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
    // Convert the returned content URI into a typed Crosswake transfer result.
}
```
[CITED: https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `UIImagePickerController` or generic file-upload UI as the main photo-library seam | `PHPickerViewController` for library selection plus dedicated capture APIs for camera work | Current Apple docs; `PHPickerViewController` is documented as an alternative to `UIImagePickerController` | Crosswake should separate library selection from capture and keep both explicit. [CITED: https://developer.apple.com/documentation/photosui/phpickerviewcontroller?language=objc] |
| Android storage-permission-heavy gallery access | Android Photo Picker via `PickVisualMedia`, with fallback behavior across older devices | `PickVisualMedia` added in `androidx.activity 1.6.0`; docs updated 2026-02-19 | Crosswake can keep media import explicit without asking for broad library ownership first. [CITED: https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en] |
| Broad WebView native bridge exposure | Origin-scoped, bounded, request/reply-only native bridge or explicit activity contracts | Current Android security guidance warns against modern default use of `addJavascriptInterface` | Crosswake should keep Phase 5 media work out of a broad WebView bridge. [CITED: https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge] [CITED: https://developer.android.com/guide/topics/security/security] |
| Unproven native support claims | Proof-gated support matrix with generated-host hooks and example-host lanes | Already in repo as of Phase 3/4 | Phase 5 should preserve and strengthen this posture rather than relaxing it. [VERIFIED: guides/support_matrix.md] [VERIFIED: guides/native_shell.md] |

**Deprecated/outdated:**
- Using `:adapter` as a public runtime is still out of scope; the schema explicitly reserves it for future extension. [VERIFIED: lib/crosswake/policy/schema.ex]
- Treating generic WebView file chooser callbacks as the public media contract is outdated for this project because it conflicts with the explicit-route thesis. [VERIFIED: .planning/PROJECT.md] [CITED: https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc] [CITED: https://developer.android.com/reference/android/webkit/WebChromeClient]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] The best first pack kinds are likely `content`, `media`, and `shell_chrome`, because those map cleanly onto current route and denial semantics without widening into OTA code delivery. | Standard Stack / Architecture Patterns | Medium — pack taxonomy might need a different first split, but the plan shape stays similar. |
| A2 | [ASSUMED] A checked-in `examples/` tree is the cleanest DX-03 artifact shape, even though the requirement only mandates example hosts and deterministic proof, not a specific directory layout. | Recommended Project Structure / Open Questions | Low — the repo could place example hosts elsewhere if the proof artifact class remains explicit. |

If this table is non-empty, those assumptions should be confirmed during planning before they become locked execution decisions. [ASSUMED]

## Open Questions

1. **Should Phase 5 prove checked-in example hosts, generated hosts, or both?**
   - What we know: current proof hooks generate tempdir shell projects and there is no checked-in `examples/` host today. [VERIFIED: script/verify_generated_ios_shell.sh] [VERIFIED: script/verify_generated_android_shell.sh] [VERIFIED: filesystem search on 2026-05-17 found no `examples/` directory]
   - What's unclear: whether the maintainer wants DX-03 proof centered on generated artifacts only or on stable example-host repos plus generator smoke. [ASSUMED]
   - Recommendation: plan for both, but make checked-in example hosts the public proof artifact and keep generator smoke as a secondary guard. [ASSUMED]

2. **Should pack downloads be foreground-only in Phase 5?**
   - What we know: the project thesis values explicit route ownership and honest support boundaries over breadth. [VERIFIED: .planning/PROJECT.md] [VERIFIED: AGENTS.md]
   - What's unclear: whether background/resumable transfer is needed in v1 for the chosen exemplar, or whether explicit foreground transfer is enough. [ASSUMED]
   - Recommendation: plan foreground-only first unless the exemplar route demonstrably fails without background behavior. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `xcodebuild` | iOS example-host proof lane | ✓ | `Xcode 26.0.1 (17A400)` | None for full support claims. [VERIFIED: `xcodebuild -version` on 2026-05-17] |
| iOS Simulator SDK + `simctl` | iOS runtime proof lane | ✓ | `iOS Simulator 26.0`; device list returned | No full fallback; compile/list checks are weaker than runtime proof. [VERIFIED: `xcodebuild -showsdks` on 2026-05-17] [VERIFIED: `xcrun simctl list devices` on 2026-05-17] |
| iOS generated-shell proof hook | DX-03 iOS runtime verification | Partial | Current run reaches build and test launch, then fails with `IDEPseudoTerminalDomain Code 7` / `Device not configured` on 2026-05-17 | Keep support at `verification required` until fixed. [VERIFIED: `bash script/verify_generated_ios_shell.sh` on 2026-05-17] |
| `java` | Android proof bootstrap | ✗ | — | The Android proof script bootstraps JDK or uses Homebrew/OpenJDK automatically. [VERIFIED: `java -version` on 2026-05-17] [VERIFIED: script/verify_generated_android_shell.sh] |
| `adb` | Android emulator/device proof | ✗ | — | The Android proof script bootstraps Android SDK tools, including `adb`. [VERIFIED: `command -v adb` on 2026-05-17] [VERIFIED: script/verify_generated_android_shell.sh] |
| `sdkmanager` | Android SDK install for proof | ✗ | — | The Android proof script downloads command-line tools and exposes `sdkmanager`. [VERIFIED: `command -v sdkmanager` on 2026-05-17] [VERIFIED: script/verify_generated_android_shell.sh] |
| `gradle` | Android project proof | ✗ | — | The generated Android shell includes a Gradle wrapper, so system Gradle is not required. [VERIFIED: `command -v gradle` on 2026-05-17] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs] |
| `brew` | Android JDK fallback bootstrap | ✓ | `Homebrew 5.1.11` | Secondary fallback only; script can also download Temurin directly. [VERIFIED: `brew --version` on 2026-05-17] [VERIFIED: script/verify_generated_android_shell.sh] |

**Missing dependencies with no fallback:**
- None at the CLI layer, but the iOS runtime proof lane currently has no substitute for a successful simulator test launch if support claims are to be widened. [VERIFIED: `bash script/verify_generated_ios_shell.sh` on 2026-05-17] [VERIFIED: guides/support_matrix.md]

**Missing dependencies with fallback:**
- `java`, `adb`, `sdkmanager`, and `gradle` are absent locally, but the Android proof flow already embeds JDK/SDK/bootstrap fallback through the generated project and shell verification script. [VERIFIED: script/verify_generated_android_shell.sh] [VERIFIED: test/mix/tasks/crosswake_gen_shell_test.exs]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Phoenix host should mint transfer/auth intent, not the shell. [VERIFIED: .planning/PROJECT.md] |
| V3 Session Management | yes | Keep route-owned upload/download sessions tied to explicit transfer tickets and origin checks. [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex] |
| V4 Access Control | yes | Reuse route allowlists, active-route checks, and fail-closed denials. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: lib/crosswake/bridge/contract.ex] |
| V5 Input Validation | yes | Keep route policy and manifest additions inside NimbleOptions and typed struct validation, not stringly typed native config. [VERIFIED: lib/crosswake/policy/schema.ex] [VERIFIED: lib/crosswake/manifest/types.ex] |
| V6 Cryptography | yes | Use standard integrity hashes for pack contents; never hand-roll integrity algorithms. [ASSUMED] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Insecure WebView-native bridge exposure | Elevation of Privilege | Keep media transfer out of a broad `addJavascriptInterface` bridge and preserve origin-scoped, request/reply-only behavior. [CITED: https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge] [CITED: https://developer.android.com/guide/topics/security/security] |
| Untrusted file or URI handoff | Tampering | Use app-owned temp files and `content://` URIs via `FileProvider` on Android; validate MIME, size, and route intent before upload. [CITED: https://developer.android.com/reference/androidx/core/content/FileProvider] [CITED: https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en] |
| Pack downgrade or stale-pack activation | Tampering | Require exact or compatible `pack_id@version` matches and deny route activation on mismatch. [VERIFIED: lib/crosswake/compatibility/compatibility.ex] [VERIFIED: test/crosswake/compatibility/compatibility_test.exs] |
| Container-driven file access on sensitive routes | Information Disclosure | Keep transfer as an explicit contract and preserve security-sensitive route declarations. [VERIFIED: test/support/router_fixtures.ex] [VERIFIED: lib/crosswake/policy/validator.ex] |

## Sources

### Primary (HIGH confidence)
- [mix.exs](/Users/jon/projects/crosswake/mix.exs) - repo dependency baselines and version targets
- [lib/crosswake/manifest/types.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/types.ex) - typed manifest structure and existing route `packs`
- [lib/crosswake/manifest/builder.ex](/Users/jon/projects/crosswake/lib/crosswake/manifest/builder.ex) - route-first manifest assembly
- [lib/crosswake/compatibility/compatibility.ex](/Users/jon/projects/crosswake/lib/crosswake/compatibility/compatibility.ex) - pack/version/origin gating and denial mapping
- [lib/crosswake/shell/activation.ex](/Users/jon/projects/crosswake/lib/crosswake/shell/activation.ex) - manifest-first activation contract
- [lib/crosswake/shell/denial.ex](/Users/jon/projects/crosswake/lib/crosswake/shell/denial.ex) - stable denial vocabulary
- [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex) - bounded request/reply contract shape
- [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex) - bounded command set
- [lib/mix/tasks/crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex) - generated shell posture and fixture export
- [lib/crosswake/doctor/doctor.ex](/Users/jon/projects/crosswake/lib/crosswake/doctor/doctor.ex) - doctor aggregation and support gating
- [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md) - shell contract and support posture
- [guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md) - bounded bridge posture
- [guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md) - public support gating
- [script/verify_generated_ios_shell.sh](/Users/jon/projects/crosswake/script/verify_generated_ios_shell.sh) - iOS proof hook behavior
- [script/verify_generated_android_shell.sh](/Users/jon/projects/crosswake/script/verify_generated_android_shell.sh) - Android proof hook behavior
- [test/support/router_fixtures.ex](/Users/jon/projects/crosswake/test/support/router_fixtures.ex) - existing `:native_screen` capture fixtures
- https://developer.apple.com/documentation/avfoundation/avcapturesession - iOS capture session API
- https://developer.apple.com/documentation/photosui/phpickerviewcontroller?language=objc - iOS photo-library picker
- https://developer.apple.com/documentation/foundation/urlsession?changes=_4_2%2C_4_2 - iOS download/upload task model
- https://developer.apple.com/documentation/xcode/running-tests-and-interpreting-results?changes=_9 - `xcodebuild test` posture
- https://developer.android.com/jetpack/androidx/releases/camera?hl=en - current CameraX stable release
- https://developer.android.com/reference/kotlin/androidx/activity/result/contract/ActivityResultContracts.PickVisualMedia - Android Photo Picker activity contract
- https://developer.android.com/training/data-storage/shared/photo-picker?authuser=2&hl=en - Android Photo Picker integration guidance
- https://developer.android.com/reference/androidx/core/content/FileProvider - Android file-sharing URI posture
- https://developer.android.com/reference/android/app/DownloadManager.html - Android explicit downloads
- https://developer.android.com/studio/test/gradle-managed-devices - Android managed-device proof lane guidance
- https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge - Android bridge security guidance
- https://developer.android.com/guide/topics/security/security - Android WebView security checklist

### Secondary (MEDIUM confidence)
- https://developer.apple.com/documentation/webkit/wkuidelegate/webview%28_%3Arunopenpanelwith%3Ainitiatedbyframe%3Acompletionhandler%3A%29?language=objc - confirms generic WebView file-upload seam exists on iOS, which helps explain why Crosswake should not make it the primary contract
- https://developer.android.com/reference/android/webkit/WebChromeClient - confirms generic WebView file chooser seam exists on Android

### Tertiary (LOW confidence)
- None. All material recommendations were either verified in-repo or cited from official platform documentation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the repo already exposes the core contract surfaces, and the platform APIs chosen here are official current docs. [VERIFIED: mix.exs] [VERIFIED: lib/crosswake/manifest/types.ex] [CITED: https://developer.apple.com/documentation/avfoundation/avcapturesession] [CITED: https://developer.android.com/jetpack/androidx/releases/camera?hl=en]
- Architecture: HIGH - the current codebase already demonstrates manifest-first, fail-closed, route-owned patterns that Phase 5 should extend directly. [VERIFIED: lib/crosswake/shell/activation.ex] [VERIFIED: lib/crosswake/compatibility/compatibility.ex]
- Pitfalls: HIGH - they are grounded in both existing repo boundaries and explicit Android/iOS platform behaviors. [VERIFIED: guides/bridge.md] [VERIFIED: .planning/PROJECT.md] [CITED: https://developer.android.com/develop/ui/views/layout/webapps/native-api-access-jsbridge]

**Research date:** 2026-05-17
**Valid until:** 2026-06-16 for repo structure and public docs; re-check native proof posture sooner if the local iOS or Android host environment changes. [VERIFIED: local command checks on 2026-05-17]
