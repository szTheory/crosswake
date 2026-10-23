# Phase 192 shared library (D-04, D-05, D-06). POSIX sh; sourced, never executed.
# The caller sets HERE to the 192 scripts folder before sourcing.
# Prints only `common:` labels. A failure exits the caller with 2.

if [ -z "${HERE:-}" ]; then echo "common: locate failed"; exit 2; fi

_C192_S191=$(cd "$HERE/../../191-integration-branch-and-local-suite/scripts" 2>/dev/null && pwd -P) || { echo "common: locate failed"; exit 2; }
sh "$_C192_S191/locate-191.sh" >/dev/null || { echo "common: locate failed"; exit 2; }
. /private/tmp/crosswake-phase191-run/env-191.sh
. "$S191/git-pinned-191.sh"

P192="$WS/phases/192-pr-ci-and-merge"
EV192="$P192/192-EVIDENCE"
S192="$P192/scripts"
R192="$R191/p192"
FINALIZE="$S191/finalize-191.sh"
POLL_SLEEP=30

REPO_SLUG=szTheory/crosswake
CI_CHECK="Crosswake CI"
CI_APP=15368
PUSH_REF=refs/heads/land/v25-v27

# --- self-test hook guard -------------------------------------------------
_c192_any=""
for _n in T192_IC T192_FINALIZE T192_EV192 T192_R192 T192_MAIN T192_SLEEP; do
  eval "_v=\${$_n:-}"
  if [ -n "$_v" ]; then _c192_any=1; fi
done
if [ -n "$_c192_any" ] && [ "${SELFTEST_192:-}" != "1" ]; then
  echo "common: hook set outside self-test"; exit 2
fi
if [ "${SELFTEST_192:-}" = "1" ]; then
  for _n in T192_IC T192_FINALIZE T192_EV192 T192_R192; do
    eval "_v=\${$_n:-}"
    if [ -n "$_v" ]; then
      case "$_v" in
        /private/tmp/crosswake-selftest-*) : ;;
        *) echo "common: hook outside fixture"; exit 2 ;;
      esac
    fi
  done
  [ -z "${T192_IC:-}" ] || IC=$T192_IC
  [ -z "${T192_FINALIZE:-}" ] || FINALIZE=$T192_FINALIZE
  [ -z "${T192_EV192:-}" ] || EV192=$T192_EV192
  [ -z "${T192_R192:-}" ] || R192=$T192_R192
  [ -z "${T192_MAIN:-}" ] || MAIN_SHA=$T192_MAIN
  [ -z "${T192_SLEEP:-}" ] || POLL_SLEEP=$T192_SLEEP
fi

if [ ! -d "$R192" ]; then mkdir -m 0700 "$R192" 2>/dev/null || { echo "common: run folder unsafe"; exit 2; }; fi
if [ "$(stat -f %u "$R192" 2>/dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$R192" 2>/dev/null)" != 700 ]; then
  echo "common: run folder unsafe"; exit 2
fi

# --- validators -----------------------------------------------------------
is_sha40() {
  case "${1:-}" in
    *[!0-9a-f]*|'') return 1 ;;
  esac
  [ "${#1}" -eq 40 ]
}

is_int() {
  case "${1:-}" in
    *[!0-9]*|'') return 1 ;;
  esac
  return 0
}

# --- atomic write: stdin -> FILE (mode 600) -------------------------------
ev_write() {
  _ew_f=$1
  _ew_t=$(mktemp "$(dirname "$_ew_f")/.evw.XXXXXX") || return 2
  cat > "$_ew_t" || { rm -f "$_ew_t"; return 2; }
  chmod 600 "$_ew_t" && mv -f "$_ew_t" "$_ew_f"
}

# --- live remote read: prints SHA, `absent`, or returns 2 -----------------
live_ref() {
  _lr_out="$R192/live-ref.out"
  g "$IC" -c credential.helper= -c 'credential.helper=!gh auth git-credential' ls-remote origin "$1" > "$_lr_out" 2>/dev/null
  _lr_rc=$?
  [ "$_lr_rc" -eq 0 ] || return 2
  _lr_n=$(awk 'END{print NR+0}' "$_lr_out")
  if [ "$_lr_n" -eq 0 ]; then echo absent; return 0; fi
  [ "$_lr_n" -eq 1 ] || return 2
  _lr_sha=$(awk '{print $1}' "$_lr_out")
  _lr_ref=$(awk '{print $2}' "$_lr_out")
  is_sha40 "$_lr_sha" || return 2
  [ "$_lr_ref" = "$1" ] || return 2
  echo "$_lr_sha"
}

# --- gh from a folder that is not a git repository ------------------------
ghx() {
  ( cd "$R192" && GH_PROMPT_DISABLED=1 GH_NO_UPDATE_NOTIFIER=1 exec gh "$@" )
}

# --- write log: KIND then the exact gh argv, absolute paths by basename ---
log_write() {
  _lw_kind=$1
  shift
  _lw_line=$_lw_kind
  for _lw_a in "$@"; do
    case "$_lw_a" in
      /*) _lw_a=$(basename "$_lw_a") ;;
    esac
    _lw_line="$_lw_line $_lw_a"
  done
  printf '%s\n' "$_lw_line" >> "$EV192/gh-writes-192.txt"
}
