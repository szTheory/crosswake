---
phase: 174-clean-room-host-realism-adopter-fidelity
plan: 02
subsystem: release-infra
tags: [doctor, manifest-contract, byte-identity-guard, shell-harness, exunit, vacuity-taxonomy]

requires:
  - phase: none
    provides: git history at commit 8bc77c35157e78da0a6a8b06301cfac48f5dc301 (the pinned baseline
      source) — no other Phase 174 plan's work is a dependency of this one.
provides:
  - script/assert_manifest_contract_unchanged.sh — a mechanical byte-identity guard for
    doctor.ex's manifest_compile_check/1 and its single call site
  - test/support/fixtures/phase174/manifest_contract_baseline.txt — a committed,
    provenance-stamped baseline pinned to commit 8bc77c35157e78da0a6a8b06301cfac48f5dc301
  - Crosswake.Proof.Phase174ManifestContractImmutabilityTest — five separately-named mix test
    cases proving the guard's positive case and its four failure modes against the real script
affects: []

actuals:
  tokens: 4221
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "awk's `-v name=value` silently strips backslash escapes from `value` (it interprets
      C-style escape sequences), which breaks any `\\(` `\\)` passed that way for ERE grouping
      escapes. Export the pattern as an environment variable and read it back via
      `ENVIRON[\"NAME\"]` inside the awk program instead — this reaches awk's regex engine with
      no escape processing in between."
    - "Under `set -euo pipefail`, capturing `diff`'s output via `$(diff a b | head -1)` for a
      diagnostic message aborts the script immediately when the files differ, because `diff`
      exits 1 on any difference and that status propagates through the pipeline. Appending
      `|| true` to that specific diagnostic-only capture is correct here — the guard's actual
      verdict is still an explicit `exit N`, never taken from this pipeline's status."

key-files:
  created:
    - script/assert_manifest_contract_unchanged.sh
    - test/support/fixtures/phase174/manifest_contract_baseline.txt
    - test/crosswake/proof/phase174_manifest_contract_immutability_test.exs
  modified: []

