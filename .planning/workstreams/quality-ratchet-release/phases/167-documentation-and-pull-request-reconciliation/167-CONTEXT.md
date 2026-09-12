# Phase 167: Documentation and Pull-Request Reconciliation - Context

**Gathered:** 2026-09-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one current, code-backed account of Crosswake's supported behavior; preserve the parked
First B2C Adopter lane as a codename-only, independently resumable workstream; and give every live
pull request an explicit current disposition. The phase may reconcile canonical documentation
sources, generated projections, hand-maintained guides, contribution guidance, release runbooks,
and live PR state. It does not add product or mobile capability, resume adopter integration, widen
Android, publish packages or tags, or perform Phase 168's exact 0.2.1 candidate proof.

</domain>

<decisions>
## Implementation Decisions

### Documentation authority and reader experience
- **D-01:** Use a layered authority model: executable structured truth, deterministic generated
  projections, hand-maintained current narratives, immutable historical provenance, and
  non-authoritative research/voice inputs. Do not create a competing all-facts documentation
  manifest.
- **D-02:** Executable code/config owns volatile facts consumed by runtime, release, or verification
  behavior. This includes `mix.exs` version/ranges, `Crosswake.SupportMatrix`,
  `Crosswake.CapabilityMap`, protocol/runtime constants, CI policy manifests, and active workstream
  state. A support claim changes at its executable owner before its public projection changes.
- **D-03:** Generated guides and fixtures are checked-in projections, never independent truth.
  Generated outputs must identify their owner and regeneration command and must not be edited
  directly.
- **D-04:** README, architecture, installation, compatibility, troubleshooting, contribution, and
  release guidance remain authored around reader jobs rather than generated as templates. They
  repeat only the minimum volatile facts needed for orientation and link to generated truth for
  detail.
- **D-05:** Released changelog entries, completed phase records, and dated evidence remain
  historical provenance. Do not rewrite them merely to resemble current behavior; correct only
  privacy, safety, or explicit provenance defects.
- **D-06:** Add a compact documentation-authority map to `CONTRIBUTING.md` and clarify that the
  support matrix is the canonical public projection while its Elixir model is the executable
  source. Do not add another large governance guide.
- **D-07:** Preserve the current ExDoc guide groups and README-as-map structure. No new docs site,
  dashboard, custom documentation UI, or label taxonomy is authorized.
- **D-08:** Current `brandbook/BRAND-SPEC.md` governs voice, accessibility, and presentation and
  supersedes `prompts/crosswake-brand-book.md`. Prompt research informs judgment but never
  overrides current code, the governing ADR, or active workstream state.

### Generated documentation and drift correction
- **D-09:** Add one fixed-purpose maintainer command, `mix crosswake.docs.sync`. Its default mode
  regenerates the support/capability projections; `--check` performs a no-write byte comparison and
  names the source, target, and exact correction command. Keep this separate from
  `mix crosswake.contract.gen` because the owners and output families differ. — **Reversibility:
  costly** — once documented and wired into CI, changing the command requires coordinated
  contributor, artifact-policy, CI, and remediation migration.
- **D-10:** Register generated documentation in the existing repository artifact policy with its
  canonical source, regeneration argv, outputs, and remediation. Generalize Phase 166's generated
  artifact validation only as needed to validate every declared record; do not introduce a second
  artifact registry.
- **D-11:** Extend the existing `documentation-contracts` and package/ExDoc proof owners. Do not add
  another workflow or another required check context.
- **D-12:** Recurring CI owns deterministic generated parity, semantic support/adopter invariants,
  current package-version markers, ExDoc topology/references, stable public examples, Hex package
  surface, privacy/codename scanning, internal links/anchors, and Phase 165 docs-only routing.
- **D-13:** Generated checks are no-write in CI and never stage files. Network availability,
  generic prose linting, and broad authored-document snapshots are not merge authority.
- **D-14:** Replace brittle whole-sentence or phase-era assertions where they preserve obsolete
  wording with owner-focused semantic invariants. Retain exact-byte checks only for fully generated
  artifacts and exact closed vocabulary where wording itself is contractual.
- **D-15:** Keep full document inventory, external-link review, duplicate-claim counts, current PR
  enumeration, and representative light/dark/system ExDoc rendering as Phase 167 evidence or
  scheduled advisory maintenance, not permanent merge-blocking state.

### Adopter proof and activation truth
- **D-16:** Preserve the existing public support/proof vocabulary. Add the missing closed internal
  dimensions—`evidence_subject`, `source_binding`, and `activation_state`, or semantically exact
  equivalents—rather than creating another public status-label family.
