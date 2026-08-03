---
gsd_state_version: 1.0
milestone: v21.0
milestone_name: First B2C Adopter Readiness
current_phase: 161
current_phase_name: ios-pronunciation-pack-seam
status: executing
stopped_at: Completed 161-04-PLAN.md
last_updated: "2026-08-03T16:27:45.430Z"
last_activity: 2026-08-03
last_activity_desc: Phase 161 execution started
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 70
  completed_plans: 69
  percent: 60
current_plan: 17
---

# Project State

## Current Position

Phase: 161 (ios-pronunciation-pack-seam) — EXECUTING
Plan: 4 of 5
Status: Ready to execute
Last activity: 2026-08-03 — Phase 161 execution started

## Active Objective

Make the First B2C Adopter the forcing function. Crosswake is infrastructure, not a separate
business line. The milestone ends with one physical-iPhone offline study proof, not a broader
framework launch.

## Milestone Boundary

- Customer Alpha may be web-only; Crosswake has no Alpha deliverable.
- Public v1 requires iPhone, one offline mutation island, offline pronunciation media, auth
  continuity, server-side disablement, host-reusable proof, and physical-device evidence.

- Stop Crosswake work after 2026-08-18 except defects demonstrated by Phase 162.
- Reversal requires two independent active adopters or a separately funded business-line mandate.

## Next Action

Execute Phase 161 with `$gsd-execute-phase 161`. Phase 160 security is reconciled at 37/37 threats
closed. TODO-002 remains the bounded adopter-input gate and adopter-instance completeness remains
`unknown_blocking`; do not infer concrete adopter routes or promote downstream device claims.

## Blockers

- Phase 160 code review WR-01 records a non-blocking browser lifecycle race: fencing during an
  IndexedDB save can leave rating controls owned until reload. The finding remains available for
  `$gsd-code-review 160 --fix`.

- The route inventory needs adopter-supplied concrete route IDs/paths, mutation actions, staleness,
  auth sensitivity, expected pronunciation-pack sizes/codecs, and fallbacks.

- Phase 162 ultimately needs a runnable adopter host, backend replay endpoint, and physical iPhone.
- The canonical historical six product-failure labels were not stored because only a privacy-safe
  proxy audit was authorized.

- TODO-002 remains open: the route inventory still needs adopter-supplied concrete route IDs/paths,
  mutation actions, staleness, auth sensitivity, expected pronunciation-pack sizes/codecs, and
  fallbacks before adopter-instance promotion.

## Decisions

- GET-6 accepted: Crosswake is infrastructure for the First B2C Adopter.
- v20 is stopped/partial, not shipped; no v20.0 completion tag.
- Android is frozen at current generator/JVM/vector posture.
- Highest-impact framework change: host-reusable proof-lane generator.
- Offline mutation envelopes are scope-bound and sensitive by default.
- Pronunciation media uses one host-supplied foreground iOS pack adapter.
- Feature flags remain host-owned through existing `gated_by`.
- Generic sync and generic native storage non-goals remain in force.
- Automatable acceptance requires executable proof, not conversational verification or manual UAT;
  CI promotion is reserved for recurring contract value.

