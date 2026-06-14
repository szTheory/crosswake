# Phase 109: Drift-Prevention Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 109-Drift-Prevention Gate
**Areas discussed:** Check placement & triggers, Coverage model, Detection rules, tokens.css parity

---

Profile is `opinionated` / `minimal_decisive` (technical owner). Per the profile and project memory (research-then-recommend), all four areas were researched inline (codebase scout + full prior-context reads of 107/108 + targeted verification greps confirming current zero-hex state and existing parity coverage), and a single decisive recommendation was locked for each. The user was presented one consolidated confirmation gate rather than four bounced-back questions. User selected **"Lock all & write CONTEXT."**

---

## Check placement & CI triggers

| Option | Description | Selected |
|--------|-------------|----------|
| New step in existing `brand-structural` job (Node, browser-free, fail-fast before Playwright); broaden `on.paths` | Same required check name → no new branch-protection entry (harness-blocked); literally "extends" the gate | ✓ |
| New separate lightweight job / new required check name | Faster on consumer-only changes, but needs a NEW required-status-check (branch-protection blocked) and fragments the gate | |

**User's choice:** Locked recommendation (new step in `brand-structural`).
**Notes:** Accepted trade-off that consumer-only changes now also run the brandbook Playwright suite. Free win: broadening paths to `priv/static/crosswake/**` makes the existing tokens.css parity test fire on direct token edits.

---

## Coverage model

| Option | Description | Selected |
|--------|-------------|----------|
| Curated manifest (explicit per-file list + per-file-type assertions) | Excludes deferred offenders; supports different rules for CSS vs templates | ✓ |
| Glob discovery over `examples/**` + `priv/**` | Auto-covers new files, but flags deferred `offline_study.js` / `step_up_challenge_live.ex` → breaks build day one | |

**User's choice:** Locked recommendation (curated manifest).
**Notes:** Maintainability cost (new consumers must be added) accepted and documented via manifest header comment + contract test.

---

## Detection rules

| Option | Description | Selected |
|--------|-------------|----------|
| Forbid any `#`-hex in listed files + ban `var(--cw-primitive-` + require `var(--cw-` in CSS + forbid retired Tailwind in templates | Stricter than "brand-palette only"; safe because files are zero-hex today; per-file-type | ✓ |
| Match only the 17 brand-palette hexes | Literal reading of criterion #1; misses non-palette drift; needs palette upkeep | |

**User's choice:** Locked recommendation (any-hex + primitive ban + per-file rules).
**Notes:** `#id`-selector guard mandatory; rgba shadow naturally skipped by `#`-hex-only regex.

---

## tokens.css byte-parity

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse existing parity test (`compile-tokens.test.mjs:222`); close gap via path-trigger broadening only | No duplicate tooling; parity covered for free by D-01a | ✓ |
| Add a new parity assertion in the drift script | Redundant with existing covered test | |

**User's choice:** Locked recommendation (reuse existing).
**Notes:** Verified the two tokens.css files are currently byte-identical and the existing test already runs in `brand-structural`.

---

## Claude's Discretion

- Script form: plain `node …mjs` (exit-nonzero) vs. `node --test …test.mjs` — either satisfies the one-command local-runner criterion.
- Exact manifest representation, regexes (subject to D-03 guards), step name/ordering (before Playwright install), full retired-Tailwind blocklist (derive from Phase 108 NORM-04 test).
- Failure-message wording / GitHub `::error` annotations.

## Deferred Ideas

- `offline_study.js` and `step_up_challenge_live.ex` (hex/Tailwind offenders) — excluded from the gate manifest; future normalization follow-up.
- Shadow-opacity token for the token-less rgba box-shadow.
- Glob-based auto-discovery once all `examples/**` offenders are normalized.
- Branch-protection required-status-checks update (harness-blocked; same check name means no new entry needed).
