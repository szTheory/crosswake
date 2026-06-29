---
phase: "134"
plan: "04"
subsystem: shell-lifecycle
tags: [life-01a, life-01b, life-02c, upgrade-guide, ci-promotion, support-matrix, android-jvm-hermetic]
dependency_graph:
  requires:
    - lib/mix/tasks/crosswake.gen.shell.ex (Plan 01 — @template_version, shell_readme/1)
    - test/crosswake/guides/native_shell_upgrade_test.exs (Plan 00 scaffold)
    - .github/workflows/native-behavioral-proof-gate.yml (existing android-package-unit + aggregator)
    - lib/crosswake/support_matrix/support_matrix.ex (canonical support truth)
  provides:
    - guides/native_shell_upgrade.md (per-template-version upgrade changelog)
    - lib/mix/tasks/crosswake.gen.shell.ex (line-254 placeholder replaced with real guide pointer)
    - .github/workflows/native-behavioral-proof-gate.yml (android-generated-shell-unit job + aggregator update)
    - lib/crosswake/support_matrix/support_matrix.ex (android_shell notes + ios_shell notes updated)
    - guides/support_matrix.md (regenerated in parity)
    - mix.exs (guides/native_shell_upgrade.md registered in docs extras)
  affects:
    - Phase 134 completion (LIFE-01a, LIFE-01b, LIFE-02c satisfied)
    - Downstream: docs publish — native_shell_upgrade.md now appears in HexDocs
    - Downstream: PR merges — android-generated-shell-unit now merge-blocking via aggregator
tech_stack:
  added: []
  patterns:
    - Per-template-version changelog: newest-first, leading with RebuildPolicy verdict (D-06)
    - Aggregator fan-in via needs: (D-18) — no direct branch protection registration (D-21)
    - Canonical source edit + renderer regeneration for support_matrix parity (REVIEW FIX finding 5)
    - erlef/setup-beam SHA-pinned at fc68ffb (project standard from phase73-proof.yml)
key_files:
  created:
    - guides/native_shell_upgrade.md
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - .github/workflows/native-behavioral-proof-gate.yml
    - lib/crosswake/support_matrix/support_matrix.ex
    - guides/support_matrix.md
    - mix.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
decisions:
  - "guides/native_shell_upgrade.md uses RebuildPolicy verdict atoms as the leading anchor for each version section (D-06/D-08) — verdicts are derived from RebuildPolicy.classify/2 vocabulary, not free prose"
  - "android-generated-shell-unit runs on macos-latest (REVIEW FIX finding 2) — verify script is mac-specific: arch() exit-1s off-mac, commandlinetools-mac zip, adoptium/mac JDK"
  - "CROSSWAKE_ANDROID_CONNECTED_TESTS is the external env var the script reads (line 9); NOT the internal RUN_CONNECTED_TESTS — env var correctness verified against script source"
  - "android_shell proof_status promoted to :supported in canonical support_matrix.ex (D-20); ios_shell stays :verification_required; support_matrix_test.exs updated to match"
  - "guides/native_shell_upgrade.md placed between native_shell.md and android_uat.md in mix.exs extras for sensible ExDoc sidebar grouping"
  - "Post-merge follow-up (D-21 footgun 4): on the first aggregator run after merge, confirm needs.android-generated-shell-unit.result appears in the alls-green toJSON(needs) input"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-29"
  tasks_completed: 4
  files_created: 1
  files_modified: 6
status: complete
---

# Phase 134 Plan 04: Upgrade Guide, CI Promotion, and Honest Labels Summary

Closes Phase 134 (LIFE-01a, LIFE-01b, LIFE-02c): the per-template-version upgrade changelog
replaces the dangling gen.shell.ex placeholder; the hermetic Android JVM generated-shell lane
is merge-blocking via the aggregator (zero new registration, all D-21 footguns honored); iOS
stays advisory with honest labels; canonical support truth and the rendered guide are in parity.

## What Was Built

**Task 1 — `guides/native_shell_upgrade.md` + line-254 placeholder replacement (LIFE-02c):**

