# Phase 194: Bearings reset and ADR amendments - Pattern Map

**Mapped:** 2026-10-24
**Files analyzed:** 33 new/modified
**Analogs found:** 27 / 33 (the rest are prose-only or have no in-repo analog; see the last two sections)

All paths below were checked with `git ls-files -- <path>` (tracked = non-empty), except where marked UNTRACKED. No gitignored mirror path is cited.

## Verified path and measurement facts the planner must use

| Fact | Measured value |
|------|----------------|
| `AGENTS.md` | 127 lines, tracked. Sections: Project Context (3), Current Priority (22), Working Rules (39), Sensitive Data Rules (63), Workflow (76), How changes land (116). Approval-gate bullet is lines 56-61. Android bullet is lines 52-53. |
| Workstream `STATE.md` (`.planning/workstreams/quality-ratchet-release/STATE.md`) | 118 lines, tracked. Sections: Project Reference 23, Current Position 27, Exact Next Action 36, Accumulated Context 46 (Roadmap Evolution 48, Current decisions 67, Phase180 74, Phase179 81, Historical proof 86, Working posture 95), Deferred Items 99, Session 114. |
| STATE has no literal "Handoff history" heading | The phrase only appears at line 44 as "The earlier handoff history is in git...". The "Accumulated Context" block (lines 46-98) is the history to delete. The planner must not grep for a heading that is not there. |
| `ROADMAP-ROLLING.md`, `BEARINGS.md`, `PERSONAS.md` | Do not exist yet. All three are new files at `.planning/`. |
| `PROJECT.md` | 638 lines (already over the 250 advisory line, so the report prints that advisory line on day one). |
| `.planning/workstreams/quality-ratchet-release/state.json` | UNTRACKED and git-excluded via `.git/info/exclude`. It exists locally, with `"milestone": "v28.0"`, but a fresh clone or CI has no such file. `bearings-report` must treat a missing `state.json` as UNVERIFIED. Tests must use a fixture copy and never read the live file. Do NOT cite `state.json` as a tracked input. |
| `milestone.lock` | Not to be used (D-12). |
| Milestone-start convention doc | NOT FOUND in tracked files. The ritual text (`history/vNN-before-vMM-start` plus sha256) is described only in `v28.0-research/ROADMAP-PROCESS.md` lines 66 and 263 (E9), plus the REQUIREMENTS and ROADMAP PLAN-03 lines. It is almost certainly defined in the untracked GSD tooling (`~/.claude/get-shit-done/...`, not searched; outside the repo). `docs/MILESTONE-BOUNDARY-HYGIENE.md` section 0 "Snapshot the state (read-only)" is a read-only snapshot and is NOT the byte-copy ritual. The planner needs a task to locate the definition (grep `~/.claude/get-shit-done` and the `gsd-tools` workstream/milestone-start templates). If it lives only outside the repo, the in-repo deliverable is a recorded note and a PLAN-03 evidence line, and PR2 cannot carry that edit. Flag this to the user rather than invent a file. |
| Existing byte-snapshot artifacts | `.planning/workstreams/quality-ratchet-release/history/v26.0-before-v27-start/`, `...v26.0-before-v27-start.sha256` and `history/v25.0-before-v26-start/` are historical records. Leave them alone. |
| Selftest "controls N of N" scripts | The `selftest <name>: controls N of N as expected` format lives under the phase dirs, for example `.planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/`. There is NO root-level `scripts/` directory (the repo uses `script/`). |
| Required-check registration | `script/check_required_checks_registered.sh` and `script/list_merge_blocking_checks.py` derive producers from `.github/workflows/*.yml`. A script that no workflow references cannot become a required check. `script/required_check_policy.json` pins `umbrella_context: "Crosswake CI"`. |

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `script/bearings_report.exs` (new) | utility (reporting script) | request-response (reads `gh`/`git`/files, prints verdict, exit code) | `script/check_release_version_truth.exs` | exact (role + data flow: git read, 0/1/2 exit contract, BLOCKED = unknown) |
| `script/bearings-report` (new bash launcher) | utility (launcher) | request-response | `script/check_required_checks_registered.sh` (header, `ROOT_DIR`, exit contract) | role-match |
| `test/crosswake/bearings_report_test.exs` (new) | test | request-response | `test/crosswake/proof/absence_is_not_success_test.exs` | exact (guard-of-the-guard, positive plus negative control per check) |
| `test/fixtures/bearings/*` (new, real captured `gh`/`git` output) | fixture | file-I/O | `test/fixtures/ci/classifier/cases.json`, `test/fixtures/security/advisory-bearing.lock` | role-match |
| `test/crosswake/planning/agents_contract_test.exs` (new doc-contract test, D-13) | test | transform | `test/crosswake/planning/first_adopter_context_test.exs:395-406` | exact |
| `test/crosswake/planning/persona_tag_*` or inside `bearings_report_test.exs` (positive and negative fixtures) | test | transform | `test/crosswake/proof/absence_is_not_success_test.exs` (tmp_dir fixtures, `write_test!`) | role-match |
| `.planning/ROADMAP-ROLLING.md` (new) | doc | none | `.planning/workstreams/quality-ratchet-release/ROADMAP.md` (shape) plus SYNTHESIS section 4 draft | partial |
| `.planning/BEARINGS.md` (new) | doc | none | SYNTHESIS section 5 draft; `.planning/MILESTONE-ARC.md` Durable Lessons | partial |
| `.planning/PERSONAS.md` (new) | doc | none | `v28.0-research/JTBD-PERSONAS.md` section 3 | exact (extract) |
| `AGENTS.md` (modify, two PRs) | config/doc | none | itself at `main` | self |
| `.planning/ADR-FIRST-B2C-ADOPTER.md` (append A1, A2, add Status pointer) | doc | none | its own sections (format below) | exact |
| `.planning/PROJECT.md` (lines 131, 491, 506; check 586) | doc | none | itself | self |
| `.planning/MILESTONE-ARC.md` (banner only) | doc | none | `.planning/research/JTBD-AND-USER-FLOWS.md` banner (same treatment) | role-match |
| `.planning/research/JTBD-AND-USER-FLOWS.md` (banner only) | doc | none | n/a | no analog |
| `.planning/workstreams/quality-ratchet-release/STATE.md` (trim to at most 40) | doc | none | frontmatter plus first 45 lines of itself | self |
| `lib/crosswake/support_matrix/support_matrix.ex` (lines 446, 473) | model/data | CRUD (static data) | itself | self |
| `lib/crosswake/support_matrix/renderer.ex` (lines 378, 399) | renderer | transform | itself | self |
| `lib/crosswake/capability_map/renderer.ex` (line 163) | renderer | transform | itself | self |
| `lib/crosswake/proof_lane/provenance.ex` (comment at line 39) | comment | none | itself | self |
| `guides/support_matrix.md`, `guides/capability_map.md` (regenerate) | generated doc | batch | generator mix tasks (find at plan time, see below) | generated |
| `guides/native_shell.md` (line 33, hand-written) | doc | none | itself | self |
| `examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json` (regenerate; hits at 1298, 1748) | golden fixture | batch | generator path | generated |
| `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json` (regenerate; hits 497, 947, 1415, 1865) | golden fixture | batch | generator path | generated |
| `test/crosswake/support_matrix/renderer_test.exs` (lines 56, 412-419) | test | transform | itself | self |
| `test/crosswake/support_matrix/support_matrix_test.exs` (lines 83-84) | test | transform | itself | self |
| `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` (line 88-94 only) | test | transform | itself | self |
| SC4 phase-evidence grep script (one-time, not CI; D-07) in the phase dir, for example `.../194-.../scripts/sc4-grep-194.sh` | utility | batch | `.../193-cleanup-and-new-working-rules/scripts/selftest-193.sh` plus `privacy-193.sh` | role-match |

