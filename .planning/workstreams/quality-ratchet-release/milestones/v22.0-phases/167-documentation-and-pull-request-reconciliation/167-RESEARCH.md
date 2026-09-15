# Phase 167: Documentation and Pull-Request Reconciliation - Research

**Researched:** 2026-09-10
**Domain:** Executable documentation authority, generated-artifact drift, privacy-safe adopter status, and live pull-request reconciliation
**Confidence:** HIGH for repository architecture and constraints; MEDIUM for mutable GitHub observations

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Exact 0.2.1 candidate proof, package-family parity, iOS mirror authority/backfill, immutable tags,
  and registry publication: Phase 168.
- External-link availability may be checked once in Phase 167 or through scheduled advisory
  maintenance; it is not merge authority.
- New documentation UI, custom site, dashboard, public support taxonomy, Android feature/device
  work, adopter activation, and product/mobile breadth remain outside this phase.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | Public guides, support/capability truth, architecture notes, contribution guidance, and release runbooks agree with the verified code and current package versions. | Canonical-owner map, docs-sync design, package-floor inventory, ExDoc/CI test map, and atomic reconciliation sequence below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:73-74] |
| DOC-02 | The parked First B2C Adopter work remains codename-only, independently resumable, and visibly blocked only on its real external route/device authority. | Three-claim model, privacy boundary, mechanical invalid-state rules, and parked-state update sequence below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:76-77] |
| DOC-03 | Every open pull request is merged, rebased, superseded, closed, or explicitly deferred with a current reason; no stale PR is left ambiguous. | Read-only live PR snapshot and ordered, bounded disposition workflow below. [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:79-80] |
</phase_requirements>

## Summary

Plan this as a reconciliation transaction, not a documentation rewrite. The repository already has typed support/capability owners, deterministic renderers, a generated-artifact registry, a documentation-only CI route, ExDoc/package proof, and privacy scanning. [VERIFIED: `Crosswake.CapabilityMap` says it is the “Canonical capability-map truth” and exposes closed vocabularies in lib/crosswake/capability_map.ex:1-8,44-109; the artifact record is in script/repository_artifact_policy.json:104-122; the documentation job is in .github/workflows/crosswake-ci.yml:68-97] The gap is semantic: a renderer currently says a retained physical record “support[s] one first adopter offline-study flow,” while the canonical capability row says support “remains blocked” pending validated input and one signed iPhone. [VERIFIED: lib/crosswake/support_matrix/renderer.ex:329-347; lib/crosswake/capability_map.ex:425-437]

The safest plan has four ordered slices: (1) encode the three-layer evidence/activation model and reject impossible combinations; (2) regenerate both public projections through `mix crosswake.docs.sync --check` and reconcile only current narrative owners; (3) extend the existing artifact, documentation, ExDoc/package, privacy, and docs-only routing contracts; then (4) reconcile ordinary PRs #121, #110, and #105 before leaving release PRs #115 and #57 explicitly deferred to Phase 168. [VERIFIED: 167-CONTEXT.md D-09 through D-28] The live PR snapshot is an execution input that must be refreshed immediately before mutation; it must not become permanent repository authority. [VERIFIED: 167-CONTEXT.md D-15,D-27,D-28]

**Primary recommendation:** make one typed current-claim owner feed both generated projections; make `mix crosswake.docs.sync --check` the no-write drift boundary; keep authored docs semantic and task-oriented; and gate every remote action on a fresh SHA/check observation. [VERIFIED: 167-CONTEXT.md D-01 through D-15,D-27]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Support/capability claim modeling | API / Backend (Elixir library) | — | `Crosswake.SupportMatrix` and `Crosswake.CapabilityMap` are executable owners; generated Markdown is projection only. [VERIFIED: lib/crosswake/capability_map.ex:1-8; lib/crosswake/support_matrix/support_matrix.ex:403-483] |
| Generated guide synchronization | Build / Repository tooling | API / Backend | A Mix task renders canonical Elixir data and writes or byte-checks checked-in files. [VERIFIED: 167-CONTEXT.md D-09] |
| Public reader experience | Static / ExDoc | Build / Repository tooling | README and guides remain authored, while generated truth is checked into ExDoc extras. [VERIFIED: test/crosswake/guides/release_boundaries_test.exs:80-135] |
| Codename/privacy enforcement | Build / Repository tooling | Planning state | The scanner owns allowlisted routes and forbidden discovery sources; parked state retains the exact resume gate. [VERIFIED: lib/crosswake/planning/first_adopter_context.ex:10-64] |
| PR disposition | GitHub service boundary | Phase-local evidence | GitHub is mutable authority for current heads/checks; only a dated, bounded record belongs in phase evidence. [VERIFIED: 167-CONTEXT.md D-27,D-28] |

## Project Constraints (from AGENTS.md)

