# Plan 192-07 blocked: red_not_shown

Plain-language result: the plan could not show WR-01 failing before the fix, so I stopped before editing anything. No commit was made, nothing was pushed, and no planning file other than this one was changed.

## What was checked

1. Preconditions held: 192-06-SUMMARY.md exists, no BLOCKED file for 06, `ensure-clone` printed `reused`, and the clone HEAD equals the SYNC-2 line of heads-191.txt and the `sync_head` of sync-192.txt (2525bdce).
2. Step (1) of Task 1: I made a copy of `script/inventory_collection_assertions.exs` with the latin1 setopts line deleted, ran it under `LC_ALL=C LANG=C` with `--emit-snapshot` over scope `test/**/*.exs`, and compared the output with the committed ledger. I ran the unmodified script the same way.

## What happened

- C locale: mutant exit 0, bytes equal to the committed ledger (115328 bytes). Fixed script exit 0, bytes equal. The plan's required `mutant_bytes differ` was not produced, so the closed-list cause is `red_not_shown`.
- Extra diagnosis (not part of the plan, read-only runs): with stdout redirected to a file or pipe under the C locale, Erlang's standard_io is already `encoding: latin1`, so removing the latin1 setopts line changes nothing there. The mutant differs from the ledger only under a UTF-8 locale (C.UTF-8 and en_US.UTF-8 both: mutant bytes differ, fixed bytes equal; the ledger contains non-ASCII text).

## Assessment

The plan's WR-01 design is flawed, not the environment: a C-locale test comparing `output == File.read!(@ledger)` would also pass on the unfixed script, so it would repeat the weakness 191-REVIEW WR-01 describes (a test that cannot detect the bug). The byte-equality assertion is still an improvement, but to be a real red-before check the comparison must run the script under a UTF-8 locale (the locale where the regression shows), either instead of or in addition to the C locale. That changes the plan's behavior and test text, so it needs a decision before I proceed.

Suggested revision (needs user or planner approval): in step (1) run the mutant and the fixed script under `LC_ALL=C.UTF-8`; in the ledger test assert byte equality in both the C and a UTF-8 locale run (or only UTF-8). The rest of the plan stays the same.

## Clone and recovery state

- Clone HEAD: 2525bdce728b792a8fa52bc5d3b944ddd3652a4a (SYNC-2), working tree clean, no LAND-FIX label in heads-191.txt.
- Only files written: run-folder scratch (mutant script and outputs) and this file. No evidence file in 192-EVIDENCE was created or changed; push-192.txt not appended.
- Nothing remains for Tasks 1 steps (2) to (8) and Task 2; none were started.
