# Phase 171: Version/Authority Split - Research

**Researched:** 2026-09-17
**Domain:** GitHub Actions release-graph gating + Elixir candidate-identity validation (Crosswake's homegrown release pipeline)
**Confidence:** HIGH (all core claims are direct reads of the target files this session; a small number of ambiguous classifications are flagged, not guessed)

## Summary

Phase 171 has two halves that MUST land in one PR (roadmap-locked, not re-litigated here): a new
structural CI check (`release.publish_gate.no_bare_version_literal`, MSG-04/MSG-05) that proves the
"bare version literal in a publish gate" defect class is now impossible, and the actual fix
(WELD-01..08) that removes every live version-literal gate and replaces it with a derived
`approved_version`. This research locates every one of the 18 files SUMMARY.md's prior pass counted
(confirmed here as exactly 8 `lib/` modules + 6 scripts + 4 workflows), classifies each occurrence,
and pins down the three mechanical seams the fix hangs off: `approved-release-guard`'s existing
receipt-output idiom, `release-please`'s own already-dynamic `outputs.version`, and the
`check_release_workflow_integrity.exs` roster-ID registration pattern.

**Key structural finding:** `needs.release-please.outputs.version` is **already dynamic** — it comes
straight from `googleapis/release-please-action`, not from a Crosswake literal. The weld is entirely
on the *comparison* side: four `if:` clauses compare that already-correct dynamic value against the
bare string `'0.2.1'`. WELD-03's fix is therefore narrow and mechanical: change the right-hand side of
each comparison from `'0.2.1'` to `needs.approved-release-guard.outputs.approved_version`, once that
output exists (WELD-02). The harder, higher-blast-radius part of this phase is NOT the workflow YAML —
it is the eight `lib/` modules, several of which have never been exercised past `0.2.1` and hardcode it
as a pattern-match clause (not just a comparison), which is a different code shape to fix than an `if:`
string equality.

**Primary recommendation:** Sequence the fix bottom-up: (1) derive `approved_version` in
`approved-release-guard` from the same three sources the guard already cross-checks
(`mix.exs`, the Android `build.gradle.kts`, `.release-please-manifest.json`) instead of hardcoding
`"0.2.1"` in the match; (2) thread that single derived value through the four workflow `if:` gates
(mechanical); (3) fix the `lib/` modules from the leaves up — `Coordinate`, `Mirror`, `Identity`,
`Cleanroom` first (they are called by, not callers of, `Workflow`/`ReleaseCandidate`), then
`ReleaseCandidate`/`Workflow`/`ReleaseStatus`/the Mix task; (4) update
`check_release_workflow_integrity.exs`'s OWN internal self-assertions (it currently asserts several
of its own checks against the literal `'0.2.1'` pattern it will need to stop expecting) in the same
PR, since several of its existing checks (not just the tripwire) will start failing the moment WELD-03
lands unless they are also generalized; (5) delete the tripwire and land the new check's non-vacuity
proof, reusing the exact fixture idiom `phase168_release_version_weld_test.exs` already established.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Merge-identity authority (head/tree/base/receipt binding) | CI / GitHub Actions (`approved-release-guard` job) | — | Already exact and correct; WELD-08 requires it stay untouched by this phase |
| Version derivation for the approved candidate | CI / GitHub Actions (`approved-release-guard` job) | — | Must read the same three declared-version sources the guard already cross-checks (mix.exs, gradle, manifest), not re-invent a fourth source |
| Publish-gate comparison (`if:` clauses) | CI / GitHub Actions (`release-please.yml`) | — | Pure YAML boolean logic; consumes `approved_version` output, does not compute it |
| Candidate/receipt/rollup domain validation | Application / Elixir (`lib/crosswake/release_candidate/*`, `lib/crosswake/release_status.ex`) | — | Business rules for what counts as a valid, self-consistent candidate; independent of GitHub Actions syntax |
| Structural CI self-audit (the scanner) | CI / GitHub Actions script (`script/check_release_workflow_integrity.exs`) | Application (shares Elixir runtime) | A static-analysis tool over the workflow YAML/Elixir files, run as a CI step; must itself be updated when the files it inspects change shape |
| Weld inventory record | Documentation / `.planning/` | — | A committed, in-repo table; not code, but gates phase closure per success criterion #5 |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MSG-04 | `release.publish_gate.no_bare_version_literal` fails when any publish-gating `if:` clause contains a bare version literal | See "The New Check" section — reuses the existing scanner's `job_if`/`includes?` helpers and roster-ID pattern |
| MSG-05 | The new check is proven non-vacuous against a pre-repair fixture | See "Non-Vacuity Proof Pattern" — `phase168_release_version_weld_test.exs` is the exact idiom to copy |
| WELD-01 | Weld inventory of all 18 files, classified, committed in-repo | See "The Weld Inventory" — full table below, all 18 files enumerated with line numbers and evidence |
| WELD-02 | `approved-release-guard` emits `approved_version` bound into the existing receipt | See "approved-release-guard" section — exact lines to add, and where the value must be derived from |
| WELD-03 | Four `if:` gates compare against `approved_version`, not a literal | See "release-please.yml Publish Gates" — verbatim before/after for all four clauses |
| WELD-04 | `Crosswake.ReleaseCandidate.Workflow`'s `@coordinates`/`@dependencies` become a function of input version | See "Workflow Module" section — current shape, callers, and the arity change needed |
| WELD-05 | `cleanroom.ex:236` weld removed | See "cleanroom.ex:236" section — exact fix (delete the conjunct, not replace it) |
| WELD-06 | Any semver version runs the full graph, no workflow edit | Covered across all sections; the CLI-entrypoint welds (`release_candidate.ex:100`, `crosswake.release.candidate.ex:50`) are the two easiest-to-miss blockers of this criterion, documented under "Additional CLI-Entrypoint Welds" |
| WELD-07 | The tripwire is deleted (not disabled) in the same commit that lands the successor as merge-blocking | See "Tripwire Deletion and Merge-Blocking Registration" — confirms NO separate branch-protection registration step is needed |
| WELD-08 | Identity gate stays exact after the version gate generalizes | See "approved-release-guard" — the head/tree/base/receipt checks are structurally untouched by this phase's fix; only the `linked_candidate` boolean's version literal changes |
| DOC-05 | One word per domain concept; "manifest" collision resolved | See "DOC-05: Manifest Terminology" section |
</phase_requirements>

## The Weld Inventory (WELD-01 — the highest-value deliverable)

**Provenance of "18 files":** SUMMARY.md (`.planning/research/v23/SUMMARY.md:96`) states the prior
orchestrator pass found `0.2.1` "across 18 files (8 `lib/` modules, 6 scripts, 4 workflows)" but does
NOT enumerate them by name — no prior artifact lists the 18 files explicitly. This session's own
`grep -rln "0\.2\.1"` over `lib/`, `script/`, and `.github/workflows/` (excluding `test/`, `.planning/`,
`examples/`, docs) produces **exactly** 8 + 6 + 4 = 18 files, matching the count precisely:

- **8 `lib/` modules:** `release_candidate.ex`, `release_candidate/cleanroom.ex`,
  `release_candidate/coordinate.ex`, `release_candidate/identity.ex`, `release_candidate/mirror.ex`,
  `release_candidate/workflow.ex`, `release_status.ex`, `mix/tasks/crosswake.release.candidate.ex`
- **6 scripts:** `check_release_version_truth.exs`, `check_release_workflow_integrity.exs`,
  `guarded_hex_publish.sh`, `release_candidate/android_publication.sh`, `release_candidate/ios_mirror.sh`,
  `verify_ios_mirror_backfill.sh`
- **4 workflows:** `crosswake-ci.yml`, `hex-publish.yml`, `ios-mirror-backfill.yml`, `release-please.yml`

This is treated as the authoritative resolution of divergence #3 that SUMMARY.md itself flagged as
"genuinely open" (line 216) — the count matches exactly, and every hit below was read directly this
session (not re-derived from the prior grep-only pass).

### Classification key
- **live gate** — controls whether a job/function proceeds; must be fixed as part of WELD-01..08.
- **fixture** — a test-only value, or a value bound to one specific historical event, safe to leave.
- **docstring** — prose/comment describing a past state; hygiene-only.
- **display string** — human-readable name/label/log text; does not gate anything.

