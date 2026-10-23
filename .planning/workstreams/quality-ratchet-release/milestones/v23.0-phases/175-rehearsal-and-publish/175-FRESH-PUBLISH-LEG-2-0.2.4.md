# Phase 175 — Fresh core 0.2.4 publish leg (PARTIAL)

## Authorization and protected merge

Plan 175-20 received the exact Gate 2 response bound to PR #201 and iOS rehearsal `36029609207`. The immediate pre-merge machine checks passed. PR #201 merged once through normal protected merge-commit behavior at `f3827d0bf4131badd96d04d924f9faca2789d284` on `2026-09-24T17:38:39Z`. The merge parents are base `e298793a40538500003602edb6b1d7ea2221ee84` and approved candidate head `dfe7c0b4be909130f2474ed7d4e97e8e52d49498`; its tree equals approved tree `215493f06e4119faa25a692db7f2e8de47d39b3c`. Exact-OID runbook ancestry passed for the merge.

The one ordinary Release Please workflow run was `36035737504`, bound to merge head `f3827d0bf4131badd96d04d924f9faca2789d284`. The approved-candidate merge guard and Release Please job succeeded. The core Hex job succeeded. The iOS mirror and Maven Central core jobs failed. All five companion publish jobs, both platform clean-room jobs, and exact-public proof were skipped. Native status rollup and linked release rollup failed; the alert job succeeded. The run conclusion is `failure`.

## Independent registry state

Read-only queries at `2026-09-24T17:47:24Z` found:

- Hex `crosswake@0.2.4`: present (HTTP 200; version listed).
- iOS `refs/tags/v0.2.4`: absent. Mirror `main` remains at the expected split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, matching the rehearsal baseline; the version tag is absent.
- Maven `io.github.sztheory:crosswake-shell-core-android:0.2.4`: absent (exact POM HTTP 404). The Maven workflow failed before Gradle ran: `android_publication.sh` is still pinned to the earlier Phase 168 merge/head/tree/receipt, so its fail-closed identity guard rejected this 0.2.4 merge. The exact POM is absent and no Central deployment was started by this script.

## Disposition and stop

This release is **PARTIAL**: Hex is live; the iOS version tag is absent (mirror main remains at the expected split); Maven remains absent from its public coordinate. No workflow or publish job was retried, and no recovery was attempted. The Plan 175-20 authorization was only for one ordinary graph and does not authorize another write. Exact-public proof did not run, so Phase 175-21 cannot proceed. Do not claim complete release or REL-14 proof.

The next work is to fix the two independently demonstrated workflow integration defects, then prepare a separately scoped recovery plan and authorization for the missing iOS tag and Maven coordinate. Preserve the 0.2.3 partial and the historic REL-10 breach independently.
