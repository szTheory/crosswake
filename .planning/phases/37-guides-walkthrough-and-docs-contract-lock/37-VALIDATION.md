---
phase: 37
slug: guides-walkthrough-and-docs-contract-lock
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-29
---

# Phase 37 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> This phase's entire Nyquist contract IS `test/crosswake/guides/commerce_test.exs`.
> All five success criteria are mechanically checkable in one file — no manual UAT.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir test framework) |
| **Config file** | `test/test_helper.exs` (standard Mix project) |
| **Quick run command** | `mix test test/crosswake/guides/commerce_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~3 seconds (guide test file only; reads markdown + module-scope `Code.require_file` of pure commerce modules) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/guides/commerce_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

> Task IDs assigned by the planner. Every task in this phase is verified by the
> same single command — the docs-contract test file. The rows below map each
> success criterion to its assertion class; the planner binds each to a task.

| SC | Requirement | Behavior | Test Type | Automated Command | Status |
|----|-------------|----------|-----------|-------------------|--------|
| SC#1 | DOCS-01 | `### Paywall Corridor Walkthrough` H3 exists; each step anchors a named module/function | string-presence | `mix test test/crosswake/guides/commerce_test.exs` | ⬜ pending |
| SC#2 | DOCS-01 | Mock-vs-real callout present (`provider: "mock"`, no StoreKit, no Play Billing) | string-presence | same | ⬜ pending |
| SC#3 | DOCS-02 | `CrosswakeExample.Commerce.MockStorefront` named exactly; `provider_reference` + `evidence_ref` field names present; six anchored functions resolve | string-presence + live-code guard (`function_exported?/3`) | same | ⬜ pending |
| SC#4 | DOCS-02 | Phase23 three-layer heading assertions still pass (regression fence) | regression (existing test) | same | ⬜ pending |
| SC#5 | DOCS-02 | All four non-claims (`StoreKit`, `Play Billing`, `Device-local authority`, `Offline purchase replay`) remain present (regression fence) | regression (existing test) | same | ⬜ pending |
| D-08 | DOCS-01 | Guide cites `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` as merge-blocking proof | string-presence | same | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Live-code guard — anchored functions (D-06.2)

`Code.require_file` the PURE example commerce modules at module scope (load order:
`reconciliation_keys` → `reconciliation_inbox` → `mock_storefront` → `entitlement_projection`
→ `mock_backend`), then assert each resolves:

- `function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_purchase, 2)`
- `function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_restore, 2)`
- `function_exported?(CrosswakeExample.Commerce.ReconciliationInbox, :ingest_evidence, 2)`
- `function_exported?(CrosswakeExample.Commerce.EntitlementProjection, :project_snapshot, 2)`
- `function_exported?(CrosswakeExample.Commerce.EntitlementProjection, :derived_state, 1)`
- `function_exported?(CrosswakeExample.Commerce.MockBackend, :build_verified_snapshot, 2)`

> `MockBackend.verify_and_broadcast/2` touches `Phoenix.PubSub` at runtime — NEVER invoke;
> only `function_exported?`-check `build_verified_snapshot/2`. Switch the guide test from
> `async: true` to `async: false` (module-scope `require_file` collision avoidance — matches
> the Phase 34/36 proof precedent).

---

## Nyquist Sampling — Drift Detection Coverage

| Drift Event | Caught By |
|-------------|-----------|
| Rename/remove any anchored function (`simulate_purchase`, `simulate_restore`, `ingest_evidence`, `project_snapshot`, `derived_state`, `build_verified_snapshot`) | matching `function_exported?/3` assertion fails |
| Drop the walkthrough heading | `content =~ "### Paywall Corridor Walkthrough"` fails |
| Drop the mock-vs-real callout vocabulary | `provider: "mock"` / StoreKit / Play Billing presence assertions fail |
| Add a 4th H2 layer | phase23 three-layer assertion semantics + H3 placement guard (D-01/D-02 structurally enforce H3-only) |
| Drop one of the three H2 layers | `content =~ ~r/^## …\s*$/m` regression fence fails |
| Drop a Layer 3 non-claim | four-non-claims regression fence fails |
| Rename the proof file without updating the guide | `content =~ "test/crosswake/proof/phase34_paywall_corridor_proof_test.exs"` fails |

**Density assessment:** Six `function_exported?` assertions cover every anchored function;
string-presence assertions cover heading, module name, canonical field names, callout
vocabulary, and proof citation. Combined, they make `guides/commerce.md` a genuinely
merge-blocking artifact — renaming or removing any anchored symbol breaks the test immediately.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* `commerce_test.exs` already exists
with full ExUnit scaffolding; new assertions append to it. No new test files, fixtures, or
framework install required. The only structural change is the `async: true` → `async: false`
switch on the existing test module.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.* No manual UAT — the docs-contract test
mechanically samples all five success criteria plus the D-08 proof citation.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify (single command: `mix test test/crosswake/guides/commerce_test.exs`)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
