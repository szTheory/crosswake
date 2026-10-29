---
phase: "195"
slug: "pipeline-repair-and-hygiene"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-26"
---

# Phase 195 — Round-3 Gap Validation Strategy

Scope: gap plans 195-19 through 195-21, reopening REL-03 only. The independent continuity and behavior audit below is complete. No RESEARCH.md exists: gap planning uses inspected existing code, prior execution evidence and reproduced failures. Previous phase evidence and accepted GR-06/Phase197 deferrals remain retained; completed non-gap delivery work is not repeated.

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | Existing Node built-in node:test; existing ExUnit available for a demonstrated regression |
| Config | Existing repository scripts/test files; no dependency or framework installation |
| Quick command | `node --test test/js/ci_secret_masking.test.mjs` |
| Full JS command | `node --test test/js/*.mjs` |
| Related verifier | `node --test test/js/repository_verification.test.mjs` (already included in full JS) |
| One-time delivery assertions | New phase-local scripts/verify-gap3-evidence.mjs in plan 21; not promoted to CI |
| Planning baseline | Masking suite 138/138 passes while independent signing/deploy/camel-case/container/armor probes leak; KEY_LINE padding grows quadratically |
| Runtime target | Quick task checks under 60 seconds; each adversarial child timeout 2000 ms; stop immediately on timeout rather than repeating it |

## Sampling Rate

- Every task and every task commit: its targeted command plus quick masking suite.
- Every plan wave: full JS suite; no three consecutive tasks without automated feedback.
- Every new fix head: review/privacy/CI evidence invalidated and refreshed.
- Before irreversible-action decision: candidate/gate helper checks read live GitHub head, required checks, separate synthetic merge SHA and deletion setting.
- After approved merge: landed itself fetches and safely detaches the same checkout to actual main, checks SHA/source blobs/clean state before and after bounded child quick/full JS plus all-round controls, derives its receipt from those processes, and safely restores the saved docs ref. Caller-written success fields are insufficient.
- Before requirement completion: fresh landed helper verdict, source evidence and orchestrator-owned metadata agree.

## Per-Task Verification Map

Task identifiers use plan-task suffixes; waves continue after completed plan 18's wave 3. Plans share production files and the single checkout, so 19 → 20 → 21 is sequential.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 195-19-01 | 19 | 4 | REL-03 | T-195-70/71 | Inventory-derived identifiers masked through real failing child, padding bounded | integration/performance | V19-01 below: exact plan command, full-suite TAP identity gate | Existing file; all three new executed identities mandatory | passed (execution) |
| 195-19-02 | 19 | 4 | REL-03 | T-195-70 | Complete container/name-value/wrapped-tuple values masked | integration | V19-02 below: exact plan command, full-suite TAP identity gate | Existing file; all three new executed identities mandatory | passed (execution) |
| 195-19-03 | 19 | 4 | REL-03 | T-195-71/72 | PGP/other private-key armor bodies masked through END or fail-closed input end | integration/regression | `node --test test/js/ci_secret_masking.test.mjs && node --test test/js/*.mjs` | Existing files; new armor rows required | passed (execution) |
| 195-20-01 | 20 | 5 | REL-03 | T-195-73/74 | Exact supported stdout registration; bracket/github.token derivations detected | guard/live emulator | V20-01 below: exact plan command, full-suite TAP identity gate | Existing file; all three new executed identities mandatory | passed (execution) |
| 195-20-02 | 20 | 5 | REL-03 | T-195-75/76 | Raw-window seed presence, non-vacuous controls, independent timing and pinned readability | regression/performance | `node --test test/js/ci_secret_masking.test.mjs` | Existing file; new controls required | passed (execution) |
| 195-20-03 | 20 | 5 | REL-03 | T-195-77 | Named provider/CLI/URL/encoding/JWT forms masked with bounded rules | integration/regression | `node --test test/js/ci_secret_masking.test.mjs && node --test test/js/*.mjs` | Existing files; new rows required | passed (execution) |
| 195-21-01 | 21 | 6 | REL-03 | T-195-79/80/82 | Independent all-round review, exact-head green CI and privacy-clean PR | evidence/live readback | `node "$P/scripts/verify-gap3-evidence.mjs" --self-test --ws quality-ratchet-release && node "$P/scripts/verify-gap3-evidence.mjs" candidate --ws quality-ratchet-release` | New helper created by this task before use | passed (execution) |
| 195-21-02 | 21 | 6 | REL-03 | T-195-78 | Current per-operation permission with separate automatic deletion scope | evidence/live readback | `node "$P/scripts/verify-gap3-evidence.mjs" gate --ws quality-ratchet-release` | Plan 21 task 1 | passed (execution) |
| 195-21-03 | 21 | 6 | REL-03 | T-195-78/80/81/82 | Landed independently executes actual-main tests/controls and derives proof from process results | landing/reverification | `node "$P/scripts/verify-gap3-evidence.mjs" landed --ws quality-ratchet-release` | Plan 21 task 1; no caller-authored proof accepted | passed (execution) |

