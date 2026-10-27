---
phase: 196-spec-and-structure-ratchet
plan: "01"
subsystem: testing
tags: [git, node, source-identity, privacy, measurement]
requires:
  - phase: 195-pipeline-repair-and-hygiene
    provides: Landed source and per-file privacy scanner
provides:
  - Preserved planning and receipts on the feature branch from actual main
  - Fixed guard capsules with independently checked main inputs and verified restoration
  - Thirty-one executed source and capture controls
affects: [196-06, 196-09, 196-10, 196-11, 196-12, 196-15]
tech-stack:
  added: []
  patterns: [committed-tool-capsules, actual-main-subjects, closed-proof-records]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/execution-source.json
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/measurement-controls.json
  modified: []
key-decisions:
  - Pin preparation at the immutable transfer commit; verify subsequent committed work against its own HEAD.
  - Retain structured findings and process exits while hashing arbitrary child output.
requirements-completed: []
requirements-addressed: [SPEC-01, SPEC-02, ARCH-01, ARCH-02, ARCH-03]
actuals:
  tokens: 67769
  tasks: 2
  commits: 5
commits: 5
plan_head_before: b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97
plan_head_after: 6b549da0180e4aa1ab40fde1aa1de208a07952ff
coverage:
  - id: source
    description: Preserved planning and actual-main source identity
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs verify-source
        status: pass
    human_judgment: false
  - id: capture
    description: Real git fixture and child-process capture/refusal/restoration controls
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs self-test
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 01: Preserve planning and establish actual-main measurement Summary

**Planning and both Phase195 receipts are preserved; a fixed-capsule measurement helper proves source identity, rejects failed evidence, and restores its checkout in executed controls.**

## Execution and source identity

Source preparation started at 2026-10-27T14:09:45Z; acceptance completed at 2026-10-27T14:26:49Z. One main checkout was used. Initial HEAD was `230690946bdd4fd8d375f7d3d7eff16f65965f87`. Fetch confirmed actual `origin/main` at `b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97`.

The original docs ref remains `docs/195-closeout` at `101e853a0fafdcec4675afceb8fcf6c48db98762`. The two previously untracked privacy receipts were committed there first. All 52 nonmerge preservation commits were inspected as planning-only, applied with scoped no-commit cherry-picks, and consolidated on `fix/spec-structure-ratchet` at `784fe638afbe93bb1bd5ba80110fd03fa31fc589`. The transferred planning tree matched the preserved ref; supported code matched main.

`execution-source.json` records exact refs, 94 preserved records, 25 protected planning/receipt hashes, tool versions, and a nonempty roster of 1,359 supported files. Verification independently reads refs, ancestry, Git objects, tracked changes and file bytes. Preparation is checked at the immutable transfer commit; later committed changes are checked against their own HEAD rather than rejected for differing from the preparation baseline.

## Task commits

| Task | Commit | Result |
| --- | --- | --- |
| Preservation on docs ref | `101e853a` | Both original privacy receipts retained; scanner clean 2 files before and after |
| 196-01-01 preparation | `784fe638` | Scoped planning transfer; scanner clean 94 files before and after |
| 196-01-01 RED | `f5c946e7` | Wrong-main identity assertion fails against the initial verifier |
| 196-01-01 GREEN | `8b613331` | Independent source verification and source receipt |
| 196-01-02 RED | `4ab48b3d` | Wrong fetched-source assertion fails against initial capture |
| 196-01-02 GREEN | `6b549da0` | Fixed capsules, report validation, restoration, 31 controls |

Every scoped commit used absolute per-file arguments in a successful privacy conditional and was rescanned immediately. No push, PR, merge, tag, publish, remote deletion or worktree was performed. No tracked file was deleted. The measured five feature-branch commits exclude the separate docs-ref preservation commit and later closeout metadata.

## Verification

Let `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`.

| Command | Current result |
| --- | --- |
| `node "$P/scripts/measure-main.mjs" prepare --transfer 784fe638 --original 23069094` | Exit 0; source receipt generated |
| `node "$P/scripts/measure-main.mjs" verify-source` | Exit 0; `measure-main: verified source 1359` |
| `node "$P/scripts/measure-main.mjs" self-test` | Exit 0; `measure-main: controls passed 31`; 13,451 ms |
| `node --check "$P/scripts/measure-main.mjs"` | Exit 0 |
| `git diff --check` | Exit 0 |

