# Phase 132: Generalization Proof (rindle) + Compat Matrix — Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 18 new/modified files
**Analogs found:** 18 / 18

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `packages/crosswake_rindle/mix.exs` | config | CRUD | `packages/crosswake_rulestead/mix.exs` | exact |
| `packages/crosswake_rindle/test/test_helper.exs` | config | — | `packages/crosswake_rulestead/test/test_helper.exs` | exact |
| `packages/crosswake_rindle/test/support/engine_present/rindle.ex` | utility | — | `packages/crosswake_rulestead/test/support/engine_present/rulestead.ex` | exact |
| `packages/crosswake_rindle/test/support/study_session_live.ex` | utility | — | `test/support/router_fixtures.ex` (StudySessionLive) | role-match |
| `packages/crosswake_rindle/test/support/example_host/*.ex` (5 files) | utility | — | `examples/phoenix_host/lib/crosswake_example/media/*` | exact copy |
| `test/support/stub_companion.ex` (add StubRindleAbsentCompanion) | utility | — | `test/support/stub_companion.ex` (StubRulesteadAbsentCompanion) | exact |
| `lib/crosswake/companion_guard.ex` (add Rindle to MapSet) | utility | — | `lib/crosswake/companion_guard.ex` lines 35-38 | exact |
| `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | test | request-response | `test/crosswake/proof/phase130_extraction_guards_test.exs` | role-match |
| `guides/companion_compatibility.md` | config | — | `guides/support_matrix.md` (table house-style) | role-match |
| `test/crosswake/guides/companions_test.exs` (rewrite lines 122/131/150/228) | test | — | `test/support/stub_companion.ex` (StubRulesteadAbsentCompanion usage) | role-match |
| `test/crosswake/proof/phase47_companion_arc_test.exs` (partial rewrite tests 1-2) | test | — | `test/support/stub_companion.ex` (StubRulesteadAbsentCompanion) | role-match |
| `mix.exs` (extend companions.test alias) | config | — | `mix.exs` line 59 | exact |
| `.github/workflows/phase132-proof.yml` | config | — | `.github/workflows/phase130-proof.yml` | exact |
| `.github/workflows/release-please.yml` (add publish-hex-rindle + clean-room-proof-rindle) | config | — | `release-please.yml` lines 627-661 (clean-room-proof-rulestead) | exact |
| `release-please-config.json` (add crosswake_rindle component) | config | — | `release-please-config.json` lines 54-72 (crosswake_rulestead block) | exact |
| `.release-please-manifest.json` (add rindle baseline) | config | — | `.release-please-manifest.json` | exact |
| `script/verify_companion_package.sh` (parameterize line 53) | utility | — | `script/verify_companion_package.sh` lines 53-56 | exact |
| `script/verify_companion_cleanroom.sh` (add Contracts canary) | utility | — | `script/verify_companion_cleanroom.sh` lines 192-222 (smoke block) | exact |

---

## Pattern Assignments

### `packages/crosswake_rindle/mix.exs` (config)

**Analog:** `packages/crosswake_rulestead/mix.exs` (full file — 101 lines)

**Full file pattern** — copy-substitute `Rulestead`→`Rindle`, `rulestead`→`rindle`, `CrosswakeRulestead`→`CrosswakeRindle`:

```elixir
# packages/crosswake_rulestead/mix.exs lines 1-101 (copy verbatim, substitute names)

defmodule CrosswakeRindle.MixProject do   # was CrosswakeRulestead.MixProject
  use Mix.Project

  @version "0.1.0" # x-release-please-version — separate from core; do NOT touch core release-please config/manifest
  @source_url "https://github.com/szTheory/crosswake"

  def project do
    [
      app: :crosswake_rindle,             # was :crosswake_rulestead
      version: @version,
      name: "crosswake_rindle",           # was "crosswake_rulestead"
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package()
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test) do            # lines 34-42: ENGINE_PRESENT_LANE pattern
    base = ["lib", "test/support"]
    if System.get_env("ENGINE_PRESENT_LANE") == "1" do
      base ++ ["test/engine_present"]
    else
      base
    end
  end

  defp elixirc_paths(_), do: ["lib"]

  defp deps do                            # lines 46-56
    [
      crosswake_dep(),
      {:rindle, "~> 0.1", optional: true} # was {:rulestead, "~> 0.1", optional: true}
                                          # D-16: cap stays ~> 0.1; 0.3.0 ∉ ~> 0.1
    ]
  end

  defp crosswake_dep do                   # lines 64-68 — THE env-conditional resolver
    if System.get_env("CROSSWAKE_RELEASE") == "1",
      do: {:crosswake, "~> 0.1"},
      else: {:crosswake, path: "../.."}
  end

  defp aliases do                         # lines 74-80 — engine-present advisory lane
    [
      "engine-present.test": [
        "clean",
        "cmd ENGINE_PRESENT_LANE=1 mix test --only engine_present"
      ]
    ]
  end

  defp package do                         # lines 87-99
    [
      name: "crosswake_rindle",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake_rindle",
        "GitHub" => @source_url
      },
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
                                          # D-24: test/ excluded; no priv/ or guides/
    ]
  end
