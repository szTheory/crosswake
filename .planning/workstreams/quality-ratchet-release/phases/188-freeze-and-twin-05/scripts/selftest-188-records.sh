#!/bin/sh
# One-time evidence tooling (phase 188-02). Throwaway repos only; never touches the real candidate or records.
set -u
RUNS=/private/tmp/crosswake-phase180-run
W=$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release
REAL180=$W/phases/180-bounded-digital-twin-demonstration/180-SEAM-HANDOFF.json
REAL182=$W/phases/182-loopback-origin-for-local-ios-host/182-FINAL-HEAD.json
MODE=full; EXPECT=18
if [ "${1:-}" = "--only" ]; then
  if [ "${2:-}" = "R01-R09" ]; then MODE=sub; EXPECT=9; else echo "selftest-records: unknown subset"; exit 2; fi
fi
TOP=$(mktemp -d /private/tmp/crosswake-selftest-188-02.XXXXXX) || exit 2
trap 'rm -rf "$TOP"' EXIT
trap 'exit 130' INT TERM
mkdir -p "$TOP/bin"
printf '#!/bin/sh\necho "probe: all zero"\n' > "$TOP/bin/mix"
chmod 0755 "$TOP/bin/mix"
PATH="$TOP/bin:$PATH"; export PATH

PASS=0
ctl() { # id name status
  if [ "$3" -eq 0 ]; then echo "$1 $2: as expected"; PASS=$((PASS + 1)); else echo "$1 $2: NOT as expected"; fi
}
gt() { d=$1; shift; env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE git -C "$d" -c user.name=t -c user.email=nobody.invalid -c commit.gpgsign=false -c core.hooksPath=/dev/null "$@"; }
MANIFEST=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json
ACTIVATION=examples/phoenix_host/native/ios/crosswake_shell/Fixtures/route_activation.json
MEDIA=examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff
N=0
mkcand() { # prints new root
  N=$((N + 1)); x="$TOP/c$N"; MK=$x
  mkdir -p "$x/cand" "$x/pd" "$x/p180" "$x/p182" "$x/runs"
  gt "$x/cand" init -q
  for f in "$MANIFEST" "$ACTIVATION" "$MEDIA"; do mkdir -p "$x/cand/$(dirname "$f")"; done
  printf '{"m":1}\n' > "$x/cand/$MANIFEST"
  printf '{"a":1}\n' > "$x/cand/$ACTIVATION"
  printf 'AIFF\000\001\002\003 sample bytes\n' > "$x/cand/$MEDIA"
  printf 'base\n' > "$x/cand/base.txt"
  gt "$x/cand" add -A
  gt "$x/cand" commit -q -m base
  gt "$x/cand" remote add origin some-remote-url
  gt "$x/cand" remote set-url --push origin no-push-phase180
  return 0
}
head_of() { gt "$1/cand" rev-parse HEAD; }
fz() { T188_SELFTEST_ROOT="$1" sh "$RUNS/freeze-check-188.sh" "$2"; }
FAILMSG=0

# ---------- R01 ----------
mkcand; x=$MK; h=$(head_of "$x")
out=$(fz "$x" "$h" 2>&1); rc=$?
s=1
if [ $rc -eq 0 ] && jq -e --arg h "$h" '.schema=="crosswake.phase188.freeze/1" and (keys_unsorted[0]=="summary") and (keys_unsorted[1]=="status") and (.summary|startswith("One frozen candidate commit means the cumulative tree")) and (.summary|split(". ")|length)==1 and .status=="all 7 freeze checks passed" and .freeze_head==$h and (.checks|map(.label))==["head_equals_argument","porcelain_empty","info_exclude_empty","elixir_probe_all_zero","push_url_no_push","no_gitlinks","no_gitmodules"] and (.checks|all(.status=="pass")) and (.accepted_exception|startswith("Two git-ignored classes inside the candidate are the accepted exception to D-03")) and (.accepted_exception|contains("_build")) and (.accepted_exception|contains("crosswake_example.db")) and (.recorded_at|length)>0' "$x/pd/188-FREEZE.json" >/dev/null 2>&1; then s=0; fi
ctl R01 freeze_ok $s

