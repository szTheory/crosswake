# Phase 37: Guides Walkthrough And Docs-Contract Lock - Context

**Gathered:** 2026-05-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Add an end-to-end **Paywall Corridor Walkthrough** to `guides/commerce.md` written against the
final shipped example-host code, and extend `test/crosswake/guides/commerce_test.exs` to lock the
walkthrough's module/function references, canonical field names, and the four non-claims against
the shipped example — making `guides/commerce.md` a merge-blocking artifact.

**The lane the walkthrough narrates (all SHIPPED, anchor against — do NOT modify):**
route declaration (`commerce: [corridor: :subscription_default, role: :paywall_entry]`) →
`CrosswakeExample.Commerce.MockStorefront.simulate_purchase/2` · `simulate_restore/2` →
`ReconciliationInbox.ingest_evidence/2` → `EntitlementProjection.project_snapshot/2` ·
`derived_state/1` (+ `MockBackend.build_verified_snapshot/2`) → `PaywallLive` rendering the four
derived states.

**In scope:** Edits to `guides/commerce.md` (one new `### Paywall Corridor Walkthrough` H3 inside
Layer 1) and new assertions appended to `commerce_test.exs`. No shipped lib or example-host code
changes.
**Requirements:** DOCS-01, DOCS-02.

**Out of scope:** Any change to `lib/crosswake/**` or example-host modules (shipped/locked from
Phases 21/33/34/35/36); StoreKit / Play Billing / provider-SDK references (`provider: "mock"` only,
AF-01/AF-07); embedded code snippets (anchor-only, D-04); promoting the walkthrough to a 4th
top-level layer (D-02).

</domain>

<decisions>
## Implementation Decisions

### A. Walkthrough placement (DOCS-01, SC#1/SC#4)
- **D-01 (USER-CONFIRMED):** The walkthrough is a new `### Paywall Corridor Walkthrough` **H3
  subsection inside Layer 1 "Commerce Support Truth"**, placed after the existing
  `### Minimal Reconciliation Inbox Example`. The runnable corridor IS canonical support truth.