end
```

**Key line:** Line 4 — `# x-release-please-version` marker MUST appear on the same line as `@version`. Line 64-68 — `crosswake_dep/0` exact shape is the drift-test parse target.

---

### `packages/crosswake_rindle/test/test_helper.exs` (config)

**Analog:** `packages/crosswake_rulestead/test/test_helper.exs` line 1

```elixir
# packages/crosswake_rulestead/test/test_helper.exs — line 1 (copy verbatim)
ExUnit.start(exclude: [:engine_present, :collateral_binaries, :advisory_only])
```

Copy verbatim — no substitution needed.

---

### `test/support/stub_companion.ex` — add `StubRindleAbsentCompanion` (utility)

**Analog:** `test/support/stub_companion.ex` lines 1-43 (`StubRulesteadAbsentCompanion`)

**Copy pattern — substitute `:rulestead`→`:rindle`, `Rulestead`→`Rindle`:

```elixir
# test/support/stub_companion.ex — append after line 43 (after StubRulesteadAbsentCompanion)

defmodule Crosswake.TestSupport.StubRindleAbsentCompanion do
  @moduledoc """
  Stub companion that acts as Rindle with the engine absent from core deps.

  Used in core tests (phase47, companions guide) that registered
  `Crosswake.Companions.Rindle` before Phase 132 extracted it to
  `packages/crosswake_rindle/`. The stub has `companion_id: :rindle` so
  Doctor findings carry `finding.check == "companion.rindle"`.

  `validate_dependency/0` returns `{:error, [:"Elixir.Rindle"]}` because
  rindle is absent from core deps (EXTRACT-01 guard, D-21).
  """
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :rindle

  @impl true
  def enabled?(config), do: Map.get(config, :enabled, false)

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def validate_dependency, do: {:error, [:"Elixir.Rindle"]}

  @impl true
  def report_state do
    config = Application.get_env(:crosswake, :rindle, %{})

    %Crosswake.Companion.State{
      companion_id: :rindle,
      enabled: Map.get(config, :enabled, false),
      dependency_status: {:missing, [:"Elixir.Rindle"]},
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: System.monotonic_time(:millisecond)
    }
  end
end
```

**Key delta from RESEARCH.md §Code Examples:** The RESEARCH.md draft omitted `config = Application.get_env(:crosswake, :rindle, %{})` and used `Map.get(config, :enabled, false)` in `report_state/0` — copy the rulestead pattern exactly (lines 32-33 of the analog).

---

### `lib/crosswake/companion_guard.ex` — add Rindle to `@extracted_companion_names` (utility)

**Analog:** `lib/crosswake/companion_guard.ex` lines 35-38

```elixir
# Current (lib/crosswake/companion_guard.ex lines 35-38):
@extracted_companion_names [
  # Phase 130: rulestead adapter extracted
  "Crosswake.Companions.Rulestead"
]

# After Phase 132 edit:
@extracted_companion_names [
  # Phase 130: rulestead adapter extracted
  "Crosswake.Companions.Rulestead",
  # Phase 132: rindle adapter extracted
  "Crosswake.Companions.Rindle"
]
```

**Mechanical note:** The guard comment on line 34 says "Change this attribute AND remove the source from lib/ in the SAME PR." This edit must land in the same plan/commit that deletes `lib/crosswake/companions/rindle.ex` and its subdirectory.

---

### `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` (test, request-response)

**Analog:** `test/crosswake/proof/phase130_extraction_guards_test.exs` (structure: module header, `use ExUnit.Case, async: true`, `alias ProofAssertions`, `stable_id_message/7` calls)

