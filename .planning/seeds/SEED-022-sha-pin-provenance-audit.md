---
id: SEED-022
title: The 8 SHAs freshly resolved by 175-02's SHA-pinning pass have never been independently audited for correctness, currency, or compromise
status: dormant
severity: medium
trigger_when: >-
  Surface when hardening supply-chain posture further, when a pinned action's
  upstream repository reports a security incident, when the next scheduled
  Dependabot bump for one of these actions lands, or when planning a phase whose
  scope is CI/CD hygiene generally. NOT blocking — 175-02's own diligence (in-repo
  reuse first, `gh api` tag dereferencing for the rest, byte-identical secret
  checks) is a real floor, not a placeholder.
created: 2026-09-18
related: [SEED-018, SEED-021]
---

# SEED-022: pinning a mutable ref to a SHA proves reproducibility, not correctness — the pinned SHAs themselves are unaudited

## The finding

Phase 175's Wave 0 (plans 175-01/175-02) fixed a real vacuity defect: `check-actions`
reported `mutable_refs=0` against a hardcoded three-file default while 31 mutable
third-party action refs sat unscanned across ten other workflow files. 175-02 then
pinned all 31 to 40-character commit SHAs.

That work answers "is the ref mutable" — it does not answer "is the SHA correct." Two
of the pins 175-02 wrote came from tag objects that were themselves ambiguous or
required dereferencing:

- `erlef/setup-beam@v1` had two different pre-existing in-repo SHAs
  (`54075bcc5e249e4758d363f27d099f55d843f124` and
  `fc68ffb90438ef2936bbb3251622353b3dcb2f93`) before this plan touched anything.
  175-02 resolved the ambiguity by calling `gh api repos/erlef/setup-beam/git/ref/tags/v1`
  fresh rather than guessing, and used whichever SHA that call returned — but the SHA
  itself was never checked against, for example, the action's own release notes, a
  second independent source, or a known-good hash published by the action's maintainer.
- `ReactiveCircus/android-emulator-runner@v2` similarly resolved through an annotated
  tag object dereferenced via `git/tags/<sha>` to `a421e43855164a8197daf9d8d40fe71c6996bb0d`,
  with the same single-source trust.

`gh api`'s response is trusted as ground truth. If GitHub's tag-to-commit mapping were
compromised at the moment of the query (a supply-chain attack on the action's own repo,
or a MITM on the API call, however unlikely), the pin would faithfully immortalize the
compromised commit — the exact SHA would now be permanent in ten workflow files, and
Dependabot's future bump PRs would only ever move it *forward* from that point, never
audit whether the original pin was sound.

## Why it's out of scope for Wave 0 (D-29)

D-29 explicitly places "auditing whether the pinned SHAs are themselves correct, latest,
or uncompromised" outside Wave 0. Wave 0's job was narrowly "stop scanning three files
when 27 exist" and "stop trusting a mutable ref at all" — not "verify every commit hash
ever written into this repository's CI config." Folding provenance auditing into Wave 0
would have significantly widened its blast radius and delayed the publish waves this
phase exists to unblock.

## What a remediation would look like

- Cross-reference each of the 8 freshly-resolved SHAs against a second independent
  source: the action's GitHub Releases page (commit shown there), `npm`/`go.sum`-style
  checksum registries where the action ecosystem has one, or a manual diff of the
  commit's changed files against what the version bump claims to do.
- For the two dereferenced-tag-object cases specifically (`erlef/setup-beam`,
  `ReactiveCircus/android-emulator-runner`), confirm the annotated tag's own GPG
  signature (if the maintainer signs tags) rather than trusting the API's plain object
  graph traversal.
- Consider whether `pin-github-action`-style tooling (which cross-checks against a
  broader reputation/provenance signal, not just the live API) should replace ad hoc
  `gh api` resolution for any future pin.
- This generalizes beyond the 8 freshly-resolved SHAs: the pre-existing pins reused
  verbatim by 175-02 (`actions/checkout`, `actions/setup-node`, `actions/upload-artifact`,
  and the *other* `erlef/setup-beam@v1` SHA left untouched elsewhere in the repo per
  175-02's scope boundary) carry the identical unaudited-provenance property; a
  remediation phase should treat the full pinned-action surface, not just this phase's
  8 new resolutions.