Created `guides/native_shell_upgrade.md` as a per-template-version changelog (D-06):
- Newest-first order: Template Version 2 (Phase 134 stamp/manifest/diff) and Template Version 1 (initial baseline)
- Each version section leads with the `RebuildPolicy.classify/2` verdict and named change-class atoms (D-08)
- "Should you rebuild?" subsection quotes the actual `RebuildPolicy.classify/2` call return
- Version 2 verdict: `:ota_safe` (stamp/manifest are commentary only — no native code change)
- Version 1: baseline, no prior version to upgrade from
- Calm brand-spec voice; no banned words; code identifiers in backticks
- Explicitly references `RebuildPolicy.classify/2` so the doc-presence test passes

Replaced the dangling placeholder `shell_readme/1` bullet (D-07):
- Before: "Upgrade this shell with patch-or-doc guidance after generation..."
- After: "Upgrade this shell following guides/native_shell_upgrade.md for per-version changelog and rebuild guidance."

Result: `mix test test/crosswake/guides/native_shell_upgrade_test.exs` → 3 tests, 0 failures.

**Task 2 — `android-generated-shell-unit` CI job + aggregator wired (LIFE-01a):**

Added new job `android-generated-shell-unit` to `native-behavioral-proof-gate.yml` (D-17):
- `runs-on: macos-latest` (REVIEW FIX finding 2 — matches mac-specific verify script: `arch()` exit-1s off-mac, commandlinetools-mac zip, adoptium/mac JDK)
- `env: CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"` — the external env var the script reads at line 9 (NOT the internal `RUN_CONNECTED_TESTS`)
- `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1` SHA-pinned at elixir 1.19.5 / otp 27.3 (project standard from phase73-proof.yml) — required because the script calls `mix crosswake.gen.shell android` (D-21 footgun 2)
- `actions/setup-java@v4` Temurin 17 — satisfies JAVA_HOME check and skips slow self-install
- `run: script/verify_generated_android_shell.sh`
- Step summary echo

Wired aggregator (D-18): `needs: [android-package-unit, android-generated-shell-unit]`
- `if: always()` unchanged (D-21 footgun 1 — without it, skipped dependency passes)
- `re-actors/alls-green` with `jobs: ${{ toJSON(needs) }}` unchanged
- New job NOT added to branch protection directly (D-21 footgun 3 / D-19 — aggregator is already the sole registered required check; fan-in via `needs:` propagates merge-blocking with zero new registration)

**Post-merge follow-up (D-21 footgun 4):** On the first aggregator run after merge, confirm
`needs.android-generated-shell-unit.result` appears in the alls-green `toJSON(needs)` input.

**Task 3 — Honest iOS-advisory / Android-merge-blocking labels in CANONICAL support truth + rendered guide (LIFE-01b):**

Edited CANONICAL `lib/crosswake/support_matrix/support_matrix.ex` (REVIEW FIX finding 5):
- `android_shell` support_entry: `proof_status: :supported`, `proof` references `native-behavioral-proof-gate / android-generated-shell-unit`, `notes` carry verbatim caveat "JVM hermetic proof is not emulator evidence or physical-device proof." and phrase "Generated Android shell artifacts are supported based strictly on `JVM hermetic proof`"
- `ios_shell` support_entry: `notes` carry verbatim advisory note "advisory — not wired as a required CI lane; macOS/Xcode toolchain not guaranteed in CI."

Regenerated `guides/support_matrix.md` via `Crosswake.SupportMatrix.Renderer.write/2` — the renderer produces the guide deterministically from canonical source. The phase69 parity test asserts they stay in sync.

Updated `test/crosswake/support_matrix/support_matrix_test.exs`: the shell proof_status assertion now expects `{"android_shell", :supported, :supported}` instead of `:verification_required` — this is correct because android_shell has a merge-blocking JVM hermetic CI lane.

Result: 68 tests, 0 failures across phase69 parity + renderer + support_matrix tests.

**Task 4 — Register `guides/native_shell_upgrade.md` in `mix.exs` docs extras (LIFE-02c):**

Added `"guides/native_shell_upgrade.md"` to the `extras:` list in `mix.exs` docs, positioned between `guides/native_shell.md` and `guides/android_uat.md` for sensible ExDoc sidebar grouping. Without this registration, the upgrade changelog would not publish to HexDocs.

`mix compile --warnings-as-errors`: clean.

