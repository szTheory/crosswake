---
phase: 185-checks-that-cannot-pass-empty
verified: 2026-10-16T13:00:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/workstreams/quality-ratchet-release/REQUIREMENTS.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-01-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-01-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-02-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-02-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-03-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-03-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-04-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-04-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-05-PLAN.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-05-SUMMARY.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-CONTEXT.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-LOOP-MEASUREMENT.md
  - .planning/workstreams/quality-ratchet-release/phases/185-checks-that-cannot-pass-empty/185-loop-scan.exs
covered_digest: "v3:sha256:c94352c40d81a1d6f83ce96e0737850131391ca778a54ad65fdb5da07c701ddc"
behavior_unverified: 0
advisory:
  - finding: "The example-host phase180_twin_feasibility_test has two failing tests (G2, G6) at their own refute lines, because the example router declares host.study.audio.play. 185-03 did not run the unmodified file, so 'pre-existing' is argued from the stack trace, not shown by a baseline run."
    category: other
    reason: "The commit adds two lines to that file (the :47 floor); the floor passes and the failing lines are elsewhere. The file is excluded from the main suite (requires_example_host), so the suite baseline is unaffected. Worth a one-line decision on whether G2/G6 are a known failure."
    evidence_status: "stack-trace argument only; not reproduced by this verifier"
  - finding: "Four ledger rows differ in rationale text (the cited guard line number), not only in the display field."
    category: other
    reason: "Verified display-derived: rows equal after normalising 'at line N'; keys, shapes, buckets, enclosing text and expressions are unchanged."
    evidence_status: "diff of the committed ledger read by this verifier"
---

# Phase 185: Checks that cannot pass empty Verification Report

**Phase Goal:** Every v25-era check that iterates or scans fails loudly when its input is missing or empty, so a green result always means something was examined.
**Verified:** 2026-10-16
**Status:** passed
**Re-verification:** No, initial verification (candidate commit `25614cf685e2ee299646e04b833293c677023c45` on `b898e110`)

## What was checked and what happened

I confirmed the candidate is at 25614cf6 (parent b898e110) with an empty `git status`, and that it was still empty after I finished. I copied it to a scratch directory with its own build path and ran the six test files this phase touches most (absence checker, twin runtime, twin journey, twin producers, twin receipt, verify_twin task): 134 tests, 0 failures. I did not run the twin, the Simulator, xcodebuild or twin-05.

I also ran the checker myself. With no arguments it exits 0 and prints "scanned 249 test files, pin 249" and "todos 12, seeds 23, deferred-items 11". With `--root /nonexistent-x` it exits 2 with "root does not exist".

Two mutation controls I re-ran on the scratch copy, independent of the executor's log:
- Making `tracked_children` return `{:ok, []}` when the registry is gone (the old behaviour): 3 failures, including "stop_children reports registry_gone, not :ok, when the registry is already gone".
- Putting the `File.stat` pre-filter back into `lock_digests/2`: 2 failures, the "never had the root lockfile" and "never had the host lockfile" source-gate tests.

I read the code changes rather than the summaries: `stop_children`/`stop_all` return `{:error, :registry_gone}` through a try/catch around the registry read; both `lock_digests` functions now digest every lockfile with no stat filter and return `identity_unknown` unless both succeed; `observe_identities` sets `locks` to nil unless both digests exist; the checker has strict argument parsing, pinned `@scopes`, and prints counts. The :289 loop in `twin_receipt_test.exs` has `assert [_ | _] = g["sub_observations"]` plus an exact count from `TwinReceipt.roster/0`.

From the run records: `mutation-185.log` has 20 lines (control 0 passes with 154 tests; 17 mutation controls each fail named tests; the two negative controls 9 and 11 pass, which shows the new floors are the only thing catching an emptied collection). `fix-185.failures` holds only `phase180_twin_feasibility_test.exs:30`, the Phase 184 baseline. The twin history manifest has 87 OK lines and nothing else. No `twin-05` directory exists. The real-candidate probe returned all zeros (`{:ok, %{modified: 0, flagged: 0, excludes: 0}}`). The preflight printed four lines and exited 2 (blocked, no run root created).

## Known deviations judged

