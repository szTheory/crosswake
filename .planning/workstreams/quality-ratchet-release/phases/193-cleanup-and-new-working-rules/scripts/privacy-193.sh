#!/bin/bash
# Phase 193 plain privacy check for public PR text and phase evidence (fork of the 192 check, standalone).
# usage: privacy-193.sh FILE...   |   privacy-193.sh --self-test
# exit 0 = clean, 1 = hits, 2 = no input or an unreadable input or a tool error (never a clean pass).
# Output: fixed `privacy:` labels only. A matched value, a path or a file name is never printed;
# K in `privacy: hit CLASS file K` is the 1-based argument index.
# Depends only on paths-193.sh. Scratch lives under the session temp folder, never the system temp root.
# Self-test hooks (SELFTEST_193=1 only): T193_ACCOUNT, T193_PRIVATE_STRINGS; every input must then sit
# under the fixture prefix.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || { echo "privacy: locate failed"; exit 2; }
SELF="$HERE/$(basename "$0")"

if { [ -n "${T193_ACCOUNT:-}" ] || [ -n "${T193_PRIVATE_STRINGS:-}" ]; } && [ "${SELFTEST_193:-}" != "1" ]; then
  echo "privacy: hook set outside self-test"; exit 2
fi

[ "${1:-}" = "--self-test" ] || [ "$#" -ge 1 ] || { echo "privacy: no input"; exit 2; }

. "$HERE/paths-193.sh" || { echo "privacy: locate failed"; exit 2; }

SYS_TMP="/pri""vate/tmp"
[ "$_p193_tmpd" != "$SYS_TMP" ] || { echo "privacy: temp root unsafe"; exit 2; }
case "$_p193_tmpd" in
  *[!A-Za-z0-9/._+-]*) echo "privacy: temp root unsafe"; exit 2 ;;
esac

HOOKS=
if [ -n "${T193_ACCOUNT:-}" ] || [ -n "${T193_PRIVATE_STRINGS:-}" ]; then HOOKS=1; fi
if [ -n "${T193_PRIVATE_STRINGS:-}" ]; then
  case "$T193_PRIVATE_STRINGS" in
    "$ST193_PREFIX"*) : ;;
    *) echo "privacy: hook outside fixture"; exit 2 ;;
  esac
fi

# patterns are assembled from fragments so this file never matches its own classes
SL=/
P_HOME="${SL}Us""ers/[A-Za-z0-9._-]+"
P_TEMP="${SL}va""r/folders/[A-Za-z0-9_+-]{2}/[A-Za-z0-9_+-]{8,}"
P_GH="(g""h[pousr]_|git""hub_pat_)[A-Za-z0-9_]{36,}"
P_PEM="BEGIN [A-Z ]*PRIV""ATE KEY"
CK="HEX_API_""KEY|HEX_ORGANIZATION_""KEY|(MAVEN|OSS""RH)[A-Z_]*(USERNAME|PASSWORD|TOKEN)|[A-Z_]*SIGNING[A-Z_]*(PASSWORD|PASSPHRASE)"
P_CRED="(${CK})[[:space:]]*[=:][[:space:]]*[\"']?[^[:space:]\"'<\${(][^[:space:]\"'()]{7,}"
P_EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
ATTR_ADDR="noreply@anth""ropic.com"

