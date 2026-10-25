# Phase 177: Maintenance and Queue Reconciliation - Discussion Log

> **Audit trail only.** Downstream agents use `177-CONTEXT.md`; this log preserves alternatives, research and limits.

**Date:** 2026-10-12
**Workstream:** quality-ratchet-release
**Areas discussed:** old release commands; open PRs/issues; active maintenance instructions.

The user selected all areas, explicitly requested subagent fan-out through applicable domain/role lenses and an adversarial pass, and delegated automatic adoption of a coherent recommendation set. No further preference questionnaire was needed. Three typed `gsd-advisor-researcher` agents ran in parallel; the queue researcher then challenged the combined recommendations. Research remained read-only. The scope did not select release publication or GitHub mutations.

## Old release commands

| Option | Pros | Cons | Surface and risk | Selected |
|---|---|---|---|---|
| Evidence-backed retirement of spent behaviors, preserving supported generic commands/readers | Reduces reachable spent authority; keeps useful operator jobs | Needs per-mode caller and replacement proof | Mix routers, scripts/workflows, generated/package exposure and tests; missed dynamic caller risk | Yes, conditional on actual evidence |
| Narrow blocked tombstone | Gives a supported stale caller one correction | Leaves a callable command and maintenance burden | Old task and denial proof; accidental delegation/bypass risk | Only for an evidenced supported transition need |
| Lossless read redirect | Preserves a genuinely equivalent read job | Can silently change semantics/authority | Selector/parser mapping; spent authority transfer risk | Read-only, non-consuming equivalence only |
| Bulk removal of numbered helpers | Low apparent code count | Confuses filenames/age with obsolescence; may destroy inspectors/guards | Broad source/test deletion | Rejected |

Examples: `release.status` is publicly linked; `release.candidate` has runbook/workflow callers; `receipt`/`gate` have generic contracts. `candidate_read` and `mirror_tag_026` mix historical inspectors with fixed-attempt launch/decision/apply modes. No specific removal is proven by this discussion.

