# Phase 50: Doctor Publish and Readiness Checks - Context

**Gathered:** 2026-05-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend `mix crosswake.doctor` into release/support readiness without widening
Crosswake's support claims.

**Delivers:**
- `mix crosswake.doctor --check-publish` as the operator-facing release/support
  readiness check.
- Actionable findings for Hex metadata, changelog state, docs/support parity,
  proof posture, verification-required surfaces, companion dependency health,
  provider-adapter readiness, notification-token readiness, auth/session
  predicate readiness, and native shell verification gaps.
- Machine-readable and human-readable output that keeps support status, proof
  class, severity, rebuild posture, deferred scope, and remediation visible.
- Findings that fail closed when readiness is missing and never imply StoreKit,
  Play Billing, full Sigra machinery, Chimeway delivery, or standalone shell
  packages have shipped.

**Satisfies:** DIAG-01 and DIAG-02.

**In scope:**
- Add `--check-publish` to the existing doctor task rather than creating a new
  release-readiness command.
- Compose publish/readiness findings from local package/release truth, canonical
  support matrix truth, and Phase 49 `Crosswake.OperatorInspection` route truth.
- Add stable JSON/human output for publish readiness and readiness findings.
- Add focused tests proving missing readiness does not silently pass as
  supported.

**Out of scope:**
- StoreKit or Play Billing adapters.
- Full Sigra handoff, passkey, OAuth, ceremony, refresh-token, or native auth UI
  machinery.
- Chimeway delivery integration or push-delivery guarantees.
- Standalone public native shell packages.
- Phase 51 support-matrix/rebuild guide expansion, except where Phase 50 needs
  code hooks or docs anchors for its findings.
- Phase 52 full operator proof/docs-contract lane, except focused Phase 50 tests
  needed to make the new checks credible.

</domain>

<decisions>
## Implementation Decisions

### 1. Command Boundary - LOCKED
- **D-01:** Keep the public command as `mix crosswake.doctor --check-publish`.
  Do not create `mix crosswake.publish_check`, `mix crosswake.readiness`, or a
  second release command in Phase 50.
- **D-02:** `doctor` remains findings-first diagnostics. `crosswake.inspect`
  remains inventory/readiness-first. Phase 50 may consume
  `Crosswake.OperatorInspection`, but it must not move route inventory into
  doctor as the primary operator surface.
- **D-03:** `--check-publish` enables additional release/support readiness
  checks. Normal `mix crosswake.doctor` keeps its current install/runtime
  diagnostic behavior unless the flag is present.
- **D-04:** Use strict `OptionParser` style matching the existing doctor and
  inspect tasks. Planner may add `--fail-on error|warning|advisory` if scoped,
  defaulting to `error`.

### 2. Publish Check Scope - LOCKED
- **D-05:** Use a hybrid check model. Local contract checks are authoritative
  and deterministic; network/provider/environment-sensitive checks, if any, are
  explicitly advisory.
- **D-06:** Local publish readiness should check at least:
  - package metadata and package file allowlist from `mix.exs`;
  - README, changelog, guide, source URL, and docs link hygiene;
  - `CHANGELOG.md` distinction between `[Unreleased]` and published Hex
    versions;
  - release/support policy truth from `Crosswake.SupportMatrix`;
  - proof posture and verification-required surfaces already known locally;
  - public docs/support claims that would be false if published as-is.
- **D-07:** Remote Hex truth is useful but must not be a merge-blocking default
  unless the check is deterministic in the target lane. If implemented in Phase
  50, mark remote Hex/public URL checks as advisory or require an explicit flag.
- **D-08:** Publish readiness should distinguish `published Hex truth`,
  `unreleased local support truth`, and `planning milestone truth`. Planning
  milestones are not installable SemVer releases.

### 3. Readiness Finding Derivation - LOCKED
- **D-09:** Use a layered derivation:
  `Crosswake.OperatorInspection` for route-authoritative inventory,
  `Crosswake.SupportMatrix` for canonical support/rebuild/proof vocabulary, and
  doctor-specific publish/environment checks for release readiness.
- **D-10:** Do not duplicate support, proof, denial, auth, notification, or
  rebuild vocabularies by hand when canonical accessors already exist.
- **D-11:** Required readiness categories:
  - `publish_parity`;
  - `companion_dependency_health`;
  - `provider_adapter_readiness`;
  - `notification_token_readiness`;
  - `auth_session_predicate_readiness`;
  - `native_shell_verification_gap`;
  - `docs_support_parity`;
  - `proof_posture`.
