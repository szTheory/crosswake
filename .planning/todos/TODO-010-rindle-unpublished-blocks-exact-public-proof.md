---
id: TODO-010
title: crosswake_rindle was never published to Hex, which blocks the exact-public proof entirely
status: open
created: 2026-09-15
severity: high
surfaced_by: attempting Phase 168's human verification item (168-UAT.md test 1)
relates_to: SC1, REL-01, PROOF-01, SEED-017, D-15, D-16
---

# `crosswake_rindle` is not on Hex, so exact-public proof cannot pass

## Outcome

Either `crosswake_rindle` is published and the exact-public proof can run, or the expected package
family is corrected so the proof reflects what Crosswake actually ships. Today neither is true, so
SC1 / REL-01's post-publication half is unachievable rather than merely untested.

## The defect

`script/verify_companion_cleanroom.sh:209` fetches a hardcoded family of six:

```
for package in crosswake crosswake_rulestead crosswake_rindle crosswake_sigra \
               crosswake_chimeway crosswake_threadline; do
```

If any one fails to fetch, the script emits `state: PARTIAL` and `exit 1` — correctly fail-closed
(`:248-263`): "exact-public registry availability is partial; no profile result is complete."

`https://hex.pm/api/packages/crosswake_rindle` returns **404**. The package has never been
published, at any version. `mix hex.info crosswake_rindle` agrees: "No package with name
crosswake_rindle".

Every other member matches its declared version exactly:

| Package | Declared | On Hex |
|---|---|---|
| `crosswake` | 0.2.1 | 0.2.1 |
| `crosswake_rulestead` | 0.1.0 | 0.1.0 |
| **`crosswake_rindle`** | **0.1.0** | **404 — never published** |
| `crosswake_sigra` | 0.1.3 | 0.1.3 |
| `crosswake_chimeway` | 0.1.0 | 0.1.0 |
| `crosswake_threadline` | 0.1.0 | 0.1.0 |

So this is a single missing package, not broad drift. Five of six are exactly right.

## Why this is more than the advisory it was filed as

The 2026-09-15 re-verification recorded the `--live` rindle warning as advisory and "out of scope
per D-15/D-16". D-15/D-16 correctly say companions version *independently* of core — that is about
**version lockstep**, and it remains true. But it does not follow that a companion may be **absent**
from the family the proof harness requires. The consequence is not cosmetic: the exact-public proof
returns `exit 1` before running a single profile, so Phase 168's one remaining human item can never
pass in its current form. `168-UAT.md` test 1 is therefore `blocked`, not `pending`.

## The decision this needs (do not guess it)

One of two things is true, and they have different owners:

1. **`crosswake_rindle 0.1.0` should be published.** Then publishing it unblocks the proof.
   Publishing is a one-way door (D-19: Hex artifacts are immutable and must not be replaced) and
   is not a decision to make incidentally while chasing a verification item.
2. **The expected family is wrong** — rindle is not actually a shipped companion, and the
   hardcoded six in `verify_companion_cleanroom.sh:209`, the `@hex_packages` list in
   `script/check_release_workflow_integrity.exs`, and the runbook's floor table should be five.

Do not "fix" this by making the harness tolerate a missing package. Fail-closed on partial registry
availability is the behavior that caught this, and it is correct.

## Breadcrumbs

- `script/verify_companion_cleanroom.sh:209` — the hardcoded six
- `script/verify_companion_cleanroom.sh:248-263` — the fail-closed partial path
- `packages/crosswake_rindle/mix.exs:4` — declares 0.1.0 (its trailing comment still says
  "independently versioned from core 0.2.0", stale since the 0.2.1 restore)
- `.planning/workstreams/quality-ratchet-release/phases/168-0-2-1-release-candidate-readiness/168-UAT.md`
  — test 1, blocked by this
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — companion floor table