P is the repository-relative phase directory specified in plan 21. All checks are run from checkout root. No private machine path is evidence.

### Exact Mandatory-Family Commands

These are the matching plan task automated commands, not shorthand filters. Each spawns the unfiltered masking suite with TAP, requires positive actually executed non-skipped tests and all three exact new family identities, runs a zero-match child, and rejects a copied result missing each required family while all old successful tests remain. Planning baseline: V19-01 returns nonzero against the current old suite because mandatory new identities are absent.

V19-01 (195-19 task 1):

```sh
node --input-type=module -e 'import{spawnSync}from"node:child_process";const required=process.argv.slice(1);const passed=s=>s.split("\n").filter(l=>/^ok \d+ - /.test(l)&&!/# (SKIP|TODO)\b/i.test(l)).map(l=>l.replace(/^ok \d+ - /,"").replace(/ #.*$/,""));const good=s=>required.length>0&&passed(s).length>0&&required.every(n=>passed(s).includes(n));const args=["--test","--test-reporter=tap","test/js/ci_secret_masking.test.mjs"];const opts={encoding:"utf8",timeout:55000,maxBuffer:33554432};const r=spawnSync(process.execPath,args,opts);if(r.error||r.status!==0||!good(r.stdout))throw Error("required executed case family missing or failed");const z=spawnSync(process.execPath,[...args.slice(0,2),"--test-name-pattern=^NO_ROUND3_TEST_CAN_MATCH$",args[2]],opts);if(z.error||z.status!==0||good(z.stdout))throw Error("zero selection control failed");for(const n of required){const omitted=r.stdout.split("\n").filter(l=>!l.startsWith("ok ")||l.replace(/^ok \d+ - /,"").replace(/ #.*$/,"")!==n).join("\n");if(good(omitted))throw Error("missing family control failed");}console.log("required executed families "+required.length+"; zero-selection and omitted-family controls passed");' -- 'round3 structural repository signing assignment' 'round3 inventory all workflow secret names' 'round3 padding credential whitespace matrix'
```

V19-02 (195-19 task 2):

```sh
node --input-type=module -e 'import{spawnSync}from"node:child_process";const required=process.argv.slice(1);const passed=s=>s.split("\n").filter(l=>/^ok \d+ - /.test(l)&&!/# (SKIP|TODO)\b/i.test(l)).map(l=>l.replace(/^ok \d+ - /,"").replace(/ #.*$/,""));const good=s=>required.length>0&&passed(s).length>0&&required.every(n=>passed(s).includes(n));const args=["--test","--test-reporter=tap","test/js/ci_secret_masking.test.mjs"];const opts={encoding:"utf8",timeout:55000,maxBuffer:33554432};const r=spawnSync(process.execPath,args,opts);if(r.error||r.status!==0||!good(r.stdout))throw Error("required executed case family missing or failed");const z=spawnSync(process.execPath,[...args.slice(0,2),"--test-name-pattern=^NO_ROUND3_TEST_CAN_MATCH$",args[2]],opts);if(z.error||z.status!==0||good(z.stdout))throw Error("zero selection control failed");for(const n of required){const omitted=r.stdout.split("\n").filter(l=>!l.startsWith("ok ")||l.replace(/^ok \d+ - /,"").replace(/ #.*$/,"")!==n).join("\n");if(good(omitted))throw Error("missing family control failed");}console.log("required executed families "+required.length+"; zero-selection and omitted-family controls passed");' -- 'round3 container inspect values' 'round3 name-value record isolation' 'round3 tuple wrapped values'
```

