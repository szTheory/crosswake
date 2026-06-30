---
phase: 134
reviewers: [codex, opencode]
reviewed_at: 2026-06-29T19:08:43Z
plans_reviewed: [134-00-PLAN.md, 134-01-PLAN.md, 134-02-PLAN.md, 134-03-PLAN.md, 134-04-PLAN.md]
failed_reviewers:
  gemini: "IneligibleTierError — Gemini Code Assist free tier no longer supported for this client (migrate to Antigravity)"
  cursor: "Authentication required (cursor-agent login / CURSOR_API_KEY not set)"
  antigravity: "agy print-mode hung on large prompt (Cascade non-convergence); --print-timeout did not self-terminate; no transcript conversation registered"
---

# Cross-AI Plan Review — Phase 134

> Reviewers invoked: **codex**, **opencode** (both grounded against the live repo).
> Skipped: `claude` (self — running inside Claude Code).
> Failed/unavailable: `gemini` (deprecated free tier), `cursor` (no auth), `antigravity` (print-mode hang).

## Codex Review

## Summary

The phase structure is mostly sound: it uses the right existing patterns for proof tests, Mix task output, generator ownership, and CI aggregation. The biggest issues are not conceptual, but source-of-truth mismatches. Several plans assume files or locations that do not match the current generator, and Plan 04 edits rendered docs while leaving canonical support-matrix code unchanged. I would revise before execution.

## Strengths

- The drift-test plan correctly mirrors the existing proof-test pattern: `File.cwd!()` anchoring and stable proof messages match [phase132_compat_matrix_drift_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase132_compat_matrix_drift_test.exs:25) and [proof_assertions.ex](/Users/jon/projects/crosswake/test/support/proof_assertions.ex:8).

- The plan correctly avoids using `ensure_file/2` for the manifest. Existing generation skips already-present files at [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:261), so `File.write!/2` is the right choice for `.crosswake/shell.json`.

- The `RebuildPolicy.diff/2` caveat is well handled. The source explicitly says it diffs `Root.t()` manifests and is tooling input only at [rebuild_policy.ex](/Users/jon/projects/crosswake/lib/crosswake/runtime_line/rebuild_policy.ex:30) and [rebuild_policy.ex](/Users/jon/projects/crosswake/lib/crosswake/runtime_line/rebuild_policy.ex:145).

- The Android promotion approach uses the existing aggregator topology instead of registering a new individual required check. That matches the workflow’s current `if: always()` + `alls-green` rollup at [native-behavioral-proof-gate.yml](/Users/jon/projects/crosswake/.github/workflows/native-behavioral-proof-gate.yml:86).

## Concerns

- **HIGH: Plan 01 stamps the wrong template set.** The generator emits `android/gradle.properties.eex` at [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:20), but Plan 01 explicitly says not to edit it at [134-01-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-01-PLAN.md:125). Conversely, Plan 01 stamps `ios/README.md.eex` and `android/README.md.eex` at [134-01-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-01-PLAN.md:15), but generated READMEs come from `shell_readme/1`, not those templates, at [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:88) and [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:106). Result: some generated files will miss the stamp while unused templates get stamped.

- **HIGH: Manifest path expectations conflict.** Plan 01 says `mix crosswake.gen.shell android --target DIR` should create `DIR/.crosswake/shell.json` at [134-01-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-01-PLAN.md:89), but its action writes under `root/.crosswake/shell.json` at [134-01-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-01-PLAN.md:96). In current code, `root` is `target/native/android/crosswake_shell` or `target/native/ios/crosswake_shell` at [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:81) and [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:103). The Plan 01 verification command will fail if the implementation follows the action text.

- **HIGH: Android CI job may fail on Ubuntu because the script fallback is macOS-specific.** Plan 04 proposes `ubuntu-latest` at [134-04-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-04-PLAN.md:112). The script still uses `commandlinetools-mac-...zip` at [verify_generated_android_shell.sh](/Users/jon/projects/crosswake/script/verify_generated_android_shell.sh:10) and downloads/runs it if SDK tools are absent at [verify_generated_android_shell.sh](/Users/jon/projects/crosswake/script/verify_generated_android_shell.sh:105). That makes the job depend on preinstalled runner state unless the script is made Linux-aware or the workflow installs Android tooling explicitly.

