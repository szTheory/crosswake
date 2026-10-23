# LAND-02 dispositions

Every failure that existed before Phase 191 is now fixed, and nothing is listed as still failing. One more failure, found only by this plan's run (two example-host-only tests whose manifest fixture lacked a routes object), was fixed by the FIXTURE commit (A-15) and is recorded after the table.

Each row below is one row of Phase 190's baseline-dispositions.md. "Shown passing in" names the gate record at the FIXTURE head 7075a441 (the full-suite record is suite-ALL.txt, nine stages, 0 failures).

| Failing test | Disposition | Fixed by | Shown passing in |
|---|---|---|---|
| G1 gate: validator rejects the host audio command as an unknown capability | fixed | G1 commit ee9d304d | suite-ALL root-proof (main lane 2657 tests, 0 failures) |
| Phase 170 ledger: completeness, both directions (C-locale decode failure) | fixed | LOCALE commit 5fd65f9f | suite-ALL root-proof (main lane) |
| Phase 170 ledger: adjacency edge, two identical adjacent assertions | fixed | LOCALE commit 5fd65f9f | suite-ALL root-proof (main lane) |
| Phase 170 ledger: encoding edge, re-wrapping a flagged assertion | fixed | LOCALE commit 5fd65f9f | suite-ALL root-proof (main lane) |
| Phase 170 ledger: encoding edge, renaming an identifier | fixed | LOCALE commit 5fd65f9f | suite-ALL root-proof (main lane) |
| Phase 170 ledger: ordering edge, byte-identical regeneration | fixed | LOCALE commit 5fd65f9f | suite-ALL root-proof (main lane) |
| Example host phase180_twin_feasibility_test G2 | fixed | HOST-G2G6 commit 55708e5b | suite-HOST-FINAL (167 tests, 0 failures) and suite-ALL example-host-proof |
| Example host phase180_twin_feasibility_test G6 | fixed | HOST-G2G6 commit 55708e5b | suite-HOST-FINAL (167 tests, 0 failures) and suite-ALL example-host-proof |
| Swift suite G4 | fixed | SWIFT-G4 commit 6b9a6d9c | suite-ALL ios-package-proof (89 tests, 0 failures) and suite-SWIFT-EXPORT-FINAL (0 skips) |

## Found by Plan 11 and fixed

Two example-host-only tests in `crosswake_doctor_router_test.exs` (accepts a freshly written Phoenix router without external preloading; discovers the installed router when --router is omitted) failed at the carry head because their manifest fixture had no routes object and the tightened doctor check rejects that. The doctor check was right; the fixture was stale. FIXTURE commit 7075a441 adds an empty routes object to the fixture. Red before, green after (fixture-191.txt), and the whole example-host stage passes in suite-ALL.
