---
phase: 154-the-control-contract-seam
plan: 06
subsystem: api
tags: [javascript, esm, liveview-hook, swift, webkit, kotlin, mix-task, doctor, contract-vectors]

requires:
  - phase: 154-the-control-contract-seam
    provides: "Plan 04's epoch tracking, exactly-once delivery, resolve/2, the two correlation timers, and the four reserved wire event names in Crosswake.Bridge"
  - phase: 154-the-control-contract-seam
    provides: "Plan 03's Crosswake.Bridge facade, Bridge.Reply, and the :shell_unreachable denial reason every client-detectable failure collapses onto"
  - phase: 154-the-control-contract-seam
    provides: "Plan 05's merge-blocking CatalogGuard (untouched here — this plan adds no native command)"
provides:
  - "priv/static/crosswake.esm.js — the library-owned client half of the crosswake.bridge wire protocol"
  - "window.crosswakeBridge.__reply — the reply landing pad, now part of the shipped client/native contract"
  - "the iOS reply return leg (BridgeReplyDelivery) with injection-safe serialization"
  - "reply_leg_vectors in the committed bridge contract vectors, consumed by both native suites"
  - "mix crosswake.gen.bridge_hook (refuse-and-teach, with --eject)"
  - "Crosswake.Install.Patcher.patch_endpoint/1 and the installer's printed layout wiring"
  - "Crosswake.Doctor.bridge_hook_wiring_findings/2"
  - "a private, zero-dependency repo-root package.json and the Node built-in test suite"
affects: [154-07, 154-08, 156, native-controls-pack-2]

tech-stack:
  added: []
  patterns:
    - "Library-owned client protocol half served from priv/static/ — no build step, no npm, no generated copy"
    - "Ordered transport lookup with an explicit function-type check per candidate (never null-coalescing)"
    - "Ack-before-transport so a server-armed deadline measures wiring rather than shell latency"
    - "Module-scoped single-owner guard for LiveView hooks whose events broadcast page-wide"
    - "Native→WebView reply delivered as a parsed JSON string literal, never interpolated into script source"
    - "Refuse-and-teach mix generator: the refusal is the onboarding surface"
    - "Patch what is canonical, print what is not"
    - "Best-effort doctor host-file grep, explicitly documented as never authoritative"

key-files:
  created:
    - priv/static/crosswake.esm.js
    - package.json
    - test/js/crosswake_esm_test.mjs
    - lib/mix/tasks/crosswake.gen.bridge_hook.ex
    - test/mix/tasks/crosswake_gen_bridge_hook_test.exs
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeReplyLegTest.kt
  modified:
    - packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShell.swift
    - examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift
    - lib/mix/tasks/crosswake.contract.gen.ex
    - lib/crosswake/install/patcher.ex
    - lib/mix/tasks/crosswake.install.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/support_matrix/renderer.ex
    - guides/install.md
    - guides/bridge.md
    - guides/support_matrix.md
    - .github/workflows/offline-sync-e2e-gate.yml
    - test/fixtures/bridge_contract_vectors.json (+ 2 mirrored copies)

key-decisions:
  - "The hook ships from priv/static/crosswake.esm.js at the literal D-30 path, served at /crosswake/crosswake.esm.js — nesting under priv/static/crosswake/ would have doubled the URL path segment"
  - "reply_leg_vectors is its own top-level array, NOT an entry in `vectors` — `vectors` is a request-evaluation corpus and both native harnesses feed every entry through BridgeChannel.evaluate"
  - "The iOS reply is embedded as a JSON string literal the evaluated script parses, with U+2028/U+2029 escaped explicitly on top of JSON escaping"
  - "D-03's honesty statement lands as a new generated `## Bridge Reply Delivery` per-path table rather than as an edit to the haptics capability cell — guides/support_matrix.md is byte-generated from Crosswake.SupportMatrix.Renderer and the capability row has no column that could carry a shipping date"
  - "The doctor wiring finding is :advisory severity (the ejected-stamp drift finding is :warning) so the best-effort grep can never fail doctor's exit code"
  - "The eject target is the host's priv/static/, never assets/js/ — the reference host has no bundler at all"