# ---------- R02 wrong head ----------
mkcand; x=$MK
out=$(fz "$x" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 2>&1); rc=$?
s=1; if [ $rc -eq 1 ] && [ ! -e "$x/pd/188-FREEZE.json" ] && printf '%s\n' "$out" | grep -q '^head_equals_argument fail$'; then s=0; fi
ctl R02 freeze_wrong_head $s

# ---------- R03 dirty ----------
mkcand; x=$MK; h=$(head_of "$x"); printf 'x\n' > "$x/cand/stray.txt"
out=$(fz "$x" "$h" 2>&1); rc=$?
s=1; if [ $rc -eq 1 ] && [ ! -e "$x/pd/188-FREEZE.json" ] && printf '%s\n' "$out" | grep -q '^porcelain_empty fail$'; then s=0; fi
ctl R03 freeze_dirty_tree $s

# ---------- R04 push url ----------
mkcand; x=$MK; h=$(head_of "$x"); gt "$x/cand" remote set-url --push origin some-other-url
out=$(fz "$x" "$h" 2>&1); rc=$?
s=1; if [ $rc -eq 1 ] && [ ! -e "$x/pd/188-FREEZE.json" ] && printf '%s\n' "$out" | grep -q '^push_url_no_push fail$'; then s=0; fi
ctl R04 freeze_push_url_changed $s

# ---------- R05 gitlink ----------
mkcand; x=$MK
gt "$x/cand" update-index --add --cacheinfo 160000,1111111111111111111111111111111111111111,vendored >/dev/null 2>&1
gt "$x/cand" commit -q -m gitlink; h=$(head_of "$x")
out=$(fz "$x" "$h" 2>&1); rc=$?
s=1; if [ $rc -eq 1 ] && [ ! -e "$x/pd/188-FREEZE.json" ] && printf '%s\n' "$out" | grep -q '^no_gitlinks fail$'; then s=0; fi
ctl R05 freeze_gitlink $s

# ---------- R06 existing record ----------
mkcand; x=$MK; h=$(head_of "$x"); printf 'keep\n' > "$x/pd/188-FREEZE.json"; cp "$x/pd/188-FREEZE.json" "$x/keep.copy"
out=$(fz "$x" "$h" 2>&1); rc=$?
s=1; if [ $rc -eq 5 ] && cmp -s "$x/pd/188-FREEZE.json" "$x/keep.copy"; then s=0; fi
ctl R06 freeze_record_exists $s

# ---------- R07 identity ----------
mkcand; x=$MK
out=$(T188_SELFTEST_ROOT="$x" sh "$RUNS/make-identity-188.sh" 2>&1); rc=$?
c="$x/cand"; s=1
dm=$(gt "$c" show "HEAD:$MANIFEST" | shasum -a 256 | cut -d' ' -f1)
da=$(gt "$c" show "HEAD:$ACTIVATION" | shasum -a 256 | cut -d' ' -f1)
df=$(gt "$c" show "HEAD:$MEDIA" | shasum -a 256 | cut -d' ' -f1)
sz=$(wc -c < "$c/$MEDIA" | tr -d ' ')
h=$(head_of "$x"); t=$(gt "$c" rev-parse 'HEAD^{tree}')
if [ $rc -eq 0 ] && jq -e --arg h "$h" --arg t "$t" --arg dm "$dm" --arg da "$da" --arg df "$df" --argjson sz "$sz" '.schema=="crosswake.phase180.identity/1" and .supersedes=="183-IDENTITY.json" and .candidate_head==$h and .candidate_tree==$t and (.media.size|type)=="number" and .media.size==$sz and .media.sha256==$df and .generated.manifest_sha256==$dm and .generated.activation_sha256==$da' "$x/pd/188-IDENTITY.json" >/dev/null 2>&1; then s=0; fi
ctl R07 identity_ok $s

