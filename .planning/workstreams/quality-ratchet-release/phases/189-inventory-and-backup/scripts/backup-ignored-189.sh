#!/usr/bin/env bash
# backup-ignored-189.sh - classify ignored content of the recovery checkout and back up the keep set (plan 05, task 2).
# Read-only on the checkout. Output: counts only.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
export RESTORE_PLAN=05
S="$RUNS/scratch-05"
mkdir -p -m 0700 "$S" || exit 3
EVID="$PD/189-EVIDENCE"
is_env() { case ${1##*/} in .env|.env.*|local.properties) return 0 ;; esac; return 1; }

# 1. entries
gr "$REC" ls-files --others --ignored --exclude-standard --directory > "$S/ign-entries.txt" || exit 1
: > "$S/entries.tsv"; : > "$S/keep-roots.txt"; : > "$S/regen-top.txt"
n_env=0
while IFS= read -r e; do
  [ -n "$e" ] || continue
  p="${e%/}"
  if [ ! -d "$REC/$p" ]; then
    if is_env "$p"; then n_env=$((n_env + 1)); continue; fi
    sz=$(du -sk "$REC/$p" 2>/dev/null | cut -f1)
    printf '%s\tfile\t%s KB\tunclassified\tignored file; backed up in ignored-keep.tar\n' "$e" "$sz" >> "$S/entries.tsv"
    printf '%s\n' "$p" >> "$S/keep-roots.txt"
    continue
  fi
  sz=$(du -sk "$REC/$p" 2>/dev/null | cut -f1)
  case $p in
    .claude/worktrees/agent-*)
      printf '%s\tworktree-covered\t%s KB\tunclassified\tcovered by plan 04 worktree rows\n' "$e" "$sz" >> "$S/entries.tsv"; continue ;;
  esac
  if k=$(regen_check "$REC/$p" 2>/dev/null); then
    printf '%s\tregenerable\t%s KB\tobsolete\t%s\n' "$e" "$sz" "$k" >> "$S/entries.tsv"
    printf '%s\t%s\t%s\n' "$p" "$sz" "$k" >> "$S/regen-top.txt"
  else
    printf '%s\tfolder\t%s KB\tunclassified\tignored folder; backed up in ignored-keep.tar\n' "$e" "$sz" >> "$S/entries.tsv"
    printf '%s\n' "$p" >> "$S/keep-roots.txt"
  fi
done < "$S/ign-entries.txt"

# 2. expand keep roots to regular files, excluding regenerable subfolders, agent worktree dirs and env files
: > "$S/prune-keep.txt"
while IFS= read -r r; do
  [ -d "$REC/$r" ] || continue
  find -P "$REC/$r" -type d \( -name '_build' -o -name '_build_*' -o -name deps -o -name node_modules -o -name .elixir_ls -o -name DerivedData -o -name .build -o -name .gradle -o -name build -o -name __pycache__ \) -print 2>/dev/null |
  while IFS= read -r d; do
    if k=$(regen_check "$d" 2>/dev/null); then printf '%s\t%s\t%s\n' "${d#$REC/}" "$(du -sk "$d" | cut -f1)" "$k"; fi
  done
done < "$S/keep-roots.txt" > "$S/regen-nested.txt"
cut -f1 "$S/regen-nested.txt" > "$S/prune-keep.txt"

: > "$S/keep-list.txt"
while IFS= read -r r; do
  if [ -d "$REC/$r" ]; then
    (cd "$REC" && find -P "$r" -type f 2>/dev/null)
  else
    printf '%s\n' "$r"
  fi
done < "$S/keep-roots.txt" |
awk -v pf="$S/prune-keep.txt" '
  BEGIN{ while ((getline l < pf) > 0) if (l != "") P[++n]=l }
  { if ($0 ~ /^\.claude\/worktrees\/agent-[^\/]*\//) next
    b=$0; sub(/.*\//,"",b)
    if (b == ".env" || b ~ /^\.env\./ || b == "local.properties") next
    for (i=1;i<=n;i++) if (index($0, P[i] "/") == 1) next
    print }' | LC_ALL=C sort -u > "$S/keep-list.txt"

n_keep=$(awk 'NF{n++} END{print n+0}' "$S/keep-list.txt")
n_ad=$(grep -c -E '(^|/)\._' "$S/keep-list.txt")
n_sym=$( (cd "$REC" && while IFS= read -r r; do [ -d "$r" ] && find -P "$r" -type l 2>/dev/null; done < "$S/keep-roots.txt") | grep -v -E '^\.claude/worktrees/agent-[^/]*/' | wc -l | tr -d ' ')
echo "ignored: keep files $n_keep, appledouble $n_ad, symlinks not archived $n_sym, env entries $n_env"
[ "$n_ad" -eq 0 ] || { echo "ignored: stop (appledouble)"; exit 1; }

# 3. space precheck
bytes=$(cd "$REC" && tr '\n' '\0' < "$S/keep-list.txt" | xargs -0 stat -f %z | awk '{s+=$1} END{printf "%d", s}')
avail=$(df -k "$OUT" | awk 'NR==2{print $4}')
need=$(( (bytes / 1024) * 3 + 1048576 ))
echo "ignored: keep KB $((bytes / 1024)), need KB $need, available KB $avail"
[ "$avail" -ge "$need" ] || { echo "ignored: stop (disk_space)"; exit 1; }

# 4. manifest and tar
cd "$REC" || exit 1
tr '\n' '\0' < "$S/keep-list.txt" | xargs -0 shasum -a 256 > "$S/sha.txt" || exit 1
tr '\n' '\0' < "$S/keep-list.txt" | xargs -0 stat -f '%Lp' > "$S/modes.txt" || exit 1
[ "$(wc -l < "$S/sha.txt")" -eq "$n_keep" ] && [ "$(wc -l < "$S/modes.txt")" -eq "$n_keep" ] || { echo "ignored: stop (manifest count)"; exit 1; }
paste -d' ' <(cut -c1-64 "$S/sha.txt") "$S/modes.txt" "$S/keep-list.txt" > "$OUT/ignored-keep.files"
COPYFILE_DISABLE=1 tar -c -n -f "$OUT/ignored-keep.tar" -C "$REC" -T "$S/keep-list.txt" 2>/dev/null || { echo "ignored: tar failed"; exit 1; }
chmod 600 "$OUT/ignored-keep.tar" "$OUT/ignored-keep.files"
{ echo "keep"; } >/dev/null
cp "$OUT/ignored-keep.files" "$RUNS/expect/ignored-keep.expect"; chmod 600 "$RUNS/expect/ignored-keep.expect"

# 5. regenerable list
{ cat "$S/regen-top.txt"; cat "$S/regen-nested.txt"; } | awk -F'\t' '{printf "%s\t%s KB\t%s\n", $1, $2, $3}' | LC_ALL=C sort > "$OUT/ignored-regenerable.list"
chmod 600 "$OUT/ignored-regenerable.list"
echo "ignored: regenerable lines $(wc -l < "$OUT/ignored-regenerable.list" | tr -d ' ')"
