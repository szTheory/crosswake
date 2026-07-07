# Phase 143: Guarded Auto-Publish Train - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 6 new/modified files
**Analogs found:** 6 / 6

## Scope Boundary

Phase 143 is limited to automatic Hex publish idempotency, component-aware exact-ref Hex recovery, and semantic proof extensions. Do not plan Phase 144 clean-room exactness, Phase 145 SwiftPM/Maven recovery or mirror backfill, or Phase 146 release-status completion from this map.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `script/guarded_hex_publish.sh` | utility | request-response, batch | `script/verify_companion_cleanroom.sh` | role-match |
| `.github/workflows/release-please.yml` | config | event-driven, request-response | existing Hex publish jobs in same file | exact |
| `.github/workflows/hex-publish.yml` | config | manual event-driven, request-response | root-only recovery workflow + release workflow companion jobs | role-match |
| `script/check_release_workflow_integrity.exs` | utility | transform | same semantic scanner | exact |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | test | transform | same ExUnit wrapper | exact |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | doc | request-response | existing companion publish runbook | role-match |

## Pattern Assignments

### `script/guarded_hex_publish.sh` (utility, request-response/batch)

**Analog:** `script/verify_companion_cleanroom.sh`

**Shell header and validation pattern** (`script/verify_companion_cleanroom.sh` lines 48-57):

```bash
set -euo pipefail

PACKAGE="${1:-crosswake_rulestead}"
VERSION="${2:?}" # required: VERSION?: pass a semver string as \$2
if [ -z "${VERSION:-}" ]; then
  echo "[crosswake] FAIL: VERSION required as \$2 (e.g. 0.1.0)"
  exit 1
fi
```

**Hex registry polling pattern** (`script/verify_companion_cleanroom.sh` lines 118-141):

```bash
MAX_ATTEMPTS=36
DELAY=10

HEX_FOUND=false
for i in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -fsS "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}" | grep -q '"version"'; then
    echo "[crosswake] Hex.pm lists ${PACKAGE} ${VERSION}"
    HEX_FOUND=true
    break
  fi
  echo "[crosswake] waiting for Hex propagation... (${i}/${MAX_ATTEMPTS})"
  sleep "$DELAY"
done
```

**Fail-closed operator copy pattern** (`script/check_release_as_staleness.sh` lines 59-72):

```bash
if git rev-parse -q --verify "refs/tags/${tag}" >/dev/null 2>&1; then
  stale_found=1
  echo "[crosswake] STALE: '${component}' pins release-as '${version}', but tag '${tag}' already exists."
  echo "[crosswake]   What happened: '${version}' is already released, so this one-shot bootstrap pin is now stuck —"
  echo "[crosswake]   What to do next: remove \"release-as\" (and any \"_TODO_release_as\") from the"
fi
```

**Parsed JSON pattern** (`.github/workflows/release-please.yml` lines 964-966):

```bash
STATE=$(curl -fsS -X POST -H "$AUTH" \
  "https://central.sonatype.com/api/v1/publisher/status?id=${DEPLOYMENT_ID}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('deploymentState',''))")
```

**Package map pattern to create in the helper:**

| Package | Working Directory | Version File | Release Env | Test Command | Publish Command |
|---------|-------------------|--------------|-------------|--------------|-----------------|
| `crosswake` | `.` | `mix.exs` | none | `mix test --exclude requires_example_host` | `mix hex.publish --yes` |
| `crosswake_rulestead` | `packages/crosswake_rulestead` | `packages/crosswake_rulestead/mix.exs` | `CROSSWAKE_RELEASE=1` | `mix test` | `mix hex.publish --yes` |
| `crosswake_rindle` | `packages/crosswake_rindle` | `packages/crosswake_rindle/mix.exs` | `CROSSWAKE_RELEASE=1` | `mix test` | `mix hex.publish --yes` |
| `crosswake_sigra` | `packages/crosswake_sigra` | `packages/crosswake_sigra/mix.exs` | `CROSSWAKE_RELEASE=1` | `mix test` | `mix hex.publish --yes` |
| `crosswake_chimeway` | `packages/crosswake_chimeway` | `packages/crosswake_chimeway/mix.exs` | `CROSSWAKE_RELEASE=1` | `mix test` | `mix hex.publish --yes` |
| `crosswake_threadline` | `packages/crosswake_threadline` | `packages/crosswake_threadline/mix.exs` | `CROSSWAKE_RELEASE=1` | `mix test` | `mix hex.publish --yes` |

