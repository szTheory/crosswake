#!/bin/sh
# Phase 191 finalize (D-09, D-18-D-22, A-9, A-14, A-15). Prints only `finalize:` labels.
# Modes:
#   finalize-191.sh                  sync late records, verify the full carry, re-check, scan HEAD
#   finalize-191.sh --scan-only      run only the HEAD-bound scan (no sync)
#   finalize-191.sh --check-binding  exit 0 only when EV/scan-191.txt is bound to the clone HEAD
# Env: FINALIZE_STOP_BEFORE_SCAN=1 stops after the sync-HEAD checks (exit 3, `scan pending`).
# Exit 0 pass, 1 check failed, 2 scope or input error, 3 stopped before the scan.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
sh "$HERE/locate-191.sh" >/dev/null || { echo "finalize: locate failed"; exit 2; }
. /private/tmp/crosswake-phase191-run/env-191.sh
. "$HERE/git-pinned-191.sh"

fail() { echo "finalize: $1"; exit "${2:-1}"; }

MODE=${1:-}
case "$MODE" in
  ''|--scan-only|--check-binding) : ;;
  *) fail "usage" 2 ;;
esac

if [ "$MODE" = "--check-binding" ]; then
  SC="$EV/scan-191.txt"
  H=$(g "$IC" rev-parse HEAD 2>/dev/null) || H=""
  if [ -n "$H" ] && [ -f "$SC" ] && grep -qx "head $H" "$SC" && grep -qx "main $MAIN_SHA" "$SC" && grep -qx 'scan_exit 0' "$SC"; then
    echo "finalize: binding pass"; exit 0
  fi
  echo "finalize: binding fail"; exit 1
fi

