# Phase 137: crosswake_sigra Extraction - Research

**Researched:** 2026-07-01
**Domain:** Elixir companion extraction — Finding boundary refactor + Hex package publish pipeline
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### D-137-A — Single `%Finding{}` type end-to-end in sigra; `evaluate_auth/3` callback returns `{:deny, Finding.t()}`
Add two OPTIONAL fields to `Crosswake.Compatibility.Finding` (`code :: String.t() | nil` and `details :: map()` default `%{}`). Change `Companion.evaluate_auth/3` behaviour callback return from `{:deny, Denial.t()}` to `{:deny, Finding.t()}`. Core's `prepend_auth_evaluation_denials/4` calls `finding_to_denial/2` before accumulating. Sigra edits are narrow — 2 files: `Evaluator.deny/4` returns `%Finding{}`, `StepUpCeremony` re-points its semantic branch. Remove `alias Crosswake.Shell.Denial` from both files.

#### D-137-B — `:auth` clause in `finding_to_denial/2`, guarded `base_details` merge; sanitize runs once at source
Add `:auth -> {:step_up_required, finding.code, %{}, finding.details}` before the catch-all. Guard the unconditional `Map.merge(base_details(finding), details)` block for `:auth` exactly like the existing `:pack_version` special-case so `:auth` passes `finding.details` through UNMERGED. `DenialCodes.sanitize_details/1` runs once, inside sigra, at `Finding` construction. Core does not re-sanitize.

#### D-137-C — Release-PR merge IS the human go/no-go; fold register_required_checks as task #1
No extra environment-protection approval before `hex.publish`. The merge of the sigra Release PR is the auditable human decision. Fold `DRY_RUN=0 script/register_required_checks.sh` into the plan as an early task, run after `clean-room-proof-sigra` goes green once on main. Wire `release-as-cleanup` to fire on `sigra_release_created`. The full workflow is ~100 lines mirroring rulestead/rindle verbatim.

#### D-137-D — Test split mirrors rindle; clean-room MUST register sigra in setup and assert via RouteGate
| Test | Lane | Reason |
|---|---|---|
| `companions/sigra/handoff_test.exs` | MOVE → package | sigra-internal |
| `companions/sigra/telemetry_test.exs` | MOVE → package | sigra-internal |
| `companions/sigra/contracts_test.exs` | MOVE → package | sigra-internal |
| `companions/sigra/step_up_test.exs` | MOVE → package | sigra-internal |
| `proof/phase46_sigra_auth_contract_test.exs` | STAY in core | RouteGate/Doctor/SupportMatrix integration |
| `proof/phase54_sigra_session_authority_test.exs` | **SPLIT** | Evaluator/DenialCodes/Contracts → package; SupportMatrix assertion → core |
Clean-room MUST `Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])` in setup, then drive `RouteGate.evaluate/4` and assert `decision.denial.reason == :step_up_required`.

### Claude's Discretion
- Exact `@version` starting value for `crosswake_sigra` (follow rindle: `0.1.0` first-publish one-shot)
- mix.exs metadata (description/docs/licenses) — clone the rindle package block
- Whether generic step-up/handoff message microcopy is refined for brand voice

### Deferred Ideas (OUT OF SCOPE)
- DX/microcopy polish of step-up/handoff denial `message`/`hint` against BRAND-SPEC.md
- Chimeway (138) / threadline (139) extraction — next phases
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SIGRA-01 | `sigra` source + tests move to standalone `packages/crosswake_sigra/` Hex project (own `mix.exs`, own `@version`), with all sub-modules (`Evaluator`, `Handoff`, `StepUp`, `StepUpCeremony`, `AuthReturn`, `Contracts`, `DenialCodes`, `Telemetry`) preserving `Crosswake.Companions.Sigra.*` namespace. | Extraction recipe (`script/extract_companion.md`) proven on rulestead/rindle. Source files enumerated in § Source Files to Move. Test split table confirmed against live filesystem in § Test Split Verification. |
| SIGRA-02 | Sigra internals emit `Crosswake.Compatibility.Finding` at companion boundary; `Crosswake.Shell.Denial` stays core-private and absent from sigra package; PII detail-sanitization (`DenialCodes.sanitize_details/1`) lives inside the package. All internal `Denial.new` call sites refactored to `Finding` boundary. | Drift-verified: `Evaluator.deny/4` at L241-260 is sole `Denial.new` site in sigra internals. `StepUpCeremony` at L39 has `%Denial{reason: :step_up_required, code: code}` semantic match. `compatibility.ex` drift-verified for `finding_to_denial/2` at L144 and `base_details` block at L187-191. `companion.ex` evaluate_auth callback verified at L183-187. |
| SIGRA-03 | `crosswake_sigra` publishes to Hex as independent `release-please` component (not lockstep), preceded by path-dep dress rehearsal, gated by `hex.publish --dry-run` + clean-room install lane before irreversible publish. | release-please-config.json, .release-please-manifest.json, and release-please.yml patterns read and documented verbatim. 10-step gate sequence confirmed. |
</phase_requirements>

## Summary

Phase 137 is a mechanical extraction (proven recipe, twice-proven) PLUS a boundary-type refactor (one new `Finding` axis) PLUS a CI pipeline registration. The design is fully locked from the two-round research + adversarial audit. This research is focused entirely on **drift-verification** — confirming that line-number anchors in CONTEXT.md match the live code after Phase 136 execution — and on **mechanical precedent mirroring** so the planner can write exact, executable tasks.

**Drift verdict:** All CONTEXT.md line-number anchors are CONFIRMED against the live code with minor adjustments noted below. No BLOCKER conditions were found.

**Three audit must-fixes (all confirmed still required in live code):**
1. Audit fix ①: `base_details` merge block at L187-191 is still unconditional — the `:auth` guard must be added.
2. Audit fix ②: `companion.ex` `evaluate_auth/3` callback at L183-187 still returns `Crosswake.Shell.Denial.t()` — must change to `Finding.t()`.
3. Audit fix ③: clean-room proof `put_env` is not present in `verify_companion_cleanroom.sh` — must be added as a test-level `setup` in the new `proof/phase137_sigra_cleanroom_test.exs`.

**Primary recommendation:** Follow the `script/extract_companion.md` recipe Steps 1-12 for sigra, applying the D-137-A/B boundary refactor in Step 1 (modified source), and adding the D-137-D test split in Step 2 rather than the recipe's default. The Finding→Denial boundary change is the only non-mechanical aspect; all other steps are direct parameter substitution.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Auth evaluation (route_predicate check) | Backend (RouteGate) | — | RouteGate owns the dispatch; sigra only implements the algorithm |
| Finding→Denial translation | Backend (Compatibility) | — | Core owns the internal type; companions never touch `Denial` |
| PII sanitization | Package (sigra) | Core baseline (telemetry sink) | Source-side scrub in sigra + sink-side baseline in Telemetry |
| Package publication | CI (release-please) | Human gate (PR merge) | Standard rulestead/rindle pattern |
| Clean-room verification | CI (clean-room-proof-sigra) | — | Post-publish lane, no in-tree deps |

