# Phase 136: Core Decoupling - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-30
**Phase:** 136-core-decoupling
**Areas discussed:** PII baseline denylist, Finding-refactor timing, Guard false-positives, reserved-events test

---

**Discussion mode:** Phase is heavily pre-locked by design spine D-1..D-9. Presented the four
genuinely-open gray areas beneath the spine; user selected **all four** and requested a deep,
research-backed, coherent one-shot recommendation set (rather than sequential Q&A). Four parallel
`gsd-advisor-researcher` subagents (Sonnet) investigated codebase + `prompts/` corpus + ecosystem
precedent; the synthesized recommendations were adopted as the locked decisions.

---

## PII baseline denylist (D-5 / DECOUPLE-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Exact-atom MapSet, 10 keys | Hardcode 10 auth-token/identity/PII atoms; exact membership; union with companion keys, cached at attach | ✓ |
| Substring/regex on stringified keys | Phoenix `filter_parameters` style | |
| Broad union of all ~39 companion keys | Core owns everything companions declare | |

**User's choice:** Exact-atom MapSet baseline of 10 keys (adopted from research synthesis).
**Notes:** Substring matching rejected — drops metric keys (`:notification_token_count`) and hits
atom/string-mismatch footgun. Companion-specific creds (PKCE, push tokens, nonce) stay
companion-owned. Expose public `baseline_forbidden_metadata_keys/0`; additions=minor, removals=major.

---

## Finding-refactor timing (D-2 / D-4)

| Option | Description | Selected |
|--------|-------------|----------|
| Denial in 136, Finding in 137 | `evaluate_auth/3` returns `Denial.t()`; pure passthrough; Finding refactor deferred to extraction | ✓ |
| Finding-forward into 136 | Refactor sigra internals to emit `Finding.t()` now; add `:auth` axis in 136 | |

**User's choice:** Denial-in-136 (adopted from research synthesis).
**Notes:** Finding-forward stacks two axes of change on 136 — `StepUpCeremony` matches `%Denial{}`
directly and `sanitize_details` runs inside sigra's `deny/4`. `Finding` has no `:auth` axis today
(falls through to `:compatibility_mismatch`). Those become explicit Phase-137 prerequisites.

---

## Guard false-positives (DECOUPLE-06)

| Option | Description | Selected |
|--------|-------------|----------|
| AST `__aliases__` prefix-walk | Extend existing `companion_guard.ex`; ignores prose/comments/atoms by construction; stdlib-only | ✓ |
| `mix xref` compile-dep graph | First-class tool | |
| `boundary` hex lib | Declarative module-boundary enforcement | |
| grep/regex + allowlist | Shell-scriptable | |

**User's choice:** AST prefix-walk (adopted from research synthesis).
**Notes:** Research found the current guard uses **exact list-match**, silently missing child
modules (`Sigra.Evaluator` etc.) — must switch to prefix containment. Scope = `lib/**/*.ex` minus
`lib/crosswake/companions/**`. `mix xref` misses alias-only refs; `boundary` is a new dep/overkill.

---

## reserved-events test (D-6)

| Option | Description | Selected |
|--------|-------------|----------|
| Shape assertion + keep stub-seeded merge test | Count-independent struct-contract on `:reserved` tier + existing `:active` membership test | ✓ |
| Shape assertion only | Drop count, assert struct shape | |
| Stub-seeded only | Deterministic count from a known stub | |

**User's choice:** Both, on separate concerns (adopted from research synthesis).
**Notes:** Drop `length(reserved_events) >= 24`. Shape assertion passes with zero companions
(reserved set legitimately empty). No magic numbers. Each companion owns its own Side-A proof.

---

## Claude's Discretion

- Exact helper names / module placement for runtime aggregation (`@auth_contract_truth` /
  `@notification_support_truth` module-attributes → `def` runtime helpers).
- Guard failure-message wording and public `@doc` text.

## Deferred Ideas

- Finding-boundary refactor for sigra auth (`:auth` axis, StepUpCeremony re-point,
  `sanitize_details` move, `Denial.new` call-site audit) → Phase 137.
- Per-companion Side-A telemetry contract tests → Phases 137-140.
- `Crosswake.Live.Threadline` Phoenix-dep-optional consideration → Phase 139.
