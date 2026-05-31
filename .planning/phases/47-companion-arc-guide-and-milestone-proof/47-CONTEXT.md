# Phase 47: Companion Arc Guide And Milestone Proof - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the v3.5 companion milestone by turning the shipped companion seams into
a standalone adopter/maintainer guide and a milestone-level proof that the
guide, doctor output, support-matrix truth, denial vocabulary, and fail-closed
optional-dependency behavior agree.

**Delivers:**
- A broadened `guides/companions.md` covering the companion pattern, the
  `Crosswake.Companion` behaviour, the `lib/crosswake/companions/<name>/`
  convention, optional-dependency posture, telemetry, Rulestead gating, Rindle
  media, Sigra auth contracts, proof posture, and deferred non-goals.
- Stronger docs-contract tests that assert live-code parity against companion
  IDs, route-policy keys, denial reasons, doctor finding codes, support-matrix
  truth, and exported modules/functions.
- A milestone-level hermetic proof assertion that all shipped v3.5 companion
  surfaces remain safe with optional dependencies absent.

**Satisfies:** PROOF-02.

**In scope:**
- Restructure and expand `guides/companions.md`.
- Update `test/crosswake/guides/companions_test.exs` from keyword presence to
  live-code parity checks.
- Add a small aggregate hermetic proof test for the v3.5 companion arc.
- Wire that proof into the existing hermetic test path or an existing proof
  workflow without creating avoidable advisory/env duplication.

**Out of scope:**
- Real Rulestead snapshot adapter.
- Real Rindle upload/storage adapter.
- Full Sigra handoff, step-up ceremony, OAuth/PKCE, passkey, or refresh-token
  machinery.
- Chimeway first-party notification delivery.
- Threadline provenance/audit capstone.
- Separate-package extraction or `mix crosswake.gen.companion`.

</domain>

<decisions>
## Implementation Decisions

### 1. Guide Structure And Narrative - LOCKED
- **D-01:** Keep one canonical `guides/companions.md` for Phase 47. Do not
  split into per-companion guide files yet. A single guide is the least
  surprising shape for milestone closure, keeps ExDoc navigation simple, and
  gives docs-contract tests one authoritative product surface to lock.
- **D-02:** Restructure the one guide by reader intent, using a Diataxis-like
  shape inside the file: quick orientation, concepts, how-to/examples,
  reference/truth tables, proof posture, and non-goals. This keeps the file
  useful for both first-hour adopters and maintainers without creating a docs
  tree before the companion surface justifies it.
- **D-03:** The guide should lead with the companion contract before individual
  companions: `Crosswake.Companion`, six callbacks, in-tree location,
  host config registration, optional dependency validation, telemetry span,
  and fail-closed semantics.
- **D-04:** The Rulestead section should remain the route-gating exemplar:
  `gated_by`, `on_unavailable`, `:gate_denied`, `:kill_switch_active`,
  `MockFlagSource`, gate-state truth, and the advisory promotion path.
- **D-05:** Add a Rindle section as the non-gating media exemplar. It should
  document `UploadGrant`, `CaptureEvidence`, `MediaObject`, backend-owned
  verification, `:queued | :uploaded | :scanning | :available | :rejected`,
  mock upload/verify flow, and the rule that device evidence cannot promote
  availability.
- **D-06:** Add a Sigra section as the contract-only auth exemplar. It should
  document `AuthContext`, `SessionAuthorityLane`, `StepUpChallenge`,
  `auth_min_level`, `requires_recent_auth`, and `:step_up_required`, while
  saying plainly that v3.5 ships route predicates and fail-closed denial only.
- **D-07:** The guide should avoid marketing language and avoid implying a
  generic plugin bus. Companions are first-party, typed, semantic, route-local
  or contract-local seams that can only further restrict or clarify authority.

### 2. Docs-Contract Parity - LOCKED
- **D-08:** Upgrade `test/crosswake/guides/companions_test.exs` beyond current
  string-anchor coverage. Keep explicit anchor assertions for readable failures,
  but add live-code set parity checks against canonical sources.