# (a) clone, branch, clean tree
sh "$HERE/ensure-clone-191.sh" > "$R191/fin-ensure.out" 2>&1
grep -qx 'ensure-clone: reused' "$R191/fin-ensure.out" || fail "clone not reusable" 2
[ "$(g "$IC" rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || fail "clone on wrong branch" 2
[ -z "$(g "$IC" status --porcelain=v1 --untracked-files=all)" ] || fail "clone dirty" 2

STATE="$R191/fin-state.txt"

SYNC_DONE=none

if [ "$MODE" = "" ]; then
  : > "$STATE"
  # (b) manifest of late records against the integration HEAD
  rm -rf "$R191/sync" "$R191/sync.d" "$R191/sync.src"
  bash "$HERE/carry-191.sh" manifest --sync "$REC" "$IC" HEAD "$HERE/carry-table-191.tsv" "$HERE/carry-exclusions-191.tsv" "$R191/sync" > "$R191/sync.out" 2>&1
  mrc=$?
  if [ "$mrc" -eq 2 ] && grep -qx 'carry: empty delta' "$R191/sync.out"; then
    echo "finalize: sync none"
    printf 'sync none\nsync_paths 0\n' >> "$STATE"
  elif [ "$mrc" -ne 0 ]; then
    cat "$R191/sync.out"
    fail "sync_failed" 2
  else
    MD=$(sed -n 's/^carry: manifest_sha256 //p' "$R191/sync.out")
    [ -n "$MD" ] || fail "sync_failed" 2
    NP=$(wc -l < "$R191/sync" | tr -d ' ')
    bash "$HERE/carry-191.sh" apply "$IC" "$R191/sync" ALL > "$R191/sync-apply.out" 2>&1 || { cat "$R191/sync-apply.out"; fail "sync_failed" 2; }
    MSG=$(mktemp "$R191/fin-msg.XXXXXX") || fail "sync_failed" 2
    {
      printf 'docs(planning): sync Phase 191 records written after the cut\n\n'
      printf 'This commit is a snapshot of planning records that changed in the recovery\n'
      printf 'working tree after the previous carry commit, not their original authorship\n'
      printf 'history. The original history is kept in the Phase 189 refs-all.bundle.\n\n'
      printf 'Planning-Carry: sync\n'
      printf 'Planning-Carry-Manifest: sha256:%s\n' "$MD"
      printf 'Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>\n'
    } > "$MSG"
    bash "$HERE/carry-191.sh" commit-bucket "$IC" "$R191/sync" ALL "$MSG" > "$R191/sync-commit.out" 2>&1 || { cat "$R191/sync-commit.out"; fail "sync_failed" 2; }
    SYNC_DONE=committed
    SYNC_SHA=$(g "$IC" rev-parse HEAD)
    printf 'sync committed\nsync_paths %s\n' "$NP" >> "$STATE"
    echo "finalize: sync committed"
  fi

  # (c) full manifest against main, independent floor, verify
  rm -rf "$R191/fin-full" "$R191/fin-full.d" "$R191/fin-full.src" "$R191/fin-floor"
  bash "$HERE/carry-191.sh" manifest "$REC" "$IC" "$MAIN_SHA" "$HERE/carry-table-191.tsv" "$HERE/carry-exclusions-191.tsv" "$R191/fin-full" > "$R191/fin-full.out" 2>&1 || { cat "$R191/fin-full.out"; fail "verify_failed" 2; }
  sh "$HERE/carry-floor-191.sh" "$REC" "$IC" "$MAIN_SHA" "$HERE/carry-exclusions-191.tsv" "$HERE/../../189-inventory-and-backup/189-INVENTORY.md" "$R191/fin-floor" > "$R191/fin-floor.out" 2>&1 || { cat "$R191/fin-floor.out"; fail "verify_failed" 2; }
  FA=$(sed -n 's/^floor_a //p' "$R191/fin-floor/floor.txt")
  FD=$(sed -n 's/^floor_d //p' "$R191/fin-floor/floor.txt")
  MA=$(sed -n 's/^carry: delta A \([0-9]*\) M \([0-9]*\) D \([0-9]*\)$/\1/p' "$R191/fin-full.out")
  MDD=$(sed -n 's/^carry: delta A \([0-9]*\) M \([0-9]*\) D \([0-9]*\)$/\3/p' "$R191/fin-full.out")
  if [ "$MA" != "$FA" ] || [ "$MDD" != "$FD" ]; then
    echo "finalize: floor_mismatch manifest_a $MA floor_a $FA manifest_d $MDD floor_d $FD"
    exit 2
  fi
  bash "$HERE/carry-191.sh" verify "$IC" "$MAIN_SHA" "$R191/fin-full" "$R191/fin-floor/floor-n" > "$R191/fin-verify.out" 2>&1
  if [ $? -ne 0 ]; then cat "$R191/fin-verify.out"; fail "verify_failed" 1; fi
  echo "finalize: verify pass"
  printf 'verify pass\n' >> "$STATE"

  # heads record (after verify: heads-191.txt is itself a carried record)
  if [ "$SYNC_DONE" = committed ]; then
    NS=$(grep -c '^SYNC' "$EV/heads-191.txt")
    if [ "$NS" -eq 0 ]; then LBL=SYNC; else LBL="SYNC-$((NS + 1))"; fi
    printf '%s %s\n' "$LBL" "$SYNC_SHA" >> "$EV/heads-191.txt"
  fi

  # (d) re-checks at the sync HEAD
  HEADNOW=$(g "$IC" rev-parse HEAD)
  NB=$(grep -v '^SYNC' "$EV/heads-191.txt" | tail -n 1 | awk '{print $2}')
  g "$IC" diff --name-only "$NB" HEAD > "$R191/fin-nonplan.txt" 2>/dev/null || fail "verify_failed" 2
  NPN=$(grep -vc '^\.planning/' "$R191/fin-nonplan.txt")
  # A-15: code commits up to the FIXTURE head are outside this check; only the later commits must touch .planning/ alone
  printf 'non_planning_paths %s\n' "$NPN" >> "$STATE"
  [ "$NPN" -eq 0 ] || fail "sync_checks_failed" 1
  if [ "$SYNC_DONE" = committed ]; then
    FLOOR=$(sed -n 's/^resolver_tests //p' "$EV/checkpoints-191.txt")
    case "$FLOOR" in ''|*[!0-9]*) fail "floor_mismatch" 2 ;; esac
    sh "$HERE/suite-gate-191.sh" root "$IC" "$HEADNOW" root-SYNC "$FLOOR" > "$R191/fin-root.out" 2>&1
    if [ $? -ne 0 ]; then cat "$R191/fin-root.out"; fail "sync_checks_failed" 1; fi
    echo "finalize: root suite pass"
    printf 'root_suite pass\n' >> "$STATE"
    sh "$HERE/suite-gate-191.sh" subset "$IC" "$HEADNOW" SYNC "$R191/empty-red.txt" \
      test/crosswake/planning test/crosswake/proof test/mix/tasks/crosswake_release_status_test.exs \
      test/mix/tasks/crosswake_adoption_context_scan_test.exs test/crosswake/release_candidate/evidence_live_test.exs > "$R191/fin-subset.out" 2>&1
    if [ $? -ne 0 ]; then cat "$R191/fin-subset.out"; fail "sync_checks_failed" 1; fi
    echo "finalize: subset pass"
    printf 'subset pass\n' >> "$STATE"
    (
      cd "$IC" || exit 2
      export LC_ALL=C.UTF-8
      node --test test/js/phase167_pr_dispositions.test.mjs > "$R191/fin-c-phase167_js.out" 2>&1; echo $? > "$R191/fin-c-phase167_js.rc"
      mix crosswake.adoption_context.scan > "$R191/fin-c-adoption_scan.out" 2>&1; echo $? > "$R191/fin-c-adoption_scan.rc"
      elixir script/check_release_workflow_integrity.exs > "$R191/fin-c-integrity_script.out" 2>&1; echo $? > "$R191/fin-c-integrity_script.rc"
      elixir script/inventory_collection_assertions.exs --check > "$R191/fin-c-ledger_check.out" 2>&1; echo $? > "$R191/fin-c-ledger_check.rc"
    )
    for c in phase167_js adoption_scan integrity_script ledger_check; do
      rc=$(cat "$R191/fin-c-$c.rc" 2>/dev/null || echo 9)
      printf 'check %s exit %s\n' "$c" "$rc" >> "$STATE"
      [ "$rc" = 0 ] || fail "sync_checks_failed" 1
    done
    [ -z "$(g "$IC" status --porcelain=v1 --untracked-files=all)" ] || fail "clone dirty after checks" 1
    echo "finalize: checks pass"
  else
    printf 'root_suite not_needed\nsubset not_needed\n' >> "$STATE"
    for c in phase167_js adoption_scan integrity_script ledger_check; do printf 'check %s not_needed\n' "$c" >> "$STATE"; done
  fi
  printf 'result pass\n' >> "$STATE"
  if [ "${FINALIZE_STOP_BEFORE_SCAN:-}" = 1 ]; then echo "finalize: scan pending"; exit 3; fi
