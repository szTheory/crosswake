# Thread: Runtime Contract Confidence

**Opened:** 2026-06-19 (milestone next-step assessment, post-v13.0)
**Status:** RESOLVED by v14.0 — historical thread retained for evidence.
**Lens:** adopter-first production confidence for Phoenix SaaS apps using Crosswake

## Assessment

Crosswake is strong and credible for its intended scope, but not yet at the point where further work is mostly diminishing returns. The repo is roughly **86% done** for the stated Phoenix-first route-policy and runtime-contract thesis.

The core adopter story is real:

- Phoenix teams can keep most SaaS routes Phoenix/LiveView-owned inside a mobile shell.
- One bounded native affordance can be declared and denied explicitly without turning the bridge into an event bus.
- One offline island can queue real local work through IndexedDB, replay on reconnect, and reconcile through Phoenix/Ecto.
- One native-screen corridor can be represented as explicit runtime ownership instead of a silent WebView fallback.
- Install, release, quick-start, route-owner docs, support labels, evidence manifests, and troubleshooting are now current after v13.0.

The main remaining risk is no longer public proof-path drift. It is runtime contract confidence: the same contract has to be canonical across Elixir, manifest compatibility, generated shells, reusable native packages, checked-in examples, proof lanes, and docs.

## Highest-Leverage Finding

Repo inspection found bridge protocol-version drift:

- `Crosswake.Bridge.Contract` defaults to `1.1.0`.
- Manifest/support/example/native proof paths still commonly use `1.0.0`.
- The example bridge proof emits `1.0.0`.
- The route-tour proof asserts `1.0.0`.
- Native bridge code requires exact protocol-version equality.

That means an otherwise valid bounded-bridge request can be denied because the public/runtime contract surfaces disagree. This is a production-confidence problem, not a feature request.

## Recommended Next Milestone

**v14.0 Runtime Contract Confidence**

Goal: make the bridge/runtime contract boringly canonical and hard to drift, then prove it in the reusable native packages rather than only in checked-in example hosts.

Done enough:

- One canonical bridge protocol version source drives Elixir envelopes, manifest compatibility, shell fixtures, route-tour proof, generated templates, iOS, Android, and docs.
- Example/adopter bridge payloads use a supported helper or generated contract path instead of handcoded protocol/version strings.
- iOS and Android shell-core packages have real behavioral tests for activation, bridge denials, capability allowlists, active-route checks, pack checks, and delegate behavior.
- Drift guards fail if bridge protocol truth diverges across Elixir, manifest fixtures, example payloads, native package tests, generated shells, or docs.
- The support matrix and compatibility guide explain whether the change is core-only/no native rebuild, compatibility-bump only, or native rebuild required.

## Candidate Wedges Ranked

1. **Runtime Contract Confidence** - single pick. It closes a concrete drift risk in a contract Crosswake asks adopters to trust.
2. **Native Runtime Evidence And Generated Shell Lifecycle** - make simulator/emulator/device UAT repeatable only where support labels can remain honest; add a stronger upgrade/patch runbook for host-owned generated shells.
3. **Offline Sync Productization** - improve `mix crosswake.gen.sync` scaffolding and reusable idempotent replay helpers without claiming a generic sync engine.
4. **Operator Metrics / `crosswake_dashboard`** - useful day-2 surface for DASH-01 and Threadline visibility, but less urgent than contract coherence.
5. **Provider Commerce Or Notification/Auth Re-entry** - valuable future product wedges, but defer until the current runtime contract is canonical and better proven.

## Diminishing Returns Judgment

Keep pushing through v14 and likely one more production-evidence wedge. After runtime contract confidence and native/generated-shell lifecycle hardening, additional work should be scrutinized heavily for overbuilding.

High leverage:

- canonical runtime contract truth
- reusable native package behavioral proof
- honest generated-shell upgrade/rebuild guidance
- targeted offline/operator production surfaces

Lower leverage or likely adjacent:

- broad capability catalog growth
- generic plugin-bus semantics
- full local-first sync engine
- provider/device proof that cannot be kept advisory or repeatable

## Bookkeeping Notes

This assessment belongs in a thread rather than phase learnings because no active `.planning/phases/*/*LEARNINGS.md` file exists. The next phase can graduate these lessons into phase learnings if v14 is selected.

Root `.planning/REQUIREMENTS.md` is absent by design at this boundary. The next `/gsd-new-milestone` run should recreate current active requirements from the shipped v13 state and this thread.
