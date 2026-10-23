# API Coverage — Phase 175 Release Evidence

> Full coverage by default for this phase's release-gate integration surface. Every capability
> outside the bounded release job is an explicit opt-out.

| capability | decision | reason |
|---|---|---|
| GitHub PR identity, state, base/head, readiness, and merge result | INTEGRATE | Binds authorization and post-merge evidence to exact remote objects. |
| GitHub commit/ref identity and ancestry | INTEGRATE | Proves the incident runbook is an ancestor of exact base, approved head, and actual merge. |
| GitHub root release-manifest bytes at the verified immutable PR head | INTEGRATE | Plan134 adds one fixed contents GET behind a distinct v3 card; retain version and head/tree/blob provenance. Legacy scopes and mutation gates stay unchanged. |
| GitHub CI/check-suite and required-check results for exact head | INTEGRATE | Confirms current head evidence; missing or failed checks block authorization. |
| GitHub workflow definition bytes at an immutable PR head | INTEGRATE | Checks aggregate behavior against the exact workflow revision; persist only its digest and bounded parser facts, never the raw response. |
| GitHub effective branch/ruleset and required-check policy | INTEGRATE | Policy is mutable and must be re-fetched at authorization and before side effects. |
| GitHub legacy tag-protection endpoint (`/tags/protection`) | OPT-OUT | Sunset by GitHub and returns no usable tag-protection policy; repository rulesets remain the supported policy source. |
| Actions: dispatch candidate rehearsals; read exact runs/artifacts | INTEGRATE | Supplies candidate-bound leg run IDs, raw retained evidence, and non-mutating rehearsal results. |
| GitHub: merge the exact approved pull request through the normal protected path | INTEGRATE | This existing one-way boundary is required for the planned successor; REL-17 checks it and rejects admin bypass. |
| GitHub: administrative merge/bypass, force-update, or override required checks | OPT-OUT | Contradicts REL-17's protected-path/no-bypass condition and the repository's fail-closed policy. |
| Git: create exact iOS mirror version tag | INTEGRATE | Plan83 permits one create-only `v0.2.6` push after a separate digest/object/ref-bound decision. Dry-run grants no authority; force updates and admin overrides remain OPT-OUT. |
| Plan143: GET `/repos/szTheory/crosswake/pulls/219` | INTEGRATE | Recheck the exact candidate state, base and head before the proposed ref operation. |
| Plan143: exact source commit GET | INTEGRATE | GET `/repos/szTheory/crosswake/commits/696a27a3be1fcd56efe70923dc0ce286a1c41c6d` rechecks pinned head/tree. |
| Plan143: exact-head manifest GET | INTEGRATE | GET `/repos/szTheory/crosswake/contents/.release-please-manifest.json?ref={validated PR219 head}` rechecks version 0.2.7. |
| Plan143: GET `/repos/szTheory/crosswake-shell-core-ios` | INTEGRATE | Recheck exact mirror identity and repository permission metadata. |
| Plan143: GET `/user` | INTEGRATE | Bind the authenticated permission check to the same credential used for preview and push; retain no login. |
| Plan143: mirror collaborator permission GET | INTEGRATE | GET `/repos/szTheory/crosswake-shell-core-ios/collaborators/{login from /user}/permission` rechecks push access without retaining the principal. |
| Plan143: mirror ruleset list GET | INTEGRATE | GET `/repos/szTheory/crosswake-shell-core-ios/rulesets?includes_parents=true&per_page=100&page={1..4}` reads bounded current policy pages. |
| Plan143: mirror ruleset detail GET | INTEGRATE | GET `/repos/szTheory/crosswake-shell-core-ios/rulesets/{returned numeric id}` completes the create-only policy digest. |
| Plan143: exact source Git reads and split | INTEGRATE | `ls-remote` source `refs/tags/ios-core-v0.2.6` and peeled ref; exact clone/fetch/subtree split recomputes pinned object and tree. |
| Plan143: exact mirror Git ref reads | INTEGRATE | `ls-remote` mirror `main`, prior `v0.2.5`, target `v0.2.6` and peeled tags before write; exact three-ref readback afterward. |
| Plan143: one exact-ref no-write Git preview | INTEGRATE | `git push --dry-run --porcelain` of `424ab96ede1b92f2b751b54bce04c6e607f0f3c8:refs/tags/v0.2.6`; require one non-force, non-delete row. |
| Plan143: one exact create-only remote Git push | INTEGRATE | Push `424ab96ede1b92f2b751b54bce04c6e607f0f3c8:refs/tags/v0.2.6` once after fresh card-specific ALLOW, rechecks and synced intent. |
| Plan143: unrelated PR/check/Actions/CI operations | OPT-OUT | The exact tag repair establishes only mirror parity; candidate CI evaluation needs a separate reviewed plan. |
| Plan143: PR merge, branch/ruleset changes and administrative bypass | OPT-OUT | Merge policy is unknown and this operation confers no Gate 2 or protected-path authority. |
| Plan143: recovery, Hex/Maven/registry actions and publication | OPT-OUT | REL-13/14/15/17 and release hold stay open after every tag result. |
| Plan143: generic GitHub POST/PATCH/PUT/DELETE writes and other repository refs | OPT-OUT | The fixed adapter permits only the one exact remote-Git create-only tag operation. |
| Plan143: tag move, overwrite, force push or delete | OPT-OUT | The approved ref is absent-before-write and immutable for this attempt; changing or removing it is outside the one-use decision. |
| GitHub unrelated APIs (issues, projects, users, org/admin, etc.) | OPT-OUT | These capabilities do not serve release evidence or the adopter's route/runtime contract; broader scopes add access and maintenance without phase value. |
| GitHub: write repository files or change rulesets from the release gate | OPT-OUT | Gate evaluation is read-only; source changes use normal reviewed pull requests and policy is never weakened to make a release pass. |
| Hex: read package and release state | INTEGRATE | Captures raw response, checked nonempty parse, exact package/version state, and matching evidence row. |
| Hex: publish successor or companion after authorization | INTEGRATE | Required phase outcome; the side effect remains behind REL-17 and its separate one-way authorization. |
| Hex: retire-forward recovery | INTEGRATE | Required by the existing incident-response contract; separately gated and does not claim deletion. |
| Hex ownership, account, billing, or metadata admin | OPT-OUT | Not required to authorize or verify the bounded release operations. |
| Maven: upload, validate, and drop isolated rehearsal deployment | INTEGRATE | Exercises real signed upload to the last safe state without crossing permanent publication. |
| Maven: publish successor through protected workflow | INTEGRATE | Required phase outcome after REL-17 and a fresh one-way authorization. |
| Maven: read public coordinate/POM state | INTEGRATE | Independently confirms public state; a missing public POM is not proof of Central Portal state. |
| Maven: delete, overwrite, or claim rollback of published coordinate | OPT-OUT | Published Maven coordinates are permanent; the interface must not imply reversal. |
| Maven account, namespace, or unrelated repository admin | OPT-OUT | Outside the release gate and not needed for Crosswake's single bounded release path. |

