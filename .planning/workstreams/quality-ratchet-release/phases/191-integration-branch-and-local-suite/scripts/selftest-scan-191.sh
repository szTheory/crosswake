#!/bin/bash
# Phase 191 self-test for scan-191.sh, terms-191.sh (D-18, D-19, D-20, A-13). Throwaway fixtures only.
# Prints one fixed label per control, never a path or a planted value.
# usage: selftest-scan-191.sh [--tracer]
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
SCAN="$HERE/scan-191.sh"
TERMS="$HERE/terms-191.sh"
. "$HERE/git-pinned-191.sh"
PREFIX=/private/tmp/crosswake-selftest-scan-191
MODE_ARG=${1:-}
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
CANARY="zqx""canaryterm"
ACCT_CANARY="canary""acct"
ACCT_NONE="no-such-""account-191"
HOMEP="/Us""ers/fixtureuser/work"
TEMPP="/va""r/fol""ders/zz/abcd1234efgh5678/T/x"
TOKEN="gh""p_R7kQ2mZ9xT4vB1nL8cW3yH6dF0sJ5aPeXuGi"
TOKEN_LOW="gh""o_abcdefghijklmnopqrstuvwxyz0123456789"
UDIDV="A1B2C3D4-00112233445566AA"
CREDV="HEX_API_""KEY=q9w8e7r6""t5y4u3i2o1p0"
PEMV="-----BEGIN RSA PRIV""ATE KEY-----"
BADMAIL="intruder@corp-""mail.org"
ID_N="Fixture Author"
ID_E="fixture@example.com"

mk_tree() {
  S=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest: fixture failed"; exit 1; }
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest: guard failed"; exit 1 ;; esac
  mkdir "$S/bin"
  printf 'fingerprint\tclass\treason\n' > "$S/triage.tsv"
  R="$S/r"; mkdir "$R"
  g "$R" init -q -b main > /dev/null 2>&1
  printf 'base text\n' > "$R/base.txt"
  gc "base"
  BASE=$(g "$R" rev-parse HEAD)
}
gc() { # MESSAGE
  g "$R" add -A > /dev/null 2>&1
  g "$R" -c "user.name=$ID_N" -c "user.email=$ID_E" commit -q --allow-empty -m "$1" > /dev/null 2>&1
}
gc_as() { # NAME EMAIL MESSAGE
  g "$R" add -A > /dev/null 2>&1
  g "$R" -c "user.name=$1" -c "user.email=$2" commit -q --allow-empty -m "$3" > /dev/null 2>&1
}
head_sha() { g "$R" rev-parse HEAD; }

TERMS_ENV="$CANARY"
ACCT="$ACCT_NONE"
# run_scan [PRESERVED]: status in RC, output in $S/out.txt
run_scan() {
  env CROSSWAKE_PRIVATE_ADOPTER_TERMS="$TERMS_ENV" SCAN191_ACCOUNT="$ACCT" SCAN191_TRIAGE="$S/triage.tsv" \
    bash "$SCAN" "$R" "$BASE" "$(head_sha)" ${1:+"$1"} > "$S/out.txt" 2>&1
  RC=$?
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }
has() { grep -q -- "$1" "$S/out.txt"; }

run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  TERMS_ENV="$CANARY"; ACCT="$ACCT_NONE"
  mk_tree
  if "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
  rm_tree
}

nz() { grep -Eq "^scan: $1 [1-9][0-9]*\$" "$S/out.txt"; }

