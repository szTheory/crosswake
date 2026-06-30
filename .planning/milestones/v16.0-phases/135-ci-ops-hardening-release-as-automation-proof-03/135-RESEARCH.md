# Phase 135: CI-Ops Hardening — Release-As Automation (PROOF-03) — Research

**Researched:** 2026-06-28
**Domain:** ExUnit proof-capture, shell-script auditing, GitHub Actions YAML structural assertion
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01: Audit-then-prove.** For each of SC1–SC5, the executor reads the landed artifact,
  writes a proof assertion against its success criterion, and applies a **minimal fix only
  where the assertion fails**. Passing artifacts are recorded as proven with **no code change**.
  Treats landed code as ground-truth-but-verify (the posture that closed Phases 132/133).

- **D-02: Hermetic core + structural wiring.** Prove the deterministic core hermetically; assert
  the un-hermetic GitHub-side effects structurally (the phase133 doc-presence-assert pattern).
  Per-SC bar:
  - SC1 (staleness guard): ExUnit RED→GREEN proof — script returns RED (non-zero) against a
    fixture whose `release-as` pin equals an already-released `{component}-v{X}` tag, and GREEN
    (zero) once the pin is removed. Marquee deliverable; must be demonstrated, not asserted.
  - SC2 (auto-cleanup PR): unit-prove `script/strip_release_as.py` idempotency on a config
    fixture (strips `release-as` + `_TODO_release_as`, minimal diff, re-run is a no-op) PLUS
    structurally assert the `release-as-cleanup` job is wired in `release-please.yml`.
  - SC3 (failure-alert): structurally assert the `release-failure-alert` job exists with
    `if: failure()` on the publish + clean-room-proof jobs, and is dormant on the green path.
  - SC4 (recipe inheritance): assert `script/extract_companion.md` Step 12f references the
    automation (not a manual runbook) so sigra/chimeway/threadline inherit 0-human release ops.
  - SC5 (registration tooling): prove `register_required_checks.sh` is idempotent + green-first
    via dry-run, and `check_required_checks_registered.sh` is a fail-closed detector.
  - Live-fire deferred (real release cleanup PR + alert; admin registration).

- **D-03: Tooling-proven in-phase, actual registration deferred.** SC5 closes on tooling
  correctness, not on the admin action. In-phase = prove the registrar + detector.
  Out-of-phase (tracked human gate) = `DRY_RUN=0 script/register_required_checks.sh` by an
  admin after v16.0 lands on origin and each lane has gone green on origin once.

### Claude's Discretion

- **Proof-test home:** an ExUnit `test/crosswake/proof/phase135_*_test.exs` joining the hermetic
  suite (mirrors `test/crosswake/proof/phase133_telemetry_contract_test.exs`), rather than a
  standalone CI proof workflow. Researcher/planner may confirm.
- **Git-tag fixture mechanism for SC1:** researcher to determine the cleanest hermetic approach
  (no network, no real tags).
- The detector (`check_required_checks_registered.sh`) MAY be wired to run periodically
  (maintainer or scheduled job with an admin PAT) — optional, planner's call.

### Deferred Ideas (OUT OF SCOPE)

- v16.0 → origin sync (the ~100-commit catch-up PR).
- Actual required-check registration (`DRY_RUN=0 script/register_required_checks.sh`).
- Live-fire of GitHub-side effects (real cleanup PR + alert from a true companion release).
- Periodic detector run with an admin PAT scheduled job.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-03 | The two post-publish companion-release follow-ups are CI-enforced with no recurring human step (parametric across all `crosswake_*` companions): (a) fail-closed `release-as` staleness guard; (b) auto-cleanup PR strips release-as on release; (c) `if: failure()` alert on publish + clean-room-proof jobs; SC4 recipe inheritance so future companions inherit 0-human release ops; SC5 parametric idempotent registrar + fail-closed detector. | All five SCs have landed artifacts on local main; research confirms each SC is met, identifies one latent edge-case in strip_release_as.py, and determines the GIT_DIR-injection fixture approach for SC1 RED→GREEN proof. |
</phase_requirements>

---

## Summary

This is a **proof-capture/audit phase, not a greenfield build.** All five PROOF-03 artifacts landed on local main 2026-06-26 as part of v16.0. The planner's job is to write a single `test/crosswake/proof/phase135_ci_ops_proof_test.exs` that (a) demonstrates SC1 RED→GREEN hermetically, (b) unit-proves SC2 idempotency, and (c) structurally asserts SC3/SC4/SC5 wiring — then applies minimal fixes wherever an audit finds a real SC gap.

