# Phase 192: PR, CI and merge - Pattern Map

**Mapped:** 2026-10-23
**Files analyzed:** 12 new/modified (scripts, selftests, evidence files, two clone code edits)
**Analogs found:** 11 / 12 (the `gh` shim has a partial analog only)

Path convention: `S191` below means `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/`. The integration clone is written only as `<integration-clone>` and is reached only through `locate-191.sh` then `env-191.sh` (`$IC`). Never write its real path, the backup root, the run-folder contents, or the account name into any 192 artifact.

Tracked-source note (#3645 gate): every `S191/*` file is currently UNTRACKED in the recovery checkout (`git ls-files` on that folder prints nothing). They are plain files that `finalize-191.sh` carries into the clone (as `.planning/` records). They are not gitignored mirrors, and they are the real origin; name them by these paths. The two clone code analogs (`test/crosswake/proof/phase170_*`, `script/inventory_collection_assertions.exs`) are tracked in the clone, not the recovery checkout. No analog below points at a `.gsd/capabilities` mirror.

## File Classification

| New/Modified File (under the 192 phase dir `scripts/` unless noted) | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `scan-191.sh` (MODIFY, WR-03, lines ~197/201) | utility (scanner) | batch / transform | itself, lines 191-195 (`tags.ref` loop uses `|| fail`) | exact (in-file) |
| `selftest-scan-191.sh` (MODIFY, add control S33) | test | batch | itself, `ctl_s24` / `ctl_s30` + `run_ctl` | exact (in-file) |
| `push-192.sh` (NEW push gate) | utility (gate script) | request-response, fail-closed | `S191/finalize-191.sh` (`--check-binding`, header, `fail`) | role-match |
| `selftest-push-192.sh` (NEW, local bare remote) | test | request-response | `S191/selftest-base-191.sh` (mk_repo, run_ctl, PREFIX guard) | exact |
| `common-192.sh` (NEW sourced library: P192/EV192/R192, `is_sha40`, `is_int`, `ev_write`, `live_ref`, `ghx`, `log_write`, self-test hook guard) | utility (shared library) | config / file-I/O | `S191/locate-191.sh` (env resolution, atomic env write lines 50-72) + `S191/git-pinned-191.sh` (`g()` scrubbed git) | role-match |
| `privacy-192.sh` (NEW, public-text and evidence privacy check) | utility (scanner) | batch / transform, fail-closed | `S191/scan-191.sh` (fixed-class hits, `privacy: hit CLASS file K` mirrors its index-only labels) | role-match |
| `gh-shim-192.sh` (NEW, live capture + PATH stub + shape derive) | test (test double) | request-response | `S191/selftest-suite-191.sh` lines 70-95 (scenario folder driving a PATH shim) | partial (capture and derive have no analog) |
| `ci-poll-192.sh` (NEW) | utility | polling / event-driven | `S191/suite-gate-191.sh` (labelled evidence, `die2`, atomic temp+mv) | partial |
| `merge-gate-192.sh` (NEW, binding + merge) | utility (gate script) | request-response, one-use approval | `S191/finalize-191.sh --check-binding` + atomic `mktemp`/`chmod 600`/`mv -f` write | role-match |
| `selftest-merge-192.sh` + `bin/gh` shim (NEW) | test | request-response | `S191/selftest-suite-191.sh` (PATH shim, SCEN dir) and `selftest-base-191.sh` ctl_s07 (stat shim heredoc) | role-match |
| `postmerge-192.sh` (NEW verifier) | utility | batch / read-only verify | `S191/finalize-191.sh` (a)-(d) verify + `SC` label checks; `recovery-snap-191.sh` | role-match |
| `192-EVIDENCE/recovery-before-192.txt`, `recovery-after-192.txt` (NEW) | evidence | file-I/O | `S191/recovery-snap-191.sh` output; `191-EVIDENCE/recovery-after-191.txt` | exact |
| `192-EVIDENCE/*.txt` (head labels, scan copies, ci, merge, baselines) | evidence | file-I/O | `191-EVIDENCE/scan-191.txt`, `heads-191.txt` formats | exact |
| `<integration-clone>/test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` (MODIFY, WR-01) | test | transform | same file lines 484-499 + `script/collection_assertion_ledger.json` | exact (in-file) |
| `<integration-clone>/test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` (MODIFY, WR-02) | test | transform | `Crosswake.Test.PhaseEvidencePath.resolve/2` in `test/support/phase_evidence_path.ex` | role-match |
| `<integration-clone>/script/inventory_collection_assertions.exs` (MODIFY, `emit_bytes/1` `:ok =`) | utility | transform | its own lines 98-101 | exact (in-file) |

## Pattern Assignments

### Header and bootstrap for EVERY new 192 shell script (`push-192.sh`, `ci-poll-192.sh`, `merge-gate-192.sh`, `postmerge-192.sh`)

**Analog:** `S191/finalize-191.sh` lines 1-31.

```sh
#!/bin/sh
# Phase 192 <name> (D-xx). Prints only `<name>:` labels.
# Exit 0 pass, 1 check failed, 2 scope or input error.
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
sh "$S191/locate-191.sh" >/dev/null || { echo "<name>: locate failed"; exit 2; }
. /private/tmp/crosswake-phase191-run/env-191.sh
. "$S191/git-pinned-191.sh"

fail() { echo "<name>: $1"; exit "${2:-1}"; }
```

Notes for the planner:
- finalize derives `HERE` from its own location and calls `"$HERE/locate-191.sh"`. A 192 script lives in the 192 folder, so it must call the 191 scripts by an absolute path built from the env file (`$S191` is exported by `env-191.sh`, but only AFTER locate runs). Bootstrap order: resolve `HERE`, find the 191 `scripts` folder as a sibling (`$HERE/../../191-integration-branch-and-local-suite/scripts`), run its `locate-191.sh`, source the env file, then `. "$S191/git-pinned-191.sh"`.
- Fixed labels only. Output never contains a path, SHA of a private object, or token. A SHA that is a public commit may be written to evidence files but not to the allow prompt text (D-07: user never copies hashes).
- Capture a command's exit code into a file, then `tail` the file. Never `cmd | tail && echo OK` (project memory: pipe masks exit codes). 191 style: `cmd > "$R191/x.out" 2>&1; rc=$?`.

### `push-192.sh` (utility gate, fail-closed request-response)

**Analog:** `S191/finalize-191.sh`.

**Binding predicate to call, not reimplement** (finalize lines 24-31):
```sh
if [ "$MODE" = "--check-binding" ]; then
  SC="$EV/scan-191.txt"
  H=$(g "$IC" rev-parse HEAD 2>/dev/null) || H=""
  if [ -n "$H" ] && [ -f "$SC" ] && grep -qx "head $H" "$SC" && grep -qx "main $MAIN_SHA" "$SC" && grep -qx 'scan_exit 0' "$SC"; then
    echo "finalize: binding pass"; exit 0
  fi
  echo "finalize: binding fail"; exit 1
fi
```
`push-192.sh` runs `sh "$S191/finalize-191.sh" --check-binding > "$R191/push-bind.out"`, then `grep -qx 'finalize: binding pass'`. This is the D-05/D-22 refusal. Do not copy the grep; call the mode so there is one definition.

**Branch and clean-tree checks** (finalize lines 36-37):
```sh
[ "$(g "$IC" rev-parse --abbrev-ref HEAD)" = "$BRANCH" ] || fail "clone on wrong branch" 2
[ -z "$(g "$IC" status --porcelain=v1 --untracked-files=all)" ] || fail "clone dirty" 2
```

**Fail-closed ls-remote live read.** No 191 analog does a remote read; follow the `ensure-clone-191.sh` main pin style (line 35): `[ "$(g "$IC" rev-parse refs/remotes/origin/main)" = "$MAIN_SHA" ] || fail main_moved`. For 192 use `g "$IC" ls-remote origin refs/heads/main` captured to a file, take field 1, compare to `$MAIN_SHA`, fixed label `push: main moved`.

**Push form (from RESEARCH, the only allowed command shape):**
```sh
g "$IC" -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
  push origin HEAD:refs/heads/land/v25-v27
```
`g()` (see Shared Patterns) scrubs `GIT_CONFIG_GLOBAL`, so the credential helper must be passed per command. Argument allow-list: refuse `--force`, `-f`, `--force-with-lease`, a leading `+` in any refspec, `--mirror`, `--all`, `--tags`, `--delete`, and any refspec other than `HEAD:refs/heads/land/v25-v27`. Use a `case` over `"$@"` before calling git; fixed labels such as `push: refused flag`. For an update push (fix-forward), additionally require the remote branch tip to be an ancestor of local HEAD (`g "$IC" merge-base --is-ancestor`, same call shape as ensure-clone line 40).

**Fixed-label style** to copy for every refusal: one `echo "push: <label>"; exit N` per condition, no value interpolation. Exit semantics copy finalize: 0 pass, 1 check failed, 2 scope/input error.

**Dry-run first:** support a `--dry-run` arg that appends `--dry-run` to the git push and prints `push: dry-run ok`; the real push prints `push: delivered` only after a post-push `ls-remote` read shows the remote tip equals local HEAD. If the push call errors, do not repeat it: read the remote tip and reconcile (D-06).

### `selftest-push-192.sh` (test, local bare remote)

**Analog:** `S191/selftest-base-191.sh` (header 1-50 and `mk_repo`), plus `S191/selftest-scan-191.sh` `run_ctl`/`expect`.

**Harness to copy verbatim** (selftest-base-191.sh lines 16-50):
```sh
PREFIX=/private/tmp/crosswake-selftest-base-191   # -> crosswake-selftest-push-192
S=
RC=
TOTAL=0
GOOD=0
rm_tree() { case "$S" in "$PREFIX".*) rm -rf "$S" ;; esac; S=; }
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP
mk_tree() {
  S=$(mktemp -d "$PREFIX.XXXXXX") || { echo "selftest: fixture failed"; exit 1; }
  case "$S" in "$PREFIX".*) : ;; *) echo "selftest: guard failed"; exit 1 ;; esac
  mkdir "$S/bin"
}
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }
run_ctl() { # ID FN NAME
  TOTAL=$((TOTAL + 1))
  mk_tree
  if "$2"; then GOOD=$((GOOD + 1)); echo "$1 $3: as expected"; else echo "$1 $3: NOT as expected"; fi
  rm_tree
}
```
`rm -rf` is guarded by the `"$PREFIX".*` case; keep it.

**Fixture repo pattern:** `g "$R" init -q -b main`, commits via `g "$R" -c "user.name=$ID_N" -c "user.email=$ID_E" commit -q --allow-empty -m ...` (selftest-scan-191.sh lines 42-56). For the bare remote: `g "$S" init -q --bare -b main "$S/origin.git"`, set the fixture clone `origin` to that path, and point the gate at the fixture through test hooks. 191 precedent for test hooks is env overrides named in the header (`SUITE191_EV`, `SUITE191_R`, `LOCATE_191_RUN_OVERRIDE`, `SCAN191_TRIAGE`, "self-test only"). Add equivalents (for example `PUSH192_IC`, `PUSH192_EV`, `PUSH192_MAIN`) documented "self-test only".

**Controls to include** (one `ctl_sNN` each, fixed expected label, output asserted by `expect`): stale scan refuses; dirty tree refuses; wrong branch refuses; moved remote main refuses; each forbidden flag refuses (`--force`, `+refspec`, `--tags`, `--delete`, `--all`, `--mirror`); ok path pushes ONLY the one ref (assert `for-each-ref` on the bare repo lists exactly `refs/heads/main` and `refs/heads/land/v25-v27`); trial branches present in the fixture clone are NOT pushed; non-fast-forward update refuses; scan with `scan_exit 1` refuses. Final line style copied from scan self-test: `echo "selftest-push: controls $GOOD of $TOTAL as expected"; [ "$GOOD" -eq "$TOTAL" ] && [ "$TOTAL" -ge N ] && exit 0; exit 1`. The floor `-ge N` is the absence-scored-as-success guard; copy it.

### `ci-poll-192.sh` (utility, polling)

**Analog (partial):** `S191/suite-gate-191.sh` header and atomic-evidence conventions (lines 1-40): mode word as `$1`, label validation, `die2`, `cleanup` trap, temp file then `mv`.

```sh
die2() { echo "suite-gate: $1"; cleanup; exit 2; }
case "$LABEL" in
  ''|*[!A-Za-z0-9._-]*) die2 "label invalid" ;;
```
Copy: strict label validation for any value used in a filename; SHA regex check `^[0-9a-f]{40}$` and integer PR check before use (RESEARCH Security table).

**Read forms (RESEARCH Code Examples):**
```sh
gh api repos/szTheory/crosswake/commits/<head>/check-runs --paginate \
  --jq '.check_runs[]|select(.name=="Crosswake CI")|[.app.id,.status,.conclusion]|@tsv'
gh run list -R szTheory/crosswake --workflow crosswake-ci.yml --commit <head> --json databaseId,event,conclusion,status,headSha
```
Select by name AND `app.id==15368` AND head SHA (pitfall 7). Output labelled evidence lines to `192-EVIDENCE`: head, synthetic merge SHA and tree (D-08), upstream non-success jobs list, conclusion. Poll with a bounded loop and a fixed sleep; write each poll result to a file; the exit code comes from the final conclusion read, never from a pipe. CI takes about 21 to 25 minutes, so run in the background and poll the evidence file.

### `merge-gate-192.sh` (utility, one-use approval)

**Analog:** the atomic write idiom in `locate-191.sh` lines 50-72 and `finalize-191.sh` lines 152-162; the live-read predicate in finalize `--check-binding`.

**Atomic mode-600 record write (copy):**
```sh
TMPS=$(mktemp "$EV/.scan-191.XXXXXX") || fail "scan_scope_error" 2
{ printf 'head %s\n' "$HEADNOW"; ... } > "$TMPS"
chmod 600 "$TMPS"
mv -f "$TMPS" "$EV/scan-191.txt" || fail "scan_scope_error" 2
```
Binding file format should mirror the `key value` lines of `scan-191.txt` (one `grep -qx` per field): `pr N`, `head <sha>`, `tree <synthetic tree>`, `nonce ...`, `consumed false`. Write it in `$R191` (run folder, mode 700), not in `.planning/`.

**Gate order at merge time:** re-read binding (exists, `consumed false`), re-read PR `headRefOid` equals bound head, `state` OPEN, `mergeStateStatus` CLEAN, `Crosswake CI` check-run `success` for that head, `ls-remote` main == `$MAIN_SHA`; then rewrite the binding with `consumed true` (atomic temp+mv) BEFORE the call; then exactly:
```sh
gh pr merge <N> -R szTheory/crosswake --merge --match-head-commit <bound-head-sha>
```
Never `--admin`, `--auto`, `--squash`, `--rebase`, `--delete-branch`. Capture `gh` output to a file and `$?` to a variable; on error or uncertain delivery do not re-run, run `gh pr view --json state,mergeCommit,headRefOid` and reconcile. Argument allow-list `case` over the planned argv, same technique as push gate. The user-facing prompt shows PR URL plus head in plain words; the script, not the user, reads the head into the binding (D-07).

### `selftest-merge-192.sh` and `bin/gh` shim (test)

**Analog:** `S191/selftest-suite-191.sh` lines 70-95 (scenario directory driving a PATH shim) and `S191/selftest-base-191.sh` `ctl_s07` lines 120-129 (heredoc shim).

**Shim installation pattern (copy):**
```sh
cat > "$S/bin/stat" <<'SHIM'
#!/bin/sh
if [ "$1" = "-f" ] && [ "$2" = "%u" ]; then echo 99999; exit 0; fi
exec /usr/bin/stat "$@"
SHIM
chmod 755 "$S/bin/stat"
PATH="$S/bin:$PATH" LOCATE_191_RUN_OVERRIDE="$S/run" sh "$LOCATE" > "$S/out.txt" 2>&1; RC=$?
```
and the scenario dir approach: `SCEN="$S/scen"`, shim reads `$SCEN/<cmd>.out` and `$SCEN/<cmd>.rc`, `export SCEN PATH`, `printf '0\n' > "$SCEN/mix.rc"`.

Adaptations: the `gh` shim must (1) append its full argv to `$SCEN/argv.log` so the test can assert the merge call was exactly `pr merge N -R szTheory/crosswake --merge --match-head-commit <bound>` and that `--squash/--rebase/--admin/--auto` never appeared; (2) answer `pr view --json ...` and `api .../check-runs` with REAL return shapes. Per AGENTS.md lesson, capture the shapes from a live read of an existing PR (RESEARCH names `gh pr view 236 --json headRefOid,state,mergeStateStatus,statusCheckRollup`) rather than inventing fields. Controls: no binding refuses; consumed binding refuses; head changed after allow refuses; mergeStateStatus not CLEAN refuses; check not success refuses; main moved refuses; happy path merges once; shim returns error on merge and the gate does NOT retry (argv.log has one merge line). Use the same `controls N of N` floor line.

### `postmerge-192.sh` (read-only verifier)

**Analog:** `S191/finalize-191.sh` steps (c)-(d) (compare computed vs recorded, fixed `finalize:` labels, state lines appended to a file) and `S191/recovery-snap-191.sh`.

Checks, each emits one fixed label and appends a `key value` line to the evidence file (finalize `printf '... \n' >> "$STATE"` style, lines 51, 92, 107): merge commit has two parents, first == `$MAIN_SHA`, second == bound head (`gh api repos/szTheory/crosswake/commits/<merge_sha> --jq '[.parents[].sha]'`); merge commit tree == the recorded synthetic-merge tree; push-triggered runs on the merge SHA (`gh run list -R szTheory/crosswake --commit <merge_sha> --event push --json databaseId,name,status,conclusion,headSha`): Release Please `success`, every `Publish*`/`Mirror*`/`Clean-room*`/`exact-public` job `skipped`, See It Run Collateral named as a known-cancelled advisory; baselines (latest release, `/tags`, Hex `latest_stable_version` for the six packages) identical to the pre-merge capture; recovery snapshot equality. For the recovery snapshot invoke:
```sh
REC_GIT="$REC/.git" sh "$S191/recovery-snap-191.sh" > "$EV192/recovery-after-192.txt"
diff "$EV192/recovery-before-192.txt" "$EV192/recovery-after-192.txt"
```
(`recovery-snap-191.sh` requires `REC_GIT`, prints digest lines such as `head_file_sha256 ...`, `index_content_sha256 ...`, `object_files_count ...`, and exits 2 with `recovery-snap: git folder missing` on bad input.) Do not run `git status` in the recovery checkout as the proof.

### WR-03 fix in `scan-191.sh` (modify)

**Analog (in file), the pattern to match** (scan-191.sh line ~193 for tags, already fail-closed):
```sh
g "$REPO" for-each-ref refs/tags --format='%(objecttype) %(objectname) %(*objectname)' > "$SC/tags.ref" 2>/dev/null || fail "for-each-ref failed"
...
  g "$REPO" cat-file tag "$to" > "$SC/tagbody.txt" 2>/dev/null || fail "cat-file failed"
```
**Current defective lines to change** (lines ~197 and ~201):
```sh
g "$REPO" notes list > "$SC/notes.ref" 2>/dev/null || : > "$SC/notes.ref"
...
  g "$REPO" cat-file blob "$no" > "$SC/notebody.txt" 2>/dev/null || continue
```
Replace both fallbacks with `|| fail "notes list failed"` and `|| fail "cat-file failed"`. `fail()` here is `echo "scan: $1"; exit 2` (scan-191.sh line 21), so the self-test label is `scan: cat-file failed`. Edit as a plain file in the recovery checkout BEFORE `finalize-191.sh` so the sync commit carries it.

### `selftest-scan-191.sh` control S33 (modify)

**Analog (in file):** `ctl_s24` (scan-191 lines 255-262, writes a shim, builds a commit, runs the scan inline, calls `expect 2 "scan: ..."`) and `ctl_s04` (`expect 2 "scan: empty range"`); registration via `run_ctl`.

```sh
ctl_s24() {
  printf '#!/bin/sh\necho 9.9.9\n' > "$S/bin/gitleaks"; chmod 700 "$S/bin/gitleaks"
  printf 'text\n' > "$R/a.txt"; gc "x"
  env PATH="$S/bin:$PATH" ... bash "$SCAN" "$R" "$BASE" "$(head_sha)" > "$S/out.txt" 2>&1
  RC=$?
  expect 2 "scan: gitleaks version"
}
```
New control: add a commit via `gc`, `g "$R" -c "user.name=$ID_N" -c "user.email=$ID_E" notes add -m body HEAD`, remove the note blob's loose object file (`$R/.git/objects/xx/yyyy`, found via `g "$R" notes list`), `run_scan`, `expect 2 "scan: cat-file failed"`. Register with `run_ctl S33 ctl_s33 "unreadable git note is a scope error"` after the S32 line; the final line becomes `controls 33 of 33 as expected`. The existing floor `[ "$TOTAL" -ge 26 ]` stays. Capture red-before by running S33 against the unfixed scanner first.

### WR-01: `phase170_vacuous_assertion_ledger_test.exs` (clone code edit)

**Analog:** the same file, lines 484-499 (RESEARCH): the C-locale test runs `--emit-snapshot` under `LC_ALL=C`/`LANG=C`, asserts `exit_code == 0`, and `{:ok, %{"rows" => _}} = JSON.decode(output)`.
**Change:** replace the final decode-only assertion with `assert output == File.read!(@ledger)` (byte equality with committed `script/collection_assertion_ledger.json`), keep the exit-code assertion. Do NOT add literal `Enum.all?` / `Enum.any?` text to this file: another test counts exactly 6 raw matches inside its own fixtures. Companion: in `script/inventory_collection_assertions.exs` lines 98-101 change `:io.setopts(:standard_io, encoding: :latin1)` to `:ok = :io.setopts(:standard_io, encoding: :latin1)`. Read the exact current lines in the clone via `g "$IC" show HEAD:<path>` or `sed -n` on the file under `$IC` before editing; I did not read them here (RESEARCH quotes them).

### WR-02: `phase170_vacuity_taxonomy_convention_test.exs` (clone code edit)

**Analog:** `test/support/phase_evidence_path.ex` `Crosswake.Test.PhaseEvidencePath.resolve(@workstream, &1)` (RESEARCH names it, not read by me). Replace `Enum.filter(&File.dir?/1)` with resolve over every roster entry, then:
```elixir
missing = Enum.reject(dirs, &File.dir?/1)
assert missing == []
assert length(examined) == length(@v23_phases)
```
and delete the `length(@v23_phases) == 7` tautology. This shape deliberately avoids `assert Enum.all?` / `any?` / `refute` forms that `script/inventory_collection_assertions.exs` inventories (a new site fails `--check`, the ledger test and `finalize` `ledger_check`). Prove with `elixir script/inventory_collection_assertions.exs --check` ("ledger matches the live tree exactly").

### Evidence files under `192-EVIDENCE/`

**Analog:** `191-EVIDENCE/heads-191.txt` (label + SHA lines, last 40-hex token is what `ensure-clone-191.sh` compares) and `191-EVIDENCE/scan-191.txt` (plain `key value` lines).

Required: after the WR-01/02 code commit, append `LAND-FIX <sha>` to `191-EVIDENCE/heads-191.txt` (ensure-clone line 17: `LAST=$(grep -Eo '[0-9a-f]{40}' "$EV/heads-191.txt" | tail -n 1)`, else `clone_diverged`). Before the rescan, copy the existing `scan-191.txt` (head 98e0d390) and the SYNC-2 record into `192-EVIDENCE/` because `finalize-191.sh` overwrites it (lines 152-162). Keep plain `key value` lines readable by `grep -qx`.

## Shared Patterns

### Pinned git helper `g()`
**Source:** `S191/git-pinned-191.sh` lines 9-20.
**Apply to:** every git call in 192 scripts against `$IC` or a fixture repo. First argument is the repo; all `GIT_*` env is scrubbed and `GIT_CONFIG_GLOBAL=/dev/null` is forced, `GIT_TERMINAL_PROMPT=0`.
```sh
g() {
  if [ "$#" -lt 1 ] || [ -z "${1:-}" ]; then echo "g: repo missing"; return 2; fi
  _g191_repo=$1
  shift
  (
    for _n in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$_n"; done
    ...
    exec git $(printf '%s\n' "$G191_PINS") -C "$_g191_repo" "$@"
  )
}
```
Consequence: the push needs `-c credential.helper= -c 'credential.helper=!gh auth git-credential'` per command; fixtures that need identity use `-c user.name=... -c user.email=...` inline (never global config).

### Locate and env sourcing
**Source:** `S191/locate-191.sh` (73 lines): walks up to the recovery checkout, finds the one backup root, regenerates `/private/tmp/crosswake-phase191-run/env-191.sh` atomically, exits 2 with `locate: run folder unsafe` unless the run folder is user-owned mode 700. Env exports `REC BR D PARENT IC DENY R191 WS P191 P190 EV S191 BRANCH MAIN_SHA CAND_HEAD BASE_A53 MERGE_BASE`. Every 192 script re-runs locate then sources the env file (finalize lines 12-14). `LOCATE_191_RUN_OVERRIDE` is the self-test hook.

### Fail-closed exits with fixed labels
**Source:** `finalize-191.sh` `fail()` (line 16) and `ensure-clone-191.sh` `fail()` (line 10); `scan-191.sh` `fail()` (line 21). Contract: print `<tool>: <fixed label>`, never a value; exit 2 for scope/input, 1 for failed check, 0 only on proven pass. WR-03 is the same class: a read that cannot complete must not `continue` or default to empty.

### Atomic evidence writes
**Source:** `finalize-191.sh` lines 152-162 and `locate-191.sh` lines 50-72: `mktemp` inside the target folder, write, `chmod 600`, `mv -f`. Apply to the binding record, CI evidence, baselines.

### Self-test harness and control floors
**Source:** `selftest-scan-191.sh` lines 1-85 and 311-end; `selftest-base-191.sh` lines 16-50. `/private/tmp/crosswake-selftest-*-N.XXXXXX` fixture prefix with guarded `rm -rf`, `run_ctl ID FN "name"` printing `ID name: as expected` or `NOT as expected`, closing `controls GOOD of TOTAL as expected` plus a minimum-count floor in the exit condition. Planted values assembled from fragments (`"gh""p_..."`) so the script never matches its own scanner.

### Privacy
**Source:** `scan-191.sh` header (lines 1-9) and pattern block (lines 24-40): output carries labels and counts only. Apply a fragment-pattern grep (home path, per-user temp path, token shapes, email) over the PR body file and every `192-EVIDENCE` file before `gh pr create` and before finishing (RESEARCH pitfall 11). Use `<integration-clone>` everywhere.

### No-change proof for the recovery checkout
**Source:** `S191/recovery-snap-191.sh` (34 lines), invoked `REC_GIT="$REC/.git" sh "$S191/recovery-snap-191.sh"`; working-tree compare via `recovery-tree-191.sh` with `recovery-named-191.tsv` and `recovery-volatile-191.txt` (a 192 named list must add the plain `.planning/` files edited this phase). Baseline is `191-EVIDENCE/recovery-after-191.txt` plus a fresh `recovery-before-192.txt`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `bin/gh` shim returning real `gh pr view` / check-runs / `pr merge` shapes | test fixture | request-response | 191 shims fake `stat`, `gitleaks`, `mix` with one-line outputs; none fake a JSON-returning API CLI. Reuse the heredoc + PATH + SCEN mechanics, but take JSON shapes from a live read of an existing PR (AGENTS.md lesson). |
| Polling loop for remote CI | utility | event-driven | No 191 script waits on an external system; build it from the suite-gate evidence conventions with a bounded retry and file-based state. |
| Any `git push` / `ls-remote` write path | utility | request-response | 191 scripts contain no push; the gate is new. Only the refusal predicate (`--check-binding`) exists. |

## Metadata

**Analog search scope:** `S191` (all 22 files; read in full or in targeted ranges: locate, git-pinned, finalize, ensure-clone, recovery-snap, selftest-scan, selftest-base, selftest-suite ranges, scan-191 lines 1-40 and 185-215, suite-gate header). Clone-side files (`phase170_*` tests, `script/inventory_collection_assertions.exs`, `phase_evidence_path.ex`) were taken from RESEARCH.md, not re-read; the executor must read them before editing.
**Files scanned:** about 14 read directly; `git ls-files` check on `S191` returned 0 tracked (all plain untracked files).
**Pattern extraction date:** 2026-10-23
