# Phase 168: 0.2.1 Release Candidate Readiness - Context

**Gathered:** 2026-09-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Prepare one exact, approval-gated Crosswake 0.2.1 release candidate after every reversible
package-family, clean-room, coordinate, documentation, release-status, and cross-repository iOS
authority check has passed. The phase may land the five exact Phase 167 closeout blobs, repair the
bounded live-PR evidence query that Phase 168 consumes, build and inspect distributable packages,
prove them in generated Phoenix hosts, bind a refreshed linked Release Please PR to immutable
evidence, rehearse the iOS mirror write path without changing refs, and present one explicit
maintainer approval for the linked Hex/iOS/Android release unit.

The phase does not publish implicitly, combine independently versioned companion releases into the
0.2.1 authorization, resume the parked First B2C Adopter workstream, add Android capability, create
a generic release platform, move or replace immutable tags, or treat cached/path-based source proof
as equivalent to public package resolution.

</domain>

<decisions>
## Implementation Decisions

### Phase entry and candidate identity
- **D-01:** Phase 168's first reversible landing binds exactly the five paths handed off by Phase
  167 to their `100644` blob IDs, lands them through the protected default branch, and records a
  machine-checkable receipt. Phase 167 supplied path and owner authority but did not claim that the
  blobs had landed.
- **D-02:** Repair the Phase 167 live deferral-marker query's `comments(last:100)` pagination or
  truncation ambiguity before Phase 168 consumes that query as exact release authority. A
  potentially truncated result is `BLOCKED`, never authoritative absence.
- **D-03:** The current release PR #57 head is not a candidate. After the Phase 167 landing, allow
  Release Please to refresh #57 from current protected default and capture the future exact head
  commit, tree, base commit, linked version tuple, workflow/configuration digests, artifact digests,
  proof receipt, and CI run as the candidate identity.
- **D-04:** Any candidate head, tree, base/default commit, linked coordinate, package payload,
  workflow/configuration input, mirror plan, or required proof change makes the receipt `STALE` and
  requires a complete recapture. Mutable PR number, branch name, or successful historical run is
  not sufficient identity.
- **D-05:** Merge the approved Release Please candidate with merge-commit strategy and exact-head
  matching. Before any publication job proceeds, prove the resulting merge commit contains the
  approved head as a parent and has the identical Git tree; this binds the tested PR head to the
  merge commit that Release Please tags.
- **D-06:** Do not introduce a release branch, annotated RC tag, or second candidate authority.
  External prerelease consumption is not a Phase 168 job.

### Candidate package and clean-room proof
- **D-07:** Use a two-stage clean-room contract: deterministic candidate-local distributable proof
  before approval, followed by exact public-registry resolution and payload comparison after
  publication. Published-current packages may calibrate the harness once but cannot establish
  0.2.1 candidate readiness.
- **D-08:** Before approval, run Hex package audit/dry-run for core and all five companions, unpack
  the exact tarballs, record normalized payload and metadata digests, and consume those unpacked
  payloads from a generated host. Do not use repository source paths as the payload under test.
- **D-09:** Mix has no direct tarball dependency SCM, so the generated host may use isolated path
  dependencies pointing only at the unpacked candidate payloads. Counter the path-dependency blind
  spot by separately asserting every packaged file, package version, dependency requirement,
  compatibility floor, and candidate-core `Version.match?/2` result from the built metadata.
- **D-10:** Do not build an ephemeral signed Hex repository for Phase 168. Its signing, HTTP server,
  repository configuration, cleanup, and transitive custom-repository closure would add more false
  harness failures than confidence. Exact public Hex resolution remains the post-publication proof.
- **D-11:** Generate a real minimal Phoenix application with a pinned `phx_new`; use
  invocation-unique temporary roots and isolated `MIX_HOME`, `HEX_HOME`, dependency, build, and
  lockfile state; run installation twice; compile with warnings as errors; load runtime
  configuration; and exercise router/config output, public seams, smoke tests, registration, and
  `mix crosswake.doctor`.