**Audit verdict summary:** SC1, SC3, SC4, and SC5 all match their Success Criteria exactly as landed. SC2 has a latent trailing-comma edge-case in `strip_release_as.py` that does not affect the real config (release-as is never the last key in any real block) but **must be noted** in the proof fixture contract so the test reflects the limitation. Both previously-deferred core-hermetic failures (`milestone_transition_reset`, `phase52_operator_truth`) are confirmed green locally.

**Primary recommendation:** Write one ExUnit proof file in the phase133 pattern, structured into five tagged sections (one per SC), using `GIT_DIR`-injection for SC1, `System.cmd` with a temp-file fixture for SC2, and `File.read!` + `String.contains?` for SC3/SC4/SC5 structural assertions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SC1 staleness guard (core logic) | Script layer (bash + jq) | CI workflow trigger | The deterministic tag-check lives entirely in `check_release_as_staleness.sh`; the workflow is just a runner |
| SC1 hermetic proof | ExUnit test | Temp git repo fixture | ExUnit shells out to the script; GIT_DIR injection provides the tag fixture |
| SC2 cleanup PR (core logic) | Python script (`strip_release_as.py`) | CI workflow trigger | All text-manipulation is in the Python script; the workflow calls it and opens the PR |
| SC2 hermetic proof | ExUnit test (System.cmd) | Temp config fixture | Script invoked via System.cmd against a temp JSON file |
| SC3/SC4/SC5 structural assertions | ExUnit test (File.read!) | — | YAML/Markdown string presence checks; no live execution needed |
| SC5 parametric discovery | Python helper (`list_merge_blocking_checks.py`) | Called by both shell scripts | Single source of truth for merge-blocking lane names |

---

## Primary Research Question Answers

### Q1: SC1 Git-Tag Fixture Mechanism (the open question) — RESOLVED

**Concrete recommendation: use `GIT_DIR` environment variable injection.**

The staleness script uses a single git command for tag detection (line 59 of `check_release_as_staleness.sh`):

```bash
git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1
```

The script does NOT accept a `--git-dir` flag, a `REPO` variable, or any other override. However, `git` inherits `GIT_DIR` from the environment, and `git rev-parse` respects it without any code change needed.

**Approach A: `GIT_DIR`-injected temp git repo (RECOMMENDED)**

```elixir
# In ExUnit test: create a throwaway repo, tag it, pass GIT_DIR to the script
tmp = System.tmp_dir!() |> Path.join("crosswake-phase135-proof-#{System.unique_integer([:positive])}")
File.mkdir_p!(tmp)
{_, 0} = System.cmd("git", ["-C", tmp, "init"])
{_, 0} = System.cmd("git", ["-C", tmp, "commit", "--allow-empty", "-m", "init"])
{_, 0} = System.cmd("git", ["-C", tmp, "tag", "crosswake_rulestead-v0.1.0"])

# RED case: config has release-as = "0.1.0", tag crosswake_rulestead-v0.1.0 EXISTS
{_, red_exit} = System.cmd("bash", [script_path, config_red],
  env: [{"GIT_DIR", Path.join(tmp, ".git")}] ++ System.get_env() |> Map.to_list())
assert red_exit == 1

# GREEN case: config has release-as removed, same tag EXISTS (but no pin to check)
{_, green_exit} = System.cmd("bash", [script_path, config_green],
  env: [{"GIT_DIR", Path.join(tmp, ".git")}] ++ System.get_env() |> Map.to_list())
assert green_exit == 0
```

**Why this is the right approach:**
- No code change to the script required — `GIT_DIR` is a standard git mechanism the script already inherits
- Fully hermetic: the temp repo is created fresh with `System.unique_integer`, contains no real tags, and is cleaned up in `on_exit`
- RED→GREEN is demonstrated in a single test, satisfying D-02's "must be demonstrated, not asserted" bar
- `async: true` is safe because `GIT_DIR` isolation prevents any collision with the real repo tags

**Approach B: Stub via env var (NOT POSSIBLE)** — The script has no `GIT_CMD` or `GIT_TAG_CMD` override mechanism; it calls `git` directly.

**Approach C: Real-repo tags (NOT HERMETIC)** — Would depend on the real repo state, violating hermetic-suite discipline.

**Fixture design note:** The config fixture must have `release-as` as a non-final key in the package block (e.g., followed by `"extra-files": [...]`). If `release-as` is the final key before the closing brace, the script's surgical line-removal produces a trailing comma that fails JSON validation (see SC2 audit finding below). This matches the real config's structure, so it is not a real-world problem — but the test fixture must reflect the constraint.

---

### Q2: Per-SC Proof Mechanics (SC2–SC5)

#### SC2 — `strip_release_as.py` Idempotency Proof

The script is **CLI-only** (no importable function entry point); assertions must use `System.cmd("python3", ...)`.

**Verified behavior** (tested against real config and temp fixtures):