- **MEDIUM: Plan 04 updates rendered support docs but not canonical support truth.** `Crosswake.SupportMatrix` is documented as canonical truth shared by manifest, doctor, and docs at [support_matrix.ex](/Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex:2). The shell rows live in code at [support_matrix.ex](/Users/jon/projects/crosswake/lib/crosswake/support_matrix/support_matrix.ex:416), and the guide is rendered from that source at [renderer.ex](/Users/jon/projects/crosswake/lib/crosswake/support_matrix/renderer.ex:18). Editing only [guides/support_matrix.md](/Users/jon/projects/crosswake/guides/support_matrix.md:65) will leave doctor/manifest support truth stale.

- **MEDIUM: Plan 02 has no clean shared source for current template version.** Plan 02 compares against the generator’s live `@template_version` and suggests adding an accessor at [134-02-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-02-PLAN.md:75), but its `files_modified` excludes `crosswake.gen.shell.ex` at [134-02-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-02-PLAN.md:7). A private module attribute in Plan 01 will not be usable by `shell.status` unless Plan 01 adds `template_version/0` or a shared module.

- **MEDIUM: Plan 03 excludes generated wrapper scripts from `--diff`.** The generator emits `gradlew` and `gradlew.bat` at [crosswake.gen.shell.ex](/Users/jon/projects/crosswake/lib/mix/tasks/crosswake.gen.shell.ex:21), but Plan 03 skips them at [134-03-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-03-PLAN.md:74). D-02 only excluded stamps there; hiding them from diff means hosts cannot see wrapper-template changes.

- **LOW: Plan dependencies do not match the roadmap sequencing.** The roadmap says Wave 3 is blocked on Wave 2 at [ROADMAP.md](/Users/jon/projects/crosswake/.planning/ROADMAP.md:278), but Plan 03 depends only on `134-01` at [134-03-PLAN.md](/Users/jon/projects/crosswake/.planning/phases/134-shell-lifecycle-native-uat-promotion/134-03-PLAN.md:6).

## Suggestions

- Derive the stamp/diff inventory from `@ios_templates` and `@android_templates`, then handle `shell_readme/1` separately. Add a generated-output test that every comment-supporting generated file has a stamp, including `gradle.properties`.

- Pick one manifest location and make Plan 01, Plan 02, Plan 03, and all verify commands use it consistently. Based on current generator roots, `<generated shell root>/.crosswake/shell.json` is the least ambiguous.

- Add `Mix.Tasks.Crosswake.Gen.Shell.template_version/0` in Plan 01, and have status/diff/bump tests use that instead of parsing source or duplicating the integer.

- For Plan 04, update `lib/crosswake/support_matrix/support_matrix.ex`, renderer/tests if needed, and `guides/support_matrix.md` together. Also add `guides/native_shell_upgrade.md` to `mix.exs` docs extras; current guide extras end at [mix.exs](/Users/jon/projects/crosswake/mix.exs:127).

- Either update `script/verify_generated_android_shell.sh` to provision Linux Android command-line tools or run the new generated-shell job on a runner/tooling path the script already supports.

## Risk Assessment

**Overall risk: MEDIUM-HIGH.** The design is aligned with the phase goals, but the current plans would likely produce failing verification and stale support truth unless revised. The manifest path and template inventory issues are execution blockers; the support-matrix source issue is a product-truth blocker; the Android CI runner mismatch is a real merge-gate risk.

---

## OpenCode Review

I’m checking the referenced source files and workflow topology against the plan, then I’ll give a plan-quality review with concrete risks and gaps.
I’ve confirmed the current generator still lacks the planned stamp/version machinery, and I’m checking the workflow and script details that the plan must fit without breaking CI topology.
I’ve got the main discrepancies now. I’m checking the review guidance once, then I’ll condense this into findings ordered by severity.
## Summary
The phase is well-sliced and mostly reuses existing proven patterns, but I see two blocking inconsistencies: the shell manifest location is not consistent between Plans 01 and 02, and the new Android CI lane is assigned to a runner that conflicts with the verification script’s macOS-specific toolchain assumptions. There’s also an under-specified version source for `shell.status` and one broken validation command in the scaffold wave.

## Strengths
- Good decomposition: test scaffolds first, then generator/versioning, then status, diff, and docs/CI.
- Strong reuse of existing patterns: `ProofAssertions.stable_id_message/7`, `exit({:shutdown, N})`, and `List.myers_difference/2` are all grounded in current code.
- The diff plan explicitly forbids writes before the branch point, which is the right safety model for host-owned output.
- The CI plan correctly keeps `if: always()` and the `alls-green` aggregator pattern, which avoids skipped-success masking.