## Plan135 observed boundary — 2026-10-10

The fresh v3 card's one-use ALLOW was consumed by one production read. Both prescribed terminal audits passed; result SHA-256 `bfd109757f08e7fda44e106b17b62b963aba3bb3b75b0be9d7810b2aacba463c` establishes version `0.2.7` from PR219's verified immutable head/tree/manifest blob and a complete `CREATE_ONLY_ALLOWED` policy snapshot. Counts were 8 GitHub GETs, 16 Git operations, 1 helper check and 2 permission checks, with zero dry-run/tag/CI. The fixed anonymous root-manifest route remained distinct from authenticated identity/permission/policy routes. Prior evidence stayed unchanged.

These dated observations support bounded follow-up planning; they do not satisfy Plan106's Plan119-pinned ready preflight, immediate effective permission/policy rechecks, exact one-ref dry-run or separate tag decision. Plan106 and Plans46–48/89 remain HELD; REL-13/14/15/17 OPEN; readiness BLOCKED; effective write permission UNKNOWN; tag authority NONE; merge policy UNKNOWN; release hold ACTIVE. Last completed phase 174; Phase175 remains incomplete. No capability or support promotion follows this observation, and no approval transfers to another action.

## Boundary

This matrix describes the exact GitHub, Hex, and Maven Central capabilities used by the Phase 175
release graph. It does not turn Crosswake into a general GitHub, Hex, or Maven API client. Candidate
IDs, credentials, registry bodies, and run logs remain outside user-facing status output; retain
only the evidence required by REL-17 in the approved artifact channel. No action is authorized by
this coverage decision.

## Plan136 local preflight contract — completed 2026-10-10

The existing INTEGRATE rows already cover the root release manifest, authenticated GitHub policy/permission and exact mirror-tag preflight; no API opt-out changes. Plan136/Wave39 completed a distinct versioned same-run preflight contract inside that surface, proven by synthetic injected Mix/Elixir/Node tests only (36 required Node cases; 16 required ExUnit cases; 158 Node and 55 ExUnit full-suite tests). Exact-head manifest provenance and complete effective policy/permission join one same-credential exact-ref dry-run in the synthetic receipt. No real scope/card/attempt or external operation occurred, no synthetic result satisfies Plan106’s Plan119-pinned predicate, and no tag/release authority follows. All five sealed Plan135 files and legacy scope semantics remain immutable; future live preflight and tag action retain separate reviewed plans and fresh choices.

## Plan143 scoped tag-operation decision — planned 2026-10-10

The Plan143-prefixed rows above are the exact capability decision for one new Plan142-mode attempt. They preserve the phase's earlier release-graph decisions while explicitly opting out of those broader capabilities for this operation. The Plan140 policy and permission are dated observations; the Plan142 adapter must refresh them with the same credential after a fresh card-specific allow and immediately before its one possible create-only push. This matrix authorizes no card, attempt, read or write during planning. Even verified mirror parity cannot advance CI, Gate 2, merge, recovery, registry, publication or release readiness.