- First run: strips `"release-as"` and `"_TODO_release_as"` lines, writes the file, validates JSON, exits 0
- Second run: detects keys are absent, prints OK, exits 0 without touching the file (idempotency confirmed)
- Minimal diff: only the target key lines are removed; all other JSON structure preserved
- JSON validation: the script calls `json.loads(new_text)` after edit — fails on invalid JSON before writing

**Proof fixture pattern:**

```elixir
# Create a temp config that mirrors the real structure (release-as NOT the last key)
fixture = """
{
  "packages": {
    "packages/crosswake_rulestead": {
      "component": "crosswake_rulestead",
      "release-type": "elixir",
      "separate-pull-requests": true,
      "release-as": "0.1.0",
      "_TODO_release_as": "remove after first release",
      "extra-files": ["packages/crosswake_rulestead/mix.exs"]
    }
  }
}
"""
# Run 1: both keys stripped, exit 0
# Run 2: "already has no release-as/_TODO_release_as — no change", exit 0
# Assert: the resulting JSON has no "release-as" or "_TODO_release_as" keys for the component
```

**Structural wiring assertion (release-as-cleanup job):**

```elixir
source = File.read!(".github/workflows/release-please.yml")
assert String.contains?(source, "release-as-cleanup")
assert String.contains?(source, "strip_release_as.py crosswake_rulestead")
assert String.contains?(source, "strip_release_as.py crosswake_rindle")
```

**Cannot be asserted hermetically:** The actual PR creation (the `gh pr create` step) is live-fire; deferred per D-02.

#### SC3 — Failure Alert Structural Assertions

**Verified behavior:** The `release-failure-alert` job in `release-please.yml` (line 842):
- Has `if: ${{ failure() }}` at the job level (line 853)
- Lists `needs:` covering all four companion publish/proof jobs: `publish-hex-rulestead`, `publish-hex-rindle`, `clean-room-proof-rulestead`, `clean-room-proof-rindle`
- Does NOT cover `publish-hex` (core) or `publish-ios-core`/`publish-android-core` — this is correct; SC3 scope is companion-only
- Is dormant on the green/no-release path because GitHub Actions `failure()` is `false` when all dependencies are `skipped` (which they are when no companion releases)

**Structural assertion:**

```elixir
source = File.read!(".github/workflows/release-please.yml")
assert String.contains?(source, "release-failure-alert:")
assert String.contains?(source, "if: ${{ failure() }}")
assert String.contains?(source, "publish-hex-rulestead")
assert String.contains?(source, "publish-hex-rindle")
assert String.contains?(source, "clean-room-proof-rulestead")
assert String.contains?(source, "clean-room-proof-rindle")
```

**Cannot be asserted hermetically:** The actual issue-creation step is live-fire GitHub API; deferred per D-02.

#### SC4 — Recipe Inheritance Structural Assertion

**Verified behavior:** `script/extract_companion.md` line ~360–377 (Step 12f) says:

> "As of Phase 135 this is CI-automated — no manual edit and no per-companion human runbook"

And the checklist entry at line ~416:

> `[x] release-as removal is CI-automated (PROOF-03): release-as-cleanup job auto-opens the cleanup PR + merge-blocking-release-as-staleness guard enforces it — parametric, no manual step (Pitfall 6)`

**Structural assertion:**

```elixir
source = File.read!("script/extract_companion.md")
assert String.contains?(source, "12f")
assert String.contains?(source, "PROOF-03")
assert String.contains?(source, "CI-automated")
assert String.contains?(source, "release-as-cleanup")
assert String.contains?(source, "merge-blocking-release-as-staleness")
# Negative assertion: no per-companion manual runbook
refute String.contains?(source, "12f. `release-as` removal — manual")
```

#### SC5 — Registration Tooling Proof

**Verified behavior of `register_required_checks.sh`:**
- `DRY_RUN=1` by default (line 37: `DRY_RUN="${DRY_RUN:-1}"`)
- Calls `python3 script/list_merge_blocking_checks.py` to discover all merge-blocking lanes — the parametric discovery
- Green-first preflight: only registers lanes that have already gone green on the branch HEAD via GitHub's check-runs API
- Idempotent: uses `unique_by(.context)` on the merged check array
- Cannot be run dry-run hermetically without `gh` admin auth (it calls `gh api` to read current branch protection + check-runs)

**SC5 hermetic assertions (structural):**

