# Phase 132: Generalization Proof (rindle) + Compat Matrix — Research

**Researched:** 2026-06-26
**Domain:** Elixir companion package extraction, Hex publish pipeline, compatibility matrix drift testing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
All 19 decisions D-01..D-19 are locked (delegated as a single coherent recommendation set,
2026-06-26). Do not relitigate. See CONTEXT.md §Implementation Decisions for the full text.

Summary of the binding constraints:
- Rindle + its owned `Contracts` (UploadGrant/CaptureEvidence/MediaObject) + `Reconciliation`
  (Attempt/IdempotencyKey/EvidenceResult) move to `packages/crosswake_rindle/`; module names preserved.
- Zero rindle-specific branches in core lib/ (D-02). CompanionGuard MapSet gains `Crosswake.Companions.Rindle` (D-02).
- SIX core test files are coupling tests; disposition per D-03/D-04 (domain → companion lane;
  seam → rewrite in core). NOTE: CONTEXT.md listed six but the repo has SEVEN — see §Code Fact Verification.
- Compat matrix: one table, 6 columns, pinned HTML comment for drift test, 5 prose sections (D-05..D-09).
- Drift test: core-owned, hermetic, async: true, AST-parses `crosswake_dep/0` do: branch (D-10..D-13).
- Engine cap stays `{:rindle, "~> 0.1", optional: true}` (resolves 0.1.10 — latest 0.3.0 ∉ ~> 0.1) (D-14..D-16).
- Clean-room: happy-path only (validate_dependency == :ok), Contracts.media_state_vocabulary() canary, no new param needed (D-17..D-18).
- Independent versioning via release-please separate component; NOT in linked-versions (130/131 locked).

