#!/bin/bash
# Phase 194 SC4 one-time evidence: only dated history and refute pins may still say Android is frozen.
# Modes: run [--root DIR] | --ref REV [--root DIR] | --self-test.  Labels only: never prints matched text.
# Exit: 0 pass, 1 hit-set mismatch / posture missing / control behaved, 2 input or tool error.
set -u
umask 077
export LC_ALL=C

PAT='(android[^.\n]{0,80}\b(is|are|remains?|stays?|retains?)\b[^.\n]{0,20}\bfrozen\b)|(\bfrozen\b[^.\n]{0,60}\bandroid\b)|(android[^.\n]{0,60}\bfrozen\b)'
POSTURE_A='Android is unfrozen only for proof and parity of existing contracts'
POSTURE_B='Android proof and parity cover existing contracts only.'
POSTURE_C='Android (existing contracts)'
POSTURE_ADR2='## A2 — Synthetic-profile reversal gate'

SCOPE='AGENTS.md .planning/ADR-FIRST-B2C-ADOPTER.md .planning/PROJECT.md lib/crosswake/support_matrix/support_matrix.ex lib/crosswake/support_matrix/renderer.ex lib/crosswake/capability_map/renderer.ex lib/crosswake/proof_lane/provenance.ex guides/support_matrix.md guides/capability_map.md guides/native_shell.md test/crosswake/support_matrix/renderer_test.exs test/crosswake/support_matrix/support_matrix_test.exs examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json'
# index:needle-kind (A, B, C, N = file only needs to exist; AD = A plus the A2 heading)
POSTURE_KINDS='1:A 2:AD 3:A 4:B 5:C 6:A 7:N 8:B 9:A 10:B 11:B 12:N 13:B 14:B'
JOINED_INDEXES='1 2 3 10'

# Allowlist: <scope path><TAB><whitespace-normalized text><TAB><class>; class history or refute-pin.
ALLOW='.planning/ADR-FIRST-B2C-ADOPTER.md	`push_patch` does not change native stack depth. Android implementation remains frozen during v21.	history
.planning/PROJECT.md	shell marker, and automated proof. Android implementation and parity remain frozen.	history
.planning/PROJECT.md	Phoenix confirmation remains required; Android remains frozen; Phase 162 alone owns	history
.planning/PROJECT.md	After v19.0, Crosswake has a product-shaped proof surface with three fictional showcase lanes. Its earlier native-controls/breadth sequence was stopped by the first-adopter ADR. The governing priority remains one real Phoenix application on one physical iPhone, with explicit route ownership and one honest offline mutation island. Adopter execution remains parked on its recorded external gate; Android breadth, new controls/companions, dashboard and generic sync/storage remain frozen.	history
test/crosswake/support_matrix/renderer_test.exs	"Android is frozen at its existing generator, Maven, JVM, and shared-vector posture."	refute-pin
test/crosswake/support_matrix/renderer_test.exs	"Android retains its frozen generator, Maven, JVM, and shared-vector posture.",	refute-pin
test/crosswake/support_matrix/renderer_test.exs	"Android is frozen during first adopter iOS readiness"	refute-pin'

SELF="${BASH_SOURCE[0]}"
SCRATCH=''
cleanup() { if [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ]; then rm -rf "$SCRATCH"; fi; }
trap cleanup EXIT

norm() { perl -pe 's/^\s+|\s+$//g; s/\s+/ /g; $_ .= "\n"'; }

# scan_tree TREE OUTDIR: sets MISSING_IDX (space list) and writes OUTDIR/hits.tsv (path<TAB>normalized line)
scan_tree() {
  tree=$1; out=$2; : > "$out/hits.raw"; MISSING_IDX=''; i=0
  for f in $SCOPE; do
    i=$((i + 1))
    if [ ! -r "$tree/$f" ]; then MISSING_IDX="$MISSING_IDX $i"; continue; fi
    rg -i -P -N --no-filename -e "$PAT" "$tree/$f" > "$out/lines.$i" 2> "$out/err.$i"; rc=$?
    if [ "$rc" -gt 1 ]; then echo "sc4: tool error $i"; return 2; fi
    norm < "$out/lines.$i" | while IFS= read -r l; do printf '%s\t%s\n' "$f" "$l"; done >> "$out/hits.raw"
  done
  sort -u "$out/hits.raw" > "$out/hits.tsv"
  return 0
}