## Pattern Assignments

### `script/bearings_report.exs` (utility, request-response)

**Analog:** `script/check_release_version_truth.exs`. Role-match files: `script/check_absence_is_not_success.exs`.

**Shebang, moduledoc-comment and exit contract** (`check_release_version_truth.exs` lines 1-15):
```elixir
#!/usr/bin/env elixir
# ...
# Being AHEAD of the newest tag is the normal pre-release state and is OK.
# Being BEHIND it is the defect. Not being able to tell is BLOCKED, never OK.
#
# Exit codes: 0 OK, 1 FAIL, 2 BLOCKED.
defmodule Crosswake.ReleaseVersionTruth do
```
Copy the idea but map to D-12a: 0 OK, 1 ATTENTION, 2 UNVERIFIED (UNVERIFIED wins). Output prefix in the analog is `[crosswake] ...`. D-12a requires line 1 to be `BEARINGS: ...`, so do not copy the prefix.

**git read via System.cmd, explicit exit handling** (`check_release_version_truth.exs` line 63):
```elixir
case System.cmd("git", ["tag", "--list"], stderr_to_stdout: true) do
```
D-10 wants this behind ONE injectable `run(cmd, args)` returning `{:ok, out}` or `{:error, reason}`. Never print raw stderr (D-12a). Rule: map `{_, nonzero}` and `:enoent` (rescue `ErlangError` from `System.cmd` on a missing binary) to fixed reason strings.

