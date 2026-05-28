# Phase 27: Versioning Decision And CHANGELOG Synthesis - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `27-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 27-Versioning Decision And CHANGELOG Synthesis
**Areas discussed:** CHANGELOG.md shape, first-publish version, release-please anchoring, roadmap traceability.

---

## CHANGELOG.md Shape

The exact format of `CHANGELOG.md` for a first Hex release.

| Option | Description | Selected |
|--------|-------------|----------|
| Per-milestone entries | Write sections for `[v1.0]`, `[v2.0]`, `[v3.2]`, etc. | |
| Keep-a-Changelog + single `[0.1.0]` | Use standard KaC format with an `[Unreleased]` section and a single `[0.1.0]` entry synthesizing capability bullets. Include a preamble and traceability footer. | ✓ |

**User's choice:** Keep-a-Changelog + single `[0.1.0]` entry.
**Notes:** Recommended in `REC-CHANGELOG.md` with HIGH confidence. It satisfies the szTheory canonical invariant (matches oarlock/sigra), correctly anchors release-please, and complies with Crosswake's "narrow honest claims" principle by not creating phantom release versions from internal planning milestones.

---

## First Publish Version

Deciding the version number for the first Hex publish.

| Option | Description | Selected |
|--------|-------------|----------|
| 1.0.0 | Full production release. | |
| 0.1.0 | Initial public release. Matches `mix.exs` current state. | ✓ |

**User's choice:** 0.1.0
**Notes:** Recommended by `REC-VERSIONING.md` and `REC-CHANGELOG.md` (HIGH confidence). Zero external adopters makes SemVer 0.x appropriate.

---

## docs/0 Extras Scope

Phase 26 established the split-phase approach, but Phase 27 must execute its half.

| Option | Description | Selected |
|--------|-------------|----------|
| Complete Phase-split | Add `"CHANGELOG.md"` to `mix.exs` `docs/0` extras list in the same commit that creates the file. | ✓ |

**User's choice:** Complete Phase-split.
**Notes:** Ensures `mix docs` remains green. Required by Phase 26 decisions.

---

## Claude's Discretion

- Bullet phrasing for the 4-5 capabilities in the `[0.1.0]` entry.
- Preamble exact phrasing.
- Date in the `CHANGELOG.md` entry (leave as `2026-MM-DD` or use today's date). Default to today's date since it's being generated.

## Deferred Ideas

- ExUnit test asserting CHANGELOG presence of `[Unreleased]` anchor (deferred to v3.4 per REC-CHANGELOG).
