---
id: TODO-005
title: First B2C Adopter identity leaked into the public repo — working tree scrubbed, history and HexDocs still exposed
status: partially-resolved
created: 2026-09-14
severity: medium
surfaced_by: incidental finding while triaging the adopter device-proof report
relates_to: TODO-002 (sanitized adopter inputs), ADR-FIRST-B2C-ADOPTER.md
---

# Adopter identity leaked into the public repo

## What happened

`.planning/` consistently anonymizes the adopter as **"First B2C Adopter"**. The shipped package did
not. The adopter's real product name appeared **14 times** across three files in
`github.com/szTheory/crosswake` — a **public** repository — used as the worked example for
mixed-case namespace derivation:

- `CHANGELOG.md` — shipped on Hex, rendered on HexDocs
- `guides/install.md` — shipped on HexDocs
- `test/mix/tasks/crosswake_install_test.exs`

## Done (2026-09-14, working tree)

Replaced throughout with a neutral mixed-case example, `AcmeShop` / `AcmeShopWeb` / `:acmeshop`,
which preserves the pedagogical point (the casing is not reconstructible from the OTP app name).
`mix test test/mix/tasks/crosswake_install_test.exs` — 11 tests, 0 failures.
Zero occurrences remain anywhere outside `.git`.

## Still exposed

1. **Git history.** Three commits carry the string; **one is already on `origin/main`**
   (`cc5286da chore: reconcile complete default branch truth`; the other two are local). Removing it
   needs a history rewrite on a public repo with an already-published tag lineage — weigh that cost
   against the actual sensitivity. The name is a product name, not a credential.
2. **Published HexDocs.** `guides/install.md` for the already-published release carries the old text.
   It cannot be edited in place; it clears on the next release's docs build.

## Decision needed

Whether to rewrite history. Default recommendation: **no** — push the scrub forward, let the next
docs build clear HexDocs, and accept the historical commit. Confirm with the adopter whether the
reference was unwanted at all; it may have been volunteered.

## Guard (not yet built)

Add a merge-blocking grep for adopter-identifying strings, matching the repo's other structural
sweeps, so this cannot recur as adopter evidence keeps flowing in. Codename of record for all
adopter material is **"First B2C Adopter"**.
