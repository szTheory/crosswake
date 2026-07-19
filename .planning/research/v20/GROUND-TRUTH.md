# v20 "Native Controls Pack 1" — Ground Truth

Researched: 2026-07-12
Repo: `/Users/jon/projects/crosswake` (commit-tree at time of research, `main`)

This document resolves what already exists vs. what v20 must actually build. Every
claim below is backed by a file:line citation. Where evidence conflicts, it is
marked **AMBIGUOUS** with both sides shown.

---

## 0. The headline resolution (read this first)

The apparent contradiction in the brief is **not a contradiction** — it's two
different axes being described with overlapping vocabulary:

- **v3.1 (Phases 15-17, `.planning/milestones/v3.1-ROADMAP.md:177`)** shipped the
  **plumbing**: a typed Elixir contract + a real native delegate-dispatch
  implementation on both iOS and Android for `haptics`, `share`, `app_info`,
  `deep_link`, `permissions.status`, `notification_token`, and `file_picker`.
  This is true and verified in code (Section 2 below) — every one of these
  commands has a live `case`/`when` branch in both
  `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`
  and `packages/crosswake-shell-core-android/.../BridgeChannel.kt`.

- **Phase 152 / `guides/capability_map.md`** is describing **proof posture**, a
  narrower and stricter claim than "shipped plumbing exists." Of that same set,
  only `app_info`, `haptics`, `permissions.status`, and `deep_link` carry
  `proof_class: :merge_blocking` in the canonical capability catalog
  (`lib/crosswake/manifest/builder.ex:245-453`). `share` and `notification_token`
  carry `proof_class: :advisory` in that same catalog
  (`lib/crosswake/manifest/builder.ex:295`, `:323`) — meaning the plumbing exists
  and is wired to a real (if thin) route-tour assertion, but the maintainers do
  not consider that assertion strong enough evidence to call the capability
  "Available today." `guides/capability_map.md:21-22,56-58` reproduces exactly
  this: share/notification_token are "Advisory evidence"/"demoed", not "shipped."

- Genuinely new for v20: **alert/confirm, menu/action-button, toast/review-prompt**
  have **zero** presence anywhere in the stack — not in the capability catalog,
  not in `Crosswake.Bridge.Contract.commands/0`, not in either native
  `BridgeCommand` enum. These are the only "next-pack candidates" that require
  new native code, not just new proof (Section 1 row-by-row table, Section 2).

