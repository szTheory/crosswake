---
phase: 169-diagnostic-legibility
reviewed: 2026-09-16T15:15:47Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - .github/workflows/phase70-proof.yml
  - .github/workflows/release-please.yml
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - lib/crosswake/release_status.ex
  - lib/mix/tasks/crosswake.release.status.ex
  - script/check_release_workflow_integrity.exs
  - script/check_required_checks_registered.sh
  - script/list_merge_blocking_checks.py
  - test/crosswake/proof/phase153_1_gate_integrity_test.exs
  - test/crosswake/proof/phase168_release_version_weld_test.exs
  - test/crosswake/proof/phase169_check_name_uniqueness_test.exs
  - test/crosswake/proof/phase169_diagnostic_legibility_test.exs
  - test/crosswake/proof/phase169_exit_contract_guard_test.exs
  - test/mix/tasks/crosswake_release_status_test.exs
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Phase 169: Code Review Report

**Reviewed:** 2026-09-16T15:15:47Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 169 wires a stable `release.workflow_integrity` owner check through
`Crosswake.ReleaseStatus`, adds a first-class `:unverifiable`/exit-3 status with
retry-and-classify logic for two distinct scanner crash shapes, widens
duplicate-display-name detection in `list_merge_blocking_checks.py`, retires
version-welded workflow display/artifact names, and adds a proof test
(`phase169_exit_contract_guard_test.exs`) that pins every entry point's literal
exit-code set against drift.

The core `lib/crosswake/release_status.ex` logic is careful and well-tested:
the crash-shape classification (`:unavailable` vs `:unverifiable`), the
scoped-vs-owner check composition, and the exit-code precedence
(`:error > :unverifiable > :warning > :ok`) all have negative-control/mutation
tests that raise loudly if their target pattern goes missing, which is the
right defense against the project's own "checks that stay green while
asserting nothing" defect class. `aggregate_status/1`, `exit_code/1`, and the
scanner's ROSTER/DONE/roster_exact self-check are all exercised both
positively and by deliberately breaking them.

Two things fall short of that bar and are called out below: one true dead-code
addition backed by a test that passes for the wrong reason (exactly the
vacuous-assertion shape this milestone targets), and one workflow display-name
rename that is now factually wrong about what its job runs.

## Warnings

### WR-01: New duplicate-name check in `check_required_checks_registered.sh` is dead code; its proof test passes for the wrong reason

**File:** `script/check_required_checks_registered.sh:93-103`
**Issue:**

This phase added a dedicated duplicate-display-name loop to the shell script:

```sh
dup_names="$(awk -F '\t' '{print $1}' "$PRODUCERS_FILE" | sort | uniq -d)"
if [ -n "$dup_names" ]; then
  while IFS= read -r dup_name; do
    ...
    echo "[crosswake] FAIL: display name '${dup_name}' has ${dup_count} producers (duplicate-producer/duplicate-display-name)." >&2
    errors=1
  done <<EOF
$dup_names
EOF
fi
```

But `PRODUCERS_FILE` is populated a few lines earlier at line 37:

```sh
python3 script/list_merge_blocking_checks.py --producers >"$PRODUCERS_FILE" || {
  echo "[crosswake] FAIL: local producer inventory failed." >&2; exit 1;
}
```

`list_merge_blocking_checks.py`'s `inventory()` (this same phase's other
change) now runs the duplicate-display-name scan unconditionally, regardless
of `--producers`/`--emitters`/`--contexts` mode, and `main()` returns exit 1
whenever `errors` is non-empty. So for **any** real duplicate display name in
the workflow tree, the `python3 ... --producers` invocation at line 37 already
exits non-zero and the shell script `exit 1`s right there — it never reaches
line 93. I confirmed this empirically with a two-workflow fixture sharing one
display name and no `--local-only` flag:

```
[crosswake] FAIL: duplicate-producer/duplicate-display-name - .github/workflows/a.yml (alpha), .github/workflows/b.yml (beta): literal context 'shell-level shared display name' has 2 producers
[crosswake]   What to do next: rename the later producer so every display name has exactly one producer.
[crosswake] FAIL: local producer inventory failed.
exit:1
```

The first line is Python's own diagnostic (stderr, not captured by the
`>"$PRODUCERS_FILE"` redirect but still visible because the shell doesn't
redirect its own stderr). The second line is the shell script's early-exit
generic message from line 38 — the dedicated block at lines 93-103 never runs.

The new test `test/crosswake/proof/phase169_check_name_uniqueness_test.exs`
("Task 2: the shell entry point's global-uniqueness branch fires independent
of gh") asserts `out =~ "duplicate-producer/duplicate-display-name"` against
exactly this fixture shape and passes — but it is passing because of Python's
pre-existing (this-same-phase) inventory-level check firing first, not because
of the new shell-level block it claims to prove. The test's own docstring
("proves the same guarantee at the shell entry point independent of the
Python exit code") is false: the guarantee is never exercised independent of
the Python exit code, because the Python exit code always arrives first for
this scenario.

This is precisely the "checks that stay green while asserting nothing" defect
class this quality-ratchet workstream exists to eliminate (see project
context on absence-scored-as-success) — except here the new block asserts
nothing about *itself*, and the proof test doesn't notice.

**Fix:** Either delete the dead block at lines 93-103 (the Python-level check
already covers this globally and unconditionally, so the shell-level
duplication adds no coverage), or make it reachable — e.g. by capturing
`PRODUCERS_FILE` before checking Python's exit status so the shell can
distinguish "producer inventory itself failed" from "inventory succeeded but
line 93's later, more specific check found something." If it stays, rewrite
the test to actually falsify the claim in its name, e.g. by forcing the
Python-level duplicate check to succeed (a fixture that only collides after
the `--producers`/`--emitters` cross-reference, if such a case exists) or by
asserting the *specific* `${dup_count}`-shaped message text lines 96-98 emit,
then confirming that text only appears when the Python invocation at line 37
exited 0.

## Info

### IN-01: `phase70-proof.yml`'s renamed job now misdescribes its own steps

**File:** `.github/workflows/phase70-proof.yml:17`
**Issue:** To resolve the one real display-name collision this phase's tests
target (`phase48-proof.yml` and `phase70-proof.yml` both produced `advisory
provider sandbox/device proof (storekit + play billing)`), `phase70-proof.yml`
was renamed to `advisory provider device proof (play billing)`. But the job's
steps are unchanged and still include:

```yaml
- name: Advisory StoreKit sandbox/device checks
  env:
    CROSSWAKE_STOREKIT_SANDBOX_READY: ${{ secrets.CROSSWAKE_STOREKIT_SANDBOX_READY }}
  run: |
    ...
```

The new display name drops "storekit" and "sandbox" entirely, so a maintainer
reading the check name in the Actions UI or a notification would reasonably
believe this run only covers Play Billing, when it still runs the StoreKit
advisory checks too. This directly cuts against the phase's own stated goal
(diagnostic legibility) — the rename fixed the mechanical uniqueness
violation but introduced a semantic inaccuracy in its place. `phase48-proof.yml`
kept the accurate, complete name; `phase70-proof.yml`'s content did not
actually shrink to match its new, narrower-sounding name.
**Fix:** Rename to something that stays both unique and accurate, e.g.
`advisory provider sandbox/device proof (storekit + play billing, phase 70)`,
or split the truly-identical `phase48`/`phase70` steps so one workflow lane
legitimately owns "play billing" and the other legitimately owns "storekit +
play billing."

---

_Reviewed: 2026-09-16T15:15:47Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
