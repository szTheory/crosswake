---
phase: 138-crosswake-chimeway-extraction
plan: "03"
subsystem: infra
tags: [release-please, ci, hex-publish, clean-room, chimeway, elixir]

requires:
  - phase: 138-02
    provides: crosswake_chimeway package extracted with tests and non-vacuous clean-room proof

provides:
  - chimeway CI publish pipeline (publish-hex-chimeway + clean-room-proof-chimeway jobs)
  - chimeway-correct no-engine smoke test in verify_companion_cleanroom.sh (assert enabled?(%{}) + Telemetry canary)
  - crosswake_chimeway registered as independent release-please component (release-as 0.1.0, NOT locked)
  - examples/phoenix_host chimeway path dep + compat matrix row present

affects:
  - 138-04 (human gate that triggers the deferred Hex publish)
  - future wave: threadline CI pipeline (mirrors this chimeway pattern)

tech-stack:
  added: []
  patterns:
    - "per-component release-please gate (chimeway_release_created, never aggregate releases_created)"
    - "no-engine chimeway smoke test: package-aware assert/refute guard + Telemetry vacuity canary"
    - "CROSSWAKE_RELEASE=1 on all publish mix steps so hex.build sees Hex dep not path:"
    - "release-as-cleanup fires on chimeway_release_created to strip one-shot pin after first merge"

key-files:
  created: []
  modified:
    - script/verify_companion_cleanroom.sh
    - release-please-config.json
    - .release-please-manifest.json
    - .github/workflows/release-please.yml
    - examples/phoenix_host/mix.exs

key-decisions:
  - "Chimeway no-engine smoke assertion is package-gated: assert enabled?(%{}) for chimeway (defaults true), refute for all other no-engine companions — exactly one form per package (RESEARCH Pitfall 1)"
  - "Chimeway.Telemetry.event_names/0 == 10 canary added to no-engine smoke test for vacuity-safety (CHIME-02): proves notification machinery shipped in tarball without sigra"
  - "clean-room-proof-chimeway invokes verify_companion_cleanroom.sh with NO engine args — sigra deliberately absent at the CI level, enforcing CHIME-02 no-sigra-dep invariant"
  - "crosswake_chimeway NOT added to linked-versions lockstep group — independently versioned (D-8)"
  - "guides/companion_compatibility.md chimeway row was already present from a prior wave commit; no duplicate action needed"

patterns-established:
  - "Package-aware enabled? assertion guard pattern: if/else on PACKAGE inside NO_ENGINE heredoc block, never both forms in same heredoc"
  - "Vacuity canary pattern: event_names/0 == N assertion proves sub-module shipped and runs without engine dep"

requirements-completed: [CHIME-02, CHIME-03]

coverage:
  - id: D1
    description: "verify_companion_cleanroom.sh no-engine chimeway mode emits assert enabled?(%{}) (not refute) and Chimeway.Telemetry.event_names/0 == 10 canary"
    requirement: CHIME-02
    verification:
      - kind: other
        ref: "bash -n script/verify_companion_cleanroom.sh && grep crosswake_chimeway + grep event_names"
        status: pass
    human_judgment: false
  - id: D2
    description: "release-please-config.json crosswake_chimeway component block (elixir, separate-pull-requests, release-as 0.1.0, NOT in linked-versions)"
    requirement: CHIME-03
    verification:
      - kind: other
        ref: "python3 JSON parse + assert component==crosswake_chimeway and release-as==0.1.0 + NOT in linked-versions"
        status: pass
    human_judgment: false
  - id: D3
    description: ".release-please-manifest.json has packages/crosswake_chimeway: 0.1.0"
    requirement: CHIME-03
    verification:
      - kind: other
        ref: "python3 -c \"import json; m=json.load(...); assert m['packages/crosswake_chimeway']=='0.1.0'\""
        status: pass
    human_judgment: false
  - id: D4
    description: "release-please.yml has chimeway outputs + publish-hex-chimeway (CROSSWAKE_RELEASE=1, per-component gate) + clean-room-proof-chimeway (no-engine) + cleanup + failure-alert extended"
    requirement: CHIME-03
    verification:
      - kind: other
        ref: "python3 yaml.safe_load + grep publish-hex-chimeway + grep clean-room-proof-chimeway + grep strip_release_as.py crosswake_chimeway"
        status: pass
    human_judgment: false
  - id: D5
    description: "examples/phoenix_host/mix.exs has crosswake_chimeway path dep; guides/companion_compatibility.md has chimeway row (engine dep: none)"
    requirement: CHIME-03
    verification:
      - kind: other
        ref: "grep crosswake_chimeway examples/phoenix_host/mix.exs && grep crosswake_chimeway guides/companion_compatibility.md"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-02
status: complete
---

# Phase 138 Plan 03: crosswake_chimeway CI Publish Pipeline Summary

