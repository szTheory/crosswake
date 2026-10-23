#!/bin/bash
# Phase 191 HEAD-bound privacy scanner (D-18, D-19, D-20, A-13). Read-only on the scanned repo.
# usage: scan-191.sh REPO BASE HEAD [PRESERVED_HEAD]
#        scan-191.sh --term-check
# exit 0 = clean, 1 = hits, 2 = scope or tool error (never a clean pass).
# Output: fixed `scan:` labels only. A matched value, a term, a path or a file name is never printed.
# Env: CROSSWAKE_PRIVATE_ADOPTER_TERMS (comma separated), SCAN191_ACCOUNT (self-test only),
#      SCAN191_TRIAGE (triage file override, self-test only).
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || { echo "scan: bad location"; exit 2; }
. "$HERE/git-pinned-191.sh"

SC=$(mktemp -d /private/tmp/crosswake-scan-191.XXXXXX) || { echo "scan: scratch failed"; exit 2; }
cleanup() { case "$SC" in /private/tmp/crosswake-scan-191.*) rm -rf "$SC" ;; esac; }
trap cleanup EXIT
trap 'exit 2' INT TERM HUP

fail() { echo "scan: $1"; exit 2; }

# patterns are assembled from fragments so this file never matches its own classes
SL=/
P_HOME="${SL}Us""ers/[A-Za-z0-9._-]+"
P_TEMP="${SL}va""r/folders/[A-Za-z0-9_+-]{2}/[A-Za-z0-9_+-]{8,}"
HX16='[0-9A-F]'
P_UDID="${HX16}{8}-${HX16}{16}"
P_GH="(g""h[pousr]_|git""hub_pat_)[A-Za-z0-9_]{36,}"
P_PEM="BEGIN [A-Z ]*PRIV""ATE KEY"
CK="HEX_API_""KEY|HEX_ORGANIZATION_""KEY|(MAVEN|OSS""RH)[A-Z_]*(USERNAME|PASSWORD|TOKEN)|[A-Z_]*SIGNING[A-Z_]*(PASSWORD|PASSPHRASE)"
P_CRED="(${CK})[[:space:]]*[=:][[:space:]]*[\"']?[^[:space:]\"'<\${(][^[:space:]\"'()]{7,}"
P_EMAIL='[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}'
HXL='[0-9a-f]'
P_UUID="${HXL}{8}-${HXL}{4}-${HXL}{4}-${HXL}{4}-${HXL}{12}"
P_BW="to""ken|sec""ret"
P_H40="${HXL}{40}"

load_terms() { # FILE -> prints count
  printf '%s\n' "${CROSSWAKE_PRIVATE_ADOPTER_TERMS:-}" | tr ',' '\n' \
    | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | awk 'NF' > "$1"
  echo $(( $(wc -l < "$1") ))
}

# ---------------------------------------------------------------- term check mode
if [ "${1:-}" = "--term-check" ]; then
  n=$(load_terms "$SC/terms.txt")
  [ "$n" -ge 1 ] || { echo "term-check: terms 0 matched 0"; exit 2; }
  m=0
  while IFS= read -r t; do
    printf '%s\n' "$t" > "$SC/t1"
    printf 'alpha %s beta\n' "$t" > "$SC/tc.txt"
    printf 'alpha %s beta\n' "$t" | tr 'a-z' 'A-Z' > "$SC/tcu.txt"
    if grep -a -q -i -F -f "$SC/t1" "$SC/tc.txt" && grep -a -q -i -F -f "$SC/t1" "$SC/tcu.txt"; then m=$((m + 1)); fi
  done < "$SC/terms.txt"
  echo "term-check: terms $n matched $m"
  [ "$m" -eq "$n" ] && exit 0
  exit 1
fi

# ---------------------------------------------------------------- arguments
[ "$#" -ge 3 ] && [ "$#" -le 4 ] || fail "usage"
REPO=$(cd "$1" 2>/dev/null && pwd -P) || fail "bad range"
BASE=$(g "$REPO" rev-parse --verify --quiet "$2^{commit}" 2>/dev/null) || fail "bad range"
HEADC=$(g "$REPO" rev-parse --verify --quiet "$3^{commit}" 2>/dev/null) || fail "bad range"
[ -n "$BASE" ] && [ -n "$HEADC" ] || fail "bad range"
PRESC=
if [ "$#" -eq 4 ]; then
  PRESC=$(g "$REPO" rev-parse --verify --quiet "$4^{commit}" 2>/dev/null) || fail "bad range"