ctl_s01() {
  printf 'ordinary one\n' > "$R/a.txt"; gc "one"
  printf 'ordinary two\n' > "$R/b.txt"; printf 'a\000b\000c\n' > "$R/bin.dat"; gc "two"
  run_scan
  expect 0 "scan: result clean" || return 1
  grep -qx "scan: commits 2" "$S/out.txt" || return 1
  for n in added_lines added_bytes text_blobs binary_blobs paths identities terms; do nz "$n" || return 1; done
  grep -qx "scan: gitleaks_version 8.30.1" "$S/out.txt"
}
ctl_s02() {
  printf 'x %s y\n' "$HOMEP" > "$R/work.txt"; gc "add"
  git_rm_commit work.txt "remove"
  run_scan
  expect 1 "scan: blocking_final 1" && has '^scan: hit home_path added_line [0-9a-f]\{64\}$'
}
git_rm_commit() { rm -f "$R/$1"; printf 'filler %s\n' "$2" > "$R/filler.txt"; gc "$2"; }
ctl_s03() {
  printf 'value %s\n' "$TOKEN" > "$R/t.txt"; gc "tok"
  run_scan
  expect 1 "scan: gitleaks_findings 1"
}
ctl_s04() {
  printf 'one\n' > "$R/a.txt"; gc "one"
  BASE=$(head_sha)
  run_scan
  expect 2 "scan: empty range"
}
ctl_s05() {
  printf 'text line\n' > "$R/a.txt"
  printf 'x\000%s\000y\n' "$CANARY" > "$R/bin.dat"; gc "bin"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit adopter_term blob [0-9a-f]\{64\}$'
}
ctl_s06() {
  printf 'text\n' > "$R/a.txt"; gc "see $TEMPP here"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit user_temp message [0-9a-f]\{64\}$'
}
ctl_s07() {
  printf 'text\n' > "$R/a.txt"; gc_as "$ID_N" "$BADMAIL" "mail"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit email identity [0-9a-f]\{64\}$'
}
ctl_s08() {
  printf 'text\n' > "$R/$UDIDV.txt"; gc "named"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit udid path [0-9a-f]\{64\}$'
}
ctl_s09() {
  printf 'export %s\n' "$CREDV" > "$R/env.sh"; gc "cred"
  run_scan
  [ "$RC" -eq 1 ] && has '^scan: hit credential added_line [0-9a-f]\{64\}$'
}
ctl_s10() {
  printf 'mentions ZqX%s here\n' "CaNaRyTeRm" > "$R/a.txt"; gc "mixed"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit adopter_term added_line [0-9a-f]\{64\}$'
}
ctl_s11() {
  printf '%s\n' "$PEMV" > "$R/k.txt"; gc "pem"
  run_scan
  [ "$RC" -eq 1 ] && has '^scan: hit pem_key added_line [0-9a-f]\{64\}$'
}
ctl_s12() {
  printf 'text\n' > "$R/a.txt"; gc_as "Intruder Person" "$ID_E" "name"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit author_name identity [0-9a-f]\{64\}$'
}
ctl_s13() {
  ACCT="$ACCT_CANARY"
  printf 'owner is %s today\n' "$ACCT_CANARY" > "$R/a.txt"; gc "who"
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit user_name added_line [0-9a-f]\{64\}$'
}
ctl_s14() {
  printf 'text\n' > "$R/a.txt"; gc "tagged"
  g "$R" -c "user.name=$ID_N" -c "user.email=$ID_E" tag -a v0.0.1 -m "see $HOMEP" > /dev/null 2>&1
  run_scan
  expect 1 "scan: result hits" && has '^scan: hit home_path tag [0-9a-f]\{64\}$'
}
ctl_s15() {
  TERMS_ENV=""
  printf 'text\n' > "$R/a.txt"; gc "x"
  run_scan
  expect 2 "scan: empty terms"
}
ctl_s16() {
  printf 'x %s y\n' "$HOMEP" > "$R/work.txt"; gc "personal"
  PRES=$(head_sha)
  git_rm_commit work.txt "clean up"
  run_scan "$PRES"
  expect 0 "scan: history_personal 1" && grep -qx "scan: history_personal_class home_path 1" "$S/out.txt" \
    && grep -qx "scan: blocking_final 0" "$S/out.txt" && grep -qx "scan: result clean" "$S/out.txt"
}
ctl_s25() {
  ACCT="$ACCT_CANARY"
  printf 'owner %s here\n' "$ACCT_CANARY" > "$R/who.txt"; gc "personal"
  PRES=$(head_sha)
  git_rm_commit who.txt "clean up"
  run_scan "$PRES"
  expect 0 "scan: history_personal_class user_name 1" && grep -qx "scan: history_personal_class home_path 0" "$S/out.txt" \
    && grep -qx "scan: history_personal_class user_temp 0" "$S/out.txt" && grep -qx "scan: blocking_final 0" "$S/out.txt" \
    && grep -qx "scan: history_personal 1" "$S/out.txt"
}
ctl_s17() {
  printf 'about %s\n' "$CANARY" > "$R/who.txt"; gc "sensitive"
  PRES=$(head_sha)
  git_rm_commit who.txt "clean up"
  run_scan "$PRES"
  expect 1 "scan: history_sensitive 1" && grep -qx "scan: rung adopter_term" "$S/out.txt"
}
ctl_s18() {
  printf 'key %s end\n' "$TOKEN_LOW" > "$R/t.txt"; gc "fixture"
  run_scan
  [ "$RC" -eq 1 ] || return 1
  grep -qx "scan: gitleaks_findings 0" "$S/out.txt" || return 1
  fp=$(sed -n 's/^scan: hit gh_token added_line \([0-9a-f]\{64\}\)$/\1/p' "$S/out.txt")
  [ -n "$fp" ] || return 1
  printf '%s\tgh_token\tfabricated fixture value\n' "$fp" >> "$S/triage.tsv"
  run_scan
  expect 0 "scan: triaged 1"
}
ctl_s19() {
  printf 'a noreply@anywhere.io b git@github.com c a@example.com d x@users.noreply.github.com\n' > "$R/a.txt"; gc "mails"
  run_scan
  expect 0 "scan: result clean"
}
ctl_s20() {
  printf 'id 123e4567-e89b-12d3-a456-426614174000 sha da39a3ee5e6b4b0d3255bfef95601890afd80709 the secret word\n' > "$R/a.txt"; gc "benign"
  run_scan
  expect 0 "scan: result clean" || return 1
  grep -Eq '^scan: triage_only uuid [1-9]' "$S/out.txt" && grep -Eq '^scan: triage_only bare_word [1-9]' "$S/out.txt" \
    && grep -Eq '^scan: triage_only bare_hex40 [1-9]' "$S/out.txt"
}
ctl_s21() {
  ACCT="$ACCT_CANARY"
  printf 'p %s\nt %s\nc %s\nw %s\nu %s\n' "$HOMEP" "$TEMPP" "$CANARY" "$ACCT_CANARY" "$TOKEN" > "$R/a.txt"
  printf 'text\n' > "$R/$UDIDV.txt"; printf 'e %s\n' "$BADMAIL" > "$R/m.txt"
  gc_as "$ID_N" "$BADMAIL" "msg $HOMEP"
  run_scan
  [ "$RC" -eq 1 ] || return 1
  for v in "$HOMEP" "fixtureuser" "$TEMPP" "abcd1234" "$CANARY" "$ACCT_CANARY" "$TOKEN" "R7kQ2mZ9" "$UDIDV" "A1B2C3D4" "$BADMAIL" "corp-" "Users" "folders"; do
    if grep -qiF -- "$v" "$S/out.txt"; then return 1; fi
  done
  return 0
}
ctl_s22() {
  printf 'text\n' > "$R/a.txt"; gc "x"
  printf '%s\tgh_token\t\n' "0000000000000000000000000000000000000000000000000000000000000000" >> "$S/triage.tsv"
  run_scan
  expect 2 "scan: triage row without reason"
}
terms_try() { # DENYPATH [TMPPREFIX]
  env DENY="$1" REC="$S/rec" IC="$S/ic" D="$S/dd" TERMS191_TMP="${2:-/private/tmp}" sh -c ". \"$TERMS\"; echo \"ret=\$?\"" > "$S/tout.txt" 2>&1
}
ctl_s23() {
  mkdir -p "$S/ok"
  printf 'termone\n' > "$S/ok/open.txt"; chmod 644 "$S/ok/open.txt"
  terms_try "$S/ok/open.txt" "$S/never"
  grep -qx "terms: denylist unsafe" "$S/tout.txt" && grep -qx "ret=2" "$S/tout.txt" || return 1
  printf 'termone\n' > "$S/ok/real.txt"; chmod 600 "$S/ok/real.txt"; ln -s "$S/ok/real.txt" "$S/ok/link.txt"
  terms_try "$S/ok/link.txt" "$S/never"
  grep -qx "terms: denylist unsafe" "$S/tout.txt" && grep -qx "ret=2" "$S/tout.txt" || return 1
  terms_try "$S/ok/real.txt"
  grep -qx "terms: denylist inside repo or tmp" "$S/tout.txt" && grep -qx "ret=2" "$S/tout.txt"
}
ctl_s24() {
  printf '#!/bin/sh\necho 9.9.9\n' > "$S/bin/gitleaks"; chmod 700 "$S/bin/gitleaks"
  printf 'text\n' > "$R/a.txt"; gc "x"
  env PATH="$S/bin:$PATH" CROSSWAKE_PRIVATE_ADOPTER_TERMS="$CANARY" SCAN191_ACCOUNT="$ACCT" SCAN191_TRIAGE="$S/triage.tsv" \
    bash "$SCAN" "$R" "$BASE" "$(head_sha)" > "$S/out.txt" 2>&1
  RC=$?
  expect 2 "scan: gitleaks version"
}
ctl_s26() {
  printf 'a /private/tmp/crosswake-x b /tmp/crosswake-x c %s\n' "/va""r/fol""ders/<bucket>/T/" > "$R/a.txt"; gc "paths"
  run_scan
  expect 0 "scan: result clean" && ! has '^scan: hit user_temp'
}
ctl_s27() {
  mkdir -p "$S/ok"
  printf 'termone\n  Term Two  \n\n' > "$S/ok/real.txt"; chmod 600 "$S/ok/real.txt"
  terms_try "$S/ok/real.txt" "$S/never"
  grep -qx "terms: loaded 2" "$S/tout.txt" && grep -qx "ret=0" "$S/tout.txt"
}
ctl_s28() {
  mkdir -p "$S/ok"
  printf 'one,two\n' > "$S/ok/real.txt"; chmod 600 "$S/ok/real.txt"
  terms_try "$S/ok/real.txt" "$S/never"
  grep -qx "terms: comma in term" "$S/tout.txt" || return 1
  printf '\n  \n' > "$S/ok/empty.txt"; chmod 600 "$S/ok/empty.txt"
  terms_try "$S/ok/empty.txt" "$S/never"
  grep -qx "terms: none" "$S/tout.txt" || return 1
  terms_try "$S/ok/absent.txt" "$S/never"
  grep -qx "terms: denylist missing" "$S/tout.txt"
}
ctl_s29() {
  env CROSSWAKE_PRIVATE_ADOPTER_TERMS="alpha one, Beta" bash "$SCAN" --term-check > "$S/out.txt" 2>&1
  RC=$?
  expect 0 "term-check: terms 2 matched 2"
}
ctl_s30() {
  printf 'text\n' > "$R/a.txt"; gc "x"
  env CROSSWAKE_PRIVATE_ADOPTER_TERMS="$CANARY" SCAN191_ACCOUNT="$ACCT" SCAN191_TRIAGE="$S/triage.tsv" \
    bash "$SCAN" "$R" "not-a-revision" "$(head_sha)" > "$S/out.txt" 2>&1
  RC=$?
  expect 2 "scan: bad range"
}
ctl_s31() { # a rung-2 class only in history stops; a blocking class in HEAD is final even when the commit is preserved
  printf 'x %s y\n' "$HOMEP" > "$R/keep.txt"; gc "personal kept"
  PRES=$(head_sha)
  run_scan "$PRES"
  expect 1 "scan: blocking_final 1" && grep -qx "scan: history_personal 0" "$S/out.txt"
}