V20-01 (195-20 task 1):

```sh
node --input-type=module -e 'import{spawnSync}from"node:child_process";const required=process.argv.slice(1);const passed=s=>s.split("\n").filter(l=>/^ok \d+ - /.test(l)&&!/# (SKIP|TODO)\b/i.test(l)).map(l=>l.replace(/^ok \d+ - /,"").replace(/ #.*$/,""));const good=s=>required.length>0&&passed(s).length>0&&required.every(n=>passed(s).includes(n));const args=["--test","--test-reporter=tap","test/js/ci_secret_masking.test.mjs"];const opts={encoding:"utf8",timeout:55000,maxBuffer:33554432};const r=spawnSync(process.execPath,args,opts);if(r.error||r.status!==0||!good(r.stdout))throw Error("required executed case family missing or failed");const z=spawnSync(process.execPath,[...args.slice(0,2),"--test-name-pattern=^NO_ROUND3_TEST_CAN_MATCH$",args[2]],opts);if(z.error||z.status!==0||good(z.stdout))throw Error("zero selection control failed");for(const n of required){const omitted=r.stdout.split("\n").filter(l=>!l.startsWith("ok ")||l.replace(/^ok \d+ - /,"").replace(/ #.*$/,"")!==n).join("\n");if(good(omitted))throw Error("missing family control failed");}console.log("required executed families "+required.length+"; zero-selection and omitted-family controls passed");' -- 'round3 guard exact stdout registration' 'round3 guard rejected execution contexts' 'round3 references bracket and github token'
```

## Gap-to-Check Coverage

| GAP2 finding | Planned proof |
|--------------|---------------|
| CR-01 | 19-01 whitespace-run matrix, per-row baseline, copied quadratic control and process deadline |
| CR-02 | 19-01 actual workflow-name inventory; 19-03 armor; main readback 21-03 |
| WR-01 | 19-02 containers, nested/list values, sigils, bitstrings and wrapped tuples |
| WR-02 | 19-02 credential/cookie name-value records and tuple disambiguation |
| WR-03 | 19-03 all named armor body/newline/prefix/missing-END layouts |
| WR-04 | 20-02 diagnostic prose retention or exact accepted-overmask pins |
| WR-05 | 20-01 whole-command stdout registration, suffix/redirection/control-flow/heredoc rejection |
| WR-06 | 20-02 raw unmasked tail-window presence controls and rule-seeded timing |
| IN-01 | 20-03 all named provider/CLI/URL/encoding examples with explicit contexts |
| IN-02 | 20-01 bracket/github.token references and YAML skip; existing GR-06 grammar receiver retained |
| IN-03 | 20-02 independent minimum-of-three per-row baseline, timings and 25 ms advisory alert |
| IN-04 | 20-03 prefixed/uppercase JWT and hyphen-run performance checks |

Prior original review and GR cases remain in the same suite and are explicitly checked in GAP3/main re-verification. The old clean-room findings with colliding WR/IN identifiers retain their Phase197 dispositions; round-qualified references prevent confusion.

## Wave 0 Requirements

No separate dependency/setup wave is needed. Existing infrastructure covers execution. Tests were added red first within each production task; the phase-local delivery helper and its self-tests were created by 21-01 before later modes ran. All nine mapped tasks have retained execution evidence and current main proof. The independent sampling audit found no missing setup or test infrastructure; wave_0_complete is true.

## Required Non-Vacuity and Negative Controls