### `lib/` modules (8 files)

| File:Line | Literal context (verbatim) | Classification | Evidence |
|---|---|---|---|
| `lib/crosswake/release_candidate.ex:100` | `defp validate_command_identity!("0.2.1", ref, output_dir)` — pattern-match clause; the fallback clause always raises for any other version | **live gate** | Any version besides the literal falls through to `validate_command_identity!(_version, _ref, _output_dir), do: raise(...)`. Blocks WELD-06 at the CLI entrypoint. |
| `lib/crosswake/release_candidate/cleanroom.ex:236` | `Map.fetch!(by_package, "crosswake").version == "0.2.1"` inside `validate_approved_artifacts!/1`'s `unless` guard | **live gate** | WELD-05's named target. Function already independently verifies package-set completeness (lines 233-235) — this conjunct is the only place a specific version is demanded. |
| `lib/crosswake/release_candidate/coordinate.ex:12,49,81,114,162,165` | `@candidate "0.2.1"`; five `unless X == @candidate, do: invalid!()` sites | **live gate** (5 sites, all in one file) — **caller status UNVERIFIED, see note** | `grep -rn "ReleaseCandidate.Coordinate" lib/ script/` returns **zero** production call sites this session — only `test/crosswake/release_candidate/coordinate_test.exs` references the module. This is either dead code or invoked dynamically in a way this grep missed. Flagging as **UNVERIFIED whether this module is live** — the planner must confirm before deciding whether fixing it is in-scope-required (if genuinely unreferenced, it may be a fixture/orphan rather than a true live gate; do not silently skip it either way, since an orphaned validator with the OLD literal reactivated later would reintroduce the weld). |
| `lib/crosswake/release_candidate/identity.ex:71` | `if consistent? and not String.ends_with?(coordinate, "@0.2.1"), do: invalid!()` in `normalize_coordinate!/2` | **live gate** | `consistent?` defaults to `true` (line 16); this fires on every default-path call. Fix: compare against the already-normalized `version` field (available in the same `normalize!/2` caller scope) instead of the literal suffix. |
| `lib/crosswake/release_candidate/identity.ex:128` | `defp version!("0.2.1", _consistent?), do: "0.2.1"` — a leading pattern-match clause ahead of the generic `is_binary(version)` regex clause | **live gate** | This clause exists ONLY to let `"0.2.1"` through when `consistent? == false`... but actually inspect: the generic clause at line 130 already accepts any `\d+\.\d+\.\d+` when `consistent? == false`, making this clause redundant for the `false` case; for `consistent? == true` there is NO matching clause below it except the catch-all `invalid!()`, so today `consistent?: true` accepts ONLY `"0.2.1"`. Fix: delete this clause; let `consistent? == true` reuse the same regex-based well-formedness check as `consistent? == false` (self-consistency is separately enforced elsewhere, e.g. `mirror.tag == "v#{normalized.version}"` at identity.ex:44, which already uses the *normalized* version, not a literal). |
| `lib/crosswake/release_candidate/mirror.ex:11,245,311,325,332` | `@candidate_version "0.2.1"`; used in two `input.version == @candidate_version` mode-dispatch guards and two tag-string interpolations | **live gate** (245, 311) + **functional/display** (325, 332 — interpolation, becomes correct automatically once the constant is removed and the real version threads through) | `script/release_candidate/ios_mirror.sh:52` calls into this exact constant via CLI arg `--version`; see also `mirror.ex:@baseline_version "0.2.0"` at line 10, which is a **different, legitimately fixed** historical baseline tag (do not conflate — see `ios_mirror.sh` baseline-mode note below). |
| `lib/crosswake/release_status.ex:10,146,258-260,267,273,278,283,299,362-363` | `@candidate_version "0.2.1"`, used in live-registry probe construction (`maybe_hex_live`, `maybe_ios_mirror_live`, `maybe_maven_live`) AND in human-readable report lines | **live gate** (10, 258-260, 267, 273, 278, 283, 299 — controls what version the registry probes check against) + **display string** (146 `"Exact 0.2.1 candidate (read-only):"`, 362-363 `"all three linked 0.2.1 coordinates are public"` / `"0.2.1 linked-coordinate state is..."`) | The live-gate sub-set determines which version's public artifacts get probed — must be derived at read time (likely from the manifest, same source as the guard), not compiled in as a module attribute. The display strings should read the same derived value rather than being separately hardcoded. |
| `lib/mix/tasks/crosswake.release.candidate.ex:4,7,9,50` | `@shortdoc`/`@moduledoc` text (4,7,9 — human-readable, includes an example CLI invocation); `opts[:version] == "0.2.1"` in `parse!/1`'s validity conjunction (line 50) | **docstring** (4, 7, 9) + **live gate** (50) | Line 50 is the OTHER CLI-entrypoint weld alongside `release_candidate.ex:100` — the Mix task itself refuses any `--version` besides the literal before `Crosswake.ReleaseCandidate.run!/1` is ever called. Both must change together (line 50 gates, then the same value flows into the pattern-matched line 100). |

### Scripts (6 files)