fi
RANGE="$BASE..$HEADC"

CNT_REV=$(g "$REPO" rev-list --count "$RANGE" 2>/dev/null) || fail "bad range"
[ "$((CNT_REV))" -gt 0 ] || fail "empty range"

# gitleaks must be the pinned version
GLV=$(gitleaks version 2>/dev/null)
[ "$GLV" = "8.30.1" ] || fail "gitleaks version"
if [ -e "$REPO/.gitleaks.toml" ] || [ -e "$REPO/.gitleaksignore" ] || [ -e "$REPO/.gitleaks" ]; then fail "gitleaks repo config present"; fi
g "$REPO" ls-tree --name-only "$HEADC" > "$SC/toplevel.txt" 2>/dev/null || fail "bad range"
if grep -q -E '^\.gitleaks' "$SC/toplevel.txt"; then fail "gitleaks repo config present"; fi

ACCOUNT=${SCAN191_ACCOUNT:-$(id -un)}
[ -n "$ACCOUNT" ] || fail "account unknown"
TRIAGE=${SCAN191_TRIAGE:-"$HERE/../191-EVIDENCE/scan-triage-191.tsv"}

# ---------------------------------------------------------------- triage file
: > "$SC/triaged.txt"
: > "$SC/glignore.txt"
if [ -f "$TRIAGE" ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in ''|'#'*|fingerprint"	"*) continue ;; esac
    fp=$(printf '%s' "$line" | awk -F'\t' '{print $1}')
    tclass=$(printf '%s' "$line" | awk -F'\t' '{print $2}')
    reason=$(printf '%s' "$line" | awk -F'\t' '{print $3}')
    case "$reason" in *[![:space:]]*) : ;; *) fail "triage row without reason" ;; esac
    [ -n "$fp" ] || fail "triage row without reason"
    # A row of class gitleaks holds one exact gitleaks fingerprint (commit:file:rule:line), used only as
    # an exact-match ignore entry for the secret layer; every other row is a scanner fingerprint.
    if [ "$tclass" = gitleaks ]; then printf '%s\n' "$fp" >> "$SC/glignore.txt"; else printf '%s\n' "$fp" >> "$SC/triaged.txt"; fi
  done < "$TRIAGE"
fi

# ---------------------------------------------------------------- input 1: added lines
g "$REPO" log -p --no-renames -m --no-ext-diff --no-textconv --full-index --format='%x01%H' "$RANGE" > "$SC/log-p.txt" 2>/dev/null || fail "log failed"
: > "$SC/al.txt"; : > "$SC/al.idx"; : > "$SC/blobcommit.txt"
cat > "$SC/al.awk" <<'AWK'
BEGIN { SOH = sprintf("%c", 1); off = 0; st = 0; nadd = 0; bytes = 0; zero = "0000000000000000000000000000000000000000" }
{
  if (substr($0, 1, 1) == SOH) { commit = substr($0, 2); st = 0; blob = ""; next }
  if (index($0, "diff --git ") == 1) { st = 1; blob = ""; k = 0; next }
  if (st == 1) {
    if (index($0, "index ") == 1) {
      split($2, a, "[.][.]"); blob = a[2]
      if (blob != "" && blob != zero) print blob " " commit >> BC
    } else if (index($0, "@@ ") == 1) { st = 2 }
    next
  }
  if (st == 2) {
    if (substr($0, 1, 1) == "+") {
      line = substr($0, 2); k++; nadd++
      print line >> ALT
      print off "\t" blob "." k "\t" commit "\t" (blob == "" ? "-" : blob) "\t-" >> ALI
      off += length(line) + 1; bytes += length(line)
    }
  }
}
END { print nadd " " bytes > STATS }
AWK
LC_ALL=C awk -v ALT="$SC/al.txt" -v ALI="$SC/al.idx" -v BC="$SC/blobcommit.txt" -v STATS="$SC/al.stats" -f "$SC/al.awk" "$SC/log-p.txt" || fail "awk failed"
[ -f "$SC/al.stats" ] || fail "awk failed"
read -r ADDED_LINES ADDED_BYTES < "$SC/al.stats"