**Blocked helper and halt** (lines 195-201):
```elixir
defp blocked(reason) do
  IO.puts("[crosswake] BLOCKED: #{reason}")
  ...
  System.halt(2)
end
Crosswake.ReleaseVersionTruth.main(System.argv())
```

**Arg parsing** (`check_absence_is_not_success.exs` lines 459-478):
```elixir
OptionParser.parse(System.argv(), strict: [root: :string, min_test_files: :integer])
...
System.halt(Crosswake.AbsenceIsNotSuccess.run(expanded, Keyword.take(opts, [:min_test_files])))
```
Use `strict: [ws: :string, root: :string]` with `--ws` defaulting to `quality-ratchet-release`. `run/2` returns the exit integer; only the bottom line halts. That keeps the module testable without `System.halt`.

**Fail-closed scope pattern to copy** (`check_absence_is_not_success.exs` lines 56-90): every scope is a literal `{label, glob, min}`, and an empty or below-min scope fails closed before any content check:
```elixir
@scopes [
  {"test-files", "test/**/*.exs", 253},
  {"seeds", ".planning/seeds/*.md", 1},
  ...
]
```
For seeds ("UNVERIFIED if zero seeds parse") and persona tags ("UNVERIFIED if requirement count is 0") use the same shape. Absence is never scored as success; this is the repo's recurring defect (see the moduledoc, lines 3-20).

**Frontmatter shape for the hand-rolled parser** (`.planning/seeds/SEED-003-ios-mirror-push-token.md` lines 1-8):
```
---
id: SEED-003
status: planted
planted: 2026-07-03
trigger_when: "Surface before ..."
scope: Small
---
```
Prose `trigger_when` only; no `fires_when` exists today. No YAML library (D-09 and the standing preference). Skip statuses shipped/harvested/closed. Count prose-only open seeds as ONE info line.

**Key constraint:** `.planning/workstreams/quality-ratchet-release/state.json` is untracked (see table). Read it via the injected file reader and treat missing as UNVERIFIED.

---

### `script/bearings-report` (utility, launcher)

**Analog:** `script/check_required_checks_registered.sh` lines 1-12 for header, `ROOT_DIR` resolution and exit contract comment.
```bash
#!/usr/bin/env bash
# Fail-closed comparison ...
# exit contract: 0 clean / 1 defect found / 3 could not verify
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
```
Launcher body per D-09: `exec elixir "$ROOT_DIR/script/bearings_report.exs" "$@"`. No pipes. Note this analog's contract uses 3 for unverified, while bearings-report uses 2. Do not copy the 3. Make the file executable (`git update-index --chmod=+x` if needed).

---

### `test/crosswake/bearings_report_test.exs` (test)

**Analog:** `test/crosswake/proof/absence_is_not_success_test.exs`.

**Shape** (lines 14-17, 326-332): `use ExUnit.Case, async: true`, `@repo_root Path.expand("../../..", __DIR__)`, `@script Path.join(...)`, and a `run` helper that shells out and captures exit code plus output:
```elixir
defp run_argv(argv) do
  System.cmd("elixir", [@script | argv], stderr_to_stdout: true, cd: @repo_root)
end
```
**Negative-control rule** (moduledoc lines 9-14): each check has a positive case and a negative control, and the negative control asserts the specific check id or line text, never merely a non-zero exit. Use `@tag :tmp_dir` fixtures (lines 24, 28, `baseline!/1` at 335-345 builds the smallest tree where every scope is non-empty).

