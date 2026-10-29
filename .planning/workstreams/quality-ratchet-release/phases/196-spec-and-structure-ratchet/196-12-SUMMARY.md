---
phase: 196-spec-and-structure-ratchet
plan: "12"
subsystem: testing
tags: [workflow, masking, bash, grammar, actual-main, privacy]
requires:
  - phase: 196-01
    provides: Fixed actual-main grammar capsule and restoration protocol
  - phase: 196-11
    provides: Completed preceding sequential slice
provides:
  - Same-owner conserved credential-statement census before scalar filtering
  - Seven denied grammar families with synthetic shell execution controls
  - Final matching actual-main and candidate census receipts
affects: [196-15, 196-17, SPEC-02, GR-06]
tech-stack:
  added: []
  patterns: [bounded-run-local-classification, stdout-registration-before-use, closed-census-findings]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-grammar.json
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/grammar-census.json
  modified:
    - test/js/ci_secret_masking.test.mjs
key-decisions:
  - Keep the classifier in the existing masking-test owner and scope env aliases and derivations to each run body.
  - Deny credential persistence to GITHUB_ENV and GITHUB_OUTPUT as a Crosswake convention, including grouped writes and already-masked values.
  - Preserve bounded one-level derived aliases; unsupported relevant shell or YAML syntax is counted as unknown.
requirements-completed: []
requirements-addressed: [SPEC-02, GR-06]
actuals:
  tokens: 11493
  tasks: 2
  commits: 8
commits: 8
plan_head_before: d10fc2dac5aa14e9f0ed72f53fe7f9d463527ffd
plan_head_after: 2a937529d9dc4aedf2558f31e30d77470f9d00c2
coverage:
  - id: conserved-grammar
    description: Nonempty real workflow census conserves supported, denied and unknown candidates
    verification:
      - kind: integration
        ref: node --test test/js/ci_secret_masking.test.mjs
        status: pass
    human_judgment: false
  - id: actual-main-grammar
    description: Final committed grammar owner measured on fetched main with exact restoration
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard grammar --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-grammar.json
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 12: Conserved workflow credential grammar Summary

**The live workflow census accounts for 13 supported credential-connected statements across 28 workflows, with zero denied or unknown statements, backed by 207 passing masking tests and final-blob actual-main measurement.**

## Accomplishments

The existing Node owner now discovers block, folded and inline run bodies before filtering supported assignments. Secret-bound env mappings follow workflow/job/step ownership, including an env mapping at the start of a step; derived state stays local to each run. Canonical plain/export scalar assignments require the existing exact unconditional stdout mask before use. One level of derived aliases remains intentional: an authenticated result derived from a depth-two value is not automatically a new secret. Mixed-depth sources select the source that still requires derivation tracking. Ordinary nonsecret metadata writes and explicit nonsecret overwrites remain valid.

Declaration, append, read, printf-v, multiple/inline assignment, assignment-line use and credential-connected GITHUB_ENV/GITHUB_OUTPUT persistence are rejected before scalar filtering. Denied destinations remain tracked for subsequent persistence checks. Grouped persistence is also rejected. This is a local convention, not a GitHub platform prohibition. Unsupported relevant syntax, including unsupported YAML mappings/aliases or scalar continuations, contributes an unknown candidate instead of disappearing. Comments and unrelated metadata are outside the credential candidate set.

Standalone `--phase196-census-root <subject-root>` suppresses unrelated test registration while preserving normal imports and test behavior. Its report has the existing exact PHASE196_REPORT schema. Findings contain only file, category and count; no raw RHS, credential value or alias name is retained. The live test requires a nonempty workflow/reference/candidate inventory, candidate conservation and zero denied/unknown findings, and preserves the earlier derived-assignment and env-alias floors.

No workflow required normalization. GR-06 was preventive grammar debt; this work does not claim a reproduced current workflow leak or arbitrary Bash/secret completeness.

## Task commits

| Task | Commit | Result |
| --- | --- | --- |
| 196-12-01 RED | `a1aa931f` | Credential-connected local declaration failed its intended assertion |
| 196-12-01 GREEN | `9bd6ef17` | Same-owner classifier and standalone report mode |
| 196-12-01 measurement | `fa44b2c4` | Actual-main capture before replacing live census |
| 196-12-02 RED | `ba90144f` | Grouped persistence failed its intended assertion |
| 196-12-02 GREEN | `8b88fbf5` | Seven executed families, scalar/YAML, registration and census controls |
| 196-12-02 boundaries | `0fc6df8a` | Scoped env aliases, mixed-depth source handling and all YAML variants |
| 196-12-02 promotion | `83132b29` | Measured conserved census replaces live enforcement |
| 196-12-02 final receipts | `2a937529` | Final matching main/candidate owner identities and census |

Each commit ran its explicit absolute per-file privacy conditional and immediate postcommit rescan. No tracked file was deleted; no generated untracked output remains. Eight commits are measured from the persisted plan ledger before summary and lifecycle metadata commits.

## Verification

