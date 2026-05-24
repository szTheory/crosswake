# Phase 15: Base Capability Bridges - Research

**Researched:** 2026-05-20
**Domain:** Elixir Host to Native Shell bridging and capability implementation (iOS/Android).
**Confidence:** HIGH

## Summary

This phase establishes the foundational bridge capability patterns by implementing three low-frequency, stateless capabilities: `app.info.get`, `haptics.impact`, and `share.invoke`. The goal is to solidify payload serialization on the Elixir host and ensure precise invocation of native APIs without persistent state or complex lifecycles (like `FileProvider` on Android).

**Primary recommendation:** Use primitive strings and URL representations for share payloads to keep the native boundaries fail-closed, avoiding complex Android file access permissions or iOS legacy string typing issues. Add each payload capability explicitly to `lib/crosswake/bridge/registry.ex`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **Share Payload Format and Scope**
   **Decision:** Restrict share payloads to primitive strings (`url`, `text`, `title`).
   **Rationale:** To maintain a strictly stateless bridge without complex Android `FileProvider` lifecycles or temporary file garbage collection, we are mirroring the Web Share API. If a user needs to share a generated PDF, the server should host the file at an ephemeral URL and send that `url` over the bridge. This keeps the native shells thin and fail-closed.

2. **Command Naming Conventions**
   **Decision:** Standardize on `<family>.<action>`.
   - Haptics: `haptics.impact` (payload: `%{style: "light" | "medium" | "heavy"}`)
   - App Info: `app.info.get` (returns `%{version: string, build: string, bundle_id: string}`)
   - Share: `share.invoke` (payload: `%{url?: string, text?: string, title?: string}`)
   **Rationale:** `haptics.impact` and `app.info.get` are already documented as legacy/existing IDs in the manifest builder. Introducing `share.invoke` aligns perfectly with this dot-separated taxonomy.

3. **Registry Allowlisting**
   **Decision:** Explicitly map all three commands in `lib/crosswake/bridge/registry.ex`.
   **Rationale:** Crosswake operates on a fail-closed paradigm. If a capability command is not explicitly mapped in the bridge registry, the Elixir host rejects it with `:unsupported_command`. This guarantees no native boundary is ever crossed by an arbitrary or malicious string.

### the agent's Discretion
None specified in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)
None specified in CONTEXT.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CAP-HAPTICS | Haptics impact capability | `HapticFeedbackConstants` (Android), `UIImpactFeedbackGenerator` (iOS), struct payload `%{style}`. |
| CAP-SHARE | Share capability (url, text, title) | `Intent.ACTION_SEND` (Android), `UIActivityViewController` (iOS). |
| CAP-APPINFO | App Info retrieval | `PackageInfo` (Android), `Bundle.main.infoDictionary` (iOS), struct response payload. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Share Payload Generation | API / Backend | — | URLs and share-able content originate from Elixir, keeping shells thin. |
| Native Bridge Registry | API / Backend | — | Must fail-closed on unsupported/malicious commands before dispatch. |
| Share UI Display | Browser / Client | — | Native iOS `UIActivityViewController` and Android `Intent.ACTION_SEND` control share sheet rendering. |
| Haptic Feedback | Browser / Client | — | Triggered natively via OS APIs based on stateless bridge commands. |

## Standard Stack

### Core
| Library / API | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `UIActivityViewController` | iOS 13+ | System sharing (iOS) | Standard UIKit component for sharing data arrays (URLs, strings) to native/3rd-party apps. |
| `UIImpactFeedbackGenerator` | iOS 13+ | Haptic feedback (iOS) | Standard UIKit API for providing tactile response (light, medium, heavy). |
| `Intent.ACTION_SEND` | Android API 21+ | System sharing (Android) | Standard intent action for launching the Android ShareSheet. |
| `HapticFeedbackConstants` | Android API 29+ | Haptic feedback (Android) | Constant definitions matching iOS styles (`EFFECT_TICK`, `EFFECT_CLICK`). |

## Architecture Patterns

### Recommended Project Structure
```
lib/crosswake/bridge/
├── registry.ex                # Central allowlist for capabilities
└── commands/
    ├── app_info.ex            # Typed Request/Response struct
    ├── haptics.ex             # Typed Request struct
    └── share.ex               # Typed Request struct
examples/
├── ios_shell_host/CrosswakeShell/BridgeChannel.swift
└── android_shell_host/app/src/main/java/dev/crosswake/shell/BridgeChannel.kt
```

### Pattern 1: Typed Payload Structs
**What:** Define explicit `Request` and `Response` (where applicable) modules with `@enforce_keys` and `@type` definitions for Elixir commands.
**When to use:** Whenever passing a payload through `Crosswake.Bridge.Registry`.
**Example:**
```elixir
defmodule Crosswake.Bridge.Commands.Share do
  @moduledoc false
  
  defmodule Request do
    defstruct [:url, :text, :title]
    @type t :: %__MODULE__{
      url: String.t() | nil,
      text: String.t() | nil,
      title: String.t() | nil
    }
  end
end
```

### Anti-Patterns to Avoid
- **Passing generic maps across the bridge:** Always deserialize native responses into typed structs (`AppInfo.Response`) or serialize typed structs (`Share.Request`) to maps before sending to the client.
- **Requiring `VIBRATE` permission unnecessarily:** Use `view.performHapticFeedback` instead of `Vibrator` service on Android to avoid extra manifest permissions, if a view context is accessible.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sharing Files/Images | Android `FileProvider` temp storage | Ephemeral Server URLs | Lifecycles are messy. Passing a URL over the bridge delegates the download/fetching to the target app, removing state from the shell. |
| Validating commands | Pattern matching in controllers | `Crosswake.Bridge.Registry` map | Keep allowed commands in a single, predictable location for fail-closed security. |

