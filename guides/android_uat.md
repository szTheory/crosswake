# Android Device-UAT Checklist

## Status

No emulator or physical-device verification of Android has been recorded. The only Android evidence is JVM hermetic proof and the shared bridge-contract vectors. The checklist below is a template for future device evidence, not a record of runs.

## What This Proves

`JVM hermetic proof` and advisory emulator evidence can help validate Android shell behavior, but they do not prove physical-device support.

## Verification Surfaces

Use the labels literally:

- `JVM hermetic proof` | deterministic JVM-level CI for Android logic
- `emulator evidence` | advisory emulator output
- `device evidence` | named physical-device output
- `verification-required` | a claim still needs an explicit verification lane
- `rebuild-required` | a native or companion change requires rebuilding the host artifact

### CI-Provable

- [ ] Emulator boot and initial manifest parsing | `emulator evidence`
- [ ] JVM hermetic logic | `JVM hermetic proof`

### Device-Advisory

- [ ] Deep-link intent resolution: tapping a URL opens the app and routes correctly.
- [ ] Runtime permission flows: OS dialogs appear correctly for required permissions.
- [ ] WebView rendering: the embedded Phoenix app renders correctly with safe-area insets.
- [ ] SDK-version behavior: the app behaves correctly on the oldest supported API and target API.
- [ ] Hardware sensors: device sensors respond appropriately when configured.

### Provider-Advisory

- [ ] Capability provider integration behaves properly with actual Google Play Services, such as billing or push tokens.

---

## Capability families (registry mirror)

This list mirrors the capability-family registry. Listing a family here does not mean Android implements it or has verified it.

- `deep_link`
- `app_info`
- `file_picker`
- `notification_token`
- `media_capture`
- `haptics`
- `purchase_intent`
- `restore_intent`
- `paywall_entry`
- `entitlement_snapshot`
- `reconciliation_evidence`
- `document_scan`
- `permissions.status`
- `scanner`
- `share`

## Boundary

Android claims stop at JVM-hermetic proof and the shared bridge-contract vectors. No emulator, device or feature-breadth claim is made until a later phase produces that evidence.

Use `checked-in public-coordinate proof` for the checked-in host paths and `--local` for maintainer/local-dev proof.
