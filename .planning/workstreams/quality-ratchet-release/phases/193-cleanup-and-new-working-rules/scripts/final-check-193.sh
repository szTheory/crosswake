#!/bin/bash
# Phase 193 final check (CLEAN-03, D-19, D-24). Modes:
#   --pre-merge PR | --post-merge | --check N [--pre-merge PR | --post-merge] | --self-test
# Five checks; exit 0 only on a full pass. A gh failure, empty output or unparseable JSON is a failure.
# Env: FINAL193_TOP (a clean clone to read; honoured only for --check 2 and --check 3).
# Self-test hooks (SELFTEST_193=1 and values under the fixture prefix only): F193_TOP, F193_TMPROOT,
# F193_DISP, F193_LEDGER, F193_INV189, F193_POSTREC, F193_TMPMAP.
# Output: fixed `final:` labels, counts and placeholders only.
# Exit: 0 pass, 1 a check failed, 2 tool or input error.
set -u
umask 077
export LC_ALL=C
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")" || { echo "final: locate failed"; exit 2; }
HERE=$(dirname "$SELF")
. "$HERE/paths-193.sh" || { echo "final: locate failed"; exit 2; }

CI_NAME="Crosswake CI"
say() { printf '%s\n' "$1"; }
die2() { say "final: $1"; exit 2; }

hook() { # NAME DEFAULT
  local v
  eval "v=\${$1:-}"
  if [ -n "$v" ]; then
    [ "${SELFTEST_193:-}" = 1 ] || { say "final: hook set outside self-test"; exit 2; }
    case $v in "$ST193_PREFIX"*) : ;; *) say "final: hook outside fixture"; exit 2 ;; esac
    printf '%s\n' "$v"
  else
    printf '%s\n' "$2"
  fi
}

TOPC=$TOP
DISP=$(hook F193_DISP "$TOP/$P193/193-PR-DISPOSITIONS.md") || exit 2
LEDGER=$(hook F193_LEDGER "$TOP/$P193/193-REMOVAL-LEDGER.md") || exit 2
INV189_MD=$(hook F193_INV189 "$TOP/$P189/189-INVENTORY.md") || exit 2
POSTREC=$(hook F193_POSTREC "$TOP/$P193/193-POST189-RECORD.md") || exit 2
TMPMAP=$(hook F193_TMPMAP "$TOP/$P189/189-EVIDENCE/tmp-entry-map.tsv") || exit 2
TMPROOT=$(hook F193_TMPROOT "$TMPCW") || exit 2
TOPH=$(hook F193_TOP "") || exit 2