patterns-established:
  - "Transport selection: look up the iOS message handler first, then the injected global, typechecking each candidate's post method — a facts-only injection bag must never be mistaken for a transport"
  - "Reply landing pad + client in-flight map as the third exactly-once layer, gating before the server's own three-layer compare-and-delete"
  - "Contract-vector generator gains `:empty_object` as the explicit spelling for `{}` (a bare `[]` pairs list encodes as a JSON array and fails native map decoding)"

requirements-completed: [CTRL-01, CTRL-02]

coverage:
  - id: D1
    description: "The library-owned bridge hook selects its transport safely — iOS message handler first, explicit function-type check per candidate, never null-coalescing — so the document-start facts-only bag can never be mistaken for a transport"
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#a facts-only injected global is never called and yields the unreachable fact"
        status: pass
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#the message-handler path wins when both transports are present"
        status: pass
    human_judgment: false
  - id: D2
    description: "The hook acks every dispatch before any transport lookup, so a push can never resolve to silence in any configuration"
    requirement: CTRL-02
    verification:
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#the ack is emitted before any transport lookup, for every dispatch"
        status: pass
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#with no transport at all the hook posts nothing and reports the no_transport moment"
        status: pass
    human_judgment: false
  - id: D3
    description: "A second mounted hook element does not double-post to the native shell"
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#two mounted hook elements produce exactly one post per dispatch"
        status: pass
    human_judgment: false
  - id: D4
    description: "The hook reports facts with a moment identifier and never constructs a denial — denial microcopy exists only in Elixir"
    requirement: CTRL-02
    verification:
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#the unreachable report carries a moment and nothing denial-shaped"
        status: pass
      - kind: unit
        ref: "test/js/crosswake_esm_test.mjs#the shipped source contains no denial microcopy"
        status: pass
    human_judgment: false
  - id: D5
    description: "The iOS reply return leg delivers a reply to the hook's landing pad through an injection-safe evaluation path, with an adversarial payload arriving byte-intact and a serialization failure evaluating nothing"
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift#test_adversarial_denial_message_is_delivered_byte_intact"
        status: pass
      - kind: unit
        ref: "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift#test_adversarial_payload_cannot_terminate_or_extend_the_evaluated_script"
        status: pass
      - kind: unit
        ref: "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift#test_script_is_nil_when_serialization_fails"
        status: pass
    human_judgment: false
  - id: D6
    description: "The committed contract vectors gained a reply-leg case that both native suites consume, and all three copies stay byte-identical"
    requirement: CTRL-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/contract/contract_drift_test.exs"
        status: pass
      - kind: unit
        ref: "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeReplyLegTest.kt#adversarial reply content survives Android's duplex path byte-intact"
        status: pass
    human_judgment: false
  - id: D7
    description: "mix crosswake.gen.bridge_hook with no flag writes nothing and prints all three wiring fragments; --eject writes a protocol-stamped copy and is idempotent"
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/crosswake_gen_bridge_hook_test.exs#with no flag it writes nothing and prints all three wiring fragments"
        status: pass
      - kind: unit
        ref: "test/mix/tasks/crosswake_gen_bridge_hook_test.exs#running the eject twice is idempotent and does not duplicate the stamp"
        status: pass
    human_judgment: false
  - id: D8
    description: "mix crosswake.install patches the endpoint's static plug block inside the existing markers and prints the layout import, hooks map, and hook element"
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/crosswake_install_test.exs#patches the endpoint's static plug block, prints the layout wiring, and stays idempotent"
        status: pass
    human_judgment: false
  - id: D9
    description: "Doctor names an unwired hook by searching BOTH the assets tree and the HEEx templates, at advisory severity, and warns on ejected-copy protocol drift"
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "test/crosswake/doctor/doctor_test.exs#reports nothing when the hook is found in a HEEx-only host with no assets directory"
        status: pass
      - kind: unit
        ref: "test/crosswake/doctor/doctor_test.exs#warns when an ejected copy's stamped protocol version is behind the contract"
        status: pass
      - kind: unit
        ref: "test/crosswake/doctor/formatter_test.exs#renders the bridge hook wiring findings with their severity, hint, and details"
        status: pass
    human_judgment: false
  - id: D10
    description: "guides/support_matrix.md states that iOS native reply delivery reaches adopters with the Phase 156 native release rather than claiming uniform completeness"
    requirement: CTRL-01
    verification:
      - kind: integration
        ref: "mix test test/crosswake/support_matrix/renderer_test.exs (guide is byte-identical to canonical renderer output)"
        status: pass
    human_judgment: false
  - id: D11
    description: "Adopter-facing guide copy for push/3, the reply handle_info/2 clause, resolve/2, the attach requirement, and the hook wiring steps"
    verification: []
    human_judgment: true
    rationale: "Prose quality and whether the attach requirement reads prominently enough to prevent the 'raises on first use' first impression is an editorial judgment no test can make."

