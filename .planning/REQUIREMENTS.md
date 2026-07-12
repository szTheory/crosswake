# Requirements: v20.0 Native Controls Pack 1

**Milestone goal:** Ship the typed control-contract seam that every native-controls pack
rides on, and prove it with the one control that genuinely needs to be native — replacing
the ad-hoc `<script>` escape hatch adopters use today with a bounded, fail-closed,
route-declared affordance.

Research synthesis: `.planning/research/v20/SUMMARY.md`.

## v1 Requirements

### MIRROR — iOS mirror unblock (prerequisite)

Native bridge dispatch is a closed `switch` over a fixed enum compiled into the shipped
shell-core binaries, so any new control requires a new native release. The
`crosswake-shell-core-ios` SwiftPM mirror is stuck at `v0.1.2` while core and Android are
at `0.2.0` — until that is fixed, a new shell-core release cannot reach iOS adopters at
all. This category must land before MENU.

- [ ] **MIRROR-01**: The `crosswake-shell-core-ios` SwiftPM mirror carries a `v0.2.0` tag matching the live Hex and Maven `0.2.0` core, so iOS adopters can resolve the current shell core.
- [ ] **MIRROR-02**: A native shell-core release publishes to Hex, Maven, and the iOS mirror in one run, and a mirror-push failure surfaces as a hard, named CI failure instead of a silent 403.

### CTRL — the control-contract seam (load-bearing)

The reusable machinery. Once this exists, controls 4..N are cheap, repeatable work.

- [ ] **CTRL-01**: A LiveView can invoke a bounded control via `Crosswake.Bridge.push/3` and receive a typed reply correlated to the invocation.
- [ ] **CTRL-02**: No-shell, too-old-shell, and undeclared-capability all resolve to one typed `Crosswake.Shell.Denial` reply, so an adopter writes one `handle_event` branch rather than three.
- [ ] **CTRL-03**: A route invoking a capability it never declared in route policy fails loudly and names the missing declaration, rather than silently doing nothing.
- [ ] **CTRL-04**: The bridge command vocabulary stays closed and named — host-registrable or dynamic command registration is structurally impossible.
- [ ] **CTRL-05**: Every control declares its rebuild class, and a native-rebuild-required release is labeled as such in the changelog, the support matrix, and doctor guidance.

### MENU — the first genuinely-new native control

The reply-path exemplar. Unanimous across research lenses as the strongest new control:
the literal "feels wrong in a webview" moment, zero platform-policy risk, clean fallback.

- [ ] **MENU-01**: A route declares menu/action-button affordances in route policy, with allowed actions and fallback behavior explicit.
- [ ] **MENU-02**: The iOS and Android shell cores render a native menu and return the chosen action as a typed reply.
- [ ] **MENU-03**: Native menu actions carry VoiceOver and TalkBack semantics and native dismiss gestures.

### FALL — host-owned fallbacks (no component tier)

Crosswake ships no component library — that is a deliberate anti-feature. But fallbacks
must look right on day one, so they are generated and owned by the host, never imported.

- [ ] **FALL-01**: `mix crosswake.gen.native_controls_ui` scaffolds host-owned, brand-tokenized fallback components (confirm modal, action menu) as verbatim-copy files the adopter owns outright.
- [ ] **FALL-02**: Generated fallbacks render correctly in light and dark, trap focus, and meet the existing contrast gates; no importable `Crosswake.UI.*` module exists.

### HRDN — harden what already shipped

- [ ] **HRDN-01**: The AdminPilot haptics call runs through `Bridge.push/3`; the hand-rolled `<script>` IIFE with no reply path is gone.
- [ ] **HRDN-02**: Haptics respects the operating system's reduce-motion and haptics accessibility settings.
- [ ] **HRDN-03**: The iOS share sheet cannot crash on iPad — a missing popover anchor is guarded rather than left to the OS.

### EVID — read-only surfaces stay honest

- [ ] **EVID-01**: `permissions.status` documentation and support truth never imply permission *request* authority; it is a read-only snapshot.
- [ ] **EVID-02**: `notification_token` documentation and support truth never imply delivery assurance; it is provider-tagged evidence only.

### PROOF — the lanes

- [ ] **PROOF-01**: A merge-blocking browser route-tour lane proves fallbacks render, fail closed when undeclared, and never silently degrade.
- [ ] **PROOF-02**: `share` and `notification_token` move from advisory to merge-blocking proof posture.
- [ ] **PROOF-03**: Menu behavior is proven from the committed `bridge_contract_vectors.json` on both natives without a simulator or emulator.
- [ ] **PROOF-04**: The catalog line ships as a merge-blocking structural test — a proposed control failing any of its six criteria fails CI.

## Future Requirements (deferred)

- **Review prompt** — deferred until it can ship as a `requested`-only reply with no button and no success signal. Both Apple and Google forbid CTA-triggered prompts and provide no completion callback.
- **Capture & Device Controls pack** — camera, scanner, document scan, media upload, permission-request UX, evidence availability.
- **Commerce/Paywall productionization** — storefront adapters, entitlement refresh, purchase-evidence ingestion.
- **Offline Sync / Native Storage productization** (SYNCP-01, NTV-01) — native storage budgets, durable journals, outboxes, retry, conflict handling.
- **`crosswake_dashboard`** (DASH-01) — operator route/support/telemetry/audit/release inspection surface.
- **SEED-004** — companion clean-room proof harness cosmetics. The real defect was fixed in v18 Phase 144; the harness only runs for companion Hex publishes, a surface v20 does not touch.

## Out of Scope

- **A native `toast` capability** — iOS ships no toast primitive, so a cross-platform native toast overclaims by construction. Toasts are LiveView-owned UI.
- **A native `alert`/`confirm` bridge family** — a branded, focus-trapped, route-tour-provable LiveView modal is better than an unbranded OS alert on a route Phoenix already owns. It ships as a generated fallback (FALL-01), not a bridge command.
- **An importable `Crosswake.UI.*` component tier** — fallbacks are generated, host-owned, verbatim-copy files, following the `gen.offline_ui` precedent.
- **A `crosswake_controls` companion package** — controls have no external SDK or optional dependency to gate, which is what defines a companion in this family. They stay in core alongside the v3.1 command families.
- **Host-registrable, dynamic, or high-frequency bridge commands** — the vocabulary stays closed and named, enforced by PROOF-04.
- **Expanding the haptics pattern vocabulary** — `haptics.impact` shipped in v3.1 and is sufficient.

## Traceability

Filled by the roadmap.
