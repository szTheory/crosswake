# Phase 137: crosswake_sigra Extraction - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Move sigra's auth machinery into a standalone, independently-versioned
`packages/crosswake_sigra/` Hex package — **module names preserved** (`Crosswake.Companions.Sigra.*`
stays put = non-breaking for adopters) — refactored so companion internals emit
`Crosswake.Compatibility.Finding` at the package boundary instead of the core-private
`Crosswake.Shell.Denial`, then publish it **irreversibly** to Hex, gated by
dress-rehearsal (path dep) → `hex.publish --dry-run` → clean-room install lane.

**In scope:** the D-4 `Finding`-boundary refactor (SIGRA-02); source + test move with the
proven `script/extract_companion.md` recipe (SIGRA-01); independent `release-please` component
registration + the full publish gate chain (SIGRA-03). First irreversible Hex publish of v17.0,
and it's the **auth** companion.

**Out of scope:** extracting chimeway (138) or threadline (139); any change to the four
core→companion decoupling seams (that was Phase 136, verified clean); tightening
`auth_context` typing.

Requirements: **SIGRA-01, SIGRA-02, SIGRA-03** (see `.planning/REQUIREMENTS.md`).
Design spine **D-4, D-8, D-9** is LOCKED; Phase 136 CONTEXT (§D-136-B) already recorded the
four Phase-137 prerequisites. This discussion resolved the genuinely-open shape decisions
beneath that lock via a two-round research + adversarial-audit pass.

</domain>

<decisions>
## Implementation Decisions

Derived from parallel ecosystem research (Ash/Ecto/Oban/Phoenix boundary-struct idiom;
Sentry/Phoenix/OTel PII scrubbing; release-please/trusted-publishing release gates;
rulestead/rindle in-repo precedent) **plus a second adversarial audit that verified every
claim against the live code.** The four decisions are mutually coherent: the new `Finding`
fields (A) are exactly what the `:auth` clause (B) propagates; sanitize-at-source (B) is what
makes the clean-room `Finding→Denial` assertion (D) trustworthy; clean-room green (D) is the
precondition the publish gate (C) waits on.

### D-137-A — Single `%Finding{}` type end-to-end in sigra; `evaluate_auth/3` callback returns `{:deny, Finding.t()}`
- **Rejected** an internal parallel step-up struct or a package-local Denial shim (they'd
  re-import a Denial-shaped type, defeat the boundary, and trip the Phase-136 AST guard). One
  public type, `Finding`, flows through sigra end-to-end. Idiom precedent: Phoenix
  (`%Phoenix.HTML.Form{}`), Ecto.Changeset, Ash.Error — expose one canonical boundary struct,
  never leak the core's internal representation.
- **Add two OPTIONAL fields to `Crosswake.Compatibility.Finding`** (`compatibility.ex` ~L57):
  `code :: String.t() | nil` and `details :: map()` (default `%{}`). **Verified non-breaking**
  (minor bump): `@enforce_keys` is `[:axis, :message]`; no exhaustive/positional `%Finding{}`
  match exists in core, `crosswake_rulestead`, or `crosswake_rindle` (only struct-update
  `%Finding{f | ...}` and keyword construction, both field-additive-safe). Update the struct
  moduledoc semver note to list `:code`/`:details` as auth-classification carriers.
- **BOUNDARY OWNERSHIP (audit fix ②, load-bearing):** change the
  `Crosswake.Companion.evaluate_auth/3` behaviour callback return from
  `{:deny, Crosswake.Shell.Denial.t()}` (the Phase-136 passthrough) to
  **`{:deny, Crosswake.Compatibility.Finding.t()}`**. Core's
  `RouteGate.prepend_auth_evaluation_denials/4` (`route_gate.ex:317-319`) must call
  `Compatibility.finding_to_denial/2` on the returned Finding **before** accumulating into the
  `[Denial.t()]` denials list. This is the clean D-4 realization — **core owns Finding→Denial
  translation**; sigra never touches `Denial`. Without this the current RouteGate would push a
  raw `Finding` into a `Denial` list (silent contract break).
- **sigra edits (narrow — 2 files):** `Evaluator.deny/4` (`evaluator.ex:250-253`, the sole
  Finding-construction site) returns `%Finding{axis: :auth, code:, details: sanitized,
  message: @generic_message}`; `StepUpCeremony` re-points its semantic branch
  (`step_up_ceremony.ex:39`) from `%Denial{reason: :step_up_required, code: code}` to
  `%Finding{axis: :auth, code: code}` and reads `finding.details["max_auth_age_seconds"]` in
  `issue_attrs/4` (**guard this — dropping it silently removes the step-up max-age = security
  regression**); update the `sigra.ex` facade return; remove `alias Crosswake.Shell.Denial`
  from `evaluator.ex:14` and `step_up_ceremony.ex:15`. No `@compile {:no_warn_undefined}`
  needed — sigra depends on `crosswake` and both `Finding` and (transitively) `Denial` are
  core-public / core-owned.