- **D-12:** `error` means a false public claim, fail-closed contract break, or
  missing prerequisite that would make a supported/published surface unsafe.
  `warning` means verification-required or stale proof posture that needs action
  before support broadens. `advisory` means deferred or environment-sensitive
  evidence that is honestly labeled and non-blocking by default.
- **D-13:** Never treat "no finding" as "supported." Positive readiness must be
  explicit in a check result or derived from canonical support/inspection truth.

### 4. Machine And Human Output - LOCKED
- **D-14:** Extend doctor JSON with a versioned `publish_readiness` section when
  `--check-publish` is enabled. Do not make human prose the machine API.
- **D-15:** Recommended JSON shape:
  - `schema_version`;
  - existing `status`, `support`, `shells`, `bridge`, `offline`,
    `commerce_summary`, and `findings`;
  - `publish_readiness.status` as `ready | not_ready`;
  - `publish_readiness.summary` with counts for errors, warnings, advisories,
    and verification-required checks;
  - `publish_readiness.checks[]` with stable id/code, severity, result
    (`pass | fail | not_applicable`), blocking boolean, message, hint,
    docs reference, proof class, rebuild requirement, claim scope, and details.
- **D-16:** Human output should add a concise `Publish readiness` section with
  failing/blocking checks first, followed by warnings/advisories and concrete
  remediation hints. Avoid a single green headline when any deferred or
  verification-required surface exists.
- **D-17:** Default exit behavior should stay unsurprising: doctor exits
  non-zero for `:error` findings. With `--check-publish`, publish-readiness
  failures at or above the configured threshold also exit non-zero.
- **D-18:** GitHub annotations or job summaries are useful follow-on DX if
  scoped, but JSON remains canonical. Annotation output must be a rendering of
  the same checks, not a second diagnostic contract.

### 5. Remediation And Guardrails - LOCKED
- **D-19:** Every readiness finding should include stable code/id, severity,
  subject, route id or surface when applicable, remediation, guide anchor,
  proof class, rebuild requirement, and claim scope.
- **D-20:** Codes become public contract once shipped. Prefer a stable prefix
  such as `diag.publish.*`, `diag.provider.*`, `diag.auth.*`,
  `diag.notification.*`, `diag.shell.*`, and `diag.docs.*`; exact names are
  planner discretion.
- **D-21:** Remediation language must use bounded Crosswake vocabulary:
  `supported`, `verification_required`, `unsupported`, `merge_blocking`,
  `advisory`, and `rebuild_required`. Do not introduce casual `green`,
  `healthy`, or `production-ready` labels that hide caveats.
- **D-22:** Guide links should point only to canonical support docs:
  `guides/support_matrix.md`, `guides/compatibility.md`,
  `guides/companions.md`, `guides/commerce.md`, `guides/native_shell.md`,
  `guides/capabilities.md`, `guides/install.md`, and `CHANGELOG.md`.
- **D-23:** Findings must explicitly stamp deferred scopes:
  StoreKit/Play Billing provider adapters are not shipped in v3.6; Sigra remains
  contract-only until v3.8; notification-token readiness is not Chimeway
  delivery; standalone shell packages are not public support surfaces.
- **D-24:** Do not collapse advisory proof into supported status. Do not promote
  advisory provider/device/storefront proof to merge-blocking without explicit
  promotion criteria in roadmap/support truth.

### 6. Ecosystem Lessons To Preserve - LOCKED
- **D-25:** Import the Phoenix/Mix lesson: diagnostics should be boring to run,
  deterministic by default, explicit about options, and useful in local
  contributor workflows.
- **D-26:** Import the Django checks lesson: stable check ids, severity, hints,
  and object/surface references make diagnostics actionable without turning
  prose into API.
- **D-27:** Import the Terraform lesson: human output and JSON output serve
  different audiences. JSON must be intentional and versioned.
- **D-28:** Import the Kubernetes conditions lesson carefully: condition-like
  records are useful, but Crosswake must keep raw support/proof/rebuild/auth/
  notification/provider axes visible so a boolean does not masquerade as global
  health.
- **D-29:** Import npm audit and CI annotation lessons: thresholding and PR
  visibility help DX, but noisy advisory failures erode trust. Merge-blocking
  thresholds should default to real errors.

### the agent's Discretion
- Exact internal module layout is planner discretion. Strong default: add a
  small publish/readiness module under `Crosswake.Doctor` instead of expanding
  the existing `doctor.ex` monolith substantially.
- Exact check code names are planner discretion if they are stable, grouped, and
  documented through tests.
- Exact remote Hex behavior is planner discretion. Bias toward local
  deterministic checks in the merge-blocking path and advisory remote checks
  only when they are resilient.
- Exact `--fail-on` implementation is planner discretion. If it would distract
  from DIAG-01/DIAG-02, capture it as a Phase 52 or release-lane follow-up.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active requirements