- **D-17:** Render three separate claims:
  1. reusable Crosswake contracts and reference substrate are implemented and verified;
  2. retained source-bound physical reference evidence is a dated past-tense proof of one bounded
     reference-host flow on one recorded iOS runtime line and does not transfer to another host;
  3. real first-adopter activation remains blocked until sanitized route policy and a fresh
     source-bound signed-device run both pass.
- **D-18:** Fix the current contradiction atomically. The support matrix must not say a retained
  physical record currently supports a first-adopter flow while capability/current-state truth
  says adopter binding, evidence publication, and support promotion remain blocked. Update the
  executable source, generated projection, semantic tests, README/related narrative, and active
  parked state together wherever each is a current authority.
- **D-19:** Public first-read copy says `first adopter`, avoids internal TODO identifiers, and gives
  one direct recovery statement such as: “Blocked — sanitized route policy and signed-device proof
  are required before this host can be promoted.” Durable planning retains **First B2C Adopter**,
  `first_b2c_adopter`, TODO-002, and the exact resume gate.
- **D-20:** Reject impossible claim combinations mechanically: adopter-bound evidence attributed
  to a reference host, physical claims derived from simulator/fixture evidence, missing source
  binding, stale evidence silently aging forward, or support promotion while activation is
  blocked.
- **D-21:** Public and retained artifacts remain allowlisted, low-cardinality, and non-echoing. They
  never expose route payloads, raw answers, transcripts, credentials, account/device identifiers,
  tokens, private URLs, host flag names, proprietary taxonomy, or adopter identity.

### Live pull-request dispositions
- **D-22:** PR #121 (`actions/setup-java` v6) is to be rebased onto current authority, expanded so
  all seven live uses are coherent, pinned immutably where required, and accompanied by the
  matching version assertion. Rerun current `Crosswake CI`, then merge. If the Dependabot branch
  cannot accept the coherent completion, supersede it with one manual PR and explicitly close
  #121 as superseded.
- **D-23:** PR #110 (companion core constraints) is to be rebased, expanded to reconcile every
  affected package manifest, compatibility guide, package README, published-package statement, and
  drift fixture, then verified and merged before release PRs refresh. If that cannot remain
  reviewable, supersede it with the Phase 167 reconciliation PR while preserving the original
  rationale. Do not defer the known `~> 0.1` compatibility footgun.
- **D-24:** PR #105 (PackStore waiter closure clarity) is to be rebased/squashed to one intent
  commit, verified with the current Swift and umbrella contracts, then merged. Do not leave this
  narrow accepted cleanup indefinitely deferred.
- **D-25:** PR #115 (Chimeway 0.1.1 release) remains open and explicitly deferred to Phase 168.
  Merging it is an immutable release trigger; do not close/recreate the Release Please thread or
  publish before exact candidate proof and explicit approval.
- **D-26:** PR #57 (linked core/iOS/Android 0.2.1 release) remains open and explicitly deferred to
  Phase 168 while Release Please refreshes it. Do not merge, close/recreate, publish, or treat its
  current red/stale head as the candidate.
- **D-27:** Retain a one-time Phase 167 disposition record for every PR with number, observed
  head/base SHA, observed checks, disposition, current reason, and next gate. Put the current
  reason on every still-open deferred PR during execution, but do not create a permanent PR ledger,
  repository label taxonomy, or CI fixture containing live PR counts/titles.
- **D-28:** Actual GitHub comments, rebases, closures, supersession, and merges belong to planned
  Phase 167 execution. This discussion records authority but performs no remote mutation.

### Reader and operator quality bar
- **D-29:** Optimize current documentation for six explicit jobs: evaluator orientation,
  integrator setup/proof, route-owner selection, operator diagnosis/recovery, maintainer
  source/regeneration discovery, and release-review rebuild/publication decisions.
- **D-30:** Lead with the user-facing answer, then expose implementation/provenance detail. Status
  is always textual and never color-only; failure copy is calm, bounded, non-secret, and supplies
  one exact owner/action.
- **D-31:** Preserve ExDoc responsiveness/night mode, visible focus, text-labeled status,
  accessible Mermaid `accTitle`/`accDescr` and fallback content, reduced-motion behavior, and
  internal-link reliability. No visual polish program is authorized.
- **D-32:** Preserve Phase 165's efficient docs-only path: documentation changes receive a visible
  required result without scheduling unrelated browser, Android, Apple, or product proof.

### the agent's Discretion
- Exact module/file placement for `crosswake.docs.sync`, renderer helpers, and focused tests,
  provided there is one owner and the public command/remediation contract above remains stable.
