# Phase 154: The Control-Contract Seam - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the reusable machinery every future native-controls pack rides on:

1. `Crosswake.Bridge.push/3` — one typed, chainable, server-side way for a LiveView to
   invoke a bounded native control.
2. One shipped, library-owned JS hook — the client half of the `crosswake.bridge` protocol,
   whose single most important job is synthesizing a denial when no shell is reachable.
3. One typed denial contract — no-shell, old-shell, shell-refused, and hook-not-wired all
   land in one adopter clause.
4. A merge-blocking structural guard that keeps the command vocabulary closed.
5. Haptics migrated onto the seam, retiring the hand-rolled `<script>` IIFE.

**This phase does NOT ship a new native control.** Menu is Phase 156. Fallback UI is
Phase 155. Haptics is the proof vehicle precisely because it is already native and
already merge-blocking, so the seam can be proven with zero new native risk.

**Discussion scope note:** all eight gray areas were selected for research. Five parallel
researcher agents produced full reports; their recommendations conflicted in three places
(reply delivery mechanism, denial reason naming, event-name prefix). Those conflicts are
resolved below in favor of a single coherent design — the reports are inputs, not the record.

</domain>

<decisions>
## Implementation Decisions

### Dependency and sequencing

- **D-01:** Phase 154 is **NOT blocked** by Phase 153's human-gated mirror tag push, for the
  fire-and-forget path. Verified directly: `haptics.impact` is present in the shipped closed
  enum of both native cores (`BridgeChannel.swift:10`, `BridgeChannel.kt:11`), so the haptics
  proof needs no native release.

