# Phase 193: Cleanup and new working rules - Pattern Map

**Mapped:** 2026-10-23
**Files analyzed:** 22 new/modified (8 scripts + self-test aggregate + sums file, 9 records, 5 doc edits counted below)
**Analogs found:** 21 / 22 (one partial: `swap-193.sh`)

All analog paths are relative to `.planning/workstreams/quality-ratchet-release/phases/` unless they start with `.planning/`. Placeholders: `<home>`, `<tmp>`, `<backup-root>`, `<recovery-checkout>`.

**Tracked-source note (#3645 gate).** In the recovery checkout `git ls-files` prints nothing under `.planning/workstreams/.../phases/` (those files are plain files there). Every analog below was verified TRACKED on `origin/main` with `git ls-tree -r origin/main -- <path>`: `scan-191.sh`, `selftest-scan-191.sh`, `privacy-192.sh`, `merge-gate-192.sh`, `restore-189.sh`, `189-INVENTORY.md`, `189-SCRIPTS.sha256`, `SEED-024`. None is a gitignored mirror. Line numbers were read from the recovery copy; confirm against the clone after PR 1 (`ci-poll-192.sh`, `finalize-191.sh`, `git-pinned-191.sh`, `verify-189.sh` were read in the recovery copy and are in the same 189/191/192 sets that PR #242 / PR 1 carry). Hand the planner `git show origin/main:<path>` if a line range looks off.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `193-*/scripts/preflight-193.sh` | utility (verifier) | batch (hash + restore checks) | `189-*/scripts/verify-189.sh` + `restore-189.sh` | role-match |
| `193-*/scripts/backup-post189-193.sh` | utility (backup) | file-I/O | `189-*/scripts/backup-refs-189.sh`, `manifest-189.sh` | role-match |
| `193-*/scripts/land-gate-193.sh` (scan-bind + push + merge gate fork) | utility (gate) | request-response (gh) | `192-*/scripts/merge-gate-192.sh`, `push-192.sh`, `finalize-191.sh --check-binding` | exact (fork) |
| `193-*/scripts/copyforward-193.sh` | utility | file-I/O | `189-*/scripts/restore-189.sh` (tarfiles kind) | role-match |
| `193-*/scripts/swap-193.sh` | utility | file-I/O (rename + rollback) | none direct; `restore-189.sh` `finish`/`fail` shape only | partial |
| `193-*/scripts/guard-swapped-193.sh` | utility (guard) | request-response | `191-*/scripts/finalize-191.sh` (a)-clone checks | role-match |
| `193-*/scripts/remove-193.sh` (ledger generator, per-item gate) | utility | batch | `189-*/scripts/reconcile-189.sh` (check-per-row, `ok|FAIL`) | role-match |
| `193-*/scripts/final-check-193.sh` (`--pre-merge`/`--post-merge`/`--self-test`) | utility (verifier) | request-response (git + gh) | `192-*/scripts/ci-poll-192.sh`, `privacy-192.sh`, `selftest-scan-191.sh` | role-match |
| `193-*/scripts/selftest-193.sh` + per-script selftests | test | batch | `191-*/scripts/selftest-scan-191.sh`, `192-*/scripts/selftest-privacy-192.sh` | exact |
| `193-SCRIPTS.sha256` | config (hash freeze) | file-I/O | `189-*/189-SCRIPTS.sha256` | exact |
| `<backup-root>/inventory-189/SHA256SUMS.193` | config (sums) | file-I/O | `SHA256SUMS.NN` written by `manifest-189.sh` | exact |
| `193-POST189-RECORD.md` | record (inventory rows `R-POST-*`) | transform | `189-INVENTORY.md` | exact |
| `193-REMOVAL-LEDGER.md` | record (ledger table) | transform | `189-INVENTORY.md` (table form) + `189-EVIDENCE/pr-table.md` | role-match |
| `193-PR-DISPOSITIONS.md` | record (table) | transform | `189-EVIDENCE/pr-table.md` | exact |
| `.planning/seeds/SEED-025-phase-192-review-residue.md` | seed | transform | `.planning/seeds/SEED-024-phase-190-review-residue.md` | exact |
| `193-VERIFICATION.md`, `193-NN-SUMMARY.md` / `193-NN-BLOCKED.runN.md` | record | transform | `192-VERIFICATION.md`, `192-NN-SUMMARY.md` | exact |
| `AGENTS.md` | config (working rules) | n/a | main's `AGENTS.md` (`git show origin/main:AGENTS.md`) | exact (base) |
| workstream `STATE.md` | record | n/a | itself (active sections + Handoff history) | exact |
| workstream `ROADMAP.md` | record | n/a | itself ("Ordering rules for v27.0") | exact |
| `.planning/PROJECT.md` | record | n/a | itself ("Current stage" line ~75) | exact |
| workstream `REQUIREMENTS.md` | record | n/a | itself ("Future Requirements") | exact |

## Pattern Assignments

### Shared script skeleton for every 193 script (all scripts)

**Analog:** `191-integration-branch-and-local-suite/scripts/selftest-scan-191.sh` (lines 1-85) and `192-pr-ci-and-merge/scripts/privacy-192.sh` (lines 1-30).

Header, strict mode, label-only output, fragment-assembled planted values, trap cleanup guarded by a prefix `case`:

```bash
#!/bin/bash
# Phase 191 self-test for scan-191.sh ... Throwaway fixtures only.
# Prints one fixed label per control, never a path or a planted value.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
PREFIX=/private/tmp/crosswake-selftest-scan-191   # 193: use a NON-crosswake prefix (RESEARCH Pitfall 6)
S=
RC=
TOTAL=0
GOOD=0

rm_tree() {
  case "$S" in
    "$PREFIX".*) rm -rf "$S" ;;
  esac
  S=
}
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP

# planted values, every one assembled from fragments
HOMEP="/Us""ers/fixtureuser/work"
TOKEN="gh""p_R7kQ2mZ9xT4vB1nL8cW3yH6dF0sJ5aPeXuGi"
```

Deviation for 193: `PREFIX` must NOT start with `crosswake` (a killed run would leave a `<tmp>/crosswake*` entry that final-check (4) sees). Never hardcode a home path; build `/Us""ers` from fragments.

**Control runner and numbering (copy verbatim; this is the `S33 ...: as expected` convention)** (lines 74-85, 353-373):

```bash
run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  mk_tree
  if "$2"; then
    GOOD=$((GOOD + 1))
    echo "$1 $3: as expected"
  else
    echo "$1 $3: NOT as expected"
  fi
  rm_tree
}
...
run_ctl S33 ctl_s33 "unreadable git note is a scope error"
echo "selftest-scan: controls $GOOD of $TOTAL as expected"
[ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge 26 ] && exit 0
exit 1
```

193 should number controls per script with a distinct letter prefix (for example `P01` preflight, `L01` land-gate, `F01` final-check, `R01` remove, `W01` swap) and end with `controls N of N as expected` plus a `TOTAL >= floor` assertion (floor guards "self-test that asserts nothing").

**Assert helpers: exit code AND label together** (lines 71-72, 87):

```bash
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }
has() { grep -q -- "$1" "$S/out.txt"; }
```

**Fail-closed exit-code capture, no pipes** (`privacy-192.sh` lines 56-67; also `ci-poll-192.sh` uses `... > file 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }`):

```bash
probe() {
  grep -a -q $2 -$3 "$4" "$5" 2>/dev/null; _rc=$?
  case $_rc in
    0) HITS=$((HITS + 1)); echo "privacy: hit $1 file $K" ;;
    1) : ;;
    *) echo "privacy: grep failed"; exit 2 ;;
  esac
}
```

Exit convention for all 193 scripts: 0 pass, 1 check failed, 2 scope/input/tool error (never a clean pass), 3 delivery uncertain (gates only). Output: fixed `scriptname: word` labels, never a path, hash, file name or env value (copy `privacy-192.sh` header comment lines 3-5).

**Hash-check with explicit count (no pipe, empty input fails)** (RESEARCH "Code Examples", derived from `verify-189.sh`):

```bash
total=$(awk 'NF{n++} END{print n+0}' "$sums") || exit 2
[ "$total" -gt 0 ] || { echo "preflight: FAIL empty sums"; exit 1; }
[ "$total" -eq "$expected" ] || { echo "preflight: FAIL line count"; exit 1; }
out=$(cd "$OUT" && shasum -a 256 -c "$sums" 2>&1); rc=$?
oks=$(printf '%s\n' "$out" | grep -c ': OK$')
[ "$rc" -eq 0 ] && [ "$oks" -eq "$total" ] || { echo "preflight: FAIL mismatch"; exit 1; }
```

**Pinned git helper (reuse by copy, or call `git-pinned-191.sh` which has no `<tmp>` dependency)** (`191-*/scripts/git-pinned-191.sh` lines 1-22): `g REPO args...` scrubs `GIT_*`, pins `core.*`, sets `GIT_CONFIG_GLOBAL=/dev/null`. Use `. "$HERE/git-pinned-191.sh"` only if PR 1 has landed it in the clone (it has: carried by PR #242). Otherwise copy the file into `193-*/scripts/git-pinned-193.sh` (copy-paste over shared dependency).

**Static controls every script needs** (RESEARCH Self-test controls): grep the script source and fail if it contains `crosswake-phase191-run`, `locate-191`, `env-191`, `common-192`, a home path, or a pipe into `tail`/`head` in a gating position. This is the one place with NO analog (new control); use the `ctl_*` shape above.

---

### `193-*/scripts/final-check-193.sh` (verifier, request-response)

**Analogs:** `192-*/scripts/ci-poll-192.sh` (gh + jq selection of the Crosswake CI check; lines 100-185), `192-*/scripts/privacy-192.sh` (fail on empty input), `191-*/scripts/selftest-scan-191.sh` (self-test shape).

Interface to implement (D-19 + D-24 + RESEARCH OQ-3/OQ-4): `--pre-merge PR`, `--post-merge`, `--self-test`; five checks; `gh` failure, empty or unparseable JSON = FAIL (exit 2 for tool error, 1 for check failure).

**CI-on-main resolution** (RESEARCH "Code Examples", two `gh api` calls verified live against `d12aed75`; the CI workflow runs on `pull_request` only, so assert the PR head, not the main SHA):

```bash
sha=$(git rev-parse HEAD)
pr=$(gh api "repos/$SLUG/commits/$sha/pulls" --jq '[.[] | select(.merged_at != null)] | if length==1 then .[0].number else empty end') || exit 2
[ -n "$pr" ] || { echo "final: FAIL no single merged PR for tip"; exit 1; }
head=$(gh pr view "$pr" --json headRefOid --jq .headRefOid) || exit 2
res=$(gh api "repos/$SLUG/commits/$head/check-runs" --jq '[.check_runs[]|select(.name=="Crosswake CI" and .app.id==15368)]|sort_by(.id)|last|.conclusion') || exit 2
[ "$res" = success ] || { echo "final: FAIL crosswake ci $res"; exit 1; }
```

Check-run selection by name + app + highest id mirrors `ci-poll-192.sh` ("selects the check run by name + app + head sha, highest id"). Read the required contract live rather than hardcoding: `required_status_checks` returns `{"checks":[{"app_id":15368,"context":"Crosswake CI"}],"strict":true}`.

**Run lookup excerpt to copy for the failing-job list** (`ci-poll-192.sh` lines 112-124):

```bash
ghx run list -R "$REPO_SLUG" --workflow crosswake-ci.yml --commit "$SHA" --event pull_request \
  --json databaseId,headSha,status,conclusion,event > "$R192/ci-runs.json" 2>/dev/null || { echo "ci-poll: unreadable"; exit 2; }
_r=$(jq -r --arg s "$SHA" '[.[]|select(.headSha==$s)|.databaseId]|max // empty' "$R192/ci-runs.json" 2>/dev/null) || { echo "ci-poll: unreadable"; exit 2; }
```

Do not use `ghx` (a 192 wrapper from `common-192.sh`); call `gh` directly and capture to a variable.

**Open-PR set (check 3)**: capture `gh pr list --state open --json number` into a variable, require rc 0, non-empty, `jq -e 'type=="array"'`; compare numbers only to the first column of `193-PR-DISPOSITIONS.md` rows matched by `^\| [0-9]+ \|` (OQ-7). Zero open PRs passes only when the JSON parsed and gh exited 0. Pre-merge mode includes a `this PR` row.

**Self-test controls required** (RESEARCH): dirty tree; red CI; no single merged PR; open PR with no disposition; disposition row for a closed PR (allowed only for PR 2 / #242); empty gh output; unparseable JSON; gh non-zero; empty ledger; expected count 0; leftover `<tmp>/crosswake*`; pre-merge HEAD != PR head; post-merge with extra open PR; clean fixture passes. Implement gh as a shim script on `PATH` in the fixture (see `192-*/scripts/gh-shim-192.sh` for the shim shape; copy, do not source `common-192.sh`).

**Check (4)** lists only `<tmp>/crosswake*` (never `<tmp>/*`); each remaining entry must map to a row in `189-EVIDENCE/tmp-entry-map.tsv` (`<name>\t<row id>`) or the D-22 `R-POST-TMP-NN` rows, with the backup sha verified.

**Check (5)** expected count: read from the frozen 189 listing (`189-EVIDENCE/tmp-listing-before.txt` has a `count 159` header) plus the D-07/D-22 record; assert `> 0`.

---

### `193-*/scripts/land-gate-193.sh` (gate, request-response; fork of 192 gate)

**Analogs:** `192-*/scripts/merge-gate-192.sh` (modes `propose PR | answer allow|hold | merge | status`; exit 0/1/2/3), `192-*/scripts/push-192.sh`, `191-*/scripts/finalize-191.sh --check-binding`.

**Binding folder is owner-only** (`merge-gate-192.sh` lines 17-25):

```bash
bdir_ready() {
  if [ ! -d "$BDIR" ]; then
    mkdir -m 0700 "$BDIR" 2>/dev/null || die "binding dir unsafe" 2
  fi
  if [ "$(stat -f %u "$BDIR" 2>/dev/null)" != "$(id -u)" ] || [ "$(stat -f %Lp "$BDIR" 2>/dev/null)" != 700 ]; then
    die "binding dir unsafe" 2
  fi
}
bget() { [ -f "$BF" ] || return 0; awk -v k="$1" '$1==k {sub(/^[^ ]+ /,""); print; exit}' "$BF"; }
bstate() { awk -v s="$1" '$1=="state" {print "state " s; next} {print}' "$BF" | ev_write "$BF" || die "unreadable" 2; }
```

(`ev_write` is defined in `common-192.sh`; reimplement as a temp-file-then-`mv` helper in the 193 script. Do not source `common-192.sh`: it sources the deleted run-folder env, Pitfall 1.) BSD `stat -f` is the project convention (macOS only).

**Scan binding format to fork as `scan-bind-193.sh`** (`finalize-191.sh` lines 24-31): file lines `head <sha40>`, `main <sha40>`, `scan_exit 0`; push refuses unless head equals the clone HEAD and main equals the live base:

```bash
SC="$EV/scan-191.txt"
H=$(g "$IC" rev-parse HEAD 2>/dev/null) || H=""
if [ -n "$H" ] && [ -f "$SC" ] && grep -qx "head $H" "$SC" && grep -qx "main $MAIN_SHA" "$SC" && grep -qx 'scan_exit 0' "$SC"; then
  echo "finalize: binding pass"; exit 0
fi
echo "finalize: binding fail"; exit 1
```

193 differences: base SHA read live from `git ls-remote origin refs/heads/main`, not pinned; no `locate`; run folder outside `crosswake*`; branch and repo dir are parameters (PR 1 = clone, branch `docs/192-post-sync-records`; PR 2 = swapped checkout, branch `chore/193-cleanup-records`). Push logic to copy from `push-192.sh`: live `ls-remote` before and after, ancestry check, `already_delivered` idempotence, one attempt only, refusals `main moved`, `main not in head`, `not fast-forward`, `remote unreadable`; credential helper `gh auth git-credential`. Scan call: `SCAN191_ADOPTER_SKIP=A-14 bash scan-191.sh REPO BASE HEAD` (omit the 4th argument).

**Gate semantics**: `answer` voids when head changed since `propose` (192 D-07); delivery uncertain returns 3 and never retries. Self-test controls from RESEARCH: scan HEAD != push HEAD, scan exit != 0, main moved, not fast-forward, remote unreadable, head changed after `allow`, `hold`, `answer` without `propose`, delivery uncertain (exit 3, no retry).

---

### `193-*/scripts/preflight-193.sh` (verifier, batch)

**Analogs:** `189-*/scripts/verify-189.sh` (lines 1-30, `--quick`/`--full` loop over `restore-registry-NN.tsv`), `189-*/scripts/restore-189.sh` (usage + closed-word results).

**Restore interface to call (from a hash-checked scratch copy, not in-place)** (`restore-189.sh` lines 1-40):

```bash
# restore-189.sh ARTIFACT KIND EXPECTFILE   (kinds: bundle, stash, tarfiles, headpatch)
# Needs RESTORE_PLAN (two digits). Prints "restore <artifact>: pass" or
# "restore <artifact>: fail <reason>"; reasons are closed words and counts, never paths or hashes.
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$HERE/env-189.sh" || exit 3
. "$HERE/lib-189.sh" || exit 3
[ "$#" -eq 3 ] || { echo "restore: usage" >&2; exit 3; }
case ${RESTORE_PLAN:-} in [0-9][0-9]) : ;; *) echo "restore: RESTORE_PLAN must be a two-digit plan number" >&2; exit 3 ;; esac
RR=${RESTORE_RUNS:-$RUNS}
ROUT=${RESTORE_OUT:-$OUT}
...
[ -f "$EXPECT" ] && [ -s "$EXPECT" ] || fail "expectation empty or missing"
```

Facts the planner must respect (RESEARCH, "Preflight reality check"): `lib-189.sh locate` is NOT runnable (needs a deleted temp folder and writes `env-189.sh` into the scripts folder, which dirties the tree). Copy `189-*/scripts/` to a scratch dir (non-`crosswake` name), re-check against `189-SCRIPTS.sha256` there, hand-write `env-189.sh`, then call `restore-189.sh`. `reconcile-189.sh` and `verify-189.sh --full` are not re-runnable.

**`189-SCRIPTS.sha256` format and check** (verified rc 0): 22 lines `<64-hex>  scripts/<name>` (two spaces), run `shasum -a 256 -c 189-SCRIPTS.sha256` from the 189 phase folder. 193 freezes its own with the same layout, `193-SCRIPTS.sha256`, names `scripts/<name>-193.sh`, regenerated after any script edit.

Expected sums line counts to assert: `SHA256SUMS` 167, `.02` 2, `.03` 8, `.04` 13, `.05` 5, `.06` 1, `.07` 3, `.08` 123, `.11` 2, `.13` 7, `.cr01` 2; `ignored-keep.files` 46066; `env-local.files` 3; env tar and `.files` mode 600 (`stat -f %Lp`).

---

### `193-*/scripts/backup-post189-193.sh` and `SHA256SUMS.193` (file-I/O)

**Analogs:** `189-*/scripts/manifest-189.sh` (interface), `189-*/scripts/restore-189.sh` kind `bundle` / `tarfiles`.

`manifest-189.sh NAME FILE...` writes `${MANIFEST_OUT:-$OUT}/NAME` with `<sha256>  <name relative to the output folder>` lines (names like `../integration-191-trials.bundle` are allowed); refuses fewer than 2 args (2), bad NAME (2), missing file (1). Create `<backup-root>/inventory-189/SHA256SUMS.193`: the three-digit suffix does not match the glob `SHA256SUMS.[0-9][0-9]` that `verify-189.sh` loops, so no 189 script is disturbed. Verify with `(cd inventory-189 && shasum -a 256 -c SHA256SUMS.193)` plus an expected-line-count assertion (empty sums file passes `shasum -c`).

Bundle: **no negative prefix** (D-23). `restore-189.sh` kind `bundle` runs `git bundle verify` in an empty bare repo, so only complete-history bundles pass. Expectation file format: first line `complete-history`, then `<objectname> <refname>` lines, optional `head <commit> <tree>`. Refs: `carry-trial carry-trial-2 carry-trial-3 land/v25-v27 candidate-src` in the integration clone. Tar for D-22: same `tarfiles` kind with `.files` expectation lines `sha mode path` (see existing `tmp-crosswake-phase179-hex.tar` + `.files`). Self-test controls from RESEARCH: ref set empty, bundle fails verify, bundle missing a ref, sums line absent, checkpoint bundle unmapped.

---

### `193-*/scripts/copyforward-193.sh` (file-I/O)

**Analog:** `restore-189.sh` kind `tarfiles` (hash + mode check against `.files` lines `sha mode path`; `sensitive` first line for env, restored copy deleted after check).

Pattern to copy: closed-word results, counts only. Allowlist is an explicit pattern list (OQ-5): `.claude/*.json` and `.gsd/**` only; exclude `.claude/worktrees/**`, `*.lock`, `.DS_Store`, `.expert/`, `.planning/research/.cache/`. Assert copied count `> 0` per category. Env files restored mode 0600, assert `stat -f %Lp` equals 600; records give counts and pass/fail only. Also copy forward the workstream runtime files (OQ-2: `config.json`, `state.json`, `milestone.lock` if present) and add them to `.git/info/exclude`, reporting the exclude line count. Proof steps capture `mix deps.get` and `mix compile --warnings-as-errors` exit codes into variables; never through a pipe. Self-test controls: empty allowlist match, wrong env mode, hash mismatch, file outside the allowlist copied, env file name/content in the record (privacy grep must fail on empty scope, as `privacy-192.sh` does: `[ "$#" -ge 1 ] || { echo "privacy: no input"; exit 2; }`).

---

### `193-*/scripts/swap-193.sh` (file-I/O, partial analog)

**No direct analog.** Borrow only the exit/word style from `restore-189.sh`:

```bash
finish() { echo "restore $NAME: $2"; exit "$1"; }
fail() { finish 1 "fail $1"; }
```

Logic per D-09 (new): from `<home>/projects`, `mv crosswake crosswake-recovery-retired` then `mv crosswake-clean-main crosswake`; if the second `mv` fails, `mv` the first back and verify; refuses if target exists or source missing; second run is idempotent; no destructive git command. Each `mv` rc tested directly. Controls: target exists, second rename fails (rollback verified), source missing, run twice.

---

### `193-*/scripts/guard-swapped-193.sh` (guard, request-response)

**Analog:** `191-*/scripts/finalize-191.sh` lines 33-37 (clone/branch/clean-tree checks):

```bash
[ "$(g "$IC" rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || fail "clone on wrong branch" 2
[ -z "$(g "$IC" status --porcelain=v1 --untracked-files=all)" ] || fail "clone dirty" 2
```

Assert: toplevel is the expected path, HEAD equals fetched `origin/main`, `crosswake-recovery-retired` exists (or ledger says removed), tree clean apart from copy-forwarded ignored files. Do not call `ensure-clone-191.sh` or `locate-191.sh`.

---

### `193-*/scripts/remove-193.sh` (batch, per-item gate + ledger)

**Analog:** `189-*/scripts/reconcile-189.sh` output style: `check <name>: ok|FAIL <detail>` per check, last line `reconcile-189: ok|FAIL`, exit 0/1/3 (read the file for the per-row loop before writing; its inputs are not re-runnable, only its shape). Gate checks (a)-(e) from D-13; `kept: <cause>` rows; re-run prints `already absent`; only `<tmp>/crosswake*` names are removable (refuse any path whose realpath is outside; never glob `<tmp>/*`). Stop the whole run only if `<backup-root>` fails to verify. `rm -rf` guarded by the same `case "$X" in "$PREFIX".*)` idiom as `rm_tree` in the shared skeleton above.

---

### `193-REMOVAL-LEDGER.md`, `193-POST189-RECORD.md` (records)

**Analog:** `189-INVENTORY.md` (tracked on origin/main). Table form, 9 cells; rows start `| R-`:

```
| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |
| R-WT-2 | extra worktree on the accrue host command bridge branch | <recovery-checkout>-accrue-bridge | worktree | 1 | unclassified | worktree dirty files; branch has unique commits (see R-BR row); backed up | worktree-accrue-bridge.tar + worktree-accrue-bridge.patch | worktree-accrue-bridge.tar: pass; worktree-accrue-bridge.patch: pass (restore-04.tsv) |
| R-ENV | local environment files (count only; names and contents not recorded) | ... | env-files | 3 | unclassified | ... | env-local.tar (restricted archive, mode 0600) | env-local.tar: pass (restore-05.tsv) |
| R-TMP-038 | temporary folder with 0 nested repos and 29 files outside git | <tmp>/crosswake-phase179-hex | tmp-folder | 1 | unclassified | ... | tmp-crosswake-phase179-hex.tar | pass |
```

Preamble/classes block style (`189-INVENTORY.md` lines 1-12): short intro paragraph, `## Classes` list (`on main`, `to land`, `obsolete`, `unclassified`), `## Items` table. Placeholders only; no home paths.

- `193-POST189-RECORD.md`: new row ids `R-POST-TMP-NN` (D-22, the 11 un-inventoried `<tmp>` entries), plus rows for the sibling-clone refs (`carry-trial`, `carry-trial-2`, `land/v25-v27`, `candidate-src`, `carry-trial-3`), the stray `crosswake-checkpoint-*.bundle` file, and the 18 remote-published extra refs.
- `193-REMOVAL-LEDGER.md` (D-14): columns `row id | kind | location | backup + sha256 match | ref check | action | result | reason if kept`, header with `expected` / `removed` / `kept` counts (`expected = removed + kept`, `expected > 0`; checked by `final-check-193.sh` check 5). Header layout is discretionary.
- Map `<tmp>` entries with `189-EVIDENCE/tmp-entry-map.tsv` shape: `<tmp>/<entry-name>\t<row id>`.

---

### `193-PR-DISPOSITIONS.md` (record)

**Analog:** `189-EVIDENCE/pr-table.md` (lines 1-12 of the file):

```
## Open PR dispositions

No pull request was changed in this phase (read-only calls only). The allowed dispositions are merge, close, redo after landing or hold (INV-03 as amended for D-13).

| PR | Title | Head | Files | Contained in candidate | Disposition | Reason |
|---|---|---|---|---|---|---|
| 238 | Maintain release guides and assertion references | 3e8a4b2601b5 | 8 | 0 of 8 | redo after landing | ... |
```

193 variant (RESEARCH Wave 0): `| PR | Title | Head seen | Disposition | Reason |` (or keep 7 columns and document), data rows must match `^\| [0-9]+ \|`. Rows (D-20 as updated): #236 hold (CI fails on head `ed81c6e0`), #238 redo after landing (head unchanged `3e8a4b26`), #239 `c064db79`, #240 `e26fe524`, #241 `0e794279` (green; separate decision with SHA-pin provenance check), #210 `b2668e5e` hold (CI fails), #211 `79c426f6` hold (**reword to observed failing CI**, not "no result"). Record failure cause only as "not read". Final check compares numbers, head drift is informational.

---

### `.planning/seeds/SEED-025-phase-192-review-residue.md` (seed)

**Analog:** `.planning/seeds/SEED-024-phase-190-review-residue.md` (tracked on origin/main). Front matter and structure to copy:

```yaml
---
id: SEED-024
title: Phase 190 review residue
status: dormant
severity: medium
trigger_when: >-
  Surface before the next twin run (...), and
  again before the physical-iPhone run resumes (...).
  NOT blocking today: ...
created: 2026-10-19
related: [SEED-023]
---

# SEED-024: Phase 190 review residue

<lead paragraph: what was fixed vs deferred>

## Before the next twin run

- WR-02: <finding>. Done looks like <observable outcome, with a test>.
...
## Accepted as designed
...
## Source

- 190-REVIEW.md and its disposition file.
- 191-CONTEXT.md, decision D-17c.
```

SEED-025: `id: SEED-025`, `created: 2026-10-23`, `related: [SEED-023, SEED-024]`, `severity: medium` (consider `high` for WR-01 only if the template allows; SEED-024 uses one severity). Group by trigger; **WR-01 first** (CI failure-tail masking misses credential shapes: a credential-leak gap), then WR-02 (twin owner checks, nil os_pid), WR-03 (Xcode-only tests run nowhere in CI), IN-01, IN-02, and the missing example-host full-suite CI lane (191 D-14). Every item ends "Done looks like ...". Finding text comes from `192-REVIEW.md` and `192-REVIEW-DISPOSITION.md` (not re-read here; the executor must read them). `## Source` links those two files and `193-CONTEXT.md` D-21. No code change. Also add one Future Requirements bullet to REQUIREMENTS.md pointing to SEED-025.

---

### `AGENTS.md` (working rules, CLEAN-04)

**Base:** `git show origin/main:AGENTS.md` (PR 2 starts from main's copy; the recovery copy is the +41/-5 diff to disposition, not the base). Main's headings: `# Crosswake Agent Guide`, `## Project Context` (line 3), `## Current Priority` (22), `## Working Rules` (39), `## Sensitive Data Rules` (58), `## Workflow` (71).

Anchors in the recovery copy (do not copy wholesale), per RESEARCH:
- Hunk `@@ -49,6 +49,9 @@` adds the one-use `allow`/`hold` bullet in Working Rules: keep, generalize to merges to `main`, release PR #236, any Hex/Maven/iOS publish, tags, remote branch deletion; local commits and feature-branch pushes need no gate.
- Hunk `@@ -72,11 +75,20 @@` in Workflow: keep the GSD handoff bullet; condense "no command eligible" to one sentence.
- Hunk `@@ -92,3 +104,27 @@`: keep the plain-language status bullet; keep the durable bullets of "Lessons from the Phase175 approval loop" **without that header** (irreversible-operation rule, autonomy, one active handoff, retire superseded routes as not executed, adapters tested against real dependency output); **drop** `## Standing authorization — quality-ratchet-release Phase175`, the "Repair-only pushes" clause, and the second "Explain the outcome and next action first" duplicate; keep the workflow-credential sentence pair.
- Existing bullet style to match (main, "Working Rules"): hyphen bullets, wrapped at ~100 columns, two-space continuation indent, bold only for codenames.
- New `## How changes land` section (D-16) as a bullet list: `<type>/<topic>` branches from current `origin/main`; worktrees allowed for parallel agent runs, never as a home for candidate state under `/tmp`; every change by PR with "Crosswake CI" green on the head; merge commit only; say which commit CI ran on (the synthetic merge commit); privacy scan before every push and rescan after any new commit; red CI is fixed forward tied to the observed cause; read and reconcile before retrying a write.
- No phase names in the rewritten rules. D-18: no enforcement test or CI lane. One-off verification only: AGENTS.md has the `How changes land` heading and none of `Standing authorization`, `Phase175`, `Repair-only pushes` (the assertions fail on a missing file).

---

### workstream `STATE.md`, `ROADMAP.md`, `PROJECT.md`, `REQUIREMENTS.md` (edit anchors; line numbers drift, re-read at edit time)

Paths: `.planning/workstreams/quality-ratchet-release/{STATE,ROADMAP,REQUIREMENTS}.md`, `.planning/PROJECT.md`.

- **STATE.md** headings (as read): `## Current Position` (line 27: `Phase: 193 — Cleanup and new working rules / Plan: Not started / Status: Ready to plan / Last activity: ... / Progress: [██████░░░░] 60%`), `## Exact Next Action` (36; includes a "Phase 193 inputs:" paragraph), `### Handoff history` (46), `## Session` (179), `## Operator Next Steps` (185, currently one bullet `- Plan Phase 193 with ...`). Rewrite the three active sections; add one line at the top of Handoff history in the existing style (`- Superseded (YYYY-MM-DD): <command>. Done: ...`) reading "Superseded 2026-10-2x: frozen recovery checkout rules". Leave existing history lines verbatim (191 D-08). The STATE carried by PR 1 must already carry the exact post-swap next command (RESEARCH "Handoff content must travel with the swap"); PR 1 cut is the LAST STATE.md write in the recovery checkout (OQ-6).
- **ROADMAP.md**: `### Ordering rules for v27.0` at line 22, rule bullets 24-29. Add the single line `v27.0 only; superseded by AGENTS.md 'How changes land' after Phase 193` directly under the heading. Do not rewrite the bullets. Phase 193 detail is near line 204 (`**Plans**: TBD`; progress row `| 193. ... | 0/TBD | Not started | - |`).
- **PROJECT.md** line 75, `**Current stage:** Last completed phase 188. ... the recovery checkout stays frozen through Phase 192. See [STATE](workstreams/quality-ratchet-release/STATE.md).` Rewrite the whole line (also stale on "Phase 189 is next"), keep the bold label and the trailing STATE link form.
- **REQUIREMENTS.md**: `## Future Requirements` (line 69) has two plain bullets; add one bullet for SEED-025. CLEAN-01..04 are `- [ ] **CLEAN-NN:**` lines 60-67; flip them and the traceability rows (102-105, `Pending`) only after the final check passes (PR 2).

---

## Shared Patterns

### Fixed-label, no-leak output
**Source:** `192-pr-ci-and-merge/scripts/privacy-192.sh` lines 3-5 and 56-67; `191-*/scripts/selftest-scan-191.sh` header.
**Apply to:** every 193 script, every record the scripts write.
Output labels only (`name: word`); never a path, hash value, file name, env name/content, token or account. Planted self-test values are assembled from fragments so a script never matches its own privacy classes.

### Fail-closed exit codes with direct capture
**Source:** `privacy-192.sh` `probe()`; `ci-poll-192.sh` lines 112-114.
**Apply to:** all scripts. `cmd > file 2>/dev/null || { echo "x: unreadable"; exit 2; }`, or `out=$(cmd); rc=$?` then `case $rc in`. No `cmd | tail && echo OK` anywhere (memory: piped checks mask exit codes). Empty input is a scope error, never a pass.

### Placeholder redaction
**Source:** `191-*/scripts/carry-191.sh` (redacts `<home>`, `<tmp>`, `<user>`, `$NN` -> `${NN}` for rows marked `dollar`); `189-INVENTORY.md` (`<recovery-checkout>-accrue-bridge`, `<tmp>/...`).
**Apply to:** every record and PR text. Run `privacy-192.sh` (exit 0 required, exit 2 on no input) on each record and PR body; run `scan-191.sh` bound to the exact push head.

### Privacy scan binding before push
**Source:** `finalize-191.sh --check-binding` (lines 24-31); `scan-191.sh REPO BASE HEAD` (needs gitleaks exactly 8.30.1, `SCAN191_ADOPTER_SKIP=A-14`, triage `191-EVIDENCE/scan-triage-191.tsv`).
**Apply to:** PR 1 and PR 2 pushes. PR 1 must merge before the PR 2 scan so the updated triage file is used.

### Carry of planning records into PR 1
**Source:** `191-*/scripts/carry-191.sh` `manifest|apply|verify` + `carry-floor-191.sh`, tables `carry-table-191.tsv` (bucket `phases/1@(89|90|91|92|93)-*` already in `v27.0`) and `carry-exclusions-191.tsv` (excludes workstream `config.json`, `state.json`, `milestone.lock`).
**Apply to:** PR 1 and the late-record sweep in 193-05 (source = retired folder, base = swapped checkout). Manifest is the source of truth; `192/193 *.md` files with a `$NN` pattern need new `dollar` table rows (verify step reports it).

### Records conventions
**Source:** phase folders 189-192. Blocked plans are `NN-BLOCKED.runN.md`, never `NN-SUMMARY.md`. Scripts live in `phases/193-*/scripts/` with `<name>-193.sh`, frozen by `193-SCRIPTS.sha256`.

### Do-not-reuse list (hidden dependencies on deleted `<tmp>` state)
`common-192.sh`, `locate-191.sh`, `ensure-clone-191.sh`, `finalize-191.sh`, `suite-gate-191.sh`, `recovery-tree-191.sh`, `selftest-base-191.sh`, `lib-189.sh locate`, `reconcile-189.sh`, `verify-189.sh --full`. Reusable standalone: `scan-191.sh`, `selftest-scan-191.sh`, `carry-191.sh`, `carry-floor-191.sh`, `git-pinned-191.sh`, `privacy-192.sh`, `selftest-privacy-192.sh`, `manifest-189.sh`, `restore-189.sh` (from a hash-checked scratch copy with a hand-made env).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `swap-193.sh` | utility | file-I/O (two renames + rollback) | No existing script renames folders or does rollback; use D-09 spec and the exit/word style above |
| Static "no deleted-run-folder dependency" control | test | transform | New control; implement as a `grep` over the script source inside `ctl_*` |
| Post-swap handoff / `checkpoint:human-action` | plan structure | n/a | No prior plan ends a session by design; RESEARCH "Recommended Plan Split" |

## Metadata

**Analog search scope:** `phases/189-*`, `191-*`, `192-*` (scripts, evidence, inventory), `.planning/seeds/`, workstream STATE/ROADMAP/REQUIREMENTS, `.planning/PROJECT.md`, `origin/main:AGENTS.md`.
**Files scanned:** about 30 read or grepped (scripts: selftest-scan-191, git-pinned-191, privacy-192, merge-gate-192, ci-poll-192, finalize-191, restore-189, verify-189; records: SEED-024, 189-INVENTORY, pr-table, tmp-entry-map).
**Pattern extraction date:** 2026-10-23