# ---------------------------------------------------------------- input 2 and 3: new blobs and paths
g "$REPO" rev-list --objects "$RANGE" > "$SC/ro.txt" 2>/dev/null || fail "rev-list failed"
awk '{print $1}' "$SC/ro.txt" > "$SC/oids.txt"
g "$REPO" cat-file --batch-check='%(objectname) %(objecttype) %(objectsize)' < "$SC/oids.txt" > "$SC/bc.txt" 2>/dev/null || fail "cat-file failed"
awk '$2=="blob"{print $1, $3}' "$SC/bc.txt" > "$SC/blobs.txt"
: > "$SC/bl.txt"; : > "$SC/bl.idx"
off=0; TEXT_BLOBS=0; BIN_BLOBS=0
while read -r oid size; do
  g "$REPO" cat-file blob "$oid" > "$SC/one.bin" 2>/dev/null || fail "cat-file failed"
  nn=$(( $(LC_ALL=C tr -d '\000' < "$SC/one.bin" | wc -c) ))
  if [ "$nn" -ne "$((size))" ]; then BIN_BLOBS=$((BIN_BLOBS + 1)); else TEXT_BLOBS=$((TEXT_BLOBS + 1)); fi
  cat "$SC/one.bin" >> "$SC/bl.txt"; printf '\n' >> "$SC/bl.txt"
  printf '%s\t%s\t-\t%s\t-\n' "$off" "$oid" "$oid" >> "$SC/bl.idx"
  off=$((off + size + 1))
done < "$SC/blobs.txt"
rm -f "$SC/one.bin"
[ "$(( $(wc -c < "$SC/bl.txt") ))" -eq "$off" ] || fail "blob stream mismatch"

: > "$SC/pa.txt"; : > "$SC/pa.idx"
LC_ALL=C awk -v PAT="$SC/pa.txt" -v PAI="$SC/pa.idx" '
  NR == FNR { ty[$1] = $2; next }
  { i = index($0, " "); if (i == 0) next
    p = substr($0, i + 1); o = $1
    print p >> PAT
    print off "\t" o "\t-\t" (ty[o] == "blob" ? o : "-") "\t" p >> PAI
    off += length(p) + 1; n++ }
  BEGIN { off = 0; n = 0 }
  END { print n + 0 > (PAT ".n") }' "$SC/bc.txt" "$SC/ro.txt" || fail "awk failed"
PATHS=0; [ -f "$SC/pa.txt.n" ] && read -r PATHS < "$SC/pa.txt.n"

# ---------------------------------------------------------------- input 4: identities, messages, tags, notes
g "$REPO" log --format='%H%x09%an%x09%ae%x09%cn%x09%ce' "$RANGE" > "$SC/idlog.txt" 2>/dev/null || fail "log failed"
COMMITS=$(( $(wc -l < "$SC/idlog.txt") ))
[ "$COMMITS" -eq "$((CNT_REV))" ] || fail "commit count mismatch"
: > "$SC/id.txt"; : > "$SC/id.idx"
LC_ALL=C awk -F'\t' -v IDT="$SC/id.txt" -v IDI="$SC/id.idx" '
  BEGIN { off = 0 }
  { l1 = $2 "\t" $3; l2 = $4 "\t" $5
    print l1 >> IDT; print off "\t" $1 "\t" $1 "\t-\t-" >> IDI; off += length(l1) + 1
    print l2 >> IDT; print off "\t" $1 "\t" $1 "\t-\t-" >> IDI; off += length(l2) + 1 }' "$SC/idlog.txt" || fail "awk failed"
IDENTITIES=$(( $(wc -l < "$SC/id.txt") ))

