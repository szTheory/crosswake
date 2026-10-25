#!/bin/bash
# Phase 193 copy-forward (D-08). Modes: stage DIR | runtime-backup | apply DIR | verify DIR | --self-test
# Restores the editor/agent settings (allowlist), the env files and the workstream runtime files from
# the backup tars into a new checkout. Caches are never copied.
# Output: fixed "copyforward: ..." labels and counts. Never a file name, path, hash or env value.
# Exit: 0 pass, 1 check failed, 2 scope or tool error.
set -u
umask 077
export LC_ALL=C
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 2
. "$HERE/paths-193.sh" || exit 2

# the three workstream runtime files (exact repo-relative paths)
WS=.planning/workstreams/quality-ratchet-release
RT_PATHS="$WS/config.json
$WS/state.json
$WS/milestone.lock"

SRC=$TOP
if [ "${SELFTEST_193:-}" = 1 ] && [ -n "${CF193_SRC:-}" ]; then
  case $CF193_SRC in
    "$ST193_PREFIX"*) SRC=$CF193_SRC ;;
  esac
fi

say() { printf '%s\n' "$1"; }
die1() { say "copyforward: fail $1"; say "copyforward: result fail"; exit 1; }
die2() { say "copyforward: fail $1"; say "copyforward: result fail"; exit 2; }
rm_under_run() { case "$1" in "$RUN193"/*) rm -rf "$1" ;; esac; }
sha_of() { shasum -a 256 "$1" | awk '{print $1}'; }
oct() { printf '%d' "$((8#${1}))"; }

# path filter (reads "sha mode path" lines, prints those whose path is on the settings allowlist)
ALLOW_AWK='
{ p=$0; sub(/^[^ ]+ [^ ]+ /,"",p)
  if (p ~ /(^|\/)\.\.(\/|$)/ || p ~ /^\//) next
  if (p ~ /(^|\/)\.DS_Store$/) next
  if (p ~ /\.lock$/) next
  if (p ~ /^\.claude\/worktrees\//) next
  if (p ~ /(^|\/)\.expert(\/|$)/) next
  if (p ~ /^\.planning\/research\/\.cache\//) next
  if (p ~ /^\.claude\/[^\/]+\.json$/ || p ~ /^\.gsd\//) print
}'

# valid .files lines only: 64 hex, mode, path (a "sensitive" header line is skipped)
parse_files() {
  awk '$1 ~ /^[0-9a-f]+$/ && length($1)==64 && $2 ~ /^[0-7]+$/ { print }' "$1"
}

W=""
mkw() { mkdir -p -m 700 "$RUN193" || exit 2; W=$(mktemp -d "$RUN193/cfw.XXXXXX") || exit 2; }
cleanw() { if [ -n "$W" ]; then rm_under_run "$W"; fi; W=""; }
trap 'cleanw' EXIT

# build_expected OUT : tab lines "cat src sha mode path"
build_expected() {
  local out=$1 t
  [ -d "$INV" ] || die2 "backup root missing"
  : > "$out.raw"
  [ -f "$INV/ignored-keep.tar" ] && [ -f "$INV/ignored-keep.files" ] || die2 "source missing"
  [ -f "$INV/env-local.tar" ] && [ -f "$INV/env-local.files" ] || die2 "source missing"
  parse_files "$INV/ignored-keep.files" | awk "$ALLOW_AWK" | awk '{ s=$0; sub(/^[^ ]+ [^ ]+ /,"",s); printf "settings\tik\t%s\t%s\t%s\n",$1,$2,s }' >> "$out.raw"
  for t in post189-dirty post189-dirty-r1; do
    if [ -f "$INV/$t.tar" ] && [ -f "$INV/$t.files" ]; then
      parse_files "$INV/$t.files" | awk "$ALLOW_AWK" | awk -v src="$t" '{ s=$0; sub(/^[^ ]+ [^ ]+ /,"",s); printf "settings\t%s\t%s\t%s\t%s\n",src,$1,$2,s }' >> "$out.raw"
    fi
  done
  # the 189 env tar may hold members under the original root (SRC without its leading slash):
  # those get src "envp" and the repo-relative path; extract_expected maps them back
  parse_files "$INV/env-local.files" | awk -v pre="${SRC#/}/" '{ s=$0; sub(/^[^ ]+ [^ ]+ /,"",s); src="env"; if (index(s,pre)==1) { s=substr(s,length(pre)+1); src="envp" } printf "env\t%s\t%s\t600\t%s\n",src,$1,s }' >> "$out.raw"
  if [ -f "$INV/post189-runtime.tar" ] && [ -f "$INV/post189-runtime.files" ]; then
    parse_files "$INV/post189-runtime.files" | awk '{ s=$0; sub(/^[^ ]+ [^ ]+ /,"",s); printf "runtime\trt\t%s\t%s\t%s\n",$1,$2,s }' >> "$out.raw"
  fi
  # last source wins per path
  awk -F'\t' '{ if (!($5 in s)) ord[++n]=$5; s[$5]=$0 } END{ for(i=1;i<=n;i++) print s[ord[i]] }' "$out.raw" > "$out"
  rm -f "$out.raw"
  # path sanity: no glob characters (tar names are patterns), env paths relative without ..
  if awk -F'\t' '$5 ~ /[*?\[\]\\]/ {f=1} END{exit f?0:1}' "$out"; then die1 "glob_path"; fi
  if awk -F'\t' '$1=="env" && ($5 ~ /^\// || $5 ~ /(^|\/)\.\.(\/|$)/ || $5=="") {f=1} END{exit f?0:1}' "$out"; then die1 "path_outside"; fi
  # runtime paths must be exactly the three known files
  local rp
  while IFS= read -r rp; do
    [ -n "$rp" ] || continue
    printf '%s\n' "$RT_PATHS" | grep -qxF -- "$rp" || die1 "path_outside"
  done <<EOF3
$(awk -F'\t' '$1=="runtime"{print $5}' "$out")
EOF3
}

count_cat() { awk -F'\t' -v c="$2" '$1==c{n++} END{print n+0}' "$1"; }

# extract_expected EXP DIR : extract each file from its final source into DIR
extract_expected() {
  local exp=$1 d=$2 src tar lf envp pre ml
  mkdir -p -m 700 "$d" || exit 2
  for src in ik post189-dirty post189-dirty-r1 env envp rt; do
    lf="$W/list.$src"
    awk -F'\t' -v s="$src" '$2==s{print $5}' "$exp" > "$lf"
    [ -s "$lf" ] || continue
    case $src in
      ik) tar=$INV/ignored-keep.tar ;;
      env|envp) tar=$INV/env-local.tar ;;
      rt) tar=$INV/post189-runtime.tar ;;
      *) tar=$INV/$src.tar ;;
    esac
    if [ "$src" = envp ]; then
      # members are named under the original root; select them by full name, strip the root on extract
      pre="${SRC#/}/"
      ml="$W/members.envp"
      awk -v pre="$pre" '{print pre $0}' "$lf" > "$ml"
      COPYFILE_DISABLE=1 tar -xpf "$tar" -C "$d" -s "|^$(printf '%s' "$pre" | sed 's/[][\.*^$|]/\\&/g')||" -T "$ml" >/dev/null 2>&1 || die1 "extract"
      [ ! -e "$d/${pre%/}" ] || die1 "extract"
    else
      COPYFILE_DISABLE=1 tar -xpf "$tar" -C "$d" -T "$lf" >/dev/null 2>&1 || die1 "extract"
    fi
    if [ "$src" = env ] || [ "$src" = envp ]; then
      # env files are always tightened to 0600, whatever mode the backup recorded
      while IFS= read -r envp; do chmod 600 "$d/$envp" || die1 "extract"; done < "$lf"
    fi
  done
}

# check_tree EXP DIR : sha and mode against expected; env must be 600; no strays
check_tree() {
  local exp=$1 d=$2 cat src sha mode path f n_exp n_got bad_hash=0 bad_mode=0 am
  [ -z "$(find "$d" -type l -print -quit)" ] || die1 "symlink_entry"
  [ -z "$(find "$d" -name '._*' -print -quit)" ] || die1 "appledouble_entry"
  while IFS=$'\t' read -r cat src sha mode path; do
    f="$d/$path"
    [ -f "$f" ] || { bad_hash=$((bad_hash + 1)); continue; }
    [ "$(sha_of "$f")" = "$sha" ] || bad_hash=$((bad_hash + 1))
    am=$(stat -f %Lp "$f")
    [ "$(oct "$am")" = "$(oct "$mode")" ] || bad_mode=$((bad_mode + 1))
    if [ "$cat" = env ] && [ "$(oct "$am")" != "$(oct 600)" ]; then bad_mode=$((bad_mode + 1)); fi
  done < "$exp"
  [ "$bad_mode" -eq 0 ] || die1 "mode_mismatch"
  [ "$bad_hash" -eq 0 ] || die1 "hash_mismatch"
  return 0
}

env_tight() { parse_files "$INV/env-local.files" | awk '$2+0 != 600 {n++} END{print n+0}'; }
counts_line() { say "copyforward: settings $(count_cat "$1" settings) env $(count_cat "$1" env) runtime $(count_cat "$1" runtime)"; }

do_stage() { # DIR
  local d=$1 exp s e r
  case $d in
    "$RUN193"/*) : ;;
    *) die2 "stage_outside_run" ;;
  esac
  if [ -e "$d" ]; then
    [ -d "$d" ] && [ -z "$(ls -A "$d")" ] || die2 "stage_not_empty"
  fi
  mkw
  exp="$W/expected.tsv"
  build_expected "$exp"
  s=$(count_cat "$exp" settings); e=$(count_cat "$exp" env); r=$(count_cat "$exp" runtime)
  [ "$s" -gt 0 ] && [ "$e" -gt 0 ] || { cleanw; die1 "allowlist_empty"; }
  extract_expected "$exp" "$d"
  local n_got
  n_got=$(find "$d" -type f | awk 'END{print NR+0}')
  [ "$n_got" -eq $((s + e + r)) ] || { cleanw; die1 "file_count"; }
  check_tree "$exp" "$d"
  counts_line "$exp"
  say "copyforward: env_tightened $(env_tight)"
  cleanw
  say "copyforward: result pass"
}

check_toplevel_main() { # DIR
  local d=$1 tl br
  [ -d "$d" ] || die2 "not_git_toplevel"
  tl=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || die2 "not_git_toplevel"
  [ "$tl" = "$(cd "$d" && pwd -P)" ] || die2 "not_git_toplevel"
  br=$(git -C "$d" symbolic-ref --short HEAD 2>/dev/null) || die2 "not_main"
  [ "$br" = main ] || die2 "not_main"
}

do_apply() { # DIR
  local d dd exp st f cat src sha mode path ex
  [ -d "$1" ] || die2 "not_git_toplevel"
  d=$(cd "$1" && pwd -P)
  check_toplevel_main "$d"
  mkw
  exp="$W/expected.tsv"
  build_expected "$exp"
  [ "$(count_cat "$exp" settings)" -gt 0 ] && [ "$(count_cat "$exp" env)" -gt 0 ] || { cleanw; die1 "allowlist_empty"; }
  st="$RUN193/cf-apply"
  rm_under_run "$st"
  extract_expected "$exp" "$st"
  check_tree "$exp" "$st"
  ex="$d/.git/info/exclude"
  mkdir -p "$d/.git/info" || exit 2
  [ -f "$ex" ] || : > "$ex"
  while IFS=$'\t' read -r cat src sha mode path; do
    mkdir -p "$d/$(dirname "$path")" || die2 "copy"
    cp "$st/$path" "$d/$path" || die2 "copy"
    chmod "$(printf '%o' "$((8#$mode))")" "$d/$path" || die2 "copy"
    if [ "$cat" = runtime ]; then
      grep -qxF -- "/$path" "$ex" || printf '/%s\n' "$path" >> "$ex"
    fi
  done < "$exp"
  rm_under_run "$st"
  [ ! -e "$st" ] || die2 "stage_not_removed"
  counts_line "$exp"
  say "copyforward: env_tightened $(env_tight)"
  cleanw
  say "copyforward: result pass"
}

do_verify() { # DIR
  local d exp cat src sha mode path f am ex n_ex bad=0 st
  [ -d "$1" ] || die2 "not_git_toplevel"
  d=$(cd "$1" && pwd -P)
  tl=$(git -C "$d" rev-parse --show-toplevel 2>/dev/null) || die2 "not_git_toplevel"
  [ "$tl" = "$d" ] || die2 "not_git_toplevel"
  mkw
  exp="$W/expected.tsv"
  build_expected "$exp"
  ex="$d/.git/info/exclude"
  while IFS=$'\t' read -r cat src sha mode path; do
    f="$d/$path"
    if [ ! -f "$f" ]; then bad=1; continue; fi
    # the dispatch-isolation sentinel is rewritten by every dispatch (10-minute TTL): presence and mode only
    if [ "$path" != ".gsd/dispatch-isolation-sentinel.json" ]; then
      [ "$(sha_of "$f")" = "$sha" ] || bad=2
    fi
    am=$(stat -f %Lp "$f")
    if [ "$(oct "$am")" != "$(oct "$mode")" ]; then bad=3; fi
    if [ "$cat" = env ] && [ "$(oct "$am")" != "$(oct 600)" ]; then bad=3; fi
    if [ "$cat" = runtime ]; then
      [ -f "$ex" ] && [ "$(grep -cxF -- "/$path" "$ex")" -eq 1 ] || { cleanw; die1 "exclude_missing"; }
    fi
  done < "$exp"
  case $bad in
    1) cleanw; die1 "file_missing" ;;
    2) cleanw; die1 "hash_mismatch" ;;
    3) cleanw; die1 "mode_mismatch" ;;
  esac
  counts_line "$exp"
  n_ex=0
  [ -f "$ex" ] && n_ex=$(awk 'NF && $0 !~ /^#/{c++} END{print c+0}' "$ex")
  say "copyforward: exclude_lines $n_ex"
  st=$(git -C "$d" status --porcelain=v1 --untracked-files=all 2>/dev/null) || { cleanw; die2 "status_failed"; }
  # same allowance as guard-swapped-193.sh full: the four workstream handoff files and plain files
  # under the 193 phase folder may differ (counted); anything else is a dirty tree
  local line mp n_allowed=0 n_bad=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    mp=${line#???}
    case $mp in *" -> "*) mp=${mp##* -> } ;; esac
    case $mp in
      "$WS/STATE.md"|"$WS/ROADMAP.md"|"$WS/REQUIREMENTS.md"|"$WS/.continue-here.md") n_allowed=$((n_allowed + 1)) ;;
      "$WS/phases/193-cleanup-and-new-working-rules/"*) n_allowed=$((n_allowed + 1)) ;;
      *) n_bad=$((n_bad + 1)) ;;
    esac
  done <<EOF4
$st
EOF4
  [ "$n_bad" -eq 0 ] || { cleanw; die1 "tree_dirty"; }
  say "copyforward: allowed_changes $n_allowed"
  cleanw
  say "copyforward: result pass"
}

do_runtime_backup() {
  local f rel n=0 list="" cur sums name sha mode
  [ -d "$INV" ] || die2 "backup root missing"
  mkw
  cur="$W/cur.files"
  : > "$cur"
  for rel in $(printf '%s\n' "$RT_PATHS" | tr '\n' ' '); do
    f="$SRC/$rel"
    [ -L "$f" ] && { cleanw; die2 "symlink_source"; }
    [ -f "$f" ] || continue
    printf '%s %s %s\n' "$(sha_of "$f")" "$(stat -f %Lp "$f")" "$rel" >> "$cur"
    list="$list $rel"
    n=$((n + 1))
  done
  [ "$n" -ge 2 ] || { cleanw; die1 "runtime_files_missing"; }
  if [ -e "$INV/post189-runtime.tar" ]; then
    if [ -f "$INV/post189-runtime.files" ] && cmp -s "$cur" "$INV/post189-runtime.files"; then
      cleanw
      say "copyforward: runtime already current"
      say "copyforward: result pass"
      return 0
    fi
    cleanw
    die1 "runtime_tar_exists"
  fi
  [ ! -e "$INV/SHA256SUMS.193b" ] || { cleanw; die1 "sums_exist"; }
  # shellcheck disable=SC2086
  (cd "$SRC" && COPYFILE_DISABLE=1 tar -cf "$INV/post189-runtime.tar" $list) || { cleanw; die2 "tar_failed"; }
  cp "$cur" "$INV/post189-runtime.files" || { cleanw; die2 "write_failed"; }
  chmod 600 "$INV/post189-runtime.tar" "$INV/post189-runtime.files"
  sums="$INV/SHA256SUMS.193b"
  (cd "$INV" && shasum -a 256 post189-runtime.tar post189-runtime.files) > "$sums" || { cleanw; die2 "sums_failed"; }
  chmod 600 "$sums"
  printf '%s\n' "$(awk 'NF{c++} END{print c+0}' "$sums")" > "$INV/SHA256SUMS.193b.count"
  chmod 600 "$INV/SHA256SUMS.193b.count"
  if ! (cd "$INV" && shasum -a 256 -c SHA256SUMS.193b >/dev/null 2>&1); then cleanw; die1 "sums_check"; fi
  [ "$(cat "$INV/SHA256SUMS.193b.count")" -eq 2 ] || { cleanw; die1 "sums_count"; }
  # restore check: extract to scratch and compare
  mkdir -p -m 700 "$W/rc" || exit 2
  COPYFILE_DISABLE=1 tar -xpf "$INV/post189-runtime.tar" -C "$W/rc" >/dev/null 2>&1 || { cleanw; die1 "restore_check"; }
  while read -r sha mode name; do
    [ "$(sha_of "$W/rc/$name")" = "$sha" ] || { cleanw; die1 "restore_check"; }
  done < "$cur"
  cleanw
  say "copyforward: runtime backed up $n"
  say "copyforward: result pass"
}

# ---------------------------------------------------------------- self-test
st_mk_tar() { # TARFILE FILESFILE ROOTDIR NAME...
  local tf=$1 ff=$2 root=$3 nm
  shift 3
  (cd "$root" && COPYFILE_DISABLE=1 tar -cf "$tf" "$@") || return 1
  : > "$ff"
  for nm in "$@"; do
    printf '%s %s %s\n' "$(sha_of "$root/$nm")" "$(stat -f %Lp "$root/$nm")" "$nm" >> "$ff"
  done
}

st_fixture() { # BASE : builds a parent with backup inventory, a recovery-like source and a target repo
  local b=$1 inv r
  inv="$b/crosswake-candidate-backup/inventory-189"
  r="$b/root"
  mkdir -p -m 700 "$inv" "$r/.claude/worktrees" "$r/.gsd/runtime" "$r/.expert" "$r/cache" "$r/envs" "$r/$WS"
  printf '{"a":1}\n' > "$r/.claude/settings.local.json"
  printf '{"w":1}\n' > "$r/.claude/worktrees/x.json"
  printf 'x\n' > "$r/.claude/scheduled_tasks.lock"
  printf 'x\n' > "$r/.DS_Store"
  printf 'g\n' > "$r/.gsd/CODEBASE.md"
  printf '{"s":1}\n' > "$r/.gsd/runtime/write-gate-state.json"
  printf 'e\n' > "$r/.expert/e.txt"
  printf 'c\n' > "$r/cache/c.txt"
  printf 'old\n' > "$r/.gsd/overlay.md"
  printf 'SECRETVALUE=1\n' > "$r/envs/$ST_ENVNAME"
  chmod 600 "$r/envs/$ST_ENVNAME"
  printf '{"cfg":1}\n' > "$r/$WS/config.json"
  printf '{"st":1}\n' > "$r/$WS/state.json"
  st_mk_tar "$inv/ignored-keep.tar" "$inv/ignored-keep.files" "$r" .claude/settings.local.json .claude/worktrees/x.json .claude/scheduled_tasks.lock .DS_Store .gsd/CODEBASE.md .gsd/runtime/write-gate-state.json .expert/e.txt cache/c.txt .gsd/overlay.md || return 1
  st_mk_tar "$inv/env-local.tar" "$inv/env-local.files" "$r" "envs/$ST_ENVNAME" || return 1
  printf 'new\n' > "$r/.gsd/overlay.md"
  printf 'unrelated\n' > "$r/cache/other.md"
  st_mk_tar "$inv/post189-dirty.tar" "$inv/post189-dirty.files" "$r" .gsd/overlay.md cache/other.md || return 1
  st_mk_tar "$inv/post189-runtime.tar" "$inv/post189-runtime.files" "$r" "$WS/config.json" "$WS/state.json" || return 1
  # target repo on main with ignore rules
  mkdir -p "$b/target"
  git init -q -b main "$b/target" >/dev/null 2>&1 || return 1
  printf '.claude/\n.gsd/\nenvs/\n' > "$b/target/.gitignore"
  git -C "$b/target" add .gitignore >/dev/null 2>&1 || return 1
  git -C "$b/target" -c user.name=t -c user.email=t@example.invalid commit -q -m init >/dev/null 2>&1 || return 1
  return 0
}

st_run() { # BASE MODE [ARGS...] : run this script against the fixture with overrides
  local b=$1
  shift
  SELFTEST_193=1 P193_PARENT="$b" P193_RUN="$b/run" CF193_SRC="$b/root" bash "$HERE/copyforward-193.sh" "$@" 2>&1
}

do_selftest() {
  local pass=0 total=0 base b out rc nm ENVFRAG
  local _t
  _t=$(cd "${TMPDIR:-/nonexistent}" && pwd -P) || exit 2
  [ -n "$_t" ] || exit 2
  ST_ENVNAME=".en""v.zz193""planted"
  ENVFRAG="zz193""planted"
  ctl() { # NAME EXPECT(0=ok,1=fail) ACTUALRC
    total=$((total + 1))
    if [ "$2" = ok ] && [ "$3" -eq 0 ]; then pass=$((pass + 1))
    elif [ "$2" = fail ] && [ "$3" -ne 0 ]; then pass=$((pass + 1))
    else echo "selftest copyforward-193: unexpected result in control $1" >&2; fi
  }
  mk() { base=$(mktemp -d "$_t/cw193-st.XXXXXX") || exit 2; case "$base" in "$ST193_PREFIX"*) : ;; *) echo "selftest copyforward-193: fixture prefix" >&2; exit 2 ;; esac; mkdir -p -m 700 "$base/run"; st_fixture "$base" || { echo "selftest copyforward-193: fixture failed" >&2; exit 2; }; }
  rmfx() { case "$base" in "$ST193_PREFIX"*) rm -rf "$base" ;; esac; }

  # 1 clean stage, apply, verify pass; output holds no planted name; staging gone
  mk
  out=$(st_run "$base" stage "$base/run/s1"); rc=$?
  ctl clean-stage ok $rc
  case $out in *"settings 4 env 1 runtime 2"*) rc=0 ;; *) rc=1 ;; esac
  ctl stage-counts ok $rc
  out2=$(st_run "$base" apply "$base/target"); rc=$?
  ctl clean-apply ok $rc
  out3=$(st_run "$base" verify "$base/target"); rc=$?
  ctl clean-verify ok $rc
  # overlay applied (dirty copy wins), non-allowlist and caches absent, env mode 600, runtime excluded
  if [ "$(cat "$base/target/.gsd/overlay.md")" = new ] && [ ! -e "$base/target/cache" ] && [ ! -e "$base/target/.expert" ] && [ ! -e "$base/target/.claude/worktrees" ] && [ ! -e "$base/target/.DS_Store" ] && [ "$(stat -f %Lp "$base/target/envs/$ST_ENVNAME")" = 600 ] && [ ! -e "$base/run/cf-apply" ]; then rc=0; else rc=1; fi
  ctl overlay-allowlist-mode ok $rc
  # privacy: no planted name or content in any output
  case "$out$out2$out3" in *"$ENVFRAG"*|*SECRETVALUE*) rc=1 ;; *) rc=0 ;; esac
  ctl privacy-output ok $rc
  rmfx

  # 2 empty allowlist
  mk
  rm "$base/crosswake-candidate-backup/inventory-189/ignored-keep.tar"
  (cd "$base/root" && COPYFILE_DISABLE=1 tar -cf "$base/crosswake-candidate-backup/inventory-189/ignored-keep.tar" cache/c.txt)
  printf '%s 644 cache/c.txt\n' "$(sha_of "$base/root/cache/c.txt")" > "$base/crosswake-candidate-backup/inventory-189/ignored-keep.files"
  rm -f "$base"/crosswake-candidate-backup/inventory-189/post189-dirty.*
  out=$(st_run "$base" stage "$base/run/s2"); rc=$?
  ctl empty-allowlist fail $rc
  case $out in *allowlist_empty*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rmfx

  # 3 env member recorded as mode 644 is restored tightened to 600 (reported), and a 644 env in a checkout fails verify
  mk
  chmod 644 "$base/root/envs/$ST_ENVNAME"
  st_mk_tar "$base/crosswake-candidate-backup/inventory-189/env-local.tar" "$base/crosswake-candidate-backup/inventory-189/env-local.files" "$base/root" "envs/$ST_ENVNAME"
  out=$(st_run "$base" apply "$base/target"); rc=$?
  case $out in *"env_tightened 1"*) : ;; *) rc=1 ;; esac
  if [ "$(stat -f %Lp "$base/target/envs/$ST_ENVNAME")" != 600 ]; then rc=1; fi
  ctl env-644-tightened ok $rc
  chmod 644 "$base/target/envs/$ST_ENVNAME"
  out=$(st_run "$base" verify "$base/target"); rc=$?
  ctl env-mode-644-in-checkout fail $rc
  case $out in *mode_mismatch*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  case $out in *"$ENVFRAG"*) pass=$((pass - 1)) ;; esac
  rmfx

  # 3a env members recorded under the original root (as the real 189 env tar is) land repo-relative:
  # apply then verify pass, no stray root folder in the target, env mode 600
  mk
  (cd / && COPYFILE_DISABLE=1 tar -cf "$base/crosswake-candidate-backup/inventory-189/env-local.tar" "${base#/}/root/envs/$ST_ENVNAME") || exit 2
  printf '%s 600 %s\n' "$(sha_of "$base/root/envs/$ST_ENVNAME")" "${base#/}/root/envs/$ST_ENVNAME" > "$base/crosswake-candidate-backup/inventory-189/env-local.files"
  out=$(st_run "$base" apply "$base/target"); rc=$?
  ctl env-rooted-apply ok $rc
  out2=$(st_run "$base" verify "$base/target"); rc=$?
  if [ -n "$(git -C "$base/target" status --porcelain=v1 --untracked-files=all)" ] || [ "$(stat -f %Lp "$base/target/envs/$ST_ENVNAME" 2>/dev/null)" != 600 ]; then rc=1; fi
  ctl env-rooted-verify ok $rc
  case "$out$out2" in *"$ENVFRAG"*|*SECRETVALUE*) pass=$((pass - 1)) ;; esac
  # a stray folder outside the allowance (as the rooted bug left) still fails verify
  mkdir -p "$base/target/Us""ers/x" && printf 's\n' > "$base/target/Us""ers/x/s"
  out=$(st_run "$base" verify "$base/target"); rc=$?
  ctl stray-outside-allowance fail $rc
  case $out in *tree_dirty*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rm -rf "$base/target/Users"
  # a change under the 193 phase folder is allowed and counted
  mkdir -p "$base/target/$WS/phases/193-cleanup-and-new-working-rules" && printf 'p\n' > "$base/target/$WS/phases/193-cleanup-and-new-working-rules/p.txt"
  out=$(st_run "$base" verify "$base/target"); rc=$?
  case $out in *"allowed_changes 1"*) : ;; *) rc=1 ;; esac
  ctl phase-folder-allowed ok $rc
  rmfx

  # 3b settings member with a wrong recorded mode fails
  mk
  awk 'NR==1{ $2="640" } {print}' "$base/crosswake-candidate-backup/inventory-189/ignored-keep.files" > "$base/f.tmp" && mv "$base/f.tmp" "$base/crosswake-candidate-backup/inventory-189/ignored-keep.files"
  out=$(st_run "$base" stage "$base/run/s3b"); rc=$?
  ctl settings-mode-mismatch fail $rc
  case $out in *mode_mismatch*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rmfx

  # 4 hash mismatch
  mk
  awk 'NR==1{ $1="ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff" } {print}' "$base/crosswake-candidate-backup/inventory-189/ignored-keep.files" > "$base/f.tmp" && mv "$base/f.tmp" "$base/crosswake-candidate-backup/inventory-189/ignored-keep.files"
  out=$(st_run "$base" stage "$base/run/s4"); rc=$?
  ctl hash-mismatch fail $rc
  case $out in *hash_mismatch*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rmfx

  # 5 runtime member outside the runtime list is refused
  mk
  mkdir -p "$base/root/other"
  printf 'x\n' > "$base/root/other/evil.txt"
  st_mk_tar "$base/crosswake-candidate-backup/inventory-189/post189-runtime.tar" "$base/crosswake-candidate-backup/inventory-189/post189-runtime.files" "$base/root" other/evil.txt
  out=$(st_run "$base" apply "$base/target"); rc=$?
  ctl outside-allowlist fail $rc
  case $out in *path_outside*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  [ ! -e "$base/target/other" ] || pass=$((pass - 1))
  rmfx

  # 6 env name or content in output would be caught: planted fragment in a forced failure word check
  mk
  out=$(st_run "$base" stage "$base/run/s6"); rc=$?
  case "$out" in *"$ENVFRAG"*|*SECRETVALUE*) rc=1 ;; *) rc=0 ;; esac
  ctl privacy-stage ok $rc
  rmfx

  # 7 apply into a non-git folder
  mk
  mkdir -p "$base/plain"
  out=$(st_run "$base" apply "$base/plain"); rc=$?
  ctl apply-non-git fail $rc
  rmfx

  # 8 apply on a branch other than main
  mk
  git -C "$base/target" checkout -q -b other >/dev/null 2>&1
  out=$(st_run "$base" apply "$base/target"); rc=$?
  ctl apply-not-main fail $rc
  rmfx

  # 9 verify with a missing exclude line
  mk
  st_run "$base" apply "$base/target" >/dev/null
  : > "$base/target/.git/info/exclude"
  out=$(st_run "$base" verify "$base/target"); rc=$?
  ctl verify-missing-exclude fail $rc
  case $out in *exclude_missing*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rmfx

  # 10 verify with a dirty tree
  mk
  st_run "$base" apply "$base/target" >/dev/null
  printf 'stray\n' > "$base/target/stray.txt"
  out=$(st_run "$base" verify "$base/target"); rc=$?
  ctl verify-dirty-tree fail $rc
  case $out in *tree_dirty*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rmfx

  # 11 verify with a changed file
  mk
  st_run "$base" apply "$base/target" >/dev/null
  printf 'changed\n' > "$base/target/.gsd/CODEBASE.md"
  out=$(st_run "$base" verify "$base/target"); rc=$?
  ctl verify-hash-changed fail $rc
  rmfx

  # 12 runtime-backup: fresh pass, repeat is current, changed content refused (fixture only)
  mk
  inv="$base/crosswake-candidate-backup/inventory-189"
  rm -f "$inv/post189-runtime.tar" "$inv/post189-runtime.files"
  out=$(st_run "$base" runtime-backup); rc=$?
  ctl runtime-backup-fresh ok $rc
  out=$(st_run "$base" runtime-backup); rc=$?
  case $out in *"runtime already current"*) : ;; *) rc=1 ;; esac
  ctl runtime-backup-repeat ok $rc
  printf '{"cfg":2}\n' > "$base/root/$WS/config.json"
  out=$(st_run "$base" runtime-backup); rc=$?
  ctl runtime-backup-changed fail $rc
  rmfx

  # 13 symlink source refused by runtime-backup
  mk
  inv="$base/crosswake-candidate-backup/inventory-189"
  rm -f "$inv/post189-runtime.tar" "$inv/post189-runtime.files"
  rm "$base/root/$WS/state.json"; ln -s config.json "$base/root/$WS/state.json"
  out=$(st_run "$base" runtime-backup); rc=$?
  ctl runtime-backup-symlink fail $rc
  case $out in *symlink_source*) : ;; *) echo "selftest copyforward-193: wrong word" >&2; pass=$((pass - 1)) ;; esac
  rmfx

  # 14 stage into a non-empty folder refused
  mk
  mkdir -p "$base/run/s14"; printf 'x\n' > "$base/run/s14/f"
  out=$(st_run "$base" stage "$base/run/s14"); rc=$?
  ctl stage-not-empty fail $rc
  rmfx

  # 15 static forbidden tokens
  local tok bad=0 gt="git" toks
  toks="$gt add|$gt commit|$gt push|$gt checkout|$gt reset|$gt clean|$gt stash|$gt branch -D|$gt worktree|$gt fetch"
  if sed '/^# -* self-test$/,$d' "$HERE/copyforward-193.sh" | grep -Eq -- "$toks"; then bad=1; fi
  ctl static-forbidden-tokens ok $bad

  say "selftest copyforward-193: controls $pass of $total as expected"
  [ "$pass" -eq "$total" ]
}

case ${1:-} in
  --self-test) do_selftest; exit $? ;;
  stage) [ "$#" -eq 2 ] || die2 "usage"; do_stage "$2"; exit 0 ;;
  apply) [ "$#" -eq 2 ] || die2 "usage"; do_apply "$2"; exit 0 ;;
  verify) [ "$#" -eq 2 ] || die2 "usage"; do_verify "$2"; exit 0 ;;
  runtime-backup) do_runtime_backup; exit 0 ;;
  *) die2 "usage" ;;
esac