### D-137-B — `:auth` clause in `finding_to_denial/2`, with the `base_details` merge GUARDED; sanitize runs once at source
- Add before the catch-all `axis ->` in `finding_to_denial/2` (`compatibility.ex` ~L148):
  ```elixir
  :auth -> {:step_up_required, finding.code, %{}, finding.details}
  ```
  One `:auth` axis; sub-classification carried in the `code` string (OAuth/OIDC pattern:
  single reason + structured sub-code). Recovery `%{}` — the host owns ceremony routing.
- **AUDIT FIX ① (real bug):** the unconditional `details = Map.merge(base_details(finding),
  details)` block (`compatibility.ex:186-191`) would inject `axis: :auth` into the
  already-sanitized details. **Guard it for `:auth` exactly like the existing `:pack_version`
  special-case** so `:auth` passes `finding.details` through UNMERGED.
- **Sanitize-at-source only.** `DenialCodes.sanitize_details/1` runs **once, inside sigra, at
  `Finding` construction** (`evaluator.ex:250` — verified the sole PII-bearing path; the
  `StepUpCeremony` fallback carries no PII). Core does **not** re-sanitize and literally cannot
  — `DenialCodes` lives in the package, absent from core. Defense-in-depth is intentional and
  layered: sigra scrubs `details` at the source; core's baseline 10-atom denylist (D-136-A,
  `Crosswake.Telemetry.baseline_forbidden_metadata_keys/0`) scrubs telemetry metadata at the
  sink.
- **PII guards:** sigra's `Finding.message`/`Finding.hint` must always be the generic constant
  (they bypass `sanitize_details` and flow straight into `Denial.new`). `finding.code` must be
  populated for auth denials — a `nil` code silently downgrades to `"step_up_required"` via the
  `code || Atom.to_string(reason)` fallback (`compatibility.ex:195`).
- **Code taxonomy (DX):** keep the existing dotted `auth.step_up.*` / `auth.handoff.*` /
  `auth.auth_return.*` namespace already in use in `denial_codes.ex` — machine-matchable,
  adopter-branchable, consistent with Stripe/Ash `code` conventions. Keep them as the
  package's documented denial-code surface.

### D-137-C — Release-PR merge IS the human go/no-go; fold the admin required-checks registration in as task #1
- **No extra environment-protection approval** before `hex.publish` (violates the project's
  0-recurring-intervention principle; the dry-run + clean-room already cover the irreversible
  risk). The **merge of the sigra Release PR is the auditable human decision.** Sigra being the
  auth companion does not raise the bar — a bad Hex version is patch-recoverable; only the
  name/version coordinate is irreversible, and that is what the gate chain protects. Idiom:
  release-please's Release-PR model = the human gate (as rulestead/rindle already do).
- **Fold `DRY_RUN=0 script/register_required_checks.sh` (the carried admin ship-gate) into the
  137 plan as an early task,** run as an explicit human admin action **after** the new
  `clean-room-proof-sigra` lane has gone green **once on main** (the script's green-first
  preflight then prevents the "expected — waiting for status" required-check deadlock). Order:
  push CI wiring → clean-room green once on main → register required checks → Release PR
  becomes mergeable.
- **Ordered gate sequence:** ① HUMAN register required checks (as above) → ② path-dep dress
  rehearsal `mix test` → ③ `hex.publish --dry-run` → ④ clean-room lane (`crosswake` +
  `crosswake_sigra` **only**) → ⑤ HUMAN merge Release PR → ⑥ auto publish → ⑦ post-publish
  clean-room from Hex → ⑧ auto failure-alert issue on any step 6-7 failure → ⑨ auto `release-as`
  cleanup PR → ⑩ HUMAN merge cleanup PR.
- **`release-as: "0.1.0"` one-shot footgun (rindle Phase-132 / recipe Pitfall 6):** required for
  the first publish; must be auto-stripped after the first sigra Release PR merges or every
  subsequent release re-targets 0.1.0. Wire the `release-as-cleanup` job to also fire on
  `sigra_release_created`.
- **SCOPE CORRECTION (audit):** the `release-please.yml` change is **~100 lines mirroring the
  rulestead/rindle pattern verbatim**, NOT a one-liner: new `sigra_release_created` /
  `sigra_tag_name` / `sigra_version` outputs + a `publish-hex-sigra` job + a
  `clean-room-proof-sigra` job + extended `release-as-cleanup` and `release-failure-alert`
  `if:`/`needs:` conditions. Register `crosswake_sigra` as an **independent** `elixir`
  release-please component (NOT in the `linked-versions` lockstep group — D-8), cloning the
  rindle config block in `release-please-config.json` + `.release-please-manifest.json`.