- **D-02 (USER-CONFIRMED):** Do **NOT** add a 4th top-level H2 layer. This preserves the guide's
  "structured in three explicit layers" intro prose verbatim and keeps the phase23
  three-H2-heading assertions (`commerce guide publishes three explicit layer headings`) passing
  unchanged (SC#4). The three H2 layers remain exactly: `## Commerce Support Truth` /
  `## Reviewer And Storefront Playbooks` / `## Rough Edges And Non-Claims`.

### B. Code rendering depth (DOCS-01, SC#1)
- **D-03 (USER-CONFIRMED):** **Anchor-only.** Each walkthrough step renders prose + the named
  example-host module/function (e.g. `CrosswakeExample.Commerce.MockStorefront.simulate_purchase/2`)
  + its relative file path. **No copied code blocks** — zero drift risk, and the docs-contract
  test locks the names instead of comparing snippet bodies. Directly satisfies SC#1 ("anchors each
  step to a named example-host module and function").
- **D-04:** Steps to anchor, in order (SC#1): route declaration → `MockStorefront` purchase/restore
  call → `ReconciliationInbox.ingest_evidence/2` evidence ingestion → `project_snapshot/2` snapshot
  projection → `derived_state/1` derived state → `PaywallLive` rendering.
- **D-05 (USER-CONFIRMED, SC#2):** The walkthrough **opens with an explicit mock-vs-real callout**
  stating `MockStorefront` uses `provider: "mock"` and that **no StoreKit or Play Billing code is
  shipped** (reuse the canonical "not shipped" non-claim vocabulary already in Layer 3).

### C. Docs-contract binding strength (DOCS-02, SC#3/SC#4/SC#5)
- **D-06 (USER-CONFIRMED — the "lock against the shipped example" decision):** **Hybrid** binding,
  two complementary assertion classes appended to `commerce_test.exs`:
  1. **String-presence (markdown structure)** — mirrors the existing test idiom (`content =~ ...`):
     - `### Paywall Corridor Walkthrough` heading exists (SC#1).
     - `CrosswakeExample.Commerce.MockStorefront` named exactly (SC#3).
     - Canonical field names `provider_reference` and `evidence_ref` present, NOT invented aliases
       (SC#3).
     - The mock-vs-real callout copy (`provider: "mock"`, "no StoreKit"/"no Play Billing") present
       (SC#2).
  2. **Live-code guard (binds the named refs to reality, stays hermetic)** — `Code.require_file`
     the **PURE** example-host commerce modules at module scope (the established Phase 34/36 idiom)
     and assert `function_exported?/3` for each anchored function (e.g.
     `function_exported?(CrosswakeExample.Commerce.MockStorefront, :simulate_purchase, 2)`,
     `:simulate_restore/2`; `ReconciliationInbox.ingest_evidence/2`;
     `EntitlementProjection.project_snapshot/2` + `derived_state/1`;
     `MockBackend.build_verified_snapshot/2`). Renaming/removing an anchored example function now
     breaks the guide test — the guide is genuinely locked to the shipped example, not to dead
     strings.
- **D-07 (USER-CONFIRMED — regression fences, SC#4/SC#5):** The new assertions MUST NOT weaken
  existing coverage. Explicitly:
  - The phase23 `commerce guide publishes three explicit layer headings` assertion still passes
    (SC#4) — guaranteed structurally by D-01/D-02 (no new H2).
  - All four non-claims remain present after the walkthrough update (SC#5): re-confirm the existing
    `non-claims section explicitly names StoreKit, Play Billing, device-local authority, and offline
    replay` test still passes; the four canonical non-claims are `StoreKit`, `Play Billing`,
    `Device-local authority`, `Offline purchase replay`.

### D. Proof-file citation (DOCS-01)
- **D-08 (USER-CONFIRMED):** The walkthrough **explicitly cites**
  `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` as the hermetic, merge-blocking
  proof that the narrated lane actually runs end-to-end. This makes "the guide is a merge-blocking
  artifact" literally true (Phase 36 36-CONTEXT deferred note) and hands adopters the runnable
  evidence. (Optional discretion: also note the `phase34-proof.yml` hermetic job runs it.)

### Claude's Discretion
- Whether the guide test gains `async: false` once it `Code.require_file`s the pure example modules
  (the Phase 34/36 hermetic proofs use `async: false`; the guide test is currently `async: true`).
  Planner picks the safe option for module-scope `require_file` collision avoidance.
- Exact relative `Code.require_file` paths from `test/crosswake/guides/` to the example-host pure
  commerce modules (mirror the form in `test/crosswake/proof/phase34_mock_storefront_test.exs`).
- Whether to assert the proof-file **path string** appears in the guide (locking D-08) in addition
  to prose citation — low-cost, recommended.
- Exact step prose, anchor formatting (inline-code vs link), describe/test block naming, and
  assertion message wording.
- Whether to factor the new live-guard module list into a shared `@anchored_functions` attribute
  for readability.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone / Requirements
- `.planning/REQUIREMENTS.md` — v3.4 requirements; **DOCS-01** (end-to-end mock-corridor
  walkthrough anchored to named example-host modules/functions) and **DOCS-02** (docs-contract test
  locks references against the example host without weakening phase23 three-layer assertions) for
  this phase. Out of Scope table: AF-01 (provider-SDK ban), AF-07 (`provider: "mock"` only).
- `.planning/ROADMAP.md` §"Phase 37: Guides Walkthrough And Docs-Contract Lock" — goal + 5 success
  criteria (SC#1 anchored steps, SC#2 mock-vs-real callout, SC#3 named module + canonical field
  names, SC#4 phase23 assertions still pass, SC#5 four non-claims survive).
- `.planning/threads/commerce-archetype-proof.md` — milestone thread / strategic intent.

### The artifact being edited + its test (read both fully)
- `guides/commerce.md` — the guide. Current structure: three H2 layers (`## Commerce Support Truth`
  / `## Reviewer And Storefront Playbooks` / `## Rough Edges And Non-Claims`); intro states "three
  explicit layers". The new H3 goes after `### Minimal Reconciliation Inbox Example` (line ~103) in
  Layer 1. Layer 3 already carries the canonical "X is not shipped" non-claim copy to reuse (D-05).
- `test/crosswake/guides/commerce_test.exs` — the docs-contract test (`async: true`, reads only the
  markdown). Append the D-06/D-07 assertions here. Mirror existing idiom: setup_all reads
  `@guide_path`; assertions use `content =~ ...` and section-split helpers. The phase23 layer/
  non-claim tests (lines ~217-289) are the regression fences D-07 protects.

### Code asserted against (reuse, DO NOT modify — shipped/locked)
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_storefront.ex` — `simulate_purchase/2`,
  `simulate_restore/2`; `provider: "mock"`, `@subscription_entry_id "sub_pro_monthly"` (anchor +
  live guard).
- `examples/phoenix_host/lib/crosswake_example/commerce/reconciliation_inbox.ex` —
  `ingest_evidence/2`.
- `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` —
  `project_snapshot/2`, `derived_state/1` (`:stale | :pending | :denied | :granted`).
- `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` —
  `build_verified_snapshot/2` (synchronous, server-free; require_file-at-module-scope safe).
- `examples/phoenix_host/lib/.../*_live.ex` (`PaywallLive`) — the rendering anchor for the final
  walkthrough step. NOTE: this is example-host **runtime** code — anchor it by name in the guide,
  but do NOT `Code.require_file` it in the test (would break hermeticity; only the pure commerce
  modules above may be required — Phase 36 D-02).
- `examples/phoenix_host` router — the `:subscription_default` corridor route declaration
  (`commerce: [corridor: :subscription_default, role: :paywall_entry]`) for the first step (PWAL-01,
  Phase 33).

### Proof the walkthrough cites (D-08)
- `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` — the hermetic merge-blocking proof
  of the full lane (Phase 36). The walkthrough cites it as runnable evidence.
- `.github/workflows/phase34-proof.yml` — the hermetic merge-blocking CI job that runs it.

### Prior-phase context
- `.planning/phases/36-hermetic-proof-lane/36-CONTEXT.md` — the hermetic `Code.require_file`-pure-
  modules idiom (D-01), the "pure commerce modules only, never runtime paths" hermeticity rule
  (D-02) the D-06 live guard reuses, and the deferred note pointing here.
- `.planning/phases/34-mockstorefront-and-idempotency-invariants/34-CONTEXT.md` — `MockStorefront`
  shape, `@subscription_entry_id "sub_pro_monthly"`, MOCK-03 drop-in-swap-target framing the
  walkthrough's mock-vs-real callout echoes.
- `.planning/phases/35-reconciliation-wiring-and-four-state-liveview/35-CONTEXT.md` — `PaywallLive`
  four-state rendering + the shared verify→project→derive core the walkthrough narrates.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `commerce_test.exs` setup_all + `content =~`/section-split idiom — the new string-presence
  assertions (D-06.1) extend it directly; no new test scaffolding needed.
- The canonical "X is not shipped" non-claim copy in Layer 3 of `guides/commerce.md` — the
  mock-vs-real callout (D-05) reuses this exact vocabulary so SC#2 and SC#5 stay consistent.
- The Phase 34/36 `Code.require_file`-pure-modules-at-module-scope idiom
  (`phase34_mock_storefront_test.exs` header) — copied into the guide test for the D-06.2 live
  guard; keeps it hermetic / merge-blocking-safe.

### Established Patterns
- "Three explicit layers" is a load-bearing structural invariant locked by a phase23 test — new
  content stays at H3 within an existing layer (D-01/D-02), never a new H2.
- Docs-contract tests bind canonical surface names (module/function/field) by exact string + (now)
  live `function_exported?` so adopter-facing prose can't drift from shipped code.
- Hermetic = require_file PURE example commerce modules only; runtime modules (`*_live.ex`,
  endpoint, router) are anchored by name in prose but never loaded in tests.

### Integration Points
- The guide test is the only "integration" — it now loads the pure example commerce modules and
  asserts the guide's named references resolve to real functions. The guide itself adds no code; it
  cites the existing proof file and example modules.

</code_context>

<specifics>
## Specific Ideas

- The walkthrough's value proposition: it's the first *copy-able* corridor since `crosswake 0.1.0`
  went live on hex.pm (2026-05-29) — anchor-only + cited proof means an adopter can read the
  walkthrough, open the named files, and run the named proof to see it green.
- The hybrid lock (D-06) is the sharpest reading of the phase goal's "lock references **against the
  shipped example**": string presence alone would let `MockStorefront` survive as a dead string
  after a rename; `function_exported?/3` makes the guide break loudly instead.
- All four success-criteria fences are mechanically checkable in one test file — no manual UAT,
  matching the Phase 30 "verify release-surface deliverables with hermetic ExUnit + CI" key decision.

</specifics>

<deferred>
## Deferred Ideas

- **Embedded/extracted code snippets in the walkthrough** — rejected for v3.4 (D-03 anchor-only).
  If adopters later want copy-paste snippets, a future phase could add a snippet-extraction test
  that compares fenced blocks against source line ranges.
- **Live-guarding `PaywallLive` / runtime modules** — out of scope; would break the hermetic-lane
  discipline (Phase 36 D-02). Anchored by name in prose only.
- **ROADMAP SC#3/SC#4 rewording from Phase 36** — still open from 36-CONTEXT deferred; unrelated to
  this phase's edits but worth resolving before milestone verification.
- **ExDoc zero-warnings cleanup (HEX-03)** — deferred (STATE), unrelated to this guide phase.

### Reviewed Todos (not folded)
None — `todo.match-phase` surfaced no matches for Phase 37. The STATE pending todos (PubSub start;
verification-simulation shape) were resolved in Phase 35 and do not bear on this docs-only phase.

</deferred>

---

*Phase: 37-Guides Walkthrough And Docs-Contract Lock*
*Context gathered: 2026-05-29*
