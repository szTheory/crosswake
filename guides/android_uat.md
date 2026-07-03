# Android Device-UAT Checklist

**Last verified against:** Crosswake v0.1.2 on Android 15 (API 35) <!-- x-release-please-version -->

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

## Capabilities (Parity-Locked)

Every capability family in the registry must have an entry here for verification.

- `deep_link`
- `app_info`
- `file_picker`
- `notification_token`
- `media_capture`
- `haptics`
- `purchase_intent`
- `restore_intent`
- `paywall_entry`
- `account_management`
- `diagnostic_export`
- `entitlement_snapshot`
- `reconciliation_evidence`
- `companion_snapshot`
- `location_capture`
- `document_scan`
- `permissions.status`
- `scanner`
- `share`

## Boundary

Use `checked-in public-coordinate proof` for the checked-in host paths and `--local` for maintainer/local-dev proof.
Do not treat JVM, emulator, or device evidence as a claim of physical-device support unless a future milestone explicitly promotes it.