- At least one actual workflow secret name and one live derived assignment; one fake row per distinct actual secret name/alias and every matching-rule family.
- Every watched seed must be present inside its raw unmasked line-and-byte tail window before masked absence; batch/per-row emission prevents row growth from dropping early seeds.
- Copied/fake controls: identity mask; exported pre-fix masker; removed add-mask in an extracted copy; deliberately quadratic rule; seed outside line window; seed outside byte window; empty inventory/case family.
- Value-free assertion messages and aggregate leak counts; no raw seed, child output, armor body, credential or private absolute path in errors/evidence.
- Child deadlines bound old quadratic behavior; a timeout is red and cannot hang the parent. No tracked production source is mutated in place to create a control.
- Mandatory-family command controls reject zero actual selections and each missing new family while older successful cases remain; tests being absent cannot bypass the command-level check.
- Evidence self-tests reject empty counts, stale CI/review/head, consumed or wrong-scope approval, missing automatic-deletion permission, missing main proof and malformed receipts.
- Landed real mode executes bounded child processes itself; caller-authored green receipts, omitted controls, wrong-main blobs, child failures/timeouts and main changing mid-run fail. Self-tests exercise these through a separate fake adapter that cannot run or satisfy real landed mode and cannot emit a main-proof receipt.
- Landed prechecks tracked cleanliness and noncolliding untracked inventory before detach, rechecks main SHA/source blobs/clean state after execution, and restores the saved docs ref without reset/force/stash or working-tree loss. Its durable count/identity/control fields come only from its current child executions.

## Manual-Only Verifications

None. All behavioral assertions, review evidence, CI checks and main verification are automated. A just-displayed merge decision, and separately automatic remote deletion if enabled, are unavoidable irreversible-action approvals, not manual verification or UAT. New deferrals require an independent scope decision and cannot be silently accepted.

## Validation Sign-Off

- [x] All new tasks' automated commands executed with non-empty case floors.
- [x] Exact mandatory family identities were executed rather than skipped; zero-selection and missing-family command controls passed.
- [x] Red-first and copied negative-control evidence inspected without value leakage.
- [x] Raw-window controls cover line and byte truncation.
- [x] Every matching-rule family has bounded adversaries and independent timing rows.
- [x] Sampling continuity confirmed; no three consecutive tasks without automated feedback.
- [x] No watch-mode flags or dependency installation.
- [x] All three review rounds mapped and current GAP2 twelve findings accounted for.
- [x] Candidate CI head and distinct synthetic merge identity verified.
- [x] Actual merged main passes full checks before REL-03 completion.
- [x] Landed itself produced SHA-bound proof from live processes and rejected fabricated green/no-execution, missing-control, wrong-main and failure/timeout controls.
- [x] Existing GR-06/Phase197 deferrals and historical override preserved.
- [x] Actual audit completed before setting status validated / nyquist_compliant true.

Approval: independent automated coverage audit completed 2026-10-27. REL-03's finite boundary remains explicit: supported-rule/inventory tests cannot prove all arbitrary unlabelled secrets or arbitrary Bash safe. This is no new deferral and does not expand GR-06.

## Post-execution evidence and remaining audit

All9 mapped tasks have executed: plans19/20 summaries retain red-first, exact-family/zero-selection/omission controls, numeric rows and live guard census; plan21 retains the independent35-row review, CI49/49, separately scoped approvals/consumption and actual-main proof on b8398c38. The phase-only helper has98 passing selftests after the reproduced TMPDIR repair. The process-derived main receipt covers190 quick tests,327 full tests,213 timing rows, all required registered identities and five positive control families with zero masked leaks.

The independent audit below supersedes the former draft flags. The compliance fields derive from task mapping, commit-order inspection, substantive assertions, exact-family/empty-selection controls, bound main execution evidence and fresh focused checks; they are not inferred solely from a green suite.

## Independent Sampling and Coverage Audit

Input state A; validate-phase capability enabled. All 21 PLAN/SUMMARY pairs were inspected for requirement/task intent and retained evidence; this round's nine tasks map only REL-03. The other seven Phase195 requirements retain their prior verified status and unchanged controls. No new test or production edit was needed, so validate-phase Step3 proceeds directly to Step6.

