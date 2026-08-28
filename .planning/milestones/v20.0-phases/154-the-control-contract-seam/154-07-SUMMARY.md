---
phase: 154-the-control-contract-seam
plan: 07
subsystem: showcase
tags: [liveview, heex, csp, playwright, proof-lane, structural-guard, changelog]

requires:
  - phase: 154-the-control-contract-seam
    provides: "Plan 06's library-owned hook at priv/static/crosswake.esm.js, the endpoint static-plug shape mix crosswake.install patches, and the printed layout wiring"
  - phase: 154-the-control-contract-seam
    provides: "Plan 04's epoch tracking, exactly-once delivery, and the server-armed wiring/reply deadlines"
  - phase: 154-the-control-contract-seam
    provides: "Plan 03's Crosswake.Bridge facade, Bridge.Reply, and the :shell_unreachable denial reason"
  - phase: 154-the-control-contract-seam
    provides: "Plan 05's merge-blocking CatalogGuard proof file, which this plan extends with the HRDN-01 sweep"
provides:
  - "the AdminPilot haptics call running through Crosswake.Bridge.push/3 inside the committed branch"
  - "the evolved evidence panel: idle copy, two distinctly labelled identity rows, a polite atomic reply row"
  - "data-cw-envelope — the machine-readable projection of the envelope push/3 actually built"
  - "Crosswake.Bridge.dispatched/2 as the adopter's read-back path (shipped in Task 1's commit)"
  - "the reference host on the shipped hook: fourth static plug, layout import + hooks map, Layouts.crosswake_bridge/1"
  - "three route-tour cases — shell-absent, shell-present via addInitScript, hook-deliberately-unwired"
  - "the HRDN-01 structural sweep: 'the IIFE is gone' as a merge-blocking fact over the whole reference host"
affects: [154-08, 156]

tech-stack:
  added:
    - "lazy_html (example host, test-only) — phoenix_live_view's own optional dependency, already carried by root mix.exs"
  patterns:
    - "Render evidence from the envelope the seam built, never from a hand-assembled second copy"
    - "Machine-readable attribute on the enclosing section instead of a regex scrape of markup — CI reads one attribute, the human-readable markup stays free to change"
    - "Positive reply-arrival assertion: a waiting state looks plausible and passes a careless check"
    - "Two identity rows labelled by their vocabulary (route policy vs wire protocol), teaching the distinction where both are visible"
    - "Structural sweep over a whole tree with a synthetic non-vacuity control per signal, plus a subject-exists guard"
    - "Comment-stripping before every source predicate, so prose ABOUT a deleted pattern is never mistaken for the pattern"

key-files:
  created: []
  modified:
    - examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex
    - examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex
    - examples/phoenix_host/lib/crosswake_example/endpoint.ex
    - examples/phoenix_host/lib/crosswake_example/layouts.ex
    - examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex
    - examples/phoenix_host/e2e/route_tour.spec.ts
    - examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs
    - examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs
    - examples/phoenix_host/mix.exs
    - examples/phoenix_host/mix.lock
    - lib/crosswake/bridge.ex
    - priv/templates/crosswake/policy_module.ex
    - test/crosswake/bridge/push_test.exs
    - test/crosswake/proof/phase154_catalog_guard_test.exs
    - test/support/bridge_live_view_case.ex
    - test/support/bridge_test_helpers.ex
    - test/fixtures/proof/phase52_publish_readiness.json
    - CHANGELOG.md
    - .planning/seeds/SEED-006-native-navigation-shell.md
    - .planning/phases/149-saas-admin-showcase/149-CONTEXT.md
  deleted:
    - examples/phoenix_host/assets/js/app.js

