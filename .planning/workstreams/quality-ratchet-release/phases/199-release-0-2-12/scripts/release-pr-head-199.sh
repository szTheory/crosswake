#!/usr/bin/env bash
# Phase 199 release-PR-head predicate: is this release PR head a pure, untouched Release Please commit?
# One-time release reconciliation script kept in phase evidence. Not a CI gate, not in the scanner roster.
# Needs git and jq (and gh in live mode). Bash 3.2 compatible.
#
# usage (live):    release-pr-head-199.sh --pr N --title T --package P [--package P ...]
# usage (fixture): release-pr-head-199.sh --base OID --head OID --title T --package P [--package P ...]
#
# Exit 0 = PASS, 1 = FAIL (a named reason), 2 = ERROR (could not evaluate; never a pass).
# One line on stdout:
#   release-pr-head: pr=<n|fixture> head=<40hex> base=<40hex> commits=<n> authors=<logins> paths=<k> managed=<m> verdict=<PASS|FAIL reason=<r>|ERROR reason=<r>>
# Author logins are printed as a value and are never read by any condition.
# Every line that enforces one named rule ends with a trailing "rule:" comment so that the controls'
# mutant runs can delete one rule at a time.
set -euo pipefail

PR_LABEL=fixture
HEAD=0000000000000000000000000000000000000000
BASE=0000000000000000000000000000000000000000
COMMITS=0
AUTHORS=-
PATHS=0
MANAGED=0

prefix() {
  printf 'release-pr-head: pr=%s head=%s base=%s commits=%s authors=%s paths=%s managed=%s' \
    "$PR_LABEL" "$HEAD" "$BASE" "$COMMITS" "$AUTHORS" "$PATHS" "$MANAGED"
}
fail() { prefix; printf ' verdict=FAIL reason=%s\n' "$1"; exit 1; }
die2() { prefix; printf ' verdict=ERROR reason=%s\n' "$1"; exit 2; }

PRN=""
BASE_ARG=""
HEAD_ARG=""
TITLE=""
HAVE_TITLE=0
PKGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --pr) [ $# -ge 2 ] || die2 usage; PRN=$2; shift 2 ;;
    --base) [ $# -ge 2 ] || die2 usage; BASE_ARG=$2; shift 2 ;;
    --head) [ $# -ge 2 ] || die2 usage; HEAD_ARG=$2; shift 2 ;;
    --title) [ $# -ge 2 ] || die2 usage; TITLE=$2; HAVE_TITLE=1; shift 2 ;;
    --package) [ $# -ge 2 ] || die2 usage; PKGS+=("$2"); shift 2 ;;
    *) die2 usage ;;
  esac
done
[ "$HAVE_TITLE" -eq 1 ] || die2 usage
[ "${#PKGS[@]}" -ge 1 ] || die2 usage
if [ -n "$PRN" ]; then
  [ -z "$BASE_ARG" ] && [ -z "$HEAD_ARG" ] || die2 usage
else
  [ -n "$BASE_ARG" ] && [ -n "$HEAD_ARG" ] || die2 usage
fi

command -v git >/dev/null 2>&1 || die2 tool_unavailable
command -v jq >/dev/null 2>&1 || die2 tool_unavailable
WORK=$(mktemp -d) || die2 tool_unavailable
trap 'rm -rf "$WORK"' EXIT

PR_COMMITS=""
PR_FIRST=""
if [ -n "$PRN" ]; then
  command -v gh >/dev/null 2>&1 || die2 tool_unavailable
  PR_LABEL=$PRN
  gh pr view "$PRN" --json headRefOid,baseRefOid,commits > "$WORK/pr.json" 2> "$WORK/gh.err" || die2 gh_read_failed
  HEAD=$(jq -r '.headRefOid // empty' "$WORK/pr.json") || die2 gh_read_failed
  BASE=$(jq -r '.baseRefOid // empty' "$WORK/pr.json") || die2 gh_read_failed
  PR_COMMITS=$(jq -r '.commits | length' "$WORK/pr.json") || die2 gh_read_failed
  PR_FIRST=$(jq -r '.commits[0].oid // empty' "$WORK/pr.json") || die2 gh_read_failed
  AUTHORS=$(jq -r '[.commits[].authors[].login] | unique | join(",")' "$WORK/pr.json") || die2 gh_read_failed
  [ -n "$AUTHORS" ] || AUTHORS=-
  case "$HEAD" in [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*) : ;; *) die2 gh_read_failed ;; esac
  git fetch -q origin "$HEAD" "$BASE" 2> "$WORK/fetch.err" || die2 fetch_failed