## Standard Stack

### Core (no new deps — this is source + CI movement)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `crosswake` | `~> 0.1` (Hex dep when CROSSWAKE_RELEASE=1) | Core runtime dep of the package | Env-conditional pattern proven on rulestead/rindle |
| `elixir` | `~> 1.19` | Language runtime | Matches core mix.exs |

### No Engine Optional Dep
Sigra has no "engine" library analogous to `rulestead` or `rindle`. The auth machinery is pure Elixir — no `{:some_engine, "~> 0.1", optional: true}` line is needed. This simplifies the package `mix.exs` vs. rulestead/rindle.

**Consequence for recipe:** Steps 6 (engine_present stub) and the `engine-present.test` alias are OMITTED for sigra. The `elixirc_paths/1` function does not need the `ENGINE_PRESENT_LANE` branch. The `mix.exs` is simpler than rindle's. [VERIFIED: live code read]

### Supporting CI Infrastructure (already in repo)
| Script/File | Purpose |
|-------------|---------|
| `script/verify_companion_cleanroom.sh` | Post-publish clean-room verification (parametric) |
| `script/strip_release_as.py` | Auto-strips one-shot `release-as` pin (parametric, PROOF-03) |
| `script/register_required_checks.sh` | Admin-only green-first required-check registration |
| `release-please-config.json` | Add sigra component block (clone rindle block) |
| `.release-please-manifest.json` | Add `"packages/crosswake_sigra": "0.1.0"` |
| `.github/workflows/release-please.yml` | Add ~100 lines: sigra outputs + 3 new jobs |

## Package Legitimacy Audit

No new external packages are installed by this phase. `crosswake_sigra` is a first-party package extracted from the monorepo. No third-party packages are added to any `mix.exs`. Registry check is not applicable.

| Package | Verdict | Disposition |
|---------|---------|-------------|
| `crosswake_sigra` | First-party (new) | Created by this phase |
| `crosswake` (as dep) | First-party | Already in use by rulestead/rindle packages |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

## Drift Verification Report

### compatibility.ex — Finding struct and finding_to_denial/2

**CONTEXT.md anchors vs. live code:**

| CONTEXT anchor | Live location | Status |
|----------------|---------------|--------|
| `Finding` struct ~L57 | L57-92 (defmodule Finding at L57, @enforce_keys at L79, defstruct at L80) | CONFIRMED |
| `finding_to_denial/2` ~L143 | L143-202 | CONFIRMED |
| `:auth` clause insertion point ~L148 | INSERT between `:pack_version` clause (L173-176) and `axis ->` catch-all (L177) | CONFIRMED — the catch-all is at L177 |
| `base_details` / `Map.merge` block L186-191 | L187-191 | CONFIRMED (1-line drift) |

**Critical finding — `Finding` struct fields:**
Current `defstruct` at L80: `[:axis, :message, :required, :available, :hint, :route_id, :subject]`

The D-137-A two new fields (`:code` and `:details`) are NOT yet present. They must be added. `@enforce_keys` is `[:axis, :message]` — adding optional fields is non-breaking. [VERIFIED: live code read, L79-80]

**`base_details/1` function at L751-757:**
```elixir
defp base_details(finding) do
  %{}
  |> maybe_put(:axis, finding.axis)
  |> maybe_put(:required, finding.required)
  |> maybe_put(:available, finding.available)
  |> maybe_put(:subject, finding.subject)
end
```
This injects `:axis` into details for all axes. The guard for `:auth` (audit fix ①) must prevent this from running for `:auth` findings. Pattern: mirror the `:pack_version` special-case already at L187-191 exactly. [VERIFIED: live code read]

**`:pack_version` guard at L187-191 (template for `:auth` guard):**
```elixir
details =
  if finding.axis == :pack_version and Keyword.has_key?(opts, :current_route_id) do
    details
  else
    Map.merge(base_details(finding), details)
  end
```
The `:auth` guard follows the same pattern but unconditionally (no opts check needed):
```elixir
details =
  if finding.axis in [:pack_version, :auth] and ... do
    # or: separate clause
  end
```
Exact shape is planner's choice; matching the `:pack_version` guard idiom is the spec. [ASSUMED — exact implementation shape; the mechanic is VERIFIED]

### route_gate.ex — prepend_auth_evaluation_denials/4

**CONTEXT anchor:** `prepend_auth_evaluation_denials/4` at route_gate.ex:317-319
**Live location:** L256-326 (function starts at L256, the `case result do` block is at L317-320)

```elixir
# L317-320 (current)
case result do
  {:allow, _} -> acc
  {:deny, denial} -> [denial | acc]
end
```

After D-137-A/B: `authority.evaluate_auth/3` returns `{:deny, Finding.t()}` not `{:deny, Denial.t()}`. The pattern match `{:deny, denial}` still structurally matches, but `denial` is now a `Finding.t()`. This line must call `Compatibility.finding_to_denial/2` before accumulating:

```elixir
case result do
  {:allow, _} -> acc
  {:deny, finding} -> [Compatibility.finding_to_denial(finding, route_id: route.id) | acc]
end
```

`Compatibility` is already aliased at the top of `route_gate.ex` (L6). No new alias needed. [VERIFIED: live code read]

### companion.ex — evaluate_auth/3 callback return type

**CONTEXT anchor:** `companion.ex` evaluate_auth/3 callback spec
**Live location:** L183-187

```elixir
# Current (L183-187)
@callback evaluate_auth(
            route :: RouteEntry.t(),
            auth_context :: map(),
            opts :: keyword()
          ) :: {:allow, map()} | {:deny, Crosswake.Shell.Denial.t()}
```

Must change to `{:allow, map()} | {:deny, Crosswake.Compatibility.Finding.t()}`.
`Crosswake.Compatibility.Finding` is already aliased at L49 in companion.ex as `Finding`. So the spec becomes `{:allow, map()} | {:deny, Finding.t()}`. [VERIFIED: live code read]

The `@doc` at L166-180 currently says "Returns `{:deny, Crosswake.Shell.Denial.t()}`" — this docstring must also be updated. [VERIFIED: live code read]

### evaluator.ex — Evaluator.deny/4 (sole Finding-construction site)

**CONTEXT anchor:** `evaluator.ex:250-253`
**Live location:** L241-260 (the `deny/4` private function)

```elixir
# Current (L241-260)
defp deny(%RouteEntry{} = route, code, details, opts) do
  sanitized =
    details
    |> Map.put_new(
      :evaluated_at,
      DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    )
    |> maybe_put_ref(:challenge_ref, Keyword.get(opts, :challenge_ref))
    |> maybe_put_ref(:step_up_token_ref, Keyword.get(opts, :step_up_token_ref))
    |> DenialCodes.sanitize_details()

  {:deny,
   Denial.new(
     reason: :step_up_required,
     code: code,
     message: @generic_message,
     route_id: route.id,
     details: sanitized
   )}
end
```

