---
id: TODO-015
title: Phase 199 review follow-ups - changelog guard permanence, removed qualifier check, 0.2.12 wording
status: open
created: 2026-11-10
severity: low
surfaced_by: Phase 199 code review (199-REVIEW.md)
relates_to: REL-07, Phase 199, TODO-014
---

# Small follow-ups from the Phase 199 review

None changes a verdict today.

1. WR-01: `test/crosswake/guides/changelog_unreleased_wording_test.exs` permanently forbids `:ios_host` in
   `[Unreleased]` and pins a boilerplate sentence; the next legitimate unreleased entry will trip it. Make the
   guard assert against the published release facts instead of a fixed sentence.
2. IN-01: deleting `unreleased_claim_qualifier_test.exs` leaves `guides/native_shell.md`, `guides/compatibility.md`
   and `guides/architecture.md` without a version-qualifier check; add a small guard for the "from 0.2.12 on" wording.
3. IN-02/IN-03: the rewritten changelog checks lean on `refute`, and the `.awk` fixture in the scan test has only
   safe content; add a positive control and a private-term control.
4. IN-04: the generated guides say "from 0.2.12 on" without saying that 0.2.12's default iOS generation did not
   build (fixed in 0.2.13). Decide whether to name 0.2.14 as the install version in those sentences. The parity-ledger
   qualifier also renders twice in `guides/parity_ledger.md` (predates this phase).

## Reopen when

The next change touches the guide renderers or the changelog guard.
