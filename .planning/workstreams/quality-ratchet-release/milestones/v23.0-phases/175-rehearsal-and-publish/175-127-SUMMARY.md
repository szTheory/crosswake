# Plan127 Summary — One current-facts read and wrapper repair

Plan127 branch: ALLOW/UNKNOWN
Plan127 result SHA-256: a42e080c2017f588a2edd58e0fd5b0da76799ae9bded58f88a55eb67bdf6725f

Last completed phase: 174. Phase175 remains IN PROGRESS and INCOMPLETE; the release hold remains active.

The exact ALLOW was used once for attempt `7680ed805a23c6ee3b58d287d8496a3e`. The read completed, but it returned no usable current facts. Its safe diagnostic was `CURRENT_COLLECTOR / PROCESS_RESULT_INVALID`; uncertain GitHub, Git, credential-helper, and permission counts remain UNKNOWN. Dry-run, tag, and CI counts are zero. The offline terminal-record check passed. The attempt and approval are spent; no retry occurred.

The diagnostic led to a specific local cause: the Node collector returns the current-read fields (`status`, `reason`, `facts`, `operation_counts`, and `diagnostic`), while the Elixir output decoder accepted only older result shapes. The decoder therefore rejected the current-read result before the current-read validator could inspect it. The decoder now accepts that exact current-read shape only when its diagnostic has the safe, allowlisted form. A fake Node process regression test exercises the production wrapper without network access.

Checks after the repair passed:

- Focused ExUnit file: 32 tests, 0 failures.
- Warnings-as-errors compile.
- Named formatter check.
- Scoped `git diff --check`.

No push, dry run, tag, CI, merge, registry, publication, or release-authority action occurred. This local repair does not turn the consumed read into current facts and does not authorize another read.

Plan106 remains HELD; REL-13/14/15/17 remain OPEN; readiness BLOCKED; write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE.

The distinct decoder mismatch is now locally repaired and covered. Next GSD command: `$gsd-plan-phase 175 --ws quality-ratchet-release --skip-research` to plan the next bounded observation using the repaired wrapper. Any later read needs a newly prepared scope and a separate exact ALLOW; do not reuse this attempt or approval.
