# Phase 168: 0.2.1 Release Candidate Readiness - Research

**Researched:** 2026-09-12
**Domain:** deterministic multi-ecosystem release-candidate proof, immutable evidence, and approval-gated publication
**Confidence:** HIGH for in-repo architecture and constraints; MEDIUM for external tool behavior

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Companion PRs #115, #146, and #147: independently reassess and release serially after the linked
  0.2.1 rollup; they are not folded into Phase 168's one core approval.
- GitHub App migration for the one iOS mirror: revisit only when credential expiry, rotation,
  finer-grained policy, or multi-repository scope creates a demonstrated need.
- Signed artifact attestations or a claimed SLSA level: future supply-chain work if consumer need
  justifies the policy, signing, and verification surface.
- New release dashboard/UI, generic release orchestrator, staging package registry, public status
  taxonomy, Android breadth, and first-adopter activation remain outside Phase 168.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | “The companion clean-room harness resolves, compiles, registers, and doctors every supported published companion from a throwaway host without false harness failures.” [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:84-85] | Two-stage candidate/public payload modes, actual `phx_new` generation, five isolated profile lanes, repeat-install checks, and negative controls. |
| REL-02 | “iOS mirror publishing uses explicit cross-repository authority, fails loudly when that authority is absent or insufficient, and has an automated, idempotent backfill command for the missing 0.2.0 mirror tag.” [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:87-89] | Split mirror baseline, credentialed candidate rehearsal, fast-forward normal publication, and separately authorized recovery. Context D-21 supersedes the older word “missing”: the exact 0.2.0 tag is now an idempotent PASS. |
| REL-03 | “Core, companion, Android, and iOS release coordinates and compatibility floors are internally consistent and protected by drift checks.” [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:91-92] | Metadata-first coordinate graph plus artifact, lockfile, SwiftPM, Gradle, and Release Please drift fixtures. |
| REL-04 | “The Crosswake 0.2.1 release candidate passes package audit, build, tests, documentation generation, clean-room installation, and release-status verification from the exact candidate commit.” [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:94-96] | Exact-head candidate receipt, distributable digest pipeline, generated-host matrix, and source-bound CI receipt. |
| REL-05 | “All reversible release work is automated, leaving at most credentials and one explicit irreversible publish approval for the maintainer.” [VERIFIED: .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md:98-99] | One command, one receipt, credential rehearsal, explicit no-mutation field, one merge approval, and fail-closed postapproval graph. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Before planning or implementation, read the governing ADR, adoption brief, route-policy map, project thesis, active requirements/roadmap/state, and parked adopter state listed in the project guide. [VERIFIED: AGENTS.md:3-20]
- Optimize infrastructure for one real Phoenix application on one physical iPhone with one offline mutation island; preserve the stated priority order from explicit route ownership through host-reusable/privacy-safe proof, foreground iOS media, physical-device evidence, and only evidence-demonstrated defects. [VERIFIED: AGENTS.md:22-34]
- If the first adopter is web-only, finish only the bounded route inventory and pause Crosswake until the public-v1 mobile path is active. [VERIFIED: AGENTS.md:36-37]
- Preserve Crosswake as a Phoenix-first route-policy and runtime-contract system; keep route ownership and semantic, typed, versioned, low-frequency bridge contracts explicit. [VERIFIED: AGENTS.md:41-46]
- Keep offline claims narrow and fail closed; cached read-only is not mutation and one island is not generic sync. [VERIFIED: AGENTS.md:47-51]
- Treat diagnostics and proof as product surface and prefer one-command host proof. [VERIFIED: AGENTS.md:49-51]
- Android is frozen at its current generator, Maven, JVM, and vector posture; Phase 168 may verify and publish the existing coordinate but must not add Android features, templates, device proof, parity work, or release breadth. [VERIFIED: AGENTS.md:52-56]
- Do not add companion/product breadth, capture/device packs, commerce productionization, dashboards, generic/background sync, brand polish, or generic native storage. [VERIFIED: AGENTS.md:54-56]
- Durable internal codename is exactly “First B2C Adopter” / `first_b2c_adopter`; public guides say “first adopter.” [VERIFIED: AGENTS.md:60-61]
- Never record, infer, search for, or expose the adopter's real identity or revealing details. [VERIFIED: AGENTS.md:62-64]
- Raw answers, media, transcripts, credentials, account identifiers, tokens, and stable device identifiers must not enter logs, telemetry, doctor output, aggregates, or proof artifacts. [VERIFIED: AGENTS.md:65-69]
- Work only in `quality-ratchet-release`; do not resume the parked first-adopter workstream. [VERIFIED: AGENTS.md:73-81]
- Default to automated verification. Human action is reserved for credentials, external approval, or irreversible trust actions. [VERIFIED: AGENTS.md:82-87]
- Add recurring checks to CI only when they protect a stable contract; leave one-time reconciliation in phase evidence. [VERIFIED: AGENTS.md:88-90]
- When a decision changes, update requirements, roadmap, state, ADRs, capability/support truth, and guide renderings together. [VERIFIED: AGENTS.md:91-94]

## Summary

Phase 168 should be planned as a provenance pipeline, not as another publish script. The candidate command must evaluate immutable inputs, construct exact distributables, prove them as a consumer would, rehearse the only cross-repository write authority, and emit a deterministic receipt. The receipt becomes `STALE` when any bound identity changes; it becomes `READY FOR APPROVAL` only when every reversible check and the real credentialed mirror dry-run pass. This division follows the locked candidate identity and state model. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-CONTEXT.md:35-46,110-143]