```elixir
register_src = File.read!("script/register_required_checks.sh")
assert String.contains?(register_src, ~s(DRY_RUN="${DRY_RUN:-1}"))  # default dry-run
assert String.contains?(register_src, "list_merge_blocking_checks.py")  # parametric discovery
assert String.contains?(register_src, "unique_by(.context)")  # idempotent merge

detector_src = File.read!("script/check_required_checks_registered.sh")
assert String.contains?(detector_src, "list_merge_blocking_checks.py")  # same source of truth
assert String.contains?(detector_src, "exit 1")  # fail-closed (GAP exit code)
assert String.contains?(detector_src, "exit 3")  # UNVERIFIED (not a pass)

# list_merge_blocking_checks.py itself
checker_src = File.read!("script/list_merge_blocking_checks.py")
assert String.contains?(checker_src, "merge-blocking")
assert String.contains?(checker_src, ".github/workflows")
```

**Cannot be asserted hermetically:** The actual `gh api` branch-protection read and `PATCH` write are live-fire admin actions; deferred per D-03.

---

### Q3: `strip_release_as.py` Idempotency — Full Analysis

**CLI-only invocation:** The script has no public function; it is invoked as `python3 script/strip_release_as.py <component> [config_path]`. All proof tests must use `System.cmd`.

**Idempotency confirmed:** Tested against the actual `release-please-config.json` (copied to `/tmp`) and a synthetic temp fixture:
- Run 1 on `crosswake_rulestead`: stripped 1 line (`"release-as": "0.1.0"`), exit 0
- Run 2 on same file: "already has no release-as/_TODO_release_as — no change", exit 0
- Run 1 on `crosswake_rindle`: stripped 2 lines (`"release-as"` + `"_TODO_release_as"`), exit 0
- Run 2: same no-change result

**Minimal-diff property:** The script does surgical line removal (not JSON re-serialization). Only the exact lines starting with `"release-as"` or `"_TODO_release_as"` are removed; all surrounding structure, whitespace, and ordering is preserved. This produces a one-line (or two-line) PR diff.

**Latent edge-case (trailing comma):** If `release-as` is the final key before the package block's closing `}`, removal leaves a trailing comma on the preceding line, causing `json.loads(new_text)` to raise `JSONDecodeError`. The script would then exit 1 without writing the file (safe failure). In the real config, `release-as` is key 4/6 for rulestead and 5/7 for rindle — followed by `"extra-files"` and `"changelog-sections"` — so this edge-case **is never triggered in practice**. However, the proof fixture MUST be designed to match this constraint (release-as not the last key), or the test will fail for the wrong reason. This is an SC gap worth noting in the audit but does not require a fix.

---

### Q4: Audit Findings Per SC

#### SC1 — `check_release_as_staleness.sh` + `release-as-staleness-gate.yml`

**Verdict: MATCHES SC. No fix required.**

- Script correctly detects stale pins via `git rev-parse -q --verify "refs/tags/${tag}"` — the authoritative signal
- Parametric: iterates ALL packages in the config via `jq`, not a hardcoded list
- Exit code 1 on any stale pin; exit 0 when clean
- Workflow: `merge-blocking-release-as-staleness` job name matches the lane registered in branch protection (per `135-REQUIRED-CHECKS-REGISTRATION.md`)
- `fetch-depth: 0` + `fetch-tags: true` in the checkout step ensures all tags are available on CI
- Current repo state: both rulestead and rindle have `release-as: "0.1.0"` but NO `crosswake_rulestead-v0.1.0` or `crosswake_rindle-v0.1.0` tags yet → **the script currently exits 0** (correct bootstrap state)

#### SC2 — `strip_release_as.py` + `release-as-cleanup` job

**Verdict: MATCHES SC with one latent edge-case. No fix required; fixture design must account for it.**

- Script idempotency confirmed (see Q3 above)
- `release-as-cleanup` job in `release-please.yml` (line 795):
  - Conditional: `if: rulestead_release_created == 'true' || rindle_release_created == 'true'`
  - Calls `python3 script/strip_release_as.py crosswake_rulestead` and/or `crosswake_rindle` as appropriate
  - Checks `git status --porcelain` before attempting to push (no-op guard)
  - Creates branch `chore/release-as-cleanup-${{ github.run_id }}` and opens PR via `gh pr create`
  - Uses `RELEASE_PLEASE_TOKEN` (preferred for chain-triggering CI on the cleanup PR) with `github.token` fallback

- **Latent edge-case:** the trailing-comma JSON parse error when `release-as` is the final key in a block. Not triggered by the real config. Fixture must use a non-final key position.

#### SC3 — `release-failure-alert` job

**Verdict: MATCHES SC exactly. No fix required.**

- Job name: `Alert on companion publish/proof failure (PROOF-03c)` ✓
- Condition: `if: ${{ failure() }}` ✓ (not `if: always()`)
- `needs:` covers exactly the four companion publish + clean-room-proof jobs ✓
- Does NOT list core `publish-hex`, `publish-ios-core`, `publish-android-core` as needs — correct scoping
- **Dormant-on-green confirmed:** GitHub Actions `failure()` returns `true` only when a dep has result `failure` or `cancelled`. `skipped` does NOT trigger it. When no companion releases this run, all four deps are `skipped` → alert job is also skipped. ✓
- Alert body references run URL, commit SHA, and per-job results ✓