g "$REPO" log --format='%x01%H%n%B' "$RANGE" > "$SC/msglog.txt" 2>/dev/null || fail "log failed"
: > "$SC/ms.txt"; : > "$SC/ms.idx"
LC_ALL=C awk -v MST="$SC/ms.txt" -v MSI="$SC/ms.idx" '
  BEGIN { SOH = sprintf("%c", 1); off = 0 }
  { if (substr($0, 1, 1) == SOH) { c = substr($0, 2); next }
    print $0 >> MST; print off "\t" c "\t" c "\t-\t-" >> MSI; off += length($0) + 1 }' "$SC/msglog.txt" || fail "awk failed"

g "$REPO" rev-list "$RANGE" > "$SC/commits.txt" 2>/dev/null || fail "rev-list failed"
: > "$SC/tg.txt"; : > "$SC/tg.idx"; : > "$SC/nt.txt"; : > "$SC/nt.idx"
append_units() { # STREAM OBJ COMMIT (text on stdin)
  _s=$1; _o=$2; _c=$3
  _b=$(( $(wc -c < "$SC/$_s.txt") ))
  LC_ALL=C awk -v base="$_b" -v o="$_o" -v c="$_c" -v T="$SC/$_s.txt" -v I="$SC/$_s.idx" \
    'BEGIN { off = base } { print $0 >> T; print off "\t" o "\t" c "\t-\t-" >> I; off += length($0) + 1 }'
}
g "$REPO" for-each-ref refs/tags --format='%(objecttype) %(objectname) %(*objectname)' > "$SC/tags.ref" 2>/dev/null || fail "for-each-ref failed"
while read -r ty to tp; do
  [ "$ty" = tag ] || continue
  [ -n "${tp:-}" ] || continue
  grep -q -x "$tp" "$SC/commits.txt" || continue
  g "$REPO" cat-file tag "$to" > "$SC/tagbody.txt" 2>/dev/null || fail "cat-file failed"
  append_units tg "$to" "$tp" < "$SC/tagbody.txt"
done < "$SC/tags.ref"
g "$REPO" notes list > "$SC/notes.ref" 2>/dev/null || : > "$SC/notes.ref"
while read -r no nc; do
  [ -n "${nc:-}" ] || continue
  grep -q -x "$nc" "$SC/commits.txt" || continue
  g "$REPO" cat-file blob "$no" > "$SC/notebody.txt" 2>/dev/null || continue
  append_units nt "$no" "$nc" < "$SC/notebody.txt"
done < "$SC/notes.ref"

# ---------------------------------------------------------------- terms and counts (D-19)
TERMS=$(load_terms "$SC/terms.txt")
echo "scan: commits $COMMITS"
echo "scan: added_lines $ADDED_LINES"
echo "scan: added_bytes $ADDED_BYTES"
echo "scan: text_blobs $TEXT_BLOBS"
echo "scan: binary_blobs $BIN_BLOBS"
echo "scan: paths $PATHS"
echo "scan: identities $IDENTITIES"
echo "scan: terms $TERMS"
[ "$ADDED_LINES" -gt 0 ] || fail "empty added_lines"
[ "$TEXT_BLOBS" -gt 0 ] || fail "empty text_blobs"
[ "$PATHS" -gt 0 ] || fail "empty paths"
[ "$IDENTITIES" -gt 0 ] || fail "empty identities"
SKIP_ADOPTER=0
if [ "$TERMS" -eq 0 ] && [ "${SCAN191_ADOPTER_SKIP:-}" = "A-14" ]; then
  SKIP_ADOPTER=1
  echo "scan: adopter_check skipped_by_user A-14"
fi
[ "$TERMS" -gt 0 ] || [ "$SKIP_ADOPTER" -eq 1 ] || fail "empty terms"

# ---------------------------------------------------------------- classes
STREAMS="al bl pa id ms tg nt"
: > "$SC/hits.tsv"
grep_hits() { # CLASS FLAGS KIND(e|f) ARG
  for s in $STREAMS; do
    [ -s "$SC/$s.txt" ] || continue
    grep -a -o -b $2 -$3 "$4" "$SC/$s.txt" > "$SC/m.out" 2>/dev/null; rc=$?
    case $rc in 0) : ;; 1) continue ;; *) fail "grep failed" ;; esac
    awk -F: -v c="$1" -v s="$s" '{print c "\t" s "\t" $1}' "$SC/m.out" >> "$SC/hits.tsv"
  done
}
count_matches() { # FLAGS PATTERN -> total matches over all streams
  _t=0
  for s in $STREAMS; do
    [ -s "$SC/$s.txt" ] || continue
    grep -a -o $1 -e "$2" "$SC/$s.txt" > "$SC/m.out" 2>/dev/null; rc=$?
    case $rc in 0) _t=$((_t + $(wc -l < "$SC/m.out"))) ;; 1) : ;; *) fail "grep failed" ;; esac
  done
  echo "$_t"
}

