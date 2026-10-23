# Phase 188: Freeze and twin-05 - Pattern Map

**Mapped:** 2026-10-16
**Files analyzed:** 14 new files (6 run-dir scripts, 4 run-dir records/sentinels, 4 planning records) plus 2 modified handoff records
**Analogs found:** 14 / 14 for scripts and records (7 exact or near-exact, 7 role-match). 1 sidecar has no prior art (see end).

Scope note: no product code changes. `RUNS` = `/private/tmp/crosswake-phase180-run`, `CAND` = `/private/tmp/crosswake-phase180-impl` (read-only), `PD` = this phase directory. Run-dir scripts are one-time evidence tooling outside any git checkout, so the tracked-source gate does not apply to them. Planning analogs live under `$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/`. Excerpts below use `$HOME`; new scripts must build planning paths from `$HOME`, never a literal home path (RESEARCH Pitfall 7).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `RUNS/refresh-handoffs-188.sh` | utility (record refresh) | transform / file-I/O | `RUNS/prepare-record.sh` (+ `g()` wrapper, tmp+`mv -n`) | role-match |
| `RUNS/make-identity-188.sh` | utility (record generator) | transform | `RUNS/prepare-record.sh` + `183-IDENTITY.json` shape | role-match |
| `RUNS/run-once-05.sh` | script (gate + single run) | request-response, exactly-once | `RUNS/preflight-04.sh` + `RUNS/run-once-04.sh` merged | exact (two precedents) |
| `RUNS/assert-twin-05.sh` | test/assertion | transform (JSON shape check) | 183-05 plan `jq -e` result assertion | role-match |
| `RUNS/scan-privacy-188.sh` | test/assertion | file-I/O (grep scan) | 187-07 home-scan procedure (`home-scan-187.*`) | role-match |
| `RUNS/selftest-188.sh` | test | batch, throwaway fixtures | `RUNS/mutate-18N.sh` / `gate-184-13.sh` family (negative controls) | partial |
| `RUNS/twin-05-candidate.json` | config (prepared record) | file-I/O | `RUNS/twin-04-candidate.json` via unchanged `prepare-record.sh` | exact |
| `RUNS/go-no-go-05.json` | record | transform | `preflight-04.sh` fixed labels (stderr) turned into JSON | role-match |
| `RUNS/twin-05.started`, `.exit`, `.stdout`, `.stderr`, `twin-run-path-05`, `twin-run-count.before-05` | sentinel/log | file-I/O | `twin-04.started/.exit/.stdout/.stderr`, `twin-run-path-04`, `twin-run-count.before-04` | exact |
| `PD/188-IDENTITY.json` | config (identity) | transform | `183-IDENTITY.json` | exact |
| `PD/188-TWIN-RESULT.json` | record (byte copy) | file-I/O | `183-TWIN-RESULT.json` / 183-05 `cp`+`cmp` | exact |
| `PD/188-TWIN-RECORD.md` | doc (limits sidecar) | n/a | STATE.md "Fidelity limits:" block written by 183-05 | partial |
| `PD/188-NN-BLOCKED.md` (conditional) | doc | n/a | `183-05-BLOCKED.md` convention (183-05 plan Task text) | role-match |
| `180-SEAM-HANDOFF.json`, `182-FINAL-HEAD.json` (modified) + `*.pre-188.json` | record | transform | their own current shape (shapes in RESEARCH) | exact |

## Pattern Assignments

### `RUNS/run-once-05.sh` (script, exactly-once gate + run)

**Analogs:** `RUNS/preflight-04.sh` (gate checks) and `RUNS/run-once-04.sh` (run shape). Merge them into one script (D-12) so no time-of-check gap exists. Use `#!/bin/sh` (not zsh; zsh traps `status`, `path`, nonmatching globs, `>>` under noclobber).

