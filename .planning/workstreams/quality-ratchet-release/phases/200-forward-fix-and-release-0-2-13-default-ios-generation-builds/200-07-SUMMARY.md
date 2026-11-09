---
phase: 200-forward-fix-and-release-0-2-13-default-ios-generation-builds
plan: 07
subsystem: release-train
tags: [rel-09, release-gates, core-hex, core-maven, release-0.2.13]
provides:
  - crosswake 0.2.13 published to Hex with docs (job success, version visible, publication record artifact 13686714976)
  - io.github.sztheory:crosswake-shell-core-android 0.2.13 published to Maven Central (POM and AAR 200, visible after 23 polls at 15:47:53Z)
affects: [200-08]
release_run_id: 42639651064
---

# 200-07: Hex and Maven gates

- core-hex attempt 1: displayed to the user, who answered allow and made publishes standing; environment 26568191797 approved once at 15:17:58Z (comment `200 core-hex attempt 1`); job success 15:18:01Z to 15:32:18Z; hex.pm 0.2.13 has docs; the only pending deployment afterwards was `publish-maven`.
- core-maven attempt 1: approved under the standing publish decision (no question asked; scope stated in chat and noted in gates-200.txt); environment 26568192162 approved once at 15:33:13Z (comment `200 core-maven attempt 1`); job success 15:33:16Z to 15:36:27Z; POM and AAR visible; the only pending deployment afterwards was `publish-ios-mirror`.
- Both pass the run-bound gate-order checker. Records: core-hex-200.json, core-maven-200.json, gates-200.txt.
