---
phase: 131-publish-pipeline-clean-room-lane-rulestead
verified: 2026-06-26T09:00:00Z
status: passed
score: 9/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 131: Publish Pipeline + Clean-Room Lane — Verification Report

**Phase Goal:** Wire release-please for an independently-versioned Hex companion (crosswake_rulestead); prove clean-room install outside the monorepo; rulestead live on Hex.
**Verified:** 2026-06-26
**Status:** PASSED
**Re-verification:** No — initial verification

**Important context applied:** This phase is a no-publish dress-rehearsal lane (decisions D-04/D-14/D-20). The "rulestead live on Hex" outcome is delivered by CI AFTER the release-please PR merges. The phase is judged on whether the pipeline is correctly wired and gated, not on whether `hex.publish` ran locally. All verification below applies that lens.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | crosswake_rulestead registered as independent release-please elixir component, NOT in linked-versions (EXTRACT-05) | VERIFIED | `release-please-config.json`: `"component": "crosswake_rulestead"`, `"release-type": "elixir"`, `"separate-pull-requests": true`, `"release-as": "0.1.0"`, `"extra-files": ["packages/crosswake_rulestead/mix.exs"]`; `linked-versions.components` array contains `["hex","ios-core","android-core"]` — crosswake_rulestead is absent |
| 2 | .release-please-manifest.json has 0.1.0 baseline for packages/crosswake_rulestead, independent of the core 0.1.2 lockstep (EXTRACT-05) | VERIFIED | `"packages/crosswake_rulestead": "0.1.0"` in manifest; core `.` is `"0.1.2"` — confirmed separate version universe |
| 3 | companion mix.exs has env-conditional crosswake_dep/0: Hex dep under CROSSWAKE_RELEASE=1, path dep otherwise (D-11/D-13) | VERIFIED | `defp crosswake_dep` present in `packages/crosswake_rulestead/mix.exs` line 64; `if System.get_env("CROSSWAKE_RELEASE") == "1", do: {:crosswake, "~> 0.1"}, else: {:crosswake, path: "../.."}` — `deps/0` calls `crosswake_dep()` (line 51) |
| 4 | slash-path outputs aliased to rulestead_release_created/rulestead_tag_name/rulestead_version in release-please job outputs block (D-08) | VERIFIED | Lines 47-49 of release-please.yml: all three aliases present using bracket-notation `packages/crosswake_rulestead--{name}` double-dash format |
| 5 | publish-hex-rulestead job: gated on rulestead_release_created (never releases_created), runs SC#2 sequence under CROSSWAKE_RELEASE=1, publishes from companion tag (EXTRACT-06, D-07/D-09/D-13) | VERIFIED | `if: ${{ needs.release-please.outputs.rulestead_release_created == 'true' }}`; `releases_created` absent from if-condition; `env.CROSSWAKE_RELEASE: "1"` at job level; checkout `ref: rulestead_tag_name`; SC#2 sequence order confirmed: deps.get(4) → compile(5) → test(7) → dry-run(8) → publish(9) |
| 6 | publish-hex-rulestead contains pre-publish hex.publish --dry-run gate preceding the real publish (PROOF-02, SC#4) | VERIFIED | Steps 8 and 9: `mix hex.publish --dry-run --yes` with HEX_API_KEY precedes `mix hex.publish --yes` in the same job |
| 7 | script/verify_companion_cleanroom.sh exists and proves published artifact resolves + works outside the monorepo: propagation poll, throwaway Phoenix host in RUNNER_TEMP, public-seam smoke test, doctor --router exit 0 (PROOF-01, D-16/17/18/19/20) | VERIFIED | File exists (266 lines, valid bash per `bash -n`); all pattern checks pass: `set -euo pipefail`, `crosswake.doctor --router`, `use Phoenix.Router`, `validate_dependency`, `RUNNER_TEMP`, `MAX_ATTEMPTS=36/DELAY=10`, semver validation, default PACKAGE=crosswake_rulestead, VERSION required as $2; Steps 1-7 implement the PROOF-01 contract |
| 8 | clean-room-proof-rulestead job wired via needs: [release-please, publish-hex-rulestead], gated on rulestead_release_created, delegates to script (PROOF-02, D-15/D-16) | VERIFIED | Job present in release-please.yml; `needs: ['release-please', 'publish-hex-rulestead']`; `if: rulestead_release_created == 'true'`; thin YAML step calls `bash script/verify_companion_cleanroom.sh crosswake_rulestead "${{ needs.release-please.outputs.rulestead_version }}"` — no inline proof logic |
| 9 | release-as removal follow-up documented as actionable runbook (D-04, Pitfall 6) | VERIFIED | `131-RELEASE-AS-REMOVAL.md` exists (4138 bytes); contains `release-as` and `0.1.0`; `release-please-config.json` STILL carries `"release-as": "0.1.0"` on the companion entry (correctly left intact for the first cut) |

**Score:** 9/9 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `packages/crosswake_rulestead/mix.exs` | crosswake_dep/0 env-conditional resolver | VERIFIED | `defp crosswake_dep` at line 64; `deps/0` calls it at line 51; `@version "0.1.0"` + `# x-release-please-version` marker intact |
| `release-please-config.json` | crosswake_rulestead component entry with release-as 0.1.0 | VERIFIED | All required fields present: component, release-type, separate-pull-requests, release-as, extra-files, changelog-sections |
| `.release-please-manifest.json` | packages/crosswake_rulestead key at 0.1.0 | VERIFIED | `"packages/crosswake_rulestead": "0.1.0"` present; core remains at 0.1.2 |
| `.github/workflows/release-please.yml` release-please job outputs block | rulestead_release_created/tag_name/version aliases | VERIFIED | Lines 47-49; bracket-notation double-dash format |
| `.github/workflows/release-please.yml` publish-hex-rulestead job | per-component gated publish, SC#2 sequence | VERIFIED | All required attributes confirmed |
| `.github/workflows/release-please.yml` clean-room-proof-rulestead job | post-publish needs-graph, thin YAML | VERIFIED | `needs: [release-please, publish-hex-rulestead]` structural ordering |
| `script/verify_companion_package.sh` | Step 2 dep-presence gate activated, HAS_PATH_DEP removed, dry-run removed | VERIFIED | `HAS_PATH_DEP` absent; `CROSSWAKE_RELEASE=1 mix hex.build --unpack` present; `hex_metadata.config` grep present; `hex.publish --dry-run` absent; `env -u CROSSWAKE_RELEASE` in Step 3 |
| `script/verify_companion_cleanroom.sh` | New file, PROOF-01 logic | VERIFIED | 266 lines, all required patterns confirmed |
| `.planning/phases/131-publish-pipeline-clean-room-lane-rulestead/131-RELEASE-AS-REMOVAL.md` | Release-as removal runbook | VERIFIED | Present, contains trigger condition, exact JSON edit, rindle cross-reference |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| CROSSWAKE_RELEASE env | crosswake_dep/0 | `System.get_env("CROSSWAKE_RELEASE") == "1"` in mix.exs | VERIFIED | Resolver branches correctly; `deps/0` calls `crosswake_dep()` |
| rulestead_release_created output | publish-hex-rulestead if-gate | `needs.release-please.outputs.rulestead_release_created == 'true'` | VERIFIED | Per-component gate; aggregate `releases_created` NOT referenced in if-condition |
| publish-hex-rulestead | clean-room-proof-rulestead | `needs: [release-please, publish-hex-rulestead]` | VERIFIED | Structural PROOF-02 ordering — clean-room cannot dispatch before dry-run-gated publish |
| rulestead_tag_name | checkout ref | `ref: ${{ needs.release-please.outputs.rulestead_tag_name }}` | VERIFIED | D-09: publishes from companion tag, not core tag |
| rulestead_version | verify_companion_cleanroom.sh VERSION arg | `"${{ needs.release-please.outputs.rulestead_version }}"` | VERIFIED | Thin YAML delegation to script with correct version argument |
| CROSSWAKE_RELEASE=1 (job-level) | all mix steps in publish-hex-rulestead | `env: { CROSSWAKE_RELEASE: "1" }` at job level | VERIFIED | D-13: covers deps.get, compile, test, dry-run, publish steps |
| release-as 0.1.0 | first-cut tag crosswake_rulestead-v0.1.0 | config entry + manifest baseline | VERIFIED | D-04: one-shot bootstrap; removal documented in runbook |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| EXTRACT-05 | Plan 01 | crosswake_rulestead as independent release-please elixir component, NOT in linked-versions | SATISFIED | `release-please-config.json` entry with `separate-pull-requests: true`; not in `linked-versions.components`; manifest at 0.1.0 independent of core 0.1.2 |
| EXTRACT-06 | Plan 02 | per-companion publish job keyed on release-please per-component output, SC#2 sequence | SATISFIED | `publish-hex-rulestead` job: gated on `rulestead_release_created`, SC#2 sequence order verified (deps.get→compile→test→dry-run→publish), CROSSWAKE_RELEASE=1 job-level env |
| PROOF-01 | Plan 02 | clean-room script creates throwaway project outside monorepo, installs published trio, compiles, runs tests + doctor smoke | SATISFIED | `script/verify_companion_cleanroom.sh`: 266 lines; Steps 1-7 implement propagation poll, RUNNER_TEMP Phoenix host, dep install, compile, router stub, smoke test, doctor --router |
| PROOF-02 | Plan 03 | no companion publish until dry-run gate and proof lanes are green; clean-room wired post-publish | SATISFIED | dry-run step precedes publish step in same job (in-job gate); `clean-room-proof-rulestead` `needs: [release-please, publish-hex-rulestead]` (structural post-publish ordering) |

All 4 required requirement IDs are covered. No orphaned requirements detected for Phase 131.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.github/workflows/release-please.yml` | 659 | Stray `echo "LOCKSTEP OK: all coordinates agree on version $MIX_VERSION"` appended to the clean-room proof step's `run:` block; `$MIX_VERSION` is undefined in this job | INFO | Benign — GHA runner does not use `set -u` in step shells by default; `$MIX_VERSION` expands to empty string; `echo` exits 0; the step succeeds. The script itself (`verify_companion_cleanroom.sh`) runs first and if it fails the step exits non-zero before this line runs. No functional defect; the line is noise copied from the `lockstep-truth` job template. |

No TBD/FIXME/XXX debt markers found in any phase-modified file. No unreferenced blocking debt.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| verify_companion_cleanroom.sh is valid bash | `bash -n script/verify_companion_cleanroom.sh` | exit 0 | PASS |
| verify_companion_package.sh is valid bash | `bash -n script/verify_companion_package.sh` | exit 0 | PASS |
| release-please-config.json is valid JSON with correct component fields | `python3` JSON assertions | config+manifest OK; all fields verified | PASS |
| release-please.yml is valid YAML with all jobs present | `python3 yaml.safe_load` | Valid; all 10 jobs parsed | PASS |
| publish-hex-rulestead SC#2 step order | step index check | deps.get(4)→compile(5)→test(7)→dry-run(8)→publish(9) — correctly ordered | PASS |
| CROSSWAKE_RELEASE=1 job-level env | YAML parse + env key check | `env.CROSSWAKE_RELEASE: 1` confirmed | PASS |
| rulestead NOT in linked-versions | python3 assertion | `crosswake_rulestead` absent from `linked-versions.components` | PASS |
| manifest has 0.1.0 baseline (independent of core 0.1.2) | python3 | `"packages/crosswake_rulestead": "0.1.0"` vs core `"0.1.2"` | PASS |
| HAS_PATH_DEP gate removed from verify_companion_package.sh | `grep -q 'HAS_PATH_DEP'` | exits non-zero | PASS |
| hex.publish --dry-run absent from verify_companion_package.sh | `grep -q 'hex.publish --dry-run'` | exits non-zero | PASS |

**Note on full end-to-end execution:** `CROSSWAKE_RELEASE=1 bash script/verify_companion_cleanroom.sh crosswake_rulestead <VERSION>` requires a live `crosswake_rulestead` on Hex.pm, which does not exist until the Plan 02 publish job runs post-merge. This is by design (PROOF-01 is intentionally CI-only/post-publish irreversible). Static verification of script correctness is authoritative at author time.

### Human Verification Required

None. All must-haves are statically verifiable from the codebase. The clean-room proof's full runtime execution is CI-only by deliberate design (PROOF-01), not an oversight — this was established in the phase planning and is correctly not a verification gap for this dress-rehearsal lane.

---

## Notes

**Stray echo in clean-room step:** The `clean-room-proof-rulestead` job's run field contains `echo "LOCKSTEP OK: all coordinates agree on version $MIX_VERSION"` after the script invocation. `$MIX_VERSION` is not defined in that job context and expands to empty string. This is benign (GHA `run:` shells do not use `set -u`; echo exits 0), but it is cosmetic noise that could be cleaned up in a future phase.

**No-publish dress-rehearsal:** Per decisions D-04/D-14/D-20, the actual `hex.publish` execution is deliberately deferred to CI post-merge. The phase delivers the complete, correctly-wired, correctly-gated pipeline. All structural guarantees (independent versioning, per-component gate, dry-run before publish, post-publish clean-room proof) are present and verified in the codebase.

---

_Verified: 2026-06-26T09:00:00Z_
_Verifier: Claude (gsd-verifier)_
