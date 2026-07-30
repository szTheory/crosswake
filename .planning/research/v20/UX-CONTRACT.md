# v20.0 Native Controls Pack 1 — UX / Creative-Direction / User-Psychology Contract

**Lens:** UX, JTBD, brand voice, accessibility.
**Scope:** the 7 Pack 1 candidates named in `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md`: alert/confirm, menu/action-button, haptics, share, toast/review prompt, `permissions.status`, `notification_token`.
**Method:** two distinct users (USER A = the Phoenix developer/adopter; USER B = the end user), JTBD interrogation per control, brutal skepticism about whether "native" actually beats "well-styled web," and the existing brand/support-truth vocabulary as the only vocabulary this document is allowed to extend.

This document does not decide implementation files, bridge wire formats, or package boundaries. It decides: which controls have a real native JTBD, what happens when native is absent, what the fallback experience is (for both users), what the API/microcopy vocabulary should be, and which controls should lead Pack 1.

---

## 0. The single hardest tension (read this first)

Crosswake's brand pillar is **"no hidden bridge magic"** and its design pillar is **"Crosswake must not ship an opinionated visual component library."** But four of the seven candidates (alert/confirm, menu, toast, and the LiveView-modal fallback for all of them) require *some* rendered UI to exist in the Phoenix-owned fallback path, and that UI has to look right, in both themes, at 44px tap targets, with focus traps — i.e. it has to look like a **product**, not a stub.

The tension: the moment Crosswake ships a good-looking confirm modal or action-menu component, adopters will use *that* even on routes that never touch the native bridge, because it's the best available styled primitive in the box. That is exactly the "Crosswake becomes a UI kit" mission creep the brand pillars warn against — the no-importable-module-tier rule (FALL-02; Phase 154's D-31; `prompts/crosswake-elixir-oss-dna.md:119-124`'s "Use generators when adopters need editable app code"). **(D-57 correction: BRAND-SPEC's visual-identity section (section seven) is the design-TOKEN tier rule — primitive vs. semantic tokens — not this module-level rule; the citation above is the correct authority.)**

The resolution used throughout this document (detailed in §3) is: ship the fallback surfaces as **verbatim-copy, host-owned generator output** (the same contract as `mix crosswake.gen.offline_ui`), never as an importable runtime component module. The generator produces files the adopter owns and can diverge from on line one. This keeps the "no component tier" promise literally true (nothing is `import`-able from `:crosswake` at runtime) while still giving adopters a correct-by-default, token-wired starting point instead of a blank page. It is the same trick Crosswake already plays with `offline.css` — a real answer already exists in this codebase, it just hasn't been generalized past offline UI yet.

---

## 1. Per-control JTBD interrogation

For each candidate: who invokes it, where the input comes from, what USER B gets, when it fires, and the brutally skeptical question — does native actually beat a good LiveView surface here?

### 1.1 Haptics — `haptics` family, `haptics.impact` command (already shipped, Pack 1 hardens it)

- **Who invokes:** Phoenix LiveView, server-side, in the success branch of a `handle_event` after a mutation has already committed (see `approval_live.ex` — haptics fires only after `{:ok, approved}`).
- **Where the input comes from:** no user input at all. It is a one-shot signal Phoenix sends to the shell; payload is a style enum (`light | medium | heavy | success | warning | error`), not user data.
- **What USER B gets:** a physical tap on the device.
- **When it fires:** post-success only, never pre-commit, never gating.
- **Does native actually beat web here?** Yes, unambiguously. There is no web equivalent that works on iOS: the Vibration API is Android-Chrome-only and absent from iOS Safari/WKWebView entirely. This is the one candidate where "native" isn't a stylistic upgrade over a web option — the web option **does not exist on one of the two platforms**. This is the strongest possible native JTBD in the pack.
- **Vocabulary:** family `haptics`, command `haptics.impact`, posture `post_success_optional`. No changes needed to existing naming — Pack 1 hardens the contract that already shipped.

### 1.2 Menu / action-button affordances — proposed `action_menu` family