**Differences to apply (D-10):** call the module's `run/2` with an injected fake runner (a map keyed by `{cmd, args}`) rather than shelling out, except for one end-to-end launcher smoke test. The nine D-12a controls are: `gh` error gives exit 2; `[]` gives UNVERIFIED; SHA mismatch caught; failed fetch caught; 121-line ROLLING breaks the cap; missing cap file is UNVERIFIED; 15-day-old PR is stale (injected clock); satisfied `fires_when` fires; an always-`{:ok, ""}` runner never yields OK. Add a shape-guard test on the real captured fixtures and a truncation (40-line overflow-count) test.

**Ownership:** `script/check_exunit_ownership.exs` (lines 1-60) requires every `test/**/*_test.exs` to be owned by the merge-blocking lane `phase130-core-hermetic-proof` (`mix test --exclude requires_example_host --exclude advisory_only`). A plain ExUnit file with no exotic tags is owned automatically. Do NOT tag it `:advisory_only` (that excludes it), and run `elixir script/check_exunit_ownership.exs` once to confirm. Warning from CONTEXT D-12: no ExUnit test may read the live REQUIREMENTS file.

**Also bump** `script/check_absence_is_not_success.exs` `@scopes` `{"test-files", "test/**/*.exs", 253}`: the pin is a minimum, and adding files never goes red (lines 66-71), so no bump is required. Leave it.

---

### `test/fixtures/bearings/*` (fixtures)

**Analog:** `test/fixtures/ci/classifier/cases.json`, `test/fixtures/security/advisory-bearing.lock` (tracked real-shaped fixtures). Capture real `gh run list --json headSha,conclusion,status,databaseId` and `gh pr list --json ...` output once and commit it. AGENTS.md: "Test adapters against the dependency's real output, not invented fixtures." Run the privacy scan on them (PR numbers and titles are public, but check for logins and emails).

---

### Doc-contract test for AGENTS.md (D-13) (test, transform)

**Analog:** `test/crosswake/planning/first_adopter_context_test.exs` lines 395-406:
```elixir
test "governing documents keep GET-6, ... discoverable" do
  assert File.read!("AGENTS.md") =~ ".planning/ADR-FIRST-B2C-ADOPTER.md"
  adr = File.read!(".planning/ADR-FIRST-B2C-ADOPTER.md")
  assert adr =~ "GET-6"
  assert adr =~ "Two independent active adopters"
  assert adr =~ "separately funded business-line mandate"
  assert adr =~ "web-only"
  assert adr =~ "Android"
```
Extend with AGENTS.md assertions: the `allow` and `hold` phrases, "one-use", each gated action class (merges to `main`, release PR, Hex/Maven/iOS publish, tags, remote branch delete), and the ADR path. Add a negative control (a string with a phrase removed fails the same predicate). This analog test already reads `AGENTS.md` and the ADR at the cwd root, so file paths are cwd-relative. AGENTS.md is in `first_adopter_context.ex` `@artifact_globs` (line 30, `:durable`), and so is PROJECT.md (line 36); privacy scans of those files already run, so keep wording generic.

**Approval-gate bullet to keep byte-identical** (`AGENTS.md` lines 56-61); verify with `grep -F` against `git show main:AGENTS.md`:
```
- For a just-displayed, one-use approval gate, accept a plain-language `allow` or `hold`, bound
  internally to that attempt and its displayed scope. The gate is required for merges to `main`,
  merging the release PR, any Hex, Maven or iOS publish, creating or pushing tags, and deleting a
  remote branch. Local commits and pushes of feature branches need no gate. The user never copies
  hashes. An approval is never standing and never transfers to another attempt.
```
The bullet is hard-wrapped at about 100 columns. A byte-identical copy must preserve those newlines and the two-space indents. Use multi-line fixed-string matching (for example `grep -Fzq` or an Elixir `String.contains?` on the whole block), not a per-line grep.

---

### `.planning/ADR-FIRST-B2C-ADOPTER.md` (append amendments A1, A2)

