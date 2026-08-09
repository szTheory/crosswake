# Phase 156 Multi-Source Coverage Audit

SOURCE | ID | Feature / requirement | Plan | Status | Notes
--- | --- | --- | --- | --- | ---
GOAL | — | Route-declared action menu renders real iOS/Android native chrome and returns a typed reply, provable without simulator/emulator | 02-07 | COVERED | Tracer, platform presenters, host route, and proof close the full outcome.
REQ | MENU-01 | Route policy declares allowed actions and fallback behavior | 01, 02, 06 | COVERED | One-way gate, schema/manifest tracer, and exemplar.
REQ | MENU-02 | Both native cores render and return typed choice | 02-05, 07 | COVERED | Contract/reply tracer, two production presenters, race authority, vectors.
REQ | MENU-03 | Native accessibility semantics and dismiss gestures | 03, 04, 06, 07 | COVERED | Semantic presenter tests plus honest advisory-device boundary.
REQ | PROOF-03 | Both natives consume committed vectors without simulator/emulator | 02-04, 07 | COVERED | Real evaluators, fake presenters, canonical corpus, negative control.
RESEARCH | — | Route policy is sole authorization source | 02, 06 | COVERED | Shared validated projection; no DOM/native authority.
RESEARCH | — | Fallback-first native enhancement | 02, 05, 06 | COVERED | Same projection and exactly-once race.
RESEARCH | — | Contract 1.2.0 structured JSON | 02-04 | COVERED | Core plus both native decoders.
RESEARCH | — | Truthful old-shell preflight and failure layering | 02 | COVERED | Corrects D-56/D-29 premise.
RESEARCH | — | Platform-adaptive UIKit/PopupMenu presenters | 03, 04 | COVERED | No new dependency.
RESEARCH | — | Canonical vector proof, drift guard, negative control | 07 | COVERED | Anti-vacuous dual-native lane.
RESEARCH | — | ASVS L1 authorization, integrity, replay, privacy, and bounds | 02-07 | COVERED | Every plan carries a STRIDE threat model and high-severity mitigations.
CONTEXT | D-01 | Phoenix-owned trigger and `action_menu.present` | 02, 06 | COVERED |
CONTEXT | D-02 | No shell-owned toolbar/navigation chrome | 06 | COVERED | Explicit non-execution rationale/prohibition.
CONTEXT | D-03 | No DOM scanning as authority | 02 | COVERED |
CONTEXT | D-04 | Narrow bounded-control JTBD | 06 | COVERED | Explicit non-execution rationale.
CONTEXT | D-05 | Public `anchor_id:` option | 02, 06 | COVERED |
CONTEXT | D-06 | Hook-measured typed anchor metadata | 02 | COVERED |
CONTEXT | D-07 | Invalid anchors fail closed | 02, 05 | COVERED |
CONTEXT | D-08 | One route `action_menu:` contract | 02 | COVERED |
CONTEXT | D-09 | Exact published policy/manifest shape | 01, 02 | COVERED | Blocking one-way gate precedes implementation.
CONTEXT | D-10 | Policy excludes localized/dynamic presentation state | 02 | COVERED |
CONTEXT | D-11 | Capability/contract cross-field validation | 02 | COVERED |
CONTEXT | D-12 | Frozen Phase 155 action projection | 02, 06 | COVERED |
CONTEXT | D-13 | Runtime subset/invariant validation | 02 | COVERED |
CONTEXT | D-14 | Visible disabled nil-id rows | 02-04, 06, 07 | COVERED |
CONTEXT | D-15 | Empty projection does not present native chrome | 02, 05, 06, 07 | COVERED |
CONTEXT | D-16 | Family-form `Bridge.push/3` call | 02, 06 | COVERED |
CONTEXT | D-17 | UIKit action sheet and Android PopupMenu | 03, 04 | COVERED |
CONTEXT | D-18 | No Android Material bottom sheet | 04 | COVERED |
CONTEXT | D-19 | Mandatory iPad anchoring | 03 | COVERED |
CONTEXT | D-20 | Intentional semantic platform divergence | 03, 04, 07 | COVERED |
CONTEXT | D-21 | Native labels/roles/scaling/dismiss semantics | 03, 04, 06 | COVERED |
CONTEXT | D-22 | Disabled explanations remain present | 03, 04 | COVERED |
CONTEXT | D-23 | Destructive last; Phoenix owns confirmation/mutation | 03, 04, 06 | COVERED |
CONTEXT | D-24 | Icons remain nil/unrendered | 02-04 | COVERED |
CONTEXT | D-25 | Semantic proof, no accessibility overclaim | 03, 04, 06, 07 | COVERED |
CONTEXT | D-26 | Exactly one selected/dismissed ok reply | 01-04 | COVERED | Blocking one-way gate in 01.
CONTEXT | D-27 | Selected id untrusted; reauthorize | 02-06 | COVERED |
CONTEXT | D-28 | Fallback-first native enhancement | 05, 06 | COVERED |
CONTEXT | D-29 | First answer wins and cancels stale native chrome | 05 | COVERED |
CONTEXT | D-30 | Native/fallback outcome handling and late-drop | 05, 06 | COVERED |
CONTEXT | D-31 | Additive 1.2.0 structured payloads | 01-04 | COVERED | Blocking one-way gate in 01.
CONTEXT | D-32 | Core-owned/user-answer/native-required/merge-blocking truth | 06, 07 | COVERED |
CONTEXT | D-33 | Shell capability/version preflight | 02 | COVERED |
CONTEXT | D-34 | Distinct failure layers | 02 | COVERED |
CONTEXT | D-35 | Canonical vector matrix | 03, 04, 07 | COVERED |
CONTEXT | D-36 | Fake presenters, real paths, negative control, adapter pins | 07 | COVERED |
CONTEXT | D-37 | Contract/dispatch claim and explicit non-claims | 03, 04, 06, 07 | COVERED |
CONTEXT | D-38 | Bounded telemetry without sensitive values | 02, 05, 06 | COVERED |

## Specless probe resolution

The four descriptor-less edge rows are resolved from the locked phase artifacts:

- MENU-01: explicit route-policy cross-field validation, one-menu cardinality, empty/one/eight/over-eight bounds, and fallback declaration.
- MENU-02: structured projection validation, both platform presenters, selected/dismissed exactly-once outcomes, stale/unknown/disabled rejection, and race cancellation.
- MENU-03: native labels/enabled/destructive/dismiss semantics are implementation requirements; real assistive-technology speech and final device behavior remain advisory.
- PROOF-03: one canonical vector corpus, exact mirrors, real evaluators, fake presenters, drift checks, and fail-first negative control.

Descriptor-less prohibition recall kept the product-specific constraints projected into plan `must_haves.prohibitions`: no DOM/native authority, no shell toolbar, no native mutation/confirmation, no independent menu derivation, no stale-path denial collapse, no sensitive telemetry, no platform-parity dependency/custom UI, and no device/accessibility/pixel overclaim. Routine engineering concerns were left to task verification; canonical security issues are handled by each plan's ASVS L1 threat model.
