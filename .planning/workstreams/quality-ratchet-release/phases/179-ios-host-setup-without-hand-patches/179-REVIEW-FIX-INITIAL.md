---
phase: 179
fixed_at: 2026-10-13
review_path: .planning/workstreams/quality-ratchet-release/phases/179-ios-host-setup-without-hand-patches/179-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 179: Code Review Fix Report

All seven Critical findings and the Warning finding were repaired in the candidate tree. Each finding has an atomic candidate commit; the report itself is not committed.

## Fixed issues

### CR-01: Accepts malformed and out-of-range HTTPS ports

**Commit:** `26cc860`
**Applied fix:** Validate the full HTTPS origin authority, require an explicit numeric port to be in `1..65535`, and serialize accepted origins canonically before any effect.

### CR-02: Managed output paths can escape through an ancestor symlink

**Commit:** `765e723`
**Applied fix:** Check existing ancestors with `lstat` and enforce containment without following attacker-controlled links. Preserve the established macOS `/tmp` and `/var` logical aliases while keeping the containment check strict.

### CR-03: Proof settings are published before all scaffold destinations are checked

**Commit:** `70a2126`
**Applied fix:** Preflight every proof scaffold, manifest, and managed destination before settings writes. Stage and promote the related outputs as a coherent set, retaining interruption and recovery behavior and refusing external native-file overwrites.

### CR-04: Proof project migration accepts unrecognized build configurations

**Commit:** `7baf148`
**Applied fix:** Validate the complete proof build-configuration graph, including configuration lists, names, counts, and IDs. Keep supported unrelated PBX edits intact.

### CR-05: Proof recovery overwrites edits made after interruption

**Commit:** `f27e17f`
**Applied fix:** Recovery accepts only the recorded old bytes or desired bytes. A third value is treated as an external conflict; recovery makes no writes and retains pending/recovery state.

### CR-06: Effective-settings checker can miss settings bundled as resources

**Commit:** `0f6bd00`; valid graph regression repair: `f92306a`
**Applied fix:** Inspect resource phases on every shell and proof target by following PBX object IDs through `PBXResourcesBuildPhase → PBXBuildFile → PBXFileReference`, including entries without filename comments. The original manual-flow assertion now uses a valid ID-only PBX graph mutation; the existing regression also verifies shell and proof cases with an Xcode-parseable fixture.

### CR-07: Published package omits the checker required by proof-lane checks

**Commit:** `9623464`
**Applied fix:** Ship the checker under Hex `priv`, resolve it through `:code.priv_dir(:crosswake)` in the installed host, and retain repository CLI/import behavior through the compatibility shim.

### WR-01: CLI entry-point check fails when the script path contains spaces

**Commit:** `bbb2049`
**Applied fix:** Convert `import.meta.url` with `fileURLToPath` and compare a resolved entrypoint path so direct CLI execution works for paths containing spaces and symlinked package paths.

`34b3468` preserves the frozen assertion coordinates while reconciling the maintained inventory after the regression additions.

## Verification

- `node --test test/crosswake/shell/ios_host_effective_settings_test.mjs` on pinned Node 22.14: **5 tests passed**, including the manual and automatic 20-cell matrices, resource graph rejection, installed-path shapes, and pending-marker build behavior.
- Actual Xcode control on one generated proof project: the unmarked build succeeded; two consecutive builds with the pending marker failed and emitted the expected interruption diagnostic.
- Locally built Hex archive: checker was present and executed from the archive at a path containing spaces. The installed dependency path exercised `:code.priv_dir` and its `priv` symlink. No package publication or install/upgrade was performed.
- Maintained assertion inventory and frozen guard checks: **24 tests passed**; inventory remains 231 keys and the frozen guard set remains 52 rows.
- Final required leaves on the settled candidate: `root-proof` **PASS**, `example-host-proof` **PASS** with **6/6** seed/class combinations, and `ios-package-proof` **PASS**. Each included the repository-preflight and repository-cleanliness PASS results. Raw private run logs were removed after recording the safe summaries.

## Process debt and unresolved observations

- CR-06 did not have a semantic RED regression before its implementation fix. The valid Xcode-parsed resource graph regression and the fixed-checker behavior provide post-fix evidence; no test-first evidence is claimed.
- An earlier status-zero pending-build observation was reported without retained subprocess output. Its cause cannot be assigned. On the final valid generated project, the no-marker Xcode build succeeded and two marked builds were denied with the intended diagnostic; this establishes repeatable current behavior but does not retrospectively explain that unretained observation.
- One discarded diagnostic attempt used `-derivedDataPath` without an Xcode scheme and therefore provided no behavioral evidence. The valid control and marked repetitions above used the production test invocation shape.

_Iteration: 1_
_Fixer: gsd-code-fixer_