- **D-09:** Required guide anchors include:
  `Crosswake.Companion`, `companion_id`, `enabled?`, `route_gated?`,
  `kill_switch_active?`, `validate_dependency`, `report_state`,
  `lib/crosswake/companions/<name>/`, `[:crosswake, :companion, :validate_dependency]`,
  `gated_by`, `on_unavailable`, `:gate_denied`, `:kill_switch_active`,
  `UploadGrant`, `CaptureEvidence`, `MediaObject`, `AuthContext`,
  `SessionAuthorityLane`, `auth_min_level`, `requires_recent_auth`,
  `:step_up_required`, `companion.dependency_missing`,
  `auth.step_up_required_contract`, `Crosswake.SupportMatrix.gating_truth/0`,
  and `Crosswake.SupportMatrix.auth_contract_truth/0`.
- **D-10:** Live-code guards should assert exported functions/modules exist for
  the documented surface: `Crosswake.Companion`, `Crosswake.Companion.State`,
  `Crosswake.Companions.Rulestead`, `Crosswake.Companions.Rindle`,
  `Crosswake.Companions.Sigra.Contracts`,
  `Crosswake.Companions.Rulestead.MockFlagSource.set_flag/2`,
  `Crosswake.SupportMatrix.gating_truth/0`, and
  `Crosswake.SupportMatrix.auth_contract_truth/0`.
- **D-11:** Add set-style parity where practical rather than only checking
  keyword presence. Recommended checks:
  - documented companion IDs include `:rulestead` and `:rindle`;
  - guide includes route predicates from `SupportMatrix.auth_contract_truth/0`;
  - guide includes auth denial vocabulary from `auth_contract_truth/0`;
  - guide includes gate denial reasons from `Crosswake.Shell.Denial.reasons/0`
    or the closest exported denial vocabulary source;
  - guide includes doctor codes emitted by the companion dependency and auth
    posture findings.
- **D-12:** Avoid snapshot-only docs tests. Snapshot diffs are useful in some
  ecosystems, but they invite "accept the snapshot" drift and are weaker than
  targeted semantic parity for this product-contract surface.
- **D-13:** Tests should stay idiomatic ExUnit: no new test dependency, no
  brittle Markdown parser unless needed, clear assertion messages, `setup_all`
  with `File.read!`, and small helper functions inside the test module if they
  make parity assertions readable.

### 3. Milestone Hermetic Proof - LOCKED
- **D-14:** Do not satisfy Phase 47 by relying only on existing Phase 43 and
  Phase 45 lanes. The roadmap explicitly asks for milestone-level hermetic
  proof; the aggregate claim must be asserted somewhere.
- **D-15:** Prefer one aggregate ExUnit proof module over a brand-new duplicated
  CI island. Recommended file: `test/crosswake/proof/phase47_companion_arc_test.exs`.
  It should be untagged so existing hermetic lanes running
  `mix test --exclude requires_example_host --exclude advisory_only` pick it up.
- **D-16:** The aggregate proof should register the shipped companion modules
  together where appropriate and assert enabled-but-missing optional dependency
  paths emit `companion.dependency_missing` `:error` findings for Rulestead and
  Rindle without crashing or silently passing.
- **D-17:** The Sigra proof in Phase 47 should be contract/auth-predicate
  oriented, not optional-dependency oriented. Sigra is contract-only in v3.5, so
  the aggregate proof should assert `auth_contract_truth/0`, route predicate
  anchors, and `:step_up_required` posture rather than inventing a missing
  optional dependency check for Sigra.
- **D-18:** If CI wiring is needed, minimally extend an existing hermetic proof
  workflow or shared hermetic test command. Avoid a new `phase47-proof.yml`
  unless branch-protection/release governance requires a single named milestone
  check.
- **D-19:** Keep advisory lanes advisory. Rulestead and Rindle dependency-present
  checks stay scheduled/manual with `continue-on-error: true` and step-scoped
  `MIX_INCLUDE_RULESTEAD=1` / `MIX_INCLUDE_RINDLE=1`. Do not promote them until
  real adapters, substantive optional-library behavior, sustained stability, and
  explicit roadmap/requirements changes exist.
- **D-20:** The aggregate hermetic proof must defend against the known optional
  dependency footguns from Phases 43 and 45: env var bleed into hermetic jobs,
  conflicting dependency-present vs dependency-absent assertions in the same
  test target, and accidentally including `@moduletag :advisory_only` tests in
  merge-blocking lanes.

