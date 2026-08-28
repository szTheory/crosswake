# Phase 155: Host-Owned Fallback Components - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the host-owned UI half of the native-controls story:

1. `mix crosswake.gen.native_controls_ui` — copies a **confirm modal** and an **action menu**
   into the host app as files the adopter owns outright. No importable `Crosswake.UI.*` tier.
2. Those surfaces render correctly in light and dark, trap focus, and pass the existing
   merge-blocking brand contrast gates.
3. A merge-blocking **browser** route-tour proves the fallback renders, fails closed, and
   never silently degrades.

**This phase ships NO native control and NO new bridge command.** Phase 156 ships the native
menu. Phase 155's generated surfaces are complete, working, zero-shell UI on their own.

**Discussion scope note:** all eight gray areas were selected, with research. Five parallel
researcher agents produced full reports (`/Users/jon/.claude/jobs/fe4cda4b/tmp/155-R{1..5}-*.md`,
session-local — treat the decisions below as the record, not those files). Their recommendations
conflicted in five places (token scoping, scrim mechanism, how many tokens to add, destructive
treatment, focus-ring remedy). Those conflicts are resolved below in favor of a single coherent
design; the reports are inputs, not the record. Where two agents independently reached the same
conclusion from different evidence, that is noted, because it is the strongest signal in here.

</domain>

<decisions>
## Implementation Decisions

### The trigger model and what the generator emits

- **D-01:** **Phase 155 pushes nothing.** The generated surfaces make no `Bridge.push/3` call.
  Reached independently two ways: (a) there is no `menu` capability and no menu wire command
  today — `Contract.@commands` (`lib/crosswake/bridge/contract.ex:11-22`) holds ten commands,
  none a menu, and `Manifest.Builder.capability_catalog/0` (`builder.ex:248-459`) has neither
  `menu` nor `confirm`; (b) three shipped mechanisms already forbid the alternative —
  `CatalogGuard.check_native_enum_parity/2` (`catalog_guard.ex:416-435`) makes adding
  `action_menu.present` to `Contract.@commands` a merge-blocking `:native_enum_gap`,
  `Registry.capability_command("action_menu")` returns nil → raise, and
  `Policy.Validator.@known_capabilities` (`validator.ex:9-23`) rejects the declaration, which
  fails `Manifest.compile` and MatchErrors the host's `Policy.manifest/0` (`policy.ex:26-29`),
  **killing the route at mount**.

- **D-02:** **Trigger model: fallback-first, native-enhance.** Visibility is a pure function of
  assigns; the surface renders in the same server round-trip that opens it. A denial never
  *triggers* rendering — from Phase 156 onward it annotates an already-visible surface. This
  makes D-24's "the fallback UI rebuilt from assigns is the recovery path" literally true,
  spends zero dead air against D-36's ~2000ms ack deadline or D-22's 10s backstop, and gives
  assistive tech the `role="alertdialog"` announcement immediately.
  Rejected: **denial-reactive** (would require 155 to ship UI that cannot render, since nothing
  can deny a capability that does not exist — PROOF-01 becomes untestable in the phase that owns
  it, and `resolve/2` becomes dead code); **optimistic/client-revealed** (stores visibility in
  DOM state, so a reconnect loses it, violating D-24; the "hide when shell present" variant
  silently degrades on undeclared/unavailable/refused/timeout).

- **D-03:** **The artifact is ONE host-owned `Phoenix.Component` module** —
  `lib/<app>_web/components/crosswake_fallbacks.ex` — carrying markup (`confirm_modal/1`,
  `action_menu/1`) **and** the socket transitions, so `Bridge.resolve/2` ships already-called
  per D-25. Plus one stylesheet, `priv/static/assets/crosswake_fallback.css`. Both no-clobber.
  Fixed event names (`crosswake_fallback_answer` / `_dismiss`), not configurable attrs.
  — **Reversibility:** costly — the generated function arities are called by adopter code, and
  their copy keeps the old body forever; no deprecation path exists for a file we never
  regenerate.

- **D-04:** **`Phoenix.LiveComponent` is technically blocked, not merely disfavored.** Verified:
  `diff.ex:1145-1152` builds a component's private as `Map.take([:conn_session, :root_view])`,
  so `Bridge.resolve/2 → fetch_state!` raises `NotMountedError` inside one. Phoenix 1.8 also
  removed its own generated FormComponent. Record this so planning does not revisit it.

- **D-05:** Rejected for the artifact shape: **markup-only** (drops `resolve/2` → double
  mutation, the exact failure D-25 exists to prevent); **macro/`use`** (an importable tier with
  the label filed off — FALL-02); **injection into `core_components.ex`** (no canonical anchor;
  this repo's own example host has no such file, and D-41 already settled
  patch-what-is-canonical / print-what-is-not).

- **D-06:** **Adopter step count is 4**, and step 4 is pasting three `handle_event` clauses from
  the generator's printed output. The only ways to remove it are a library-intercepted reserved
  fallback event (hidden bridge magic) or a macro (FALL-02 forbids). Keep the paste; invest in
  the printed block. This is the phase's biggest DX number — planning should treat the printed
  output as a deliverable, not an afterthought.

### The confirm modal is not a fallback

- **D-07:** **The confirm modal has no native counterpart and never will.**
  `.planning/REQUIREMENTS.md:116` places a native alert/confirm bridge family under **Out of
  Scope permanently**, and `.planning/research/v20/UX-CONTRACT.md` cuts confirm as a bridge
  family. It is therefore the **primary, only, permanent** confirm surface on every platform:
  zero `Bridge` involvement — no push, no `ref`, no `resolve/2`, no denial branch.
  Only the **action menu** is a real fallback.
  — **Reversibility:** one-way in the sense that FALL-01 names the confirm modal, so it ships;
  reversing means retracting a published generator output.

- **D-08:** Frame it deliberately in the generator's own printed output and the module's header
  comment: *this is the control the docs point at when a developer looks for a native confirm
  that does not exist.* A developer who finds nothing hand-rolls one without the focus trap.
  Also carry NN/g's rule in the header comment: **if you can offer undo, offer undo instead of
  this modal.**