## Concerns
### [HIGH] Manifest path is inconsistent across the phase
**File**: `.planning/phases/134-shell-lifecycle-native-uat-promotion/134-01-PLAN.md:89-106`, `.planning/phases/134-shell-lifecycle-native-uat-promotion/134-02-PLAN.md:73-75`, `lib/mix/tasks/crosswake.gen.shell.ex:81-122`

**Issue**: Plan 01 says `mix crosswake.gen.shell android --target DIR` writes `DIR/.crosswake/shell.json`, but Plan 02 probes `native/ios/crosswake_shell/.crosswake/shell.json` and `native/android/crosswake_shell/.crosswake/shell.json`. The current generator already writes into per-platform roots (`native/ios/crosswake_shell` and `native/android/crosswake_shell`), so a target-root manifest would not line up with the existing output layout.

**Why it matters**: `shell.status` will not find the manifest the generator wrote, and if both platforms are generated into one `DIR`, a single top-level manifest would be overwritten or ambiguous.

**Suggestion**: Standardize on one location now, most likely per-platform root `.crosswake/shell.json`, and update Plan 01 acceptance text plus Plan 02 probing to match.

### [HIGH] Android CI runner does not match the verification script
**File**: `.planning/phases/134-shell-lifecycle-native-uat-promotion/134-04-PLAN.md:111-114`, `script/verify_generated_android_shell.sh:5-10, 41-55, 58-90, 102-120`

**Issue**: The plan puts `android-generated-shell-unit` on `ubuntu-latest`, but the script it runs is built around macOS assumptions: `commandlinetools-mac-...zip`, `/opt/homebrew` JDK fallback, and other mac-specific setup paths.

**Why it matters**: The lane is likely to fail or spend time fighting the wrong environment, so the merge-blocking proof could be flaky or dead on arrival.

**Suggestion**: Either move the job to a macOS runner if the script is truly mac-only, or split out a Linux-safe verification path and make the new job use that instead.

### [MEDIUM] `shell.status` needs an explicit shared version source
**File**: `.planning/phases/134-shell-lifecycle-native-uat-promotion/134-02-PLAN.md:75-77`, `lib/mix/tasks/crosswake.gen.shell.ex:146-160, 199-214`

**Issue**: Plan 02 says status should compare against the live `@template_version`, but the generator currently only has a private `fetch_version!/0`. The plan hints at “a tiny public accessor” but does not assign it to any file or task.

**Why it matters**: `Mix.Tasks.Crosswake.Shell.Status` cannot reliably read the current template epoch without either adding a new exported accessor or duplicating the constant, which makes the phase under-specified.

**Suggestion**: Add an explicit public accessor in Plan 01, or move the epoch to a shared module constant and list that file in the plan.

### [MEDIUM] Plan 00’s “expected RED” verification command is broken
**File**: `.planning/phases/134-shell-lifecycle-native-uat-promotion/134-00-PLAN.md:72-74`

**Issue**: The automated verify chains `mix test ... && grep ... && echo ...`, but the drift test is expected to fail at first. That means the `grep` never runs when the command behaves as intended.

**Why it matters**: The scaffold wave’s validation can’t actually confirm the intended red state, so the phase loses one of its main Nyquist guards.

**Suggestion**: Capture the failing output explicitly with `if`/`|| true`, then grep the saved output for the stable ID.

## Suggestions
- Align Plan 01 and Plan 02 on one manifest location before implementation starts.
- Reconcile the Android CI runner with the actual verification script environment.
- Add a named shared accessor for the live template epoch so `shell.status` is not guessing.
- Fix Plan 00’s verification command so it can assert the expected failure cleanly.
- Consider tightening Plan 04 so the promotion-table row is updated explicitly alongside the shell-artifacts row.

## Risk Assessment
**HIGH**

The phase is conceptually solid, but the manifest-path mismatch and CI runner mismatch are both blocking-level integration risks. If those two are not resolved up front, the implementation is likely to churn across multiple plans.


---

## Consensus Summary

Two independent, source-grounded reviewers (Codex, OpenCode) examined all five plans against the live generator, CI workflows, and verification scripts. Both converged on the **same two execution-blocking issues** and rated overall risk **MEDIUM-HIGH / HIGH**. The phase is conceptually sound and reuses the right existing patterns (proof-test anchoring, `exit({:shutdown, N})`, `List.myers_difference/2`, the `if: always()` + `alls-green` aggregator), but would likely produce failing verification and churn across plans unless revised first.

