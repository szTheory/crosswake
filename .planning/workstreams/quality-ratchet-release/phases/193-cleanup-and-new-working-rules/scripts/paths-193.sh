# Phase 193 shared paths (sourced, no side effects beyond assigning variables).
# Everything is derived from the location of this file. No home path literal.
# Self-test overrides (P193_PARENT, P193_TMPCW, P193_TABLE) are honoured only when
# SELFTEST_193=1 and the value sits under the self-test fixture prefix.

_p193_here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || return 2
_p193_tmpd=${TMPDIR:-}
if [ -z "$_p193_tmpd" ] || [ ! -d "$_p193_tmpd" ]; then
  echo "paths: TMPDIR unset or not a directory" >&2
  return 2
fi
_p193_tmpd=$(cd "$_p193_tmpd" && pwd -P) || return 2
ST193_PREFIX="$_p193_tmpd/cw193-st."

SCRIPTS193=$_p193_here
TOP=$(cd "$_p193_here/../../../../../.." && pwd -P) || return 2
PARENT=$(dirname "$TOP")
_p193_ok_override() { # 0 when SELFTEST_193=1 and the value starts with the fixture prefix
  [ "${SELFTEST_193:-}" = 1 ] || return 1
  case ${1:-} in
    "$ST193_PREFIX"*) return 0 ;;
  esac
  return 1
}
if [ -n "${P193_PARENT:-}" ] && _p193_ok_override "$P193_PARENT"; then
  PARENT=$P193_PARENT
fi

BACKUP_ROOT=$PARENT/crosswake-candidate-backup
INV=$BACKUP_ROOT/inventory-189
CLONE=$PARENT/crosswake-clean-main
RETIRED=$PARENT/crosswake-recovery-retired
INTEG=$PARENT/crosswake-integration-191
DURABLE=$PARENT/crosswake-candidate-durable
BRIDGE=$PARENT/crosswake-accrue-bridge
RUN193=$_p193_tmpd/cw193-run
if [ -n "${P193_RUN:-}" ] && _p193_ok_override "$P193_RUN"; then
  RUN193=$P193_RUN
fi

# the crosswake* entries live in the system temp folder of the earlier phases
TMPCW=/private/tmp
if [ -n "${P193_TMPCW:-}" ] && _p193_ok_override "$P193_TMPCW"; then
  TMPCW=$P193_TMPCW
fi

P193=.planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules
E3=$P193/193-EVIDENCE
S3=$P193/scripts
S191=.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts
S192=.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/scripts
P189=.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup
REPO_SLUG=szTheory/crosswake

RECOVERY_BRANCH=recovery/phase-175-orchestrator-2026-09-27

# expected line counts of the 189 sums files and companions (preflight table)
SUMS_COUNTS="SHA256SUMS:167 SHA256SUMS.02:2 SHA256SUMS.03:8 SHA256SUMS.04:13 SHA256SUMS.05:5 SHA256SUMS.06:1 SHA256SUMS.07:3 SHA256SUMS.08:123 SHA256SUMS.11:2 SHA256SUMS.13:7 SHA256SUMS.cr01:2"
N_SCRIPTS189=22
N_IGNORED_FILES=46066
N_ENV_FILES=3
# restore checks of preflight: artifact kind expectation (names relative to the inventory folder)
RESTORES_193="refs-all.bundle bundle refs-all.reflist
tmp-commits.bundle bundle tmp-commits.expect
ignored-keep.tar tarfiles ignored-keep.files
env-local.tar tarfiles env-local.files
worktree-accrue-bridge.tar tarfiles worktree-accrue-bridge.files
worktree-agent-p78.tar tarfiles worktree-agent-p78.files
worktree-accrue-bridge.patch headpatch worktree-accrue-bridge.expect
worktree-agent-p78.patch headpatch worktree-agent-p78.expect
tmp-crosswake-phase179-hex.tar tarfiles tmp-crosswake-phase179-hex.files"
if [ -n "${P193_TABLE:-}" ] && _p193_ok_override "$P193_TABLE" && [ -f "$P193_TABLE" ]; then
  . "$P193_TABLE"
fi
