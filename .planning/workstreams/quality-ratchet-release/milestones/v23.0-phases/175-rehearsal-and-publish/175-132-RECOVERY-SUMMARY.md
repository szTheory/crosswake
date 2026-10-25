---
phase: 175
plan: 132-recovery
status: complete
requirements-completed: []
---

# Plan132 user-directed local decision recovery

The user instructed correction after the original local safe stop. The same unchanged displayed card and earlier ALLOW were verified as unconsumed; the rejected command had created no authorization or read intent. One corrective local decision used inspector-derived digest values directly, then immediately invoked exactly one production read. No new attempt or changed scope was created. The original `175-132-SUMMARY.md` remains unchanged as the historical safe-stop record.

The result is independently audited **ALLOW / OBSERVED / FACTS_CAPTURED**, observed at `2026-10-10T17:02:46.769108Z`.

- Attempt: `d9364591d7faf4a6f9fa70b634bd6c2a`.
- Scope SHA-256: `39f9bd7c81e1d18ca078dee5af736a9ba0978b6fc9e5d3938428a8964897631b`.
- Raw card SHA-256: `bb3c336e5b5c9ac74f26d17f344083bb58bbd84515af73f62c79c4af2cf4a221`.
- Collector SHA-256: `03440406756419807a98c3adf6e44a370615c5e549693d9058546eefd73a1d2c`.
- Authorization SHA-256: `bef56e3476497f698c09c33d05518d4b9b9f35dab6be26422bbf75974fabeae4`.
- Result SHA-256: `9c925042f1f41e627f46734538c3bbd09fc9500a059055bc2025b97d4f34e28e`.
- Counts: 7 GitHub GETs, 16 Git operations, 1 helper check, 2 permission checks; zero dry-run/tag/CI attempts.

Both plan-prescribed independent terminal audits passed: canonical scope/authorization/result/event digests and references, exact schema/key sets, reservation/decision/read-intent/read-result order, one intent, count caps, raw card/collector binding, and structured privacy. The prior preparation gates passed 114 Node and 37 ExUnit tests. The observation and ALLOW are now consumed; no read or decision replay is permitted.

The source package split matches mirror main and prior v0.2.5. Target v0.2.6 is ABSENT. PR219 is OPEN, not draft, and unmerged, with base/head/tree matching the retained comparison. Observed candidate version is UNKNOWN. Authenticated access projects ADMIN with permission/identity/helper TRUE, but policy complete=false and tag_policy UNKNOWN; these do not establish effective tag-write permission.

A distinct no-network probe now reproduces a local classifier defect: two injected cases with nonempty tag restrictions that are disabled or explicitly exclude the exact destination incorrectly project incomplete policy. The probe exited 1 with two assertion failures and zero network calls. It establishes a repairable local ordering defect, not the cause of the live incomplete policy. See evidence/175-plan132-local-policy-probe.json and currentPolicySnapshot in the pinned collector. Authoritative candidate version acquisition remains a separate scoped question; the existing title projector recognizes only its historical 0.2.7 hint.

Plan106 HELD; Plans46–48/89 HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. No registry, tag, CI, merge, publication, phase completion, or support promotion occurred. No stage/commit under phase_commit_docs.175=false.

## Self-Check: PASSED

The sealed terminal artifacts exist and both independent audits passed. Original safe-stop and historical evidence are preserved. The new local reproduction reopens bounded local-only planning; it does not authorize another acquisition.