1. **Unreadable-lockfile source-gate test is a control, not a red test.** Confirmed in the summary and code: a `chmod 000` file makes git report the tree dirty, so the gate blocks on `source_dirty` before reaching the lock check. The test now injects an unreadable digest. It was not red on old code, which is honest and disclosed. The behaviour it guards is still proven red-then-green elsewhere: the freeze-side real-chmod test (red before the fix), the "never had" tests, and the observation test. Control 19 (per log) does fail this test. Accepted.
2. **Ledger drift beyond the display field.** Confirmed from the commit diff: exactly four rows changed, each shifting the same line numbers in `display` and in the rationale text. Header and bucket counts are identical, and the normalised row comparison is equal. No bucket or key changed. Accepted as display-derived.
3. **Preflight blocks first on the missing run root.** The output ("Create a private run root directory (mode 0700)") shows it. It is a read-only blocked answer that created nothing, which is what the goal needs; D-17's all-zero evidence legitimately comes from `probe_source` on a full HEAD copy and the committed candidate. Accepted.
4. **Example-host G2/G6 failures.** Outside the main suite and not made by this commit's floor (see advisory). Not a gap for GUARD-02, whose floor at :47 passes.

## Observable Truths

| # | Truth (ROADMAP success criterion) | Status | Evidence |
| - | --------------------------------- | ------ | -------- |
| 1 | The absence checker exits non-zero for a nonexistent root, an empty derived scope and a scope below its pin; OK lines print counts; red and green self-tests cover each; Elixir `assertFullScope` copy, no shared module or dependency | VERIFIED | Ran checker: nonexistent root exits 2, default run exits 0 with counts. Controls 1-7 each fail named tests (dot-directory subset, empty tree, below-pin, directory named x.exs, pin raised). `assert_full_scope/2` is in the script itself. |
| 2 | The `twin_receipt_test` :289 loop, and every other unguarded runtime-derived v25 loop, asserts a non-empty collection first; a mutation emptying the collection makes the test fail | VERIFIED | Floor present at the :289 loop. Control 8 (empty `sub_observations`) fails; control 9 (same mutation, floors removed) passes, so the floor is what catches it. Same pair for `ios_entries` (controls 10 and 11). Control 12 for `identity_joins/0`. Scan read 45 files and 96 sites. |
| 3 | A report-mode measurement table lists each v25 loop site and its disposition; no new repo-wide blocking rule unless zero findings | VERIFIED | `185-LOOP-MEASUREMENT.md` has per-file counts for all 45 files and the 96 sites. Commit diff: no `.github/` path, only the checker and the ledger under `script/`, no added `assert/refute Enum.all?/any?(` line. Ledger header and buckets unchanged. |
| 4 | `stop_children/1` errors when its registry is gone; `lock_digests/1` fails closed unless both lockfiles are digested; each proven by a test that fails when the fix is reverted | VERIFIED | Re-ran two reversions myself (3 and 2 failures respectively). Controls 13-19 in the log cover registry, stop_all, journey discard pin, freeze side, source gate and observation. |

**Score:** 4/4 truths verified (0 behavior-unverified)

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| ----------- | ------------ | ------ | -------- |
| GUARD-01 | 185-01, 185-05 | SATISFIED | Truth 1 |
| GUARD-02 | 185-03, 185-04, 185-05 | SATISFIED | Truths 2 and 3 |
| GUARD-03 | 185-02, 185-04, 185-05 | SATISFIED | Truth 4 |

All three IDs appear in plan frontmatter and in REQUIREMENTS.md; no orphans. REQUIREMENTS.md still shows the three checkboxes unticked and the traceability rows "Pending" (the ROADMAP also still says "In Progress"). These are bookkeeping edits for the orchestrator, not code gaps.

### Anti-Patterns / Other Findings

None blocking. Known and recorded as deferred with reopen triggers: a stop failure feeding the run verdict, registry ownership, raising the pin at Phase 188, scan blind spots. A symlinked lockfile used to be skipped at freeze and now blocks (disclosed behaviour change). The fixture-dependent unreadable-file tests need a non-root user.

### Human Verification Required

None.

### Gaps Summary

No gaps. Every requirement rests on checks that asserted something: failing tests named in the mutation log, two reversions reproduced by this verifier, and counts printed by the checker. The candidate checkout was left byte-identical.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
