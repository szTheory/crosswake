# Phase 171 — Plan-Checker Findings and Their Dispositions

`gsd-plan-checker` returned **VERIFICATION PASSED** on 2026-09-17: **0 blockers**, 3 warnings, 2 info,
across all five plans. Both deterministic probes (verify-command path resolvability, failing-direction
coverage) returned clean over all 34 `<automated>` commands.

This file records what was done about each non-blocking finding, so "we accepted it" and "we missed it"
never look the same on disk — the same discipline `VERIFICATION-CONVENTIONS.md` applies to the vacuity
taxonomy's null statement.

| # | Severity | Finding | Disposition |
|---|---|---|---|
| 1 | WARNING | 171-03 estimate 108k vs 100k smart-zone budget (1.08x), 11 files_modified | **Accepted, not split** |
| 2 | WARNING | 171-04 estimate 108k vs 100k smart-zone budget (1.08x) | **Accepted, not split** |
| 3 | WARNING | 171-05 Task 2 runs the full suite as a per-task `<automated>` (6-10 min vs ~30s Nyquist guidance) | **Accepted, not narrowed** |
| 4 | INFO | `171-RESEARCH.md`'s `## Open Questions` heading lacked a RESOLVED marker | **Fixed** |
| 5 | INFO | Criterion #6 says "same commit"; the tripwire deletion and the successor check are two tasks | **Fixed** |

## 1 and 2 — the estimate overages: accepted

`estimate.confidence` is `low` on **all five** plans because `estimate-calibration` has **zero sample
data** for this workstream. The 108k figures are unfactored projections, not measurements, and the
overage is 8%.

Re-slicing on an uncalibrated 8% is acting on a number that does not yet mean anything — it would cost a
full replanning cycle and buy no information. The plans are also honest about their own risk: the planner
independently named 171-03 and 171-04 as the likeliest to need mid-flight splitting. An executor that hits
the wall can split then, against a real measurement rather than a projection.

**What would change this:** once this workstream has calibration samples, a repeat overage is evidence
rather than noise, and should be acted on.

## 3 — the full-suite run in 171-05 Task 2: accepted, deliberately

The checker's fix hint was to narrow Task 2's per-task `<automated>` to the quick-run command and leave
the full suite at the plan's phase-level `<verification>` block.

Declined. Nyquist's feedback-latency guidance targets *iteration* — keeping the loop tight while work is
in flight. 171-05 Task 2 is not an iteration step: it is the terminal reconciliation of the whole phase,
the last thing that runs before the blocking human checkpoint that authorizes the one PR. The full suite
is the strongest evidence available at exactly the point where the evidence matters most.

Narrowing it would trade real proof for a green guideline. That is the shape of defect milestone v23.0
exists to remove, so it is not an acceptable trade here even though the guideline is a good one in general.

## 4 — research Open Questions marker: fixed

`## Open Questions` is now `## Open Questions (RESOLVED — see the Orchestrator Addendum ...)`, with an
inline `**RESOLVED**` marker and a pointer on each of the two questions. The original wording is kept so
the provenance of each answer stays legible. Both were already resolved in substance by the Addendum; this
closes a documentation-convention gap only.

## 5 — "same commit" for criterion #6: fixed

ROADMAP success criterion #6 requires the tripwire to be deleted *"in the same commit that lands the
successor check as merge-blocking."* Those are 171-01 Task 2 and Task 3 — two tasks, therefore two commits
on the branch under this project's per-task commit convention.

A **squash merge collapses them into one commit on `main`**, satisfying the criterion literally. A merge
commit or rebase-merge would not. This was implicit; it is now an explicit, stated item (#6) in 171-05
Task 3's human checkpoint, including the note that this repo refuses `--admin` merge and the exact
command. Without it, the phase could ship every behavior correctly and still fail criterion #6 on a
merge-button choice made at the end.