grep_hits home_path "-i -E" e "$P_HOME"
grep_hits user_temp "-i -E" e "$P_TEMP"
printf '%s\n' "$ACCOUNT" > "$SC/account.txt"
grep_hits user_name "-i -w -F" f "$SC/account.txt"
[ "$SKIP_ADOPTER" -eq 1 ] || grep_hits adopter_term "-i -F" f "$SC/terms.txt"
grep_hits udid "-E" e "$P_UDID"
grep_hits gh_token "-i -E" e "$P_GH"
grep_hits pem_key "-i -E" e "$P_PEM"
grep_hits credential "-i -E" e "$P_CRED"

# email: keep only addresses outside the allow list
for s in $STREAMS; do
  [ -s "$SC/$s.txt" ] || continue
  grep -a -o -b -i -E -e "$P_EMAIL" "$SC/$s.txt" > "$SC/m.out" 2>/dev/null; rc=$?
  case $rc in 0) : ;; 1) continue ;; *) fail "grep failed" ;; esac
  awk -F: -v s="$s" '
    function ew(a, b) { return length(a) >= length(b) && substr(a, length(a) - length(b) + 1) == b }
    { off = $1; m = substr($0, length($1) + 2); lm = tolower(m); at = index(lm, "@")
      loc = substr(lm, 1, at - 1); dom = substr(lm, at + 1); ok = 0
      if (loc == "noreply" || loc == "no-reply") ok = 1
      if (lm == "git@github.com") ok = 1
      if (dom == "users.noreply.github.com" || ew(dom, ".users.noreply.github.com")) ok = 1
      n = split("example.com example.org example.net localhost", A, " ")
      for (i = 1; i <= n; i++) if (dom == A[i] || ew(dom, "." A[i])) ok = 1
      n = split("example test invalid localhost", B, " ")
      for (i = 1; i <= n; i++) if (ew(dom, "." B[i])) ok = 1
      if (!ok) print "email\t" s "\t" off }' "$SC/m.out" >> "$SC/hits.tsv"
done

# author_name: identity names that are not among main's author and committer names
g "$REPO" log --format='%an%n%cn' "$BASE" > "$SC/mainnames.txt" 2>/dev/null || fail "log failed"
[ -s "$SC/mainnames.txt" ] || fail "empty main names"
LC_ALL=C awk -F'\t' '
  NR == FNR { ok[$0] = 1; next }
  { if (!($1 in ok)) print "author_name\tid\t" off; off += length($0) + 1 }
  BEGIN { off = 0 }' "$SC/mainnames.txt" "$SC/id.txt" >> "$SC/hits.tsv" || fail "awk failed"

# triage-only counts (never blocking)
T_UUID=$(count_matches "-i -E" "$P_UUID")
T_BW=$(count_matches "-i -E" "$P_BW")
T_H40=$(count_matches "-E" "$P_H40")

# ---------------------------------------------------------------- map hits to objects
cat > "$SC/map.awk" <<'AWK'
BEGIN { FS = "\t" }
FNR == NR { n++; st[n] = $1 + 0; ob[n] = $2; cm[n] = $3; bl[n] = $4; ex[n] = $5; next }
{ c = $1; off = $2 + 0; lo = 1; hi = n; res = 0
  while (lo <= hi) { mid = int((lo + hi) / 2); if (st[mid] <= off) { res = mid; lo = mid + 1 } else hi = mid - 1 }
  if (res == 0) { print "ERR"; next }
  print c "\t" P "\t" ob[res] "\t" cm[res] "\t" bl[res] "\t" ex[res] "\t" (off - st[res]) }