- Work only in `quality-ratchet-release`; do not infer an active lane from a removed flat state or resume the parked adopter work. [VERIFIED: AGENTS.md]
- Preserve the Phoenix-first route-policy/runtime-contract thesis, explicit per-route ownership, typed/versioned/low-frequency bridge contracts, honest offline claims, and fail-closed denials. [VERIFIED: AGENTS.md]
- Keep Android frozen at its existing generator, Maven, JVM, and vector posture; add no Android features, templates, device proof, parity, or release requirements. [VERIFIED: AGENTS.md]
- Do not add menu/action breadth, companions, capture/device packs, commerce productionization, dashboards, showcase polish, generic/background sync, or generic native storage. [VERIFIED: AGENTS.md]
- Public guides say **first adopter**; durable planning may use **First B2C Adopter** and `first_b2c_adopter`. Never identify or infer the adopter, and never search history/external sources to do so. [VERIFIED: AGENTS.md]
- Never emit payloads, answers, media, transcripts, credentials, account identifiers, tokens, or stable device identifiers into logs, diagnostics, aggregates, or proof. Preserve opaque scopes, partitioned outboxes, replay authorization, and fail-closed logout/account-switch behavior. [VERIFIED: AGENTS.md]
- Verification is automation-first; human steps are reserved for unavoidable credentials, approvals, or irreversible trust actions. Device setup may be human, but assertions/evidence evaluation stay automated. [VERIFIED: AGENTS.md]
- Promote only recurring stable contracts into CI; keep one-time reconciliation as phase evidence. Update requirements, roadmap, state, ADR/support truth, and rendered guides together when a decision changes. [VERIFIED: AGENTS.md]

## Standard Stack

### Core

| Component | Version / contract | Purpose | Why standard here |
|-----------|--------------------|---------|-------------------|
| Elixir / Mix task | Elixir `~> 1.19`; project `0.2.0` | Typed current truth and `crosswake.docs.sync` command | Already the package/runtime and task convention. [VERIFIED: mix.exs:4-22] |
| Existing support and capability renderers | In-repo | Produce byte-stable Markdown | Both output families already expose deterministic render/write seams. [VERIFIED: lib/crosswake/support_matrix/renderer.ex:18-100; lib/crosswake/capability_map/renderer.ex:25-80] |
| ExUnit | In-repo framework | Semantic, byte-parity, task-output, privacy, and CI-policy tests | Existing tests already separate generated parity from authored semantic invariants. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs:37-81; test/crosswake/guides/release_boundaries_test.exs:22-145] |
| ExDoc | `~> 0.38` | Current guide navigation and rendered package docs | Existing extras/groups and README-as-map are contractual and must remain unchanged. [VERIFIED: mix.exs:48-60,109-215] |
| Repository artifact policy + Node verifier | Schema `1` | Generated-source ownership, fixed argv, outputs, remediation, drift restoration | Existing verifier already loops records, snapshots outputs, catches undeclared output, and restores originals. [VERIFIED: script/verify_repository.mjs:55-85,229-268] |
| GitHub Actions / `gh` | Existing `Crosswake CI` | Current check authority and PR reconciliation | Phase must extend existing leaves and use fresh PR state; no new required context. [VERIFIED: 167-CONTEXT.md D-11,D-22 through D-28] |

### Supporting

| Component | Purpose | When to use |
|-----------|---------|-------------|
| `Mix.Shell.Process` | Capture calm task output in ExUnit | Test success text and exact drift remediation without terminal parsing. [VERIFIED: test/mix/tasks/crosswake.gen.native_controls_ui_test.exs:1-35] |
| `Crosswake.Planning.FirstAdopterContext` | Codename/privacy scan | Run after every current-doc/state/evidence change. Its exact destination vocabulary is `:durable`, `:public`, `:fast_changing`, `:host_private`, `:secret_only`, `:forbidden`. [VERIFIED: lib/crosswake/planning/first_adopter_context.ex:10-27] |
| Existing documentation/package leaves | Recurring proof | Add sync check and focused semantic tests to `documentation-contracts`; preserve package/ExDoc coverage for public docs. [VERIFIED: .github/workflows/crosswake-ci.yml:68-97,200-236] |

No external package is needed or authorized. [VERIFIED: 167-CONTEXT.md D-07,D-09 through D-11] Therefore there is no package-legitimacy audit or installation command for this phase.

## Architecture Patterns

### System Architecture Diagram

```text
Executable current truth
  SupportMatrix + CapabilityMap + package manifests + active STATE
                |
                v
       validate typed combinations ---- invalid ----> fail closed with owner/action
                |
              valid
                v
   crosswake.docs.sync renderer boundary
        | default                    | --check
        v                            v
checked-in support/capability     render in memory
Markdown projections             + byte compare only
        |                            |
        +------------+---------------+
                     v
 existing documentation-contracts + ExDoc/package + privacy + docs-only route
                     |
                     v
            one Crosswake CI result

GitHub API (fresh heads/bases/checks) -> guarded PR action -> phase-local disposition evidence
                                             |
                                  #115/#57 stop at Phase 168 gate
```

This preserves one executable owner, one projection command, existing CI authority, and a distinct mutable GitHub service boundary. [VERIFIED: 167-CONTEXT.md D-01 through D-15,D-27,D-28]

### Recommended Project Structure