key-decisions:
  - "The evidence panel's machine-readable attribute is a curated four-field projection plus a verdict, not a raw envelope dump — it bounds what T-154-30 can leak and keeps the correlation id library-internal (D-20, D-68)"
  - "The showcase LiveView tests became real Phoenix.LiveViewTest round trips, because push/3 has a mount contract a hand-built %Phoenix.LiveView.Socket{} cannot satisfy — the same requirement an adopter hits exactly once"
  - "The HRDN-01 sweep asserts BOTH absence (no inline dispatch) and presence (>= 2 seam call sites), so deleting the capability outright cannot satisfy the gate"
  - "The sweep strips comment lines before every predicate, because this phase deliberately left a great deal of prose ABOUT the deleted pattern"
  - "The CHANGELOG claim is scoped to bridge dispatch rather than repeating the plan threat model's stronger 'last first-party need for an inline-script allowance' — the layout's Phoenix socket bootstrap is still an inline module script"
  - "test/fixtures/proof/phase52_publish_readiness.json regenerated rather than the CHANGELOG entry watered down — the doctor reads CHANGELOG.md, so new Unreleased subsections are real readiness output"

patterns-established:
  - "data-cw-envelope: a LiveView emits its machine-readable evidence on the enclosing section, decoupling CI assertions from human-readable markup"
  - "Every browser case asserts a reply ARRIVED (deny counts) before asserting what it said"
  - "Structural proof sweeps pair an absence assertion with its positive counterpart"

requirements-completed: [HRDN-01, CTRL-01, CTRL-02]

coverage:
  - id: D1
    description: "The AdminPilot haptics call runs through Crosswake.Bridge.push/3 inside the committed branch, after the context commits"
    requirement: HRDN-01
    verification:
      - kind: integration
        ref: "examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs#AdminPilot approval detail LiveView contract handles success, bridge-absent, and typed-denial render states"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#proveAdminPilotApprovalFlow (post-success haptics wire command)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The hand-rolled inline-script builder is gone from BOTH showcase LiveViews, asserted structurally over the whole reference host rather than over the two edited files"
    requirement: HRDN-01
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase154_catalog_guard_test.exs#no module under examples/phoenix_host/lib renders raw HTML into a script element for dispatch"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase154_catalog_guard_test.exs#the seam has at least two call sites in the reference host — the positive counterpart"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase154_catalog_guard_test.exs#non-vacuity: a synthetic module reintroducing the raw-HTML script element is flagged"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase154_catalog_guard_test.exs#non-vacuity: a synthetic module hand-rolling the shell postMessage probe is flagged"
        status: pass
    human_judgment: false
  - id: D3
    description: "The evidence panel renders from the envelope push/3 actually built — no hand-assembled summary map remains"
    requirement: HRDN-01
    verification:
      - kind: integration
        ref: "examples/phoenix_host/test/crosswake_example/bridge_proof_live_test.exs#pressing Share dispatches through the seam and renders the envelope the seam built"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#approvalHapticsEvidence (capability/command/route_id/style all projected from the dispatch)"
        status: pass
    human_judgment: false
  - id: D4
    description: "In a desktop browser with no shell, the DEFAULT post-approval state renders the fail-closed thesis: shell declined, shell_unreachable, no browser substitute for a physical tap, the approval stands"
    requirement: CTRL-02
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#'desktop browser has no shell' + 'fail-closed denial reason' + 'no faked browser substitute'"
        status: pass
      - kind: integration
        ref: "examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs (Shell declined — shell_unreachable / The approval stands)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The panel labels its two identity rows distinctly — capability from route policy versus command from the wire protocol — and the values differ (family form vs dotted form)"
    requirement: CTRL-01
    verification:
      - kind: integration
        ref: "examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs (Capability (route policy) and Command (wire protocol))"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts (command == haptics.impact, capability == haptics)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The reply row is a polite atomic live region"
    requirement: CTRL-02
    verification:
      - kind: static
        ref: "grep -c 'aria-live=\"polite\"' and 'aria-atomic=\"true\"' in approval_live.ex — both 1, on #haptics-reply"
        status: pass
    human_judgment: false
  - id: D7
    description: "Every browser case asserts POSITIVELY that a reply arrived (a denial counts), not merely that nothing timed out"
    requirement: CTRL-02
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#approvalHapticsEvidence waits on the verdict landing in data-cw-envelope, then asserts reply is non-null and status in [ok, deny]"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts (all three @bridge cases assert a rendered verdict)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Three route-tour cases: shell-absent, shell-present simulated at document start, and hook-deliberately-unwired — the third proves the server-side safety net is not untested infrastructure"
    requirement: CTRL-01
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#'renders a typed denial when the browser has no shell at all'"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#'renders an ok reply when a shell is injected at document start'"
        status: pass
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#'renders the server-side wiring-deadline denial when the hook is deliberately unwired'"
        status: pass
    human_judgment: false
  - id: D9
    description: "The bridge-proof route keeps its raw payload element — curated evidence in the product-shaped showcase, raw protocol in the protocol-proof route"
    requirement: CTRL-01
    verification:
      - kind: e2e
        ref: "examples/phoenix_host/e2e/route_tour.spec.ts#bridgePayload (JSON.parse of #crosswake-bridge-payload) unchanged and passing"
        status: pass
    human_judgment: false
  - id: D10
    description: "The dead JavaScript file and its false threat-mitigation claim are deleted, and the seed that described it as an existing seam is amended in the same change"
    requirement: HRDN-01
    verification:
      - kind: static
        ref: "test -e examples/phoenix_host/assets/js/app.js exits non-zero; SEED-006 says the seam 'does not exist yet'"
        status: pass
    human_judgment: false
  - id: D11
    description: "Real haptic feedback firing on a physical iOS device"
    verification: []
    human_judgment: true
    rationale: "Not observable from any automated harness — the simulator has no haptics hardware. Deferred per 154-VALIDATION.md; instructions are in the plan's <verification> block. Note that iOS native REPLY delivery reaches adopters only with the Phase 156 native release (D-02, D-03); the tap itself works today because the command is already in the shipped closed enum (D-01)."