- Exact internal atom names and rendering layout for evidence subject, source binding, and
  activation state, provided the three-layer semantics and impossible-combination guards are exact.
- Exact Phase 167 evidence filename and JSON/Markdown shape, provided it is phase-local,
  reproducible, privacy-safe, and does not become a second live authority.
- Exact rebase/squash mechanics and PR comment wording, provided the five dispositions and
  irreversible release boundary remain unchanged.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project, workstream, and privacy authority
- `AGENTS.md` — workstream routing, phase priority, Android freeze, privacy rules, and executable
  verification policy.
- `.planning/PROJECT.md` — Phoenix-first thesis, current v22 position, active/parked workstream
  split, and accumulated project decisions.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — DOC-01 through DOC-03 and the
  Phase 168 release boundary.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 167 goal, success criteria,
  dependencies, and exclusions.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — active Phase 167 position and carried
  Phase 164-166 decisions.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — infrastructure framing, stop list, privacy boundary,
  Android freeze, and proof policy.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — first-adopter strategy, proof/media boundary,
  stakeholder lenses, and stop conditions.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — exact adopter route/device promotion gate,
  non-claims, and sensitive-data exclusions.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked external gate and exact
  resume/non-inference posture.
- `.planning/workstreams/first-b2c-adopter-readiness/phases/162-physical-iphone-adoption-proof/162-VERIFICATION.md`
  — retained physical reference proof and its bounded claim.
- `.planning/workstreams/first-b2c-adopter-readiness/phases/163.1-close-gap-v21-physical-adopter-composition/163.1-CONTEXT.md`
  — adopter composition boundary and external-authority gap.

### Prior quality decisions
- `.planning/workstreams/quality-ratchet-release/phases/164-dependency-security-and-gate-authority/164-CONTEXT.md`
  — unique producers, closed results, and fail-closed proof ownership.
- `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md`
  — docs-only classification, single umbrella authority, evidence privacy, and concise remediation.
- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-CONTEXT.md`
  — complete repository facade, generated artifact policy, no-write drift checks, and current
  purpose-led failure UX.

### Documentation, architecture, DX, and voice inputs
- `brandbook/BRAND-SPEC.md` — current authoritative voice, accessibility, documentation IA, and
  microcopy; supersedes the older prompt-era brandbook.
- `prompts/crosswake-research-synthesis.md` — current architecture thesis and prompt precedence.
- `prompts/crosswake-elixir-oss-dna.md` — install truth, README-as-map, proof-lane, ExDoc, and
  release/DX lessons from the maintainer's Elixir ecosystem.
- `prompts/crosswake-gsd-project-brief.md` — explicit route-policy, CI/CD, docs, and release vision.
- `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — current maintainable architecture-guide and
  code-walkthrough method.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — cross-ecosystem documentation, ExDoc, release,
  compatibility, and footgun research; current decisions override legacy names/scope.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — developer ergonomics, doctor,
  contract-fixture, and troubleshooting patterns; current scope overrides broad product ideas.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` — explicit ownership,
  capability, compatibility, and app-archetype lessons; current ADR stop list governs scope.

### Current public and release surfaces
- `README.md` — evaluator entry point, current baseline, proof/support posture, and guide map.
- `CONTRIBUTING.md` — current contribution and upgrade-impact guidance.
- `mix.exs` — package version, dependencies, public package files, ExDoc extras/groups, and focused
  `mix verify` meaning.
- `CHANGELOG.md` — released history and current release-impact truth.
- `guides/architecture.md` — outside-in route/runtime mental model.
- `guides/code-walkthrough.md` — source-oriented architecture trail.
- `guides/install.md` — canonical adopter installation/proof entry.
- `guides/troubleshooting.md` — operator diagnosis and recovery.
- `guides/compatibility.md` — compatibility and rebuild decisions.
- `guides/support_matrix.md` — generated public support projection.
- `guides/capability_map.md` — generated public capability/adopter-pressure projection.
- `guides/physical_iphone_handoff.md` — physical proof prerequisites and operator handoff.
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — current package-family release and recovery operation.
- `.release-please-manifest.json` — current component versions.
- `release-please-config.json` — release component relationships and release-PR behavior.

### Executable documentation and CI seams
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical support truth.
- `lib/crosswake/support_matrix/renderer.ex` — support guide rendering.
- `lib/crosswake/capability_map.ex` — canonical capability and first-adopter pressure truth.
- `lib/crosswake/capability_map/renderer.ex` — capability guide rendering.
- `lib/crosswake/planning/first_adopter_context.ex` — repository privacy/codename scanning.
- `script/repository_artifact_policy.json` — Phase 166 artifact-source/regeneration authority.
- `script/ci_docs_allowlist.json` — planning/public-doc classification and release-input exclusion.
- `script/ci_leaf_manifest.json` — literal documentation/package proof owners and remediation.
- `.github/workflows/crosswake-ci.yml` — `documentation-contracts`, package/ExDoc proof, and
  `Crosswake CI` authority.
- `test/crosswake/support_matrix/support_matrix_test.exs` — canonical support invariants.
- `test/crosswake/support_matrix/renderer_test.exs` — generated support projection parity.
- `test/crosswake/capability_map/capability_map_test.exs` — canonical capability invariants.
- `test/crosswake/capability_map/renderer_test.exs` — generated capability projection parity.
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` — current adopter/documentation drift
  assertions to preserve semantically rather than archaeologically.