**chimeway-correct no-engine smoke test (assert enabled?(%{}) + Telemetry vacuity canary) and independent release-please publish pipeline (3 new CI jobs, per-component gated) wired for crosswake_chimeway**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-02T18:39:32Z
- **Completed:** 2026-07-02T18:44:45Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Patched `verify_companion_cleanroom.sh` with a package-aware enabled? guard: chimeway invocation emits `assert enabled?(%{})` (defaults true), other no-engine companions keep `refute enabled?(%{})` — exactly one form per package, no contradiction (RESEARCH Pitfall 1 fix)
- Added `Chimeway.Telemetry.event_names/0 == 10` canary in the chimeway no-engine smoke block: vacuity-safe proof that the Telemetry sub-module shipped in the tarball without sigra present (CHIME-02)
- Registered `crosswake_chimeway` as an independent release-please elixir component (one-shot release-as 0.1.0, NOT in linked-versions lockstep — D-8); manifest entry added; example host path dep added
- Added `publish-hex-chimeway` CI job: CROSSWAKE_RELEASE=1 on all mix steps, per-component gate on `chimeway_release_created` (not aggregate `releases_created`), dry-run-gated publish, Hex propagation poll (T-138-12)
- Added `clean-room-proof-chimeway` CI job: no-engine invocation, sigra deliberately absent (CHIME-02 at CI level), runs after publish; chimeway-correct smoke via Task 1 fix (T-138-11)
- Extended `release-as-cleanup` and `release-failure-alert` to cover chimeway (T-138-08/T-138-09)

## Task Commits

1. **Task 1: chimeway-correct no-engine smoke test** - `9222bb1c` (feat)
2. **Task 2: release-please component + example host + compat matrix** - `a61b5e0f` (feat)
3. **Task 3: chimeway CI publish pipeline in release-please.yml** - `51fd30ff` (feat)

## Files Created/Modified

- `script/verify_companion_cleanroom.sh` — package-aware NO_ENGINE enabled? guard (if/else on PACKAGE), chimeway assert path + Telemetry canary; usage comment updated
- `release-please-config.json` — crosswake_chimeway component block (elixir, separate-pull-requests, release-as 0.1.0, _TODO_release_as note, NOT in linked-versions)
- `.release-please-manifest.json` — "packages/crosswake_chimeway": "0.1.0" added
- `.github/workflows/release-please.yml` — chimeway outputs (3), publish-hex-chimeway job, clean-room-proof-chimeway job, release-as-cleanup if: extended + strip block, release-failure-alert needs + body extended (~143 lines added)
- `examples/phoenix_host/mix.exs` — {:crosswake_chimeway, path: "../../packages/crosswake_chimeway"} path dep added; comment updated

## Decisions Made

- Package-aware assert/refute pattern: guard inside the NO_ENGINE if block (not a separate heredoc call) keeps the shell clean and the Elixir test non-contradictory
- `guides/companion_compatibility.md` chimeway row was already committed in a prior wave — no duplicate action taken
- No-engine smoke test split into two separate `if/else` branches (chimeway vs others) rather than using shell interpolation inside a single heredoc; safer for quoting and easier to audit

## Deviations from Plan

None — plan executed exactly as written. The compat matrix row pre-existence (already committed) was discovered but is not a deviation — the acceptance criterion (row present) was met, so no action was needed.

## Issues Encountered

None.

## Threat Mitigations Verified

- **T-138-08** (one-shot release-as supply chain): release-as-cleanup strips crosswake_chimeway on chimeway_release_created — strip block added and verified with grep
- **T-138-09** (over-publish gate): all chimeway jobs gate on chimeway_release_created (never aggregate releases_created) — per-component gate confirmed in all 3 chimeway CI jobs
- **T-138-10** (vacuity-safe clean-room): Telemetry.event_names/0 == 10 canary added; clean-room installs crosswake + crosswake_chimeway only (no sigra)
- **T-138-11** (chimeway enabled? smoke assertion): assert enabled?(%{}) replaces refute for chimeway invocation (chimeway defaults true); implemented as package-aware if/else guard
- **T-138-12** (CROSSWAKE_RELEASE build gate): CROSSWAKE_RELEASE=1 on all mix steps in publish-hex-chimeway

## Known Stubs

None. All publish machinery is wired to real jobs and real script invocations. The publish itself is deferred to Wave 4 (human gate), but all CI jobs are fully wired in-tree.

## Threat Flags

None. No new network endpoints or auth paths introduced. CI/config-only changes, all first-party files.

## Next Phase Readiness

- Wave 4 (138-04) is the human publish gate — it depends on these lanes existing and being green-able. All three chimeway CI jobs are now present.
- The actual Hex publish is deferred to a batched family publish (user decision). Wave 4 will confirm the deferred-publish state and close the phase.

## Self-Check

- `script/verify_companion_cleanroom.sh`: `bash -n` passes, grep chimeway OK, grep event_names OK
- `release-please-config.json`: valid JSON, chimeway component OK, NOT in linked-versions OK
- `.release-please-manifest.json`: valid JSON, packages/crosswake_chimeway: 0.1.0 OK
- `.github/workflows/release-please.yml`: valid YAML, all job/output greps OK, cleanup-wired OK
- `examples/phoenix_host/mix.exs`: chimeway dep present
- `guides/companion_compatibility.md`: chimeway row present
- Commits: 9222bb1c, a61b5e0f, 51fd30ff — all verified in git log

## Self-Check: PASSED

---
*Phase: 138-crosswake-chimeway-extraction*
*Completed: 2026-07-02*
