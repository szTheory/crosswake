#!/usr/bin/env bash
# backup-env-189.sh - restricted archive of local environment files (plan 05, task 1).
# Output is counts only. No path, name, hash or content of an environment file is printed.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
export RESTORE_PLAN=05
mkdir -p -m 0700 "$RUNS/expect" "$RUNS/scratch-05" || exit 3
S="$RUNS/scratch-05"
EVID="$PD/189-EVIDENCE"
: > "$S/env-list.txt"; chmod 600 "$S/env-list.txt"
: > "$S/env-a.txt"; : > "$S/env-b.txt"; : > "$S/env-c.txt"; : > "$S/skipped.txt"; : > "$S/dirty.txt"
chmod 600 "$S"/env-?.txt "$S/skipped.txt" "$S/dirty.txt"

# find_env ROOT OUTFILE [EXTRA_PRUNE_PATH]
find_env() {
  local root=$1 outf=$2 extra=${3:-} cand d
  [ -d "$root" ] || return 0
  : > "$S/prune.txt"
  # directories whose regen_check passes are pruned
  find -P "$root" \( -name .git -prune \) -o -type d \( -name '_build' -o -name '_build_*' -o -name deps -o -name node_modules -o -name .elixir_ls -o -name DerivedData -o -name .build -o -name .gradle -o -name build -o -name __pycache__ \) -print 2>/dev/null > "$S/cand.txt"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    if regen_check "$d" >/dev/null 2>&1; then printf '%s\n' "$d" >> "$S/prune.txt"; fi
  done < "$S/cand.txt"
  find -P "$root" -name .git -prune -o -type f \( -name '.env' -o -name '.env.*' -o -name 'local.properties' \) -print 2>/dev/null |
    awk -v ex="$extra" -v pf="$S/prune.txt" '
      BEGIN{ while ((getline l < pf) > 0) if (l != "") P[++n]=l }
      { if (ex != "" && (index($0, ex "/") == 1)) next
        for (i=1;i<=n;i++) if (index($0, P[i] "/") == 1) next
        print }' >> "$outf"
}

find_env "$REC" "$S/env-a.txt" "$REC/.claude/worktrees"
# extra worktrees (path list only; not the recovery checkout itself)
gr "$REC" worktree list --porcelain | sed -n 's/^worktree //p' | while IFS= read -r w; do
  [ "$w" = "$REC" ] && continue
  find_env "$w" "$S/env-b.txt"
done
# tmp scope: exactly the entries of the frozen listing
while IFS=$'\t' read -r nm kind sz; do
  [ -n "$nm" ] || continue
  case $nm in crosswake*) : ;; *) continue ;; esac
  if [ "$kind" = dir ]; then
    find_env "/private/tmp/$nm" "$S/env-c.txt"
  fi
done < "$RUNS/tmp-listing-before.raw"

# tracked-and-clean skip rule; dedupe across sources (first source wins)
: > "$S/seen.txt"
n_a=0; n_b=0; n_c=0; n_skip=0; n_dirty=0
for src in a b c; do
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    grep -qxF -e "$p" "$S/seen.txt" && continue
    printf '%s\n' "$p" >> "$S/seen.txt"
    repo=$(gr "$(dirname "$p")" rev-parse --show-toplevel 2>/dev/null) || repo=""
    keep=1; dirty=0
    if [ -n "$repo" ]; then
      if gr "$repo" ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
        gr "$repo" diff --quiet HEAD -- "$p" >/dev/null 2>&1; rc=$?
        case $rc in
          0) keep=0 ;;
          1) dirty=1 ;;
          *) echo "env: stop (diff status)"; exit 1 ;;
        esac
      fi
    fi
    if [ "$keep" -eq 0 ]; then n_skip=$((n_skip + 1)); continue; fi
    printf '%s\n' "${p#/}" >> "$S/env-list.txt"
    [ "$dirty" -eq 1 ] && n_dirty=$((n_dirty + 1))
    case $src in a) n_a=$((n_a + 1)) ;; b) n_b=$((n_b + 1)) ;; c) n_c=$((n_c + 1)) ;; esac
  done < "$S/env-$src.txt"
done
total=$((n_a + n_b + n_c))
{
  echo "recovery $n_a"; echo "worktrees $n_b"; echo "tmp $n_c"
  echo "tracked_skipped $n_skip"; echo "tracked_dirty $n_dirty"; echo "total $total"
} > "$EVID/env-counts.txt"

if [ "$total" -eq 0 ]; then
  echo "env: total 0"
  exit 0
fi

# manifest and archive
: > "$OUT/env-local.files"; chmod 600 "$OUT/env-local.files"
while IFS= read -r rp; do
  [ -n "$rp" ] || continue
  h=$(shasum -a 256 < "/$rp" | cut -c1-64) || { echo "env: hash failed"; exit 1; }
  m=$(stat -f %Lp "/$rp")
  printf '%s %s %s\n' "$h" "$m" "$rp" >> "$OUT/env-local.files"
done < "$S/env-list.txt"
COPYFILE_DISABLE=1 tar -c -n -f "$OUT/env-local.tar" -C / -T "$S/env-list.txt" 2>/dev/null || { echo "env: tar failed"; exit 1; }
chmod 600 "$OUT/env-local.tar" "$OUT/env-local.files"
{ echo sensitive; cat "$OUT/env-local.files"; } > "$RUNS/expect/env-local.expect"
chmod 600 "$RUNS/expect/env-local.expect"
echo "env: archived $total (recovery $n_a, worktrees $n_b, tmp $n_c, tracked_skipped $n_skip, tracked_dirty $n_dirty)"
