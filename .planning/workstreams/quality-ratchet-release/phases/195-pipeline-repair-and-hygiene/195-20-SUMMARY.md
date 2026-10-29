---
phase: 195-pipeline-repair-and-hygiene
plan: 20
subsystem: infra
tags: [ci, secret-masking, derived-secrets, performance, gap-closure]
requires:
  - phase: 195-19
    provides: structural masking and bounded failure-tail regression infrastructure
provides:
  - Exact unconditional stdout registration checks with bracket-secret and github.token reference coverage
  - Per-row raw-window proof, independent timing baselines and explicit diagnostic dispositions
  - Named provider, CLI, URL, encoding and JWT protections with copied negative controls
affects: [195-21]
tech-stack:
  added: []
  patterns: [conservative lexical registration fences, monotonic URL scanning, JWT token-run scanning, isolated per-row timing]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-20-SUMMARY.md
    - .planning/workstreams/quality-ratchet-release/phases/195-pipeline-repair-and-hygiene/195-EVIDENCE/mask-round3-plan20-timings.md
  modified: [script/verify_repository.mjs, test/js/ci_secret_masking.test.mjs]
key-decisions:
  - Registration is proven only by a complete supported stdout echo at assignment indentation outside unproved control contexts.
  - Short credentials remain protected; indistinguishable prose and ambiguous Docker short flags have exact accepted-overmask pins with reasons.
  - REL-03 remains pending for plan 21 delivery and fresh actual-main verification.
coverage:
  - deliverable: Exact registration and credential-reference guard
    human_judgment: false
    verification:
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 guard exact stdout registration
        status: pass
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 guard rejected execution contexts
        status: pass
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 references bracket and github token
        status: pass
  - deliverable: Non-vacuous raw windows and independently bounded rule timings
    human_judgment: false
    verification:
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 raw window and inventory controls
        status: pass
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 timing quadratic copied control
        status: pass
  - deliverable: Named residual credential forms and diagnostic pins
    human_judgment: false
    verification:
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 residual named credential forms
        status: pass
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 residual exact diagnostic pins
        status: pass
      - kind: test
        ref: test/js/ci_secret_masking.test.mjs#round3 residual rule adversaries
        status: pass
requirements-completed: []
requirements-pending: [REL-03]
actuals:
  tokens: 14518
  tasks: 3
  commits: 6
  plan_head_before: b0233b8e29f0465dd158ec67732a97145cdf635d
  plan_head_after: 8c519bfff50ef46eb62c58ae140eb68f9b6130b7
commits: 6
plan_head_before: b0233b8e29f0465dd158ec67732a97145cdf635d
plan_head_after: 8c519bfff50ef46eb62c58ae140eb68f9b6130b7
duration: 20m
completed: 2026-10-27
status: complete
---

# Phase 195 Plan 20: Derived-secret proof and named residual masking Summary

**Exact stdout registrations, per-row unmasked-window checks and bounded provider/CLI/URL/JWT scanners close the named GAP2 leak and proof gaps while pinning diagnostic costs.**

## What was checked and what happened

- Continued `fix/secret-mask-structural` from plan 19 head `b0233b8e29f0465dd158ec67732a97145cdf635d`. Final code head is `8c519bfff50ef46eb62c58ae140eb68f9b6130b7`, based on `origin/main` `7621c0ce0c38edec76cc54209eccf5acf40feddf`. Exactly the two owned code/test paths differ from that main base. Six plan-20 commits were measured from the persisted plan base; no push, PR, merge, tag, publish or remote deletion occurred.
- Task 1 red: three required families executed; one passed and two failed for permissive registration and missing credential references. Green checks accept four exact echo forms through stdout emulation and reject 20 unsupported forms, including redirects, suffixes, conditional/function/heredoc contexts and raw command text. Four reference spellings are checked directly and through env aliases. The full-suite TAP gate independently required all three exact successful identities; zero selection and each of three omitted-family reports were rejected while older identities remained.
- The live workflow census found 94 reference-bearing lines, 30 secret-bound aliases counted across files, two derived assignments and zero violations. The real fire-drill derivation hides synthetic source and derived values through `runnerMaskedLog`; removing registrations from a copied extracted script exposes a derived value internally. No network line is extracted or executed. No workflow correction was required.
- Task 2 red: the raw byte-cap assertion and two diagnostic-delimiter assertions failed, 3/3. Green checks use synchronous child writes and per-row child windows, mirror stdout/stderr concatenation and CSI normalization, and enforce line-then-size slicing before checking seed absence. Line-cap, size-cap, removed-mask, empty-inventory and three omitted-group controls all reject. The deliberate byte-cut test first proves its watched fragment is visible unmasked. The historical byte-named limit counts JavaScript string units, matching the production API exactly.
- Task 3 red: both selected named-form and exact-diagnostic tests failed. A complete pre-fix probe classified 45 named forms: 42 leaked and three were already protected. Candidate copied controls show zero leaking rows, the pre-fix copy shows 42, and the identity-mask copy shows all 45. The three prior protections retain exact output pins and fail their identity controls.
- On committed code head `8c519bff`, `node --test test/js/ci_secret_masking.test.mjs` passed **181/181** in 28.687 seconds; `node --test test/js/*.mjs` passed **318/318** in 32.696 seconds. `git diff --check` passed. No CI run is claimed for this unpushed head.
- Every task commit had a successful conditional privacy scan before staging/commit and an immediate successful rescan afterward. Existing untracked privacy evidence remained untouched. Summary and numeric evidence are committed separately on `docs/195-closeout`; orchestration owns STATE/ROADMAP updates and REL-03 stays pending.