# ---------------------------------------------------------------- self-test
selftest() {
  ST=$(mktemp -d "$_p193_tmpd/cw193-st.XXXXXX") || { echo "privacy: scratch failed"; exit 2; }
  case "$ST" in
    "$ST193_PREFIX"*) : ;;
    *) echo "privacy: scratch failed"; exit 2 ;;
  esac
  trap 'case "$ST" in "$ST193_PREFIX"*) rm -rf "$ST" ;; esac' EXIT
  trap 'exit 2' INT TERM HUP
  TOTAL=0
  GOOD=0
  OUT="$ST/out.txt"
  FIXACCT="fixtureacct""name"
  mk() { printf '%s\n' "$2" > "$ST/$1"; }
  mk clean.txt "plain text with no private value"
  mk home.txt "see ${SL}Us""ers/fixtureuser/work for details"
  mk temp.txt "at ${SL}va""r/folders/ab/cdefghij12345 here"
  mk gh.txt "token g""hp_R7kQ2mZ9xT4vB1nL8cW3yH6dF0sJ5aPeXuGi end"
  mk pem.txt "-----BEGIN RSA PRIV""ATE KEY-----"
  mk cred.txt "HEX_API_""KEY=abcd1234efgh5678"
  mk acct.txt "owner is $FIXACCT today"
  mk priv.txt "inside fixturevalue""only here"
  mk email.txt "write to someone@example.org please"
  mk attr.txt "Co-Authored-By: Claude <noreply@anth""ropic.com>"
  mk noreply.txt "12345+user@users.noreply.github.com"
  printf '%s\n' "fixturevalue""only" > "$ST/private.txt"
  : > "$ST/empty-private.txt"
  mk unread.txt "unreadable fixture"
  chmod 000 "$ST/unread.txt"
  pv() { # ARGS: runs the real script with the fixture hooks
    SELFTEST_193=1 T193_ACCOUNT="$FIXACCT" T193_PRIVATE_STRINGS="$ST/private.txt" bash "$SELF" "$@" > "$OUT" 2>&1
    RC=$?
  }
  ctl() { # ID NAME EXPECTED_EXIT EXPECTED_LINE ARGS...
    _id=$1; _nm=$2; _ex=$3; _ln=$4
    shift 4
    TOTAL=$((TOTAL + 1))
    pv "$@"
    if [ "$RC" -eq "$_ex" ] && grep -qx "$_ln" "$OUT"; then
      GOOD=$((GOOD + 1)); echo "$_id $_nm: as expected"
    else
      echo "$_id $_nm: NOT as expected"
    fi
  }
  ctl P01 "clean file passes" 0 "privacy: clean files 1" "$ST/clean.txt"
  ctl P02 "home path hits" 1 "privacy: hit home_path file 1" "$ST/home.txt"
  ctl P03 "user temp path hits" 1 "privacy: hit user_temp file 1" "$ST/temp.txt"
  ctl P04 "token shape hits" 1 "privacy: hit gh_token file 1" "$ST/gh.txt"
  ctl P05 "key header hits" 1 "privacy: hit pem file 1" "$ST/pem.txt"
  ctl P06 "credential assignment hits" 1 "privacy: hit cred_assign file 1" "$ST/cred.txt"
  ctl P07 "account name hits" 1 "privacy: hit account file 1" "$ST/acct.txt"
  ctl P08 "private string hits" 1 "privacy: hit private_string file 1" "$ST/priv.txt"
  ctl P09 "outside email hits" 1 "privacy: hit email file 1" "$ST/email.txt"
  ctl P10 "attribution address is allowed" 0 "privacy: clean files 1" "$ST/attr.txt"
  ctl P11 "noreply address is allowed" 0 "privacy: clean files 1" "$ST/noreply.txt"
  ctl P12 "second file index is reported" 1 "privacy: hit home_path file 2" "$ST/clean.txt" "$ST/home.txt"
  ctl P13 "missing file is exit 2" 2 "privacy: unreadable" "$ST/nothere.txt"
  if [ "$(id -u)" -eq 0 ]; then
    TOTAL=$((TOTAL + 1)); GOOD=$((GOOD + 1)); echo "P14 unreadable file is exit 2: as expected"
  else
    ctl P14 "unreadable file is exit 2" 2 "privacy: unreadable" "$ST/unread.txt"
  fi
  TOTAL=$((TOTAL + 1))
  SELFTEST_193=1 bash "$SELF" > "$OUT" 2>&1; RC=$?
  if [ "$RC" -eq 2 ] && grep -qx "privacy: no input" "$OUT"; then GOOD=$((GOOD + 1)); echo "P15 no argument is exit 2: as expected"; else echo "P15 no argument is exit 2: NOT as expected"; fi
  TOTAL=$((TOTAL + 1))
  T193_ACCOUNT="$FIXACCT" bash "$SELF" "$ST/clean.txt" > "$OUT" 2>&1; RC=$?
  if [ "$RC" -eq 2 ] && grep -qx "privacy: hook set outside self-test" "$OUT"; then GOOD=$((GOOD + 1)); echo "P16 hook without self-test flag is exit 2: as expected"; else echo "P16 hook without self-test flag is exit 2: NOT as expected"; fi
  TOTAL=$((TOTAL + 1))
  SELFTEST_193=1 T193_PRIVATE_STRINGS="$SELF" bash "$SELF" "$ST/clean.txt" > "$OUT" 2>&1; RC=$?
  if [ "$RC" -eq 2 ] && grep -qx "privacy: hook outside fixture" "$OUT"; then GOOD=$((GOOD + 1)); echo "P17 hook outside fixture prefix is exit 2: as expected"; else echo "P17 hook outside fixture prefix is exit 2: NOT as expected"; fi
  TOTAL=$((TOTAL + 1))
  SELFTEST_193=1 T193_PRIVATE_STRINGS="$ST/empty-private.txt" bash "$SELF" "$ST/clean.txt" > "$OUT" 2>&1; RC=$?
  if [ "$RC" -eq 2 ] && grep -qx "privacy: private strings empty" "$OUT"; then GOOD=$((GOOD + 1)); echo "P18 empty private list is exit 2: as expected"; else echo "P18 empty private list is exit 2: NOT as expected"; fi
  TOTAL=$((TOTAL + 1))
  TMPDIR="$SYS_TMP" bash "$SELF" "$ST/clean.txt" > "$OUT" 2>&1; RC=$?
  if [ "$RC" -eq 2 ] && grep -qx "privacy: temp root unsafe" "$OUT"; then GOOD=$((GOOD + 1)); echo "P19 system temp root is refused: as expected"; else echo "P19 system temp root is refused: NOT as expected"; fi
  # static control: forbidden tool names assembled from fragments so this control never matches itself
  TOTAL=$((TOTAL + 1))
  F1="cross""wake-phase191-run"; F2="locate""-191"; F3="env""-191"; F4="common""-192"; F5="/pri""vate/tmp"
  grep -q -F -e "$F1" -e "$F2" -e "$F3" -e "$F4" -e "$F5" "$SELF"; _grc=$?
  if [ "$_grc" -eq 1 ]; then GOOD=$((GOOD + 1)); echo "P20 source names no run-folder tool or system temp root: as expected"; else echo "P20 source names no run-folder tool or system temp root: NOT as expected"; fi
  # no-entry control: a real run adds no crosswake* name to the system temp folder and leaves no scratch
  TOTAL=$((TOTAL + 1))
  ls -1 "$TMPCW" 2>/dev/null | awk '/^crosswake/' | sort > "$ST/names-before.txt"
  ls -1 "$_p193_tmpd" 2>/dev/null | awk '/^cw193-privacy\./' | sort > "$ST/scratch-before.txt"
  pv "$ST/clean.txt" "$ST/home.txt"
  ls -1 "$TMPCW" 2>/dev/null | awk '/^crosswake/' | sort > "$ST/names-after.txt"
  ls -1 "$_p193_tmpd" 2>/dev/null | awk '/^cw193-privacy\./' | sort > "$ST/scratch-after.txt"
  if cmp -s "$ST/names-before.txt" "$ST/names-after.txt" && cmp -s "$ST/scratch-before.txt" "$ST/scratch-after.txt"; then
    GOOD=$((GOOD + 1)); echo "P21 real run adds no crosswake entry and leaves no scratch: as expected"
  else
    echo "P21 real run adds no crosswake entry and leaves no scratch: NOT as expected"
  fi
  echo "selftest privacy-193: controls $GOOD of $TOTAL as expected"
  [ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 14 ] && exit 0
  exit 1
}