```text
lib/crosswake/
├── capability_map.ex                         # closed claim dimensions and cross-field validation
├── capability_map/renderer.ex                # capability projection
├── support_matrix/support_matrix.ex          # public support owner
└── support_matrix/renderer.ex                 # support projection
lib/mix/tasks/
└── crosswake.docs.sync.ex                    # one default-write / --check-no-write command
script/
└── repository_artifact_policy.json           # second generated-contract record
test/
├── mix/tasks/crosswake.docs.sync_test.exs    # task modes/output/no-write proof
├── crosswake/capability_map/                  # valid/invalid claim combinations
├── crosswake/support_matrix/                  # canonical and renderer parity
├── crosswake/guides/                          # authored semantic invariants/ExDoc topology
└── crosswake/proof/                           # generalized policy and CI routing proof
.planning/workstreams/quality-ratchet-release/phases/167-.../evidence/
└── pr-dispositions.*                         # one-time dated snapshot, never live authority
```

File placement is a recommendation within the agent's discretion. [ASSUMED] The owner/output/test families themselves are locked. [VERIFIED: 167-CONTEXT.md D-09 through D-15]

### Pattern 1: Typed claim dimensions before prose

Extend the canonical row/claim model with closed `evidence_subject`, `source_binding`, and `activation_state` equivalents, validate cross-field combinations, then have both renderers phrase the three separate claims. [VERIFIED: 167-CONTEXT.md D-16 through D-20] The existing row currently enforces eleven fields and exact vocabularies such as categories `[:shipped, :demoed, :missing, :deferred, :next_pack_candidate]` and proof postures `[:merge_blocking, :advisory, :not_yet_proven, :unsupported]`; add dimensions without changing the public labels. [VERIFIED: lib/crosswake/capability_map.ex:10-56]

Recommended invariants:

- A reference-host evidence subject cannot be adopter-bound. [VERIFIED: 167-CONTEXT.md D-20]
- A physical proof posture requires a nonempty source binding and dated recorded runtime, not simulator/fixture evidence. [VERIFIED: 167-CONTEXT.md D-17,D-20]
- An activation state of blocked cannot render/promote adopter support. [VERIFIED: 167-CONTEXT.md D-17 through D-20]
- Retained evidence remains past-tense and cannot silently acquire a newer date or host subject. [VERIFIED: 167-CONTEXT.md D-17,D-20]

### Pattern 2: Render-in-memory for `--check`