So the real v20 delta has three tiers, not one:
1. **Zero new work, already merge-blocking**: `app_info`, `haptics`,
   `permissions.status` (and `deep_link`, which isn't in Pack 1 scope). v20 can
   "harden" these only in the sense of adding more showcase coverage or docs —
   there is no missing engineering here.
2. **Proof-only work** (native code and Elixir contract already exist end-to-end):
   `share`, `notification_token` need a stronger, purpose-built merge-blocking
   route-tour + explicit per-platform support-truth statement to move from
   `advisory` → `merge_blocking`. No registry/contract/native changes required.
3. **Full new-capability work** (nothing exists): `alert/confirm`,
   `menu/action-button`, `toast/review-prompt`. These require the full checklist
   in Section 4, including native shell-core code changes and (per Section 5) a
   new SwiftPM/Maven shell-core release before any host app can use them.

---

## 1. Row-by-row capability table

| Capability | Declarable in route policy today? | In capability registry/allowlist? | Typed bridge command in `Crosswake.Bridge.Contract`? | iOS native impl? | Android native impl? | Fallback/deny path tested? | Proof posture today | v20 must build |
|---|---|---|---|---|---|---|---|---|
| **alert/confirm** | **No.** Not in `@public_route_capability_ids` (`lib/crosswake/manifest/builder.ex:12-28`) nor the validator's extended reserved set (`lib/crosswake/policy/validator.ex:9-20`). Declaring `capabilities: ["alert_confirm"]` on a route fails `Policy.Validator.validate_capabilities/2` with `"unknown capability"` (`lib/crosswake/policy/validator.ex:116-127`). | **No.** Absent from `capability_catalog/0` (`lib/crosswake/manifest/builder.ex:245-453`). | **No.** Absent from `@commands` (`lib/crosswake/bridge/contract.ex:11-22`) and from `@capability_commands` (`lib/crosswake/bridge/registry.ex:12-19`). | **No.** No `alert`/`confirm` case in `BridgeCommand` enum or `evaluate(_:completion:)` switch (`packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`, full-file grep negative). | **No.** Same negative grep on `packages/crosswake-shell-core-android/.../BridgeChannel.kt`. | N/A — nothing to fall back from. `guides/capability_map.md:70` fallback text is aspirational ("Until declared and proven, routes must keep Phoenix-owned confirmation surfaces") describing the *absence* of the capability, not a tested denial path. | `not_yet_proven` (`lib/crosswake/capability_map.ex:349`); category `next_pack_candidate` (`:342-353`). | Everything in the Section 4 checklist end-to-end: registry entry, contract command, native `BridgeCommand` case + delegate protocol on both platforms, conformance vectors, doctor/support-matrix wiring, docs, proof lane. Native shell-core rebuild required (Section 5). |
| **menu/action-button** | **No.** Same as above — no `menu`/`action_button`/`action_menu` id anywhere in `@public_route_capability_ids` or the validator's reserved extras. | **No.** Absent from `capability_catalog/0`. | **No.** Absent from `Bridge.Contract.@commands` and `Bridge.Registry.@capability_commands`. | **No.** No matching `BridgeCommand` case in `BridgeChannel.swift`. | **No.** No matching case in `BridgeChannel.kt`. | N/A. | `not_yet_proven`, `next_pack_candidate` (`lib/crosswake/capability_map.ex:354-366`). | Full Section 4 checklist + native rebuild. Additionally needs an **allowlist schema** for which actions/menu items a route may declare (today's DSL has no analog for "declare N labeled actions" — closest precedent is `commerce` or `transfers`, which are structured, not flat capability strings; see `lib/crosswake/policy/schema.ex:85-108`). This is new *schema* surface, not just a new capability id. |
| **haptics** | **Yes.** `"haptics"` is in `@public_route_capability_ids` (`lib/crosswake/manifest/builder.ex:15`); legacy id `"haptics.impact"` also recognized (`:288`, `compatibility_route_capability_ids` at `:35`). Used live in the example app: `capabilities: ["haptics.impact"]` (`examples/phoenix_host/e2e/route_tour.spec.ts:168`, asserted against the compiled router). | **Yes.** `capability_catalog/0` entry at `lib/crosswake/manifest/builder.ex:277-289`, `proof_class: :merge_blocking`, `rebuild: :none`. | **Yes.** `"haptics.impact"` in `@commands` (`lib/crosswake/bridge/contract.ex:13`) and `Bridge.Commands.Haptics` payload struct (`lib/crosswake/bridge/commands/haptics.ex`). | **Yes.** `.hapticsImpact` case, dispatches to `config.hapticsDelegate` (`BridgeChannel.swift:235-248`). | **Yes.** `HAPTICS_IMPACT` case, dispatches to `config.hapticsDelegate` (`BridgeChannel.kt:153-166`). | **Yes**, merge-blocking. `route_tour.spec.ts:195-201` asserts payload shape AND asserts fallback copy (`/Optional haptics|secondary|degradable/i`); runs inside `Offline-Sync E2E Gate` (`.github/workflows/offline-sync-e2e-gate.yml`), a registered required check (`merge-blocking-offline-sync-e2e`, see workflow header comment lines 1-33). AdminPilot approval flow proves server-authoritative mutation happens **before** haptics fires (`.planning/phases/149-saas-admin-showcase/149-VERIFICATION.md:20,44,52,65`). | `merge_blocking` (shipped, "Available today" — `guides/capability_map.md:12`, `lib/crosswake/capability_map.ex:146-153`). | **Nothing to build.** v20 can only "harden" via more showcase coverage/docs. This is the clearest false-alarm in the brief's suspicion. |
| **share** | **Yes**, mechanically — `"share"` is in `@public_route_capability_ids` (`builder.ex:18`) and is used live at `/bridge-proof` (`examples/phoenix_host/e2e/route_tour.spec.ts:234`, clicks a "Share" button). | **Yes.** `capability_catalog/0` entry at `lib/crosswake/manifest/builder.ex:290-301` — **but `proof_class: :advisory`**, not merge_blocking, despite `rebuild: :none`. | **Yes.** `"share.invoke"` in `@commands` (`bridge/contract.ex:16`); `Bridge.Commands.Share.Request` struct (`bridge/commands/share.ex`). | **Yes.** `.shareInvoke` case, dispatches to `config.shareDelegate` (`BridgeChannel.swift:323-335`). | **Yes.** `SHARE_INVOKE` case, dispatches to `config.shareDelegate` (`BridgeChannel.kt:207-218`). | **Partial.** `route_tour.spec.ts:230-245` (`proveBridgeRoute`) asserts only that the **browser constructs the correct outbound envelope** (`command`, `capability`, `route_id`, `origin`, `correlation_id` shape) — it does **not** assert a completed native round-trip, a real `ShareDelegate.invoke` call, or any per-platform share-sheet/cancel semantics. There is no dedicated native XCTest/JVM test for share behavior beyond generic envelope-mechanics vectors (`test/fixtures/bridge_contract_vectors.json` only vectorizes `app.info.get` + one `unknown.command` deny case — see Section 2.3). | `advisory` ("demoed" — `guides/capability_map.md:21`, `lib/crosswake/capability_map.ex:154-167`). **AMBIGUOUS-ADJACENT NOTE:** the `proveBridgeRoute` assertion *does* run inside the same merge-blocking `Offline-Sync E2E Gate` as haptics, yet the capability's own catalog field is still `:advisory`. This is a real, citable tension: CI enforces the JS-envelope assertion but the maintainers explicitly declined to call that "proof" of the capability (per `guides/capabilities.md:73` — share is only "honest" once Crosswake "publishes a truthful route-local share contract beyond compatibility-only command seams"). | **Proof-only work.** No registry/contract/native code changes needed. v20 needs: (a) a stronger route-tour that proves fallback behavior text (like haptics line 201) and ideally something closer to a completed round-trip/support-truth statement per platform, (b) flip `proof_class: :advisory` → `:merge_blocking` in `builder.ex:295` once that lands, (c) update `guides/capability_map.md` row. |
| **toast/review-prompt** | **No.** No `toast`, `review_prompt`, or `review-prompt` id anywhere in `@public_route_capability_ids`, `@compatibility_route_capability_ids`, or the validator's reserved extras. | **No.** Absent from `capability_catalog/0`. | **No.** Absent from `Bridge.Contract.@commands`/`Bridge.Registry.@capability_commands`. | **No.** No matching case in `BridgeChannel.swift`. | **No.** No matching case in `BridgeChannel.kt`. | N/A. | `not_yet_proven`, `next_pack_candidate` (`lib/crosswake/capability_map.ex:367-380`). | Full Section 4 checklist + native rebuild. `guides/capabilities.md` (whole file) has no "review-prompt" family precedent at all (App Store `SKStoreReviewController` / Play `ReviewManager` semantics — rate limits, no-guaranteed-display — are not modeled anywhere in the codebase; this needs new platform-policy language before it can even be a `bounded_bridge` family per the v20 handoff's own Open Decision #3, `152-V20-HANDOFF.md:124-125`). |
| **`permissions.status`** | **Yes.** `"permissions.status"` in `@public_route_capability_ids` (`builder.ex:17`). | **Yes.** `capability_catalog/0` entry at `builder.ex:302-317`, `proof_class: :merge_blocking`, scoped to `notifications` alias only (prerequisite list, `:309-313`). | **Yes.** `"permissions.status"` in `@commands` (`bridge/contract.ex:14`); `Bridge.Commands.PermissionsStatus` (referenced from `notification_token.ex:6`). | **Yes.** `.permissionsStatus` case, denies non-`notifications` alias explicitly (`BridgeChannel.swift:250-267`). | **Yes.** `PERMISSIONS_STATUS` case, same alias restriction (`BridgeChannel.kt:168-188`). | **Yes**, merge-blocking per catalog; alias restriction is enforced in both native switch statements as an explicit deny (`unavailable_capability` reason, "outside the shipped read-only permissions.status scope"). | `merge_blocking`, shipped ("Available today" — `guides/capability_map.md:13`, `lib/crosswake/capability_map.ex:168-181`). | **Nothing to build** for the read-only snapshot itself. v20 handoff explicitly scopes it to read-only only — permission *requests* stay out of scope (`152-V20-HANDOFF.md:32`, `guides/capabilities.md:63`). |
| **`notification_token`** | **Yes**, mechanically — `"notification_token"` in `@public_route_capability_ids` (`builder.ex:16`); legacy id `"push.notifications"` also recognized (`builder.ex:335`). | **Yes.** `capability_catalog/0` entry at `builder.ex:318-336` — **`package_class: :companion`** (not core), **`proof_class: :advisory`**, **`rebuild: :companion_required`**. | **Yes.** `"notifications.token.get"` in `@commands` (`bridge/contract.ex:15`); full typed `Bridge.Commands.NotificationToken.Request/Response` with provider allowlist (`apns`/`fcm` only, `bridge/commands/notification_token.ex:8,55-58`). | **Yes**, and unusually thorough: requires `permissions.status` for `notifications` to already report `granted` before resolving the token (prompt-free-by-design), denies with specific reasons (`notification_authorization_required`, provider-tagged `unavailable`/registration-state hints) (`BridgeChannel.swift:269-321`). | **Yes.** `NOTIFICATIONS_TOKEN_GET` case delegating to `NotificationTokenDelegate` with `Available`/`Denied` result types (`BridgeChannel.kt:190-205`). | **Partial**, same shape as share: envelope mechanics only in shared vectors; no per-platform test proving the granted-before-token gate or provider-tag correctness beyond unit-level delegate wiring. | `advisory` ("demoed", package owner `first_party_companion` — `guides/capability_map.md:22`, `lib/crosswake/capability_map.ex:182-196`). This is the one row where package ownership genuinely sits outside core (Chimeway is named as the companion in `152-V20-HANDOFF.md:33` and the capability_map route/evidence source `lib/crosswake/capability_map.ex:186`). | **Proof-only work**, same shape as share, but scoped stricter: v20 handoff explicitly forbids implying "APNs/FCM delivery" or "backend registration truth" (`152-V20-HANDOFF.md:18-19,33`). No registry/contract/native changes; needs a companion-scoped (Chimeway) route-tour/support-truth proof to move category, and the copy must stay "provider-tagged evidence" not "delivery." |

