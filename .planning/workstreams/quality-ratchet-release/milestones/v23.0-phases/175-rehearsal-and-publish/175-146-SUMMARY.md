---
phase: 175-rehearsal-and-publish
plan: 146
status: complete
requirements_completed: []
completed: 2026-10-11
---

# Plan146: Production preflight interface repaired

The apply runner expected a status field that the production preflight API never returns. The replacement runner accepts only the exact raw four-field shape, supplies the internal status, and still requires every existing fact/count/permission/preview check. Failed diagnostics, extra provider fields and drift cannot be promoted.

The replacement keeps the original runner and its attempt auditable. New Plan146 Mix modes use additive module/collector files. Safe enumerated failure reasons are sealed in outcomes and shown by the terminal inspector. Source-preparation Git commands now request quiet output; unexpected stderr still blocks.

Verification: twelve Node tests passed, including production snapshot normalization, raw API shape, malformed/failed/drifted data, helper startup with every external boundary denied, durable intent, rejection and ambiguous delivery. Fourteen focused old/new Elixir tests passed. The independent local audit validates Plan145's terminal digest/event/count chain and confirms the three earlier frozen collectors plus Plan144 are unchanged. Audit: evidence/175-plan146-local-repair-audit.json.

No remote request, push or attempt preparation was performed by this repair. No requirements close. The live Plan145 result cannot be retrospectively promoted; its discarded remote facts remain unavailable.

Next: Plan147 reserves one replacement tag card locally, then requires its own fresh choice before any remote access. This is the single active route, not a repeated diagnostic plan.

The bounded push parser now reuses Plan105's vetted exact object:ref row and optional final Done handling. A real temporary local Git push confirmed the output contract; duplicate/extra/wrong-ref output stays rejected. Quiet checkout and subtree split were also exercised locally. One premature local reservation was retired before authorization when this parser defect was found; its original scope/card/journal and collector snapshot remain preserved. It had zero external operations and supplies no authority.