- **D-12:** The closed core-release matrix covers all supported companions: Rulestead and Rindle
  with their required engines and non-vacuous dependency validation; Sigra with a non-vacuous auth
  result; Chimeway with Sigra absent plus its telemetry canary; and Threadline as an unregistered
  observer with sibling companions absent and its required Plug/Telemetry/Ledger/templates surface.
  Each lane includes a negative registration or profile control so success cannot be vacuous.
- **D-13:** Ordinary PR CI keeps fast hermetic scanner/harness fixtures and existing package tests.
  The complete candidate-local matrix runs for release-sensitive or Release Please candidate
  changes and produces one exact-head receipt; it is not a new always-on workflow family.
- **D-14:** After publication, fetch by exact public package/version, reject path fallbacks, assert
  lockfile package and core selections, compare public payload digests to the approved candidate,
  rerun all companion lanes for a core release, and finish with fail-closed live release status.

### Release train and approval boundary
- **D-15:** The single Phase 168 irreversible approval covers only the linked Crosswake 0.2.1
  release unit: Hex core, iOS core, and Android core at `0.2.1`. Linked lockstep versioning is real
  release authority; cross-registry publication is not represented as transactional.
- **D-16:** PRs #115, #146, and #147 remain independently versioned companion release proposals.
  They are excluded from the 0.2.1 candidate and approval. Keep them open and refreshable while the
  core rollup completes, then evaluate them serially with fresh exact-head evidence and a distinct
  future approval per companion release.
- **D-17:** Do not create a controller that merges several Release Please PRs under one captured
  approval. Each merge advances protected default and may refresh or invalidate later PR heads;
  hiding those changes beneath one authorization would create a time-of-check/time-of-use gap.
- **D-18:** The fixed postapproval release graph is approved-head merge/tree guard, linked Release
  Please tags, registry/mirror publications, exact public artifact proofs, and a fail-closed linked
  rollup. A failed child stops dependent work without denying already-public coordinates.
- **D-19:** If only part of the linked release becomes public, report `PARTIAL`, retain the exact
  successful coordinates and failed step, and recover only from exact refs. Routine recovery is a
  forward fix/new version; never move a public tag or silently replace a package. — **Reversibility:
  one-way** — public package versions and semantic Git tags are externally consumed immutable
  contracts, so undo requires an explicit registry-supported exceptional action or a new release.
- **D-20:** Merging the refreshed, fully bound #57 head is the one explicit approval. Do not add a
  second GitHub-environment reviewer gate unless an external organizational policy later requires
  it; doing so would obscure the maintainer job and can force approval before credential rehearsal.

### iOS mirror authority and idempotency
- **D-21:** Treat the live 0.2.0 mirror baseline honestly: mirror `main` and `v0.2.0` already equal
  the expected computed split. The baseline check is credential-free and idempotent; an exact tag
  is `PASS`, a mismatching tag is an immutable conflict, and an unreachable or ambiguous remote is
  `BLOCKED`, never reported as absent.
- **D-22:** Add candidate mode that accepts an exact 40-character commit and version, computes the
  iOS subtree split before `ios-core-v0.2.1` exists, and performs a credentialed
  `git push --dry-run --porcelain` against the real mirror. `READY FOR APPROVAL` requires this
  trusted-workflow authority rehearsal; local runs without credentials say
  `WRITE AUTHORITY NOT CHECKED` rather than passing.
- **D-23:** Load the single-repository mirror deploy key only for the credentialed rehearsal and
  publication steps. The current deploy key is proportionate for one mirror; a GitHub App is
  deferred until rotation, expiry, or finer-grained multi-repository policy is a demonstrated need.
- **D-24:** Normal mirror publication fetches current mirror refs, requires mirror `main` to be an
  ancestor of the candidate split, creates immutable `v0.2.1`, and updates `main` only by ordinary
  fast-forward. Push `main` and tag atomically where supported; forbid force, movement, and deletion
  in normal release logic.