duration: 27min
completed: 2026-07-30
status: complete
---

# Phase 154 Plan 07: HRDN-01 — The Showcase On The Seam Summary

**Both showcase LiveViews now dispatch through `Crosswake.Bridge.push/3`, the hand-rolled inline-script IIFE is gone as a merge-blocking structural fact rather than a claim in a summary, and the AdminPilot evidence panel's DEFAULT desktop state is the fail-closed thesis rendering itself: shell declined, `shell_unreachable`, no browser substitute for a physical tap, the approval stands.**

## Execution Note — This Plan Was Resumed, Not Run Fresh

This plan was executed across two sessions and reconciled rather than restarted:

- **Task 1 was already committed** at `d26d5736` by a prior session. Its work was verified in place (endpoint plug, layout import + hooks map, `Layouts.crosswake_bridge/1`, bridge-proof migration, `app.js` deletion, SEED-006 amendment, the three route-tour cases, `Crosswake.Bridge.dispatched/2`) and left untouched.
- **Task 2 existed as uncommitted work-in-progress.** It was read in full, verified coherent against the plan's behaviors and acceptance criteria, finished where incomplete, and committed as-is — **reconciled, never rewritten**. No part of that WIP was discarded, reset, stashed, or regenerated from scratch.
- **Task 3 was written fresh** in this session.

## Performance

- **Duration:** ~27 min (this session; Task 1 predates it)
- **Completed:** 2026-07-30T00:52Z
- **Tasks:** 3 of 3
- **Files:** 21 modified, 1 deleted, 0 created

## Accomplishments

