# Phase 30: Hex Page Polish And Tarball Dry-Run - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 30-hex-page-polish
**Areas discussed:** README.md Link Rewrite Strategy, Docs Structure / Polish, Tarball Exclusions

---

## README.md Link Rewrite Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| README.md Link Rewrite Strategy | What URL target to use for absolute links (e.g., `main` branch vs release tag)? | ✓ |

## Docs Structure / Polish

| Option | Description | Selected |
|--------|-------------|----------|
| Docs Structure / Polish | Should we customize ex_doc groups, add extra pages, or keep it basic? | ✓ |

## Tarball Exclusions

| Option | Description | Selected |
|--------|-------------|----------|
| Tarball Exclusions | How aggressively should we exclude files (e.g., examples/, script/)? | ✓ |

**User's choice:** The user selected all three areas and requested a cohesive, comprehensive recommendation.
**Notes:** The user provided the following instructions for the choices:
"research using subagents, what is pros/cons/tradeoffs of each considering the example for each approach, what is idiomatic for elixir/plug/ecto/phoenix for this type of lib/app and in this ecosystem, lessons learned from other libs/apps in same space even from other languages/frameworks if thehy are popular successful, what did they do right that we should learn from, what did they do wrong/footguns we can learn from, great developer ergeonomics/dx emphasized... user friendly (if it's a lib or app), think deeply one-shot a perfect set of recommendations so i dont have to think, all recommendations are coherent/cohensive with each other and move us toward the goals/vision of this project... using great software architecture/engineering, principle of least surprise and great UI/UX wheere applicable great dev experience... also consider all of the information inside of our prompts subdir where applicable since we have some great research in there... liek best practices pros/cons/tradeoffs vision etc..."

Based on these instructions, we made decisions D-01 through D-06 in `30-CONTEXT.md` emphasizing native Elixir Hex hygiene.

---

## Claude's Discretion

None explicitly identified as "you decide" apart from the user delegating the deep thinking and recommendation formulation.

## Deferred Ideas

None