allow_keys() { printf '%s\n' "$ALLOW" | awk -F'\t' 'NF==3 {print $1 "\t" $2}' | sort -u; }

scope_index() { # path -> index
  i=0; for f in $SCOPE; do i=$((i + 1)); [ "$f" = "$1" ] && { echo "$i"; return; }; done; echo 0
}

posture_ok() { # TREE FILE NEEDLE
  N=$3 perl -0777 -ne 's/\s+/ /g; exit(index($_, $ENV{N}) >= 0 ? 0 : 1)' "$1/$2"
}

do_run() {
  tree=$1
  SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/cw194-sc4.XXXXXX") || { echo "sc4: tool error scratch"; return 2; }
  n=0; for f in $SCOPE; do n=$((n + 1)); done
  if [ "$n" -eq 0 ]; then echo "sc4: input missing 0"; return 2; fi
  echo "sc4: scope files $n"
  scan_tree "$tree" "$SCRATCH"; rc=$?
  [ "$rc" -ne 0 ] && return 2
  if [ -n "$MISSING_IDX" ]; then
    for m in $MISSING_IDX; do echo "sc4: input missing $m"; done
    return 2
  fi
  allow_keys > "$SCRATCH/allow.keys"
  hits=$(awk 'END{print NR}' "$SCRATCH/hits.tsv"); alw=$(awk 'END{print NR}' "$SCRATCH/allow.keys")
  echo "sc4: hits $hits"; echo "sc4: allowlisted $alw"
  fail=0
  comm -13 "$SCRATCH/allow.keys" "$SCRATCH/hits.tsv" | while IFS= read -r k; do
    echo "sc4: hit new file $(scope_index "${k%%	*}")"; done > "$SCRATCH/new.out"
  comm -23 "$SCRATCH/allow.keys" "$SCRATCH/hits.tsv" | awk -F'\t' '{print NR "\t" $1}' | while IFS= read -r k; do
    e=${k%%	*}; p=${k#*	}; echo "sc4: allow vanished $e file $(scope_index "$p")"; done > "$SCRATCH/van.out"
  cat "$SCRATCH/new.out" "$SCRATCH/van.out"
  if [ -s "$SCRATCH/new.out" ] || [ -s "$SCRATCH/van.out" ]; then fail=1; fi
  # joined-text pass
  for i in $JOINED_INDEXES; do
    f=$(printf '%s\n' $SCOPE | awk -v i="$i" 'NR==i')
    perl -0777 -pe 's/\s*\n\s*/ /g' "$tree/$f" > "$SCRATCH/joined.$i"
    rg -o -i -P -N --no-filename -e "$PAT" "$SCRATCH/joined.$i" > "$SCRATCH/jm.$i" 2> /dev/null; rc=$?
    if [ "$rc" -gt 1 ]; then echo "sc4: tool error joined $i"; return 2; fi
    jbad=0
    while IFS= read -r m; do
      [ -z "$m" ] && continue
      ok=0
      while IFS= read -r a; do
        ap=${a%%	*}; [ "$ap" = "$f" ] || continue
        at=${a#*	}
        case "$at" in *"$m"*) ok=1; break ;; esac
      done < "$SCRATCH/allow.keys"
      [ "$ok" -eq 0 ] && jbad=1
    done < <(norm < "$SCRATCH/jm.$i")
    if [ "$jbad" -ne 0 ]; then echo "sc4: hit joined file $i"; fail=1; fi
  done
  # posture
  pcount=0; pbad=0
  for kv in $POSTURE_KINDS; do
    i=${kv%%:*}; k=${kv#*:}
    f=$(printf '%s\n' $SCOPE | awk -v i="$i" 'NR==i')
    ok=1
    case "$k" in
      A)  posture_ok "$tree" "$f" "$POSTURE_A" || ok=0 ;;
      AD) posture_ok "$tree" "$f" "$POSTURE_A" || ok=0
          posture_ok "$tree" "$f" "$POSTURE_ADR2" || ok=0 ;;
      B)  posture_ok "$tree" "$f" "$POSTURE_B" || ok=0 ;;
      C)  posture_ok "$tree" "$f" "$POSTURE_C" || ok=0 ;;
      N)  : ;;
    esac
    if [ "$ok" -eq 1 ]; then pcount=$((pcount + 1)); else echo "sc4: posture missing $i"; pbad=1; fi
  done
  [ "$pbad" -eq 0 ] && echo "sc4: posture ok $pcount"
  [ "$pbad" -ne 0 ] && fail=1
  if [ "$fail" -eq 0 ]; then echo "sc4: result pass hits $hits allowlisted $alw"; return 0; fi
  echo "sc4: result fail"; return 1
}

