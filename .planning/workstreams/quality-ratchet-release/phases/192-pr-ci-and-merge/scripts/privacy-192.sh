#!/bin/sh
# Phase 192 plain privacy check for public PR text and phase evidence (T-192-05).
# usage: privacy-192.sh FILE...
# exit 0 = clean, 1 = hits, 2 = no input or an unreadable input or a tool error (never a clean pass).
# Output: fixed `privacy:` labels only. A matched value, a path or a file name is never printed;
# K in `privacy: hit CLASS file K` is the 1-based argument index.
# Self-test hooks (SELFTEST_192=1 only): T192_ACCOUNT, T192_PRIVATE_STRINGS (a file under the fixture prefix).
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || { echo "privacy: locate failed"; exit 2; }

# hooks are refused outside the self-test, before anything else runs
if { [ -n "${T192_ACCOUNT:-}" ] || [ -n "${T192_PRIVATE_STRINGS:-}" ]; } && [ "${SELFTEST_192:-}" != "1" ]; then
  echo "privacy: hook set outside self-test"; exit 2
fi
if [ -n "${T192_PRIVATE_STRINGS:-}" ]; then
  case "$T192_PRIVATE_STRINGS" in
    /private/tmp/crosswake-selftest-*) : ;;
    *) echo "privacy: hook outside fixture"; exit 2 ;;
  esac
fi

[ "$#" -ge 1 ] || { echo "privacy: no input"; exit 2; }

. "$HERE/common-192.sh"

SC=$(mktemp -d /private/tmp/crosswake-privacy-192.XXXXXX) || { echo "privacy: scratch failed"; exit 2; }
cleanup() { case "$SC" in /private/tmp/crosswake-privacy-192.*) rm -rf "$SC" ;; esac; }
trap cleanup EXIT
trap 'exit 2' INT TERM HUP

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

ACCOUNT=${T192_ACCOUNT:-$(id -un)}
[ -n "$ACCOUNT" ] || { echo "privacy: account unknown"; exit 2; }
printf '%s\n' "$ACCOUNT" > "$SC/account.txt"

# fixed private strings: PARENT, IC, BR, D, HOME (empty values are dropped; an empty list is an error)
if [ -n "${T192_PRIVATE_STRINGS:-}" ]; then
  [ -f "$T192_PRIVATE_STRINGS" ] && [ -r "$T192_PRIVATE_STRINGS" ] || { echo "privacy: unreadable"; exit 2; }
  awk 'NF' "$T192_PRIVATE_STRINGS" > "$SC/private.txt" || { echo "privacy: scratch failed"; exit 2; }
else
  printf '%s\n%s\n%s\n%s\n%s\n' "${PARENT:-}" "${IC:-}" "${BR:-}" "${D:-}" "${HOME:-}" | awk 'NF' > "$SC/private.txt" \
    || { echo "privacy: scratch failed"; exit 2; }
fi
[ -s "$SC/private.txt" ] || { echo "privacy: private strings empty"; exit 2; }

HITS=0
FILES=0
K=0

# probe CLASS FLAGS KIND(e|f) ARG FILE: records one hit line per class per file
probe() {
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
  FILES=$((FILES + 1))
  probe home_path "-i -E" e "$P_HOME" "$f"
  probe user_temp "-i -E" e "$P_TEMP" "$f"
  probe gh_token "-i -E" e "$P_GH" "$f"
  probe pem "-i -E" e "$P_PEM" "$f"
  probe cred_assign "-i -E" e "$P_CRED" "$f"
  probe account "-i -w -F" f "$SC/account.txt" "$f"
  probe private_string "-F" f "$SC/private.txt" "$f"
  # email: only addresses outside the allow list count
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