- `test/crosswake/guides/release_boundaries_test.exs` — upgrade-impact vocabulary and release
  boundary.
- `test/crosswake/guides/architecture_code_walkthrough_test.exs` — ExDoc architecture-guide
  topology and semantic contract.
- `test/crosswake/proof/phase69_docs_contract_parity_test.exs` — established public-doc parity
  proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.SupportMatrix` and `Crosswake.CapabilityMap` already provide typed canonical data plus
  deterministic renderers; extend these owners rather than introducing another truth store.
- `documentation-contracts` already runs the adoption-context privacy scan and focused guide/parity
  suite, while public-doc changes additionally schedule ExDoc/package proof.
- `script/repository_artifact_policy.json` already models canonical source, regeneration command,
  outputs, and drift remediation for generated contracts.
- `script/ci_docs_allowlist.json` already separates planning/public docs from release-sensitive
  runbooks and inputs.
- Existing guide, renderer, release-boundary, package, and privacy tests provide focused homes for
  semantic invariants.

### Established Patterns
- README is a map; ExDoc extras provide task-oriented learning paths; public module docs remain API
  contract.
- Generated structural truth is byte-compared, while authored guidance is protected by semantic
  assertions and executable examples.
- One fail-closed `Crosswake CI` umbrella owns recurring PR authority. Documentation-only work must
  stay visible and inexpensive.
- Operational output is calm, bounded, purpose-led, privacy-safe, and supplies one exact
  remediation.
- Release Please PR merges can trigger immutable publication; open release PRs are approval
  surfaces, not ordinary queue clutter.

### Integration Points
- Add documentation synchronization beside the existing support/capability renderers and register
  it with the repository artifact policy.
- Tighten current support/capability claims at their canonical Elixir owners, then regenerate
  projections and update the minimum hand-authored narrative.
- Extend existing documentation-contract and package/ExDoc leaves rather than modifying the
  umbrella topology.
- Reconcile #121, #110, and #105 against current main before Phase 168 refreshes #115/#57.
- Record live PR disposition as bounded Phase 167 evidence and leave future release readiness to
  Phase 168.

</code_context>

<specifics>
## Specific Ideas

- Preferred status progression:
  - “Available — reusable contracts verified.”
  - “Reference evidence — one dated physical-iPhone run; does not verify your host.”
  - “Blocked — sanitized route policy and signed-device proof required.”
- Preferred documentation failure shape names the canonical source, generated target, and one
  `mix crosswake.docs.sync` correction.
- Current focused evidence: `mix crosswake.adoption_context.scan` plus the guide/parity suite passed
  171 tests with zero failures on 2026-09-10, yet the support/capability adopter claim remains
  semantically contradictory. Phase 167 therefore needs typed cross-surface invariants, not merely
  more phrase snapshots.
- Preserve the release-input exclusion from the docs-only allowlist: a runbook that can change
  publishing behavior earns fuller release-sensitive proof.
- Ecosystem lessons: Elixir/ExDoc favors code-adjacent API docs plus authored extras; Terraform
  providers generate structural reference while authoring guidance; Flutter and Rust separate
  support from tested guarantees; SLSA treats evidence provenance as an explicit binding.

</specifics>

<deferred>
## Deferred Ideas

- Exact 0.2.1 candidate proof, package-family parity, iOS mirror authority/backfill, immutable tags,
  and registry publication: Phase 168.
- External-link availability may be checked once in Phase 167 or through scheduled advisory
  maintenance; it is not merge authority.
- New documentation UI, custom site, dashboard, public support taxonomy, Android feature/device
  work, adopter activation, and product/mobile breadth remain outside this phase.

</deferred>

---

*Phase: 167-Documentation and Pull-Request Reconciliation*
*Context gathered: 2026-09-10*