decisions:
  - "Chose four exit-code result tokens exactly as the plan's artifact table specifies —
    MANIFEST_CONTRACT_UNCHANGED_VERIFIED (0), MANIFEST_CONTRACT_EXTRACTION_EMPTY (3),
    MANIFEST_CONTRACT_DEF_DRIFT (4), MANIFEST_CONTRACT_CALL_DRIFT (5) — rather than a fifth
    call-region-specific empty token. A renamed function and a deleted call site both surface
    as MANIFEST_CONTRACT_EXTRACTION_EMPTY, distinguished by message text naming which region
    (\"definition of manifest_compile_check/1\" vs \"call site\"), matching the artifact table's
    explicit four-token inventory rather than the acceptance criteria's looser \"call-region
    result token\" phrasing."
  - "Did not register the guard as a new script/verify_repository.mjs stage. That facade's
    purpose inventory is a closed, ordered list validated by its own manifest-shape check;
    the guard is reached by the ordinary mix test lane through the proof test module instead,
    which already runs in CI. Recorded per Task 2's explicit instruction to state this choice
    in the SUMMARY."
  - "Region DEF and Region CALL extraction uses grep -E / awk with ENVIRON-passed patterns
    consistently (not grep's default BRE), after discovering BSD grep's default BRE treats
    unescaped parens as literal and \\( \\) as grouping — the opposite of ERE, and opposite of
    what awk's regex engine expects for the same pattern string."

metrics:
  duration: ~45 min
  completed: 2026-09-18

status: complete
---

# Phase 174 Plan 02: Manifest Contract Byte-Identity Guard Summary

Added a mechanical guard, `script/assert_manifest_contract_unchanged.sh`, that decides —
by byte comparison against a git-history-pinned baseline, never by review — whether `doctor`'s
`manifest_contract` check (`manifest_compile_check/1` and its single call site) has drifted from
its pre-Phase-174 state, satisfying ROADMAP Success Criterion 6 (ROOM-06).

## What Was Built

**Task 1 — the guard and its baseline.** `test/support/fixtures/phase174/manifest_contract_baseline.txt`
is a committed fixture, extracted from `git show 8bc77c35157e78da0a6a8b06301cfac48f5dc301:lib/crosswake/doctor/doctor.ex`,
containing two regions:

- **Region DEF** — the full 47-line source of `manifest_compile_check/1` (private function,
  opening `defp` line through its matching `end`).
- **Region CALL** — the single line `manifest_findings = Enum.map(errors, &manifest_compile_check/1)`.

The fixture's header records the source commit, source path, extraction method, and the
SHA-256 of Region DEF as extracted (`6afa9c1c8a9563a5ab1cfeb08afb05368086abdf1a7bf3b8267ef835c8e57bac`,
awk extraction, trailing newline included) — reproduced exactly against the digest the plan
recorded at author time.

`script/assert_manifest_contract_unchanged.sh` takes optional `--source` (default
`lib/crosswake/doctor/doctor.ex`) and `--baseline` (default the committed fixture), extracts
the same two regions by the same method from `--source`, and runs three assertions in order,
each with its own result token:

1. **Extraction non-empty.** Both regions must be non-empty AND their pattern must match
   exactly once in the source (`grep -Ec` count == 1). This runs BEFORE any comparison, so a
   renamed or deleted function — which would otherwise produce an empty extraction compared
   against a non-empty baseline (still correctly caught by assertion 2/3) or, in a pathological
   case, two empty extractions comparing equal — cannot be scored as unchanged.
2. **Region DEF byte identity** — `diff -q` against the baseline; on failure, reports the
   first differing line and states plainly that reverting `doctor.ex` is correct, not editing
   the baseline.
3. **Region CALL byte identity** — the same check, run separately, so deleting the call site
   while leaving the function body intact is caught as `MANIFEST_CONTRACT_CALL_DRIFT` rather
   than silently passing because Region DEF alone still matched. (In practice, deleting the
   capture syntax entirely drops the call-site occurrence count to zero, which assertion 1
   catches first as extraction-empty — assertion 3 is reachable for any call-site edit that
   preserves the capture syntax but changes surrounding text, demonstrated below.)

**Task 2 — the proof test.** `Crosswake.Proof.Phase174ManifestContractImmutabilityTest` invokes
the real shell script via `System.cmd/3` for five separately-named cases (no shared "it failed"
assertion, no Elixir re-implementation of the extraction rule): the real repository source, a
one-byte edit inside the function body, a renamed function, a deleted call site, and an empty
source file.

## Non-Vacuity Evidence — the required mutations, actually run

All five commands below were executed for real during this plan, against real temp copies of
`lib/crosswake/doctor/doctor.ex`. `doctor.ex` itself was never modified — every mutation ran
against a `--source` override pointing at a throwaway copy.

| # | Mutation | Command | Observed exit | Observed token |
|---|----------|---------|----------------|-----------------|
| 1 | Unmodified working tree | `bash script/assert_manifest_contract_unchanged.sh` | **0** | `MANIFEST_CONTRACT_UNCHANGED_VERIFIED` |
| 2 | One byte changed inside `manifest_compile_check/1` (`"manifest_invalid"` → `"manifest_invalie"`, line 1943) | `bash script/assert_manifest_contract_unchanged.sh --source <copy>` | **4** | `MANIFEST_CONTRACT_DEF_DRIFT` |
| 3 | Function renamed (`manifest_compile_check` → `manifest_compile_check_renamed`, both def and call site) | same, `--source <copy>` | **3** | `MANIFEST_CONTRACT_EXTRACTION_EMPTY` (message: "expected exactly 1 definition ... found 0") |
| 4 | Call-site capture deleted, function body intact (`manifest_findings = Enum.map(errors, &manifest_compile_check/1)` → `manifest_findings = []`) | same, `--source <copy>` | **3** | `MANIFEST_CONTRACT_EXTRACTION_EMPTY` (message: "expected exactly 1 call site ... found 0") |
| 5 | Empty source file | same, `--source <copy>` | **3** | `MANIFEST_CONTRACT_EXTRACTION_EMPTY` |
| 6 (extra, beyond the plan's required 4) | Call line present but reformatted with a trailing comment (capture syntax intact, so occurrence count stays 1) | same, `--source <copy>` | **5** | `MANIFEST_CONTRACT_CALL_DRIFT` |

Row 6 was run in addition to the plan's four required mutations specifically to exercise
`MANIFEST_CONTRACT_CALL_DRIFT` on its own drift path (as opposed to via extraction-empty),
proving assertion 3 is reachable and not merely a symmetrical copy of assertion 2 that never
fires in practice.

All mutation copies and their temp directories were removed after the manual runs; the only
mutation artifacts that persist are the five `System.cmd`-driven cases inside
`Crosswake.Proof.Phase174ManifestContractImmutabilityTest`, which regenerate and clean up their
own temp files on every `mix test` run via `on_exit/1`.

`git diff --name-only HEAD -- lib/crosswake/doctor/doctor.ex` printed nothing at every checkpoint
in this plan — `doctor.ex` was read eleven times and never written.

## Vacuity Taxonomy (for the phase-close verifier)

- `check_id`: `manifest_contract.byte_identity`
- `shape`: **A** — an `Enum.all?`/`Enum.any?`-shaped possibly-empty-collection risk. The guard's
  `grep -Ec`/`awk` extraction of a live source file could return empty on a renamed or deleted
  function; comparing two empty extractions would otherwise pass silently. Mitigated by
  asserting non-emptiness and exact occurrence count (assertion 1) before either identity
  comparison runs.
- `non_vacuity_evidence`: rows 1–6 of the table above — six real, independently executed runs
  against real mutated copies, covering the positive case and every named failure mode.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `awk -v` silently corrupted the escaped-paren regex pattern**
- **Found during:** Task 1, first manual run of the guard against the real (unmutated)
  `doctor.ex`. The guard reported `MANIFEST_CONTRACT_EXTRACTION_EMPTY` against the untouched
  source file — a false negative on the guard's own positive case.
- **Issue:** `awk -v pattern="$P"` interprets C-style backslash escapes inside the assigned
  string. The pattern `^  defp manifest_compile_check\(error\) do$` had its `\(` `\)` escapes
  silently stripped before reaching awk's regex engine, turning the ERE grouping-escape into
  unescaped grouping metacharacters that do not require literal parens in the matched text —
  the extraction then matched nothing.
- **Fix:** Exported the pattern as an environment variable and read it inside the awk program
  via `ENVIRON["NAME"]`, which reaches awk's regex engine with no escape preprocessing.
- **Files modified:** `script/assert_manifest_contract_unchanged.sh`
- **Commit:** `5a041ce0`

**2. [Rule 1 - Bug] BSD `grep`'s default BRE parenthesis semantics disagreed with the awk pattern**
- **Found during:** Task 1, same debugging session as above.
- **Issue:** The same escaped-paren pattern, used with plain `grep -c` (default BRE) instead
  of `grep -Ec` (ERE), treats unescaped `(` `)` as literal characters and `\(` `\)` as grouping
  — the reverse of ERE. The pattern authored for ERE (matching awk's engine) therefore matched
  zero occurrences under BRE.
- **Fix:** Switched the occurrence-count checks to `grep -Ec` (ERE) so the same pattern string
  behaves identically across both tools.
- **Files modified:** `script/assert_manifest_contract_unchanged.sh`
- **Commit:** `5a041ce0`

**3. [Rule 1 - Bug] `set -e` + `pipefail` aborted the script inside the drift-message diagnostic**
- **Found during:** Task 1, first byte-drift mutation run. The script exited with bare code 1
  and no `MANIFEST_CONTRACT_DEF_DRIFT` message at all, instead of the intended exit 4.
- **Issue:** `FIRST_DIFF_LINE="$(diff "$A" "$B" | head -1)"` runs inside a command substitution
  under `set -euo pipefail`. `diff` exits 1 whenever its inputs differ (by design — that's how
  the guard knows to report drift), and `pipefail` propagates that non-zero status to the
  substitution's own exit status, which `set -e` then treats as a script-aborting failure
  before the drift message could even be printed.
- **Fix:** Appended `|| true` to that specific `diff | head -1` capture. This is safe because
  the capture is diagnostic-only (naming the first differing line inside the failure message);
  the guard's actual pass/fail verdict is decided by the preceding `diff -q` check and reported
  via an explicit `exit 4` / `exit 5`, never by this pipeline's status — consistent with the
  plan's prohibition on taking a verdict from a pipeline tail.
- **Files modified:** `script/assert_manifest_contract_unchanged.sh`
- **Commit:** `5a041ce0`

**4. [Rule 1 - Bug] Test file was not `mix format`-compliant on first write**
- **Found during:** Task 2, final verification pass.
- **Issue:** `mix format --check-formatted` flagged one line in
  `test/crosswake/proof/phase174_manifest_contract_immutability_test.exs` exceeding the
  project's line-length convention.
- **Fix:** Ran `mix format` on the file before committing.
- **Files modified:** `test/crosswake/proof/phase174_manifest_contract_immutability_test.exs`
- **Commit:** `1b1037b1`

No architectural changes were needed; no Rule 4 escalation occurred.

## Self-Check

- `script/assert_manifest_contract_unchanged.sh` — FOUND
- `test/support/fixtures/phase174/manifest_contract_baseline.txt` — FOUND
- `test/crosswake/proof/phase174_manifest_contract_immutability_test.exs` — FOUND
- Commit `5a041ce0` (Task 1) — FOUND in `git log --oneline`
- Commit `1b1037b1` (Task 2) — FOUND in `git log --oneline`
- `lib/crosswake/doctor/doctor.ex` — untouched (`git diff --name-only HEAD` prints nothing for
  this path)

## Self-Check: PASSED
