# Phase 69: Docs-Contract Parity Gate, Android Promotion & Closeout - Pattern Map

**Mapped:** 2026-06-04 (Based on current project context)
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `test/crosswake/proof/phase69_docs_contract_parity_test.exs` | test | test/assertions | `test/crosswake/proof/phase64_runtime_line_policy_test.exs` | exact |
| `lib/crosswake/support_matrix/support_matrix.ex` | config | static declaration | (Self) | exact |
| `test/mix/tasks/closeout_verify_test.exs` | test | CLI test | (Self) | exact |
| `test/crosswake/planning/closeout_ci_parity_test.exs` | test | text parsing | (Self) | exact |
| `.planning/phases/69-docs-contract-parity-gate-android-promotion-closeout/69-CLOSEOUT.md` | docs | documentation | `.planning/milestones/v3.8-phases/58-auth-diagnostics-proof-and-security-closeout/58-SECURITY.md` | role-match |

## Pattern Assignments

### `test/crosswake/proof/phase69_docs_contract_parity_test.exs` (test, test/assertions)

**Analog:** `test/crosswake/proof/phase64_runtime_line_policy_test.exs`

**Imports pattern** (lines 1-8):
```elixir
defmodule Crosswake.Proof.Phase69DocsContractParityTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.SupportMatrix
  alias Crosswake.Manifest.Types
```

**File Reading & Guide Parity pattern** (from `test/crosswake/proof/phase68_android_uat_test.exs` & `phase64_runtime_line_policy_test.exs`):
```elixir
  @tag :proof_01
  test "manifest ↔ shell fixture ↔ guide ↔ doctor agree on runtime-line truth" do
    guide = File.read!("guides/support_matrix.md")
    native_shell = File.read!("guides/native_shell.md")
    
    assert guide =~ "Android support is fully verified" # Specifics to be determined
    
    # Asserting error messages using ProofAssertions
    assert expected_condition,
           ProofAssertions.stable_id_message(
             "proof.docs.support_matrix.parity",
             "guides parity-locked to live support truth",
             "guides/support_matrix.md",
             "expected specific string in guide",
             "guides/support_matrix.md",
             "regenerate support matrix guide from canonical renderer output",
             :merge_blocking
           )
  end
```

---

### `lib/crosswake/support_matrix/support_matrix.ex` (config, static declaration)

**Android Promotion Pattern** (lines 331-350 in `lib/crosswake/support_matrix/support_matrix.ex`):
```elixir
      android: [
        support_entry(
          "android",
          Keyword.get(opts, :android_version, "26"),
          :supported, # <-- Change from :verification_required
          baseline_status: :supported,
          proof_status: :supported, # <-- Change from :verification_required
          proof: "script/verify_generated_android_shell.sh",
          notes:
            "Host-owned Android shell boot is proof-backed by the checked-in example host and generated-shell verification hook.",
          boundary_link: "guides/native_shell.md#boundary-warnings--rough-edges"
        )
      ],
```

**Promotion Rule Pattern** (lines 806-831 in `lib/crosswake/support_matrix/support_matrix.ex`):
Review `shell.android.jvm_hermetic` and `shell.android.device_verified` to ensure they accurately reflect the `promotes_to: :supported` logic based on Phase 69 criteria.

---

### `test/crosswake/planning/closeout_ci_parity_test.exs` (test, text parsing)

**CI Parity Pattern** (lines 4-22 in `test/crosswake/planning/closeout_ci_parity_test.exs`):
```elixir
  @workflow Path.join(File.cwd!(), ".github/workflows/phase69-proof.yml") # Target correct workflow

  test "phase 69 merge-blocking proof lane runs hermetic closeout checks" do
    workflow = File.read!(@workflow)
    merge_blocking = job_section!(workflow, "merge-blocking-closeout-proof") # Or updated job name

    assert merge_blocking =~ "mix compile --warnings-as-errors"
    assert merge_blocking =~ "mix closeout.verify" # Phase 69 closeout target
    
    # Assert Phase 69 specific tests are present
    assert merge_blocking =~ "test/crosswake/proof/phase69_docs_contract_parity_test.exs"
    assert merge_blocking =~ "test/mix/tasks/closeout_verify_test.exs"
    refute merge_blocking =~ "continue-on-error: true"
  end
```

---

### `test/mix/tasks/closeout_verify_test.exs` (test, CLI test)

**Closeout Task Invocation Pattern** (lines 12-25 in `test/mix/tasks/closeout_verify_test.exs`):
```elixir
  test "mix closeout.verify prints the shared verifier report and exits cleanly when closeout passes" do
    cwd = complete_fixture!("pass")

    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--cwd", cwd]) # Adjust options for Phase 69 closeout (e.g. REL-01 gate checks)
      end)

    assert output =~ "closeout.verify passed"
  end
```

## Shared Patterns

### Proof Assertions
**Source:** `lib/crosswake/test_support/proof_assertions.ex`
**Apply to:** `test/crosswake/proof/phase69_docs_contract_parity_test.exs`
Use `ProofAssertions.stable_id_message/7` to format diagnostic error strings for merge-blocking tests, ensuring doctor/support/parity errors have a stable failure id, action, and proof posture.

### Closeout Gate Enforcement
**Source:** `mix closeout.verify` task.
**Apply to:** CI pipeline checks. Milestone closeout leverages deterministic checks via `mix closeout.verify` to enforce completeness of requirements, roadmap states, release claims, and frontmatter, completely blocking release without full documentation and testing.

## Metadata

**Analog search scope:** `test/crosswake/proof/`, `lib/crosswake/support_matrix/`, `test/mix/tasks/`, `test/crosswake/planning/`
**Files scanned:** ~15 specific targeted files.
**Pattern extraction date:** 2026-06-04