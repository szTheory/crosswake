# Phase 186: Host seam and harness honesty - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-16
**Phase:** 186-host-seam-and-harness-honesty
**Areas discussed:**
- Legacy manifest denial
- Stale check
- Path redaction
- Loopback harness
- Physical-iPhone preparation
- Order of work

**Method:** The user prefers research first, then one recommendation. One read-only research agent read the 181 and 182 reviews, the 184 and 185 decisions, and the candidate at `25614cf6`. It ran no tests and changed no files. It returned one recommended set covering all six areas, and the user approved the whole set with a single answer.

---

## Recommendation set

| Option | Description | Selected |
|--------|-------------|----------|
| Approve all | Lock D-01..D-19 as written in 186-CONTEXT.md | ✓ |
| Adjust one area | Change one decision before writing the context | |

**User's choice:** Approve all.

### Alternatives the research weighed (summary)
- **Legacy denial.** The rejected alternative was a compatibility window, or a new reason string. Schema 1.2.0 and the API must stay unchanged, and regenerating is the repair.
- **Stale check.** Separate codes for each case were rejected in favour of one code with `details.reason`, which matches success criterion 2 literally. Silent skipping was rejected in favour of an advisory finding.
- **Redaction.** A new shared module was rejected; the requirement says "one copied helper". A whole-output scan of doctor was rejected because it would sweep in path leaks that existed before this phase.
- **Harness.** Relying on `set -e` alone was rejected, because `cleanup_and_emit` runs under `set +e` by design and so needs explicit checks.
- **LOOP-07.** "Assume the generator refusal covers it" was rejected after grep showed that the physical-iPhone path never reads the origin mode. The red test decides.

## Claude's Discretion
- The wording of messages and hints, the fixture layout, and where the tests go.

## Deferred Ideas
- 182 WR-06 and IN-03.
- The harness uninstalling an app the user had already installed.
- 185 WR-02 through WR-05.
- Other absolute paths in doctor output.
- `hostCommandDeniedVersions` is empty on legacy routes.