else
  HEAD=$HEAD_ARG
  BASE=$BASE_ARG
fi
[ "${#HEAD}" -eq 40 ] && [ "${#BASE}" -eq 40 ] || die2 bad_object_id
git cat-file -e "$HEAD^{commit}" 2> /dev/null || die2 object_missing
git cat-file -e "$BASE^{commit}" 2> /dev/null || die2 object_missing

COMMITS=$(git rev-list --count "$BASE..$HEAD") || die2 object_missing

# Managed set, derived from release-please-config.json read at the BASE commit.
git show "$BASE:release-please-config.json" > "$WORK/cfg.json" 2> /dev/null || die2 config_unreadable
jq -e . "$WORK/cfg.json" > /dev/null 2>&1 || die2 config_unreadable

pjoin() { if [ "$1" = "." ]; then printf '%s\n' "$2"; else printf '%s/%s\n' "$1" "$2"; fi; }

: > "$WORK/managed.raw"
: > "$WORK/changelogs.tsv"
printf '%s\n' .release-please-manifest.json >> "$WORK/managed.raw"
for P in "${PKGS[@]}"; do
  jq -e --arg p "$P" '.packages[$p]' "$WORK/cfg.json" > /dev/null 2>&1 || die2 "unknown_package:$P"
  rt=$(jq -r --arg p "$P" '.packages[$p]["release-type"] // empty' "$WORK/cfg.json") || die2 config_unreadable
  case "$rt" in
    elixir) pjoin "$P" mix.exs >> "$WORK/managed.raw" ;;
    simple) pjoin "$P" version.txt >> "$WORK/managed.raw" ;;
    *) die2 "unsupported_release_type:$P" ;;
  esac
  skip=$(jq -r --arg p "$P" '.packages[$p]["skip-changelog"] // false' "$WORK/cfg.json") || die2 config_unreadable
  if [ "$skip" != "true" ]; then
    clname=$(jq -r --arg p "$P" '.packages[$p]["changelog-path"] // "CHANGELOG.md"' "$WORK/cfg.json") || die2 config_unreadable
    clpath=$(pjoin "$P" "$clname")
    printf '%s\n' "$clpath" >> "$WORK/managed.raw"
    printf '%s\t%s\n' "$clpath" "$P" >> "$WORK/changelogs.tsv"
  fi
  jq -r --arg p "$P" '.packages[$p]["extra-files"] // [] | .[] | if type == "string" then . else .path end' "$WORK/cfg.json" >> "$WORK/managed.raw" || die2 config_unreadable
done
sort -u "$WORK/managed.raw" > "$WORK/managed.txt"
MANAGED=$(wc -l < "$WORK/managed.txt" | tr -d ' ')

git diff --name-only --no-renames "$BASE" "$HEAD" > "$WORK/changed.txt" || die2 object_missing
PATHS=$(wc -l < "$WORK/changed.txt" | tr -d ' ')

# 1. exactly one commit, and it is the head
if [ -n "$PR_COMMITS" ]; then
  { [ "$PR_COMMITS" = 1 ] && [ "$PR_FIRST" = "$HEAD" ]; } || fail commit_count
fi
[ "$COMMITS" = 1 ] || fail commit_count

# 2. the head's only parent is the base
parents=$(git rev-parse "$HEAD^@") || die2 object_missing
[ "$parents" = "$BASE" ] || fail parent_not_base

# 3. headline
subject=$(git log -1 --format=%s "$HEAD") || die2 object_missing
[ "$subject" = "$TITLE" ] || fail headline_mismatch

# 4. the manifest changed
grep -qxF -- .release-please-manifest.json "$WORK/changed.txt" || fail manifest_unchanged

# 5. every changed path is in the managed set
outside=$({ grep -vxFf "$WORK/managed.txt" "$WORK/changed.txt" || true; } | paste -sd, -)
[ -z "$outside" ] || fail "path_outside_managed_set:$outside"