# ---------- R08 identity exists ----------
mkcand; x=$MK; printf 'keep\n' > "$x/pd/188-IDENTITY.json"; cp "$x/pd/188-IDENTITY.json" "$x/keep.copy"
out=$(T188_SELFTEST_ROOT="$x" sh "$RUNS/make-identity-188.sh" 2>&1); rc=$?
s=1; if [ $rc -eq 5 ] && cmp -s "$x/pd/188-IDENTITY.json" "$x/keep.copy"; then s=0; fi
ctl R08 identity_record_exists $s

# ---------- R09 identity dirty ----------
mkcand; x=$MK; printf 'x\n' > "$x/cand/stray.txt"
out=$(T188_SELFTEST_ROOT="$x" sh "$RUNS/make-identity-188.sh" 2>&1); rc=$?
s=1; if [ $rc -eq 3 ] && [ ! -e "$x/pd/188-IDENTITY.json" ]; then s=0; fi
ctl R09 identity_dirty_tree $s

if [ "$MODE" = full ]; then
# ---------- refresh fixtures ----------
rf() { T188_SELFTEST_ROOT="$1" sh "$RUNS/refresh-handoffs-188.sh" ${2:+"$2"}; }
mkref() { # sets X B0 H1 H2 T2 ; originals saved
  mkcand; X=$MK; c="$X/cand"
  B0=$(head_of "$X"); BR=$(gt "$c" rev-parse --abbrev-ref HEAD)
  printf 'one\n' > "$c/f1.txt"; gt "$c" add f1.txt; gt "$c" commit -q -m one
  H1=$(head_of "$X"); T1=$(gt "$c" rev-parse 'HEAD^{tree}')
  jq --arg h "$H1" --arg t "$T1" --arg b "$B0" '.repaired_head=$h|.repaired_tree=$t|.base_head=$b' "$REAL180" > "$X/p180/180-SEAM-HANDOFF.json"
  jq --arg h "$H1" --arg t "$T1" --arg b "$B0" '.base_head=$b|.head=$h|.tree=$t|.core_diff_paths=["f1.txt"]' "$REAL182" > "$X/p182/182-FINAL-HEAD.json"
  printf 'two\n' > "$c/f2.txt"; gt "$c" add f2.txt; gt "$c" commit -q -m two
  H2=$(head_of "$X"); T2=$(gt "$c" rev-parse 'HEAD^{tree}')
  cp "$X/p180/180-SEAM-HANDOFF.json" "$X/o180"; cp "$X/p182/182-FINAL-HEAD.json" "$X/o182"
}
unchanged() { cmp -s "$X/p180/180-SEAM-HANDOFF.json" "$X/o180" && cmp -s "$X/p182/182-FINAL-HEAD.json" "$X/o182" && [ ! -e "$X/p180/180-SEAM-HANDOFF.pre-188.json" ] && [ ! -e "$X/p182/182-FINAL-HEAD.pre-188.json" ]; }

# R10
mkref
out=$(rf "$X" "$H2" 2>&1); rc=$?
exp=$(gt "$X/cand" diff --name-only "$B0" "$H2" | jq -R -s -c 'split("\n")|map(select(length>0))')
s=1
if [ $rc -eq 0 ] \
 && cmp -s "$X/o180" "$X/p180/180-SEAM-HANDOFF.pre-188.json" && cmp -s "$X/o182" "$X/p182/182-FINAL-HEAD.pre-188.json" \
 && jq -e --arg h "$H2" --arg t "$T2" --arg oh "$H1" '.repaired_head==$h and .repaired_tree==$t and .supersedes.repaired_head==$oh and (.refreshed.by=="refresh-handoffs-188.sh")' "$X/p180/180-SEAM-HANDOFF.json" >/dev/null \
 && jq -e --arg h "$H2" --arg t "$T2" --arg oh "$H1" --argjson exp "$exp" '.head==$h and .tree==$t and .core_diff_paths==$exp and (.core_diff_paths|length)==2 and (.core_diff_paths_meaning|length)>0 and .checks_status=="not_rerun_at_freeze_head" and .simulator_status=="not_rerun_at_freeze_head" and .supersedes.head==$oh and .supersedes.core_diff_paths==["f1.txt"]' "$X/p182/182-FINAL-HEAD.json" >/dev/null \
 && [ "$(jq -c .checks "$X/p182/182-FINAL-HEAD.json")" = "$(jq -c .checks "$X/o182")" ]; then s=0; fi