**Header, fixed labels, scrubbed git wrapper** (`preflight-04.sh` lines 1-16; change `PD` to `$HOME`-based and RECORD/ID to 05/188):
```sh
#!/bin/sh
set -eu
RUNS=/private/tmp/crosswake-phase180-run
CAND=${CANDIDATE:-/private/tmp/crosswake-phase180-impl}
REC=${RECORD:-$RUNS/twin-04-candidate.json}      # -> twin-05-candidate.json
fail() { echo "preflight: $1 failed" >&2; exit 1; }
g() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_OBJECT_DIRECTORY -u GIT_ALTERNATE_OBJECT_DIRECTORIES -u GIT_COMMON_DIR -u GIT_NAMESPACE -u GIT_CEILING_DIRECTORIES -u GIT_CONFIG -u GIT_CONFIG_COUNT -u GIT_CONFIG_PARAMETERS -u GIT_PREFIX GIT_OPTIONAL_LOCKS=0 GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 LC_ALL=C git --no-optional-locks -c core.excludesFile=/dev/null -c core.quotePath=false -c core.fsmonitor=false -C "$CAND" "$@"
}
```

**Clean probe + digest recompute (WR-05 / D-07a)** (`preflight-04.sh` lines 17-46):
```sh
probe() {
  n=$(g status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none 2>/dev/null | wc -c | tr -d ' ') || return 1
  [ "$n" -eq 0 ] || return 1
  exc=$(g rev-parse --path-format=absolute --git-path info/exclude 2>/dev/null) || return 1
  if [ -f "$exc" ]; then
    c=$(grep -Ev '^[[:space:]]*(#|$)' "$exc" | wc -l | tr -d ' ')
    [ "$c" -eq 0 ] || return 1
  fi
  return 0
}
dig() { g show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }
probe || fail "clean probe"
HEAD_SHA=$(g rev-parse HEAD); TREE=$(g rev-parse 'HEAD^{tree}')
[ "$HEAD_SHA" = "$(jq -r .expected_head "$REC")" ] || fail "head equals record"
[ "$TREE" = "$(jq -r .expected_tree "$REC")" ] || fail "tree equals record"
DM=$(dig $MANIFEST); DA=$(dig $ACTIVATION); DS=$(dig $STUDY); DF=$(dig $MEDIA)
[ "$DM" = "$(jq -r '.resource_digests[0]' "$REC")" ] || fail "manifest digest"
[ "$(stat -f %Lp "$REC")" = 600 ] || fail "record mode"
[ "$(jq -r .candidate_head "$ID")" = "$HEAD_SHA" ] || fail "identity head"
[ "$(jq -r .media.sha256 "$ID")" = "$DF" ] || fail "identity media"
```
Note: the idiom `x=$(... | wc -c)` masks the left-hand status (Pitfall 8). Keep it only as the precedent `probe()` form; for any new check capture `out=$(cmd 2>&1) || rc=$?` first.

**Environment checks** (`preflight-04.sh` lines 47-55; adapt 04->05, count 3->4, use `find ... -name 'twin-[0-9][0-9]'` instead of the zsh-fatal `ls -d` glob):
```sh
[ -z "$(lsof -nP -iTCP:4790 -sTCP:LISTEN 2>/dev/null)" ] || fail "port 4790 free"
if xcrun simctl list devices 2>/dev/null | grep -q 'crosswake-phase180-'; then fail "no leftover simulator"; fi
[ ! -e $RUNS/twin-04.started ] || fail "twin-04.started absent"
CNT=$(ls -d $RUNS/twin-[0-9][0-9] 2>/dev/null | wc -l | tr -d ' ')
[ -f $RUNS/twin-run-count.before-04 ] || echo "$CNT" > $RUNS/twin-run-count.before-04
```
Differences for 05 (from CONTEXT D-12/D-13 and RESEARCH): `twin-05` must already exist, mode 0700, uid == `id -u`, empty (`[ -z "$(ls -A "$R")" ]`), outside CAND, no `receipt.json`/`twin-result.json`; `twin-05.started`/`.exit` absent; exactly four roots; add gitlink (`ls-tree -r HEAD | awk '$1=="160000"'` count 0, no `.gitmodules`), manifest check with rc and `: OK` count captured separately (87), Simulator runtime availability `jq -e`, and a label that `MIX_BUILD_PATH`/`DATABASE_PATH` are unset for the run. Keep the precedent's `gen.shell ios --check` plus second probe, run with `env -u MIX_BUILD_PATH`.