| Command | Result |
| --- | --- |
| `node --test --test-name-pattern='phase196 GR-06' test/js/ci_secret_masking.test.mjs` | 17/17 pass; all named GR-06 checks executed |
| `node --test --test-name-pattern='phase196 GR-06\|derivedSecret\|derived chains\|round3 guard\|round3 references\|round3 review persistent\|live workflow tree\|live fire-drill\|derivationScript' test/js/ci_secret_masking.test.mjs` | 33/33 passed before the additional supported-reference test; no skipped tests |
| `node --test test/js/ci_secret_masking.test.mjs` | 207/207 pass; zero failures/skips/cancellations; 20,721.771083 ms |
| `node test/js/ci_secret_masking.test.mjs --phase196-census-root .` | Exit 0; one report line, 28 workflows, 97 reference-bearing lines, 13 candidates = 13 supported + 0 denied + 0 unknown |
| `node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/measure-main.mjs capture --guard grammar --candidate HEAD --output .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/main-grammar.json` | Four sequential captures passed; final exit 0, same census, final capture 4,011 ms |
| `node --check test/js/ci_secret_masking.test.mjs` | Exit 0 |
| `git diff --check d10fc2da HEAD -- test/js/ci_secret_masking.test.mjs` | Exit 0 |

Seven named families (`decl_keyword`, `append_assign`, `read_into`, `printf_v`, `github_env_output`, `multi_assign`, `assign_and_use`) each discriminate across block/folded/inline YAML, giving 21 classification variants. Seven real synthetic Bash controls derive a value and prove skipped registration cannot be inferred. Supported execution controls comprise 12 plain/export × quoted/unquoted × YAML cases, their 12 mask-removed controls, four credential-reference spellings after modeled Actions substitution and their four mask-removed controls. Eight additional shell controls cover wrong quotes, stderr, redirection, conditional/skipped registration, late masks and removed masks. One true conditional is runtime-safe but remains rejected by the unconditional-registration convention. Three standalone subprocesses and six mutated census checks verify nonempty inventory, conservation, rejection and value-free diagnostics. Existing Phase195 supported mask forms, performance cases, workflow-name inventory, fire-drill execution and negative controls remain green.

## Actual-main identity and restoration

Final subject: fetched `origin/main` at `b8398c38e7d92c8bb99dcbc87fdb2370a47e6e97`. Final capsule candidate: `83132b299af01b1b8887c1a3dd109abddcfea7a1`. The owner blob is `e0891db68e92ef58b81c842b1460d622fcc84f04`, SHA-256 `cbd0b96674af82191515343aa0bf92d089912c9b0789d0cbaa55368f04a4d191`, matching the current candidate census. The capsule imported actual main's verify_repository blob `b9a8bba556037d7e78138649e517975e0c823565` without changing it. All 28 subject hashes matched main objects before and after execution.

The final capture restored `fix/spec-structure-ratchet` at its saved candidate head, with the exact index hash, all 6,168 tracked-file hashes and the empty untracked inventory unchanged. Both candidate-wide privacy scans passed on 171 changed files. Earlier report logic was captured before live promotion; subsequent owner changes were recaptured. No worktree, concurrent mutable suite, network credential, external delivery, publish, tag or approval transfer occurred.

## TDD evidence

Both RED targets executed and failed on the planned behavioral assertion, with no load/setup/fixture failure, and each received `RED_EVIDENCE_OK` from `check tdd-red-evidence` before implementation. The first observed zero declaration violations; the second observed grouped persistence classified as supported use. Their unchanged native TAP records stay locally excluded because Node includes private runner paths. SHA-256 values: `534edcc668815cb978a3aab583095713483b9b61e6de0ca443ab1430578f8d8a` and `f36de9b1ea804d5c9ab1a84ecb30dae39a97af3ab81c6631f5998cc3b5f4085f`.

The first RED report was created at 2026-10-27T16:57:12.001Z. The measured execution window ended at 2026-10-27T17:12:10.817Z; initial context loading and later metadata closeout are outside that 15-minute window. Actual tokens are ceil(45,969 diff characters / 4) over the three realized code/evidence paths, excluding summary/lifecycle text.

## Deviations from plan

None. Grouped persistence, alias ownership and mixed-depth corrections stayed within the planned credential-persistence and run-local-alias contract. A fixture correction inserted a blank boundary after `set -eu` for supported folded YAML; without it, YAML correctly folds that setup into the next shell command. No failure was waived. Temporary parser-development assertions were rerun after corrections; all final checks passed.

## Known limits and next action

No stubs, skipped tests, unrun planned verification or new production security surface were found. No authentication gate occurred. Unsupported relevant syntax fails closed under the bounded convention; this is not a general shell parser or cross-step dataflow engine.

Plan12's two tasks are complete. All eight Phase196 requirements and final GR-06 closure remain pending independent phase verification. Last completed phase remains195. Active phase196 is12/17 plans complete; the next eligible command is `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at196-13-PLAN.md. Do not repeat plans01-12. Full pilot, recurring-guard promotion and exact-head delivery remain later plans; original Phase197 clean-room debt and the parked adopter lane are unchanged.

## Self-Check: PASSED

All three task artifacts exist; all eight task/evidence commits are ancestors of HEAD. Both receipts match the final owner hash, process exits and conserved census. No source changed after the full207-test passing run.
