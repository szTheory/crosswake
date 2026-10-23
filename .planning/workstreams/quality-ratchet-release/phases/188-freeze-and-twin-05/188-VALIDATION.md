---
phase: "188"
slug: "freeze-and-twin-05"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-16"
---

# Phase 188 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `188-RESEARCH.md` § Validation Architecture. Decisions: `188-CONTEXT.md` D-01..D-21.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | POSIX `sh` scripts with `jq -e` assertions and negative controls; no ExUnit work (no product code changes) |
| **Config file** | none — scripts live in `/private/tmp/crosswake-phase180-run/` (Wave 0 creates them) |
| **Quick run command** | `for t in selftest-188.sh selftest-188-records.sh selftest-188-result.sh; do sh /private/tmp/crosswake-phase180-run/$t >/dev/null 2>&1 || exit 1; done` (31 + 18 + 37 controls; each plan's throwaway dirs under its own prefix `/private/tmp/crosswake-selftest-188-01.*`, `-188-02.*`, `-188-03.*`, scan scratch under `/private/tmp/crosswake-scan-188-03.*`, and each plan's remnant check looks only at its own prefix (revision ruling 1), stub `mix` on `PATH`, never `verify_twin`, never the real `twin-05`) |
| **Full suite command** | selftest + `shasum -a 256 -c history-184.before.sha256` (exit captured, 87 OK required) + `assert-twin-05.sh` on the real result + `scan-privacy-188.sh` |
| **Estimated runtime** | selftest < 30 s; the real compile + preflight takes minutes; the run itself ~6 min (60 min task deadline) |

Rules: never pipe a check into `tail`/`head` and trust the exit; never accept a check that ran zero cases (the selftest prints and asserts its control count).

---

## Sampling Rate

- **After every task (no commits in this checkout):** selftest + history-manifest check
- **After every plan wave:** selftest, manifest check, candidate untouched (HEAD `a53fbef…`, porcelain 0 bytes, push URL `no-push-phase180`)
- **Before `/gsd-verify-work`:** D-21 list green (manifest, `cmp`/sha256, `assert-twin-05.sh` success + negative mode, candidate unchanged, privacy scan zero hits)
- **Max feedback latency:** 30 seconds (selftest)

---

## Per-Requirement Verification Map

Task IDs are filled in by the planner; each row must map to at least one task `<automated>` command.

