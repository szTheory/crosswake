# Phase 153: iOS Mirror Unblock - Pattern Map

**Mapped:** 2026-07-12
**Files analyzed:** 8 (3 new, 5 modified)
**Analogs found:** 8 / 8 — this phase is release-infra-only; every "new" file has a near-exact structural analog already in the repo. No product code, no UI.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `script/check_ios_mirror_parity.sh` | script (merge-blocking check) | request-response (one `git ls-remote`, diff, exit code) | `script/verify_ios_mirror_backfill.sh` (bash style) + the invariant shape of `script/check_release_as_staleness.sh` (referenced by the D-16 precedent workflow) | exact (style) / role-match (invariant shape — not read directly, but its caller contract is fully specified below) |
| `.github/workflows/merge-blocking-ios-mirror-parity.yml` | workflow (required check) | request-response (thin YAML → shell out) | `.github/workflows/release-as-staleness-gate.yml` (`merge-blocking-release-as-staleness` job) | exact |
| `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` | test | CRUD (bare-repo git fixtures) + structural text-assertion | `test/crosswake/proof/phase145_ios_backfill_script_test.exs` (git fixture harness) + `test/crosswake/proof/phase142_release_integrity_test.exs` (decoy/id-list house style) | exact |
| `.github/workflows/release-please.yml` (`publish-ios-core`, `native-release-rollup`, `release-failure-alert`, `android-publish-fire-drill`) | workflow job (release pipeline) | event-driven (release-please output triggers publish) | itself — modify in place | exact (editing, not analogizing) |
| `.github/workflows/ios-mirror-backfill.yml` | workflow (workflow_dispatch recovery lane) | request-response (manual dispatch) | itself — modify in place | exact |
| `script/verify_ios_mirror_backfill.sh` | script | file-I/O + git transport | itself — modify in place | exact |
| `script/check_release_workflow_integrity.exs` | script (structural scanner) | batch (static text assertions over workflow/script source) | itself — modify in place; new checks follow the `defp <name>(jobs)` → `check(id, condition, message)` shape used throughout | exact |
| `lib/crosswake/release_status.ex` | module (release-truth CLI backend) | transform (aggregate probe results → status) | itself — modify in place | exact |

## Pattern Assignments

### `script/check_ios_mirror_parity.sh` (NEW)

**Analog:** `script/verify_ios_mirror_backfill.sh` (house bash style) — read in full, 253 lines.

**House conventions to copy verbatim:**

```bash
set -euo pipefail

log() {
  echo "[crosswake] $*"
}

ok() {
  echo "[crosswake] OK: $*"
}

fail() {
  local message="$1"
  local next_action="${2:-Inspect the version, release ref, mirror tag, and registry state before retrying.}"

  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit 1
}
```
This is the exact `[crosswake] OK|FAIL: <detail>` shape `lib/crosswake/release_status.ex:676`'s parser regex expects (`~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/` — note the parser wants an `<id> - <detail>` shape with a literal ` - ` separator; `ok()`/`fail()` above do NOT include an id token, so a script wanting to be machine-consumable by `release_status.ex` must emit `"release.ios_mirror_parity - <detail>"` as the first argument, e.g. `fail "release.ios_mirror_parity - SwiftPM mirror is missing refs/tags/v0.2.0."`).

**Public, no-credential remote read** (`lib/crosswake/release_status.ex:817-838`, `git_ref_live_probe/2` — same primitive, generalized to "all tags"):
```elixir
System.cmd(git, ["-c", "core.askPass=", "ls-remote", "--tags", remote_url, ref],
  env: [{"GIT_TERMINAL_PROMPT", "0"}],
  stderr_to_stdout: true
)
```
Bash equivalent for the new script (per RESEARCH Q5, live-verified):
```bash
git -c core.askPass= ls-remote --tags "https://github.com/szTheory/crosswake-shell-core-ios" \
  | awk '{print $2}' | sed -n 's#^refs/tags/v##p'
```
Tab-separated `<sha>\trefs/tags/<name>` lines, no auth prompt, exit 0.

