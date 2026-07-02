## Pre-existing failures discovered during 132-03 execution (out of scope → RESOLVED in Phase 135)

Both confirmed failing at the phase-start base commit 8cf3ad0 (before any 132-03
change) — not caused by the rindle extraction. Logged, deferred, then **fixed in Phase 135**
(CI-ops hardening) to make the `core hermetic proof` lane green and registerable (PROOF-03).

1. `test/crosswake/planning/milestone_transition_reset_test.exs:35` —
   "REQUIREMENTS.md header does not name the active milestone v16.0 ...". A planning-doc
   state-drift assertion; REQUIREMENTS.md header used an em-dash (`v16.0 — Companion…`) that
   broke the canonical label substring `v16.0 Companion…` that ROADMAP/PROJECT already use.
   **FIXED:** REQUIREMENTS.md header reworded to keep the label intact.

2. `test/crosswake/proof/phase52_operator_truth_test.exs:101` —
   normalized publish-readiness JSON differs from committed fixture
   `test/fixtures/proof/phase52_publish_readiness.json`. **FIXED:** fixture refreshed — the
   only semantic drift was `dependency_missing` (Phase 130's 13th denial reason, COMPAT-01/D-04)
   that the fixture predated; no readiness category/code/proof-class/rebuild change. (A second,
   intentional line — `guides/companion_compatibility.md` in the docs list — came from also
   un-orphaning that guide in `mix.exs` extras to green the `hex page proof` lane.)

## Also fixed in Phase 135 (was failing on the PR, not in deferred-items)

3. `test/crosswake/hex_page_test.exs:151` — `guides/companion_compatibility.md` (created in 132)
   was never added to docs `:extras`, orphaning it from HexDocs. **FIXED:** added to `extras`
   and the `Extension Authors` group in `mix.exs`.
