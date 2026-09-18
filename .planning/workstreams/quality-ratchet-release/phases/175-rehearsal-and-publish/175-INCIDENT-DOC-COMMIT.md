# Incident-Response Document — Commit Record

Discharges Phase 175's one-way-door bar (ROADMAP Success Criterion 1): no publish command in this
phase executes until `docs/RELEASE-INCIDENT-RESPONSE.md` is committed and that commit is an ancestor
of `HEAD` on the branch the publish runs from.

## Commit identity

- **Commit SHA (40-char, full):** `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`
- **Author date:** `2026-09-18T17:11:08-04:00`
- **Obtained with:** `git log --format=%H -1 -- docs/RELEASE-INCIDENT-RESPONSE.md` (run against this
  plan's branch after both content commits landed — this is the commit that most recently touched
  the file, i.e. the SHA at which the document reached its complete, final content for this plan).
- **Branch:** `main` (this plan committed directly to `main`; no worktree, no feature branch).

The document was introduced across two commits — `0e433735` (Task 1: irreversibility summary +
partial-failure matrix) and `d3401e51` (Task 2: retire/backfill procedures) — because this plan
requires one atomic commit per task. `d3401e51` is the SHA recorded here because it is the commit
after which the file's content is complete; an ancestor check against it necessarily also proves
`0e433735` is present (it is `d3401e51`'s parent).

Verified this session:

```
$ git cat-file -e d3401e516c5e158accf2b8c5629ce6bcf9bd80f8
(exit 0 — resolves in this repository)

$ git show --stat d3401e516c5e158accf2b8c5629ce6bcf9bd80f8
 docs/RELEASE-INCIDENT-RESPONSE.md | 68 +++++++++++++++++++++++++++++++++++++++
(touches the document)

$ git merge-base --is-ancestor d3401e516c5e158accf2b8c5629ce6bcf9bd80f8 HEAD
(exit 0 — is an ancestor of HEAD at the time of this recording)
```

## Heading anchors cited by the phase's checkpoint prompts

Both confirmed against the heading text actually present in `docs/RELEASE-INCIDENT-RESPONSE.md` at
commit `d3401e51`, using GitHub's Markdown anchor-generation algorithm (lowercase; strip punctuation
other than hyphens/underscores, leaving the space it occupied; collapse remaining spaces to hyphens):

| Heading text (verbatim in file) | Anchor |
|---|---|
| `## Mid-sequence partial failure` | `docs/RELEASE-INCIDENT-RESPONSE.md#mid-sequence-partial-failure` |
| `## Retire / backfill after a bad publish` | `docs/RELEASE-INCIDENT-RESPONSE.md#retire--backfill-after-a-bad-publish` |

The second anchor carries a double hyphen (`retire--backfill`) because the `/` in the heading is
stripped by GitHub's algorithm but the surrounding spaces are not, producing two adjacent hyphens
after the space-to-hyphen substitution. This is not a typo — it is the actual anchor GitHub will
generate, and it matches the anchor the phase's `175-07`/`175-08`/`175-10` checkpoint prompts were
already written to cite. Neither heading was reworded during execution, so no citing checkpoint needs
updating.

## The one-way-door bar, as a re-runnable check

No publish command in this phase executes until this is true:

```bash
git merge-base --is-ancestor d3401e516c5e158accf2b8c5629ce6bcf9bd80f8 HEAD
```

Exit `0` means the bar is satisfied; any other exit means it is not, and no publish task may
proceed until it is re-satisfied.

**Re-derivation rule.** The SHA above is the SHA on the branch this plan committed to (`main`,
committed directly, no PR). If this work is later folded into a different branch through a squash
or rebase — for example if a future workflow change starts routing phase work through PRs — the
recorded SHA `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` may no longer be an ancestor of the publish
branch's `HEAD`, because a squash/rebase mints a new commit object with a different SHA even when
the tree content is identical. **A stale SHA that fails the ancestor check above is correct
behavior — it is telling the truth that the specific object recorded here is not in this history.**
The defect would be a stale SHA that nobody re-checks. Before the first publish task in this phase
dispatches, re-run the `git merge-base --is-ancestor` command above against the actual publish
branch; if it fails, re-run `git log --format=%H -1 -- docs/RELEASE-INCIDENT-RESPONSE.md` on that
branch and record the new SHA here before proceeding.

## Per-registry recovery one-liners for gates 1, 2, and 3

Per D-10, these are pointers into `docs/RELEASE-INCIDENT-RESPONSE.md`'s own rows, not independently
re-derived prose. The gates quote; they do not paraphrase.

- **Hex (gate 1 and gate 3):** "`mix hex.retire` sets a forward-only advisory flag; the version
  remains resolvable and existing lockfiles are unaffected — see the Irreversibility summary table's
  Hex row and the Hex subsection of `## Retire / backfill after a bad publish`."
- **iOS mirror (gate 2):** "A mirror tag can be re-pointed through `recover-ios-mirror`, but
  re-pointing does not un-resolve consumers who already fetched the old commit via SwiftPM's
  resolved-package cache — see the Irreversibility summary table's iOS SwiftPM mirror row and the
  iOS mirror subsection of `## Retire / backfill after a bad publish`."
- **Maven (gate 2):** "A coordinate is permanent once `PUBLISHED`; only a `VALIDATED` rehearsal
  deployment is droppable, and that affordance never applies to a real publish — see the
  Irreversibility summary table's Maven Central row and the Maven subsection of
  `## Retire / backfill after a bad publish`."

## Scope note

This record does not dispatch a rehearsal, merge a pull request, or touch a registry. It exists
solely to make SC1's one-way-door bar checkable rather than asserted.