### Claude's Discretion
- Exact ExUnit module/file names, stable-id slug strings, precise drift-test helper API.
- Whether phase72/phase45 CI folds into a new `phase132-proof.yml` or the `phase130-proof.yml` companion-lane pattern — recommend one workflow per companion lane.
- Exact brand-voice microcopy in failure strings and matrix prose.
- Whether engine-present stub rides a tag + conditional `elixirc_paths` or a separate alias (inherit rulestead's settled pattern).
- Whether the four media helpers are copied vs. relative-pathed for the moved phase72 (recommend copy).

### Deferred Ideas (OUT OF SCOPE)
- Widening rindle engine cap to `~> 0.3`.
- sigra/chimeway/threadline extraction (EXTRACT-FUT).
- `Crosswake.Telemetry` public API (Phase 133).
- Shell lifecycle + native UAT (Phase 134).
- Adopter-facing clean-room proving richer companion behavior beyond resolvability + happy-path doctor.
- Generating the matrix doc from code.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EXTRACT-07 | `rindle` is extracted by the identical recipe (including owned `Contracts` incl. `MediaObject` and `Reconciliation`) and goes live on Hex, independently versioned. | §Standard Stack, §Architecture Patterns, §Code Fact Verification, §Validation Architecture |
| SEAM-05 | The same extraction checklist applies to a second companion with no companion-specific branches added to core. | §Code Fact Verification (D-02 seam-clean confirmed), §Architecture Patterns |
| COMPAT-02 | An adopter can read `guides/companion_compatibility.md` to learn each companion's minimum required core version and the cross-package compatibility matrix. | §Architecture Patterns (matrix shape), §Code Examples (table template) |
| COMPAT-03 | A drift test fails if any companion's declared `{:crosswake, "~> ..."}` requirement is missing from the compatibility matrix doc. | §Architecture Patterns (drift test design), §Code Examples (AST parse pattern), §Validation Architecture |
</phase_requirements>

---

## Summary

Phase 132 is a recipe-reuse phase, not a design phase. The extraction recipe (`script/extract_companion.md`) was proven on rulestead in Phases 130–131. This phase applies it to rindle by substitution, then adds two new deliverables that generalize across all companions: the compatibility matrix doc (`guides/companion_compatibility.md`, COMPAT-02) and the drift test that keeps it honest (`test/crosswake/proof/phase132_compat_matrix_drift_test.exs`, COMPAT-03).

The primary mechanical complexity is the test coupling: the repo has **seven** (not six as CONTEXT.md listed) core test files that alias rindle internals and will fail to compile once the modules move. Six split between companion-lane moves and one seam-rewrite; the seventh (`phase45_rindle_live_test.exs`, tagged `:requires_example_host`) uses only Phoenix aliases — no rindle internals — but requires disposition. The matrix and drift test are net-new, with the drift test being the most novel implementation work since it must AST-parse the `crosswake_dep/0` env-conditional function to extract the Hex requirement string.

**Primary recommendation:** Scaffold `packages/crosswake_rindle/` from the rulestead copy-template first (1 wave), handle the test-coupling migrations next (1 wave), and ship the drift test + matrix doc + release pipeline extensions in the final wave. Three-wave structure, mirroring Phase 130's plan shape.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Rindle adapter + domain types | Companion package (`packages/crosswake_rindle/`) | — | Extraction is the whole point; core lib/ must shed this |
| CompanionGuard enforcement (EXTRACT-03/04) | Core lib/ → proof test | — | Guard lives in core; adding Rindle to frozen MapSet is a core edit |
| Compat matrix doc | Core `guides/` | — | Core owns all companion docs; companions can't bidirectionally check each other |
| Drift test (COMPAT-03) | Core proof lane | — | Must read both companion mix.exs files and the core doc simultaneously |
| Release-please / publish pipeline | CI (`.github/workflows/release-please.yml`) | `release-please-config.json` | Same structure as rulestead component |
| Clean-room CI lane | CI (inside `release-please.yml`) | `script/verify_companion_cleanroom.sh` | Delegates logic to script; YAML stays thin (131-D-16) |
| Engine-absent/present test lanes | Companion package test structure | Core mix.exs `companions.test` alias | Mirrors rulestead's `packages/crosswake_rulestead/` test structure |

---

## Standard Stack

### Core (all pre-existing — no new deps)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir stdlib `Code.string_to_quoted/2` + `Macro.prewalk/3` | built-in | AST-parse companion mix.exs for drift test | Repo idiom (phase65/129/130); no external dep [VERIFIED: live repo grep] |
| `Path.wildcard/1` | built-in | Enumerate `packages/*/mix.exs` for drift test | Repo idiom for non-vacuity guard [VERIFIED: live repo grep] |
| `Crosswake.TestSupport.ProofAssertions.stable_id_message/7` | core test support | Teaching failure messages in drift test | Already in `test/support/proof_assertions.ex` [VERIFIED: live repo] |
| `ExUnit` async: true | built-in | Hermetic proof lane | Read-only drift test qualifies (no Application state mutation) [VERIFIED: live repo pattern] |
| `release-please` (Google) | CI-managed | Companion component versioning | rulestead component proven in Phase 131 [VERIFIED: live `release-please-config.json`] |
| `script/verify_companion_cleanroom.sh` | shell, in-repo | Post-publish clean-room proof | Already parameterized for rindle: `bash script/verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle` [VERIFIED: live script] |
| `script/verify_companion_package.sh` | shell, in-repo | Hex tarball structure gate | Used for rulestead; needs parameterization for rindle (line 53 hardcode) [VERIFIED: live script] |

**No new Hex dependencies introduced by this phase.**

---

## Package Legitimacy Audit

No new external packages are introduced in this phase. All dependencies are either in-tree scripts, Elixir stdlib, or pre-existing project dependencies.

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious (SUS):** none

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Core (lib/)                                                │
│  ┌───────────────────────┐   ┌──────────────────────────┐  │
│  │ Crosswake.Companion   │   │ CompanionGuard           │  │
│  │ @behaviour (frozen 5) │   │ frozen MapSet += Rindle  │  │
│  └───────────────────────┘   └──────────────────────────┘  │
│                                                             │
│  guides/companion_compatibility.md ◄─── pinned col contract│
│            ▲                                                │
│            │ drift test reads + asserts parity             │
│  test/crosswake/proof/phase132_compat_matrix_drift_test.exs│
│            │ AST-parses crosswake_dep/0 do: branch         │
│            ▼                                               │
│  packages/crosswake_rulestead/mix.exs  ─────────────┐     │
│  packages/crosswake_rindle/mix.exs ─────────────────┘     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  packages/crosswake_rindle/                                 │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  lib/crosswake/companions/rindle.ex  (adapter)       │  │
│  │  lib/crosswake/companions/rindle/contracts.ex        │  │
│  │  lib/crosswake/companions/rindle/reconciliation.ex   │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  test/ (companion lane: phase45_companion,           │  │
│  │         phase45_mock_media, phase45_advisory,        │  │
│  │         phase45_live, phase72_media_evidence,        │  │
│  │         contracts_test, reconciliation_test)         │  │
│  │  test/support/ (StudySessionLive stub, media helpers,│  │
│  │                 engine_present/ fake Rindle stub)    │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

CI Flow (release-please.yml):
  release-please
       │ rindle_release_created == 'true'
       ▼
  publish-hex-rindle (deps.get → compile → test → dry-run → publish)
       │ needs: [release-please, publish-hex-rindle]
       ▼
  clean-room-proof-rindle → verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle
```

### Recommended Project Structure

```
packages/crosswake_rindle/                   # copy-template from crosswake_rulestead
├── mix.exs                                  # crosswake_dep/0 env-conditional + # x-release-please-version
├── lib/
│   └── crosswake/companions/
│       ├── rindle.ex                        # moved from core lib/
│       └── rindle/
│           ├── contracts.ex                 # moved from core lib/
│           └── reconciliation.ex            # moved from core lib/
├── test/
│   ├── test_helper.exs
│   ├── support/
│   │   ├── study_session_live.ex            # copied from core test/support/
│   │   └── example_host/
│   │       ├── reconciliation_keys.ex       # copied from examples/phoenix_host/lib/...
│   │       ├── reconciliation_inbox.ex      # copied from examples/phoenix_host/lib/...
│   │       ├── mock_capture.ex              # copied from examples/phoenix_host/lib/...
│   │       ├── media_projection.ex          # copied from examples/phoenix_host/lib/...
│   │       └── media_lane_live.ex           # copied from examples/phoenix_host/lib/...
│   │   engine_present/
│   │       └── rindle.ex                    # fake top-level Rindle stub (D-33 pattern)
│   └── crosswake/proof/
│       ├── phase45_rindle_companion_test.exs   # moved from core
│       ├── phase45_rindle_mock_media_test.exs  # moved from core (Code.require_file → test/support/example_host/)
│       ├── phase45_rindle_advisory_test.exs    # moved from core
│       ├── phase45_rindle_live_test.exs        # moved from core (requires_example_host)
│       ├── phase72_media_evidence_workflow_proof_test.exs  # moved from core
│       └── (contracts_test / reconciliation_test moved from core/test/crosswake/companions/rindle/)
```

```
Core changes:
guides/companion_compatibility.md             # NEW — COMPAT-02
test/crosswake/proof/
  phase132_compat_matrix_drift_test.exs       # NEW — COMPAT-03
lib/crosswake/companion_guard.ex              # add "Crosswake.Companions.Rindle" to @extracted_companion_names
test/crosswake/guides/companions_test.exs     # REWRITE lines 122/131 (seam-only, no internal alias)
test/crosswake/proof/phase47_companion_arc_test.exs  # PARTIAL REWRITE — see §Resolved Investigation Items
mix.exs                                       # add crosswake_rindle to companions.test alias
.github/workflows/phase132-proof.yml          # NEW — rindle companion lane
.github/workflows/release-please.yml          # add publish-hex-rindle + clean-room-proof-rindle jobs
release-please-config.json                    # add packages/crosswake_rindle component
.release-please-manifest.json                 # add "packages/crosswake_rindle": "0.1.0"
script/verify_companion_package.sh            # parameterize line 53 (rulestead.ex hardcode)
```

---

## Code Fact Verification

This section is the primary new value CONTEXT.md deferred to research. Each claim in CONTEXT.md is verified against the live repo.

### ✅ Confirmed: Source files exist and public API matches

- `lib/crosswake/companions/rindle.ex` — EXISTS. `companion_id/0` → `:rindle`, `validate_dependency/0` uses `Code.ensure_loaded?(Rindle)` at function-body runtime (lines 27 and 41), `enabled?/1`, `report_state/0` — all confirmed. No `@compile {:no_warn_undefined, Rindle}` present yet (it lives in the companion adapter only after extraction — rulestead.ex line 9 has it; rindle.ex currently in core lib/ does NOT need it because rindle modules exist in core until moved). [VERIFIED: live repo]

- `lib/crosswake/companions/rindle/contracts.ex` — EXISTS. `media_state_vocabulary/0` returns `[:queued, :uploaded, :scanning, :available, :rejected]` (line 124). `new_media_object/1` exists (line 157). `UploadGrant`, `CaptureEvidence`, `MediaObject` nested modules confirmed. [VERIFIED: live repo]

- `lib/crosswake/companions/rindle/reconciliation.ex` — EXISTS. `Attempt`, `IdempotencyKey`, `EvidenceResult` nested modules confirmed. Aliases `Crosswake.Companions.Rindle.Contracts` (line 10) — this import will naturally move with the file. [VERIFIED: live repo]

- `test/crosswake/companions/rindle/contracts_test.exs` — EXISTS, `async: true`, zero `test/support` deps. [VERIFIED: live repo]

- `test/crosswake/companions/rindle/reconciliation_test.exs` — EXISTS, `async: true`, aliases `Contracts` and `Reconciliation`. [VERIFIED: live repo]

### ✅ Confirmed: rulestead package copy-template shape

- `packages/crosswake_rulestead/mix.exs` lines 64-68: `defp crosswake_dep do if System.get_env("CROSSWAKE_RELEASE") == "1", do: {:crosswake, "~> 0.1"}, else: {:crosswake, path: "../.."} end` — EXACT match to CONTEXT.md D-11 claim. `# x-release-please-version` marker at line 4. Engine cap `{:rulestead, "~> 0.1", optional: true}` at line 54. Files allowlist excludes `test/`. [VERIFIED: live repo]

- `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` line 9: `@compile {:no_warn_undefined, Rulestead}` confirmed — the companion adapter needs this once the engine is optional. [VERIFIED: live repo]

### ✅ Confirmed: CompanionGuard — current state (Rindle NOT yet added)

- `lib/crosswake/companion_guard.ex` line 37: `@extracted_companion_names` contains only `"Crosswake.Companions.Rulestead"`. `"Crosswake.Companions.Rindle"` is **NOT yet present** — adding it is a required edit in this phase. The guard comment says "Change this attribute AND remove the source from lib/ in the SAME PR." [VERIFIED: live repo]

### ✅ Confirmed: `verify_companion_package.sh` hardcodes rulestead

- Line 53: `if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]` — hardcoded `rulestead.ex`. CONTEXT.md correctly identifies lines 53/54 as the hardcode. (Line 81 references `Rulestead` only in a comment, not an executable check.) The fix: derive from `$PACKAGE` using shell substitution: `COMPANION_PATH=$(echo "$PACKAGE" | sed 's/crosswake_//') && if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/${COMPANION_PATH}.ex" ]`. [VERIFIED: live repo]

### ✅ Confirmed: `crosswake_dep/0` AST shape (the drift test parse target)

Rulestead mix.exs lines 64-68 literal:
```elixir
defp crosswake_dep do
  if System.get_env("CROSSWAKE_RELEASE") == "1",
    do: {:crosswake, "~> 0.1"},
    else: {:crosswake, path: "../.."}
end
```
The AST for the `do:` branch is `{:crosswake, "~> 0.1"}` — a 2-tuple. The drift test must find the `defp crosswake_dep` node, walk into the `if` expression's `do:` keyword, and extract the string literal `"~> 0.1"`. A bare `grep crosswake` on the file returns two hits (the `do:` Hex dep AND the `else:` path dep); the AST parse is mandatory to isolate the correct value. [VERIFIED: live repo]

### ✅ Confirmed: `verify_companion_cleanroom.sh` is already parameterized for rindle

Lines 39-46 confirm params `$1 PACKAGE`, `$2 VERSION`, `$3 ENGINE_PACKAGE` (default `rulestead`), `$4 ENGINE_MODULE` (default `Rulestead`). Calling it as `bash script/verify_companion_cleanroom.sh crosswake_rindle 0.1.0 rindle Rindle` needs no script changes except the Contracts canary described in D-18. The script derives `COMPANION_MODULE_SUFFIX` from `$PACKAGE` via string manipulation (lines 188-189) — `crosswake_rindle` → `Rindle` — correctly. [VERIFIED: live repo]

### ✅ Confirmed: `clean-room-proof-rulestead` job shape (copy-template for rindle)

`release-please.yml` line 627: `clean-room-proof-rulestead` job. Structure: `needs: [release-please, publish-hex-rulestead]`, gated on `rulestead_release_created == 'true'`, delegates everything to `verify_companion_cleanroom.sh crosswake_rulestead "${{ needs.release-please.outputs.rulestead_version }}"`. The rindle version is a direct copy-substitute. [VERIFIED: live repo]

### ✅ Confirmed: release-please-config.json + manifest current state

- `release-please-config.json`: has `packages/crosswake_rulestead` as a separate `elixir` component with `separate-pull-requests: true`, `release-as: "0.1.0"`. `packages/crosswake_rindle` is NOT present — must be added. [VERIFIED: live repo]
- `.release-please-manifest.json`: `{"." : "0.1.2", ..., "packages/crosswake_rulestead": "0.1.0"}`. `packages/crosswake_rindle` baseline NOT present — must be added as `"0.1.0"`. [VERIFIED: live repo]

### ✅ Confirmed: `phase47_companion_arc_test.exs` — classification decision (PLANNER INVESTIGATION resolved)

CONTEXT.md D-03 says "PLANNER INVESTIGATION (do not skip)." Research resolves this:

`phase47_companion_arc_test.exs` contains **five tests**, each analyzed:

1. **"enabled optional dependency findings track live companion validation outcomes"** (line 104) — iterates `[Rulestead, Rindle]` and calls `companion.validate_dependency()` through the `@behaviour` seam (`Doctor.run/1`). Uses `Crosswake.Companions.Rindle` adapter alias (line 4) — NOT `.Contracts` or `.Reconciliation`. This tests the generic companion seam (Doctor/RouteGate/validate_dependency), not rindle domain internals. → **KEEP in core; rewrite to use a StubRindleAbsentCompanion** (or keep the `alias Crosswake.Companions.Rindle` if the module remains reachable post-move via the poncho path dep — but once moved, core lib/ won't compile this alias without a path dep in core's mix.exs, which is forbidden). **Correct disposition: move this file to companion lane OR rewrite to use two stubs.** Since this test drives `Doctor.run` through the `@behaviour`/registry seam using two live adapter modules, the cleanest option is a **partial rewrite**: keep the test in core, replace `alias Crosswake.Companions.Rindle` with a `StubRindleAbsentCompanion` stub (pattern already established with `StubRulesteadAbsentCompanion`).

2. **"disabled companions suppress dependency_missing findings"** (line 137) — same cross-companion seam pattern. Same disposition as above.

3. **"sigra auth truth reflects session-authority posture..."** (line 152) — calls `SupportMatrix.auth_contract_truth()` only. No rindle alias. → **KEEP in core as-is.**

4. **"auth-predicated route denies with step_up_required..."** (line 168) — uses `RouteGate.evaluate`, `Manifest.compile`, `AuthContext`. No rindle alias. → **KEEP in core as-is.**

5. **"hermetic lane guard: proof file remains untagged..."** (line 197) — self-scan of the test file source. Checks `MIX_INCLUDE_RINDLE` absence. → **KEEP in core; update the string check to reference the new stub pattern.**

6. **"hermetic lane guard: denial vocabulary..."** (line 210) — `Denial.reasons()` only. → **KEEP in core as-is.**

**Final disposition for `phase47_companion_arc_test.exs`:** KEEP IN CORE. Rewrite tests 1 and 2 to replace `alias Crosswake.Companions.Rindle` with a new `StubRindleAbsentCompanion` (same pattern as `StubRulesteadAbsentCompanion` already in `test/support/stub_companion.ex`). Tests 3–6 need no changes. This is the correct seam-rewrite described in CONTEXT.md D-03 for the "asserts generic `@behaviour`/registry seam" case.

### ⚠️ DRIFT DISCOVERED: CONTEXT.md listed SIX coupling tests; repo has SEVEN

CONTEXT.md D-03 lists SIX files. The repo actually contains SEVEN:

| File | CONTEXT.md Listed | Actual Disposition |
|------|------------------|--------------------|
| `phase72_media_evidence_workflow_proof_test.exs` | Yes | Move to companion lane |
| `phase45_rindle_mock_media_test.exs` | Yes | Move to companion lane |
| `phase45_rindle_companion_test.exs` | Yes | Move to companion lane |
| `phase45_rindle_advisory_test.exs` | Yes | Move to companion lane |
| `phase47_companion_arc_test.exs` | Yes (investigate) | Keep in core; partial rewrite (see above) |
| `test/crosswake/guides/companions_test.exs` | Yes (rewrite) | Keep in core; rewrite lines 122/131 |
| **`phase45_rindle_live_test.exs`** | **NOT LISTED** | **See analysis below** |

**`phase45_rindle_live_test.exs` analysis:** Tagged `:requires_example_host`. Uses `Code.require_file` for five media helpers from `examples/phoenix_host/lib/`. Does NOT alias `Crosswake.Companions.Rindle.*` at all (only `Phoenix.Component` and `Phoenix.LiveViewTest`). It tests the LiveView UI behavior of `CrosswakeExample.Media.MediaLaneLive`. This file tests example-host behavior, not the rindle companion adapter or domain model. **Disposition: Move to companion lane.** The five media helpers it `Code.require_file`s must be copied into `packages/crosswake_rindle/test/support/example_host/` (already planned for phase45_mock_media/phase72 — this adds `media_lane_live.ex` to the copy list, making it five helpers total, not four as CONTEXT.md's D-04 states).

**Planner action:** Add `phase45_rindle_live_test.exs` as an eighth move/rewrite item. Update the media helper copy list to include `media_lane_live.ex` (5 files, not 4). The `Code.require_file` paths in the moved test must be rewritten to reference `test/support/example_host/` within the companion package.

### ✅ Confirmed: `companions_test.exs` lines 122/131/150/228 — seam-rewrite shape

Live code at:
- Line 122: `Code.ensure_loaded!(Crosswake.Companions.Rindle)` → becomes `Code.ensure_loaded!(Crosswake.Companion)` (or deleted — the line is a guard that the module compiled)
- Line 131: `assert function_exported?(Crosswake.Companions.Rindle, :validate_dependency, 0)` → becomes an assertion through the seam: the registered companion (StubRindleAbsentCompanion) reports `:rindle` as companion_id, and the core `@behaviour` declares `validate_dependency/0`
- Line 150 and 228: `Crosswake.Companions.Rindle` used as an element in the companions list passed to `Application.put_env` — replace with `StubRindleAbsentCompanion`

The test at line 116 already has a comment explaining the rulestead extraction pattern. The rindle extraction rewrite follows the identical idiom. The `StubRindleAbsentCompanion` needs to be created in `test/support/` (analog of `StubRulesteadAbsentCompanion`). [VERIFIED: live repo — lines read and confirmed]

### ✅ Confirmed: `mix.exs` `companions.test` alias only covers rulestead

Line 59: `"companions.test": ["cmd --cd packages/crosswake_rulestead mix test"]` — must be extended to `["cmd --cd packages/crosswake_rulestead mix test", "cmd --cd packages/crosswake_rindle mix test"]`. [VERIFIED: live repo]

### ✅ Confirmed: `phase72-proof.yml` exists and is currently merge-blocking

`.github/workflows/phase72-proof.yml` runs `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` on `pull_request` and `push` to main. Once phase72 moves to the companion lane, this workflow needs to be redirected to run from within `packages/crosswake_rindle/` (or folded into the new `phase132-proof.yml` companion lane). The `runs-on: macos-15` is unusual for a hermetic proof — post-move the companion lane should run on `ubuntu-latest` (cheaper, consistent with phase130-proof.yml). [VERIFIED: live repo]

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Extracting the Hex requirement from `crosswake_dep/0` | Custom string parser, `grep crosswake`, `deps/0` eval | `Code.string_to_quoted/2` + `Macro.prewalk/3` on the file | The env-conditional function returns two different strings depending on env var; grep gets both; `deps/0` eval is non-hermetic and not async-safe (D-11) |
| Parsing the compat matrix doc | A markdown parser Hex dep | Targeted regex on the package-name-keyed row | A regex on the specific `~>`-prefixed cell in the known column position (anchored by the HTML comment contract) is sufficient and adds no deps |
| Verifying the Contracts canary in clean-room | New script parameter | A small `if [ "$PACKAGE" = crosswake_rindle ]` block in `verify_companion_cleanroom.sh` | One conditional in the script body; the canary is rindle-specific so it belongs inside the parameterized script, not as a separate file |
| Engine-present test stub for Rindle | A real `rindle` Hex dep in test | Fake `defmodule Rindle do end` stub in `test/engine_present/` | Same `ENGINE_PRESENT_LANE=1` + `elixirc_paths/1` pattern as rulestead; no live network needed for the engine-present advisory proof lane |
| Cross-companion seam tests in `phase47` | Moving the whole file to companion lane | Partial rewrite replacing `Crosswake.Companions.Rindle` alias with `StubRindleAbsentCompanion` | The test drives `Doctor.run` through the `@behaviour` seam — keeping it in core with stubs is the principled call; moving it would re-couple through the companion lane |

---

## Common Pitfalls

### Pitfall 1: Bare `grep crosswake` extracts the wrong requirement string
**What goes wrong:** The drift test greps `packages/crosswake_rindle/mix.exs` and matches `"crosswake"`. Since `crosswake_dep/0` contains both `{:crosswake, "~> 0.1"}` and `{:crosswake, path: "../.."}`, grep returns two hits — or captures the path dep string.
**Why it happens:** The env-conditional function body contains `"crosswake"` in both branches.
**How to avoid:** AST-parse the file. Find the `defp crosswake_dep` function node. Walk into the `if` expression. Take the `do:` keyword value (`{:crosswake, "~> 0.1"}`). Extract the version string literal. This is the D-11 canonical approach proven in phase130.
**Warning signs:** Test passes even when `CROSSWAKE_RELEASE` is unset; extracted string contains `"path:"`.

### Pitfall 2: `verify_companion_package.sh` fails for rindle with file-not-found error
**What goes wrong:** Step 1 of the script checks for `$UNPACK_DIR/lib/crosswake/companions/rulestead.ex` (line 53) regardless of the `$PACKAGE` argument. When called with `crosswake_rindle`, it checks for the rulestead file and fails.
**Why it happens:** The check was hardcoded when only rulestead existed.
**How to avoid:** Derive the companion source path from `$PACKAGE` — strip the `crosswake_` prefix to get the companion name, then check `lib/crosswake/companions/${COMPANION_NAME}.ex`. [VERIFIED: line 53 of live script]
**Warning signs:** `verify_companion_package.sh crosswake_rindle` exits immediately with "rulestead.ex not found in unpacked tarball."

### Pitfall 3: Empty-glob silent pass in drift test
**What goes wrong:** The drift test runs `Path.wildcard("packages/*/mix.exs")` before `packages/crosswake_rindle/` is created. Returns `["packages/crosswake_rulestead/mix.exs"]` — a list of 1 — and the test iterates over one companion instead of two, potentially passing vacuously.
**Why it happens:** Wildcard expansion is never empty during development if rulestead exists.
**How to avoid:** Assert `length(paths) >= 2` before the loop. This is the D-13 non-vacuity guard from CONTEXT.md (and the Phase 130 EXTRACT-03 footgun pattern). [ASSUMED: pattern from 130; not yet in a drift test that doesn't exist yet]
**Warning signs:** Drift test passes on a branch where `packages/crosswake_rindle/` has not been created.

### Pitfall 4: `Code.require_file` paths break after moving phase45_rindle_live_test.exs
**What goes wrong:** The test file's `Code.require_file` calls use relative paths from `test/crosswake/proof/` to `examples/phoenix_host/lib/...`. After moving to `packages/crosswake_rindle/test/crosswake/proof/`, the relative paths are wrong.
**Why it happens:** `Code.require_file` takes a path relative to `__DIR__`. The directory depth changes.
**How to avoid:** Copy the five media helpers into `packages/crosswake_rindle/test/support/example_host/` and rewrite the `Code.require_file` calls to `Path.join([__DIR__, "../../support/example_host", "filename.ex"])`. This is the D-04 copy approach (safe because the hermeticity self-scan matches on basename).
**Warning signs:** `Code.require_file` raises `{:error, :enoent}` at test compile time.

### Pitfall 5: Phantom row in drift test if doc is written before package exists
**What goes wrong:** The matrix doc is written with a `crosswake_rindle` row before `packages/crosswake_rindle/mix.exs` exists. The drift test's "phantom doc row" check fires.
**Why it happens:** Ordering: doc before package scaffold.
**How to avoid:** Scaffold `packages/crosswake_rindle/mix.exs` with the correct `crosswake_dep/0` before writing the matrix doc, OR write the drift test to tolerate the doc row + package being added in the same PR (which is correct — they should land together).
**Warning signs:** Drift test assertion `no matching package — phantom doc row` fires on a PR that adds both.

### Pitfall 6: `release-as` leftover after first release PR merges
**What goes wrong:** The `release-as: "0.1.0"` stays in `release-please-config.json` after the first Release PR for `crosswake_rindle` merges, causing release-please to always propose version 0.1.0 on subsequent PRs.
**Why it happens:** `release-as` is a one-shot override; it must be removed after the first Release PR is merged (D-04 runbook from 131, "cross-ref Step 12f for rindle").
**How to avoid:** Add a TODO comment in the config. Include it explicitly in the Phase 132 verify-work checklist.

### Pitfall 7: `phase45_rindle_advisory_test.exs` still references `MIX_INCLUDE_RINDLE`
**What goes wrong:** The advisory test (line 7 of that file) references `MIX_INCLUDE_RINDLE=1` in its moduledoc. After extraction, the advisory lane uses `ENGINE_PRESENT_LANE=1` pattern (rulestead idiom). The moduledoc becomes misleading.
**Why it happens:** The advisory test was written before the extraction pattern was settled.
**How to avoid:** Update the moduledoc when moving the file to the companion lane to reference `ENGINE_PRESENT_LANE=1` (or the equivalent). The actual `@moduletag :advisory_only` tag should become `@moduletag :engine_present` (mirroring rulestead's phase43 advisory test).
**Warning signs:** CI instructions reference a deleted env var.

---

## Resolved Investigation Items

### D-03: `phase47_companion_arc_test.exs` — Per-assertion disposition (resolved above)

Confirmed: this is a CROSS-companion seam test. It drives `Doctor.run`, `RouteGate.evaluate`, `SupportMatrix.auth_contract_truth`, and `Denial.reasons` — all generic seam surfaces. The rindle-specific coupling is solely via `alias Crosswake.Companions.Rindle` (line 4) used in tests 1–2 to get the live adapter.

**Resolved disposition:** KEEP IN CORE. Create `StubRindleAbsentCompanion` in `test/support/stub_companion.ex` (alongside `StubRulesteadAbsentCompanion`). Replace `alias Crosswake.Companions.Rindle` with `alias Crosswake.TestSupport.StubRindleAbsentCompanion, as: Rindle`. The six tests that do NOT use rindle internals need no changes.

### `companions_test.exs` lines 122/131/150/228 — Seam-rewrite shape (confirmed)

**Line 122 (`Code.ensure_loaded!(Crosswake.Companions.Rindle)`):** Remove — the rulestead comment on line 117 explains why (`Core only guards the seam + remaining in-tree companions`). No corresponding seam assertion is needed; `Crosswake.Companion` behaviour is already loaded on line 120.

**Line 131 (`function_exported?(Crosswake.Companions.Rindle, :validate_dependency, 0)`):** Remove — the extracted companion's API guard lives in the companion lane test (mirrors the rulestead extraction precedent: "Its API guard is now in the companion's own test lane" per line 118 comment).

**Line 150 (`Crosswake.Companions.Rindle` in companions list):** Replace with `StubRindleAbsentCompanion` — consistent with rulestead's replacement pattern (`StubRulesteadAbsentCompanion` on line 149).

**Line 228 (`Crosswake.Companions.Rindle` in companions list):** Same substitution as line 150.

---

## Code Examples

Verified patterns from the live repo:

### AST-parse `crosswake_dep/0` to extract Hex requirement (drift test core pattern)

```elixir
# Source: packages/crosswake_rulestead/mix.exs lines 64-68 (the target shape)
# Technique: Code.string_to_quoted/2 + Macro.prewalk/3 (repo idiom, phase65/129/130)

defp extract_crosswake_requirement(mix_exs_path) do
  source = File.read!(mix_exs_path)
  {:ok, ast} = Code.string_to_quoted(source)

  result = Macro.prewalk(ast, nil, fn
    # Match: defp crosswake_dep do if ..., do: {:crosswake, "~> X.Y"}, else: ...
    {:defp, _, [{:crosswake_dep, _, _}, [do: if_expr]]} = node, _acc ->
      # Extract the do: branch of the if expression
      req_string = extract_hex_requirement_from_if(if_expr)
      {node, req_string}
    node, acc ->
      {node, acc}
  end)

  elem(result, 1)
end

defp extract_hex_requirement_from_if({:if, _, [_condition, [do: {:crosswake, req}, else: _]]}) do
  req  # e.g. "~> 0.1"
end
```

### Drift test structure (COMPAT-03)

```elixir
# Source: CONTEXT.md D-10..D-13 (the locked design)
# File: test/crosswake/proof/phase132_compat_matrix_drift_test.exs
defmodule Crosswake.Proof.Phase132CompatMatrixDriftTest do
  use ExUnit.Case, async: true
  # No tags — untagged, not :requires_example_host, not :advisory_only
  alias Crosswake.TestSupport.ProofAssertions

  @doc_path Path.join([File.cwd!(), "guides", "companion_compatibility.md"])

  test "companion_compatibility.md doc exists" do
    # Distinct failure: "the doc doesn't exist" ≠ "a row is wrong"
    assert File.exists?(@doc_path),
           ProofAssertions.stable_id_message(
             "proof.compat_03.doc_exists",
             "companion_compatibility.md",
             "phase132_compat_matrix_drift_test.exs",
             "file missing",
             @doc_path,
             "run: touch guides/companion_compatibility.md and fill COMPAT-02 content",
             "merge-blocking"
           )
  end

  test "at least two companion packages exist (non-vacuity guard)" do
    paths = Path.wildcard("packages/crosswake_*/mix.exs")
    assert length(paths) >= 2,
           "expected at least 2 companion packages, found #{length(paths)} — " <>
           "rindle extraction may not be complete"
  end

  test "every companion mix.exs crosswake requirement matches the doc" do
    doc = File.read!(@doc_path)
    paths = Path.wildcard("packages/crosswake_*/mix.exs")

    for path <- paths do
      pkg = path |> Path.dirname() |> Path.basename()
      req = extract_crosswake_requirement(path)

      assert req != nil,
             "could not extract crosswake_dep/0 Hex requirement from #{path}"

      # BIDIRECTIONAL: (a) doc row exists for this package
      assert doc =~ pkg,
             ProofAssertions.stable_id_message(
               "proof.compat_03.matrix_drift.#{pkg}.missing_from_doc",
               "companion_compatibility.md",
               path,
               "package #{pkg} has no row in the doc",
               @doc_path,
               "add a row for #{pkg} to guides/companion_compatibility.md",
               "merge-blocking"
             )

      # (b) version in doc matches mix.exs literal (exact string match — no semver equivalence)
      assert doc =~ req,
             ProofAssertions.stable_id_message(
               "proof.compat_03.matrix_drift.#{pkg}.version_mismatch",
               "companion_compatibility.md",
               path,
               "doc says != crosswake_dep/0 literal #{inspect(req)}",
               @doc_path,
               "update the '#{pkg}' row in guides/companion_compatibility.md to match #{inspect(req)}",
               "merge-blocking"
             )
    end

    # PHANTOM check: every doc row has a real package
    for line <- String.split(doc, "\n") do
      if String.starts_with?(String.trim(line), "| `crosswake_") do
        pkg = Regex.run(~r/`(crosswake_\w+)`/, line, capture: :all_but_first) |> List.first()
        if pkg do
          assert File.exists?("packages/#{pkg}/mix.exs"),
                 ProofAssertions.stable_id_message(
                   "proof.compat_03.matrix_drift.#{pkg}.phantom_doc_row",
                   "companion_compatibility.md",
                   @doc_path,
                   "doc row for #{pkg} has no corresponding packages/#{pkg}/mix.exs",
                   @doc_path,
                   "remove the #{pkg} row from the doc, or create the package",
                   "merge-blocking"
                 )
        end
      end
    end
  end
end
```

### Companion compatibility matrix doc — locked table shape (COMPAT-02)

```markdown
<!-- compat-03 contract: col1=Hex Package, requirement cell = "Requires `crosswake`";
     do not reorder columns without updating phase132_compat_matrix_drift_test.exs -->
| Hex Package | Companion ID | Current Version | Requires `crosswake` | Engine Dependency | hexdocs |
|---|---|---|---|---|---|
| `crosswake_rulestead` | `:rulestead` | `0.1.0` | `~> 0.1` | `{:rulestead, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rulestead](https://hexdocs.pm/crosswake_rulestead) |
| `crosswake_rindle`    | `:rindle`    | `0.1.0` | `~> 0.1` | `{:rindle, "~> 0.1", optional: true}`    | [hexdocs.pm/crosswake_rindle](https://hexdocs.pm/crosswake_rindle)       |
```

### CompanionGuard — add Rindle to frozen MapSet

```elixir
# Source: lib/crosswake/companion_guard.ex @extracted_companion_names (line 37 area)
# Current (Phase 131):
@extracted_companion_names [
  "Crosswake.Companions.Rulestead"
]

# After Phase 132:
@extracted_companion_names [
  "Crosswake.Companions.Rulestead",
  "Crosswake.Companions.Rindle"   # Phase 132: rindle adapter extracted
]
```

### StubRindleAbsentCompanion (needed in test/support/stub_companion.ex)

```elixir
# Source: Mirrors StubRulesteadAbsentCompanion already in test/support/stub_companion.ex
defmodule Crosswake.TestSupport.StubRindleAbsentCompanion do
  @behaviour Crosswake.Companion

  def companion_id, do: :rindle
  def enabled?(config), do: Map.get(config, :enabled, false)
  def route_gated?(_route, _target), do: :pass
  def kill_switch_active?(_target), do: false
  def validate_dependency, do: {:error, [:"Elixir.Rindle"]}
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :rindle,
      enabled: false,
      dependency_status: {:missing, [Rindle]},
      gate_status: :unconfigured,
      kill_switch_status: :inactive,
      checked_at: System.monotonic_time(:millisecond),
      details: %{}
    }
  end
end
```

### `packages/crosswake_rindle/mix.exs` structure (from rulestead template)

```elixir
# Source: packages/crosswake_rulestead/mix.exs — copy-substitute Rulestead→Rindle, rulestead→rindle
defmodule CrosswakeRindle.MixProject do
  use Mix.Project

  @version "0.1.0" # x-release-please-version
  @source_url "https://github.com/szTheory/crosswake"

  # ... (identical project/0, application/0 structure)

  defp deps do
    [
      crosswake_dep(),
      {:rindle, "~> 0.1", optional: true}   # cap stays ~> 0.1 per D-16 (0.3.0 ∉ ~> 0.1)
    ]
  end

  defp crosswake_dep do
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp elixirc_paths(:test) do
    base = ["lib", "test/support"]
    if System.get_env("ENGINE_PRESENT_LANE") == "1", do: base ++ ["test/engine_present"], else: base
  end

  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      "engine-present.test": ["clean", "cmd ENGINE_PRESENT_LANE=1 mix test --only engine_present"]
    ]
  end

  defp package do
    [
      name: "crosswake_rindle",
      licenses: ["Apache-2.0"],
      # test/ excluded from files: (D-24); the companion ships NO priv/ or guides/ either
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end
end
```

### `verify_companion_package.sh` line 53 parameterization fix

```bash
# Before (hardcoded):
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/rulestead.ex not found in unpacked tarball ..."
  exit 1
fi

# After (parameterized from $PACKAGE):
COMPANION_NAME=$(echo "$PACKAGE" | sed 's/^crosswake_//')
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/${COMPANION_NAME}.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/${COMPANION_NAME}.ex not found in unpacked tarball — source not moved yet"
  exit 1
fi
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `MIX_INCLUDE_RINDLE=1` env hack in core mix.exs | `path:` poncho dep, removed in Phase 130 | Phase 130 | Core mix.exs has no companion deps at all |
| rindle source in `lib/crosswake/companions/rindle*.ex` (core) | Moves to `packages/crosswake_rindle/` | Phase 132 | Independently versioned Hex package |
| No compat matrix doc | `guides/companion_compatibility.md` with drift test | Phase 132 | Adopter single-source-of-truth for version compatibility |

**Deprecated/outdated:**
- `MIX_INCLUDE_RINDLE=1` env var: removed in Phase 130; Phase 132 removes the last test references.
- `phase72-proof.yml` running on `macos-15` with a hermetic Elixir test: after move, the proof runs in the companion lane on `ubuntu-latest`.

---

## Validation Architecture

> `workflow.nyquist_validation` key is absent from `.planning/config.json` — treated as ENABLED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in, no config file — standard Elixir) |
| Config file | `test/test_helper.exs` (core); `packages/crosswake_rindle/test/test_helper.exs` (NEW, mirrors rulestead) |
| Quick run command | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` |
| Full suite command | `mix verify` (runs `companions.test` + hermetic core suite excluding requires_example_host + advisory_only) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EXTRACT-07 | Rindle source + domain types absent from core lib/ (EXTRACT-03 guard green) | Unit (guard) | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ (existing guard, updated for Rindle) |
| EXTRACT-07 | `packages/crosswake_rindle/` compiles cleanly, engine-absent | Unit (companion lane) | `mix companions.test` (after alias update) | ❌ Wave 0 — package must be created |
| EXTRACT-07 | Hex tarball structure correct (test/ excluded, lib/ source present) | Integration (script) | `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rindle` | ✅ (script exists, needs line 53 fix) |
| EXTRACT-07 | Published artifact resolves + doctor exits 0 (clean-room) | Integration (CI-only) | `bash script/verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle` | ✅ (script exists, needs Contracts canary) |
| SEAM-05 | No static alias to `Crosswake.Companions.Rindle` in core lib/ after move | Unit (guard) | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ (guard extended by adding Rindle to MapSet) |
| SEAM-05 | No rindle-specific branch in core lib/ | Manual inspection + EXTRACT-03 guard | (above) | ✅ |
| COMPAT-02 | `guides/companion_compatibility.md` exists with correct table | Manual + drift test | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | ❌ Wave 0 — both doc and test are NEW |
| COMPAT-03 | Drift test fails if companion requirement missing from doc | Unit (proof lane) | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | ❌ Wave 0 — test is NEW |

### Nyquist Proof Lane Idiom (from Phase 130 established pattern)

All merge-blocking proofs are:
- Untagged (not `:advisory_only`, not `:requires_example_host`)
- `async: true` when no `Application.put_env` mutation (drift test qualifies)
- `async: false` when test mutates Application env (companion adapter tests)
- Failure messages via `ProofAssertions.stable_id_message/7` with `[crosswake]`-prefixed stable IDs
- Run via `mix test <specific_file>` in CI (not part of broad suite exclusion)

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` (COMPAT-03 gate)
- **Per wave merge:** `mix verify` (companions.test + hermetic core suite)
- **Phase gate:** Full `mix verify` green + EXTRACT-03 guard green before `/gsd-verify-work`

### Wave 0 Gaps (must create before implementation waves)

- [ ] `packages/crosswake_rindle/` — the entire package directory (scaffold from rulestead)
- [ ] `packages/crosswake_rindle/mix.exs` — required before drift test can assert ≥2 packages
- [ ] `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — NEW, covers COMPAT-02 + COMPAT-03
- [ ] `guides/companion_compatibility.md` — NEW, covers COMPAT-02
- [ ] `packages/crosswake_rindle/test/test_helper.exs` — companion lane test entry point
- [ ] `test/support/stub_companion.ex` — add `StubRindleAbsentCompanion` (alongside existing `StubRulesteadAbsentCompanion`)

---

## Security Domain

> `security_enforcement` not set to false — domain applies.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase scope is package extraction + doc authoring |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No auth changes |
| V5 Input Validation | Marginal | Drift test regex parses controlled in-tree files; no untrusted input |
| V6 Cryptography | No | No crypto |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shell injection via `$VERSION` in `verify_companion_cleanroom.sh` | Tampering | Already mitigated: line 53 of script validates `$VERSION` against semver regex before using in curl URL [VERIFIED: live script] |
| Slopsquatted package on npm/hex for `rindle` | Spoofing | `rindle` confirmed on Hex (same author `szTheory`, versions 0.1.4–0.1.10 + 0.3.0); engine cap `~> 0.1` resolves 0.1.10 — no wildcard that could resolve a hijacked package [VERIFIED: CONTEXT.md D-14, confirmed by prior subagent hex.pm investigation] |
| Stale `.beam` from engine-present leaking into engine-absent lane | Tampering | `mix clean` step in engine-present CI lane (D-33 pattern, already in phase130-proof.yml) |

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | All tasks | ✅ | 1.19.5 (from `.tool-versions`) | — |
| OTP | All tasks | ✅ | 27.3 | — |
| `mix hex` | Hex publish pipeline | ✅ | CI-installed | — |
| `python3` | `verify_companion_cleanroom.sh` Step 2 (mix.exs patch) | ✅ (CI ubuntu-latest) | 3.x | — |
| Hex.pm (live `rindle` 0.1.10) | Clean-room lane | CI-only post-publish | — | Engine-present advisory lane uses fake stub |
| `bash` | All scripts | ✅ | macOS + ubuntu-latest | — |

**Missing dependencies with no fallback:** None — all CI-gated tasks use dependencies already available in CI.

**Note:** Clean-room proof is irreversible and CI-only. It cannot run locally before the Hex publish job cuts the first `crosswake_rindle` release.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `rindle` 0.1.10 is the correct pin for the clean-room engine (latest `~> 0.1`-compliant version on Hex) | Code Fact Verification §D-14 | If Hex resolves a different 0.1.x, the clean-room may behave differently — low risk, the cap handles it |
| A2 | `StubRindleAbsentCompanion` follows the identical shape as `StubRulesteadAbsentCompanion` | Code Examples | If the Companion behaviour adds new callbacks before this phase runs, the stub will need updating — low risk |
| A3 | The drift test regex (`~r/`(crosswake_\w+)`/`) correctly extracts the package name from the matrix table col-1 cells | Code Examples (drift test pattern) | If the table format uses different backtick placement, the regex needs adjusting — low risk given pinned HTML comment |

**If this table is empty of real concerns:** All load-bearing code facts were verified against the live repo in this session. The only assumptions above are low-risk implementation details.

---

## Open Questions

1. **`phase45_rindle_advisory_test.exs` tag after move**
   - What we know: Current tag is `@moduletag :advisory_only`. In the companion package, rulestead uses `@moduletag :engine_present` for the equivalent test (`phase43_rulestead_advisory_test.exs`).
   - What's unclear: Which tag to use in the companion lane — `:advisory_only` (keeps the semantic) or `:engine_present` (matches rulestead's pattern and the `elixirc_paths` conditional).
   - Recommendation: Use `@moduletag :engine_present` to match the rulestead pattern and the `ENGINE_PRESENT_LANE=1` CI trigger. Update the `test_helper.exs` in the companion to exclude `:engine_present` by default (identical to rulestead's setup).

2. **`phase72-proof.yml` OS transition after move**
   - What we know: Currently runs on `macos-15` (unusual for a hermetic Elixir proof). Phase 130 companion lane runs on `ubuntu-latest`.
   - What's unclear: Why phase72-proof uses macOS — likely legacy from when native integration was contemplated.
   - Recommendation: The new `phase132-proof.yml` companion lane should run on `ubuntu-latest`. The old `phase72-proof.yml` should be retired (or its `merge-blocking-media-evidence-workflow-proof` job redirected to `packages/crosswake_rindle/` and OS updated to `ubuntu-latest`).

3. **`release-as: "0.1.0"` removal timing**
   - What we know: rulestead's config still has `release-as: "0.1.0"` — per 131-D-04 runbook, it should be removed after the first Release PR merges.
   - What's unclear: Whether rulestead's `release-as` has been removed yet (not checked in this session).
   - Recommendation: Planner should add an explicit task: "After first rindle Release PR merges, remove `release-as: '0.1.0'` from `packages/crosswake_rindle` block in `release-please-config.json`."

---

## Sources

### Primary (HIGH confidence)
- Live repo — `lib/crosswake/companions/rindle.ex`, `rindle/contracts.ex`, `rindle/reconciliation.ex` (direct read)
- Live repo — `test/crosswake/proof/phase47_companion_arc_test.exs` (full read, per-test analysis)
- Live repo — `test/crosswake/guides/companions_test.exs` (full read, line-by-line verification)
- Live repo — `test/crosswake/proof/phase45_rindle_*.exs`, `phase72_media_evidence_workflow_proof_test.exs` (direct read)
- Live repo — `packages/crosswake_rulestead/mix.exs` (copy-template verification)
- Live repo — `lib/crosswake/companion_guard.ex` (MapSet state confirmed)
- Live repo — `script/verify_companion_package.sh` (line 53 hardcode confirmed)
- Live repo — `script/verify_companion_cleanroom.sh` (parameterization confirmed)
- Live repo — `.github/workflows/release-please.yml` (clean-room job shape)
- Live repo — `.github/workflows/phase130-proof.yml` (companion lane structure)
- Live repo — `.github/workflows/phase72-proof.yml` (existing proof, disposition)
- Live repo — `release-please-config.json` + `.release-please-manifest.json` (current state)
- Live repo — `test/support/proof_assertions.ex` (`stable_id_message/7` signature)
- Live repo — `mix.exs` (`companions.test` alias current state)
- `132-CONTEXT.md` — 19 locked decisions (all verified against repo in this session)
- `REQUIREMENTS.md` — EXTRACT-07, SEAM-05, COMPAT-02, COMPAT-03 (direct read)

### Secondary (MEDIUM confidence)
- CONTEXT.md D-14 subagent hex.pm investigation (rindle 0.1.10 as compliant version) — not re-verified against live hex.pm in this session but confirmed by domain expert subagent in the same conversation

### Tertiary (LOW confidence)
- None — all claims verified from live repo or prior-phase locked decisions

---

## Metadata

**Confidence breakdown:**
- Code facts (source locations, API shapes, line numbers): HIGH — direct repo reads
- Test coupling disposition (`phase47`, `companions_test`): HIGH — full file reads + per-assertion analysis
- Architecture (drift test design, matrix shape): HIGH — locked decisions verified against repo idioms
- Clean-room pipeline: HIGH — script and YAML directly read
- Pitfalls: HIGH for items with live-code evidence; MEDIUM for "could happen during development" warnings

**Research date:** 2026-06-26
**Valid until:** End of Phase 132 execution (recipe-reuse phase; no fast-moving ecosystem dependencies)
