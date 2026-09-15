---
phase: 168-0-2-1-release-candidate-readiness
plan: "13"
subsystem: release-readiness
gap_closure: true
tags: [candidate-receipt, approval-record, evidence-recovery, provenance]
requires: []
provides:
  - Canonical exact-head candidate receipt durable on protected default
  - Maintainer dossier recording the single explicit approval
  - Proven digest equality between the receipt and the constant three gated publish jobs enforce
  - Committed 168-08 completion record with dated provenance
affects: [phase-168-evidence, release-approval-audit-trail]
actuals:
  tasks: 2
  commits: 2
plan_head_before: 52135b09
tech-stack:
  added: []
  patterns: [byte-for-byte-evidence-recovery, dated-provenance-not-retroactive-edit]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.json
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/evidence/phase168-candidate-receipt.md
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-08-SUMMARY.md
key-decisions:
  - "Leave the receipt's capture-time external state (`publication: NONE`, `changed: false`) exactly as recorded. A pre-publication capture rewritten to describe the publication is no longer evidence of what was approved."
  - "Correct the reader's frame with a dated provenance section rather than editing 168-08's historical statements. Its claims were accurate on 2026-09-13; rewriting them would destroy the record of what was known when the approval was given."
  - "Verify the dossier against the receipt by substantive agreement, not byte-equality with `Projection.markdown/1` — see the deviation below."
patterns-established:
  - "Evidence recovered from an unmerged branch is written from the object store and proven by digest against an independently-enforced constant, never regenerated."
requirements-completed: [REL-04, REL-05]
requirements-addressed: [REL-01, REL-04, REL-05]
---

# Plan 168-13 Summary — Canonical candidate receipt landed on protected default

## Accomplishments

Closed verification gap 2. The exact-head candidate receipt this phase exists to
produce — and the dossier recording the single explicit maintainer approval — had
been captured, approved, and then stranded on an unmerged, unpushed local branch.
For two days the phase's central deliverable existed only in a local object store.

**Task 1 — recovered byte-for-byte.** Both files written out of the object store at
`3c825ea2` and verified identical to their content there. The JSON was created by
`9160f3c0` and untouched since; `3c825ea2` appended only the approval outcome to the
Markdown, so reading both at `3c825ea2` yields the complete final pair.

**Task 2 — the record and its provenance.** `168-08-SUMMARY.md` committed as written,
with a dated provenance section recording what the forensic pass established since.

## Task Commits

| Task | Commit |
|---|---|
| 1 | `cbc50e8d` docs(168-13): land the canonical 0.2.1 candidate receipt |
| 2 | `862dcada` docs(168-13): commit the 168-08 record with receipt provenance |

## Evidence and Verification

**The decisive check — record and mechanism are the same transaction:**

The recovered JSON hashes to
`359ef8a5257b54e472a2328ce3ae722222506527312b3805467d643bb8666c78`, byte-identical to
the `PHASE168_CANDIDATE_RECEIPT` constant that three gated jobs compare against before
any irreversible action:

| Job | Location |
|---|---|
| `publish-ios-mirror` | `.github/workflows/ios-mirror-backfill.yml:331` |
| Hex publish recovery | `.github/workflows/hex-publish.yml:172` |
| `recover-android-core` | `.github/workflows/hex-publish.yml:304` |

The constant was read out of the workflows, not retyped from memory.

- Both files byte-identical to `3c825ea2` (SHA-256 compared per file)
- `Crosswake.ReleaseCandidate.Receipt.validate!/1` → OK; `state` `READY FOR APPROVAL`,
  `next_action` `approve_exact_candidate`
- `jq` → `state == "READY FOR APPROVAL"`, `external_state.changed == false`,
  `external_state.publication == "NONE"`, `identity.bound.head == 1051ab90…`
- 12 of 12 checks `PASS` in the receipt; the dossier independently states `PASS 12/12`
- Dossier carries the approval line naming that exact head and digest at
  `2026-09-13T19:49:41Z`, preceding the 2026-09-14 publication runs
- `mix test test/crosswake/release_candidate/` → 44 tests, 0 failures
- Evidence directory clean after Task 2

**No package, tag, ref, mirror, or workflow was touched by this plan.**

## Deviations from Plan

### Deviation 1 — the dossier is not a `Projection.markdown/1` output

- **Plan asserted:** "the generated portion of the Markdown still equals
  `Crosswake.ReleaseCandidate.Projection.markdown/1` for that receipt with the recorded
  approval outcome appended after it."
- **What is actually true:** `Projection.markdown/1` emits a terse six-line summary
  (`READY FOR APPROVAL`, checks `12/12`, credentials, external state, next action). The
  dossier on disk is a 105-line hand-authored maintainer document. It was never
  generated by that function, so no prefix of it can equal that function's output.
- **Resolution:** verified *substantive* agreement instead — the dossier's state,
  check count, credential posture, external-state claim, and next action all match the
  receipt, and its approval line matches the bound head and digest exactly. The
  prohibition against regenerating or reformatting the artifact rules out making the
  dossier match the function; the artifact is correct and the plan's assumption about
  its provenance was not.

### Deviation 2 — `validate!/1` needs atom keys

`Receipt.validate!/1` operates on atom-keyed in-memory maps; no JSON-loading helper
exists in the repository. The decoded receipt was deep-atomized in a throwaway
verification script to run the validator. No shipped code was added or changed, and the
on-disk bytes were not touched.

### Deviation 3 — delivered by pull request

`main` is protected (`GH006`). Delivered on branch
`gsd/phase-168-version-truth-changelog` via **PR #163**.

### Finding carried forward — the attestation operation is a dead end

The `candidate-receipt-attestation` operation added by `ad8fbada` cannot reproduce this
receipt. Its validation step asserts four pre-publication conditions — Hex endpoint 404,
no `0.2.1` tags on origin, Maven POM 404, no `v0.2.1` mirror tag — and all four are now
false, so a dispatch today fails rather than producing a receipt. It also uploads a
retention-limited workflow artifact rather than committing a durable file. This is
recorded in the 168-08 provenance section where the next maintainer will look.

**Total deviations:** 3, plus one carried-forward finding.

## Issues Encountered

None beyond the above.

## Known Stubs

None.

## User Setup Required

None. PR #163 needs review and merge.

## Next Phase Readiness

- Gap 2 is closed. Gap 3 was closed by 168-09, 168-10, and 168-11.
- Gap 1 (CR-01 iOS mirror exact-identity gate) remains, owned by 168-12.
- The exact-public post-publication clean-room run remains an open human-verification
  item from the verification report — not a gap.

---
*Phase: 168-0-2-1-release-candidate-readiness*
*Completed: 2026-09-15*