## Common Pitfalls

### Pitfall 1: Facebook App sharing on Android
**What goes wrong:** Facebook often ignores `EXTRA_TEXT` when both text and a URL are concatenated in `Intent.ACTION_SEND`.
**Why it happens:** Facebook's ShareSheet receiver parses intents poorly without their proprietary SDK.
**How to avoid:** Accept it as a known ecosystem constraint; avoid creating a custom workaround for Facebook. Passing just a URL or combined text is the standard `ACTION_SEND` behavior.

### Pitfall 2: iOS `UIActivityViewController` iPad Crash
**What goes wrong:** `UIActivityViewController` crashes on iPad if a `sourceView` or `barButtonItem` isn't provided.
**Why it happens:** iPads require popovers to be anchored to a specific view element.
**How to avoid:** Set `popoverPresentationController.sourceView` to the root view controller's view and explicitly define the `sourceRect` or `permittedArrowDirections`.

### Pitfall 3: Legacy String types in iOS Share
**What goes wrong:** Passing a URL string directly as a `String` into `activityItems` causes some apps to treat it as plain text instead of a clickable rich link.
**Why it happens:** `UIActivityViewController` uses the types of `activityItems` to determine what share extensions appear.
**How to avoid:** Always convert string URLs to `URL(string: urlString)!` before placing them in the `activityItems` array.

## Code Examples

### iOS App Info Fetching
```swift
// Source: Apple Developer Docs
let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
let bundleId = Bundle.main.bundleIdentifier ?? ""
```

### Android App Info Fetching
```kotlin
// Source: Android Developer Docs
val packageInfo = context.packageManager.getPackageInfo(context.packageName, 0)
val version = packageInfo.versionName ?: ""
val build = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
    packageInfo.longVersionCode.toString()
} else {
    @Suppress("DEPRECATION")
    packageInfo.versionCode.toString()
}
val bundleId = context.packageName
```

### iOS Haptics Implementation
```swift
// Source: Apple Developer Docs
let style: UIImpactFeedbackGenerator.FeedbackStyle
switch payload["style"] as? String {
    case "light": style = .light
    case "heavy": style = .heavy
    default: style = .medium
}
let generator = UIImpactFeedbackGenerator(style: style)
generator.impactOccurred()
```

### Android Haptics Implementation
```kotlin
// Source: Android Developer Docs
val constant = when (payload["style"] as? String) {
    "light" -> HapticFeedbackConstants.KEYBOARD_TAP // Fallback for pre-API 29
    "heavy" -> HapticFeedbackConstants.LONG_PRESS
    else -> HapticFeedbackConstants.VIRTUAL_KEY
}
// Note: If targeting API 29+, EFFECT_TICK, EFFECT_CLICK, and EFFECT_HEAVY_CLICK are preferred.
view.performHapticFeedback(constant)
```

### Android Share Implementation
```kotlin
// Source: Android Developer Docs
val intent = Intent(Intent.ACTION_SEND).apply {
    type = "text/plain"
    
    val text = payload["text"] as? String
    val url = payload["url"] as? String
    val title = payload["title"] as? String
    
    val combinedText = listOfNotNull(text, url).joinToString("\n\n")
    if (combinedText.isNotEmpty()) {
        putExtra(Intent.EXTRA_TEXT, combinedText)
    }
    
    if (title != null) {
        putExtra(Intent.EXTRA_TITLE, title) // API 29+ rich preview title
    }
}
val chooser = Intent.createChooser(intent, "Share via")
context.startActivity(chooser)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Vibrator` service | `view.performHapticFeedback` | API 29 | Avoids `VIBRATE` permission requirement and respects system settings. |
| Concatenated titles | `Intent.EXTRA_TITLE` | API 29 | Enables rich previews in the Android Sharesheet. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No explicit `VIBRATE` permission is needed on Android if `view.performHapticFeedback` is used. | Patterns | Moderate. If incorrect, app may crash on Haptics invocation without permission. (Considered standard practice, but context-dependent on view availability). |

## Open Questions (RESOLVED)

1. **View Availability for Android Haptics**
   - What we know: `view.performHapticFeedback` is preferred over `Vibrator` service for haptics.
   - What's unclear: If `BridgeChannel.kt` executes entirely outside of a view context or has easy access to the root view.
   - Recommendation: Pass the root view (e.g., `window.decorView`) to the bridge channel or fallback to `Vibrator` (which requires permission) if a view isn't accessible.
   - **Resolution:** Based on Plan 03, the webView is accessible and can be passed to or utilized by `BridgeChannel.kt` for haptic feedback without `VIBRATE` permission.

## Sources

### Primary (HIGH confidence)
- Android Developer Docs - Intents & Intent Filters / Sharing simple data.
- Android Developer Docs - `HapticFeedbackConstants`.
- Apple Developer Documentation - `UIActivityViewController` & `UIImpactFeedbackGenerator`.

### Secondary (MEDIUM confidence)
- Community verification regarding iPad `UIActivityViewController` popover crashes.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Verified via official Apple and Google documentation.
- Architecture: HIGH - Derived directly from the `15-PATTERNS.md` analog file.
- Pitfalls: HIGH - Well-known industry edge cases (iPad popovers, Facebook text handling).

**Research date:** 2026-05-20
**Valid until:** 2027-05-20