Must change to return `{:deny, %Finding{axis: :auth, code: code, details: sanitized, message: @generic_message}}`. The `route_id:` field is not in Finding's current defstruct — Finding has `:route_id` at L80. So it IS present: `defstruct [:axis, :message, :required, :available, :hint, :route_id, :subject]`. The `route_id:` field on Finding can be populated: `%Finding{axis: :auth, code: code, details: sanitized, message: @generic_message, route_id: route.id}`. [VERIFIED: live code read]

**Aliases at L14 in evaluator.ex:** `alias Crosswake.Shell.Denial` — MUST be removed. `alias Crosswake.Compatibility.Finding` (or equivalent) — must be added. [VERIFIED: live code read at L14]

### step_up_ceremony.ex — semantic step-up match

**CONTEXT anchor:** `step_up_ceremony.ex:39` for the semantic branch
**Live location:** L39

```elixir
# Current (L39)
{:deny, %Denial{reason: :step_up_required, code: code} = denial}
when code in @challengeable_codes ->
  issue_challenge(route, auth_context, denial, opts)
```

After D-137-A: evaluator now returns `{:deny, Finding.t()}` so this match must become:
```elixir
{:deny, %Finding{axis: :auth, code: code} = finding}
when code in @challengeable_codes ->
  issue_challenge(route, auth_context, finding, opts)
```

And `issue_attrs/4` reads `denial.details` at L94 — must become `finding.details["max_auth_age_seconds"]`. **This field access is load-bearing** per D-137-A: dropping it silently removes the step-up max-age = security regression. [VERIFIED: live code read]

`issue_attrs/4` at L80-99 also has `denial.code` at L106 (route_denial_code) — must become `finding.code`. [VERIFIED: live code read at L93-98]

**Alias at L15 in step_up_ceremony.ex:** `alias Crosswake.Shell.Denial` — MUST be removed. `alias Crosswake.Compatibility.Finding` — must be added. The `normalize_issue_result/1` function at L59-78 also references `%Denial{}` and `Denial.new` — these must also be updated to `Finding` and `%Finding{}` respectively (or kept as-is if they remain producing `{:deny, Denial.t()}` for the outer return — see below).

**Important nuance in `normalize_issue_result/1`:** The function at L59-78 wraps the `issue_intent` callback result. It currently returns `{:deny, Denial.t()}`. After D-137-A, `evaluate_or_issue/3` must return `{:deny, Finding.t()}` throughout. However, the `normalize_issue_result` path wraps external host callback results (`{:error, %Denial{} = denial}`). The planner must decide: do these denial pass-throughs in `normalize_issue_result` also get converted to `Finding`? Since `StepUpCeremony` is an internal sigra module that will live entirely in the package, it can keep using `Denial` internally for the host-provided `issue_intent` result, OR convert. Given the D-137-A boundary rule ("sigra never touches Denial"), the `normalize_issue_result` path must be updated. The `{:deny, Denial.new(...)}` fallback at L72-77 must become `{:deny, %Finding{...}}`. The `{:error, %Denial{}}` match from the host callback is trickier — the host returns a `Denial`-shaped result; this needs careful handling. **OPEN QUESTION flagged below.**

### sigra.ex facade

**Live location:** `lib/crosswake/companions/sigra.ex`

The facade's `evaluate_auth/3` callback at L81-95 currently does:
```elixir
{:deny, denial} ->
  # Pass the Denial.t() through UNCHANGED — No Finding conversion — D-136-B
  {:deny, denial}
```

After D-137-A, the facade receives `{:deny, Finding.t()}` from `Evaluator.evaluate_route_auth/3` and must pass it through as `{:deny, Finding.t()}`. The comment "No Finding conversion — D-136-B" should be updated to "Finding boundary is implemented — D-137-A". [VERIFIED: live code read]

**Removal from `mix.exs` application env:** `mix.exs` L32 currently has `env: [companions: [Crosswake.Companions.Sigra, Crosswake.Companions.Chimeway]]`. The comment at L30-31 already says "Phase-137 extraction: remove Crosswake.Companions.Sigra from this list when that module is extracted". The entire `sigra.ex` facade file is REMOVED from core and `Crosswake.Companions.Sigra` is removed from the `env:` list. [VERIFIED: live code read]

### Source Files to Move (SIGRA-01)

All these move from `lib/crosswake/companions/sigra/` to `packages/crosswake_sigra/lib/crosswake/companions/sigra/`: [VERIFIED: live filesystem]

- `auth_return.ex`
- `contracts.ex`
- `denial_codes.ex`
- `evaluator.ex`
- `handoff.ex`
- `step_up.ex`
- `step_up_ceremony.ex`
- `telemetry.ex`

Plus the facade: `lib/crosswake/companions/sigra.ex` moves to `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex`.

### Test Split Verification (D-137-D)

