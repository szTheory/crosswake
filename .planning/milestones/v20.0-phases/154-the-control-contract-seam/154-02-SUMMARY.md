---
phase: 154-the-control-contract-seam
plan: 02
subsystem: api
tags: [elixir, manifest, doctor, capability-contract, support-matrix, capability-map]

# Dependency graph
requires:
  - phase: 154-the-control-contract-seam (154-01)
    provides: family-form capability vocabulary, fixed legacy_ids self-reference bug,
      doctor's capability.legacy_capability_id advisory, current committed fixtures
provides:
  - "Capability.@enforce_keys widened to [:id, :version, :rebuild, :interaction] — a
    control without a declared rebuild AND interaction class is unconstructable at
    compile time (the one structurally-impossible part of CTRL-05, D-52)"
  - "Capability.interaction field (:fire_and_forget | :device_answer | :user_answer)
    on all 15 capability_catalog/0 entries and both compatibility_capability_attrs/2
    branches, plus manifest_schema_version bump 1.0.0 -> 1.1.0"
  - "Crosswake.Doctor.capability_rebuild_findings/1 — the one genuinely missing
    CTRL-05 leg — under the stable code bridge.capability.native_rebuild_required"
  - "Crosswake.CapabilityMap.Row gains an enforce_keys'd :rebuild field; all 21
    canonical rows declare an explicit rebuild class; guides/capability_map.md
    renders a Rebuild column"
  - "guides/support_matrix.md Interaction-Class Legend documenting the 3
    Capability.interaction values and the 1.0.0 -> 1.1.0 schema bump"
  - "Crosswake.Manifest.Types.manifest_schema_version/0 — new public accessor that
    is now the single source of truth for the schema version literal (fixes two
    independently hardcoded 'target' literals discovered mid-execution)"