## Bounded timing and diagnostic evidence

[The numeric evidence artifact](195-EVIDENCE/mask-round3-plan20-timings.md) retains **all 202 per-row baseline/candidate/bound measurements** and the complete 45-row pre-fix/identity control matrix. It contains labels and numeric results only.

- 60 padding rows cover five families, three whitespace forms and four sizes; 75 additional rows cross five credential heads, five separators and three whitespace forms at 200,000 units.
- 21 retained-rule and 14 residual-rule adversaries each have positive, nonmatching and pathological cases. The 28 older linear inputs, three armor adversaries and one baseline row remain covered. Every family asserts a nonzero floor.
- Each row has a fresh equal-length plain-prose minimum of three timings, candidate fastest of three, a bound of `max(250 ms, 10 × baseline)` and a 2000 ms child deadline. Named groups have 55000 ms budgets. A deliberately quadratic isolated copy is rejected by the child deadline.
- Maximum committed-head candidate time was **61.568 ms**; 18 rows emitted the advisory alert above 25 ms. No row exceeded its bound. This floor discriminates the tested quadratic defects; it does not detect every possible bounded-window constant regression.
- Earlier exact shape expectations remain passing. WR-04 prose is explicitly retained or pinned in `ACCEPTED_OVERMASK`: bearer-required/authentication/scheme errors, minimum/blank changeset messages without apostrophe tearing, invalid-token errors, refresh/use token, cookie/credential prose, numeric/atom/boolean/nil containers, JWT-looking version prose, lone armor marker, `ps` and short-user flags. Basic prose and ambiguous Docker short flags have named conservative pins and rationales. Safe ExUnit titles and Finished-in lines survive.

## Twelve-finding GAP2 coverage matrix

| Finding | Executable coverage and disposition |
|---|---|
| CR-01 | `round3 padding credential whitespace matrix`, `round3 separator head adversaries`, per-row timing and quadratic-copy rejection protect the linear separator path from plan 19. |
| CR-02 | `round3 structural repository signing assignment`, `round3 inventory all workflow secret names` and private-key armor tests retain signing/deploy/camel-case and PGP coverage. |
| WR-01 | `round3 container inspect values`, `round3 tuple wrapped values` and older shape pins cover nested maps/lists, cookies, sigils, bitstrings, wrapped/long tuples and multiword values through per-row raw windows. |
| WR-02 | `round3 name-value record isolation` retains value keys and unrelated records; per-row raw-window checks prevent hidden seed loss. |
| WR-03 | Complete/malformed private-key armor tests and three armor adversaries retain all reviewed layouts; missing/mismatched END consumes EOF with explicit prior overmask rationale. |
| WR-04 | Named prose round-trip and exact accepted-overmask tests enumerate every reviewed prose class; known closers survive numeric/atom masking and changeset apostrophes are not torn. |
| WR-05 | Exact stdout, rejected-context and reference families plus the live fire-drill emulator/control require actual supported unconditional registration before use. |
| WR-06 | `round3 raw window and inventory controls`, rule/separator adversaries, per-row independent baselines and copied quadratic rejection eliminate the three named proof weaknesses. |
| IN-01 | `round3 residual named credential forms` covers all named provider, CLI, identifier, URL, query, full-width/CSI and authorization forms; 45-row copied controls and exact diagnostic pins retain finite coverage. |
| IN-02 | Dot/bracket/github.token references and Authorization expression assignments are recognized; env aliases share detection. The previously accepted broader GR-06 grammar remains with Phase 196. |
| IN-03 | All 202 rows report numeric baselines/candidates/bounds, with an advisory alert above 25 ms; the 250 ms floor's finite discrimination claim is explicit. |
| IN-04 | JWT maximal-token/segment scanning covers hyphen/underscore prefixes and uppercase headers; old hyphen-run/segment-repeat and new prefix-uppercase adversaries pass. |

