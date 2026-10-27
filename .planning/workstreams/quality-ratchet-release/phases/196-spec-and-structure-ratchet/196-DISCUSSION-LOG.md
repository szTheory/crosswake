# Phase 196: Spec and structure ratchet - Discussion Log

> Audit trail only. Planning, research and execution consume `196-CONTEXT.md`, not this log.

**Date:** 2026-10-27
**Phase:** 196-spec-and-structure-ratchet
**Areas considered:** non-vacuous evidence, vector execution, delta scanner, privacy, exhaustive policy, compile structure, exception boundaries, dependency surface, mutation pilot, GR-06.

## Discussion authority and research

The user invoked `$gsd-discuss-phase 196 --ws quality-ratchet-release`, then explicitly requested all relevant decision points be considered through relevant stakeholder roles, alternatives and an adversarial pass, with coherent recommendations followed automatically. They prefer another small copy over a new dependency, while allowing dependencies when justified. This superseded interactive selection for these decisions; no unanswered questionnaire was defaulted silently. It did not request planning/execution chaining or approve an irreversible operation.

Three read-only `gsd-advisor-researcher` agents researched independent areas: `spec_decisions`, `architecture_decisions`, and `mutation_and_debt`. Each reached a terminal result before synthesis. No agent edited product code. Roles applied where relevant: privacy/security, policy/API correctness, Elixir/Mix architecture, Swift/Kotlin parity, CI operations, diagnostic UX and solo-maintainer cost. No product UI redesign was relevant.

Prior scope and dependency choices were carried forward from v28 scope, requirements, roadmap and recent contexts. No matching pending todos, existing Phase 196 context/spec/plans, blocking phase handoff or codebase map was found. Actual source and tests supplied the scout fallback. `discuss:pre` reported no active hooks. GSD reported that legacy `gsd_profile`/`auto_apply_prefs` config keys are ignored; this discussion used the user's explicit instructions rather than treating them as effective runtime settings.

## Optional manifest evidence — D-04

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Visible opt-in exclusion; enabled proof asserts real prerequisites | Preserves ordinary tests and existing generated-manifest lane; absence is not a pass | Lane wiring must distinguish not requested from supplied-but-invalid | Yes |
| Require external manifests in every ordinary test run | Strong unconditional prerequisite | Makes unrelated local/root runs depend on optional artifact generation | |
| Keep conditional no-op or synthetic success artifact | Cheap | Repeats the exact vacuity defect and misstates proof | Rejected |

**Delegated recommendation:** preserve visible optionality; fail missing/malformed inputs once proof is enabled. Existing committed-manifest checks remain.

## Vector cardinality — D-05/06

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Independent loaded and executed pins per actual consumer | Detects deletion and all-excluded execution | Intentional corpus changes require expectation review | Yes |
| Pin loaded count only | Simple | Platform filters can execute zero cases while green | |
| Derive expected count from the discovered collection | No pin maintenance | Tautological; a missing file shrinks both sides | Rejected |

**Scout evidence:** requests 15 loaded, 9 Elixir/14 native executed, replies 2. Reconfirm before implementation. A scout correction matters: navigation topology has five JSON entries, but the inspected Swift test selects one by ID; transition tests build inline cases. Do not claim those tests loop over both JSON corpora. The actual-consumer inventory determines scope; Phase 198 retains vector hashes/parity ledger ownership.

## Delta-only absence scanner — D-07..09

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| AST findings versus reviewed legacy-unsafe multiset | Deterministic locally/CI, independent of shallow Git refs; deleted guard becomes a new finding | Limited lexical analysis and explicit baseline upkeep | Yes |
| AST findings versus explicit base/head | Avoids grandfather file | Ref availability/comparison semantics add operational surface | |
| Added-line regex or exemption for every existing assertion | Cheap initial implementation | Misses deleted guards, reintroduced defects and duplication | Rejected |

**Delegated recommendation:** baseline only remaining unsafe findings, keyed by semantic context and multiplicity. Fix named sites in the same change. Match the guarded collection/branch; legitimate expected-empty results remain valid. Existing inventory's blanket treatment of attributes and `[]` as non-empty is a demonstrated heuristic defect, not reusable proof. Negative controls target guard removal without assertion-line changes, branch mismatch, wrong collection and duplicated exemptions.

