# Phase 168: 0.2.1 Release Candidate Readiness - Pattern Map

**Mapped:** 2026-09-12
**Files analyzed:** 18 likely new/modified files or file families
**Analogs found:** 18 / 18

All analogs below were verified with `git ls-files`. No runtime/plugin mirror path is used. This map is confined to the `quality-ratchet-release` workstream. Android work is coordinate/build/publication verification only; it does not add Android capability, templates, device proof, or parity breadth.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/release_candidate.ex` | service | batch / transform | `lib/crosswake/release_status.ex` | exact role/data-flow |
| `lib/crosswake/release_candidate/identity.ex` | model / utility | transform | `lib/crosswake/release_status.ex` | role-match |
| `lib/crosswake/release_candidate/receipt.ex` | model / utility | transform / file-I/O | `lib/crosswake/release_status.ex` | role-match |
| `lib/crosswake/release_candidate/artifact.ex` | service | file-I/O / batch | `script/verify_hex_publish_dry_run.sh` | data-flow match |
| `lib/crosswake/release_candidate/mirror.ex` | service | request-response / event-driven | `script/verify_ios_mirror_backfill.sh` | exact behavior |
| `lib/mix/tasks/crosswake.release.candidate.ex` | controller | request-response | `lib/mix/tasks/crosswake.release.status.ex` | exact role |
| `script/release_candidate/*` | utility adapters | file-I/O / request-response | `script/verify_hex_publish_dry_run.sh`, `script/verify_ios_mirror_backfill.sh` | exact behavior |
| `script/verify_companion_cleanroom.sh` | service / harness | batch / file-I/O | same file | extension |
| `script/check_phase167_pr_dispositions.py` | service / validator | request-response / transform | same file | extension |
| `test/js/phase167_pr_dispositions.test.mjs` | test | request-response / transform | same file | extension |
| `test/crosswake/release_candidate/*_test.exs` | test | batch / transform | `test/mix/tasks/crosswake_release_status_test.exs` | role-match |
| `test/mix/tasks/crosswake_release_candidate_test.exs` | test | request-response | `test/mix/tasks/crosswake_release_status_test.exs` | exact role |
| `test/fixtures/release_candidate/**` | test fixture | file-I/O / transform | Phase 167 evidence fixtures consumed by `test/js/phase167_pr_dispositions.test.mjs` | role-match |
| `.github/workflows/crosswake-ci.yml` | config | event-driven / batch | same file's release-sensitive jobs | extension |
| `.github/workflows/release-please.yml` | config | event-driven / pub-sub | same file's path-gated publish graph | extension |
| `.github/workflows/ios-mirror-backfill.yml` | config | event-driven / request-response | same file | extension |
| `script/check_release_workflow_integrity.exs` | test / structural scanner | batch / transform | same file | extension |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | config / documentation | request-response | same file | extension |

The five Phase 167 handoff paths are prerequisite landing inputs, not templates for new runtime code. Preserve their exact `100644` blob identities and add a machine receipt; do not rewrite their content while landing them.

## Pattern Assignments

### Candidate domain modules and receipt

**Applies to:** `lib/crosswake/release_candidate.ex`, `lib/crosswake/release_candidate/{identity,receipt,artifact,mirror}.ex`

**Analog:** `lib/crosswake/release_status.ex`

**Module constants and allowlisted contract** (lines 1-27):

```elixir
defmodule Crosswake.ReleaseStatus do
  @schema_version "1.0.0"
  @manifest_path ".release-please-manifest.json"
  @config_path "release-please-config.json"
  @workflow_path ".github/workflows/release-please.yml"
  @probe_attempts 3
  @probe_retry_sleep_ms 200
  @release_components ~w(rulestead rindle sigra chimeway threadline)
```

Copy the checked-in-path and explicit allowlist style. Candidate code should introduce its own receipt schema and exact five states, while composing status checks rather than changing `ReleaseStatus` into a mutating orchestrator.

**Functional core with injected observations** (lines 66-92, 916-926):

```elixir
def build(opts \\ []) do
  cwd = Keyword.get(opts, :cwd, File.cwd!())
  live? = Keyword.get(opts, :live?, false)
  manifest = read_json!(cwd, @manifest_path)
  config = read_json!(cwd, @config_path)
  workflow = read_file!(cwd, @workflow_path)
  probes = live_probes(opts)
  # derive one map from bounded observations
end

defp live_probes(opts) do
  %{
    http: Keyword.get(opts, :http_probe, &http_live_probe/2),
    git_ref: Keyword.get(opts, :git_ref_probe, &git_ref_live_probe/2)
  }
end
```

Use the same keyword-injected seams for command runner, filesystem, GitHub, Git/remote, time, and run metadata. Stable receipt fields must be canonicalized separately from volatile envelope fields.

**Fail-closed aggregation and exit code** (lines 729-739):

```elixir
def aggregate_status(checks) do
  cond do
    Enum.any?(checks, &(&1.status == :error)) -> :error
    Enum.any?(checks, &(&1.status == :warning)) -> :warning
    true -> :ok
  end
end

def exit_code(:error), do: 1
def exit_code(%{status: status}), do: exit_code(status)
def exit_code(_status), do: 0
```

Adapt the precedence to `PARTIAL`, `STALE`, `BLOCKED`, `READY FOR APPROVAL`, and `COMPLETE`; unknown/incomplete observations must never collapse to readiness.

**Bounded unavailable-vs-absent handling** (lines 928-959):

```elixir
def probe_with_retry(fun, attempts, sleep_ms) when attempts > 1 do
  case fun.() do
    %{status: :unavailable} ->
      if sleep_ms > 0, do: Process.sleep(sleep_ms)
      probe_with_retry(fun, attempts - 1, sleep_ms)
    result -> result
  end
end
```

Retain bounded retries only in real adapters. Fixtures must remain single-call and deterministic.

### Thin candidate Mix task

**Applies to:** `lib/mix/tasks/crosswake.release.candidate.ex`

**Analog:** `lib/mix/tasks/crosswake.release.status.ex`

**Parse, delegate, render, fail** (lines 20-47):

```elixir
{opts, _argv, invalid} = OptionParser.parse(args, strict: [json: :boolean, live: :boolean])
if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")
status = Crosswake.ReleaseStatus.build(live?: opts[:live] == true)
output = if opts[:json], do: Jason.encode!(status, pretty: true), else: Crosswake.ReleaseStatus.render(status)
Mix.shell().info(output)
if Crosswake.ReleaseStatus.exit_code(status) != 0, do: Mix.raise("Crosswake release status found blocking release issues")
```

Copy the shape, replacing options with exactly `version`, `ref`, and `output-dir`. Validate exact `0.2.1` and lowercase 40-SHA at the boundary, delegate all evaluation/serialization, print the answer-first terminal projection, and fail nonzero unless the evaluator permits the requested read-only candidate operation.

### Hex/package adapter and candidate-local clean room

**Applies to:** `lib/crosswake/release_candidate/artifact.ex`, `script/release_candidate/*`, `script/verify_companion_cleanroom.sh`

**Analogs:** `script/verify_hex_publish_dry_run.sh`, `script/verify_companion_cleanroom.sh`

**Isolated, non-authorizing Hex environment** (`verify_hex_publish_dry_run.sh`, lines 7-25):

```bash
set -euo pipefail
hex_home="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-hex-dry-run.XXXXXX")"
cleanup() { rm -rf -- "$hex_home"; }
trap cleanup EXIT
env -u HEX_API_KEY HEX_HOME="$hex_home" mix hex.config api_key "$sentinel" >/dev/null
env -u HEX_API_KEY HEX_HOME="$hex_home" HEX_OFFLINE=1 mix hex.publish --dry-run --yes
```

Create every root uniquely, trap only that invocation-owned root, isolate `MIX_HOME`, `HEX_HOME`, deps/build/lock state, and never serialize credentials or raw tool logs.

**Existing profile journey to preserve** (`verify_companion_cleanroom.sh`, lines 15-26, 418-425, 723-740):

```bash
mix deps.get
assert_lockfile_postconditions
mix compile --warnings-as-errors
# ... public-seam smoke and runtime registration ...
mix crosswake.doctor --router CleanRoomHost.Router
ok "verify_companion_cleanroom: package=${PACKAGE} ... state=passed"
```

Replace the predictable `clean_room_${PACKAGE}`/`mix new` setup at lines 331-346 with an invocation-unique root and pinned `phx_new 1.8.13`. Run installation twice in fresh state. Candidate mode may point only to unpacked tarball roots; public mode must fetch exact registry versions and reject `:path` lock entries. Preserve all five positive lanes and their negative controls, including Threadline as unregistered observer. Do not add companion breadth.

### Mirror adapter and authority workflow

**Applies to:** `lib/crosswake/release_candidate/mirror.ex`, mirror shell adapter, `.github/workflows/ios-mirror-backfill.yml`, `.github/workflows/release-please.yml`

**Analog:** `script/verify_ios_mirror_backfill.sh`

**Strict input and standard split lineage** (lines 93-108, 179-197):

```bash
if ! printf "%s" "$VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+'; then
  fail "VERSION ... is not valid" "Pass the exact Release Please version."
fi
SPLIT_SHA="$(git -C "$RELEASE_REPO" subtree split --prefix="$IOS_PATH" "$SOURCE_REF" 2>/dev/null | tail -1)"
[ -n "$SPLIT_SHA" ] || fail "git subtree split produced no SHA" "Confirm full history."
```

Candidate mode changes `SOURCE_REF` to the exact 40-SHA. Keep `git subtree split`; do not introduce another split engine.

**Dry-run and immutable-tag behavior** (lines 235-245):

```bash
git -C "$RELEASE_REPO" push --dry-run --porcelain "$push_remote" "${SPLIT_SHA}:refs/tags/v${VERSION}" >/dev/null
if [ "$APPLY" -ne 1 ]; then
  ok "verification-only mode made no changes."
  return
fi
```

Candidate rehearsal must exercise the complete intended atomic main+tag refspec with credentials and record `external_state_changed: false`. Local credential absence yields `WRITE AUTHORITY NOT CHECKED`, hence `BLOCKED`.

**Important negative analog** (`verify_ios_mirror_backfill.sh`, lines 248-267; `release-please.yml`, lines 465-496): current normal flow uses `--force-with-lease`. Do not copy it into normal publication. Normal mode must fetch, require remote main ancestry, and use ordinary `git push --atomic`; preserve force-with-lease only in a separately invoked recovery route.

The workflow credential boundary currently appears in `.github/workflows/ios-mirror-backfill.yml` lines 71-88. Split the credential-free baseline into a job/step that runs before the SSH agent; inject `MIRROR_DEPLOY_KEY` only for trusted rehearsal and publication.

### Cursor-complete Phase 167 authority

**Applies to:** `script/check_phase167_pr_dispositions.py`, `test/js/phase167_pr_dispositions.test.mjs`

**Analog:** the existing validator and fixture suite.

**Current query seam to replace** (`check_phase167_pr_dispositions.py`, lines 1017-1049):

```python
comments(last:100) {{ nodes {{ body }} }}
response = gh_json("api", "graphql", "-f", f"query={query}")
repository = response.get("data", {}).get("repository")
require_closeout(isinstance(repository, dict))
```

Add `pageInfo { hasPreviousPage startCursor }` and `totalCount`; page backward until complete. Null, invalid, or non-advancing cursors and any page error are closed failures/`BLOCKED`, never absence.

**Privacy and mutation-table tests** (`phase167_pr_dispositions.test.mjs`, lines 235-267):

```javascript
for (const [name, change] of cases) {
  await t.test(name, () => {
    const candidate = clone(receipt);
    change(candidate);
    assertClosedFailure(runValidator(closeoutArgs(pathname)), "... FAIL closed_failure");
  });
}
assert.doesNotMatch(`${result.stdout}${result.stderr}`, new RegExp(canary));
assert.doesNotMatch(`${result.stdout}${result.stderr}`, /https?:\/\//);
```

Use this exact style for >100 comments, multiple pages, malformed/non-advancing cursor, and fetch-failure fixtures.

### Candidate ExUnit and fixtures

**Applies to:** `test/crosswake/release_candidate/*_test.exs`, `test/mix/tasks/crosswake_release_candidate_test.exs`, `test/fixtures/release_candidate/**`

**Analog:** `test/mix/tasks/crosswake_release_status_test.exs`

**Injected external observations** (lines 420-451):

```elixir
Crosswake.ReleaseStatus.build(
  live?: true,
  http_probe: fn _url, context ->
    case context do
      %{kind: :hex, package: "crosswake_sigra"} -> %{status: :missing, evidence: ["released but absent"]}
      _ -> %{status: :ok, evidence: ["live"]}
    end
  end,
  git_ref_probe: fn _remote, _ref -> %{status: :ok, evidence: ["mirror ok"]} end
)
```

Build table-driven mutation coverage for every D-04 identity, all five states, deterministic JSON/Markdown/terminal projection, `NO_COLOR`, unknown fields, path escape/symlink cases, privacy canaries, five clean-room lanes, and four mirror modes.

**Read-only separation guard** (lines 472-489): retain the existing assertions forbidding `hex.publish`, `git push`, `--apply`, and `gh pr` in `ReleaseStatus`; add corresponding candidate preapproval assertions proving no external mutation.

### CI, release graph, scanner, and runbook

**Applies to:** `.github/workflows/crosswake-ci.yml`, `.github/workflows/release-please.yml`, `script/check_release_workflow_integrity.exs`, `docs/COMPANION-PUBLISH-RUNBOOK.md`

**Fail-safe release-sensitive scheduling** (`crosswake-ci.yml`, lines 25-66):

```yaml
- name: Classify the validated base-to-merge diff
  if: always()
  run: |
    set -euo pipefail
    echo 'classification=full_proof' >> "$GITHUB_OUTPUT"
    echo 'reason=checkout_or_object_validation_failed' >> "$GITHUB_OUTPUT"
```

Extend existing classifier/leaf ownership and the single `Crosswake CI` umbrella. Do not create an always-on workflow family. Candidate artifacts must bind tested head/tree/base, workflow run, config digests, and receipt digest.

**Exact component gates** (`release-please.yml`, lines 33-99): use `paths_released` and exact component outputs for behavior. Never gate publication on aggregate `releases_created`, and keep companions outside the linked 0.2.1 approval.

**Honest partial rollup** (`release-please.yml`, lines 642-703): evolve the existing per-platform `published`/`proven`/`failed` calculation into the receipt's `COMPLETE` or `PARTIAL`, preserving successful exact coordinates and the failed child. Before any child, verify merge parentage and tree equality against the approved receipt.

**Runbook voice and boundary** (`docs/COMPANION-PUBLISH-RUNBOOK.md`, lines 16-46, 150-176): retain answer-first commands, exact immutable-coordinate semantics, machine fields over prose, read-only status separation, and the rule that post-merge publish/proof jobs are not PR-required checks. Reconcile the stale “missing 0.2.0 mirror tag” language to the exact idempotent baseline.

## Shared Patterns

### Privacy-safe evidence

Apply to every receipt, projection, adapter failure, workflow artifact, and test. Serialize only allowlisted low-cardinality facts. Never include secrets, actors, private URLs, raw package contents/logs, adopter details, tokens, credentials, account/device identifiers, or volatile scratch paths. Use the non-echoing test pattern from `test/js/phase167_pr_dispositions.test.mjs:252-267`.

### Exact identity and staleness

Bind candidate head, tree, base/default commit, linked coordinate tuple, normalized package payload/metadata, workflows/config, mirror plan, proof results, and CI run. Recompute before the one merge approval and before every irreversible child. Any change is `STALE`; incomplete or ambiguous observation is `BLOCKED`.

### Error handling and remediation

Use fail-closed textual states and exactly one safe next action. Shell adapters use `set -euo pipefail`, narrow `fail`/`ok` helpers, and invocation-owned cleanup. Elixir evaluators return structured results; only the Mix boundary raises/exits.

### Authentication and least privilege

Read-only local/baseline checks use no credentials. The single-repository deploy key exists only in trusted mirror rehearsal/publication steps. Candidate PR code must never receive publication credentials. No second approval environment is added.

### Test ownership

Fast deterministic fixtures stay on ordinary PRs; the full distributable/generated-host/mirror-authority matrix runs only for release-sensitive or refreshed Release Please candidate changes. Automated proof is the gate; human action is only the single irreversible merge approval or unavoidable credential setup.

## No Analog Found

None. Every likely new file has a tracked role or behavior analog. Some analogs are intentionally incomplete and are marked as negative patterns above (predictable clean-room deletion, one-page comments, credential-loaded baseline, and normal-path force-with-lease).

## Metadata

**Analog search scope:** `lib/crosswake`, `lib/mix/tasks`, `script`, `test`, `.github/workflows`, `docs`
**Strong analogs used:** 9 tracked files (stopped after sufficient role/data-flow coverage)
**Pattern extraction date:** 2026-09-12