**Single run + sentinel** (`run-once-04.sh` lines 8-17, with the D-12/D-13 changes: no `mkdir`, noclobber sentinel, `cd` into the candidate because the asdf `mix` shim needs `.tool-versions`):
```sh
mkdir -m 0700 "$R"                                   # REMOVE in 05: separate pre-step (D-13)
date -u +%Y-%m-%dT%H:%M:%SZ > "$R.started"          # 05: ( set -C; umask 077; date -u ... > "$R.started" )
printf '%s\n' "$R" > $RUNS/twin-run-path-04
cd $C
set +e
MIX_ENV=test mix crosswake.proof_lane.verify_twin ios --candidate $RUNS/twin-04-candidate.json --run-root "$R" --identity $PD/183-IDENTITY.json > "$R.stdout" 2> "$R.stderr"
rc=$?
set -e
echo $rc > "$R.exit"
```
Apply for 05: `( set -C; umask 077; ... > "$R.started" )` so the second call fails; run as `env -u MIX_BUILD_PATH -u DATABASE_PATH MIX_ENV=test mix ...` (RESEARCH Pitfall 1, refinement of D-12); build one argv for preflight and run (Pitfall 3); no loop, `timeout`, or `||` retry; exactly one `verify_twin` line.

**Preflight command form** (read-only, exit 0 required, exactly four output lines): `mix crosswake.proof_lane.twin_preflight ios --candidate <record> --run-root <dir> --identity <file>` with the dedicated `MIX_BUILD_PATH=$RUNS/_build_188_twin05` for compile/probe/preflight only, and `env -u DATABASE_PATH`.

**Probe form for the D-12 re-probe** (precedent `real-probe-187.out`; RESEARCH A1 pattern-match form, confirm in the selftest): 
```sh
cd "$CAND" && MIX_ENV=test MIX_BUILD_PATH=$B mix run --no-start -e '{:ok, %{modified: 0, flagged: 0, excludes: 0}} = Crosswake.ProofLane.TwinProducers.probe_source(File.cwd!()); IO.puts("probe: all zero")'
```

**Gate output** (new; derived from the label list in `preflight-04.sh`): `go-no-go-05.json` = one plain-language line first, then `[{label,status}]` built with `jq -n --arg`; labels are fixed strings, no paths.

---

### `RUNS/twin-05-candidate.json` and `RUNS/prepare-record.sh` reuse (config, file-I/O)

**Analog:** `RUNS/prepare-record.sh` (reuse unchanged) and `RUNS/twin-04-candidate.json`.

**Core pattern** (`prepare-record.sh` lines 22-35):
```sh
if [ -e "$OUT" ]; then echo "refused: record_exists"; exit 5; fi
HEAD_SHA=$(g rev-parse HEAD); TREE=$(g rev-parse 'HEAD^{tree}')
dig() { g show "HEAD:$1" | shasum -a 256 | cut -d' ' -f1; }
...
TMP=$(mktemp "$OUTDIR/.prep-record.XXXXXX")
jq -n --arg p "$PHYS" --arg h "$HEAD_SHA" --arg t "$TREE" --arg m "$DM" --arg a "$DA" --arg s "$DS" --arg f "$DF" \
  '{candidate_path:$p,expected_head:$h,expected_tree:$t,origin:"http://127.0.0.1:4790",resource_digests:[$m,$a,$s],fixture_digests:[$f]}' > "$TMP"
chmod 0600 "$TMP"
mv -n "$TMP" "$OUT"
```
Invocation (use absolute paths, `$3` is tested with `-f`): `prepare-record.sh $CAND $RUNS/twin-05-candidate.json $RUNS/twin-04-candidate.json`. Expected: all four digests equal the twin-04 record; only head (`a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`) and tree (`f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`) change. A digest difference means stop.

---

### `RUNS/make-identity-188.sh` and `PD/188-IDENTITY.json` (config, transform)

