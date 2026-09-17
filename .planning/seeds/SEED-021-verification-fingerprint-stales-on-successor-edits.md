---
id: SEED-021
title: A phase's covered_digest fingerprint goes stale when a LATER phase edits the same files, misrouting /gsd-progress back to the already-closed phase
status: dormant
severity: medium
trigger_when: >-
  Surface when automating phase-to-phase routing (`/gsd-progress --next --auto`),
  when a progress report names a long-closed phase as `current_phase`, or when
  deciding what `covered_files` a VERIFICATION.md should declare. NOT blocking —
  the misroute is advisory, and every affected phase is genuinely verified.
created: 2026-09-17
related: [SEED-019, SEED-020]
---

# SEED-021: verification staleness cannot distinguish "unverified change" from "a successor phase legitimately moved on"

## The finding

`readVerificationStatus` in `~/.claude/gsd-core/bin/lib/verification.cjs` has two
staleness strategies, chosen by whether the VERIFICATION.md declares a fingerprint:

- **No fingerprint** → `findStaleVerificationSummary`: is any `*-SUMMARY.md` newer than
  the `*-VERIFICATION.md`? Phase-local, and correct.
- **Declares `covered_files` + `covered_digest`** → recompute the digest over
  `covered_files` and compare. Any byte change anywhere in that list reads as stale.

The second strategy has no notion of *who* changed the bytes. When phase N's
`covered_files` include shared repository files — CI workflows, shared scripts, the
workstream's own conventions doc — and phase N+1 legitimately edits them, phase N's
fingerprint breaks. The phase is not less verified than it was; the check simply cannot
tell a successor's authorized edit from an unreviewed drive-by.

## Measured scope (2026-09-17, workstream `quality-ratchet-release`)

Recomputing each closed phase's declared digest against the live tree:

```
phase  covered_files  digest match  missing files
169         21          false          none
170         43          false          none
171         38          false          none
172         19          TRUE           none
```

No covered file is missing — the lists resolve cleanly. Only the most recent phase (172,
which nothing has yet succeeded) still matches. The pattern is monotonic: a phase's
fingerprint survives exactly until the next phase lands.

Every one of 169/170/171 carries `status: passed` in its own frontmatter, merged with CI
green, and 171's VERIFICATION.md is committed *after* all five of its SUMMARY files — so
the phase-local staleness rule would have said `stale: false` for all four. Verified
directly:

```
169-diagnostic-legibility         {"determined":true,"stale":false}
170-vacuous-assertion-remediation {"determined":true,"stale":false}
171-version-authority-split       {"determined":true,"stale":false}
172-per-package-proof-scope       {"determined":true,"stale":false}
```

The fingerprint path overrides that and returns `stale`.

## The consequence

`gsd_run query init.progress` reports `completed_count: 1` of 7 for a workstream where
four phases are closed, and names **phase 169** as `current_phase` with
`next_command: /gsd-verify-work 169`. `/gsd-progress --next --auto` would re-verify a
phase closed a day earlier instead of planning the next one. STATE.md, maintained by
hand, correctly says `completed_phases: 4` — so the two surfaces disagree, and the
machine-derived one is the wrong one.

## The remediation shape

Not a crosswake code change — this lives in `@opengsd/gsd-core`. Two candidate shapes:

1. **Scope the fingerprint to the phase's own artifacts.** Declare only files under the
   phase directory in `covered_files`; treat shared repository files as evidence cited in
   the body, not as fingerprint inputs. Cheapest, and available today with no tool change:
   it is purely a convention for what the verifier writes.
2. **Make staleness successor-aware.** Recompute the digest at the commit that closed the
   phase, and only report stale if a covered file changed in a commit that is *not*
   reachable from a later phase's closing commit. Correct, but needs git history walking
   inside the tool.

Option 1 has the better cost/benefit and keeps the fingerprint's original meaning
(nothing edited this phase's record behind the verifier's back) intact. Option 2 is what
you would want if the fingerprint is meant to assert something about the whole tree.

Either way this needs the non-vacuity treatment every check in this milestone carries: a
fixture where a covered file is mutated by the phase itself must still read `stale`, or
the fix has simply turned the check off.

## Why this is not urgent

No phase is falsely marked passed — the failure direction is conservative (it over-reports
staleness, never under-reports it). The cost is a misrouted `--next` and a progress report
that undercounts completed phases, both of which a human reading STATE.md catches
immediately. It is recorded because the auto-routing goal makes "advisory misroute" a
progressively more expensive category.