- **Who invokes:** USER B, tapping an overflow ("...") icon or long-pressing a list row that Phoenix rendered.
- **Where the input comes from:** the route policy declares an **allowlist** of actions (id, label, destructive?, icon hint) at compile time; nothing about the menu contents is decided at runtime by native code.
- **What USER B gets:** an OS-native context menu / action sheet (iOS `UIMenu`/`UIAlertController`, Android `PopupMenu`/`BottomSheet`) drawn with system chrome, system dismiss gestures, system positioning.
- **When it fires:** on-demand tap, low frequency, one round trip (present → selected action id → Phoenix executes the actual mutation).
- **Does native actually beat web here?** Yes, and this is the second-strongest case, but for a different reason than haptics. A LiveView-rendered dropdown *can* visually approximate an action sheet, but the seams show immediately: no native blur/vibrancy backdrop, no native open/close haptic, wrong dismiss gesture (native sheets respond to a system swipe-down; a WebView `<div>` needs its own backdrop-click handler that users occasionally beat with a browser back-swipe instead), inconsistent placement conventions (Android bottom sheet vs iOS top-anchored menu — a web dropdown does not auto-adapt per platform the way a native menu does), and VoiceOver/TalkBack treat a native menu as a first-class semantic control automatically, where a web dropdown needs `role="menu"` wiring by hand to get the same rotor/announcement behavior. This is the literal "moment that feels wrong in a webview" the brief names. Rank: strong.
- **Vocabulary:** family `action_menu`, command `action_menu.present`. Payload: `actions: [%{id, label, destructive: boolean, icon: optional}]`. Reply: `{selected_action_id}` or `{dismissed: true}` as a distinct outcome (never conflate "dismissed" with "selected the first action" — same discipline the bridge guide already applies to `file_picker` cancellation).

### 1.3 Share — `share` family, `share.invoke` command (already an advisory row; Pack 1 promotes it)

- **Who invokes:** USER B, tapping an explicit "Share" affordance on a Phoenix-owned route (a generated link, an export, a report).
- **Where the input comes from:** Phoenix generates the shareable payload (URL, text, or a staged file from `transfer.export`) server-side and hands it to the bridge.
- **What USER B gets:** the OS share sheet with every installed share target (Messages, Mail, AirDrop, WhatsApp, Save to Files, copy).
- **When it fires:** on-demand tap.
- **Does native actually beat web here?** This is the most genuinely contested one, and it deserves the brutal-skepticism treatment the brief asks for. The **Web Share API** (`navigator.share`) exists in mobile Safari and Chrome/Android WebView and would, in principle, let a LiveView page trigger a real OS share sheet with zero bridge round trip and zero capability declaration. So why go through Crosswake's bridge at all?
  - Reason it's still worth it: `navigator.share` support inside an **embedded WKWebView/Chrome Custom Tab shell** (as opposed to the top-level mobile browser) is inconsistent across iOS versions, injected CSP policies, and whether the shell disables it deliberately for security. A host cannot rely on it being present just because the underlying engine is WebKit/Blink.
  - Reason it's still worth it #2: content staged via `transfer.export` (a native file handle) cannot always cross into `navigator.share` from inside a sandboxed WebView the way it can from native code calling `UIActivityViewController` directly with the real file handle.
  - Reason it's *not* obviously worth it: for the common case — sharing a plain URL or text string — a host could just call `navigator.share` directly and skip Crosswake's involvement entirely, with a `navigator.clipboard.writeText` fallback for unsupported browsers. Nothing about that requires route policy or a manifest capability.
  - **Verdict:** legitimate, but it is "harden a flaky/inconsistent web API into a guaranteed native path with fail-closed telemetry," not "give USER B something the web literally cannot do." Rank: medium. This matches the existing capability-map posture (`advisory`) — the row is honest about its own modesty and Pack 1 should keep it that way rather than overclaiming.
- **Vocabulary:** keep existing `share` family / `share.invoke` command; no renaming.

### 1.4 Alert / confirm — proposed `confirm` family (recommend: do NOT ship as a bridge family)