The final controls comprise ten source tests and 21 capture tests. Disposable real Git repositories execute detach/restore, compare actual-main bytes against different candidate bytes, preserve index and untracked inventories, and recapture an existing output. Controls refuse wrong SHA, empty inventory, wrong coverage/counts, uncommitted or mismatched candidates, nonzero operational failure, child signal, timeout, changed capsule, arbitrary success fields, unknown findings, missing findings for exit 1, active-suite classification, failed restoration and an existing exclusive lock. A real helper process receives SIGTERM only after its guard starts; it restores the saved branch and emits no accepted receipt. Publication-privacy refusal preserves the preceding receipt. Arbitrary stdout/stderr canaries appear only as hashes in accepted receipts.

Report-mode exit 1 with validated findings is retained as exit 1; it is not relabeled green. Operational failures never certify measurements. Independent filesystem discovery must equal main's matching Git-object inventory, with subject and capsule hashes checked before and after. Detached-run output stays in tool scratch until branch, HEAD, index, tracked bytes and untracked bytes are restored. Test adapters are prohibited on the owning repository.

## Producer contract for subsequent plans

`capture --guard absence|compile|rescue|dependencies|grammar --candidate HEAD --output <phase-evidence.json>` requires a clean committed candidate, fresh fetched main ancestry, a privacy-clean candidate, a single checkout, no detected mutable suite and an exclusive capture lock. Fixed file/dependency lists and report-mode argv are declared in `CAPSULES`. Grammar copies the candidate owner and main's original `verify_repository.mjs` into the matching tool-only import layout, invoking `--phase196-census-root <actual-main>`.

Each producer must emit exactly one `PHASE196_REPORT ` line containing JSON with exactly `schema_version`, `guard`, `scanned_files`, `counts`, and `findings`. Schema version is 1; `scanned_files` must equal the independently discovered subject roster; `counts.files` must equal its nonzero size. Findings have exactly `file`, `category`, `count`; count is positive and the file belongs to that roster. The helper's `COUNT_KEYS` and `FINDING_KEYS` enumerate permitted labels. Other output is hashed. Tool or protocol changes require fresh controls and recapture of the exact candidate guard blob before required wiring. No production guard measurement is claimed by these synthetic fixture controls.

## TDD evidence

Both intentional RED runs failed the named assertion, not loading or fixture setup; the installed `check tdd-red-evidence` classified each `RED_EVIDENCE_OK` before implementation. Their unchanged native TAP reports remain in locally excluded `196-EVIDENCE/tdd-source-red.json` and `tdd-capture-red.json`; Node emits private absolute runner paths, so they were not committed. Report SHA-256 values are respectively `717f6419cd2b9f7a7581a4c9b9661fa6135998de1d6bea8e661807d929d74ed8` and `0610c7400cc949d288443f4f4b2e19225306604061aa105a5a55a5929b688476`. GREEN controls and commands are retained in the public measurement-controls receipt.

## Deviations and issues

- [Rule 2 - Privacy] Raw TDD reports were locally excluded rather than publishing runner paths. The committed evidence contains only commands, counts and hashes; no sensitive payload is retained.
- [Rule 3 - Environment] The sandbox initially denied writes to `.git/FETCH_HEAD`; authorized Git mutations succeeded with filesystem escalation. The first failed fetch changed no source state.
- [Rule 1 - Tooling] Final lock controls caught macOS lexical/canonical temp-path aliases. Canonicalizing the existing lock parent fixed the refusal; all 31 controls then passed. No failed run emitted accepted evidence.
- The plan commit ledger was initialized after transfer, then corrected to the independently recorded feature-branch base so its measured count includes the transfer. Actual tokens are `ceil(271074/4)` over the realized diff of the three newly authored helper/evidence files; already-authored transferred planning is excluded from that token measure.

No known stubs, skipped tests or unrun plan acceptance commands remain. All eight Phase196 requirements and GR-06 remain pending; plan01 supplies their preparation machinery, not their final acceptance. No device, emulator, adopter, native-capability, full pilot, repaired-baseline or CI result is claimed.

## Next plan

Last completed phase remains 195. Phase196 is executing, 1/17 plans complete. Next eligible plan is `196-02-PLAN.md`; exact resume command is `$gsd-execute-phase 196 --ws quality-ratchet-release`. Do not repeat plan01 or completed Phase195 work. No irreversible operation has an approval from this plan.

## Self-Check: PASSED

All three declared artifacts exist, the controls receipt matches the final helper hash, and all five feature-branch commits are ancestors of HEAD. The separate docs preservation commit remains reachable from its unchanged preserved ref. Both current plan acceptance commands passed after the final implementation change.
