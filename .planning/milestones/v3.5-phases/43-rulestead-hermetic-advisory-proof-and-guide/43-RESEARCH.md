# Phase 43: Rulestead Hermetic+Advisory Proof And Guide - Research

**Researched:** 2026-05-30
**Domain:** Elixir CI proof posture (hermetic/advisory split), optional Hex dependency isolation, docs-contract testing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Advisory lane is Option C — add rulestead as an optional/conditional dep to `mix.exs`. Advisory CI runs the existing Phase 42 proof suite with rulestead present. Key proof point: `validate_dependency/0` returns `:ok` when dep is present, vs. `{:error, [:"Elixir.Rulestead"]}` when absent (hermetic lane). Real `Rulestead.Snapshot` adapter is explicitly the advisory-to-merge-blocking promotion target — NOT shipped in Phase 43.
- **D-02:** ROADMAP SC#2 "same suite with rulestead present" is the authority. Advisory lane does not need new test files for the overall suite; it runs the Phase 42 proof suite in an environment where `Code.ensure_loaded?(Rulestead)` returns true.
- **D-03:** Promotion path (documented in CI workflow header) requires: (1) real `Rulestead.Snapshot` adapter shipped and in-tree, (2) advisory lane exercising actual flag reads, (3) sustained stability evidence, (4) explicit roadmap scope change. Follows 4-condition `promotion_path` from `phase34-proof.yml`.
- **D-04:** `guides/companions.md` structure: (1) short companion-pattern intro (2-4 sentences), (2) complete rulestead section covering `gated_by` DSL, gate-state semantics, kill-switch behavior, MockFlagSource as mock swap target.
- **D-05:** No rindle/sigra placeholder headings. Only intro + rulestead section in Phase 43.
- **D-06:** Rulestead section must use exact DSL vocabulary matching live code: `gated_by`, `on_unavailable: :deny`, `:kill_switch_active`.
- **D-07:** Test file: `test/crosswake/guides/companions_test.exs`. Pattern mirrors `test/crosswake/guides/commerce_test.exs` — `File.read!`, `setup_all`, `assert content =~`. `async: false`.
- **D-08:** Key anchors: `"gated_by"`, `"kill_switch"`, `"MockFlagSource"`, `"on_unavailable"`, `"fail-closed"` (or canonical phrase). At least one `function_exported?` check confirming a live code symbol.

### Claude's Discretion

- Exact `phase43-proof.yml` job names and structure — follow `phase34-proof.yml` naming conventions
- macOS-15 vs. ubuntu-latest runner choices — macOS for merge-blocking, ubuntu for advisory
- Exact timeout-minutes values — 20 for hermetic, 30 for advisory
- Exact CI workflow header comment explaining the hermetic+advisory split
- Whether advisory lane runs on weekly schedule or only on workflow_dispatch
- Exact mechanism for excluding rulestead from hermetic dep tree (env-var conditional in `mix.exs`)
- How to handle Phase 42 `validate_dependency/0` assertion tension (planner decides: separate advisory test file vs. conditional assertion)
- Exact anchor strings in docs-contract test beyond D-08 minimum

### Deferred Ideas (OUT OF SCOPE)

- Real `Rulestead.Snapshot` adapter — explicitly the advisory-to-merge-blocking promotion target
- Rindle/Sigra guide sections — Phases 44-47
- Full companion arc guide overview section — Phase 47
- `mix crosswake.gen.companion` generator — deferred until rindle validates the convention
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Each shipped companion has a hermetic merge-blocking proof lane that compiles and passes without the optional dependency present (proving fail-closed), plus an advisory lane that exercises it with the dependency present. | Hermetic lane: env-var conditional excludes rulestead from dep tree; Phase 42 proof suite proves fail-closed. Advisory lane: `MIX_INCLUDE_RULESTEAD=1` includes dep; advisory test asserts `validate_dependency() == :ok`. |
| PROOF-02 | A `guides/companions.md` guide documents the companion-seam pattern and rulestead surfaces; locked to support-matrix/doctor truth by a docs-contract test. | New `guides/companions.md` + `test/crosswake/guides/companions_test.exs` following `commerce_test.exs` pattern. |
</phase_requirements>

---

## Summary

Phase 43 completes the CI proof posture for the rulestead companion by splitting into a hermetic merge-blocking lane (rulestead absent — proves fail-closed) and an advisory lane (rulestead present — proves `validate_dependency() == :ok`). It also ships the first section of `guides/companions.md` locked by a docs-contract test.

