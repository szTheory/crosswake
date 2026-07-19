# Phase 145: Native Registry & Mirror Parity - Pattern Map

**Mapped:** 2026-07-08
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/release-please.yml` | config/workflow | event-driven + batch + request-response | `.github/workflows/release-please.yml` | exact |
| `.github/workflows/ios-mirror-backfill.yml` (optional new wrapper) | config/workflow | workflow_dispatch + batch | `.github/workflows/hex-publish.yml`; `.github/workflows/native-collateral-advisory.yml` | role-match |
| `script/check_release_workflow_integrity.exs` | utility/static scanner | file-I/O + transform | `script/check_release_workflow_integrity.exs` | exact |
| `test/crosswake/proof/phase142_release_integrity_test.exs` | test | file-I/O + transform | `test/crosswake/proof/phase142_release_integrity_test.exs` | exact |
| `script/verify_ios_mirror_backfill.sh` | utility/script | batch + file-I/O + request-response | `script/guarded_hex_publish.sh`; `script/verify_generated_ios_shell.sh` | role-match |
| `docs/COMPANION-PUBLISH-RUNBOOK.md` | docs/runbook | transform | `docs/COMPANION-PUBLISH-RUNBOOK.md` | exact |
| `guides/support_matrix.md` | docs/support truth | transform | `guides/support_matrix.md` | exact |
| `guides/companion_compatibility.md` | docs/compatibility truth | transform | `guides/companion_compatibility.md` | exact |

## Pattern Assignments

### `.github/workflows/release-please.yml` (config/workflow, event-driven + batch + request-response)

**Analog:** `.github/workflows/release-please.yml`

**Release output and exact path gate pattern** (lines 33-46, 386-390):

```yaml
outputs:
  releases_created: ${{ steps.release.outputs.releases_created }}
  paths_released: ${{ steps.release.outputs.paths_released || '[]' }}
  tag_name: ${{ steps.release.outputs.tag_name }}
  version: ${{ steps.release.outputs.version }}

publish-ios-core:
  name: Mirror iOS core to split repo
  needs: release-please
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios') }}
```

Keep root/native behavior gated on `paths_released`, not aggregate `releases_created`.

**Pinned split and current mirror push target** (lines 398-433):

```yaml
- name: Install splitsh-lite v1.0.1
  run: |
    curl -fsSL https://github.com/splitsh/lite/releases/download/v1.0.1/lite_linux_amd64.tar.gz \
      | tar xz
    sudo mv splitsh-lite /usr/local/bin/splitsh-lite

- name: Split subtree
  run: |
    SHA=$(splitsh-lite --prefix=packages/crosswake-shell-core-ios)
    echo "SPLIT_SHA=$SHA" >> "$GITHUB_ENV"

- name: Push split to mirror and tag
  env:
    MIRROR_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}
    VERSION: ${{ needs.release-please.outputs.version }}
  run: |
    set -euo pipefail
    if [ -z "${MIRROR_TOKEN:-}" ]; then
      echo "[crosswake] FAIL: MIRROR_PUSH_TOKEN is not configured."
      echo "[crosswake] What to do next: create a fine-grained PAT or GitHub App token with Contents:write on szTheory/crosswake-shell-core-ios and store it as MIRROR_PUSH_TOKEN."
      exit 1
    fi
    git remote add mirror \
      "https://x-access-token:${MIRROR_TOKEN}@github.com/szTheory/crosswake-shell-core-ios.git"
    git ls-remote mirror HEAD >/dev/null
    if git ls-remote --exit-code mirror "refs/tags/v${VERSION}" >/dev/null 2>&1; then
      echo "[crosswake] iOS mirror tag v${VERSION} already exists; skipping mirror push."
      exit 0
    fi
    git push mirror "${SPLIT_SHA}:refs/heads/main"
    git push mirror "${SPLIT_SHA}:refs/tags/v${VERSION}"
```

Phase 145 should add the non-mutating write probe in this same step, after the read check/tag identity check and before the real pushes:

```bash
git push --dry-run --porcelain mirror \
  "${SPLIT_SHA}:refs/heads/main" \
  "${SPLIT_SHA}:refs/tags/v${VERSION}"