ctl R10 refresh_ok $s
cp "$X/p180/180-SEAM-HANDOFF.json" "$X/n180"; cp "$X/p182/182-FINAL-HEAD.json" "$X/n182"; X10=$X; H210=$H2

# R11 missing arg
mkref; out=$(rf "$X" 2>&1); rc=$?
s=1; if [ $rc -eq 2 ] && printf '%s\n' "$out" | grep -q '^refused: usage$' && unchanged; then s=0; fi
ctl R11 refresh_missing_arg $s
# R12 non-hex
mkref; out=$(rf "$X" "not-a-sha" 2>&1); rc=$?
s=1; if [ $rc -eq 2 ] && unchanged; then s=0; fi
ctl R12 refresh_non_hex_arg $s
# R13 arg is not HEAD
mkref; out=$(rf "$X" "$H1" 2>&1); rc=$?
s=1; if [ $rc -eq 4 ] && unchanged; then s=0; fi
ctl R13 refresh_arg_not_head $s
# R14 dirty
mkref; printf 'x\n' > "$X/cand/stray.txt"; out=$(rf "$X" "$H2" 2>&1); rc=$?
s=1; if [ $rc -eq 3 ] && unchanged; then s=0; fi
ctl R14 refresh_dirty_tree $s
# R15 non-ancestor old head
mkref
gt "$X/cand" checkout -q -b side "$B0"; printf 's\n' > "$X/cand/s.txt"; gt "$X/cand" add s.txt; gt "$X/cand" commit -q -m side
S=$(head_of "$X"); gt "$X/cand" checkout -q "$BR"
jq --arg s "$S" '.repaired_head=$s' "$X/p180/180-SEAM-HANDOFF.json" > "$X/t" && mv "$X/t" "$X/p180/180-SEAM-HANDOFF.json"; cp "$X/p180/180-SEAM-HANDOFF.json" "$X/o180"
out=$(rf "$X" "$H2" 2>&1); rc=$?
s=1; if [ $rc -eq 5 ] && unchanged; then s=0; fi
ctl R15 refresh_not_ancestor $s
# R16 pre-existing copy
mkref; printf 'keep\n' > "$X/p182/182-FINAL-HEAD.pre-188.json"; cp "$X/p182/182-FINAL-HEAD.pre-188.json" "$X/kp"
out=$(rf "$X" "$H2" 2>&1); rc=$?
s=1; if [ $rc -eq 6 ] && cmp -s "$X/p180/180-SEAM-HANDOFF.json" "$X/o180" && cmp -s "$X/p182/182-FINAL-HEAD.json" "$X/o182" && cmp -s "$X/p182/182-FINAL-HEAD.pre-188.json" "$X/kp" && [ ! -e "$X/p180/180-SEAM-HANDOFF.pre-188.json" ]; then s=0; fi
ctl R16 refresh_pre188_exists $s
# R17 second run
X=$X10; out=$(rf "$X" "$H210" 2>&1); rc=$?
s=1; if [ $rc -eq 6 ] && cmp -s "$X/p180/180-SEAM-HANDOFF.json" "$X/n180" && cmp -s "$X/p182/182-FINAL-HEAD.json" "$X/n182"; then s=0; fi
ctl R17 refresh_second_run_refused $s
# R18 static
s=1; k=$(grep -v '^[[:space:]]*#' "$RUNS/refresh-handoffs-188.sh" | grep -c 'twin-0'); [ "$k" -eq 0 ] && s=0
ctl R18 refresh_names_no_twin_root $s
fi

echo "selftest-records: controls $PASS of $EXPECT as expected"
[ "$PASS" -eq "$EXPECT" ]