- **D-09:** The word **"fallback" must never reach an end user.** `push` / `reply` / `answer` /
  `denial` (D-27's four verbs) plus bridge, shell, capability, route policy, seam, manifest,
  and hook are **all internal-only** — legitimate in moduledocs, attribute *names*, doctor
  output, and the demo evidence panels, never in end-user copy.

### Zero new JavaScript

- **D-10:** **Phase 155 ships no JavaScript at all.** Focus trapping is delegated to Phoenix:
  `Phoenix.Component.focus_wrap/1` (`deps/phoenix_live_view/lib/phoenix_component.ex:3173`)
  renders `phx-hook="Phoenix.FocusWrap"`, a LiveView **built-in** implemented at
  `phoenix_live_view.esm.js:1275-1301`, already served by the reference host
  (`endpoint.ex:32-37`) and already imported by its layout (`layouts.ex:27`). No hooks-map
  registration, no bundler, no new file, no CSP change. Reached independently by two agents.
  Initial focus comes free from `FocusWrap.mounted()`'s `focusFirst`.

- **D-11:** Everything else uses LiveView built-ins authored in HEEx: `JS.push_focus` /
  `pop_focus` (`js.ex:995-1060`; empty-stack pop is a no-op), `phx-remove` (`js.ex:1137`),
  `phx-window-keydown` + `phx-key="escape"` (`phx-key` matching is case-insensitive),
  `phx-click-away`, `JS.add_class` / `remove_class` for scroll lock. Background suppression is a
  **server-rendered `inert`** attribute, printed as an optional enhancement.

- **D-12:** **Reject `<dialog>` + `showModal()`.** Not on browser floor — `<dialog>` is iOS
  15.4, the same floor `:focus-visible` already crossed at `offline.css:9`. Rejected because
  `showModal()` is **JS-only**, so it forces either a second library module or an inline
  `<script>`, regressing D-40's CSP win; and because it behaves worst exactly at the
  resolve-while-open race D-25 exists for. Also reject Popover API and CSS anchor positioning
  on floor (iOS 17 vs the project's iOS 15.0 in `Package.swift:9`, minSdk 26 in
  `build.gradle.kts:17`).

- **D-13:** **The FALL-02 "no importable tier" question dissolves — nothing UI-shaped ships from
  `lib/`.** For the record, had it been live: D-31's presentation-vs-correctness distinction is
  sound and *would* have licensed a library-owned trap, but it loses anyway because the
  invariant is **Phoenix's**, already in a required dependency; D-31's decisive clause ("client
  half of a versioned wire protocol") does not transfer (no wire, no version, no denial); and a
  `crosswake_ui.esm.js` would satisfy FALL-02's letter while shipping the opposite of its
  spirit.

- **D-14:** **The load-bearing DOM-patch constraint:** the fallback renders from a **snapshot
  assign**, never from live-changing assigns. Same-id re-patch is then harmless;
  resolve-while-open is handled by `phx-remove={remove_class |> pop_focus}`;
  `JS.ignore_attributes` is unneeded.

### Creative direction and the two surfaces

- **D-15:** **One deliberately-branded Crosswake surface at every viewport on every platform.**
  Both surfaces are the same object — opaque `--cw-surface-inset` panel, one 20° 2px wake-seam
  rule, `--cw-radius-lg`, display-font title, body-font copy — **bottom-anchored below 768px,
  centred above**, differing only in the middle (a sentence + two buttons, or a list of
  buttons). It never explains itself; honesty is discharged machine-readably in `data-cw-*`,
  matching the existing `data-cw-envelope` / `data-cw-reply-status` convention.

- **D-16:** **Reject platform mimicry.** Mimicry is a lie and the thesis is honesty; the confirm
  modal has nothing to mimic; 16 visual states in a file adopters edit is unmaintainable;
  `BRAND-SPEC.md:112-143` already names Ionic/Capacitor's mode-switching as a thing not to
  resemble. The strongest counter — every toolkit that shipped at scale (Ionic, Flutter
  Cupertino/Material, `ActionSheetIOS`) mimics — **loses because those replace the native
  control, whereas ours exists only when native is absent, and from Phase 156 the real one is
  one tap away on the same device.** Mimicry is most convincing where you cannot compare and
  most broken where you can. Capacitor concedes the point: its Dialog plugin falls back to an
  honest, ugly `window.confirm()` on web.
  **Hard boundary: adopt platform *ergonomics* (anchoring, 48px targets, safe areas, Cancel
  placement); reject platform *chrome*.**

- **D-17:** **Confirm modal:** centred dialog ≥768px, bottom sheet below. `role="dialog"`
  neutral / `role="alertdialog"` destructive, and **destructive has no click-away dismissal**
  (the Radix Dialog/AlertDialog split shadcn inherits).

- **D-18:** **Button order — one rule that satisfies four conflicting platform conventions:**
  DOM order `[Cancel, Action]`; narrow viewport `column-reverse` (Action top, Cancel bottom);
  wide viewport `row` + `flex-end` (Cancel left, Action right). This simultaneously honors
  Apple's alert rule, Apple's action-sheet rule, Material's right-end confirming action, and
  Tailwind UI's `sm:flex-row-reverse`. Cancel in the thumb-rest position costs a neutral
  confirm one stretch and saves a destructive one from a mis-tap — asymmetric payoff, so **no
  tone exception**.

- **D-19:** **Initial focus is the one tone branch:** Action for neutral, **Cancel for
  destructive** (`JS.focus(to:)`). The answer lives in `phx-value-answer`, and **the modal
  closes on server confirmation, not on click.**

- **D-20:** **Action menu:** same chassis; mandatory `<h2>`; `<ul>`/`<li>`/`<button>`; **no
  icons**; ~7 rows before scroll (`max-height: min(60vh, 420px)`, heading and Cancel *outside*
  the scroll container); destructive row last behind a 4px gap band with a 3px left bar; pending
  state on the **trigger only**. A destructive row always routes through the destructive
  confirm, never straight to the mutation.

- **D-21:** **Do NOT use `role="menu"`.** Reached independently by two agents. APG's Menu
  contract (arrow keys, Home/End, Tab-closes, roving tabindex, `aria-haspopup` +
  `aria-expanded`) cannot be honored without host JS, and declaring it unimplemented is worse
  than never claiming it — "No ARIA is better than Bad ARIA." A `UIAlertController` action sheet
  is exposed as an alert-with-buttons anyway. The trigger takes **`aria-expanded` +
  `aria-controls`**, not `aria-haspopup`. Buttons in a dialog.
  — **Reversibility:** cheap to keep, costly to adopt later (would oblige roving tabindex, i.e.
  the JS D-10 exists to avoid).

- **D-22:** **Action menu is a centred modal at wide viewports in 155, not a trigger-anchored
  dropdown.** One DOM, one a11y contract, one proof lane, no positioning engine. An unanchored
  dropdown can render off-screen, which is a worse first impression than slight heaviness. Defer
  anchoring to SEED-005 where elevation and z tokens land.

- **D-23:** `aria-modal="true"` is unreliable in Safari + VoiceOver (why React Aria ships
  `ariaHideOutside`). The `inert` mitigation covers it for free, but **record it as a
  manual-check limitation** rather than claiming it is proven.

### Tokens and theming

- **D-24:** **Generated files carry a host-owned scoped alias layer**, not direct `var(--cw-*)`
  references: a `--cwfb-*` block on `.cw-fallback` mapping to Crosswake's existing semantics
  (`--cwfb-surface → var(--cw-surface-inset)`, `--cwfb-ink → var(--cw-text-default)`, etc.).
  Chosen over direct references for the **adopter-with-their-own-design-system** path, which is
  the common case: they re-point ~12 lines (`--cwfb-surface: var(--card)`) and delete the tokens
  link, instead of fighting every declaration. In-repo precedent: `app.css:220-224`
  (`--app-accent: var(--cw-runtime-liveview)`) with per-brand overrides at `:248-267` and dark
  at `:487-495`; the drift gate was written to permit exactly this (`check-consumer-drift.mjs:99-114`).
  — **Reversibility:** costly — the `--cwfb-*` names are adopter-visible in a file we never
  regenerate.

- **D-25:** **The generated CSS contains ZERO theme logic** — no `prefers-color-scheme` blocks,
  no `[data-theme]` selectors. It inherits both mechanisms from `tokens.css:57-117`
  (`@media (prefers-color-scheme: dark) :root:not([data-theme])` **and** `[data-theme="dark"]`).
  It copies exactly one theme line from `offline.css:5-7`: `:root { color-scheme: light dark }`.
  This is assertable and should be asserted.

- **D-26:** **`tokens.css` is library-served, not copied into the host.** A second
  `Plug.Static` serves it at `/crosswake/tokens.css`. One source of truth, no drift.
  This also fixes two verified latent defects: `crosswake.gen.offline_ui`'s
  `~p"/assets/tokens.css"` **404**, and a byte-identical **third** copy of tokens.css at
  `examples/phoenix_host/priv/static/css/tokens.css` that **nothing gates** (delete it).
  — **Reversibility:** costly — `/crosswake/tokens.css` becomes a published URL.

- **D-27:** **Add exactly two semantic tokens. 27 → 29, against a documented hard cap of 30**
  (`brandbook/AUDIT.md:392`; "do not invent tokens beyond this spec" `:352`; no mechanical count
  test exists — planning should consider adding one).
  1. **`--cw-overlay-scrim`** ← new primitive `current.950a72 = #09141AB8` (8-digit hex).
     **Deliberately no `$dark` variant.**
  2. **`--cw-status-error-fg`** ← `{primitive.white}` — a pure alias, no compiler change.
  — **Reversibility:** **one-way.** Published tokens are public API for every adopter and are
  effectively unremovable (Primer's `--fgColor-*` rename is the cautionary precedent).

- **D-28:** **The scrim uses an 8-digit hex primitive, NOT `color-mix`.** Decisive: `color-mix`
  has an **iOS 16.2** floor and this project's floor is **iOS 15.0** (`Package.swift:9`), so a
  `color-mix` scrim breaks on supported devices. It also avoids needing a `resolveAlias` fix at
  `compile-tokens.js:22-26` for embedded `{…}` aliases, which today would emit invalid CSS.

- **D-29:** **`compile-tokens.js:67`'s `groups` array must gain `'overlay'` or the new token is
  silently dropped.** Verified. A silent drop would make the scrim `var()` resolve to nothing
  and the modal transparent — with no gate failure.

- **D-30:** **Explicitly decline elevation / z-index / motion / border-width / padding tokens.**
  Compose shadows via `color-mix` off `--cw-text-default` (precedent `app.css:36`). Designing
  that tier belongs to **SEED-005**, not to a phase whose scope is two surfaces.

- **D-31:** **Hard contrast constraints, computed via `brandbook/tools/contrast.mjs` (two agents,
  same numbers):**
  - Panel background **must** be `--cw-surface-inset`, **not** `--cw-surface-raised`:
    `--cw-text-muted` on raised is **4.11:1 — FAILS AA**. The trap is already documented at
    `offline.css:61-64`.
  - Verified passing: `--cw-text-default` 18.64 light / 13.05 dark; `--cw-text-muted` 5.09 / 9.64
    (**on inset only**); `--cw-action-bg`/`-fg` 5.45 / 6.35; `--cw-border-strong` 5.45 / 9.64.
  - Cancel border **must** be `--cw-border-strong` — dark `--cw-border-default` is **1.49:1**.

- **D-32:** **Destructive actions use a FILLED rust-600 button with `--cw-status-error-fg`
  (6.02:1 in both themes)** — decided by the user over the zero-token alternative.
  `--cw-status-error` as *text* is **2.44:1** on `current-800` (2.83 on `-900`, 3.10 on `-950`),
  so red text or border is mathematically dead on dark; without the filled variant a destructive
  confirm has **no color signal at all** on dark, only shape. For "Delete this job? It cannot be
  undone," losing the danger channel on half of users' devices is a safety regression, not a
  style preference. Border-left shape cue is retained *in addition*, not instead.

- **D-33:** **Fix `--cw-action-focus-ring` in this phase AND close the gate hole** — decided by
  the user. The token is **brass-500 = 2.93:1 on white / 2.61:1 on foam-50**, below WCAG SC
  1.4.11's 3:1, **already shipped and live** in `offline.css:9-12` and `app.css:75`. It is
  invisible to CI because `contrast.test.mjs:96-122` tests **text pairs only**.
  Fix: light value → **wake-700** (5.45 light / 4.85 dark), keep wake-500 for dark, **and add
  focus-ring pairs to `contrast.test.mjs`** so this class of failure can never ship silently
  again. Under `forced-colors: active`, substitute `outline`.
  Rationale: success criterion 2 requires the fallbacks "meet the existing contrast gates";
  shipping a ring that fails 1.4.11 through a gate that cannot see it is precisely the DNA
  doc's "letting marketing framing outrun architectural truth" footgun (`oss-dna:212`).
  — **Reversibility:** cheap to revert in code, visually one-way once published.

- **D-34:** **The drift MANIFEST is curated, not a glob** (`check-consumer-drift.mjs:29`). Both
  new library template files (`priv/templates/crosswake/native_controls_ui/*.eex`) **must** be
  added at `:37-43` or they are ungated. Generated **host** files are **NOT** added — we prove
  our default is brand-clean; we do not police the adopter's file. Use **literal `class="…"`
  only**: `class={…}` dynamic bindings are a documented blind spot (`:170-184`).

### Second-run, drift, and the FALL-02 guard

- **D-35:** **Copy `crosswake.gen.bridge_hook`'s pattern (`:129-183`), not
  `gen.offline_ui`'s.** No-clobber **plus** a stamped provenance header (`@template_version`)
  plus a doctor stamp-drift finding. **No `--force`, no three-way merge, no igniter adoption in
  this phase.** Reuses three mechanisms already shipped in-house: the stamp
  (`gen.bridge_hook.ex:58,169-183`), the doctor advisory (`doctor.ex:2131-2160`), and the
  version-drift test (`bump_template_version.ex` + `phase134_template_version_drift_test.exs`).
  — **Reversibility:** the stamp is **cheap to add now, costly to omit** — adding it later
  leaves every already-generated file undetectable, which is shadcn's unfixable-in-retrospect
  problem. Its format is costly to change (doctor regex-parses it, cf. `doctor.ex:2138`).

- **D-36:** **FALL-02 gets a real structural guard: `Crosswake.ComponentTierGuard` in `lib/`**
  (mirroring `CatalogGuard`/`CompanionGuard`, stdlib `Code.string_to_quoted/2` +
  `Macro.prewalk/3`, no new dependency). **Do not name it `Crosswake.UI.*`** — it would
  self-trip; steal `companion_guard.ex:29-33`'s names-as-strings trick. Living in `lib/` means
  deleting the test does not delete the rule.
  Five rules over `lib/**/*.ex`: `namespace` (alias prefix `[:Crosswake, :UI]`),
  `namespace_minted` (`Module.concat` / `String.to_atom` literals), `component_use`
  (`Phoenix.Component` / `LiveComponent` — **zero today**), `component_dsl` (`attr` / `slot`
  call nodes), `template_sigil` (`~H` — **zero today**).

- **D-37:** **The anti-vacuity twin is the sixth rule, and it is the whole point:**
  `components_exist_in_templates` — the generator's templates **must** contain real `~H` and
  `attr`. Without it the guard asserts the vacuously-true "Crosswake has no components." With
  it, the claim is the actual requirement: **"components exist only as adopter-owned text."**
  Four D-46 controls: a multi-violation fixture asserting the **set** of violated rules (not
  `length >= 1`); five one-rule synthetics; a positive control on real `lib/` **plus** real
  templates; and attestation rejecting gaps **and orphan templates**. Use a `root:` injection
  seam per `catalog_guard.ex:88-102` so fixtures drive the raiser itself.

- **D-38:** Guard failure message per D-48's shape — stable bracketed id on line 1
  (`[proof.fall_02.no_component_tier.namespace] subject=… observed=… path=… posture=merge_blocking`),
  then a teaching heredoc with a **five-step retirement recipe** (open an issue naming the
  anti-feature → amend FALL-02 + README + guides in the same PR → **delete guard and test,
  never allowlist** → add to `groups_for_modules`, because importable means public API → add
  `### Upgrade Impact`). Load-bearing final block: **"what you probably want instead"**
  (redefine a token; use the generator; put it in *your* shared web module). Most people should
  take that path, and naming it is what stops the gate being deleted at 2am.

- **D-39:** **Keep the guard test repo-root-only and untagged.** D-47's five-lane hermetic claim
  is **verified true** (`phase130:84`, `phase132:91`, `phase43:106`, `phase45:71`,
  `phase34:89`) **but incomplete**: the step passes `--exclude requires_example_host`, so a
  *tagged* test drops to a single serial lane (`requires-example-host-gate.yml:44-94`,
  `--max-cases 1`).

- **D-40:** **Doctor gains two findings** (stamp drift; fallback wiring), and must **not**
  overclaim: it reads a version integer and inspects no content, so it cannot and must not
  assert anything about the adopter's edited file. Per D-37's discipline, a grep is best-effort
  and never authoritative.

### PROOF-01: the browser lane

- **D-41:** **PREMISE CORRECTION — `script/automated_uat.mjs` is NOT the browser route tour.**
  It is a hand-run phase-UAT markdown writer (`:201`) keyed to Phase 150, with **zero hits in
  `.github/`**. Anything landed there is **advisory by omission**. The real tour is
  `examples/phoenix_host/e2e/route_tour.spec.ts` (613 lines), run at
  `offline-sync-e2e-gate.yml:166-170`. Do not extend `automated_uat.mjs`.

- **D-42:** **A new spec file is merge-blocking the moment it exists — no new workflow, no new
  required check.** `e2e-proof` runs unfiltered `npx playwright test`
  (`offline-sync-e2e-gate.yml:129-131`) and is a `needs:` of the registered required aggregator
  `merge-blocking-offline-sync-e2e` (`:254-264`). New spec:
  `examples/phoenix_host/e2e/native_controls_fallback.spec.ts`, ~200 lines — **a new file, not
  200 lines bolted onto the 613-line tour.** Add one named `run:` step for evidence legibility
  (D-47: a step name is free). **Pin it in `script/check-e2e-honesty.mjs`'s `FILES` (`:55-60`)**
  — the missing-file rule (`:81-86`) is the only thing that makes a proof spec undeletable.
  Cost: **≈0 added wall-clock** (parallel jobs; `route-tour-proof` is the critical path),
  **≈40-60 s runner-seconds**, ubuntu only, chromium already installed (`:126-128`), zero queue
  time. 153.1's 5.8 min is untouched. Verify empirically before closeout.

- **D-43:** **Success criterion 3's wording is wrong; Phase 154's raise decisions all hold.**
  Reached independently by three agents. "Undeclared" is **three moments, not one**:
  (A) outbound preflight — route policy never declared the family → **raises**
  (`bridge.ex:210-215`, `:564-589`), renders nothing; (B) shell-side rejection → wire `deny`
  with `reason: "undeclared_capability"` (`BridgeChannel.swift:198-208`, `.kt:115-121`), decoded
  at `bridge.ex:686-716` → **renders**; (C) family not in the bridge vocabulary at all → same
  raise, misleading message. **Criterion 3 is satisfiable only against (B).**
  D-04/D-05/D-06/D-07/D-09/D-10 all hold, reinforced by new evidence: `denial_reason` telemetry
  (`bridge.ex:800-811`) would gain a third population contaminating two dashboards that must
  stay quiet, whereas a named exception groups cleanly in an error reporter; and a raise is
  announced to no assistive technology, which argues for making it **unreachable earlier**, not
  softer.

- **D-44:** **Replacement wording for criterion 3 / PROOF-01** (paste-ready):
  *"An undeclared capability raises and names the missing declaration; an unavailable capability
  renders an explicit denial. A merge-blocking browser route-tour proves that the fallback
  renders, that a shell-side denial renders and the mutation does not proceed, and that no
  failure path resolves to silence. The outbound `UndeclaredCapabilityError` is deliberately
  excluded from the browser lane — a browser cannot observe a server-side raise — and is
  asserted server-side in ExUnit instead."*
  Label the split **hybrid** in the spec docblock, exactly as D-44 of Phase 154 labelled the
  fails-closed criterion.

- **D-45:** **Three routes, because there are three conditions.** (A1) fallback renders →
  `/saas/approvals/approval-1` (product-shaped; catalog fallback string at `builder.ex:288`).
  (A2) undeclared → a **new** `/_e2e/undeclared-control` route, because **you cannot un-declare
  an existing route without breaking its existing proofs**; `/_e2e` is already prod-policed by
  `guard-02` (`:73-103`). (A3) no-silence → `/bridge-proof`, which adds no UI and just
  enumerates paths already visible (stays 152 lines).
  Do **not** target the AdminPilot `saas-approval` route: it is pinned by eight merge-blocking
  checks from Phase 154.

- **D-46:** **Assertion design, with the non-vacuity condition stated for each.**
  - Absent-before / present-after on `data-cw-fallback`. **Vacuous if the route hardcodes the
    modal** → require the example host's committed file to carry the generated stamp.
  - The catalog sentence is **read from `Manifest.Builder`, never hardcoded**
    (`route_tour.spec.ts:19-23`'s existing discipline).
  - Focus trap asserted **as behavior** (Tab / Shift-Tab wrap, Escape, focus return).
  - Computed WCAG AA in **both** schemes by toggling `data-theme` **in-page** (`tokens.css:89`),
    **not** via extra Playwright projects — that config's own comment warns it would "triple a
    merge-blocking lane's wall clock." Reuse `evidence_panel.spec.ts:271-380`'s
    effective-background compositing walk plus its `matchMedia` non-vacuity guard.
  - **Focus-ring ≥3:1 — this assertion fails today** and passes only after D-33.
  - Denial injected via `page.addInitScript()` using the **doubly-nested** wire shape verbatim
    from `BridgeChannel.kt:328-350`. **Vacuous if single-nested**, since `bridge.ex:686-692`
    accepts both.
  - Assert the reason is `undeclared_capability` and **not** `unavailable_capability` — the
    D-13 regression guard.
  - Assert **no `role="menu"`** anywhere.
  - **The negative control that matters:** assert the success surface **and the server-side
    effect** are *absent*. "A denial rendered" does not mean "the mutation did not happen."

- **D-47:** **"Never silently degrades" — the honest approximation.** Enumerate the vocabulary
  from `CatalogGuard.closed_vocabulary/0` (`:668`) and require *exercised ∪ explicitly-excluded
  == full set*, so adding a reason turns the lane red. Assert rendered text **changed from
  idle** (`bridge_proof_live.ex:139`), not merely non-empty. Add a MutationObserver dead-air
  invariant per `evidence_panel.spec.ts:404-485` — the browser form of D-36's "no configuration
  resolves to silence." Add a `CROSSWAKE_PROOF_BREAK_FALLBACK` mutation control **in the example
  host, never in `lib/`**, mutating only visibility so A1 reds while the enumeration stays green.

- **D-48:** **What the proof does NOT prove — paste into the requirement and the spec
  moduledoc** (per D-45's anti-overclaim discipline): not "never" as a universal, only the
  enumerated current vocabulary, excluding the five unbounded `String` seams SEED-008 carries;
  not native behavior (desktop Chromium plus document-start injection is a faithful stand-in,
  not iOS/Android); not the **adopter's edited** fallback; not that the UI is *good* (contrast
  and focus are floors, not judgments); not reachability on every route; not screenshots.

- **D-49:** **All of PROOF-01 is merge-blocking, and that is consistent with the repo's existing
  split.** The `brandbook-verify.yml` split is by **assertion kind, not browser presence**:
  required `brand-structural` already runs Playwright Chromium for DOM checks (`:86-92`);
  advisory `brand-visual` does the **pixel** sampling (`:94-129`). None of PROOF-01 is a pixel
  assertion. Already configured in `playwright.config.ts`: `workers:1`,
  `fullyParallel:false`, `serviceWorkers:'block'`, `retries:2`, `trace:'on-first-retry'`.
  **Gap to fix:** `e2e-proof` uploads **no** artifacts (unlike `route-tour-proof:231-241`) —
  add an `if: failure()` upload **before** landing a required browser assertion.
  `continue-on-error` is forbidden (v12.0 GATE-01: it "paints a failed lane green and makes it
  permanently unpromotable"). No `@flaky` quarantine — a quarantined fail-closed proof is a
  fail-open gate. The 2000ms ack deadline is awaited via rendered outcome, **never a sleep**.

### Shipped-code defects to fix in this phase

- **D-50:** **`resolve/2` must become tolerant on an unattached socket.** Found independently by
  two agents. Its docstring promises "it never raises" (`bridge.ex:270-271`) but `fetch_state!/1`
  raises `NotMountedError` — and D-25 puts `resolve/2` **inside generated adopter code**. In 155
  there is no `menu` capability, so an early adopter will not have called `attach/1` and their
  **first fallback click 500s**. The fallback must never be the thing that crashes. Keep
  `dispatched/2` strict. Land as its own first commit for a clean bisect.
  — **Reversibility:** one-way after first publish — D-05's asymmetry means softening is
  source-compatible but re-hardening is not. Decide deliberately; this is the last cheap moment.

- **D-51:** **Ship a distinct `Crosswake.Bridge.UnknownCapabilityFamilyError`.**
  `bridge.ex:205-207` routes moment (C) into `raise_undeclared_capability!/3`, whose remediation
  tells the adopter to add `capabilities: ["action_menu"]` — which per `validator.ex:116-131`
  **escalates a click-time crash into a mount-time crash**. Still an unconditional raise; only
  the name and message change. The existing `:unsupported_command` branch (`:225-229`) is dead
  code. Blast radius: **zero** — `Bridge.push/3` is unpublished.

- **D-52:** **`patcher.ex:129-131` returns `[:marker_reused]` and never reconciles block
  contents**, so existing Phase 154 adopters will **not** receive the new tokens `Plug.Static`.
  Needs marker-content reconciliation plus a doctor finding.
  — **Reversibility:** costly — changes an installer that has already run in adopter repos.

### The 155 → 156 seam

- **D-53:** **The `actions` data shape is this phase's real one-way door** and deserves a
  dedicated planning review. Frozen shape: `actions :: [%{id, label, destructive, icon}]`, with
  **two distinct outcomes** — select-with-id versus dismiss (`UX-CONTRACT.md:41`). It is
  host-owned and never regenerated, so getting it wrong means hand-editing in every adopter's
  app.
  — **Reversibility:** **one-way.**

- **D-54:** Because 155 is push-free, **D-29's `[String: String]` payload ceiling never reaches
  the adopter in this phase.** 156 adds the catalog entry, both native enum cases
  simultaneously, the registry mapping, and the transport choice. **Breaking changes to
  adopter-owned files: none.** Cost is additive hand-editing only, and an adopter who never
  takes 156 keeps a working menu forever.

- **D-55:** Ship an **inert commented Phase-156 hand-off block inside the generated
  `action_menu` source itself.** The generator has no `--force`, so a comment in the file the
  adopter owns is the only upgrade instruction that survives.

### Corrections to the existing record

- **D-56:** **Phase 154's D-29 is factually wrong.** It claims old natives return
  `unavailable_capability`; verified false — the closed-enum miss fires first and **both**
  natives return `undeclared_capability`, which is exactly the two-remediation collapse D-13
  forbade. Does not block 155. **Phase 156 must not plan against the stated premise.**

- **D-57:** **A citation in the existing docs is wrong.** `UX-CONTRACT.md:15` and
  `.planning/research/v20/SUMMARY.md:76-77` cite "BRAND-SPEC §7" for the **module**-level
  no-component-tier rule. Verified: `BRAND-SPEC.md:336-342`'s "No component tier" is the
  **design-token** tier rule. The real authority is **FALL-02 + Phase 154's D-31 +
  `prompts/crosswake-elixir-oss-dna.md:119-124`**. The requirement is unaffected; stop citing §7
  for it.

### Microcopy

- **D-58:** **`title` and `confirm_label` are required attrs with NO default.** A default of
  "OK"/"Confirm" ships habituation; the compile error is the teaching surface.

- **D-59:** Canonical strings (adopter-editable, but these are the shipped defaults):
  - Neutral: title `Approve this request?` / body `The requester is notified and the decision is
    recorded.` / action `Approve request` / pending `Approving…`
  - Destructive: title `Delete this job?` / body (**required**) `This removes the job and its 3
    photos. It cannot be undone.` / action `Delete job` / pending `Deleting…`
  - Cancel is `Cancel` in both (NN/g Cancel-vs-Close).
  - Success: `Approved. The requester was notified.` / `Deleted. The job and its photos are gone.`
  - Answer-didn't-land (`role="alert"`, panel stays open): `That didn't save. Nothing was changed
    — try again.`
  - Menu: heading `Choose an action`; dismiss `Cancel`; disabled row `Reassign job — needs a
    supervisor`; empty `No actions are available for this record.`
  - Fail-closed, rendered **inline `role="alert"`, never in a modal**: `This action needs a newer
    version of the app. Update the app, then try again.` (stale binary) /
    `This action isn't available here. Nothing was changed.` (undeclared).
  - **`:shell_unreachable` produces no string at all** — the fallback simply renders. Precedent:
    `approval_live.ex:292-297`.

### Claude's Discretion

- Exact `--cwfb-*` alias names and their ordering within the block (D-24 fixes the mapping, not
  the spelling).
- Wireframe-level spacing, the 20° wake-seam's exact geometry, and scroll-shadow treatment.
- Test-file organization within the new spec, and which existing helper modules to reuse.
- Whether the token-count cap (`AUDIT.md:392`) gains a mechanical test in this phase or is
  merely noted — D-27 flags it; either resolution is acceptable.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and the immediately-prior phase
- `.planning/ROADMAP.md` — Phase 155 entry (goal, 3 success criteria) and Phase 156. **Note
  D-43/D-44: criterion 3's wording is wrong and must be amended.**
- `.planning/REQUIREMENTS.md` — FALL-01, FALL-02, PROOF-01. Line 116 places a native
  alert/confirm bridge family **permanently out of scope** (load-bearing for D-07).
- `.planning/phases/154-the-control-contract-seam/154-CONTEXT.md` — **read in full.** All
  D-NN references in this document point at it. Note D-29 is factually wrong (D-56) and D-44's
  hybrid-labelling precedent is reused by D-44 here.

### Project DNA and brand
- `prompts/crosswake-elixir-oss-dna.md` — §"Package design" lines 119-124 is the governing
  ownership rule; line 212's "letting marketing framing outrun architectural truth" is the
  rationale for D-33; line 208 forbids device-only proof paths.
- `brandbook/BRAND-SPEC.md` — **current and authoritative.** `:112-143` (do not resemble
  Ionic/Capacitor mode-switching, D-16); `:336-342` ("No component tier" is the **token** tier
  rule — see D-57).
- `brandbook/AUDIT.md` — `:352` "do not invent tokens beyond this spec"; `:392` the hard cap of
  30 semantic tokens.
- `prompts/crosswake-brand-book.md` — **superseded** by BRAND-SPEC.md where they conflict. Read
  for vision only.

### v20 research corpus
- `.planning/research/v20/UX-CONTRACT.md` — cuts confirm as a bridge family; `:41` fixes the
  two-outcome menu contract (D-53). Its `:15` citation is wrong (D-57).
- `.planning/research/v20/SUMMARY.md` — `:76-77` carries the same wrong citation; `:124-125`
  footgun #6 ("never show the end user a broken affordance; never hide a broken affordance from
  the developer") is the rationale anchor for D-43.
- `.planning/research/v20/API-DESIGN.md` — note Phase 154 already overrode its §3 hook design.
- `.planning/research/v20/GROUND-TRUTH.md`, `PRIOR-ART.md`, `VISION-COHERENCE.md`

### Seeds
- `.planning/seeds/SEED-005-themable-web-control-equivalents.md` — owns the elevation / z-index /
  motion token tier and trigger-anchored dropdowns (D-22, D-30).
- `.planning/seeds/SEED-008-native-denial-vocabulary.md` — owns the five unbounded `String`
  seams that D-48 excludes from the proof's claim.

### Generator precedent
- `lib/mix/tasks/crosswake.gen.bridge_hook.ex` `:58`, `:129-183` — **the pattern to copy** (D-35).
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` `:113-129` — `ensure_file` shape; also carries the
  `~p"/assets/tokens.css"` 404 that D-26 fixes.
- `lib/mix/tasks/bump_template_version.ex` + `test/crosswake/proof/phase134_template_version_drift_test.exs`
- `lib/crosswake/doctor/doctor.ex` `:2131-2160` (stamp advisory), `:2138` (stamp regex).
- `lib/crosswake/install/patcher.ex` `:73-83`, `:129-131` — the `[:marker_reused]` defect (D-52).

### The seam
- `lib/crosswake/bridge.ex` — `:122`,`:125` (timers); `:205-215` (D-51); `:255` `dispatched/2`;
  `:270-281` `resolve/2` (D-50); `:564-589`; `:686-716` (wire decode, accepts both nestings);
  `:800-811` (telemetry).
- `lib/crosswake/bridge/contract.ex` `:11-22` — the ten commands, no menu.
- `lib/crosswake/bridge/catalog_guard.ex` `:88-102` (`root:` seam), `:416-435` (enum parity),
  `:668` (`closed_vocabulary/0`).
- `lib/crosswake/companion_guard.ex` `:29-33` — the names-as-strings trick (D-36).
- `lib/crosswake/manifest/builder.ex` `:248-459` (catalog), `:288` (the A1 fallback string).
- `lib/crosswake/policy/validator.ex` `:9-23`, `:116-131` — why D-51 matters.

### Brand tooling and gates
- `brandbook/tools/check-consumer-drift.mjs` `:29` (curated, not a glob), `:37-43` (MANIFEST),
  `:78-153` (hex/primitive bans), `:99-114` (alias layers permitted), `:170-184` (dynamic-class
  blind spot).
- `brandbook/tools/contrast.mjs`, `contrast.test.mjs` `:96-122` — **text pairs only; the hole
  D-33 closes.**
- `brandbook/tools/compile-tokens.js` `:22-26` (`resolveAlias`), `:67` (`groups` — D-29).
- `brandbook/tools/compile-tokens.test.mjs` `:222` — tokens.css byte-parity.
- `brandbook/tokens/crosswake.tokens.json` — where D-27's two tokens are authored.
- `.github/workflows/brandbook-verify.yml` `:86-92` (required, Playwright DOM), `:94-129`
  (advisory, pixels) — the split D-49 relies on.

### CI and the proof lane
- `.github/workflows/offline-sync-e2e-gate.yml` `:73-103` (`guard-02` prod policing of `/_e2e`),
  `:126-131` (`e2e-proof`, unfiltered playwright), `:166-170` (route tour),
  `:201-206`,`:207-230` (critical path), `:231-241` (artifact upload to copy), `:254-264`
  (the required aggregator).
- `.github/workflows/requires-example-host-gate.yml` `:44-94` — the single serial lane D-39 avoids.
- `script/check-e2e-honesty.mjs` `:55-60` (FILES), `:81-86` (missing-file rule — D-42).
- `examples/phoenix_host/e2e/route_tour.spec.ts` `:19-23` (read-from-source discipline),
  `:97`,`:103`,`:110-146` (the addInitScript harness).
- `examples/phoenix_host/e2e/evidence_panel.spec.ts` `:271-382` (contrast compositing walk),
  `:404-485` (MutationObserver invariant), `:552` (`data-cw-*` convention).
- `examples/phoenix_host/playwright.config.ts` — determinism settings; its own comment on why
  extra projects are refused.
- **`script/automated_uat.mjs` — NOT the route tour. Do not extend it (D-41).**

### Frontend primitives (in deps — read, do not vendor)
- `deps/phoenix_live_view/lib/phoenix_component.ex:3173` — `focus_wrap/1`.
- `deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js` `:1275-1301` (FocusWrap),
  `:3400-3425` (push/pop focus), `:6375` (case-insensitive `phx-key`).
- `deps/phoenix_live_view/lib/phoenix_live_view/js.ex` `:995` (`focus`), `:1039-1060`
  (push/pop focus), `:1137` (`phx-remove`).
- `deps/phoenix_live_view/lib/phoenix_live_view/diff.ex:1145-1152` — why LiveComponent is
  blocked (D-04).

### Platform floors
- `Package.swift:9` — iOS **15.0**. `build.gradle.kts:17` — minSdk **26**. These kill
  `color-mix` (D-28) and the Popover API (D-12).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Phoenix.Component.focus_wrap/1`** — the entire focus-trap requirement, free, already
  served and imported by the reference host. This is the single biggest scope reduction in the
  phase.
- **`crosswake.gen.bridge_hook`'s stamp + doctor advisory + drift test** — three shipped
  mechanisms that together answer the second-run/drift question with no new invention.
- **`evidence_panel.spec.ts:271-382`** — an existing effective-background compositing walk that
  computes real contrast in a browser. Reuse rather than rewrite; it already solves the hard
  part of criterion 2.
- **`evidence_panel.spec.ts:404-485`** — an existing MutationObserver dead-air invariant, which
  is the browser form of "never silently degrades."
- **`Crosswake.CompanionGuard` and `Crosswake.Bridge.CatalogGuard`** — two in-repo templates for
  a `lib/`-resident structural rule with a `root:` injection seam for fixtures.
- **`offline.css`** — the one existing host-facing stylesheet: the model for zero theme logic
  plus `color-scheme: light dark`, and the source of the documented
  `text-muted`-on-`surface-raised` trap.
- **`app.css:220-224`, `:248-267`, `:487-495`** — in-repo precedent for exactly the scoped alias
  layer D-24 adopts.

### Established Patterns
- **Curated manifests, not globs** — the drift gate (`:29`) and `check-e2e-honesty.mjs`'s FILES
  both require explicit registration. New files are ungated until listed. This has bitten before.
- **No-clobber generators with printed next steps** — adopters own the output; the generator
  never updates it. Every upgrade instruction must survive *inside* the generated file.
- **Read facts from source, never hardcode** — `route_tour.spec.ts:19-23`. Applies to the
  catalog fallback sentence and the denial vocabulary.
- **Structural rules live in `lib/`, not in tests** — so deleting the test does not delete the
  rule, and doctor can call it.
- **Proof tests land as untagged files in existing lanes** — no new workflow, no new required
  check, no registration ritual.
- **Honest labelling over faked mechanization** — Phase 154's D-44 labelled criteria
  mechanical / hybrid / attestation-only rather than pretending. D-44 and D-48 here continue it.

### Integration Points
- `mix crosswake.install`'s endpoint patcher gains a second `Plug.Static` for
  `/crosswake/tokens.css` — and needs marker-content reconciliation so existing adopters get it.
- `mix crosswake.doctor` gains two findings.
- `brandbook/tokens/crosswake.tokens.json` → `compile-tokens.js` → both `tokens.css` copies,
  under byte-parity enforcement.
- `contrast.test.mjs` gains focus-ring pairs — a new *class* of assertion for that gate.
- The example host commits real generator output, so PROOF-01 exercises the actual artifact
  rather than a hand-written stand-in. The generated file's stamp is what makes that
  non-vacuous.

</code_context>

<specifics>
## Specific Ideas

- **"Mimicry is most convincing where you can't compare and most broken where you can."** The
  reason the fallback is deliberately branded: from Phase 156 the real native control is one tap
  away on the same device.
- **The anti-vacuity twin (D-37)** is the intellectual core of the FALL-02 guard. "Crosswake has
  no components" is vacuously true; "components exist only as adopter-owned text" is the
  requirement. A guard that cannot tell those apart is theater.
- **"The fallback must never be the thing that crashes"** (D-50) — the one-line statement of why
  `resolve/2` has to be widened before this ships.
- **"A denial rendered" ≠ "the mutation did not happen"** (D-46) — the negative control that
  makes PROOF-01 mean something.
- Two independent agents computing the same contrast ratios from `contrast.mjs` is why D-31/D-32/
  D-33 are stated as numbers rather than intentions.
- Both the destructive-treatment call (D-32) and the focus-ring call (D-33) were the user's,
  taken over the cheaper alternatives, on safety and honesty grounds respectively.

</specifics>

<deferred>
## Deferred Ideas

- **Elevation / z-index / motion / border-width / padding token tier** → **SEED-005**. D-30
  declines it explicitly; composing shadows via `color-mix` off `--cw-text-default` is the
  in-phase workaround.
- **Trigger-anchored dropdown for the action menu at wide viewports** → **SEED-005**, where the
  elevation and z tokens it needs will exist (D-22).
- **The five unbounded native denial `String` seams** → **SEED-008**. D-48 explicitly excludes
  them from what PROOF-01 claims.
- **`igniter` adoption for generator codemods / three-way merge** → not this phase (D-35).
  Worth a real evaluation when a generator genuinely needs to *update* adopter files.
- **A mechanical semantic-token count test** against `AUDIT.md:392`'s cap of 30 — flagged in
  D-27, left to planning's discretion. After this phase only one slot remains.
- **Phase 156 must re-derive D-29's premise** (D-56) — old natives return
  `undeclared_capability`, not `unavailable_capability`. Not a 155 deliverable, but recorded so
  156 does not plan against a false statement.
- **Fixing `--cw-status-error`'s dark-theme text contrast generally** (2.44:1) beyond the filled
  button case — the token remains unusable as text/border on dark. D-32 solves it for this
  phase's destructive button only.

</deferred>

---

*Phase: 155-Host-Owned Fallback Components*
*Context gathered: 2026-07-29*