WK="$RUN193/final"
rm_wk() { case "$WK" in "$RUN193"/*) rm -rf "$WK" ;; esac; } # RMOK

# ---------------------------------------------------------------- gh helpers (output captured, rc tested)
GHOUT=""
ghx() { # ARGS... : 0 only when gh exited 0 with non-empty output
  local rc
  GHOUT=$(GH_PROMPT_DISABLED=1 GH_NO_UPDATE_NOTIFIER=1 gh "$@" 2> /dev/null); rc=$?
  [ "$rc" -eq 0 ] && [ -n "$GHOUT" ]
}
jqe() { printf '%s' "$GHOUT" | jq -e "$@" > /dev/null 2>&1; }
jqr() { printf '%s' "$GHOUT" | jq -r "$@" 2> /dev/null; }
is_sha40() { case "${1:-}" in ''|*[!0-9a-f]*) return 1 ;; esac; [ "${#1}" -eq 40 ]; }
is_int() { case "${1:-}" in ''|*[!0-9]*) return 1 ;; esac; return 0; }

FAILWORD=""
TOOLERR=0
fail() { FAILWORD=$1; return 1; }
toolfail() { FAILWORD=$1; TOOLERR=1; return 1; }

# ---------------------------------------------------------------- check 1: clean tree, HEAD is the intended head
chk1() {
  local branch st head live fh prhead
  branch=$(git -C "$TOPC" rev-parse --abbrev-ref HEAD 2> /dev/null) || { toolfail git_unreadable; return 1; }
  if [ "$branch" = "$RECOVERY_BRANCH" ]; then say "final: refused recovery checkout"; exit 2; fi
  st=$(git -C "$TOPC" status --porcelain=v1 --untracked-files=all 2> /dev/null); [ $? -eq 0 ] || { toolfail git_unreadable; return 1; }
  [ -z "$st" ] || { fail dirty_tree; return 1; }
  head=$(git -C "$TOPC" rev-parse HEAD 2> /dev/null) || { toolfail git_unreadable; return 1; }
  is_sha40 "$head" || { toolfail git_unreadable; return 1; }
  live=$(git -C "$TOPC" ls-remote origin refs/heads/main 2> /dev/null | awk 'NR==1{print $1}')
  is_sha40 "$live" || { toolfail remote_unreadable; return 1; }
  git -C "$TOPC" fetch -q origin main > /dev/null 2>&1 || { toolfail remote_unreadable; return 1; }
  fh=$(git -C "$TOPC" rev-parse FETCH_HEAD 2> /dev/null) || { toolfail remote_unreadable; return 1; }
  [ "$fh" = "$live" ] || { fail main_moved; return 1; }
  if [ "$MODE" = post ]; then
    [ "$branch" = main ] || { fail not_on_main; return 1; }
    [ "$head" = "$fh" ] || { fail head_not_main; return 1; }
  else
    ghx pr view "$PRN" -R "$REPO_SLUG" --json headRefOid || { toolfail gh_failed; return 1; }
    jqe 'type=="object"' || { toolfail gh_unparseable; return 1; }
    prhead=$(jqr '.headRefOid // empty')
    is_sha40 "$prhead" || { toolfail gh_unparseable; return 1; }
    [ "$head" = "$prhead" ] || { fail head_not_pr; return 1; }
    git -C "$TOPC" merge-base --is-ancestor "$fh" "$head" > /dev/null 2>&1 || { fail main_not_ancestor; return 1; }
  fi
  return 0
}

# ---------------------------------------------------------------- check 2: Crosswake CI on the producing PR head
APP=""
tip_pr() { # MAINSHA -> sets TIPPR ; 0 when exactly one merged PR produced the tip
  TIPPR=""
  ghx api "repos/$REPO_SLUG/commits/$1/pulls" || { toolfail gh_failed; return 1; }
  jqe 'type=="array"' || { toolfail gh_unparseable; return 1; }
  local n
  n=$(jqr '[.[] | select(.merged_at != null)] | length')
  is_int "$n" || { toolfail gh_unparseable; return 1; }
  [ "$n" -eq 1 ] || { fail merged_pr_count; return 1; }
  TIPPR=$(jqr '[.[] | select(.merged_at != null)] | .[0].number | tostring')
  is_int "$TIPPR" || { toolfail gh_unparseable; return 1; }
  return 0
}
ci_on() { # SHA : success required on the highest-id Crosswake CI check run of the right app
  local row st concl
  ghx api "repos/$REPO_SLUG/commits/$1/check-runs" --paginate || { toolfail gh_failed; return 1; }
  jqe '.check_runs | type == "array"' || { toolfail gh_unparseable; return 1; }
  row=$(printf '%s' "$GHOUT" | jq -s -r --arg c "$CI_NAME" --argjson a "$APP" --arg s "$1" \
    '[.[].check_runs[]? | select(.name==$c and .app.id==$a and .head_sha==$s)] | sort_by(.id) | if length==0 then "none" else (last | [(.id|tostring), .status, (.conclusion // "-")] | @tsv) end' 2> /dev/null) || { toolfail gh_unparseable; return 1; }
  [ -n "$row" ] || { toolfail gh_unparseable; return 1; }
  [ "$row" != none ] || { fail ci_missing; return 1; }
  st=$(printf '%s' "$row" | awk -F'\t' '{print $2}'); concl=$(printf '%s' "$row" | awk -F'\t' '{print $3}')
  [ "$st" = completed ] || { fail ci_not_complete; return 1; }
  [ "$concl" = success ] || { fail ci_not_success; return 1; }
  return 0
}
chk2() {
  local main prhead
  ghx api "repos/$REPO_SLUG/branches/main/protection/required_status_checks" || { toolfail gh_failed; return 1; }
  jqe '.checks | type == "array"' || { toolfail gh_unparseable; return 1; }
  APP=$(jqr --arg c "$CI_NAME" '[.checks[] | select(.context==$c) | .app_id] | if length==1 then .[0] else empty end')
  is_int "$APP" || { fail required_check_unreadable; return 1; }
  main=$(git -C "$TOPC" ls-remote origin refs/heads/main 2> /dev/null | awk 'NR==1{print $1}')
  is_sha40 "$main" || { toolfail remote_unreadable; return 1; }
  tip_pr "$main" || return 1
  ghx pr view "$TIPPR" -R "$REPO_SLUG" --json headRefOid || { toolfail gh_failed; return 1; }
  jqe 'type=="object"' || { toolfail gh_unparseable; return 1; }
  prhead=$(jqr '.headRefOid // empty')
  is_sha40 "$prhead" || { toolfail gh_unparseable; return 1; }
  ci_on "$prhead" || return 1
  if [ "$MODE" = pre ]; then
    ghx pr view "$PRN" -R "$REPO_SLUG" --json headRefOid || { toolfail gh_failed; return 1; }
    jqe 'type=="object"' || { toolfail gh_unparseable; return 1; }
    prhead=$(jqr '.headRefOid // empty')
    is_sha40 "$prhead" || { toolfail gh_unparseable; return 1; }
    ci_on "$prhead" || return 1
  fi
  say "final: ci ran on pr head SHA (pull_request runs also test a synthetic merge commit)"
  if ghx run list -R "$REPO_SLUG" --commit "$main" --json name,conclusion,status && jqe 'type=="array"'; then
    printf '%s' "$GHOUT" | jq -r '.[] | "final: info main-push \(.name) \(.conclusion // .status)"' 2> /dev/null
  else
    say "final: info main-push unreadable"
  fi
  return 0
}

# ---------------------------------------------------------------- check 3: open PRs against the disposition table
chk3() {
  local n row dups extra
  mkdir -p -m 700 "$WK" || { toolfail run_folder; return 1; }
  [ -f "$DISP" ] && [ -s "$DISP" ] || { fail disposition_missing; return 1; }
  awk -F'|' '/^\| [0-9]+ \|/ { a=$2; gsub(/ /,"",a); h=$4; gsub(/ /,"",h); print a "\t" h }' "$DISP" > "$WK/rows.tsv"
  [ -s "$WK/rows.tsv" ] || { fail disposition_empty; return 1; }
  awk -F'\t' '{print $1}' "$WK/rows.tsv" | sort -n > "$WK/rows.sorted"
  dups=$(uniq -d "$WK/rows.sorted" | awk 'END{print NR+0}')
  [ "$dups" -eq 0 ] || { fail disposition_duplicate; return 1; }
  ghx pr list -R "$REPO_SLUG" --state open --json number,headRefOid --limit 200
  if [ $? -ne 0 ]; then
    # an empty open list prints `[]` (non-empty text), so empty output means a failed read
    toolfail gh_failed; return 1
  fi
  jqe 'type=="array" and (all(.[]; (.number|type)=="number"))' || { toolfail gh_unparseable; return 1; }
  printf '%s' "$GHOUT" | jq -r '.[] | "\(.number)\t\(.headRefOid)"' > "$WK/open.tsv" 2> /dev/null || { toolfail gh_unparseable; return 1; }
  awk -F'\t' '{print $1}' "$WK/open.tsv" | sort -n | uniq > "$WK/open.sorted"
  sort -n "$WK/rows.sorted" | uniq > "$WK/rows.uniq"
  if [ "$MODE" = pre ]; then
    { cat "$WK/rows.uniq"; echo "$PRN"; } | sort -n | uniq > "$WK/want.sorted"
  else
    cp "$WK/rows.uniq" "$WK/want.sorted"
    # a row for the merged PR that produced the main tip is allowed once it is no longer open
    extra=$(comm -13 "$WK/open.sorted" "$WK/want.sorted")
    if [ -n "$extra" ]; then
      local main
      main=$(git -C "$TOPC" ls-remote origin refs/heads/main 2> /dev/null | awk 'NR==1{print $1}')
      if is_sha40 "$main" && tip_pr "$main" && [ "$extra" = "$TIPPR" ]; then
        awk -v x="$TIPPR" '$1!=x' "$WK/want.sorted" > "$WK/want.2" && mv "$WK/want.2" "$WK/want.sorted"
      fi
      FAILWORD=""; TOOLERR=0
    fi
  fi
  cmp -s "$WK/open.sorted" "$WK/want.sorted" || { fail open_pr_mismatch; return 1; }
  n=$(awk -F'\t' 'NR==FNR{h[$1]=$2; next} ($1 in h) && h[$1]!="" && substr($2,1,length(h[$1]))!=h[$1] {c++} END{print c+0}' "$WK/rows.tsv" "$WK/open.tsv")
  say "final: info head drift $n"
  return 0
}

# ---------------------------------------------------------------- check 4: no unverified crosswake* temp entries
sums_line_ok() { # NAME : every sums line for NAME verifies
  local n=$1 f one="$WK/one.sums" found
  : > "$one"
  for f in "$INV"/SHA256SUMS*; do
    [ -f "$f" ] || continue
    case $f in *.count|*.run1) continue ;; esac
    awk -v n="$n" '{ b=$2; sub(/^.*\//,"",b); if (b==n) print }' "$f" >> "$one"
  done
  found=$(awk 'NF{c++} END{print c+0}' "$one")
  [ "$found" -gt 0 ] || return 1
  ( cd "$INV" && shasum -a 256 -c "$one" > /dev/null 2>&1 )
}
chk4() {
  local e name id cell t nleft=0 ok
  mkdir -p -m 700 "$WK" || { toolfail run_folder; return 1; }
  [ -d "$TMPROOT" ] || { toolfail tmp_unreadable; return 1; }
  find "$TMPROOT" -maxdepth 1 -name 'crosswake*' | sort > "$WK/tmp-now.txt"
  while IFS= read -r e; do
    [ -n "$e" ] || continue
    nleft=$((nleft + 1))
    name=$(basename "$e")
    id=$(awk -F'\t' -v k="<tmp>/$name" '$1==k{print $2; exit}' "$TMPMAP" 2> /dev/null)
    cell=""
    if [ -n "$id" ]; then cell=$(rowcell "$id"); fi
    if [ -z "$cell" ]; then
      id=$(rowid_by_location "<tmp>/$name")
      [ -z "$id" ] || cell=$(rowcell "$id")
    fi
    [ -n "$cell" ] || { fail leftover_unmapped; return 1; }
    printf '%s\n' "$cell" | grep -Eo '[A-Za-z0-9_.-]+\.(tar|bundle|patch|files|excluded|expect)' | sort -u > "$WK/tok.txt"
    [ -s "$WK/tok.txt" ] || { fail leftover_no_backup; return 1; }
    while IFS= read -r t; do
      sums_line_ok "$t" || { fail leftover_backup_unverified; return 1; }
    done < "$WK/tok.txt"
  done < "$WK/tmp-now.txt"
  say "final: info tmp crosswake entries $nleft"
  return 0
}
rowcell() { awk -F'|' -v i="$1" '{ a=$2; gsub(/^ +| +$/,"",a); if (a==i) { b=$9; gsub(/^ +| +$/,"",b); print b; exit } }' "$INV189_MD" "$POSTREC"; }
rowid_by_location() { awk -F'|' -v k="$1" '{ l=$4; gsub(/^ +| +$/,"",l); if (l==k) { a=$2; gsub(/ /,"",a); print a; exit } }' "$INV189_MD" "$POSTREC"; }

# ---------------------------------------------------------------- check 5: the removal ledger
expected_ids() { # same rule as remove-193.sh load_rows : ids of the inventory and the post-189 record
  awk -F'|' '{ id=$2; gsub(/^ +| +$/,"",id); if (id ~ /^(R|C)-/) print id }' "$INV189_MD"
  awk -F'|' '{ id=$2; gsub(/^ +| +$/,"",id); if (id ~ /^R-POST-/) print id }' "$POSTREC"
}
chk5() {
  local e r k ne nrows nr nk nreason
  mkdir -p -m 700 "$WK" || { toolfail run_folder; return 1; }
  [ -f "$INV189_MD" ] && [ -f "$POSTREC" ] || { toolfail records_missing; return 1; }
  expected_ids > "$WK/exp.ids"
  ne=$(awk 'NF{c++} END{print c+0}' "$WK/exp.ids")
  [ "$ne" -gt 0 ] || { fail expected_zero; return 1; }
  sort "$WK/exp.ids" | uniq -d > "$WK/exp.dups"
  [ ! -s "$WK/exp.dups" ] || { fail expected_duplicate; return 1; }
  [ -f "$LEDGER" ] && [ -s "$LEDGER" ] || { fail ledger_missing; return 1; }
  e=$(awk '$1=="expected:"{print $2; exit}' "$LEDGER"); r=$(awk '$1=="removed:"{print $2; exit}' "$LEDGER"); k=$(awk '$1=="kept:"{print $2; exit}' "$LEDGER")
  is_int "$e" && is_int "$r" && is_int "$k" || { fail ledger_header; return 1; }
  [ "$e" -gt 0 ] || { fail expected_zero; return 1; }
  [ "$e" -eq $((r + k)) ] || { fail ledger_arithmetic; return 1; }
  [ "$e" -eq "$ne" ] || { fail ledger_count; return 1; }
  awk -F'|' 'NF==10 { a=$2; gsub(/^ +| +$/,"",a); if (a=="row id" || a ~ /^-+$/ || a=="") next; res=$8; gsub(/^ +| +$/,"",res); why=$9; gsub(/^ +| +$/,"",why); print a "\t" res "\t" why }' "$LEDGER" > "$WK/led.tsv"
  nrows=$(awk 'END{print NR+0}' "$WK/led.tsv")
  [ "$nrows" -eq "$e" ] || { fail ledger_rows; return 1; }
  awk -F'\t' '{print $1}' "$WK/led.tsv" | sort > "$WK/led.ids"
  sort "$WK/exp.ids" > "$WK/exp.sorted"
  cmp -s "$WK/led.ids" "$WK/exp.sorted" || { fail ledger_ids; return 1; }
  nk=$(awk -F'\t' '$2=="kept"{c++} END{print c+0}' "$WK/led.tsv")
  nr=$(awk -F'\t' '$2 ~ /^(removed|already absent)/{c++} END{print c+0}' "$WK/led.tsv")
  nreason=$(awk -F'\t' '$2=="kept" && $3==""{c++} END{print c+0}' "$WK/led.tsv")
  [ "$nreason" -eq 0 ] || { fail kept_without_reason; return 1; }
  [ "$nk" -eq "$k" ] && [ "$nr" -eq "$r" ] || { fail ledger_counts; return 1; }
  return 0
}

# ---------------------------------------------------------------- driver
MODE=""; PRN=""; ONLY=""
run_check() { # N
  local n=$1
  FAILWORD=""
  case $n in 1) chk1 ;; 2) chk2 ;; 3) chk3 ;; 4) chk4 ;; 5) chk5 ;; esac
  if [ $? -eq 0 ]; then say "final: check $n pass"; return 0; fi
  say "final: check $n fail ${FAILWORD:-unknown}"
  return 1
}

do_main() {
  local n bad=0
  mkdir -p -m 700 "$RUN193" || die2 "run folder failed"
  rm_wk; mkdir -p -m 700 "$WK" || die2 "run folder failed"
  [ -n "$MODE" ] || die2 "usage"
  if [ "$MODE" = pre ]; then is_int "$PRN" || die2 "pull request number missing"; fi
  if [ -n "$TOPH" ]; then TOPC=$TOPH; fi
  if [ -n "${FINAL193_TOP:-}" ]; then
    case $ONLY in 2|3) TOPC=$FINAL193_TOP ;; *) die2 "FINAL193_TOP is honoured only for --check 2 and --check 3" ;; esac
  fi
  command -v gh > /dev/null 2>&1 && command -v jq > /dev/null 2>&1 || die2 "gh or jq missing"
  if [ -n "$ONLY" ]; then
    run_check "$ONLY" || bad=1
  else
    for n in 1 2 3 4 5; do run_check "$n" || bad=1; done
  fi
  rm_wk
  if [ "$bad" -eq 0 ]; then say "final: result pass"; exit 0; fi
  say "final: result fail"
  if [ "$TOOLERR" -eq 1 ]; then exit 2; fi
  exit 1
}

# ---------------------------------------------------------------- self-test
fx_rm() { case "$1" in "$ST193_PREFIX"?*) rm -rf "$1" ;; esac; } # RMOK (fixture folders only)
fx_git() { GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 git -c user.name=t -c user.email=t@t.invalid -c commit.gpgsign=false "$@"; }
fx_sha() { shasum -a 256 < "$1" | awk '{print $1}'; }

FX=""; NFX=0
repeat40() { printf '%s' "$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1$1"; }
fxmk() {
  [ -z "$FX" ] || fx_rm "$FX"
  NFX=$((NFX + 1)); FX=$FXROOT/f$NFX
  PAR=$FX/parent; GHS=$FX/gh; BIN=$FX/bin; RECD=$FX/rec; TR=$FX/tmproot; ORIG=$FX/origin.git; TOPF=$FX/top; RUNF=$FX/run
  INVF=$PAR/crosswake-candidate-backup/inventory-189
  mkdir -p "$INVF" "$GHS" "$BIN" "$RECD" "$TR" || return 1
  mkdir -m 700 "$RUNF" || return 1
  fx_git init -q --bare -b main "$ORIG" || return 1
  fx_git init -q -b main "$TOPF" || return 1
  echo base > "$TOPF/a.txt"; fx_git -C "$TOPF" add a.txt; fx_git -C "$TOPF" commit -q -m c1 || return 1
  fx_git -C "$TOPF" remote add origin "$ORIG"; fx_git -C "$TOPF" push -q origin main || return 1
  MAINSHA=$(fx_git -C "$TOPF" rev-parse HEAD)
  fx_git -C "$TOPF" checkout -q -b pr7; echo x > "$TOPF/x.txt"; fx_git -C "$TOPF" add x.txt; fx_git -C "$TOPF" commit -q -m p7
  fx_git -C "$TOPF" push -q origin pr7; PRHEAD=$(fx_git -C "$TOPF" rev-parse HEAD)
  fx_git -C "$TOPF" checkout -q main
  H242=$(repeat40 e); HA=$(repeat40 a); HB=$(repeat40 b)
  printf '{"strict":true,"checks":[{"context":"Crosswake CI","app_id":15368}]}\n' > "$GHS/prot.json"
  printf '[{"number":242,"merged_at":"2026-10-24T00:00:00Z"}]\n' > "$GHS/pulls-$MAINSHA.json"
  printf '{"headRefOid":"%s"}\n' "$H242" > "$GHS/prview-242.json"
  fx_checks "$H242" success
  printf '[{"number":236,"headRefOid":"%s"},{"number":238,"headRefOid":"%s"}]\n' "$HA" "$HB" > "$GHS/prlist.json"
  printf '[]\n' > "$GHS/runs.json"
  cat > "$BIN/gh" <<'SHIM'
#!/bin/bash
G=${GHS:?}
[ ! -f "$G/fail" ] || exit 1
[ ! -f "$G/empty" ] || exit 0
f=""
case "$1" in
  pr) case "$2" in view) f="$G/prview-$3.json" ;; list) f="$G/prlist.json" ;; esac ;;
  run) f="$G/runs.json" ;;
  api) p=$2
       case "$p" in
         *required_status_checks) f="$G/prot.json" ;;
         */pulls) s=${p%/pulls}; s=${s##*/}; f="$G/pulls-$s.json" ;;
         */check-runs) s=${p%/check-runs}; s=${s##*/}; f="$G/checks-$s.json" ;;
       esac ;;
esac
[ -n "$f" ] && [ -f "$f" ] || exit 1
cat "$f"
SHIM
  chmod 700 "$BIN/gh"
  fx_disp 236:"$(printf '%s' "$HA" | cut -c1-12)" 238:"$(printf '%s' "$HB" | cut -c1-12)"
  {
    echo '| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |'
    echo '|---|---|---|---|---|---|---|---|---|'
    echo '| R-A | a | <tmp>/crosswake-a | tmp-folder | 1 | c | r | a.tar | pass |'
    echo '| R-B | b | <recovery-checkout> | branch | 1 | c | r | refs-all.bundle | pass |'
    echo '| C-C | c | <tmp>/crosswake-c | commits | 1 | c | r | none needed | n/a |'
  } > "$RECD/inv.md"
  {
    echo '| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |'
    echo '|---|---|---|---|---|---|---|---|---|'
    echo '| R-POST-X | x | <recovery-checkout> | ref | 1 | published | r | remote | n/a |'
  } > "$RECD/post.md"
  fx_ledger 4 3 1
  printf '<tmp>/crosswake-left\tR-A\n' > "$RECD/tmpmap.tsv"
  echo tarball > "$INVF/a.tar"
  ( cd "$INVF" && shasum -a 256 a.tar > SHA256SUMS )
  return 0
}
fx_checks() { # SHA CONCLUSION
  printf '{"check_runs":[{"id":5,"name":"Crosswake CI","app":{"id":15368},"head_sha":"%s","status":"completed","conclusion":"%s"}]}\n' "$1" "$2" > "$GHS/checks-$1.json"
}
fx_disp() { # NUM:HEAD ...
  {
    echo '| PR | title | seen sha | disposition |'
    echo '|---|---|---|---|'
    for a in "$@"; do echo "| ${a%%:*} | t | ${a#*:} | hold |"; done
  } > "$RECD/disp.md"
}
fx_ledger() { # EXPECTED REMOVED KEPT
  {
    echo '# ledger'
    echo "expected: $1"; echo "removed: $2"; echo "kept: $3"
    echo '| row id | kind | location | backup + sha256 match | ref check | action | result | reason if kept |'
    echo '|---|---|---|---|---|---|---|---|'
    echo '| R-A | tmp-folder | <tmp>/crosswake-a | ok | n/a | delete | removed | |'
    echo '| R-B | branch | <recovery-checkout> | ok | n/a | none | kept | parent kept |'
    echo '| C-C | commits | <tmp>/crosswake-c | n/a | n/a | none | already absent | |'
    echo '| R-POST-X | ref | <recovery-checkout> | n/a | n/a | none | removed with R-POST-LOC-03 | |'
  } > "$RECD/ledger.md"
}
fx_pre() { # the pull request under test is 7 and HEAD is its head
  fx_git -C "$TOPF" checkout -q pr7
  printf '{"headRefOid":"%s"}\n' "$PRHEAD" > "$GHS/prview-7.json"
  fx_checks "$PRHEAD" success
  printf '[{"number":236,"headRefOid":"%s"},{"number":238,"headRefOid":"%s"},{"number":7,"headRefOid":"%s"}]\n' "$HA" "$HB" "$PRHEAD" > "$GHS/prlist.json"
}
fr() {
  env SELFTEST_193=1 PATH="$BIN:$PATH" GHS="$GHS" P193_PARENT="$PAR" P193_RUN="$RUNF" F193_TOP="$TOPF" F193_TMPROOT="$TR" \
    F193_DISP="$RECD/disp.md" F193_LEDGER="$RECD/ledger.md" F193_INV189="$RECD/inv.md" F193_POSTREC="$RECD/post.md" F193_TMPMAP="$RECD/tmpmap.tsv" \
    bash "$SELF" "$@" > "$FX/out.txt" 2>&1
  RC=$?
}
has() { grep -qxF -- "$1" "$FX/out.txt"; }
hasp() { grep -qF -- "$1" "$FX/out.txt"; }
failed() { has "final: check $1 fail $2" && has "final: result fail" && [ "$RC" -ne 0 ]; }

