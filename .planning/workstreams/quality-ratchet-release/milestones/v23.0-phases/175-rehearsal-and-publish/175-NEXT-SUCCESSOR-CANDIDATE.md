# Phase 175 Next Successor Candidate

Observed 2026-09-27T20:28:09Z. Candidate PR #215 proposes `0.2.6` from base
`b5608a3dc0b013d83ac2b25768f1907873739b20` at head
`0968fea84dc758c05b9b0161db2f221c9e778c3b` (tree
`0199c0bee29dbcf76bc1a12d241c0ed140a244bd`). It is open, non-draft, and mergeable.

Exact-head Crosswake CI run `36346477576` passed all 49 checks. Its candidate CI receipt,
artifact manifest, and clean-room result digests are recorded in
`evidence/175-next-successor-candidate.json`; the unexpired artifact is
`phase168-candidate-ci-0968fea84dc758c05b9b0161db2f221c9e778c3b`.

Repair PR #216 is in candidate lineage at merge `b5608a3dc0b013d83ac2b25768f1907873739b20`.
Its ordinary Release Please run `36346252825` succeeded with `linked_release=false`. Runbook
ancestry passed on the base and candidate. The strict required context is `Crosswake CI`.

Fresh public target checks observed Hex 404, no iOS mirror tag `v0.2.6`, and Maven POM 404.
The repair PR's linked publication jobs remained gated off. This record establishes a safe
rehearsal candidate only; it grants no publication authority.

## Rehearsals and pre-merge evidence

- Hex run `36348273088`: six package artifacts, PASS, no external state change.
- iOS run `36348273033`: PASS/PROVEN; the split matches mirror main and tag `v0.2.6` is absent.
- Maven run `36348273114`: VALIDATED then DROP; candidate PR head was unchanged.
- Attestation run `36348696331`: canonical receipt artifact `10941079991`, unexpired, all 13
  checks PASS, bound identity equals observed identity, publication NONE. Its artifact digest is
  `c51181d384661e77cf68935a6496b4c4bdf9e147854889027f64312dd5d6e9ba`.
- Live pre-merge REL-17 capture: PASS for `(linked_release, 36348273088)`. The retained public Hex
  response SHA-256 is `8c4bcd4a344389ff3c6a2548879053fa8aceb541ed2a1cea059986e33cb69c5b`;
  pagination, candidate readiness, policy, response-table row, and runbook ancestry passed.

Pre-merge authorization remains `PENDING`, `authorized=false`; merge OID is null. Gate 2 still
requires the exact human decision defined by Plan 175-38.