### 4. Ecosystem Lessons To Preserve - LOCKED
- **D-21:** Import the Phoenix/Plug lesson: public contracts should be explicit
  behaviours, plugs/callbacks, and route-local declarations with boring names.
  Do not hide companion behavior behind magic macros.
- **D-22:** Import the Ecto/Phoenix docs lesson: docs should teach the mental
  model first, then show concrete examples, then document boundaries. Crosswake
  should document where host ownership begins and where library-owned contracts
  stop.
- **D-23:** Import Rails Active Storage/Shrine lessons for Rindle: upload
  evidence and backend availability are different states; direct upload success
  must not be documented as committed media.
- **D-24:** Import phx.gen.auth/OAuth/OWASP lessons for Sigra: server-side auth
  authority, recency, and step-up vocabulary matter; the docs must not imply
  Crosswake performs full re-auth machinery in v3.5.
- **D-25:** Import Rust doctest/Python doctest lessons at the principle level:
  executable documentation should test claims against code. Do this with
  targeted ExUnit parity checks, not heavy docs infrastructure.
- **D-26:** Import Jest snapshot footgun lessons: avoid tests whose normal
  workflow is approving broad text diffs without understanding the semantic
  contract change.

### the agent's Discretion
- Exact guide headings are planner discretion if the single-file,
  reader-intent structure remains.
- Exact helper names inside `companions_test.exs` are planner discretion.
- Exact aggregate proof file name and workflow hook are planner discretion.
  Bias toward the untagged proof-test approach unless CI visibility demands a
  separate workflow.
- Exact assertion source for denial vocabulary is planner discretion if the
  test still locks `:gate_denied`, `:kill_switch_active`, and
  `:step_up_required` to live code.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` section "Phase 47: Companion Arc Guide And Milestone Proof" — authoritative goal and success criteria.
- `.planning/REQUIREMENTS.md` section "PROOF - Proof Lanes & Docs Contract" — PROOF-02.
- `.planning/PROJECT.md` — Crosswake thesis, v3.5 scope, companion guardrails, and deferred sequence.
- `.planning/MILESTONE-ARC.md` — strategic v3.5 companion arc source of truth.
- `.planning/research/v3.5-companions-SUMMARY.md` — milestone research synthesis if present.

### Prior phase decisions
- `.planning/phases/43-rulestead-hermetic-advisory-proof-and-guide/43-CONTEXT.md` — Rulestead guide/proof posture, advisory promotion path, docs-contract precedent.
- `.planning/phases/44-rindle-media-seam-contracts-and-reconciliation-vocabulary/44-CONTEXT.md` — Rindle media state, reconciliation, evidence-vs-authority decisions.
- `.planning/phases/45-rindle-in-tree-companion-mock-example-and-proof/45-CONTEXT.md` — Rindle companion implementation, mock lane, and proof posture.
- `.planning/phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` — Sigra contract-only route predicate and docs-contract handoff.

### Existing docs and tests
- `guides/companions.md` — current Rulestead-only guide to expand.
- `guides/commerce.md` — mature guide style and docs-contract parity precedent.
- `guides/support_matrix.md` — support truth language and package/companion classification.
- `guides/compatibility.md` — companion compatibility contract and release-boundary language.
- `test/crosswake/guides/companions_test.exs` — current docs-contract test to strengthen.
- `test/crosswake/guides/commerce_test.exs` — mature docs-contract test pattern if present.

### Companion, doctor, support, and denial code
- `lib/crosswake/companion.ex` — behaviour contract and callback docs.
- `lib/crosswake/companion/state.ex` — companion state struct.
- `lib/crosswake/companions/rulestead.ex` — concrete gating companion.
- `lib/crosswake/companions/rulestead/mock_flag_source.ex` — dev/test mock source.
- `lib/crosswake/companions/rindle.ex` — concrete media companion.
- `lib/crosswake/companions/rindle/contracts.ex` — media contract structs/vocabularies.
- `lib/crosswake/companions/rindle/reconciliation.ex` — media reconciliation and authority fence.
- `lib/crosswake/companions/sigra/contracts.ex` — auth contract structs/vocabularies.
- `lib/crosswake/doctor/doctor.ex` — dependency, gating, and auth finding codes.
- `lib/crosswake/support_matrix/support_matrix.ex` — `gating_truth/0` and `auth_contract_truth/0`.
- `lib/crosswake/shell/denial.ex` — denial vocabulary including gate, kill-switch, and step-up reasons.

### Proof and CI precedent
- `.github/workflows/phase43-proof.yml` — Rulestead hermetic/advisory split and promotion path.
- `.github/workflows/phase45-proof.yml` — Rindle hermetic/advisory split and promotion path.
- `test/crosswake/proof/phase42_rulestead_companion_test.exs` — Rulestead fail-closed proof.
- `test/crosswake/proof/phase45_rindle_companion_test.exs` — Rindle fail-closed proof.
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` — Sigra auth contract proof.
- `mix.exs` — optional dependency env handling for Rulestead/Rindle.