## Task commits

1. `0e0804a6` — test(195-20): expose unsupported mask registrations and references
2. `7ee7f994` — feat(195-20): require supported stdout mask registration
3. `2c716d15` — test(195-20): expose vacuous tail windows and diagnostic loss
4. `c7a0fed6` — feat(195-20): prove bounded raw windows and independent rule timings
5. `bb325826` — test(195-20): cover named provider cli url and jwt residuals
6. `8c519bff` — feat(195-20): mask reviewed provider cli url and jwt boundaries

## TDD gate compliance

All three tasks have red-before-green commits. Actual TAP reports were classified `RED_EVIDENCE_OK`: task 1 executed 3 tests with 2 intended failures; task 2 executed 3 with 3 intended failures; task 3 executed 2 with 2 intended failures. Semantic inspection confirmed assertion failures in the planned behavior, without load/setup failures. Correcting the scratch evidence record's target-field/schema and working directory did not alter any test output. No optional refactor commit was necessary.

## Deviations from plan

**[Rule 1 - Bug] Per-row isolation exposed malformed-quote leakage.** The complete-value quote reader could close an unterminated quote against a later duplicate stderr record. It now stops an unterminated scalar at the original CR/LF boundary. Existing `unterminated_quote_value` shape and exact-output tests pass through the stricter per-row harness. Included in `c7a0fed6`.

**[Rule 3 - Blocking issue] Child output had to be synchronous.** A failing child using asynchronous console output could exit before a large fake window was fully written. Synchronous writes establish the intended line/size negative controls. Included in `c7a0fed6`.

Execution bookkeeping: the on-disk commit ledger was reconstructed from the first red commit's exact parent before the final task commit. The six-commit count and before/after heads above are measured, not inferred from intended tasks. Actual token cost is the realized two-file diff character count divided by four, rounded up.

## Known stubs and deferred issues

None introduced. The earlier GR-06 Phase 196 grammar receiver and older Phase 197 debt remain unchanged. Declaration/append/read/printf/GITHUB_ENV/output/multiple-assignment/inline-use grammar is not silently promoted into this bounded one/two-level line scanner. No new endpoint, auth path, runtime file-access boundary or schema surface was added.

## Next phase readiness

Last completed phase remains **194**. Phase **195** now has plan **20** complete and plan **21** pending; REL-03 remains pending until approved delivery and fresh actual-main proof. Continue the workstream command `$gsd-execute-phase 195 --gaps-only --ws quality-ratchet-release` at plan 21 without repeating 01–20. This executor did not start plan 21.

The flagged assumption remains finite: these tests prove the supported credential identifiers/shapes, live inventory and named review cases. They cannot prove arbitrary unlabelled secrets or arbitrary Bash programs safe. No universal credential-safety claim is made.

## Performance

- First task commit: 2026-10-27T03:34:09Z.
- Completed evidence: 2026-10-27T03:53:42Z.
- Three tasks; two code files; six task commits; one separate docs closeout commit.
- Runtime configuration resolved an unavailable claude-sonnet-5-5; the inherited available executor model and paired high effort were used as directed by the orchestrator.

## Self-check: PASSED

- Both created documentation files exist and the numeric artifact has exactly 202 timing rows and 45 named-form control rows.
- All six task commits are ancestors of `fix/secret-mask-structural`; the measured code diff contains exactly the two owned paths and no deletions.
- Committed-head results are 181/181 and 318/318, with zero live workflow violations and the intended copied-control failures.
- REL-03 remains pending; STATE/ROADMAP are left to the parent orchestrator.