The repository already has the right seams, but they are not yet candidate-grade. `Crosswake.ReleaseStatus` reads manifest/config/workflow inputs and checks the five companions, while its current schema is exactly `"1.0.0"` and its aggregate values are exactly `:error`, `:warning`, and `:ok`. [VERIFIED: lib/crosswake/release_status.ex:9-27,729-739] The existing clean-room script currently creates `CLEAN_ROOM_DIR="${RUNNER_TEMP:-/tmp}/clean_room_${PACKAGE}"`, deletes that predictable path, runs `mix new`, resolves public packages once, and only then compiles/smokes/doctors. [VERIFIED: script/verify_companion_cleanroom.sh:327-346,418-425,670-739] The current iOS paths require already-created release tags and use `--force-with-lease` in normal main updates, so candidate mode and normal fast-forward publication must be separated from recovery. [VERIFIED: script/verify_ios_mirror_backfill.sh:93-124,248-267]

The first planning wave is a prerequisite landing/authority repair, not release implementation: verify and land the exact five Phase 167 blobs, then fix full pagination before trusting deferral-marker absence. The current GraphQL fragment is verbatim `comments(last:100) { nodes { body } }` and counts only returned nodes. [VERIFIED: script/check_phase167_pr_dispositions.py:1017-1046,1070-1084] GitHub requires cursor pagination with `pageInfo` and limits `first`/`last` to 100, so either fetch all pages or fail closed when another page exists. [CITED: https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api]

**Primary recommendation:** implement one deterministic Elixir candidate evaluator with narrow Git/Hex/native adapters and fixture seams; bind all artifacts and proofs into one exact-head receipt; keep the existing status command read-only and keep public mutation solely behind the one Release Please merge approval.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Candidate evaluation and receipt serialization | API / Backend (local Elixir domain layer) | — | Ordinary modules own deterministic validation, state derivation, schema, and projections. |
| Maintainer command | API / Backend (Mix task) | — | The task parses fixed inputs, delegates, renders, and exits; it does not own policy. |
| Hex build/unpack/public fetch | External package registry + narrow adapter | Local filesystem | Hex owns package format/resolution; the adapter produces bounded observations and unpacked roots. |
| Generated Phoenix consumer proof | Frontend Server (throwaway Phoenix host) | Local filesystem | Consumer truth belongs in an actual generated host, not repository source. |
| Candidate CI and approval | External service boundary (GitHub Actions/Release Please) | Local evaluator | Actions supplies exact run/head identity and credentials; the evaluator proves content and emits the receipt. |
| iOS subtree publication | External Git mirror | Git adapter | The mirror owns public refs; local code computes the split and validates remote state before any push. |
| Android coordinate verification | External Maven registry | Gradle adapter | Existing Android artifacts are verified/published without expanding Android capability. |

## Standard Stack

### Core

| Tool / Library | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Erlang / Elixir / Node | `27.3` / `1.19.5-otp-27` / `22.14.0` | Repository and candidate runtime | These are the exact checked-in toolchain values: `erlang 27.3`, `elixir 1.19.5-otp-27`, `nodejs 22.14.0`. [VERIFIED: .tool-versions:1-3] |
| `phx_new` | `1.8.13` pinned exactly | Generate the real minimal consumer host | The official Hex package reports `latest_stable_version: 1.8.13`, published 2026-08-25, and the project lock contains Phoenix `1.8.13`. [CITED: https://hex.pm/api/packages/phx_new] [VERIFIED: mix.lock:15] |
| Hex/Mix package tasks | installed by pinned toolchain | Build, dry-run, unpack, and fetch exact packages | `mix hex.build`, `mix hex.publish --dry-run`, and `mix hex.package fetch PACKAGE VERSION --unpack` are the official package surfaces. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Package.html] |
| Git + `git subtree` | existing runner Git, full history | Compute exact iOS split and validate/push mirror refs | The repository already standardizes `git subtree split --prefix=packages/crosswake-shell-core-ios`. [VERIFIED: script/verify_ios_mirror_backfill.sh:179-197] |
| Release Please action | pinned action SHA, documented as `v4.1.3` | Refresh the linked core release proposal and create component releases after merge | Current workflow invokes `googleapis/release-please-action@45996ed...` with manifest/config files. [VERIFIED: .github/workflows/release-please.yml:82-95] |

### Supporting

