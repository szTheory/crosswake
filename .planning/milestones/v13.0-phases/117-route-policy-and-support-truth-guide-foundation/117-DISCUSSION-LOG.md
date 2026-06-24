# Phase 117: Route-Policy And Support-Truth Guide Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-18T20:37:43Z
**Phase:** 117-Route-Policy And Support-Truth Guide Foundation
**Areas discussed:** Route-policy guide shape, Web-to-mobile migration guide, Support-truth vocabulary, README and ExDoc wiring

---

## Route-Policy Guide Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Dedicated `guides/route_policy.md` | Creates a clear GUIDE-01 anchor while keeping `user_flows` as narrative context. | yes |
| Promote/rename `guides/user_flows.md` only | Lower file churn, but risks burying DSL/source-of-truth examples in a JTBD narrative. | |
| Fold route-policy doctrine into README | Makes the front door heavy and duplicates guide material. | |

**User's choice:** User delegated selection to Claude with "decide automated" / "do it all for me".
**Notes:** Auto-selected the dedicated route-policy guide because Phase 117 needs a durable anchor for downstream quick start, migration, support labels, and ExDoc grouping.

---

## Web-To-Mobile Migration Guide

| Option | Description | Selected |
|--------|-------------|----------|
| Route inventory worksheet | Existing Phoenix SaaS teams inventory routes by user job, default to LiveView, and promote only where justified. | yes |
| Capability catalog | Starts from device features and risks drifting into plugin/API framing. | |
| Quick-start walkthrough | Belongs to Phase 118 and would blur conceptual migration with command verification. | |

**User's choice:** User delegated selection to Claude.
**Notes:** Auto-selected the route inventory worksheet. It aligns with MIGRATE-01 and keeps Crosswake route-owner-first.

---

## Support-Truth Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Friendly legend plus canonical matrix | Gives new readers proof labels before the dense matrix while preserving `support_matrix` as source of truth. | yes |
| New independent support-truth guide as source | Easier prose surface, but risks creating a second truth source. | |
| Dense matrix only | Accurate, but too intimidating for first-read adoption. | |

**User's choice:** User delegated selection to Claude.
**Notes:** Auto-selected the friendly legend plus canonical matrix. A helper guide is allowed only if it does not replace generated support truth.

---

## README And ExDoc Wiring

| Option | Description | Selected |
|--------|-------------|----------|
| Compact front-door wiring | README and ExDoc guide groups point to the new route-policy path and support labels without duplicating full guides. | yes |
| Full guide content in README | Puts everything in the first page, but makes README too heavy. | |
| Leave entry points unchanged | Lowest churn, but fails Phase 117's first-read success criteria. | |

**User's choice:** User delegated selection to Claude.
**Notes:** Auto-selected compact README/ExDoc wiring. The recommended grouping is Start, Adopt, Runtime Owners, Truth, Advanced/Companions.

---

## Claude's Discretion

- The user explicitly asked Claude to decide and automate the discussion.
- Claude selected all key gray areas and chose conservative defaults grounded in roadmap, requirements, research, Phase 116 context, and existing docs/code.
- Claude kept the automation scoped to Phase 117 context capture, not Phase 118 planning/execution.

## Deferred Ideas

- Full quick-start and adoption guide rewrite remains Phase 118.
- Native evidence classification remains Phase 119.
- Collateral capture and full troubleshooting guide remains Phase 120.
