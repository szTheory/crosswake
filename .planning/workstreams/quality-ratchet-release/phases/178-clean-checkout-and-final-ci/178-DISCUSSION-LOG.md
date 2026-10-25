# Phase 178: Clean Checkout and Final CI - Discussion Log

> Audit trail only. Downstream planning/research/execution consumes 178-CONTEXT.md, not this log.

**Date:** 2026-10-12
**Workstream:** quality-ratchet-release
**Areas discussed:** Final source delivery and preservation; complete local verification; hosted CI source identity; failures and maintainer handoff.

## Discussion handling

The user invoked discussion for Phase178. Their earlier generic direction asked to consider all relevant decision points with subagents, synthesize coherent recommendations and automatically follow them. That standing direction was applied to bounded discussion judgment. No new explicit user answer or remote-operation approval is fabricated. All four areas were selected by delegation.

Three typed gsd-advisor-researcher agents researched the first three areas using role-resolved gpt-6-luna/high settings. Follow-up adversarial checks refined each result until no further material decision remained. The parent synthesized authority, privacy, maintainer/JTBD and handoff consequences. No source/Git/build or remote write was performed. The runtime is @opengsd/gsd-core 1.16.0; unknown gsd_profile/auto_apply_prefs config keys were reported by the runtime, and no configuration was changed. No --auto/--chain flag or automatic plan/execute chain was introduced.

The phase directory initially contained no CONTEXT, SPEC, plans, checkpoint or phase-local blocking handoff. The matching-todo query returned zero. No codebase maps or packaged spike/sketch findings were available; the existing source facade, Mix aliases and CI owners supplied the scout. discuss:pre had no active hooks.

## Final source delivery and preservation

| Option | Pros | Cons | Complexity | Recommendation |
|---|---|---|---|---|
| Fresh independent candidate clone, verified six-file transfer, fresh exact-commit proof checkout | Isolates recovery; makes complete source selection and ignored residue visible; gives reproducible commit/tree binding | Needs explicit candidate construction and later runner identity reconciliation | Independent clones plus existing bundle replay; no dependency; risk is omitted bytes or wrong base | Selected for the six completed maintenance edits |
| Reuse existing dirty Phase177 clone for final proof | Already holds scoped edits and prior focused checks | Dirty tracked state and ignored build/dependency caches cannot establish clean proof | Existing preparation surface; contamination and false-source risk | Use for review/transfer preparation only |
| Verify unchanged attested base | Useful baseline and diagnostic comparison | Omits completed maintenance output unless separately dispositioned; old CI does not cover the candidate | Existing commit; false completion risk | Diagnostic only |
| Shared worktree as independent proof | Cheap shared objects | Shares repository refs/data and conflicts with protected checkout restrictions | Worktree lifecycle and shared Git authority | Not selected |

**Delegated selection:** Carry all six files using the existing exact private patch-bundle handoff, preserve 119 capture rows/two unresolved historical readers, then verify a fresh clean committed source. Git bundle is not a synonym for a private patch bundle. A new base requires explicit bounded reconciliation. A local candidate commit in a qualified separate clone is reversible execution preparation; it transfers no authority to mutate recovery Git or publish remotely.

**Lenses:** maintainer reviews one bounded diff; architect keeps source ownership explicit; security excludes private archives; QA gets exact provenance; operations avoids source/cache coupling. Current source/locks/tested behavior outrank historical safe-to-merge text.

