---
phase: 197-public-docs-truth
plan: 03
subsystem: release-tooling
tags: [cleanroom, curl-hardening, pom-identity, need-tools, wr-04, wr-05, wr-06, in-03]

requires:
  - phase: 197-public-docs-truth
    provides: "197-01 script/mix_test_gate.sh, 197-02 baseline"
provides:
  - "script/verify_published_cleanroom.sh: bounded, https-pinned fetch; parse_failed and resolve_failed reasons; POM project-coordinate check; complete per-leg need_tools"
  - "test/fixtures/cleanroom/crosswake-shell-core-android-0.2.11.pom: the real Maven Central POM, byte-for-byte"
affects: [197-04]

actuals:
  tokens: 4431
  tasks: 2
  commits: 2
plan_head_before: b33efea20b10d9c9e2c7112796173884732ad438
plan_head_after: 91503186a6f96892bb42b2f5c3a39c15d60bfc52

tech-stack:
  added: []
  patterns:
    - "Sentinel-byte block stripping in sed ERE (no non-greedy match): replace the close tag with \\001, delete <tag>[^\\001]*\\001"
    - "Per-leg tool-removal loop: parse the need_tools list from source, require it equals the expected list, remove each tool in turn"

key-files:
  created:
    - test/fixtures/cleanroom/crosswake-shell-core-android-0.2.11.pom
  modified:
    - script/verify_published_cleanroom.sh
    - test/crosswake/release/published_cleanroom_test.exs

key-decisions:
  - "file:// fixtures are answered locally in fetch(): missing path is 3, a path that exists but is not a readable regular file is 4, so resolve failures never read as not_published"
  - "pom_field strips a superset of the planned blocks (adds distributionManagement, reporting, and XML comments) because those can carry their own groupId/artifactId/version"
  - "Version argument validation uses a bash regex instead of grep so a missing grep surfaces as FAIL <leg> tool_unavailable rather than a usage error"

requirements-completed: []

duration: 55min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 03: cleanroom script hardening Summary

**`verify_published_cleanroom.sh` now bounds and https-pins every network fetch, reports resolve and parse failures under their own reasons instead of `not_published`, binds the Maven POM to the exact project coordinate (proven on the real 0.2.11 POM), and fails closed on any missing tool its legs call.**

## Accomplishments

- WR-04: the network curl carries `--max-time 120 --retry 2 --proto '=https' --proto-redir '=https'` (constants `CURL_MAX_TIME`, `CURL_RETRY`). No `--retry-all-errors`. A source assertion checks each flag, with a removal control (mutated copy differs, helper flags exactly the removed flag).
- WR-05: a 200 hex response with no checksum is `FAIL hex parse_failed`; a failing `git ls-remote` is `FAIL ios resolve_failed`; only a successful empty lookup or a 404 is `not_published`; a `file://` path that exists but is not a readable regular file is `resolve_failed`. Header output contract lists reasons per leg.
- WR-06: `pom_field` reads project-level groupId, artifactId, version and packaging; `leg_maven` requires `io.github.sztheory`, `crosswake-shell-core-android`, the version under test and `aar`. Real POM 0.2.11 (HTTP 200, 69 lines, coordinates on lines 10-13 as recorded, no parent, five dependencies) passes; a copy with only the project version changed to 0.2.10 and a copy with a `<parent>` of the real coordinates plus project groupId changed to `io.github.other` both fail `pom_mismatch`. Four synthetic cases (group, artifact, version-with-matching-dependency, packaging) also fail.
- IN-03: `need_tools` lists are maven `curl cut grep mktemp head tr sed mkdir`, hex `curl grep cut tr head tail mktemp mkdir`, ios `git swift mktemp cut`. One test per leg parses the list from the script, requires it equal the expected list, and removes each tool from PATH in turn, requiring `FAIL <leg> tool_unavailable` and no `leg <leg> PASS`. A mutation (dropping `tail` from the hex list) made the hex loop test fail, then was reverted.