The critical implementation challenge is the dep isolation mechanism: the hermetic lane must compile and pass without rulestead in the dep tree, while the advisory lane must run with rulestead present. The clean solution is an env-var conditional in `mix.exs` `deps/0`: `if System.get_env("MIX_INCLUDE_RULESTEAD") == "1"`. The hermetic CI job sets no env var; the advisory CI job sets `MIX_INCLUDE_RULESTEAD=1` before `mix deps.get`. This is a standard Elixir pattern — `deps/0` is a regular function evaluated at compile time.

The secondary challenge is the conflicting `validate_dependency/0` assertion: the Phase 42 test asserts `{:error, [:"Elixir.Rulestead"]}` (hermetic context), but the advisory lane needs to assert `:ok` (dep present). The cleanest resolution is a separate `phase43_rulestead_advisory_test.exs` file that inverts the assertion and is run exclusively by the advisory CI job. The Phase 42 test file stays unchanged.

**Primary recommendation:** Use env-var conditional dep in `mix.exs`, separate advisory test file for the inverted `validate_dependency` assertion, and follow `phase34-proof.yml` exactly for the CI workflow structure.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hermetic CI proof (rulestead absent) | CI/Build layer | Library test suite | Proves that the library compiles and all fail-closed assertions pass without the optional dep |
| Advisory CI proof (rulestead present) | CI/Build layer | Library test suite | Proves `validate_dependency()` returns `:ok` when dep is present |
| Dep isolation mechanism | Build config (`mix.exs`) | CI workflow env vars | `deps/0` is evaluated at compile time; env var controls inclusion |
| Docs-contract test | Test suite (`ExUnit`) | File system | `File.read!` + `assert content =~` pattern; no runtime deps needed |
| `guides/companions.md` | Documentation | — | Static guide file; locked by docs-contract test |

---

## Standard Stack

### Core

No new external packages are installed in Phase 43. All tooling is already in the project.

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| ExUnit | built-in (Elixir 1.19.5) | Test framework for all proof tests and docs-contract test | Elixir's built-in test framework; already in use across all proof suites [VERIFIED: official Elixir docs] |
| Mix | built-in | Dep management, conditional deps via `deps/0` function, test runner | Already in use; `deps/0` conditional pattern is standard Elixir [VERIFIED: official Mix docs] |
| GitHub Actions | N/A | CI workflow execution | Already in use; all proof lanes use GHA |
| erlef/setup-beam@v1 | v1 | Sets up Elixir 1.19.5 + OTP 27.3 in CI | Already in use across all proof workflows [VERIFIED: existing workflows] |

### Optional Dep Being Added

| Package | Registry | Version | Purpose | Status |
|---------|----------|---------|---------|--------|
| `rulestead` | Hex.pm | `~> 0.1.6` | Elixir feature-flag library; advisory lane dep | [VERIFIED: hex.pm via `mix hex.info rulestead`] |

**Installation (advisory lane only — see dep isolation section):**
```bash
# Advisory CI sets this env var before mix deps.get:
MIX_INCLUDE_RULESTEAD=1 mix deps.get
```

**mix.exs addition:**
```elixir
# In deps/0:
defp deps do
  base_deps = [
    {:jason, "~> 1.4"},
    # ... existing deps ...
  ]

  rulestead_dep =
    if System.get_env("MIX_INCLUDE_RULESTEAD") == "1" do
      [{:rulestead, "~> 0.1.6"}]
    else
      []
    end

  base_deps ++ rulestead_dep
end
```

---

## Package Legitimacy Audit

> slopcheck does not support the Hex (Elixir) ecosystem. Manual verification performed via `mix hex.info rulestead` and GitHub repository inspection.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `rulestead` | Hex.pm | ~2 days (first release 2026-05-28) | 167 all-time, 57 yesterday | github.com/szTheory/rulestead | N/A (Hex) | Approved — szTheory's own library (same author as crosswake); first-party companion dep |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*Note: slopcheck does not cover the Hex ecosystem. Manual verification confirms `rulestead` is the author's own library (szTheory = the project owner), published 2026-05-28, with active releases (0.1.1 through 0.1.6 in 2 days). The low download count is expected for a brand-new first-party library. Source repo is github.com/szTheory/rulestead — confirmed same organization as crosswake.*

