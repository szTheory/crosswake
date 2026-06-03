# Phase 47: Companion Arc Guide And Milestone Proof - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 6  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/companions.md` | config | transform | `guides/commerce.md` | role-match |
| `test/crosswake/guides/companions_test.exs` | test | transform | `test/crosswake/guides/commerce_test.exs` | exact |
| `test/crosswake/proof/phase47_companion_arc_test.exs` | test | request-response | `test/crosswake/proof/phase45_rindle_companion_test.exs` | role-match |
| `test/crosswake/proof/phase47_companion_arc_test.exs` | test | request-response | `test/crosswake/proof/phase46_sigra_auth_contract_test.exs` | role-match |
| `.github/workflows/phase43-proof.yml` (if wiring changed) | config | batch | `.github/workflows/phase45-proof.yml` | exact |
| `test/test_helper.exs` (if advisory exclusion wiring changed) | config | batch | `test/test_helper.exs` | exact |

## Pattern Assignments

### `guides/companions.md` (config, transform)

**Analog:** `guides/commerce.md`

**Guide structure pattern** (`guides/commerce.md` layered sections):
- Layered contract-first organization with explicit support truth before playbooks/non-claims.
- Use canonical module/function names verbatim and keep truth table language aligned to `SupportMatrix`.

**Copy style from**:
- `guides/commerce.md` sections beginning at `## Commerce Support Truth` and explicit non-claims language in later sections.

**Parity-lock surface anchors to include** (from existing docs/test contracts):
- `Crosswake.Companion`, callback names, `lib/crosswake/companions/<name>/`
- `Crosswake.SupportMatrix.gating_truth/0`, `Crosswake.SupportMatrix.auth_contract_truth/0`
- denial vocabulary `:gate_denied`, `:kill_switch_active`, `:step_up_required`
- doctor codes `companion.dependency_missing`, `auth.step_up_required_contract`

---

### `test/crosswake/guides/companions_test.exs` (test, transform)

**Analog:** `test/crosswake/guides/commerce_test.exs`

**Imports/setup pattern** (`companions_test.exs:13-20`, `commerce_test.exs:27-34`):
```elixir
use ExUnit.Case, async: false

@guide_path Path.join([File.cwd!(), "guides", "companions.md"])

setup_all do
  content = File.read!(@guide_path)
  %{content: content}
end
```

**Anchor + semantic parity pattern** (`commerce_test.exs:207-249`):
```elixir
support_matrix_roles =
  Crosswake.SupportMatrix.commerce_corridors()
  |> Enum.map(& &1.corridor_role)
  |> Enum.sort()

for role <- support_matrix_roles do
  assert ownership_section =~ "`#{role}`"
end
```

**Live export guard pattern** (`companions_test.exs:55-69`):
```elixir
Code.ensure_loaded!(Crosswake.Companions.Rulestead)
Code.ensure_loaded!(Crosswake.Companions.Rulestead.MockFlagSource)
Code.ensure_loaded!(Crosswake.SupportMatrix)

assert function_exported?(Crosswake.SupportMatrix, :gating_truth, 0)
```

**Apply in Phase 47:** keep string anchors, then add set-style parity checks against live sources:
- `Crosswake.SupportMatrix.gating_truth/0` and `auth_contract_truth/0`
- `Crosswake.Shell.Denial.reasons/0`
- doctor finding codes emitted by auth/companion checks.

---

### `test/crosswake/proof/phase47_companion_arc_test.exs` (test, request-response)

**Analog A:** `test/crosswake/proof/phase45_rindle_companion_test.exs`

**Hermetic temp-install setup pattern** (`phase45_rindle_companion_test.exs:26-76`):
```elixir
setup do
  Application.put_env(:crosswake, :companions, [Rindle])
  Application.put_env(:crosswake, :rindle, %{enabled: true})
  on_exit(fn ->
    Application.delete_env(:crosswake, :companions)
    Application.delete_env(:crosswake, :rindle)
  end)
  # temp router/policy/install_manifest files...