## Test counts

- `published_cleanroom_test.exs` baseline at plan start: 12 tests. After Task 1: 17 (floor 13). After Task 2: 26 (floor 23). All through `script/mix_test_gate.sh`, verdict PASS.
- `absence_is_not_success_test.exs`: 59 tests, PASS (floor 59). `mix format --check-formatted` clean; `bash -n` clean; no-argument run prints the usage line and exits 2.

## need_tools audit (non-builtin commands each leg body calls)

| Leg | Tool | Where (line in final script) |
|---|---|---|
| maven | curl | fetch 132, 137 |
| maven | mktemp | mk_work 168 |
| maven | mkdir | 180 |
| maven | tr, head, cut | checksum parse 192; PASS line 208 |
| maven | grep, head, tr, sed | pom_field 157-163 |
| maven | shasum or sha256sum, cut | sha256_of 113-116 (alternative, checked separately at 174) |
| hex | curl | fetch via 217 |
| hex | jq or python3 | 227-230 (alternative, checked at 214-218) |
| hex | tr | 232, 256 |
| hex | mkdir | 237 |
| hex | mix | 245-266 (checked after the fetch, as today) |
| hex | grep, head, tail | 255-256, 266 |
| hex | cut | 271 |
| hex | mktemp | mk_work |
| ios | git | 278, 283, 291 |
| ios | swift | 287 |
| ios | mktemp | mk_work |
| ios | cut | 291 |
| none | rm | only in the script-level EXIT trap `cleanup` (92); no leg lists it |

## Deviations from Plan

**1. [Rule 1 - Bug] `file://` directory does not make curl fail**
- **Found during:** Task 1 design check
- **Issue:** on curl 8.7.1 `curl -o out file:///some/dir` exits 0 with an empty file, so the plan's "curl cannot copy it" assumption would have let a directory pass as a successful fetch.
- **Fix:** `fetch()` tests the path explicitly (`-e` then `-f` and `-r`) before calling curl, so an existing-but-uncopyable path returns 4 independent of curl's behavior or the uid running the test.
- **Commit:** `0778979e`

**2. [Rule 3 - Blocking] Top-level `grep` use blocked the grep removal case**
- **Found during:** Task 2 design
- **Issue:** argument validation piped the version through `grep` before any leg ran, so removing `grep` from PATH would exit 2 (usage), not `tool_unavailable`. `need_tools` cannot move ahead of argument validation.
- **Fix:** the strict `X.Y.Z` check uses `[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]`; same acceptance set, no external command.
- **Commit:** `91503186`

**3. [Rule 2 - Missing critical] `pom_field` strips a superset of blocks**
- Adds `distributionManagement`, `reporting` (can contain relocation/plugin coordinates) and XML comments to the planned five blocks; strips each block with a sentinel-byte delete so a nested or repeated block cannot swallow project-level elements.
- **Commit:** `91503186`

**4. [Process] Missing-tool loop uses stub executables for tools absent on the host**
- `swift` is not guaranteed on a Linux runner; a tool the host lacks is replaced by an empty executable so the "was in the set before removal" guard holds everywhere. The tests only need `command -v` to see the tool because each leg fails at `need_tools` first.

## Known Stubs

None.

## Threat Flags

None. No new endpoint or auth path; the change narrows existing network behavior. The committed fixture holds only public coordinates, the public repository URL and the public maintainer handle.

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: later plans in the phase also carry it.

## Self-Check: PASSED

- FOUND: script/verify_published_cleanroom.sh, test/crosswake/release/published_cleanroom_test.exs, test/fixtures/cleanroom/crosswake-shell-core-android-0.2.11.pom
- FOUND commits: 0778979e, 91503186 (ancestors of HEAD); no deletions in either commit
- `.planning/config.json` still shows an uncommitted modification and is in no commit.