#### SC4 — `script/extract_companion.md` Step 12f

**Verdict: MATCHES SC exactly. No fix required.**

- Step 12f (line ~360) explicitly says "As of Phase 135 this is CI-automated — no manual edit and no per-companion human runbook"
- Names both automation elements: `release-as-cleanup` job + `merge-blocking-release-as-staleness` check
- States "parametric over every `crosswake_*` package, so new companions inherit this for free"
- Checklist item at line ~416: `[x] release-as removal is CI-automated (PROOF-03)` — already checked
- Recipe version line at end: `*Recipe version: Phase 135 (release-as removal CI-automated — PROOF-03)*` ✓

#### SC5 — `register_required_checks.sh` + `check_required_checks_registered.sh` + `list_merge_blocking_checks.py`

**Verdict: MATCHES SC exactly. No fix required.**

- `register_required_checks.sh` is parametric (discovers all merge-blocking lanes via `list_merge_blocking_checks.py`), idempotent (`unique_by(.context)`), green-first (preflight skips lanes with no green run), and default dry-run (`DRY_RUN=1`)
- `check_required_checks_registered.sh` is fail-closed: exits 1 (GAP) when any declared lane is missing from branch protection; exits 3 (UNVERIFIED) rather than 0 when it can't read branch protection (not a pass)
- `list_merge_blocking_checks.py` is the single source of truth for both scripts — currently discovers 20 lanes including `merge-blocking-release-as-staleness` (the Phase 135 addition)
- The PyYAML dependency is required; must be noted in the proof test as an environment dependency

---

### Q5: Deferred Failure Confirmation

**Both previously-deferred core-hermetic failures are now GREEN.**

- `test/crosswake/planning/milestone_transition_reset_test.exs`: **5 tests, 0 failures** (confirmed green locally, 2026-06-28)
- `test/crosswake/proof/phase52_operator_truth_test.exs`: **6 tests, 0 failures** (confirmed green locally, 2026-06-28)
- Full hermetic suite: **1173 tests, 0 failures** (10 excluded) — UP from the previously-reported 1109 count

The runbook's note ("the two deferred failures are now fixed in Phase 135") is **pre-confirming a fix that must be proven, not something already proven**. The Phase 135 proof test must explicitly confirm these two files pass as part of the hermetic-suite self-assertion. The most faithful approach is a test that invokes `mix test` on these two files (or asserts the file structure that makes them pass), not merely asserting their existence.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Git tag lookup in hermetic tests | Custom git wrapper or mock | GIT_DIR env var injection | Standard git mechanism; zero script changes needed |
| JSON fixture generation | Custom JSON serializer | Inline heredoc string with the exact format | Controls key ordering so release-as is never the last key |
| Script idempotency proof | Mock the file system | System.cmd with a temp file + assert JSON | Script does surgical text edit; temp file is the correct medium |
| YAML parsing in ExUnit | Parse and traverse the YAML | File.read! + String.contains? | The structural presence assertions are string-level; no YAML parser needed in Elixir |
| Merge-blocking lane discovery in tests | Hardcoded list | Assert `list_merge_blocking_checks.py` runs without error and includes known lanes | Keeps the test aligned with the live discovery source |

---

## Architecture Patterns

### Proof Test Structure

The proof test mirrors `phase133_telemetry_contract_test.exs` exactly, with these differences:

- `async: true` is safe for SC2–SC5 (pure file reads + temp files with unique paths)
- SC1 requires a temp git repo; `async: true` remains safe because each test creates its own `GIT_DIR`
- No `Application.put_env` calls needed (no shared application state is modified)
- No `async: false` requirement

### Recommended Project Structure

```
test/crosswake/proof/
├── phase135_ci_ops_proof_test.exs    # NEW — the Phase 135 proof test
├── phase133_telemetry_contract_test.exs  # EXISTING — the pattern to follow
```

### Pattern 1: SC1 RED→GREEN via GIT_DIR Injection