**Env-var override seam to add** (so the phase153 test can inject a fake mirror, matching the `CROSSWAKE_IOS_BACKFILL_*` pattern at `verify_ios_mirror_backfill.sh:22-26`):
```bash
MIRROR_REPO="szTheory/crosswake-shell-core-ios"
DEFAULT_MIRROR_REMOTE="https://github.com/${MIRROR_REPO}.git"
MIRROR_REMOTE="${CROSSWAKE_IOS_PARITY_MIRROR_REMOTE:-$DEFAULT_MIRROR_REMOTE}"
RELEASE_REPO="${CROSSWAKE_IOS_PARITY_RELEASE_REPO:-$REPO_ROOT}"
```

**Retry loop (D-16 "3 retries for network flake")** — no existing bash retry precedent in this repo (the closest is the `for i in 1 2 3; do ... sleep 30; done` pattern in `release-please.yml`'s `clean-room-proof-ios` swift-build retry, lines 520-528). Adapt that shape:
```bash
for attempt in 1 2 3; do
  if tags_output="$(git -c core.askPass= ls-remote --tags "$MIRROR_REMOTE" 2>&1)"; then
    break
  fi
  if [ "$attempt" -eq 3 ]; then
    fail "release.ios_mirror_parity - could not reach SwiftPM mirror after 3 attempts: ${tags_output}" \
      "Check network access to github.com; re-run this check."
  fi
  sleep 2
done
```

**Invariant to implement** (per D-16, tag-existence only, no `--deep` in v1): every local `ios-core-vX` tag ⇒ mirror has `vX`.
```bash
local_versions="$(git -C "$RELEASE_REPO" tag --list 'ios-core-v*' | sed -n 's#^ios-core-v##p' | sort -u)"
mirror_versions="$(printf '%s\n' "$tags_output" | sed -n 's#^.*\trefs/tags/v##p' | sort -u)"
missing="$(comm -23 <(printf '%s\n' "$local_versions") <(printf '%s\n' "$mirror_versions"))"
if [ -n "$missing" ]; then
  fail "release.ios_mirror_parity - SwiftPM mirror is missing $(printf '%s' "$missing" | wc -l) tag(s): $(printf '%s ' $missing)" \
    "gh workflow run ios-mirror-backfill.yml -f version=<X> -f release_ref=refs/tags/ios-core-v<X> -f apply=true"
fi
```

**Exact D-19 target failure message shape** (copy verbatim as the multi-line detail):
```
[crosswake] FAIL: release.ios_mirror_parity - SwiftPM mirror is missing refs/tags/v0.2.0.
[crosswake]   released here:  refs/tags/ios-core-v0.2.0
[crosswake]   mirror state:   szTheory/crosswake-shell-core-ios has no refs/tags/v0.2.0
[crosswake]   adopter impact: .package(url: "…/crosswake-shell-core-ios", from: "0.2.0")
[crosswake]                   CANNOT RESOLVE. Every iOS adopter of 0.2.0 is broken right now.
[crosswake] What to do next:
[crosswake]   gh workflow run ios-mirror-backfill.yml -f version=0.2.0 \
[crosswake]     -f release_ref=refs/tags/ios-core-v0.2.0 -f apply=true
[crosswake] This gate stays RED and merges stay BLOCKED until the mirror tag exists.
```

---

### `.github/workflows/merge-blocking-ios-mirror-parity.yml` (NEW)

**Analog:** `.github/workflows/release-as-staleness-gate.yml` — read in full (57 lines), this is CONTEXT's own stated exact precedent.

**Copy this shape verbatim, substituting the script name:**
```yaml
name: iOS Mirror Parity Gate

concurrency:
  group: ${{ github.workflow }}-${{ github.head_ref || github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

on:
  push:
    branches:
      - '**'
  pull_request:
    branches:
      - main

jobs:
  merge-blocking-ios-mirror-parity:
    name: merge-blocking-ios-mirror-parity
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
        with:
          fetch-depth: 0
          fetch-tags: true
      - name: Check iOS SwiftPM mirror parity
        run: ./script/check_ios_mirror_parity.sh
      - name: Step summary
        if: always()
        run: |
          echo "iOS mirror parity gate: see job log for per-tag results" >> "$GITHUB_STEP_SUMMARY"
```

**⚠️ Naming contract (CRITICAL, verified against `script/list_merge_blocking_checks.py:48-75` in full):**
- Auto-discovery is a **case-insensitive substring match on `merge-blocking`** in the job's `name:` field (job id is the fallback if `name:` is absent) — `if "merge-blocking" in name.lower():` at line 70.
- The literal string printed becomes the required-check "context" registered by `register_required_checks.sh`.
- **Do not use an unresolved `${{ ... }}` expression in `name:`** — those are explicitly skipped (line 68: `if "${{" in name`).
- Use the job id `merge-blocking-ios-mirror-parity` for BOTH the YAML job key and the `name:` field, matching the existing precedent's `merge-blocking-release-as-staleness` (job id == name field, exactly).

**One deviation from the precedent, per RESEARCH Q5:** SHA-pin `actions/checkout` (the precedent's `@v7` tag-pin is a known minor inconsistency, not to be copied — this repo's dominant discipline is SHA+comment, see `release-please.yml:394` `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0`).

**Registration ritual (out-of-band, document but do not automate):**
```
DRY_RUN=0 script/register_required_checks.sh
```
only after the lane is observed green on `main` at least once (`register_required_checks.sh:23-27` green-first preflight, read in full — do not attempt to register in the same PR that creates the lane).

---

### `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs` (NEW)

**Analog A — bare-repo git fixture harness:** `test/crosswake/proof/phase145_ios_backfill_script_test.exs` — read in full (159 lines). **This is the ONLY existing test in the repo that creates temp git repos as fixtures.** Confirmed via file read; no other precedent exists, so this pattern must be extended/copied, not just referenced.

Exact reusable fixture skeleton:
```elixir
defp backfill_fixture do
  root = Path.join(System.tmp_dir!(), "crosswake-phase153-ios-mirror-#{System.unique_integer([:positive])}")
  release = Path.join(root, "release")
  mirror = Path.join(root, "mirror.git")
  File.mkdir_p!(release)
  File.mkdir_p!(mirror)
  on_exit(fn -> File.rm_rf(root) end)

  git!(["init", "-q", release])
  git!(["-C", release, "config", "user.email", "ci@crosswake"])
  git!(["-C", release, "config", "user.name", "Crosswake CI"])
  # ... commit + tag as needed ...
  git!(["init", "--bare", "-q", mirror])

  %{release: release, mirror: mirror, split_sha: split_sha}
end

defp git!(args) do
  {output, exit_code} = System.cmd("git", args, stderr_to_stdout: true)
  assert exit_code == 0, output
  output
end
```

Env-var injection for driving the script under test (`System.cmd("bash", [@script, ...], env: base_env)`), mirroring lines 117-132 of the analog.

**For D-08's off-lineage scenario specifically**, build a mirror `main` with **no common ancestor** to the release repo (two independent `git init` trees, as RESEARCH's own Q1 methodology did) — this is new fixture shape beyond what phase145 needs (phase145's mismatch test at lines 64-77 uses a *related* mismatch commit, not a wholly disjoint history). Needed scenarios per RESEARCH's Wave-0 gap list:
1. atomic+lease push with off-lineage `main` (disjoint history) → succeeds
2. atomic+lease push with a stale/wrong lease value → whole transaction fails, tag absent
3. attempt to move an existing tag inside the atomic push → rejected, tag unchanged (`refs/tags/*` structural protection — no app-logic assertion needed, just assert the push fails and the tag SHA is unchanged)

**Analog B — id-list / decoy house style:** `test/crosswake/proof/phase142_release_integrity_test.exs` — read lines 1-40 (module doc + `@phaseNNN_ids ~w(...)` pattern). Copy this shape for the new `@phase153_ids`:
```elixir
defmodule Crosswake.Proof.Phase153IosMirrorUnblockTest do
  @moduledoc """
  Merge-blocking proof for the iOS mirror transport fix and lease-safe atomic push (Phase 153).
  """
  use ExUnit.Case, async: true

  @scanner "script/check_release_workflow_integrity.exs"
  @workflow ".github/workflows/release-please.yml"
  @backfill_script "script/verify_ios_mirror_backfill.sh"
  @backfill_workflow ".github/workflows/ios-mirror-backfill.yml"
  @parity_script "script/check_ios_mirror_parity.sh"

  @phase153_ids ~w(
    release.ios.checkout_ref_pinned
    release.ios.persist_credentials_false
    release.mirror_deploy_key.preflight
    release.ios_mirror_parity
  )
  # ... decoy tests asserting these ids appear with :ok status, per phase142's established pattern
end
```

**Test tag** to register (per RESEARCH's Validation Architecture table): `@tag :phase153_ios_mirror_unblock`, runnable via `mix test --only phase153_ios_mirror_unblock`.

---

### `.github/workflows/release-please.yml` — MODIFY, current-state excerpts

**`publish-ios-core` — current full block** (lines 386-450, read in full and reproduced above under "Existing Code Insights" already in RESEARCH; key touch points for the executor):
- Checkout (394-396): `actions/checkout@9c091bb...` with `fetch-depth: 0`, **no `ref:`** (D-11 bug) and **no `persist-credentials: false`** (D-04 gap).
- Credential block (411-450): `MIRROR_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}` env, `git remote add mirror "https://x-access-token:${MIRROR_TOKEN}@..."` at line 425, `git ls-remote mirror HEAD` public-repo read-check at 427, tag-SHA-equality short-circuit at 432-437, **two separate non-atomic pushes** at 449-450 (`git push mirror "${SPLIT_SHA}:refs/heads/main"` then `git push mirror "${SPLIT_SHA}:refs/tags/v${VERSION}"` — the exact partial-state bug D-13 fixes).
- `permissions: contents: read` (391-392) — D-14 says **do not touch this**.

**`native-release-rollup` — current full block** (lines 593-701): computes `native_core=partial|complete|none` (655-663), writes `native-release-status.json` (665-683), **`if: ${{ always() }}`** at 601, **exits 0 unconditionally** (no `exit 1` anywhere in this job — confirms D-17's gap). `next_action` string at 658 references `Fix MIRROR_PUSH_TOKEN` — **must be updated to `MIRROR_DEPLOY_KEY`** language when D-03 lands, and `check_release_workflow_integrity.exs:830` asserts this exact substring (`"Fix MIRROR_PUSH_TOKEN or run the iOS mirror backfill workflow."`) — that scanner assertion needs the matching edit.
Artifact upload step (695-701): `actions/upload-artifact@v4` (unpinned — tracked exception, do not SHA-pin per Deferred Ideas / `native_status_artifact` check at line 841 which asserts the literal string).

**`release-failure-alert` — current `needs:` list** (lines 1213-1234, read in full): 10 companion jobs only, `if: ${{ failure() }}`. D-15 requires adding the 4 native jobs (`publish-ios-core`, `clean-room-proof-ios`, `publish-android-core`, `clean-room-proof-android`) + `native-release-rollup` to this `needs:` array, and extending the "Job results" echo block (starts at line 1249, `${{ needs.publish-hex-rulestead.result }}` pattern) with matching `${{ needs.publish-ios-core.result }}` etc. lines.

**`android-publish-fire-drill` — 4th `MIRROR_PUSH_TOKEN` touch point (research finding, not in CONTEXT):**
```yaml
# lines 728, 739, 746
MIRROR_PUSH_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}
...
            MIRROR_PUSH_TOKEN \
...
          echo "All 8 required secrets are set."
```
This preflight loop (lines 730-746) has **nothing to do with iOS** — it is one of 8 secrets checked for presence only. Retiring `MIRROR_PUSH_TOKEN` without updating this list will make this unrelated fire-drill job fail with `MISSING SECRET: MIRROR_PUSH_TOKEN`. Replace with `MIRROR_DEPLOY_KEY` in the `env:` block, the `for var in ... ; do` list, and update the count string (`"All 8 required secrets are set."` stays 8, just a different name in the list).

---

### `.github/workflows/ios-mirror-backfill.yml` — MODIFY, current-state excerpt

Full file read (107 lines). The `workflow_dispatch` inputs block (lines 9-29: `version`, `release_ref`, `apply`, `update_main`, all with defaults) is unchanged by this phase. The checkout (69-71) needs the same `persist-credentials: false` addition as `publish-ios-core`. The credential env (81: `MIRROR_PUSH_TOKEN: ${{ secrets.MIRROR_PUSH_TOKEN }}`) needs the SSH-agent block substitution (see Shared Patterns below) replacing this HTTPS-token env entirely.

---

### `script/verify_ios_mirror_backfill.sh` — MODIFY, current-state excerpts

Full file read (252 lines — cited length off by one from CONTEXT's "253", confirmed 252 via direct read).

**`verify_or_apply_mirror()` (lines 204-245)** — the D-07 target: currently `if [ "$APPLY" -ne 1 ]` (line 222) returns immediately with `ok "... verification-only mode made no changes."` (line 223) **before** any push attempt. D-07 requires adding a `git push --dry-run --porcelain` probe inside this branch before the early return.

**`--update-main` path (lines 236-244)** — the exact block to fix per D-13/Q1 Finding 1 (the named-without-`:expect` bug):
```bash
if [ "$UPDATE_MAIN" -eq 1 ]; then
  current_main="$(git ls-remote "$push_remote" "refs/heads/main" | awk '{print $1}' | head -1 || true)"
  if [ -n "$current_main" ] && ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$current_main" "$SPLIT_SHA" 2>/dev/null; then
    fail "mirror main has commits not reachable from expected split SHA." "Do not realign main until mirror-only commit evidence is reviewed."
  fi

  git -C "$RELEASE_REPO" push --porcelain --force-with-lease=refs/heads/main "$push_remote" "${SPLIT_SHA}:refs/heads/main"
  ok "updated mirror main to ${SPLIT_SHA} with --force-with-lease."
fi
```
Per RESEARCH Q1/Q2 (empirically verified), replace with:
```bash
if [ "$UPDATE_MAIN" -eq 1 ]; then
  current_main="$(git ls-remote "$push_remote" "refs/heads/main" | awk '{print $1}' | head -1 || true)"
  if [ -n "$current_main" ]; then
    if ! git -C "$RELEASE_REPO" cat-file -e "${current_main}^{commit}" 2>/dev/null; then
      log "mirror main (${current_main}) is unknown locally — cannot prove ancestry; proceeding only because this is the approved one-time re-baseline."
    elif ! git -C "$RELEASE_REPO" merge-base --is-ancestor "$current_main" "$SPLIT_SHA" 2>/dev/null; then
      fail "mirror main has commits not reachable from expected split SHA (both objects are known locally)." "Do not realign main until mirror-only commit evidence is reviewed."
    fi
  fi

  git -C "$RELEASE_REPO" push --porcelain \
    --force-with-lease="refs/heads/main:${current_main}" \
    "$push_remote" "${SPLIT_SHA}:refs/heads/main"
  ok "updated mirror main to ${SPLIT_SHA} with --force-with-lease."
fi
```

**`mirror_push_remote()` (lines 192-198)** — currently builds the HTTPS token URL. Must be replaced with the SSH remote form once D-03/D-04 land; the `MIRROR_PUSH_TOKEN` env-based branch (line 193, `[ -n "${MIRROR_PUSH_TOKEN:-}" ]`) goes away entirely — the script should just use `$MIRROR_REMOTE` directly once it defaults to `git@github.com:szTheory/crosswake-shell-core-ios.git` and the SSH agent (loaded by the calling workflow) handles auth transparently.

---

### `script/check_release_workflow_integrity.exs` — MODIFY, current-state excerpts

Full run/orchestration read (lines 1-100) plus the checker function block (745-998, showing 745-864 above).

**Shape of a checker function** (copy this exact shape for every new check):
```elixir
defp <check_name>(jobs) do
  block = job_block(jobs, "<job-id>")

  check(
    "<dotted.check.id>",
    <boolean condition, usually includes?/2 substring assertions>,
    "<human message ending with 'run elixir script/check_release_workflow_integrity.exs'>"
  )
end
```
`check/3` (referenced but not shown above; used identically across every existing checker — 1-arg-status form defaults `:error` on false) is the universal wrapper; do not reinvent it.

**Checks that reference `MIRROR_PUSH_TOKEN` and need REWRITE, not rename** (flagged per phase-specific guidance):
- `mirror_token_preflight/1` (lines 775-784) — asserts `includes?(block, "MIRROR_PUSH_TOKEN is not configured")` and `includes?(block, "git ls-remote mirror HEAD")`. Both substrings disappear once the HTTPS-token preflight is replaced by SSH-agent wiring — this check's assertions must change to assert the new SSH-preflight shape (e.g. `persist-credentials: false`, `webfactory/ssh-agent`, `ssh-keyscan`), not just get a find/replace on the string `MIRROR_PUSH_TOKEN` → `MIRROR_DEPLOY_KEY`.
- `workflow_mirror_token_preflight/1` (lines 786-795) — identical duplicate assertion against the same block; same rewrite required.
- `mirror_token_write_preflight/1` (lines 797-807) — asserts the **two-command push shape** (`"${SPLIT_SHA}:refs/heads/main"` and `"${SPLIT_SHA}:refs/tags/v${VERSION}"` as **separate** refspecs in a dry-run). Once D-13 lands (single atomic push with both refspecs in one command), this assertion's shape must change to match the new one-line atomic form, not just the token name.

**New check needed per D-20/D-11:**
```elixir
defp release_ios_checkout_ref_pinned(jobs) do
  block = job_block(jobs, "publish-ios-core")

  check(
    "release.ios.checkout_ref_pinned",
    includes?(block, "ref: ${{ needs.release-please.outputs.tag_name }}") and
      includes?(block, "fetch-depth: 0"),
    "publish-ios-core must checkout at the release tag with full history, not the retroactive github.sha; run elixir script/check_release_workflow_integrity.exs"
  )
end
```

**`native_status_artifact/1` (lines 835-846)** — unaffected by this phase, but note the literal `actions/upload-artifact@v4` assertion (line 841) — do not accidentally SHA-pin that action as a "drive-by fix," it would break this check (confirmed in Deferred Ideas).

**All 4 code locations referencing `"MIRROR_PUSH_TOKEN"` string literal in this file** (per RESEARCH's Runtime State Inventory): lines 780, 782, 791, 793, 830, 852 — grep to confirm exact count before editing; RESEARCH's line numbers are pre-edit and will drift once earlier edits land, so **re-grep after every edit in this file**, don't trust cumulative line numbers across a multi-edit session.

---

### `lib/crosswake/release_status.ex` — MODIFY, current-state excerpts

All read directly, exact line matches confirmed (`maybe_ios_mirror_live/3` 772-787, `live_registry_checks/2` 462-491, `exit_code/1` 626-628, parser 676).

**`maybe_ios_mirror_live/3` (772-787)** — unchanged by this phase; it already emits the right `next_action` (`"run script/verify_ios_mirror_backfill.sh --version #{version} --ref refs/tags/ios-core-v#{version}"`) and calls `probes.git_ref` (the injection seam used by `crosswake_release_status_test.exs`'s `git_ref_probe:` fixture at line ~150 of that test).

**`live_registry_checks/2` (462-491) — THE function to change (D-18/Q6).** Current bug, exact code:
```elixir
missing = Enum.reject(entries, &(&1.live.status == :ok))   # lumps :missing AND :unavailable
...
status: if(missing == [], do: :ok, else: :warning),        # :warning, not :error
code: "release.live_registry_presence",                     # one code for both failure kinds
```
Replace with the RESEARCH-provided split (Filter on `:missing` vs `:unavailable` separately, two distinct `:error` codes: `release.live_registry_presence` for definite negatives, `release.live_registry_unverifiable` for probe failures after retry). Full replacement code is in RESEARCH.md's Q6 section — copy that verbatim; it is a complete, mechanically-derived function body.

**`exit_code/1` (626-628)** — **no change needed**: `def exit_code(:error), do: 1` already maps both new `:error` codes to exit 1 correctly, since both codes use `status: :error`.

**Parser regex, line 676** (in `check_release_workflow_integrity.exs`, not `release_status.ex` — CONTEXT's line citation for "the parser" at `release_status.ex:676` is off; the actual regex is at `check_release_workflow_integrity.exs`'s consumer, `parse_workflow_integrity_output/1`):
```elixir
~r/^\[crosswake\] (OK|FAIL): ([^\s]+) - (.*)$/
```
Any new script output intended to be consumed by this parser MUST emit `[crosswake] OK: <id> - <detail>` or `[crosswake] FAIL: <id> - <detail>` — note the required ` - ` separator and the `<id>` token with no whitespace, which is stricter than the bare `ok()`/`fail()` helpers in `verify_ios_mirror_backfill.sh` currently produce (those omit the id). New scripts (`check_ios_mirror_parity.sh`) should emit ids explicitly if they want this integration "for free," per D-19.

**Retry logic to add to `git_ref_live_probe/2` (817-838) and `http_live_probe/2`** — wrap the existing `System.cmd`/HTTP call in up to 3 attempts; only classify `:unavailable` after all 3 fail. No existing retry precedent in this file to copy from — the closest in-repo retry pattern is the bash `for i in 1 2 3; do ... sleep 30; done` shape in `release-please.yml`'s `clean-room-proof-ios` step (lines 520-528); translate to Elixir as a simple recursive/loop helper, no library needed (per RESEARCH's Don't-Hand-Roll table — a generic retry library would be overkill for "try 3 times").

**Existing test file located and confirmed:** `test/mix/tasks/crosswake_release_status_test.exs` (NOT `test/crosswake/release_status_test.exs` as RESEARCH guessed — path corrected here). Its `probes`-map injection seam, confirmed by direct read (lines ~150-183):
```elixir
status =
  Crosswake.ReleaseStatus.build(
    live?: true,
    http_probe: fn _url, context ->
      case context do
        %{kind: :hex, package: "crosswake"} -> %{status: :ok, evidence: ["hex fixture"]}
        %{kind: :maven} -> %{status: :missing, evidence: ["maven fixture"]}
        %{kind: :hex} -> %{status: :unavailable, evidence: ["hex unavailable fixture"]}
      end
    end,
    git_ref_probe: fn _remote, _ref -> %{status: :missing, evidence: ["ios fixture"]} end
  )
```
This is a full, complete existing test already covering `:missing` and `:unavailable` distinctly per-source (test name: `"live probes distinguish ok, missing, and unavailable as advisory warnings"`). It currently asserts `status.status == :warning` (line ~164) — **this assertion must flip to `:error`** once D-18 lands, and the check-lookup line `check!(status, "release.live_registry_presence")` needs a companion assertion for the new `release.live_registry_unverifiable` code (currently only one code exists in this test). Extend this test file in place; do not create a new one for this module.

---

## Shared Patterns

### Bash script house style (`[crosswake]` prefix, `ok`/`fail`/`log` helpers, `set -euo pipefail`)
**Source:** `script/verify_ios_mirror_backfill.sh:1-51`
**Apply to:** `script/check_ios_mirror_parity.sh` (new)
```bash
set -euo pipefail
log() { echo "[crosswake] $*"; }
ok() { echo "[crosswake] OK: $*"; }
fail() {
  local message="$1"
  local next_action="${2:-...}"
  echo "[crosswake] FAIL: ${message}"
  log "What to do next: ${next_action}"
  exit 1
}
```

### SSH transport block for cross-repo push (NEW pattern — no existing precedent in this repo; entirely from RESEARCH's Q3, empirically/API-verified)
**Source:** RESEARCH.md Q3, "Exact replacement for the current HTTPS remote"
**Apply to:** `publish-ios-core` checkout in `release-please.yml`, AND `ios-mirror-backfill.yml`'s checkout (D-04's "both" requirement)
```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
  with:
    fetch-depth: 0
    persist-credentials: false   # D-04

- uses: webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 # v0.10.0
  with:
    ssh-private-key: ${{ secrets.MIRROR_DEPLOY_KEY }}

- name: Add GitHub to known_hosts
  run: |
    mkdir -p ~/.ssh
    ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
```
Then: `git remote add mirror git@github.com:szTheory/crosswake-shell-core-ios.git`

### Atomic + explicit-lease push (NEW pattern — the D-13/Q1 empirically-verified form; the ONLY form that works in this CI shape)
**Source:** RESEARCH.md Q1 "Definitive recommendation for D-13"
**Apply to:** `publish-ios-core`'s push step in `release-please.yml`, AND `verify_ios_mirror_backfill.sh`'s `--update-main` path
```bash
CURRENT_MAIN_SHA="$(git ls-remote "$push_remote" refs/heads/main | awk '{print $1}' | head -1)"
if [ -n "$CURRENT_MAIN_SHA" ]; then
  git push --atomic "$push_remote" \
    --force-with-lease="refs/heads/main:${CURRENT_MAIN_SHA}" \
    "${SPLIT_SHA}:refs/heads/main" \
    "${SPLIT_SHA}:refs/tags/v${VERSION}"
else
  git push --atomic "$push_remote" \
    "${SPLIT_SHA}:refs/heads/main" \
    "${SPLIT_SHA}:refs/tags/v${VERSION}"
fi
```
**Never** use bare `--force-with-lease` or `--force-with-lease=refs/heads/main` (no `:expect`) in this repo's CI shape — both fail 100% of the time here (no `git fetch` ever runs, so no remote-tracking ref exists to compare against). Always read the expected SHA explicitly via `git ls-remote` first.

### `[crosswake] OK|FAIL: <id> - <detail>` machine-parseable failure format
**Source:** `check_release_workflow_integrity.exs`'s `parse_workflow_integrity_output/1` regex, consumed by `lib/crosswake/release_status.ex`
**Apply to:** Any new script output intended to feed `mix crosswake.release.status`
```
[crosswake] FAIL: <dotted.id> - <one-line detail>
```
(Note: `verify_ios_mirror_backfill.sh`'s own `ok()`/`fail()` helpers do NOT include this id token today — they predate this consumer contract. New scripts should include it if machine-consumability matters; existing scripts are not required to retrofit it as part of this phase unless a specific decision calls for it.)

### Structural checker function shape (`check_release_workflow_integrity.exs`)
**Source:** every `defp <name>(jobs)` function in the file, e.g. `workflow_native_proof_decoupled/1` (lines 751-773)
**Apply to:** every new invariant this phase adds (`release.ios.checkout_ref_pinned`, the SSH-preflight rewrites, the atomic-push assertion rewrite)
```elixir
defp <name>(jobs) do
  block = job_block(jobs, "<job-id>")
  check(
    "<dotted.id>",
    <boolean condition>,
    "<message ending with 'run elixir script/check_release_workflow_integrity.exs'>"
  )
end
```
Extend `test/crosswake/proof/phase142_release_integrity_test.exs`'s `@phaseNNN_ids ~w(...)` + decoy-test pattern for any new ids added here, per D-20's explicit instruction — OR put them in the new `phase153_ios_mirror_unblock_test.exs` file with the same `@phase153_ids` shape (Claude's discretion per CONTEXT's "number of plans/split").

### Merge-blocking gate topology ("thin YAML delegating to a script")
**Source:** `.github/workflows/release-as-staleness-gate.yml` (full file, 57 lines)
**Apply to:** `.github/workflows/merge-blocking-ios-mirror-parity.yml` (new)
One job that IS the check: checkout with `fetch-depth: 0` + `fetch-tags: true`, one `run:` step calling the script, one `if: always()` step-summary echo. No auto-commit, no PR-writeback.

## Action-Pinning Discipline (for `webfactory/ssh-agent`)

**Every third-party action in `release-please.yml` is SHA-pinned with a version comment** — verified via direct grep in this session and RESEARCH.md Q3:
```yaml
actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
actions/setup-java@c1e323688fd81a25caa38c78aa6df2d33d3e20d9 # v4.8.0
```
**Exactly one tracked exception:** `actions/upload-artifact@v4` (release-please.yml:696) — tag-pinned, deliberately NOT SHA-pinned, because `check_release_workflow_integrity.exs`'s `native_status_artifact` check (line 841) asserts the literal string `actions/upload-artifact@v4`. Do not "fix" this as a drive-by.

`webfactory/ssh-agent` should be SHA-pinned to match the dominant convention:
```yaml
webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 # v0.10.0
```
`.github/workflows/release-as-staleness-gate.yml` itself uses an unpinned `actions/checkout@v7` — a known minor inconsistency in that one precedent file; do not copy that specific detail into the new parity workflow.

## No Analog Found

None. Every file this phase touches or creates has a direct, already-identified analog in the repo — this is the intended shape of a "release-infrastructure extension" phase per RESEARCH's own "Don't Hand-Roll" table: the fire-drill lane, the alerting machinery, the required-check registration, and the offline bash-script proof harness all already exist from prior phases (144/145/PROOF-03).

## Metadata

**Analog search scope:** `.github/workflows/*.yml`, `script/*.sh`, `script/*.exs`, `lib/crosswake/release_status.ex`, `test/crosswake/proof/*.exs`, `test/mix/tasks/*.exs`
**Files read in full:** `script/verify_ios_mirror_backfill.sh` (252 lines), `test/crosswake/proof/phase145_ios_backfill_script_test.exs` (159 lines), `.github/workflows/ios-mirror-backfill.yml` (107 lines), `.github/workflows/release-as-staleness-gate.yml` (57 lines), `script/list_merge_blocking_checks.py` (79 lines), `script/register_required_checks.sh` (112 lines)
**Files read in targeted sections:** `.github/workflows/release-please.yml` (380-779), `lib/crosswake/release_status.ex` (440-540, 620-690, 760-838), `script/check_release_workflow_integrity.exs` (1-100, 745-864), `test/crosswake/proof/phase142_release_integrity_test.exs` (1-40), `test/mix/tasks/crosswake_release_status_test.exs` (1-40, 140-210)
**Correction to CONTEXT/RESEARCH:** the existing `Crosswake.ReleaseStatus` test file is `test/mix/tasks/crosswake_release_status_test.exs`, not `test/crosswake/release_status_test.exs` — confirmed via `find`.
**Pattern extraction date:** 2026-07-12