duration: 34min
completed: 2026-07-29
status: complete
---

# Phase 154 Plan 06: The Shipped Client Half And The iOS Return Leg Summary

**One dependency-free ESM file now speaks the client half of `crosswake.bridge` — it cannot post into the void, acks before it transports, refuses to double-register, and reports facts rather than denials — and iOS replies finally come home through an injection-safe evaluation path proven by Swift tests and committed vectors.**

## Performance

- **Duration:** 34 min
- **Started:** 2026-07-29T19:29Z
- **Completed:** 2026-07-30T00:02Z
- **Tasks:** 3 of 3
- **Files modified:** 24 (14 created, 10 modified)

## Accomplishments

- **The client half exists and is library-owned.** `priv/static/crosswake.esm.js` is hand-authored, dependency-free ESM with no build step, no minification, and nothing published to a second package registry. Its transport lookup checks the iOS message handler first and then explicitly typechecks each candidate's `postMessage` — the exact D-35 hazard (the document-start facts-only bag on iOS) has its own dedicated test asserting the hook invokes *nothing* on it.
- **`push/3` can no longer resolve to silence.** The hook emits the ack before any transport lookup for every dispatch it receives, which is what makes the server-armed deadline measure wiring rather than shell latency. With no transport at all it emits the unreachable fact carrying a moment and nothing else — no denial is ever constructed client-side.
- **The iOS return leg is closed.** `BridgeReplyDelivery` serializes the reply envelope and embeds it as a JSON string literal the evaluated script parses, never interpolating envelope fields into script source text. A Swift test feeds a denial message carrying quote, backslash, newline, `</script>`, U+2028, and U+2029 and asserts it arrives byte-identical while no raw line terminator survives into the emitted source. A serialization failure evaluates nothing at all.
- **The support matrix says when adopters get it.** A new generated `## Bridge Reply Delivery` table states server-synthesized denials as supported everywhere, Android native replies as supported, and iOS native replies as landing in-repo now but reaching adopters with the **Phase 156** native release.
- **Wiring became survivable.** `mix crosswake.gen.bridge_hook` refuses by default and prints all three fragments; `mix crosswake.install` patches the canonical endpoint plug and prints the host-authored layout wiring; `mix crosswake.doctor` greps both the assets tree and the HEEx templates and warns on ejected-copy protocol drift.

## Task Commits