**Core test files confirmed present:** [VERIFIED: live filesystem]
- `test/crosswake/companions/sigra/contracts_test.exs` ✓
- `test/crosswake/companions/sigra/handoff_test.exs` ✓
- `test/crosswake/companions/sigra/step_up_test.exs` ✓
- `test/crosswake/companions/sigra/telemetry_test.exs` ✓
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` ✓
- `test/crosswake/proof/phase54_sigra_session_authority_test.exs` ✓

**NOTE: there is no `evaluator_test.exs` in `test/crosswake/companions/sigra/`** — the evaluator is tested via phase54 proof tests and via phase46. The CONTEXT.md split table does not list an evaluator_test.exs, which is consistent with reality.

**phase54 SPLIT analysis** — which tests call sigra internals vs. core:

| Test in phase54 | Calls | Lane |
|-----------------|-------|------|
| "phase 54 authority contract is backend owned..." | `Contracts.new_session_authority_lane/1`, `Contracts.*` | MOVE → package |
| "evidence lanes cannot smuggle session authority fields" | `Contracts.validate_evidence_lane/1` | MOVE → package |
| "canonical auth denial taxonomy remains..." | `DenialCodes.codes/0` | MOVE → package |
| "shell-safe auth denial details are allowlisted" | `DenialCodes.sanitize_details/1`, `DenialCodes.allowed_detail_keys/0` | MOVE → package |
| "evaluator keeps auth failures under stable step-up reason..." | `Evaluator.evaluate_route_auth/3` | MOVE → package |
| "support truth locks route posture vocabulary..." | `SupportMatrix.auth_contract_truth/0` | STAY in core |
| "phase 54 proof still does not claim later auth machinery" | `File.read!(__ENV__.file)` (text assertion) | MOVE → package (self-referential) |

**Implication:** The split results in:
- `packages/crosswake_sigra/test/crosswake/proof/phase54_sigra_session_authority_test.exs` — 6 tests (all except SupportMatrix)
- A new core test in `test/crosswake/proof/phase54_sigra_support_truth_test.exs` (or retained inline in phase46) — 1 test (`SupportMatrix.auth_contract_truth/0`)

The `SupportMatrix.auth_contract_truth/0` assertion at L162-177 of phase54 must stay in core because `SupportMatrix` is core-internal. [VERIFIED: live code read]

### StubSigraAbsentCompanion — location and pattern

**`StubRulesteadAbsentCompanion` and `StubRindleAbsentCompanion` live in:** `test/support/stub_companion.ex` (both in same file). [VERIFIED: live code read]

**Pattern for `StubSigraAbsentCompanion`** (add to `test/support/stub_companion.ex`):

```elixir
defmodule Crosswake.TestSupport.StubSigraAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Sigra with the engine absent from core deps.

  Used in core tests that prove auth-predicated fail-closed behavior after
  Phase 137 extracts Crosswake.Companions.Sigra to packages/crosswake_sigra/.
  companion_id: :sigra so Doctor findings carry "companion.sigra".

  validate_dependency/0 returns {:error, [:"Elixir.Crosswake.Companions.Sigra"]} — or
  more precisely the modules that sigra would have provided — because sigra is
  absent from core deps after extraction (EXTRACT-01 guard, D-21).
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :sigra

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [:"Elixir.Crosswake.Companions.Sigra"]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :sigra, %{})
    %Crosswake.Companion.State{
      companion_id: :sigra,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [:"Elixir.Crosswake.Companions.Sigra"]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

**Also needs `auth_authority?/0` optional callback** because phase46 test drives auth-predicated routes. Without it, the stub never qualifies as auth authority and the test can't drive the fail-closed path for auth:

```elixir
  @impl true
  def auth_authority?, do: false  # engine absent = no authority
```

[ASSUMED — the exact absent-stub behaviour for auth_authority? is inferred from the fail-closed contract; the rulestead/rindle stubs don't have auth_authority? because they are not auth companions]

## Architecture Patterns

### System Architecture Diagram

```
[Host Application]
    config :crosswake, :companions, [Crosswake.Companions.Sigra]
         |
         v
[RouteGate.evaluate/4]  (core — packages/crosswake)
    |
    +-- prepend_auth_evaluation_denials/4
    |       |
    |       +-- Application.get_env(:crosswake, :companions, [])
    |       +-- filter auth_authority?() == true
    |       +-- authority.evaluate_auth(route, auth_context, opts)
    |               |
    |               v
    |         [Crosswake.Companions.Sigra.evaluate_auth/3]  (package boundary)
    |               |
    |               v
    |         [Sigra.Evaluator.evaluate_route_auth/3]  (sigra-internal)
    |               |
    |               v (returns {:deny, %Finding{axis: :auth, ...}})
    |               |
    |       +-- Compatibility.finding_to_denial(finding, route_id: route.id)
    |               |
    |               v (Finding → Denial translation, core-owned)
    |         [Compatibility.finding_to_denial/2]
    |               |   :auth clause: {:step_up_required, finding.code, %{}, finding.details}
    |               v
    |         Denial.new(reason: :step_up_required, code: finding.code, details: finding.details)
    |
    v
[Decision.t() with denial: Denial.t()]  →  host

[PII Scrub layering]
  sigra source: DenialCodes.sanitize_details/1 inside Evaluator.deny/4  (once, at construction)
  core sink:    Telemetry.baseline_forbidden_metadata_keys/0            (always-on baseline)
```

### Recommended Package Structure

```
packages/crosswake_sigra/
├── lib/
│   └── crosswake/
│       └── companions/
│           ├── sigra.ex               # facade + @behaviour Crosswake.Companion
│           └── sigra/
│               ├── auth_return.ex
│               ├── contracts.ex
│               ├── denial_codes.ex    # sanitize_details/1 lives here (SIGRA-02)
│               ├── evaluator.ex       # deny/4 returns Finding.t() (D-137-A)
│               ├── handoff.ex
│               ├── step_up.ex
│               ├── step_up_ceremony.ex # re-pointed to Finding (D-137-A)
│               └── telemetry.ex
├── test/
│   ├── crosswake/
│   │   ├── companions/
│   │   │   └── sigra/
│   │   │       ├── contracts_test.exs   (MOVED from core)
│   │   │       ├── handoff_test.exs     (MOVED from core)
│   │   │       ├── step_up_test.exs     (MOVED from core)
│   │   │       └── telemetry_test.exs   (MOVED from core)
│   │   └── proof/
│   │       ├── phase54_sigra_session_authority_test.exs  (SPLIT from core — 6 tests)
│   │       └── phase137_sigra_cleanroom_test.exs          (NEW — non-vacuous clean-room proof)
│   ├── support/
│   │   └── study_session_live.ex  (copied from crosswake_rindle/test/support/)
│   └── test_helper.exs
├── mix.exs                        # @version "0.1.0" # x-release-please-version
├── mix.lock
├── config/
│   └── config.exs                 # minimal (no flag_source needed — sigra has no engine)
├── README.md
├── LICENSE
└── CHANGELOG.md
```

**Key difference from rindle:** No `engine_present/` directory, no `ENGINE_PRESENT_LANE` branch in `elixirc_paths/1`, no `engine-present.test` alias — sigra has no optional engine. [VERIFIED: sigra has no engine dep; auth machinery is pure Elixir]

### Pattern 1: mix.exs for crosswake_sigra (clone rindle, drop engine dep)

```elixir
# Source: packages/crosswake_rindle/mix.exs (verified live code read)
defmodule CrosswakeSigra.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version — separate from core 0.1.2; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_sigra,
      version: @version,
      name: "crosswake_sigra",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [crosswake_dep()]
    # NOTE: No optional engine dep — sigra has no third-party engine library
  end

  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp description, do: "Sigra auth companion adapter for the Crosswake route-policy system."

  defp package do
    [
      name: "crosswake_sigra",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_sigra",
        "GitHub" => @source_url
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
```

[VERIFIED: pattern confirmed against live rindle/rulestead mix.exs files]

### Pattern 2: release-please-config.json sigra block (clone rindle block exactly)

```json
"packages/crosswake_sigra": {
  "component": "crosswake_sigra",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "_TODO_release_as": "ONE-SHOT override: remove 'release-as' after first crosswake_sigra Release PR merges — else subsequent runs re-target 0.1.0 forever (Pitfall 6 / recipe Step 12f). sigra is independently versioned.",
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_sigra/mix.exs"],
  "changelog-sections": [
    { "type": "feat",     "section": "Features" },
    { "type": "fix",      "section": "Bug Fixes" },
    { "type": "perf",     "section": "Performance Improvements" },
    { "type": "deps",     "section": "Dependencies" },
    { "type": "chore",    "section": "Miscellaneous",          "hidden": true },
    { "type": "docs",     "section": "Documentation",          "hidden": true },
    { "type": "test",     "section": "Tests",                  "hidden": true },
    { "type": "ci",       "section": "Continuous Integration", "hidden": true },
    { "type": "refactor", "section": "Refactoring",            "hidden": true },
    { "type": "build",    "section": "Build System",           "hidden": true }
  ]
}
```

[VERIFIED: pattern matches live rindle block in release-please-config.json]

### Pattern 3: .release-please-manifest.json addition

Add to the existing JSON object:
```json
"packages/crosswake_sigra": "0.1.0"
```

Current manifest has 5 keys: `.`, `packages/crosswake-shell-core-ios`, `packages/crosswake-shell-core-android`, `packages/crosswake_rulestead`, `packages/crosswake_rindle`. Sigra becomes the 6th. [VERIFIED: live manifest read]

### Pattern 4: release-please.yml additions (~100 lines, 4 sub-blocks)

**Sub-block 1: outputs: block additions (add after rindle outputs, ~L55)**
```yaml
# Companion: crosswake_sigra (Phase 137 — independently versioned, NOT in lockstep)
# Same double-dash path-output -> dot-notation alias contract as rulestead/rindle (D-08):
# GitHub Actions if: cannot index slash-containing keys, so alias here for downstream.
sigra_release_created: ${{ steps.release.outputs['packages/crosswake_sigra--release_created'] }}
sigra_tag_name: ${{ steps.release.outputs['packages/crosswake_sigra--tag_name'] }}
sigra_version: ${{ steps.release.outputs['packages/crosswake_sigra--version'] }}
```

**Sub-block 2: publish-hex-sigra job (mirror publish-hex-rindle, ~35 lines)**
```yaml
publish-hex-sigra:
  name: Publish crosswake_sigra to Hex.pm
  needs: release-please
  if: ${{ needs.release-please.outputs.sigra_release_created == 'true' }}
  runs-on: ubuntu-latest
  permissions:
    contents: read
  env:
    CROSSWAKE_RELEASE: "1"
  steps:
    # ... identical structure to publish-hex-rindle but:
    # - ref: needs.release-please.outputs.sigra_tag_name
    # - working-directory: packages/crosswake_sigra
    # - VERSION: needs.release-please.outputs.sigra_version
    # - Version grep: packages/crosswake_sigra/mix.exs
    # - Poll URL: hex.pm/api/packages/crosswake_sigra/releases/${VERSION}
```

**Sub-block 3: clean-room-proof-sigra job (~20 lines)**
```yaml
clean-room-proof-sigra:
  name: Clean-room proof — crosswake_sigra resolvability + auth evaluation
  needs: [release-please, publish-hex-sigra]
  if: ${{ needs.release-please.outputs.sigra_release_created == 'true' }}
  runs-on: ubuntu-latest
  permissions:
    contents: read
  steps:
    - uses: actions/checkout@...
    - uses: erlef/setup-beam@...
      with:
        version-file: .tool-versions
        version-type: strict
    - name: Install Hex + Rebar
      run: |
        mix local.hex --force
        mix local.rebar --force
    - name: Run clean-room proof
      # sigra has no engine library (3rd arg), no engine module (4th arg)
      run: >
        bash script/verify_companion_cleanroom.sh
        crosswake_sigra
        "${{ needs.release-please.outputs.sigra_version }}"
```

**NOTE for clean-room script:** `verify_companion_cleanroom.sh` is parametric but currently writes a smoke test that registers `ENGINE_PACKAGE` and `ENGINE_MODULE`. For sigra with no engine, the script is invoked with only 2 args (PACKAGE + VERSION). The existing default values (`ENGINE_PACKAGE=rulestead`, `ENGINE_MODULE=Rulestead`) will kick in — the planner must verify whether the script handles the no-engine case, or the script needs a "no engine" code path. [ASSUMED — the script may need a guard for the no-engine case; verify before running]

**Sub-block 4: release-as-cleanup and release-failure-alert if: condition updates**

`release-as-cleanup` job condition at L803 must add `sigra_release_created`:
```yaml
if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' || needs.release-please.outputs.rindle_release_created == 'true' || needs.release-please.outputs.sigra_release_created == 'true' }}
```

`release-as-cleanup` strip block must add:
```bash
if [ "${{ needs.release-please.outputs.sigra_release_created }}" = "true" ]; then
  python3 script/strip_release_as.py crosswake_sigra
fi
```

`release-failure-alert` needs: block must add `publish-hex-sigra` and `clean-room-proof-sigra`. Its `if:` condition is already `${{ failure() }}` — no change needed. The job body must add sigra job results to the issue body.

[VERIFIED: live release-please.yml read, exact line numbers confirmed]

### Pattern 5: Finding boundary refactor (D-137-A/B combined)

**Step 1 — Add fields to Finding struct (compatibility.ex)**

```elixir
# Before (L80 current):
@enforce_keys [:axis, :message]
defstruct [:axis, :message, :required, :available, :hint, :route_id, :subject]

# After:
@enforce_keys [:axis, :message]
defstruct [:axis, :message, :required, :available, :hint, :route_id, :subject,
           :code, details: %{}]
```

Update `@typedoc` to add `code: String.t() | nil` and `details: map()` with auth-classification carrier note.

**Step 2 — Add :auth clause to finding_to_denial/2 (compatibility.ex ~L175-177)**

```elixir
# Insert before the catch-all `axis ->` clause:
:auth ->
  {:step_up_required, finding.code, %{}, finding.details}
```

**Step 3 — Guard base_details merge for :auth (compatibility.ex L187-191)**

```elixir
# Current:
details =
  if finding.axis == :pack_version and Keyword.has_key?(opts, :current_route_id) do
    details
  else
    Map.merge(base_details(finding), details)
  end

# After:
details =
  cond do
    finding.axis == :auth ->
      details
    finding.axis == :pack_version and Keyword.has_key?(opts, :current_route_id) ->
      details
    true ->
      Map.merge(base_details(finding), details)
  end
```

[ASSUMED — exact `cond` vs. nested `if` implementation shape is planner's choice]

**Step 4 — Update Evaluator.deny/4 (evaluator.ex ~L241)**

```elixir
# Before: {:deny, Denial.new(reason: :step_up_required, code: code, ...)}
# After:
{:deny, %Finding{
  axis: :auth,
  code: code,
  message: @generic_message,
  route_id: route.id,
  details: sanitized
}}
```

Remove `alias Crosswake.Shell.Denial` from evaluator.ex L14. Add `alias Crosswake.Compatibility.Finding`.

**Step 5 — Update StepUpCeremony match (step_up_ceremony.ex L39)**

```elixir
# Before:
{:deny, %Denial{reason: :step_up_required, code: code} = denial}
when code in @challengeable_codes ->

# After:
{:deny, %Finding{axis: :auth, code: code} = finding}
when code in @challengeable_codes ->
  issue_challenge(route, auth_context, finding, opts)
```

Update `issue_attrs/4` to use `finding.details` instead of `denial.details` (at L94).
Update `normalize_issue_result` fallback to return `{:deny, %Finding{axis: :auth, ...}}` instead of `{:deny, Denial.new(...)}`.
Remove `alias Crosswake.Shell.Denial` from step_up_ceremony.ex L15. Add `alias Crosswake.Compatibility.Finding`.

**Step 6 — Update RouteGate accumulation (route_gate.ex L317-319)**

```elixir
# Before:
case result do
  {:allow, _} -> acc
  {:deny, denial} -> [denial | acc]
end

# After:
case result do
  {:allow, _} -> acc
  {:deny, finding} -> [Compatibility.finding_to_denial(finding, route_id: route.id) | acc]
end
```

**Step 7 — Update companion.ex callback spec and docstring (companion.ex L183-187)**

Change `{:deny, Crosswake.Shell.Denial.t()}` to `{:deny, Finding.t()}`. Update docstring. `Finding` is already aliased at L49.

**Step 8 — Update sigra.ex facade (before extraction)**

The `evaluate_auth/3` pass-through at L89-93 passes `{:deny, denial}` — after D-137-A this becomes `{:deny, finding}` where finding is a `Finding.t()`. The pass-through still works structurally; update the comment.

### Anti-Patterns to Avoid

- **Moving all tests wholesale without splitting (D-20 test split violation):** phase46 and the SupportMatrix assertion from phase54 MUST stay in core. Moving them breaks SC#5 fail-closed proof.
- **Using `application: [env: [...]]` self-registration in the package:** packages CANNOT self-register into core's Application env. The clean-room proof MUST use `Application.put_env` in test setup. [VERIFIED: existing rulestead/rindle tests follow this pattern]
- **Gating clean-room on `releases_created` (aggregate):** must gate on `sigra_release_created` (per-component). Using the aggregate would publish sigra on every core release.
- **Forgetting `CROSSWAKE_RELEASE=1`** on all mix steps in `publish-hex-sigra`: without it, `hex.publish` errors because `crosswake_dep/0` returns a path: dep which hex.build rejects.
- **Registering `clean-room-proof-sigra` as required check before it has gone green once:** triggers the "Expected — Waiting for status" deadlock. The `register_required_checks.sh` script has a green-first preflight that prevents this, but the ordering (push CI → green once on main → then register) must be followed. [VERIFIED: register_required_checks.sh header at L21-28]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `release-as` cleanup after first publish | Manual edit + PR | `script/strip_release_as.py` (auto, PROOF-03) | Already parametric and CI-wired; no per-companion code needed — add sigra to the `release-as-cleanup` job `if:` condition only |
| Clean-room verification | Custom CI steps | `script/verify_companion_cleanroom.sh` (parametric) | Already handles poll + throwaway host + doctor; sigra invocation has no engine args |
| Required-check registration | `gh api` one-liners | `script/register_required_checks.sh` (parametric) | Green-first preflight built in; automatically discovers all merge-blocking lanes |
| Finding→Denial translation | Custom translation in sigra | `Compatibility.finding_to_denial/2` | Core owns this; adding the `:auth` clause is the right seam |
| PII scrubbing in core | Core-side sanitize call | `DenialCodes.sanitize_details/1` (source-side) | Core literally cannot call it after extraction — sanitize happens once in sigra before the Finding is returned |

## Common Pitfalls

### Pitfall 1: `release-as` one-shot footgun
**What goes wrong:** `release-as: "0.1.0"` is required for the first publish. If left in place after the first sigra Release PR merges, every subsequent run re-targets 0.1.0 forever.
**Why it happens:** release-please treats `release-as` as a permanent override, not a one-shot hint.
**How to avoid:** The `release-as-cleanup` job fires automatically when `sigra_release_created == 'true'` and opens a cleanup PR. Wire it by adding `sigra_release_created` to the `if:` condition — no other action needed.
**Warning signs:** `_TODO_release_as` comment in release-please-config.json still present after the Release PR merges; `release-as-staleness-gate.yml` goes RED.

### Pitfall 2: Vacuous clean-room proof
**What goes wrong:** If the clean-room test doesn't `Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])` in setup, auth-predicated routes get `:dependency_missing` (fail-closed) not `:step_up_required`. The assertion `decision.denial.reason == :step_up_required` would be RED.
**Why it happens:** The companion registry is Application-env based; packages cannot self-register.
**How to avoid:** The new `proof/phase137_sigra_cleanroom_test.exs` MUST include the `put_env` in setup with `on_exit` cleanup. See Validation Architecture § Backstop Tests.
**Warning signs:** Test passes but logs show `:dependency_missing` denial in the test output.

### Pitfall 3: `base_details` injects `:axis` into sanitized auth details
**What goes wrong:** The unconditional `Map.merge(base_details(finding), details)` block merges `%{axis: :auth}` INTO the already-sanitized `finding.details` (which passed sanitize_details). This injects a key that was NOT in the allowlist.
**Why it happens:** `base_details/1` at L751 always includes `finding.axis`. `:auth` is not in `@allowed_detail_keys` in DenialCodes.
**How to avoid:** Audit fix ① — guard the `Map.merge` for `:auth` exactly like `:pack_version`. [VERIFIED: live code confirms the guard is not yet present]
**Warning signs:** Auth denial details contain `"axis" => "auth"` which was not allowlisted.

### Pitfall 4: StepUpCeremony's `normalize_issue_result` still references Denial
**What goes wrong:** `normalize_issue_result/1` at L59-78 currently constructs `Denial.new(...)` for the fallback case and pattern-matches `{:error, %Denial{} = denial}`. After removing `alias Crosswake.Shell.Denial`, these references break at compile time.
**Why it happens:** The D-137-A spec says "sigra never touches Denial" — this is absolute.
**How to avoid:** Update `normalize_issue_result` to use `%Finding{axis: :auth, ...}` for the fallback, and update the `{:error, %Denial{}}` match. The host-provided `issue_intent` callback contract may need a separate review for the `{:error, denial}` arm — the planner should verify whether `issue_intent` callers expect `{:error, Denial.t()}` or can be updated.
**Warning signs:** `mix compile --warnings-as-errors` fails with "Crosswake.Shell.Denial is undefined" inside the package.

### Pitfall 5: `verify_companion_cleanroom.sh` no-engine path
**What goes wrong:** Script's default `ENGINE_PACKAGE=rulestead` and `ENGINE_MODULE=Rulestead` kick in when no 3rd/4th args are passed. The throwaway host mix.exs may add `{:rulestead, ...}` as a dep, and the smoke test may reference `Rulestead`, causing compile failures or incorrect smoke test behavior.
**Why it happens:** The script is parameterized for rulestead by default, not for no-engine companions.
**How to avoid:** Either (a) add a no-engine mode to the script, or (b) pass explicit empty args. Confirm this before the publish step. [ASSUMED — risk is MEDIUM; verify by reading the script's smoke-test generation section fully]
**Warning signs:** CI clean-room-proof-sigra fails with "Rulestead is not loaded" or similar.

## Code Examples

### Clean-room proof setup (D-137-D audit fix ③)

```elixir
# packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs
defmodule Crosswake.Proof.Phase137SigraCleanroomTest do
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Companions.Sigra.Contracts
  alias Crosswake.Companions.Sigra.Contracts.AuthContext
  alias Crosswake.Manifest

  defmodule AuthRouter do
    use Crosswake.Router
    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "secure", runtime: :live_view, auth_min_level: :mfa]
      end
    end
  end

  setup do
    # REQUIRED: sigra cannot self-register; test must register it explicitly.
    # Without this, auth-predicated routes get :dependency_missing not :step_up_required.
    original = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])
    on_exit(fn -> Application.put_env(:crosswake, :companions, original) end)
    :ok
  end

  test "clean-room non-vacuity: sigra registered → :step_up_required not :dependency_missing" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthRouter)
    target = %Target{origin: manifest.host.origin}

    decision = RouteGate.evaluate(manifest, "secure", target, [])

    assert decision.status == :deny
    # Non-vacuous: proves registry dispatch + Finding→Denial translation, not just fail-closed
    assert decision.denial.reason == :step_up_required
    refute decision.denial.reason == :dependency_missing
  end
end
```

### Finding struct update (compatibility.ex)

```elixir
# Source: compatibility.ex drift-verified live code
# Add :code and :details to Finding:
@enforce_keys [:axis, :message]
defstruct [:axis, :message, :required, :available, :hint, :route_id, :subject,
           :code, details: %{}]

@type t :: %__MODULE__{
        axis: atom(),
        message: String.t(),
        required: String.t() | atom() | nil,
        available: String.t() | atom() | nil,
        hint: String.t() | nil,
        route_id: String.t() | nil,
        subject: String.t() | nil,
        code: String.t() | nil,        # auth sub-classification carrier
        details: map()                  # sanitized auth evidence
      }
```

### :auth clause in finding_to_denial/2

```elixir
# Insert before the `axis ->` catch-all (currently at L177 in compatibility.ex)
:auth ->
  {:step_up_required, finding.code, %{}, finding.details}
```

The `code || Atom.to_string(reason)` fallback at L194 (`code: code || Atom.to_string(reason)`) handles the nil-code case — if `finding.code` is nil, the denial code falls back to `"step_up_required"`. [VERIFIED: live code at L194]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Sigra evaluates directly in core via `Sigra.Evaluator.evaluate_route_auth/3` | Registry-dispatched via `auth_authority?/0` + `evaluate_auth/3` optional callback | Phase 136 (DECOUPLE-02) | Core no longer compile-depends on any companion |
| `evaluate_auth/3` returns `{:deny, Denial.t()}` | Returns `{:deny, Finding.t()}` after Phase 137 | Phase 137 (D-137-A) | Full boundary: companions never touch core-private Denial |
| Companion extraction by env variable (MIX_INCLUDE_SIGRA) | Standalone Hex package with `path:` → Hex dep pivot | Phase 130-132 (rulestead/rindle precedent) | Non-breaking module-name preservation pattern |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `StubSigraAbsentCompanion` needs `auth_authority?/0` returning `false` to drive the absent-engine Doctor finding | § StubSigraAbsentCompanion | Without it, tests using the stub for auth-predicated fail-closed proof might not hit the right code path |
| A2 | `cond` vs nested `if` for the guarded `base_details` merge — exact implementation shape | § Pattern 5, Step 3 | Low risk; both are functionally equivalent |
| A3 | `verify_companion_cleanroom.sh` needs a no-engine guard or explicit empty 3rd/4th args for sigra | § Pitfall 5 | If wrong, clean-room CI job fails with rulestead references |
| A4 | `normalize_issue_result/1` in StepUpCeremony must use `%Finding{}` for the fallback case | § Pitfall 4 | If wrong, compilation fails with Denial undefined in the package |
| A5 | `StepUpCeremony.evaluate_or_issue/3` return type `{:deny, Denial.t()}` must become `{:deny, Finding.t()}` throughout | § Pattern 5, Step 5 | If wrong, host callers of `evaluate_or_issue/3` receive `Finding.t()` where they expected `Denial.t()` — need host-side update too |

## Open Questions

1. **`normalize_issue_result/1` and the host `issue_intent` callback contract**
   - What we know: `normalize_issue_result` currently matches `{:error, %Denial{} = denial}` from the host callback. After D-137-A, sigra cannot reference `Denial`.
   - What's unclear: Whether host apps that implement `issue_intent` return `{:error, Denial.t()}` and need updating, or whether this internal path can remain as a pass-through that never encounters a live Denial in the sigra-extraction context.
   - Recommendation: Planner should audit all callers of `StepUpCeremony.evaluate_or_issue/3` in the codebase to understand the `issue_intent` callback's `{:error, denial}` return shape before finalizing step 5.

2. **`verify_companion_cleanroom.sh` no-engine invocation**
   - What we know: Script defaults `ENGINE_PACKAGE=rulestead` when $3 is absent.
   - What's unclear: Whether the script's throwaway host and smoke test will fail gracefully when called as `bash script/verify_companion_cleanroom.sh crosswake_sigra 0.1.0` (no engine args).
   - Recommendation: Read the full script's smoke-test generation block before writing the `clean-room-proof-sigra` CI job. May need to pass `""` as 3rd/4th args or add a no-engine branch.

3. **phase54 SupportMatrix assertion in core**
   - What we know: The `"support truth locks route posture vocabulary..."` test at L162-177 of phase54 uses `SupportMatrix.auth_contract_truth/0` which depends on `Sigra.DenialCodes.codes()` via the runtime registry.
   - What's unclear: After extraction, does `SupportMatrix.auth_contract_truth/0` still work in a core-only context when sigra is not registered?
   - Recommendation: If `SupportMatrix.auth_contract_truth/0` reads denial codes via the runtime companion registry (confirmed in 136 decoupling), then in a core-only test the `denial_codes` field would be `[]`. The test assertion at L164 `assert row.denial_codes == DenialCodes.codes()` would fail. This test might need to be moved to the package OR the assertion updated to be registration-aware.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All build steps | ✓ | 1.19+ (per .tool-versions) | — |
| Hex CLI | `hex.publish` | ✓ | In CI via erlef/setup-beam | — |
| `HEX_API_KEY` secret | `hex.publish` | Expected ✓ | CI secret (used by rulestead/rindle) | — |
| `RELEASE_PLEASE_TOKEN` secret | Release PR + cleanup PR CI trigger | Expected ✓ | CI secret (existing) | `github.token` (but won't chain-trigger CI on cleanup PR) |
| `script/register_required_checks.sh` | Task #1 (human admin action) | ✓ | In repo | — |
| gh CLI (admin-scoped) | `DRY_RUN=0 register_required_checks.sh` | Required on human's machine | ≥ 2.x | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** `RELEASE_PLEASE_TOKEN` → can use `github.token` but cleanup PRs won't trigger CI automatically.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in Elixir) |
| Config file | `packages/crosswake_sigra/test/test_helper.exs` (create in Wave 0) |
| Quick run command | `cd packages/crosswake_sigra && mix test` |
| Full suite command | `mix test --include integration` (from repo root via `mix companions.test` alias) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SIGRA-01 | All sub-modules compile in package context | unit | `cd packages/crosswake_sigra && mix compile --warnings-as-errors` | ❌ Wave 0 — package does not exist yet |
| SIGRA-01 | Moved tests pass in package lane | unit | `cd packages/crosswake_sigra && mix test` | ❌ Wave 0 |
| SIGRA-01 | No Crosswake.Companions.Sigra refs remain in core lib/ | structural | `grep -r "Crosswake.Companions.Sigra" lib/ && echo FAIL \|\| echo CLEAN` | Runs inline |
| SIGRA-02 | No Crosswake.Shell.Denial ref inside packages/crosswake_sigra/ | structural | `grep -r "Crosswake.Shell.Denial\|alias.*Denial" packages/crosswake_sigra/lib/` | Runs inline |
| SIGRA-02 | Finding→Denial translation: auth axis produces :step_up_required | unit | `mix test test/crosswake/compatibility/compatibility_test.exs` (core) | ✅ (existing) |
| SIGRA-02 | Clean-room: sigra registered → :step_up_required not :dependency_missing | integration | `cd packages/crosswake_sigra && mix test test/crosswake/proof/phase137_sigra_cleanroom_test.exs` | ❌ Wave 0 |
| SIGRA-02 | max_auth_age_seconds guard: dropping field is a compile-error or test failure | unit | `cd packages/crosswake_sigra && mix test test/crosswake/companions/sigra/step_up_test.exs` | ❌ Wave 0 (moved) |
| SIGRA-02 | Finding fields are additive-non-breaking: existing Finding matches still compile | structural | `mix compile --warnings-as-errors` (core with new Finding fields) | Runs inline |
| SIGRA-03 | path-dep dress rehearsal passes mix test | integration | `CROSSWAKE_RELEASE=0 cd packages/crosswake_sigra && mix test` | ❌ Wave 0 |
| SIGRA-03 | hex.publish --dry-run succeeds | CI | `CROSSWAKE_RELEASE=1 mix hex.publish --dry-run --yes` | CI-only |
| SIGRA-03 | release-please component registered and independent | structural | Verify release-please-config.json NOT in linked-versions group | Manual |

### Backstop Tests (Required by D-137-D — must exist before phase gate)

1. **Non-vacuous clean-room proof** — `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs`
   - Asserts: `Application.put_env` registers sigra → `RouteGate.evaluate/4` on auth-predicated route → `decision.denial.reason == :step_up_required`
   - Non-vacuity guard: assert `denial.reason != :dependency_missing` explicitly

2. **step-up max-age guard** — inside `step_up_test.exs` (moved to package)
   - Asserts: `issue_attrs/4` populates `max_auth_age_seconds` from `finding.details["max_auth_age_seconds"]`
   - Security regression guard: dropping this field lookup silently removes the max-age constraint

3. **Finding-field-additive non-breaking guard** — in `phase46_sigra_auth_contract_test.exs` (STAYS in core)
   - The existing "weaker mfa and stale auth age deny with minimal typed details" test at L175-203 already drives `Finding.t()` fields through `finding_to_denial/2` and checks denial details — it will catch field-additive regressions. No new test needed.

4. **No Denial reference inside packages/crosswake_sigra/** — structural grep
   - `grep -r "Crosswake.Shell.Denial\|alias Crosswake.Shell.Denial" packages/crosswake_sigra/lib/ && echo FAIL || echo CLEAN`
   - Run as part of Wave 1 commit gate

### Sampling Rate

- **Per task commit:** `cd packages/crosswake_sigra && mix test && mix compile --warnings-as-errors`
- **Per wave merge:** Full core suite + companion lane: `mix test --exclude requires_example_host && cd packages/crosswake_sigra && mix test`
- **Phase gate:** Full suite green + clean-room proof green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `packages/crosswake_sigra/` directory skeleton (mix.exs, mix.lock, config/config.exs, README.md, CHANGELOG.md, LICENSE)
- [ ] `packages/crosswake_sigra/test/test_helper.exs` — `ExUnit.start(exclude: [:requires_example_host, :advisory_only])`
- [ ] `packages/crosswake_sigra/test/support/study_session_live.ex` — copy from crosswake_rindle/test/support/
- [ ] `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs` — non-vacuous clean-room proof
- [ ] Framework install: `cd packages/crosswake_sigra && mix deps.get` (after mix.exs is written)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes (this IS the auth companion) | `DenialCodes.sanitize_details/1` scrubs PII at source; `Telemetry.baseline_forbidden_metadata_keys/0` scrubs at sink |
| V3 Session Management | Yes | `StepUpCeremony` requires `max_auth_age_seconds` guard; SessionAuthorityLane lifecycle validation |
| V4 Access Control | Yes | `RouteGate` fail-closed: no auth authority → `:dependency_missing` deny; multiple authorities → first-registered + conflict telemetry |
| V5 Input Validation | Yes | `DenialCodes.sanitize_details/1` allowlist with `@safe_ref` regex for ref fields; `safe_value?/2` type gates |
| V6 Cryptography | No | No crypto in sigra — auth is session-authority-based, not token-crypto |

### Known Threat Patterns for sigra extraction

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| PII leak via auth denial details | Information Disclosure | `sanitize_details/1` at source (sigra) + baseline denylist at sink (core Telemetry) |
| Vacuous clean-room proof (no register = always `:dependency_missing`) | Tampering (test bypass) | audit fix ③: `Application.put_env` in clean-room setup + explicit `!= :dependency_missing` assertion |
| `max_auth_age_seconds` silently dropped from `issue_attrs/4` | Elevation of Privilege | `finding.details["max_auth_age_seconds"]` guard — D-137-A specifically calls this a security regression |
| `base_details` injecting `:axis: :auth` into sanitized details (unsanitized key injection) | Tampering | audit fix ①: guard `Map.merge` for `:auth` axis |
| `release-as: "0.1.0"` re-publishing stale version | Tampering (supply chain) | PROOF-03 auto-cleanup + staleness gate; parametric, no manual action needed for sigra |

## Sources

### Primary (HIGH confidence)
- Live code reads: `lib/crosswake/compatibility/compatibility.ex`, `lib/crosswake/compatibility/route_gate.ex`, `lib/crosswake/companion.ex`, `lib/crosswake/companions/sigra/evaluator.ex`, `lib/crosswake/companions/sigra/step_up_ceremony.ex`, `lib/crosswake/companions/sigra/denial_codes.ex`, `lib/crosswake/companions/sigra.ex`
- `script/extract_companion.md` — proven recipe, Steps 1-12
- `packages/crosswake_rindle/mix.exs`, `packages/crosswake_rulestead/mix.exs` — in-repo precedent
- `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml` — CI wiring patterns
- `test/support/stub_companion.ex` — `StubRulesteadAbsentCompanion` and `StubRindleAbsentCompanion` templates
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`, `test/crosswake/proof/phase54_sigra_session_authority_test.exs` — split table verification

### Secondary (MEDIUM confidence)
- `.planning/phases/137-crosswake-sigra-extraction/137-CONTEXT.md` — locked decisions D-137-A..D from two-round research + adversarial audit
- `.planning/phases/136-core-decoupling/136-CONTEXT.md` — §D-136-B four 137 prerequisites, §D-136-A baseline denylist

### Tertiary (LOW confidence)
- A1-A5 in Assumptions Log — inferred from pattern/precedent, not directly verified

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; patterns directly read from live code
- Architecture: HIGH — drift-verified against live code; all anchor lines confirmed
- Pitfalls: HIGH — three audit must-fixes confirmed still required in live code
- CI wiring: HIGH — exact patterns read from live release-please.yml
- Test split: HIGH — live filesystem confirmed all 6 test files

**Research date:** 2026-07-01
**Valid until:** 2026-07-31 (stable Elixir ecosystem; code drift is the main risk)
