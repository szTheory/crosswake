# Phase 50: Doctor Publish and Readiness Checks - Research

**Researched:** 2026-05-31  
**Domain:** Elixir Mix diagnostics, publish-readiness checks, and stable operator output contracts  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
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
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DIAG-01 | `mix crosswake.doctor --check-publish` reports actionable release/support readiness across Hex metadata, changelog status, docs/support parity, proof posture, and known verification-required surfaces. | Command boundary, check composition, JSON/human contract, and test map below define implementable scope. [VERIFIED: codebase grep] |
| DIAG-02 | Doctor output identifies companion dependency health, provider-adapter readiness, notification-token readiness, auth/session predicate readiness, and native shell verification gaps with explicit severity and remediation. | OperatorInspection + SupportMatrix reuse pattern and finding schema recommendations define this contract without new truth silos. [VERIFIED: codebase grep] |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Preserve Crosswake as Phoenix-first route-policy/runtime-contract system. [VERIFIED: codebase grep]
- Keep runtime ownership explicit per route; no generic WebView wrapper drift. [VERIFIED: codebase grep]
- Keep bridge contracts semantic/typed/versioned/low-frequency. [VERIFIED: codebase grep]
- Keep offline claims explicit and honest about read-only cache vs local-first mutation. [VERIFIED: codebase grep]
- Treat diagnostics/support matrices/proof lanes/docs rough edges as product surface. [VERIFIED: codebase grep]
- Respect v1/v3.6 scope boundaries from PROJECT/REQUIREMENTS before widening integrations. [VERIFIED: codebase grep]

## Summary

Phase 50 should be planned as a targeted extension of existing doctor contracts, not a new diagnostics subsystem. The current code already provides strict Mix option parsing, structured finding types (`severity`, `code`, `check`, `hint`, `details`), and stable JSON/human formatter split; the plan should reuse these seams and add a `publish_readiness` layer only when `--check-publish` is present. [VERIFIED: codebase grep]

The strongest implementation path is a layered derivation: doctor-local deterministic publish checks (mix/changelog/docs parity) + route/readiness data from `Crosswake.OperatorInspection` + canonical support/proof/rebuild vocabulary from `Crosswake.SupportMatrix`. This avoids duplicating truth and satisfies DIAG-01/DIAG-02 with stable machine contract and actionable human output. [VERIFIED: codebase grep]

Phase 50 must explicitly avoid phase-51/52 overreach. It should add checks and output hooks necessary for readiness visibility now, while deferring broad support-matrix vocabulary expansion (Phase 51) and hermetic docs-contract hardening/CI annotation polish (Phase 52). [VERIFIED: codebase grep]