1. **Task 1: The library-owned hook** — `dbc1d113` (feat)
2. **Task 2: Close the iOS reply return leg** — `8be02608` (feat)
3. **Task 2 (vectors): regenerate contract vectors** — `5b80a3a4` (chore, separate per the plan's verification gate)
4. **Task 3: Distribution surfaces** — `bee80099` (feat)

## Files Created/Modified

- `priv/static/crosswake.esm.js` — the client half: transport selection, ack-before-transport, single-owner guard, `__reply` landing pad, client reply timer
- `package.json` — private, zero-dependency repo-root manifest; `npm test` runs the Node built-in suite
- `test/js/crosswake_esm_test.mjs` — 22 tests over a hand-stubbed global; no test framework, no browser
- `.github/workflows/offline-sync-e2e-gate.yml` — the hook suite as a named STEP in the existing Node-provisioned `guard-01` job (no new required check)
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/CrosswakeShell.swift` — `BridgeReplyDelivery` (landing pad name, `script/2`, `sink/1`) plus a `createBridgeChannel(…evaluateJavaScript:)` overload
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift` — 8 tests including the adversarial payload and the serialization-failure path
- `packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeReplyLegTest.kt` — 3 tests proving Android's duplex path is unchanged
- `examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift` — the sink is no longer a no-op closure
- `lib/mix/tasks/crosswake.contract.gen.ex` — `reply_leg_vectors` and the `:empty_object` encoding spelling
- `lib/mix/tasks/crosswake.gen.bridge_hook.ex` — refuse-and-teach generator with `--eject`
- `lib/crosswake/install/patcher.ex` — `patch_endpoint/1`, `endpoint_static_plug_block/1`, `layout_wiring_lines/0`, `hook_name/0`, `hook_url/0`
- `lib/mix/tasks/crosswake.install.ex` — endpoint patching plus the printed layout-wiring notice
- `lib/crosswake/doctor/doctor.ex` — `bridge_hook_wiring_findings/2` and the ejected-stamp drift check
- `lib/crosswake/support_matrix/renderer.ex` + `guides/support_matrix.md` — the `## Bridge Reply Delivery` section
- `guides/install.md` — Step 1b plus the attach-before-push requirement
- `guides/bridge.md` — `## The Adopter API`: attach, `push/3`, the reply `handle_info/2` clause, `resolve/2`, the reconnect epoch rule

## Decisions Made

- **`reply_leg_vectors` is a new top-level array, not an entry in `vectors`.** `vectors` is a request-evaluation corpus — every native harness feeds each entry through `BridgeChannel.evaluate`. A reply-leg case has no request to evaluate, so folding it in would have made both harnesses evaluate a phantom request.
- **`:empty_object` added to the vector generator's encoder.** The encoder spells "JSON object" as a pairs list, so an empty object could not be spelled `[]` — that emits a JSON *array*, which then fails to decode into the native `[String: String]` / `Map<String, String>` payload types.
- **The D-03 honesty statement is a new generated table, not an edit to the haptics capability cell.** `guides/support_matrix.md` is asserted byte-identical to `Crosswake.SupportMatrix.Renderer.render/1` output, and the capability row has no column that could carry "the reply comes back on this platform in a later release." Widening the capability cell to imply completeness is precisely the claim D-03 prohibits, so the statement lives in a per-reply-path table with its own baseline and proof-status columns.
- **The wiring finding is `:advisory`, the ejected-stamp finding is `:warning`.** Neither can fail doctor's exit code, which keeps D-37's "the grep is never authoritative; the runtime deadline is" true mechanically and not just in a comment.
- **A host with no resolvable endpoint prints guidance rather than failing the install.** The static plug block is four lines an adopter can place by hand; failing an additive installer over it would be worse than saying so.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] `node --test test/js/` does not scan directories on the installed Node**

- **Found during:** Task 1
- **Issue:** The plan's `<verify>` and acceptance criterion specify `node --test test/js/`. On Node v22.14.0 (this repo's asdf-pinned runtime) that form resolves the positional argument as a *module path* and dies with `Cannot find module '…/test/js'`. Reproduced in a clean scratch directory, so it is the runtime's behavior and not a repo artifact.
- **Fix:** Used the glob form `node --test "test/js/*.mjs"` as the single canonical invocation — in the repo-root `npm test` script, in the CI step, and in the plan's verification. Behavior is otherwise identical: 22 tests, exit 0.
- **Files modified:** `package.json`, `.github/workflows/offline-sync-e2e-gate.yml`
- **Verification:** `npm test` exits 0; `node --test "test/js/*.mjs"` reports 22 pass / 0 fail.
- **Committed in:** `dbc1d113`

**2. [Rule 3 — Blocking] The support matrix guide is byte-generated, so it cannot be hand-edited**

- **Found during:** Task 2
- **Issue:** The plan's action says to "update `guides/support_matrix.md`". That file is asserted byte-identical to `Crosswake.SupportMatrix.Renderer.render(Crosswake.SupportMatrix.canonical())` by `test/crosswake/support_matrix/renderer_test.exs`; a hand edit would have failed that merge-blocking parity test.
- **Fix:** Added `bridge_reply_delivery_section/0` to the renderer and regenerated the guide, so the statement is generated truth rather than prose that can drift.
- **Files modified:** `lib/crosswake/support_matrix/renderer.ex`, `guides/support_matrix.md`
- **Verification:** `mix test test/crosswake/support_matrix/ test/crosswake/guides/ test/crosswake/proof/phase69_docs_contract_parity_test.exs` — 249 tests, 0 failures.
- **Committed in:** `8be02608`

**3. [Rule 2 — Missing critical functionality] The plan's `--eject` path had no host-facing print of the eject-relative import**

- **Found during:** Task 3
- **Issue:** An ejected copy is served from the *host's* `priv/static/`, not from `/crosswake/`, so printing the library import path after an eject would have taught a URL that 404s.
- **Fix:** The eject output prints the import line derived from the actual eject destination.
- **Files modified:** `lib/mix/tasks/crosswake.gen.bridge_hook.ex`
- **Verification:** `test/mix/tasks/crosswake_gen_bridge_hook_test.exs` covers the `--path` redirect.
- **Committed in:** `bee80099`