AWK
: > "$SC/recs.tsv"
for s in $STREAMS; do
  case $s in al) pos=added_line ;; bl) pos=blob ;; pa) pos=path ;; id) pos=identity ;; ms) pos=message ;; tg) pos=tag ;; nt) pos=note ;; esac
  awk -F'\t' -v s="$s" '$2 == s { print $1 "\t" $3 }' "$SC/hits.tsv" > "$SC/h.$s"
  [ -s "$SC/h.$s" ] || continue
  [ -s "$SC/$s.idx" ] || fail "index missing"
  LC_ALL=C awk -v P="$pos" -f "$SC/map.awk" "$SC/$s.idx" "$SC/h.$s" >> "$SC/recs.tsv" || fail "awk failed"
done
grep -q '^ERR' "$SC/recs.tsv" && fail "offset map failed"

# ---------------------------------------------------------------- D-20 ladder
g "$REPO" ls-tree -r "$HEADC" 2>/dev/null | awk '{print $3}' > "$SC/headblobs.txt"; [ "${PIPESTATUS[0]}" -eq 0 ] || fail "ls-tree failed"
g "$REPO" ls-tree -r -t --name-only "$HEADC" > "$SC/headpaths.txt" 2>/dev/null || fail "ls-tree failed"
: > "$SC/pres.txt"
if [ -n "$PRESC" ]; then g "$REPO" rev-list "$BASE..$PRESC" > "$SC/pres.txt" 2>/dev/null || fail "rev-list failed"; fi
cat > "$SC/ladder.awk" <<'AWK'
BEGIN { FS = "\t" }
FILENAME == F_HB { hb[$0] = 1; next }
FILENAME == F_HP { hp[$0] = 1; next }
FILENAME == F_PR { pr[$0] = 1; npres++; next }
FILENAME == F_BC { split($0, a, " "); bh[a[1]] = 1; if (!(a[2] in pr)) bn[a[1]] = 1; next }
{ n++; rec[n] = $0; if ($2 == "added_line") al[$1 SUBSEP $5] = 1 }
END {
  for (i = 1; i <= n; i++) {
    split(rec[i], f, "\t"); c = f[1]; pos = f[2]; obj = f[3]; cm = f[4]; bl = f[5]; ex = f[6]; rel = f[7]
    if (pos == "blob" && ((c SUBSEP bl) in al)) continue
    fin = 1
    if (pos == "added_line") fin = (!(cm in pr)) || (bl in hb)
    else if (pos == "blob") fin = (bl in hb) || !(bl in bh) || (bl in bn)
    else if (pos == "path") {
      if (ex in hp) fin = 1
      else if (bl != "-") fin = !(bl in bh) || (bl in bn)
      else fin = (npres == 0)
    } else fin = !(cm in pr)
    if (fin) cat = "final"
    else if (c == "home_path" || c == "user_temp" || c == "user_name") cat = "hist_personal"
    else cat = "hist_sensitive"
    print cat "\t" c "\t" pos "\t" obj "\t" rel
  }
}
AWK
LC_ALL=C awk -v F_HB="$SC/headblobs.txt" -v F_HP="$SC/headpaths.txt" -v F_PR="$SC/pres.txt" -v F_BC="$SC/blobcommit.txt" \
  -f "$SC/ladder.awk" "$SC/headblobs.txt" "$SC/headpaths.txt" "$SC/pres.txt" "$SC/blobcommit.txt" "$SC/recs.tsv" > "$SC/ladder.out" || fail "awk failed"