- **The AdminPilot haptics call is on the seam.** `Bridge.push(@haptics_family, ref: :approval_haptics, payload: %{"style" => "light"})` runs inside the `{:ok, approved}` branch, after the AdminPilot context has recorded the decision. Phase 149's D-07 and D-12 hold unchanged and are now enforced by the seam rather than by convention.
- **The hand-built envelope is gone, and with it the drift it was free to accrue.** The old module restated `protocol`, `version`, `command`, `capability`, `origin`, `native_runtime_version`, `capabilities`, and `installed_packs` by hand — eight fields the manifest already owned. The panel now projects every value out of `Bridge.dispatched/2`, so there is exactly one envelope in the system.
- **The default desktop experience is the strongest demo in the project.** A skeptical Phoenix developer clicks Approve in a browser with no shell and reads: *Shell declined — shell_unreachable. There is no browser substitute for a physical tap, so Crosswake does nothing rather than fake one. The approval stands.* That is the fail-closed thesis rendering itself, for free, on every visit.
- **The two vocabularies are taught where both are visible.** *Capability (route policy)* reads `haptics`; *Command (wire protocol)* reads `haptics.impact`. The browser lane asserts both values independently, which is what would catch a future edit quietly collapsing them back into one string.
- **The highest-risk single edit in the phase landed cleanly.** The route-tour helper used to locate a `<script>` by id and regex-scrape a payload literal out of its `innerHTML` — a required check wired directly to markup this phase deletes. It is now one `getAttribute` and one `JSON.parse`, waiting on the verdict landing in `data-cw-envelope`, which doubles as the positive reply-arrival gate. `grep -c 'match('` in the spec went `1 -> 0`.
- **"The IIFE is gone" is now merge-blocking.** A structural sweep over `examples/phoenix_host/lib/**/*.ex` asserts no module renders raw HTML into a script element for bridge dispatch *and* no module hand-rolls the `webkit.messageHandlers.crosswakeBridge` probe — with the positive counterpart that the seam has at least two call sites there, so deleting the capability outright cannot satisfy the gate.

## Task Commits

1. **Task 1: Reference host on the shipped hook, bridge-proof route on the seam** — `d26d5736` (feat) — *pre-committed by a prior session*
2. **Task 2: AdminPilot haptics on the seam, the panel renders the refusal** — `22343628` (feat) — *reconciled WIP*
3. **Task 3: HRDN-01 as a merge-blocking structural fact** — `20b6e805` (test)

## Files Created/Modified

**Task 1 (`d26d5736`, pre-committed):**
- `examples/phoenix_host/lib/crosswake_example/endpoint.ex` — fourth static plug, `from: :crosswake` at `/crosswake`
- `examples/phoenix_host/lib/crosswake_example/layouts.ex` — third bare module import, `hooks: {CrosswakeBridge}` in the socket options, and `Layouts.crosswake_bridge/1` (the hook element lives once, and as a component rather than root-layout markup because a LiveView binds hooks only inside its own container)
- `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` — share via `Crosswake.Bridge.push/3`, reply `handle_info/2`, raw payload element preserved
- `examples/phoenix_host/lib/crosswake_example/crosswake/policy.ex` + `priv/templates/crosswake/policy_module.ex` — `manifest/0`
- `lib/crosswake/bridge.ex` — `Crosswake.Bridge.dispatched/2`
- `examples/phoenix_host/assets/js/app.js` — **deleted** (81 lines, incl. its false threat-mitigation comment)
- `.planning/seeds/SEED-006-native-navigation-shell.md` — the navigation-intent seam "does not exist yet"
- `examples/phoenix_host/e2e/route_tour.spec.ts` — the three `@bridge` cases
- `test/crosswake/bridge/push_test.exs`, `test/support/bridge_live_view_case.ex`, `test/support/bridge_test_helpers.ex`

**Task 2 (`22343628`):**
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` — the migration, the evolved panel, `data-cw-envelope`, `#haptics-reply` as a polite atomic live region, `Layouts.crosswake_bridge/1`; `haptics_request/1` and `bridge_script/1` deleted
- `examples/phoenix_host/e2e/route_tour.spec.ts` — `approvalHapticsEvidence` replaces `approvalHapticsPayload`; the positive reply-arrival and fail-closed assertions
- `examples/phoenix_host/test/crosswake_example/saas_portal/approvals_live_test.exs` and `.../bridge_proof_live_test.exs` — real LiveViewTest round trips
- `examples/phoenix_host/mix.exs` / `mix.lock` — `lazy_html` test-only (see Deviations)
- `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` — D-07 and D-12 amendment bullets, short bold-prefix format
- `CHANGELOG.md` — `### Security` (the CSP framing + the deleted false claim) and `### Added` (`dispatched/2`, generated `manifest/0`)
- `test/fixtures/proof/phase52_publish_readiness.json` — regenerated