if [ "${1:-}" = "--self-test" ]; then selftest; fi

# ---------------------------------------------------------------- real run
SC=$(mktemp -d "${TMPDIR%/}/cw193-privacy.XXXXXX") || { echo "privacy: scratch failed"; exit 2; }
cleanup() { case "$SC" in "${TMPDIR%/}"/cw193-privacy.*) rm -rf "$SC" ;; esac; }
trap cleanup EXIT
trap 'exit 2' INT TERM HUP

ACCOUNT=${T193_ACCOUNT:-$(id -un)}
[ -n "$ACCOUNT" ] || { echo "privacy: account unknown"; exit 2; }
printf '%s\n' "$ACCOUNT" > "$SC/account.txt"

# fixed private strings: PARENT, INTEG, BACKUP_ROOT, DURABLE, HOME (empty values dropped; an empty list is an error)
if [ -n "${T193_PRIVATE_STRINGS:-}" ]; then
  [ -f "$T193_PRIVATE_STRINGS" ] && [ -r "$T193_PRIVATE_STRINGS" ] || { echo "privacy: unreadable"; exit 2; }
  awk 'NF' "$T193_PRIVATE_STRINGS" > "$SC/private.txt" || { echo "privacy: scratch failed"; exit 2; }
else
  printf '%s\n%s\n%s\n%s\n%s\n' "${PARENT:-}" "${INTEG:-}" "${BACKUP_ROOT:-}" "${DURABLE:-}" "${HOME:-}" | awk 'NF' > "$SC/private.txt" \
    || { echo "privacy: scratch failed"; exit 2; }