- `.planning/ROADMAP.md` section "Phase 50: Doctor Publish and Readiness Checks" - authoritative phase goal and success criteria.
- `.planning/REQUIREMENTS.md` section "Doctor Readiness" - DIAG-01 and DIAG-02.
- `.planning/PROJECT.md` - Crosswake thesis, v3.6 scope, deferred provider/auth/notification/shell claims, and support-truth guardrails.
- `.planning/STATE.md` - current state and deferred items; note that it currently says milestone complete after Phase 49, conflicting with roadmap/requirements that keep Phases 50-53 pending.
- `.planning/MILESTONE-ARC.md` - v3.6 operator truth rationale and future dependency queue.

### Prior phase decisions
- `.planning/phases/49-operator-inspection-contract/49-CONTEXT.md` - route-authoritative inspection contract, doctor-vs-inspection boundary, JSON/human split, and readiness vocabulary.
- `.planning/phases/48-strategic-signal-and-milestone-memory/48-CONTEXT.md` - closeout/release/support truth as product surface.
- `.planning/milestones/v3.5-phases/47-companion-arc-guide-and-milestone-proof/47-CONTEXT.md` - companion guide parity, optional dependency proof, and deferred companion non-goals.
- `.planning/milestones/v3.5-phases/46-sigra-auth-contract-only-slice/46-CONTEXT.md` - Sigra contract-only auth predicates and full-machinery defers.
- `.planning/milestones/v3.5-phases/41-gating-doctor-and-support-matrix-truth/41-CONTEXT.md` - route gating doctor/support truth.
- `.planning/milestones/v3.2-phases/23-commerce-support-and-proof-closure/23-CONTEXT.md` - commerce proof posture, advisory provider proof, and support matrix truth.

### Existing code surfaces
- `lib/mix/tasks/crosswake.doctor.ex` - existing doctor Mix task option parsing, formatter dispatch, and failure behavior.
- `lib/mix/tasks/crosswake.inspect.ex` - Phase 49 inspect task boundary and CLI pattern.
- `lib/crosswake/doctor/doctor.ex` - current diagnostic pipeline and report struct.
- `lib/crosswake/doctor/check.ex` - existing severity/check/hint/details finding struct.
- `lib/crosswake/doctor/formatter.ex` - current human output style.
- `lib/crosswake/doctor/json_formatter.ex` - current stable JSON formatter and detail handling.
- `lib/crosswake/operator_inspection.ex` - route-authoritative inspection source for readiness axes.
- `lib/crosswake/operator_inspection/types.ex` - typed inspection document/route schema.
- `lib/crosswake/operator_inspection/json_formatter.ex` - machine output precedent from Phase 49.
- `lib/crosswake/support_matrix/support_matrix.ex` - canonical support, proof, release, package, change-class, auth, commerce, and gating truth.
- `mix.exs` - package metadata, source/docs links, files allowlist, Hex package configuration.
- `CHANGELOG.md` - published-vs-unreleased release truth.
- `.github/workflows/hex-publish.yml` - current publish dry-run/manual recovery posture.

### Guides and public support language
- `README.md` - public first-run and proof positioning.
- `guides/install.md` - install path, doctor proof entry, package surface, and rebuild guidance.
- `guides/support_matrix.md` - support statuses, proof statuses, package surfaces, release policy, and change classes.
- `guides/compatibility.md` - compatibility axes and runtime-line language.
- `guides/native_shell.md` - native shell proof/rebuild guidance.
- `guides/companions.md` - companion dependency health, Rulestead/Rindle/Sigra boundaries, and proof posture.
- `guides/commerce.md` - provider-neutral commerce, reviewer guidance, proof class, and provider-adapter defers.
- `guides/capabilities.md` - notification-token readiness, bounded bridge, backend seams, and deferred surfaces.

### Prompt corpus and research memory
- `prompts/crosswake-brand-book.md` - route-boundary language and anti-hype support-claim guardrails.
- `prompts/crosswake-elixir-oss-dna.md` - install truth, proof lanes, release truth, and diagnostics as product surface.
- `prompts/crosswake-integrations-and-companions.md` - companion classifications and deferred integration sequencing.
- `prompts/crosswake-research-synthesis.md` - stable architecture thesis and anti-patterns.
- `prompts/elixir-mobile-oss-lib-deep-research.md` - OSS library release, proof, and support posture lessons.
- `prompts/elixir-mobile-oss-refined-plan-deep-research.md` - route/navigation/capability/command plane lessons and typed boundary discipline.
- `prompts/elixir-mobile-architecture-apptypes-stresstest-deep-research.md` - runtime ladder and mobile app pressure context.
- `prompts/new elixir oss lib prompt.txt` - maintainer preference for research-backed, DX-heavy OSS library planning.

