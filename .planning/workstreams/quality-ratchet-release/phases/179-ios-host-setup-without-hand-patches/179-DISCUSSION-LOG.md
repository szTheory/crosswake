# Phase 179: iOS Host Setup Without Hand Patches - Discussion Log

> **Audit trail only.** Downstream agents consume 179-CONTEXT.md, not this log.

**Date:** 2026-10-13
**Workstream:** quality-ratchet-release
**Disposition:** Approved decisions carried forward; no new unresolved preference questions.

## User direction and approval

The user previously requested broad subagent research, tradeoff comparisons, applicable project prompts, consumer-focused DX, expert lenses and a coherent recommendation set. They then said “i approve the roadmap” and invoked `$gsd-discuss-phase 179 --ws quality-ratchet-release`.

The approved roadmap and scope adopt the selected research synthesis. The workflow's skip assessment and prior-decision rule apply: no meaningful user gray areas remain; unresolved host/Xcode behavior needs execution rather than another preference interview. No answer, selection or runtime success is fabricated. No new question was asked, and no interrupted-discussion checkpoint was needed.

## Alternatives resolved upstream

| Area | Selected | Rejected or bounded alternative | Reason |
|---|---|---|---|
| Config authority | Ordinary host build-time config, normalized explicit generator options | A new config DSL or lasting CLI overrides | One source of truth follows the host's Mix environment |
| Config lifecycle | Compile-only requirement | app.config/app.start/runtime.exs | Actual minimal Mix experiment showed a runtime credential dependency |
| Native ownership | Missing-only scaffold plus recognized managed projections | Rewriting arbitrary edited projects | Host owns Swift, project and entitlement edits |
| Update safety | Preflight, staging, atomic per-file replacement, interruption detection/recovery | Claiming multi-file rename atomicity | Mixed outputs must deny, not silently pass |
| Signing | Managed xcconfig plus effective app/test/SDK/config inspection | Checking rendered strings or claiming physical installation | Project precedence and device credentials remain separate |
| Manifest | Selected host router/entry/primary origin | Example fixtures as production truth | Canonical route and authority boundaries must survive generation |
| Evidence | Safe presence/field/status/cause categories | Raw private config/settings or identity hashes | Private storage does not waive privacy rules |
| Delivery | Independent qualified source work; scoped planning here | Recovery Git/source mutation or repeat PR delivery | Existing preservation and consumed-operation limits remain |

## Agent Discretion

Subordinate key names, deterministic test identity derivation, managed recovery metadata, precise migration steps and safe diagnosis wording may be resolved during research/planning within the approved boundaries. `:ios_host` follows the researched configuration resolution. No new product scope, credential collection or remote operation is selected.

## Checks and limits

Registered phase initialization found Phase 179 with no context, research, plans or verification. There was no phase SPEC/checkpoint/continue file, no pending todo match, no codebase map and no active discuss pre-hook. A bounded read-only code scout located current generator/template/manifest seams. Recovery protection check returned unchanged before artifact writing. Full host/Xcode generation remains unexecuted.

The skill's commit steps are skipped because AGENTS.md and approved scope protect this recovery checkout's Git state. State fields/session use registered writers; handoff prose lacking a registered mutation uses the installed locked planning/state seams. Fresh artifact/routing/preservation checks are recorded in 179-DISCUSSION-VALIDATION.json.

## Deferred Ideas

No new ideas. Phase 180 and the existing physical/adopter gates retain their approved owners. No automatic plan/execute chain.