```elixir
# Source: direct verification of script/check_release_as_staleness.sh (2026-06-28)
test "SC1: staleness guard turns RED on stale pin, GREEN after removal" do
  tmp = System.tmp_dir!() |> Path.join("crosswake-p135-sc1-#{System.unique_integer([:positive])}")
  on_exit(fn -> File.rm_rf!(tmp) end)
  File.mkdir_p!(tmp)
  {_, 0} = System.cmd("git", ["-C", tmp, "init"])
  {_, 0} = System.cmd("git", ["-C", tmp, "commit", "--allow-empty", "-m", "init"])
  {_, 0} = System.cmd("git", ["-C", tmp, "tag", "crosswake_rulestead-v0.1.0"])
  git_dir = Path.join(tmp, ".git")

  config_red = Path.join(tmp, "config-red.json")
  File.write!(config_red, ~s({"packages":{"packages/crosswake_rulestead":{"component":"crosswake_rulestead","release-type":"elixir","release-as":"0.1.0","extra-files":[]}}}))

  {output, exit_code} = System.cmd("bash", ["script/check_release_as_staleness.sh", config_red],
    env: Map.put(System.get_env(), "GIT_DIR", git_dir) |> Map.to_list(),
    stderr_to_stdout: true)
  assert exit_code == 1, "Expected RED (exit 1) for stale pin; got #{exit_code}\n#{output}"
  assert output =~ "STALE"

  config_green = Path.join(tmp, "config-green.json")
  File.write!(config_green, ~s({"packages":{"packages/crosswake_rulestead":{"component":"crosswake_rulestead","release-type":"elixir","extra-files":[]}}}))

  {output2, exit_code2} = System.cmd("bash", ["script/check_release_as_staleness.sh", config_green],
    env: Map.put(System.get_env(), "GIT_DIR", git_dir) |> Map.to_list(),
    stderr_to_stdout: true)
  assert exit_code2 == 0, "Expected GREEN (exit 0) after pin removed; got #{exit_code2}\n#{output2}"
end
```

### Pattern 2: SC2 Idempotency via System.cmd + Temp File

```elixir
# Source: direct verification of script/strip_release_as.py (2026-06-28)
test "SC2: strip_release_as.py is idempotent — strips both keys, re-run is no-op" do
  tmp_config = Path.join(System.tmp_dir!(), "crosswake-p135-sc2-#{System.unique_integer([:positive])}.json")
  on_exit(fn -> File.rm_rf!(tmp_config) end)

  # release-as MUST NOT be the last key (trailing-comma edge-case)
  File.write!(tmp_config, """
  {
    "packages": {
      "packages/crosswake_rulestead": {
        "component": "crosswake_rulestead",
        "release-type": "elixir",
        "release-as": "0.1.0",
        "_TODO_release_as": "remove after first release",
        "extra-files": []
      }
    }
  }
  """)

  {out1, 0} = System.cmd("python3", ["script/strip_release_as.py", "crosswake_rulestead", tmp_config], stderr_to_stdout: true)
  assert out1 =~ "stripped"

  content = File.read!(tmp_config)
  parsed = Jason.decode!(content)
  block = get_in(parsed, ["packages", "packages/crosswake_rulestead"])
  refute Map.has_key?(block, "release-as")
  refute Map.has_key?(block, "_TODO_release_as")

  {out2, 0} = System.cmd("python3", ["script/strip_release_as.py", "crosswake_rulestead", tmp_config], stderr_to_stdout: true)
  assert out2 =~ "no change"
end
```

### Pattern 3: Structural Wiring Assertions (SC3/SC4/SC5)

```elixir
# Source: phase133_telemetry_contract_test.exs doc-presence-assert pattern (2026-06-28)
test "SC3: release-failure-alert job is wired with if: failure()" do
  source = File.read!(".github/workflows/release-please.yml")
  assert source =~ "release-failure-alert"
  assert source =~ "if: ${{ failure() }}"
  assert source =~ "publish-hex-rulestead"  # in needs
  assert source =~ "publish-hex-rindle"
  assert source =~ "clean-room-proof-rulestead"
  assert source =~ "clean-room-proof-rindle"
end
```

### Anti-Patterns to Avoid

- **Hardcoding the current tag list in SC1:** The test must create a synthetic tag in a temp repo; referencing the real repo tags breaks hermetic isolation.
- **Invoking strip_release_as.py against the real config:** Always use a temp copy; the real config must not be mutated by a test.
- **Using `if: always()` in the alert job:** The SC3 audit confirmed `if: failure()` is used correctly; an `if: always()` would fire on skipped jobs (every non-release run) which is the anti-pattern PROOF-03c was designed to avoid.
- **Parsing YAML in the proof test:** String-level assertions are sufficient and avoid introducing a YAML parser dependency into the Elixir test suite.
- **Making the proof test `async: false`:** Not needed here; no shared global state is mutated by SC1–SC5 tests.

---

## Common Pitfalls

### Pitfall 1: Trailing-Comma Edge-Case in `strip_release_as.py`

**What goes wrong:** If `"release-as"` is the final key in a package block (before the `}`), removal of that line leaves a trailing comma on the line above (e.g., `"separate-pull-requests": true,`). The script then fails `json.loads(new_text)` and exits 1 without writing the file.

