---
phase: 132-generalization-proof-rindle-compat-matrix
plan: 04
subsystem: companion-packaging
tags: [extraction, rindle, release-please, publish-pipeline, clean-room, independent-versioning, generalization-proof]
status: complete
requires:
  - "packages/crosswake_rindle/ fully populated (132-03 — source + tests + mix.lock)"
  - "guides/companion_compatibility.md + COMPAT-03 drift test (132-02)"
  - "crosswake_rulestead release-please wiring proven in Phase 131"
  - "engine-parameterized script/verify_companion_cleanroom.sh ($3 engine_package $4 engine_module, Phase 131)"
provides:
  - "packages/crosswake_rindle release-please component (separate elixir, NOT in linked-versions lockstep)"
  - ".release-please-manifest.json packages/crosswake_rindle: 0.1.0 baseline"
  - "rindle_release_created / rindle_tag_name / rindle_version workflow output aliases (D-08)"
  - "publish-hex-rindle job (gated, CROSSWAKE_RELEASE=1, dry-run -> publish -> Hex poll)"
  - "clean-room-proof-rindle job (needs publish-hex-rindle) delegating to verify_companion_cleanroom.sh"
  - "rindle Contracts.media_state_vocabulary/0 canary inside the clean-room smoke body (D-18)"
affects:
  - "first irreversible crosswake_rindle Hex publish (cut when the first rindle Release PR merges)"
  - "post-phase runbook: remove release-as 0.1.0 after first rindle Release PR merges"
tech-stack:
  added: []
  patterns:
    - "independent per-companion versioning via a separate release-please component (NOT linked-versions, D-01)"
    - "per-component gate (rindle_release_created) never the aggregate releases_created (D-07)"
    - "double-dash path output -> dot-notation alias for slash-key indexing in if: (D-08)"
    - "thin-YAML clean-room job delegating all proof logic to the engine-parameterized script (D-16)"
    - "PACKAGE-guarded canary block inside the unquoted SMOKEEOF heredoc — no new script parameter (D-18)"
key-files:
  created: []
  modified:
    - release-please-config.json
    - .release-please-manifest.json
    - .github/workflows/release-please.yml
    - script/verify_companion_cleanroom.sh
decisions:
  - "TODO note for the one-shot release-as lives as a _TODO_release_as field INSIDE the crosswake_rindle package object (not a sibling packages-map key) — release-please enumerates only top-level packages keys as paths and ignores unknown per-package fields, so a sibling _comment key would have been mis-parsed as a package directory."
  - "Removed a pre-existing stray `echo \"LOCKSTEP OK: ... $MIX_VERSION\"` line that had been folded into the rulestead clean-room job's `run: >` block (Rule 1 — $MIX_VERSION is undefined in that job; leftover paste from the lockstep-truth job). The rulestead clean-room run is now a clean two-arg script invocation."
metrics:
  duration: ~9m
  completed: 2026-06-26
  tasks: 3
  files: 4
---

# Phase 132 Plan 04: Rindle Publish Pipeline + Clean-Room Lane Summary

Wired `crosswake_rindle` into the release-please publish pipeline as an
independently-versioned (NOT lockstep) separate component, added the gated
`publish-hex-rindle` job and the post-publish `clean-room-proof-rindle` job, and
appended the rindle `Contracts.media_state_vocabulary/0` canary to the clean-room
smoke body. This is `script/extract_companion.md` Step 12 applied to rindle by
substitution, mirroring the rulestead wiring proven in Phase 131. No irreversible
Hex publish was performed — the pipeline is wired; the first `crosswake_rindle`
release is cut when the first rindle Release PR merges (CI-only, post-merge).

## What Was Built

**Task 1 — release-please component + manifest baseline (commit d164ac2)**
Added a `packages/crosswake_rindle` separate elixir component to
`release-please-config.json` (copy-substituted from the `crosswake_rulestead`
block): `release-as: "0.1.0"` (one-shot), `separate-pull-requests: true`,
`extra-files: [packages/crosswake_rindle/mix.exs]`, the same changelog-sections.
It is intentionally **NOT** added to the `linked-versions` lockstep group (D-01) —
rindle versions independently of core. A `_TODO_release_as` field inside the
package object documents that `release-as` is a one-shot override to remove after
the first Release PR merges. Added `"packages/crosswake_rindle": "0.1.0"` to
`.release-please-manifest.json`. The plan's node verification (`RELEASE_PLEASE_OK`)
passes — component present, correct, not in lockstep, manifest baseline present.

**Task 2 — publish + clean-room jobs + output aliases (commit afc52d6)**
In the `release-please` job outputs block, added the three rindle aliases
(`rindle_release_created` / `rindle_tag_name` / `rindle_version`) mapping the
double-dash path outputs to dot-notation (D-08 — `if:` cannot index slash keys).
Added `publish-hex-rindle` mirroring `publish-hex-rulestead`: gated on
`rindle_release_created == 'true'`, checkout at `rindle_tag_name`,
`working-directory: packages/crosswake_rindle`, `CROSSWAKE_RELEASE: "1"` (activates
the Hex `crosswake` dep in the tarball), steps `deps.get -> compile
--warnings-as-errors -> version grep -> mix test (no --exclude) -> hex.publish
--dry-run -> hex.publish -> Hex propagation poll`. Added `clean-room-proof-rindle`
as a copy-substitute of `clean-room-proof-rulestead`: `needs: [release-please,
publish-hex-rindle]`, gated on `rindle_release_created`, pinned setup-beam, and the
single thin step `bash script/verify_companion_cleanroom.sh crosswake_rindle
"<rindle_version>" rindle Rindle` (D-16). YAML parses (`YAML_VALID`).