do_ref() { # ROOT REV
  root=$1; rev=$2
  SCRATCH=$(mktemp -d "${TMPDIR:-/tmp}/cw194-sc4.XXXXXX") || { echo "sc4: tool error scratch"; return 2; }
  mkdir -p "$SCRATCH/tree" "$SCRATCH/out"
  i=0
  for f in $SCOPE; do
    i=$((i + 1)); mkdir -p "$SCRATCH/tree/$(dirname "$f")"
    if ! git -C "$root" show "$rev:$f" > "$SCRATCH/tree/$f" 2> /dev/null; then echo "sc4: input missing $i"; return 2; fi
  done
  scan_tree "$SCRATCH/tree" "$SCRATCH/out"; rc=$?
  [ "$rc" -ne 0 ] && return 2
  hits=$(awk 'END{print NR}' "$SCRATCH/out/hits.tsv")
  echo "sc4: control hits $hits"
  if [ "$hits" -ge 8 ]; then return 1; fi
  echo "sc4: control too weak"; return 2
}

# ---- self-test ----
ST_N=0; ST_OK=0
expect() { # NAME WANT_RC WANT_LABEL_REGEX GOT_RC OUTFILE
  ST_N=$((ST_N + 1))
  if [ "$4" -eq "$2" ] && { [ -z "$3" ] || grep -Eq "$3" "$5"; }; then ST_OK=$((ST_OK + 1)); echo "control $1: ok"; else echo "control $1: unexpected (rc $4)"; fi
}