**Primary recommendation:** Implement `--check-publish` as an additive doctor pipeline stage that emits versioned `publish_readiness` JSON plus concise human section, sourcing readiness truth from existing OperatorInspection and SupportMatrix APIs. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `mix crosswake.doctor --check-publish` option parsing and exit behavior | API / Backend | — | Mix task is CLI/backend-side contract; no client runtime tier involved. [VERIFIED: codebase grep] |
| Publish parity checks (`mix.exs`, changelog, docs links) | API / Backend | CDN / Static | Source-of-truth files live in repo; docs URLs are static/public references. [VERIFIED: codebase grep] |
| Route/capability/auth/notification readiness derivation | API / Backend | Database / Storage | Derived from manifest/support-matrix runtime contracts, not browser logic. [VERIFIED: codebase grep] |
| Machine-readable JSON diagnostics | API / Backend | — | JSON formatter is canonical automation surface for CI/tooling. [VERIFIED: codebase grep] |
| Human actionable operator output | API / Backend | — | Formatter renders findings for operators; no frontend rendering system exists. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Runtime and language for Mix tasks/doctor checks | Existing project/toolchain baseline. [VERIFIED: codebase grep] |
| Erlang/OTP | 28 | VM/runtime for Elixir execution | Existing project runtime baseline. [VERIFIED: codebase grep] |
| Mix/OptionParser | bundled | CLI switch parsing and task lifecycle | Existing doctor/inspect pattern uses strict parsing and `Mix.raise` on invalid options. [VERIFIED: codebase grep] |
| Jason | `~> 1.4` | Stable JSON formatting for doctor/inspection outputs | Existing JSON formatter contract depends on Jason encoding. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Crosswake.OperatorInspection` | in-repo | Route-authoritative readiness inventory | Derive companion/provider/auth/notification readiness without duplicating logic. [VERIFIED: codebase grep] |
| `Crosswake.SupportMatrix` | in-repo | Canonical support/proof/rebuild vocabulary | Populate severity/proof/rebuild/claim-scope fields in publish checks. [VERIFIED: codebase grep] |
| `Crosswake.Doctor.Check` | in-repo | Structured finding envelope | Keep stable finding schema across existing and publish-readiness findings. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending `mix crosswake.doctor` | New `mix crosswake.readiness` task | Violates locked command boundary D-01 and splits operator surface. [VERIFIED: codebase grep] |
| Reusing `OperatorInspection` data | Recompute route readiness inside doctor | Duplicates truth and increases drift risk between inspect and doctor. [VERIFIED: codebase grep] |
| Additive `publish_readiness` section | Re-shape whole doctor JSON schema | Breaks existing automation consumers and overreaches Phase 50 scope. [VERIFIED: codebase grep] |

**Installation:**  
No new package installation is required for Phase 50 scope. [VERIFIED: codebase grep]

**Version verification:**  
- `Elixir 1.19.5`, `OTP 28` detected in environment. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No external package installation is in scope for Phase 50; legitimacy gate is not applicable. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | — | — | — | — | — | Not required for this phase |

**Packages removed due to slopcheck [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
mix crosswake.doctor --check-publish
        |
        v
Mix.Tasks.Crosswake.Doctor (strict OptionParser + threshold rules)
        |
        v
Crosswake.Doctor.run(...)
        |
        +--> Existing doctor phases (install/manifest/shell/bridge/offline/commerce/findings)
        |
        +--> Publish Readiness stage (new in Phase 50)
                |
                +--> Local deterministic checks (mix.exs, CHANGELOG.md, docs/support parity)
                +--> OperatorInspection snapshot (route/auth/notification/companion/provider posture)
                +--> SupportMatrix vocabulary/proof/rebuild truth
                |
                v
         publish_readiness.checks[] + summary/status
        |
        +--> Human formatter section ("Publish readiness")
        +--> JSON formatter section ("publish_readiness", versioned)
        |
        v
Exit code gate (existing :error + fail-on threshold for publish checks)
```

### Recommended Project Structure
```text
lib/
├── mix/tasks/crosswake.doctor.ex                    # flag wiring + threshold plumbing
├── crosswake/doctor/doctor.ex                       # orchestrator pipeline
├── crosswake/doctor/publish_readiness.ex            # new check composer (recommended)
├── crosswake/doctor/formatter.ex                    # human section rendering
└── crosswake/doctor/json_formatter.ex               # machine contract rendering
```

