---
phase: 182-loopback-origin-for-local-ios-host
review: 182-REVIEW.md
critical: 0
warning: 6
info: 4
recorded: 2026-10-14
---

# Phase 182 review disposition

The review found no blockers. Every finding is still open: none was fixed during phase execution. Fixing any of them means a new commit on `phase182-impl`. After that, the Simulator harness has to rerun, `182-FINAL-HEAD.json` has to be refreshed, and the Phase 180 candidate has to move again (182-06 procedure). The review is advisory, so the phase verdict (182-VERIFICATION.md, passed) is unaffected.

| Finding | Severity | Disposition | Note |
|---------|----------|-------------|------|
| WR-01 | warning | open | Plist reconcile is not transactional with the other generated outputs. |
| WR-02 | warning | open | `IOSHostGeneration.origin_transport/1` does not re-check the loopback host allowlist for hand-built structs. |
| WR-03 | warning | open | The harness assertion that owned hashes are unchanged cannot fail as written. |
| WR-04 | warning | open | A failed evidence-file write in the harness is not checked. |
| WR-05 | warning | open | The harness reports `passed` even when uninstall or shutdown cleanup failed. |
| WR-06 | warning | open | `mix crosswake.inspect` now prints the HTTPS origin for every declared host, not only in local mode. |
| IN-01 | info | open | Drift message grammar and duplicated repair text. |
| IN-02 | info | open | `grep -q` under `pipefail` can fail falsely. |
| IN-03 | info | open | No timeouts on `xcodebuild`, `mix run` or `simctl bootstatus`. |
| IN-04 | info | open | Unused `rc` variable; race on the listener log in the narrowness check. |
