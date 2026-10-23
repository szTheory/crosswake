# Phase 191: Integration branch and local suite - Pattern Map

**Mapped:** 2026-10-19
**Files analyzed:** 27 new or modified (8 tools plus self-tests, 12 code and test edits, 7 record files)
**Analogs found:** 25 / 27

Placeholders: `<recovery-checkout>`, `<durable-candidate>`, `<backup-root>`, `<tmp>`, `<home>`, `<denylist>`.
Line numbers are from the files as read this session. `P190` = `.planning/workstreams/quality-ratchet-release/phases/190-fix-warnings-before-landing/scripts/`.

**Tracked-source note (#3645).**
- The P190 and 188 scripts exist as plain files in `<recovery-checkout>`. `git ls-files` prints nothing for them, because Phases 188-190 are uncommitted there. They are not ignored (`check-ignore` exits 1), and they are not a gitignored capability mirror.
- They are the genuine origin files, and no tracked copy exists anywhere else. Treat them as the source.
- The Phase 191 scripts will be carried into the integration clone by the v27 carry commit. They are not on `main` yet.
- All `lib/`, `test/` and `script/` analogs below were confirmed tracked. Candidate-only files are tracked in `<durable-candidate>` (for example `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, which is absent from `<recovery-checkout>`).
- No path below is under a `.gsd/capabilities` mirror.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `191/scripts/git-pinned-191.sh` | utility (sourced helper) | request-response | `P190/git-pinned-190.sh` | exact (parameterize repo; add commit path) |
| `191/scripts/locate-191.sh` | utility | file-I/O | `P190/locate-190.sh` | exact (WR-11 changes) |
| `191/scripts/ensure-clone-191.sh` | utility | batch | `P190/ensure-work-190.sh` | role-match |
| `191/scripts/recovery-snap-191.sh` | utility (digest) | transform | `P190/recovery-snap-190.sh` | exact (WR-10 changes) |
| `191/scripts/selftest-{locate,ensure,snap}-191.sh` | test | request-response | `P190/selftest-scan-190.sh` (harness) | role-match |
| `191/scripts/carry-191.sh` + `selftest-carry-191.sh` | utility + test | batch / transform | `P190/scan-privacy-190.sh` (list expansion, symlink refusal, exit-2 scope errors) | partial |
| `191/scripts/suite-gate-191.sh` + self-test | utility + test | batch | `P190/suite-gate-190.sh` | exact (WR-09 changes) |
| `191/scripts/scan-191.sh` + `selftest-scan-191.sh` | utility + test | streaming (git log -p) / transform | `P190/scan-privacy-190.sh` + `P190/selftest-scan-190.sh` | role-match |
| `test/support/phase_evidence_path.ex` (reuse only) | utility | request-response | itself | exact |
| `script/check_release_workflow_integrity.exs` (inline resolver) | script | file-I/O | `test/support/phase_evidence_path.ex` | exact logic |
| 6 test files (phase170 vacuity, phase174 x3, phase175 runbook, release_status) | test | file-I/O | `phase165_evidence_test.exs:9-17` | exact |
| `test/crosswake/proof/phase180_twin_feasibility_test.exs` | test | request-response | itself (invert in place) | exact |
| `script/inventory_collection_assertions.exs` + `script/collection_assertion_ledger.json` | script | transform | itself (`IO.write` to `IO.binwrite`) | exact |
| `examples/phoenix_host` G2/G6 tests, Swift G4 test | test | request-response | `RESEARCH.md` "D-14" examples | exact |
| `test/crosswake/guides/native_shell_upgrade_test.exs` | test | n/a | format-only | n/a |
| `lib/crosswake/proof_lane/physical_iphone_preflight.ex` (WR-05) | service | request-response | `lib/crosswake/shell/ios_host_origin_mode.ex:165-175` | exact |
| `lib/crosswake/shell/ios_host_origin_mode.ex` (`@doc false` helper) | service | request-response | itself | exact |
| `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (WR-01/06) | controller (mix task) | request-response | itself, `annotate_stop/2` | exact |
| `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` | test | request-response | itself, lines 716-760 | exact |
| `test/crosswake/proof_lane/provenance_test.exs` (WR-03) | test | request-response | itself, lines 49-86 | exact |
| `lib/crosswake/planning/first_adopter_context.ex` (+12 extensions) | config/service | transform | itself, `@scannable_extensions` (67-70) | exact |
| `script/check_absence_is_not_success.exs` (pin recount) | script | batch | itself, line 65 | exact |
| `.planning/seeds/SEED-024-*.md` | record | n/a | `SEED-023-extend-scope-cardinality-gate.md` | role-match |
| `190-REVIEW-DISPOSITION.md` row edits | record | n/a | itself | exact |
| 191 EVIDENCE files | record | n/a | `P190/../190-EVIDENCE/*` (`head <sha>` / counts / `result pass|fail`) | exact |

## Pattern Assignments

### `191/scripts/git-pinned-191.sh` (utility, request-response)
**Analog:** `P190/git-pinned-190.sh`

Copy the scrub list, fixed env and pins (lines 4-7) and the subshell `g()` (9-17). The change is that `g()` hard-codes `-C "$CAND"` (line 15), so 191 must take the repo as an argument or a variable name.

```sh
G190_SCRUB="GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE ... GIT_EXEC_PATH"
G190_FIXED="GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_NO_REPLACE_OBJECTS=1 ... LC_ALL=C"
g() {
  (
    for _n in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do unset "$_n"; done
    for _n in $G190_SCRUB; do unset "$_n"; done
    for _p in $G190_FIXED; do export "$_p"; done
    exec git $G190_PINS -C "$CAND" "$@"
  )
}
```

Pitfall 12 (research): the scrub removes the global identity, and `hooksPath=/dev/null` disables hooks. Add a `gc()` commit variant that passes `-c user.name=... -c user.email=<noreply>` after the scrub, and never use plain `git clone` except for the first fetch. The `insteadOf` rewrite in global config is bypassed by the pinned form.
`g190_describe` (19-25) is the evidence-description pattern; copy it as `g191_describe`.

---

### `191/scripts/locate-191.sh` (utility, file-I/O)
**Analog:** `P190/locate-190.sh`

Keep the folder walk (lines 8-14), the unique-backup-root count (15-23), the `q()` shell-quote helper (27), and the env file written via `mktemp` then `chmod 600` then `mv` (28-45).

WR-11 changes:
- Drop the early `--ensure` exit on line 7 (`[ -f "$ENVF" ] && echo "locate: kept"`). Regenerate every run.
- Check the run folder owner and mode 700 before use. Line 26 only does `mkdir -m 0700` when it is missing.
- Use pinned git plus an untracked-file check.
- Compare the clone HEAD with its source HEAD. 190 uses plain `git` in `ensure-work-190.sh:14-16`.

---

### `191/scripts/ensure-clone-191.sh` (utility, batch)
**Analog:** `P190/ensure-work-190.sh`

```sh
set -u
umask 077
HERE=$(cd "$(dirname "$0")" && pwd -P) || exit 2
sh "$HERE/locate-190.sh" --ensure >/dev/null || exit 2
. /private/tmp/crosswake-phase190-run/env-190.sh
...
git -C "$R190" clone --no-hardlinks --branch candidate "$D" "$W" >/dev/null 2>&1 || { echo "ensure-work: clone_failed"; exit 2; }
...
if [ -z "$wh" ] || [ "$wh" != "$dh" ] || ! git -C "$W" diff --quiet HEAD ... ; then
  echo "ensure-work: work_diverged"; exit 2
fi
```

Copy:
- the fixed-label `echo "name: reason"` plus `exit 2` convention;
- the HEAD-equality check.

Change:
- Clone from GitHub `main` (not from `<durable-candidate>`). Take the URL from the recovery checkout's `origin`, and do not copy the candidate's local-bundle remote (fact F4).
- Then fetch `refs/heads/candidate`, run the `merge-base --is-ancestor` gate (D-01, stop and replan if false), and `merge --ff-only`.
- Set repo-local `user.email` to the noreply address before any commit.
- Swap the source path for the durable clone location outside `<tmp>`.
- Replace the plain-git status checks with pinned `status --porcelain --untracked-files=all`.

---

### `191/scripts/recovery-snap-191.sh` (utility, transform)
**Analog:** `P190/recovery-snap-190.sh` (17 lines, read-only digests)

```sh
export LC_ALL=C
G=${REC_GIT:?}
sha() { shasum -a 256 | awk '{print $1}'; }
printf 'head_file_sha256 %s\n' "$(sha < "$G/HEAD")"
cnt=$(cd "$G" && find refs -type f | awk 'END{print NR+0}')
printf 'loose_refs_sha256 %s\n' "$(cd "$G" && find refs -type f | sort | while IFS= read -r f; do shasum -a 256 "$f"; done | sha)"
printf 'config_sha256 %s\n' "$(sha < "$G/config")"
```

WR-10 additions:
- Fail with a fixed label if the folder, `HEAD` or `config` is missing. `${REC_GIT:?}` accepts any non-empty string.
- Digest `ls-files -s` through pinned git (content, not the raw index bytes).
- Digest `logs/HEAD`.
- Add an object-file count.
- Take a fresh before-snapshot at Phase 191 start, then diff with the after-snapshot.

Caution: the `| while ... | sha` pipelines are fine here because the digest is the value. Do not copy them for exit-code checks (feedback_pipe_masks_exit_code).

---

### `191/scripts/suite-gate-191.sh` (utility, batch)
**Analog:** `P190/suite-gate-190.sh` (47 lines)

Reusable parts:
- `HERE=` plus locate plus env source (6-8);
- totals extraction and `sed` parsing (19-23);
- failed-name extraction (26-27);
- `hdr()` evidence header (28);
- `result pass|fail` footer (43-45).

```sh
TL=$(grep -E '^[0-9]+ tests?, [0-9]+ failures?' "$RAW" | tail -n 1)
TESTS=$(printf '%s' "$TL" | sed -E 's/^([0-9]+) tests?.*/\1/')
EXCL=$(printf '%s' "$TL" | sed -n -E 's/.*\(([0-9]+) excluded\).*/\1/p'); EXCL=${EXCL:-0}
...
if [ "$FAILS" -eq 0 ]; then [ "$EXIT" -eq 0 ] || OK=0; else [ "$EXIT" -eq 2 ] || OK=0; fi
```

WR-09 and D-19 changes (each is a defect in 190):
- Line 9 `MIN=${2:-0}`. MIN must be required and greater than 0.
- Line 5 `export LC_ALL=C`. Remove it for child processes (D-12). Keep `LC_ALL=C` only for `sort` and `comm`.
- Line 12 `git -C "$W" diff --quiet HEAD` ignores untracked files and unpinned git. Use pinned `status --porcelain --untracked-files=all`.
- Line 17 writes to a raw log with `2>&1`. Instead capture each stage's exit code to a file, and read the orchestrator's `logs/<stage>.log`, whose first line is `status=N`. Set `CROSSWAKE_REPOSITORY_RUN_ROOT` and `CROSSWAKE_REPOSITORY_CAPTURE_ROOT`.
- Lines 13-14 and 29-34 (baseline mode): drop. There is no baseline mode.
- Line 19 loose grep: match the strict totals regex from RESEARCH `The suite gate parse`, and check the number of totals lines (7 expected for `root-proof`, pending assumption A1).
- Lines 30 and 45: write evidence to a temp file and `mv` after validation.
- Require nine PASS stage records and a matching excluded total and tag set. Keep only parsed totals and test names, never raw logs.

---

### `191/scripts/scan-191.sh` (utility, streaming and transform)
**Analog:** `P190/scan-privacy-190.sh` (structure only; D-18 says not to use its classes on code)

Copy the skeleton:

```sh
set -u
umask 077
SCR=$(mktemp -d /private/tmp/crosswake-scan-190.XXXXXX) || { echo "scan: scratch failed"; exit 2; }
trap 'rm -rf "$SCR"' EXIT
trap 'exit 2' INT TERM HUP
# patterns assembled from fragments so this file does not match its own classes
P_HOME_ERE="/Us""ers/[^/[:space:]]+"
P_TEMP_ERE="/private/va""r/|/va""r/folders/"
chk() { # class flags pattern copy path
  grep $2 -e "$3" "$4" >/dev/null 2>&1; rc=$?
  case $rc in 0) hits=$((hits + 1)); ... ;; 1) : ;; *) echo "scan: grep failed"; exit 2 ;; esac
}
echo "scan: files $files"
echo "scan: hits $hits"
[ "$hits" -eq 0 ] || exit 1
exit 0
```

Copy these conventions:
- Fragment-assembled patterns (lines 11-26) so the scanner does not flag itself. The home path pattern lives on line 18, the temp path on line 19.
- Exit contract: 0 clean, 1 hits, 2 scope error ("never a clean pass").
- `redact()` (70-75), which prints `<home>` and never a real path.
- The fixed label output `scan: <noun> <count>`.
- The `grep` rc case (0/1/else) in `chk`.

Change for D-18, D-19:
- Inputs become the four git streams: `git log -p --no-renames -m --no-ext-diff --no-textconv` (added lines only), the `rev-list --objects` blobs (binary as raw bytes), tree path names, and commit, author, committer and tag text. Run them through pinned git with the range as the argument.
- Print and enforce non-zero counts: commits scanned (equal to `rev-list --count main..HEAD`), added lines and bytes, text and binary blobs, paths, identities, term count. Exit 2 on any zero.
- Terms come from the `<denylist>` file (mode 0600, outside the repo and `<tmp>`) through `CROSSWAKE_PRIVATE_ADOPTER_TERMS`. Zero terms is exit 2. Never print a term. Case-insensitive except hex shapes.
- The 190 classes `at` (line 95) and `credential` `token|secret` (P_CRED_ERE line 22) become triage-only classes, not blocking.
- The email class must allow `noreply@*`, `git@github.com` and the reserved example domains (research, Privacy Scan Grounding).
- Wrap gitleaks 8.30.1: `gitleaks git --no-banner --redact --log-opts="<main>..HEAD" --report-format json --report-path <scratch> --ignore-gitleaks-allow .` (F17), with `GIT_*` scrubbed. Record only version, rule count (222, from SARIF) and finding count.
- Bind the result to the `HEAD` and `main` SHAs (D-22).

---

### `191/scripts/selftest-scan-191.sh` and the other self-tests (test)
**Analog:** `P190/selftest-scan-190.sh` (177 lines)

```sh
PREFIX=/private/tmp/crosswake-selftest-scan-190
rm_tree() { case "$S" in "$PREFIX".*) rm -rf "$S" ;; esac; S=; }
trap 'rm_tree' EXIT
trap 'rm_tree; exit 1' INT TERM HUP
mk_tree() { S=$(mktemp -d "$PREFIX.XXXXXX") || ...; case "$S" in "$PREFIX".*) : ;; *) ... exit 1 ;; esac; mkdir "$S/bin" "$S/d"; }
run_scan() { sh "$SCAN" "$1" > "$S/out.txt" 2>&1; RC=$?; }
expect() { [ "$RC" -eq "$1" ] && grep -qx "$2" "$S/out.txt"; }      # RC plus exact label line
run_ctl() { TOTAL=$((TOTAL + 1)); mk_tree; if "$2"; then GOOD=$((GOOD + 1)); echo "$1 $3: as expected"; else echo "$1 $3: NOT as expected"; fi; rm_tree; }
```

Patterns to copy:
- `ctl_sNN` functions, each ending in `expect <rc> "<label>"`.
- A leak guard: `! grep -q 'ers/x/y' "$S/out.txt"` (S09) proves output never echoes the planted value.
- Signal and cleanup control (S12): a `PATH`-shim that sleeps, then `kill -TERM`, then compare scratch listings before and after.
- A parallel-runs-identical control (S13).
- A `--tracer` mode that runs 3 controls first.
- A final `selftest-scan: controls $GOOD of $TOTAL as expected` line.
- A negative control that the old tool still behaves as recorded (S15 runs the 188 original).

191 additions: one planted control per D-19 class and position (added then deleted later, binary blob, commit message, author email, file name, upper-case credential, canary adopter term, gitleaks shape), a clean control with non-zero counts, and zero-term and zero-commit exit-2 controls. For `carry-191.sh`, the five D-09 controls: dropped file, flipped byte, extra file, mode change, empty manifest, each with its own label. Add unmatched path, symlink refused, and both hashes recorded.

---

### `191/scripts/carry-191.sh` (utility, batch/transform)
**Analog:** partial. `P190/scan-privacy-190.sh` lines 28-50 (the list expansion that refuses symlinks, special files and empty scope).

```sh
if [ -L "$line" ]; then echo "scan: symlink refused"; exit 2
...
find "$line" ! -type f ! -type d ! -type l > "$SCR/special" ...; [ -s "$SCR/special" ] && { echo "scan: special file refused"; exit 2; }
```

Use the same hard-fail, fixed-label, exit-2 style for the manifest build (symlinks refused, unmatched path fails, tolerate empty directories).

The rest has no analog; use RESEARCH sections `Path-to-milestone table` and `Pitfalls 4-7`. Hash with `git hash-object` and `shasum -a 256`. Compare against `git diff --raw --no-renames main..HEAD -- .planning`.

---

### Resolver, six test files (test, file-I/O)
**Analog:** `test/crosswake/proof/phase165_evidence_test.exs:9-17`, which uses `Crosswake.Test.PhaseEvidencePath.resolve/2` (module at `test/support/phase_evidence_path.ex:25-51`).

```elixir
@evidence Crosswake.Test.PhaseEvidencePath.resolve(
            "quality-ratchet-release",
            "174-clean-room-host-realism-adopter-fidelity/evidence/174-legacy-rindle-local-run.log"
          )
```

Per-file notes:
- `phase174_cleanroom_lane_parity_test.exs:36-37` has `@live_phase_dir` and `@archived_phase_dir`. The archived path there is `milestones/v23.0/phases/...`, which is wrong; the archive is `milestones/v23.0-phases/`. Replace both with one `resolve/2` call.
- `phase170_vacuity_taxonomy_convention_test.exs`: a resolver alone is not enough (Pitfall 2). Scope to a literal roster of the seven v23 phases (169-175), resolve each, and assert the roster length is 7.
- Add a negative control: `resolve/2` on a path in neither place returns the live path, and the caller fails.

### `script/check_release_workflow_integrity.exs` (script, file-I/O)
The script runs under plain `elixir`, so it cannot load `test/support`. Inline the logic (RESEARCH "D-06: inline resolver", about 12 lines, same algorithm as `phase_evidence_path.ex:32-51`). Replace the literal read at line 1683:

```elixir
File.read!(".planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-INCIDENT-DOC-COMMIT.md")
```

Shell-side model of the same algorithm: `script/phase_evidence_path.sh:12-24`.

---

### `test/crosswake/proof/phase180_twin_feasibility_test.exs` (test, request-response)
**Analog:** itself (invert in place). Keep the `validate_with/1` helper (lines 6-24) and the `@tag phase180_gate: "G1"` convention (lines 27 and 35). Replace the test at lines 27-33:

```elixir
assert [error] = errors
assert error.key == :capabilities
assert error.message =~ "host.study.audio.play"
```

with the two tests in RESEARCH "D-13" (`== []` for the host command, and `assert [error] = ...` for an unknown core capability). Avoid `Enum.any?/all?`; the existing control uses `refute Enum.any?` at line 38 and is the form to leave alone or rewrite per D-13. Regenerate the ledger in the same commit, because the ledger `display` holds the test line number (F16).

### `script/inventory_collection_assertions.exs` (script, transform)
Lines 86 and 107 are `|> IO.write()`. Change both to `|> IO.binwrite()`. Add a `LC_ALL=C` negative control (no new `.exs` file).

---

### `lib/crosswake/proof_lane/physical_iphone_preflight.ex` (WR-05)
**Analog:** `lib/crosswake/shell/ios_host_origin_mode.ex:165-175`, which already encodes the required shape. Read from `<durable-candidate>`.

```elixir
defp observe_activation(root) when is_binary(root) do
  with {:ok, bytes} <- File.read(Path.join(root, "Fixtures/route_activation.json")),
       {:ok, %{"origin" => origin}} when is_binary(origin) <- Jason.decode(bytes),
       {scheme, canonical} when not is_nil(canonical) <- canonical_origin(origin) do
    {scheme, canonical}
  else
    _ -> :none
  end
end
```

Target in the preflight, `activation_refusal/1` (lines 186-201): the current `{:ok, _} <- Jason.decode(bytes)` accepts any decoded value. Keep the absent-file branch (`{:error, :enoent} -> nil`) and `@unreadable_activation_reason`. Expose a `@doc false` predicate that reuses `canonical_origin`, and leave `observe/2` unchanged (190 D-08). The table cases are `null`, `[]`, `{}`, `{"origin": 5}`, a list origin and an origin that will not canonicalize, each blocking with PI-PREFLIGHT-CONFIG.

### `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex` (WR-01/06)
**Analog:** itself, lines 91-100.

```elixir
@registry_timeout_note "Also check for leftover child processes: ..."
def annotate_stop({code, [result, cause, report, next]}, {:error, :registry_timeout}) do
  cause = if cause == "first cause: none", do: "first cause: registry_timeout", else: cause
  {code, [result, cause, report, next <> " " <> @registry_timeout_note]}
end
def annotate_stop(verdict, _stop_result), do: verdict
```

Add one clause per `{:error, :child_still_alive}` and `{:error, :registry_gone}` with its own note, keeping the exit code and receipt. Test analog is `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs:716-760`. Keep the `@passed` fixture (lines 719-724) and the pattern `assert {0, [l1, l2, l3, l4]} = ...`. Replace the test at lines 752-756, `for stop <- [:ok, {:error, :registry_gone}, {:error, :child_still_alive}] do assert ... == @passed`, with one assertion per result (`:ok` stays unchanged).

### `test/crosswake/proof_lane/provenance_test.exs` (WR-03 test half)
**Analog:** itself, lines 49-86. Existing assertions `assert Provenance.commit_ref(dir) == "git-" <> head` (49, 59) and `== "git-unknown"` (58, 64, 86). Under each hostile config, add the positive assertion before the chmod.

### `lib/crosswake/planning/first_adopter_context.ex`
**Analog:** itself. Extend `@scannable_extensions` (lines 67-70, alphabetical sigil `~w(...)`) with the 12 extensions: `.xcconfig .entitlements .xcprivacy .xctestplan .source .tsv .out .sha256 .stdout .stderr .body .patch`. Add one classification test per extension in the existing planning test file, with no new `.exs`. The `$NN` transform for three Phase 189 plan files uses the same machinery as the `<home>` transform.

### `script/check_absence_is_not_success.exs` (pin recount)
Line 65: `{"test-files", "test/**/*.exs", 253}`. Recount on the final HEAD with `git ls-files test | grep -c '\.exs$'` and `find test -name '*.exs'`. The literal `git ls-files 'test/**/*.exs'` prints 252 and is wrong (research anti-pattern). Change the pin only on a measured difference.

### `SEED-024-*.md`
**Analog:** `.planning/seeds/SEED-023-extend-scope-cardinality-gate.md` (use its frontmatter and section shape). Contents and triggers are in D-17c. The seed count rises from 23 to 24; the guard minimum is 1, so no pin change.

## Shared Patterns

### Fixed-label output, exit-2 scope errors
**Source:** `P190/scan-privacy-190.sh` (lines 4, 9, 35, 50), `P190/ensure-work-190.sh:9-18`
**Apply to:** every 191 script
`echo "tool: reason"; exit 2` for every scope error; never print a path or value; an empty scope never passes.

### Pinned git
**Source:** `P190/git-pinned-190.sh:4-17`
**Apply to:** every git call in 191 scripts (clone checks, status, rev-list, log -p, ls-files). `LC_ALL=C` is allowed only here and for `sort`/`comm`.

### Scratch folder and cleanup traps
**Source:** `P190/scan-privacy-190.sh:13-15` and `selftest-scan-190.sh:17-24`
**Apply to:** scanner, carry, gate, and all self-tests
`mktemp -d` under a fixed prefix, `trap ... EXIT`, `trap 'exit 2' INT TERM HUP`, `umask 077`, guarded `rm -rf` with a prefix case-check.

### Evidence record shape
**Source:** `P190/suite-gate-190.sh:28, 43-45`
**Apply to:** all 191 evidence outputs
`head <sha>`, counts, `result pass|fail`. Write to a temp file and `mv` after validation. Store counts, digests and fingerprints only, never raw logs.

### Privacy placeholders
**Source:** `P190/scan-privacy-190.sh:70-75` (`redact()`)
**Apply to:** all evidence and PATTERNS or SUMMARY files
Use `<home>`, `<tmp>` and the others. Fragment-assemble sensitive literals in scripts (`"/Us""ers/"`).

### No pipe-masked exit codes
**Apply to:** `suite-gate-191.sh`, `carry-191.sh`. The 190 gate captured `$?` straight after a redirect (line 17-18), which is the right shape. Extend it to write exit codes to files for each stage.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `carry-191.sh` core (path-to-milestone table, manifest, transform, equality verify) | utility | batch | No prior manifest or carry tool. Use RESEARCH `Path-to-milestone table` and D-09. Only the symlink and special-file refusal style is borrowed. |
| Four-input git-history scanner core (`log -p`, `rev-list --objects` blobs, tree names, identities) | utility | streaming | 190 and 188 scan a file list, not history. Use D-18 and fact F17 for the gitleaks wrapper. |

## Metadata

**Analog search scope:** `P190/` (10 scripts), `188-freeze-and-twin-05/scripts/` (listing), `test/support/`, `script/`, `.planning/seeds/`, `<durable-candidate>` `lib/` and `test/` (read-only, located via the Phase 190 env file).
**Files scanned:** about 30 read or grepped.
**Pattern extraction date:** 2026-10-19