### D-137-D — Test split mirrors rindle; clean-room MUST register sigra in setup and assert via RouteGate on the translated Denial
- **Test split** (recipe D-20: SC#1 → companion lane, SC#5 → core lane):
  | Test | Lane | Reason |
  |---|---|---|
  | `companions/sigra/handoff_test.exs` | MOVE → package | sigra-internal |
  | `companions/sigra/telemetry_test.exs` | MOVE → package | sigra-internal |
  | `companions/sigra/contracts_test.exs` | MOVE → package | sigra-internal |
  | `companions/sigra/step_up_test.exs` | MOVE → package | sigra-internal |
  | `proof/phase46_sigra_auth_contract_test.exs` | STAY in core | RouteGate/Doctor/SupportMatrix integration = SC#5 fail-closed |
  | `proof/phase54_sigra_session_authority_test.exs` | **SPLIT** | Evaluator/DenialCodes/Contracts direct-call assertions → package; `SupportMatrix.auth_contract_truth()` assertion → core |
- **Clean-room non-vacuity (audit fix ③):** the clean-room proof MUST, in setup,
  `Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])` — registration is
  Application-env based and the extracted package **cannot self-register** into core's env.
  Then drive a real auth evaluation through the **public** `RouteGate.evaluate/4`
  (`route_gate.ex:33`, returns a `Decision` with `denial: Denial.t() | nil`) and assert
  `decision.denial.reason == :step_up_required`. **Without the `put_env`, the denial is
  `:dependency_missing` (fail-closed) not `:step_up_required` → the assertion is vacuous/red.**
  This proves the FULL boundary: registry dispatch + `Finding→Denial` translation, with only
  `crosswake + crosswake_sigra` installed. Lane installs **no other `crosswake_*` companion**.
- **Support modules:** add a `StubSigraAbsentCompanion` in core (parallel to the existing
  `StubRulesteadAbsentCompanion`) for the engine-absent fail-closed proof. Exact test-support
  module moves (fixtures/mocks) → **planner/researcher verifies against the actual rindle
  precedent** rather than trusting a guessed module name.

### Claude's Discretion
- Exact `@version` starting value for `crosswake_sigra` (follow rindle: `0.1.0` first-publish
  one-shot) and mix.exs metadata (description/docs/licenses) — clone the rindle package block.
- Whether the generic step-up/handoff `message`/`hint` microcopy is refined for brand voice is
  a nice-to-have; keep the existing generic wording unless the planner sees an easy win
  (the DX/microcopy research lens was deprioritized — this is a backend denial contract).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Design spine + milestone lock
- `.planning/research/v17-companion-family-completion.md` — design spine D-1..D-9; esp. **D-4**
  (companions emit `Finding`, core translates; `sanitize_details` stays in-package), **D-8**
  (independent versioning, not lockstep), **D-9** (Step-0 decoupling prereq, sequential
  sigra→chimeway→threadline publish, non-vacuous clean-room, carried admin ship-gate).
- `.planning/phases/136-core-decoupling/136-CONTEXT.md` — **§D-136-B** records the four
  Phase-137 prerequisites (`:auth` clause, re-point StepUpCeremony match, move
  `sanitize_details` to boundary, audit all `Denial.new` sites); **§D-136-A** the baseline
  10-atom denylist this layers with; **§D-136-D** the count-independent vacuity-safe test
  philosophy the clean-room assertion follows.
- `.planning/REQUIREMENTS.md` — SIGRA-01 (L26), SIGRA-02 (L27), SIGRA-03 (L28).
- `.planning/ROADMAP.md` — Phase 137 goal + 5 success criteria.

### Extraction recipe + precedent
- `script/extract_companion.md` — the parameterized extraction checklist (proven on rulestead
  Phase 130, rindle Phase 132); Step 2 test-split table; publish steps; the `release-as`
  one-shot Pitfall 6.
- `packages/crosswake_rindle/` + `packages/crosswake_rulestead/` — **in-repo precedent** for
  package `mix.exs`, `@version`, test layout, and CI clean-room lane; mirror what worked.
- `release-please-config.json` + `.release-please-manifest.json` — independent-component
  registration pattern (rindle/rulestead blocks) + the one-shot `release-as` TODO note.
- `.github/workflows/release-please.yml` — the per-component `*_release_created` gate,
  `publish-hex-*`, clean-room, `release-as-cleanup`, and `release-failure-alert` jobs to clone
  for sigra.
- `script/register_required_checks.sh` — the parametric required-checks registrar (read its
  header on the green-first preflight / "expected — waiting for status" deadlock).

### Refactor target code
- `lib/crosswake/compatibility/compatibility.ex` — `Finding` struct (~L57) + `finding_to_denial/2`
  (~L143, the `:auth` clause + guarded `base_details` merge at L186-191).
- `lib/crosswake/compatibility/route_gate.ex` — `evaluate/4` (public, L33) + auth-eval
  accumulation `prepend_auth_evaluation_denials/4` (L317-319) that must call `finding_to_denial/2`.
- `lib/crosswake/companion.ex` — the `evaluate_auth/3` behaviour callback whose return type changes.
- `lib/crosswake/companions/sigra/{evaluator,step_up_ceremony,denial_codes}.ex` — the two
  `Denial.new` sites + the semantic step-up match + `sanitize_details/1` / `@allowed_detail_keys`.
- `lib/crosswake/shell/denial.ex` — the core-private struct that stays absent from the package.

### DX / voice (secondary)
- `.planning/research/v3.8/DENIAL-TELEMETRY-DX.md` — prior denial/telemetry DX research (code
  taxonomy + microcopy). `brandbook/BRAND-SPEC.md` — current brand voice (prefer over older
  `prompts/crosswake-brand-book.md`). `prompts/crosswake-elixir-oss-dna.md` — adopter/OSS ethos.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`script/extract_companion.md` + rulestead/rindle packages** — the extraction is a
  mechanical clone of a twice-proven path; the recipe's test-split table, publish gate, and
  `release-as` handling are directly reusable.
- **`Compatibility.finding_to_denial/2`** — already the core Finding→Denial translation seam
  with ~9 axis clauses; the `:auth` clause slots in beside them (mirror the `:pack_version`
  guarded-details special-case).
- **`RouteGate.evaluate/4`** — public entry that returns a `Decision` with a translated
  `Denial`; the clean-room lane's non-vacuity assertion drives it directly.
- **`StubRulesteadAbsentCompanion`** — template for the new `StubSigraAbsentCompanion`.
- **`Telemetry.baseline_forbidden_metadata_keys/0`** (D-136-A) — the sink-side scrub that
  layers with sigra's source-side `sanitize_details`.

### Established Patterns
- **Boundary-struct idiom** — one public struct (`Finding`) across the package seam; internal
  core type (`Denial`) stays private. Matches Phoenix/Ecto/Ash.
- **Application-env companion registry** — `Application.get_env(:crosswake, :companions, [])`;
  packages are registered by the host/config, never self-register (drives the clean-room setup).
- **Per-component release gate** — key on `sigra_release_created`, never the aggregate
  `releases_created`, to keep the sequential sigra→chimeway→threadline publish honest.
- **Fail-closed** — an unregistered auth authority yields `:dependency_missing`, not an allow;
  the clean-room test must register sigra to observe `:step_up_required` instead.

### Integration Points
- `Companion.evaluate_auth/3` callback return type (`Denial.t()` → `Finding.t()`) — the single
  behaviour-contract change that ripples into `RouteGate` and every auth-authority companion
  (only sigra today).
- `finding_to_denial/2` `:auth` clause — where the companion-public Finding becomes the
  core-private Denial.
- `release-please.yml` + `release-please-config.json` — where `crosswake_sigra` becomes an
  independently-versioned, independently-published component.

</code_context>

<specifics>
## Specific Ideas

- User directive for this phase: **research every decision through all relevant expert lenses
  (Elixir/OTP idiom, ecosystem precedent incl. cross-language, SWE/architecture, DevOps/SRE,
  API-consumer/JTBD, DX, footguns), then one-shot a single coherent recommendation** — realized
  via a first-round 4-agent research pass + a second-round adversarial code-verified audit.
  (Matches the saved "research-then-recommend" working preference.)
- The adversarial audit is the source of the three must-fixes baked into D-137-A/B/D and the
  D-137-C scope correction — the planner should treat those as verified, not re-derive them.

</specifics>

<deferred>
## Deferred Ideas

- **DX/microcopy polish** of step-up/handoff denial `message`/`hint` against `BRAND-SPEC.md` —
  optional nice-to-have; the research agent for this lens was deprioritized this session. Pick
  up opportunistically during planning if cheap; otherwise leave existing generic wording.
- **Chimeway (138) / threadline (139) extraction** — next phases; chimeway's clean-room must
  explicitly **not** install `crosswake_sigra` (else its no-sigra decoupling proof is vacuous) —
  noted here so 138's discuss owns it.

None else — discussion stayed within phase scope.

</deferred>

---

*Phase: 137-crosswake_sigra Extraction*
*Context gathered: 2026-07-01*
