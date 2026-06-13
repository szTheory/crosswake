# Android Device-UAT Checklist

**Last verified against:** Crosswake v0.1.0 on Android 15 (API 35)

## Verification Surfaces

This checklist explicitly documents what hermetic JVM testing cannot cover and requires either CI device tests or human operator advisory testing.

### CI-Provable
- [ ] Emulator boot and initial manifest parsing
- [ ] JVM Hermetic logic (tested natively via ExUnit/JUnit)

### Device-Advisory
- [ ] Deep-link intent resolution: Tapping a URL opens the app and routes correctly.
- [ ] Runtime permission flows: OS dialogs appear correctly for required permissions.
- [ ] WebView rendering: The embedded Phoenix app renders correctly with correct safe-area insets.
- [ ] SDK-version behavior: App behaves correctly on oldest supported API and target API.
- [ ] Hardware sensors: Device sensors (if configured) respond appropriately.

### Provider-Advisory
- [ ] Capability provider integration behaves properly with actual Google Play Services (e.g. billing, push tokens).

---

## Capabilities (Parity-Locked)

Every capability family in the registry must have an entry here for verification.

- **deep_link**: Verified intent filter and URI routing.
- **app_info**: Verified app name and version string bridge properly.
- **file_picker**: Verified system file picker returns valid URIs.
- **notification_token**: Verified FCM/Push provider correctly issues a token to the bridge.
- **media_capture**: Verified camera intent works and returns media.
- **haptics**: Verified device vibrates on trigger.
- **purchase_intent**: Verified billing bottom sheet appears.
- **restore_intent**: Verified past purchases are restored correctly.
- **paywall_entry**: Verified paywall renders and blocks content.
- **account_management**: Verified settings or account management surface displays.
- **diagnostic_export**: Verified logs/diagnostics can be packaged and shared.
- **entitlement_snapshot**: Verified local user capabilities reflect active purchases.
- **reconciliation_evidence**: Verified purchase receipts can be synchronized.
- **companion_snapshot**: Verified companions state synchronizes.
- **location_capture**: Verified location permission and coordinate fetching.
- **document_scan**: Verified system document scanner works and returns PDF/image.
- **permissions.status**: Verified bridge accurately reports permission status without prompting.
- **scanner**: Verified barcode/QR scanner launches and captures codes.
- **share**: Verified system share sheet appears with correct content payload.