| Task | Requirement coverage found | Current evidence | Audit |
|---|---|---|---|
| 195-19-01 | Real failing child, inventory-derived names and bounded padding | Three exact required identities; raw seed presence and masked absence; 60-row size/whitespace matrix in current main proof | COVERED |
| 195-19-02 | Containers, record-local name/value handling and wrapped tuples | Three exact identities; per-row raw windows, multiple seeded elements and malformed-value behavior | COVERED |
| 195-19-03 | Complete/incomplete private-key armor | Exact layout/malformed families, following diagnostics and three bounded armor adversaries | COVERED |
| 195-20-01 | Supported stdout registration and credential references | Exact echo/rejected-context/reference identities; real extracted fire-drill emulator, positive live floor and zero violations | COVERED |
| 195-20-02 | Non-vacuous tail windows, independent baselines and diagnostic pins | Line/size/empty/omitted-family controls, copied quadratic rejection, value assertions and 213 current timing rows | COVERED |
| 195-20-03 | Named provider/CLI/URL/encoding/JWT forms | 45 raw-window and identity controls, 43 pre-fix detections, zero candidate leaks; exact diagnostic and residual-adversary identities | COVERED |
| 195-21-01 | Review, CI and privacy bound to the final head | 35 round-qualified review rows, exact source blobs, CI40449366324 overall success; 48 successful jobs and one skipped release-candidate-full-proof out of49 | COVERED |
| 195-21-02 | Current separate irreversible operation scopes | Current attempt binds base/head/run/synthetic identity; separate merge/deletion answers each consumed once; no previous allow transferred | COVERED |
| 195-21-03 | Actual main proof generated from real processes | Main SHA/two parents/source blobs, current helper/receipt/review digests, quick190/full327, all190 registered identities, five controls and safe docs restoration | COVERED |

### Commit and Feedback Continuity

Git parent/diff inspection verifies the six planned RED→GREEN pairs, in exact order:

| Task | RED commit | GREEN commit | Substantive transition |
|---|---|---|---|
| 19-01 | edb0084c | 37f450f6 | Test-only signing/inventory/padding additions precede production classifier repair |
| 19-02 | 5934c715 | c2030f72 | Test-only container/record/tuple additions precede balanced consumers |
| 19-03 | 2f1ad9eb | b0233b8e | Test-only armor additions precede terminator/EOF scanner |
| 20-01 | 0e0804a6 | 7ee7f994 | Test-local guard failures precede registration/reference repair in the same test module |
| 20-02 | 2c716d15 | c7a0fed6 | Window/diagnostic failures precede synchronous children, real windows and quote repair |
| 20-03 | bb325826 | 8c519bff | Named residual failures precede bounded production rules |

Each GREEN is the immediate child of its RED; each later RED descends from the previous GREEN. The RED diffs add assertions against the existing import/interface, rather than removing a module or intentionally breaking test setup. Recorded failure labels/counts align with those assertions. Old RED commands were not rerun against historical attack inputs; commit inspection and retained red evidence establish sequencing. Current real-main tests establish behavior after delivery.

Review repairs also retain test-first pairs 0c90fc28→a45078fa and29c1abd8→24baafa3. Plan21's evidence tasks each use their executable helper gate; its final successful proof is after the approved merge. No three consecutive tasks lack automated feedback. No new framework, package or watch mode was introduced.

### Fresh Independent Checks

- Existing focused command `node --test --test-name-pattern '^round3 review ' test/js/ci_secret_masking.test.mjs`:9pass,0fail,0skip;1.742s;11numeric interaction rows, maximum28.526ms, each within bound.
- Phase helper `--self-test --ws quality-ratchet-release`:98pass. Its test-only fake adapter cannot satisfy real landed execution or create a main-proof receipt.
- Artifact binding check: proof/main/reviewed/working source blobs equal; current helper, review and delivery SHA256 digests exactly equal proof fields; all213 unique metric rows satisfy their bounds. Main b8398c38 has approved parents7621c0ce and24baafa3.
- Source audit: no disabled requirement tests; expected masking results are handwritten exact pins or independently specified raw-presence/absence/diagnostic assertions. No expected-value regeneration from the masker is used. Controlled fixture input is supplied by real subprocesses and the live workflow path, not substituted for production inventory.
- The main proof is process-derived: quick190pass/full327pass, five non-empty controls, zero masked leaks. It requires every registered masking identity, prior-round identities and current all-round findings. Main execution was not repeated during report edits.
- Manifest regression gate supplied by the parent: Phase194 referenced tests84pass/0fail in this verification session; no repeated full suite.

### Audit Outcome

Gaps found:0. Resolved:0. Escalated:0. Manual-only:0. All nine mapped tasks COVERED. Existing GR-06/Phase196, original clean-room Phase197 debt and the historical HYG-02 exception remain exactly scoped. Lifecycle completion remains the orchestrator's separate transaction.

## Validation Audit 2026-10-27

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