**Analog:** `183-IDENTITY.json` (shape) plus 183-04 Task 1 (values from `git show HEAD:<path>` only) plus `prepare-record.sh` `dig()`/`jq -n --arg`/tmp+`mv -n` writing.

**Shape to copy** (`183-IDENTITY.json`; change `supersedes` to `"183-IDENTITY.json"`, head/tree to the freeze values, rewrite `note`):
```json
{
  "schema": "crosswake.phase180.identity/1",
  "supersedes": "180-IDENTITY.json",
  "candidate_head": "<40-hex>",
  "candidate_tree": "<40-hex>",
  "media": { "path": "examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/pronunciation.aiff", "size": 33706, "sha256": "<64-hex>" },
  "generated": { "manifest_sha256": "<64-hex>", "activation_sha256": "<64-hex>" },
  "note": "..."
}
```
`media.size` is `git show HEAD:<media> | wc -c` (must be a JSON integer; use `jq --argjson`). The twin reads only `media.sha256`, `media.size`, `generated.manifest_sha256`, `generated.activation_sha256`; head/tree are for the shell gate. Output goes in `PD`, mode default, refuse if it exists (copy the `record_exists` refusal).

---

### `RUNS/refresh-handoffs-188.sh` (utility, record rewrite)

**Analog:** `prepare-record.sh` (refusal exit codes, `g()`, tmp then `mv`, verify-after-write). No refresh script has existed before. Argument is required with no default: `FREEZE=${1:?freeze sha}`; validate as 40 lowercase hex before use.

**Pieces to copy** (`prepare-record.sh` lines 5, 14-16, 29-35):
```sh
CAND=${1:?candidate dir}; OUT=${2:?output record}
...
if ! g rev-parse --git-dir >/dev/null 2>&1; then echo "refused: probe_unavailable"; exit 4; fi
if [ "$P" -ne 0 ]; then echo "refused: source_dirty"; exit 3; fi
TMP=$(mktemp "$OUTDIR/.prep-record.XXXXXX")
jq -n ... > "$TMP"
mv -n "$TMP" "$OUT"
[ "$(jq -r .expected_head "$OUT")" = "$HEAD_SHA" ] || { echo "refused: write_failed"; exit 6; }
```
Record shapes and rewrite rules (RESEARCH "JSON shapes"):
- `180-SEAM-HANDOFF.json` (schema `crosswake.phase180.seam_handoff/1`): rewrite only `repaired_head`, `repaired_tree`; add `supersedes` object with the old values. Old `repaired_head` is `12f84cd950d4574921767df823faed6797c17c26`, an ancestor of the freeze head.
- `182-FINAL-HEAD.json` (schema `crosswake.phase182.final_head/1`): rewrite `head`, `tree`, `core_diff_paths`. Rule verified: `core_diff_paths == git diff --name-only <base_head> <head>` (33 paths at `da53c54`; 129 at the freeze head), so state the meaning change in the record. Add top-level `checks_status` and `simulator_status` = `not_rerun_at_freeze_head`; leave `checks[]`/`simulator_*` untouched under `supersedes` (field layout is discretion, RESEARCH A2).
- Copy each old record to `*.pre-188.json` first (never overwrite an existing copy; use `cp -n` and check), write temp then `mv`, then `jq -e` that head equals `rev-parse HEAD` and tree equals `rev-parse HEAD^{tree}`. Never touch a `twin-0[1-4]*` path. These two records are not in `history-184.before.sha256`, so editing them does not break the manifest.

---

### `RUNS/assert-twin-05.sh` (assertion, transform)

**Analog:** 183-05 plan automated check (`183-05-PLAN.md` line 95), which asserts `cmp`, `receipt_sha256` equality, 10 group ids, 49 unique sub-observations, 5 limits. Use RESEARCH's already-tested script as the base; constants live in the script, never read from the file under test.