---

## 2. Direct code evidence backing the table

### 2.1 Contract layer (Elixir, core package)

- `Crosswake.Bridge.Contract.@commands` (`lib/crosswake/bridge/contract.ex:11-22`):
  ```
  app.info.get, haptics.impact, permissions.status, notifications.token.get,
  share.invoke, files.pick, transfer.download, transfer.export, transfer.import,
  transfer.upload.prepare
  ```
  This is the **entire** closed set of legal bridge commands today. There is no
  `alert.*`, `menu.*`, `toast.*`, or `review.*` entry.

- `Crosswake.Bridge.Registry.@capability_commands` (`lib/crosswake/bridge/registry.ex:12-19`)
  maps each command string to its capability-family id (e.g.
  `"haptics.impact" => "haptics"`, `"share.invoke" => "share"`). This is the
  runtime lookup Crosswake uses to check `capability_declared_on_route?/2`
  (`registry.ex:140-142`) before allowing a bridge call through.

- `Crosswake.Manifest.Builder.capability_catalog/0` (`lib/crosswake/manifest/builder.ex:245-453`)
  is the single source of truth for `proof_class`, `package_class`, `rebuild`,
  `prerequisites`, `denial`, and `fallback` per capability family. Every row in
  Section 1 above traces directly to a `[id: ..., proof_class: ..., rebuild: ...]`
  keyword list in this function.

