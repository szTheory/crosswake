# Phase 145: User Setup Required

**Generated:** 2026-07-08
**Phase:** 145-native-registry-mirror-parity
**Status:** Incomplete

Complete these items for apply-mode iOS mirror publishing/backfill to function. Automation can verify workflow shape and local fixtures, but it cannot provision repository secrets.

## Environment Variables

| Status | Variable | Source | Add to |
|--------|----------|--------|--------|
| [ ] | `MIRROR_PUSH_TOKEN` | GitHub fine-grained PAT or GitHub App token scoped to `szTheory/crosswake-shell-core-ios` with `Contents:write` | GitHub Actions repository secret |

## Dashboard Configuration

- [ ] **Store the mirror write token**
  - Location: GitHub repository settings -> Secrets and variables -> Actions
  - Secret name: `MIRROR_PUSH_TOKEN`
  - Scope: `szTheory/crosswake-shell-core-ios`
  - Required permission: `Contents:write`

## Verification

After completing setup, verify through the release workflow or the iOS mirror backfill workflow in apply mode.

Expected results:
- `[crosswake] OK` output names the package/version/ref being verified.
- Missing, read-only, or wrong-repository tokens fail before public mirror mutation.

---

**Once all items complete:** Mark status as "Complete" at top of file.
