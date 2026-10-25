#!/bin/sh
# Phase 192 self-test for privacy-192.sh (T-192-05). Throwaway fixtures only.
# Prints one fixed label per control, never a path or a planted value.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
PRIV="$HERE/privacy-192.sh"
PREFIX=/private/tmp/crosswake-selftest-privacy-192
S=
RC=
TOTAL=0
GOOD=0

rm_tree() {
  case "$S" in
    "$PREFIX".*) rm -rf "$S" ;;
  esac
  S=
}
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP

# planted values, every one assembled from fragments
HOMEP="/Us""ers/fixtureuser/work"
TEMPP="/va""r/fol""ders/zz/abcd1234efgh5678/T/x"
TOKEN="gh""p_R7kQ2mZ9xT4vB1nL8cW3yH6dF0sJ5aPeXuGi"
CREDV="HEX_API_""KEY=q9w8e7r6""t5y4u3i2o1p0"
PEMV="-----BEGIN RSA PRIV""ATE KEY-----"
BADMAIL="intruder@corp-""mail.org"
OKMAIL="1234+someone@users.nore""ply.github.com"
ACCT_CANARY="canary""acct"
ACCT_NONE="no-such-""account-192"
PRIVSTR="zqx""privatestring192"

mk_tree() {
  S=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest-privacy: fixture failed"; exit 1; }
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest-privacy: guard failed"; exit 1 ;; esac
  printf '%s\n' "$PRIVSTR" > "$S/priv.txt"
  printf 'plain text with nothing private in it\n' > "$S/clean.txt"
}

ACCT=$ACCT_NONE
# run_priv ARGS...: status in RC, output in $S/out.txt
run_priv() {
  env SELFTEST_192=1 T192_ACCOUNT="$ACCT" T192_PRIVATE_STRINGS="$S/priv.txt" \
    sh "$PRIV" "$@" > "$S/out.txt" 2>&1
  RC=$?
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  ACCT=$ACCT_NONE
  mk_tree
  if "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
  rm_tree
}

# one planted line in a file, one hit class expected
hit_ctl() { # CLASS LINE
  printf 'before\n%s\nafter\n' "$2" > "$S/in.txt"
  run_priv "$S/in.txt"
  expect 1 "privacy: hit $1 file 1" && grep -qx "privacy: hits 1" "$S/out.txt"
}

ctl_v01() { run_priv "$S/clean.txt"; expect 0 "privacy: clean files 1"; }
ctl_v02() { hit_ctl home_path "see $HOMEP now"; }
ctl_v03() { hit_ctl user_temp "dir $TEMPP here"; }
ctl_v04() { hit_ctl gh_token "value $TOKEN end"; }
ctl_v05() { hit_ctl pem "$PEMV"; }
ctl_v06() { hit_ctl cred_assign "export $CREDV"; }
ctl_v07() { hit_ctl email "write to $BADMAIL today"; }
ctl_v08() {
  printf 'author %s ok\n' "$OKMAIL" > "$S/in.txt"
  run_priv "$S/in.txt"
  expect 0 "privacy: clean files 1"
}
ctl_v09() {
  ACCT=$ACCT_CANARY
  hit_ctl account "owner is $ACCT_CANARY today"
}
ctl_v10() { hit_ctl private_string "mentions $PRIVSTR here"; }
ctl_v11() { run_priv; expect 2 "privacy: no input"; }
ctl_v12() { run_priv "$S/absent.txt"; expect 2 "privacy: unreadable"; }
ctl_v13() { # no planted value or fixture path in any output, for hits and for an unreadable file
  ACCT=$ACCT_CANARY
  printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n' "$HOMEP" "$TEMPP" "$TOKEN" "$CREDV" "$PEMV" "$BADMAIL" "$ACCT_CANARY" "$PRIVSTR" > "$S/in.txt"
  run_priv "$S/clean.txt" "$S/in.txt"
  [ "$RC" -eq 1 ] || return 1
  grep -qx "privacy: hit home_path file 2" "$S/out.txt" || return 1
  grep -qx "privacy: hit private_string file 2" "$S/out.txt" || return 1
  cp "$S/out.txt" "$S/out1.txt"
  run_priv "$S/clean.txt" "$S/absent.txt"
  [ "$RC" -eq 2 ] || return 1
  cat "$S/out.txt" >> "$S/out1.txt"
  for v in "$HOMEP" "fixtureuser" "$TEMPP" "abcd1234" "$TOKEN" "R7kQ2mZ9" "$CREDV" "q9w8e7r6" "$PEMV" "$BADMAIL" "corp-" "$ACCT_CANARY" "$PRIVSTR" "$PREFIX" "in.txt" "absent"; do
    if grep -qiF -- "$v" "$S/out1.txt"; then return 1; fi
  done
  return 0
}

run_ctl V01 ctl_v01 "clean text file"
run_ctl V02 ctl_v02 "home path"
run_ctl V03 ctl_v03 "per-user temp path"
run_ctl V04 ctl_v04 "token shape"
run_ctl V05 ctl_v05 "private key line"
run_ctl V06 ctl_v06 "upper-case credential assignment"
run_ctl V07 ctl_v07 "foreign email address"
run_ctl V08 ctl_v08 "noreply email stays clean"
run_ctl V09 ctl_v09 "account name as a word"
run_ctl V10 ctl_v10 "fixed private string"
run_ctl V11 ctl_v11 "no argument is no input"
run_ctl V12 ctl_v12 "missing file is unreadable"
run_ctl V13 ctl_v13 "no planted value in any output"
echo "selftest-privacy: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 12 ] && exit 0
exit 1