ctl_s32() { # a gitleaks triage row suppresses exactly its own finding and nothing else
  printf 'value %s\n' "$TOKEN" > "$R/t.txt"; gc "tok"
  run_scan
  expect 1 "scan: gitleaks_findings 1" || return 1
  H=$(head_sha)
  env -u GIT_DIR GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 gitleaks git --no-banner --redact "--log-opts=$BASE..$H" --report-format json --report-path "$S/gl.json" "$R" > /dev/null 2>&1
  FPG=$(sed -n 's/^ *"Fingerprint": *"\(.*\)",\{0,1\}$/\1/p' "$S/gl.json" | sed -n '1p')
  [ -n "$FPG" ] || return 1
  printf 'x:%s\tgitleaks\twrong line: must not suppress\n' "$FPG" >> "$S/triage.tsv"
  run_scan
  expect 1 "scan: gitleaks_findings 1" || return 1
  printf '%s\tgitleaks\tfabricated fixture token\n' "$FPG" >> "$S/triage.tsv"
  run_scan
  expect 1 "scan: gitleaks_findings 0"
}

ctl_s33() { # a git note whose blob cannot be read is a scope error, never a skipped note
  printf 'text\n' > "$R/a.txt"; gc "note target"
  g "$R" -c "user.name=$ID_N" -c "user.email=$ID_E" notes add -m body HEAD > /dev/null 2>&1 || return 1
  NB=$(g "$R" notes list HEAD | awk '{print $1}')
  [ -n "$NB" ] || return 1
  NF="$R/.git/objects/$(printf '%s' "$NB" | cut -c1-2)/$(printf '%s' "$NB" | cut -c3-)"
  [ -f "$NF" ] || return 1
  rm -f "$NF"
  run_scan
  expect 2 "scan: cat-file failed"
}