| Tool | Version / Source | Purpose | When to Use |
|------|------------------|---------|-------------|
| `Jason` | `1.4.5` locked | Receipt JSON encoding | Keep deterministic map normalization and schema fixtures in Elixir. [VERIFIED: mix.lock:7] |
| `actionlint` | local `1.7.12` | Workflow static validation | Run after every workflow topology or expression change. [VERIFIED: local probe 2026-09-12] |
| Node test runner | Node `22.14.0` | Python/script fixture tests and cross-process checks | Reuse the established Phase 167 harness for pagination, blob receipts, and privacy failure output. [VERIFIED: test/js/phase167_pr_dispositions.test.mjs:1-20,136-173] |
| `hex_tarball` reference implementation | `hex_core` docs | Extract exact local tarball metadata, contents, and checksums | Prefer a narrow adapter or test helper around the official unpack semantics; do not invent the Hex archive format. [CITED: https://hex-core.hexdocs.pm/hex_tarball.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Unpacked candidate path dependencies | Custom signed local Hex repository | Rejected by D-10: added signing/server/repository/transitive-closure complexity would test the harness more than the candidate. |
| One candidate receipt | PR number, branch, mutable artifact name, or historical CI success | Rejected by D-04 because none binds all content identities. |
| Existing Release Please workflow family | New release controller/workflow family | Rejected by D-13/D-17; it expands authority and obscures exact per-release approval. |
| Fast-forward normal mirror push | `--force-with-lease` normal push | Rejected by D-24/D-25; the latter can replace history and belongs only in explicit recovery. |

**Installation / setup:** no new project runtime dependency should be added. Install the pinned generator only inside an invocation-specific `MIX_HOME`/`HEX_HOME`, then invoke `mix phx.new` from that archive. Official Mix supports installing an exact Hex archive version. [CITED: https://mix.hexdocs.pm/Mix.Tasks.Archive.Install.html]

```bash
MIX_HOME="$isolated_mix_home" HEX_HOME="$isolated_hex_home" \
  mix archive.install hex phx_new 1.8.13 --force
MIX_HOME="$isolated_mix_home" HEX_HOME="$isolated_hex_home" \
  mix phx.new "$host_root" --no-ecto --no-assets --no-dashboard --no-install --no-version-check
```

The `phx.new` flags above are official generator options. [CITED: https://phx-new.hexdocs.pm/Mix.Tasks.Phx.New.html]

## Package Legitimacy Audit

No new application dependency is recommended. The only newly pinned external tool is the official Phoenix generator archive `phx_new`; the GSD package-legitimacy seam supports npm/PyPI/crates but not Hex, so no false seam verdict is asserted. The authoritative Hex API identifies its source as `https://github.com/phoenixframework/phoenix`, shows insertion in 2018, more than two million all-time downloads, and version `1.8.13`; official Phoenix docs expose the same generator task. [CITED: https://hex.pm/api/packages/phx_new] [CITED: https://phx-new.hexdocs.pm/Mix.Tasks.Phx.New.html]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `phx_new` | Hex | since 2018 | 2,219,448 all-time at research time | `phoenixframework/phoenix` | Authoritative manual audit; Hex seam unsupported | Approved as isolated exact-version build tool, not project dependency |

**Packages removed due to SLOP verdict:** none.
**Packages flagged as suspicious:** none.

## Architecture Patterns

### System Architecture Diagram

```text
exact 40-SHA + 0.2.1 + output dir
              |
              v
thin Mix task -> deterministic evaluator -> identity/config/coordinate guards
                                             |
                           +-----------------+------------------+
                           |                 |                  |
                           v                 v                  v
                    Hex artifact       generated Phoenix    iOS split +
                    build/unpack        host matrix          remote plan
                           |                 |                  |
                           +-----------------+------------------+
                                             |
                                             v
                                  schema-versioned receipt
                                  JSON (authority) + Markdown
                                             |
                          changed identity? -+-> STALE/BLOCKED
                                             |
                          trusted mirror dry-run PASS?
                                             |
                                             v
                                    READY FOR APPROVAL
                                             |
                             one explicit merge approval
                                             |
                                             v
                       merge parent/tree guard -> linked tags
                                             |
                     +-----------------------+-------------------+
                     v                       v                   v
                  Hex core               iOS mirror          Maven core
                     |                       |                   |
                     +----------- exact public proofs ----------+
                                             |
                                      COMPLETE or PARTIAL
```

### Recommended Project Structure

```text
lib/crosswake/release_candidate.ex              # deterministic orchestration and state
lib/crosswake/release_candidate/                # identity, artifact, proof, receipt modules
lib/mix/tasks/crosswake.release.candidate.ex    # fixed-purpose thin CLI
script/release_candidate/                       # narrow Git/Hex/Swift/Gradle adapters
test/crosswake/release_candidate/               # domain and negative fixtures
test/mix/tasks/crosswake_release_candidate_test.exs
test/fixtures/release_candidate/                # normalized inputs/expected receipts
```

This placement is a recommendation within D-26 discretion. Keep `Crosswake.ReleaseStatus` as a reusable read-only projection rather than making it the mutable candidate orchestrator; its existing task only accepts `json` and `live` booleans and delegates to `Crosswake.ReleaseStatus.build/1`. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:20-47]

### Pattern 1: Functional Core, Imperative Shell

**What:** adapters return small allowlisted observations; a pure evaluator validates them and derives one state, one next action, and deterministic receipt bytes.

**When to use:** every Git, GitHub, Hex, mirror, Swift, Gradle, and registry interaction.

**Required seams:** filesystem reader, command runner, time/run metadata provider, HTTP/Git remote probes, and credential-rehearsal observation. Volatile time and run IDs may be recorded but must not participate in normalized proof digests. The current status module demonstrates injectable `http_probe` and `git_ref_probe` seams. [VERIFIED: lib/crosswake/release_status.ex:66-92,916-926]

### Pattern 2: Content-Addressed Candidate Receipt

**What:** canonical JSON binds commit/tree/base, exact linked coordinates, workflow/config blobs, every package outer checksum plus normalized payload/metadata digests, toolchains, proof results, iOS split and remote ref observations, CI head/run, approval boundary, credential-use flag, external-mutation flag, and exactly one next/recovery action.

**When to use:** candidate capture, approval display, pre-publication merge guard, postpublication comparison, and partial recovery.

**Rule:** recompute the current input digest before every irreversible child. Any mismatch yields the exact textual state `STALE`; incomplete/ambiguous evidence yields `BLOCKED`. The allowed values are quoted verbatim: `READY FOR APPROVAL`, `BLOCKED`, `STALE`, `PARTIAL`, `COMPLETE`. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-CONTEXT.md:137-147]

### Pattern 3: Two-Stage Distributable Proof

**Before approval:** build the core and all five companion tarballs with release-mode metadata, use Hex's tarball unpacker to extract each exact file, record its outer checksum and canonical metadata/payload manifest, point the generated host only at those unpacked payload directories, and assert packaged files and requirements independently. Hex's reference unpack API accepts a tarball file and returns checksums/metadata while extracting to a target path. [CITED: https://hex-core.hexdocs.pm/hex_tarball.html]

**After publication:** `mix hex.package fetch PACKAGE VERSION --unpack --output PATH`, reject any lock entry sourced from `path`, compare normalized public payload/metadata digests with the approved receipt, then rerun all five lanes and `mix crosswake.release.status --live`. The exact package fetch/unpack form is official. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Package.html]

### Pattern 4: Four Mirror Modes with Separate Authority

| Mode | Credentials | Mutation | Required result |
|------|-------------|----------|-----------------|
| 0.2.0 baseline | no | no | remote main and tag equal computed split; unreachable is `BLOCKED` |
| 0.2.1 candidate rehearsal | yes, trusted workflow only | no | exact split, current remote refs, `git push --dry-run --porcelain` succeeds |
| normal publication | yes | yes | remote main ancestor, immutable tag absent/exact, ordinary fast-forward main, atomic tag+main where supported |
| recovery | yes + separate explicit approval | possibly history-replacing | exact expected ref and explicit `--force-with-lease=<ref>:<expected>` |

Git documents `--dry-run` as doing everything except sending updates, `--porcelain` as machine-readable status, `--atomic` as all-or-none where supported, and `--force-with-lease=<ref>:<expect>` as allowing update only if the ref still has the expected value. [CITED: https://git-scm.com/docs/git-push.html]

### Pattern 5: Exact-Head Release-Sensitive CI

Keep fast fixtures and structural scanners in ordinary `Crosswake CI`; schedule the expensive candidate matrix only for release-sensitive inputs or the refreshed Release Please candidate. Existing CI already classifies a full-history base-to-merge diff and fails open scheduling to `full_proof` when checkout/object validation fails, with verbatim defaults `classification=full_proof` and `reason=checkout_or_object_validation_failed`. [VERIFIED: .github/workflows/crosswake-ci.yml:25-66]

The candidate artifact must contain the tested head/tree/base and workflow run ID; the later merge/publish workflow must verify approved head parentage and identical tree before tags or publications. Release Please's documented outputs include `release_created`, `sha`, `tag_name`, `version`, and `paths_released`, but those outputs do not replace Crosswake's PR head/base/tree receipt. [CITED: https://github.com/googleapis/release-please-action]

### Anti-Patterns to Avoid

- **Path-source masquerading as package proof:** the current script resolves Hex packages, but candidate mode must never silently fall back to repository paths; only unpacked artifact roots are allowed.
- **Predictable shared scratch directory:** current `clean_room_${PACKAGE}` plus `rm -rf` is not invocation-isolated. [VERIFIED: script/verify_companion_cleanroom.sh:331-348] Use exclusively created temporary roots and only remove roots created by that invocation.
- **One successful install:** current script runs `mix deps.get` once. [VERIFIED: script/verify_companion_cleanroom.sh:414-425] Run a second install in fresh dependency/build/lock state to expose hidden cache and undeclared-input dependence.
- **Handwritten host called Phoenix generation:** current harness invokes `mix new`, then patches in Phoenix and writes its router. [VERIFIED: script/verify_companion_cleanroom.sh:327-412,428-446] Use exact pinned `mix phx.new`.
- **Credential loaded during read-only baseline:** the existing mirror workflow loads `MIRROR_DEPLOY_KEY` before its verify/apply branch. [VERIFIED: .github/workflows/ios-mirror-backfill.yml:71-103] Split credential-free baseline from trusted candidate rehearsal/publication jobs.
- **Force-with-lease in normal publication:** current release workflow constructs `MIRROR_PUSH_ARGS=(--force-with-lease=...)` and uses it for the atomic main/tag push. [VERIFIED: .github/workflows/release-please.yml:444-496] Replace with fetch + ancestor guard + ordinary fast-forward; retain force-with-lease only in recovery.
- **Aggregate release gates:** exact `paths_released` and component outputs already exist. [VERIFIED: .github/workflows/release-please.yml:33-80] Never authorize core/native publication from aggregate `releases_created`.
- **Color-only or log-volume authority:** JSON is authoritative; terminal/Markdown are projections. Never retain raw tool logs in the receipt.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Hex archive creation/inspection | custom tar writer/parser | official Mix/Hex tasks and Hex `hex_tarball` unpack semantics | Preserves metadata/checksum/file-list behavior and avoids archive-format drift. |
| Phoenix host skeleton | manual Mix project plus router stub | exact pinned `phx_new 1.8.13` | Exercises the supported consumer topology and generator output. |
| Release proposal/version grouping | custom version calculator/controller | existing Release Please manifest and linked-versions group | Current config defines exactly `components: ["hex", "ios-core", "android-core"]`. [VERIFIED: release-please-config.json:6-11] |
| iOS split | copy files or alternate split engine | repository-standard `git subtree split` | Existing lineage and scripts use it. [VERIFIED: script/verify_ios_mirror_backfill.sh:179-197] |
| JSON serialization | shell string concatenation | ordinary Elixir maps + Jason + normalized fixture tests | Avoids escaping/order/privacy mistakes and matches existing automation patterns. |
| GraphQL pagination | one `last:100` fetch | GitHub cursor pagination with `pageInfo` | A one-page absence is not exact when another page may exist. [CITED: https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api] |
| Cross-registry transaction claim | rollback/controller abstraction | honest child states plus `PARTIAL` receipt | Hex, Git refs, and Maven publication are independent irreversible systems. |

**Key insight:** the custom work belongs in Crosswake's identity/evidence policy, not in reimplementing package formats, generators, versioning, or Git concurrency.

## Common Pitfalls

### Pitfall 1: Capturing a Mutable Candidate

**What goes wrong:** evidence names PR #57 or a branch but no longer matches its head/base/tree or artifacts.

**Why it happens:** Release Please refreshes its PR after protected-default changes.

**How to avoid:** treat the current PR as non-candidate; capture only after the five-blob landing and refresh, bind every input digest, and re-evaluate immediately before merge/publication.

**Warning signs:** historical green run, missing tree/base, or receipt created before the refreshed head.

### Pitfall 2: Proving Absence from a Truncated GraphQL Connection

**What goes wrong:** a deferral marker outside the last 100 comments is treated as absent.

**Why it happens:** the current query omits `pageInfo` beside `comments(last:100)`. [VERIFIED: script/check_phase167_pr_dispositions.py:1038-1046]

**How to avoid:** test >100-comment fixtures; fetch backward until `hasPreviousPage` is false, or return `BLOCKED` on any incomplete page.

**Warning signs:** node count 100, missing cursor/pageInfo, or a result without a completeness assertion.

### Pitfall 3: Digesting Nondeterministic Containers

**What goes wrong:** gzip/tar headers or volatile timestamps make equivalent payloads appear different.

**Why it happens:** whole-file archive hashes mix transport/container bytes with content identity.

**How to avoid:** retain the official outer checksum, and separately compute a canonical manifest over allowlisted metadata plus sorted unpacked paths, file bytes, and relevant modes; exclude scratch paths, timestamps, logs, and actor data.

**Warning signs:** repeated builds from the same tree produce a changed normalized digest, or receipt bytes change only because `generated_at` changed. Current release status includes `generated_at: DateTime.utc_now()`. [VERIFIED: lib/crosswake/release_status.ex:83-91]

### Pitfall 4: Letting Path Dependencies Hide Bad Published Metadata

**What goes wrong:** unpacked code compiles even though package metadata names the wrong version, omits files, or has an incompatible core floor.

**Why it happens:** local path dependency resolution does not exercise public Hex metadata.

**How to avoid:** assert metadata and packaged file list separately; require candidate core `Version.match?/2`; postpublish fetch exact public packages and assert lock entries are `:hex`, never `:path`.

**Warning signs:** no metadata receipt, no lock-source assertion, or package success with an empty/non-vacuous check missing.

### Pitfall 5: False Companion Success

**What goes wrong:** a lane compiles without proving its intended runtime contract.

**How to avoid:** preserve the exact D-12 five-lane matrix and add negative controls. Current reusable canaries include Threadline's telemetry/Plug/Ledger plus sibling absence, Chimeway's ten-event telemetry assertion, and Rindle's non-empty contracts vocabulary. [VERIFIED: script/verify_companion_cleanroom.sh:472-538,570-581,623-667]

**Warning signs:** unconditional `:ok`, no engine-presence check, no auth result, no absence assertion, or Threadline registered as a companion.

### Pitfall 6: Rehearsing the Wrong Mirror Operation

**What goes wrong:** a tag-only dry-run passes but the eventual main+tag operation fails, or a local credentialless check claims write authority.

**How to avoid:** candidate rehearsal uses the real mirror, exact split and complete intended refspec with `--dry-run --porcelain`; receipt says whether credentials were exercised. Normal publish re-fetches refs and repeats guards.

**Warning signs:** HTTPS read remote, no SSH authority, dry-run output discarded, or `WRITE AUTHORITY NOT CHECKED` mapped to readiness.

### Pitfall 7: Partial Publication Reported as Failure-with-No-State

**What goes wrong:** one coordinate is public but the rollup only says “failed,” inviting an unsafe retry or attempted replacement.

**How to avoid:** persist exact successes and failed child as `PARTIAL`; downstream work stops, and recovery begins from immutable exact refs.

**Warning signs:** retry-all button, moving tags, direct package replacement, or no coordinate inventory.

### Pitfall 8: Overloading the Existing Read-Only Status Command

**What goes wrong:** `mix crosswake.release.status` starts mutating or producing candidate authority, breaking its deterministic local-status contract.

**How to avoid:** compose/reuse checks but keep the new fixed-purpose candidate task separate. Existing docs explicitly say status “only reads checked-in files” by default. [VERIFIED: lib/mix/tasks/crosswake.release.status.ex:6-18]

## Code Examples

### Exact Package Build and Public Fetch

```bash
# Candidate source tree: build the distributable and keep the tarball.
CROSSWAKE_RELEASE=1 MIX_ENV=prod mix hex.build --output "$artifact_tar"

# Exercise Hex's real non-publishing checks with isolated, non-authorizing config.
bash script/verify_hex_publish_dry_run.sh

# Postpublication: fetch and unpack the exact public version.
mix hex.package fetch crosswake 0.2.1 --unpack --output "$public_unpack_root"
```

`mix hex.build --output`, publish `--dry-run`, and exact package fetch/unpack are official task forms. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html] [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Package.html]

### Candidate Command Boundary

```elixir
def run(args) do
  # Parse only: --version, --ref, --output-dir.
  # Require version == "0.2.1" and ref to match 40 lowercase hex characters.
  # Delegate all observation/evaluation/serialization to an ordinary module.
  result = Crosswake.ReleaseCandidate.run!(parsed_options)
  Mix.shell().info(result.terminal)
end
```

The literal command version `0.2.1` and 40-character-ref contract come from D-26/D-22; the internal module name is discretionary. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-CONTEXT.md:110-114,126-133]

### Cursor-Complete Comment Query

```graphql
comments(last: 100, before: $before) {
  nodes { body }
  pageInfo { hasPreviousPage startCursor }
  totalCount
}
```

Repeat with `before: startCursor` while `hasPreviousPage` is true, and reject null/non-advancing cursors. This uses GitHub's official cursor-pagination contract. [CITED: https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api]

### Normal Mirror Guard

```bash
git fetch mirror refs/heads/main refs/tags/v0.2.1
git merge-base --is-ancestor "$mirror_main" "$split_sha"
git push --dry-run --porcelain --atomic mirror \
  "$split_sha:refs/heads/main" "$split_sha:refs/tags/v0.2.1"
# After the one approval and identical re-check, perform the same push without --dry-run.
```

Do not add any force option in normal mode. Git's official documentation defines dry-run, porcelain, atomic, fast-forward, and force-with-lease semantics. [CITED: https://git-scm.com/docs/git-push.html]

## State of the Art

| Old / Current Approach | Phase 168 Approach | Impact |
|------------------------|--------------------|--------|
| public-only companion proof after individual companion publish | candidate-local unpacked artifacts before approval plus exact public proof after core publication | Separates reversible readiness from public-resolution truth. |
| `mix new` host and patched Phoenix deps | pinned actual `phx_new 1.8.13` minimal host | Tests a supported Phoenix consumer topology. |
| one shared predictable clean-room directory and one install | unique root and isolated Mix/Hex/deps/build/lock state for two installs | Detects hidden cache/state dependencies and avoids cross-lane deletion/collision. |
| release-tag-bound mirror backfill | pre-tag exact-commit candidate mode plus baseline/publish/recovery modes | Proves write authority before approval and removes recovery force from normal publication. |
| native-only `none/complete/partial` shell rollup | candidate receipt with exact five textual states and coordinate-level partial preservation | Gives one machine authority across preapproval and postapproval phases. Current rollup derives native state in shell. [VERIFIED: .github/workflows/release-please.yml:642-695] |
| one-page GraphQL comment query | cursor-complete pagination or `BLOCKED` | Makes absence evidence authoritative. |

**Deprecated/outdated:**

- Normal-path `--force-with-lease` for mirror main is deprecated by D-24/D-25; preserve it only as separately invoked recovery.
- Documentation that calls the 0.2.0 mirror tag “missing” is stale under D-21 and must be reconciled with the verified idempotent baseline.
- Candidate authority based on release PR number, branch, existing tag, path source, or historical run is invalid under D-03/D-04/D-07.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Recommendations within the agent's discretion are identified as recommendations; external behavior is cited from official documentation, and in-repo values are quoted from opened source files. | — | — |

## Open Questions (RESOLVED)

1. **What is the refreshed Release Please #57 identity?**
   - What we know: D-03 explicitly says the current head is not a candidate.
   - What's unclear: the future head/tree/base/run cannot exist until the five-blob landing reaches protected default and Release Please refreshes the proposal.
   - Recommendation: make capture an execution-time gate, not a planning constant; refuse readiness until exact values are observed and receipt-bound.
   - **RESOLVED:** Preserve those values as execution-time observations. Plan 168-08 captures them only after the D-01 landing and all reversible implementation reach protected default; missing or ambiguous refresh evidence is `BLOCKED`, and any later identity drift is `STALE` and requires complete recapture per D-03/D-04. No planning-time PR identity is authorized.

2. **Can the real mirror remote perform atomic multi-ref push?**
   - What we know: Git's `--atomic` fails rather than partially updating when the server cannot support it. [CITED: https://git-scm.com/docs/git-push.html]
   - What's unclear: capability is a live remote property and must be demonstrated by the trusted candidate dry-run.
   - Recommendation: require the exact atomic dry-run for `READY FOR APPROVAL`; an unsupported result is `BLOCKED` and requires an explicit plan change/recapture, not a silent non-atomic fallback.
   - **RESOLVED:** Keep capability as a trusted execution-time observation and require the exact credentialed atomic multi-ref dry-run before `READY FOR APPROVAL`. Unsupported, denied, ambiguous, or changed capability is `BLOCKED`; execution must stop for an explicit plan change and full recapture, with no silent non-atomic fallback, per D-22/D-24 and Plan 168-05.

3. **Where should volatile workflow metadata live?**
   - What we know: D-28 requires run ID, while D-28/D-30 also require deterministic digest-bound evidence.
   - Recommendation: serialize volatile run metadata in a clearly separate receipt envelope; compute content/proof digests only over canonical stable fields and test that rerendering does not alter them.
   - **RESOLVED:** Store run ID and other allowlisted volatile workflow metadata in a dedicated execution envelope within the authoritative receipt. Bind that envelope through the final receipt identity, but exclude it from reusable content/proof sub-digests, which cover only canonical stable fields; identical inputs must rerender byte-for-byte while a changed run identity yields a newly bound receipt per D-28/D-30 and Plans 168-02/168-08.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Git / git-subtree | mirror split | ✓ | Git `2.41.0`; repository already invokes stock `git subtree` | trusted Ubuntu workflow with full history |
| `gh` | exact PR/CI observation | ✓ | `2.95.0` | GitHub GraphQL via authenticated workflow |
| Node/npm | Phase 167 and repository fixture tests | ✓ | `22.14.0` / `11.1.0` | CI pinned `.tool-versions` |
| Python | existing closeout validator | ✓ | `3.14.4` | CI system Python |
| Swift | local iOS build probes | ✓ | Swift `6.3.3` | macOS CI |
| Java 17 / Gradle | Android coordinate build/proof | not usable from this shell | `/usr/bin/java` exists but no local version was established | existing Actions `setup-java` at Java `17` [VERIFIED: .github/workflows/release-please.yml:511-526] |
| Erlang/Elixir/Mix | main candidate evaluator and tests | ✗ exact local runtime | `.tool-versions` asks for Erlang `27.3`; local asdf reports installed `27.3.4.15` but no exact configured `erl` | use repository setup action/clean checkout, or install exact pinned toolchain before local Mix work |
| `actionlint` | workflow validation | ✓ | `1.7.12` | actionlint CI stage |
| `jq` / `curl` | bounded adapter parsing/probes | ✓ | `1.7.1` / `8.7.1` | Python/Elixir JSON and HTTP seams |
| Mirror deploy key | candidate authority rehearsal/publication | intentionally unavailable locally | — | trusted GitHub workflow only; local result must say `WRITE AUTHORITY NOT CHECKED` |

Environment observations above are from read-only local probes on 2026-09-12. [VERIFIED: local probe 2026-09-12] The Mix falsification output was: `No version is set for command erl` after listing available Erlang versions, so local Mix execution is not a valid phase gate until the exact repository runtime is restored. [VERIFIED: local `mix --version` probe 2026-09-12]

**Missing dependencies with no fallback:** none in the trusted CI target; locally, exact Erlang/Elixir/Mix blocks Mix tests.

**Missing dependencies with fallback:** Java/Gradle and mirror credentials are intentionally supplied only by existing trusted workflows.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on pinned Elixir, Node built-in test runner, shell syntax checks, `actionlint`, existing structural release scanner |
| Config file | `mix.exs`, `test/test_helper.exs`, `.github/workflows/crosswake-ci.yml` |
| Quick run command | `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs` |
| Full suite command | `bash script/verify_repository.sh --all` |

The repository verification facade's accepted commands are quoted verbatim: `--all`, `--stage <purpose-id>`, and `--self-test`. [VERIFIED: script/verify_repository.sh:8-23]

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | five candidate-local and postpublic companion profiles, twice-installed, non-vacuous, registered/doctored correctly | integration + fixture | `mix test test/crosswake/release_candidate/cleanroom_test.exs` | ❌ Wave 0 |
| REL-02 | baseline/candidate/publish/recovery mirror modes; credential absence/denial, immutable conflict, ancestry and atomic dry-run | unit + script integration | `mix test test/crosswake/release_candidate/mirror_test.exs` | ❌ Wave 0 |
| REL-03 | linked coordinate tuple, companion independence, package file/floor metadata, Swift/Gradle coordinate drift | unit + structural | `mix test test/crosswake/release_candidate/coordinate_test.exs && elixir script/check_release_workflow_integrity.exs` | ❌ Wave 0 (new candidate test); scanner exists |
| REL-04 | exact ref/head/tree/base/config/artifact/CI binding; any mutation yields `STALE`; receipt deterministic/privacy-safe | unit + integration | `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs` | ❌ Wave 0 |
| REL-05 | no mutation preapproval, one approval boundary, parent/tree guard, ordered child graph, honest `PARTIAL` | unit + workflow structural | `actionlint .github/workflows/release-please.yml .github/workflows/ios-mirror-backfill.yml .github/workflows/crosswake-ci.yml && elixir script/check_release_workflow_integrity.exs` | Existing tools; ❌ new fixtures |
| D-01/D-02 prerequisite | exact five blobs and cursor-complete PR comment authority | Node/Python fixture | `node --test test/js/phase167_pr_dispositions.test.mjs` | ✅ but pagination fixtures missing and current local suite has two environment failures |

### Sampling Rate

- **Per task commit:** run the narrow ExUnit/Node/script test for the touched seam plus `bash -n` or `actionlint` when applicable.
- **Per wave merge:** `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs`, `node --test test/js/phase167_pr_dispositions.test.mjs`, `elixir script/check_release_workflow_integrity.exs`, and relevant shell/workflow linters.
- **Phase gate:** `bash script/verify_repository.sh --all`, exact-head candidate workflow green, deterministic receipt `READY FOR APPROVAL`, and credentialed mirror dry-run recorded; no public state changed.

### Wave 0 Gaps

- [ ] Restore the exact pinned Erlang/Elixir runtime in the execution environment; local `mix --version` currently fails before tests.
- [ ] Restore/regenerate the Phase 167 runtime authority fixture expected at `.planning/workstreams/quality-ratchet-release/milestone.lock` or update its canonical path before landing; the current Node suite passes 25/27 tests and its two failures are both `ENOENT` copying that missing path. [VERIFIED: test/js/phase167_pr_dispositions.test.mjs:117-133,269-284] [VERIFIED: local Node test run 2026-09-12]
- [ ] Add >100-comment, multi-page, missing/invalid/non-advancing cursor, and page-fetch failure fixtures before changing the live query.
- [ ] Add canonical candidate receipt fixtures and mutation table covering every D-04 identity field plus privacy canaries.
- [ ] Add candidate-local Hex tarball fixtures with file-list, metadata, checksum, dependency-floor, path escape, and public-vs-candidate digest controls.
- [ ] Add four-mode mirror fixtures including 0.2.0 exact baseline, unreachable remote, mismatched immutable tag, non-ancestor main, dry-run permission failure, unsupported atomic push, and recovery-only lease.
- [ ] Add five clean-room profile fixtures with two-install isolation and at least one deliberate negative control per lane.
- [ ] Extend CI leaf/ownership manifests and release workflow structural scanner rather than creating a separate workflow family.

Research-time checks: `actionlint` passed for the three relevant workflows and `bash -n` passed for the four relevant release scripts. [VERIFIED: local probes 2026-09-12]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes, only for external write credentials | GitHub secret injection into the two trusted steps; never serialize or log secret values |
| V3 Session Management | no | no user session exists in local release orchestration |
| V4 Access Control | yes | protected-default merge approval, exact-head/tree guard, least-privilege `contents: read` jobs, one-repository deploy key |
| V5 Input Validation | yes | strict `0.2.1`, lowercase 40-SHA, allowlisted paths/packages/coordinates/states, canonical receipt schema, reject unknown fields where authority-sensitive |
| V6 Cryptography | yes | use SSH/Git/Hex/Maven provider tooling and SHA-256 digests; never implement cryptographic signing or claim SLSA |

This is an applicability mapping for the release tooling, not an ASVS compliance claim. Security enforcement is enabled because `.planning/config.json` does not explicitly set it to false; Nyquist validation is explicitly `true`. [VERIFIED: .planning/config.json:1-15]

### Known Threat Patterns for Release Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| TOCTOU between candidate proof and merge | Tampering / Elevation | bind head/base/tree/artifacts/config/run, exact-head merge, verify merge parent and identical tree before children |
| Untrusted PR code reaches publish credentials | Elevation / Information Disclosure | credentials only after merge/approval in trusted jobs; no secrets in PR candidate code execution |
| Truncated GitHub query produces false absence | Tampering / Repudiation | cursor completeness or `BLOCKED`; fixture >100 comments |
| Malicious/path-escaping package contents | Tampering | official Hex unpacker limits plus safe destination, canonical file allowlist, reject symlink/path escapes |
| Credential leak in logs/receipt | Information Disclosure | allowlisted low-cardinality fields, non-echoing errors, no actors/private URLs/raw logs/tokens |
| Mirror ref race or history replacement | Tampering | fetch immediately before push, ancestry check, ordinary fast-forward, atomic main+tag, force-with-lease only recovery |
| Partial registry publication hidden as all-or-nothing | Repudiation | durable `PARTIAL` receipt with exact successful coordinates and failed child |
| Unbounded API/registry retry | Denial of Service | bounded attempts/timeouts; preserve unavailable vs missing. Existing live probes use exactly `3` attempts and `200` ms retry sleep. [VERIFIED: lib/crosswake/release_status.ex:17-21,928-959] |

Privacy tests should inject canaries into every untrusted observation and assert that terminal, Markdown, JSON, GitHub Summary, failure output, and uploaded artifacts do not echo them. The existing Phase 167 suite already asserts no private canary and no `http(s)` URL in diagnostics. [VERIFIED: test/js/phase167_pr_dispositions.test.mjs:252-267]

## Planning Sequence Recommendation

1. **Wave 0 — test and environment foundations:** exact toolchain, missing Phase 167 runtime authority, pagination fixtures, receipt fixtures, safe command/adapters.
2. **Wave 1 — Phase 167 authority landing:** prove the exact five path/blob pairs, land only those through protected default, record receipt, and fix comment pagination before using live dispositions.
3. **Wave 2 — candidate domain/CLI/schema:** implement immutable identity graph, five-state evaluator, privacy allowlist, deterministic JSON/Markdown/terminal projections, `NO_COLOR`, and thin command.
4. **Wave 3 — package artifact pipeline:** core + five companion dry-run/build, exact tarball unpack/checksum/metadata/file manifests, normalized digests, coordinate/floor drift guards.
5. **Wave 4 — generated-host matrix:** pin/install `phx_new`, make each lane invocation-unique and fully isolated, use only unpacked payloads, run two installs, preserve five positive/negative profiles and doctor/runtime/router/public seams.
6. **Wave 5 — mirror modes:** exact 0.2.0 baseline, 0.2.1 credentialed candidate rehearsal, fast-forward-only atomic normal publication, separately approved force-with-lease recovery; load key only in the two credentialed paths.
7. **Wave 6 — CI and postapproval graph:** integrate release-sensitive candidate execution into existing CI/workflow; exact-head receipt artifact; merge parent/tree guard; linked children; public artifact re-fetch/digest matrix/status; durable partial rollup.
8. **Wave 7 — docs and candidate capture:** reconcile runbook/status/docs, verify no adopter/Android/deferred scope drift, wait for refreshed #57, capture exact candidate, run complete proof, and present the one merge approval only after `READY FOR APPROVAL`.

Do not put the maintainer approval in an earlier wave: all credential rehearsal and reversible proof must precede it. Do not treat the phase as permission to execute publication automatically; the success criterion is to present the one irreversible approval boundary. [VERIFIED: .planning/workstreams/quality-ratchet-release/ROADMAP.md:217-223]

## Sources

### Primary (HIGH confidence in-repo)

- `168-CONTEXT.md` — locked candidate, package, clean-room, approval, mirror, evidence, state, privacy, and scope decisions.
- `AGENTS.md` — project thesis, privacy boundary, Android freeze, workstream, and verification policy.
- `REQUIREMENTS.md` / `ROADMAP.md` — REL-01 through REL-05 and success criteria.
- `phase167-closeout-resolution.json` — the owner is quoted verbatim as `phase_168_first_reversible_landing`; the five paths are quoted verbatim as `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json`, `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-08-SUMMARY.md`, `.planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/167-VERIFICATION.md`, `.planning/workstreams/quality-ratchet-release/ROADMAP.md`, and `.planning/workstreams/quality-ratchet-release/STATE.md`. [VERIFIED: .planning/workstreams/quality-ratchet-release/phases/167-documentation-and-pull-request-reconciliation/evidence/phase167-closeout-resolution.json:192-201]
- `release-please-config.json`, `.release-please-manifest.json`, `mix.exs`, companion `mix.exs`, iOS `Package.swift`, and Android `build.gradle.kts` — current coordinate and package source truth.
- release/status/clean-room/mirror scripts and workflows — reusable seams and identified deltas.
- local validation probes on 2026-09-12 — actionlint/shell pass, Phase 167 Node suite 25/27 with two missing-runtime-file failures, and local Mix runtime failure.
- No `.codex/skills/` or `.agents/skills/` project-local skill directory was present; no project skill adds a phase-specific implementation convention. [VERIFIED: local filesystem probe 2026-09-12]

### Secondary (MEDIUM confidence, official documentation)

- https://hex.hexdocs.pm/Mix.Tasks.Hex.Build.html — package build/unpack options.
- https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html — dry-run behavior.
- https://hex.hexdocs.pm/Mix.Tasks.Hex.Package.html — exact package fetch/unpack.
- https://hex-core.hexdocs.pm/hex_tarball.html — reference tarball unpack/checksum/metadata semantics.
- https://mix.hexdocs.pm/Mix.Tasks.Archive.Install.html — exact-version archive installation.
- https://phx-new.hexdocs.pm/Mix.Tasks.Phx.New.html — generator and minimal-host switches.
- https://git-scm.com/docs/git-push.html — dry-run, porcelain, atomic, fast-forward, and force-with-lease semantics.
- https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api — cursor pagination and connection limits.
- https://github.com/googleapis/release-please-action — manifest outputs and release action behavior.
- https://hex.pm/api/packages/phx_new — official package identity, version, publication date, source, and registry usage.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH for checked-in versions and MEDIUM for current external documentation/registry metadata.
- Architecture: HIGH because it follows locked D-01 through D-31 and opened implementation seams.
- Pitfalls: HIGH for observed code deltas; MEDIUM for container-normalization guidance grounded in official Hex APIs.

**Research date:** 2026-09-12
**Valid until:** 2026-10-12 for repository architecture; re-check external versions, candidate PR identity, registry state, and mirror refs at execution time.