The task should call pure renderer functions first. In default mode, write only if changed; in `--check`, read targets and compare bytes without invoking any write helper. On drift, raise/fail once per target with canonical source, target, and `mix crosswake.docs.sync`. [VERIFIED: 167-CONTEXT.md D-09,D-13] `Mix.Task` supplies the task contract and `Mix.shell()` provides testable output. [CITED: https://hexdocs.pm/mix/Mix.Task.html] [CITED: https://hexdocs.pm/mix/Mix.Shell.Process.html]

### Pattern 3: Generalize the registry, preserve exact old-record regression

Change only the invalid singleton assumption: `regeneration_argv.length !== 2` must become a nonempty fixed-argv rule for every record. [VERIFIED: script/verify_repository.mjs:78-84] Add ordering/uniqueness/non-overlap checks across generated records, then retain an exact regression assertion for the existing contract generator and add an exact docs-sync record. [ASSUMED] The current executor already visits every record and protects the worktree by restoring snapshotted outputs. [VERIFIED: script/verify_repository.mjs:229-268] Update the Phase 166 test/helper that currently requires exactly one record and exactly two argv calls. [VERIFIED: test/crosswake/proof/phase166_repository_quality_test.exs:166-192,361-372]

### Pattern 4: Guarded PR mutation

For each PR: refresh head/base SHA and current `Crosswake CI`; compare them to the planned observation; stop if changed; perform only its locked rebase/expand/squash/defer action; wait for current checks; then record observed SHA/checks/disposition/reason/next gate. [VERIFIED: 167-CONTEXT.md D-22 through D-28] This is optimistic concurrency at a mutable service boundary. [ASSUMED]

### Anti-Patterns to Avoid

- **Second all-facts manifest:** creates competing authority. Use typed owners plus projections. [VERIFIED: 167-CONTEXT.md D-01,D-10]
- **Renderer-only prose fix:** leaves invalid combinations representable and recurrence unguarded. Fix the canonical model first. [VERIFIED: 167-CONTEXT.md D-02,D-18,D-20]
- **`--check` that writes then restores:** violates explicit no-write CI semantics even if the final diff is clean. Render and compare in memory. [VERIFIED: 167-CONTEXT.md D-09,D-13]
- **Whole-guide snapshots:** freeze obsolete wording and reader structure. Use exact bytes only for generated files; semantic assertions for authored guides. [VERIFIED: 167-CONTEXT.md D-14]
- **Permanent PR ledger/live count fixture:** mutable queue facts are one-time evidence, not CI truth. [VERIFIED: 167-CONTEXT.md D-15,D-27]
- **Refreshing release PRs during reconciliation:** #115 and #57 are Phase 168 approval surfaces. [VERIFIED: 167-CONTEXT.md D-25,D-26]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Documentation ownership | New global docs manifest | Existing Elixir owners + artifact policy | The layered authority decision explicitly forbids a competing all-facts store. [VERIFIED: 167-CONTEXT.md D-01,D-10] |
| Projection drift | Bespoke shell diff/staging script | Pure renderers + Mix task + byte compare | Existing Elixir rendering and ExUnit output capture cover deterministic/no-write behavior. [VERIFIED: lib/crosswake/capability_map/renderer.ex:25-80; test/mix/tasks/crosswake.gen.native_controls_ui_test.exs:1-35] |
| CI topology | New workflow/check | Existing `documentation-contracts`, package/ExDoc leaf, umbrella | Required by D-11 and D-32. [VERIFIED: 167-CONTEXT.md D-11,D-32] |
| Privacy scanning | Regexes in the disposition script | `FirstAdopterContext` allowlist/scanner | It already encodes repository destinations and forbidden discovery inputs. [VERIFIED: lib/crosswake/planning/first_adopter_context.ex:10-64] |
| PR truth | Checked-in live PR database | Fresh GitHub query + phase-local evidence | Prevents stale queue state from becoming authority. [VERIFIED: 167-CONTEXT.md D-15,D-27] |

## Current Contradictions and Reconciliation Inventory

| Surface | Observed current truth | Planning action |
|---------|------------------------|-----------------|
| Support projection | Physical-iPhone row says “A committed corrected-provenance physical-device record and deterministic authority gates support one first adopter offline-study flow.” [VERIFIED: lib/crosswake/support_matrix/renderer.ex:337-343] | Remove present adopter-support implication; render dated reference-host proof and blocked adopter activation separately. |
| Capability owner | Exact row values include `id: "first-adopter-physical-iphone"`, `category: :missing`, `display_label: "Future gap"`, `proof_posture: :not_yet_proven`; its implication says support remains blocked. [VERIFIED: lib/crosswake/capability_map.ex:425-437] | Add claim dimensions/guards and retain the blocked current activation meaning. |
| iOS support owner | Exact defaults are `ios_version: "17.0"`, status `:supported`, `baseline_status: :supported`, `proof_status: :supported`; notes distinguish verified substrate from blocked physical/support promotion. [VERIFIED: lib/crosswake/support_matrix/support_matrix.ex:427-435] | Preserve platform baseline while splitting evidence subject and adopter activation; do not demote unrelated iOS support. |
| Generated renderer test | Test currently asserts the contradictory “support one first adopter” sentence. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs:63-68] | Replace with three semantic claims plus exact generated byte parity. |
| Package floors | Rulestead and Rindle manifests/READMEs still declare core `~> 0.1`; the compatibility guide labels Rulestead unpublished even though current release state differs. [VERIFIED: packages/crosswake_rulestead/mix.exs:66-69; packages/crosswake_rindle/mix.exs:81-84; packages/crosswake_rulestead/README.md:14-16; packages/crosswake_rindle/README.md:14-16; guides/companion_compatibility.md:24-28] | Expand PR #110 across manifests, both package READMEs, compatibility/published statement, install guidance where current, runbook, and drift fixtures. |
| Install guide | It still presents core dependency `~> 0.1`. [VERIFIED: guides/install.md:36-45] | Reconcile the current install version marker to the executable package version/floor without rewriting historical changelog entries. |
| setup-java | Seven live uses exist; one composite action and six workflow uses are not coherently covered by PR #121. [VERIFIED: .github/actions/setup-android-jvm/action.yml:19; .github/workflows/crosswake-ci.yml:947,1338; .github/workflows/phase68-proof.yml:39; .github/workflows/release-please.yml:511,597,777] | Rebase/expand #121 to all seven, immutable full SHAs where required, plus one repository-wide exact assertion. |
| Parked state | Its recorded status is `parked_external_dependency` and exact next action retains TODO-002 plus source-bound signed-device proof. [VERIFIED: .planning/workstreams/first-b2c-adopter-readiness/STATE.md] | Update only current contradictory wording; preserve codename, independent resume point, and exact external gate. |

## Live Pull-Request Research Snapshot

This table is a read-only observation from 2026-09-10 and must be refreshed before any execution action. [VERIFIED: GitHub API observed 2026-09-10]