**Analog:** the file's own repeated section format. The last section, "Verification is executable by default" (lines 370-408), ends with the field order. Copy this exact structure (lines 397-408), each label bold on its own line:
```
**Date**

2026-07-31

**Confidence**

High

**Status**

Accepted
```
Section skeleton, per D-08: H2 title, body (Decision), Why, Alternatives, "What would change my mind", then **Date**, **Confidence**, **Status**. The earlier sections show "What would change my mind" as prose before **Date**, so copy a section such as lines 8-45 (GET-6) for the intro order. Section headings use `## <title>` (lines 8, 46, 81, ...). Other notes:
- The ADR body ends with a section starting at line 410 ("Proxy audit..."), so append after the end (line 421), not after line 408.
- Add one Status pointer line in the existing GET-6 section **Status** block (line 42) pointing to A1/A2. Leave line 123 ("Android implementation remains frozen during v21") as dated history.
- Pinned phrases that must remain verbatim: "GET-6", "Two independent active adopters", "separately funded business-line mandate", "web-only", "Android". The reversal text in the file is at about lines 30-32 ("Two independent active adopters need overlapping generalized behavior, or Crosswake receives a separately funded business-line mandate ..."). The test uses a case-sensitive match on "Two independent active adopters".
- Re-run `mix test test/crosswake/planning/first_adopter_context_test.exs` after the edit. The file is `:durable` in `first_adopter_context.ex:31`, so the ADR text must stay free of real-adopter identifiers.

---

### `AGENTS.md` (Android line plus full trim, D-06 and D-13)

**Analog:** itself. The line to replace is lines 52-53:
```
- Android is frozen at its current generator, Maven, JVM, and vector posture. Do not add Android
  features, templates, device proof, parity work, or release requirements during v21.
```
Replace with the D-06 text (verbatim from CONTEXT). PR1 changes only this bullet (and PROJECT.md); the full trim goes in PR2. The Project Context list (lines 3-20, eight numbered pointers) becomes the D-13 order. Sensitive Data Rules (63-75) and How changes land (116-127) stay verbatim. Produce a disposition table covering every bullet of `git show main:AGENTS.md`. The target is at most 90 lines (currently 127).

---

### `.planning/PROJECT.md` (modify)

Exact lines:
- Line 131 (posture line to rewrite per D-06; verify the text at plan time, the SC4 regex did not hit it, so it may use other wording such as "frozen" without "Android" in range; run `sed -n 131p`).
- Line 506 (hit): `- **Platform**: iOS and Android remain library targets; Android stays frozen at its current generator, Maven, JVM and vector posture under the governing ADR.` Rewrite to the D-06 sentence.
- Lines 162, 166 and 493 are milestone history and stay (SC4 allowlist entries).
- Line 491: `The strategic source of truth for the current sequence is .planning/MILESTONE-ARC.md.` Point at `.planning/ROADMAP-ROLLING.md`. Paired test change at `test/crosswake/planning/milestone_arc_closeout_parity_test.exs` lines 88-94 (currently `assert project =~ "strategic source of truth" and project =~ ".planning/MILESTONE-ARC.md"`). Change to assert `ROADMAP-ROLLING.md` is referenced and the MILESTONE-ARC banner string is present. Keep the other tests in that 179-line file.
- Line 586 is a table row ("Treat planning-milestone version tags (vN.0) as distinct from the Hex 0.x release axis ...", a decision row); D-17 asks to "check it is still true". It appears unrelated to the ARC pointer, so confirm what line 586 is meant to be (the CONTEXT cites it next to the ARC change). Possibly the row numbering shifted after earlier edits; grep for "MILESTONE-ARC" in PROJECT.md before editing.

---

### Support-matrix source, renderers, generated guides (the `fix(support-matrix):` commit)

**Analogs:** the files themselves; the replacement text is D-06's. Exact current text:

