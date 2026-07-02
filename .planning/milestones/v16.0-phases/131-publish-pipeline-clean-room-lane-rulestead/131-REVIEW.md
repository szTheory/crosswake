---
phase: 131-publish-pipeline-clean-room-lane-rulestead
reviewed: 2026-06-26T00:00:00Z
depth: standard
files_reviewed: 7
files_reviewed_list:
  - .github/workflows/release-please.yml
  - .release-please-manifest.json
  - packages/crosswake_rulestead/mix.exs
  - release-please-config.json
  - script/extract_companion.md
  - script/verify_companion_cleanroom.sh
  - script/verify_companion_package.sh
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 131: Code Review Report

**Reviewed:** 2026-06-26
**Depth:** standard
**Files Reviewed:** 7
**Status:** issues_found

## Summary

This phase wires `crosswake_rulestead` into the release-please publish pipeline: a per-component release gate (`rulestead_release_created`), an env-conditional `CROSSWAKE_RELEASE` dependency resolver, two new CI jobs (`publish-hex-rulestead`, `clean-room-proof-rulestead`), and two shell scripts (`verify_companion_package.sh`, `verify_companion_cleanroom.sh`).

The core wiring is correct and demonstrates careful CI hygiene: the per-component gate (`rulestead_release_created`) is used instead of the aggregate `releases_created` (so a core-only release does NOT publish the companion), `set -euo pipefail` is present in every multi-line shell block, the version string is semver-validated before URL construction, the companion's public API (`companion_id/0`, `validate_dependency/0`, `enabled?/1`) matches the clean-room smoke-test assertions, and `config/runtime.exs` is confirmed to load in a plain `mix new --sup` app (so the doctor sees the registered companion). The double `ExUnit.start()` in the generated smoke test was verified to be a harmless no-op.

No blockers. Four warnings concern: (1) a stray copy-paste `echo "$MIX_VERSION"` line accidentally folded into the rulestead clean-room job's `run:`, referencing an undefined variable; (2) a hardcoded `rulestead.ex` path that breaks the scripts' documented rindle-reuse parameterization; (3) the `release-as: "0.1.0"` config trap left active; (4) the version-grep verify step being substring-fragile. Info items cover minor robustness nits.

## Warnings

### WR-01: Stray `echo "$MIX_VERSION"` folded into rulestead clean-room job — references undefined variable

**File:** `.github/workflows/release-please.yml:655-660`
**Issue:** The `clean-room-proof-rulestead` job's final step uses a folded scalar (`run: >`). Because of the blank line at 659 and the trailing line at 660, the folded `run:` value is actually TWO commands:

```
bash script/verify_companion_cleanroom.sh crosswake_rulestead "<version>"
echo "LOCKSTEP OK: all coordinates agree on version $MIX_VERSION"
```

The second line is leftover copy-paste from the `lockstep-truth` job (which defines `MIX_VERSION`). In this job `MIX_VERSION` is never set, so it expands to an empty string and prints a misleading "LOCKSTEP OK: all coordinates agree on version " message that has nothing to do with this job. It also implies a lockstep assertion ran when none did. The step has no `set -u`, so it will not fail the build — it is dead, confusing output that can mask a real lockstep regression.

**Fix:** Delete the stray line and the blank line so the folded scalar contains only the script invocation:
```yaml
        run: >
          bash script/verify_companion_cleanroom.sh
          crosswake_rulestead
          "${{ needs.release-please.outputs.rulestead_version }}"
```
(Remove lines 659–660 entirely.)

### WR-02: `verify_companion_package.sh` hardcodes `rulestead.ex` — breaks documented rindle reuse

**File:** `script/verify_companion_package.sh:53-54`
**Issue:** The script header (lines 23-24) and `extract_companion.md` advertise this script as "Parameterized so Phase 132 can reuse for crosswake_rindle: `./script/verify_companion_package.sh crosswake_rindle`". But Step 1's tarball-content assertion hardcodes the rulestead path:
```bash
if [ ! -f "$UNPACK_DIR/lib/crosswake/companions/rulestead.ex" ]; then
  echo "[crosswake] FAIL: lib/crosswake/companions/rulestead.ex not found ... source not moved yet"
```
Running this for `crosswake_rindle` will ALWAYS fail Step 1 with a false "source not moved yet" error even when rindle's source (`companions/rindle.ex`) is correctly placed. The parameterization is incomplete: `PACKAGE` is parameterized but the companion source filename is not derived from it.

**Fix:** Derive the companion source filename from `PACKAGE` (strip `crosswake_` prefix), mirroring the suffix-derivation already done in `verify_companion_cleanroom.sh:188`:
```bash
COMPANION_SUFFIX="${PACKAGE#crosswake_}"
SRC="$UNPACK_DIR/lib/crosswake/companions/${COMPANION_SUFFIX}.ex"
if [ ! -f "$SRC" ]; then
  echo "[crosswake] FAIL: $SRC not found in unpacked tarball — source not moved yet"
  exit 1
fi
```