c_post_clean() {
  fr --post-merge; [ "$RC" -eq 0 ] || return 1
  has "final: result pass" && has "final: check 1 pass" && has "final: check 2 pass" && has "final: check 3 pass" && has "final: check 4 pass" && has "final: check 5 pass" || return 1
  hasp "final: ci ran on pr head SHA (pull_request runs also test a synthetic merge commit)"
}
c_pre_clean() {
  fx_pre
  fx_disp 236:cccccccccccc 238:"$(printf '%s' "$HB" | cut -c1-12)"
  fr --pre-merge 7; [ "$RC" -eq 0 ] || return 1
  has "final: result pass" && has "final: info head drift 1"
}
c_dirty() { echo x > "$TOPF/dirty.txt"; fr --post-merge; failed 1 dirty_tree; }
c_head_not_main() { echo y > "$TOPF/y.txt"; fx_git -C "$TOPF" add y.txt; fx_git -C "$TOPF" commit -q -m local; fr --post-merge; failed 1 head_not_main; }
c_head_not_pr() { fx_pre; printf '{"headRefOid":"%s"}\n' "$HA" > "$GHS/prview-7.json"; fr --pre-merge 7; failed 1 head_not_pr; }
c_red_ci() { fx_checks "$H242" failure; fr --post-merge; failed 2 ci_not_success; }
c_no_ci() { printf '{"check_runs":[]}\n' > "$GHS/checks-$H242.json"; fr --post-merge; failed 2 ci_missing; }
c_zero_merged() { printf '[]\n' > "$GHS/pulls-$MAINSHA.json"; fr --post-merge; failed 2 merged_pr_count; }
c_two_merged() { printf '[{"number":242,"merged_at":"x"},{"number":243,"merged_at":"y"}]\n' > "$GHS/pulls-$MAINSHA.json"; fr --post-merge; failed 2 merged_pr_count; }
c_pre_extra_open() {
  fx_pre
  printf '[{"number":236,"headRefOid":"%s"},{"number":238,"headRefOid":"%s"},{"number":7,"headRefOid":"%s"},{"number":999,"headRefOid":"%s"}]\n' "$HA" "$HB" "$PRHEAD" "$HA" > "$GHS/prlist.json"
  fr --pre-merge 7; failed 3 open_pr_mismatch
}
c_dup_row() { echo "| 236 | t | x | hold |" >> "$RECD/disp.md"; fr --post-merge; failed 3 disposition_duplicate; }
c_gh_empty() { : > "$GHS/empty"; fr --post-merge; failed 2 gh_failed && failed 3 gh_failed; }
c_gh_garbage() { echo 'not json' > "$GHS/prlist.json"; fr --post-merge; failed 3 gh_unparseable; }
c_gh_fail() { : > "$GHS/fail"; fr --post-merge; failed 2 gh_failed && [ "$RC" -eq 2 ]; }
c_ledger_missing() { rm -f "$RECD/ledger.md"; fr --post-merge; failed 5 ledger_missing; }
c_ledger_empty() { : > "$RECD/ledger.md"; fr --post-merge; failed 5 ledger_missing; }
c_expected_zero() { : > "$RECD/inv.md"; : > "$RECD/post.md"; fr --post-merge; failed 5 expected_zero; }
c_arith() { fx_ledger 4 4 1; fr --post-merge; failed 5 ledger_arithmetic; }
c_id_missing() { grep -v '^| R-A ' "$RECD/ledger.md" > "$RECD/l.new"; mv "$RECD/l.new" "$RECD/ledger.md"; fr --post-merge; failed 5 ledger_rows; }
c_kept_noreason() { sed 's/| kept | parent kept |/| kept | |/' "$RECD/ledger.md" > "$RECD/l.new"; mv "$RECD/l.new" "$RECD/ledger.md"; fr --post-merge; failed 5 kept_without_reason; }
c_leftover_unmapped() { mkdir -p "$TR/crosswake-nomap"; fr --post-merge; failed 4 leftover_unmapped; }
c_leftover_mapped() {
  mkdir -p "$TR/crosswake-left"; fr --post-merge; [ "$RC" -eq 0 ] && has "final: check 4 pass" || return 1
  echo tamper >> "$INVF/a.tar"; fr --post-merge; failed 4 leftover_backup_unverified
}
c_post_extra_open() {
  printf '[{"number":236,"headRefOid":"%s"},{"number":238,"headRefOid":"%s"},{"number":999,"headRefOid":"%s"}]\n' "$HA" "$HB" "$HA" > "$GHS/prlist.json"
  fr --post-merge; failed 3 open_pr_mismatch
}
c_zero_open() {
  printf '[]\n' > "$GHS/prlist.json"; fx_disp 242:"$(printf '%s' "$H242" | cut -c1-12)"
  fr --post-merge; has "final: check 3 pass"
}
c_zero_open_empty_table() { printf '[]\n' > "$GHS/prlist.json"; fx_disp; fr --post-merge; failed 3 disposition_empty; }
c_order() {
  printf '[{"number":238,"headRefOid":"%s"},{"number":236,"headRefOid":"%s"}]\n' "$HB" "$HA" > "$GHS/prlist.json"
  fx_disp 238:"$(printf '%s' "$HB" | cut -c1-12)" 236:"$(printf '%s' "$HA" | cut -c1-12)"
  fr --post-merge; [ "$RC" -eq 0 ] && has "final: result pass"
}
c_only() {
  fr --check 2 --post-merge; [ "$RC" -eq 0 ] || return 1
  has "final: check 2 pass" && ! hasp "check 1" && ! hasp "check 3" && ! hasp "check 4" && ! hasp "check 5"
}
c_recovery_refused() {
  fx_git -C "$TOPF" checkout -q -b "$RECOVERY_BRANCH"
  fr --post-merge; [ "$RC" -eq 2 ] && hasp "refused recovery checkout"
}
c_topenv() {
  FINAL193_TOP="$TOPF" fr --check 1 --post-merge; [ "$RC" -eq 2 ] && hasp "honoured only for --check 2"
}
c_static() {
  local code f1 f2 f3 f4 f5 f6 toks
  code=$(sed '/^# -* self-test$/,$d' "$SELF" | grep -v '^[[:space:]]*#')
  f1="git ""clean"; f2="git ""push"; f3="git ""stash"; f4="update""-ref"; f5="git ""reset"; f6="git ""checkout"
  toks="$f1|$f2|$f3|$f4|$f5|$f6|[|] *tail|[|] *head|rm -rf [^\"]*\\*"
  if printf '%s\n' "$code" | grep -Eq -- "$toks"; then return 1; fi
  [ "$(sed '/^# -* self-test$/,$d' "$SELF" | grep -c 'rm -rf')" -eq 1 ]
}