| File:Line | Literal context (verbatim) | Classification | Evidence |
|---|---|---|---|
| `script/check_release_version_truth.exs:8` | `# PR #158 came to propose an already-published 0.2.1, whose merge would have` | **docstring** | Comment narrating a specific historical PR incident; the script's actual logic (read this session, lines 1-40) is already fully version-generic (`@components` maps paths to tag prefixes, never hardcodes a version value). No fix needed beyond optional comment cleanup. |
| `script/check_release_workflow_integrity.exs:92,346,1106,1130` | `"release.version_weld.gates_match_declared_version"` (roster ID, line 92); the tripwire's own doc-comment (346); `includes?(job_if(jobs, job), "needs.release-please.outputs.version == '0.2.1'")` inside `release.approval.linked_graph`'s `guarded_children?` check (1106); the `release.approval.linked_graph` failure detail string naming "Hex/iOS/Android 0.2.1 children" (1130) | **live gate** (92 — the tripwire itself, target of WELD-07 deletion) + **live gate, self-referential** (1106 — this scanner check will start FAILING the moment WELD-03 changes the literal to `approved_version`, unless updated in the same PR) + **docstring** (346) + **display string** (1130, part of a check's failure message) | **This is the sharpest hazard in the whole phase.** `release.approval.linked_graph` (a DIFFERENT, currently-passing check from the tripwire) asserts the graph contains the literal string `'0.2.1'` inside the `if:` clause as a correctness condition. If WELD-03 changes the workflow's `if:` text without also updating this assertion, `release.approval.linked_graph` goes from a true positive to a false negative in the same PR — a real regression masquerading as a passing check going red for the wrong reason. Must update `1106`'s `includes?(...)` string to match the new `approved_version`-based comparison text, and reword `1130`'s detail string away from the specific literal. |
| `script/check_release_workflow_integrity.exs:483` | `includes?(full, "mix crosswake.release.candidate --version 0.2.1 --ref <40sha>")` | **live gate, self-referential** | Asserts the candidate-receipt artifact's embedded terminal text contains this exact literal invocation string. Once `crosswake.release.candidate.ex`'s `@moduledoc`/`@shortdoc` example text is generalized (see lib table above), this assertion needs to match the new (version-parametric) example text or be relaxed to a pattern. |
| `script/check_release_workflow_integrity.exs:1244` | `~s([ "$RELEASE_VERSION" = "0.2.1" ])` inside a list of `pinned_constants`/`compared?` assertions (context: `hex-publish.yml`'s recovery job structural check) | **live gate, self-referential** | Same hazard class as 1106 — asserts `hex-publish.yml`'s recovery path still contains the literal comparison; will need updating in lockstep with `hex-publish.yml`'s own fix (see workflow table below). |
| `script/check_release_workflow_integrity.exs:1345,1347` | Asserts `android_publication.sh` contains the exact POM path string `.../0.2.1/crosswake-shell-core-android-0.2.1.pom` (1345) and does NOT contain a differently-shaped coordinate string (1347) | **fixture-like, but UNVERIFIED whether version-parametric** | This asserts the CURRENT exact 0.2.1 Maven coordinate string is present. If `android_publication.sh`'s own `--version` handling generalizes (see below), this assertion must generalize too (e.g. assert the pattern with an interpolated `$VERSION` rather than the literal `0.2.1`) or it will start failing the first time a non-0.2.1 candidate is rehearsed through this checked path. Flagging as needing the planner's explicit design decision on how deep the scanner's own self-checks need to go here. |
| `script/guarded_hex_publish.sh:140` | `if [ "$PACKAGE" != "crosswake" ] || [ "$VERSION" != "0.2.1" ]; then` | **live gate** | Direct blast-radius match for WELD-06 — this script is the actual `mix hex.publish` wrapper; it refuses to publish any package/version pair besides exactly `crosswake`/`0.2.1` today. |
| `script/release_candidate/android_publication.sh:18,21,46,60,72,100,105` | `PUBLIC_POM="https://repo1.maven.org/.../0.2.1/....pom"` (18, built from a literal, not `$VERSION`); usage text (21); `[ "$VERSION" = "0.2.1" ] \|\| usage` (46); `grep -q 'version = "0.2.1"' .../build.gradle.kts` (60); OK/FAIL echo text naming "0.2.1" (72, 100, 105) | **live gate** (18, 46, 60) + **display string** (21, 72, 100, 105) | Line 18's URL is built from the literal rather than `$VERSION` even though `$VERSION` is already an accepted CLI arg elsewhere in the same script — an easy, contained fix (interpolate `$VERSION` into the existing URL template). Line 60's `grep -q 'version = "0.2.1"'` must become `grep -q "version = \"$VERSION\""`. |
| `script/release_candidate/ios_mirror.sh:46,52` | `[ "$VERSION" = "0.2.0" ] \|\| usage` (baseline mode, line 46); `[ "$VERSION" = "0.2.1" ] \|\| usage` (candidate mode, line 52) | Line 46: **fixture** (0.2.0 is the fixed, permanently-historical pre-candidate baseline tag — NOT part of this weld; do not touch) — Line 52: **live gate** | Confirmed by reading the mode dispatch: `baseline` mode inspects the state *before* any candidate existed (a fixed reference point that never changes), while `candidate` mode inspects the release currently under construction (which must generalize). Conflating these two would be a classification error. |
| `script/verify_ios_mirror_backfill.sh:6,49` | Usage-example comment (6): `script/verify_ios_mirror_backfill.sh --mode candidate --version 0.2.1 --ref <40sha>`; doc text (49): `requires exact 0.2.1 and a full 40-SHA and performs only a porcelain dry-run` | **docstring** (both) | Read the surrounding function this session — these are comment/usage-string only; no runtime comparison against the literal was found in this file's logic. Verify at plan time that no other line in this file (outside the two grepped lines) contains a live comparison — this file was read at the two hit lines only, not exhaustively. |

### Workflows (4 files)

| File:Line | Literal context (verbatim) | Classification | Evidence |
|---|---|---|---|
| `.github/workflows/crosswake-ci.yml:292` | `echo 'The approval receipt remains operator-owned: mix crosswake.release.candidate --version 0.2.1 --ref <40sha> --output-dir <new-directory>.'` | **display string** | A `$GITHUB_STEP_SUMMARY` echo line, human-readable operator guidance only; does not gate anything. |
| `.github/workflows/hex-publish.yml:45,68,73,78,192,308` | `default: '0.2.1'` (workflow_dispatch input default, 45); three `description:` strings referencing "root 0.2.1 recovery" (68,73,78); `if [ "$RECOVERY_PACKAGE" = "crosswake" ] && [ "$EXPECTED_VERSION" = "0.2.1" ]` (192); `[ "$RECOVERY_VERSION" = "0.2.1" ]` (308) | **live gate** (45 — a misleading stale default that operators will unknowingly accept; 192, 308) + **docstring** (68, 73, 78 — input descriptions) | Lines 192 and 308 are inside the manual recovery-dispatch path (`workflow_dispatch`), gating whether a recovery publish is permitted for a given package/version pair — direct WELD-06 blockers for recovery publishes of any future version. |
| `.github/workflows/ios-mirror-backfill.yml:27,107,147,288-293,336,431` | `description: '...0.2.0 iOS tag for baseline or a 40-character 0.2.1 candidate SHA.'` (27); `[ "${{ inputs.version }}" = "0.2.1" ] \|\| usage`-equivalent gate (107); `--version 0.2.1 --ref "$CANDIDATE_HEAD"` literal CLI arg (147); four negative-control assertions that `0.2.1`'s tag/Hex-release/Maven-POM/iOS-tag are NOT YET public (288-293); two more `[ "$RELEASE_VERSION" = "0.2.1" ]` gates (336, 431) | **docstring** (27) + **live gate** (107, 147, 336, 431) + **UNVERIFIED — needs planner decision** (288-293) | Lines 288-293 assert "the exact 0.2.1 artifacts are not yet public" — this reads as a **one-time pre-flight negative control specific to the original 0.2.1 recovery incident** (confirming a specific historical publish had not already happened before this exact backfill workflow ran). Flagging as ambiguous rather than guessing: if this input mode is retained ONLY to document/replay that one historical event, it is a **fixture**; if this mode is meant to be reusable for any future backfill, these four lines are **live gates** requiring the same `$VERSION`-interpolation fix as line 107. The planner must read the surrounding job name/trigger condition (not fully re-read this session past the two grepped occurrences) to decide before writing the fix task. |
| `.github/workflows/release-please.yml` | See dedicated section below — this is the file with the four named publish-gating `if:` clauses (WELD-03's primary target) plus the `approved-release-guard` job (WELD-02's target) | **live gate** (all identified occurrences) | Fully quoted below with line numbers. |

**Weld-inventory completeness note for the plan/verification artifact:** every row above must be
copied into the phase's committed weld-inventory table (success criterion #5) with its own
live-gate/fixture/docstring/display-string classification restated per-row (not just per-file) —
several files above have multiple, differently-classified occurrences, and the acceptance criterion
("zero remaining live-gate rows referencing a bare version literal") is checked at the occurrence
level, not the file level.

## `.github/workflows/release-please.yml` Publish Gates (WELD-03)

All four publish-gating `if:` clauses, quoted verbatim with current line numbers (re-grep before
writing the diff — SUMMARY.md itself warns these numbers drift as earlier phases land):

```yaml
# line 223 — publish-hex
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' && contains(fromJSON(needs.release-please.outputs.paths_released), '.') }}

# line 525 — publish-ios-core
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' && contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-ios') }}

# line 571 — publish-android-core
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' && contains(fromJSON(needs.release-please.outputs.paths_released), 'packages/crosswake-shell-core-android') }}

# line 728 — exact-public-proof
if: ${{ needs.approved-release-guard.outputs.linked_release == 'true' && needs.release-please.outputs.version == '0.2.1' }}
```

**Exact rewrite for all four** (only the middle conjunct changes; the identity gate
`linked_release == 'true'` and the path-containment conjuncts are untouched, satisfying WELD-08):

```yaml
needs.release-please.outputs.version == needs.approved-release-guard.outputs.approved_version
```

`needs.release-please.outputs.version` (declared at `release-please.yml:170`,
`version: ${{ steps.release.outputs.version }}`) is **already dynamic** — it is release-please-action's
own reported version for the root/Hex path, not a Crosswake literal. Nothing about this side of the
comparison needs to change; only the right-hand side does.

## `approved-release-guard` (WELD-02, WELD-08)

Full job read this session (`release-please.yml:29-150`). Current `outputs:` block:

```yaml
outputs:
  linked_release: ${{ steps.guard.outputs.linked_release }}
  approved_head: ${{ steps.guard.outputs.approved_head }}
  approved_tree: ${{ steps.guard.outputs.approved_tree }}
  merge_oid: ${{ steps.guard.outputs.merge_oid }}
  merge_parents: ${{ steps.guard.outputs.merge_parents }}
  merge_tree: ${{ steps.guard.outputs.merge_tree }}
  candidate_receipt: ${{ steps.guard.outputs.candidate_receipt }}
  candidate_run_id: ${{ steps.guard.outputs.candidate_run_id }}
  candidate_receipt_run_id: ${{ steps.guard.outputs.candidate_receipt_run_id }}
```

Add one line to the `outputs:` map:

```yaml
  approved_version: ${{ steps.guard.outputs.approved_version }}
```

**Where the value legitimately comes from — this is the crux of WELD-02.** The guard step (lines
58-150) already computes and cross-checks a `linked_candidate` boolean at lines 73-79:

```bash
linked_candidate=false
if grep -q '@version "0.2.1"' mix.exs &&
  grep -q 'version = "0.2.1"' packages/crosswake-shell-core-android/build.gradle.kts &&
  jq -e '."." == "0.2.1" and ."packages/crosswake-shell-core-ios" == "0.2.1" and ."packages/crosswake-shell-core-android" == "0.2.1"' .release-please-manifest.json >/dev/null; then
  linked_candidate=true
fi
[ "$linked_candidate" = "true" ] || exit 0
```

This is itself a live-gate weld (line 64's comment even names it: "the strict gate activates only for
the merge that changes all three linked coordinates to 0.2.1"). The fix generalizes this block to
extract the actual declared version from one of the three sources (the manifest's `"."` key is the
natural single source of truth, since it is what `release-please.outputs.version` itself derives from)
and assert all three agree with EACH OTHER rather than with a hardcoded string:

```bash
manifest_version=$(jq -er '."."' .release-please-manifest.json)
linked_candidate=false
if grep -q "@version \"${manifest_version}\"" mix.exs &&
  grep -q "version = \"${manifest_version}\"" packages/crosswake-shell-core-android/build.gradle.kts &&
  jq -e --arg v "$manifest_version" \
    '."." == $v and ."packages/crosswake-shell-core-ios" == $v and ."packages/crosswake-shell-core-android" == $v' \
    .release-please-manifest.json >/dev/null; then
  linked_candidate=true
fi
[ "$linked_candidate" = "true" ] || exit 0
```

Then, alongside the existing `emit_output` calls at lines 142-150, add:

```bash
emit_output "approved_version=$manifest_version"
```

**This is the only place `approved_version` should be computed.** It must NOT be independently
re-derived inside `publish-hex`/`publish-ios-core`/etc. — those jobs only ever compare, never derive,
preserving the same single-producer shape the guard already uses for `approved_head`/`approved_tree`.

**WELD-08 (identity gate stays exact):** every line in the guard from 81-140 (two-parent-merge shape,
tree-identity, artifact/receipt verification, CI-run cross-check) is untouched by this change — those
lines never reference `"0.2.1"` at all; only the version-consistency pre-check at lines 73-79 changes.
This is the concrete basis for a test asserting "the identity gate remains exact after the version
comparison generalizes" (success criterion #7): mutate ONLY the manifest version in a fixture receipt
while holding head/tree/base fixed, and confirm the guard still requires all the same identity
predicates it does today.

## `Crosswake.ReleaseCandidate.Workflow` (WELD-04)

Full module read this session (`lib/crosswake/release_candidate/workflow.ex:1-19` quoted verbatim):

```elixir
defmodule Crosswake.ReleaseCandidate.Workflow do
  @moduledoc false

  @children ~w(hex ios_mirror android ios_public_proof android_public_proof exact_public)a
  @public_children ~w(hex ios_mirror android)a
  @statuses ~w(success failed skipped)
  @coordinates %{
    hex: "hex:crosswake@0.2.1",
    ios_mirror: "swift:crosswake-shell-core-ios@0.2.1",
    android: "maven:io.crosswake:crosswake-shell-core@0.2.1"
  }
  @dependencies %{
    hex: [],
    ios_mirror: [],
    android: [],
    ios_public_proof: ~w(hex ios_mirror)a,
    android_public_proof: ~w(hex android)a,
    exact_public: @children -- [:exact_public]
  }
```

`@dependencies` has NO version content at all — it is a pure topology map (which children depend on
which) and does not need to change shape; WELD-04's "derives... from the release version rather than
frozen module attributes" applies specifically to `@coordinates`. The public function that consumes
`@coordinates` is `rollup!/1` (line 22), at line 37: `Enum.map(&Map.fetch!(@coordinates, &1))`.

**Only caller found this session:** `rollup!/1` is invoked by
`script/release_candidate/*` (rollup step in `release-please.yml`'s `linked-release-rollup` job, per
the `check_release_workflow_integrity.exs:1122` assertion
`includes?(rollup, "Crosswake.ReleaseCandidate.Workflow.evaluate_cli!()")`) — meaning there is likely
an `evaluate_cli!/0` wrapper not shown in the 60-line window read this session. **The planner must grep
for `evaluate_cli!` and any other public function in this module before finalizing the arity change** —
this research read only lines 1-60 of the file, not the full module, and the CLI wrapper's own
arg-parsing may itself need a version input threaded through if it does not already accept one.

**Fix shape:** change `rollup!/1`'s signature (or add a required key to its existing `input` map — it
already validates `input` via `exact_map?(input, ~w(approved_ref candidate_receipt children)a)` at
line 23) to require a `version` field, then compute coordinates inline:

```elixir
defp coordinates(version) do
  %{
    hex: "hex:crosswake@#{version}",
    ios_mirror: "swift:crosswake-shell-core-ios@#{version}",
    android: "maven:io.crosswake:crosswake-shell-core@#{version}"
  }
end
```

Success criterion #4's test shape ("calling it with two different versions and observing two different
results") maps directly onto this: `Workflow.rollup!(%{... version: "0.2.1", ...})` vs.
`Workflow.rollup!(%{... version: "0.2.2", ...})` should produce different `successful_coordinates`
strings while the pass/fail/rollup STATE logic (unchanged) stays identical.

## `cleanroom.ex:236` (WELD-05)

Full surrounding function read this session (`lib/crosswake/release_candidate/cleanroom.ex:218-240`):

```elixir
defp validate_approved_artifacts!(artifacts) when is_list(artifacts) do
  normalized =
    Enum.map(artifacts, fn artifact ->
      unless exact_map?(artifact, @approved_artifact_keys), do: invalid!()

      %{
        package: package!(artifact.package),
        version: version!(artifact.version),
        metadata_digest: sha!(artifact.metadata_digest),
        payload_digest: sha!(artifact.payload_digest)
      }
    end)

  by_package = Map.new(normalized, &{&1.package, &1})

  unless length(normalized) == length(Artifact.packages()) and
           map_size(by_package) == length(normalized) and
           Map.keys(by_package) |> Enum.sort() == Enum.sort(Artifact.packages()) and
           Map.fetch!(by_package, "crosswake").version == "0.2.1",
         do: invalid!()

  Map.new(Artifact.packages(), &{&1, Map.fetch!(by_package, &1)})
end
```

**What it is deciding:** whether a supplied list of "approved" package artifacts (the six-package
manifest the clean-room lane consumes) is well-formed — every expected package present exactly once
— AND, currently, that the core `"crosswake"` package's approved version is specifically `"0.2.1"`.

**Correct fix — delete the conjunct, do not replace it with a parameter:** the three preceding
conjuncts (`length(normalized) == length(Artifact.packages())`, `map_size(by_package) ==
length(normalized)`, sorted-key-set equality) already fully establish structural completeness; nothing
in this function's own responsibility is "assert a specific version" — that authority belongs to
`approved-release-guard`'s `approved_version` (WELD-02), one layer up, at the point the approved
manifest is produced. This function's job is internal consistency of what it's handed, not
re-asserting an external fact it isn't itself the source of truth for:

```elixir
unless length(normalized) == length(Artifact.packages()) and
         map_size(by_package) == length(normalized) and
         Map.keys(by_package) |> Enum.sort() == Enum.sort(Artifact.packages()),
       do: invalid!()
```

**Only caller found this session:** `script/verify_companion_cleanroom.sh:730` invokes
`Crosswake.ReleaseCandidate.Cleanroom.evaluate_cli!(System.argv())`. Phase 172 depends on this same
module/test-fixture set per the roadmap's explicit note — do not restructure `@approved_artifact_keys`
or the artifact shape beyond what this fix needs, since Phase 172 (per-package refs) builds on
whatever shape this phase leaves behind.

## Additional CLI-Entrypoint Welds (feeds WELD-06, found via lib/ table above)

Two call sites gate the actual command-line entrypoint used to generate a candidate receipt at all —
if either is missed, `mix crosswake.release.candidate --version 0.2.2 ...` fails before any workflow
YAML is even reached, silently defeating WELD-06 even after every other fix lands:

1. `lib/mix/tasks/crosswake.release.candidate.ex:50` —
   `... and opts[:version] == "0.2.1" and ...` inside `parse!/1`'s validity conjunction. Fix: replace
   with a semver-format regex check, e.g. `Regex.match?(~r/\A\d+\.\d+\.\d+\z/, opts[:version] || "")`.
2. `lib/crosswake/release_candidate.ex:100` —
   `defp validate_command_identity!("0.2.1", ref, output_dir) when is_binary(ref) and
   is_binary(output_dir) do` — a literal pattern-match head, with a catch-all fallback clause that
   always raises. Fix: change the guard to a format check instead of a literal match, e.g.
   `defp validate_command_identity!(version, ref, output_dir) when is_binary(version) and
   is_binary(ref) and is_binary(output_dir) do unless Regex.match?(~r/\A\d+\.\d+\.\d+\z/, version) and
   ... , do: raise(...) end`.

## Tripwire Deletion and Merge-Blocking Registration (WELD-07)

**File:** `script/check_release_workflow_integrity.exs`. The tripwire is registered via:
- Its check ID `"release.version_weld.gates_match_declared_version"` in the `@roster_ids` list
  (verified present at line 92 of the roster block read this session).
- Its implementing function `release_version_weld/2` (full body read, lines 361-393), which returns
  `check(id, boolean, detail)` — the same `check/3` idiom every other scanner rule uses.
- A comment block above it (lines 346-360) explicitly instructing: "When TODO-009 lands, retire this
  check deliberately along with the literals it guards. Do not weaken it to keep a bumped manifest
  green." — this is the phase's own prior authorization to delete it outright.

**How a check becomes merge-blocking in this repo — confirmed, not assumed:** the scanner
(`check_release_workflow_integrity.exs`) is invoked directly as a shell step inside the
`release-candidate-fixtures` job (`.github/workflows/crosswake-ci.yml:157`,
`run: elixir script/check_release_workflow_integrity.exs`), which exits non-zero if ANY roster check
fails. `release-candidate-fixtures` itself is listed as a `needs:` dependency of the umbrella
"conclude the governed proof graph" job (`crosswake-ci.yml:1652`), which is the actual required
GitHub status check enforced by branch protection (per Phase 165's decisions recorded in STATE.md:
"Bind ... to the checkout-free Crosswake CI umbrella"). **This means no separate branch-protection or
required-check registration step is needed for WELD-07** — the successor check
(`release.publish_gate.no_bare_version_literal`) becomes merge-blocking automatically the instant it
is added to the roster in the same scanner script, exactly the way the tripwire it replaces already
was. Confirmed by reading `script/list_merge_blocking_checks.py`: it enumerates GitHub job/context
names for branch-protection parity, and has NO knowledge of internal scanner check IDs — so there is
nothing in that producer-inventory contract to update for this phase.

**Mechanical deletion steps** (all inside `check_release_workflow_integrity.exs`, same commit as the
new check):
1. Remove `"release.version_weld.gates_match_declared_version"` from `@roster_ids`.
2. Remove the `release_version_weld/2` function definition and its call site.
3. Add the new check's ID to `@roster_ids` and implement its function (see "The New Check" below).
4. Update the OTHER self-referential assertions this same scanner makes about the literal `'0.2.1'`
   (documented in the weld-inventory table above at lines 1106, 1130, 1244, 1345, 1347) — these are
   NOT part of the tripwire being deleted, but they DO assert the pre-fix literal shape and will
   silently start failing (or worse, silently stop checking anything meaningful) once WELD-03 lands
   unless updated in lockstep.
5. `@roster_ids`'s own coverage test (`release.scanner.roster_exact`, referenced in the file's header
   comment) asserts the declared roster equals the emitted check-ID set exactly in both directions —
   this test will itself catch a mismatched add/remove, which is a useful built-in guardrail but not a
   substitute for doing steps 1-4 correctly.

## The New Check: `release.publish_gate.no_bare_version_literal` (MSG-04)

**Where it belongs:** same file (`check_release_workflow_integrity.exs`), same `check(id, bool, detail)`
idiom as every other rule. Reuse the existing helper functions already used by
`release_version_weld/2` and other checks in this file: `job_block/2` (extracts a named job's YAML
block), `job_if/2` (extracts a job's `if:` string). A minimal, generalizable rule:

```elixir
defp no_bare_version_literal(jobs) do
  offenders =
    @version_gated_jobs
    |> Enum.flat_map(fn job ->
      job
      |> then(&job_if(jobs, &1))
      |> then(&Regex.scan(~r/outputs\.version\s*==\s*'\d+\.\d+\.\d+'/, &1))
      |> Enum.map(&{job, &1})
    end)

  check(
    "release.publish_gate.no_bare_version_literal",
    offenders == [],
    if(offenders == [],
      do: "no publish-gating if: clause compares against a bare version literal",
      else: "bare version literal(s) found in publish-gating if: clauses: #{inspect(offenders)} — compare against approved_version instead"
    )
  )
end
```

`@version_gated_jobs` (`~w(publish-hex publish-ios-core publish-android-core exact-public-proof)`) is
already declared at the top of this file (used by the now-deleted tripwire) — reuse it verbatim; this
is also the literal list success criterion #3 names.

## Non-Vacuity Proof Pattern (MSG-05)

**Established idiom, confirmed by direct read of `test/crosswake/proof/phase168_release_version_weld_test.exs`
(full file structure read this session):**

- A `run/2` helper shells out to the real scanner via `System.cmd("elixir", [@scanner, workflow_path],
  env: [{"RELEASE_PLEASE_MANIFEST_PATH", manifest_path}])` — the scanner already supports overriding
  its manifest path via env var for exactly this purpose.
- `tmp_dir!/1` creates an isolated temp directory per test case (`System.tmp_dir!()` +
  `System.unique_integer/1`), registers `ExUnit.Callbacks.on_exit` cleanup — this is the fixture
  pattern to copy, not a new tmp-file idiom.
- `manifest_at!/2` writes a mutated COPY of `.release-please-manifest.json` with a different declared
  version, without touching the real repo file.
- A separate `mutate_job_version/3` (referenced, not fully read this session — confirm shape at plan
  time) produces a mutated COPY of the WORKFLOW file with one job's literal changed, proving the check
  catches drift in ANY of the four gated jobs individually, not just the manifest side.
- `line_for/2` parses scanner stdout for the specific `] OK: <id> -` / `] FAIL: <id> -` line shape —
  this is the same parsing contract `release_status.ex`'s consumer depends on (per the file's own
  code comment about the 169-01 ROSTER line ordering hazard) — reuse this exact line-matching
  approach, do not write a new stdout-parsing convention.

**For MSG-05 specifically**, the required proof is the INVERSE assertion from the old tripwire's test:
instead of proving the OLD check fires when the manifest and gates DIVERGE, prove the NEW check fires
when a PRE-REPAIR fixture of the workflow (i.e., a copy of `release-please.yml` with the literal
`'0.2.1'` still present in one of the four `if:` clauses, simulating "this phase's own fix was never
applied") is fed to the scanner. Concretely: `File.read!(@workflow) |> String.replace(new_approved_version_comparison, "== '0.2.1'")`
to reconstruct the pre-fix shape as a fixture, write it to a temp path, run the scanner against it, and
assert `release.publish_gate.no_bare_version_literal` FAILs. This is the literal meaning of success
criterion #1 ("runs against a pre-repair fixture ... and fails, proving it is non-vacuous").

## DOC-05: Manifest Terminology

`.planning/research/v23/DX.md:40-52` (read this session) identifies three distinct nouns sharing the
word "manifest" in this codebase:
1. **release manifest** — `.release-please-manifest.json` (the approval/version-identity artifact this
   phase's `approved_version` derivation reads from).
2. **runtime manifest** — Crosswake's own `Manifest` module / `crosswake_manifest.json` (adopter
   routes/capabilities; `doctor.ex`'s `manifest_contract` check) — unrelated to this phase.
3. **approved-manifest matrix** — the six-entry `MATRIX_APPROVED_MANIFEST` clean-room input (Phase 172
   territory, adjacent to `cleanroom.ex`'s `validate_approved_artifacts!/1` this phase touches).

**Scope for THIS phase:** every new or changed string this phase introduces that uses the word
"manifest" — in the `approved-release-guard` step's shell comments/output, in
`check_release_workflow_integrity.exs`'s new/changed check details, in the weld-inventory document
itself — must qualify which of the three it means ("release manifest", never bare "manifest"). This is
a copy-discipline requirement on NEW/CHANGED text only, not a retroactive rename of
`.release-please-manifest.json` itself or of `cleanroom.ex`'s existing field names.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deriving the approved version | A new script, a new artifact, or a second grep of mix.exs at a different layer | `approved-release-guard`'s existing manifest-read (`jq -er '."."' .release-please-manifest.json`), extended in place | One producer for one fact — the same principle already governing `approved_head`/`approved_tree`; a second computation path is exactly the "fact that should have been derived got hardcoded" root cause this milestone exists to remove |
| Proving the new check is non-vacuous | A hand-rolled subprocess/fixture harness | `phase168_release_version_weld_test.exs`'s exact `run/2` + `tmp_dir!/1` + `manifest_at!/2` idiom | Already proven correct in this repo; a second, slightly-different fixture harness is needless surface area to keep synchronized |
| Registering the new check as merge-blocking | A branch-protection API call, a new GitHub required-check entry, an edit to `list_merge_blocking_checks.py` | Nothing — inherited automatically via `release-candidate-fixtures` → the CI umbrella | Confirmed this session that check IDs inside the scanner are invisible to the required-check registration layer; adding registration machinery here would be solving a problem that doesn't exist |

**Key insight:** every mechanism this phase needs already exists in the repo in a slightly narrower
form (a receipt-output field, a scanner-roster entry, a fixture-test harness). The work is
generalization of existing idioms, not new infrastructure — consistent with the milestone thesis
("repair three architectural defects... never add new machinery").

## Common Pitfalls

### Pitfall 1: Fixing the workflow YAML while leaving the scanner's own self-assertions stale
**What goes wrong:** `release.approval.linked_graph` and other EXISTING (non-tripwire) checks inside
`check_release_workflow_integrity.exs` assert the literal `'0.2.1'` is present in specific job blocks
as a correctness condition (see weld-inventory line 1106 above). If WELD-03's YAML edit lands without
updating these assertions, CI either (a) goes red for a fixed graph (false regression, blocks the PR)
or (b) — worse — if the assertion is a loose substring check that happens to still match leftover text
elsewhere, silently stops checking what it claims to check (a Shape A/D vacuity variant, exactly what
this milestone's vacuity taxonomy exists to catch).
**Why it happens:** the scanner was written when the graph was genuinely fixed at one version; several
of its checks encode "the graph looks like the 0.2.1-specific shape" as their definition of correct,
not "the graph looks like a well-formed generalized shape."
**How to avoid:** grep `check_release_workflow_integrity.exs` for every remaining `0.2.1` occurrence
AFTER writing the WELD-03/04/05 diffs (not before), and update each one's assertion to match the new
shape, in the same commit.
**Warning signs:** any scanner check flipping from OK to FAIL (or silently continuing to pass with no
behavior change) immediately after the workflow/lib edits land, with no code-behavior justification.

### Pitfall 2: Treating `ios_mirror.sh`'s two version constants as the same weld
**What goes wrong:** `[ "$VERSION" = "0.2.0" ]` (baseline mode) and `[ "$VERSION" = "0.2.1" ]`
(candidate mode) look identical in shape (same file, same script, twelve lines apart) but are
semantically different: 0.2.0 is a permanently-fixed historical baseline tag that will never change,
while 0.2.1 is the currently-live candidate value that must generalize.
**Why it happens:** pattern-matching on "looks like a hardcoded version string" without reading what
each mode actually represents (SUMMARY.md's own stated Pitfall 1: "assuming a category based on shape
... rather than verifying function").
**How to avoid:** classify by function, as the weld-inventory table above does — read the mode
dispatch logic, not just the grep hit.

### Pitfall 3: An orphaned validator (`Coordinate` module) reactivating the weld later
**What goes wrong:** `lib/crosswake/release_candidate/coordinate.ex` has 5 live-gate-shaped
`unless X == @candidate, do: invalid!()` sites but NO production caller found this session. If this
phase's fix skips it (reasoning "it's dead code, out of scope") and a later phase wires it back in
without re-checking for the literal, the weld silently reappears in a module everyone believed was
already fixed.
**How to avoid:** the planner must explicitly confirm caller status (grep again at plan/execution time,
including dynamic dispatch patterns like `apply/3` or Mix task delegation this research's static grep
may have missed) before deciding to fix vs. explicitly document as "confirmed orphaned, tracked
separately." Either resolution is acceptable; silent omission is not.

### Pitfall 4: The identity.ex `version!/2` fix accidentally weakening self-consistency
**What goes wrong:** deleting the `version!("0.2.1", _consistent?)` clause and unifying both branches
onto the plain `\d+\.\d+\.\d+` regex is correct for FORMAT validation, but this must not be mistaken
for the ONLY consistency check needed — `normalize_coordinate!/2`'s `@0.2.1` suffix check (line 71)
enforces that every coordinate's embedded version matches the identity's own declared version. Fixing
one without the other leaves a self-consistency gap (coordinates could declare a different version
than `identity.version` while still passing format checks).
**How to avoid:** fix both together, and have `normalize_coordinate!/2` compare against the
ALREADY-NORMALIZED `version` value from the same `normalize!/2` call (available via closure or an
explicit parameter), not a second independent parse.

## Code Examples

### Reused non-vacuity fixture idiom (from `phase168_release_version_weld_test.exs`, confirmed working pattern)
```elixir
defp run(workflow_path, manifest_path) do
  System.cmd("elixir", [@scanner, workflow_path],
    stderr_to_stdout: true,
    env: [{"RELEASE_PLEASE_MANIFEST_PATH", manifest_path}]
  )
end

defp line_for(output, id) do
  output
  |> String.split("\n")
  |> Enum.find(&String.contains?(&1, "] OK: #{id} -"))
  |> case do
    nil -> output |> String.split("\n") |> Enum.find(&String.contains?(&1, "] FAIL: #{id} -"))
    line -> line
  end
end
```
Source: `test/crosswake/proof/phase168_release_version_weld_test.exs` (read directly this session).

### Existing dynamic value already available, no fix needed
```yaml
# release-please.yml:170 — already dynamic, sourced from release-please-action itself
version: ${{ steps.release.outputs.version }}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Version literal AND merge authority enforced by the same string comparison | Version derived once (`approved_version`), authority enforced independently by the existing head/tree/base/receipt chain | This phase (WELD-01..08) | The two properties become independently testable and independently correct; a future authority-model change cannot accidentally loosen version-safety and vice versa |
| `release.version_weld.gates_match_declared_version` (interim tripwire, 2026-09-15) | `release.publish_gate.no_bare_version_literal` (permanent structural check) | This phase (WELD-07, same commit) | The interim check only detected THIS specific drift (manifest vs. gates); the successor detects the general defect class (any bare version literal in any publish-gating `if:`), so a FIFTH such job added later is caught automatically |

**Deprecated/outdated:**
- `release.version_weld.gates_match_declared_version`: deleted, not disabled, per WELD-07 — its own
  code comment self-documents this as correct ("Do not weaken it to keep a bumped manifest green").

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Coordinate` module (`coordinate.ex`) has no production caller and may be dead code | Weld Inventory, lib/ table | If it IS live (e.g. invoked via a Mix task or dynamic dispatch this session's static grep missed), its 5 live-gate sites would be silently left welded, defeating WELD-06 for whatever path calls it |
| A2 | `ios-mirror-backfill.yml:288-293`'s negative-control assertions are a one-time historical fixture tied to the original 0.2.1 incident, not a reusable gate | Weld Inventory, workflows table | If this input mode is meant to be reused for future backfills, these 4 lines are live gates that would silently block or misfire on a non-0.2.1 backfill attempt |
| A3 | `Crosswake.ReleaseCandidate.Workflow` has an `evaluate_cli!/0`-shaped public wrapper beyond the 60 lines read this session, with its own CLI arg handling that also needs version threading | Workflow Module section | If the wrapper has its own hardcoded assumption not visible in the lines read, WELD-04's fix could be incomplete despite `rollup!/1` itself being correctly generalized |
| A4 | `script/check_release_workflow_integrity.exs`'s self-assertions at lines 1345/1347 (Android POM path checks) need to become version-parametric rather than staying pinned to 0.2.1 | Weld Inventory, scripts table | If the planner instead intentionally pins these as fixtures against one known-good historical build (a valid alternative design), leaving them un-generalized could be correct — this needs an explicit decision, not a default assumption either way |
| A5 | `mix.exs`'s own `@version "0.2.1"` (release-please's bump target) is correctly OUT of scope for this phase's weld fix, since it is the authoritative source `approved-release-guard` reads FROM, not a copy of it elsewhere | Weld Inventory intro | Extremely low risk — directly confirmed by reading `approved-release-guard`'s own grep against `mix.exs` as its input, not its output |

**If this table is empty:** N/A — five assumptions logged above, all flagged inline at point of use
rather than presented as verified fact.

## Open Questions (RESOLVED — see the Orchestrator Addendum at the end of this file)

> Both questions below were open when this section was written and were **resolved by direct
> inspection before planning began**. Their verified answers, with the commands and evidence, are in
> the `## Orchestrator Addendum` section at the end of this file, and the plans consume those
> resolutions as decisions D-171-C and D-171-D. The original wording is kept so the provenance of
> each answer stays legible.

1. **RESOLVED** (see Addendum, Open Question 1 — no production caller).
   **Does `Crosswake.ReleaseCandidate.Coordinate` need fixing in this phase, or is it confirmed dead code?**
   - What we know: no production caller found via static grep this session; the module's own tests
     exercise it in isolation.
   - What's unclear: whether a Mix task, a script, or dynamic dispatch invokes it outside what a plain
     `grep -rn "Coordinate\."` would surface.
   - Recommendation: the planner should run `grep -rn "Coordinate" lib/ script/ .github/` (broader than
     the module-qualified grep this session used) and/or ask the maintainer directly before deciding;
     if genuinely orphaned, note it explicitly in the weld-inventory table as "orphaned, not wired into
     any production path as of this phase" rather than silently omitting the file.

2. **RESOLVED** (see Addendum, Open Question 2 — live gate, currently unsatisfiable).
   **Are `ios-mirror-backfill.yml:288-293`'s negative-control lines a fixture or a live gate?**
   - What we know: they assert the specific 0.2.1 artifacts are NOT YET public, in a job whose
     surrounding trigger/name context was not fully re-read this session (only the two grepped lines).
   - What's unclear: whether this input mode is retained specifically to document the original 0.2.1
     recovery, or is a generically-reusable "verify nothing published yet" pre-flight for any future
     backfill.
   - Recommendation: read the full job definition surrounding these lines at plan time before
     classifying; do not guess based on the two-line grep excerpt alone.

## Environment Availability

Skipped — this phase is a pure code/workflow-YAML/Elixir-script change with no new external tool,
service, or runtime dependency. `elixir`, `mix`, `jq`, `gh`, `git` are all already load-bearing
dependencies of the existing (unmodified) pipeline this phase edits, not new requirements introduced
by this phase.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir's built-in test framework), `mix test` |
| Config file | `mix.exs` (`elixirc_paths`, deps) — no separate ExUnit config file found |
| Quick run command | `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` (mirrors `release-candidate-fixtures`'s own invocation, `.github/workflows/crosswake-ci.yml:151-156`) |
| Full suite command | `mix test` (repo-wide) plus `elixir script/check_release_workflow_integrity.exs` (the structural scanner, run as a separate non-ExUnit step) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MSG-04 | New check fails on a bare version literal in a publish-gating `if:` | unit (scanner subprocess) | `mix test test/crosswake/proof/phase171_no_bare_version_literal_test.exs` | ❌ Wave 0 (new file, pattern from `phase168_release_version_weld_test.exs`) |
| MSG-05 | New check fails against a pre-repair fixture of the workflow file | unit (fixture mutation) | same file as above, additional test case | ❌ Wave 0 |
| WELD-02 | `approved-release-guard` emits `approved_version` | integration (workflow-YAML structural assertion, no live GH Actions run needed) | `mix test test/crosswake/proof/phase171_approved_version_output_test.exs` (new) asserting the `outputs:` block and guard-step emit line | ❌ Wave 0 |
| WELD-03 | Zero bare-literal matches across the 4 gated `if:` clauses | unit (grep-shaped assertion, same as new check's own logic) | covered by MSG-04's test directly re-run against the real (fixed) `release-please.yml` | Covered by MSG-04's test |
| WELD-04 | `Workflow.rollup!/1` (or successor) produces different coordinates for two different versions | unit | extend `test/crosswake/release_candidate/workflow_test.exs` with a two-version comparison case | ✅ file exists, needs new test case |
| WELD-05 | `cleanroom.ex:236`'s literal no longer exists | unit + grep | extend `test/crosswake/release_candidate/cleanroom_test.exs`; add a grep-based regression assertion (`refute File.read!(@cleanroom_source) =~ ~s(== "0.2.1")`) | ✅ file exists, needs new test case |
| WELD-06 | A non-0.2.1 version runs the CLI entrypoint without error | unit | extend `test/mix/tasks/crosswake_release_candidate_test.exs` with a `--version 0.2.2`-shaped case | ✅ file exists, needs new test case |
| WELD-07 | Tripwire file/roster entry fully removed | unit (negative — asserts absence) | new assertion in `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` or a small dedicated file: `refute "release.version_weld.gates_match_declared_version" in roster_ids()` | ❌ Wave 0 |
| WELD-08 | Identity gate (head/tree/base) stays exact after the version generalizes | unit (fixture mutation on `approved-release-guard`'s logic, mirrored in an Elixir-side equivalent if one exists, or a scanner-fixture test analogous to `phase168`'s own coverage) | `mix test test/crosswake/proof/phase171_identity_gate_unchanged_test.exs` (new) | ❌ Wave 0 |
| DOC-05 | New/changed copy in this phase qualifies "manifest" | manual/review (not automatable — a wording convention, not a runtime behavior) | N/A — verified by phase-close reviewer reading the diff | N/A |

### Sampling Rate
- **Per task commit:** the quick-run command above (`release_candidate` + Mix-task test dirs, `--max-cases 1`, matching the existing `release-candidate-fixtures` CI job's own invocation).
- **Per wave merge:** `mix test` (full suite) plus `elixir script/check_release_workflow_integrity.exs` (the scanner itself, which is both a build artifact of this phase AND a verification tool for it).
- **Phase gate:** both commands green, PLUS a manual read confirming the weld-inventory table (WELD-01) has zero remaining "live gate" rows with a bare version literal, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase171_no_bare_version_literal_test.exs` — covers MSG-04, MSG-05, WELD-03, WELD-07 (new check + its non-vacuity proof + tripwire-absence assertion); pattern directly from `phase168_release_version_weld_test.exs`
- [ ] `test/crosswake/proof/phase171_approved_version_output_test.exs` — covers WELD-02, WELD-08 (guard output + identity-gate-unchanged regression)
- [ ] No new shared fixtures/conftest-equivalent needed — ExUnit's per-test `tmp_dir!`/`on_exit` pattern (already used by `phase168_release_version_weld_test.exs`) is copied per-file, not centralized
- [ ] Framework install: none — ExUnit ships with Elixir, already the repo's only test framework

## Security Domain

`security_enforcement` is absent from `.planning/config.json` (confirmed by reading the file this
session — only `nyquist_validation: true` was found), so per convention it is treated as enabled. This
phase is CI/release-pipeline plumbing, not an application-facing authn/input-validation surface, so
most ASVS categories do not apply; the relevant ones are supply-chain/integrity-adjacent.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No new auth surface; `approved-release-guard` continues to rely on `github.token`/`GH_TOKEN`, unchanged by this phase |
| V3 Session Management | no | N/A |
| V4 Access Control | yes (narrowly) | The `linked_release`/`approved_version` boolean/value pair IS the access-control decision for who may publish; WELD-08 exists specifically to keep this exact after generalization — see the "approved-release-guard" section above |
| V5 Input Validation | yes | Version-format validation (`\d+\.\d+\.\d+` regex) replaces literal-equality checks across every `lib/` module fixed in this phase — the fix must not loosen the format check to accept malformed input (e.g. a version with a pre-release suffix) unless that is an explicit, separately-confirmed decision |
| V6 Cryptography | yes (unchanged, verify no regression) | SHA-256 digest comparisons (`sha256sum`, `digest!/1`, `sha!/1`) throughout the identity/receipt chain are untouched by this phase; the fix must not introduce a new comparison path that bypasses these existing digest checks |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Version-comparison weakened to a substring/prefix match instead of exact-equality during the fix (e.g. `String.starts_with?` instead of `==`) | Tampering | Every replacement comparison in this research uses exact string equality or a bounded regex anchor (`\A...\z`), never a loose substring match — carry this forward into implementation |
| `approved_version` derived from an attacker-influenceable source (e.g. a PR title or branch name) rather than the merged manifest content itself | Spoofing | `approved_version` is derived strictly from `.release-please-manifest.json` content AT THE APPROVED HEAD, inside the same guard step that already verifies tree-identity for that exact commit — no new external input source is introduced |
| The generalized CLI/task version-format regex accepting non-semver strings that later break downstream `String.to_integer`/comparison logic | Tampering / Denial of Service | Anchor every replacement regex to `\A\d+\.\d+\.\d+\z` (no pre-release/build-metadata suffixes) unless the phase explicitly decides to support them — matches the existing (narrower) literal behavior's effective format constraint |

## Sources

### Primary (HIGH confidence — direct reads this session)
- `.github/workflows/release-please.yml` (lines 1-160, 220-230, 520-600, 720-870) — `approved-release-guard`, `release-please`, all four publish gates
- `.github/workflows/hex-publish.yml`, `.github/workflows/ios-mirror-backfill.yml`, `.github/workflows/crosswake-ci.yml` — grep + targeted reads
- `lib/crosswake/release_candidate.ex`, `lib/crosswake/release_candidate/{cleanroom,coordinate,identity,mirror,workflow}.ex`, `lib/crosswake/release_status.ex`, `lib/mix/tasks/crosswake.release.candidate.ex` — full or targeted reads of every `0.2.1` occurrence
- `script/check_release_workflow_integrity.exs`, `script/check_release_version_truth.exs`, `script/guarded_hex_publish.sh`, `script/release_candidate/{android_publication,ios_mirror}.sh`, `script/verify_ios_mirror_backfill.sh`
- `script/check_required_checks_registered.sh`, `script/list_merge_blocking_checks.py` — merge-blocking registration contract
- `test/crosswake/proof/phase168_release_version_weld_test.exs` — non-vacuity fixture idiom (full structural read)
- `.planning/todos/TODO-009-release-graph-welded-to-0-2-1.md`, `.planning/seeds/SEED-017-release-graph-version-generalization.md`
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`, `ROADMAP.md` (Phase 171/172/173 sections), `STATE.md`
- `.planning/research/v23/SUMMARY.md` (full divergence #3 + Phase B sections), `.planning/research/v23/PITFALLS.md` (Pitfall 4 taxonomy), `.planning/research/v23/DX.md` (manifest-collision section)
- `.planning/workstreams/quality-ratchet-release/VERIFICATION-CONVENTIONS.md`

### Secondary (MEDIUM confidence)
- None used — no WebSearch/external documentation was needed for this phase; every claim resolves to a repo-internal read.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: N/A — no new library/framework choices; this phase edits existing Elixir/YAML/bash
- Weld inventory: HIGH on all 18 files' occurrence-level classification except the 3 explicitly flagged UNVERIFIED items (Coordinate module's caller status, ios-mirror-backfill.yml:288-293's fixture-vs-gate status, and the Workflow module's un-read `evaluate_cli!` wrapper) — each flagged inline, not silently resolved
- Architecture (guard/gate mechanics): HIGH — every YAML/Elixir excerpt quoted verbatim from a direct read this session
- Pitfalls: HIGH on repo-specific findings (self-referential scanner assertions is a new finding this session, not previously documented anywhere in `.planning/`)

**Research date:** 2026-09-17
**Valid until:** ~14 days (workflow file line numbers are explicitly expected to drift as prior phases land per SUMMARY.md's own caveat; re-grep before writing the diff regardless of this file's age)

---

## Orchestrator Addendum — the two carried-forward open items, resolved (2026-09-17)

Both items the researcher and pattern-mapper flagged UNVERIFIED were resolved by direct inspection
before planning, so the planner writes tasks against facts rather than assumptions.

### Open Question 1 — `Crosswake.ReleaseCandidate.Coordinate` is orphaned. RESOLVED: no production caller.

Command run: `grep -rn "Coordinate" lib script test` (whole tracked tree, excluding the module's own file).

Result: the ONLY references to `Crosswake.ReleaseCandidate.Coordinate` anywhere outside
`lib/crosswake/release_candidate/coordinate.ex` are in
`test/crosswake/release_candidate/coordinate_test.exs`. The three `lib/crosswake/doctor/publish_readiness.ex`
hits are the unrelated English prose string "Coordinated deploy with updated Hex package"; the
`test/fixtures/proof/phase52_publish_readiness.json` hit is `generator_coordinate_parity`, a different
concept. The module exposes exactly one public function, `validate!/1` (line 47).

**Conclusion:** `Coordinate` is a validator that nothing in production calls. Its 5 live-gate-shaped
`0.2.1` sites are therefore not currently gating anything — they are a dormant weld. This is precisely
the hazard RESEARCH.md's own Pitfall 3 names ("an orphaned validator reactivating the weld later").

**Classification for the WELD-01 inventory:** NOT "live gate". Record it as its own row type —
`orphaned validator (no production caller; test-only)` — and say so in the table rather than
flattening it into one of the four original labels, which would misstate what the grep found.
Do not silently delete the module under cover of this phase: deleting dead code is a defensible change
but it is not what WELD-01..08 asked for, and bundling it would hide a deletion inside a repair PR.
The planner should make the disposition an explicit, recorded decision.

### Open Question 2 — `ios-mirror-backfill.yml:288-293`. RESOLVED: live gate, and currently unsatisfiable.

The lines sit inside job `attest-candidate-receipt` (job starts line 165), which is
`workflow_dispatch`-only and further gated by
`if: ${{ github.event.inputs.operation == 'candidate-receipt-attestation' }}` (line 167). It never runs
in ordinary CI and is not merge-blocking.

The six assertions are **negative controls proving the candidate has not yet been published**:

```
test -z "$(git ls-remote --tags origin 'refs/tags/*0.2.1*')"
test "$(curl ... https://hex.pm/api/packages/crosswake/releases/0.2.1)" = 404
test "$(curl ... .../crosswake-shell-core-android/0.2.1/...pom)" = 404
test -z "$(git ls-remote ...crosswake-shell-core-ios.git refs/tags/v0.2.1)"
```

**They are a live gate, not a fixture** — they execute and can fail. But `0.2.1` is now fully published
to Hex, Maven and the iOS mirror, so all four assertions are **false today**: this attestation path
cannot pass for any dispatch, at any version, in its current form. It is not vacuous (it would fail
loudly) — it is welded to a version whose premise has since inverted.

**Classification for the WELD-01 inventory:** `live gate`, with a note that it is presently
unsatisfiable. The fix is the same version-parametric one as everywhere else — assert the absence of
the *candidate* version, not of the literal `0.2.1`.

**Flag for Phase 175:** Phase 175 (Rehearsal and Publish) depends on this attestation path working for
`0.2.2`. If Phase 171 does not parameterize these six lines, Phase 175 inherits a blocked one-way-door
rehearsal. This is a cross-phase dependency the ROADMAP does not currently record.