**Core assertion** (183-05 plan line 95, condensed):
```sh
jq -e '.exit_status==0 and .overall_status=="passed"
  and (.groups|map(.id))==["T01","T02","T03","T04","T05","T06","T07","T08","T09","T10"]
  and ([.groups[].sub_observations[].id]|length==49 and (unique|length)==49)
  and (.fidelity_limits|length)==5
  and (.fidelity_limits[4]=="source edit made and reverted during a run not detected")' "$PD/183-TWIN-RESULT.json"
```
Extend it per D-18 and RESEARCH "Result assertion": `schema == "crosswake.twin_result/1"`, each group `status=="passed"` with at least one sub-observation, every observation `outcome=="passed" and cause==null`, the seven join ids in order (`source`, `dependency_lock`, `generated_resources`, `served_static`, `installed_media`, `installed_build`, `backend_build`) all passed with null cause, the five `fidelity_limits` strings verbatim, the two `residual_external_gates` strings, `receipt_sha256` 64-hex and equal to `shasum -a 256 twin-05/receipt.json`. Negative self-test (required): empty-groups file and 9-group file must both exit non-zero; also 6-join, non-null cause, empty sub-observations, 4-limit, twin-02 blocked result, mismatching receipt.

Reconciliation after assertion (183-05 pattern): `cp "$R/twin-result.json" "$PD/188-TWIN-RESULT.json"`, `cmp`, record full 64-hex sha256 of source and copy; only on exit 0 plus passed. Byte-copy precedent proven: `cmp $RUNS/twin-04/twin-result.json 183-TWIN-RESULT.json` is identical. Do not copy `receipt.json`, stdout, stderr or xcresult into planning.

---

### `RUNS/scan-privacy-188.sh` (assertion, file-I/O)

**Analog:** the 187-07 home-scan procedure (`187-07-PLAN.md` line 120 and the check at line 125; outputs `RUNS/home-scan-187.files` and `.log`). Pattern: list files first into a `.files` list, require every listed path to be a readable regular file, then run the two greps and require empty output; the log states the scope and result.

**Precedent check** (`187-07-PLAN.md` line 125, condensed):
```sh
test -s $RUNS/home-scan-187.files && test -s $RUNS/home-scan-187.log \
 && test -z "$(while IFS= read -r f; do { test -f "$f" && test -r "$f"; } || echo "$f"; done < $RUNS/home-scan-187.files)" \
 && test -z "$(xargs grep -lF "$HOME" < $RUNS/home-scan-187.files)" \
 && test -z "$(xargs grep -lw "$(id -un)" < $RUNS/home-scan-187.files)"
```
**D-17 pattern set** (RESEARCH, validated: zero hits over twin-04 root, its stdout/stderr, `183-TWIN-RESULT.json`, `183-IDENTITY.json`; planted hit detected):
```sh
pat='/Users/|/private/var|/var/folders|[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}|token|secret|@|CrosswakeExample\.Router|unmanaged_(routes|paths)'
grep -IlE -e "$pat" "$@" ; [ $? -eq 1 ]     # require rc exactly 1; rc 2 (unreadable) must not read as clean
grep -Ilw -e "$(id -un)" "$@" ; [ $? -eq 1 ]
```
Include a positive control (a planted file must be found). Keep the scripts themselves free of the scan tokens (`token`, `secret`, `@`, `/Users/`) so script copies in the phase directory scan clean, or name the exclusion explicitly (RESEARCH Open Question 4). A scan hit in a planning file is fixed by editing text, never by in-place sed on planning files (187-07 rule).

---

### `RUNS/selftest-188.sh` (test, throwaway fixtures)

**Analog:** the negative-control family in `RUNS` (`mutate-18N.sh`, `gate-184-13.sh`) and the `CANDIDATE`/`RECORD` env overrides in `preflight-04.sh` line 6-7 (`CAND=${CANDIDATE:-...}`, `REC=${RECORD:-...}`). New scripts should expose `CANDIDATE`, `RUNS`, `PD`, `RECORD` overrides so the selftest points them at throwaway repos. Design (RESEARCH "Self-test design"): scratch `git init`, stub `mix` first on `PATH` recording argv, refuse to run if the resolved root equals the real `twin-05` or real candidate path, print a fixed label per control, and require the executed control count to equal an expected constant (never accept zero cases). Never invoke `verify_twin` or touch `twin-05`.