| Requirement / criterion | Behavior | Task ID | Automated Command | File Exists | Status |
|-------------------------|----------|---------|-------------------|-------------|--------|
| TWIN-07 / 1 | HEAD, tree, clean, push URL, zero probe at freeze (D-01, D-02); one-sentence criterion-1 `summary` plus separate `status` (ruling I1); `accepted_exception` names both ignored classes, `_build` and the example-host SQLite files, never only `_build` (rulings 5, W3) | 188-02-T1 (controls R01-R06), 188-04-T1 | `freeze-check-188.sh a53fbef…` -> `188-FREEZE.json` 7 labels pass; `jq -e` requires one-sentence summary, `.status`, and `accepted_exception` containing `_build` and `crosswake_example.db` | ✅ (188-02) | ✅ green |
| TWIN-07 / 1 | refresh writes git-derived values only, keeps `*.pre-188.json`, refuses bad input (D-09) | 188-02-T2 (R10-R18), 188-04-T2 | `selftest-188-records.sh` 18 of 18; real refresh then `jq -e` on both records and `core_diff_paths` vs `git diff --name-only` | ✅ (188-02) | ✅ green |
| TWIN-07 / 1 | identity and prepared record from committed bytes (D-10) | 188-02-T1 (R07-R09), 188-04-T2 | `jq -e --slurpfile` identity vs `twin-05-candidate.json`; digests equal twin-04's | ✅ (188-02) | ✅ green |
| TWIN-07 / 1 | twin-01..04 byte-unchanged (D-11) | 188-04-T2 (t1, t2), 188-01-T2 (gate label, C20), 188-05-T2 (t3) | `shasum -a 256 -c history-184.before.sha256` rc 0 and 87 `: OK` lines at each point; `cmp twin-04/twin-result.json 183-TWIN-RESULT.json` | ✅ manifest exists | ✅ green |
| TWIN-07 / 1 | no later commit changes attested source | 188-04-T1..T3, 188-05-T1 | HEAD `a53fbef…`, porcelain 0 bytes, push URL `no-push-phase180` in every verify | ✅ | ✅ green |
| TWIN-07 / 1 | ignored example-host SQLite files not written by the run (ruling W3: children get `DATABASE_PATH` inside the run root, twin_runtime.ex:140, 551-552; twin_journey.ex:228-241; gate never migrates) | 188-01-T2 (C04 static: no ecto task or app.start), 188-05-T1 (pre), 188-05-T2 (post), 188-05-T3 (record) | `candidate-db-05.<A>.pre` and `candidate-db-05.post` 3 base-name lines each, no path; `188-TWIN-RECORD.md` names `crosswake_example.db` with the pre/post result | ✅ | ✅ green |
| TWIN-07 / 1 | script evidence equals what ran (D-08); unmodified `prepare-record.sh` and every copy with the `"$@"` positional token scan clean (blocker ruling) | 188-04-T3, 188-05-T1 precondition | `cmp` per copy; `(cd PD && shasum -a 256 -c 188-SCRIPTS.sha256)` 10 OK; early scan over the ten copies `scan: hits 0` | ✅ | ✅ green |
| TWIN-07 / 2 | digests match: record vs fresh `git show`, identity vs record (D-07a) | 188-01-T2 (C12, C13), 188-05-T1 | gate labels `record_digests_match_git_show`, `identity_matches_record` | ✅ (188-01) | ✅ green |
| TWIN-07 / 2 | 0700 empty owned root outside candidate, no sentinel, roots 01..05 (D-12, D-13) | 188-01-T1/T2 (C05-C11), 188-05-T1 | gate labels `root_is_private_dir`, `root_empty`, `root_outside_candidate`, `no_started_or_exit_sibling`, `roots_are_01_to_05` | ✅ (188-01) | ✅ green |
| TWIN-07 / 2 | zero gitlinks, no `.gitmodules` (D-07b) | 188-01-T2 (C15, C16), 188-02-T1 (R05) | labels `no_gitlinks`, `no_gitmodules` | ✅ | ✅ green |
| TWIN-07 / 2 | no doctor JSON / router name in inputs (D-07c); classes match only the dotted module form `[A-Z][A-Za-z0-9_]*[.]Router([^A-Za-z0-9_]\|$)` and the quoted key form `"unmanaged_(routes\|paths)"[[:space:]]*:`, never a path string (ruling 2) | 188-01-T2 (C18, C29, C30), 188-03-T2 (S08, S09, S18), 188-04-T3, 188-05-T2, 188-05-T3 | label `no_doctor_json_in_inputs`; C29/S18 pass the 10 doctor/router path shapes; 188-04 early scan of the real 129-path 182 record (10 doctor/router paths) reports 0 hits; pre-copy scan of `twin-result.json`; run-root router/doctor findings recorded informationally | ✅ | ✅ green |
| TWIN-07 / 2 | read-only preflight passes; build path refinement (D-12), fresh `_build_188_twin05/attempt-<N>` per gate attempt | 188-01-T1 (C01), 188-01-T2 (C22, C23, C24), 188-05-T1 | labels `twin_preflight_allowed`, `run_env_unsets_build_and_db`, `dedicated_build_fresh`; latest `go-no-go-05.<N>.json` 30 pass | reserved for go/no-go | ✅ green |
| TWIN-07 / run once | the sentinel is the one-way door: any invocation after `twin-05.started` exits 3 before a gate record or mix call; a no-go writes a new noclobber `go-no-go-05.<N>.json` and is re-gatable while the root is empty (D-12, D-14, ruling 4) | 188-01-T1 (C02, C03), 188-01-T2 (C09, C26) | `selftest-188.sh` stub-`mix` log: exactly one verify_twin line after a no-go then a go; exit 3 after `.started` | ✅ (188-01) | ✅ green |
| TWIN-07 / run once | every wait on the one-way launch is bounded (revision ruling 2): the script's fixed `GATE_DEADLINE_S=2700` refuses the sentinel with cause `gate_deadline_exceeded`; the owner's pre-start bound of 3300 s after `run-once-05.<A>.launched` stops a stalled gate's process group and records `gate_stalled`/`gate_unterminated` (decision class) or, if `.started` appeared, D-14 outcome unknown; the 75-minute bound after `.started` never signals the run | 188-01-T2 (C31), 188-05-T1 | C31: over-deadline gate writes cause `gate_deadline_exceeded`, no `.started`, zero verify_twin lines, and stall markers advance the attempt number; static `GATE_DEADLINE_S=2700` exactly once; 188-05-T1 verify accepts a record or a stall marker for attempt A and requires `run-once-05.<A>.launched` | ✅ (188-01) | ✅ green |
| TWIN-07 / 2 | not_run rule is an exact list (revision ruling 4): chain 3, 4, 5, 7, 29; first chain failure makes later chain labels not_run; any failure in 1-28 makes 29 not_run; labels 1, 2, 6, 8-28, 30 always run | 188-01-T2 (C05, C22, C28) | C28 three sub-trees: 3 fail -> 4, 5, 7, 29 not_run; 5 fail -> 7, 29; 7 fail -> 29; C05 only 29 not_run; C22 none not_run, 30 pass | ✅ (188-01) | ✅ green |
| TWIN-07 / run once | exactly one `verify_twin` call, no retry construct | 188-01-T2 (C04), 188-05-T1 | static awk/grep on non-comment lines; after the run exactly five `twin-NN` roots and no twin-06 | ✅ (188-01) | ✅ green |
| TWIN-08 / 3 | exit 0 | 188-05-T1, 188-05-T2 | `twin-05.exit` = `0`; stdout line 1 `result: passed (exit 0)` | ✅ | ✅ green |
| TWIN-08 / 3 | 10 groups, 7 joins, 5 limits, receipt digest, 49 unique sub-observations (D-18) | 188-03-T1 (A01-A15), 188-05-T2 | `assert-twin-05.sh twin-05/twin-result.json twin-05/receipt.json` prints `assert: ok`; `--only A01-A15` 15 of 15 | ✅ (188-03) | ✅ green |
| TWIN-08 / 3 | byte copy (D-17) | 188-05-T2 | `cmp` rc 0; equal full sha256; assert on the copy | ✅ | ✅ green |
| TWIN-08 / 3 | privacy scan zero hits over planning-bound files (D-17, ruling 3) with explicit classes (ruling W1): home `/Users/[^/[:space:]]+` and `$HOME`; temp `/private/var/\|/var/folders/` only; UUID `[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}` only; the two D-17 credential words; the at-sign; username word; router and doctor classes. Neutralised per occurrence, never per line: the template literal and the `$@` positional token | 188-03-T2 (S01-S22: S05/S06/S07 planted UUID, `/private/var/`, `/var/folders/` hit; S19 `"$@"` alone clean; S20 `"$@"` plus another at-sign hits; S21 `/private/tmp` clean; S22 40-hex digest clean), 188-04-T3, 188-05-T2, 188-05-T3 | pre-copy `scan-188-05-result` on `twin-result.json` (hit: not copied, BLOCKED); blocking `scan-privacy-188.sh scan-188-05.<A>.files` exit 0, `scan: hits 0`, no run-root path in the list; informational `scan-188-05-info` recorded by class and file name; home/username check on STATE/ROADMAP/REQUIREMENTS | ✅ (188-03) | ✅ green |
| TWIN-08 / 3 | limits disclosed (D-19) | 188-05-T3 | `188-TWIN-RECORD.md` first content line and 16 required strings | ✅ | ✅ green |
| TWIN-08 / 4 | failure preserved honestly (D-20) | 188-05-T2, 188-05-T3 | non-pass: annotation by sha256, `188-05-BLOCKED.md`, no SUMMARY, TWIN-08 unticked, the twin-06 handoff sentence exactly once in STATE.md and exactly once in ROADMAP.md (ruling W2), no twin-06 path | conditional | ✅ green (non-pass path not reached: twin-05 passed; covered by 188-03 negatives) |
| TWIN-07 / 2 | gate no-go consumes nothing (ruling 4) | 188-01-T2 (C26), 188-05-T1, 188-05-T3 | `188-05-BLOCKED.md` first line `Gate attempt A: environmental no-go` or `decision-class no-go`; root empty and 0700; no `.started`; TWIN-07/08 unticked and not failed; environmental handoff names the `$gsd-execute-phase 188` re-run, decision class names the owner or re-freeze decision (compile/preflight labels stay decision class with an owner review, ruling I2; `run_env_unsets_build_and_db` is decision class as a script defect, revision ruling 3; causes `gate_deadline_exceeded`, `gate_stalled` and `gate_unterminated` are decision class); the same handoff in STATE.md and ROADMAP.md; a re-gate renames the old BLOCKED to `188-05-NOGO-<K>.md` | conditional | ✅ green (no no-go occurred: attempt 1 passed; covered by 188-01 C26) |
| Plan outcome honesty | a failed selftest or control leaves `188-0N-BLOCKED.md` and no SUMMARY; 188-04 starts only with 01-03 SUMMARYs and no BLOCKED (ruling 1) | 188-01..03 output, 188-04 preconditions | file-existence check in 188-04 preconditions | conditional | ✅ green |