**Task 3 (`20b6e805`):**
- `test/crosswake/proof/phase154_catalog_guard_test.exs` — the HRDN-01 sweep (5 new assertions, +167 lines)

## Decisions Made

- **The envelope attribute is curated, not a dump.** `data-cw-envelope` carries `capability`, `command`, `route_id`, `style`, and the reply verdict — the same four semantic fields plus verdict the panel renders visibly. The correlation id stays library-internal (D-20); adopters correlate with their own opaque `ref:`. This is what bounds T-154-30.
- **The showcase tests became real LiveViewTest round trips.** `push/3` raises `NotMountedError` on a socket that never called `attach/1`, so a hand-constructed `%Phoenix.LiveView.Socket{}` can no longer stand in for a mounted LiveView. That is the point: it is the same requirement an adopter hits exactly once, and the showcase's own tests should hit it too.
- **The sweep asserts presence as well as absence.** An absence-only gate is satisfied by deleting the capability. HRDN-01 is a migration, not a deletion (D-70), so the sweep also requires >= 2 seam call sites in the reference host.
- **The sweep strips comment lines before every predicate.** This phase deliberately left a great deal of prose *about* the deleted pattern, because the reasoning is the artifact. Stripping comments keeps that prose from being mistaken for the pattern in either direction.
- **The CHANGELOG claim is scoped to bridge dispatch.** See "Scope Correction" below.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] The example host needed `lazy_html` as a test dependency**

- **Found during:** Task 2 reconciliation
- **Issue:** The reconciled WIP converted the two showcase LiveView tests to real `Phoenix.LiveViewTest` round trips (necessarily — `Bridge.push/3` has a mount contract a bare socket struct cannot satisfy). `phoenix_live_view 1.1.30` then raised `Phoenix LiveView requires lazy_html as a test dependency` on all four tests. The example host suite was **95 tests, 4 failures**.
- **Why this was not escalated to a package-legitimacy checkpoint:** this is not an unverified name. `lazy_html` is `phoenix_live_view`'s own declared optional dependency (visible in both lockfiles' `phoenix_live_view` entry), the name is emitted verbatim by the installed framework's runtime error, and the root `mix.exs` already carries `{:lazy_html, ">= 0.1.0", only: :test}` — added earlier in this same phase, with a comment giving this exact reason. Nothing new entered the dependency graph.
- **Fix:** Added `{:lazy_html, ">= 0.1.0", only: :test}` to `examples/phoenix_host/mix.exs` with a comment naming the cause.
- **Files modified:** `examples/phoenix_host/mix.exs`, `examples/phoenix_host/mix.lock`
- **Verification:** `cd examples/phoenix_host && mix test` — **95 tests, 0 failures**.
- **Committed in:** `22343628`

**2. [Rule 1 — Bug] The publish-readiness proof fixture drifted on the CHANGELOG edit**

- **Found during:** Task 2 reconciliation
- **Issue:** `mix test` was **1231 tests, 2 failures** — `phase52_operator_truth_test.exs:101` and the `phase135_ci_ops_proof_test.exs:597` wrapper around it. Root cause: `Crosswake.Doctor.PublishReadiness` reads `CHANGELOG.md` and reports `details.unreleased_subsections`, so the new `### Security` and `### Added` headings are genuine readiness output that the golden had not seen.
- **Fix:** Regenerated the affected entry in `test/fixtures/proof/phase52_publish_readiness.json` — **not** by watering down the CHANGELOG entry and **not** by weakening the assertion. The doctor's real output was captured through the test's own invocation path and diffed field-by-field against the fixture; the only non-version delta was `unreleased_subsections` gaining `"Security"` and `"Added"` in document order. Readiness `category`, `code`, `proof_class`, `rebuild_requirement`, `blocking`, `severity`, and `claim_scope` semantics are byte-unchanged — the fixture diff is a single line, `1 insertion(+), 1 deletion(-)`.
- **Files modified:** `test/fixtures/proof/phase52_publish_readiness.json`
- **Verification:** `mix test test/crosswake/proof/phase52_operator_truth_test.exs` — 6 tests, 0 failures; full suite 0 failures.
- **Committed in:** `22343628`

