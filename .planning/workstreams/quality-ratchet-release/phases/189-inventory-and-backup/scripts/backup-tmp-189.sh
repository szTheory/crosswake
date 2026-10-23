#!/usr/bin/env bash
# backup-tmp-189.sh MODE - plan 08: backups of unclassified / to-land content in the temp folder.
# Modes: commits | build | restore | rows | manifest
# Reads temp sources only (gr, plain file reads, tar). Writes OUT/tmp-*, RUNS/scratch-08, PD evidence.
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
export RESTORE_PLAN=08
EV="$PD/189-EVIDENCE"
S="$RUNS/scratch-08"
TMPROOT=/private/tmp
FULL="$OUT/tmp-entries-full.tsv"
R08="$EV/restore-08.tsv"
die() { echo "backup-tmp: BLOCKED $1" >&2; exit 1; }
cnt() { awk 'NF{n++} END{print n+0}'; }
is_env() { case ${1##*/} in .env|.env.*|local.properties) return 0 ;; esac; return 1; }
slugof() { printf '%s' "$1" | sed -e "s|^$TMPROOT/||" -e 's|[/ ]|-|g'; }

record() { # record ARTIFACT KIND EXPECT DETAIL : run restore, replace the line in restore-08.tsv
  local out rc res
  out=$(bash "$HERE/restore-189.sh" "$1" "$2" "$3" 2>&1); rc=$?
  echo "$out"
  case $out in "restore $1: pass") res=pass ;; *) res=fail ;; esac
  [ "$rc" -eq 0 ] || res=fail
  { [ -f "$R08" ] && awk -F'\t' -v a="$1" '$1 != a' "$R08"; printf '%s\t%s\t%s\t%s (%s)\n' "$1" "$2" "$res" "$4" "$out"; } > "$R08.tmp" && mv "$R08.tmp" "$R08"
}

MODE=${1:-}
case $MODE in