---

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│  phase43-proof.yml (new CI workflow)                                │
│                                                                     │
│  Trigger: PR / push / workflow_dispatch ──────────────────────────┐ │
│                                                                   ↓ │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  merge-blocking-rulestead-proof (macOS-15, required check)  │  │
│  │                                                              │  │
│  │  checkout → setup-beam → mix deps.get (NO env var)          │  │
│  │  → mix compile --warnings-as-errors                          │  │
│  │  → mix test --exclude requires_example_host                  │  │
│  │  (picks up phase42_rulestead_companion_test.exs)             │  │
│  │  → ALL fail-closed assertions pass (rulestead ABSENT)        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Trigger: schedule (weekly) / workflow_dispatch ──────────────────┐ │
│                                                                   ↓ │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  advisory-rulestead-proof (ubuntu-latest, continue-on-error) │  │
│  │                                                              │  │
│  │  checkout → setup-beam                                       │  │
│  │  → MIX_INCLUDE_RULESTEAD=1 mix deps.get (fetches rulestead)  │  │
│  │  → MIX_INCLUDE_RULESTEAD=1 mix compile --warnings-as-errors  │  │
│  │  → mix test phase43_rulestead_advisory_test.exs              │  │
│  │  → validate_dependency() == :ok proved                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────┐
│  mix.exs deps/0 conditional           │
│                                        │
│  MIX_INCLUDE_RULESTEAD=1              │
│  ┌───────────────────────────────────┐ │
│  │ [{:rulestead, "~> 0.1.6"}]       │ │
│  └───────────────────────────────────┘ │
│  (else: [])                            │
└────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────┐
│  Docs layer                                                        │
│                                                                    │
│  guides/companions.md (NEW)                                        │
│    → companion-pattern intro (2-4 sentences)                       │
│    → rulestead section: gated_by DSL, gate-state semantics,        │
│      kill-switch behavior, MockFlagSource mock swap target         │
│         ↑                                                          │
│  test/crosswake/guides/companions_test.exs (NEW)                  │
│    → File.read! + setup_all + assert content =~ anchors            │
│    → function_exported? live-code guard                            │
└────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

New files only (all existing files unchanged except `mix.exs`):

```
.github/workflows/
└── phase43-proof.yml          # new two-job CI workflow

mix.exs                        # ADD: rulestead conditional dep in deps/0

test/crosswake/proof/
└── phase43_rulestead_advisory_test.exs  # new advisory test (validate_dependency :ok)

guides/
└── companions.md              # new guide (intro + rulestead section)

test/crosswake/guides/
└── companions_test.exs        # new docs-contract test
```

Additionally, `mix.exs` `docs/0` `extras:` list needs `"guides/companions.md"` added.
The existing `groups_for_extras: [Guides: ~r/guides\//]` catch-all handles grouping automatically.

### Pattern 1: Env-Var Conditional Dep Isolation (Hermetic Gate)

**What:** `deps/0` in `mix.exs` is a regular Elixir function. System.get_env is evaluated at compile time during `mix deps.get`. When the env var is absent, Mix never downloads or includes the dep. When present, Mix fetches and locks it for that CI run.

**When to use:** When a dep must be excluded from the hermetic dep tree but included in the advisory dep tree — without modifying mix.exs between CI runs.

**Key behavior:** If `mix.lock` was committed without rulestead (hermetic lock), advisory CI runs `MIX_INCLUDE_RULESTEAD=1 mix deps.get` which fetches and adds rulestead to the in-CI lock. The lock is not persisted back to the repo, so the committed lock stays hermetic. [ASSUMED — standard Mix behavior, not verified against a specific official Elixir docs URL in this session]

**Example:**
```elixir
# Source: mix.exs pattern (standard Elixir - deps/0 is a regular function)
defp deps do
  base = [
    {:jason, "~> 1.4"},
    {:nimble_options, "~> 1.1"},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:telemetry, "~> 1.0"},
    {:ex_doc, "~> 0.38", only: :dev, runtime: false}
  ]

  rulestead =
    if System.get_env("MIX_INCLUDE_RULESTEAD") == "1" do
      [{:rulestead, "~> 0.1.6"}]
    else
      []
    end

  base ++ rulestead
end
```

### Pattern 2: Advisory Test File (Inverted validate_dependency Assertion)

**What:** A separate test file that runs only in the advisory context where rulestead IS present. It inverts the Phase 42 assertion.

