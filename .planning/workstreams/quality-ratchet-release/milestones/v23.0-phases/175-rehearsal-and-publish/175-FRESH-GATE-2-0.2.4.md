# Phase 175 — Gate 2 Evidence for Fresh Core 0.2.4

**Gate state:** `AUTHORIZED` (consumed by run `36035737504`)
**Authorized:** `true`
**Authorization:** exact response recorded in the bound machine evidence
**Decision presented:** `true`

## Exact candidate and receipt

PR #201 merged at `f3827d0bf4131badd96d04d924f9faca2789d284` for version `0.2.4`, base `e298793a40538500003602edb6b1d7ea2221ee84`, head `dfe7c0b4be909130f2474ed7d4e97e8e52d49498`, tree `215493f06e4119faa25a692db7f2e8de47d39b3c`. Candidate CI run `36026349375` and fresh Hex/iOS/Maven rehearsal runs `36029591408`, `36029609207`, and `36029497304` all bind to that identity and report no external publication change.

Trusted attestation run `36030036687` produced one unexpired canonical artifact, `phase168-candidate-receipt-dfe7c0b4be909130f2474ed7d4e97e8e52d49498` (ID `10821206063`; SHA-256 `aad9a9f23a291763353b4e087d7f9e332884bd68ee24cfabfe325c527a9947ee`; expires `2026-10-08T16:51:30Z`). Its state is `READY FOR APPROVAL`; the receipt identity matches the candidate; publication is `NONE`; `external_state.changed=false`. The artifact digest and four run bindings are recorded in the machine-readable Gate 2 input.

Runbook ancestry passed for candidate base/head and exact merge OID. The pre-merge probes found all targets absent; after the single authorized ordinary graph, Hex is present, iOS v0.2.4 tag is absent, and Maven POM is absent. See the partial publish-leg record.

Plan 175-20 displayed the one-way Gate 2 question after its own machine precheck. The exact response was received and consumed by one protected merge and its ordinary graph. No retry or recovery was authorized or performed.

## Plan 175-20 live precheck

Precheck passed at `2026-09-24T17:01:31Z`: PR #201 remains open, non-draft, clean and mergeable at the recorded base/head/tree; Crosswake CI remains successful (49/49); the trusted attestation run is successful at the exact head and has exactly one matching unexpired artifact with the recorded digest; runbook ancestry passes on base and head; Hex, the iOS tag, and Maven remain absent. The exact response was received and durably bound. It authorized only one protected merge and the single ordinary graph, which ended PARTIAL.

The exact authorization was consumed by protected merge `f3827d0bf4131badd96d04d924f9faca2789d284` and ordinary run `36035737504`. The run ended PARTIAL. This authorization cannot be reused for recovery or any additional publish attempt. See `175-FRESH-PUBLISH-LEG-2-0.2.4.md`.