- [Phase ?]: Route-local safety posture is represented as a closed status/value pair and never inherits from surface defaults.
- [Phase ?]: Empty or unknown-blocking inventories are explicitly blocked from promotion.
- [Phase ?]: Canonical capability rows use adoption_implication; v20_implication remains a renderer input alias for one documented compatibility window.
- [Phase ?]: Conflicting canonical and legacy implication values fail closed without echoing supplied row content.
- [Phase ?]: Private-term scans omit plan files that intentionally document the secret-input seam and synthetic canary.
- [Phase ?]: Executor-state discoverability asserts the active execute command rather than the pre-execution discuss command.
- [Phase ?]: Policy-contract completion and surface defaults never promote external-host or physical-device support while route inputs are unknown_blocking.
- [Phase ?]: Public support wording uses first adopter, retains the existing vocabulary, and keeps Android at its frozen generator/Maven/JVM/vector posture.
- [Phase ?]: Concrete-route safety fields reject known_default before promotion while preserving the closed discovery vocabulary.
- [Phase ?]: Local-first promotion requires explicit coherent ownership, mutation, scope, fallback, disablement, retention, and recent-auth authority.
- [Phase ?]: Approved first-adopter artifacts are discovered through destination-tagged globs, with private-term failures limited to stable rule/path pairs.
- [Phase ?]: Phase 158 post-gap validation closes defaults-only/incoherent route promotion and unscanned planning-artifact gaps, while adopter-instance input remains unknown_blocking.
- [Phase ?]: Protected private-term scans run only for trusted same-repository PRs, main pushes, and manual dispatches; fork PRs fail closed without secret exposure.
- [Phase ?]: Public capability prose uses first adopter throughout rendered output; stable row IDs remain unchanged.
- [Phase ?]: Final validation records a protected test input only as runtime-assembled neutral fragments and preserves adopter-instance unknown_blocking.
- [Phase ?]: Durable route IDs use exactly route- plus 16 lowercase hexadecimal characters.
- [Phase ?]: Phoenix path templates allow only generic static segments and the :id parameter token.
- [Phase ?]: Public prose accepts only the standalone two-word phrase; standalone hyphenated wording has a dedicated stable rule ID.
- [Phase ?]: Sensitive identity vocabulary requires a key-plus-assignment shape so safe review terminology remains scannable.
- [Phase ?]: Final formatter ledger enumerates all seven Elixir sources and tests changed by Plans 158-11 through 158-13, including lib/crosswake/capability_map.ex.
- [Phase ?]: Phase 158 final gate closes only on fresh observed evidence; TODO-002 remains unknown_blocking.
- [Phase ?]: Repository privacy candidates are enumerated from cached and non-ignored Git paths; artifact globs are compatibility metadata, not the scanner boundary.
- [Phase ?]: Unsafe, unreadable, unclassified, and enumeration-failure paths fail closed with rule/path-only diagnostics.
- [Phase ?]: Phase 158 final gate closes only on fresh Git-backed repository-classification and post-write scan evidence; TODO-002 remains unknown_blocking.
- [Phase ?]: Recognized textual repository candidates scan for private terms regardless of subtree; raw evidence and binary exclusions remain explicit.
- [Phase ?]: Generic privacy rules cover every scan?: true textual artifact while destination wording checks remain scoped.
- [Phase ?]: RESET-04 closes only after fresh final-tree direct, production Mix-task, and post-write scan evidence.
- [Phase ?]: TODO-002 remains open and adopter-instance completeness remains unknown_blocking; no later-phase or platform claim changed.
- [Phase ?]: RouteInventory rejects non-atom map keys before Keyword normalization with a fixed non-echoing error.
- [Phase ?]: Only fresh final-tree and post-write execution can close demonstrated scanner or validator blockers.
- [Phase ?]: TODO-002 remains open and adopter-instance completeness remains unknown_blocking after phase verification.
- [Phase ?]: Proof-lane generation uses one closed Phoenix config and creates only missing host-owned files.
- [Phase ?]: Proof driver outcomes are closed to passed, blocked, and unavailable; later-phase prerequisites remain non-passing.
- [Phase ?]: Proof-lane configuration accepts exactly nine atom-keyed Phoenix values and returns non-echoing PL-CONFIG errors.
- [Phase ?]: Generated files remain host-owned; only missing paths are exclusively created and the manifest is promoted from a sibling staging file without replacement.
- [Phase ?]: The original browser corpus remains primary while host callbacks supply the reusable offline-island proof sequence.
- [Phase ?]: Native proof exposes only closed blocked or unavailable prerequisites until later host auth/replay and pack/audio adapters exist.
- [Phase ?]: Retained proof evidence uses an exact twelve-field allowlist and final-byte scanning before promotion.
- [Phase ?]: Proof-lane host roots are derived only from a normalized non-root native/ios shell path.
- [Phase ?]: Generator actions revalidate direct Config structs before filesystem destination derivation.
- [Phase ?]: Browser proof cleanup restores online state in finally before reconnect or later assertions.
- [Phase ?]: Generated iOS proof outcomes are JSON-only passed, blocked, or unavailable; only a successful target build exits zero.
- [Phase ?]: Retained proof evidence accepts only closed opaque identifiers and SHA-256 values derived from approved canonical bytes.
- [Phase ?]: Evidence promotion uses OS no-replace directory primitives and preserves concurrent destination winners.
- [Phase ?]: Generator filesystem authority is confined to GeneratorFS using root-relative paths only.
- [Phase ?]: Unsafe topology and native-helper failures fail closed with stable relative-path rules.
- [Phase ?]: The existing Playwright webServer remains the sole owner of Phoenix test-database setup and server lifecycle.
- [Phase ?]: Browser proof accepts only anchored lowercase UUID-shaped opaque mutation references and emits PL-BROWSER-MUTATION-ID without echoing input.
- [Phase ?]: Evidence lifecycle hooks permit only an absent hook or an installed zero-arity hook returning exactly :ok; every other outcome is one sanitized promotion failure.
- [Phase ?]: Generated Xcode proof targets declare explicit product/module names and XCTest host settings so real shared-scheme tests retain unique outputs.
- [Phase 159]: A fresh complete same-tree gate closed private helper provenance and digest-bound evidence replacement races while preserving the real Phoenix-host browser and generated XCTest/XCUITest contract boundaries.
- [Phase ?]: Failed exclusive proof writes remove only their newly created destination before returning the original write failure.
- [Phase ?]: Manifest reuse is returned only after helper-owned staging cleanup succeeds; cleanup failure remains non-passing.
- [Phase ?]: Generated iOS proof passes only after exact host-adapter XCTest and adapter-derived lifecycle/accessibility XCUITest markers.
- [Phase ?]: Nil host adapters remain deterministic blocked outcomes; unavailable and blocked are never proof success.
- [Phase ?]: Proof-lane endpoint paths reject quote and backslash characters at the canonical normalizer before rendering or filesystem activity.
- [Phase ?]: Direct Config structs are normalized before generator root derivation so direct, application, and selected config seams fail identically.
- [Phase 159]: Fresh final-tree proof closes only on deterministic fixture evidence; generated accessibility-size runtime execution is advisory and cannot promote or block the phase.
- [Phase 159]: Quote and backslash endpoint values reject before rendering or filesystem activity, while untouched generated iOS lanes remain deterministically blocked until exact host-adapter evidence exists.
- [Phase ?]: Deterministic generated-contract fixtures close Phase 159; native accessibility runtime remains advisory and non-promoting.
- [Phase ?]: Generated Phoenix host proof is required, typed, and selected within the existing primary browser corpus.
- [Phase ?]: Proof-lane endpoint paths reject every backslash byte at canonical normalization before raw EEx rendering or generator filesystem authority.
- [Phase 159]: The final same-tree gate typechecks and executes the generated Phoenix-host proof with backend confirmation, empty-outbox, and duplicate-idempotency assertions; endpoint one-backslash rejection is verified at every config seam.
- [Phase 159]: Executable generated-browser proof, swapped-source rejection, and descriptor publication are verified together by the final same-tree gate.
- [Phase ?]: Generated browser specs use one typed host adapter that defaults to stable PL-BROWSER-HOST-ADAPTER denial.
- [Phase ?]: Phoenix proof pre-seeds the host adapter and executes only isolated version-2 generated Playwright output.
- [Phase ?]: Retained evidence requires a regular 64-byte SHA-256 marker matching exact canonical artifact bytes on every read.
- [Phase ?]: Generated proof-lane bytes publish through a bounded private frame and descriptor-only atomic destination handoff.
- [Phase ?]: Concurrent helper builds reuse a content-addressed warning-clean executable without expanding the generator filesystem API.
- [Phase 159]: Phase completion required and received a fresh full same-tree gate; focused repairs and stale evidence did not advance status.
- [Phase ?]: Generator helpers are reusable only inside one invocation-owned private lifecycle; predictable shared-temp executables are inert.
- [Phase ?]: Evidence checks consume only the completion-digest-bound snapshot; replacement races use a test-only process-local barrier.
- [Phase 159]: Retained-evidence publication holds no-follow parent and destination descriptors after reservation; all leaf writes, verification, no-replace handoff, owned-leaf cleanup, and synchronization remain descriptor-relative, and a deterministic ancestor replacement cannot redirect evidence.
- [Phase ?]: Opaque scope refs are versioned, bounded, and validated without echoing rejected values.
- [Phase ?]: Browser replay starts inert and requires an exact scope-plus-epoch lease before storage, send, completion, or UI mutation.
- [Phase ?]: Each replay event resolves host session, scope, route, feature, Sigra, and domain authority in order immediately before mutation.
- [Phase ?]: Review-event idempotency is qualified by opaque scope and commits with its domain effect in one transaction.
- [Phase ?]: Sigra projects backend authority to only allow or the safe sigra_denied class.
- [Phase ?]: Operational egress receives only explicit SafeObservation projections; generated iOS blocked output remains non-passing prerequisite evidence.
- [Phase ?]: Legacy IndexedDB mutations are quarantined on upgrade and can enter one scoped outbox only through a matching active host lease.
- [Phase ?]: Replay admission requires typed RouteEntry and validated AuthContext; all other inputs project to sigra_denied.
- [Phase ?]: The Phoenix host constructs synthetic fixture authority privately for each default replay event and never returns it to callers.
- [Phase ?]: Opaque scope validation consumes the entire value before host authority callbacks run.
- [Phase ?]: Persisted accepted and rejected ReviewEvent rows use one closed mapper for duplicate and recovery outcomes.
- [Phase ?]: Only accepted replay outcomes advance accepted_records; rejected work remains retained and halts ordered draining.
- [Phase ?]: Online events capture an active scope-plus-epoch lease before replay and discard caught failure details.
- [Phase ?]: Inactive or fenced lifecycle state resolves as a silent no-op before requireActiveLease or activeFlush creation.
- [Phase ?]: Post-160-09/10 final-tree evidence supersedes the pre-repair gate while blocked generated iOS and independent security remain non-passing.
- [Phase ?]: The full offline-island Playwright corpus is the automated behavior gate for Plan 160-10 JavaScript and TypeScript changes.
- [Phase ?]: Replay admission now accepts exactly client_mutation_id, card_id, and rating before any authority callback.
- [Phase ?]: Study reconstructs replay persistence attributes and ReviewEvent assigns accepted server-side, preserving internal rejected tombstones.
- [Phase ?]: Successful online activation dispatches only through the existing lease-guarded replay worker.
- [Phase ?]: Non-halted acknowledgements require complete ordered acceptance and no rejected records before deletion.
- [Phase ?]: Browser replay proof uses a compile-time-gated signed test session and request-bound test authority; production remains fail closed.
- [Phase ?]: Immediate online review replay enters replayOnOnline so current-lease failures render the existing paused state without unhandled rejections.
- [Phase ?]: Private evidence digest barriers are declared only in the test compilation branch beside their sole consumer.
- [Phase ?]: Phase 160 final validation retains only commands, aggregate counts, stable IDs, and closed outcomes.
- [Phase ?]: Legacy recovery remains recovery-required without a host-owned per-record ownership binding.
- [Phase ?]: Nil-scope ReviewEvent history is scope-conflict-only before persisted outcome mapping.
- [Phase ?]: Rating controls synchronously own one card submission across IndexedDB persistence.
- [Phase ?]: Pack availability requires a fresh exact provider status record; install acknowledgement and legacy inventory are non-authoritative.
- [Phase ?]: The optional host PackProvider stays outside bridge capabilities and preserves host storage and transport authority.
- [Phase ?]: Reference iOS host injects PackProvider at composition root; RequiredPackView presents only closed foreground recovery actions.
- [Phase ?]: Generated pack/audio proof defaults to non-passing; only explicit reference-adapter simulator output can pass as advisory.
- [Phase ?]: Exact adapter-derived XCTest/XCUITest markers gate pack_audio_prerequisite; generic build success remains blocked.

