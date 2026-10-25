#!/usr/bin/env bash
# assemble-inventory-189.sh - builds PD/189-INVENTORY.md from PD/189-EVIDENCE/rows-*.md
set -u
umask 077
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
EV="$PD/189-EVIDENCE"
OUTF="$PD/189-INVENTORY.md"
TMPF=$(mktemp "$RUNS/inv.XXXXXX") || exit 3
ROWS=$(mktemp "$RUNS/invrows.XXXXXX") || exit 3
for f in "$EV"/rows-*.md; do [ -f "$f" ] && grep '^|' "$f" >> "$ROWS"; done
bad=$(awk -F'|' '
  { n=NF-2
    if (n!=9) {print "cells " n; next}
    c=$6; gsub(/^ +| +$/,"",c)
    k=$7; gsub(/^ +| +$/,"",k)
    if (c !~ /^[0-9]+$/) {print "count"; next}
    if (k!="on main" && k!="to land" && k!="obsolete" && k!="unclassified") print "class"
  }' "$ROWS")
if [ -n "$bad" ]; then echo "assemble: FAIL bad rows: $(printf '%s\n' "$bad" | sort | uniq -c | tr '\n' ';')"; rm -f "$TMPF" "$ROWS"; exit 1; fi
{
  echo "# Phase 189 Inventory"
  echo
  echo "This inventory lists what the frozen recovery checkout holds (references, reflog commits, stashes, branches, files, temporary clones and the candidate), where each item is backed up, how its restore was checked, and whether its content is already on main, still to land, obsolete or unclassified. Paths are written as placeholders only (<recovery-checkout>, <backup-root>, <tmp>); no identity, credential or customer detail is recorded."
  echo
  echo "## Classes"
  echo
  echo "- on main: the content is already in main (ancestry, or patch-equivalence with every changed path matching main)."
  echo "- to land: the content is in the candidate and lands with it."
  echo "- obsolete: judged unneeded by a stated, checked reason."
  echo "- unclassified: backed up, but the user decides before Phase 193."
  echo
  for s in "$EV"/scope-note-*.md; do [ -f "$s" ] && { cat "$s"; echo; }; done
  echo "## Items"
  echo
  echo "| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |"
  echo "|---|---|---|---|---|---|---|---|---|"
  cat "$ROWS"
  if [ -f "$EV/pr-table.md" ]; then echo; cat "$EV/pr-table.md"; fi
} > "$TMPF"
mv "$TMPF" "$OUTF"; rm -f "$ROWS"
echo "assemble: ok ($(grep -c '^| [A-Z]' "$OUTF") rows)"