### Agreed Strengths
- **Pattern reuse is correct.** Drift test mirrors `phase132_compat_matrix_drift_test.exs` / `ProofAssertions`; `File.write!/2` (not `ensure_file/2`) is the right choice for the manifest; the diff plan correctly forbids writes before the branch point (host-owned output safety).
- **CI topology preserved.** The Android promotion uses the existing `if: always()` + `alls-green` rollup rather than registering a brittle new individual required check — avoids skipped-success masking.

### Agreed Concerns (highest priority — raised by BOTH reviewers)
1. **[HIGH] Manifest path is inconsistent across the phase.** Plan 01 writes/acceptance-tests `DIR/.crosswake/shell.json` (target root), but the current generator writes into per-platform roots (`native/ios/crosswake_shell`, `native/android/crosswake_shell` — `crosswake.gen.shell.ex:81,103`), and Plan 02 probes those per-platform paths. `shell.status` will not find the manifest the generator wrote; a single top-level manifest is ambiguous/overwritten when both platforms generate into one DIR. **Standardize on `<generated shell root>/.crosswake/shell.json` and reconcile Plan 01 acceptance text + Plan 02 probing before execution.**
2. **[HIGH] Android CI runner ↔ verification-script environment mismatch.** Plan 04 puts `android-generated-shell-unit` on `ubuntu-latest` (`134-04-PLAN.md:111-114`), but `script/verify_generated_android_shell.sh` is macOS-specific (`commandlinetools-mac-...zip`, `/opt/homebrew` JDK fallback). The merge-blocking lane is likely dead-on-arrival or flaky. **Either run on macOS or add a Linux-safe verification path.**
3. **[MEDIUM] `shell.status` has no clean shared source for the current template version.** Plan 02 compares against the generator's live `@template_version`, but it's a private attribute and Plan 02's `files_modified` excludes `crosswake.gen.shell.ex`. **Add a public `template_version/0` accessor (or shared module constant) in Plan 01** rather than parsing source or duplicating the integer.

### Divergent / Single-Reviewer Concerns (worth investigating)
- **[HIGH — Codex only] Plan 01 stamps the wrong template set.** Generator emits `android/gradle.properties.eex` (which Plan 01 says *not* to stamp) while Plan 01 stamps `ios/README.md.eex` / `android/README.md.eex` — but generated READMEs come from `shell_readme/1`, not those templates (`crosswake.gen.shell.ex:88,106`). Some generated files miss the stamp; unused templates get stamped. *Suggested fix: derive the stamp/diff inventory from `@ios_templates`/`@android_templates` + handle `shell_readme/1` separately; add a generated-output test asserting every comment-supporting file has a stamp.*
- **[MEDIUM — Codex only] Plan 04 edits rendered docs but not canonical support truth.** `Crosswake.SupportMatrix` is canonical (shared by manifest, doctor, docs); shell rows live at `support_matrix.ex:416` and the guide renders from it (`renderer.ex:18`). Editing only `guides/support_matrix.md` leaves doctor/manifest support truth stale. Also add `guides/native_shell_upgrade.md` to `mix.exs` docs extras.
- **[MEDIUM — Codex only] Plan 03 excludes generated wrapper scripts (`gradlew`, `gradlew.bat`) from `--diff`** (`134-03-PLAN.md:74`). D-02 only excluded *stamps*; hiding wrappers means hosts can't see wrapper-template changes.
- **[MEDIUM — OpenCode only] Plan 00's "expected RED" verify command is broken.** `mix test ... && grep ... && echo ...` — the `grep` never runs because the drift test is expected to fail first, so the scaffold can't confirm the intended red state (loses a Nyquist guard). *Fix: capture failing output with `if`/`|| true`, then grep the saved output for the stable ID.*
- **[LOW — Codex only] Plan dependency vs roadmap sequencing.** Roadmap says Wave 3 blocks on Wave 2 (`ROADMAP.md:278`), but Plan 03 depends only on `134-01`.

### Recommended action before execution
Resolve the two HIGH consensus blockers (manifest path, Android runner) and the shared version-accessor MEDIUM up front — all three are cheap plan edits that prevent cross-plan churn. Codex's stamp-inventory and support-matrix-canonical-truth findings are also worth folding in since they affect product correctness, not just verification.
