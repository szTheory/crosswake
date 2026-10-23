# Phase 189: Inventory and backup - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-16
**Phase:** 189-inventory-and-backup
**Areas discussed:** Backup location (one user decision); the other areas were decided with a single opinionated recommendation (advisor mode, minimal_decisive)

---

## Backup location

| Option | Description | Selected |
|--------|-------------|----------|
| Local now, GitHub at PR | Keep backups in the sibling folder outside /private/tmp with restore tests; the first off-machine copy is the Phase 191/192 push after a privacy scan | ✓ |
| Also copy off-machine now | Also copy the bundles somewhere off this machine during 189 | |
| Push backup branch to GitHub now | Push the candidate to a non-main branch on the public repo before the privacy scan | |

**User's choice:** Local now, GitHub at PR (Recommended)

## Claude's recommendation (presented, not objected to)

- Scope: Crosswake `/private/tmp` folders only; other projects' folders untouched.
- Classification by content against fresh `main` + candidate; anything unclear stays unclassified and backed up, never guessed obsolete.
- Backups by read-only operations only: all-refs bundle, per-stash patches, tar + diff of the uncommitted files; restore-tested in a scratch folder.
- PR dispositions: dependabot = redo after landing; #238 = by content (close if superseded, else redo); #236 = hold (no release).

## Deferred Ideas

- Off-machine backup during 189 (declined).
- Cleanup of other projects' `/private/tmp` folders (out of scope).