Scan scope (D-17, orchestrator resolution 4 and ruling 3): the blocking scan covers planning-bound files only (records, script copies, gate records, `188-TWIN-RESULT.json`, `188-TWIN-RECORD.md`, SUMMARY/BLOCKED/NOGO files). `twin-05/twin-result.json` is scanned before the copy and is not copied on a hit. Other run-root outputs are scanned read-only and informationally; their hits are recorded by class and file name and never change the verdict. 188-CONTEXT.md, 188-DISCUSSION-LOG.md, 188-RESEARCH.md, 188-PATTERNS.md, this file and the 188-0N-PLAN.md files are not scanned by the full regex, because they quote the scan regex and the scanned words. STATE.md, ROADMAP.md and REQUIREMENTS.md get the home-path and username checks only, because they hold pre-existing historical text.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `selftest-188.sh` (188-01), `selftest-188-records.sh` (188-02), `selftest-188-result.sh` (188-03) with throwaway fixtures (scratch repo with gitlink and `.gitmodules` variants, stub `mix`)
- [ ] `assert-twin-05.sh` (constants: T01..T10, 7 joins, 5 limits, 49 unique sub-observations)
- [ ] `scan-privacy-188.sh` (explicit privacy classes + doctor/router regex, planted-hit controls, `$@` and template neutralisation per occurrence, `/private/tmp` and 40-hex non-hit controls)
- [ ] `refresh-handoffs-188.sh`, `make-identity-188.sh`, `freeze-check-188.sh` (188-02; `prepare-record.sh` reused unchanged), `run-once-05.sh` (188-01)

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (plans 188-01..03)
- [x] No watch-mode flags
- [ ] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