---

**Total deviations:** 3 auto-fixed (2× Rule 3, 1× Rule 2)
**Impact on plan:** No scope creep. Two were environmental/structural facts the plan could not have known (Node's positional-path behavior; the guide being generated). The third closes a would-be wrong instruction in generated output.

## Issues Encountered

- **Android reply-leg fixture characters.** The first write of `BridgeReplyLegTest.kt` embedded raw U+2028/U+2029 characters directly in the Kotlin source. They are legal there (Kotlin's line terminators are only `\n`/`\r`), but invisible characters in source are a maintenance trap. Replaced with `""` / `""` escapes.
- **`"type": "module"` at the repo root.** Required so an `.mjs` test can import the `.js` hook as ESM. Audited every Node-executed script in CI first: all are `.mjs`, and `brandbook/tools/` has its own `package.json` (so `compile-tokens.js` stays CJS). `brandbook/assets/brandbook.js` is a browser `<script src>` only. No CI lane is affected.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired components were introduced.

## Threat Flags

None. The plan's `<threat_model>` covers every surface this plan touched, and each `mitigate` disposition is implemented and tested:

| Threat | Status |
|--------|--------|
| T-154-23 (iOS reply-sink JS evaluation) | mitigated — JSON string literal parsed as data; adversarial Swift test; nil-on-serialization-failure |
| T-154-24 (hook transport selection) | mitigated — ordered lookup + per-candidate function typecheck; dedicated test |
| T-154-25 (duplicated hook double-firing) | mitigated — module-scoped single-owner guard; two-elements-one-post test |
| T-154-26 (ejected copy protocol drift) | mitigated — stamped header + doctor warning |
| T-154-27 (client-side denial microcopy) | mitigated — facts-only unreachable payload; source scan asserts no denial shapes |
| T-154-28 (landing pad invoked by page script) | mitigated — client in-flight map gate plus the server's independent three-layer compare-and-delete |
| T-154-SC (package-manager installs) | mitigated — private manifest, zero dependencies, no install step, nothing published |

## Verification Results

| Suite | Command | Result |
|-------|---------|--------|
| Elixir | `mix test` | **1229 tests, 0 failures** (61 excluded); baseline was 1214 |
| Elixir | `mix compile --warnings-as-errors` | exit 0 |
| JavaScript | `node --test "test/js/*.mjs"` | **22 tests, 0 failures** |
| Swift (iOS core) | `swift test` | **14 tests, 0 failures** (was 6) |
| Kotlin (Android core) | `./gradlew testDebugUnitTest` | **12 tests, 0 failures** (was 9) |
| Contract vectors | `mix crosswake.contract.gen` re-run | idempotent; three committed copies byte-identical |
| Scope | `git diff --name-only ef6dd637..HEAD \| grep -c '^examples/phoenix_host/'` | **0** — the showcase is untouched, as Plan 07 owns it |

## Self-Check: PASSED

All created files exist on disk and all four commit hashes are present in `git log`.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Ready for Plan 07.** The showcase migration now has everything it needs: a shipped hook to import, an endpoint plug shape to copy, the reserved event names already spoken on both sides, and `Bridge.push/3` wired end to end. Plan 07 owns `examples/phoenix_host/` — the endpoint's fourth static plug, the layout's import and hooks map, and deleting the two inline IIFEs in `approval_live.ex` and `bridge_proof_live.ex`.

**Carried forward, not blocking:**

- The iOS reply leg reaches adopters only with the **Phase 156** native release, which needs the shell mirror. The mirror is still NO-GO at v0.1.2 (Phase 153 fire-drill). The support matrix states this rather than claiming completeness, so nothing here depends on the mirror unblocking.
- The hook's client reply timer defaults to 10s (mirroring `Crosswake.Bridge`'s `@default_reply_timeout_ms`) because the dispatch envelope carries no timeout field. A per-push override is available today via `data-crosswake-reply-timeout` on the hook element, and the hook already reads an optional `reply_timeout_ms` envelope field if a future wire-version bump adds one.

---
*Phase: 154-the-control-contract-seam*
*Completed: 2026-07-29*