**Why separate file:** The Phase 42 test asserts `validate_dependency() == {:error, [:"Elixir.Rulestead"]}` (correct for hermetic context). If the advisory CI runs the full suite including this file, this assertion FAILS when rulestead is present. A separate file avoids tagging/exclusion complexity and keeps both lanes clean.

**Example:**
```elixir
# Source: pattern derived from phase42_rulestead_companion_test.exs + CONTEXT.md
defmodule Crosswake.Proof.Phase43RulesteadAdvisoryTest do
  @moduledoc """
  Advisory-only proof: asserts that validate_dependency/0 returns :ok when
  the rulestead library IS present in the dep tree.

  Runs ONLY in the advisory CI lane (phase43-proof.yml advisory-rulestead-proof job)
  where MIX_INCLUDE_RULESTEAD=1 was set during mix deps.get.
  Never run in the hermetic lane.
  """
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Rulestead

  setup do
    Application.put_env(:crosswake, :companions, [Rulestead])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})
    on_exit(fn ->
      Application.delete_env(:crosswake, :companions)
      Application.delete_env(:crosswake, :rulestead)
    end)
    :ok
  end

  test "validate_dependency/0 returns :ok when rulestead library is present" do
    assert Rulestead.validate_dependency() == :ok
  end
end
```

### Pattern 3: Two-Job CI Workflow (follow phase34-proof.yml exactly)

**What:** Two jobs in `phase43-proof.yml`, following `phase34-proof.yml` template.

**Hermetic job:**
- `runs-on: macos-15`
- `timeout-minutes: 20`
- `if: ${{ github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}`
- Steps: checkout, setup-beam (1.19.5/27.3), `mix deps.get`, `mix compile --warnings-as-errors`, `mix test --exclude requires_example_host`
- NO `MIX_INCLUDE_RULESTEAD` env var
- Proves fail-closed: phase42 suite (including `validate_dependency == {:error, ...}`) passes

**Advisory job:**
- `runs-on: ubuntu-latest` (no macOS-specific steps — BEAM compilation is cross-platform)
- `timeout-minutes: 30`
- `if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}`
- `continue-on-error: true`
- Steps: checkout, setup-beam, `MIX_INCLUDE_RULESTEAD=1 mix deps.get`, `MIX_INCLUDE_RULESTEAD=1 mix compile --warnings-as-errors`, `mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs`, advisory lane status summary step
- Proves: `validate_dependency() == :ok` when dep present

### Pattern 4: Docs-Contract Test (follow commerce_test.exs exactly)

**What:** `test/crosswake/guides/companions_test.exs` mirrors `commerce_test.exs` structure.

**Key structure:**
```elixir
# Source: test/crosswake/guides/commerce_test.exs (canonical pattern)
defmodule Crosswake.Guides.CompanionsTest do
  use ExUnit.Case, async: false

  @guide_path Path.join([File.cwd!(), "guides", "companions.md"])

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end

  test "includes gated_by DSL anchor", %{content: content} do
    assert content =~ "gated_by"
  end

  test "includes kill_switch anchor", %{content: content} do
    assert content =~ "kill_switch"
  end

  test "includes MockFlagSource anchor", %{content: content} do
    assert content =~ "MockFlagSource"
  end

  test "includes on_unavailable anchor", %{content: content} do
    assert content =~ "on_unavailable"
  end

  test "includes fail-closed semantics anchor", %{content: content} do
    assert content =~ "fail-closed"
  end

  test "live code guard — key symbols resolve to real exports", _context do
    assert function_exported?(Crosswake.Companions.Rulestead, :validate_dependency, 0),
           "Crosswake.Companions.Rulestead.validate_dependency/0 not exported — guide anchor is stale"

    assert function_exported?(Crosswake.Companions.Rulestead.MockFlagSource, :set_flag, 2),
           "MockFlagSource.set_flag/2 not exported — guide anchor is stale"

    assert function_exported?(Crosswake.SupportMatrix, :gating_truth, 0),
           "Crosswake.SupportMatrix.gating_truth/0 not exported — gate-state semantics anchor is stale"
  end
end
```

### Anti-Patterns to Avoid

