---
id: TODO-012
title: The exact-public proof requires one candidate ref for all six packages, which contradicts independent companion versioning
status: open
created: 2026-09-15
severity: high
surfaced_by: attempting 168-UAT test 1 after TODO-010 was closed
relates_to: SC1, REL-01, PROOF-01, D-15, D-16, SEED-014, SEED-017, TODO-011
---

# The exact-public proof presupposes a release shape Crosswake does not use

## Outcome

The post-publication proof matches how Crosswake actually ships: a core release plus independently
versioned companions. Today it presupposes a single linked six-package release, so it cannot pass.

## The contradiction

`script/verify_companion_cleanroom.sh:206` requires the approved manifest to carry **exactly one**
`candidate_ref` across all six entries:

```
candidate_ref=$(jq -er 'map(.candidate_ref) | unique
  | if length == 1 then .[0] else error("candidate ref") end' "$MATRIX_APPROVED_MANIFEST")
```

It then fetches all six from Hex and `Crosswake.ReleaseCandidate.Cleanroom` requires byte-exact
digest equality against that manifest (`cleanroom.ex:298-300`, `"digest_mismatch"`).

`docs/COMPANION-PUBLISH-RUNBOOK.md:16-18` states the opposite design:

> The five `crosswake_*` Hex packages are independent companions. Their current versions and
> `crosswake` floors are evidence, **not members of the linked `0.2.1` approval**.

D-15 / D-16 say the same. So the proof requires the six to come from one approved candidate, while
the release design guarantees they do not.

## Why it cannot pass today, concretely

The six were published from six different commits across ten weeks:

| Package | Version | Published |
|---|---|---|
| `crosswake_chimeway` | 0.1.0 | 2026-07-03 |
| `crosswake_threadline` | 0.1.0 | 2026-07-04 |
| `crosswake_rulestead` | 0.1.0 | 2026-08-08 |
| `crosswake_sigra` | 0.1.3 | 2026-08-09 |
| `crosswake` | 0.2.1 | 2026-09-13 |
| `crosswake_rindle` | 0.1.0 | 2026-09-15 |

No single ref produced all six. Nor can one be reconstructed: package contents have drifted since
their own publish tags — `git diff <tag>..HEAD -- packages/<pkg>` shows chimeway 2 files,
threadline 1, rulestead 3 (sigra and rindle 0). Rebuilding at any current ref therefore yields
payload digests that differ from what Hex serves, so the run fails `digest_mismatch` even before
the single-`candidate_ref` check is considered.

An older ref does not help either: at chimeway's July commit, `crosswake` was 0.2.0 and rindle was
unpublished.

**This is not a missing artifact.** The `phase168-candidate-receipt-<head>` artifact that
`release-please.yml:744` downloads for this job does not exist on any run (checked: the candidate
runs carry only `candidate-rehearsal-ios`). But regenerating it would not help, because the
precondition it encodes has never held.

## Consequence for Phase 168

`168-UAT.md` test 1 returns to **blocked**. It was blocked on `TODO-010` (rindle absent); that is
closed, and it is now blocked on this, which is structural rather than a missing publish. SC1 /
REL-01's post-publication half cannot be satisfied in the proof's current form, by anyone, without
a design decision.

## The decision this needs (do not guess it)

1. **Scope exact-public to the linked core only** (`crosswake` + the two native coordinates),
   proving companions separately against their own approved refs. This matches D-15/D-16 and the
   runbook, and is the smaller change.
2. **Per-package approved refs** — replace the single `candidate_ref` with one ref per entry, so a
   family assembled from independent releases can still be proven byte-exactly.
3. **Genuinely link the family** — publish all six from one approved candidate. This contradicts
   D-15/D-16 and should not be chosen casually.

Recommended: **(2)**, then (1) if (2) proves too costly. (2) keeps the byte-exact guarantee, which
is the property worth having, while dropping an assumption the release design never promised.

## Do not

- Do not relax the digest equality check. Byte-exact comparison against the published tarball is
  the entire value of exact-public; loosening it turns the proof into a reachability check.
- Do not drop packages from the expected family to make the run pass — that is the failure mode
  already recorded in `TODO-010`.

## Breadcrumbs

- `script/verify_companion_cleanroom.sh:206` — the single-`candidate_ref` requirement
- `script/verify_companion_cleanroom.sh:208` — the hardcoded six
- `lib/crosswake/release_candidate/cleanroom.ex:244-305` — `validate_public_artifacts!/3` and
  `digest_mismatch`
- `.github/workflows/release-please.yml:718-763` — `exact-public-proof`, including the
  `gh run download` of an artifact that does not exist
- `docs/COMPANION-PUBLISH-RUNBOOK.md:16-18` — companions are not members of the linked approval
- `TODO-011` — the separate, already-failing per-companion clean-room lane