# 6. form, read before any line content (a mode-only, type, added, deleted or binary change has no -U0 line)
bad_mode=$(git diff --raw --no-renames --no-abbrev "$BASE" "$HEAD" | awk -F'\t' '{ split($1, f, " "); if (f[5] != "M" || substr(f[1], 2) != f[2]) { printf "%s%s", (n++ ? "," : ""), $2 } }')
[ -z "$bad_mode" ] || fail "mode_or_type_change:$bad_mode" # rule:mode
bad_bin=$(git diff --numstat --no-renames "$BASE" "$HEAD" | awk -F'\t' '$1 == "-" || $2 == "-" { printf "%s%s", (n++ ? "," : ""), $3 }')
[ -z "$bad_bin" ] || fail "binary_change:$bad_bin" # rule:binary

# 7. each named package's version differs between base and head
OLDV=()
NEWV=()
for P in "${PKGS[@]}"; do
  ov=$(git show "$BASE:.release-please-manifest.json" | jq -r --arg p "$P" '.[$p] // empty') || die2 manifest_unreadable
  nv=$(git show "$HEAD:.release-please-manifest.json" | jq -r --arg p "$P" '.[$p] // empty') || die2 manifest_unreadable
  { [ -n "$ov" ] && [ -n "$nv" ]; } || die2 manifest_unreadable
  [ "$ov" != "$nv" ] || fail "version_not_bumped:$P"
  OLDV+=("$ov")
  NEWV+=("$nv")
done

# 8. the final byte of every changed path is unchanged (a dropped final newline otherwise looks like an identical text pair)
while IFS= read -r p; do
  b=$(git cat-file blob "$BASE:$p" | tail -c 1 | od -An -tx1) || die2 object_missing
  h=$(git cat-file blob "$HEAD:$p" | tail -c 1 | od -An -tx1) || die2 object_missing
  [ "$b" = "$h" ] || fail "eol_change:$p" # rule:eol
done < "$WORK/changed.txt"

cut -f1 "$WORK/changelogs.tsv" > "$WORK/cl_paths.txt"

split_diff() { # BODYFILE REMFILE ADDFILE
  awk -v rem="$2" -v add="$3" 'BEGIN { h = 0; printf "" > rem; printf "" > add }
    /^@@/ { h = 1; next }
    h == 0 { next }
    /^-/ { print substr($0, 2) > rem; next }
    /^\+/ { print substr($0, 2) > add }' "$1"
}

apply_versions() { # LINE -> LINE with each named package old version replaced by its new one
  local e=$1 k=0 o n
  while [ "$k" -lt "${#OLDV[@]}" ]; do
    o=${OLDV[$k]}
    n=${NEWV[$k]}
    e=${e//"$o"/$n}
    k=$((k + 1))
  done
  printf '%s' "$e"
}

content_check() { # PATH: removed and added lines pair up as pure version substitutions
  local p=$1 r a e
  git diff -U0 --no-color --no-ext-diff --no-textconv "$BASE" "$HEAD" -- "$p" > "$WORK/body.txt" || return 1
  split_diff "$WORK/body.txt" "$WORK/rem.txt" "$WORK/add.txt"
  [ "$(wc -l < "$WORK/rem.txt" | tr -d ' ')" -eq "$(wc -l < "$WORK/add.txt" | tr -d ' ')" ] || return 1
  exec 3< "$WORK/rem.txt" 4< "$WORK/add.txt"
  while IFS= read -r r <&3 && IFS= read -r a <&4; do
    e=$(apply_versions "$r")
    if [ "$a" != "$e" ]; then
      exec 3<&- 4<&-
      return 1
    fi
  done
  exec 3<&- 4<&-
  return 0
}

# 9. a changed path that is not a named package's changelog: version substitution lines only
while IFS= read -r p; do
  if grep -qxF -- "$p" "$WORK/cl_paths.txt"; then continue; fi
  content_check "$p" || fail "non_version_change:$p" # rule:content
done < "$WORK/changed.txt"

render_desc() { # DESCRIPTION -> Release Please rendering (htmlEscape outside single-backtick spans, #N links)
  DESC=$1 awk 'BEGIN {
    s = ENVIRON["DESC"]; out = ""; n = length(s); i = 1
    while (i <= n) {
      c = substr(s, i, 1)
      if (c == "`") {
        j = index(substr(s, i + 1), "`")
        if (j > 0) { out = out substr(s, i, j + 1); i += j + 1; continue }
      }
      if (c == "<") { out = out "&lt;" }
      else if (c == ">") { out = out "&gt;" }
      else if (c == "#") {
        prev = (i > 1) ? substr(s, i - 1, 1) : ""
        k = i + 1
        while (k <= n && substr(s, k, 1) ~ /[0-9]/) k++
        if (k > i + 1 && prev !~ /[A-Za-z0-9_]/) {
          num = substr(s, i + 1, k - i - 1)
          out = out "[#" num "](https://github.com/szTheory/crosswake/issues/" num ")"
          i = k
          continue
        }
        out = out c
      } else { out = out c }
      i++
    }
    printf "%s", out
  }'
}