| PR | Observed state | Required disposition / next gate |
|----|----------------|----------------------------------|
| #121 | Head `6270a256ef24058d7854076ad3c3bb42f18877bc`; observed current base `0b59224bbabc3f0b40038d0c1c4dc7ecae81de4c`; mergeable `CLEAN`; 47 passing checks. Its diff covers six uses and uses an older v6 SHA. [VERIFIED: GitHub API observed 2026-09-10] | Rebase, cover all seven uses, use current immutable v6 pin, update exact assertion, rerun current CI, merge; supersede only if Dependabot cannot carry coherent scope. [VERIFIED: 167-CONTEXT.md D-22] |
| #110 | Head `28c563dd594eaa30f64d999a1412b1732c599a83`; base snapshot `329b219908faa3bdc8f932db3b4ffd7b8853ea89`; `BEHIND`; observed legacy set 7 failed/58 passed/12 skipped; diff touches only two manifests. [VERIFIED: GitHub API observed 2026-09-10] | Rebase and expand all package/docs/drift surfaces; merge or supersede while preserving rationale. [VERIFIED: 167-CONTEXT.md D-23] |
| #105 | Head `801ac754fcfc9a6de7d7a2b00122d246d98c490d`; base snapshot `329b219908faa3bdc8f932db3b4ffd7b8853ea89`; `BEHIND`; 3 commits; observed 65 passed/12 skipped. [VERIFIED: GitHub API observed 2026-09-10] | Rebase/squash to one intent commit; run focused Swift plus current umbrella; merge. [VERIFIED: 167-CONTEXT.md D-24] |
| #115 | Head `a82f15fa998a675226598187ac1c817730ab6c9e`; base snapshot `cec20fbd71ca3319c7d7dfbeb439d1f74545e9c8`; `BEHIND`; 47 passed. [VERIFIED: GitHub API observed 2026-09-10] | Keep open, add current reason, defer to Phase 168; no merge/close/recreate/publish. [VERIFIED: 167-CONTEXT.md D-25] |
| #57 | Head `e14a4e32db90efd5f54d250d9e1ee1ba929a56c1`; base snapshot `0b59224bbabc3f0b40038d0c1c4dc7ecae81de4c`; observed `BLOCKED`; 11 failed/36 passed. [VERIFIED: GitHub API observed 2026-09-10] | Keep open, add current reason, defer to Phase 168; current red/stale head is not the candidate. [VERIFIED: 167-CONTEXT.md D-26] |

GitHub reports old base snapshots for behind PRs; the plan must capture full observed base SHA at action time rather than treating abbreviated research values as executable inputs. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Conflating platform support, evidence proof, and adopter activation
**What goes wrong:** a valid dated reference run becomes a present support statement for another host. [VERIFIED: lib/crosswake/support_matrix/renderer.ex:329-347]
**Avoidance:** represent subject/binding/activation independently and test prohibited combinations before rendering. [VERIFIED: 167-CONTEXT.md D-16 through D-20]

### Pitfall 2: Breaking the Phase 166 registry while adding a second record
**What goes wrong:** validator/tests assume one record and exactly two argv arrays. [VERIFIED: script/verify_repository.mjs:78-84; test/crosswake/proof/phase166_repository_quality_test.exs:166-192,361-372]
**Avoidance:** generalize cardinality only; preserve fixed argv safety, sorted outputs, safe paths, exact existing record regression, undeclared-output detection, and restoration. [VERIFIED: script/verify_repository.mjs:78-84,229-268]

### Pitfall 3: A “check” command mutates the worktree
**What goes wrong:** CI temporarily writes or stages generated files, violating the locked no-write contract. [VERIFIED: 167-CONTEXT.md D-13]
**Avoidance:** compare pure rendered bytes in memory and include a test that snapshots target mtimes/bytes or denies writer invocation. [ASSUMED]

### Pitfall 4: Fixing package floors incompletely
**What goes wrong:** manifests update while package READMEs, install/compatibility guides, runbook statements, and synthetic drift fixtures continue teaching `~> 0.1` or incorrect publish status. [VERIFIED: packages/crosswake_rulestead/mix.exs:66-69; packages/crosswake_rindle/mix.exs:81-84; guides/companion_compatibility.md:24-28]
**Avoidance:** source an explicit affected-surface inventory from PR #110's locked scope and run focused package/release-boundary tests. [VERIFIED: 167-CONTEXT.md D-23]

### Pitfall 5: Treating stale GitHub observations as authority
**What goes wrong:** a force-push, base advance, or check change invalidates the planned action. [ASSUMED]
**Avoidance:** refresh immediately before each action, compare exact SHAs/checks, and stop on mismatch. [ASSUMED]

### Pitfall 6: Accidentally performing Phase 168
**What goes wrong:** merging a Release Please PR triggers immutable release work. [VERIFIED: 167-CONTEXT.md D-25,D-26]
**Avoidance:** make #115/#57 explicit stop nodes in the plan and evidence; comments are allowed, merge/close/recreate/publish is not. [VERIFIED: 167-CONTEXT.md D-25 through D-28]

## Code Examples

### Mix task shape

```elixir
# Pattern derived from the repository and official Mix task API; exact module placement is discretionary.
defmodule Mix.Tasks.Crosswake.Docs.Sync do
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    check? = args == ["--check"]
    projections = Crosswake.Docs.Projections.render_all()

    if check? do
      Crosswake.Docs.Projections.check!(projections)
    else
      Crosswake.Docs.Projections.write(projections)
    end
  end
end
```