**Module header pattern** (from `phase130_extraction_guards_test.exs` lines 1-25):

```elixir
defmodule Crosswake.Proof.Phase132CompatMatrixDriftTest do
  @moduledoc """
  Merge-blocking drift test for COMPAT-03.

  Asserts that every companion's declared {:crosswake, "~> X.Y"} Hex requirement
  (extracted from crosswake_dep/0 in packages/*/mix.exs via AST parse) matches
  the corresponding row in guides/companion_compatibility.md. Bidirectional:
  also asserts no phantom doc rows exist without a real package.

  Untagged. async: true — read-only source and doc file access; no Application
  state mutation. Must NOT carry :requires_example_host or :engine_present tags.
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions

  @doc_path Path.join([File.cwd!(), "guides", "companion_compatibility.md"])
```

**`stable_id_message/7` call pattern** (from `phase130_extraction_guards_test.exs` lines 35-45):

```elixir
# ProofAssertions.stable_id_message/7 signature (test/support/proof_assertions.ex line 8):
# stable_id_message(id, subject, source, observed, path, hint, posture)
# Returns: "[#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}"
#
# Example from phase130 lines 36-44:
ProofAssertions.stable_id_message(
  "proof.extract_01.mix_exs.no_mix_include_rulestead",
  "core mix.exs must not contain MIX_INCLUDE_RULESTEAD block",
  "File.read!(mix.exs)",
  "found MIX_INCLUDE_RULESTEAD in mix.exs — env hack must be deleted",
  "mix.exs",
  "delete the rulestead MIX_INCLUDE_RULESTEAD conditional block from deps/0 (EXTRACT-01)",
  :merge_blocking
)
```

**AST-parse crosswake_dep/0 pattern** (repo idiom: `Code.string_to_quoted/2` + `Macro.prewalk/3`, same as `lib/crosswake/companion_guard.ex` lines 87-99):

```elixir
# The crosswake_dep/0 AST shape being parsed (packages/crosswake_rulestead/mix.exs lines 64-68):
#   defp crosswake_dep do
#     if System.get_env("CROSSWAKE_RELEASE") == "1",
#       do: {:crosswake, "~> 0.1"},
#       else: {:crosswake, path: "../.."}
#   end
#
# Extraction pattern (must use AST, NOT grep — grep returns both branches):
defp extract_crosswake_requirement(mix_exs_path) do
  source = File.read!(mix_exs_path)
  {:ok, ast} = Code.string_to_quoted(source, [])

  {_ast, req} =
    Macro.prewalk(ast, nil, fn
      {:defp, _, [{:crosswake_dep, _, _}, [do: if_expr]]} = node, _acc ->
        req = extract_hex_req_from_if(if_expr)
        {node, req}
      node, acc ->
        {node, acc}
    end)

  req
end

# The if expression AST shape for:
#   if ..., do: {:crosswake, "~> 0.1"}, else: {:crosswake, path: "../.."}
# The do: keyword value is a 2-tuple literal {atom, string}.
defp extract_hex_req_from_if({:if, _, [_condition, [do: {:crosswake, req}, else: _]]}) do
  req   # returns "~> 0.1"
end
defp extract_hex_req_from_if(_), do: nil
```

**Stable IDs for the three failure cases** (D-13):
- `"proof.compat_03.matrix_drift.#{pkg}.missing_from_doc"` — package in mix.exs but absent from doc
- `"proof.compat_03.matrix_drift.#{pkg}.version_mismatch"` — version string mismatch
- `"proof.compat_03.matrix_drift.#{pkg}.phantom_doc_row"` — doc row with no matching package
- `"proof.compat_03.doc_exists"` — distinct failure for missing doc file
- Non-vacuity guard: `Path.wildcard("packages/crosswake_*/mix.exs")` must return `length >= 2`

---

### `guides/companion_compatibility.md` (config/doc)

**Analog:** `guides/support_matrix.md` (table house-style — pipe-delimited, header row, `---` separator rows)

**Locked table shape with HTML comment contract anchor** (D-12):