**Why it happens:** The script does regex-based line removal, not AST manipulation. It skips the preceding line's trailing comma.

**How to avoid:** Ensure proof fixtures always have at least one key after `release-as` (e.g., `"extra-files": []`). The real config satisfies this invariant (release-as is key 4/6 for rulestead, 5/7 for rindle).

**Warning signs:** `JSONDecodeError: Illegal trailing comma before end of object` in script stderr.

### Pitfall 2: GIT_DIR Collisions Between Parallel Tests

**What goes wrong:** If two SC1 test cases share a git repo directory (without `System.unique_integer`), parallel execution can cause one test to create a tag that interferes with another test's RED/GREEN assertion.

**How to avoid:** Always include `System.unique_integer([:positive])` in the temp dir path. The recommended fixture pattern above does this.

**Warning signs:** SC1 RED case passes when the tag was never created, or GREEN case fails when a leftover tag from another test exists.

### Pitfall 3: `failure()` vs `always()` in Dormant-Path Reasoning

**What goes wrong:** Confusing GitHub Actions `failure()` with `always()`. `failure()` does NOT fire when dependencies are skipped — only when they actually fail or are cancelled.

**How to avoid:** The structural assertion for SC3 should assert `if: ${{ failure() }}` is present (not `if: always()`). Do not attempt to assert dormant behavior via ExUnit; that requires a live GitHub workflow run.

**Warning signs:** SC3 structural test passes even if the `if:` condition was changed to `if: always()`.

### Pitfall 4: PyYAML Missing for SC5

**What goes wrong:** `list_merge_blocking_checks.py` prints an error to stderr and exits 2 if PyYAML is not installed. `register_required_checks.sh` and `check_required_checks_registered.sh` would then fail silently (empty array).

**How to avoid:** The proof test for SC5 that invokes `list_merge_blocking_checks.py` via `System.cmd("python3", ["script/list_merge_blocking_checks.py"])` will surface a non-zero exit code. Alternatively, assert the script output is non-empty.

---

## Code Examples

### SC1 Full RED→GREEN Test

See Pattern 1 above. Confirmed working via manual test:

```bash
# RED case: tag exists, pin set
GIT_DIR=/tmp/test-repo/.git bash script/check_release_as_staleness.sh /tmp/config-red.json
# → exits 1, prints [crosswake] STALE: ...

# GREEN case: pin removed (tag still exists, but no pin to check)
GIT_DIR=/tmp/test-repo/.git bash script/check_release_as_staleness.sh /tmp/config-green.json
# → exits 0, prints [crosswake] OK: no release-as pins set — nothing to check.
```

[VERIFIED: direct execution on local main 2026-06-28]

### SC5 Parametric Discovery

```bash
python3 script/list_merge_blocking_checks.py
# → 20 contexts including merge-blocking-release-as-staleness
```

[VERIFIED: direct execution on local main 2026-06-28]

### Current Hermetic Suite State

```bash
mix test --seed 0
# → 1173 tests, 0 failures (10 excluded)
mix test test/crosswake/planning/milestone_transition_reset_test.exs --seed 0
# → 5 tests, 0 failures
mix test test/crosswake/proof/phase52_operator_truth_test.exs --seed 0
# → 6 tests, 0 failures
```

[VERIFIED: direct execution on local main 2026-06-28]

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-03a | Staleness guard RED→GREEN | ExUnit shell-out | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |
| PROOF-03b | strip_release_as.py idempotency | ExUnit shell-out | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |
| PROOF-03b | release-as-cleanup job wired | ExUnit structural | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |
| PROOF-03c | failure-alert job + if: failure() | ExUnit structural | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |
| PROOF-03 | Recipe Step 12f automation reference | ExUnit structural | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |
| PROOF-03 | Registration tooling idempotent + fail-closed | ExUnit structural | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |
| PROOF-03 | Deferred failures now green | ExUnit (nested run) | `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs` | ❌ Wave 0 |

### Sampling Rate