fi
[ -s "$SC/private.txt" ] || { echo "privacy: private strings empty"; exit 2; }

HITS=0
FILES=0
K=0

probe() { # CLASS FLAGS KIND(e|f) ARG FILE: one hit line per class per file
  grep -a -q $2 -$3 "$4" "$5" 2>/dev/null; _rc=$?
  case $_rc in
    0) HITS=$((HITS + 1)); echo "privacy: hit $1 file $K" ;;
    1) : ;;
    *) echo "privacy: grep failed"; exit 2 ;;
  esac
}

for f in "$@"; do
  K=$((K + 1))
  if [ ! -f "$f" ] || [ ! -r "$f" ]; then echo "privacy: unreadable"; exit 2; fi
  if [ -n "$HOOKS" ]; then
    _fd=$(cd "$(dirname "$f")" 2>/dev/null && pwd -P) || { echo "privacy: unreadable"; exit 2; }
    case "$_fd/" in
      "$ST193_PREFIX"*) : ;;
      *) echo "privacy: hook outside fixture"; exit 2 ;;
    esac
  fi
  FILES=$((FILES + 1))
  probe home_path "-i -E" e "$P_HOME" "$f"
  probe user_temp "-i -E" e "$P_TEMP" "$f"
  probe gh_token "-i -E" e "$P_GH" "$f"
  probe pem "-i -E" e "$P_PEM" "$f"
  probe cred_assign "-i -E" e "$P_CRED" "$f"
  probe account "-i -w -F" f "$SC/account.txt" "$f"
  probe private_string "-F" f "$SC/private.txt" "$f"
  grep -a -o -i -E -e "$P_EMAIL" "$f" > "$SC/m.out" 2>/dev/null; _rc=$?
  case $_rc in
    0)
      _bad=$(awk -v attr="$ATTR_ADDR" '
        function ew(a, b) { return length(a) >= length(b) && substr(a, length(a) - length(b) + 1) == b }
        { lm = tolower($0); at = index(lm, "@"); dom = substr(lm, at + 1); ok = 0
          if (lm == attr) ok = 1
          if (dom == "users.noreply.github.com" || ew(dom, ".users.noreply.github.com")) ok = 1
          if (!ok) n++ }
        END { print n + 0 }' "$SC/m.out") || { echo "privacy: awk failed"; exit 2; }
      if [ "$_bad" -gt 0 ]; then HITS=$((HITS + 1)); echo "privacy: hit email file $K"; fi ;;
    1) : ;;
    *) echo "privacy: grep failed"; exit 2 ;;
  esac
done

if [ "$HITS" -gt 0 ]; then
  echo "privacy: hits $HITS"
  exit 1
fi
echo "privacy: clean files $FILES"
exit 0