Controls needed: gitlink (`git update-index --add --cacheinfo 160000,...`) and `.gitmodules` variants; modified digest in record copy; modified identity media; root mode 0755; root with `receipt.json`/`twin-result.json`; non-empty root; symlink root; `.started` present; wrong root count; second invocation stops at the sentinel before the stub is invoked (argv log has one entry); refresh with wrong SHA, dirty tree, non-ancestor, missing argument; manifest copy with one byte altered; static grep that `verify_twin` appears on exactly one invoking line with no `while|until|for|timeout` around it.

---

### `RUNS/twin-05.*` sibling files (sentinel/log, file-I/O)

**Analog:** `twin-04.started` (`2026-10-15T13:43:32Z`, 21 bytes), `twin-04.exit` (`0`), `twin-04.stdout` (4 lines), `twin-04.stderr` (0 bytes), `twin-run-path-04`, `twin-run-count.before-04` (content `3`). Create `twin-run-count.before-05` (content `4`) and `twin-run-path-05` analogously. The `.stdout` is exactly four lines: `result:`, `first cause:`, `report:`, `next action:`. For the failure branch read line 2 and `jq -c '{not_reached, last: (.stages|last)}' "$R/run-stages.json"`. Canary `xcodebuild: "failed"` in `run-stages.json` is normal in a pass.

---

### `PD/188-TWIN-RECORD.md` (doc, limits sidecar)

**Analog (partial):** the STATE.md block that 183-05 Task text required (`183-05-PLAN.md` line 106): ten `- Tnn: <status>` lines, `Failed or blocked:`, `Fidelity limits:` listing all five limits verbatim in receipt order, `Residual external gates:` verbatim. There is no prior `*-TWIN-RECORD.md`. Use plain language first (AGENTS.md) and open with "A pass means the Simulator twin saw X; it does not mean Y." Required contents (D-19, verified by grep on this file, not the JSON, because the JSON carries only the five receipt limits):
- the five receipt limits verbatim: `simulator not physical speaker`, `simulator not signed device`, `synthetic_test_authority not real adopter`, `trusted local runner not cryptographic certification`, `source edit made and reverted during a run not detected`;
- under "Planning-record limits the receipt cannot vouch for": `ignored files`, `Phase 179 identity join`, `DEBT-IDENT` with `org.crosswake.twin`;
- "Open warnings not exercised by twin-05" as a separate list;
- residual gates: `physical iPhone signed-device run`, `first adopter sanitized route handoff`.
Use the durable codename or "first adopter"; never the real adopter.

---

### `PD/188-NN-BLOCKED.md` (conditional doc)

**Analog:** the 183-05 convention (`183-05-PLAN.md` line 106 and check line 108): on a non-pass write `PD/183-05-BLOCKED.md` with the same plain-language account, assert `! -f 183-05-SUMMARY.md`, annotate the superseded result by sha256 (`crosswake.phase183.annotation/1`), never edit it. For 188: no SUMMARY, record stage, closed cause atom, exit status (1 failed, 2 blocked), say "raw output not retained" where true, single handoff "no command is eligible until an explicit twin-06 decision".

## Shared Patterns

### Scrubbed git wrapper
**Source:** `RUNS/prepare-record.sh` lines 11-13 and `RUNS/preflight-04.sh` lines 14-16 (identical).
**Apply to:** every script that reads the candidate. Set `CAND` before the first call; never call bare `git -C`.

### Fixed-label failures, never print paths
**Source:** `RUNS/preflight-04.sh` line 13 (`fail() { echo "preflight: $1 failed" >&2; exit 1; }`) and `prepare-record.sh` `refused: <code>` lines with exit codes 3 to 6.
**Apply to:** `run-once-05.sh`, `refresh-handoffs-188.sh`, `make-identity-188.sh`, `scan-privacy-188.sh`.

