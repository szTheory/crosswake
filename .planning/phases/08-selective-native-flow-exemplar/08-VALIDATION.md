# Phase 8 Validation

**Validated:** 2026-05-18
**Phase:** 08-selective-native-flow-exemplar
**Status:** Ready for execution planning gate

## Gate Summary

- Phase context exists and is locked in `08-CONTEXT.md`.
- Phase research exists in `08-RESEARCH.md`.
- Phase pattern map exists in `08-PATTERNS.md`.
- Four executable plan artifacts exist: `08-01-PLAN.md` through `08-04-PLAN.md`.
- Roadmap and state surfaces reflect the planned Phase 8 execution path.

## Resolved Planning Decisions

### Example-host persistence boundary

Phase 8 will satisfy locked decision D-26 literally with an example-host-only Ecto-backed claim and submission slice. The repo root `crosswake` application remains free of app-level persistence concerns.

### Native seam boundary

The capture route will plan explicit route-local seams for:

- one `:native_screen` runtime
- one required pack
- one explicit `:camera` capability declaration
- one semantic `transfer.upload.prepare` seam

### Proof and docs ordering

Execution order is validated as:

1. lane and state skeleton
2. nested capture plus review handoff
3. shell fixture and proof-lane alignment
4. public guide and doc-contract refresh

Doc contract enforcement belongs with the doc-refresh slice, not before it.

## Nyquist Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Locked route map preserved | pass | Four `/native` routes, exactly one `:native_screen` |
| Pack, transfer, and capability seams planned | pass | Capture route carries all three seam classes explicitly |
| Review-before-upload truth preserved | pass | Upload stays gated behind Phoenix review |
| Shared artifact class preserved | pass | Proof extends checked-in example hosts instead of forking a sample app |
| Support truth remains canonical | pass | Phase 8 docs route status back to existing support and install guides |

## Remaining Execution Risks

- Native-host verification still depends on provisioned iOS and Android tooling, especially on Android.
- The example-host Ecto slice must stay narrow and avoid leaking persistence responsibilities into Crosswake core.
- Public docs must retire the older generic selective-native route story in the same phase as the proof refresh.

## Validation Verdict

Phase 8 is valid for execution planning. The execution plans should proceed with the example-host-only Ecto decision, explicit capture capability planning, and doc-contract checks deferred to the documentation refresh slice.
