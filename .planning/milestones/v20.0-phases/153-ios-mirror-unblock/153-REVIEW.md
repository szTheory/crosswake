---
phase: 153-ios-mirror-unblock
reviewed: 2026-07-30T20:58:27Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - .github/workflows/ios-mirror-backfill.yml
  - .github/workflows/release-please.yml
  - lib/crosswake/release_status.ex
  - script/check_release_workflow_integrity.exs
  - script/verify_ios_mirror_backfill.sh
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - test/crosswake/proof/phase145_ios_backfill_script_test.exs
  - test/crosswake/proof/phase153_ios_mirror_unblock_test.exs
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 153: Code Review Report

**Reviewed:** 2026-07-30T20:58:27Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Reviewed the iOS mirror backfill workflow, Release Please native publish path, release-status live probe logic, structural scanner, and phase proof tests. The release identity, explicit-lease, fail-closed registry-status, and focused phase tests are generally coherent. One security/robustness issue remains in the SSH transport setup: the workflows dynamically trust `ssh-keyscan` output instead of pinning GitHub's host key.

Verification run during review:

- `elixir script/check_release_workflow_integrity.exs` - passed
- `mix test --only phase153_ios_mirror_unblock` - 19 tests, 0 failures

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: SSH Host Key Is Learned Dynamically Instead Of Pinned

**File:** `.github/workflows/release-please.yml:423`
**Issue:** `publish-ios-core` appends unauthenticated `ssh-keyscan` output directly to `~/.ssh/known_hosts`, and `.github/workflows/ios-mirror-backfill.yml:80` repeats the same pattern. That preserves non-interactive SSH, but it does not actually pin GitHub's host identity. A network/DNS MITM during the release or backfill job can supply its own host key, satisfy SSH host verification, and receive the mirror push attempt. The deploy key itself is not sent, but the release job can still report success against the wrong SSH endpoint while the real SwiftPM mirror remains unmodified, reintroducing the "green but adopters cannot resolve" failure mode this phase is meant to eliminate.

**Fix:** Pin GitHub's published SSH host key material in the workflow or in a checked-in helper, then verify `ssh-keyscan` against that pinned value before writing `known_hosts`. Update the structural checker to require the pinned fingerprint/value, not just the presence of `ssh-keyscan`.

```yaml
- name: Add GitHub to known_hosts
  run: |
    set -euo pipefail
    mkdir -p ~/.ssh
    cat > ~/.ssh/known_hosts <<'EOF'
    github.com ssh-ed25519 <pinned GitHub ed25519 host key>
    EOF
```

Also change `script/check_release_workflow_integrity.exs` so `release.ios.ssh_transport` and `release.ios_backfill.ssh_transport` fail unless the pinned host-key contract is present.

---

_Reviewed: 2026-07-30T20:58:27Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