`lib/crosswake/support_matrix/support_matrix.ex:446` and `:473` (notes strings):
```
"Android retains its frozen generator, Maven, JVM, and shared-vector posture. Checked-in Android host boot is `checked-in public-coordina...
"Generated Android shell artifacts retain the frozen generator, Maven, JVM, and shared-vector posture based strictly on `JVM hermetic pro...
```
Replace only the "retains its frozen ..." clause with the D-06 note ("Android proof and parity cover existing contracts only. Evidence is `JVM hermetic proof` and shared vectors; there is no emulator, device or new-feature claim."), keeping the trailing sentences that follow it. Read the whole line (they are long) before editing.

`lib/crosswake/support_matrix/renderer.ex:378` (table row; wide). Current row title is `| Android during first adopter readiness | advisory evidence frozen at current posture | Android is frozen at its existing generator, Maven, JVM, and shared-vector posture. | No new Android feature, parity, template, emulator/device, or release requirem...`. Rename to `Android (existing contracts)`. Line 399 bullet: `- Android remains available at its existing generated-shell/JVM proof posture but is frozen during first adopter iOS readiness; frozen does not mean ...` (remove "frozen"; keep the "no new Android feature, template, emulator/device or release requirement" boundary).

`lib/crosswake/capability_map/renderer.ex:163`: change only "Android parity and native-control breadth are frozen." to separate Android from native-control breadth. Keep the heading `### Frozen candidates` (line 166).

`lib/crosswake/proof_lane/provenance.ex:39` comment: `# iOS manifest only; the Android manifest is frozen and not read.` Reword comment only (no behavior change).

**Pinning tests to rewrite, not delete:**
`test/crosswake/support_matrix/renderer_test.exs` lines 52-58 and 412-420:
```elixir
test "first adopter readiness preserves Android freeze and makes no unsupported proof claim" do
  guide = Renderer.render(SupportMatrix.canonical())
  assert guide =~ "Android is frozen at its existing generator, Maven, JVM, and shared-vector posture."
```
and
```elixir
test "NAV-06 renders the bounded iOS posture and frozen Android boundary" do
  ...
  "Android retains its frozen generator, Maven, JVM, and shared-vector posture.",
  "Android is frozen during first adopter iOS readiness: no new feature, parity, device, template, or release claim."
```
Rename both test names (they contain "Freeze"/"frozen"), pin the new truth, and add `refute guide =~ <old literal>` for each old string plus a refute for the old row title "Android during first adopter readiness" (grep `test/` for the old title first, per D-05).
`test/crosswake/support_matrix/support_matrix_test.exs` lines 80-86: `for frozen_posture <- ["generator", "Maven", "JVM", "shared-vector"] do assert android.notes =~ frozen_posture end`. The words are still present after the rewrite (Evidence ... `JVM hermetic proof` and shared vectors); verify "Maven", "generator" and "shared-vector" survive, otherwise change the list. Rename the variable.

**Regeneration:** The guide generators were not located in this pass. At plan time, grep `lib/mix/tasks/` for `support_matrix` and `capability_map` (look for `mix crosswake.gen.*` or a `docs` task) and for how the fixtures are generated (grep the manifest generator and `host_command_seam_fixture` writer). The CONTEXT requires: "Never hand-edit". The fixtures and `guides/*.md` hits are at:
`guides/support_matrix.md` lines 92, 99, 121, 285; `guides/capability_map.md` line 49; `guides/native_shell.md` line 33 is hand-written (edit directly).

**CI:** iOS/macOS jobs must pass on PR1's head (golden fixture comparisons). Phase 195 later makes these ignore the `Generated by crosswake X.Y.Z` line, so do not touch that here.

---

### MILESTONE-ARC.md and JTBD banners (docs)

**Analog:** none for banners. Use a dated blockquote directly under the H1 (D-16/D-17), with no heading edits. Constraints:
- `.planning/research/JTBD-AND-USER-FLOWS.md`: H1 is line 1, then bold metadata lines 3-5. Insert the banner after line 5. Heading assertions in `test/crosswake/guides/user_flows_test.exs` lines 49-60 pin "Current JTBD Map", "What Is Fully Covered Today", "Biggest Gaps", "Proposed Ordering", "Diminishing Returns Boundary", "Update Protocol", "Commerce And Paywall Corridor", "Notification-Driven Re-Entry Corridor", "Auth And Account-Security Corridor", "Operator Truth And Diagnostic Surfaces". Banner text should include "Proposed Ordering superseded 2026-10-24 by PERSONAS.md and ROADMAP-ROLLING; not executed".
- `.planning/MILESTONE-ARC.md`: banner under H1; body unedited. `milestone_arc_closeout_parity_test.exs` reads the body.

