---
phase: 185-checks-that-cannot-pass-empty
review: 185-REVIEW.md
critical: 0
warning: 5
info: 2
recorded: 2026-10-16
---

# Phase 185 review disposition

The standard-depth review of `fix(185)` `25614cf685e2ee299646e04b833293c677023c45` found no critical issue. It could not make the absence checker pass on an empty or partial scope, it traced every lockfile path to the both-lockfiles rule, and it found the floors it read sitting before their loops and not vacuous. The verifier passed the phase 4/4 independently (185-VERIFICATION.md). No finding blocks completion. The open rows below carry forward as advisory debt.

| ID | Severity | Disposition | Note |
|----|----------|-------------|------|
| WR-01 | warning | kept by decision (D-14) | The callers discarding the stop result is the recorded D-14 deferral, pinned by tests. Reopen trigger unchanged: the next twin change that alters the cause list or receipt (Phase 188 or later), or any run that leaves a process behind. |
| WR-02 | warning | open | A 5 s `Agent.get` timeout in `tracked_children` is read as `:registry_gone`; `stop_all` then stops a live registry and loses its child list. Candidate for the next twin-touching change: catch only `:noproc`/`:normal`-class exits as gone, or treat a timeout as `:child_still_alive`. |
| WR-03 | warning | open | `--min-test-files` accepts 0 and negative values (reproduced: both print OK, exit 0). The flag is fixture-only (D-03), but nothing enforces that. Fix candidate: refuse N < 1 with exit 2. |
| WR-04 | warning | open | `VerifyTwin.lock_digests/1` requires a regular file (lstat) while `TwinProducers.file_digest` follows symlinks, so the two lockfile rules disagree on a symlinked lockfile. Align on lstat in the next twin-touching change. |
| WR-05 | warning | open | The unreadable-lockfile test asserts nothing when run as root (the chmod skip is recorded, but the test still reports a pass). Fix candidate: tag the test and skip it explicitly under uid 0. |
| IN-01 | info | kept by decision (D-12) | No CI lane or new check script is added; the checker is enforced through its ExUnit test, which the full suite runs. |
| IN-02 | info | open (advisory) | A dangling symlink blocks with a message that does not say why; the planning scopes are pinned at 1. Both fail closed. |