- **D-25:** Keep explicit `--force-with-lease=<ref>:<expected>` main replacement in a separately
  invoked, explicitly approved recovery path only. It is safer than blind force but still permits
  history replacement and is not normal release idempotency.

### Maintainer interface, evidence, and design quality
- **D-26:** Provide one fixed-purpose Mix entry point,
  `mix crosswake.release.candidate --version 0.2.1 --ref <40sha> --output-dir <dir>`. Keep the Mix
  task thin, put deterministic evaluation and serialization in ordinary Elixir modules, and retain
  narrow shell adapters for Git, Hex, Swift, and Gradle. `mix crosswake.release.status` remains a
  read-only status projection. — **Reversibility: costly** — once documented and used in CI/runbooks,
  renaming or changing the command/schema requires coordinated workflow, evidence, and operator
  migration.
- **D-27:** Ecto and application database processes do not belong in release orchestration. Phoenix
  is present only where consumer truth requires a generated host; the orchestration itself remains
  a package/repository concern.
- **D-28:** Emit deterministic schema-versioned JSON as authority plus concise Markdown/GitHub
  Summary and terminal projections. Bind candidate commit/tree, base, linked coordinates, package
  digests, toolchains, workflow/config digests, proof IDs/results, mirror split/ref plan, credential
  rehearsal result, run ID, approval boundary, and one exact next/recovery action.
- **D-29:** Lead with one textual state: `READY FOR APPROVAL`, `BLOCKED`, `STALE`, `PARTIAL`, or
  `COMPLETE`. Status never depends on color; support `NO_COLOR`; show whether credentials were
  exercised and whether any external state changed; name what happened and one correction.
- **D-30:** Evidence is allowlisted, low-cardinality, portable JSON/Markdown, and digest-bound. It
  omits secrets, actors, private URLs, raw package or mutation payloads, adopter details, tokens,
  credentials, account/device identifiers, and volatile logs. Call it a candidate receipt or
  provenance record, not SLSA compliance unless signed attestations and the claimed level are
  actually implemented.
- **D-31:** The relevant design pillars are clarity, least surprise, accessibility, privacy and
  least privilege, correctness/fail-closed behavior, reproducibility, auditability, recoverability,
  bounded performance, portability, consistency, and maintainability. There is no app-screen or
  visual design scope; UI work is limited to humane terminal and GitHub evidence presentation.

### the agent's Discretion
- Exact internal module names and file placement beneath the stable
  `mix crosswake.release.candidate` contract.
- Exact JSON field ordering, schema file location, evidence filenames, and concise Markdown layout,
  provided the identities, states, privacy boundary, and deterministic projections above remain
  exact.
- Exact candidate-local matrix parallelism and cache use, provided every lane remains isolated,
  payload-bound, deterministic, and independently actionable.
- Exact postapproval child ordering where registries are independent, provided mirror authority is
  proven before approval, no atomicity is implied, and partial state is preserved honestly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project, workstream, privacy, and release authority
- `AGENTS.md` — priority order, workstream routing, Android freeze, privacy rules, proof policy, and
  zero-human verification default.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing infrastructure decision, stop list, privacy
  boundary, non-goals, and reversal conditions.
- `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — first-adopter strategy, ownership boundaries,
  proof/media analysis, and dated sequence.
- `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — route owners and physical-iPhone exit test.
- `.planning/PROJECT.md` — Phoenix-first thesis, active/parked lane split, current release posture,
  constraints, and accumulated decisions.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — REL-01 through REL-05 and
  traceability.
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 168 goal, dependencies, and
  success criteria.
- `.planning/workstreams/quality-ratchet-release/STATE.md` — active position, open release-PR
  ownership, Phase 167 handoff, and current next action.