**Primary constraints:** [Git status](https://git-scm.com/docs/git-status), [Git worktree](https://git-scm.com/docs/git-worktree), existing Phase177 binding/replay evidence and governing AGENTS.md.

## Complete local verification

| Option | Pros | Cons | Complexity | Recommendation |
|---|---|---|---|---|
| Existing script/verify_repository.sh --all on a fully prepared clean exact checkout | One complete nine-stage contract; existing preflight, artifacts and cleanliness guards | Requires all manifest tools and package/browser prerequisites; costs more than focused diagnosis | Nine existing stages; no new runner; source/residue/log retention risks | Selected MAINT-07 gate |
| Existing --stage runs | Fast targeted failure isolation; reuses existing owners | Cannot establish the requirement's complete-command run; aggregation can hide omitted stages | Existing per-stage interface | Diagnosis only |
| New wrapper/CI reconciliation system or waived stages | No demonstrated recurring benefit | Adds authority/dependencies or produces misleading green | New maintenance surface and false-proof risk | Outside selected scope |

**Delegated selection:** Full --all is required; missing or skipped stages remain blocked. Honor actual manifest versions, resolve exact locked dependencies, reuse existing Phoenix/Ecto/Playwright isolation, retain private logs outside source, and inspect HEAD/tree/index/status/ignored-policy outputs before and after. Generated-contract drift is not reset away.

**Adversarial corrections:** The first advisor table allowed stage aggregation; MAINT-07's complete-command criterion rejects that as completion. Manifest pins are not uniformly minimum versions: Node26 fails the exact Node22.14.0 rule. Default facade run roots are deleted, so explicit private retention is necessary. Porcelain status omits ignored files/HEAD; existing owned-output directories are not automatically cleaned. Copying Phase177 caches risks repeating the lazy_html lock mismatch.

**Lenses:** QA retains the full corpus; Elixir/Phoenix maintainers keep Mix/test environment ownership; SRE receives actionable safe causes; security keeps raw logs private; solo-maintainer DX preserves one public command. Existing Android hermetic checks prove their existing contracts without reopening Android features/device work.

**Primary constraints:** [Mix deps.get --check-locked](https://hexdocs.pm/mix/Mix.Tasks.Deps.Get.html), [npm ci](https://docs.npmjs.com/cli/commands/npm-ci/), [Git status](https://git-scm.com/docs/git-status), and exact source manifests/facade.

## Hosted CI source identity

| Option | Pros | Cons | Complexity | Recommendation |
|---|---|---|---|---|
| Existing PR graph, with observed checkout provenance and local --all on the exact tested merge candidate | Reuses classifier, control, 46 proof leaves and umbrella; no merge/release needed | PR head, suite association and actual checkout SHA can differ; immutable tested object must be retained/retrievable | Existing workflow plus phase-local metadata/provenance join | Selected if the observed commit and required graph can be bound |
| Direct-commit event/new CI workflow | Could test another final commit directly | No demonstrated need; changes event/context/authority contracts and adds surface | Workflow and guard changes | Deferred unless an actual scoped defect proves necessary |
| Head/suite SHA, nearby green run, badge, or equal source tree alone | Easy metadata to find | Does not establish the runner-tested commit and required proof set | False MAINT-08 completion risk | Rejected as sufficient evidence |

**Delegated selection:** The exact synthetic merge commit may be an unmerged final reviewed candidate. Record actual checkout per job, event/head/base/run/attempt, existing required context/app policy and complete leaf outcomes. Head-specific release-candidate-full-proof remains a separate declared contract. Only manifest/classifier-authorized skips are acceptable; no missing, failed, neutral, cancelled or stale proof may pass.

**Adversarial corrections:** Initial research incorrectly required eventual merged-main identity. The scope selects no merge; exact unmerged tested candidate proof is sufficient. Another initial assertion equated check_suite.head_sha with runner HEAD; this is false. Workflow/run/check metadata corroborates checkout evidence rather than replacing it.

A complete parent catalog read of repos/szTheory/crosswake/actions/workflows?per_page=100 exhausted one page, total/count 38, and confirmed active Crosswake CI ID353403178 at .github/workflows/crosswake-ci.yml. The researcher retracted their earlier absence claim: they had inspected only the default first page.

The researcher then examined historical [run 38152560619](https://github.com/szTheory/crosswake/actions/runs/38152560619), attempt1, suite103367724467. Run/suite/check associations named head commit 7273e6cfccf6d62feed9b893eded0bd1028223d1; most observed checkouts named merge commit 1086f4fe02e019a341bfe4487684648b5fe1c729, while release-candidate-full-proof checked out the head. The trees matched, but the commit identities differed. Logs were parsed in memory; raw logs were not retained in this discussion or copied into artifacts. Only these allowlisted source/run observations are recorded. This is a historical counterexample, not CI proof for the six-file candidate.

**Lenses:** release engineering preserves exact attempt/source; security checks policy and app authority; QA validates full expected job population; DevOps reuses the existing dynamic graph; maintainer avoids false green or an unnecessary new workflow. Current mutable merge refs cannot substitute for historical observed checkout evidence.

**Primary constraints:** [GitHub PR workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows), [check suite API](https://docs.github.com/en/rest/checks/suites), [workflow runs API](https://docs.github.com/en/rest/actions/workflow-runs), [required checks](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks).

## Failures and maintainer handoff

| Option | Description | Selected |
|---|---|---|
| Complete reversible preparation and checks, then present one concrete scoped remote proposal if authority is missing | User reviews actual source/base/head/diff and operation; routine reads and repairs continue without repetitive permission prompts | Yes |
| Blanket authorization or inherited Phase175 release approval | Expands authority beyond maintenance and consumed attempts | No |
| Treat partial checks as final proof | Hides failed prerequisites/source drift and weakens MAINT-07/08 | No |

**Delegated selection:** Preserve history/privacy, keep MAINT-07/08 pending until exact evidence passes, fix only demonstrated bounded defects, renew proof after source changes, and report command/source/result/cause/next action plainly. Require no human UAT for automatable claims. Discussion completion advances only to planning.

**Applicable project research:** OSS DNA supports honest public contracts, named verification and minimal dependencies. Architecture synthesis/code-walkthrough prompts support source/proof ownership and preservation. The first-adopter ADR overrides old breadth proposals. Ratified brandbook/BRAND-SPEC.md supplies calm precise voice; no visual system work is needed.

## Agent discretion and deferred ideas

The agent may select bounded evidence filenames, safe existing setup paths, phase-local stdlib joins and scheduling. No new dependency, public API, Plug/Ecto/Phoenix abstraction, product UI, dashboard or permanent reconciliation CI is selected.

Remote maintenance delivery requires concrete operation binding and an authority check at execution; release selection/merge/publication, archive retirement, milestone archival, unrelated queue lifecycle changes, Android breadth and adopter promotion remain separate.

## Artifact and handoff outcome

178-CONTEXT.md is the canonical planning input; checkpoint records were written after each completed area and removed after context/log capture. STATE/ROADMAP are to agree on Phase178 ready for planning and the exact plan command. MAINT-07/08 remain pending. Phase176/177 and v23 history remain frozen. Root Git/source and independent preparation-source changes are outside this discussion.

The generic workflow's commit steps are omitted because the user's phase-specific protected-checkout restriction prohibits staging/commits here. This changes artifact delivery, not discussion completeness. No new permission question is needed to save authorized planning files.