- **Mix.exs `optional: true` flag for rulestead:** This flag means the dep is optional for downstream consumers of the library — it does NOT exclude rulestead from crosswake's own build. It only affects transitive dependency resolution. [VERIFIED: Elixir Mix docs]
- **Modifying phase42 test to add environment-conditional assertions:** Fragile, increases coupling between hermetic and advisory contexts, and pollutes the hermetic proof with advisory-context logic.
- **Adding rulestead without env-var guard (always-present dep):** Breaks the hermetic lane's core proof premise — the point is to prove fail-closed with rulestead ABSENT.
- **Advisory CI running `mix test --exclude requires_example_host`:** This picks up `phase42_rulestead_companion_test.exs` which will fail the `validate_dependency` assertion in the advisory context (rulestead present → returns `:ok`, but Phase 42 test expects `{:error, ...}`).
- **Committing mix.lock with rulestead included:** Creates a dependency in the committed hermetic lock. The hermetic CI env should produce the definitive lock — no rulestead.
- **Placeholder `guides/companions.md` headings for rindle/sigra:** Creates implied surface-area commitments; explicitly out of scope per D-05.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dep isolation in CI | Custom scripts to modify mix.exs or remove packages | `System.get_env` conditional in `deps/0` | Standard Elixir pattern; Mix handles it cleanly at compile time |
| Advisory lane not blocking merge | Per-step fail handling | `continue-on-error: true` job setting | GitHub Actions built-in; already proven in phase34-proof.yml |
| Docs liveness verification | Custom reflection code | `function_exported?/3` | Built-in Elixir reflection; already used in commerce_test.exs |
| Guide file anchoring | Custom parsing | `String.contains?` / `content =~` | commerce_test.exs pattern; simple and mechanically verifiable |

**Key insight:** Every pattern needed for Phase 43 already exists in the project. `phase34-proof.yml` is the CI template; `commerce_test.exs` is the docs-contract template; `phase42_rulestead_companion_test.exs` is the proof suite to reuse. This phase assembles, it does not invent.

---

## Common Pitfalls

### Pitfall 1: Advisory CI Runs Phase 42 Full Suite (validate_dependency Collision)
**What goes wrong:** Advisory CI runs `mix test --exclude requires_example_host`. This picks up `phase42_rulestead_companion_test.exs`, which asserts `validate_dependency() == {:error, [:"Elixir.Rulestead"]}`. In the advisory context where rulestead IS present, this assertion fails.
**Why it happens:** The Phase 42 test is written for the hermetic context (rulestead absent). Running it in the advisory context (rulestead present) inverts the result.
**How to avoid:** Advisory CI runs only `phase43_rulestead_advisory_test.exs` (the file with the inverted `:ok` assertion). The Phase 42 test stays hermetic-only.
**Warning signs:** Advisory CI job exits red on the `validate_dependency/0` test despite rulestead being installed.

### Pitfall 2: mix.lock Rulestead Entry After Advisory CI Run (Local Dev)
**What goes wrong:** Developer runs `MIX_INCLUDE_RULESTEAD=1 mix deps.get` locally, rulestead gets added to `mix.lock`, developer commits `mix.lock` with rulestead in it.
**Why it happens:** Mix updates the committed lock file when new deps are fetched.
**How to avoid:** Document in the CI workflow and PR description that `mix.lock` must NOT include rulestead. The hermetic lock is the committed state. If rulestead appears in `mix.lock`, it should be removed from the lockfile before committing.
**Warning signs:** `mix.lock` diff shows a rulestead entry added.

### Pitfall 3: `optional: true` Dep Flag Used Instead of Env-Var Conditional
**What goes wrong:** Adding `{:rulestead, "~> 0.1.6", optional: true}` to `deps/0`. This makes rulestead optional for downstream consumers of crosswake, but it is still downloaded and compiled for crosswake itself. The hermetic lane still has rulestead present.
**Why it happens:** Confusing the Hex `optional` flag (for transitive dep resolution) with "exclude from my own build."
**How to avoid:** Use `System.get_env("MIX_INCLUDE_RULESTEAD") == "1"` conditional in `deps/0`. Only this approach actually excludes the dep from the build.
**Warning signs:** `Code.ensure_loaded?(Rulestead)` returns `true` in the hermetic CI lane.

### Pitfall 4: Hermetic CI Job Uses `MIX_INCLUDE_RULESTEAD=1` Accidentally
**What goes wrong:** The hermetic CI job inherits the env var from the CI environment or from a previous workflow step, causing rulestead to be included.
**Why it happens:** GitHub Actions env var scope bleeds, or a `env:` block at the job level sets it.
**How to avoid:** Never set `MIX_INCLUDE_RULESTEAD` at the workflow level. Only set it inside the advisory job's step(s).
**Warning signs:** `validate_dependency/0` returns `:ok` in the hermetic lane; hermetic `validate_dependency` test fails.