affects: [154-03, 154-04, 154-05, 154-06, 154-07, 154-08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Doctor findings: capability_rebuild_findings/1 mirrors native_rebuild_findings/2's
      check(:warning, code, subject, message, hint, details) shape exactly, folded into
      the existing phase_154_findings accumulation (no new aggregation mechanism)"
    - "Guide renderers (Crosswake.CapabilityMap.Renderer, Crosswake.SupportMatrix.Renderer)
      stay the only writers of their guides — every guide change in this plan went
      through a renderer regeneration, never a hand-edit, so the byte-identical drift
      tests stay meaningful"

key-files:
  created: []
  modified:
    - lib/crosswake/manifest/types.ex
    - lib/crosswake/manifest/builder.ex
    - lib/crosswake/compatibility/compatibility.ex
    - lib/crosswake/shell/activation.ex
    - lib/mix/tasks/crosswake.contract.gen.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/capability_map.ex
    - lib/crosswake/capability_map/renderer.ex
    - lib/crosswake/support_matrix/renderer.ex
    - examples/ios_shell_host/Fixtures/crosswake_manifest.json
    - examples/android_shell_host/app/src/main/assets/crosswake_manifest.json
    - test/fixtures/bridge_contract_vectors.json
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json
    - packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json
    - docs/_contract_snippet.md
    - guides/capability_map.md
    - guides/support_matrix.md
    - CHANGELOG.md
    - test/crosswake/manifest/builder_test.exs
    - test/crosswake/manifest/manifest_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/doctor/formatter_test.exs
    - test/crosswake/compatibility/compatibility_test.exs
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs
    - test/crosswake/operator_inspection/formatter_test.exs
    - test/mix/tasks/crosswake_doctor_test.exs
    - test/crosswake/capability_map/capability_map_test.exs
    - test/crosswake/capability_map/renderer_test.exs
    - test/crosswake/guides/release_boundaries_test.exs
    - test/fixtures/proof/phase52_operator_inspection.json
    - test/fixtures/proof/phase52_publish_readiness.json

key-decisions:
  - "D-51/D-52 ordering honored literally: hardened new_capability/1's tolerant
    rebuild default to fail-closed :native_required BEFORE widening @enforce_keys,
    so no intermediate state could crash on a nil rebuild value"
  - "Interaction values assigned per-capability using D-54's honesty framing: share
    is :fire_and_forget (request acknowledgement, not completion); app_info,
    permissions.status, notification_token are :device_answer; file_picker is
    :user_answer. The 9 catalog entries not named in the plan (deep_link,
    media_capture, scanner, document_scan, and the 5 commerce capabilities) were
    assigned by domain judgment, documented inline in builder.ex"
  - "Fixed two independently hardcoded manifest_schema_version '1.0.0' literals
    (Crosswake.Shell.Activation.target_from_request/1,
    Crosswake.Compatibility.bridge_target/1) discovered mid-execution — both
    silently diverged from the real schema version the moment it was first ever
    bumped, breaking route activation and bridge-request compatibility checks
    project-wide. Both now read the new Types.manifest_schema_version/0 accessor"
  - "Regenerated the two committed manifest JSON fixtures via a SCOPED patch (adding
    interaction/rebuild fields + schema bump only), not a full gen_manifest.exs
    regeneration — a full regen still pulls in ~2 months of unrelated router drift,
    exactly as Plan 01 discovered and documented"
  - "guides/capability_map.md's Rebuild column values are real
    capability_catalog/0 values where a row maps onto a live capability (9 of 21
    rows), and a deliberate judgment call for the other 12 narrative-only rows —
    documented and asserted in capability_map_test.exs for the 9 real mappings"
  - "The Interaction-Class Legend added to guides/support_matrix.md deliberately
    does NOT claim the Capability Families table shows a per-row interaction
    column (it doesn't) — the sentence was corrected mid-task to avoid making a
    false claim in a guide that exists specifically to prevent overclaiming"

patterns-established:
  - "capability_rebuild_findings/1 is keyed off Capability.rebuild != :none AND
    declared on >= 1 route in the compiled manifest — never on catalog membership
    alone, so an adopter is only warned about rebuild cost they have actually
    taken on"
  - "The Upgrade Impact vocabulary derivability assertion (release_boundaries_test.exs)
    is a total-mapping proof over RebuildPolicy.classify/2's verdict domain, not a
    coverage claim over the 4-string CHANGELOG vocabulary — docs-only and
    core-only/no native rebuild are not reachable from classify/2 at all, and that
    is fine; the mapping only needs to be total, not onto"

requirements-completed: [CTRL-05]

coverage:
  - id: D1
    description: "Capability struct is unconstructable without both :rebuild and :interaction (@enforce_keys), and every capability_catalog/0 entry plus both compatibility_capability_attrs/2 branches declare an explicit interaction value"
    requirement: "CTRL-05"
    verification:
      - kind: unit
        ref: "test/crosswake/manifest/builder_test.exs#Capability rebuild + interaction — structurally unconstructable without both (D-51, D-52, D-54)"
        status: pass
    human_judgment: false
  - id: D2
    description: "manifest_schema_version bumped 1.0.0 -> 1.1.0 with all five committed JSON fixtures regenerated and byte-identical across the three bridge_contract_vectors.json mirrors"
    verification:
      - kind: unit
        ref: "test/crosswake/manifest/manifest_test.exs#manifest keeps schema 1.1.0 while commerce corridor fields remain additive"
      - kind: other
        ref: "diff test/fixtures/bridge_contract_vectors.json packages/crosswake-shell-core-{ios,android}/.../bridge_contract_vectors.json (no output)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Doctor emits a capability_rebuild_findings/1 finding (bridge.capability.native_rebuild_required) naming the route, capability, and rebuild class for any non-:none capability declared on an active route; empty list when all-:none; hint distinguishes native vs companion"
    requirement: "CTRL-05"
    verification:
      - kind: unit
        ref: "test/crosswake/doctor/doctor_test.exs#capability rebuild finding (D-49, CTRL-05)"
        status: pass
      - kind: unit
        ref: "test/crosswake/doctor/formatter_test.exs#renders the bridge.capability.native_rebuild_required finding without a fall-through (Phase 154, D-49)"
        status: pass
    human_judgment: false
  - id: D4
    description: "guides/capability_map.md renders a Rebuild column across all 21 rows; guides/support_matrix.md carries an Interaction-Class Legend and the schema 1.1.0 bump note with the locked 4-string Change Classes vocabulary untouched; CHANGELOG.md Unreleased section carries the Upgrade Impact entry; a derivability assertion proves the 4-string vocabulary is total over RebuildPolicy's verdict domain"
    requirement: "CTRL-05"
    verification:
      - kind: unit
        ref: "test/crosswake/capability_map/capability_map_test.exs#D-53 rows backed by a real manifest capability match its catalog rebuild class"
        status: pass
      - kind: unit
        ref: "test/crosswake/guides/release_boundaries_test.exs#D-50 (Phase 154, CTRL-05): every RebuildPolicy verdict maps onto one of the four locked Upgrade Impact strings"
        status: pass
    human_judgment: false

# Metrics
duration: 70min
completed: 2026-07-29
status: complete
---

# Phase 154 Plan 02: The Control-Contract Seam — Rebuild/Interaction Contract Summary

**`Capability.@enforce_keys` now requires both `:rebuild` and `:interaction` (the one structurally-impossible part of CTRL-05), doctor gains a `capability_rebuild_findings/1` warning, and the capability map / support matrix / changelog all surface rebuild cost — plus two pre-existing hardcoded `manifest_schema_version` literals fixed along the way.**

## Performance

- **Duration:** ~70 min
- **Tasks:** 3
- **Files modified:** 33

## Accomplishments
- `Crosswake.Manifest.Types.Capability`'s `@enforce_keys` widened to `[:id, :version, :rebuild, :interaction]`, and `new_capability/1`'s tolerant compatibility-path defaults flipped to fail-closed `:native_required` (rebuild, D-51) and least-claiming `:fire_and_forget` (interaction, D-54) — in that order, per D-51's explicit "harden before enforce" sequencing.
- All 15 `capability_catalog/0` entries and both `compatibility_capability_attrs/2` branches now declare an explicit `interaction` value in the committed literal, with `share` declaring `:fire_and_forget` as the D-54 honesty-forcing case (it returns a request acknowledgement, not a completion).
- `manifest_schema_version` bumped `1.0.0` -> `1.1.0`; all five committed JSON fixtures regenerated via scoped patches (not full `gen_manifest.exs`/`crosswake.contract.gen` regenerations where those would pull in unrelated drift), and the two `bridge_contract_vectors.json` mirror copies remain byte-identical to the canonical one.
- `Crosswake.Doctor.capability_rebuild_findings/1` closes the one genuinely missing CTRL-05 leg (D-49): a `:warning`-severity `bridge.capability.native_rebuild_required` finding names the route, capability, and rebuild class for any non-`:none` capability declared on an active route, with a hint that branches on native vs companion rebuild path.
- `guides/capability_map.md` gains a Rebuild column across all 21 rows (`Crosswake.CapabilityMap.Row` gains an `enforce_keys`'d `:rebuild` field); `guides/support_matrix.md` gains an Interaction-Class Legend recording the schema bump as `compatibility-bump only`; `CHANGELOG.md`'s Unreleased section carries the `### Upgrade Impact` entry; and a new derivability assertion in `release_boundaries_test.exs` proves the locked 4-string Upgrade Impact vocabulary is total over `RebuildPolicy.classify/2`'s verdict domain.
- Discovered and fixed two independently hardcoded `manifest_schema_version: "1.0.0"` literals (`Crosswake.Shell.Activation.target_from_request/1`, `Crosswake.Compatibility.bridge_target/1`) that silently diverged from the real schema constant the instant it was ever bumped, breaking route activation and bridge-request compatibility checks project-wide — both now read a new `Crosswake.Manifest.Types.manifest_schema_version/0` public accessor.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make rebuild and interaction class unconstructable-without** - `a0392b25` (feat)
2. **Task 2: Give doctor a capability-level rebuild finding** - `491a08ea` (feat)
3. **Task 3: Surface rebuild class in the capability map, support matrix, and changelog vocabulary** - `68bcbe93` (docs)

_Note: this plan's `tdd="true"` tasks folded RED+GREEN into each task's single commit (regression coverage added alongside the fix), matching Plan 01's precedent — not split into separate test/feat commits._

## Files Created/Modified

**Core contract:**
- `lib/crosswake/manifest/types.ex` - `Capability.@enforce_keys` widened; `:interaction` field, type, and `to_map/1`/`format_interaction/1` serialization added; `@manifest_schema_version` bumped to `1.1.0`; new `manifest_schema_version/0` public accessor
- `lib/crosswake/manifest/builder.ex` - all 15 catalog entries + both `compatibility_capability_attrs/2` branches declare `interaction:` explicitly
- `lib/crosswake/compatibility/compatibility.ex`, `lib/crosswake/shell/activation.ex` - fixed hardcoded `manifest_schema_version: "1.0.0"` literals to read the new accessor
- `lib/mix/tasks/crosswake.contract.gen.ex` - hardcoded vectors/docs-snippet schema literal bumped to `1.1.0`

**Doctor:**
- `lib/crosswake/doctor/doctor.ex` - `capability_rebuild_findings/1` + `capability_rebuild_finding/2` + label/hint helpers, folded into the `phase_154_findings` accumulation

**Guides:**
- `lib/crosswake/capability_map.ex`, `lib/crosswake/capability_map/renderer.ex` - `Row.:rebuild` field + Rebuild column
- `lib/crosswake/support_matrix/renderer.ex` - Interaction-Class Legend section
- `guides/capability_map.md`, `guides/support_matrix.md` - regenerated via their renderers
- `CHANGELOG.md` - Unreleased `### Upgrade Impact` entry

**Fixtures (regenerated):**
- `examples/ios_shell_host/Fixtures/crosswake_manifest.json`, `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json` - `interaction`/schema-version scoped patch
- `test/fixtures/bridge_contract_vectors.json` + both native mirror copies, `docs/_contract_snippet.md` - schema `1.1.0`
- `test/fixtures/proof/phase52_operator_inspection.json`, `test/fixtures/proof/phase52_publish_readiness.json` - regenerated golden fixtures

**Tests:** `test/crosswake/manifest/builder_test.exs`, `test/crosswake/manifest/manifest_test.exs`, `test/crosswake/doctor/doctor_test.exs`, `test/crosswake/doctor/formatter_test.exs`, `test/crosswake/compatibility/compatibility_test.exs`, `test/crosswake/proof/phase64_runtime_line_policy_test.exs`, `test/crosswake/operator_inspection/formatter_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`, `test/crosswake/capability_map/capability_map_test.exs`, `test/crosswake/capability_map/renderer_test.exs`, `test/crosswake/guides/release_boundaries_test.exs`

## Decisions Made
- Assigned `interaction` values for the 9 catalog entries not explicitly named in the plan (`deep_link`, `media_capture`, `scanner`, `document_scan`, `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, `reconciliation_evidence`) by domain judgment against D-54's honesty framing — documented inline as source comments in `builder.ex`.
- Mapped 9 of 21 `guides/capability_map.md` rows to their real `capability_catalog/0` rebuild value (asserted in `capability_map_test.exs`); the other 12 narrative-only rows (which don't correspond to a live manifest capability) got a deliberate, documented judgment call.
- Corrected an initially-inaccurate sentence in the Interaction-Class Legend that would have falsely claimed the Capability Families table shows a per-row interaction column — it doesn't (out of this plan's scope), and the guide's whole purpose is preventing exactly that kind of overclaim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed two hardcoded `manifest_schema_version: "1.0.0"` literals broken by the schema bump**
- **Found during:** Task 1 (running the full suite after the schema bump)
- **Issue:** `Crosswake.Shell.Activation.target_from_request/1` and `Crosswake.Compatibility.bridge_target/1` both hardcoded `manifest_schema_version: "1.0.0"` as a synthetic "shell target" value used purely to evaluate the Elixir-internal compatibility floor check (`compatible_version?/2`, target >= required). Bumping the real schema constant to `1.1.0` made every route activation and bridge request in the suite fail closed with a spurious `compatibility_mismatch`, since `1.0.0 < 1.1.0`. This was a latent bug present since the schema was first introduced — it had simply never been exercised because the schema had never been bumped before.
- **Fix:** Added `Crosswake.Manifest.Types.manifest_schema_version/0` as a public accessor for the existing `@manifest_schema_version` module attribute, and pointed both hardcoded call sites at it, so this synthetic value can never again silently diverge from the real schema constant on a future bump.
- **Files modified:** `lib/crosswake/manifest/types.ex`, `lib/crosswake/shell/activation.ex`, `lib/crosswake/compatibility/compatibility.ex`, plus test updates in `test/crosswake/compatibility/compatibility_test.exs` (3 `Target` fixtures switched from the hardcoded literal to the new accessor)
- **Verification:** Full suite (`mix test --exclude requires_example_host --exclude advisory_only --exclude engine_present --exclude collateral_binaries`) went from multiple `compatibility_mismatch` failures to 0 failures.
- **Committed in:** `a0392b25` (Task 1 commit)

**2. [Rule 3 - Blocking] Regenerated three stale golden-JSON proof fixtures instead of hand-patching them**
- **Found during:** Tasks 1 and 3 (after the schema bump and the CHANGELOG Unreleased edit)
- **Issue:** `test/fixtures/proof/phase52_operator_inspection.json` and `test/fixtures/proof/phase52_publish_readiness.json` are byte-identical golden fixtures compared against live `mix crosswake.inspect --format json` / `mix crosswake.doctor --check-publish --format json` output; both drifted from the schema bump (the former) and the new CHANGELOG `### Upgrade Impact` entry changing `unreleased_subsections` (the latter).
- **Fix:** Ran the exact same setup/normalization steps the proof tests themselves use (`ExUnit.CaptureIO` capturing the mix task, then the test's own `crosswake_version`/`version`-detail normalization) via a throwaway script, and overwrote each fixture with the normalized live output — never hand-edited the JSON.
- **Files modified:** `test/fixtures/proof/phase52_operator_inspection.json`, `test/fixtures/proof/phase52_publish_readiness.json`
- **Verification:** Both diffs confirmed minimal and semantically correct before/after (`manifest_schema_version` 1.0.0→1.1.0 in the first; `unreleased_subsections` gaining `"Upgrade Impact"` as its first entry in the second); `mix test test/crosswake/proof/phase52_operator_truth_test.exs` green.
- **Committed in:** `a0392b25` (operator_inspection fixture, Task 1) and `68bcbe93` (publish_readiness fixture, Task 3)

**3. [Rule 3 - Blocking] Scoped manifest fixture patch instead of full `gen_manifest.exs` regeneration**
- **Found during:** Task 1 (regenerating the two committed example-host manifest fixtures)
- **Issue:** Running `gen_manifest.exs` against the current router reproduced Plan 01's exact finding: an ~850-line diff pulling in ~2 months of unrelated router drift (routes from Phases 149-152 the checked-in fixtures never caught up to), which would have buried this plan's actual change (interaction fields + schema bump) inside unrelated out-of-scope drift.
- **Fix:** Reverted the full regeneration (`git checkout --`) and applied a narrow Python-scripted patch instead: bumped `manifest_schema_version` to `1.1.0` in both the root and `compatibility` blocks, and inserted an `interaction` key immediately after each capability's `rebuild` key, for all 16 registry entries (15 public + the `camera` compatibility entry). Verified byte-identical between the two host fixtures after patching, matching what a scoped regeneration of only the affected keys would produce.
- **Files modified:** `examples/ios_shell_host/Fixtures/crosswake_manifest.json`, `examples/android_shell_host/app/src/main/assets/crosswake_manifest.json`
- **Verification:** `git diff --stat` showed a 20-line diff per file (not ~850); both files remain byte-identical to each other; `python3 -c "import json; json.load(...)"` confirms valid JSON; all Task 1 acceptance-criteria greps pass.
- **Committed in:** `a0392b25` (Task 1 commit)

---

**Total deviations:** 3 auto-fixed (1 bug fix, 2 blocking-issue fixes)
**Impact on plan:** All three were necessary to complete the plan's own stated verification bar (`mix test --exclude requires_example_host --exclude advisory_only` green) without leaving broken production code or buried unrelated drift in the diff. No scope creep — the pre-existing `validator_test.exs` temp-file flakiness discovered along the way was logged to `deferred-items.md` and explicitly NOT fixed (out of scope, unrelated to this plan).

## Known Stubs

None. Every behavior this plan claims (enforce-keys construction failure, doctor finding emission, guide rendering) is backed by a passing automated test exercised in this session, not a hardcoded/mocked value.

## Issues Encountered
- `validator_test.exs`'s "json rendering is deterministic..." test collides with stale `crosswake-manifest-*.json` files left in `$TMPDIR` from unrelated prior sessions (no `on_exit` cleanup in the test) — pre-existing, unrelated to this plan, logged to `.planning/phases/154-the-control-contract-seam/deferred-items.md` rather than fixed (out of scope).
- Discovering the two hardcoded `manifest_schema_version` literals required tracing every `%Target{}` construction site in the codebase (not just the ones the plan's `<read_first>` named), since the schema bump's blast radius extended beyond the manifest/doctor/builder files the plan scoped Task 1 to.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- PR #1b (per D-76's sequencing) is complete and verified: `mix compile --warnings-as-errors` exits 0; `mix test --exclude requires_example_host --exclude advisory_only` is green (1089 tests, 0 failures); all five committed JSON fixtures regenerated and the native mirror copies byte-identical to the canonical one; `mix crosswake.doctor` confirmed emitting rebuild guidance against the real reference host.
- `Capability.interaction` and the widened `@enforce_keys` are now load-bearing for later Phase 154 plans (`Bridge.push/3`, the catalog guard, HRDN-01 migration) — any new capability construction site must supply both `:rebuild` and `:interaction` going forward.
- No blockers for subsequent Phase 154 plans. The one open non-blocking item (`validator_test.exs` temp-file hygiene) is tracked in `deferred-items.md`, not this plan's scope.

## Self-Check: PASSED

All files listed under "Files Created/Modified" confirmed present on disk; all 3 task commit hashes (`a0392b25`, `491a08ea`, `68bcbe93`) confirmed present in `git log --oneline --all`.

---
*Phase: 154-the-control-contract-seam*
*Completed: 2026-07-29*