- `Crosswake.Manifest.Builder.@public_route_capability_ids` (`lib/crosswake/manifest/builder.ex:12-28`)
  is the flat list of capability ids a route is allowed to declare in
  `capabilities: [...]`. `Crosswake.Policy.Validator.@known_capabilities`
  (`lib/crosswake/policy/validator.ex:9-20`) is built by unioning this list with
  `compatibility_route_capability_ids/0` plus a small extra reserved set
  (`audio, background_audio, background_sync, document_preview,
  generic_plugin_bus, lock_screen_controls, microphone, webrtc`) — none of which
  cover alert/confirm/menu/toast/review either. Declaring an unrecognized
  capability id produces a validator error: `"unknown capability #{inspect(capability)}"`
  with hint text pointing at the existing families only
  (`validator.ex:116-127`).

### 2.2 Route policy DSL shape

`capabilities:` is **not** a per-capability typed DSL — it's a flat
`[String.t()]` field validated generically via `validate_identifier`
(`lib/crosswake/policy/schema.ex:85-89`), then checked for membership in
`@known_capabilities` by the validator. This means "declarability" for any
*existing* family is just adding its string id to the list — no schema work
needed. But it also means there is **no existing precedent for a capability that
needs structured payload declared per-route** (e.g., "these 3 named menu
actions"); `commerce` (`schema.ex:90-93`) and `transfers`
(`schema.ex:104-108`) are the only precedents for structured, non-flat
capability-adjacent declarations. `menu/action-button` will likely need a
structured declaration in that style, not a bare string id — this is schema
surface, not just a registry addition.

### 2.3 Native shell-core implementations (iOS + Android)

Both `BridgeChannel.swift` and `BridgeChannel.kt` implement an **exhaustive**
`switch`/`when` over a **closed enum** (`BridgeCommand` on both platforms). Every
existing command (`app.info.get`, `haptics.impact`, `permissions.status`,
`notifications.token.get`, `share.invoke`, `files.pick`, `transfer.*`,
`connection.state.update`/`server.event.push` on iOS,
`server_event_push`/`server_state_update` on Android) has a real case that
either dispatches to a host-supplied delegate (`CrosswakeDelegates.swift` /
`CrosswakeDelegates.kt` — one shared delegate-protocol file per platform, not
one file per capability) or denies with `undeclared_capability`/
`unavailable_capability`. Grepping both files (and the whole
`packages/crosswake-shell-core-ios/Sources` and
`packages/crosswake-shell-core-android/src/main` trees) for
`alert|confirm|menu|toast|review` returns **zero matches** — confirmed via
`grep -rn` (empty output).

Cross-platform envelope-enforcement order is identical on both platforms and
matches `guides/bridge.md:38-51`: protocol/version compatibility →
route/active-route match → origin allowlist → command recognized + capability
matches → pack compatibility → capability-version-available check → per-command
delegate dispatch (`BridgeChannel.swift:180-394`, `BridgeChannel.kt:97-301`).

### 2.4 Conformance vectors are envelope-generic, not per-command

`test/fixtures/bridge_contract_vectors.json` (canonical; mirrored into
`packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/` and
`packages/crosswake-shell-core-android/src/test/resources/` by
`mix crosswake.contract.gen`, see `lib/mix/tasks/crosswake.contract.gen.ex:14,53-54`)
contains 13 vectors (`vec-001` through `vec-017`). **All but one use
`"command": "app.info.get"` as the representative command**; the only other
command exercised is the literal string `"unknown.command"` (a deliberate
denial case). The vectors test envelope mechanics (version floors, route
match, origin allowlist, pack compatibility, capability-version floors) — they
are intentionally command-agnostic and do **not** provide per-command proof
for haptics/share/permissions.status/notification_token payload correctness.
This is fine as a design (the enforcement pipeline genuinely is
command-agnostic) but it means "conformance vectors exist" cannot be cited as
capability-specific proof for any of the Section 1 rows.

### 2.5 v3.1 shipped-capability claim, verbatim

`.planning/milestones/v3.1-ROADMAP.md:177`:
> Ship the first low-frequency bounded native capability families (`haptics`,
> `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`,
> and `file_picker`) without widening into high-frequency bridge authority.
> Validated across Phases 15-17.

`.planning/milestones/v3.1-ROADMAP.md:34-35,50-53,69-72` breaks this into
per-phase implementation (iOS/Android handlers for haptics/share/app_info in
Phase 15; deep_link + permissions.status in Phase 16; notification_token +
file_picker in Phase 17). Line 121 is worth flagging too: *"Phase 15
`15-VERIFICATION.md` still records 3 human-needed device checks for share sheet
presentation, haptics hardware feedback, and runtime app-info fidelity."* This
is the real seed of today's advisory/merge-blocking gap for `share` — even at
ship time in v3.1, share's on-device behavior was flagged as **human-verify
only**, never automated. That gap was never closed; Phase 152 just made it
visible in the capability map instead of leaving it implicit.

---

## 3. What the capability map itself says the v20 gap is (verbatim)

`guides/capability_map.md:30-39` ("What v20 will do"):
> v20 Native Controls Pack 1 should stay route-local, typed, versioned,
> low-frequency, and fail-closed. It should prioritize bounded controls and keep
> capture/device, commerce/paywall productionization, offline sync/native
> storage, and operator dashboard work as named later packs.
>
> ### Next-pack candidates
> - **Fieldserv native capture handoff** — Next-pack candidate; Promote only
>   after Capture & Device Controls proof exists.
> - **Native alert and confirm affordances** — Next-pack candidate; Candidate
>   for v20 Native Controls Pack 1.
> - **Native menu and action-button affordances** — Next-pack candidate;
>   Candidate for v20 Native Controls Pack 1.
> - **Native toast and review prompt** — Next-pack candidate; Candidate for v20
>   Native Controls Pack 1 with strict platform policy truth.

And the handoff's own primary decision (`.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md:14-21`):
> Build Pack 1 around route-declared alert/confirm, menu/action-button,
> haptics, share, and toast/review prompt affordances. Treat
> `permissions.status` and `notification_token` as read-only snapshot or
> evidence surfaces only. Defer capture/device controls, production commerce,
> reusable sync/native storage, and operator dashboard work to named later
> packs.

Read together with Section 1, this means the handoff already (correctly)
distinguishes "hardened existing controls" (haptics, share) from "genuinely new
controls" (alert/confirm, menu/action-button, toast/review-prompt) — it just
doesn't spell out that the first two require zero-to-proof-only work while the
latter three require full native-rebuild engineering. That's the gap this
ground-truth doc closes for the roadmap.

---

## 4. The "unit of work" checklist — what a brand-new capability costs, mechanically

Using `haptics`/`share`/`notification_token` as the shipped precedent, adding
one new bounded-bridge capability family (e.g. `alert_confirm`) end-to-end
touches:

**Elixir core (`lib/crosswake/`):**
1. `bridge/contract.ex` — add the wire command string to `@commands` (e.g.
   `"alert.confirm.invoke"`), bump `@version` if the schema changes
   (`bridge/contract.ex:10-22`).
2. `bridge/registry.ex` — add `"alert.confirm.invoke" => "alert_confirm"` to
   `@capability_commands` (`registry.ex:12-19`).
3. `bridge/commands/alert_confirm.ex` (new file) — typed `Request`/`Response`
   payload structs, following `bridge/commands/haptics.ex` or
   `bridge/commands/notification_token.ex` as the pattern.
4. `manifest/builder.ex` — add an entry to `capability_catalog/0` (id, family,
   owner, package_class, proof_class, rebuild, prerequisites, denial, fallback,
   guide link) and add the id string to `@public_route_capability_ids`
   (`builder.ex:12-28,245-453`). **Choosing `rebuild:` here is the single most
   consequential decision** — see Section 5.
5. `policy/validator.ex` — no edit needed *if* the id was added to
   `public_route_capability_ids` (the known-capabilities set derives from it
   automatically, `validator.ex:9-20`). If the capability needs structured
   payload (e.g., named menu actions) rather than a flat string, `policy/schema.ex`
   needs a new typed field (precedent: `commerce`/`transfers`,
   `schema.ex:85-108`) and `policy/validator.ex` needs a new
   `validate_*` clause.
6. `doctor/doctor.ex` — largely auto-derives command posture from
   `Registry.allowed_commands()` and `manifest.capability_registry`
   (`doctor.ex:1380-1409`); verify no capability-specific doctor rule needs a
   manual addition (compare to the existing `background_sync`/
   `generic_plugin_bus` unsupported-capability doctor findings at
   `doctor.ex:503-524`, which are hand-written per-capability exceptions).
7. `support_matrix/support_matrix.ex` — `SupportMatrix.canonical/1` is fed
   `capability_registry` directly (`manifest/builder.ex:55-60`), so the support
   matrix table should update automatically; confirm via
   `test/crosswake/support_matrix/support_matrix_test.exs`.
8. `capability_map.ex` + `capability_map/renderer.ex` — flip the row from
   `next_pack_candidate`/`not_yet_proven` to the appropriate new category once
   proof lands; `test/crosswake/capability_map/capability_map_test.exs` and
   `test/crosswake/guides/capability_claims_test.exs` are the drift guards that
   will fail if the guide and the module disagree.

**Native (both platforms — required even for a "core"-owned family, because the
bridge dispatch lives in the native shell, not in Elixir):**
9. iOS: `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`
   — add a `BridgeCommand` case + `capability` mapping + a switch branch that
   checks `capabilityAvailable`, looks up a new delegate, dispatches, and
   returns `ok`/`deny`.
10. iOS: `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeDelegates.swift`
    — add the new delegate protocol (shared file, not a new file per
    capability) and wire it into `CrosswakeShellConfig.swift` (`weak var
    ...Delegate`, init parameter, capability-advertisement list at
    `CrosswakeShellConfig.swift:32-39`).
11. Android: same shape in `BridgeChannel.kt`, `CrosswakeDelegates.kt`,
    `CrosswakeShellConfig.kt`.
12. `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift`
    and `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt`
    — add unit coverage for the new delegate dispatch and denial paths.

**Contract-derived artifacts (regenerated, not hand-edited):**
13. Run `mix crosswake.contract.gen` to refresh
    `test/fixtures/bridge_contract_vectors.json` (+ its two native mirrors) and
    `docs/_contract_snippet.md` if `Bridge.Contract.@version` changed
    (`lib/mix/tasks/crosswake.contract.gen.ex:1-55`). Add capability-specific
    vectors by hand if the generic envelope vectors don't already exercise the
    new command's unique payload shape.

**Docs:**
14. `guides/bridge.md` — add the command to the public command list, the
    "public families" line, and denial-reason list if new denial reasons are
    introduced (`guides/bridge.md:6-19,75-84`).
15. `guides/capabilities.md` — add the family to the Phase-11 inventory, assign
    an ownership-rubric class (`bounded_bridge`/`native_screen`/etc.), a package
    class, and update "First Public Example Set"/"Package Class Examples"
    (`guides/capabilities.md:22-49,193-207`).
16. `guides/capability_map.md` — regenerate from `Crosswake.CapabilityMap`
    once the row's category changes.
17. `guides/support_matrix.md` — regenerate via
    `Crosswake.SupportMatrix.Renderer` (`support_matrix/renderer.ex`).

**Proof lane (showcase / example host):**
18. `examples/phoenix_host/` — add a route (or extend an existing one) that
    declares the capability, exercises it through a real user flow (not just a
    button click), and asserts fallback copy — follow the AdminPilot-haptics
    pattern (`149-VERIFICATION.md` + `route_tour.spec.ts:161-217`), not the
    thinner bridge-proof-share pattern (`route_tour.spec.ts:230-246`).
19. `examples/phoenix_host/e2e/support/evidence_manifest.ts` — add an evidence
    row per D-15/D-16 of `152-CONTEXT.md:37-40`.
20. Confirm the new/extended spec runs inside a **merge-blocking** required
    check (today that's `Offline-Sync E2E Gate` /
    `merge-blocking-offline-sync-e2e`, `.github/workflows/offline-sync-e2e-gate.yml`)
    — a spec that merely exists in `route_tour.spec.ts` is not sufficient by
    itself to earn `proof_class: :merge_blocking` per the maintainers' own
    share/notification_token precedent (Section 1, share row).

This is roughly a 20-point checklist spanning 3 languages (Elixir, Swift,
Kotlin) and 2 release surfaces (Hex + SwiftPM/Maven) per new capability family.
The existing families (haptics/share/etc.) each took a full v3.1 phase
(Phases 15-17) to ship under this same checklist shape.

---

## 5. Does adding a native bridge command require a new native shell-core release? Can a control be added without a native rebuild?

**Short answer: yes, a rebuild is required for any genuinely new command, and no,
there is no way around it with the current architecture.**

The dispatch mechanism on both platforms is a closed, exhaustive
`switch`/`when` over a fixed enum compiled into the shell-core binary
(`BridgeCommand` in `BridgeChannel.swift:8-19` and `BridgeChannel.kt:9-21`).
There is no dynamic/reflective dispatch, no plugin registry, no JS-evaluable
native handler — this is by design (`guides/capabilities.md:112-127`, "Family
Naming Rules"/"Package Boundary Rules": no generic plugin bus). Adding
`alert.confirm.invoke` (or any new command) means editing and recompiling
`CrosswakeShellCore` on both platforms; there is no host-side-only or
manifest-only way to add real behavior for a command that isn't already an
enum case with a switch branch.

This is exactly what `Crosswake.RuntimeLine.RebuildPolicy` formalizes as
**the closed set** governing OTA-safety
(`lib/crosswake/runtime_line/rebuild_policy.ex:1-133`):

- `Capability.rebuild` is a 3-value enum: `:none` | `:native_required` |
  `:companion_required` (`rebuild_policy.ex:80-89` doctests).
- `RebuildPolicy.classify(:capability_family_add, capability)` returns
  `:ota_safe` only when `capability.rebuild == :none`; otherwise
  `{:rebuild_required, :native_shell}` or `{:rebuild_required, :companion_shell}`
  (`rebuild_policy.ex:103-110`).
- The module's own doc is explicit that this is **derived from data, not a
  label** — "Never classify by change-class label alone; always key off
  `Capability.rebuild`" (`rebuild_policy.ex:14-19`) — precisely because a new
  capability family is *always* a `capability_family_add` change class, and
  whether it's OTA-safe depends entirely on whether the native dispatch code
  for it already shipped.
- `guides/native_shell.md:57-70` ("Do I need to rebuild?") documents the same
  four-tier action-class taxonomy in prose: `docs-only`,
  `core-only/no native rebuild`, `compatibility-bump only`, `native or
  companion rebuild required` — the last of which "applies when shell
  templates, native code, entitlements, permissions, platform configuration, or
  native dependencies change," which is unavoidably true for
  alert/confirm/menu/action-button/toast/review-prompt.

Why `haptics`/`share`/`app_info`/`permissions.status` all carry `rebuild: :none`
today (`builder.ex:270,283,296,308`): their native dispatch code **already
shipped** in the currently-published shell-core release. Declaring the
capability on a *new* route is OTA-safe (no rebuild) precisely because the
binary the host already has installed already knows how to execute
`haptics.impact`/`share.invoke`/etc. This is not true for alert/confirm,
menu/action-button, or toast/review-prompt — for those, `rebuild:` in their
future `capability_catalog` entries would have to be `:native_required` (or
`:companion_required` if scoped to a first-party companion), because no
currently-published shell-core binary contains the dispatch code.

**This directly answers the SEED-003 (iOS mirror token) blocking question:**
adding any of the three genuinely-new Pack 1 controls requires publishing a new
`crosswake-shell-core-ios` (SwiftPM) and `crosswake-shell-core-android` (Maven)
release before any host app can use them — it is not optional and there is no
"declare it in Elixir only" escape hatch. `share` and `notification_token`
hardening, by contrast, needs **no** native rebuild (their `rebuild: :none`/
already-shipped native code stands) — only Elixir-side proof-class promotion
and doc updates. So SEED-003 only becomes a hard blocker once v20 scope
includes alert/confirm, menu/action-button, or toast/review-prompt; it is not a
blocker for a "harden haptics + promote share/notification_token to
merge-blocking" -only slice of Pack 1.

---

## 6. The "bounded bridge" ceiling — what makes a command legal

`guides/bridge.md:1-19`: *"Crosswake exposes one typed, versioned,
request/reply-only bridge... Everything else is denied. The bridge is not
navigation authority, not render synchronization, and not a generic plugin
bus."*

`guides/route_policy.md:70-100` (the canonical `:live_view` + bounded-bridge
pattern) states the rule most concretely: *"Use this when Phoenix owns the
route but one low-frequency native action improves the experience. The native
side answers a typed request/reply command; it does not drive navigation,
rendering, or data authority."* And the explicit boundary line: *"if a flow
needs continuous client authority, it is not a bounded bridge flow. Move it
toward an offline island or native screen"* (`route_policy.md:99-100`).

`guides/capabilities.md:11-20` gives the ownership rubric that decides whether
a candidate can even be `bounded_bridge`:
> Use `bounded_bridge` only when the route stays Phoenix-owned and the native
> side is answering one narrow semantic request.

Concretely, the ceiling has five load-bearing properties, each independently
enforced somewhere in code:
1. **Low-frequency** — request/reply only, never a stream (no persistent native
   authority loop; enforced by the architecture itself — there's no
   subscribe/push primitive in `Bridge.Contract`, only `new_request`/`new_reply`
   at `bridge/contract.ex:114-146`).
2. **Semantic, not generic** — commands are named `app.info.get`,
   `haptics.impact`, etc., never a generic `invoke(method, args)`
   (`guides/capabilities.md:112-118`, "Family Naming Rules").
3. **Typed** — every request/reply is a `defstruct` with `@enforce_keys`
   (`bridge/contract.ex:24-69`), not a bag of arbitrary JSON.
4. **Versioned** — `protocol`/`version`/`native_runtime_version` are checked via
   `SemVer.compatible` before any dispatch on both platforms
   (`BridgeChannel.swift:181-186`, `BridgeChannel.kt:101-105`).
5. **Route-local** — every request carries `route_id`/`active_route_id` and is
   denied with `inactive_route` if they don't match the live session
   (`bridge/contract.ex:42-43`; enforced identically in both native
   `evaluate()` implementations).

Any candidate capability that would violate any of these five (continuous
authority, generic dispatch, untyped payload, unversioned, or route-agnostic)
gets classified `native_screen`, `backend_seam`, or `defer` instead of
`bounded_bridge` (`guides/capabilities.md:7-20`). Alert/confirm,
menu/action-button, and toast/review-prompt are being proposed as
`bounded_bridge` in the v20 handoff (`152-V20-HANDOFF.md:27-33`, package owner
`core` in the capability-map rows, `lib/crosswake/capability_map.ex:348,361,374`)
— which is architecturally consistent with the ceiling (they're one-shot,
semantic, typeable, versionable, route-scoped asks) but menu/action-button in
particular will stress rule #2/#3 if it needs a variable-length list of
labeled actions per route (see the schema note in Section 2.2/4.5) — that's a
real design question for the roadmap, not a resolved one.

---

## 7. Open items / things the roadmap should not assume are settled

- **Menu/action-button payload shape is undesigned.** Unlike haptics (single
  `style` string) or share (`url`/`text`/`title`), a "declare allowed actions"
  capability implies either (a) a fixed small enum of actions (cheap, fits the
  existing flat-capability-string pattern) or (b) a per-route structured list
  (expensive, needs new `policy/schema.ex` surface akin to `commerce`/
  `transfers`). The capability map and handoff do not decide this
  (`152-V20-HANDOFF.md:28` just says "Route policy must declare allowed actions
  and fallback behavior" — no shape given).
- **Toast/review-prompt platform-policy language does not exist yet.** No file
  in the repo models App Store/Play Store review-prompt rate-limiting or
  guaranteed-non-display semantics; `152-V20-HANDOFF.md:124-125` lists this as
  an explicit open decision (#3), not a settled one.
- **The "advisory → merge-blocking" promotion criteria for share/notification_token
  are not formally specified** anywhere as a checklist (only prose intent in
  `guides/capabilities.md:73` for share, and the v20 handoff's general
  Promotion Criteria section `152-V20-HANDOFF.md:78-90`, which is generic
  across all Pack 1 candidates, not share/notification_token-specific).
- **AMBIGUOUS**: whether `share`'s existing merge-blocking CI test
  (`proveBridgeRoute`, inside the required `Offline-Sync E2E Gate`) should
  itself be read as sufficient to promote `proof_class` to `:merge_blocking`
  once the fallback-copy assertion (like haptics') is added, or whether the
  maintainers intend something stronger (an actual native round-trip proof,
  which the current Playwright-only harness cannot provide since there's no
  real WKWebView/native shell attached in CI). The docs do not resolve this;
  it's a design decision the roadmap needs to make explicitly rather than
  infer.

---

## Summary of citations by file (for quick reference)

- `guides/capability_map.md` — public capability-map guide (rendered)
- `guides/capabilities.md` — capability family taxonomy, ownership rubric, package classes
- `guides/bridge.md` — bounded bridge contract, envelope, enforcement order, denial reasons
- `guides/route_policy.md` — route DSL patterns incl. bounded-bridge-affordance example
- `guides/native_shell.md` — rebuild decision tree, activation posture
- `lib/crosswake/capability_map.ex` — canonical `CapabilityMap.Row` data (source of the guide)
- `lib/crosswake/manifest/builder.ex` — `capability_catalog/0`, `@public_route_capability_ids`, capability registry construction
- `lib/crosswake/policy/validator.ex` — `@known_capabilities`, capability-declaration validation
- `lib/crosswake/policy/schema.ex` — route DSL field types (`capabilities`, `commerce`, `transfers`)
- `lib/crosswake/bridge/contract.ex` — `Bridge.Contract` typed request/reply envelope + `@commands`
- `lib/crosswake/bridge/registry.ex` — `@capability_commands`, manifest-backed allowlist lookup
- `lib/crosswake/bridge/commands/{haptics,share,notification_token}.ex` — typed payload structs
- `lib/crosswake/runtime_line/rebuild_policy.ex` — OTA-safe vs. rebuild-required derivation
- `lib/crosswake/doctor/doctor.ex` — command posture / capability diagnostics
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/{BridgeChannel,CrosswakeShellConfig,CrosswakeDelegates}.swift`
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/{BridgeChannel,CrosswakeShellConfig,CrosswakeDelegates}.kt`
- `test/fixtures/bridge_contract_vectors.json` + native mirrors — conformance vectors (envelope-generic)
- `lib/mix/tasks/crosswake.contract.gen.ex` — vector/fixture regeneration mechanism
- `examples/phoenix_host/e2e/route_tour.spec.ts` — merge-blocking route-tour proof (haptics vs. share depth comparison)
- `.github/workflows/offline-sync-e2e-gate.yml` — the actual required/merge-blocking CI gate
- `.planning/milestones/v3.1-ROADMAP.md` — original v3.1 shipped-capability claim (Phases 15-17)
- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` — v20 decision summary, candidates, exclusions, promotion criteria
- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-CONTEXT.md` — Phase 152 decisions D-01..D-34
- `.planning/phases/149-saas-admin-showcase/149-VERIFICATION.md` — AdminPilot haptics proof evidence
- `.planning/phases/150-field-service-showcase/150-07-SUMMARY.md` — Fieldserv capture/scanner/media deferred-scope evidence