### External precedent surfaced by advisor research
- `https://hexdocs.pm/mix/main/Mix.Task.html` - idiomatic Mix task behavior.
- `https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html` - Hex publish/dry-run expectations.
- `https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html` - docs generation/publish surface expectations.
- `https://keepachangelog.com/en/1.1.0/` - changelog structure.
- `https://semver.org/` - SemVer release axis.
- `https://docs.djangoproject.com/en/stable/topics/checks/` - stable diagnostic ids, severity, hints, and object references.
- `https://developer.hashicorp.com/terraform/internals/json-format` - machine-readable JSON versioning.
- `https://developer.hashicorp.com/terraform/cli/commands/show` - human/machine output split.
- `https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions` - condition records and health footguns.
- `https://docs.npmjs.com/about-audit-reports` - severity thresholds and audit-report lessons.
- `https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions` - CI annotation output precedent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Crosswake.Doctor` already owns `--router`, `--format`, `--install-manifest`, and `--native-checks`. Add `--check-publish` here to preserve user expectations.
- `Crosswake.Doctor.Report` already carries `status`, support, shell, bridge, offline, commerce summary, and findings. Add publish readiness as an optional report field or sidecar when the flag is enabled.
- `Crosswake.Doctor.Check` already models `severity`, `code`, `message`, `hint`, `check`, and `details`; Phase 50 should extend details conventions before inventing a new finding struct.
- `Crosswake.Doctor.JSONFormatter` already preserves atom/string details carefully and keeps false values. Reuse that discipline for publish readiness checks.
- `Crosswake.OperatorInspection.inspect/1` already projects route-level support, proof, rebuild, auth, notification, companion, and denial axes.
- `Crosswake.SupportMatrix` already exports support statuses, commerce corridor proof/rebuild truth, auth contract truth, package surfaces, release boundaries, and change classes.
- `CHANGELOG.md` already separates `[Unreleased]` from `[0.1.0]` Hex release truth.

### Established Patterns
- Crosswake uses deterministic local proof as merge-blocking and provider/device/storefront checks as advisory until promotion criteria are explicit.
- Public support truth is intentionally narrow and docs-contract locked where possible.
- Runtime/operator surfaces prefer typed structs and renderers over ad hoc prose parsing.
- Human output is for operators; JSON output is the machine contract.
- Optional dependency health should fail closed when a companion is enabled but missing required optional packages.

### Integration Points
- Add a publish/readiness check path inside doctor run options and formatter dispatch.
- Reuse `Crosswake.OperatorInspection` to avoid duplicating route readiness logic.
- Reuse `SupportMatrix` for proof class, rebuild, package surface, release boundary, and change-class language.
- Add focused tests near existing doctor tests for `--check-publish` JSON/human shape and non-zero behavior.
- Phase 51 can widen support matrix/rebuild truth that Phase 50 exposes; Phase 52 can promote docs-contract/proof coverage across the full operator surface.

</code_context>

<specifics>
## Specific Ideas

- User asked to consider all gray areas with subagent research and return one
  cohesive recommendation set so they do not need to choose routine
  architecture details.
- Five advisor researchers were used:
  - publish-check scope;
  - readiness finding derivation;
  - output and CI contract;
  - guardrails/remediations;
  - ecosystem/DX synthesis.
- Research converged on one recommendation: `doctor --check-publish` should be
  a composed findings layer over local publish checks, support matrix truth, and
  Phase 49 inspection truth.
- Strongest footguns to avoid:
  - a new command that fragments DX;
  - duplicated support/readiness logic;
  - advisory remote/provider proof rendered as supported;
  - no-finding interpreted as supported;
  - a single "ready" bit hiding verification-required or deferred surfaces;
  - docs links and support claims drifting from live code.

</specifics>

<deferred>
## Deferred Ideas

- Remote Hex/public URL checks may remain advisory or move to a later release
  lane if deterministic behavior is not practical in Phase 50.
- GitHub annotations and CI job summaries are useful, but JSON remains canonical;
  if scoped out, they can land in Phase 52 operator proof/CI polish.
- Full support-matrix and native rebuild guide expansion belongs to Phase 51.
- Full docs-contract and hermetic operator proof across doctor/support/guides
  belongs to Phase 52.
- StoreKit, Play Billing, full Sigra machinery, Chimeway delivery, standalone
  shell packages, and broad provider/native support claims remain deferred to
  their planned milestones.

</deferred>

---

*Phase: 50-Doctor Publish and Readiness Checks*
*Context gathered: 2026-05-31*