**Required helper behavior:** verify the expected `@version` in the mapped version file, query `https://hex.pm/api/packages/$package/releases/$version`, parse JSON to confirm exact `.version == $version`, print `[crosswake] OK: ... already live ... no publish attempted` and exit 0 when exact live state is proven, otherwise run dry-run, publish, and poll. Do not use `--replace`.

---

### `.github/workflows/release-please.yml` (config, event-driven/request-response)

**Analog:** existing Hex publish and proof jobs in `.github/workflows/release-please.yml`

**Release Please identity output pattern** (lines 39-76):

```yaml
paths_released: ${{ steps.release.outputs.paths_released || '[]' }}
rulestead_release_created: ${{ steps.release.outputs['packages/crosswake_rulestead--release_created'] }}
rulestead_tag_name: ${{ steps.release.outputs['packages/crosswake_rulestead--tag_name'] }}
rulestead_version: ${{ steps.release.outputs['packages/crosswake_rulestead--version'] }}
```

**Exact gate and least-permission pattern** (root lines 96-104, companion lines 170-180):

```yaml
publish-hex:
  name: Publish to Hex.pm
  needs: release-please
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}
  runs-on: ubuntu-latest
  permissions:
    contents: read
```

```yaml
publish-hex-rulestead:
  name: Publish crosswake_rulestead to Hex.pm
  needs: release-please
  if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' }}
  runs-on: ubuntu-latest
  permissions:
    contents: read
```

**Current direct publish pattern to replace with helper calls** (`.github/workflows/release-please.yml` lines 413-424):

```yaml
- name: Dry run Hex publish
  working-directory: packages/crosswake_sigra
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: mix hex.publish --dry-run --yes

- name: Publish crosswake_sigra to Hex
  working-directory: packages/crosswake_sigra
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: mix hex.publish --yes
```

**Already-exists skip analog** (`.github/workflows/release-please.yml` lines 663-675):

```yaml
if git ls-remote --exit-code mirror "refs/tags/v${VERSION}" >/dev/null 2>&1; then
  echo "[crosswake] iOS mirror tag v${VERSION} already exists; skipping mirror push."
  exit 0
fi
git push mirror "${SPLIT_SHA}:refs/heads/main"
git push mirror "${SPLIT_SHA}:refs/tags/v${VERSION}"
```

**Proof must remain downstream of publish success** (`.github/workflows/release-please.yml` lines 1104-1134):

```yaml
clean-room-proof-sigra:
  name: Clean-room proof — crosswake_sigra resolvability + doctor
  needs: [release-please, publish-hex-sigra]
  if: ${{ needs.release-please.outputs.sigra_release_created == 'true' }}
  runs-on: ubuntu-latest
```

**Cleanup after publish and proof pattern** (`.github/workflows/release-please.yml` lines 1216-1278):

```yaml
release-as-cleanup:
  needs:
    - release-please
    - publish-hex-rulestead
    - publish-hex-rindle
    - publish-hex-sigra
    - publish-hex-chimeway
    - publish-hex-threadline
    - clean-room-proof-rulestead
    - clean-room-proof-rindle
    - clean-room-proof-sigra
    - clean-room-proof-chimeway
    - clean-room-proof-threadline
```

**Implementation note:** replace every automatic Hex dry-run/publish/verify block with the shared helper, but keep existing exact Release Please gates, tag checkouts, setup-beam/cache shapes, `CROSSWAKE_RELEASE=1` companion env, and proof/cleanup `needs:` structure. A helper exit 0 for exact already-live state must still count as publish success so proof jobs run.

---

### `.github/workflows/hex-publish.yml` (config, manual event-driven/request-response)