self_test() {
  root=$(git rev-parse --show-toplevel 2> /dev/null) || { echo "sc4: tool error root"; return 2; }
  st=$(mktemp -d "${TMPDIR:-/tmp}/cw194-st.XXXXXX") || return 2
  SCRATCH_ST=$st
  trap 'rm -rf "$SCRATCH_ST"; cleanup' EXIT
  fx="$st/fx"; mkdir -p "$fx"
  for f in $SCOPE; do mkdir -p "$fx/$(dirname "$f")"; cp "$root/$f" "$fx/$f" || { echo "sc4: input missing copy"; return 2; }; done
  reset() { for f in $SCOPE; do cp "$root/$f" "$fx/$f"; done; }
  o="$st/o.txt"

  reset; bash "$SELF" run --root "$fx" > "$o" 2>&1; expect clean-pass 0 '^sc4: result pass hits [0-9]+ allowlisted [0-9]+$' $? "$o"

  reset; printf '%s\n' '- Android is frozen at its current posture.' >> "$fx/AGENTS.md"
  bash "$SELF" run --root "$fx" > "$o" 2>&1; expect new-hit 1 '^sc4: hit new file 1$' $? "$o"

  reset; perl -ni -e 'print unless /Android implementation remains frozen during v21/' "$fx/.planning/ADR-FIRST-B2C-ADOPTER.md"
  bash "$SELF" run --root "$fx" > "$o" 2>&1; expect vanished-allow 1 '^sc4: allow vanished [0-9]+ file 2$' $? "$o"

  reset; rm -f "$fx/guides/native_shell.md"
  bash "$SELF" run --root "$fx" > "$o" 2>&1; expect missing-file 2 '^sc4: input missing 10$' $? "$o"

  reset; perl -0777 -pi -e 's/Android\s+is\s+unfrozen\s+only/Android is limited only/g' "$fx/.planning/PROJECT.md"
  bash "$SELF" run --root "$fx" > "$o" 2>&1; expect posture-missing 1 '^sc4: posture missing 3$' $? "$o"

  reset; printf '%s\n' '- Android' '  remains frozen here.' >> "$fx/AGENTS.md"
  bash "$SELF" run --root "$fx" > "$o" 2>&1; expect joined-wrap 1 '^sc4: hit joined file 1$' $? "$o"

  reset; printf '%s\n' '- Android is unfrozen for proof and parity here.' >> "$fx/AGENTS.md"
  bash "$SELF" run --root "$fx" > "$o" 2>&1; expect unfrozen-not-hit 0 '^sc4: result pass' $? "$o"

  # --ref control against a fixture git repo holding old-style text
  rr="$st/refrepo"; mkdir -p "$rr"; reset
  for f in $SCOPE; do mkdir -p "$rr/$(dirname "$f")"; cp "$fx/$f" "$rr/$f"; done
  n=0; while [ "$n" -lt 9 ]; do n=$((n + 1)); printf '%s\n' "- Android is frozen at its posture $n." >> "$rr/AGENTS.md"; done
  git -C "$rr" init -q . && git -C "$rr" add -A . && git -C "$rr" -c user.email=st@example.invalid -c user.name=st commit -q -m old
  bash "$SELF" --ref HEAD --root "$rr" > "$o" 2>&1; expect ref-control-strong 1 '^sc4: control hits [0-9]+$' $? "$o"

  # weak control: a ref with no old text must be refused as too weak (exit 2)
  rw="$st/weakrepo"; mkdir -p "$rw"
  for f in $SCOPE; do mkdir -p "$rw/$(dirname "$f")"; cp "$fx/$f" "$rw/$f"; done
  git -C "$rw" init -q . && git -C "$rw" add -A . && git -C "$rw" -c user.email=st@example.invalid -c user.name=st commit -q -m clean
  bash "$SELF" --ref HEAD --root "$rw" > "$o" 2>&1; expect ref-control-weak 2 '^sc4: control too weak$' $? "$o"

  # static: script never pipes into a line limiter
  ST_N=$((ST_N + 1))
  if grep -Eq '[|] *(ta[i]l|he[a]d)( |$)' "$SELF"; then echo "control static-no-limiter: unexpected"; else ST_OK=$((ST_OK + 1)); echo "control static-no-limiter: ok"; fi

  echo "selftest sc4-grep-194: controls $ST_OK of $ST_N as expected"
  [ "$ST_OK" -eq "$ST_N" ] && return 0
  return 1
}

mode=${1:-run}; [ $# -gt 0 ] && shift
ROOT=''; REV=''
case "$mode" in --ref) REV=${1:-}; [ $# -gt 0 ] && shift ;; esac
while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT=${2:-}; shift 2 || { echo "sc4: tool error args"; exit 2; } ;;
    *) echo "sc4: tool error args"; exit 2 ;;
  esac
done
command -v rg > /dev/null 2>&1 || { echo "sc4: tool error rg"; exit 2; }
command -v perl > /dev/null 2>&1 || { echo "sc4: tool error perl"; exit 2; }
[ -z "$ROOT" ] && ROOT=$(git rev-parse --show-toplevel 2> /dev/null)
[ -z "$ROOT" ] && { echo "sc4: tool error root"; exit 2; }
case "$mode" in
  run) do_run "$ROOT"; exit $? ;;
  --ref) [ -z "$REV" ] && { echo "sc4: tool error args"; exit 2; }; do_ref "$ROOT" "$REV"; exit $? ;;
  --self-test) self_test; exit $? ;;
  *) echo "sc4: tool error args"; exit 2 ;;
esac