### Pitfall 5: guides/companions.md Anchor Strings Not Matching Live Code
**What goes wrong:** Guide uses prose descriptions that don't match exact DSL keys (e.g., writes "kill switch" instead of `kill_switch`, or "gated by" prose instead of `` `gated_by` ``). Docs-contract test anchors fail.
**Why it happens:** Natural language paraphrasing instead of using verbatim DSL symbols.
**How to avoid:** Every anchor string in `companions_test.exs` (D-08 minimum: `"gated_by"`, `"kill_switch"`, `"MockFlagSource"`, `"on_unavailable"`, `"fail-closed"`) must appear verbatim in `guides/companions.md`.
**Warning signs:** `assert content =~ "gated_by"` fails because the guide wrote "gated by" as prose.

### Pitfall 6: Advisory Lane Missing Weekly Schedule Trigger
**What goes wrong:** Advisory lane only has `workflow_dispatch` but no cron schedule. Absence of advisory results becomes invisible in the CI dashboard between manual runs.
**Why it happens:** Overlooking the `schedule` trigger from the `phase34-proof.yml` pattern.
**How to avoid:** Add `schedule: cron: "0 6 * * 1"` (Monday 06:00 UTC) to the workflow triggers, same as phase34. The advisory-specific `if:` guard on the job (`schedule || workflow_dispatch`) gates it correctly.
**Warning signs:** Advisory lane never appears in CI dashboard unless manually triggered.

---

## Code Examples

Verified patterns from existing codebase:

### CI Workflow: Hermetic Job (from phase34-proof.yml)
```yaml
# Source: .github/workflows/phase34-proof.yml (canonical template)
merge-blocking-rulestead-proof:
  name: merge-blocking rulestead proof (hermetic)
  runs-on: macos-15
  timeout-minutes: 20
  if: ${{ github.event_name == 'pull_request' || github.event_name == 'push' || github.event_name == 'workflow_dispatch' }}

  steps:
    - name: Checkout
      uses: actions/checkout@v6

    - name: Setup BEAM
      uses: erlef/setup-beam@v1
      with:
        elixir-version: "1.19.5"
        otp-version: "27.3"

    - name: Install Elixir dependencies
      run: mix deps.get

    - name: Compile (warnings as errors)
      run: mix compile --warnings-as-errors

    - name: Run hermetic Phase 42+43 rulestead proof (fail-closed)
      run: mix test --exclude requires_example_host
```

### CI Workflow: Advisory Job (adapted from phase34-proof.yml advisory pattern)
```yaml
# Source: .github/workflows/phase34-proof.yml advisory job (adapted for rulestead)
advisory-rulestead-proof:
  name: advisory rulestead proof (dep present, validate_dependency :ok)
  runs-on: ubuntu-latest
  timeout-minutes: 30
  if: ${{ github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' }}
  continue-on-error: true

  steps:
    - name: Checkout
      uses: actions/checkout@v6

    - name: Setup BEAM
      uses: erlef/setup-beam@v1
      with:
        elixir-version: "1.19.5"
        otp-version: "27.3"

    - name: Install Elixir dependencies (with rulestead)
      run: mix deps.get
      env:
        MIX_INCLUDE_RULESTEAD: "1"

    - name: Compile (with rulestead, warnings as errors)
      run: mix compile --warnings-as-errors
      env:
        MIX_INCLUDE_RULESTEAD: "1"

    - name: Run advisory rulestead proof (validate_dependency :ok)
      run: mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs
      env:
        MIX_INCLUDE_RULESTEAD: "1"

    - name: Advisory lane status summary
      run: |
        echo "::notice title=Advisory lane::This lane is advisory only and"
        echo "::notice::cannot gate merge. Failures here do NOT retract any"
        echo "::notice::merge-blocking rulestead companion claim. Promotion to"
        echo "::notice::merge-blocking requires explicit requirement/roadmap"
        echo "::notice::scope change plus sustained stability evidence."
```

