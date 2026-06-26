## Pre-existing failures discovered during 132-03 execution (out of scope)

Both confirmed failing at the phase-start base commit 8cf3ad0 (before any 132-03
change) — not caused by the rindle extraction. Logged, not fixed (SCOPE BOUNDARY).

1. `test/crosswake/planning/milestone_transition_reset_test.exs:35` —
   "REQUIREMENTS.md header does not name the active milestone v16.0 ...". A planning-doc
   state-drift assertion; REQUIREMENTS.md header still names a prior milestone label.

2. `test/crosswake/proof/phase52_operator_truth_test.exs:101` —
   normalized publish-readiness JSON differs from committed fixture
   `test/fixtures/proof/phase52_publish_readiness.json`. Fixture drift independent of
   the rindle move (fixture references only generic companion health, not rindle).