### Scope Correction (no false claim shipped)

The plan's threat model states T-154-29's mitigation as "removing the **last** first-party need for an inline-script allowance or a per-render nonce in the example host." That is stronger than what is true: `examples/phoenix_host/lib/crosswake_example/layouts.ex:25` still carries an inline `<script type="module">` — the standard Phoenix LiveSocket bootstrap — which is unrelated to bridge dispatch and out of this plan's scope.

The reconciled `CHANGELOG.md` entry (the shipped artifact, and the only one an adopter reads) makes the accurate, scoped claim instead: *"Bridge dispatch no longer renders a server-built payload into an inline `<script>` element … A host that adopted the previous inline pattern by copy-paste can drop that allowance once it moves to `Crosswake.Bridge.push/3`."* No overclaim was shipped. Recorded here so the stronger sentence in the plan does not get quoted forward as fact.

---

**Total deviations:** 2 auto-fixed (1× Rule 3, 1× Rule 1), plus 1 scope correction. No Rule 4 architectural decisions.
**Impact on plan:** No scope creep. Both fixes were consequences of the plan's own changes; neither altered a plan behavior or acceptance criterion.

## Issues Encountered

- **`grep -c 'Crosswake.Bridge.push'` in `approval_live.ex` matches a comment, not the call.** The module aliases `Crosswake.Bridge`, so the call site reads `Bridge.push(...)`; the fully-qualified string appears only in a docstring comment. The plan's artifact `contains:` check therefore passes for the wrong reason. Rather than de-idiomatize the source to satisfy a grep, Task 3's sweep detects seam call sites structurally — `Crosswake.Bridge.push(` **or** (`alias Crosswake.Bridge` **and** `Bridge.push(`), with comments stripped first — so the merge-blocking gate is honest even where the frontmatter grep is not.
- **The known `validator_test.exs` `$TMPDIR` flake did not reproduce** in any run this session.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired components were introduced. The panel's idle state is deliberate honest copy per D-69 and the brand spec's empty-state rule ("No haptics request sent. Phoenix sends one only after an approval commits."), not a placeholder — it renders only before an approval and is asserted by the LiveView test.

## Threat Flags

None. Every `mitigate` disposition in the plan's `<threat_model>` is implemented and tested:

| Threat | Status |
|--------|--------|
| T-154-29 (inline-script dispatch requiring an unsafe-inline allowance) | mitigated **for bridge dispatch** — both builders deleted, external module hook, merge-blocking sweep over the whole tree. See "Scope Correction": the layout's Phoenix socket bootstrap is a separate pre-existing inline script and the shipped CHANGELOG claim is scoped accordingly. |
| T-154-30 (the machine-readable envelope attribute) | mitigated — four semantic fields plus verdict, the same content the panel renders visibly; no token, no secret, no correlation id |
| T-154-31 (a false threat-mitigation claim in a shipped file) | mitigated — `app.js` deleted and SEED-006 amended in the same change (`d26d5736`) |
| T-154-32 (a plausible waiting state passing as success) | mitigated — the helper waits on the verdict landing in `data-cw-envelope`, then asserts the reply is non-null and its status is `ok` or `deny` |
| T-154-33 (showcase pattern propagating by copy-paste) | mitigated — both LiveViews migrated together, enforced tree-wide by Task 3 |
| T-154-SC (package-manager installs) | one addition, documented above: `lazy_html`, `phoenix_live_view`'s own optional dependency, already resolved in this repo's root lockfile |

## Verification Results