fi

# (e) HEAD-bound scan (A-14: adopter-term check skipped by the user's decision)
HEADNOW=$(g "$IC" rev-parse HEAD)
unset CROSSWAKE_PRIVATE_ADOPTER_TERMS
SCAN191_ADOPTER_SKIP=A-14 bash "$HERE/scan-191.sh" "$IC" "$MAIN_SHA" HEAD "$CAND_HEAD" > "$R191/fin-scan.out" 2>&1
src=$?
echo "$src" > "$R191/fin-scan.rc"
if [ "$src" -eq 2 ]; then cat "$R191/fin-scan.out"; fail "scan_scope_error" 2; fi
TMPS=$(mktemp "$EV/.scan-191.XXXXXX") || fail "scan_scope_error" 2
{
  printf 'head %s\n' "$HEADNOW"
  printf 'main %s\n' "$MAIN_SHA"
  printf 'preserved %s\n' "$CAND_HEAD"
  printf 'scan_exit %s\n' "$src"
  printf 'adopter_check skipped_by_user_decision A-14\n'
  grep '^scan: ' "$R191/fin-scan.out"
} > "$TMPS"
chmod 600 "$TMPS"
mv -f "$TMPS" "$EV/scan-191.txt" || fail "scan_scope_error" 2
if [ "$src" -ne 0 ]; then
  grep '^scan: ' "$R191/fin-scan.out"
  fail "scan has hits (exit $src)" 1
fi
echo "finalize: head $HEADNOW scan clean"
exit 0