---

### STATE.md trim to at most 40 lines (D-18)

**Analog:** its own lines 1-45: frontmatter (lines 1-19), "Current Position" (27-34) and "Exact Next Action" (36-44) are the shape to keep. Delete "Accumulated Context" (46-98), "Deferred Items" (99-113) and "Session" (114-118) per D-18, or fold the minimum into the carried-debt link. The frontmatter alone is 19 lines, so Position (about 8) plus Next Action (about 8) fits only if the frontmatter stays at or below about 19. Count with the tool's own counting method, not `wc`, since the cap is checked by `bearings-report`, which counts by reading the file. State the counting method (whether a trailing newline or the blank lines count) once in the plan so `bearings-report` and the plan agree. Note: `gsd-tools` rewrites this file's frontmatter on state updates, so verify the trimmed file survives a `state` command without regrowing sections.

---

### SC4 phase-evidence grep script (D-07)

**Analog:** `.planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/selftest-193.sh` (tracked) for the self-test format, and `privacy-193.sh` in the same directory for scan conventions.

**Selftest format and aggregation to copy** (selftest-193.sh lines 1-9, 24, 33-35):
```bash
#!/bin/bash
# ... requires each to end with `selftest <name>: controls N of N as expected`. Output: fixed labels only.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
...
bash "$f" --self-test > "$OUTD/$n.out" 2>&1; rc=$?
last=$(awk 'NF{l=$0} END{print l}' "$OUTD/$n.out")
ok=$(printf '%s\n' "$last" | awk -v n="$n" '$1=="selftest" && $2==n":" && $3=="controls" && $5=="of" && $7=="as" && $4==$6 && $6>0 {print "yes"}')
```
Sample real outputs: `selftest copyforward-193: controls 24 of 24 as expected` (`193-EVIDENCE/selftest-copyforward-193.out`). Each script supports `--self-test`; capture `rc=$?` explicitly (no pipe to `tail`, per the project memory on masked exit codes). Note `selftest-193.sh` sources `paths-193.sh` (a phase-193 file); copy the pattern, not the dependency.

**Hit set today (the SC4 regex run on the D-05 scope, measured now on this branch):** AGENTS.md:52; ADR:123; `crosswake_manifest.json:1298,1748`; `host_command_seam_fixture.json:497,947,1415,1865`; PROJECT.md:162,166,493,506; `renderer_test.exs:56,412,418,419`; `guides/support_matrix.md:92,99,121,285`; `guides/native_shell.md:33`; `guides/capability_map.md:49`; `support_matrix.ex:446,473`; `renderer.ex:378,399`; `provenance.ex:39`; `capability_map/renderer.ex:163` (this last one hits via "Android parity ... frozen"; the first-pass `rg` over `lib` did not print it because the match was truncated by `cut`; re-run uncropped). After PR1, only these should remain: ADR:123, PROJECT.md:162,166,493, and any amendment-history text in the new ADR sections. Key the allowlist by file plus normalized text, not line number.

The D-07 negative control requires at least 8 hits against `git show origin/main:<file>`. The count above on origin/main content exceeds 8 (verified 24+ lines), so the control is feasible.

---

## Shared Patterns

### Fail-closed, absence is never success
**Source:** `script/check_absence_is_not_success.exs` lines 3-20 (moduledoc), 56-90 (scopes)
**Apply to:** `bearings_report.exs`, its tests, the SC4 script
Every read that returns an empty, missing or truncated result is UNVERIFIED. Every check has a negative control that asserts the specific diagnostic.

### Exit-code contract and no piped masks
**Source:** `script/check_release_version_truth.exs` lines 1-15, 173-201; `script/check_required_checks_registered.sh` header
**Apply to:** `bearings-report`, launcher, SC4 script
Capture exit codes explicitly. `set -u`, `export LC_ALL=C`, and `umask 077` as in `selftest-193.sh`.