`use Mix.Task`, `@impl Mix.Task`, and `run/1` follow the official task contract; the proposed projection helper is [ASSUMED] and should use the existing renderer APIs rather than create a truth store. [CITED: https://hexdocs.pm/mix/Mix.Task.html] [VERIFIED: lib/mix/tasks/crosswake.contract.gen.ex:1-4,57-64]

### Mechanical invalid-state test shape

```elixir
# Values quoted from the current closed vocabulary; new dimension values are intentionally omitted
# until implementation chooses their exact names.
assert :missing in Crosswake.CapabilityMap.categories()
assert :not_yet_proven in Crosswake.CapabilityMap.proof_postures()
assert {:error, violations} = validate_claim(invalid_reference_claim)
assert Enum.any?(violations, &(&1.rule_id == "claim.subject_binding_mismatch"))
```

The quoted existing values `:missing` and `:not_yet_proven` are exact. [VERIFIED: lib/crosswake/capability_map.ex:44-56] The validator/function/rule-id names are [ASSUMED]; the executor should choose focused names while preserving D-20 behavior.

## State of the Art

| Old/current approach | Phase 167 approach | Impact |
|----------------------|--------------------|--------|
| Renderer contains a hard-coded current-status table. [VERIFIED: lib/crosswake/support_matrix/renderer.ex:329-347] | Typed claims precede shared projection language. [VERIFIED: 167-CONTEXT.md D-16 through D-20] | Contradictions become invalid data rather than prose archaeology. |
| Renderer tests preserve whole sentences. [VERIFIED: test/crosswake/support_matrix/renderer_test.exs:63-68] | Exact bytes for generated artifacts plus semantic invariant tests. [VERIFIED: 167-CONTEXT.md D-14] | Wording may improve without losing owner truth. |
| Artifact registry validator encodes one generator's two invocations. [VERIFIED: script/verify_repository.mjs:78-84] | Every declared generator has one-or-more fixed invocations. [VERIFIED: 167-CONTEXT.md D-10] | Docs sync joins the existing authority without a second registry. |
| Manual renderer commands are discoverable only in code/tests. [VERIFIED: lib/crosswake/capability_map/renderer.ex:25-80; lib/crosswake/support_matrix/renderer.ex:18-100] | One documented `mix crosswake.docs.sync` command and exact remediation. [VERIFIED: 167-CONTEXT.md D-09] | Maintainers get a stable correction path. |

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under project Elixir `~> 1.19`; Node built-in tests for repository verifier [VERIFIED: mix.exs:4-22; test/js/repository_verification.test.mjs] |
| Config | `test/test_helper.exs`; repository policy fixtures under `test/js` [VERIFIED: repository paths opened this session] |
| Quick run | `mix test test/mix/tasks/crosswake.docs.sync_test.exs test/crosswake/capability_map test/crosswake/support_matrix` [ASSUMED: new test filename] |
| Full documentation gate | Use the exact commands already owned by `documentation-contracts`, package/ExDoc proof, privacy scan, and current `Crosswake CI`; add `mix crosswake.docs.sync --check` without creating a new context. [VERIFIED: .github/workflows/crosswake-ci.yml:68-97,200-236; 167-CONTEXT.md D-11,D-12] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | File exists? |
|--------|----------|-----------|-------------------|--------------|
| DOC-01 | Canonical claims reject contradictions; generated outputs byte-match; package/current narratives/ExDoc topology agree. | unit + integration + CI-policy | focused docs-sync, capability/support, guide, package, ExDoc and repository-verifier suites; then `Crosswake CI` | ❌ Wave 0 for docs-sync and cross-field invalid states; existing homes otherwise [VERIFIED: existing test paths in 167-CONTEXT.md] |
| DOC-02 | Public/durable terminology stays routed correctly and parked gate remains exact. | unit + artifact inspection | `mix crosswake.adoption_context.scan` plus first-adopter context tests and a parked-state assertion | Existing scanner/tests; ❌ focused parked/current-claim assertion [VERIFIED: lib/mix/tasks/crosswake.adoption_context.scan.ex:1-19; test/crosswake/planning/first_adopter_context_test.exs] |
| DOC-03 | All live PRs receive the locked disposition based on fresh state; deferred release PRs remain open. | automated GitHub query + artifact schema check | read-only `gh pr list/view/checks` before/after actions; validate phase-local evidence fields | ❌ Wave 0 phase-local evidence validator [ASSUMED] |

### Sampling Rate

- **Per task commit:** run the smallest affected ExUnit/Node/Swift test and `mix crosswake.docs.sync --check` after generated outputs exist. [ASSUMED]
- **Per wave merge:** run existing documentation-contract and package/ExDoc commands plus privacy scan. [VERIFIED: 167-CONTEXT.md D-12]
- **Phase gate:** current `Crosswake CI` green; one-time artifact inspection confirms all five PR dispositions and #115/#57 remain deferred. [VERIFIED: 167-CONTEXT.md D-22 through D-28]

### Wave 0 Gaps

- [ ] `test/mix/tasks/crosswake.docs.sync_test.exs` — default write, `--check` success, drift error, no-write proof, source/target/remediation output. [ASSUMED: filename]
- [ ] Focused canonical-claim tests — all five D-20 impossible combinations and three D-17 claims. [VERIFIED: 167-CONTEXT.md D-17,D-20]
- [ ] Multi-record repository-policy fixtures — one argv, multiple argv, duplicate source/output collision, unordered output, unsafe argv, restoration. [ASSUMED]
- [ ] Phase-local disposition schema/inspection check with number, full head/base SHA, checks, disposition, reason, next gate and privacy scan. [VERIFIED: 167-CONTEXT.md D-21,D-27]

The phase context reports the existing privacy/guide suite passed 171 tests on 2026-09-10 while missing this semantic contradiction, demonstrating that new typed invariants—not more phrase snapshots—are required. [VERIFIED: 167-CONTEXT.md Specific Ideas]

## Environment Availability

| Dependency | Required by | Available | Version / observation | Fallback |
|------------|-------------|-----------|-----------------------|----------|
| Git | repository inspection/rebase | ✓ | `2.41.0` [VERIFIED: local command 2026-09-10] | — |
| GitHub CLI | fresh PR state/action | ✓ | `2.95.0` [VERIFIED: local command 2026-09-10] | GitHub API/web UI for unavoidable trust action [ASSUMED] |
| Node/npm | repository verifier | ✓ | Node `v22.14.0`, npm `11.1.0` [VERIFIED: local command 2026-09-10] | — |
| Swift | PR #105 focused proof | ✓ | Swift `6.3.3` [VERIFIED: local command 2026-09-10] | CI/Xcode matrix remains authority [ASSUMED] |
| Erlang/Elixir/Mix | docs task and ExUnit | ✗ current shell | Repository requests Erlang `27.3`, Elixir `1.19.5-otp-27`; asdf reports no selectable Erlang for `erl`, so Mix cannot run. [VERIFIED: .tool-versions:1-3 and local command output 2026-09-10] | Install/select the pinned toolchain before execution, or use existing CI only after local task tests are authored. [ASSUMED] |
| Java | setup-java/Android validation | ✗ local system runtime | `/usr/bin/java` reports no runtime. [VERIFIED: local command output 2026-09-10] | GitHub Actions setup-java lane is the recurring proof; no Android feature work. [VERIFIED: AGENTS.md; 167-CONTEXT.md D-22] |

**Missing dependency with no acceptable local fallback:** the pinned Erlang/Elixir toolchain must be available before implementing or claiming local docs-sync/ExUnit verification. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | No product auth change | GitHub authentication is an external operator boundary; do not store credentials in evidence. [VERIFIED: 167-CONTEXT.md D-21,D-28] |
| V3 Session Management | No product session change | No runtime/session behavior changes authorized. [VERIFIED: phase boundary in 167-CONTEXT.md] |
| V4 Access Control | Yes, operational | Fresh base/head and branch authority must gate PR mutation; release PRs are explicitly non-mutable in this phase. [VERIFIED: 167-CONTEXT.md D-25 through D-28] |
| V5 Input Validation | Yes | Treat PR titles/bodies/check output and generated files as untrusted; store only fixed low-cardinality fields and full SHAs/status summaries. [VERIFIED: 167-CONTEXT.md D-21,D-27] |
| V6 Cryptography | Yes, supply chain | Pin Actions by immutable full-length commit SHA; never hand-roll signature/hash behavior. GitHub documents full-length commit SHA as the only immutable action release form. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Untrusted PR prose or check text injected into commands/evidence | Tampering / information disclosure | Query structured fields, quote shell arguments safely, do not echo bodies/payloads/secrets. [VERIFIED: 167-CONTEXT.md D-21,D-27] |
| TOCTOU between observed and mutated PR SHA | Tampering | Refresh and compare exact head/base immediately before action; stop on mismatch. [ASSUMED] |
| Mutable action tag | Tampering / supply chain | Pin full commit SHA and assert all seven uses. [CITED: https://docs.github.com/en/actions/reference/security/secure-use] [VERIFIED: 167-CONTEXT.md D-22] |
| Adopter identity/payload leakage | Information disclosure | Use the existing destination allowlist/privacy scanner; retain codename-only, low-cardinality evidence. [VERIFIED: lib/crosswake/planning/first_adopter_context.ex:10-64; 167-CONTEXT.md D-19,D-21] |
| Accidental release merge | Elevation / repudiation | Treat #115/#57 as immutable stop boundaries and record explicit deferral reason. [VERIFIED: 167-CONTEXT.md D-25 through D-27] |

## Recommended Plan Decomposition

1. **Wave 0 — prove the seams:** restore the pinned Erlang/Elixir toolchain; add task-mode tests, invalid-claim fixtures, generalized multi-record policy tests, and phase-local disposition schema/inspection. [ASSUMED]
2. **Claim transaction:** extend the canonical current-claim owner and validation, fix the support/capability contradiction, update semantic tests, and preserve unrelated platform/public vocabulary. [VERIFIED: 167-CONTEXT.md D-16 through D-20]
3. **Projection transaction:** implement `crosswake.docs.sync`, regenerate both guides, register the record, generalize policy validation, and wire no-write `--check` into existing docs/package proof without changing umbrella topology. [VERIFIED: 167-CONTEXT.md D-09 through D-15,D-32]
4. **Narrative transaction:** update only current README/install/compatibility/contribution/runbook/architecture references needed by the six reader jobs; preserve historical records and ExDoc groups. Run privacy, internal links, package/ExDoc, and docs-only routing proof. [VERIFIED: 167-CONTEXT.md D-04 through D-08,D-12,D-29 through D-32]
5. **Ordinary PR reconciliation:** refresh and guard #121, #110, #105 in that order; merge/supersede according to locked decisions and rerun current umbrella after each. Ordering #121 and #110 before release refresh is locked; placing #105 third is [ASSUMED].
6. **Release stop/evidence:** refresh #115/#57, add current defer reasons without merging/closing, write the privacy-safe phase-local disposition record for all five, and inspect that Phase 168 remains the next gate. [VERIFIED: 167-CONTEXT.md D-25 through D-28]

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | A focused `Crosswake.Docs.Projections` helper and suggested test/evidence filenames are appropriate placements. | Architecture / Code Examples / Validation | Low; names are discretionary, but avoid a second truth owner. |
| A2 | Cross-record canonical sources and output paths should be unique/non-overlapping. | Architecture Pattern 3 | Medium; planner should confirm desired registry invariant before locking it. |
| A3 | Guarded PR mutation should use optimistic exact-SHA rechecks and #121 → #110 → #105 sequencing. | PR pattern / Plan decomposition | Medium; remote state may change and mechanics are discretionary. |
| A4 | Timestamp/byte snapshots or writer denial are the best no-write test mechanism. | Pitfalls / Validation | Low; behavior matters more than test technique. |
| A5 | A small phase-local evidence schema validator is worthwhile. | Validation | Low; context permits JSON or Markdown, but reproduction/privacy fields must be exact. |
| A6 | Local toolchain installation/selection is required rather than relying only on CI. | Environment | Medium; execution environment may be repaired externally before implementation. |

## Open Questions (RESOLVED)

1. **Exact new closed atom vocabulary**
   - Known: semantics must cover evidence subject, source binding, and activation state without new public labels. [VERIFIED: 167-CONTEXT.md D-16]
   - Unknown: exact atoms and whether they live on every capability row or a focused current-claim struct. [ASSUMED]
   - Recommendation: choose the smallest typed owner that both renderers can consume; quote exact values in tests before updating prose. [ASSUMED]
   - **RESOLVED:** Plan 167-01 owns the bounded selection. It must place the three closed dimensions on the smallest typed `Crosswake.CapabilityMap` claim owner consumed by both renderers, and its deciding invariant is that all three D-17 claims plus every D-20 invalid combination are representable and table-tested without changing public labels. Exact internal atoms remain an implementation choice because they are not mutable external facts.
2. **Current action pin at execution time**
   - Known: all seven uses must be coherent and immutably pinned. [VERIFIED: 167-CONTEXT.md D-22]
   - Unknown: latest suitable v6 SHA may change after this research snapshot. [ASSUMED]
   - Recommendation: resolve from the official `actions/setup-java` release immediately before editing, then assert that exact SHA repository-wide. [CITED: https://github.com/actions/setup-java/releases]
   - **RESOLVED:** Plan 167-05 owns selection at execution time. It must resolve the suitable official v6 release immediately before editing, accept only a full immutable commit OID, and require all seven live uses plus the repository assertion to equal that OID. Research snapshots and mutable tags are never write authority.
3. **PR supersession necessity**
   - Known: #121/#110 may be superseded only if their existing branches cannot carry coherent completion. [VERIFIED: 167-CONTEXT.md D-22,D-23]
   - Unknown: current branch permissions and post-rebase reviewability. [ASSUMED]
   - Recommendation: attempt the locked rebase/expansion path first; record the reason if supersession becomes necessary. [VERIFIED: 167-CONTEXT.md D-22,D-23]
   - **RESOLVED:** Plans 167-05 and 167-06 each own the decision for their PR after a fresh head/base/permission/reviewability read. The original branch is mandatory when it can carry the complete locked transaction; exactly one replacement is authorized only when that invariant fails. Any replacement number and relationship are captured as bounded execution evidence, never pinned during planning.

## Sources

### Primary (HIGH confidence)

- Repository source files and tests cited inline, opened during this session — canonical values, renderer behavior, artifact policy, CI owners, privacy routing, package floors, and test topology.
- `167-CONTEXT.md`, `AGENTS.md`, active/parked workstream requirements/state/roadmap, governing ADR and retained Phase 162/163.1 records — locked scope, privacy, proof, and disposition decisions.
- GitHub API read-only observations on 2026-09-10 — mutable PR head/base/check snapshot; refresh before use.

### Secondary (MEDIUM confidence)

- [Mix.Task official documentation](https://hexdocs.pm/mix/Mix.Task.html) — task behavior and `run/1` contract.
- [Mix.Shell.Process official documentation](https://hexdocs.pm/mix/Mix.Shell.Process.html) — process-message shell testing.
- [ExDoc 0.38.2 Mix task documentation](https://hexdocs.pm/ex_doc/0.38.2/Mix.Tasks.Docs.html) — extras/group configuration and stable authored guide topology.
- [GitHub secure use reference](https://docs.github.com/en/actions/reference/security/secure-use) — immutable action pinning.

### Tertiary (LOW confidence)

- None. All assumptions are isolated in the Assumptions Log.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — entirely existing repository components and official APIs.
- Architecture: HIGH — locked decisions align with current typed/rendered/artifact/CI seams.
- Pitfalls: HIGH for observed contradictions and singleton assumptions; MEDIUM for recommended PR concurrency mechanics.
- Mutable PR state: MEDIUM — authoritative when observed, intentionally time-limited.

**Research date:** 2026-09-10
**Valid until:** 2026-09-17 for GitHub/package/action observations; repository architecture remains valid until those files change.