BF=0; HP=0; HS=0; TR=0; HPH=0; HPT=0; HPU=0
: > "$SC/seen.txt"; : > "$SC/printed.txt"; : > "$SC/rungs.txt"
while IFS="	" read -r cat class pos obj rel; do
  fp=$(printf '%s' "$class:$obj:$rel" | shasum -a 256 | cut -c1-64)
  [ -n "$fp" ] || fail "fingerprint failed"
  grep -q -x "$fp" "$SC/seen.txt" && continue
  printf '%s\n' "$fp" >> "$SC/seen.txt"
  if grep -q -x "$fp" "$SC/triaged.txt"; then TR=$((TR + 1)); continue; fi
  case $cat in
    final) BF=$((BF + 1)); printf 'scan: hit %s %s %s\n' "$class" "$pos" "$fp" >> "$SC/printed.txt" ;;
    hist_sensitive) HS=$((HS + 1)); printf 'scan: hit %s %s %s\n' "$class" "$pos" "$fp" >> "$SC/printed.txt"; printf '%s\n' "$class" >> "$SC/rungs.txt" ;;
    hist_personal)
      HP=$((HP + 1)); printf 'scan: accepted %s %s %s\n' "$class" "$pos" "$fp" >> "$SC/printed.txt"
      case $class in home_path) HPH=$((HPH + 1)) ;; user_temp) HPT=$((HPT + 1)) ;; user_name) HPU=$((HPU + 1)) ;; esac ;;
  esac
done < "$SC/ladder.out"
[ "$((HPH + HPT + HPU))" -eq "$HP" ] || fail "personal split mismatch"

# ---------------------------------------------------------------- gitleaks (secret layer)
GLENV=$(env | sed -n -e 's/^\(GIT_[A-Za-z0-9_]*\)=.*/-u \1/p' -e 's/^\(GITLEAKS_[A-Za-z0-9_]*\)=.*/-u \1/p' | tr '\n' ' ')
run_gl() { # REPO LOGOPTS FORMAT REPORT [IGNORE_FILE]
  _gi=${5:-"$SC/glignore.empty"}
  env $GLENV GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    gitleaks git --no-banner --redact "--log-opts=$2" --report-format "$3" --report-path "$4" --gitleaks-ignore-path "$_gi" --ignore-gitleaks-allow "$1" > /dev/null 2>&1
}
: > "$SC/glignore.empty"
run_gl "$REPO" "$RANGE" json "$SC/gl.json" "$SC/glignore.txt"; glrc=$?
case $glrc in 0|1) : ;; *) fail "gitleaks failed" ;; esac
[ -f "$SC/gl.json" ] || fail "gitleaks failed"
GL_FIND=$(grep -c '"RuleID"' "$SC/gl.json"); GL_FIND=$((GL_FIND + 0))
if [ "$glrc" -eq 1 ] && [ "$GL_FIND" -eq 0 ]; then fail "gitleaks failed"; fi
# rule count from a SARIF report over a fixed one-commit repo (no findings are expected there)
GR="$SC/glrules"; mkdir "$GR" || fail "scratch failed"
g "$GR" init -q -b main > /dev/null 2>&1 || fail "gitleaks failed"
printf 'plain\n' > "$GR/a.txt"
g "$GR" add a.txt > /dev/null 2>&1 || fail "gitleaks failed"
g "$GR" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q -m one > /dev/null 2>&1 || fail "gitleaks failed"
run_gl "$GR" "HEAD" sarif "$SC/gl.sarif"; srcode=$?
case $srcode in 0|1) : ;; *) fail "gitleaks failed" ;; esac
GL_RULES=$(awk '/"rules":[[:space:]]*\[/ { f = 1 } /"results"/ { f = 0 } f && /"id":/ { n++ } END { print n + 0 }' "$SC/gl.sarif")
echo "scan: gitleaks_version $GLV"
echo "scan: gitleaks_rules $GL_RULES"
echo "scan: gitleaks_findings $GL_FIND"

# ---------------------------------------------------------------- results
sort "$SC/printed.txt" | while IFS= read -r l; do printf '%s\n' "$l"; done
echo "scan: blocking_final $BF"
echo "scan: history_personal $HP"
echo "scan: history_personal_class home_path $HPH"
echo "scan: history_personal_class user_temp $HPT"
echo "scan: history_personal_class user_name $HPU"
echo "scan: history_sensitive $HS"
echo "scan: triaged $TR"
echo "scan: triage_only uuid $T_UUID"
echo "scan: triage_only bare_word $T_BW"
echo "scan: triage_only bare_hex40 $T_H40"
sort -u "$SC/rungs.txt" | while IFS= read -r c; do [ -n "$c" ] && echo "scan: rung $c"; done
if [ "$((BF + HS + GL_FIND))" -gt 0 ]; then
  echo "scan: result hits"
  exit 1
fi
echo "scan: result clean"
exit 0