run_ctl S01 ctl_s01 "clean repo with non-zero counts"
run_ctl S02 ctl_s02 "home path added then deleted"
run_ctl S03 ctl_s03 "gitleaks token shape"
run_ctl S04 ctl_s04 "empty range is a scope error"
if [ "$MODE_ARG" = "--tracer" ]; then
  if [ "$GOOD" -eq 4 ]; then
    echo "selftest-scan: tracer controls 4 of 4 as expected"; exit 0
  fi
  echo "selftest-scan: tracer controls $GOOD of 4 as expected"; exit 1
fi
run_ctl S05 ctl_s05 "adopter term in a binary blob"
run_ctl S06 ctl_s06 "per-user temp path in a commit message"
run_ctl S07 ctl_s07 "non-allowed author email"
run_ctl S08 ctl_s08 "device id in a file name"
run_ctl S09 ctl_s09 "upper-case credential assignment"
run_ctl S10 ctl_s10 "mixed-case adopter term"
run_ctl S11 ctl_s11 "private key line"
run_ctl S12 ctl_s12 "author name absent from main"
run_ctl S13 ctl_s13 "account name as a word"
run_ctl S14 ctl_s14 "home path in a tag message"
run_ctl S15 ctl_s15 "zero terms is a scope error"
run_ctl S16 ctl_s16 "home path only in preserved history accepted"
run_ctl S17 ctl_s17 "adopter term only in preserved history stops"
run_ctl S18 ctl_s18 "triaged fingerprint subtracted"
run_ctl S19 ctl_s19 "allow-listed emails stay clean"
run_ctl S20 ctl_s20 "triage-only classes do not block"
run_ctl S21 ctl_s21 "no planted value in any output"
run_ctl S22 ctl_s22 "triage row without reason"
run_ctl S23 ctl_s23 "unsafe denylist refused three ways"
run_ctl S24 ctl_s24 "gitleaks version mismatch"
run_ctl S25 ctl_s25 "account name only in preserved history on its own class line"
run_ctl S26 ctl_s26 "fixed shared temp folders are not user_temp"
run_ctl S27 ctl_s27 "valid denylist loads trimmed terms"
run_ctl S28 ctl_s28 "comma, empty and missing denylist refused"
run_ctl S29 ctl_s29 "term-check mode matches every term"
run_ctl S30 ctl_s30 "unresolvable base revision"
run_ctl S31 ctl_s31 "personal value present in HEAD is final"
run_ctl S32 ctl_s32 "gitleaks triage row suppresses only its own finding"
run_ctl S33 ctl_s33 "unreadable git note is a scope error"
echo "selftest-scan: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 26 ] && exit 0
exit 1
