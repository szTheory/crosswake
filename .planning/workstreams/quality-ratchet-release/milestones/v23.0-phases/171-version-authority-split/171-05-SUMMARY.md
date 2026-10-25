---
phase: 171-version-authority-split
plan: 05
status: complete
executor: orchestrator (recovery — see Provenance)
---

# 171-05 Summary — Weld Inventory, DOC-05 Pass, Measured Sweep

## Task Commits

1. **Task 2b (landed first, out of plan order): thread `approved_version` into the last two hardcoded `--version` literals** — `50a27285` (fix)
2. **Task 1: the occurrence-level weld inventory for all 18 flagged files** — `81723f2e` (docs)
3. **Task 2 + Task 3: DOC-05 terminology pass and requirement ledger** — this commit

## Provenance — executor loss and orchestrator recovery

The 171-05 executor **stalled and was terminated by the stream watchdog** (no progress for 600s)
after committing `50a27285` and `81723f2e`, while staging the DOC-05 commit. This is the second
executor loss in this phase (171-03 was killed by an `ENOTFOUND` API error).

Rather than revert or re-dispatch, the orchestrator assessed the working tree, confirmed every
uncommitted hunk was legitimate Task 2/3 output, **re-ran the measured sweep independently** rather
than inheriting the dead agent's number, and committed the remainder. The DOC-05 diff was reviewed
hunk-by-hunk before commit with particular attention to the three `test/crosswake/proof/` files:
**every change in those files is comment or assertion-message text only — no needle, threshold,
polarity, or assertion logic was touched.** That was verified by reading the full diff, not inferred
from the commit message of an agent that was no longer running.

## The measured sweep (WELD-01 non-vacuity evidence)

Run independently by the orchestrator at branch tip, NOT copied from the executor:

```
grep -rl '0\.2\.1' lib/ script/ .github/workflows/     -> 4 files   (was 18 at phase start)
grep -rn '0\.2\.1' lib/ script/ .github/workflows/ | wc -l -> 5 occurrences
```

**All five surviving occurrences, each accounted for:**

| Occurrence | Classification |
|---|---|
| `.github/workflows/release-please.yml:65` | comment — narrative describing the phase-168 merge |
| `script/check_release_workflow_integrity.exs:1210` | comment — documents the deliberate 171-04 generalization |
| `script/check_release_workflow_integrity.exs:1293` | comment — documents the 171-04 `${VERSION}` interpolation |
| `script/check_release_version_truth.exs:8` | comment — historical narrative about PR #158 |
| `script/collection_assertion_ledger.json:185` | `rationale` display text in a generated ledger; gates nothing |

**Zero are executable. Zero are live gates.** This is the measured count ROADMAP criterion #5
requires — not an assertion that the tree "looks clean".

Reconciliation with the inventory's 49 rows: the inventory catalogues every occurrence across the 18
originally-flagged files at the occurrence level, including sites whose literal was *removed* by this
phase (which therefore no longer appear in a current-tip grep). The sweep above counts what SURVIVES
at tip. The two numbers answer different questions and are both reported rather than collapsed into
one flattering figure.

## The late find — why the sweep earned its place

Task 2b caught a live gate that **171-RESEARCH.md's inventory and all four prior plans missed**:
`release-please.yml`'s `publish-ios-core` (line 568) and `publish-android-core` (line 603) passed
`--version 0.2.1` **literally** to `ios_mirror.sh publish` and `android_publication.sh`. Their `if:`
conditions had been correctly generalized to compare against `approved_version` — which is exactly
why four plans' reviews passed over them — but the publish commands themselves would have shipped
artifacts stamped `0.2.1` the moment release-please bumped past it. That is a direct defeat of
WELD-06's exit criterion, found only because the sweep counted occurrences instead of trusting that
the gates looked right.

## Verification

- `elixir script/check_release_workflow_integrity.exs` — exit 0, **69 of 69**, 0 failed
- `mix format --check-formatted` — clean
- `.github/workflows/release-please.yml` — parses under `yaml.safe_load`
- `mix test --exclude requires_example_host` — see phase VERIFICATION
- Independent sweep — 4 files / 5 occurrences, all non-executable (table above)

## Requirements closed

MSG-04, MSG-05, WELD-01 through WELD-08, DOC-05 — marked Complete in `REQUIREMENTS.md`.