### Capture status explicitly (no pipe masking)
**Source:** RESEARCH Pitfall 8 and project memory "piped checks mask exit codes".
```sh
out=$(shasum -a 256 -c "$RUNS/history-184.before.sha256" 2>&1); rc=$?
n=$(printf '%s\n' "$out" | grep -c ': OK$')
[ "$rc" -eq 0 ] && [ "$n" -eq 87 ]
```
**Apply to:** the three D-11 manifest checks (before refresh, after refresh, inside go/no-go), scan greps (require rc exactly 1), the preflight (require rc 0 and four lines). Under `set -e` use `|| rc=$?`.

### Atomic write, no overwrite
**Source:** `prepare-record.sh` lines 29-35 (`mktemp` in the output dir, `chmod 0600`, `mv -n`, then verify).
**Apply to:** `twin-05-candidate.json`, `188-IDENTITY.json`, `go-no-go-05.json`, refreshed handoff records, `*.pre-188.json` copies.

### Exactly-once sentinel
**Source:** `run-once-04.sh` lines 10, 14-17 plus the D-12 noclobber change, tested in RESEARCH Pitfall 4.
```sh
( set -C; umask 077; date -u +%Y-%m-%dT%H:%M:%SZ > "$R.started" )
```
Keep `set -C` in a subshell so later `> "$R.stdout"` redirects stay ordinary; do not use `>>` under noclobber in zsh.
**Apply to:** `run-once-05.sh` only.

### History byte-unchanged proof
**Source:** `RUNS/history-184.before.sha256` (87 absolute-path entries, covers twin-01..04 and 183 result/identity; excludes `180-SEAM-HANDOFF.json` and `182-FINAL-HEAD.json`), prior outputs `history-18N.after.out`. Plus `cmp twin-04/twin-result.json 183-TWIN-RESULT.json`.
**Apply to:** 188-01 (before/after refresh), `run-once-05.sh` gate, verification (D-21).

### Home-path hygiene in planning-bound files
**Source:** 187-07 plan line 120 and RESEARCH Pitfall 7. Build `PD="$HOME/projects/crosswake/.planning/workstreams/quality-ratchet-release/phases/188-freeze-and-twin-05"`; copies of scripts into `PD` get a `188-SCRIPTS.sha256` listing; scan covers everything under `PD` plus the two refreshed records.
**Apply to:** all new scripts and planning records.

### Candidate and recovery checkout stay untouched
Verify after each wave: `g rev-parse HEAD` equals `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, porcelain 0 bytes, push URL `no-push-phase180`, and `git -C $HOME/projects/crosswake diff --cached --name-only` empty (precedent assertion at the end of `187-07-PLAN.md` line 125 and `183-05-PLAN.md` line 108).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `RUNS/refresh-handoffs-188.sh` (as a script) | utility | transform | No refresh script existed before; only composition of `prepare-record.sh` primitives. The 180/182 record shapes are the specification. |
| `PD/188-TWIN-RECORD.md` | doc | n/a | No earlier limits sidecar; closest is the STATE.md block text from 183-05. |
| D-07(c) doctor-JSON/router-name scan | assertion | file-I/O | No prior script; use the validated regex in the shared scan pattern above. |
| `selftest-188.sh` stub-`mix` harness | test | batch | Prior mutate/gate scripts do not use a stub `mix`; build per RESEARCH "Self-test design". |

## Metadata

**Analog search scope:** `/private/tmp/crosswake-phase180-run/` (scripts, records, manifests, home-scan files), phases 180, 182, 183, 184, 186, 187 planning directories, 188-CONTEXT and 188-RESEARCH.
**Files read:** `prepare-record.sh`, `preflight-04.sh`, `run-once-04.sh`, `183-IDENTITY.json`, `home-scan-187.log`, excerpts of `183-05-PLAN.md` and `187-07-PLAN.md`, CONTEXT and RESEARCH in full. Remaining precedent contents (`twin-04-candidate.json`, `twin-result.json`, manifest, handoff shapes) were taken from RESEARCH, which read them directly.
**Pattern extraction date:** 2026-10-16
