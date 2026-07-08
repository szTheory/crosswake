# Phase 146: Release Status DX & Docs Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-08
**Phase:** 146-Release Status DX & Docs Truth
**Areas discussed:** Completed Evidence Truth, JSON Contract Shape, Live Probe Semantics, Docs And Exit Behavior

---

## Completed Evidence Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Keep downstream warning text | Leave status output saying PREF validation remains Phase 144 and similar phase-era caveats. | |
| Promote completed evidence to direct checks | Report Phase 144/145 evidence as current status checks now that those phases are verified complete. | yes |
| Hide completed evidence | Remove PREF/MIRR checks from status to avoid stale wording. | |

**User's choice:** Discuss and consider all areas with research, then provide one coherent recommendation set.
**Notes:** Research found the current task exits `error` because `release.cleanroom_dependency_floor` still uses stale Phase 144 wording even though Phase 144 verification passed. Recommendation: replace planning-era caveats with direct evidence checks and actionable next steps.

---

## JSON Contract Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Stable codes only | Keep JSON small and branch only on `checks[].code` and aggregate status. | |
| Rich structured contract | Lock top-level fields, component fields, check status, source, evidence, message, and next_action. | yes |
| Separate issue-specific JSON task | Add another command for automation to avoid touching human status output. | |

**User's choice:** Discuss and consider all areas with research, then provide one coherent recommendation set.
**Notes:** Mix/Cargo/npm/GitHub Actions research supports a single command with machine mode. Recommendation: `--json` is an additive schema-versioned API and must be parseable without human banners or prose.

---

## Live Probe Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Live by default | Always check Hex, Maven, and SwiftPM mirror on every status run. | |
| Optional advisory live probes | Keep deterministic local default; `--live` overlays public registry truth as warnings. | yes |
| No live probes | Avoid network entirely and leave registry checks to separate scripts. | |

**User's choice:** Discuss and consider all areas with research, then provide one coherent recommendation set.
**Notes:** Research converged on local-only default for normal CI. Recommendation: `--live` distinguishes `ok`, `missing`, and `unavailable`; missing/unavailable live state is warning by default, never mutation.

---

## Docs And Exit Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Fail on every warning | Make any warning, including optional live registry misses, exit non-zero. | |
| Warnings are advisory, errors are blocking | Exit 0 for ok/warning; exit non-zero for blocking local errors or invalid invocation. | yes |
| Never fail | Always print status and exit 0. | |

**User's choice:** Discuss and consider all areas with research, then provide one coherent recommendation set.
**Notes:** Recommendation: local contradictions such as lockstep drift, configured version drift, stale release-as pins, and missing guard evidence are errors. Optional live registry misses and unavailable probes are warnings. Docs must explain that release status is read-only and does not publish, push, or backfill.

---

## Claude's Discretion

- Exact helper names and test module factoring.
- Whether to add `--fail-on-warning`; recommended only if an issue-opening or scheduled strict workflow is added in Phase 146.
- Whether `native-release-status` is consumed via an explicit file input or left as CI-only evidence.
- Whether JSON schema documentation lives in the Mix task moduledoc, the companion publish runbook, or both.

## Deferred Ideas

- Graphical or Phoenix LiveDashboard release dashboard remains DASH-01.
- Registry mutation/recovery remains in guarded scripts and workflows, not `mix crosswake.release.status`.
- Full automatic issue-opening is optional future automation if JSON suitability is enough to satisfy STAT-02.