- `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked v21 external gate and exact
  non-resumption posture.

### Carried quality and handoff decisions
- `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-CONTEXT.md`
  — single umbrella authority, release workflow isolation, source-bound evidence, and bounded CI.
- `.planning/workstreams/quality-ratchet-release/phases/166-clean-checkout-engineering-quality/166-CONTEXT.md`
  — clean-checkout verification facade, generated artifact policy, hermetic proof, and failure UX.
- `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-CONTEXT.md`
  — Release Please PR dispositions, documentation authority, companion-floor reconciliation, and
  Phase 168 publication boundary.
- `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-08-SUMMARY.md`
  — exact five-path reversible landing handoff and owner.
- `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-VERIFICATION.md`
  — final Phase 167 proof, remaining advisories, and non-claims.
- `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json`
  — machine-readable closeout and deferred-release ownership.

### Package, release, and operator surfaces
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — current package-family publish, mirror backfill, approval,
  post-publication proof, and recovery contract.
- `.release-please-manifest.json` — current component versions.
- `release-please-config.json` — linked core/native components, independent companions, paths, and
  remaining bootstrap `release-as` configuration.
- `mix.exs` — root Hex package version, dependency floors, package files, and docs configuration.
- `lib/crosswake/release_status.ex` — current deterministic and live release readiness checks.
- `lib/mix/tasks/crosswake.release.status.ex` — established user-facing read-only status command.
- `script/verify_companion_cleanroom.sh` — existing generated-Phoenix-host companion profiles,
  registration, compile, smoke, and doctor proof.
- `script/verify_hex_publish_dry_run.sh` — current Hex package dry-run surface.
- `script/verify_ios_mirror_backfill.sh` — current release-tag-bound mirror verification/backfill
  behavior and recovery-era main update.
- `script/check_ios_mirror_parity.sh` — existing iOS source/mirror parity proof.
- `script/check_release_as_staleness.sh` — remaining bootstrap-pin drift guard.
- `script/check_release_workflow_integrity.exs` — release workflow contract checks.
- `script/guarded_hex_publish.sh` — exact-ref Hex publication guard.
- `script/verify_repository.sh` — complete clean-checkout repository verification facade.
- `.github/workflows/release-please.yml` — release proposal, linked tag, native publish, rollup, and
  recovery topology.
- `.github/workflows/hex-publish.yml` — Hex publish and exact-ref recovery surface.
- `.github/workflows/ios-mirror-backfill.yml` — current mirror credential and backfill workflow.
- `.github/workflows/crosswake-ci.yml` — recurring `Crosswake CI` authority and release-sensitive
  proof integration point.

### Current research, DX, and voice inputs
- `brandbook/BRAND-SPEC.md` — current authoritative voice, terminal microcopy, accessibility,
  release-note, API naming, and visual/system-mode guidance; supersedes prompt-era brand material.
- `prompts/crosswake-research-synthesis.md` — public-contract honesty, proof-lane, packaging, and
  release/recovery principles.
- `prompts/crosswake-elixir-oss-dna.md` — idiomatic Mix/Hex/ExDoc packaging, install truth, doctor,
  and maintainer DX patterns.
- `prompts/crosswake-gsd-project-brief.md` — explicit route-policy and release vision.
- `prompts/crosswake-integrations-and-companions.md` — companion boundaries and package-family
  expectations.
- `prompts/elixir-mobile-oss-lib-deep-research.md` — cross-ecosystem CI, packaging, release,
  compatibility, security, and proof lessons; current ADR and decisions override legacy breadth.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` — generated-host testing, doctor,
  deterministic evidence, and developer ergonomics patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Crosswake.ReleaseStatus` already owns manifest/config/workflow consistency, lockstep versions,
  clean-room integrity, governance, live registry probes, iOS mirror tag state, and stale
  `release-as` detection; extend or compose it rather than duplicating status policy.
- `Mix.Tasks.Crosswake.Release.Status` already establishes the thin-Mix-task/read-only projection
  pattern for a new candidate command.
- `script/verify_companion_cleanroom.sh` already generates a throwaway Phoenix host and encodes the
  five companion profiles; evolve its package source and assertions instead of replacing its user
  journey.
- `script/verify_ios_mirror_backfill.sh` already computes subtree splits, verifies exact tags,
  rehearses pushes, and refuses tag movement; separate baseline, candidate, normal publish, and
  recovery responsibilities from this foundation.
- Phase 166's repository facade, evidence environment, artifact policy, and CI leaf manifest already
  provide deterministic execution, ownership, bounded logs, cleanup, and stable remediation.

### Established Patterns
- User-facing repository commands are purpose-named Mix tasks or stable scripts backed by ordinary
  testable modules; mutation and status surfaces remain separate.
- Release Please PR merges are explicit approval boundaries. Core Hex/iOS/Android components are a
  linked lockstep group; companions have independent versions and releases.
- Post-merge publish and public clean-room jobs are not PR-required checks, but their rollups remain
  explicit and fail closed.
- Generated-host proof is the install truth. It preserves browser fixtures while avoiding claims
  based only on repository-local paths.
- Exact refs and immutable coordinates control recovery; retries are bounded and never reinterpret
  an externally visible conflict as success.
- CLI and evidence output is calm, textual, non-secret, answer-first, and paired with one exact
  correction.

### Integration Points
- Add candidate evaluation beside `Crosswake.ReleaseStatus`, with a thin Mix task and a
  schema-versioned receipt renderer.
- Extend the existing clean-room and Hex dry-run scripts to consume built/unpacked payloads and to
  compare them with exact public artifacts after publication.
- Add pre-tag candidate input to the existing mirror split/push foundation; keep public baseline
  checks credential-free and normal publication separate from recovery.
- Register recurring structural checks in the existing `Crosswake CI` release-sensitive owners;
  do not add another required umbrella or broad workflow family.
- Bind the final candidate receipt to the refreshed Release Please #57 head and make the workflow
  reject stale head/base/tree/config/artifact identities before merge or publication.

</code_context>

<specifics>
## Specific Ideas

- Preferred first line:
  `Crosswake 0.2.1 release candidate — READY FOR APPROVAL. Reversible checks PASS 12/12. Mirror write authority PASS; dry-run only; no refs or packages changed. Next: review the dossier, then approve release PR head <sha>.`
- Operator job: given this exact 0.2.1 candidate, prove every reversible release action and show one
  safe approval or one exact recovery.
- Domain nouns: Candidate, Coordinate Set, Package Payload, Proof Step, Mirror Ref Plan, Authority
  Probe, Candidate Receipt, Approval, and Partial Release.
- Domain verbs/events: bind, inspect, build, compare, rehearse, approve, publish, verify, recover;
  `candidate_bound`, `check_blocked`, `candidate_stale`, `write_authority_proven`,
  `approval_requested`, `publication_partial`, and `publication_completed`.
- Ecosystem lesson adopted: Hex, Cargo, npm, and Gradle all provide package-first inspection or
  local-consumer workflows. Crosswake should test the distributable before public upload and retain
  a separate exact-registry check rather than confusing source-tree success with installation truth.
- Ecosystem footguns rejected: path-only proof, silent registry fallbacks, a custom local registry
  with an incomplete transitive closure, multiple preapproved Release Please merges, mutable RC
  tags, normal-path force pushes, blind retries, double human approval, and unsupported SLSA claims.

</specifics>

<deferred>
## Deferred Ideas

- Companion PRs #115, #146, and #147: independently reassess and release serially after the linked
  0.2.1 rollup; they are not folded into Phase 168's one core approval.
- GitHub App migration for the one iOS mirror: revisit only when credential expiry, rotation,
  finer-grained policy, or multi-repository scope creates a demonstrated need.
- Signed artifact attestations or a claimed SLSA level: future supply-chain work if consumer need
  justifies the policy, signing, and verification surface.
- New release dashboard/UI, generic release orchestrator, staging package registry, public status
  taxonomy, Android breadth, and first-adopter activation remain outside Phase 168.

</deferred>

---

*Phase: 168-0.2.1-release-candidate-readiness*
*Context gathered: 2026-09-12*