end
```

**Fail-closed doctor assertion pattern** (`phase45_rindle_companion_test.exs:111-128`):
```elixir
report = Doctor.run(route_source: MediaRouter, install_manifest_path: install_manifest_path, cwd: target)
finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))
assert finding.severity == :error
assert finding.check == "companion.rindle"
```

**Analog B:** `test/crosswake/proof/phase46_sigra_auth_contract_test.exs`

**Auth truth + denial posture pattern** (`phase46_sigra_auth_contract_test.exs:251-271`):
```elixir
auth_truth = SupportMatrix.auth_contract_truth()
assert [%{} = row] = auth_truth
assert row.route_predicates == [:auth_min_level, :requires_recent_auth]
assert row.denial_vocabulary == :step_up_required
assert decision.denial.reason == :step_up_required
```

**Doctor auth code assertions** (`phase46_sigra_auth_contract_test.exs:228-249`):
```elixir
assert Enum.any?(report.findings, &(&1.code == "auth.step_up_required_contract"))
```

**Use for Phase 47 aggregate test:** compose one untagged module that:
- registers shipped companions together,
- asserts missing-dependency `companion.dependency_missing` findings for rulestead+rindle when enabled,
- asserts sigra auth contract truth and `:step_up_required` posture from live code.

---

### `.github/workflows/phase43-proof.yml` and `.github/workflows/phase45-proof.yml` (config, batch; conditional)

**Analog:** existing hermetic/advisory split jobs

**Hermetic command surface pattern** (`phase43-proof.yml:95-101`, `phase45-proof.yml:64-66`):
```yaml
run: mix test --exclude requires_example_host --exclude advisory_only
```

**Advisory env isolation pattern** (`phase43-proof.yml:135-148`, `phase45-proof.yml:84-97`):
```yaml
env:
  MIX_INCLUDE_RULESTEAD: "1"
```
and
```yaml
env:
  MIX_INCLUDE_RINDLE: "1"
```
set at **step-level only**.

**Apply in Phase 47:** prefer no new workflow; ensure aggregate test remains untagged so current hermetic command picks it up.

---

### `test/test_helper.exs` (config, batch; conditional)

**Analog:** current advisory-tag exclusion gate (`test/test_helper.exs:3-5`)
```elixir
unless System.get_env("MIX_INCLUDE_RULESTEAD") == "1" do
  ExUnit.configure(exclude: [advisory_only: true])
end
```

**Apply in Phase 47:** do not tag aggregate proof `:advisory_only`; keep it included in hermetic lanes automatically.

## Shared Patterns

### Companion Contract Surface
**Source:** `lib/crosswake/companion.ex:13-16`, `:54-124`  
**Apply to:** guide anchors and docs tests
```elixir
@behaviour Crosswake.Companion
@callback companion_id() :: atom()
@callback enabled?(config :: map()) :: boolean()
@callback route_gated?(route :: RouteEntry.t(), context :: Target.t()) :: {:deny, Finding.t()} | :pass
@callback kill_switch_active?(context :: Target.t()) :: boolean()
@callback validate_dependency() :: :ok | {:error, [module()]}
@callback report_state() :: State.t()
```

### Doctor Companion/Auth Finding Codes
**Source:** `lib/crosswake/doctor/doctor.ex:518-572`, `:688-728`  
**Apply to:** docs parity test + aggregate proof assertions
```elixir
check(:error, "companion.dependency_missing", ...)
check(:advisory, "auth.route_predicated", ...)
check(:advisory, "auth.step_up_required_contract", ...)
```

### Support Truth Accessors
**Source:** `lib/crosswake/support_matrix/support_matrix.ex:277-290`  
**Apply to:** guide parity assertions
```elixir
def gating_truth do
  Application.get_env(:crosswake, :companions, [])
  |> Enum.map(fn companion ->
    state = companion.report_state()
    %{companion_id: state.companion_id, gate_state: gate_state_display(state)}
  end)
end

def auth_contract_truth, do: @auth_contract_truth
```

### Denial Vocabulary Source
**Source:** `lib/crosswake/shell/denial.ex:8-20`, `:48-49`  
**Apply to:** docs parity checks for gate/auth denial terms
```elixir
@reasons [..., :gate_denied, :kill_switch_active, :step_up_required]
def reasons, do: @reasons
```

### Hermetic Proof Test Conventions
**Sources:**  
- `test/crosswake/proof/phase45_rindle_companion_test.exs:8`, `:26-33`  
- `test/crosswake/proof/phase46_sigra_auth_contract_test.exs:2`, `:120-123`, `:143-148`  
**Apply to:** new phase47 proof
```elixir
use ExUnit.Case, async: false
Application.put_env(...)
on_exit(fn -> Application.delete_env(...) end)
refute Regex.match?(~r/code\.require_file\s*\(/, source)
```

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | - | - | All target files have strong existing analogs. |

## Metadata

**Analog search scope:** `guides/`, `test/crosswake/guides/`, `test/crosswake/proof/`, `.github/workflows/`, `lib/crosswake/`  
**Files scanned:** 18  
**Pattern extraction date:** 2026-05-31