| Suite | Command | Result |
|-------|---------|--------|
| Elixir (core) | `mix test` | **1236 tests, 0 failures** (61 excluded) — was 1231 tests / 2 failures on entry; pre-plan baseline 1229 |
| Elixir (core, hermetic) | `mix test --exclude requires_example_host --exclude advisory_only` | **1236 tests, 0 failures** |
| Elixir (core) | `mix compile --warnings-as-errors` | exit 0 |
| Elixir (example host) | `cd examples/phoenix_host && mix test` | **95 tests, 0 failures** |
| Elixir (example host) | `cd examples/phoenix_host && mix compile --warnings-as-errors` | exit 0 |
| JavaScript | `node --test "test/js/*.mjs"` | **22 tests, 0 failures** |
| Browser | `cd examples/phoenix_host && npx playwright test route_tour.spec.ts` | **7 passed** (chromium, headless, webServer-booted) — includes both `proveAdminPilotApprovalFlow` call sites and all three `@bridge` cases |
| Proof lane | `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | **36 tests, 0 failures** (was 31) |
| Proof lane | `mix test test/crosswake/proof/phase52_operator_truth_test.exs` | **6 tests, 0 failures** |
| Contract vectors | not regenerated | this plan touched neither the capability catalog nor the contract vectors |
| Workflows | `ls .github/workflows/ \| wc -l` | **40**, unchanged (D-47: no new required check) |

The Playwright lane ran headless in this environment with no human involvement — the config's `webServer` boots the host on port 4700 and the run completed in 8.2s.

### Acceptance Criteria

All Task 1, Task 2, and Task 3 acceptance criteria verified:

- `from: :crosswake` in `endpoint.ex` = 1; `crosswake.esm.js` in `layouts.ex` = 1; `hooks` present
- `Phoenix.HTML.raw` in both migrated LiveViews = **0**; `crosswake-bridge-payload` preserved = 1
- `test -e examples/phoenix_host/assets/js/app.js` → non-zero; SEED-006 contains "does not exist yet"
- `data-cw-envelope` in `approval_live.ex` = 1, in the spec = 2; `aria-live="polite"` = 1; `aria-atomic="true"` = 1; "route policy" = 1; "wire protocol" = 1
- `grep -c 'match('` in the spec: **1 → 0** (the regex scrape is gone)
- `### Upgrade Impact` present in Unreleased; `grep -ci 'unsafe-inline\|nonce' CHANGELOG.md` = 1
- `D-07` in 149-CONTEXT.md = 2, with a Phase 154 amendment bullet
- `grep -ci 'hrdn'` in the proof file = 11; `ProofAssertions.stable_id_message` count **34 → 39** (+5, criterion required +2); `@moduletag` = 0; self-assertion still last

## Self-Check: PASSED

- All three commit hashes present in `git log`: `d26d5736`, `22343628`, `20b6e805`
- All files listed as modified exist on disk; `examples/phoenix_host/assets/js/app.js` confirmed absent
- Working tree clean apart from the untracked `tmp/` scratch directory, which was left untouched as instructed

## Manual-Only Verification (deferred)

Real haptic feedback on a physical iOS device is not observable from any automated harness — the simulator has no haptics hardware. Per `154-VALIDATION.md`: build the iOS example shell against this branch, open the AdminPilot approval route on a physical iPhone, approve a request, and confirm both a physical tap and a correlated `ok` reply in the evidence panel. On a shell built from the current mirror tag the expected in-panel result is the correlated `ok` arriving only after the **Phase 156** native release (D-02, D-03); the haptic tap itself works today because the command is already in the shipped closed enum (D-01).

## User Setup Required

None.

## Next Phase Readiness

**Ready for Plan 08.** This closes D-76's **PR #3**, the last of the three, with both the core hermetic suite and the Playwright route tour green.

**Carried forward, not blocking:**

- The iOS reply return leg reaches adopters only with the Phase 156 native release, which needs the shell mirror. The mirror is still NO-GO at v0.1.2 (Phase 153 fire-drill). `guides/support_matrix.md` already states this rather than claiming completeness.
- The layout's inline LiveSocket bootstrap script is unrelated to bridge dispatch and out of scope here; a host that wants a fully nonce-free CSP would move that bootstrap to an external module file too. Not a Crosswake claim, and the CHANGELOG does not imply otherwise.

---
*Phase: 154-the-control-contract-seam*
*Completed: 2026-07-30*