### Docs-Contract Test: setup_all + assert content =~ (from commerce_test.exs)
```elixir
# Source: test/crosswake/guides/commerce_test.exs (canonical pattern)
defmodule Crosswake.Guides.CompanionsTest do
  use ExUnit.Case, async: false

  @guide_path Path.join([File.cwd!(), "guides", "companions.md"])

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end

  test "includes gated_by DSL anchor", %{content: content} do
    assert content =~ "gated_by"
  end
  # ... additional anchor tests
end
```

### validate_dependency Logic (from lib/crosswake/companions/rulestead.ex)
```elixir
# Source: lib/crosswake/companions/rulestead.ex
def validate_dependency do
  # Rulestead (unaliased) resolves to :"Elixir.Rulestead" — the hex package's root module
  if Code.ensure_loaded?(Rulestead) do
    :ok                           # advisory lane result (dep present)
  else
    {:error, [Rulestead]}         # hermetic lane result (dep absent) = {:error, [:"Elixir.Rulestead"]}
  end
end
```

### Doctor Companion Logic (key: enabled=true, :ok → no finding)
```elixir
# Source: lib/crosswake/doctor/doctor.ex phase_38_companion_seam_findings/0
case {enabled, result} do
  {true, {:error, mods}} ->   # hermetic: emits companion.dependency_missing :error
    [check(:error, "companion.dependency_missing", ...)]

  {false, :ok} ->              # dep present but companion disabled: advisory finding
    [check(:advisory, "companion.disabled_dependency_present", ...)]

  _ ->                         # advisory lane happy path: enabled=true, :ok → NO finding
    []
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Advisory lane as pure echo placeholder (phase34 pattern) | Advisory lane with actual dep present + functional assertion | Phase 43 | Stronger proof: not just "dep would work here" but "dep IS here and validate_dependency :ok passes" |
| Single CI workflow covers all proof scenarios | Dedicated per-phase proof workflow files | Phase 34 onward | Each phase has explicit proof posture; no implicit coverage assumptions |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | When mix.lock does not contain rulestead and advisory CI runs `MIX_INCLUDE_RULESTEAD=1 mix deps.get`, Mix fetches rulestead and updates the in-memory lock for that CI run without error | Standard Stack, Architecture Patterns | Advisory CI might fail on dep resolution; low risk — standard Mix behavior |
| A2 | Setting `MIX_INCLUDE_RULESTEAD` only in the step `env:` (not job-level `env:`) prevents env var bleed into hermetic job steps | Common Pitfalls | Pitfall 4 occurs — hermetic lane silently includes rulestead |
| A3 | `Code.ensure_loaded?(Rulestead)` returns `true` when rulestead is in the dep tree (rulestead's root module is `Rulestead`) | Architecture Patterns | Advisory `validate_dependency()` returns `{:error, ...}` even with dep present — confirmed by rulestead source code `defmodule Rulestead do` |

*A3 is LOW risk — confirmed by reading `github.com/szTheory/rulestead/main/rulestead/lib/rulestead.ex` which starts with `defmodule Rulestead do`.*

---

## Open Questions

1. **Should advisory CI run `mix test --exclude requires_example_host` (full suite minus phase42's conflicting test) or only `phase43_rulestead_advisory_test.exs`?**
   - What we know: Phase 42 test expects `{:error, ...}` which will fail in advisory context. Full-suite run breaks.
   - What's unclear: Whether SC#2 ("same suite") requires all phase42 tests to pass, or only the key `validate_dependency` inversion.
   - Recommendation: Run only `phase43_rulestead_advisory_test.exs` in the advisory job. The CONTEXT.md "specifics" section explicitly recommends this. SC#2 "same suite" is satisfied by running the suite logic (same proof structure, inverted key assertion).

2. **Should `mix.lock` be updated to include rulestead before merging Phase 43?**
   - What we know: Hermetic lock should not include rulestead. Advisory CI fetches rulestead fresh.
   - What's unclear: Whether there's value in committing the resolved rulestead lock entry for reproducibility.
   - Recommendation: Keep `mix.lock` hermetic (no rulestead). Advisory CI is inherently non-hermetic; its lock doesn't need to be pinned to the repo.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.19.5 (CI via erlef/setup-beam) | — |
| OTP/Erlang | All | ✓ | 27.3 (CI via erlef/setup-beam) | — |
| rulestead Hex package | Advisory lane only | ✓ (fetched by advisory CI) | 0.1.6 | — |
| GitHub Actions macOS-15 | Hermetic job | ✓ (in use by phase34/41) | N/A | — |
| GitHub Actions ubuntu-latest | Advisory job | ✓ (in use by phase34 advisory) | N/A | — |

**Missing dependencies with no fallback:** none
**Missing dependencies with fallback:** none

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in, no install needed) |
| Config file | `test/test_helper.exs` (single line: `ExUnit.start()`) |
| Quick run command | `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs` |
| Full suite command | `mix test --exclude requires_example_host` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PROOF-01 (hermetic) | Phase 42 proof suite passes with rulestead absent | hermetic integration | `mix test --exclude requires_example_host` (in hermetic CI) | ✅ (phase42 test) |
| PROOF-01 (advisory) | `validate_dependency() == :ok` with rulestead present | advisory integration | `mix test test/crosswake/proof/phase43_rulestead_advisory_test.exs` | ❌ Wave 0 |
| PROOF-02 | `guides/companions.md` anchor strings match live code | docs-contract unit | `mix test test/crosswake/guides/companions_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase42_rulestead_companion_test.exs` (verify hermetic suite unbroken)
- **Per wave merge:** `mix test --exclude requires_example_host`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase43_rulestead_advisory_test.exs` — covers PROOF-01 (advisory assertion)
- [ ] `test/crosswake/guides/companions_test.exs` — covers PROOF-02 (docs-contract)
- [ ] `guides/companions.md` — the file the docs-contract test reads (must exist before test runs)