**Analog:** `.github/workflows/hex-publish.yml` root-only recovery plus release workflow companion publish jobs

**Current manual input pattern to broaden** (`.github/workflows/hex-publish.yml` lines 10-18):

```yaml
workflow_dispatch:
  inputs:
    tag:
      description: 'Git tag or commit SHA to publish from (e.g. v0.1.0).'
      required: true
      type: string
    release_version:
      description: 'Expected @version string in mix.exs at that ref (e.g. 0.1.0).'
      required: true
      type: string
```

**Exact checkout pattern** (`.github/workflows/hex-publish.yml` lines 29-32):

```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
  with:
    ref: ${{ inputs.tag }}
```

**Version verification pattern** (`.github/workflows/hex-publish.yml` lines 51-52):

```yaml
- name: Verify release version in mix.exs
  run: grep -n "@version \"${{ inputs.release_version }}\"" mix.exs
```

**Build/test/recovery publish sequence to preserve through helper** (`.github/workflows/hex-publish.yml` lines 54-77):

```yaml
- name: Fetch library deps
  run: mix deps.get

- name: Compile (warnings as errors)
  run: mix compile --warnings-as-errors

- name: Run library tests
  env:
    MIX_ENV: test
  run: mix test --exclude requires_example_host

- name: Dry run Hex publish
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: mix hex.publish --dry-run --yes

- name: Publish to Hex
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: mix hex.publish --yes
```

**Package choice source** (`release-please-config.json` lines 95-174):

```json
"packages/crosswake_rulestead": {
  "component": "crosswake_rulestead",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "extra-files": ["packages/crosswake_rulestead/mix.exs"]
}
```

**Implementation note:** change `tag` to `ref`, add a `package` choice input for `crosswake`, `crosswake_rulestead`, `crosswake_rindle`, `crosswake_sigra`, `crosswake_chimeway`, and `crosswake_threadline`, reject branch-shaped refs before checkout, print the resolved SHA after checkout, then call `script/guarded_hex_publish.sh` with the selected package and expected version. Keep recovery Hex-only.

---

### `script/check_release_workflow_integrity.exs` (utility, transform)

**Analog:** same semantic scanner

**Module/check-list pattern** (lines 3-38):

```elixir
defmodule Crosswake.ReleaseWorkflowIntegrity do
  @default_workflow ".github/workflows/release-please.yml"
  @components ~w(rulestead rindle sigra chimeway threadline)

  def run(argv \\ System.argv(), env_path \\ System.get_env("RELEASE_WORKFLOW_PATH")) do
    workflow_path = workflow_path(argv, env_path)
    workflow = File.read!(workflow_path)
    non_comment_workflow = strip_full_line_comments(workflow)
    jobs = job_blocks(workflow)

    checks =
      [
        concurrency_not_cancelled(non_comment_workflow),
        concurrency_queue_max(non_comment_workflow),
        no_true_cancellation(non_comment_workflow),
        paths_released(non_comment_workflow)
      ] ++ component_gates(jobs) ++ component_proof_gates(jobs)
```

**Stable check output pattern** (lines 42-50):

```elixir
for {status, id, detail} <- checks do
  prefix = if status == :ok, do: "OK", else: "FAIL"
  IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
end
```

**YAML job parser/comment stripping pattern** (lines 58-67):

```elixir
defp job_blocks(workflow) do
  ~r/(?ms)^  ([A-Za-z0-9_-]+):\n(.*?)(?=^  [A-Za-z0-9_-]+:\n|\z)/
  |> Regex.scan(workflow, capture: :all_but_first)
  |> Map.new(fn [name, block] -> {name, strip_full_line_comments(block)} end)
end

defp strip_full_line_comments(text) do
```

**Semantic gate pattern** (lines 161-194):

```elixir
defp path_gate(jobs, id, job, path) do
  check(
    id,
    job_if(jobs, job) == path_gate_expression(path),
    "#{job} must gate on paths_released exact path #{path}; run elixir script/check_release_workflow_integrity.exs"
  )
end

defp aggregate_gate_absent(jobs) do
  offenders =
    jobs
    |> Enum.filter(fn {job, _block} ->
      behavioral_job?(job) and
        includes?(job_if(jobs, job), "needs.release-please.outputs.releases_created")
    end)
```