section_of_type() { # TYPE -> section name of the non-hidden changelog-sections entry for TYPE (package P, else top level)
  jq -r --arg p "$P" --arg t "$1" '(.packages[$p]["changelog-sections"] // ."changelog-sections" // []) | map(select(.hidden != true and .type == $t)) | .[0].section // empty' "$WORK/cfg.json"
}

bullet_rendered() { # SECTION BULLET: the bullet is Release Please's exact rendering of a real commit of that section's type
  local sec=$1 bullet=$2 re hre text short oid touched msg l t scope desc rendered exp
  re='^\* (.+) \(\[([0-9a-f]{7})\]\(https://github\.com/szTheory/crosswake/commit/([0-9a-f]{40})\)\)$'
  [[ $bullet =~ $re ]] || return 1
  text=${BASH_REMATCH[1]}
  short=${BASH_REMATCH[2]}
  oid=${BASH_REMATCH[3]}
  [ -n "$text" ] || return 1
  [ "$short" = "${oid:0:7}" ] || return 1
  git cat-file -e "$oid^{commit}" 2> /dev/null || return 1
  git merge-base --is-ancestor "$oid" "$BASE" || return 1
  touched=$(git diff-tree --root --no-commit-id -r --name-only -m --first-parent "$oid" -- "$P") || return 1
  [ -n "$touched" ] || return 1
  msg=$(git log -1 --format=%B "$oid") || return 1
  hre='^([a-z]+)(\(([^)]*)\))?(!)?: (.+)$'
  while IFS= read -r l; do
    [[ $l =~ $hre ]] || continue
    t=${BASH_REMATCH[1]}
    scope=${BASH_REMATCH[3]}
    desc=${BASH_REMATCH[5]}
    [ "$(section_of_type "$t")" = "$sec" ] || continue # rule:type
    rendered=$(render_desc "$desc")
    if [ -n "$scope" ]; then
      exp="* **$scope:** $rendered ([$short](https://github.com/szTheory/crosswake/commit/$oid))"
    else
      exp="* $rendered ([$short](https://github.com/szTheory/crosswake/commit/$oid))"
    fi
    if [ "$exp" = "$bullet" ]; then return 0; fi
  done <<< "$msg"
  return 1
}