### Pattern 1: Additive CLI Surface
**What:** Introduce `--check-publish` as strict switch, preserving default doctor behavior when absent. [VERIFIED: codebase grep]  
**When to use:** Any new doctor lane where backward-compatible default invocation is required. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: lib/mix/tasks/crosswake.doctor.ex
@switches [format: :string, router: :string, install_manifest: :string, native_checks: :boolean]
{opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")
```

### Pattern 2: Canonical Finding Envelope
**What:** Emit every readiness item as structured finding/check with stable code and severity. [VERIFIED: codebase grep]  
**When to use:** Any readiness category that needs both human and JSON output plus threshold handling. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: lib/crosswake/doctor/check.ex
defstruct [:severity, :code, :message, :hint, :check, details: %{}]
```

### Anti-Patterns to Avoid
- **New command split (`crosswake.readiness`)**: breaks D-01 command boundary and fragments UX. [VERIFIED: codebase grep]
- **Re-deriving support truth manually**: risks drift from `SupportMatrix` and `OperatorInspection`. [VERIFIED: codebase grep]
- **Single boolean “ready” headline without caveats**: hides verification-required/deferred surfaces and violates locked guidance. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route readiness derivation | New ad hoc route parser | `Crosswake.OperatorInspection.inspect/1` | Already typed and route-authoritative with conditions/findings. [VERIFIED: codebase grep] |
| Support/proof/rebuild vocabulary | Custom enums in new module | `Crosswake.SupportMatrix` accessors | Canonical statuses and taxonomy already encoded there. [VERIFIED: codebase grep] |
| JSON ordering contract for machine output | DIY string assembly | Existing JSON formatters + Jason | Existing stable rendering style and tests already in repo. [VERIFIED: codebase grep] |

**Key insight:** Phase 50 should compose existing truth surfaces; hand-rolled parallel truth will create drift that Phase 52 then has to unwind. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Breaking current doctor consumers
**What goes wrong:** JSON contract changes are made by mutation instead of additive `publish_readiness` section. [VERIFIED: codebase grep]  
**Why it happens:** Existing formatter currently emits fixed top-level keys without schema versioning for new sections. [VERIFIED: codebase grep]  
**How to avoid:** Preserve existing keys and append `publish_readiness` only when flag enabled; gate with tests. [VERIFIED: codebase grep]  
**Warning signs:** Existing `test/mix/tasks/crosswake_doctor_test.exs` JSON assertions fail on unchanged fields. [VERIFIED: codebase grep]

### Pitfall 2: Duplicating inspect/support logic in doctor
**What goes wrong:** Doctor check module starts recalculating route/auth/notification posture directly. [VERIFIED: codebase grep]  
**Why it happens:** Convenience during implementation instead of explicit composition. [VERIFIED: codebase grep]  
**How to avoid:** Ingest `OperatorInspection` output and annotate to readiness checks. [VERIFIED: codebase grep]  
**Warning signs:** New phase-50 code introduces duplicated status mappings already present in inspection/support modules. [VERIFIED: codebase grep]

### Pitfall 3: Overreaching into Phase 51/52
**What goes wrong:** Plan includes broad support-matrix policy rewrite or full docs-contract hermetic suite in Phase 50. [VERIFIED: codebase grep]  
**Why it happens:** Readiness work naturally touches support/docs surfaces. [VERIFIED: codebase grep]  
**How to avoid:** Limit to hooks/checks needed for DIAG-01/02; defer taxonomy expansion (51) and full parity locks (52). [VERIFIED: codebase grep]  
**Warning signs:** Tasks modify many guides/support-matrix rules beyond check references and minimal anchors. [VERIFIED: codebase grep]

## Code Examples

### Stable mix-task contract pattern
```elixir
# Source: lib/mix/tasks/crosswake.doctor.ex
output =
  case opts[:format] do
    nil -> Formatter.render(report)
    "human" -> Formatter.render(report)
    "json" -> JSONFormatter.render(report)
    other -> Mix.raise("unsupported format: #{inspect(other)}")
  end

if report.status == :error do
  Mix.raise("Crosswake doctor found blocking issues")
end
```

### Stable inspection JSON schema precedent
```elixir
# Source: lib/crosswake/operator_inspection/types.ex
@schema_version "1.0.0"
def document(attrs) do
  struct!(Document, %{schema_version: Keyword.get(attrs, :schema_version, @schema_version), ...})
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Doctor-only install/runtime diagnostics | Doctor + typed commerce/support surfaces + separate inspect command | Through phases 41 and 49 | Phase 50 can extend instead of redesigning operator diagnostics. [VERIFIED: codebase grep] |
| Prose-only operator interpretation | Machine-readable JSON + human formatter split | Existing in doctor and inspect | Enables CI/tooling without scraping prose. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating no-findings as implicit support is invalid for v3.6 readiness scope. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Introducing `--fail-on` in Phase 50 is optional and may defer to Phase 52 without DIAG regressions. [ASSUMED] | Summary / Patterns | Could slightly reduce CI ergonomics until later phase. |
| A2 | A dedicated `Crosswake.Doctor.PublishReadiness` module is the best maintainability split. [ASSUMED] | Recommended Structure | If maintainers prefer single-file edits, plan granularity changes. |

## Open Questions

1. **Should remote Hex checks ship in Phase 50 behind explicit opt-in?**
   - What we know: locked decisions require deterministic local path to remain primary; remote checks must be advisory by default. [VERIFIED: codebase grep]
   - What's unclear: whether maintainers want any remote check in this phase.
   - Recommendation: plan local deterministic checks as required scope; remote checks as optional trailing task or defer.

2. **Do we ship `publish_readiness.schema_version` independent of existing doctor payload versioning?**
   - What we know: inspect has explicit schema version precedent; doctor JSON currently does not expose top-level schema field. [VERIFIED: codebase grep]
   - What's unclear: desired backward-compatibility strategy for doctor consumers.
   - Recommendation: add nested `publish_readiness.schema_version` first for additive safety.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Mix task execution and tests | ✓ | 1.19.5 | — |
| `mix` | CLI task entrypoint/tests | ✓ | bundled with Elixir 1.19.5 | — |
| `erl` / OTP | Runtime | ✓ | 28 | — |
| `rg` | fast code/test discovery during planning | ✓ | 15.1.0 | `grep` |

**Missing dependencies with no fallback:**
- None identified. [VERIFIED: codebase grep]

**Missing dependencies with fallback:**
- None identified. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (project default) [VERIFIED: codebase grep] |
| Config file | none explicit (Mix + `test/` conventions) [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mix/tasks/crosswake_doctor_test.exs` [VERIFIED: codebase grep] |
| Full suite command | `mix test` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DIAG-01 | `--check-publish` emits actionable publish readiness in human/json | integration | `mix test test/mix/tasks/crosswake_doctor_test.exs -x` | ❌ Wave 0 (new assertions needed) |
| DIAG-02 | readiness categories include companion/provider/notification/auth/shell with severity+remediation | unit+integration | `mix test test/crosswake/doctor/doctor_test.exs -x` | ❌ Wave 0 (new coverage needed) |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] Add `--check-publish` CLI behavior tests in `test/mix/tasks/crosswake_doctor_test.exs`.
- [ ] Add publish-readiness report/JSON schema tests in `test/crosswake/doctor/doctor_test.exs`.
- [ ] Add formatter-focused checks for publish section in `test/crosswake/doctor/formatter_test.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse `OperatorInspection` auth predicates (`auth_min_level`, `requires_recent_auth`) and explicit verification-required findings. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Report auth/session freshness posture via existing contract-only vocabulary, avoid implicit “supported” claims. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Preserve fail-closed denial/status vocabulary from support matrix and inspection denials. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Keep strict `OptionParser` and deterministic local checks before external I/O. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No new crypto primitives in Phase 50 scope. [VERIFIED: codebase grep] |

### Known Threat Patterns for Elixir CLI diagnostics

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False support claims in publish output | Tampering | Block on `error` severity and explicit claim-scope/deferred markers. [VERIFIED: codebase grep] |
| Silent pass on missing readiness | Repudiation | Require explicit check results and non-zero exit on threshold breach. [VERIFIED: codebase grep] |
| Schema drift breaking CI tooling | DoS | Keep additive JSON contract and lock with formatter tests. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `lib/mix/tasks/crosswake.doctor.ex` — current doctor CLI switches, strict parsing, output dispatch, exit behavior. [VERIFIED: codebase grep]
- `lib/crosswake/doctor/doctor.ex` — report shape, status derivation, commerce summary precedent, findings pipeline. [VERIFIED: codebase grep]
- `lib/crosswake/doctor/check.ex` — structured finding contract fields. [VERIFIED: codebase grep]
- `lib/crosswake/doctor/formatter.ex` and `lib/crosswake/doctor/json_formatter.ex` — human/json rendering patterns and stability constraints. [VERIFIED: codebase grep]
- `lib/crosswake/operator_inspection.ex` and `lib/crosswake/operator_inspection/types.ex` — typed route-authoritative inspection and schema version precedent. [VERIFIED: codebase grep]
- `lib/crosswake/support_matrix/support_matrix.ex` — canonical support/proof/rebuild/status vocabulary and readiness-related truth. [VERIFIED: codebase grep]
- `test/mix/tasks/crosswake_doctor_test.exs`, `test/crosswake/doctor/*`, `test/crosswake/operator_inspection/*` — existing verification patterns and output contracts. [VERIFIED: codebase grep]
- `.planning/phases/50-doctor-publish-and-readiness-checks/50-CONTEXT.md` — locked decisions and scope boundaries. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md` — requirement traceability and phase boundaries. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/mix/main/Mix.Task.html — Mix task behavior expectations. [CITED: https://hexdocs.pm/mix/main/Mix.Task.html]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html — Hex publish workflow semantics for readiness framing. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- https://docs.djangoproject.com/en/stable/topics/checks/ — stable diagnostic code/severity precedent. [CITED: https://docs.djangoproject.com/en/stable/topics/checks/]

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly observed in code and runtime.
- Architecture: HIGH - constrained by locked decisions + existing module boundaries.
- Pitfalls: HIGH - backed by current tests/contracts and explicit phase boundaries.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30

## RESEARCH COMPLETE