### WR-03: `release-as: "0.1.0"` left active with manifest baseline already at `0.1.0` — re-cut / version-pin trap

**File:** `release-please-config.json:58` (with `.release-please-manifest.json:5`)
**Issue:** The new component entry sets `"release-as": "0.1.0"` while `.release-please-manifest.json` already pins `"packages/crosswake_rulestead": "0.1.0"`. release-please's `release-as` forces the next release to that exact version on EVERY run until removed. The recipe's own Step 12f (`extract_companion.md:360-364`) explicitly warns this must be removed after the first Release PR merges, "otherwise subsequent runs continue targeting 0.1.0 even after it is already published." Leaving it committed is a latent footgun: after 0.1.0 publishes, the companion cannot advance to 0.1.1+ (release-please keeps targeting 0.1.0, and the publish job's Hex publish of an already-existing 0.1.0 will fail). Because the cleanup is a manual post-merge step in a doc, it is easy to forget.

**Fix:** This is an intentional bootstrap value for the first cut, so it is acceptable to ship for 0.1.0 — but track the removal as a blocking follow-up. Either (a) add a CI assertion / issue that fails if `release-as` is still present after the `crosswake_rulestead-v0.1.0` tag exists, or (b) immediately after the first Release PR merges, remove the `"release-as": "0.1.0"` line per Step 12f. Do not let it persist silently.

### WR-04: Version-verify grep is substring-fragile (no anchoring, no marker requirement)

**File:** `.github/workflows/release-please.yml:188-190`
**Issue:** The companion version-verify step runs:
```bash
grep -n "@version \"${{ needs.release-please.outputs.rulestead_version }}\"" packages/crosswake_rulestead/mix.exs
```
The injected version is not anchored and not escaped. A version like `0.1.0` is treated as a regex where `.` matches any char, so `@version "0X1X0"` would also match — a false pass. More practically, this grep does not require the `# x-release-please-version` marker, so if release-please ever fails to bump the annotated line but some other `@version "0.1.0"` string exists (e.g. in a doc-comment or a second module attribute), the check passes against the wrong line. The core `lockstep-truth` job (line 599) correctly keys off the `# x-release-please-version` marker; this step does not.

**Fix:** Match the annotated line and treat the version as a literal:
```bash
grep -nF "@version \"${{ needs.release-please.outputs.rulestead_version }}\" # x-release-please-version" \
  packages/crosswake_rulestead/mix.exs
```
(`-F` for fixed-string; include the marker to pin the exact line.)

## Info

### IN-01: `clean-room-proof-rulestead` job comments reference iOS/Android `releases_created` semantics but job correctly gates per-component

**File:** `.github/workflows/release-please.yml:627-634`
**Issue:** The job correctly gates on `rulestead_release_created` (per-component, D-07) and `needs: [release-please, publish-hex-rulestead]`. This is correct. Noting only that the surrounding pipeline mixes aggregate-gated jobs (`publish-hex`, `publish-ios-core`, etc. gate on `releases_created`) with this per-component-gated companion job — a reader skimming the file could conflate the two gating strategies. The inline comments already explain the distinction well; no code change needed, but consider a top-of-file note that companion jobs intentionally use a different gate than the linked-version trio.

**Fix:** Optional: add a one-line banner comment above `publish-hex-rulestead` clarifying "Companion jobs gate on the PER-COMPONENT `<name>_release_created`; the linked trio gates on aggregate `releases_created`."

### IN-02: `basename $ARTIFACT` unquoted in fire-drill job

**File:** `.github/workflows/release-please.yml:491`
**Issue:** `echo "OK: $(basename $ARTIFACT) + .asc"` leaves `$ARTIFACT` unquoted inside the command substitution. The path is constructed from a controlled version + fixed artifact names (no spaces), so this is not exploitable, but it violates the otherwise-consistent quoting discipline in these scripts. (Pre-existing fire-drill job, not part of the rulestead change — noted for completeness.)

**Fix:** Quote it: `echo "OK: $(basename "$ARTIFACT") + .asc"`.

### IN-03: Cleanroom `re.sub` deps-block replacement assumes no nested brackets in generated `mix.exs`

**File:** `script/verify_companion_cleanroom.sh:128-133`
**Issue:** The Python `re.sub(r'defp deps do\s*\[.*?\]\s*end', ...)` non-greedily matches the first `]` after `defp deps do [`. This is correct for the `mix new --sup` template (whose deps list contains only a comment, no nested `[...]`). If the generator template ever changes to include a nested list inside `deps` (e.g. `extra_applications` style nesting or a tuple with a list value), the non-greedy match would truncate at the inner `]` and produce a malformed `mix.exs`. Low likelihood given the controlled `mix new` template, but the assumption is undocumented.

**Fix:** Optional hardening — add a post-substitution assertion that the rewritten `mix.exs` still contains the `{:crosswake, "~> 0.1"}` line and parses (`elixir -e 'Code.eval_file("mix.exs")'` would be heavyweight; a grep for the four injected deps suffices), failing fast if the regex mis-fired.

---

_Reviewed: 2026-06-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