Mix derives task names from modules and can invoke tasks dynamically; hiding documentation is distinct from disabling a task. Use module/mode and real caller checks. [Mix.Task](https://mix.hexdocs.pm/Mix.Task.html) and [Mix help](https://mix.hexdocs.pm/Mix.Tasks.Help.html).

Strict OptionParser parsing exposes invalid switches and positional leftovers; callers must enforce both along with identity uniqueness. [OptionParser](https://elixir.hexdocs.pm/OptionParser.html).

Hex's configured package file set establishes exposure, not a promise that every included helper is supported. Inspect materialized package contents if relevant. [Hex publishing](https://hex.pm/docs/publish).

Cargo's public-API removal guidance and Go's explicit source-compatibility boundary support classifying support before removal. Their compatibility policies do not require retaining spent release writers. [Cargo SemVer guide](https://doc.rust-lang.org/cargo/reference/semver.html), [Go compatibility](https://go.dev/doc/go1compat).

## Open PRs and issues

| Option | Pros | Cons | Surface and risk | Selected |
|---|---|---|---|---|
| Complete dated local inventory and recommended next actions | Meets MAINT-05; preserves queue and authority boundaries | Queue remains visibly open; dated observations can drift | One phase-local evidence/rendering pair and paginated reads | Yes |
| Selective remote comments/labels/closures | Could reduce ambiguity/queue clutter | Needs separately scoped authority; may alter release automation | Per-item remote mutations and fresh checks | Deferred |
| Bulk close old/bot-generated objects | Fast apparent cleanup | Can erase unique debt/security tracking and disturb bot lifecycle | Broad remote writes | Rejected |

**Observed:** 2026-10-12 12:49:20–12:49:25 UTC. Separate GraphQL `issues(states: OPEN, first: 100)` and `pullRequests(states: OPEN, first: 100)` connections returned 20 and 3 objects, with counts and `hasNextPage: false`. Fields were metadata such as number/update time, PR state/labels and check rollup; no bodies/comments/logs were retrieved. PR check-context connections each reported 49 objects and complete pagination.

Open PRs were #210, #211 and #236. #210/#211 each had 9 failed and 40 successful check contexts; #236 had 1 failed, 14 successful and 34 cancelled contexts. All were behind. Mergeability does not override failed checks or behind status. Check results do not establish causes without diagnosis.

Open issues were #24, #108, #116, #119, #126, #156, #159, #162, #166, #194, #199, #205, #209, #213, #217, #220, #223, #226, #231 and #234. The research identified historical validation debt and run-specific failure categories; it did not establish per-issue resolution/ownership. Execution must refresh and map every object to its concrete action. The roster is research context, not completed MAINT-05 evidence.

GitHub cursor pagination uses `endCursor`/`hasNextPage` and page sizes up to 100; the observation is still not an atomic transaction. [GitHub GraphQL pagination](https://docs.github.com/en/graphql/guides/using-pagination-in-the-graphql-api).

Release Please maintains proposals/lifecycle labels and merging a release PR creates release state; closing/reopening can change its label handling. Keep #236 held for separately selected release work. Do not modify labels or force-run automation during queue reconciliation. [Release Please README](https://github.com/googleapis/release-please/blob/main/README.md), [troubleshooting](https://github.com/googleapis/release-please/blob/main/docs/troubleshooting.md).

GitHub distinguishes resolving/closing an issue from closing a PR without merging; neither proves that an old/bot item is resolved. [Closing an issue](https://docs.github.com/en/issues/tracking-your-work-with-issues/administering-issues/closing-an-issue), [closing a PR](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/closing-a-pull-request).

## Active maintenance instructions

| Option | Pros | Cons | Surface and risk | Selected |
|---|---|---|---|---|
| Bounded repairs at existing active owners | Preserves task separation and source ownership; low review cost | Must catch all active conflicting pointers | PROJECT/handoffs/affected runbooks/renderings/tests | Yes |
| New consolidated entry guide | Could improve navigation if a real gap exists | Duplicates navigation and creates another drift source | New guide, links and ongoing maintenance | Deferred unless a navigation failure is demonstrated |
| Rewrite/rename active and historical release records together | Apparent simplification | Erases history, breaks links and confuses pre-flight/recovery | Broad document/workflow edits | Rejected |

Concrete defects: STATE/ROADMAP record Phase176 complete and discussion177 next; workstream `.continue-here.md` still points to Phase176. PROJECT's next/active milestone statements still describe new scope as unselected. Correct active pointers without replacing archive meaning.

Existing `crosswake.docs.sync` owns capability/support guide rendering. Existing pre-release and incident documents serve different operator moments. Their separation remains useful; changes must preserve runbook ancestry/integrity checks.

Mix/Phoenix task docs establish the existing discovery pattern; maintenance needs no runtime Plug/Ecto abstraction. [Phoenix Mix tasks](https://phoenix.hexdocs.pm/1.7.7/mix_tasks.html), [Mix.Task](https://mix.hexdocs.pm/Mix.Task.html). Django's documented deprecation/replacement practice informs supported stale-caller transitions; its exact schedule is not adopted. [Django deprecation policy](https://docs.djangoproject.com/en/5.2/internals/release-process/#deprecation-policy).

## Lenses and diminishing returns

| Lens/JTBD | Relevant conclusion |
|---|---|
| Solo maintainer: understand leftovers and act | Complete accounting, precise unknowns, one current next action; no prompt per routine check |
| Library consumer: run supported commands | Preserve support contracts; prove real task/parser/caller behavior |
| Contributor: locate current guidance | Repair existing navigation and command docs; clearly mark historical provenance |
| Release operator/SRE: diagnose safely | Separate pre-flight/recovery, current source/remote facts and consumed authority |
| Security reviewer | Fail before credential/network/write side effects; retain durable guards and unique findings |
| Privacy reviewer | Metadata-only queue research, allowlisted necessary evidence, private recovery bytes/pointers |
| Software architect | Behavioral ownership and small surfaces; no generic cleanup or authority framework |
| Elixir ecosystem maintainer | Mix/stdlib/generated owners; no unnecessary Plug/Ecto/runtime/dependency layer |
| CI/proof maintainer | Targeted meaningful regression coverage; Phase178 owns matching final-source CI |
| Documentation/accessibility | Purpose-led plain text, observable outcomes and actionable corrections without color/hash-copy dependence |
| Product/adopter | Preserve frozen scope and parked gates; no mobile support promotion from maintenance |

The prompt catalogue was reviewed for relevance. OSS DNA, synthesis, GSD brief, walkthrough DNA and the two core library/refinement research prompts inform ownership/DX/tooling. Integration/companion and application/offline stress-test prompts reinforce frozen host/runtime/privacy boundaries; they do not add active product work. The generic `new elixir oss lib prompt.txt` informs breadth/depth and smaller dependencies. `brandbook/BRAND-SPEC.md` supersedes `prompts/crosswake-brand-book.md`. Graphic design, animation and new UI components are inapplicable to this CLI/docs maintenance phase.

The adversarial pass added explicit protection for historical readers, support-vs-package classification, enduring guard tests, local read side effects, no-forced-deletion outcomes, queue object/relationship counting and nontransactional drift. It also confirmed that a tombstone must not delegate old write authority and that the current handoff must remain singular. No further material decision emerged; additional fan-out would repeat these gates rather than change recommendations.

## Agent discretion and deferred work

The user delegated recommendation selection and bounded technical details. Exact files meeting retirement gates remain implementation-research decisions, not speculative removal claims. No GitHub state or source/index/branch/worktree state was changed by research.

Remote queue operations, dependency upgrades/merges, new releases, new dependencies/runbooks/bots/standing CI, archive retirement, product/native/Android breadth and adopter promotion remain outside scope. Phase178 owns final exact-source verification/CI. Discussion artifact validation does not establish any maintenance requirement complete.
