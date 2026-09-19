# Incident-Response Document — Commit Record

Records the commit intended to discharge Phase 175's one-way-door bar. It does **not** retroactively
discharge Gate 1: the original check targeted divergent local `HEAD`, while PR #147 merged and
published from a remote graph that did not contain this commit or the runbook file. REL-10's remote
ancestry bar was therefore breached for Gate 1 and must remain recorded as such.

For every remaining publish, the bar is checked against freshly fetched exact remote base/head OIDs
before merge and the exact GitHub merge OID afterward. Symbolic local `HEAD` is not a valid target.

## Commit identity

- **Commit SHA (40-char, full):** `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`
- **Author date:** `2026-09-18T17:11:08-04:00`
- **Obtained with:** `git log --format=%H -1 -- docs/RELEASE-INCIDENT-RESPONSE.md` (run against this
  plan's branch after both content commits landed — this is the commit that most recently touched
  the file, i.e. the SHA at which the document reached its complete, final content for this plan).
- **Branch at recording time:** local `main` (not `origin/main`; this distinction is the Gate 1
  incident's root cause trigger).

The document was introduced across two commits — `0e433735` (Task 1: irreversibility summary +
partial-failure matrix) and `d3401e51` (Task 2: retire/backfill procedures) — because this plan
requires one atomic commit per task. `d3401e51` is the SHA recorded here because it is the commit
after which the file's content is complete; an ancestor check against it necessarily also proves
`0e433735` is present (it is `d3401e51`'s parent).

Originally verified only against local checkout state (historical evidence, now known insufficient):

```
$ git cat-file -e d3401e516c5e158accf2b8c5629ce6bcf9bd80f8
(exit 0 — resolves in this repository)

$ git show --stat d3401e516c5e158accf2b8c5629ce6bcf9bd80f8
 docs/RELEASE-INCIDENT-RESPONSE.md | 68 +++++++++++++++++++++++++++++++++++++++
(touches the document)

$ git merge-base --is-ancestor d3401e516c5e158accf2b8c5629ce6bcf9bd80f8 HEAD
(exit 0 — local-only result; not release authority)
```

Gate 1 remote audit performed 2026-09-19:

```text
PR #147 base:  4627170fffb6688dcb2750c07fae3a18c6d0ee19 — runbook ancestor: no
PR #147 head:  491c7a74e2128f7e77c411d50aa22276626c6f51 — runbook ancestor: no
PR #147 merge: 096371e3008d19da775c0d561d092fb3d349b26e — runbook ancestor: no
```

`docs/RELEASE-INCIDENT-RESPONSE.md` is absent from all three trees. Gate 1's publish remains
historically noncompliant; no later landing can change that fact.

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

## The one-way-door bar, as a re-runnable exact-target check

No remaining publish command in this phase executes until the runbook commit is present in the exact
remote graph. After fetching and matching the live PR `baseRefOid` and `headRefOid`, run the helper
against each full OID:

```bash
bash script/check_release_runbook_ancestry.sh \
  d3401e516c5e158accf2b8c5629ce6bcf9bd80f8 \
  <exact-40-character-remote-target>
```

Exit `0` means the named exact target contains the runbook commit and path. Any other exit means the
bar is not satisfied. The helper rejects `HEAD`, branch names, abbreviated SHAs, missing objects, a
commit that does not touch the runbook path, non-ancestry, and a target tree missing the path.

**Re-derivation rule.** If a squash or rebase lands the runbook under a new commit object, first land
that object on remote `main`, then re-run `git log --format=%H -1 --
docs/RELEASE-INCIDENT-RESPONSE.md` against the freshly fetched remote commit and update this record.
Do not derive a replacement from local-only history. Before a remaining publish, the updated SHA must
pass the helper against both live remote PR OIDs; after merge, it must pass against GitHub's exact
`mergeCommit.oid` as an audit.

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