**Component loop pattern** (lines 291-318):

```elixir
defp component_gates(jobs) do
  for component <- @components do
    job = "publish-hex-#{component}"

    check(
      "release.#{component}.component_gate",
      job_if(jobs, job) == component_gate_expression(component),
      "#{job} must gate on #{component}_release_created, not aggregate releases_created; run elixir script/check_release_workflow_integrity.exs"
    )
  end
end
```

**Implementation note:** add semantic checks for automatic Hex jobs using `script/guarded_hex_publish.sh`, already-live preflight before irreversible publish, no normal `--replace`, recovery workflow package/ref/version inputs, branch-shaped ref rejection, package-map coverage, and proof continuation after already-live success. Keep stable check IDs such as `release.hex_publish.guarded_preflight` and `recovery.hex.package_map`.

---

### `test/crosswake/proof/phase142_release_integrity_test.exs` (test, transform)

**Analog:** same ExUnit wrapper

**Proof wrapper pattern** (lines 17-25):

```elixir
test "release workflow integrity script passes" do
  {output, exit_code} = run_scanner(@workflow)

  assert exit_code == 0, output
  assert output =~ "release.root_hex.path_gate"
  assert output =~ "release.concurrency.queue_max"
  assert output =~ "release.aggregate_gate.behavioral_jobs_absent"
  assert output =~ "release.cleanup.after_publish_and_proof"
end
```

**Negative fixture mutation pattern** (lines 79-88):

```elixir
test "aggregate identity in a behavioral job fails with stable check id" do
  workflow =
    real_workflow()
    |> String.replace(
      "if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}",
      "if: ${{ needs.release-please.outputs.releases_created == 'true' }}",
      global: false
    )

  assert_failure!("release.aggregate_gate.behavioral_jobs_absent", workflow)
end
```

**Comment-decoy proof pattern** (lines 91-108):

```elixir
test "full-line comments cannot satisfy or violate semantic checks" do
  commented_queue =
    real_workflow()
    |> String.replace("  queue: max", "  # queue: max", global: false)

  assert_failure!("release.concurrency.queue_max", commented_queue)

  aggregate_comment =
    real_workflow()
    |> String.replace(
      "  publish-hex:\n    name:",
      "  publish-hex:\n    # if: ${{ needs.release-please.outputs.releases_created == 'true' }}\n    name:",
      global: false
    )
```

**Fixture runner pattern** (lines 187-220):

```elixir
defp assert_failure!(check_id, workflow) do
  {output, exit_code} = run_fixture(workflow)

  assert exit_code == 1, output
  assert output =~ "[crosswake] FAIL: #{check_id}"
end

defp run_scanner(path) do
  System.cmd("elixir", [@scanner, path], stderr_to_stdout: true)
end
```

**Implementation note:** extend this file with Phase 143 assertions and negative fixtures instead of creating a disconnected proof style. Recommended fixtures: direct `mix hex.publish --yes` without helper fails; helper call without already-live preflight fails; root-only recovery input fails; `--replace` fails; branch-shaped recovery ref passes only if rejected.

---

### `docs/COMPANION-PUBLISH-RUNBOOK.md` (doc, request-response)

**Analog:** existing companion publish runbook

**Old human-gated posture to reconcile** (lines 3-16):

```markdown
**The safety rail for the irreversible, batched companion-family publish.**

This runbook is the human-facing operating procedure for taking the three
extracted companion packages ... live on hex.pm, one at a time, in a fixed order.

> **Readiness, not execution.** Authoring and verifying this runbook is the
> complete Phase-140 `FAMILY-04` deliverable.
```

**Already-live recovery warning to preserve and update** (lines 228-240):