- Per task commit: `mix test test/crosswake/proof/phase135_ci_ops_proof_test.exs`
- Per wave merge: `mix test`
- Phase gate: full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/proof/phase135_ci_ops_proof_test.exs` — the single deliverable; covers all 7 test rows above

---

## Security Domain

This phase introduces no new authentication, session management, input validation beyond what already exists in the landed scripts. No ASVS categories apply beyond V5 (Input Validation) for the script inputs:

- `check_release_as_staleness.sh`: reads a JSON config path from argv; validates file existence before processing
- `strip_release_as.py`: reads component name from argv; validates JSON structure after edit before writing
- Both exit non-zero on any malformed input — fail-closed

No new external secrets or API tokens introduced in this phase.

---

## Runtime State Inventory

Not applicable — this is not a rename/refactor/migration phase. All artifacts are already on local main.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash | SC1 proof test | ✓ | zsh/bash (macOS) | — |
| python3 | SC2/SC5 proof test | ✓ | 3.14.4 | — |
| PyYAML | SC5 list_merge_blocking_checks.py | ✓ | (system install) | pip install pyyaml |
| jq | check_release_as_staleness.sh | ✓ | (brew install) | — |
| git | SC1 proof fixture | ✓ | 2.x | — |
| Jason (Elixir) | SC2 proof (JSON parse assertion) | ✓ | already in deps | — |
| ExUnit | proof test runner | ✓ | Elixir built-in | — |

**Missing dependencies with no fallback:** None.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GitHub Actions `failure()` does not fire when dependency is `skipped` | SC3 audit | If this semantics changed, SC3 dormant-on-green would be broken; verify against GitHub docs if SC3 behavioral test is added |
| A2 | PyYAML is installed in the CI environment where `list_merge_blocking_checks.py` runs | SC5 | Script exits 2 with a clear error; the cleanup and register scripts would emit "0 checks found" |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed. The two assumptions above are LOW-risk and do not affect planning decisions.

---

## Open Questions (RESOLVED)

1. **Should the proof test invoke `mix test` on the two deferred-failure files as a nested System.cmd call, or simply read their source and assert structural properties?**
   - What we know: both files are currently green (5/0 and 6/0 respectively). The runbook says "fixed in Phase 135."
   - What's unclear: what was actually "fixed"? No code change to those test files was observed in the Phase 135 work. The tests appear to have been passing already (they reference planning doc state that was updated in earlier phases).
   - Recommendation: The planner should verify by checking git log for what changed in those files around 2026-06-26. If they were already green before Phase 135 landed, the "fix" is likely the STATE.md / REQUIREMENTS.md updates that unblocked them. The proof test should assert they're currently green via `mix test` with a no-op assertion on exit code, not a structural file read.
   - **RESOLVED (planner, 135-01 Task 2):** nested `mix test` asserting exit 0 on both files. Git log shows last edits in phases 111/124 (both green before the 2026-06-26 window), so the "fix" was upstream STATE/REQUIREMENTS state, not code — only an actual run proves "green."

2. **SC5: Should the proof test assert the current list of 20 merge-blocking lanes, or just assert the tool runs without error?**
   - What we know: there are currently 20 lanes. New lanes will be added over time.
   - Recommendation: Assert the tool exits 0 AND that `merge-blocking-release-as-staleness` is in the output (the Phase 135 addition) — do not hardcode all 20 names, which would require updating this test on every new merge-blocking lane.
   - **RESOLVED (planner, 135-01 Task 2):** assert `list_merge_blocking_checks.py` exits 0 and its output contains `merge-blocking-release-as-staleness`; do NOT hardcode the 20-lane set.

---

## Sources

### Primary (HIGH confidence)

- `script/check_release_as_staleness.sh` — direct read + execution, 2026-06-28
- `script/strip_release_as.py` — direct read + execution, 2026-06-28
- `.github/workflows/release-please.yml` — direct read, 2026-06-28
- `.github/workflows/release-as-staleness-gate.yml` — direct read, 2026-06-28
- `script/register_required_checks.sh` — direct read, 2026-06-28
- `script/check_required_checks_registered.sh` — direct read, 2026-06-28
- `script/list_merge_blocking_checks.py` — direct read + execution, 2026-06-28
- `script/extract_companion.md` Step 12f (~line 360) + checklist (~line 416) — direct read, 2026-06-28
- `test/crosswake/proof/phase133_telemetry_contract_test.exs` — direct read, 2026-06-28
- `.planning/phases/135-ci-ops-hardening-release-as-automation-proof-03/135-REQUIRED-CHECKS-REGISTRATION.md` — direct read, 2026-06-28

### Secondary (MEDIUM confidence)

- GitHub Actions `failure()` semantics: behavior confirmed via structural analysis of the workflow and cross-checked against known behavior [ASSUMED: training data; GitHub docs confirm `failure()` returns true for `failure` or `cancelled` statuses only]

---

## Metadata

**Confidence breakdown:**
- Audit findings (SC1–SC5): HIGH — direct code read + execution verification of every script
- Proof mechanics (ExUnit patterns): HIGH — confirmed via existing phase133 precedent + local execution
- Git-tag fixture approach: HIGH — confirmed via direct execution (GIT_DIR injection tested end-to-end)
- SC2 trailing-comma edge-case: HIGH — confirmed via direct test of both the edge-case and the real-config path
- Deferred failure status: HIGH — `mix test` run on both files 2026-06-28, both green

**Research date:** 2026-06-28
**Valid until:** Stable (the artifacts are locked on local main; only changes to the scripts themselves would invalidate this research)