### Keep bearings-report non-required
**Source:** `script/check_required_checks_registered.sh` and `script/list_merge_blocking_checks.py --producers/--emitters`; `script/required_check_policy.json` (`umbrella_context: "Crosswake CI"`, strict true); `.github/workflows/native-collateral-advisory.yml` (dispatch-only advisory precedent, `on: workflow_dispatch:` at lines 6-7) and `crosswake-ci.yml` (line 29 `continue-on-error: true` precedent)
**Apply to:** `script/bearings-report`
Required checks are derived from workflows. Do not add the script to any `.github/workflows/*.yml` in Phase 194 (the weekly workflow is deferred to v29, per CONTEXT). Check that the ExUnit test is the only CI exposure (via the `phase130-core-hermetic-proof` lane), and that it uses fixtures only, so it never calls live `gh`. Mention: `script/ci_leaf_manifest.json` and `script/check_ci_leaf_manifest.py` pin CI leaves; a new test file does not change that, a new workflow job would.

### Privacy scan before every push
**Source:** `.planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/privacy-193.sh` (tracked)
**Apply to:** both PRs
Per project memory: pass absolute paths as separate zsh args (otherwise exit 2). Rescan after each new commit. The 12 v28 research files have never been pushed (D-04).

### Generated artifacts are regenerated, never hand-edited
**Source:** `guides/support_matrix.md`, `guides/capability_map.md`, both golden JSON fixtures
**Apply to:** the `fix(support-matrix):` commit. Before choosing `fix:` check `release-please-config.json` (186 lines, tracked) for linked components, because touching `packages/crosswake-shell-core-ios/Tests/...` could bump the iOS core component (D-03); fall back to `docs:` and record why.

### Doc-contract tests: banners add, headings never change
**Source:** `test/crosswake/guides/user_flows_test.exs:49-60`, `milestone_arc_closeout_parity_test.exs:88-94`, `first_adopter_context_test.exs:395-406`

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.planning/ROADMAP-ROLLING.md` | doc | none | No rolling NOW/NEXT/LATER roadmap exists. Use SYNTHESIS section 4 draft (`v28.0-research/SYNTHESIS.md`). Closest shape: the workstream `ROADMAP.md`. |
| `.planning/BEARINGS.md` | doc | none | New artifact type. Use SYNTHESIS section 5 and MILESTONE-ARC Durable Lessons. |
| `.planning/PERSONAS.md` | doc | none | Extract from `v28.0-research/JTBD-PERSONAS.md` section 3. |
| Milestone-start convention edit (PLAN-03) | doc | none | Not found in tracked repo files (see facts table). It likely lives in untracked GSD tooling outside the repo. |
| Persona-tag check function | utility | transform | No requirements-tag parser exists. Grammar is `- [ ] **ID** [TAG]:` (live example: `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` line 15 `- [ ] **PLAN-03** [M]: ...`; line 21 `**ADR-01** [P7]`). Tags are `P[1-7]`, `J[1-5]`, `M`, or combos like `P1/J2`. Checked-box lines may be `[x]`; accept both. |
| Seed `fires_when:` evaluator | utility | transform | No `fires_when` field exists in any seed yet. |
| Real captured `gh pr list` / `gh run list` fixtures | fixture | file-I/O | None exist; capture them once with live `gh` (read-only) and commit. |

## Metadata

**Analog search scope:** `script/`, `test/crosswake/{proof,planning,guides,support_matrix}`, `test/fixtures/`, `.github/workflows/`, `docs/`, `.planning/*.md`, `.planning/seeds/`, `.planning/workstreams/quality-ratchet-release/{phases/193*,history,STATE.md,ROADMAP.md,REQUIREMENTS.md}`, `lib/crosswake/{support_matrix,capability_map,proof_lane,planning}`.
**Files scanned:** about 60 (read or grepped).
**Pattern extraction date:** 2026-10-24

**Caveats for the planner:**
1. The workstream `state.json` is git-excluded (not a tracked input). Fixture it in tests.
2. `AGENTS.md` is 127 lines now; the D-13 target is 90.
3. `STATE.md` is 118 lines now; the cap is 40 and the frontmatter alone is 19.
4. The generators for `guides/*` and the golden fixtures, and the milestone-start convention text, were not located in-repo and need a first discovery task.
5. This file cites no `.gsd/capabilities/` mirror paths.
