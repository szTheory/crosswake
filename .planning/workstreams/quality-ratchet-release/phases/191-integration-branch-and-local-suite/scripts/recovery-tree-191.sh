#!/bin/sh
# Working-tree byte digest of the recovery checkout (A-11, extends D-23). No git command.
# snapshot TOP NAMED VOLATILE [TRACKED]   compare BEFORE AFTER NAMED
set -u
umask 077
P191_REL=.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite
TAB=$(printf '\t')
NL=$(printf '\n_'); NL=${NL%_}
RT_TMP=${RECOVERY_TREE_TMPDIR:-/private/tmp/crosswake-phase191-run}
sha() { shasum -a 256 | awk '{print $1}'; }

snapshot() {
  TOP=${1:-}; NAMED=${2:-}; VOL=${3:-}; TRACKED=${4:-}
  [ -d "$TOP" ] && [ -f "$NAMED" ] && [ -f "$VOL" ] || { echo "recovery-tree: input missing"; exit 2; }
  NROWS=$(awk -F'\t' 'NR>1 && $1!=""{n++} END{print n+0}' "$NAMED")
  if [ "$NROWS" -eq 0 ]; then echo "recovery-tree: named list empty"; exit 2; fi
  # volatile validation
  VENT=$(awk -F'\t' 'NR>1 && $1!=""{print $1}' "$VOL")
  for e in $VENT; do
    case "$e" in .planning|.planning/*) echo "recovery-tree: volatile entry not allowed"; exit 2 ;; esac
    if [ -n "$TRACKED" ] && [ -f "$TRACKED" ]; then
      b=${e%/}
      hit=$(awk -F'\t' -v e="$b" 'NF>=2 { p=$2; n=split(p, a, "/"); if (p==e || index(p, e "/")==1 || a[n]==e) c++ } END{print c+0}' "$TRACKED")
      if [ "$hit" -ne 0 ]; then echo "recovery-tree: volatile entry not allowed"; exit 2; fi
    fi
  done
  WORK=$(mktemp -d "$RT_TMP/tree.XXXXXX") || exit 2
  # build prune args
  set -- -path ./.git -o -path "./$P191_REL"
  for e in $VENT; do
    b=${e%/}
    case "$e" in
      */) set -- "$@" -o -path "./$b" ;;
      *) set -- "$@" -o -name "$b" ;;
    esac
  done
  NP=$(awk -F'\t' 'NR>1 && $1!=""{print $1}' "$NAMED")
  for p in $NP; do set -- "$@" -o -path "./$p"; done
  ( cd "$TOP" || exit 2
    find . \( "$@" \) -prune -o -name "*${NL}*" -print > "$WORK/nl.txt"
    find . \( "$@" \) -prune -o ! -type d ! -type f ! -type l -print > "$WORK/odd.txt"
    find . \( "$@" \) -prune -o -type f -exec shasum -a 256 {} + > "$WORK/files.raw"
    echo $? > "$WORK/files.rc"
    find . \( "$@" \) -prune -o -type l -print > "$WORK/links.txt"
  )
  if [ -s "$WORK/nl.txt" ] || [ -s "$WORK/odd.txt" ]; then rm -rf "$WORK"; echo "recovery-tree: unsafe entry"; exit 2; fi
  if [ "$(cat "$WORK/files.rc")" -ne 0 ]; then rm -rf "$WORK"; echo "recovery-tree: digest failed"; exit 2; fi
  : > "$WORK/lines.txt"
  sed -E 's#^([0-9a-f]{64})  \./(.*)$#\1\tfile\t\2#' "$WORK/files.raw" >> "$WORK/lines.txt"
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    h=$(readlink "$TOP/$l" | sha)
    printf '%s\tlink\t%s\n' "$h" "${l#./}" >> "$WORK/lines.txt"
  done < "$WORK/links.txt"
  LC_ALL=C sort "$WORK/lines.txt" > "$WORK/sorted.txt"
  N=$(awk 'END{print NR+0}' "$WORK/sorted.txt")
  if [ "$N" -eq 0 ]; then rm -rf "$WORK"; echo "recovery-tree: zero files"; exit 2; fi
  if [ -n "${RECOVERY_TREE_KEEP:-}" ]; then
    case "$RECOVERY_TREE_KEEP" in /private/tmp/crosswake-*) cp "$WORK/sorted.txt" "$RECOVERY_TREE_KEEP" ;; esac
  fi
  printf 'tree_rest_files %s\n' "$N"
  printf 'tree_rest_sha256 %s\n' "$(sha < "$WORK/sorted.txt")"
  for p in $NP; do
    if [ -f "$TOP/$p" ]; then printf 'named %s sha256 %s\n' "$p" "$(sha < "$TOP/$p")"; else printf 'named %s absent\n' "$p"; fi
  done
  rm -rf "$WORK"
}

compare() {
  B=${1:-}; A=${2:-}; NAMED=${3:-}
  [ -f "$B" ] && [ -f "$A" ] && [ -f "$NAMED" ] || { echo "recovery-tree: input missing"; exit 2; }
  rest=ok
  [ "$(grep -E '^tree_rest_(files|sha256) ' "$B")" = "$(grep -E '^tree_rest_(files|sha256) ' "$A")" ] || rest=changed
  if [ "$rest" = ok ]; then echo "recovery-tree: rest unchanged"; else echo "recovery-tree: rest changed"; fi
  missing=""
  while IFS="$TAB" read -r p ex pl rs; do
    [ "$p" = path ] && continue
    [ -n "$p" ] || continue
    lb=$(grep -F "named $p " "$B" | awk -v p="$p" '$2==p' )
    la=$(grep -F "named $p " "$A" | awk -v p="$p" '$2==p' )
    if [ "$lb" = "$la" ]; then
      echo "recovery-tree: named $p unchanged"
      if [ "$ex" = change ] && [ -z "$missing" ]; then missing=$p; fi
    else
      echo "recovery-tree: named $p changed"
    fi
  done < "$NAMED"
  if [ "$rest" != ok ]; then echo "recovery-tree: compare fail rest_changed"; exit 1; fi
  if [ -n "$missing" ]; then echo "recovery-tree: compare fail expected_change_missing $missing"; exit 1; fi
  echo "recovery-tree: compare pass"
}

MODE=${1:-}
[ "$#" -gt 0 ] && shift
case "$MODE" in
  snapshot) snapshot "$@" ;;
  compare) compare "$@" ;;
  *) echo "recovery-tree: usage"; exit 2 ;;
esac