```markdown
### Hex is irreversible — the ~60-minute revert window

Once `mix hex.publish` completes, the package version is **permanent.**

- **Do NOT retry a failed publish by re-pushing.** First check whether the version
  already made it to hex.pm. If it did, re-pushing will fail (version exists) and
  you must go through `mix hex.retire` + a new version — never assume a failed job
  means "nothing published."
```

**Do-not-register publish job warning to preserve** (lines 270-276):

```markdown
The companion `publish-hex-*` and `clean-room-proof-*` jobs are **POST-MERGE** jobs:
they run only after a Release PR merges and are SKIPPED on normal PRs.

> **MUST NOT** register `publish-hex-*` or `clean-room-proof-*` as required checks.
```

**Implementation note:** rewrite the runbook around Release Please PR merge as the human approval boundary, CI as the happy-path publish owner, and manual dispatch as exact-ref recovery only. Keep the irreversible Hex warnings and already-live check, but replace "human drives publish loop" language with helper/recovery commands and expected `[crosswake] OK/FAIL` log meanings.

## Shared Patterns

### Exact Release Identity

**Source:** `.github/workflows/release-please.yml` lines 39-76 and `script/check_release_workflow_integrity.exs` lines 161-194  
**Apply to:** `release-please.yml`, `hex-publish.yml`, scanner, ExUnit proof

Use Release Please path/component outputs for behavior. Aggregate `releases_created` remains summary/log-only. Root Hex gates on `paths_released` containing `.`, companions gate on `<component>_release_created == 'true'`.

### Hex Idempotency

**Source:** `script/verify_companion_cleanroom.sh` lines 118-141; `.github/workflows/release-please.yml` lines 663-675  
**Apply to:** `script/guarded_hex_publish.sh`, both workflows, docs

Registry presence is state. If the exact package/version is live and identity is proven, print `[crosswake] OK`, skip publish, and continue proof. If identity cannot be proven, fail closed with a next action. Current codebase has no `--replace` use; keep it out of normal paths.

### Version Graph And Floors

**Source:** `release-please-config.json` lines 8-10, 95-174; `.release-please-manifest.json` lines 2-9; package `mix.exs` files  
**Apply to:** helper package map, scanner proof, docs

Core Hex + iOS core + Android core are the only `linked-versions` group. Companions remain independent package entries. Preserve mixed floors: `rulestead` and `rindle` use `~> 0.1` (`packages/crosswake_rulestead/mix.exs` line 68; `packages/crosswake_rindle/mix.exs` line 83), while `sigra`, `chimeway`, and `threadline` use `~> 0.2` (`packages/crosswake_sigra/mix.exs` line 55; `packages/crosswake_chimeway/mix.exs` line 63; `packages/crosswake_threadline/mix.exs` line 60).

### Operator Copy

**Source:** `script/check_release_as_staleness.sh` lines 59-72 and `script/verify_companion_cleanroom.sh` lines 89-103, 134-141  
**Apply to:** helper, workflow run logs, recovery docs

Prefix release logs with `[crosswake]`. Name the package, version, registry state, skipped command, proof continuation, and next safe action. Avoid vague success language.

### Semantic Proof Style

**Source:** `script/check_release_workflow_integrity.exs` lines 123-124, 291-318; `test/crosswake/proof/phase142_release_integrity_test.exs` lines 187-220  
**Apply to:** scanner and ExUnit file

Add checks as stable IDs returning `{:ok | :error, id, detail}`. Use string/regex semantic checks against stripped job blocks, and prove failure modes by mutating the real workflow into temporary fixtures.

## No Analog Found

No Phase 143 file lacks an analog. The new helper has no exact single predecessor, but `verify_companion_cleanroom.sh`, `check_release_as_staleness.sh`, and existing Hex publish jobs cover the shell, registry, and operator-copy patterns.

## Metadata

**Analog search scope:** `.github/workflows`, `script`, `test/crosswake/proof`, `docs`, `guides`, `release-please-config.json`, `.release-please-manifest.json`, root and companion `mix.exs` files.  
**Files scanned:** 23  
**Project skills:** no project-local `.codex/skills` or `.agents/skills` found.  
**Pattern extraction date:** 2026-07-07