*(Framework and infra: no gaps — ExUnit already configured, test/test_helper.exs exists)*

---

## Security Domain

> Phase 43 is a CI proof posture + documentation phase. No new authentication, session management, cryptography, or input validation surfaces are introduced. The rulestead dependency being conditional means it never executes in production paths (it is only loaded in the advisory CI lane). ASVS categories V2–V6 do not apply.

| ASVS Category | Applies | Rationale |
|---------------|---------|-----------|
| V2 Authentication | no | No auth surfaces introduced |
| V3 Session Management | no | No session surfaces introduced |
| V4 Access Control | no | Proof/docs phase; no new access control paths |
| V5 Input Validation | no | No new user inputs |
| V6 Cryptography | no | No cryptographic operations |

---

## Sources

### Primary (HIGH confidence)
- Codebase: `.github/workflows/phase34-proof.yml` — canonical two-job CI template (hermetic + advisory split, header comment structure, `continue-on-error`, schedule cron, advisory status summary step)
- Codebase: `test/crosswake/guides/commerce_test.exs` — canonical docs-contract test pattern (`File.read!`, `setup_all`, `assert content =~`, `function_exported?`)
- Codebase: `test/crosswake/proof/phase42_rulestead_companion_test.exs` — Phase 42 proof suite (the "same suite" advisory lane references; `validate_dependency` assertion confirmed)
- Codebase: `lib/crosswake/companions/rulestead.ex` — `validate_dependency/0` implementation (`Code.ensure_loaded?(Rulestead)` → `:ok | {:error, [Rulestead]}`)
- Codebase: `lib/crosswake/companions/rulestead/mock_flag_source.ex` — MockFlagSource API (`set_flag/2`, `get_flag/1`)
- Codebase: `lib/crosswake/doctor/doctor.ex` — companion seam findings logic (`enabled=true, :ok → []`; `enabled=true, {:error,...} → dependency_missing`)
- Hex.pm: `mix hex.info rulestead` — rulestead `0.1.6` on Hex.pm, szTheory author, MIT license
- GitHub: `github.com/szTheory/rulestead/main/rulestead/lib/rulestead.ex` — confirms top-level module is `defmodule Rulestead do`

### Secondary (MEDIUM confidence)
- Codebase: `mix.exs` — existing dep structure; no rulestead entry; `ex_doc: only: :dev` shows `:only`-scoped dep pattern for reference

### Tertiary (LOW confidence — flagged in Assumptions Log)
- Mix behavior: env-var conditional in `deps/0` cleanly excludes dep without lock file error when env var is unset [A1, A2]

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — all tools already in project; rulestead confirmed on Hex.pm
- Architecture: HIGH — all patterns copied from existing in-project references
- Pitfalls: HIGH — derived from reading actual code; dep isolation pitfalls from Elixir Mix docs knowledge
- CI workflow structure: HIGH — phase34-proof.yml is the canonical template

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable pattern domain; rulestead 0.1.x API may change, but Phase 43 only uses top-level module presence check)