commits)
  [ -f "$EV/../189-06-SUMMARY.md" ] && [ ! -e "$EV/../189-06-BLOCKED.md" ] || die precondition
  if [ -d "$S" ]; then rm -rf "$S/b.git" "$S/chk.git"; else mkdir -m 0700 "$S" || die scratch; fi
  [ "$(stat -f %Lp "$S")" = 700 ] || die scratch_mode
  gclone "$RUNS/scratch-06/cmp.git" "$S/b.git" --mirror --shared -q >/dev/null 2>&1 || die bundle_failed
  [ "$(gs "$S/b.git" rev-parse --is-shallow-repository)" = false ] || die bundle_failed
  # no tip may belong to a shallow repo
  bad=$(awk -F'\t' 'FILENAME==ARGV[1]{if ($4 ~ /shallow/) s[$1]=1; next} NF && ($1 in s){n++} END{print n+0}' "$RUNS/tmp-gitdirs.tsv" "$RUNS/tmp-tips.tsv")
  [ "$bad" -eq 0 ] || die bundle_failed
  awk -F'\t' 'NF{print $1" "$4}' "$RUNS/tmp-tips.tsv" | LC_ALL=C sort -u > "$S/pairs.txt"
  while read -r n tip; do
    if ! gs "$S/b.git" cat-file -e "$tip^{commit}" 2>/dev/null; then
      gs "$S/b.git" fetch -q "$RUNS/scratch-06/cmp.git" '+refs/*:refs/*' >/dev/null 2>&1 || die bundle_failed
    fi
    gs "$S/b.git" update-ref "refs/tmp-backup/$n/$tip" "$tip" || die bundle_failed
  done < "$S/pairs.txt"
  awk '{print $2}' "$S/pairs.txt" | LC_ALL=C sort -u > "$S/tips-only.txt"
  est=$(gs "$S/b.git" rev-list --objects --disk-usage --stdin < "$S/tips-only.txt") || die bundle_failed
  need_kb=$(( (3 * est) / 1024 + 1048576 ))
  avail_kb=$(df -k "$OUT" | awk 'NR==2{print $4}')
  [ "$avail_kb" -gt "$need_kb" ] || die disk_space
  echo "space: est_bytes=$est need_kb=$need_kb avail_kb=$avail_kb"
  gs "$S/b.git" for-each-ref --format='%(refname)' refs/tmp-backup/ > "$S/reflist.txt" || die bundle_failed
  [ "$(cnt < "$S/reflist.txt")" -eq "$(cnt < "$S/pairs.txt")" ] || die bundle_failed
  rm -f "$OUT/tmp-commits.bundle"
  gs "$S/b.git" bundle create "$OUT/tmp-commits.bundle" --stdin < "$S/reflist.txt" >/dev/null 2>&1 || die bundle_failed
  chmod 0600 "$OUT/tmp-commits.bundle"
  { echo complete-history; gs "$S/b.git" for-each-ref --format='%(objectname) %(refname)' refs/tmp-backup/ | LC_ALL=C sort; } > "$OUT/tmp-commits.expect" || die bundle_failed
  chmod 0600 "$OUT/tmp-commits.expect"
  : > "$R08"
  record tmp-commits.bundle bundle "$OUT/tmp-commits.expect" "tmp"
  # unique commits (plan 06 definition) must all be present in the restored bundle
  gs "$RUNS/scratch-06/cmp.git" rev-list --glob='refs/tmpitem/*' --glob='refs/tmpextra/*' --not refs/heads/main refs/cand/head --glob='refs/rec/*' | LC_ALL=C sort -u > "$S/unique-ids.txt" || die bundle_failed
  M=$(cnt < "$S/unique-ids.txt")
  awk -F'\t' '$3=="fetched"{print $2}' "$RUNS/tmp-unique.tsv" | LC_ALL=C sort -u > "$S/unique-fetched.txt"
  cmp -s "$S/unique-ids.txt" "$S/unique-fetched.txt" || die bundle_failed
  gclone "$OUT/tmp-commits.bundle" "$S/chk.git" --mirror -q >/dev/null 2>&1 || die bundle_failed
  N=0
  while read -r id; do gs "$S/chk.git" cat-file -e "$id^{commit}" 2>/dev/null && N=$((N + 1)); done < "$S/unique-ids.txt"
  tips=$(cnt < "$S/pairs.txt")
  line=$(awk -F'\t' '$1=="tmp-commits.bundle"' "$R08")
  [ -n "$line" ] || die restore_failed
  res=$(printf '%s' "$line" | cut -f3)
  rest=$(printf '%s' "$line" | cut -f4- | sed 's/^tmp (//; s/)$//')
  printf 'tmp-commits.bundle\tbundle\t%s\tcomplete history, connectivity ok in restored scratch, %s tip refs equal; unique_present %s of %s (%s)\n' "$res" "$tips" "$N" "$M" "$rest" > "$R08"
  echo "unique_present $N of $M"
  ;;