## Privacy boundaries — D-10/11

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Explicit boundary and adversarial field/projection matrices | Auditable, deterministic, no dependency | Finite corpus must cover distinct contracts deliberately | Yes |
| Add a bounded seeded loop when a distinct gap appears | More diversity with a reproducible seed | No shrinking; random volume can obscure missing assertions | Conditional supplement |
| Add property-testing dependency immediately | Generator/shrinker facilities | No current evidence that the small explicit matrix is inadequate | Deferred |

**Observed defect:** a direct constructor/projection probe accepted a syntactically valid route ID followed by LF and preserved LF in telemetry. Journal's absolute anchors reject the analogous scope input. Correct the demonstrated observation boundary; test all projections that accept forged structs as well as construction. Scope lengths refer to suffix bytes after `v1.`, not the prefix-inclusive length. Never print synthetic payload values as evidence.

**Primary source:** [Erlang regex anchor semantics](https://www.erlang.org/doc/apps/stdlib/re.html).

## Exhaustive policy and diagnostic provenance — D-12/13

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Hand-written factored verdict tables over all 108 cases | Independent oracle with a reviewable size | Factoring must not copy production validators | Yes |
| Literal independent map with 108 entries | Very explicit each-case verdict | More repetitive review surface | |
| Derive expected verdicts from compiler/validator output | Easy generation | Correlated implementation mistakes are blessed as expected | Rejected |

**Delegated recommendation:** assert 108 unique executions and exact error pairs. Use structured option keys; split grouped unknown keys into per-key errors without silently changing atom-key contract. Preserve `{:id, nil}` for missing identity. Reproduce mixed-invalid source attribution before correcting it: compressed indices/zip are a code-level risk, not a claimed executed failure in this discussion. Controls corrupt both verdict and key/route provenance.

**Primary source:** [NimbleOptions validation error contract](https://nimble-options.hexdocs.pm/NimbleOptions.ValidationError.html); installed 1.1.1 source confirms unknown-option keys can be a list despite its narrower local typespec. Merely replacing message parsing with `error.key` would be incomplete normalization.

## Compile-cycle repair and guard — D-14/15

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Tiny protocol-version leaf, preserve existing API delegation | Removes the denial-family coupling with one canonical version | Adds a small internal module | Yes |
| Lazy runtime call to `Contract.version/0` | Smallest edit, removes compile capture | Leaves the four-file runtime/export SCC; weaker structural outcome | |
| Relocate denial structs or build custom graph tooling | Could impose broader layering | Disproportionate contract/migration and maintenance surface | Rejected |

**Measured scout:** pinned Elixir 1.19.5, one compile-connected SCC and four total SCCs, not the original report's three. `--label compile` already detects the original mixed SCC on this tool; an early concern that it necessarily missed mixed edges was corrected by running the real command. `--only-direct` is the dangerous narrowing. Built-in `--fail-above 0` exits nonzero correctly. Fresh compilation and actual repaired graph measurements remain required; scout `--no-compile` output is not that gate. Test real mixed-cycle output and missing compilation evidence, without inventing parser fixtures.

**Primary source:** [Pinned Mix xref implementation](https://github.com/elixir-lang/elixir/blob/v1.19.5/lib/mix/lib/mix/tasks/xref.ex).

## Rescue semantics — D-16/17

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Explicit diagnostic results; two precise semantic extension-boundary exceptions | Preserves authoring diagnostics and fail-closed arbitrary-host containment | Exceptions need exact reviewed identities and stale-record checks | Yes |
| Narrow every rescue to familiar exception classes | Appears cleaner | Unknown custom host exceptions can escape the intended containment boundary | |
| Rename `_` to `error`, or exempt compatibility directory | Small diff | Leaves broad swallowing invisible to a spelling-only guard | Rejected |

**Scout:** bridge's three sites are location hints; compatibility has two additional broad rescues around extension callbacks. Preserve existing denials/telemetry and catch behavior. Guard named roots and descendants, reject renamed broad rescues elsewhere, and test arbitrary custom exceptions with no auth success or raw exception leakage. No broad legacy allowance.

## Direct dependency inventory — D-18/19

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Evaluated production declarations, six Mix projects | Matches original architecture proposal; captures optional/runtime flags and declaration branches | Sequential isolated contexts and exact project roster required | Yes |
| Lockfile/resolved transitive tree | Easy existing file/tool output | Includes irrelevant development/transitive changes; misses declared optional surface | |
| New multi-ecosystem dependency abstraction | Wider eventual reach | Expands this phase beyond the original Mix ratchet and duplicates native work | Deferred |

**Delegated recommendation:** compare names/classification and nonblank justifications, not version strings; local/release branches both covered without fetches. Include optional deps and package membership. Native maintainer owns Android JSON choice in Phase 198 and toolchain dependency review in v29; do not claim native ratchet coverage here.

**Primary source:** [Mix dependency options](https://hexdocs.pm/mix/Mix.Tasks.Deps.html).

## Muex isolation, validity and decision protocol — D-20..24

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Pinned isolated archive, real-output wrapper and controls | No committed dependency; bounded experiment on hardened tests | Integration, invalid mutants and hidden filtering must be measured | Yes |
| Pinned standalone escript | Same dependency boundary | Additional build provenance and target-loading checks | Observed-cause fallback |
| Commit Muex now or build a bespoke mutation engine | Convenient future execution/control | Premature dependency or maintenance commitment | Rejected |

**Delegated recommendation:** exact five files; no filtering/optimization/sampling; one worker; fresh versioned JSON. Real schema uses `summary.total`, not `mutations_generated`. Validate record/count consistency, target membership, statuses and actual useful outcomes for every target. Zero/absent reports, no tests, invalid-only or all-timeout outcomes cannot be green evidence. Timeout and compile errors are not behavioral kills.

The prospective 30-minute aggregate wall limit and 20% invalid/uncovered non-equivalent limit are chosen maintainer appetite, not primary-source best practice. Known-kill and known-survive controls establish discrimination independently of a score. Classify survivors using stable semantic keys. Adopt means later local advisory eligibility only; no result is declared now. Incomplete coverage remains pending or follows the roadmap cut rule, even when tooling is dropped. No automatic rerun to green, recurring lane, committed dependency or new harness follows.

**Primary sources:** [Muex 0.12.0 configuration](https://github.com/Oeditus/muex/blob/v0.12.0/lib/muex/config.ex), [reporter](https://github.com/Oeditus/muex/blob/v0.12.0/lib/muex/reporter/json.ex), [installation](https://github.com/Oeditus/muex/blob/v0.12.0/docs/INSTALLATION.md). Current package verification found stable 0.12.0 dated 2026-10-21; tagged source overrides inconsistent unversioned guidance.

## GR-06 grammar closure — D-25..27

| Option | Benefit | Cost / failure mode | Selected |
|---|---|---|---|
| Bounded canonical grammar; deny unsupported credential-connected forms | Makes seven missing families visible with no dependency; protects current convention | Some valid Bash is intentionally disallowed near secrets | Yes |
| General Bash parser plus taint/dataflow system | Better syntactic coverage | Parsing does not prove execution, taint or stdout authority; dynamic forms remain difficult | Deferred absent measured need |
| Raise a single live-tree non-empty floor | Tiny change | One supported assignment hides every unsupported family | Rejected |

**Delegated recommendation:** account for supported/denied/unknown credential-connected candidates, fail live denied/unknown, and inject each formerly invisible family. Preserve nonsecret metadata writes. Secret-connected GITHUB_ENV/OUTPUT persistence is prohibited as local policy; GitHub itself allows masked same-job outputs. Do not present a policy choice as a platform rule. Execute synthetic expansion/mask-order controls. The prior seven zero counts support preventive closure, not a current-leak claim, and never establish general grammar completeness.

**Primary sources:** [GitHub workflow commands](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands), [Bash manual](https://www.gnu.org/software/bash/manual/bash.html).

## Adversarial synthesis and stopping point

The useful counterexamples changed the decisions: loaded-only vector pins became execution pins; added-line scans became unsafe-finding comparisons; arbitrary attributes stopped counting as non-empty; constructor-only privacy tests gained projection checks; structured keys gained grouped-key normalization; version laziness lost to a true leaf; rescue spelling checks gained semantic exceptions; a generic mutation score became a validated per-target result with controls; and unsupported secret-connected syntax gained explicit denials. Further speculative breadth would not change these choices and would cross the milestone boundary.

Actual pilot results, repaired graph baseline, full scanner census and confirmed mixed-batch attribution remain research/implementation work. No code fix, CI-green claim or full-module pilot result is asserted here.

## Agent discretion and later receivers

Minimal helper placement, focused test grouping and PR/wave packaging remain planner choices. Context names owners, triggers and receivers for recurring mutation/property tests, broad Bash analysis and native dependency work. Existing Phase 197 clean-room debt remains there. All one-use irreversible gates remain in force. The existing docs closeout branch retains this local planning continuation; a later PR/CI delivery remains required before landing, with the two pre-existing untracked privacy receipts preserved.