**Task 3 — rindle Contracts canary in the clean-room smoke (commit c803467)**
Inside the generated `SMOKEEOF` smoke-test heredoc, appended a rindle-specific
Contracts canary guarded by `if [ "$PACKAGE" = "crosswake_rindle" ]` (the unquoted
heredoc evaluates the `$(...)` at generation time, so the test is emitted only for
rindle). The canary is one ExUnit test asserting
`Crosswake.Companions.Rindle.Contracts.media_state_vocabulary/0` returns a non-empty
list (confirmed arity-0, returns `[:queued, :uploaded, :scanning, :available,
:rejected]`), with a `[crosswake]`-prefixed failure message naming the possibly-
missing Contracts module. This confirms the Contracts sub-module shipped in the
tarball — the one rindle delta vs rulestead (which had no sub-module). No new script
parameter (D-18); `COMPANION_MODULE` derivation unchanged. `bash -n` clean; the
guard emits the canary for `crosswake_rindle` and nothing for `crosswake_rulestead`.

## Verification

- Task 1: `node -e "..."` component/lockstep/manifest assertion → `RELEASE_PLEASE_OK`. ✓
- Task 2: rindle aliases + both jobs + script reference present; `python3 -c "import yaml; yaml.safe_load(...)"` → `YAML_VALID`. ✓
- Task 3: `crosswake_rindle` + `media_state_vocabulary` present; `bash -n script/verify_companion_cleanroom.sh` clean → `CANARY_OK`. ✓
- Guard isolation: simulated heredoc body emits the canary for `crosswake_rindle`, ABSENT for `crosswake_rulestead`. ✓
- rindle is NOT in `linked-versions`: the lockstep `plugins` group still lists only `["hex", "ios-core", "android-core"]`. ✓
- (CI-only, post-publish) `clean-room-proof-rindle` is green after the first rindle Release PR merges — irreversible, cannot run locally (RESEARCH.md §Environment).

## Deviations from Plan

**1. [Rule 1 — pre-existing defect] Removed a stray `$MIX_VERSION` echo from the rulestead clean-room job.**
- **Found during:** Task 2, while inserting the rindle clean-room job immediately after `clean-room-proof-rulestead`.
- **Issue:** The rulestead clean-room job's `run: >` folded scalar had a trailing
  `echo "LOCKSTEP OK: all coordinates agree on version $MIX_VERSION"` line. `$MIX_VERSION`
  is undefined in that job (it is a `lockstep-truth`-job variable) — a leftover paste
  artifact. Because `run: >` folds the blank line + echo into the same shell command,
  the rulestead clean-room step would echo `LOCKSTEP OK: ... version ` (empty) on every
  run; harmless but incorrect and confusing.
- **Fix:** Removed the stray line; the rulestead clean-room `run` is now a clean
  two-argument `bash script/verify_companion_cleanroom.sh crosswake_rulestead "<ver>"`.
- **Files:** `.github/workflows/release-please.yml`.
- **Commit:** afc52d6.

**2. [Plan-honoring placement decision] One-shot `release-as` TODO placed as an in-object field, not a sibling map key.**
- **Plan asked for** a "TODO comment near the release-as." JSON has no comments. A
  sibling `_comment_*` key inside the `packages` map would be enumerated by
  release-please as a package PATH and fail. The TODO is therefore a `_TODO_release_as`
  field INSIDE the `crosswake_rindle` package object — release-please ignores unknown
  per-package fields, so the note travels with the block without breaking config parsing.
  Not a behavioral deviation; documented for traceability.

## Known Stubs

None. All four files are fully wired: the component + manifest baseline are real,
both CI jobs are gated and executable (pending the first Release PR), and the canary
asserts against the live `media_state_vocabulary/0` function shipped in 132-03.

## Threat Surface

No new threat surface beyond the plan's `<threat_model>`.
- **T-132-07 (shell injection via `$VERSION`):** mitigated — the existing semver-regex
  guard in `verify_companion_cleanroom.sh` (lines 53-57) is unchanged; the canary edit
  is inside the smoke heredoc, not the curl-URL path.
- **T-132-08 (publishing an unverified tarball):** mitigated — `publish-hex-rindle` runs
  `hex.publish --dry-run` before `hex.publish`; `clean-room-proof-rindle` (needs publish)
  installs + compiles `--warnings-as-errors` + asserts the seam happy path + the Contracts
  canary before the release is trusted.
- **T-132-01 / T-132-SC (slopsquat / package-manager installs):** unchanged — the only
  installs are `mix deps.get` resolving `crosswake` + `crosswake_rindle` + the
  `rindle ~> 0.1` engine, all `szTheory`-authored, no wildcards; dry-run + clean-room are
  the slopcheck. No new external packages.

## Post-Phase Runbook (carry to verify-phase)

After the first `crosswake_rindle` Release PR merges (recipe Step 12f / Pitfall 6):
remove `"release-as": "0.1.0"` (and the adjacent `_TODO_release_as` note) from the
`packages/crosswake_rindle` block in `release-please-config.json`, or subsequent runs
keep re-targeting 0.1.0. Track in the phase verify-work checklist.

## Self-Check: PASSED

All four modified files present on disk with the expected edits; all three task
commits (d164ac2, afc52d6, c803467) present in git history.