build)
  [ -d "$S" ] || die scratch
  J="$S/jobs"; rm -rf "$J"; mkdir -m 0700 "$J" || die scratch
  : > "$J/jobs.tsv"; : > "$J/rowmap.tsv"
  # ---- gitdir jobs
  while IFS=$'\t' read -r n repo gd reason rest; do
    [ -d "$gd" ] || die fetch_failed
    stem="tmp-$(slugof "$repo")-gitdir"
    find "$gd" -type f -print | awk -v r="$gd" 'BEGIN{l=length(r)+2}{print substr($0,l)}' | LC_ALL=C sort > "$J/$stem.list"
    find "$gd" -type d -empty -print | awk -v r="$gd" 'BEGIN{l=length(r)+2}{if (length($0)>=l) print substr($0,l)}' | LC_ALL=C sort > "$J/$stem.dirs"
    printf 'tar\t%s\t%s\n' "$stem" "$gd" >> "$J/jobs.tsv"
    top=$(printf '%s' "${repo#$TMPROOT/}" | cut -d/ -f1)
    rid=$(awk -F'\t' -v t="$top" '$1==t{print $10}' "$FULL")
    printf '%s\t%s\n' "$rid" "$stem.tar" >> "$J/rowmap.tsv"
  done < "$RUNS/tmp-gitdirs.tsv"
  # ---- entries
  : > "$J/loose.list"
  while IFS=$'\t' read -r name type nrepos nbroken nfiles nenv size cls rsn rid plan; do
    [ "$name" = entry ] && continue
    root="$TMPROOT/$name"
    case $plan in
      none) continue ;;
    esac
    case $plan in
      *loose-tar*) is_env "$name" && die env_loose; printf '%s\n' "$name" >> "$J/loose.list"; printf '%s\t%s\n' "$rid" "tmp-loose-files.tar" >> "$J/rowmap.tsv"; continue ;;
    esac
    case $plan in *commits*) printf '%s\t%s\n' "$rid" "tmp-commits.bundle" >> "$J/rowmap.tsv" ;; esac
    # repo roots below this entry
    : > "$J/reposroots.tmp"
    while IFS=$'\t' read -r rn rp rl; do
      case $rp in "$root"|"$root"/*) printf '%s\t%s\n' "$rn" "$rp" >> "$J/reposroots.tmp" ;; esac
    done < "$RUNS/scratch-06/repo-index.tsv"
    # dirty tars
    case $plan in *dirty-tar*)
      while IFS=$'\t' read -r rn rp; do
        [ -s "$RUNS/scratch-06/dirty-$rn.txt" ] || continue
        stem="tmp-$(slugof "$rp")-dirty"
        : > "$J/$stem.list"
        while IFS= read -r dp; do
          [ -n "$dp" ] || continue
          is_env "$dp" && die env_dirty
          if [ -L "$rp/$dp" ] || [ ! -f "$rp/$dp" ]; then die dirty_unreadable; fi
          printf '%s\n' "$dp" >> "$J/$stem.list"
        done < "$RUNS/scratch-06/dirty-$rn.txt"
        LC_ALL=C sort -o "$J/$stem.list" "$J/$stem.list"
        : > "$J/$stem.dirs"
        printf 'tar\t%s\t%s\n' "$stem" "$rp" >> "$J/jobs.tsv"
        [ "$rid" = C-CAND ] || printf '%s\t%s\n' "$rid" "$stem.tar" >> "$J/rowmap.tsv"
      done < "$J/reposroots.tmp"
    ;; esac
    # folder tar / excluded only
    case $plan in *folder-tar*|*excluded-only*)
      stem="tmp-$(slugof "$root")"
      prune=()
      while IFS=$'\t' read -r rn rp; do prune+=( -path "$rp" -prune -o ); done < "$J/reposroots.tmp"
      if [ "${#prune[@]}" -gt 0 ]; then
        find "$root" -name .git -prune -o "${prune[@]}" -type f -print > "$J/own.tmp"
      else
        find "$root" -name .git -prune -o -type f -print > "$J/own.tmp"
      fi
      : > "$J/own.abs"
      while IFS= read -r f; do is_env "$f" || printf '%s\n' "$f" >> "$J/own.abs"; done < "$J/own.tmp"
      : > "$J/regen.tmp"
      if [ ! -s "$J/reposroots.tmp" ] && k=$(regen_check "$root"); then
        printf '%s\t%s\n' "$root" "$k" > "$J/regen.tmp"
      else
        find "$root" -name .git -prune -o -type d \( -name _build -o -name '_build_*' -o -name deps -o -name node_modules -o -name .elixir_ls -o -name DerivedData -o -name .build -o -name .gradle -o -name build -o -name __pycache__ \) -prune -print 2>/dev/null | while IFS= read -r d; do
          if k=$(regen_check "$d"); then printf '%s\t%s\n' "$d" "$k"; fi
        done > "$J/regen.tmp"
      fi
      awk -F'\t' -v root="$root" -v kept="$J/$stem.list" -v excl="$J/$stem.excl" '
        BEGIN{while ((getline l < ARGV[1]) > 0) { split(l, a, "\t"); d[++nd]=a[1]; k[nd]=a[2] } ARGV[1]=""; rl=length(root)+2 }
        { f=$0; hit=0; for (i=1;i<=nd;i++) { if (f==d[i] || index(f, d[i] "/")==1) { hit=i; break } }
          if (hit) print substr(f, rl) "\t" k[hit] > excl; else print substr(f, rl) > kept }' "$J/regen.tmp" "$J/own.abs"
      : >> "$J/$stem.list"; : >> "$J/$stem.excl"
      LC_ALL=C sort -o "$J/$stem.list" "$J/$stem.list"; LC_ALL=C sort -o "$J/$stem.excl" "$J/$stem.excl"
      : > "$J/$stem.dirs"
      if [ -s "$J/$stem.list" ]; then
        printf 'tar\t%s\t%s\n' "$stem" "$root" >> "$J/jobs.tsv"
        printf '%s\t%s\n' "$rid" "$stem.tar" >> "$J/rowmap.tsv"
      fi
      if [ -s "$J/$stem.excl" ]; then
        printf 'excl\t%s\t%s\n' "$stem" "$root" >> "$J/jobs.tsv"
        printf '%s\t%s\n' "$rid" "$stem.excluded" >> "$J/rowmap.tsv"
      fi
    ;; esac
  done < "$FULL"
  if [ -s "$J/loose.list" ]; then
    LC_ALL=C sort -o "$J/loose.list" "$J/loose.list"
    cp "$J/loose.list" "$J/tmp-loose-files.list"; : > "$J/tmp-loose-files.dirs"
    printf 'tar\t%s\t%s\n' "tmp-loose-files" "$TMPROOT" >> "$J/jobs.tsv"
  fi
  # unique artifact names
  [ "$(cut -f1,2 "$J/jobs.tsv" | LC_ALL=C sort | uniq -d | cnt)" -eq 0 ] || die name_collision
  # sanity on names: no newline/backslash/leading dash
  while IFS=$'\t' read -r kind stem root; do
    for lf in "$J/$stem.list" "$J/$stem.excl"; do
      [ -f "$lf" ] || continue
      if grep -q -E '^-|\\' "$lf"; then die odd_name; fi
    done
  done < "$J/jobs.tsv"
  # free space
  tot=0
  while IFS=$'\t' read -r kind stem root; do
    [ "$kind" = tar ] || continue
    s=$(cd "$root" && sed 's|^|./|' "$J/$stem.list" | tr '\n' '\0' | xargs -0 stat -f %z | awk '{t+=$1} END{print t+0}')
    tot=$((tot + s))
  done < "$J/jobs.tsv"
  need_kb=$(( (3 * tot) / 1024 + 1048576 ))
  avail_kb=$(df -k "$OUT" | awk 'NR==2{print $4}')
  echo "space: total_bytes=$tot need_kb=$need_kb avail_kb=$avail_kb"
  [ "$avail_kb" -gt "$need_kb" ] || die disk_space
  echo "$tot" > "$J/total.txt"
  # manifests and tars
  while IFS=$'\t' read -r kind stem root; do
    lf="$J/$stem.list"
    if [ "$kind" = tar ]; then
      n=$(cnt < "$lf")
      n0=$(cd "$root" && sed 's|^|./|' "$lf" | tr '\n' '\0' | tr -cd '\0' | wc -c | tr -d ' ')
      [ "$n" -eq "$n0" ] || die odd_name
      ( cd "$root" && sed 's|^|./|' "$lf" | tr '\n' '\0' | xargs -0 shasum -a 256 ) | awk '{print $1}' > "$J/$stem.sha" || die manifest_failed
      ( cd "$root" && sed 's|^|./|' "$lf" | tr '\n' '\0' | xargs -0 stat -f %Lp ) > "$J/$stem.mode" || die manifest_failed
      [ "$(cnt < "$J/$stem.sha")" -eq "$n" ] && [ "$(cnt < "$J/$stem.mode")" -eq "$n" ] || die manifest_failed
      paste -d' ' "$J/$stem.sha" "$J/$stem.mode" "$lf" > "$OUT/$stem.files" || die manifest_failed
      # environment basenames never appear in a manifest
      if cut -d' ' -f3- "$OUT/$stem.files" | grep -q -E '(^|/)(\.env[^/]*|local\.properties)$'; then die env_in_manifest; fi
      cat "$lf" "$J/$stem.dirs" > "$J/$stem.tarlist"
      rm -f "$OUT/$stem.tar"
      COPYFILE_DISABLE=1 tar -c -n -f "$OUT/$stem.tar" -C "$root" -T "$J/$stem.tarlist" || die tar_failed
      chmod 0600 "$OUT/$stem.tar" "$OUT/$stem.files"
      echo "built $stem.tar files=$n"
    else
      el="$J/$stem.excl"
      cut -f1 "$el" > "$J/$stem.exl"
      ( cd "$root" && sed 's|^|./|' "$J/$stem.exl" | tr '\n' '\0' | xargs -0 shasum -a 256 ) | awk '{print $1}' > "$J/$stem.xsha" || die manifest_failed
      ( cd "$root" && sed 's|^|./|' "$J/$stem.exl" | tr '\n' '\0' | xargs -0 stat -f %z ) > "$J/$stem.xsz" || die manifest_failed
      cut -f2 "$el" > "$J/$stem.xrs"
      paste -d'\t' "$J/$stem.xsha" "$J/$stem.xsz" "$J/$stem.exl" "$J/$stem.xrs" > "$OUT/$stem.excluded" || die manifest_failed
      chmod 0600 "$OUT/$stem.excluded"
      echo "built $stem.excluded lines=$(cnt < "$OUT/$stem.excluded")"
    fi
  done < "$J/jobs.tsv"
  ;;

restore)
  J="$S/jobs"
  [ -f "$J/jobs.tsv" ] || die scratch
  while IFS=$'\t' read -r kind stem root; do
    [ "$kind" = tar ] || continue
    n=$(cnt < "$OUT/$stem.files")
    record "$stem.tar" tarfiles "$OUT/$stem.files" "$n files match tar-time sha256 and mode"
  done < "$J/jobs.tsv"
  ;;

rows)
  J="$S/jobs"
  RW="$EV/rows-06.md"
  # cells: rid -> backup list
  awk -F'\t' '
    FILENAME==ARGV[1] { st[$1]=$3; next }
    { rid=$1; a=$2; if (!(rid in b)) { b[rid]=a; ord[++no]=rid } else if (index(" " b[rid] " ", " " a " ")==0) b[rid]=b[rid] "; " a }
    END { for (i=1;i<=no;i++) { r=ord[i]; n=split(b[r], parts, "; "); res="pass"; for (j=1;j<=n;j++) { p=parts[j]; if (p ~ /\.excluded$/) continue; if (st[p] != "pass") res="fail" } printf "%s\t%s\t%s\n", r, b[r], res } }
  ' "$R08" "$J/rowmap.tsv" > "$J/cells.tsv"
  # R-TMP-COMMITS: bundle plus gitdir tar of the shallow repo holding a unique commit that is not the candidate
  p179=$(grep -o 'tmp-crosswake-phase179-impl-gitdir\.tar' "$J/cells.tsv" | sort -u)
  [ -n "$p179" ] || die rows
  printf 'R-TMP-COMMITS\ttmp-commits.bundle; %s\tpass\n' "$p179" >> "$J/cells.tsv"
  awk -F'\t' 'BEGIN{OFS="\t"} {print}' "$J/cells.tsv" > /dev/null
  awk -F'\t' -v cells="$J/cells.tsv" '
    BEGIN { while ((getline l < cells) > 0) { split(l, a, "\t"); bk[a[1]]=a[2]; rs[a[1]]=a[3] } }
    /^\| R-TMP-/ && / pending \| pending \|$/ {
      split($0, f, "|"); id=f[2]; gsub(/^ +| +$/, "", id)
      if (id in bk) { sub(/ pending \| pending \|$/, " " bk[id] " | " rs[id] " |") }
      else if (id == "R-TMP-COMMITS") { }
    }
    { print }' "$RW" > "$J/rows-06.new"
  if grep -q 'pending' "$J/rows-06.new"; then
    grep -n 'pending' "$J/rows-06.new" | cut -c1-80 >&2
    die rows_pending
  fi
  cp "$J/rows-06.new" "$RW"
  echo "rows filled"
  ;;

manifest)
  files=$(cd "$OUT" && ls -1 tmp-* | grep -v -x 'tmp-entries-full.tsv' | LC_ALL=C sort)
  # shellcheck disable=SC2086
  set -- $files
  bash "$HERE/manifest-189.sh" SHA256SUMS.08 "$@" || die manifest_failed
  ;;

*) echo "usage: backup-tmp-189.sh commits|build|restore|rows|manifest" >&2; exit 2 ;;
esac