## Verification Results

```
# Task 1:
test -f guides/native_shell_upgrade.md → TRUE
grep "RebuildPolicy.classify/2" guides/native_shell_upgrade.md → FOUND
grep "patch-or-doc guidance" lib/mix/tasks/crosswake.gen.shell.ex → EMPTY (placeholder gone)
mix test test/crosswake/guides/native_shell_upgrade_test.exs → 3 tests, 0 failures

# Task 2:
grep "android-generated-shell-unit" .github/workflows/native-behavioral-proof-gate.yml → FOUND
grep 'CROSSWAKE_ANDROID_CONNECTED_TESTS: "0"' → FOUND
grep "erlef/setup-beam" → FOUND
grep "needs: [android-package-unit, android-generated-shell-unit]" → FOUND
grep "if: always()" → FOUND
python3 -c yaml.safe_load: android-generated-shell-unit runs-on: macos-latest → VALID

# Task 3:
grep "JVM hermetic proof is not emulator evidence or physical-device proof" guides/support_matrix.md → FOUND (line 70)
grep "advisory — not wired as a required CI lane" guides/support_matrix.md → FOUND (line 69)
grep "android-generated-shell-unit" guides/support_matrix.md → FOUND (line 70)
grep "android-generated-shell-unit|JVM hermetic" lib/crosswake/support_matrix/support_matrix.ex → FOUND
mix test phase69_parity + renderer + support_matrix_test → 68 tests, 0 failures

# Task 4:
grep '"guides/native_shell_upgrade.md"' mix.exs → FOUND
test -f guides/native_shell_upgrade.md → TRUE
mix compile --warnings-as-errors → clean
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated support_matrix_test.exs shell proof_status assertion**
- **Found during:** Task 3 verification
- **Issue:** `support_matrix_test.exs` line 54 hardcoded `{"android_shell", :supported, :verification_required}` which failed after promoting `android_shell` proof_status to `:supported`
- **Fix:** Updated expected value to `{"android_shell", :supported, :supported}` with comment referencing D-17/D-20
- **Files modified:** `test/crosswake/support_matrix/support_matrix_test.exs`
- **Commit:** 0e2d01c

## Known Stubs

None — all artifacts are fully implemented and functional. The upgrade guide has real content for template versions 1 and 2; the CI job is correctly configured; the canonical support truth and rendered guide are in parity.

## Threat Surface Scan

T-134-04-01 (mitigate): `if: always()` confirmed present on aggregator — skipped android-generated-shell-unit blocks the merge (confirmed via grep + python3 yaml parse).
T-134-04-02 (mitigate): `erlef/setup-beam` SHA-pinned at fc68ffb — prevents tag-move supply-chain swap; `mix crosswake.gen.shell android` runs correctly.
T-134-04-03 (mitigate): iOS advisory label explicit with verbatim caveat; android_shell notes do NOT claim device_verified — "JVM hermetic proof is not emulator evidence or physical-device proof" is the canonical boundary statement.
T-134-04-04 (mitigate): Only the aggregator (`merge-blocking-native-behavioral-proof`) is registered as required check; `android-generated-shell-unit` is NOT registered directly.

No new threat surface beyond what the plan modeled.

## Self-Check: PASSED

- FOUND: guides/native_shell_upgrade.md (96 lines, references RebuildPolicy.classify/2)
- FOUND: lib/mix/tasks/crosswake.gen.shell.ex (placeholder replaced, no "patch-or-doc guidance")
- FOUND: .github/workflows/native-behavioral-proof-gate.yml (android-generated-shell-unit on macos-latest, aggregator updated)
- FOUND: lib/crosswake/support_matrix/support_matrix.ex (android-generated-shell-unit + JVM hermetic references)
- FOUND: guides/support_matrix.md (verbatim caveats in both shell rows, in parity)
- FOUND: mix.exs (guides/native_shell_upgrade.md in extras list)
- FOUND: commit 001a597 (Task 1 — upgrade guide + placeholder)
- FOUND: commit d2f038a (Task 2 — CI job + aggregator)
- FOUND: commit 0e2d01c (Task 3 — canonical support truth + rendered guide)
- FOUND: commit 1ced14c (Task 4 — mix.exs docs extras)