### Prompt corpus
- `prompts/crosswake-brand-book.md` — brand language and "no hidden boundary" posture.
- `prompts/crosswake-elixir-oss-dna.md` — maintainer house style: install truth, docs-contracts, proof lanes, optional-dep honesty.
- `prompts/crosswake-integrations-and-companions.md` — companion classifications and sequencing.
- `prompts/crosswake-research-synthesis.md` — route ownership and bounded bridge thesis.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — capability ladder and runtime ownership lessons.
- `prompts/elixir-mobile-offlinesupport-stresstest-deep-research.md` — offline honesty and local-first caveats.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — Hotwire Native lessons, bridge/capability plane, and proof posture.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/companions.md` already has a usable Rulestead section but needs the
  cross-companion overview, Rindle section, Sigra section, non-goals, and a more
  precise fail-closed framing.
- `test/crosswake/guides/companions_test.exs` already follows the basic
  `File.read!`/`setup_all` docs-contract pattern and can be extended in place.
- `Crosswake.SupportMatrix.gating_truth/0` and `auth_contract_truth/0` provide
  canonical support truth for docs parity.
- `Crosswake.Doctor` already emits companion dependency findings and auth
  posture findings that the guide should name exactly.
- Existing Phase 42/45/46 proof tests cover individual companion surfaces and
  should be composed rather than duplicated wholesale.

### Established Patterns
- Optional dependencies are absent from hermetic lanes and included only through
  step-scoped advisory env vars.
- Advisory tests are separated with `@moduletag :advisory_only` and run only in
  targeted dependency-present lanes.
- Companion proof tests use `async: false` because they mutate global
  `Application` env.
- Docs-contract tests intentionally use ExUnit and live code reflection instead
  of external docs tooling.
- Public support claims must be mechanically backed by doctor/support-matrix
  truth, not free-form prose.

### Integration Points
- Guide expansion connects to `mix.exs` ExDoc extras because
  `guides/companions.md` is already listed.
- Docs-contract parity connects to `test/crosswake/guides/companions_test.exs`.
- Milestone aggregate proof connects to `test/crosswake/proof/` and the existing
  hermetic proof command.
- CI changes, if any, connect to `.github/workflows/phase43-proof.yml` and/or
  `.github/workflows/phase45-proof.yml`, not a new workflow by default.

</code_context>

<specifics>
## Specific Ideas

- The user explicitly requested all three gray areas be considered with
  subagent-backed research, pros/cons/tradeoffs, ecosystem lessons, DX, least
  surprise, and prompt-corpus context.
- Advisor synthesis converged on one coherent direction:
  1. one reader-intent structured `guides/companions.md`;
  2. live-code semantic parity over snapshot-only docs tests;
  3. one aggregate hermetic ExUnit proof folded into existing proof posture.
- The guide should be a maintainer/adopter operating manual, not a marketing
  page and not a future-companion placeholder list.

</specifics>

<deferred>
## Deferred Ideas

- Per-companion guide split — defer until companion surface area is large enough
  to justify multiple ExDoc pages.
- Real Rulestead snapshot adapter — future phase after optional-library behavior
  is stable enough to promote advisory proof.
- Real Rindle adapter/transport/storage provider integration — future phase.
- Full Sigra machinery — v3.6+ security-focused work.
- Chimeway seam and Threadline capstone — future companion sequence, not Phase
  47 implementation.

</deferred>

---

*Phase: 47-companion-arc-guide-and-milestone-proof*
*Context gathered: 2026-05-31*