```

Also tighten the existing tag branch: exact SHA match is OK; mismatched tag must fail closed.

**Native proof DAG to preserve** (lines 464-519):

```yaml
clean-room-proof-ios:
  name: Clean-room proof - iOS swift build
  needs: [release-please, publish-hex, publish-ios-core]
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios') }}

clean-room-proof-android:
  name: Clean-room proof - Android gradle build
  needs: [release-please, publish-hex, publish-android-core]
  if: ${{ contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android') }}
```

Do not introduce sibling native dependencies. The iOS proof must not need `publish-android-core`; the Android proof must not need `publish-ios-core`.

**Dispatch secret preflight style** (lines 576-619):

```yaml
android-publish-fire-drill:
  name: Android publish fire-drill (validated-upload -> drop)
  if: ${{ github.event_name == 'workflow_dispatch' }}
  runs-on: ubuntu-latest
  steps:
    - name: Preflight - assert required secrets are set
      env:
        HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
        MIRROR_PUSH_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}
        RELEASE_PLEASE_TOKEN: ${{ secrets.RELEASE_PLEASE_TOKEN }}
      run: |
        set -euo pipefail
        for var in \
          HEX_API_KEY \
          MIRROR_PUSH_TOKEN \
          RELEASE_PLEASE_TOKEN; do
          if [ -z "${!var:-}" ]; then
            echo "MISSING SECRET: $var"
            exit 1
          fi
        done
```

Use this only as a shape reference. Phase 145 user-facing failure copy should use `[crosswake] FAIL` and name the mirror repo/required `Contents:write` permission.

---

### `.github/workflows/ios-mirror-backfill.yml` (optional config/workflow, workflow_dispatch + batch)

**Analog:** `.github/workflows/hex-publish.yml` for typed manual dispatch and exact-ref validation; `.github/workflows/native-collateral-advisory.yml` for summaries/artifacts.

**Typed manual dispatch inputs** (`.github/workflows/hex-publish.yml` lines 11-33):

```yaml
on:
  workflow_dispatch:
    inputs:
      package:
        description: 'Hex package to recover.'
        required: true
        type: choice
      ref:
        description: 'Exact recovery ref: full 40-character lowercase SHA or explicit refs/tags/vX.Y.Z tag ref.'
        required: true
        type: string
      release_version:
        description: 'Expected @version string in the selected package mix.exs at that ref.'
        required: true
        type: string
```

For iOS mirror backfill, copy this shape with inputs like `version`, `release_ref`, `apply`, and optional `update_main`. Keep mutation behind explicit input.

**Exact-ref rejection pattern** (`.github/workflows/hex-publish.yml` lines 42-72):

```yaml
- name: Validate recovery ref
  env:
    RECOVERY_REF: ${{ inputs.ref }}
  run: |
    set -euo pipefail

    FULL_SHA_PATTERN='^[0-9a-f]{40}$'
    RELEASE_TAG_PATTERN='^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'

    case "$RECOVERY_REF" in
      release/v0.2.0|feature/v0.2.0|v0.2.0|refs/heads/release/v0.2.0|refs/heads/*|heads/*|main|master)
        echo "[crosswake] FAIL: recovery ref '${RECOVERY_REF}' is branch-shaped, bare-version-shaped, or mutable."
        echo "[crosswake] What to do next: pass a full 40-character lowercase commit SHA or explicit refs/tags/vX.Y.Z release tag ref."
        exit 1
        ;;
    esac
```

Reuse this before checkout. For MIRR-03 the preferred default is `refs/tags/ios-core-v0.2.0`, not `main`, `HEAD`, or a bare `v0.2.0`.

**Thin workflow delegates to script** (`.github/workflows/hex-publish.yml` lines 114-123):

```yaml
- name: Guarded Hex recovery publish
  env:
    HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
  run: >
    bash script/guarded_hex_publish.sh
    "${{ inputs.package }}"
    "${{ inputs.release_version }}"
    "${{ inputs.ref }}"
```

The backfill workflow should delegate to `script/verify_ios_mirror_backfill.sh` and not duplicate split/ref/tag logic in YAML.

**Summary and artifact style** (`.github/workflows/native-collateral-advisory.yml` lines 32-50, 74-92):

```yaml
- name: Upload iOS simulator advisory evidence
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: crosswake-ios-simulator-advisory-evidence
    path: native-collateral/ios/
    if-no-files-found: error
    retention-days: 14
- name: Step summary
  if: always()
  run: |
    {
      echo "## iOS simulator advisory evidence"
      echo ""
      echo "Artifact: crosswake-ios-simulator-advisory-evidence, retained for 14 days."
    } >> "$GITHUB_STEP_SUMMARY"
```

For Phase 145, use the same `if: always()` summary discipline but summarize release state: version, release ref, split SHA, mirror tag state, apply/verify mode, and next safe action.

---

### `script/check_release_workflow_integrity.exs` (utility/static scanner, file-I/O + transform)

**Analog:** `script/check_release_workflow_integrity.exs`

**Default path and env-override pattern** (lines 3-20, 22-40):

```elixir
defmodule Crosswake.ReleaseWorkflowIntegrity do
  @default_workflow ".github/workflows/release-please.yml"
  @default_recovery_workflow ".github/workflows/hex-publish.yml"
  @default_helper "script/guarded_hex_publish.sh"
  @default_cleanroom_script "script/verify_companion_cleanroom.sh"
  @default_doctor_task "lib/mix/tasks/crosswake.doctor.ex"

  def run(argv \\ System.argv(), env_path \\ System.get_env("RELEASE_WORKFLOW_PATH")) do
    workflow_path = workflow_path(argv, env_path)
    workflow = File.read!(workflow_path)
    non_comment_workflow = strip_full_line_comments(workflow)
    jobs = job_blocks(workflow)

    recovery_workflow =
      File.read!(path_from_env("HEX_PUBLISH_WORKFLOW_PATH", @default_recovery_workflow))

    helper = File.read!(path_from_env("GUARDED_HEX_PUBLISH_PATH", @default_helper))
```

Add default paths/env overrides for the new backfill script and optional backfill workflow so ExUnit can pass adversarial fixtures without editing real files.

**Checks list insertion pattern** (lines 54-104):

```elixir
checks =
  [
    concurrency_not_cancelled(non_comment_workflow),
    paths_released(non_comment_workflow),
    path_gate(jobs, "release.ios.path_gate", "publish-ios-core", "packages/crosswake-shell-core-ios"),
    workflow_native_proof_decoupled(jobs),
    workflow_mirror_token_preflight(jobs),
    cleanroom_hex_metadata_floor(non_comment_cleanroom_script),
    workflow_doctor_proof_unmasked(non_comment_doctor_task, non_comment_cleanroom_script),
    version_graph_lockstep_core_native_only(release_config)
  ] ++ component_gates(jobs) ++ component_proof_gates(jobs)
```

Add Phase 145 stable IDs here, not as ad hoc tests only:

- `release.mirror_token.write_preflight`
- `release.ios_backfill.verify_first`
- `release.ios_backfill.exact_release_ref`
- `release.ios_backfill.tag_idempotent`
- `release.ios_backfill.no_default_main_force`
- `release.workflow.native_rollup_summary`
- `release.workflow.native_status_artifact`

**Check helper and output contract** (lines 196-200, 108-111):

```elixir
defp check(id, true, detail), do: {:ok, id, detail}
defp check(id, false, detail), do: {:error, id, detail}

for {status, id, detail} <- checks do
  prefix = if status == :ok, do: "OK", else: "FAIL"
  IO.puts("[crosswake] #{prefix}: #{id} - #{detail}")
end
```

New checks should use this tuple contract so the proof test can assert stable `[crosswake] OK/FAIL: <id>` strings.

**Native proof decoupling scanner** (lines 684-732):

```elixir
defp workflow_native_proof_decoupled(jobs) do
  ios_ok? =
    job_needs?(jobs, "clean-room-proof-ios", "release-please") and
      job_needs?(jobs, "clean-room-proof-ios", "publish-hex") and
      job_needs?(jobs, "clean-room-proof-ios", "publish-ios-core") and
      not job_needs?(jobs, "clean-room-proof-ios", "publish-android-core")

  android_ok? =
    job_needs?(jobs, "clean-room-proof-android", "release-please") and
      job_needs?(jobs, "clean-room-proof-android", "publish-hex") and
      job_needs?(jobs, "clean-room-proof-android", "publish-android-core") and
      not job_needs?(jobs, "clean-room-proof-android", "publish-ios-core")

  check(
    "release.workflow.native_proof_decoupled",
    ios_ok? and android_ok?,
    "native clean-room proofs in .github/workflows/release-please.yml must depend only on their own native publish job plus root Hex publish; rerun elixir script/check_release_workflow_integrity.exs"
  )
end
```

Extend this style for Phase 145 negative cases: iOS needing Android publish and Android needing iOS publish.

**Mirror preflight scanner to extend** (lines 734-754):

```elixir
defp workflow_mirror_token_preflight(jobs) do
  block = job_block(jobs, "publish-ios-core")

  check(
    "release.workflow.mirror_token_preflight",
    includes?(block, "MIRROR_PUSH_TOKEN is not configured") and
      includes?(block, "git ls-remote mirror HEAD"),
    "publish-ios-core in .github/workflows/release-please.yml must fail fast on missing or unusable MIRROR_PUSH_TOKEN; rerun elixir script/check_release_workflow_integrity.exs"
  )
end
```

Add sibling `release.mirror_token.write_preflight` that requires `git push --dry-run --porcelain mirror`, `${SPLIT_SHA}:refs/heads/main`, and `${SPLIT_SHA}:refs/tags/v${VERSION}`.

---

### `test/crosswake/proof/phase142_release_integrity_test.exs` (test, file-I/O + transform)

**Analog:** `test/crosswake/proof/phase142_release_integrity_test.exs`

**Module-level fixture paths and ID-list pattern** (lines 11-19, 21-56):

```elixir
use ExUnit.Case, async: true

@workflow ".github/workflows/release-please.yml"
@recovery_workflow ".github/workflows/hex-publish.yml"
@scanner "script/check_release_workflow_integrity.exs"
@cleanroom_script "script/verify_companion_cleanroom.sh"
@guarded_helper "script/guarded_hex_publish.sh"

@phase144_release_integrity_ids ~w(
  release.workflow.aggregate_gate.behavioral_jobs_absent
  release.workflow.proof_after_publish
  release.workflow.native_proof_decoupled
  release.workflow.mirror_token_preflight
)
```

Add `@phase145_mirror_ids`, `@phase145_native_rollup_ids`, and `@phase145_ios_backfill_ids` instead of scattering literals through many tests.

**Stable scanner ID pass assertion** (lines 68-76, 124-132):

```elixir
@tag :phase143_auto_publish
test "phase 143 guarded auto publish scanner ids pass" do
  {output, exit_code} = run_scanner(@workflow)

  assert exit_code == 0, output

  for check_id <- @phase143_ids do
    assert output =~ "[crosswake] OK: #{check_id}"
  end
end
```

Use the same pattern for `:phase145_mirror`, `:phase145_native_rollup`, and `:phase145_ios_backfill`.

**Negative fixture mutation pattern** (lines 194-223):

```elixir
@tag :phase144_release_integrity
test "phase 144 native proof cascade fails consolidated native id" do
  workflow =
    real_workflow()
    |> replace_in_job(
      "clean-room-proof-ios",
      "needs: [release-please, publish-hex, publish-ios-core]",
      "needs: [release-please, publish-hex, publish-ios-core, publish-android-core]"
    )

  assert_failure!("release.workflow.native_proof_decoupled", workflow)
end

@tag :phase144_release_integrity
test "phase 144 missing mirror token preflight fails consolidated mirror id" do
  workflow =
    real_workflow()
    |> replace_in_job("publish-ios-core", "MIRROR_PUSH_TOKEN is not configured", "mirror token absent")
    |> replace_in_job("publish-ios-core", "git ls-remote mirror HEAD >/dev/null", "echo mirror preflight skipped")

  assert_failure!("release.workflow.mirror_token_preflight", workflow)
end
```

Copy this adversarial style for read-only-only token checks, sibling proof dependencies, and false native-complete rollup copy.

**Fixture env override helpers** (lines 716-786):

```elixir
defp assert_failure_with_fixtures!(check_id, fixtures) do
  {output, exit_code} = run_fixture_set(fixtures)

  assert exit_code == 1, output
  assert output =~ "[crosswake] FAIL: #{check_id}"
end

defp run_fixture_set(fixtures) do
  env =
    fixtures
    |> Enum.map(fn {name, contents} ->
      path =
        Path.join(
          System.tmp_dir!(),
          "crosswake-phase143-#{name}-#{System.unique_integer([:positive])}"
        )

      File.write!(path, contents)
      on_exit(fn -> File.rm(path) end)

      {fixture_env_name(name), path}
    end)

  run_scanner(@workflow, env)
end

defp fixture_env_name(:recovery_workflow), do: "HEX_PUBLISH_WORKFLOW_PATH"
defp fixture_env_name(:helper), do: "GUARDED_HEX_PUBLISH_PATH"
defp fixture_env_name(:release_config), do: "RELEASE_PLEASE_CONFIG_PATH"
defp fixture_env_name(:cleanroom_script), do: "CLEANROOM_SCRIPT_PATH"
defp fixture_env_name(:doctor_task), do: "DOCTOR_TASK_PATH"
```

Add fixture env names for the backfill script and optional backfill workflow. Keep fixture writes in test temp paths only.

---

### `script/verify_ios_mirror_backfill.sh` (utility/script, batch + file-I/O + request-response)

**Analog:** `script/guarded_hex_publish.sh` for strict shell, logging, fail-closed registry identity, and Python JSON parsing; `script/verify_generated_ios_shell.sh` for SwiftPM mirror/tag resolution lessons.

**Strict shell, repo-root, log/fail copy** (`script/guarded_hex_publish.sh` lines 13-61):

```bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
CHECKED_SHA=$(git -C "$REPO_ROOT" rev-parse HEAD)

log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  local next_action="${2:-Stop and inspect the package, version, release ref, and registry state before retrying.}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit 1
}
```

Use this for every operator-facing branch. Do not echo token values.

**Exact registry identity parsing style** (`script/guarded_hex_publish.sh` lines 137-165, 259-283):

```bash
hex_release_state() {
  local body_file="$1"
  local code_file="$2"
  local url="https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}"

  code=$(curl -sS -o "$body_file" -w "%{http_code}" "$url" || true)
  printf "%s" "$code" > "$code_file"
}

live_release_version() {
  local body_file="$1"

  python3 - "$body_file" <<'PYEOF'
import json
import sys

try:
    with open(sys.argv[1], "r", encoding="utf-8") as handle:
        payload = json.load(handle)
except Exception:
    sys.exit(2)

version = payload.get("version")
if not isinstance(version, str):
    sys.exit(3)

print(version)
PYEOF
}

case "$code" in
  200)
    ok "${PACKAGE} ${VERSION} is already live on Hex.pm; no publish attempted. Continuing to proof."
    ;;
  404)
    ok "${PACKAGE} ${VERSION} is not live on Hex.pm yet; publish is required for this released package."
    ;;
  *)
    fail "Hex.pm release preflight returned HTTP ${code} for ${PACKAGE} ${VERSION}."
    ;;
esac
```

For backfill, adapt this to verify `crosswake` Hex `VERSION` and Maven Android `VERSION` before any mirror mutation. Exact live state is success; ambiguous registry identity fails closed.

**SwiftPM tag/mirror lessons** (`script/verify_generated_ios_shell.sh` lines 39-86):

```bash
# Hermetic release-PR resolution: the checked-in host pins the remote SwiftPM
# package at the CURRENT version, which isn't tagged on the remote mirror until the
# release PR merges. When CROSSWAKE_IOS_USE_LOCAL_CORE=1, redirect the remote URL to a
# locally-tagged clone of packages/crosswake-shell-core-ios via a SwiftPM mirror
if [[ "${CROSSWAKE_IOS_USE_LOCAL_CORE:-0}" == "1" ]]; then
  ios_core_remote="https://github.com/szTheory/crosswake-shell-core-ios.git"
  ios_core_version="$(sed -n 's/.*minimumVersion = \([0-9][0-9.]*\);.*/\1/p' "${project}/project.pbxproj" | head -1)"
  ios_core_clone="${RUNNER_TEMP:-${ROOT_DIR}/tmp}/crosswake-ios-core-hermetic"
  rm -rf "${ios_core_clone}"
  mkdir -p "${ios_core_clone}"
  cp -R "${ROOT_DIR}/packages/crosswake-shell-core-ios/." "${ios_core_clone}/"
  git -C "${ios_core_clone}" -c init.defaultBranch=main init -q
  git -C "${ios_core_clone}" tag -f "${ios_core_version}"
  git -C "${ios_core_clone}" tag -f "v${ios_core_version}"
  git config --global "url.${ios_core_clone}.insteadOf" "${ios_core_remote}"
fi
```

The production backfill must use the real split SHA, not this local mirror workaround, but the lesson is important: SwiftPM release identity is the semver Git tag.

**Mirror split and push ref pattern to reuse** (`.github/workflows/release-please.yml` lines 398-433):

```bash
SHA=$(splitsh-lite --prefix=packages/crosswake-shell-core-ios)
echo "SPLIT_SHA=$SHA" >> "$GITHUB_ENV"

git remote add mirror \
  "https://x-access-token:${MIRROR_TOKEN}@github.com/szTheory/crosswake-shell-core-ios.git"
git ls-remote mirror HEAD >/dev/null
git push mirror "${SPLIT_SHA}:refs/heads/main"
git push mirror "${SPLIT_SHA}:refs/tags/v${VERSION}"
```

Backfill should compute the split at `refs/tags/ios-core-v0.2.0`, verify `refs/tags/hex-v0.2.0`, `refs/tags/ios-core-v0.2.0`, and `refs/tags/android-core-v0.2.0` share the same release commit, then create/verify `refs/tags/v0.2.0` on the mirror. Tag-only is the default; `main` update should require an explicit flag.

---

### `docs/COMPANION-PUBLISH-RUNBOOK.md` (docs/runbook, transform)

**Analog:** `docs/COMPANION-PUBLISH-RUNBOOK.md`

**Operating model and exact already-live copy** (lines 3-31, 34-55):

```markdown
This runbook describes the current package-family release operating model for
Crosswake Hex packages. The publish path is now guarded CI automation, not a
maintainer's local `mix hex.publish` loop.

For Hex packages, the release workflow routes root `crosswake` and all five
`crosswake_*` companions through `script/guarded_hex_publish.sh`.

- Exact package/version is already live: report success, skip publish, and let
  proof continue.
- Exact package/version is not live: run deps, compile, tests, dry-run, publish,
  and poll until Hex.pm reports the exact version.
```

Mirror backfill copy should mirror this state vocabulary: exact tag already present is OK; absent tag in verify-only is OK with next action; mismatch is FAIL.

**Manual recovery boundary pattern** (lines 57-76):

```markdown
Manual dispatch is exact-ref Hex recovery and fire-drill only. It is not the
happy path and should not be used when the Release Please publish train is
healthy.

The workflow rejects branch-shaped and bare version-looking refs before
checkout, including `release/v0.2.0`, `feature/v0.2.0`,
`refs/heads/release/v0.2.0`, bare `v0.2.0`, `main`, and `master`.

Recovery remains Hex-only in Phase 143. SwiftPM mirror recovery, Maven Central
recovery, and the missing iOS `v0.2.0` mirror backfill belong to Phase 145.
```

Update this section with the canonical iOS mirror backfill command/workflow. Do not make "rerun Release Please" the primary recovery path.

**Phase boundary pattern** (lines 103-116):

```markdown
Phase 143 owns the guarded automatic Hex publish train and exact-ref Hex
recovery.

Phase 144 owns clean-room exactness completion: exact just-published companion
installs, derived core floors, and fresh-router doctor loading.

Phase 145 owns native registry recovery and parity: SwiftPM mirror credential
preflight, Maven/SwiftPM recovery semantics, native proof decoupling, and iOS
mirror backfill.

Phase 146 owns full release-status DX: local text output, JSON output, optional
live registry probes, and any issue-opening automation.
```

Keep Phase 145 docs limited to native parity/backfill and Phase 146 docs limited to release-status DX.

---

### `guides/support_matrix.md` (docs/support truth, transform)

**Analog:** `guides/support_matrix.md`

**Support-label vocabulary** (lines 12-28):

```markdown
| Label | What it proves | What it does not prove |
|-------|----------------|------------------------|
| merge-blocking proof | Required deterministic proof that must pass before the claim can merge. | It does not prove every platform/device path or any unsupported owner class. |
| advisory evidence | Useful evidence that informs confidence but does not block standard merge flow. | It does not widen support truth by itself. |
| checked-in public-coordinate proof | A checked-in host path resolves published SwiftPM/Maven coordinates by default. | It is not a device, simulator, or emulator support claim and it does not cover `--local`. |
| generated public-coordinate proof | A generated adopter-facing path resolves published SwiftPM/Maven/Hex coordinates. | It does not prove checked-in local hosts use those coordinates. |
| verification-required | A claim needs an explicit verification lane before it can be treated as supported. | It is not a failure-open support claim. |
```

Use these labels literally for the mirror parity note. Do not claim device/emulator proof from a SwiftPM tag backfill.

**Native shell rows to update carefully** (lines 65-70):

```markdown
| ios_shell | Hex-matched | supported | verification required | clean-room-proof-ios; script/verify_generated_ios_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Default non-local scaffolds resolve `https://github.com/szTheory/crosswake-shell-core-ios.git` via SwiftPM at the Crosswake package version; release-time clean-room proof confirms external resolution and `swift build`. advisory - not wired as a required CI lane; macOS/Xcode toolchain not guaranteed in CI. |
| android_shell | Hex-matched | supported | supported | native-behavioral-proof-gate / android-generated-shell-unit; script/verify_generated_android_shell.sh | [View Boundaries](native_shell.md#boundary-warnings--rough-edges) | Generated Android shell artifacts are supported based strictly on `JVM hermetic proof` via the merge-blocking android-generated-shell-unit CI lane (native-behavioral-proof-gate). JVM hermetic proof is not emulator evidence or physical-device proof. |
```

If Phase 145 changes proof/reporting truth, update these rows only with what is proven: mirror tag presence/backfill path and independent native proof reporting.

**Release/version policy pattern** (lines 113-122):

```markdown
| Target | Versioning | Compatibility Contract | Release Rule |
|--------|------------|------------------------|--------------|
| core | Independent SemVer for the `crosswake` Hex package. | package versions alone do not define support truth; manifest_schema_version, bridge_protocol_version, and native_runtime_version stay canonical. | Manifest-major, bridge-major, and runtime-line changes must update support docs and doctor before release. |
| ios_shell | SwiftPM core package version is lockstep with the Hex package; host app build numbers remain adopter-owned. | Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens. | Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required. |
| android_shell | Maven Central core artifact version is lockstep with the Hex package; host app build numbers remain adopter-owned. | Breaking bridge semantics require a bridge_protocol_version major bump plus a compatible shell artifact before support widens. | Changes touching native code, entitlements, permissions, registration, or packaged runtime behavior move the native_runtime_version line and mark rebuild required. |
```

Phase 145 should reinforce that core/native lockstep is root Hex + SwiftPM + Maven, while companions remain independent.

---

### `guides/companion_compatibility.md` (docs/compatibility truth, transform)

**Analog:** `guides/companion_compatibility.md`

**Source-derived truth contract** (lines 13-21):

```markdown
The `Requires crosswake` cell below is the verbatim Hex requirement extracted from
each package's `mix.exs`; a merge-blocking drift test
(`test/crosswake/proof/phase132_compat_matrix_drift_test.exs`) fails the build if a
cell drifts from the package source in either direction.

<!-- Current Version: do not hand-edit; keep this aligned with package mix.exs / release manifest.
     Use mix crosswake.release.status --live for public registry presence. -->
```

Keep compatibility floors separate from live registry status. Do not use the iOS mirror backfill to normalize companion floors or current versions.

**Release integrity boundary language** (lines 66-74):

```markdown
## Release Integrity Boundaries

Phase 143 keeps the release train honest without changing these compatibility
floors: Release Please Release PR merge is the human approval boundary, CI owns
happy-path Hex publishing, and manual dispatch is exact-ref Hex recovery only.
Phase 144 owns clean-room exactness completion, Phase 145 owns SwiftPM/Maven
recovery and iOS mirror backfill, and Phase 146 owns full text/JSON release
status DX. This guide remains the floor contract; live registry presence is a
status concern, not a reason to normalize older-compatible companion floors.
```

If touched, preserve this phase boundary and status-vs-compatibility distinction.

## Shared Patterns

### Authentication / Authorization

No application auth pattern applies. Phase 145 credential handling is CI secret handling:

- `MIRROR_PUSH_TOKEN` must come from GitHub Actions secrets.
- Logs must never print token values.
- Write authority must be proven through `git push --dry-run --porcelain` before mutation.
- Failure copy should name `szTheory/crosswake-shell-core-ios`, `refs/tags/v${VERSION}`, and required `Contents:write`.

### Error Handling And Operator Copy

**Source:** `script/guarded_hex_publish.sh` lines 29-61.

Apply to workflow shell and backfill script:

```bash
ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  local next_action="${2:-Stop and inspect the package, version, release ref, and registry state before retrying.}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit 1
}
```

### Exact Ref Validation

**Source:** `.github/workflows/hex-publish.yml` lines 48-72.

Apply to the backfill workflow and script:

```bash
FULL_SHA_PATTERN='^[0-9a-f]{40}$'
RELEASE_TAG_PATTERN='^refs/tags/v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$'

case "$RECOVERY_REF" in
  release/v0.2.0|feature/v0.2.0|v0.2.0|refs/heads/release/v0.2.0|refs/heads/*|heads/*|main|master)
    echo "[crosswake] FAIL: recovery ref '${RECOVERY_REF}' is branch-shaped, bare-version-shaped, or mutable."
    exit 1
    ;;
esac
```

### Registry Idempotency

**Source:** `script/guarded_hex_publish.sh` lines 259-279.

Apply to mirror tag checks:

- Exact live artifact/tag points to expected identity: OK, no mutation.
- Missing artifact/tag in verify-only mode: OK with next safe apply command.
- Missing artifact/tag in apply mode: perform the one intended mutation.
- Existing artifact/tag mismatch: FAIL, no delete, no force move.

### Native Rollup Reporting

**Sources:** `.github/workflows/native-collateral-advisory.yml` lines 32-50 and `.github/workflows/offline-sync-e2e-gate.yml` lines 211-232.

Apply to the new native release rollup:

- `if: always()`.
- Read `needs.publish-ios-core.result`, `needs.clean-room-proof-ios.result`, `needs.publish-android-core.result`, and `needs.clean-room-proof-android.result`.
- Write a concise `$GITHUB_STEP_SUMMARY`.
- Upload a narrow `native-release-status.json` artifact.
- Report `native_core=partial` when one platform is missing/failed and the other is proven.

### Scanner / Test Coupling

**Sources:** `script/check_release_workflow_integrity.exs` lines 196-200 and `test/crosswake/proof/phase142_release_integrity_test.exs` lines 716-786.

Every new invariant should have:

- One stable scanner ID.
- One positive ID-list assertion.
- At least one negative fixture that mutates real workflow/script text.
- Env-overridable fixture path when the scanner reads a non-workflow file.

## No Analog Found

None. The dedicated iOS mirror backfill script has no exact existing file, but it has strong role-match analogs in `script/guarded_hex_publish.sh`, `.github/workflows/hex-publish.yml`, and `script/verify_generated_ios_shell.sh`.

## Metadata

**Analog search scope:** `.github/workflows`, `script`, `test/crosswake/proof`, `docs`, `guides`, prior phase pattern map for output shape only.
**Files scanned:** 136
**Pattern extraction date:** 2026-07-08

