# v25 Media Ownership Resolution

**Decision:** The generated-candidate twin should test a foreground native audio action owned by the host and initiated from the actual visible `:offline_island` UI. Do not require the WebView to decode or open files from Application Support.

## Why this is the coherent boundary

The governing ADR assigns the host archive acquisition, authentication, codecs, content grouping, storage, and actual playback; Crosswake owns only the requirement-bound pack lifecycle and denial contract. The route map explicitly places audio asset consumption inside the offline island while naming the iOS pack provider as the host owner. “Inside the island” identifies the user workflow and trigger; it does not require WebKit to own the file bytes or decoder.

The approved source already has the narrow mechanism needed for this division. `CrosswakeShellConfig` accepts `HostBridgeCommandDelegate`; that delegate exposes registered host commands and a typed request/reply result. `BridgeChannel` accepts only `host.*` commands registered by the host and declared for the active route/session, then returns the correlated reply. This is an existing generic extension seam, not a new Crosswake audio capability or pack-file API. The example shell currently wires its `PackProvider` but does not wire an audio host command, so the missing work is a narrow reference-host composition using that existing seam.

The physical proof host already owns installed-asset lookup and AVFoundation playback, including a requirement-checked `installedAssetURL` and `AVAudioPlayer`. That is useful implementation precedent, but its separate physical UI flow does not prove the generated visible island can request playback. Conversely, the generated shell’s provider installs an opaque verified pack and has no observed audio command from the study UI. The solution is to join the real UI action to the host owner, not to combine unrelated green tests.

## Required composition and observation

Use one host-declared command such as `host.study.audio.play`, limited to the selected offline-island route and a closed payload containing only the pack/asset reference allowed by that host. A learner tap in the visible study WebView sends the typed, correlated command. The existing shell validates protocol/version, active route, origin, and manifest-declared capability before calling the host delegate. The host adapter rechecks current pack status and integrity against its expected size/digest, resolves the requested asset inside that installed pack, and starts its foreground AVFoundation player. It must fail closed on missing, stale, corrupt, undeclared, or unavailable assets. Return only a closed outcome and safe reason; never expose filesystem paths, archive bytes, answer data, or stable user/scope identifiers.

The twin passes only when one source/build-bound run demonstrates the whole chain: the actual visible island’s user gesture; its matching bridge command and correlation reply from the same WebView; the host delegate’s acceptance for the active route; provider verification of the installed pack and asset identity; native player start and playback progress/completion; and a target-scoped network denial showing no remote-media fallback. The test must bind the player input to the installed verified bytes, rather than merely observing that some audio played. This establishes simulator playback behavior, not physical-speaker quality or signed-device evidence. Keep the existing physical-iPhone gate for that evidence.

## Why not expose files to WebKit

Serving `file://` URLs, introducing a custom scheme handler, copying media into IndexedDB, or adding a general native-file bridge would create a second asset authority, permission surface, cache/lifecycle policy, and WebKit-specific contract. None is required by the ADR’s host-owned native media adapter. Consider a WebView-readable media path only if an actual host route contract requires browser decoding and the host cannot satisfy the action through the existing declared host-command seam. If that path requires a new public Crosswake protocol/capability, generic file URL/scheme service, or generic storage API, keep the scenario blocked and return for an explicit scope decision.

## Corrections to twin wording

- Replace “the WebView audio element must decode bytes installed by the provider” with “the visible offline-island audio action invokes the host-owned native player for an asset proven to come from the verified installed pack.”
- Keep “native AVFoundation playback” insufficient when it is tested through a separate button, test-only call, hidden WebView, or direct adapter invocation. The originating action must be the visible island’s normal user gesture.
- No new Crosswake audio capability is proposed. Use only the existing host-declared command delegate and current route/bridge authorization. If the pinned command path does not carry the active route’s required capability in the generated candidate, stop rather than inventing a core seam.

## Pinned source anchors

- [ADR: pronunciation media](../../ADR-FIRST-B2C-ADOPTER.md#pronunciation-media-uses-a-narrow-host-supplied-ios-pack-adapter) and [route policy map](../../FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md) define host ownership and offline-island placement.
- [`HostBridgeCommandDelegate`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift), [`CrosswakeShellConfig`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShellConfig.swift), and [`BridgeChannel`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift) provide the registered host-command request/reply seam.
- [`HostLearningBundleProvider`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/phoenix_host/native/ios/CrosswakeProofLane/HostLearningBundleProvider.swift) and [`ProofLaneDriver`](https://github.com/szTheory/crosswake/blob/d0dbdf7bf196cea167ced3c50cf620bf3cb2452b/examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift) show host-private installed asset validation and AVFoundation playback; they are precedent, not generated-island coverage.