- **D-02:** **The iOS reply return leg does not exist and must be built in this phase.**
  Found independently by two researchers and verified: Android is duplex
  (`BridgeChannel.kt:59` uses `WebViewCompat.addWebMessageListener`, and
  `replyProxy.postMessage(reply)` reaches JS), but iOS hands the reply to a Swift closure
  (`BridgeChannel.swift:170-178` → `replySink`), which the example host constructs as
  `replySink: { _ in }` (`LiveViewContainerViewController.swift:244-247`). Nothing ever calls
  `webView.evaluateJavaScript`. `WKScriptMessageHandler` is send-only by design.
  **Resolution:** write the iOS return leg (`replySink` → `evaluateJavaScript` against the
  hook's `window.crosswakeBridge.__reply` landing pad) in Phase 154, proven by Swift unit
  tests and committed contract vectors. It **reaches adopters** with the Phase 156 native
  release, which needs the mirror anyway. The support matrix must state that iOS native
  reply delivery is pending that release.
  — **Reversibility:** costly — the landing-pad function name becomes part of the shipped
  client/native contract; renaming it later means every shell binary in the field is talking
  to a function that no longer exists.

- **D-03:** CTRL-01's reply half is therefore satisfied in 154 by: Android native replies,
  server-synthesized denials on every platform, and iOS native replies landing in-repo but
  shipping in 156. This must be stated honestly in the support matrix rather than claimed as
  uniformly complete.

### The error contract (raise vs. deny)

- **D-04:** **CTRL-02 and CTRL-03 are not in tension — there are two different
  undeclared-capability moments.** Outbound (server → shell) is a preflight: route policy
  never declared the capability, nothing has reached the wire, so `Bridge.push/3` **raises**.
  Inbound (shell → server) keeps the existing `:undeclared_capability` **denial**, because the
  shell never trusts the WebView. Same authorization source (`Bridge.Registry.lookup/4`),
  outcome selected by direction.

- **D-05:** The raise is **unconditional — every environment, including `:prod`.** A raise
  in `:dev` only means the bug ships and manifests only where it cannot be debugged.
  — **Reversibility:** costly — softening a raise to a denial later is source-compatible, but
  hardening a denial into a raise afterwards breaks every adopter who wrote code depending on
  the soft path.

- **D-06:** The decisive argument is **honesty, not DX**. A `Shell.Denial` is *evidence about
  the shell*. When route policy never declared the capability, there is no shell fact to
  report — no request was made and nobody answered. Minting a denial would make Crosswake
  misreport which layer failed. Reinforcing it: `push/3` returns a `Socket`, so a denial could
  only arrive asynchronously down the reply channel, delivering a *server-side authoring bug*
  through the seam reserved for *shell facts*.

- **D-07:** Raise a **named** `Crosswake.Bridge.UndeclaredCapabilityError`, not a bare
  `ArgumentError` — a bare `ArgumentError` is unmatchable in adopter tests, in Crosswake's own
  proof lane, and in error-reporter grouping.

- **D-08:** Precedent that settles the "chainable functions can't raise" objection:
  `Phoenix.LiveView.stream_insert/3` raises `ArgumentError, "no stream with name ...
  previously defined"` — a chainable socket→socket function raising on an undeclared name is
  structurally identical.

- **D-09:** **Do not ship `Crosswake.Bridge.available?/2` or `connected?/1`.** A pre-check
  invites `if available?, do: push, else: fallback` — a three-way branch by the back door,
  directly contradicting CTRL-02. Expo shipped exactly this and its `isAvailableAsync`
  returns `true` on browsers where sharing does not work.

- **D-10:** The error message must be a heredoc that shows the fix as code (house style:
  `Phoenix.LiveView.allow_upload/3`), naming: route id, missing family, what *is* declared,
  the view module, the router file/line, the literal line to add, and one sentence on *why it
  raised* so nobody files a bug asking for a denial. Brand rule: calm, specific, actionable;
  name what happened and what to do next.

### The denial contract

- **D-11:** **Collapse at `status`, distinguish at `reason`.** CTRL-02 requires one typed
  *Denial*, not one *reason*. Three client-detectable states, three reasons, one adopter clause.

- **D-12:** Add exactly one new reason to the closed vocabulary: **`:shell_unreachable`**
  (13 → 14). Naming chosen over `:shell_unavailable` because it also honestly covers the
  timeout case ("we could not reach a shell that answers"). Variants live in
  `details.failing_moment` (`:no_transport | :reply_timeout | :transport_error |
  :hook_not_wired`) — one reason, not four.
  — **Reversibility:** one-way — the reason string is written into committed contract vectors
  consumed by both native test suites; renaming it after release means regenerating vectors
  across three repos and invalidating any adopter telemetry keyed on it.

- **D-13:** **Do not reuse `:unavailable_capability` for no-shell.** It would make the denial
  *false* (it asserts a shell exists and lacks something) and collapse two opposite
  remediations: "you are in a browser, this is correct and expected" vs "your shell binary is
  stale, ship a new one." Doctor cannot write correct copy for a reason that means two things.
  Capacitor independently reached the same split (`unavailable` vs `unimplemented`).

- **D-14:** **Denials are minted only in Elixir, only by `Shell.Denial.new/1`.** The JS hook
  reports a *fact* (`crosswake:bridge_unreachable` with a `moment`); core translates facts
  into typed denials. This keeps denial microcopy out of JS where it would drift and could not
  be gettext'd, and preserves the `Shell.Denial` moduledoc's own boundary that only core
  constructs denials. **This overrides the draft hook in `API-DESIGN.md` §3**, which builds
  denial objects client-side.

- **D-15:** `:shell_unreachable` is deliberately **not** added to
  `Compatibility.finding_to_denial/2` — it has no `Finding` axis and no companion path, so the
  "companions return Findings, core owns Denials" boundary is untouched.

- **D-16:** **Latent contract violation to resolve in this phase:** the shipped natives already
  emit denial reasons outside the closed vocabulary — `notification_status_unavailable` and
  `notification_authorization_required` (Swift), `invalid_payload` and a host-supplied
  unbounded string via `NotificationTokenDelegate.Result.Denied` (Kotlin). Nothing validates
  inbound reasons today, so it is dormant — but the moment 154 parses replies server-side,
  CTRL-02's "one typed `Shell.Denial`" is provably false on the wire. Land a structural test
  asserting the natives' emitted reason strings are a subset of the vocabulary. **That test
  fails today.** Either fix in 154 or defer explicitly with a named seed — do not discover it
  during execution.

### Reply delivery, correlation, and races

- **D-17:** **The reply is delivered to `handle_info/2` as a typed struct**, via a distinctive
  tagged tuple: `{:crosswake_bridge, ref, %Crosswake.Bridge.Reply{}}` where the reply's
  `:denial` field is a `%Crosswake.Shell.Denial{}`.
  *Conflict resolution:* researchers split between `handle_info` + typed struct and
  `handle_event` + string maps. Resolved toward the struct because (a) it is the only
  mechanism that can deliver a typed value — the raw client event arrives as
  `handle_event` and `attach_hook(:handle_event)` returns `{:cont, socket}` / `{:halt, socket}`
  without a documented way to rewrite the params the adopter's clause receives; (b) matching
  stringly-typed JSON at the milestone's most important seam is off-DNA for a protocol-typed
  library; (c) today's wire denial is *doubly* nested (`reply["denial"]["denial"]["reason"]`),
  which will be copy-pasted wrong. **Planning must verify (a) against the installed
  `phoenix_live_view` before locking it** — if `attach_hook` can rewrite params, revisit.
  — **Reversibility:** one-way — this is the adopter-facing callback shape; changing it after
  release rewrites every adopter's reply-handling code.

- **D-18:** Crosswake owns the reserved event name and intercepts it via
  `Phoenix.LiveView.attach_hook/4`, validates and decodes, then `{:halt, socket}`s and
  `send`s the typed struct. The adopter never sees the raw event.

- **D-19:** **Reject per-call `reply_to:` event names.** Hotwire Native correlates by event
  name and its `receivedMessage(for:)` returns only the *last* message of that name —
  provably broken for N-in-flight. It also makes the event namespace unbounded and stringly
  typed, and prevents Crosswake from intercepting an unknown name, which would forfeit
  dedupe, timeout, and telemetry — the entire fail-closed story.

- **D-20:** **`correlation_id` stays library-internal; adopters get an opt-in opaque `ref:`.**
  `push/3` generates the correlation id (the natives already echo it on every ok and deny
  path); `ref` is the adopter's routing handle, echoed back, re-attached by the hook from its
  in-flight table, and **never crosses the native boundary and never enters telemetry**
  (cardinality). Precedent: `Phoenix.Channel`'s `ref`, `Plug.RequestId`.

- **D-21:** 20 rows with pending asks = **one** `handle_info` clause matching on `ref`.
  Haptics (fire-and-forget, no `ref:`) needs **no reply clause at all** — Crosswake consumes
  the reply after emitting telemetry. Passing `ref:` opts the adopter in, which is also how
  Phase 154 exercises the full correlated round trip against an already-shipped native.

- **D-22:** **Two timers.** Client-side timer in the hook (primary; dies with the client) plus
  a server-side backstop at `timeout + 2s` (guarantees no LiveView waits forever if the hook
  element is patched away). Default `10_000ms`, `:timeout` option per call, `:infinity`
  permitted for human-in-the-loop controls. Precedent: `GenServer.call` uses a caller timer
  *and* a monitor; `Task.await` uses a timeout *and* demonitor-flush.

- **D-23:** **Exactly-once delivery is structural, not conventional:** three-layer
  compare-and-delete keyed on `correlation_id` — hook in-flight map, server in-flight map in
  `socket.private`, and a per-mount **epoch** embedded in the correlation id. Anything failing
  a layer is dropped before adopter code runs, with telemetry.
  `Phoenix.LiveView.put_private/3`'s own docs designate it for exactly this: library state
  that needs no change tracking, prefixed with the library name.

- **D-24:** **An in-flight ask does NOT survive a LiveView reconnect.** Fresh epoch at mount;
  late replies drop as `:foreign_epoch`. Resurrecting them would replay a user's answer into a
  LiveView that never asked — precisely the "silently wrong" failure the project exists to
  prevent. Document it; the fallback UI rebuilt from assigns is the recovery path.

- **D-25:** **`API-DESIGN.md`'s double-answer fix is wrong and must not be implemented.**
  Routing the native reply and the on-page fallback click into the same event name does not
  deduplicate anything — it guarantees the same mutation runs twice. Ship
  **`Crosswake.Bridge.resolve(socket, ref)`**, an atomic compare-and-delete (safe because a
  LiveView is one serialized process), called once on the fallback handler; the native path is
  then deduped automatically because the ask is already gone. Phase 155's generated fallback
  components should ship with the call already in them.

- **D-26:** Wire event names use the **`crosswake:` prefix, not `cw:`** —
  `crosswake:bridge`, `crosswake:bridge_reply`, `crosswake:bridge_unreachable`,
  `crosswake:bridge_ack`. `cw:` appears in this codebase only as the CSS token prefix
  (`--cw-*`), where per-declaration brevity has a real cost justification. Everything
  protocol-side spells it out (`"crosswake.bridge"`, `window.crosswakeBridge`,
  `[:crosswake, ...]` telemetry). `push_event` names are page-global and also dispatched as
  `phx:<name>` on `window`, so the full prefix is collision-safe and greppable. Nothing has
  shipped with `cw:` on the wire, so this costs zero churn.

- **D-27:** Domain verbs stay at four, no synonyms: **push** (dispatch), **reply** (envelope),
  **answer** (the human's choice inside an ok payload), **denial/deny** (refusal). `invoke`
  survives only inside the existing `share.invoke` wire command.

- **D-28:** **Do not "clean up" the wire.** The `denial.denial` double nest and `Bridge.Denial`'s
  duplicated fields are ugly and will tempt a drive-by fix, but every shell binary already in
  the field emits that shape. Flatten in the Elixir decoder only; the wire is frozen until a
  `Contract.@version` major. `Bridge.Denial` is demoted to an internal wire-decode envelope
  with a moduledoc saying adopters match `Crosswake.Shell.Denial`.

- **D-29:** **Payload ceiling to record now:** both natives type the bridge payload as
  `[String: String]` / `Map<String,String>`. Phase 156's menu `actions:` list literally cannot
  fit. That is a **wire-only** `Contract.@version` bump in 156 (not an adopter-API break —
  the capability handshake already routes old natives to `unavailable_capability`, and 156 is
  native-rebuild-required regardless). Neither `GROUND-TRUTH.md` nor `API-DESIGN.md` notices
  this; 154 does not need to pre-solve it, but 156 must not be surprised by it.

### The JS hook — distribution and wiring detection

- **D-30:** **Ship the hook library-owned as `priv/static/crosswake.esm.js`.** Hand-authored
  dependency-free ESM, no build step, no minification. `priv` is already in the hex
  `files:` list, so packaging does not change. Add a repo-root `package.json` marked
  `"private": true` purely so bare-specifier / `file:./deps/crosswake` resolution works —
  **not** so anything is published to npm, which would open a second registry and a second
  version axis (Capacitor's documented drift failure).
  — **Reversibility:** costly — moving to a generated host-owned copy later means every
  adopter's import path changes.

- **D-31:** **This is not a violation of the no-component-tier anti-feature.** The project's
  own DNA states the rule: *"Use generators when adopters need editable app code. Keep
  security-sensitive or protocol-sensitive behavior library-owned."* The no-component-tier
  rule governs **presentation** — things adopters restyle. This hook is the client half of a
  versioned wire protocol whose single job is deciding whether a denial is synthesized.
  Generating a host-owned copy would mean silent protocol drift on the one file that decides
  whether the fail-closed contract holds.

- **D-32:** Reject option (b) generate-into-host outright for a second reason: **the reference
  host has no bundler at all.** `examples/phoenix_host/lib/crosswake_example/endpoint.ex`
  serves deps' JS via `plug Plug.Static, from: :phoenix_live_view` and
  `layouts.ex` imports from a bare `<script type="module">`. A generator writing into
  `assets/js/` writes into a directory nothing builds.

- **D-33:** Ship `mix crosswake.gen.bridge_hook --eject` as a deliberately inconvenient escape
  valve. Without the flag the task **refuses and prints the wiring instructions** — the
  refusal is the primary teaching surface. Ejected copies carry a stamped protocol header;
  doctor warns when it falls behind `Contract.version/0`.

- **D-34:** **Reject Cordova-style shell injection of the hook.** It is definitionally fatal:
  the hook's most important job is synthesizing a denial *when there is no shell*, and code
  shipped by the shell cannot run when there is no shell. It would also put the fastest-moving
  half of the contract (JS) behind the slowest release train (App Store review) and force
  `RebuildPolicy` to classify pure-JS changes as `native_required`. **Steal one piece:** the
  shells already inject `window.crosswakeBridge.capabilities` and `.threadId` at
  document-start on both platforms — keep that and have the hook read it. The shell injects
  *facts*; the library ships *logic*.

- **D-35:** **`API-DESIGN.md` §3's transport check has a real bug that would have shipped.**
  `window.webkit?.messageHandlers?.crosswakeBridge ?? window.crosswakeBridge` — on iOS the
  shell injects `window.crosswakeBridge` at document-start carrying `.capabilities`/`.threadId`
  and **no** `.postMessage`, so the `??` can resolve to the capabilities bag and post into the
  void. The shipped hook must order `webkit.messageHandlers` first **and** typecheck
  `typeof … === "function"`. Add a unit test for exactly this shape.

- **D-36:** **Hook-not-wired detection: a server-armed two-stage ack deadline, not a mount
  handshake.** The hook acks receipt (`crosswake:bridge_ack`) *before* touching the transport,
  so the deadline measures wiring, not shell latency. If no ack lands within ~2000ms,
  `Bridge.push/3` synthesizes the identical typed denial server-side with
  `details.failing_moment: :hook_not_wired`. A mount handshake false-negatives per route (an
  adopter can register `Hooks` correctly and still omit `phx-hook` on *this* route's tree).
  **Result: there is no configuration in which `Bridge.push/3` resolves to silence** — that is
  CTRL-02 in its strongest form. No comparable server-side detector exists anywhere in the
  Phoenix ecosystem.

- **D-37:** Backed by two more layers: a `mix crosswake.doctor` static check (precedent:
  `phase_66_generator_drift_findings/3` already greps host files) that must search **both**
  `assets/**` and `lib/**/*.heex` — an assets-only grep would fail the repo's own example host
  — and merge-blocking Playwright assertions. The grep is best-effort and must never be
  treated as authoritative; the runtime deadline is.

- **D-38:** Three route-tour tests, all browser-only (no simulator, honoring the v15 COLL-01
  wall): shell-absent → deny renders; shell-present simulated via `page.addInitScript()`
  (which runs at document-start, the exact injection point both real shells use, so it is a
  faithful stand-in) → ok renders; **hook deliberately unwired → the server-side
  `hook_not_wired` denial renders.** The third proves the safety net itself; without it, D-36
  is untested infrastructure.

- **D-39:** The hook carries a module-scoped **single-owner guard** — LiveView broadcasts
  `push_event` to every mounted hook on the page, so two hook elements would post every
  request to the shell twice.

- **D-40:** **HRDN-01 is a CSP hardening, not just a cleanup** — say so in the changelog. The
  hook is an external module file needing no `unsafe-inline`; the `Phoenix.HTML.raw` `<script>`
  IIFE it replaces requires `unsafe-inline` or a per-render nonce.

- **D-41:** `mix crosswake.install` **patches the endpoint** (canonical `Plug.Static` shape,
  reusing the existing `# crosswake:install:start` markers and idempotent semantics) and
  **prints** the layout/LiveSocket lines. Patch what is canonical; print what is not.

### The catalog-line guard (PROOF-04 / CTRL-04)

- **D-42:** **Do not create a new `priv/control_catalog.exs`.** The attestation file already
  exists and is already committed: `Manifest.Builder.capability_catalog/0`
  (`builder.ex:245-455`) is a compile-time literal carrying `owner`, `package_class`,
  `proof_class`, `rebuild`, `denial`, `fallback`, `guide`, `prerequisites` for all 15
  capabilities. A second catalog recreates exactly the two-lists-drift problem `API-DESIGN.md`
  rejects for a separate `controls:` DSL block — here it would be **five**-way drift
  (new file + catalog + `@commands` + `@capability_commands` + two native enums).

- **D-43:** Extend the existing catalog; add `Crosswake.Bridge.CatalogGuard` in **`lib/`**
  (not in the test), mirroring `Crosswake.CompanionGuard` — stdlib `Code.string_to_quoted/2` +
  `Macro.prewalk/3`, no new dependency. The rule living in `lib/` means deleting the test does
  not delete the rule, and doctor can call it.

- **D-44:** **Label the six criteria honestly rather than faking six mechanical checks.**
  Four are mechanical: (a) route-local/declarable — universally quantified over every command,
  not spot-checked; (c) zero external SDK — AST allowlist walk; (d) semantically bounded —
  six sub-assertions including `@commands` being a literal, no `register_*` function, no
  `apply/3` or atom-minting, and **native enum parity** against both `BridgeChannel` sources;
  (f) backend-authoritative — proxied by freezing `Reply`'s field set so it has nowhere to put
  an authority-carrying key. (b) low-frequency is mechanical **only in the negative** (we can
  prove no streaming seam exists; we cannot prove nobody calls haptics in a loop). (e)
  fails-closed is **hybrid** — 154 asserts the *declaration*, Phase 155's PROOF-01 route-tour
  asserts it *renders*. Say all of this in the test's moduledoc.

- **D-45:** **PROOF-04 does not stop maintainers adding forty controls one string at a time.**
  It closes the *mechanical* road to a plugin catalog completely. The inoculation against
  gradual sprawl is criteria (e)/(f) attestation plus CTRL-05 making each control's rebuild
  cost publicly named. Record this so the requirement does not quietly overclaim.

- **D-46:** **Negative controls, four ways** (extending 153.1's GATE-02 non-vacuity precedent):
  a multi-violation fixture that must report **all** violated criteria, not just the first;
  one inline synthetic per sub-assertion; a positive control on real shipped code; and an
  attestation check that rejects both gaps and **orphans**. Plus: if the Swift/Kotlin enum
  block cannot be located, that is a **failure, not a pass** (carrying forward phase 134's
  "job not found is an error" guard).

- **D-47:** **No new workflow file and no new required check.** An untagged file in
  `test/crosswake/proof/` is already executed by the broad hermetic step in at least five
  existing merge-blocking contexts (`phase130-proof.yml:84`, `phase132-proof.yml:91`,
  `phase43`, `phase45`, `phase34`). Phases 142, 145, 153, and 153.1 all shipped proof tests
  with zero new workflow files. This avoids the two-step rename/registration ritual entirely
  and adds ~100-200ms to an 88-second suite. **Phase 153.1 just cut wall-clock time-to-green
  from 34.9 min to 5.8 min — do not regress it.** If a named lane is wanted for evidence
  legibility, add a named `run:` *step* inside the existing job; a step name is free, a check
  name costs the ritual.

- **D-48:** The failure message keeps the bracketed stable id on line 1 for greppability, then
  breaks into a teaching heredoc naming which criterion failed, why the closed vocabulary
  exists (Cordova), and — critically — **the six-step recipe for legitimately adding control
  #7**. A gate with no documented path to "yes" gets deleted; a gate with one gets used.

### CTRL-05 rebuild class and `Capability.interaction`

- **D-49:** **CTRL-05 is a surfacing pass, not new machinery — ~85% already wired.** Exactly
  one leg is genuinely missing: doctor has **no capability-level rebuild finding** at all
  (`capability_posture_findings/1` groups by `proof_class` only; `native_rebuild_findings/2`
  is fed exclusively by commerce corridors). A developer with a `rebuild: :native_required`
  capability declared on a route gets no rebuild guidance today. Build
  `capability_rebuild_findings/1` (~40 lines + formatter coverage).

- **D-50:** The changelog leg is **already merge-blocking and stronger than the requirement
  asks** — `release_boundaries_test.exs:540-595` enforces exactly one `### Upgrade Impact`
  block per release from a locked 4-string vocabulary, with legend parity against
  `guides/support_matrix.md`. Ship as-is plus one cheap assertion that the vocabulary is
  derivable from `RebuildPolicy` verdicts. **Do not build a diff-based release gate** —
  `RebuildPolicy`'s own moduledoc warns `diff/2` is not a release-gate oracle without
  published-version history.

- **D-51:** **Two correctness holes to fix.** `Capability` `@enforce_keys` is `[:id, :version]`
  only, and `compatibility_capability_attrs(nil, id)` builds `rebuild: nil`, which makes
  `classify/2` raise `CaseClauseError` and `format_rebuild/1`'s silent catch-all render the
  literal string `"nil"` into the **published support matrix**. Fix the tolerant construction
  site with a fail-closed `rebuild: :native_required` default **first**, then add `:rebuild`
  and `:interaction` to `@enforce_keys`. Order matters — enforcing first turns a tolerant path
  into a crash.

- **D-52:** `@enforce_keys [:id, :version, :rebuild, :interaction]` is the **only** part of
  CTRL-04/CTRL-05 that earns the phrase "structurally impossible" — it makes a control without
  a declared rebuild class literally unconstructable at compile time. Everything else is
  CI-caught. State which is which so the requirement does not overclaim.

- **D-53:** Add a **rebuild column to the capability map** (`guides/capability_map.md`). Not
  named by CTRL-05, but it is the guide adopters read to *choose* controls, so omitting
  rebuild cost is the highest-leverage gap. One renderer change plus regeneration.

- **D-54:** **`Capability.interaction` is IN for Phase 154 — with three values, not the two
  `API-DESIGN.md` §4 proposes.** `:fire_and_forget | :device_answer | :user_answer`.
  Rationale: a two-value enum is ambiguous for four already-shipped commands (`app.info.get`,
  `permissions.status`, `notifications.token.get`, `files.pick` all return real payloads), and
  the ambiguity lands hardest on **share** — which returns `%{"outcome" => "requested"}`, *a
  payload*, so a maintainer reading a two-value enum would reasonably mark it `:answering`,
  which is precisely the lie the honesty rule exists to prevent. Under the three-value split,
  "share is `:fire_and_forget`" *is* the honesty constraint, machine-readable, in a committed
  literal a reviewer sees in the diff.
  — **Reversibility:** costly — the value set is serialized into the manifest schema and two
  hand-maintained native fixture files; changing it later is another schema bump.

- **D-55:** Doing `interaction` in 154 rather than 156 shares its migration with the `:rebuild`
  enforce-keys fix and the CTRL-05 surfacing pass already happening. Deferring means **two**
  `manifest_schema_version` bumps in one milestone, two fixture regenerations, two renderer
  passes, and a PROOF-04 edit — in a project whose brand is compatibility honesty. Cost is
  measured, not estimated: 3 committed JSON fixtures carry the sibling `rebuild` key, and the
  **native shells decode none of these fields**, so it is native-inert. Schema `1.0.0 → 1.1.0`
  is additive = `compatibility-bump only`, not rebuild-required.

- **D-56:** **Encode the checkable half of the share-honesty rule in 154; leave the typed
  `Outcome` sum type as prose until 157.** A ~15-line frozen outcome-vocabulary guard in the
  PROOF-04 file: capabilities declared `:fire_and_forget` may only emit `"outcome"` values
  from `["requested"]`, and `"completed"`/`"accepted"`/`"shared"`/`"succeeded"` must not appear
  as outcome values in `lib/crosswake/bridge/**` or the committed vectors. Building the
  `Outcome` struct now is speculative design against a control whose iPad-crash guard has not
  landed.

### Capability vocabulary (`haptics.impact` → `haptics`)

- **D-57:** **This is not an API change — `legacy_ids` is already fully wired and both forms
  already authorize.** `Manifest.Builder.@compatibility_route_capability_ids`
  (`builder.ex:30-37`), `Registry.capability_declared_on_route?/2` (`registry.ex:140-142`),
  `Registry.lookup_capability/2` (`:144-151`), `Manifest.Validator` (`validator.ex:434`).
  Zero adopter code breaks under any option. The only live question is what the docs *teach*.

- **D-58:** **Hard-switch the published vocabulary to family ids; keep `legacy_ids` accepted
  indefinitely; add a doctor advisory.** No deprecation warning.

- **D-59:** **A compile-time deprecation warning is mechanically impossible where it would
  matter.** `Crosswake.Router`'s macros only stash metadata; `Policy.Validator` never runs at
  router expansion; `Compiler.emit_warnings/2` is gated behind a flag only test support passes.
  Doctor is the only honest surface, and `Policy.Warning` + `Diagnostic` already exist to
  carry it. Elixir's own soft-deprecation ladder says step one is docs-only anyway.

- **D-60:** **The legacy path emits a malformed manifest today** — `compatibility_capability_attrs/2`
  (`builder.ex:469-474`) copies the family's attrs and overrides `:id`, producing a capability
  whose own `legacy_ids` names itself, so the shipped example manifest carries **two** haptics
  registry entries where one is correct (verified in
  `examples/ios_shell_host/Fixtures/crosswake_manifest.json:141-148`). Fix in the same PR;
  flipping the router deletes the duplicate. **Call this out in the PR body** — a reviewer
  seeing a capability vanish from a shipped manifest will correctly flag it.

- **D-61:** Blast radius for the rename itself is **one router line**
  (`examples/phoenix_host/lib/crosswake_example/router.ex:330`) — the only first-party legacy
  declaration in the repo. `bridge-proof` already uses the family form. Everything else that
  greps as `haptics.impact` is the *wire command* and is correct as-is.

- **D-62:** `"haptics"` is the better public noun: route policy declares **families**
  (authorization intent); the bridge dispatches **commands** (transport). Precedent for the
  mechanism is `Ecto.Enum` value aliasing — one canonical public vocabulary, translation at
  the boundary. Crosswake already built the right mechanism and simply never used it in its
  own examples.

- **D-63:** Breaking the legacy form (removing the aliases) is rejected. Ash 3.0 did a
  comparable rename but shipped `igniter` codemods and a section-by-section upgrade guide, at
  a **major**. Crosswake has no codemod tooling, this is a duplicated-noun cleanup rather than
  a concept rename, and `0.2.x` on Hex means real `mix.lock` entries exist. "It's pre-1.0 so
  it's fine" is an author's argument, not an adopter's experience (Absinthe 1.4→1.5 is the
  cautionary case).

### HRDN-01 — haptics migration and the showcase evidence panel

- **D-64:** **The evidence panel survives and gets more honest.** Replace the single
  `bridge_request` assign with `bridge_dispatch` + `bridge_reply`; keep the `<dl>`; add a
  Reply row in a `role="status" aria-live="polite" aria-atomic="true"` live region.
  Deleting it would trade the showcase's strongest honesty artifact for tidiness.

- **D-65:** The JTBD argument that decides it: the reader is a skeptical Phoenix developer
  running the showcase **in a desktop browser, where there is no shell at all**. Today they
  click Approve and see four fields proving only that Phoenix built an envelope. After
  migration the *default desktop experience* becomes the strongest demo — "Shell declined ·
  `shell_unreachable` · there is no browser substitute for a physical tap, so Crosswake does
  nothing rather than fake one. The approval stands." That is the fail-closed thesis rendering
  itself, for free, on every visit.

- **D-66:** Label the two rows distinctly — **Capability (route policy)** vs **Command (wire
  protocol)**. This teaches D-62's distinction at the exact moment a developer is looking at
  both, which no guide sentence can do as well.

- **D-67:** The panel must render from the envelope `Bridge.push/3` actually built — never a
  hand-copied summary. Otherwise the migration reintroduces `API-DESIGN.md` §0's problem #1
  (hand-built envelopes drifting from the manifest) in a new place.

- **D-68:** Where the "hide the guts" line sits: this panel is the deliberate exception, and it
  shows **four semantic fields plus a verdict**, not a raw JSON dump. `bridge_proof_live.ex`
  keeps its raw `<pre>` dump. Curated evidence in the product-shaped showcase; raw protocol in
  the protocol-proof route. Preserve that separation.

- **D-69:** Idle state copy is honest and non-apologetic per brand spec: *"No haptics request
  sent. Phoenix sends one only after an approval commits."* No "coming soon", no "nothing here
  yet". All styling via existing `.adminpilot-panel` + `tokens.css` variables, so light/dark/
  system and the contrast gates are inherited and nothing here is interactive.

- **D-70:** **Migrate `bridge_proof_live.ex` too.** Its IIFE is byte-identical to the one
  HRDN-01 deletes; leaving it makes "the hand-rolled `<script>` IIFE is **gone**" literally
  false in the shipped showcase and leaves the exact copy-paste template Pack 1 exists to
  eliminate sitting where an adopter will find it. Its route already declares
  `capabilities: ["share"]` (family form), so it authorizes with no vocabulary coupling.
  **Keep** its raw `<pre id="crosswake-bridge-payload">` surface — `route_tour.spec.ts`
  `JSON.parse`s it.

- **D-71:** **Delete `examples/phoenix_host/assets/js/app.js`.** Never served (absent from the
  endpoint's `Plug.Static` `only:` allowlist; the example host has no bundler), wrong handler
  name (`crosswake` vs `crosswakeBridge`), wrong Android object (`window.CrosswakeAndroidBridge`
  exists nowhere), wrong message shape (`{action, payload, timestamp}` shares zero fields with
  `Bridge.Contract`), and it carries a `T-89-01` threat-mitigation comment for a boundary it
  does not implement — a false security claim in an evidence-first repo.

- **D-72:** **Coupled edit:** `.planning/seeds/SEED-006-native-navigation-shell.md:71`
  describes that file as an *existing* web↔native nav-intent seam. That premise is false, and
  deleting the file leaves the seed referencing nothing. Amend SEED-006 in the same PR to say
  the nav-intent seam does not exist yet and would be built on `Bridge.push/3` — otherwise a
  future milestone plans against a bridge that was never real.

- **D-73:** **Amend, do not rewrite, the Phase 149 D-07/D-12 showcase contracts.** Both remain
  true and are *strengthened*: `Bridge.push/3` is called inside the `{:ok, approved}` branch
  after the context commits, and the deny reply is now rendered rather than merely implied.
  Keep the amendment as short bold-prefix bullets matching the existing D-NN format
  (the decision-coverage parser false-negatives on long-bold/embedded-colon bullets).

- **D-74:** **Highest-risk single edit in the phase:** `route_tour.spec.ts:431-438`
  `approvalHapticsPayload()` locates `#crosswake-approval-haptics` and regex-scrapes
  `const payload = "..."` out of a `<script>` tag **that is being deleted** — and it gates a
  required check. Mitigation: have the panel emit `data-cw-envelope={Jason.encode!(...)}` on
  the `<section>` so the helper becomes one `JSON.parse(getAttribute(...))` with no regex, and
  the human-readable `<dl>` stays free to change without breaking CI. Decide in the plan, not
  during execution.

- **D-75:** `push_event` requires a **connected** LiveView, and `layouts.ex:25-34` currently
  has no hooks map. If the hook is not registered the panel sits at "Waiting for the shell"
  forever — which *looks* plausible and would pass a careless assertion. Require an explicit
  positive assertion that a reply arrived (deny is fine) before declaring the migration green.

### Sequencing

- **D-76:** **Land as three PRs, in order.** (1) Docs + route policy speak family ids, plus the
  `builder.ex` self-referential-`legacy_ids` fix and fixture regeneration — no behavior change,
  IIFE deliberately untouched so the e2e helper is not rewritten while the vocabulary moves.
  (2) `Bridge.push/3` + hook + denial contract + catalog guard, unit-tested only, no showcase
  changes. (3) HRDN-01: migrate both LiveViews, evolve the panel, delete `app.js`, amend
  SEED-006 and 149-CONTEXT. Do not combine (1) and (2) — the vocabulary flip touches five
  gates and you want a clean bisect point if `merge-blocking-offline-sync-e2e` goes red.

- **D-77:** **Scope honesty.** As designed this phase includes a shipped JS asset, the iOS
  return leg, `attach_hook` lifecycle machinery, a test helper (`Crosswake.Bridge.Test`,
  without which `render_hook/3` with a fabricated id is correctly dropped and adopters will
  think the seam is broken), a 14th denial reason, a manifest schema bump, and a structural
  guard. That is materially larger than "ship `Bridge.push/3` and migrate haptics." Size it
  honestly in planning rather than discovering it mid-execution.

### Claude's Discretion

The user asked for a single coherent recommendation set rather than sequential questions, and
explicitly asked not to have to arbitrate. Every decision above is therefore Claude's call
from researched evidence. The items most worth a human glance before execution are D-02
(iOS return leg — touches milestone sequencing), D-16 (a structural test that fails today),
D-17 (marked one-way; also carries a verification caveat), and D-77 (scope).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone decision record (read first)
- `.planning/research/v20/SUMMARY.md` — control verdicts, the six-criteria catalog line, architecture decisions, footgun ledger
- `.planning/research/v20/API-DESIGN.md` — the adopter-facing API and rejected alternatives. **Read with D-14, D-25, and D-35 in hand: §3's draft hook builds denials client-side (overridden), §3's transport check has a latent iOS bug, and the double-answer fix in the consumer critique does not work.**
- `.planning/research/v20/GROUND-TRUTH.md` — file-level delta and rebuild-class analysis
- `.planning/research/v20/UX-CONTRACT.md` — per-control JTBD, degradation, a11y, microcopy
- `.planning/research/v20/RELEASE-STRATEGY.md` — proof-lane composition; the no-simulator constraint
- `.planning/research/v20/VISION-COHERENCE.md` — core-vs-companion, the catalog line, anti-scope
- `.planning/research/v20/PRIOR-ART.md` — Hotwire/Capacitor/Expo/Flutter/RN comparison, footgun ledger

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` — CTRL-01..05, PROOF-04, HRDN-01, and the **Out of Scope** section (the closed-vocabulary line lives there)
- `.planning/ROADMAP.md` — Phase 154 goal and success criteria; Phases 155/156/157 for forward-compat
- `.planning/PROJECT.md`

### Brand and engineering DNA
- `brandbook/BRAND-SPEC.md` — **the current brand spec; supersedes `prompts/crosswake-brand-book.md`.** §2 pillar 3 "No hidden bridge magic"; §6 error-message rule ("calm, specific, actionable — name what happened, what to do next"); §6 empty-state and release-note voice rules
- `prompts/crosswake-elixir-oss-dna.md` — §"Package design": *"Use generators when adopters need editable app code. Keep security-sensitive or protocol-sensitive behavior library-owned."* — the sentence that decides D-31
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md`
- `prompts/crosswake-gsd-project-brief.md`

### The seam being built
- `lib/crosswake/bridge/contract.ex` — `Request`/`Reply`, `@commands` literal, `@version "1.1.0"`
- `lib/crosswake/bridge/registry.ex` — `lookup/4` is the single authorization source for **both** directions (D-04)
- `lib/crosswake/shell/denial.ex` — the closed 13-reason vocabulary gaining `:shell_unreachable`
- `lib/crosswake/bridge/denial.ex` — demoted to an internal wire envelope (D-28)
- `lib/crosswake/compatibility/compatibility.ex` — `finding_to_denial/2`, deliberately unchanged (D-15)
- `lib/crosswake/manifest/types.ex` — `Capability` struct, `@enforce_keys` (D-51, D-52)
- `lib/crosswake/manifest/builder.ex` — `capability_catalog/0` (the attestation file, D-42), `@compatibility_route_capability_ids` (D-57), `compatibility_capability_attrs/2` (D-60)
- `lib/crosswake/runtime_line/rebuild_policy.ex` — `classify/2`; its moduledoc warns `diff/2` is not a release-gate oracle (D-50)
- `lib/crosswake/native_escape/contract.ex` — `@purposes [:media_capture]`, the precedent for holding an escape hatch to one typed purpose

### Native side
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift` — closed enum; `:170-178` the dropped reply (D-02); out-of-vocabulary denial reasons (D-16)
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShell.swift` — the `replySink` gap
- `examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift:244-247` — `replySink: { _ in }`
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:59-85` — the working duplex path
- `test/fixtures/bridge_contract_vectors.json` — plus the two mirrored copies under `packages/*/Tests|test/resources`

### Precedents to mirror
- `lib/crosswake/companion_guard.ex` — the AST-guard technique and "the guard travels with the code" rationale (D-43)
- `test/crosswake/proof/phase153_1_gate_integrity_test.exs` — non-vacuous gate + negative control (D-46)
- `test/crosswake/proof/phase130_extraction_guards_test.exs`, `phase134_native_gate_blocking_proof_test.exs`
- `test/crosswake/guides/release_boundaries_test.exs:540-595` — the already-merge-blocking `### Upgrade Impact` machinery (D-50)
- `lib/crosswake/doctor/doctor.ex:1958-2040` — `phase_66_generator_drift_findings/3`, the host-file-grep precedent (D-37)
- `lib/mix/tasks/crosswake.gen.offline_ui.ex` — the verbatim-copy generator this phase deliberately does **not** follow (D-31)
- `examples/phoenix_host/lib/crosswake_example/endpoint.ex` — the `Plug.Static`-from-deps pattern (D-30, D-41)
- `examples/phoenix_host/lib/crosswake_example/layouts.ex:25-34` — no-bundler ESM import; no hooks map yet (D-75)

### Migration targets
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` — the IIFE and the evidence panel
- `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` — the second IIFE (D-70)
- `examples/phoenix_host/lib/crosswake_example/router.ex:330` — the only first-party legacy declaration (D-61)
- `examples/phoenix_host/assets/js/app.js` — delete (D-71)
- `examples/phoenix_host/e2e/route_tour.spec.ts:168,196-201,431-438` — the required-check assertions, incl. the high-risk helper (D-74)
- `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` — D-07/D-12, amend only (D-73)
- `.planning/seeds/SEED-006-native-navigation-shell.md:71` — false premise to amend (D-72)

### Guides that must stay true
- `guides/bridge.md`, `guides/capabilities.md`, `guides/route_policy.md`, `guides/capability_map.md`, `guides/support_matrix.md`, `guides/compatibility.md`, `guides/telemetry.md`, `guides/adopter_profiles.md`, `guides/web_to_mobile_migration.md`

### Prior-phase context
- `.planning/phases/153.1-ci-gate-integrity-and-runner-cost/153.1-CONTEXT.md` — required-check ritual, non-vacuous gates, never `paths:`-filter a required context
- `.planning/phases/153.1-ci-gate-integrity-and-runner-cost/153.1-RESULTS.md` — the 5.8-minute baseline this phase must not regress

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Bridge.Registry.lookup/4`** already returns `:undeclared_capability` / `:inactive_route` / `:unsupported_command` against the compiled manifest — it is the single authorization source for both the raise and the denial (D-04). No new authorization code.
- **`Crosswake.Shell.Denial`** already exists with a closed reason vocabulary, `details`/`recovery` maps, and reason-scoped defaulting (the `:commerce_corridor` precedent shows how `:shell_unreachable` should default its `details`).
- **`Bridge.Contract.Request/Reply`** already carry `correlation_id` and it already round-trips — both natives echo it on **every** ok and deny path, which is the only thing the hook's correlation table needs. This is what makes "prove the seam with haptics, zero native risk" true.
- **`Manifest.Builder.capability_catalog/0`** is already the committed attestation file PROOF-04 needs (D-42).
- **`Crosswake.CompanionGuard`** is a working AST-guard to mirror, including its documented child-module prefix-match pitfall.
- **`Capability.legacy_ids`** is already wired end-to-end, so the vocabulary migration is docs-only (D-57).
- **`Crosswake.Install.Patcher`** has idempotent marker-based patching to extend to the endpoint (D-41).
- **`Phoenix.LiveView.put_private/3`** is documented for exactly the in-flight table's purpose (D-23).

### Established Patterns
- **Proof tests** live at `test/crosswake/proof/phaseNNN_*_test.exs`, untagged, and are picked up by existing merge-blocking hermetic lanes — no new workflow needed (D-47).
- **Gates must ship a negative control** proving they are not vacuous (153.1 GATE-02).
- **Every proof lane runs `--warnings-as-errors`**, which makes `@behaviour` callbacks and `@enforce_keys` hard gates rather than advisory.
- **Evidence is a product feature** — preserve job names, logs, artifacts, and the showcase's rendered evidence surfaces.
- **Docs-vs-code honesty gates are merge-blocking** — a vocabulary rename trips several at once (D-76 sequences around this).

### Integration Points
- `Bridge.push/3` needs `route_id`, the manifest, and the shell handshake from `socket.private` → requires a `Crosswake.Bridge.attach/1` or `on_mount/1`. Missing it must raise a named `NotMountedError`, never guess a route id. **This is a brand-new install-time failure surface every adopter hits exactly once** — install guide and a doctor check must cover it, or the milestone's headline API becomes "raises on first use."
- The hook element must sit in a live-rendered tree with a stable DOM id, ideally once in the app layout; LiveComponents need `pushEventTo` with the cid plumbed through.
- New telemetry joins the existing `Crosswake.Telemetry` catalog: `[:crosswake, :bridge, :push, :start|:stop|:exception]`, `[:crosswake, :bridge, :reply]` (with a bounded 14-atom `denial_reason`), `[:crosswake, :bridge, :reply, :dropped]`, `[:crosswake, :bridge, :hook, :ack|:missing]`. `hook.missing` should always be zero in a healthy deploy — document it that way.
- `manifest_schema_version` `1.0.0 → 1.1.0` (additive) touches 3 committed JSON fixtures; the natives decode none of the affected fields.

</code_context>

<specifics>
## Specific Ideas

- The showcase evidence panel's **desktop-browser default state is the demo**: a developer with no shell should see the fail-closed thesis render itself — "Shell declined · `shell_unreachable` · there is no browser substitute for a physical tap, so Crosswake does nothing rather than fake one. The approval stands."
- The PROOF-04 failure message should close with a line in the project's own voice: *"This gate does not exist to stop control #7. It exists to make control #7 look exactly like controls #1-6."*
- `mix crosswake.gen.bridge_hook` with no flag **refuses and teaches** — the refusal text is the primary onboarding surface for the hook, not a guide nobody opens.
- Simulate the shell-present path in CI with Playwright's `page.addInitScript()`, which runs at document-start — the exact injection point both real shells use (`WKUserScript(injectionTime: .atDocumentStart)` / `WebViewCompat.addDocumentStartJavaScript`). That is a faithful stand-in, not a hand-wave, and it needs no simulator.

</specifics>

<deferred>
## Deferred Ideas

- **Flattening the `denial.denial` double nest and `Bridge.Denial`'s duplicated fields** — frozen until a `Contract.@version` major; every shell binary in the field emits that shape (D-28).
- **Typed `Crosswake.Bridge.Outcome` sum type** — Phase 157, alongside share's iPad-crash guard (D-56).
- **Request-payload widening beyond `[String: String]`** — Phase 156, as a wire-only `Contract.@version` bump (D-29).
- **Per-capability default timeouts on the `Capability` record** — Phase 156.
- **`action_menu.dismiss`** (closing the native sheet when the fallback wins the race) — Phase 156.
- **`<.cw_action_menu>` / per-family HEEx wrappers** — Phase 155/156; the seam is already data-driven. Never a generic `<.cw_control type="...">` dispatcher.
- **Whether `Manifest.Builder` should mint a compat capability-registry entry at all for legacy ids**, versus resolving to the family entry and recording the alias on the route — a manifest *shape* change that reaches shipped shells. Defer.
- **Fixing the natives' out-of-vocabulary denial reasons (D-16)** — in 154 if affordable; otherwise it must be deferred **explicitly with a named seed**, not silently.

</deferred>

---

*Phase: 154-the-control-contract-seam*
*Context gathered: 2026-07-29*