- **Who invokes:** Phoenix, before committing a destructive or consequential mutation (delete, remove member, cancel subscription).
- **Where the input comes from:** Phoenix supplies title/body/destructive-flag; the "input" that matters (the user's yes/no) has to travel back through a bridge round trip before Phoenix can act on it.
- **What USER B gets:** either an OS `UIAlertController`/`AlertDialog`, or (recommended) a Phoenix-owned, brand-tokenized modal.
- **When it fires:** pre-commit, blocking.
- **Does native actually beat web here? Brutally: no, not for a route Phoenix already owns.** Run the skeptic's argument all the way through:
  - A LiveView confirm modal can be **branded** (Wake/Brass/Rust tokens, Space Grotesk heading, Atkinson body) where a native alert is unbranded OS chrome that looks identical to every other app's delete-confirmation dialog. Brand distinctiveness is a real product asset Crosswake would be throwing away for zero functional gain.
  - A LiveView modal is **testable in the browser** with Playwright/route-tour proof — exactly the merge-blocking proof discipline this whole project is built on. A native alert can only ever be `advisory evidence` (simulator/device only), which is a strictly worse proof posture for a route that Phoenix already owns end to end.
  - A LiveView modal has **no failure mode**. A bridge-routed confirm introduces a whole new fail-closed decision tree (`undeclared_capability`, `unavailable_capability`, timeout, compatibility mismatch) for a yes/no dialog that a `<dialog>` element or a `phx-click` handler answers with zero new failure surface.
  - The one honest counterargument: a native alert is a true OS-level modal that cannot be dismissed by an accidental WebView back-swipe gesture mid-decision, and it visually asserts "this is serious" via system chrome the user has learned to trust. That is real, but it is a marginal safety net, not a job the web version cannot do (focus-trap + `beforeunload`-style guard + `role="alertdialog"` gets most of the way there).
  - **Verdict: weak native JTBD. This is the closest thing to cargo-cult in the pack.** Recommend Crosswake explicitly **not** add a `confirm`/`alert` bridge family in Pack 1. Ship the branded LiveView confirm modal as a generator recipe instead (see §3), and say so directly in the docs so adopters don't go looking for a native alert bridge that doesn't exist.

### 1.5 Toast / review prompt — bundle needs to be split; opposite native-necessity profiles

The handoff and capability map both list this as one candidate. It should not be evaluated as one thing — the two halves have opposite verdicts.

**Toast half:**
- **Who invokes:** Phoenix, after a semantic event (link copied, draft saved, action queued).
- **What USER B gets:** an ephemeral, non-blocking status banner.
- **Does native actually beat web here?** No — and there's a sharper reason than "LiveView can do this too": **iOS has no native toast primitive at all.** Android has `Toast`/`Snackbar`; iOS does not — any "native toast" on iOS is a custom overlay the shell would have to draw itself, which is strictly *worse instrumented* than a CSS toast component (no accessibility API wiring, no dark-mode token awareness, no reduced-motion respect unless someone builds all of that by hand in Swift). Building a native toast on iOS to imitate a web toast that already looks right is definitionally cargo-cult. **Verdict: cut. Do not ship as a bridge family.**

**Review prompt half:**
- **Who invokes:** Phoenix, when it decides "this is a good moment" (e.g., after N successful completions of the core loop).
- **What USER B gets:** the OS *may* show `SKStoreReviewController` (iOS) or the Play In-App Review flow (Android) — or may show nothing at all. Both platforms rate-limit this aggressively (Apple: a handful of times per year, no app control over timing) and forbid gating any feature, reward, or messaging on it.
- **Does native actually beat web here?** Yes, completely — there is no web equivalent, full stop, this mechanism is only reachable through the platform's own store SDK.
- **The catch:** this is real native-only capability with essentially **zero adopter value and the single largest honesty risk in the pack**, because the call has no callback: Crosswake can tell the developer "the request was sent," never "the prompt was shown," never "the user rated the app." Any UI or docs language that implies otherwise is a direct violation of brand pillar 4 ("Keep each runtime honest") and would be the single easiest support-truth claim in this pack to accidentally overclaim.
- **Verdict:** native-necessity is technically the *highest* in the pack (tied with haptics — no web substitute exists), but adopter value and demonstrability are the *lowest*, and the honesty risk is the *highest*. Net: demote to `Next-pack candidate` unless it ships with extremely blunt, fire-and-forget-only copy (see §5) and is *never* counted as a "control you can prove works."

**Recommendation:** split this candidate before Pack 1 scoping proceeds. Toast → cut entirely (generator recipe only, like confirm). Review prompt → ship only if the team accepts it will always read `advisory evidence` / `Next-pack candidate` and never merge-blocking, because it structurally cannot be proven.

### 1.6 `permissions.status` (read-only snapshot, already shipped — not a "control")

- **Who invokes:** Phoenix, typically before deciding whether to show "enable notifications" upsell copy.
- **What USER B gets:** nothing directly — this is backend logic deciding what to render next.
- **Does native actually beat web here?** The underlying fact (native push authorization status) genuinely isn't visible to web JS — `Notification.permission` in a browser is a different, unrelated permission domain from the native app's push authorization state. So the *information* is real and native-only; the risk isn't necessity, it's **scope creep in adopter expectations** (see §5, Open Decision 4).

### 1.7 `notification_token` (evidence snapshot, already shipped as companion/advisory — not a "control")

- **Who invokes:** Phoenix or Chimeway, to obtain the current device's push token for backend registration.
- **What USER B gets:** nothing directly.
- **Does native actually beat web here?** Yes — the token itself is native/provider-issued and has no web equivalent. The risk here, like `permissions.status`, is entirely about **not overclaiming what the evidence proves** (see §5).

---

## 2. The degradation experience

Principle stated in the brief and matched to brand voice: **never show USER B a broken affordance; never hide a broken affordance from USER A (the developer).**

| Control | USER B sees when native is absent | USER A sees (doctor / denial / docs) |
|---|---|---|
| Haptics | Nothing. Silent no-op — this is already the shipped posture and it is correct; a missed tap is invisible and appropriately so. | Doctor: `undeclared_capability` if the route never declared `haptics`; `unavailable_capability` if declared but the shell can't supply it. Approval still completes either way. |
| Action menu | A Phoenix-rendered dropdown/bottom-sheet component (generator-provided, token-styled) offering the *same allowlisted actions* — visually different from the native sheet, functionally identical. Never a broken empty menu, never a native call that silently does nothing. | Doctor: `undeclared_capability` / `unavailable_capability`. Docs name the exact fallback component to reach for. |
| Share | Falls back to Web Share API if present in the WebView; if that's also unavailable, falls back to a "Copy link" button with a visible success state ("Link copied"). Never a dead button. | Doctor: `undeclared_capability` / `unavailable_capability`. Support matrix keeps `share` at `advisory` until platform truth is explicit per route. |
| Confirm (recommended: not a bridge family) | A Phoenix-owned branded modal — always, on every runtime, because this is the *only* implementation, not a fallback. | N/A — there is no native path to fall back from, and that is the point; no doctor finding needed. |
| Toast (recommended: cut) | A Phoenix-owned branded toast — always, same reasoning as confirm. | N/A. |
| Review prompt (if shipped) | Nothing, ever, by design — even when it "works" the OS may show nothing. USER B's experience is identical whether the call succeeded, failed, or was rate-limited by the OS. | Docs/doctor must say plainly that `requested` is the only possible reply state and it proves nothing about what USER B saw. No merge-blocking claim is possible here — see §5. |
| `permissions.status` | N/A (backend decision surface, not user-facing UI by itself). | Docs must foreclose the "can I request permission with this?" question before it's asked — see §5. |
| `notification_token` | N/A. | Docs must foreclose "does a token reply mean delivery will work?" — see §5. |

---

## 3. Consistency / design-system resolution

**Constraint:** Crosswake must not ship an opinionated, importable component library (FALL-02; Phase 154's D-31; `prompts/crosswake-elixir-oss-dna.md:119-124`'s "Use generators when adopters need editable app code" — **not** BRAND-SPEC's visual-identity section seven, which is the design-token tier rule, per D-57's correction). **Requirement:** the fallback surfaces (confirm modal, action-menu sheet, toast) still have to look right, in both themes, at brand-token fidelity, on day one.

**Resolution: extend the existing `mix crosswake.gen.offline_ui` precedent to a `mix crosswake.gen.native_controls_ui` generator.** This is not a new pattern — it is the same contract, already proven:

- Read `lib/mix/tasks/crosswake.gen.offline_ui.ex`: it copies `tokens.css` into the host's `priv/static/assets/` (no-clobber — "reused" log line if the file already exists), copies host-owned `.heex`/`.ex`/`.js` templates verbatim into the host's own `lib/*_web/` tree, and prints a "Next steps" block. Nothing it produces is importable at runtime from the `:crosswake` dependency — every file becomes the host's own source the moment `mix` finishes running.
- Apply the identical shape to native-controls fallbacks: `mix crosswake.gen.native_controls_ui` generates `confirm_modal.ex` (a Phoenix function component using `--cw-*` tokens for surface/border/action colors, a focus trap, `role="alertdialog"`, ESC-to-cancel), `action_menu_sheet.ex` (a token-styled dropdown/bottom-sheet fallback wired to the same `actions` payload shape the native bridge uses), and `toast.ex` + `toast.css` (ephemeral banner, ARIA live region, respects `prefers-reduced-motion`). All ship as **verbatim-copy, host-owned files**, no-clobber, zero build step, `tokens.css` linked before `app.css` exactly as documented in `guides/tokens.md`.
- This keeps "no component tier" literally true: there is no `Crosswake.UI.ConfirmModal` module a host imports and inherits future churn from. There is a generator that hands the host a file it owns outright starting the moment it's created — identical posture to `offline.css`, which is explicitly "host-owned and editable... re-running the generator will NOT update them."
- The generator recipe *is* the answer to the confirm/toast "cut" recommendation in §1: those two controls become **generator-only artifacts with no bridge family at all**, which resolves the design-system tension for them completely — there's no native/web parity question to manage because there is no native path.
- For `action_menu` and `share`, the generator output is the **fallback rendering** for the same `actions`/share payload the bridge already uses, so the two paths (native sheet, Phoenix-owned sheet) present *the same options* even though they render differently — this is the "invisible to the end user where possible" principle from the brief, applied to the one control (action menu) where a visual difference is unavoidable but a *behavioral* difference is not.

**Recipe, not framework, is the resolution.** Crosswake never renders a pixel on the adopter's behalf at runtime; it only ever hands over a starting file the adopter immediately owns.

---

## 4. Accessibility + design pillars

Pillars audited per control: **a11y (VoiceOver/TalkBack, focus management), reduced motion (motion AND haptics), contrast (≥4.5:1 text / ≥3:1 affordances), i18n, dark/light/system, keyboard/hover/focus states, error states, honesty.**

Key findings before the table:

- **Reduced motion vs. haptics — important clarification.** iOS and Android both gate haptic feedback through their own **system-level toggle** (iOS: Settings → Sounds & Haptics → System Haptics; Android: System → Sound & vibration → Vibration & haptics), and `UIImpactFeedbackGenerator`/haptic APIs on both platforms are automatically silenced by the OS when that toggle is off — Crosswake does not need to independently detect or gate this; it must simply **never treat a haptic no-op as an error**, since a silent user preference and a silent failure are indistinguishable and both are supposed to look the same to USER B (no visible haptic, no error surfaced).
- **`prefers-reduced-motion` is a separate, web-side concern** and applies fully to the fallback surfaces (confirm modal open/close transition, toast enter/exit, action-menu sheet slide) — these must degrade to instant show/hide with no animation when the media query is set, per the existing brand motion spec (§18: "Replace line-draw animations with simple fades or static diagrams").
- **i18n:** every string in this document is illustrative English. Crosswake must never hardcode label text into the bridge protocol or the generator templates — action labels, confirm titles/bodies, and toast messages are always adopter-supplied content flowing through the host's own i18n/gettext pipeline; Crosswake only carries structure (ids, destructive flags), never copy.
- **Focus management on native-vs-web modals:** the native action sheet and native alert (if any) get correct focus/dismiss behavior for free from the OS. The **Phoenix-owned fallback modal is the one that needs explicit engineering discipline** — focus trap on open, focus return to the trigger on close, `Escape` to cancel, `aria-modal="true"`, and `role="alertdialog"` for confirm / `role="menu"` for the action sheet. This is exactly the kind of hand-wired work a native control gets automatically and a LiveView control does not — call this out plainly in the generator's inline comments so adopters don't strip it out thinking it's decorative boilerplate.

### Per-control audit table

| Control | Native-necessity rank | End-user fallback | Developer-facing failure | A11y risks | Support label | Verdict |
|---|---|---|---|---|---|---|
| Haptics | 1 (highest — no iOS web equivalent) | Silent no-op | `undeclared_capability` / `unavailable_capability`; approval still completes | Respects OS System Haptics automatically; no reduced-motion interaction (haptics ≠ motion) | Available today / Proof-backed example | **Ship.** Already proven; harden the contract, no scope change. |
| Menu / action-button | 2 | Phoenix-owned dropdown/sheet, same allowlisted actions | `undeclared_capability` / `unavailable_capability`; docs name the fallback component | Native path: VoiceOver/TalkBack correct for free. Fallback path: needs explicit `role="menu"`, focus trap, keyboard arrow-nav — real risk if the generator recipe is skipped or hand-stripped | Next-pack candidate → promote to Available today once contract lands | **Ship — strongest new JTBD in the pack.** |
| Share | 3 | Web Share API, else "Copy link" with visible success state | `undeclared_capability` / `unavailable_capability`; never a dead button | Low risk — copy-link fallback is a plain button/toast, standard a11y | Advisory evidence | **Ship as third pick**, keep posture modest (advisory), don't overclaim platform coverage. |
| Confirm/alert | 6 (lowest — LiveView modal is arguably better) | Phoenix-owned branded modal is the *only* implementation | N/A — no native path exists to fail | Needs explicit focus trap / `role="alertdialog"` / Escape-to-cancel in the generator recipe — real risk of being stripped as "boilerplate" | Not a capability family; not in the capability map at all | **Do not ship as a bridge family.** Generator recipe only. |
| Toast | 7 (lowest of all — iOS has no native toast primitive) | Phoenix-owned branded toast is the *only* implementation | N/A | ARIA live region, respects `prefers-reduced-motion`, must not steal focus | Not a capability family | **Cut. Generator recipe only.** |
| Review prompt | 1 (tied highest technically — zero web equivalent) but adopter value lowest, honesty risk highest | Nothing observable, by design, on every path (success, failure, and OS-suppressed all look identical to USER B) | Docs must state plainly that `requested` proves nothing about what USER B saw; no merge-blocking proof is structurally possible | No a11y surface — the OS owns the entire interaction if it appears at all | Next-pack candidate; cannot ever exceed Advisory evidence | **Demote out of Pack 1 lead controls.** Ship later only with blunt fire-and-forget copy, never marketed as provable. |
| `permissions.status` | n/a (evidence surface, not a control) | n/a | Docs must foreclose "can this request permission?" — see §5 | n/a | Available today (already shipped) | Keep read-only; tighten docs per §5. |
| `notification_token` | n/a (evidence surface, not a control) | n/a | Docs must foreclose "does this prove delivery?" — see §5 | n/a | Advisory evidence (already shipped) | Keep evidence-only; tighten docs per §5. |

---

## 5. Microcopy + support-truth labels

All strings below are real, ready-to-paste copy in Crosswake's established voice (calm, explicit, technical, candid — see BRAND-SPEC §6). They keep the six support labels distinct: **Available today, Proof-backed example, Demo pressure, Advisory evidence, Future gap, Next-pack candidate.**

### 5.1 Doctor findings / denial reasons (new for Pack 1)

```
undeclared_capability (action_menu)
  "Route continues without a native action menu. The route policy does not
   declare `action_menu`. Add the capability to the route only if the listed
   actions truly need a native picker."

unavailable_capability (action_menu)
  "Native action menu is not available in this app runtime. The route policy
   requires `action_menu`. Falling back to the Phoenix-owned action sheet."

undeclared_capability (share)
  "Route continues without native share. The route policy does not declare
   `share`. The link stays in the Phoenix-owned route."

unavailable_capability (share)
  "Native share is not available in this app runtime. The route policy
   requires `share`. Use the Copy Link fallback instead of a dead button."

undeclared_capability (haptics) [existing, unchanged]
  "Route continues without native confirmation feedback."
```

### 5.2 Guidance copy that stops adopters from reaching for the wrong tool

```
[guides/capabilities.md — new note, alert/confirm]
  "Crosswake does not ship a native `alert` or `confirm` bridge family. A
   Phoenix-owned, brand-tokenized confirmation modal is not a fallback here —
   it is the recommended implementation, because it can be route-tour tested,
   themed, and proven merge-blocking the same way the rest of the route is.
   Run `mix crosswake.gen.native_controls_ui` for a host-owned starting
   component."

[guides/capabilities.md — new note, toast]
  "Crosswake does not ship a native `toast` bridge family. iOS has no native
   toast primitive to bridge to in the first place; a Phoenix-owned toast
   component looks and behaves consistently on both platforms. Run
   `mix crosswake.gen.native_controls_ui` for a host-owned starting
   component."
```

### 5.3 `permissions.status` — Open Decision 4 (must not imply request authority)

```
[capability_map.md row text]
  "`permissions.status` returns a read-only snapshot of the current
   notification authorization state (authorized, denied, not_determined, or
   provisional). It cannot request permission and cannot open the OS
   notification-settings screen on the user's behalf. Requesting permission
   remains a host-owned native call outside this bridge family."

[support_matrix.md capability row note — tighten existing]
  "Snapshot only. A `permissions.status` reply describes what the OS has
   already decided; it never triggers, and never implies Crosswake can
   trigger, the OS permission prompt."
```

### 5.4 `notification_token` — Open Decision 4 (must not imply delivery assurance)

```
[capability_map.md row text]
  "`notification_token` returns a provider-tagged token snapshot as evidence
   only. It does not prove APNs/FCM delivery, does not register the token with
   your backend, and does not guarantee the OS will ever deliver a
   notification sent to it. Treat every reply as reconciliation input for your
   own backend — never as delivery assurance."
```

(This mirrors the existing, already-correct posture in `guides/support_matrix.md` §"Notification Surface" — Pack 1 should keep that language verbatim rather than re-deriving it, since it already distinguishes token binding from delivery execution correctly.)

### 5.5 Review prompt — Open Decision 3 (the OS may show nothing, is rate-limited, gives no callback, and platform rules forbid gating/incentivizing it)

```
[capability_map.md row text, if shipped]
  "`review_prompt.request` asks the OS to consider showing its native
   App Store or Play Store review prompt. The OS decides whether, when, and
   how often to show it — Crosswake cannot confirm it was shown, cannot
   confirm the user rated the app, and cannot retry on a schedule you choose.
   A `requested` reply means the ask was sent, nothing more. Do not gate
   features, rewards, or messaging on this call — Apple and Google explicitly
   forbid it, and Crosswake will not pretend otherwise."

[doctor / docs guardrail]
  "This is the one Pack 1 surface that can never reach merge-blocking proof,
   by design — there is no observable outcome to assert against. Treat it as
   Advisory evidence permanently, not as a claim that will graduate."
```

### 5.6 Support-matrix / capability-map cell text for new Pack 1 rows

| Capability or surface | Display label | Current category | Proof posture | Denial/fallback behavior |
|---|---|---|---|---|
| `action_menu` | Next-pack candidate → Available today on contract completion | shipped (post-Pack-1) | verification-required → merge-blocking | Phoenix-owned action sheet renders the same allowlisted actions |
| `share` (promoted) | Advisory evidence → Proof-backed example | demoed → shipped | advisory → merge-blocking once platform truth is explicit per route | Web Share API, else Copy Link |
| `haptics` (hardened) | Available today | shipped | merge-blocking | silent no-op |
| `confirm` / `alert` | Not a capability family | n/a | n/a | n/a — generator recipe, not a bridge control |
| `toast` | Not a capability family | n/a | n/a | n/a — generator recipe, not a bridge control |
| `review_prompt` | Next-pack candidate | next-pack candidate | advisory (permanent ceiling) | no observable outcome, by design |
| `permissions.status` | Available today (tightened docs) | shipped | merge-blocking | n/a — read-only |
| `notification_token` | Advisory evidence (tightened docs) | demoed | advisory | n/a — evidence-only |

---

## 6. Wedge recommendation

From the UX/JTBD lens alone, ranked by genuine native-necessity and cross-checked against adopter value and honesty risk:

1. **Haptics** (harden the existing shipped contract) — the only control with an outright missing web capability (iOS has no Vibration API) and it's already proven end to end in AdminPilot. Zero reason to leave it as Pack 1's only "done" item; use it as the reference contract the rest of Pack 1 copies.
2. **Menu / action-button affordances** — the strongest *new* native JTBD: this is the literal "feels wrong in a webview" moment named in the brief, has real, demonstrable a11y and OS-convention advantages over any web dropdown, and has clear v19 evidence pressure (AdminPilot, Fieldserv).
3. **Share** — real but narrower: it's "harden a flaky/inconsistent Web Share API into a guaranteed native path," not "give the user something the web literally cannot." Ship it third, keep the posture honestly modest (advisory → proof-backed, not merge-blocking-from-day-one).

**Demote or cut, with justification, not laziness:**

- **Alert/confirm** — cut as a bridge family. A branded, testable LiveView modal is arguably *better* than a native alert for a route Phoenix already owns; ship it as a generator recipe instead.
- **Toast** — cut as a bridge family, more decisively than confirm, because iOS has no native toast primitive at all to bridge to. Generator recipe only.
- **Review prompt** — split it out of the toast/review bundle immediately (it has the opposite native-necessity profile), and demote it out of Pack 1's lead controls even though its native-necessity is technically tied for highest: it has the lowest adopter value (no callback, no visibility) and the highest honesty risk in the entire pack. If shipped at all in Pack 1, it must ship with copy that forecloses every overclaiming interpretation up front (§5.5) and must never be allowed to graduate past Advisory evidence.
- **`permissions.status` / `notification_token`** — correctly scoped already as read-only/evidence surfaces, not controls. Pack 1's job for these two is tightening docs (§5.3, §5.4), not adding behavior.

---

## Sources

- `.planning/phases/152-capability-map-collateral-and-v20-handoff/152-V20-HANDOFF.md` (HIGH — primary scope input)
- `guides/capability_map.md` (HIGH — canonical capability rows and support labels)
- `guides/capabilities.md`, `guides/bridge.md`, `guides/support_matrix.md`, `guides/route_policy.md`, `guides/user_flows.md`, `guides/adopter_profiles.md`, `guides/troubleshooting.md` (HIGH — first-party guides, read in full)
- `brandbook/BRAND-SPEC.md` (HIGH — authoritative brand/voice/token contract)
- `lib/mix/tasks/crosswake.gen.offline_ui.ex`, `priv/templates/crosswake/offline_ui/*`, `guides/tokens.md` (HIGH — verbatim-copy generator precedent this document's §3 recommendation is modeled on)
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`, `diagnostics.ex`, `showcase/catalog.ex` (HIGH — established microcopy voice, haptics posture, support-label vocabulary)
- General mobile-platform facts used for the brutal-skepticism analysis (iOS lacks a Vibration API and a native toast primitive; `SKStoreReviewController`/Play In-App Review give no shown/dismissed callback and are rate-limited by the OS; Web Share API availability is inconsistent inside embedded WebViews) — MEDIUM confidence, general platform knowledge not independently re-verified against current Apple/Google docs in this pass; recommend a platform-policy spot-check before this ships as final Pack 1 copy, specifically for the exact current Apple/Google review-prompt guideline wording.
