---
phase: 187-doctor-and-proof-fidelity
requirement: DOCTOR-04
seed: SEED-014
date: 2026-10-16
---

# Phase 187 Deferral Record

This file records, once, three things Phase 187 deliberately does not build: a haptics assertion in the physical-iPhone contract (CW-REQ-A), removal of the route id from the shipped denial view (CW-REQ-D), and a compile-time rule for `:local_first` routes without an `island_contract`. It also lists two doctor gaps that are disclosed but not fixed. SEED-014 and REQUIREMENTS.md only point here; they do not copy this evidence, so the triggers cannot drift apart.

## CW-REQ-A — no haptics assertion in PhysicalIphoneContract

- **Disposition:** `defer-with-reason`
- **Decided:** Phase 187 discussion (D-14), owner-adopted synthesized recommendation.
- **Reason:** The change is breaking. The enforcer is the public `PhysicalIphoneContract.validate_report/1` in `lib/crosswake/proof_lane/physical_iphone_contract.ex`, which rejects any report whose id list is not exactly the contract's ordered set (`PI-ASSERTIONS-COMPLETE` for a missing or extra id, `PI-ASSERTIONS-ORDER` for a reordering). Its caller is `Crosswake.ProofLane.Evidence` in `lib/crosswake/proof_lane/evidence.ex`, which re-validates every stored physical run contract through it. The mix task `crosswake.proof_lane.physical_iphone` separately compares its joined report with the same ordered list in its private `join_reports/3` (`PI-REPORT-COMPLETE`). Producers on the current 19 ids would therefore be hard-rejected. The first adopter is not blocked because it runs its own haptics gate. The physical-iPhone run is parked. v26 removes silent weakness rather than widening vocabulary. The ADR stop-list point is secondary and weak, because the ADR has no haptics entry.
- **Evidence:**

| Reading | Status | Evidence |
|---|---|---|
| Reading 1 — the pipeline published | Met | Core 0.2.11 ordinary run 38155320492, six-child COMPLETE rollup; Chimeway 0.1.2 ordinary run 38167555514; source `milestones/v23.0-MILESTONE-AUDIT.md`. |
| Reading 2 — the pipeline was proven | Only qualifiedly met | REL-10 BREACHED, `closeout_disposition: accepted_historical_breach_requires_qualified_archive`, Phase 175 8/9, milestone 42/43. A first-publish timing and ancestry limit that no later publish can repair. Sources: the audit and `MILESTONES.md`. |

  Verdict: defer under either reading.

  Real numbers in the tree: `@schema_version 2` with 19 assertion ids; a reopened change would bump 2->3. The seed's "20" assertions is stale.
- **Reopen trigger:** any one of (a) a planned release that deliberately breaks the proof-lane contract, with its pipeline already proven by an earlier ordinary publish; (b) the first adopter asks to retire its own haptics gate; (c) the physical-iPhone run resumes under `first-b2c-adopter-readiness`. Reopening is a new requirement, never a drive-by edit.
- **Date:** 2026-10-16
- **Evidence of no source change:** the candidate diff from bd294007 does not touch `physical_iphone_contract.ex` (checked in RUNS/deferrals-187.check; 187-07 re-checks the committed diff).
- **Recorded also in:** SEED-014 CW-REQ-A section; REQUIREMENTS.md Future Requirements.

## CW-REQ-D — RouteUnavailableView renders a route id

- **Disposition:** `defer-with-reason`
- **Decided:** Phase 187 discussion (D-15).
- **Reason:** `RouteUnavailableView.swift:29-30` renders `Text("Route: \(routeID)")` as a monospaced footnote when a denial carries a route id. Example copy: "Route: <route id>". No v26 phase touches Swift, and the first adopter composes its own denial view from `RouteDenialPresentation`, so it is not affected.
- **Evidence:** the view lines above in the shipped shell-core package; the seed's workaround note (host-owned denial view).
- **Reopen trigger:** (a) a diff that touches shell-core Swift or generated template sources and already changes the template version; (b) the first adopter adopts the shipped `RouteUnavailableView`. If reopened, drop only the `Route:` line and keep `routeID` on `RouteDenialPresentation`. No v26 phase touches Swift.
- **Date:** 2026-10-16
- **Evidence of no source change:** no `.swift` file in the candidate diff (checked in RUNS/deferrals-187.check).
- **Recorded also in:** SEED-014 CW-REQ-D section; REQUIREMENTS.md Future Requirements.

## Compile-time Policy.Route rule for :local_first without island_contract

- **Disposition:** `defer-with-reason`
- **Decided:** Phase 187 discussion (D-12).
- **Reason:** Doctor is the single enforcement point. Plan 187-01 makes a runtime `:offline_island` route with `offline: :local_first` and no `island_contract` a doctor `:error` (`offline_posture_incomplete`). A compile-time rule would be a breaking change for hosts and has no demonstrated need.
- **Evidence:** `Crosswake.Policy.Route.validate_offline_contracts/1` checks only that a contract implies the mode (`cache_contract` requires `:cached_read_only`; `island_contract` requires `:offline_island` with `:local_first`). It does not check the reverse.
- **Reopen trigger:** (a) a second `:local_first` runtime or route family besides `:offline_island`; (b) a host route ships `:local_first` without `island_contract` although doctor ran; (c) the first adopter's physical-iPhone proof shows doctor is not run before a build.
- **Date:** 2026-10-16
- **Evidence of no source change:** no change to `Policy.Route` in this plan.
- **Recorded also in:** REQUIREMENTS.md Future Requirements (DOCTOR-02, compile-time rule recorded as deferred).

## Known gaps (D-09), recorded and not fixed

1. A `:cached_read_only` route without `cache_contract` compiles (`Policy.Route` checks only that a contract implies the mode) and stays filtered out by doctor. This corrects SEED-014 CW-REQ-F, whose claim that this shape is "already invalid" is false in the candidate.
2. A `:native_screen` `:local_first` route without a contract compiles and doctor does not flag it. Plan 187-01's control test pins this so widening is a deliberate change.
3. Observable doctor output for both shapes: `offline.status` stays "supported" with finding `offline_posture_ready` (advisory); the routes are absent from `offline.routes`. A host whose only offline claims are these shapes prints `offline posture: supported states=[...] routes=[]`, and JSON `offline.routes` is `{}`. This "supported" does not mean the route's offline claim is backed by a contract. The residual is disclosed here, not mitigated (187-01 T-187-02 covers only the no-claim case).

Both gaps reopen on the compile-time rule's triggers above.

## Phase 186 review items

WR-01 (refuse an unreadable Info.plist in the physical-iPhone preflight) is not folded into Phase 187. It stays the owner's open decision and the next preflight change. WR-03 (harness `--evidence ""` and bare `--evidence`) is folded into 187-05 as a recorded deviation from the DOCTOR scope, because Phase 188 uses the harness and changes no code.