## Deferred Items

- Phase 156 native menu/action-button planning artifacts are retained but abandoned.
- Phase 157 hardening/promotion work is not active.
- Brandbook/showcase/profile/launch polish is frozen as business-line investment.
- Android device/parity work is frozen.
- Capture/device controls, commerce productionization, dashboard, and broad offline/storage
  productization require post-proof adopter evidence.

## Privacy and Context Rules

- Durable codename: **First B2C Adopter** (`first_b2c_adopter`).
- Public guide phrase: **first adopter**.
- Never store the real adopter name, founder identity, price, geography, customer information,
  proprietary product taxonomy, or revealing links.

- Never attempt to infer or rediscover the adopter identity from git history or external sources.
- Raw answer payloads, media, transcripts, credentials, account IDs, tokens, and stable device IDs
  are forbidden from diagnostics and proof artifacts.

## Working-Tree Note

The pre-existing `.planning/config.json` modification is unrelated and must not be overwritten by
this milestone reset.

## Session

**Last session:** 2026-08-03T16:27:45.416Z
**Stopped at:** Completed 161-04-PLAN.md
**Resume file:** None

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 158-adoption-reset-and-route-map P01 | 6m | 2 tasks | 3 files |
| Phase 158-adoption-reset-and-route-map P02 | 10m | 2 tasks | 5 files |
| Phase 158-adoption-reset-and-route-map P03 | 1m | 2 tasks | 2 files |
| Phase 158-adoption-reset-and-route-map P04 | 12m | 2 tasks | 5 files |
| Phase 158-adoption-reset-and-route-map P05 | 9m | 2 tasks | 3 files |
| Phase 158-adoption-reset-and-route-map P06 | 14m | 2 tasks | 5 files |
| Phase 158-adoption-reset-and-route-map P07 | 5m | 1 tasks | 2 files |
| Phase 158-adoption-reset-and-route-map P08 | 5m | 1 tasks | 2 files |
| Phase 158-adoption-reset-and-route-map P09 | 6m | 1 tasks | 3 files |
| Phase 158-adoption-reset-and-route-map P10 | 8m | 1 tasks | 1 files |
| Phase 158-adoption-reset-and-route-map P11 | 12m | 1 tasks | 2 files |
| Phase 158-adoption-reset-and-route-map P12 | 5min | 2 tasks | 4 files |
| Phase 158-adoption-reset-and-route-map P13 | 3m | 1 tasks | 1 files |
| Phase 158-adoption-reset-and-route-map P14 | 5m | 1 tasks | 3 files |
| Phase 158 P15 | 18m | 2 tasks | 5 files |
| Phase 158 P16 | 8m | 1 tasks | 3 files |
| Phase 158 P17 | 18m | 2 tasks | 3 files |
| Phase 158-adoption-reset-and-route-map P18 | 6m | 1 tasks | 3 files |
| Phase 158-adoption-reset-and-route-map P19 | 20m | 2 tasks | 10 files |
| Phase 158-adoption-reset-and-route-map P20 | 6m | 1 tasks | 3 files |
| Phase 159 P01 | 11m | 1 tasks | 9 files |
| Phase 159 P02 | 15m | 2 tasks | 5 files |
| Phase 159 P03 | 10m | 2 tasks | 10 files |
| Phase 159 P04 | 18m | 2 tasks | 3 files |
| Phase 159 P05 | 14m | 2 tasks | 4 files |
| Phase 159 P06 | 14m | 3 tasks | 10 files |
| Phase 159 P07 | 13m | 2 tasks | 5 files |
| Phase 159 P08 | 22m | 2 tasks | 4 files |
| Phase 159 P10 | 14m | 2 tasks | 7 files |
| Phase 159 P11 | 2m | 1 tasks | 2 files |
| Phase 159 P09 | ongoing continuation | 2 tasks | 10 files |
| Phase 159 P12 | 15m | 2 tasks | 7 files |
| Phase 159 P13 | 12m | 2 tasks | 3 files |
| Phase 159-host-reusable-proof-lane P15 | 10m | 1 tasks | 5 files |
| Phase 159 P16 | 6 min | 1 tasks | 4 files |
| Phase 159 P17 | 8m | 1 tasks | 5 files |
| Phase 159 P18 | 8m | 1 tasks | 5 files |
| Phase 159 P19 | 7m | 1 tasks | 3 files |
| Phase 159 P20 | 1m | 1 task | 6 files |
| Phase 159 P21 | 20m | 2 tasks | 7 files |
| Phase 159 P22 | 14m | 1 tasks | 4 files |
| Phase 159 P23 | 36m | 1 tasks | 4 files |
| Phase 159 P24 | 4m | 1 tasks | 6 files |
| Phase 159 P25 | 22m | 1 tasks | 3 files |
| Phase 159-host-reusable-proof-lane P26 | 9min | 1 tasks | 2 files |
| Phase 159-host-reusable-proof-lane P27 | 6min | 1 task | 5 files |
| Phase 159-host-reusable-proof-lane P28 | 15m | 2 tasks | 7 files |
| Phase 160 P01 | 726s | 2 tasks | 7 files |
| Phase 160 P02 | 31m | 3 tasks | 13 files |
| Phase 160 P03 | 55m | 3 tasks | 22 files |
| Phase 160 P04 | 5m | 2 tasks | 3 files |
| Phase 160-scoped-replay-and-auth-safety P06 | 15min | 2 tasks | 4 files |
| Phase 160 P09 | 6m | 2 tasks | 8 files |
| Phase 160 P10 | 4m | 1 tasks | 2 files |
| Phase 160-scoped-replay-and-auth-safety P11 | 4m | 1 tasks | 2 files |
| Phase 160 P12 | 2m 25s | 2 tasks | 7 files |
| Phase 160 P13 | 16m | 2 tasks | 3 files |
| Phase 160-scoped-replay-and-auth-safety P15 | ~22m | 2 tasks | 7 files |
| Phase 160 P16 | 15min | 2 tasks | 5 files |
| Phase 160-scoped-replay-and-auth-safety P17 | 6min | 3 tasks | 7 files |
| Phase 161-ios-pronunciation-pack-seam P01 | 5m | 2 tasks | 7 files |
| Phase 161-ios-pronunciation-pack-seam P03 | 8 minutes | 1 tasks | 4 files |
| Phase 161-ios-pronunciation-pack-seam P04 | 16m | 2 tasks | 10 files |