do_selftest() {
  local GOOD=0 TOTAL=0 probe
  FXROOT=$(mktemp -d "${ST193_PREFIX}XXXXXX") || exit 2
  FXROOT=$(cd "$FXROOT" && pwd -P)
  case $FXROOT in "$ST193_PREFIX"?*) : ;; *) echo "selftest final-check-193: fixture outside prefix"; exit 2 ;; esac
  probe=$(P193_PARENT="$FXROOT/probe" P193_RUN="$FXROOT/probe-run" SELFTEST_193=1 bash -c ". '$HERE/paths-193.sh'; echo \"\$BACKUP_ROOT|\$RUN193\"")
  if [ "$probe" != "$FXROOT/probe/crosswake-candidate-backup|$FXROOT/probe-run" ]; then
    echo "selftest final-check-193: path override not honoured; aborting before any write"; fx_rm "$FXROOT"; exit 2
  fi
  trap 'fx_rm "$FXROOT"' EXIT
  command -v jq > /dev/null 2>&1 || { echo "selftest final-check-193: jq missing"; exit 2; }
  ctl() {
    TOTAL=$((TOTAL + 1))
    if fxmk && "$3"; then GOOD=$((GOOD + 1)); echo "$1 $2: as expected"; else echo "$1 $2: NOT as expected"; if [ -n "${F193_DEBUG:-}" ] && [ -f "$FX/out.txt" ]; then sed 's/^/   | /' "$FX/out.txt"; fi; fi
  }
  ctl F01 "clean post-merge fixture passes all five checks" c_post_clean
  ctl F02 "clean pre-merge fixture passes; head drift is reported, not failed" c_pre_clean
  ctl F03 "dirty tree fails check 1" c_dirty
  ctl F04 "post-merge HEAD different from live origin main fails check 1" c_head_not_main
  ctl F05 "pre-merge HEAD different from the live PR head fails check 1" c_head_not_pr
  ctl F06 "red Crosswake CI on the producing PR head fails check 2" c_red_ci
  ctl F07 "missing Crosswake CI check run fails check 2" c_no_ci
  ctl F08 "no merged PR for the main tip fails check 2" c_zero_merged
  ctl F09 "several merged PRs for the main tip fail check 2" c_two_merged
  ctl F10 "pre-merge open PR beyond the one under test fails check 3" c_pre_extra_open
  ctl F11 "duplicated disposition row fails check 3" c_dup_row
  ctl F12 "empty gh output fails the gh-based checks" c_gh_empty
  ctl F13 "unparseable gh JSON fails check 3" c_gh_garbage
  ctl F14 "gh non-zero exit fails and exits 2" c_gh_fail
  ctl F15 "missing ledger fails check 5" c_ledger_missing
  ctl F16 "empty ledger fails check 5" c_ledger_empty
  ctl F17 "expected count 0 fails check 5" c_expected_zero
  ctl F18 "expected different from removed + kept fails check 5" c_arith
  ctl F19 "expected id missing from the ledger fails check 5" c_id_missing
  ctl F20 "kept row without a reason fails check 5" c_kept_noreason
  ctl F21 "leftover crosswake temp entry without a row fails check 4" c_leftover_unmapped
  ctl F22 "leftover entry with a verified row passes, a tampered backup fails" c_leftover_mapped
  ctl F23 "post-merge with an extra open PR fails check 3" c_post_extra_open
  ctl F24 "zero open PRs passes when gh and the JSON were good and the table has the merged PR" c_zero_open
  ctl F25 "zero open PRs with an empty disposition table fails" c_zero_open_empty_table
  ctl F26 "row order and gh order do not change the result" c_order
  ctl F27 "--check 2 prints only that check" c_only
  ctl F28 "the recovery checkout is refused" c_recovery_refused
  ctl F29 "FINAL193_TOP is refused for checks other than 2 and 3" c_topenv
  ctl F30 "static scan: no pipe into tail or head, no forbidden git write, one guarded delete" c_static
  echo "selftest final-check-193: controls $GOOD of $TOTAL as expected"
  [ "$GOOD" -eq "$TOTAL" ]
}

# ---------------------------------------------------------------- dispatch
while [ "$#" -gt 0 ]; do
  case "$1" in
    --pre-merge) MODE=pre; PRN=${2:-}; [ "$#" -ge 2 ] || die2 "usage"; shift 2 ;;
    --post-merge) MODE=post; shift ;;
    --check) ONLY=${2:-}; [ "$#" -ge 2 ] || die2 "usage"; case $ONLY in 1|2|3|4|5) : ;; *) die2 "usage" ;; esac; shift 2 ;;
    --self-test) do_selftest; exit $? ;;
    *) die2 "usage: --pre-merge PR | --post-merge | --check N | --self-test" ;;
  esac
done
do_main