grammar_ok() { # ADDFILE OLD NEW COMPONENT ALLOWEDFILE
  local add=$1 old=$2 new=$3 comp=$4 allowed=$5 line first=1 sec="" seen="|" nb=0 pre dre
  pre="## [$new](https://github.com/szTheory/crosswake/compare/$comp-v$old...$comp-v$new) ("
  dre='^[0-9]{4}-[0-9]{2}-[0-9]{2}\)$'
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if [ "$first" -eq 1 ]; then
      first=0
      [ "${line:0:${#pre}}" = "$pre" ] || return 1
      [[ ${line:${#pre}} =~ $dre ]] || return 1
      continue
    fi
    case "$line" in
      "### "*)
        if [ -n "$sec" ] && [ "$nb" -lt 1 ]; then return 1; fi
        sec=${line#"### "}
        grep -qxF -- "$sec" "$allowed" || return 1
        case "$seen" in *"|$sec|"*) return 1 ;; esac
        seen="$seen$sec|"
        nb=0
        ;;
      "* "*)
        [ -n "$sec" ] || return 1
        nb=$((nb + 1))
        ;;
      *) return 1 ;;
    esac
  done < "$add"
  [ "$first" -eq 0 ] || return 1
  [ -n "$sec" ] && [ "$nb" -ge 1 ] || return 1
  return 0
}

position_ok() { # N L BASEFILE: inserted directly above the first version heading
  local n=$1 l=$2 basecl=$3
  [ -n "$l" ] || return 1
  [ "$n" -lt "$l" ] || return 1
  if [ $((n + 1)) -le $((l - 1)) ]; then
    [ "$(sed -n "$((n + 1)),$((l - 1))p" "$basecl" | grep -c . || true)" -eq 0 ] || return 1
  fi
  return 0
}

changelog_check() { # PATH PACKAGE
  local path=$1 P=$2 hdr re N L k idx=-1 comp oldv newv sec bullet oid dup
  git diff -U0 --no-color --no-ext-diff --no-textconv "$BASE" "$HEAD" -- "$path" > "$WORK/clbody.txt" || die2 object_missing
  git show "$BASE:$path" > "$WORK/clbase.txt" 2> /dev/null || die2 changelog_unreadable
  # (a) exactly one hunk, a pure insertion
  hdr=$(awk 'BEGIN { h = 0; n = 0; bad = 0 }
    /^@@/ { n++; if (n == 1) hdr = $0; h = 1; next }
    h == 0 { next }
    /^\+/ { next }
    { bad = 1 }
    END { if (n == 1 && !bad) print hdr; else print "BAD" }' "$WORK/clbody.txt")
  [ "$hdr" != BAD ] || fail "non_version_change:$path"
  re='^@@ -([0-9]+),0 \+[0-9]+(,[0-9]+)? @@'
  [[ $hdr =~ $re ]] || fail "non_version_change:$path"
  N=${BASH_REMATCH[1]}
  split_diff "$WORK/clbody.txt" "$WORK/clrem.txt" "$WORK/cladd.txt"
  # (b) position
  L=$(grep -n -m1 '^## \[[0-9]' "$WORK/clbase.txt" | cut -d: -f1 || true)
  position_ok "$N" "$L" "$WORK/clbase.txt" || fail "changelog_position:$path" # rule:position
  # (c) grammar
  k=0
  while [ "$k" -lt "${#PKGS[@]}" ]; do
    if [ "${PKGS[$k]}" = "$P" ]; then idx=$k; fi
    k=$((k + 1))
  done
  [ "$idx" -ge 0 ] || die2 "unknown_package:$P"
  oldv=${OLDV[$idx]}
  newv=${NEWV[$idx]}
  comp=$(jq -r --arg p "$P" '.packages[$p].component // empty' "$WORK/cfg.json") || die2 config_unreadable
  [ -n "$comp" ] || comp=${P##*/}
  jq -r --arg p "$P" '(.packages[$p]["changelog-sections"] // ."changelog-sections" // []) | map(select(.hidden != true)) | .[].section' "$WORK/cfg.json" > "$WORK/allowed.txt" || die2 changelog_sections_unreadable
  [ -s "$WORK/allowed.txt" ] || die2 changelog_sections_unreadable
  grammar_ok "$WORK/cladd.txt" "$oldv" "$newv" "$comp" "$WORK/allowed.txt" || fail "changelog_grammar:$path" # rule:grammar
  # (d) no bullet twice
  dup=$({ grep '^\* ' "$WORK/cladd.txt" || true; } | sort | uniq -d | wc -l | tr -d ' ')
  [ "$dup" -eq 0 ] || fail "changelog_duplicate_bullet:$path" # rule:duplicate
  awk '/^### / { sec = substr($0, 5) } /^\* / { printf "%s\t%s\n", (sec == "" ? "-" : sec), $0 }' "$WORK/cladd.txt" > "$WORK/clbullets.tsv"
  # (e) rendering
  while IFS=$'\t' read -r sec bullet; do
    :
    bullet_rendered "$sec" "$bullet" || fail "changelog_unrendered_bullet:$path" # rule:render
  done < "$WORK/clbullets.tsv"
  # (f) no bullet's commit was listed by an earlier release
  while IFS=$'\t' read -r sec bullet; do
    oid=$(printf '%s' "$bullet" | sed -n 's/.*\/commit\/\([0-9a-f]\{40\}\)))$/\1/p')
    :
    if [ -n "$oid" ] && grep -qF -- "/commit/$oid)" "$WORK/clbase.txt"; then fail "changelog_repeated_commit:$path"; fi # rule:repeat
  done < "$WORK/clbullets.tsv"
  return 0
}

# 10. a named package's changelog: one section directly above the previous version heading, in the measured grammar
while IFS=$'\t' read -r clp clpkg; do
  [ -n "$clp" ] || continue
  if grep -qxF -- "$clp" "$WORK/changed.txt"; then changelog_check "$clp" "$clpkg"; fi
done < "$WORK/changelogs.tsv"

prefix
printf ' verdict=PASS\n'
exit 0