```markdown
<!-- compat-03 contract: col1=Hex Package, requirement cell = "Requires `crosswake`";
     do not reorder columns without updating phase132_compat_matrix_drift_test.exs -->
| Hex Package | Companion ID | Current Version | Requires `crosswake` | Engine Dependency | hexdocs |
|---|---|---|---|---|---|
| `crosswake_rulestead` | `:rulestead` | `0.1.0` | `~> 0.1` | `{:rulestead, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rulestead](https://hexdocs.pm/crosswake_rulestead) |
| `crosswake_rindle`    | `:rindle`    | `0.1.0` | `~> 0.1` | `{:rindle, "~> 0.1", optional: true}`    | [hexdocs.pm/crosswake_rindle](https://hexdocs.pm/crosswake_rindle)       |
```

**Five prose sections** (D-08):
1. Opening orientation — link to `guides/companions.md` for setup; don't re-explain companions
2. **Independent Versioning** — companion 0.1.0 + core 0.1.2 coexist; `~> 0.1` declares a minimum, not a ceiling
3. **Reading the Requirement Syntax** — `~> 0.1` = `>= 0.1.0 and < 1.0.0`, stated once
4. **Engine Dependencies** — `optional: true` engine is NOT pulled transitively; name the friction: both live engines (`rulestead 1.0.0`, `rindle 0.3.0`) have a latest release outside `~> 0.1`; adopter must pin `0.1.x` line (D-19)
5. **Verifying Companion Health** — `mix crosswake.doctor` CTA; closes the "added the package but forgot to register/add-engine" loop

**Banned words/claims** (D-09): no "Crosswake's companion ecosystem" → "first-party companion packages"; no "fully compatible"; no "just"; note `Current Version` points to hexdocs for the live number; link `guides/compatibility.md` (DISTINCT — don't merge).

---

### `test/crosswake/guides/companions_test.exs` — rewrite lines 122/131/150/228 (test)

**Analog:** `test/support/stub_companion.ex` (StubRulesteadAbsentCompanion substitution pattern already established at lines 149+ in the test)

**Four surgical edits per RESEARCH.md §Resolved Investigation Items:**

```elixir
# Line 122 — REMOVE (the rulestead comment on line 117 explains: "Core only guards the seam"):
# BEFORE: Code.ensure_loaded!(Crosswake.Companions.Rindle)
# AFTER:  (line deleted)

# Line 131 — REMOVE (API guard now in companion lane, mirrors rulestead extraction):
# BEFORE: assert function_exported?(Crosswake.Companions.Rindle, :validate_dependency, 0)
# AFTER:  (line deleted)

# Line 150 — SUBSTITUTE:
# BEFORE: Crosswake.Companions.Rindle
# AFTER:  Crosswake.TestSupport.StubRindleAbsentCompanion

# Line 228 — SUBSTITUTE:
# BEFORE: Crosswake.Companions.Rindle
# AFTER:  Crosswake.TestSupport.StubRindleAbsentCompanion
```

**Add alias at top of test module** (alongside the existing `StubRulesteadAbsentCompanion` alias):

```elixir
alias Crosswake.TestSupport.StubRindleAbsentCompanion
```

---

### `test/crosswake/proof/phase47_companion_arc_test.exs` — partial rewrite tests 1-2 (test)

**Analog:** Same file — tests 3-6 (lines 152+) need no changes. Only tests 1-2 (lines 104-136) couple via `alias Crosswake.Companions.Rindle` (line 4).

**Pattern:** Replace `alias Crosswake.Companions.Rindle` with stub alias:

```elixir
# BEFORE (line 4):
alias Crosswake.Companions.Rindle

# AFTER:
alias Crosswake.TestSupport.StubRindleAbsentCompanion, as: Rindle
```

This makes tests 1-2 drive `Doctor.run` through the `@behaviour`/registry seam using the stub (same pattern the file already uses for `StubRulesteadAbsentCompanion`). Tests 3-6 use no rindle internals — no changes needed.

**Test 5 (line 197 — hermetic lane guard self-scan):** Update the `MIX_INCLUDE_RINDLE` string check if present to reference the new stub pattern (the self-scan checks what the test file contains).

---

### `mix.exs` — extend `companions.test` alias (config)

**Analog:** `mix.exs` line 59 (current state, RESEARCH.md §Code Fact Verification)

```elixir
# BEFORE (mix.exs line 59):
"companions.test": ["cmd --cd packages/crosswake_rulestead mix test"]

# AFTER:
"companions.test": [
  "cmd --cd packages/crosswake_rulestead mix test",
  "cmd --cd packages/crosswake_rindle mix test"
]
```

---

### `.github/workflows/phase132-proof.yml` (config)

**Analog:** `.github/workflows/phase130-proof.yml` (full file — copy-substitute `rulestead`→`rindle`, `130`→`132`, `phase42/43`→`phase45/72`)

**Three-job structure** (from phase130-proof.yml):

```yaml
# Job 1: core-hermetic-proof — merge-blocking, PR + push to main
#   Runs: phase130_extraction_guards_test.exs (extended for Rindle),
#         phase132_compat_matrix_drift_test.exs (NEW),
#         broad hermetic suite (--exclude requires_example_host --exclude advisory_only)
#   if: github.event_name == 'pull_request' || 'push' || 'workflow_dispatch'

# Job 2: companion-engine-absent-proof — merge-blocking
#   working-directory: packages/crosswake_rindle
#   run: mix companions.test (picks up crosswake_rindle after alias update)
#   run: bash script/verify_companion_package.sh crosswake_rindle
#   if: github.event_name == 'pull_request' || 'push' || 'workflow_dispatch'

# Job 3: companion-engine-present-proof — advisory, schedule + workflow_dispatch only
#   working-directory: packages/crosswake_rindle
#   run: mix clean (D-33 stale .beam prevention)
#   run: mix test --only engine_present
#   env: ENGINE_PRESENT_LANE: "1"
#   continue-on-error: true
```

**Key `on:` block** (copy from phase130-proof.yml lines 32-42):

```yaml
on:
  pull_request:
  push:
    branches:
      - main
  workflow_dispatch:
  schedule:
    - cron: "0 8 * * 1"   # weekly Monday 08:00 UTC advisory lane
```

**BEAM setup pattern** (phase130-proof.yml lines 62-66):

```yaml
- name: Setup BEAM
  uses: erlef/setup-beam@v1
  with:
    elixir-version: "1.19.5"
    otp-version: "27.3"
```

---

### `.github/workflows/release-please.yml` — add `publish-hex-rindle` + `clean-room-proof-rindle` (config)

**Analog:** `release-please.yml` lines 627-661 (`clean-room-proof-rulestead` job)

**`clean-room-proof-rindle` job pattern** (copy-substitute from lines 627-661):

```yaml
clean-room-proof-rindle:
  name: Clean-room proof — crosswake_rindle resolvability + doctor
  needs: [release-please, publish-hex-rindle]
  if: ${{ needs.release-please.outputs.rindle_release_created == 'true' }}
  runs-on: ubuntu-latest
  permissions:
    contents: read
  steps:
    - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2

    - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
      with:
        version-file: .tool-versions
        version-type: strict

    - name: Install Hex + Rebar
      run: |
        mix local.hex --force
        mix local.rebar --force

    - name: Run clean-room proof (logic in script; YAML stays thin)
      run: >
        bash script/verify_companion_cleanroom.sh
        crosswake_rindle
        "${{ needs.release-please.outputs.rindle_version }}"
        rindle
        Rindle
```

**Note:** `publish-hex-rindle` job follows the same structure as `publish-hex-rulestead` (substitute package name and output refs). The outputs alias block in the `release-please` job must expose `rindle_release_created` and `rindle_version`.

---

### `release-please-config.json` — add `crosswake_rindle` component (config)

**Analog:** `release-please-config.json` lines 54-72 (`crosswake_rulestead` block)

```json
"packages/crosswake_rindle": {
  "component": "crosswake_rindle",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_rindle/mix.exs"],
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

**Pitfall:** `release-as: "0.1.0"` is a one-shot override — add a TODO comment; must be removed after first rindle Release PR merges (pitfall 6 from RESEARCH.md).

---

### `.release-please-manifest.json` — add rindle baseline (config)

**Analog:** `.release-please-manifest.json` (full file — 6 lines)

```json
{
  ".": "0.1.2",
  "packages/crosswake-shell-core-ios": "0.1.2",
  "packages/crosswake-shell-core-android": "0.1.2",
  "packages/crosswake_rulestead": "0.1.0",
  "packages/crosswake_rindle": "0.1.0"
}
```

---

### `script/verify_companion_package.sh` — parameterize line 53 (utility)

**Analog:** `script/verify_companion_package.sh` lines 53-56 (current hardcode)

```bash
# BEFORE (line 53-56):
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/rulestead.ex not found in unpacked tarball — source not moved yet"
  exit 1
fi

# AFTER (parameterized from $PACKAGE):
COMPANION_NAME=$(echo "$PACKAGE" | sed 's/^crosswake_//')
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/${COMPANION_NAME}.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/${COMPANION_NAME}.ex not found in unpacked tarball — source not moved yet"
  exit 1
fi
```

**Note:** Line 81 is a comment-only reference to `Rulestead` — not an executable check, no change needed (per RESEARCH.md §Code Fact Verification).

---

### `script/verify_companion_cleanroom.sh` — add Contracts canary (utility)

**Analog:** `script/verify_companion_cleanroom.sh` lines 192-222 (smoke test heredoc `SMOKEEOF` block)

**Contracts canary append pattern** (D-18 — add an `if [ "$PACKAGE" = crosswake_rindle ]` block inside the smoke body, before the `SMOKEEOF` terminator):

```bash
# Inside the cat > test/smoke_test.exs <<SMOKEEOF block, append BEFORE closing SMOKEEOF:

  # Rindle-specific: Contracts.media_state_vocabulary/0 canary (D-17)
  # Confirms Crosswake.Companions.Rindle.Contracts is present in the tarball
  # (sub-module, unlike rulestead which had no sub-module to verify).
$(if [ "$PACKAGE" = "crosswake_rindle" ]; then cat <<'CANARYEOF'
  test "Rindle.Contracts.media_state_vocabulary/0 returns non-empty list (canary: Contracts not orphaned)" do
    vocab = Crosswake.Companions.Rindle.Contracts.media_state_vocabulary()
    assert is_list(vocab) and vocab != [],
           "[crosswake] Rindle.Contracts.media_state_vocabulary/0 returned empty — Contracts module may be missing from tarball"
  end
CANARYEOF
fi)
```

**COMPANION_MODULE derivation** (already in script lines 188-190 — unchanged):

```bash
COMPANION_SUFFIX=$(echo "$PACKAGE" | sed 's/^crosswake_//')
COMPANION_MODULE_SUFFIX=$(echo "$COMPANION_SUFFIX" | python3 -c "import sys; s=sys.stdin.read().strip(); print(s[0].upper() + s[1:])")
COMPANION_MODULE="Crosswake.Companions.${COMPANION_MODULE_SUFFIX}"
```

---

## Shared Patterns

### `Code.string_to_quoted/2` + `Macro.prewalk/3` AST Assertion
**Source:** `lib/crosswake/companion_guard.ex` lines 87-99 (check_source/1) and phase130_extraction_guards_test.exs
**Apply to:** `phase132_compat_matrix_drift_test.exs` (extract Hex requirement from `crosswake_dep/0`)

```elixir
# Canonical idiom (companion_guard.ex lines 87-88):
{:ok, ast} = Code.string_to_quoted(source_string, [])

{_, result} =
  Macro.prewalk(ast, initial_acc, fn
    matching_node = node, _acc -> {node, new_acc}
    node, acc -> {node, acc}
  end)
```

### `ProofAssertions.stable_id_message/7` Teaching Messages
**Source:** `test/support/proof_assertions.ex` lines 8-13
**Apply to:** `phase132_compat_matrix_drift_test.exs` (all three failure cases)

```elixir
# Signature (proof_assertions.ex line 8):
def stable_id_message(id, subject, source, observed, path, hint, posture)
# Output format: "[#{id}] subject=... source=... observed=... path=... hint=... posture=..."
```

### `@compile {:no_warn_undefined, Engine}` + `Code.ensure_loaded?/1` Runtime Probe
**Source:** `packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` line 9
**Apply to:** `packages/crosswake_rindle/lib/crosswake/companions/rindle.ex` (must add `@compile {:no_warn_undefined, Rindle}` at module top after move — NOT present in current core lib/ because rindle exists there now)

### `StubXxxAbsentCompanion` Pattern
**Source:** `test/support/stub_companion.ex` lines 1-43
**Apply to:** New `StubRindleAbsentCompanion`; substitutions in `companions_test.exs` and `phase47_companion_arc_test.exs`

Key shape: `@behaviour Crosswake.Companion`, all 7 `@impl true` callbacks, `validate_dependency` returns `{:error, [:"Elixir.EngineModule"]}`, `report_state` reads `Application.get_env(:crosswake, :companion_id, %{})`.

### ENGINE_PRESENT_LANE + `mix clean` Stale-Beam Prevention
**Source:** `packages/crosswake_rulestead/mix.exs` lines 34-44; `.github/workflows/phase130-proof.yml` lines 157-161
**Apply to:** `packages/crosswake_rindle/mix.exs` `elixirc_paths/1`; `phase132-proof.yml` engine-present job

```elixir
# mix.exs (rulestead pattern lines 34-42):
defp elixirc_paths(:test) do
  base = ["lib", "test/support"]
  if System.get_env("ENGINE_PRESENT_LANE") == "1", do: base ++ ["test/engine_present"], else: base
end
```

```yaml
# CI (phase130-proof.yml lines 157-161):
- name: mix clean — purge stale engine-absent .beam before engine-present build (D-33)
  working-directory: packages/crosswake_rulestead
  run: mix clean
```

### `[crosswake]` Brand-Voice Failure Messages
**Source:** `script/verify_companion_package.sh` lines 35, 49, 54, 73-75
**Apply to:** All new script edits, all `stable_id_message/7` calls, new CI advisory notices

```bash
# Pattern: lead with [crosswake], name what happened, name what to do next
echo "[crosswake] FAIL: <what happened>"
echo "[crosswake] What to do next: <one concrete fix>"
```

---

## Moved Files — No New Pattern Needed

These files move verbatim (or with `Code.require_file` path rewrites) from core to companion lane. No new pattern extraction needed — they are copied wholesale:

| File | Move Type | Path Rewrite Needed |
|------|-----------|---------------------|
| `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` | move to `packages/crosswake_rindle/test/crosswake/proof/` | `Code.require_file` paths → `test/support/example_host/` |
| `test/crosswake/proof/phase45_rindle_mock_media_test.exs` | move | `Code.require_file` paths → `test/support/example_host/` |
| `test/crosswake/proof/phase45_rindle_companion_test.exs` | move | none (no media helpers) |
| `test/crosswake/proof/phase45_rindle_advisory_test.exs` | move | update `@moduletag :advisory_only` → `:engine_present`; update moduledoc env var reference |
| `test/crosswake/proof/phase45_rindle_live_test.exs` | move | `Code.require_file` paths → `test/support/example_host/` (adds `media_lane_live.ex` = 5 helpers total) |
| `test/crosswake/companions/rindle/contracts_test.exs` | move to `packages/crosswake_rindle/test/crosswake/companions/rindle/` | none |
| `test/crosswake/companions/rindle/reconciliation_test.exs` | move | none |
| `lib/crosswake/companions/rindle.ex` | move to `packages/crosswake_rindle/lib/crosswake/companions/` | add `@compile {:no_warn_undefined, Rindle}` |
| `lib/crosswake/companions/rindle/contracts.ex` | move | none (Contracts aliases move with source) |
| `lib/crosswake/companions/rindle/reconciliation.ex` | move | none |
| `.github/workflows/phase72-proof.yml` | retire or redirect to companion lane | update runner from `macos-15` to `ubuntu-latest` if redirected |

**Media helpers to copy** (5 files, not 4 — RESEARCH.md §drift discovered):
- `examples/phoenix_host/lib/crosswake_example/media/reconciliation_keys.ex`
- `examples/phoenix_host/lib/crosswake_example/media/reconciliation_inbox.ex`
- `examples/phoenix_host/lib/crosswake_example/media/mock_capture.ex`
- `examples/phoenix_host/lib/crosswake_example/media/media_projection.ex`
- `examples/phoenix_host/lib/crosswake_example/media/media_lane_live.ex` (added by RESEARCH.md drift discovery)

Copy to: `packages/crosswake_rindle/test/support/example_host/`

---

## No Analog Found

None — all 18 files have concrete analogs in the live codebase.

---

## Metadata

**Analog search scope:** `packages/crosswake_rulestead/`, `lib/crosswake/companion_guard.ex`, `test/support/`, `test/crosswake/proof/phase130_*.exs`, `.github/workflows/phase130-proof.yml`, `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`, `script/verify_companion_package.sh`, `script/verify_companion_cleanroom.sh`, `guides/support_matrix.md`
**Files scanned:** 14 files read directly
**Pattern extraction date:** 2026-06-26
