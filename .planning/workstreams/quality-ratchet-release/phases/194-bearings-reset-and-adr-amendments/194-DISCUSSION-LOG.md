# Phase 194 Discussion Log

**Date:** 2026-10-24
**Mode:** advisor (calibration `minimal_decisive`), with parallel research followed by one merged set of recommendations
**Human reference only. Downstream agents read 194-CONTEXT.md.**

## Areas presented
1. PR packaging
2. Frozen-text boundary
3. bearings-report build
4. AGENTS.md trim scope

**User selection:** all four. The user asked for each area to be researched in parallel across every relevant viewpoint, with an adversarial pass, and for the merged recommendations to be adopted without further questions. The user prefers copy-paste over a new dependency.

## Research and outcome

| Area | Options weighed | Adopted |
|---|---|---|
| PR packaging | A: one phase PR. B: an ADR PR (with the milestone-start commits) and then a bearings PR | B (D-01..D-04). The commit prefix is changed from all-`docs:` to `fix(support-matrix):` for the public-claim commit, with a fallback after checking the release-please config. |
| Frozen-text boundary | A: 194 owns every live surface. B: 194 changes only the rule texts | A (D-05..D-08). `native_shell.md:33` moves into 194. Two golden fixtures were found to embed the matrix notes, and this was verified in the session. |
| bearings-report build | A: Elixir `.exs` with an injected runner and ExUnit. B: bash with PATH shims | A (D-09..D-12a). Seeds without a machine trigger count as info, not attention, so that Phase 199's exit 0 stays possible. Backfilling those seeds is deferred to E7. |
| AGENTS.md trim | A: full trim in 194 through a recorded roadmap change. B: minimal edit, defer the trim | A (D-13..D-18). Current Priority is kept, not collapsed. The BEARINGS and ROLLING drafts are corrected. MILESTONE-ARC gets a banner and is not moved. |

## Conflicts resolved during synthesis
- The researcher proposed a `fires_when` attention check, which would leave the report permanently non-zero because about 20 seeds are prose-only. This became a counted info line, with a LATER row.
- The PR researcher found the fixtures embed the frozen string; the frozen-text researcher had missed them. Grep confirmed it, and the fixtures were added to D-05 and the D-07 scope.
- ROLLING and BEARINGS state that Android is unfrozen, which would be status written before the event. Landing them in PR2 after PR1 merges resolves this.

## Roadmap change recorded
PLAN-02 and Phase 194 SC1 now include the AGENTS.md trim to at most 90 lines (or the measured cap), which was already approved in v28.0-SCOPE decision 6. There are still 30 requirements.

## Deferred
E7 seed normalization, the E6 debt-row template, the E4 PROJECT.md split, relaxing the ARC parity tests, trimming the adopter STATE, and the weekly bearings workflow (v29).
