# v25 upstream research brief

Status: research in progress; v25 requirements and roadmap remain proposals. The active quality workstream remains between milestones after Phase 178. This research does not authorize implementation, publication, PR merge or adopter promotion.

## User direction

The user accepted bounded iOS host setup work, requested a digital-twin demonstration through diminishing returns, then explicitly requested subagent research before finalizing: enumerate relevant decisions, compare approaches with examples, examine Elixir/Plug/Ecto/Phoenix idioms and successful cross-language precedents, and synthesize one coherent recommendation emphasizing developer experience.

This selects research first and supersedes the earlier proposal to skip milestone-level research. It does not change persistent research preferences.

## Goal and governing constraints

Prove one supported generation path and one bounded reference offline-study flow. Reuse existing Phoenix/browser/iOS reference infrastructure. Preserve route-local ownership, backend auth authority, scope-partitioned replay, payload privacy, installed-media integrity and explicit denials. No generic mobile framework, new first-party WebView runtime, generic sync/storage, Android breadth, new companions, product polish or dashboard.

Reference twins and simulator results remain reference/runtime evidence. Real adopter input and source-bound signed physical evidence retain their independent gates. A blocked automatable check does not count as completion. The user wants a useful demonstration, not another product or an endless proof program.

Current approved GitHub main observed read-only: `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. Local recovery HEAD and working files are different; production assertions must name the source they inspected. PR #238 remains a separately delivered maintenance proposal with a consumed delivery binding.

## Decision inventory

| Decisions to resolve | Primary research owner | Relevant lenses |
|---|---|---|
| 1. Host configuration authority and precedence | GENERATION | Phoenix/Mix conventions, least surprise, lifecycle |
| 2. CLI flags versus config declarations versus project settings | GENERATION | Caller API, portability, backcompat |
| 3. Provisioning/signing facts and private storage | GENERATION | Apple, security, onboarding |
| 4. Simulator/hermetic versus device-target build modes | GENERATION | Apple, CI, claim honesty |
| 5. Regeneration, file ownership, overwrite and drift behavior | GENERATION | Installer DX, maintainability |
| 6. Route table and host-origin manifest/activation derivation | GENERATION | Phoenix route contracts, auth authority |
| 7. Placeholder-origin denial and host configuration validation | GENERATION | Security, error ergonomics |
| 8. Public contract/version/upgrade impact | GENERATION | OSS compatibility, documentation |
| 9. Twin topology and minimum reuse | TWIN-ARCHITECTURE | Architecture, cost, scope |
| 10. Visible WebView and bridge identity | TWIN-ARCHITECTURE | Native integration, least surprise |
| 11. Browser-only versus integrated shell observations | TWIN-ARCHITECTURE | Fidelity, runtime ownership |
| 12. Pack verification, atomic install and actual offline audio | TWIN-ARCHITECTURE | Media, privacy, lifecycle |
| 13. Local mutation and kill/relaunch persistence | TWIN-ARCHITECTURE | Storage, product reliability |
| 14. Backend replay, duplicates and empty outbox | TWIN-ARCHITECTURE | Ecto, domain authority |
| 15. Account fences, rejection/conflict and flags | TWIN-ARCHITECTURE | Security, recovery UX |
| 16. Finite fault/scenario roster and model limits | TWIN-ARCHITECTURE | Risk-based testing, diminishing returns |
| 17. Observation provenance and independent producers | PROOF-OPERATIONS | Test honesty, architecture |
| 18. Evidence/report reuse and physical-report rejection | PROOF-OPERATIONS | Compatibility, claim safety |
| 19. Missing/failed/unavailable checks and complete scope | PROOF-OPERATIONS | Non-vacuity, SRE |
| 20. Privacy-safe results and private failure logs | PROOF-OPERATIONS | Security, diagnosis |
| 21. Run/process/network/DB ownership and cleanup | PROOF-OPERATIONS | Isolation, operability |
| 22. Ecto sandbox versus isolated application database | PROOF-OPERATIONS | Phoenix E2E idioms, concurrency |
| 23. CI promotion, timeouts, retries and dependency failures | PROOF-OPERATIONS | DevOps, maintainability |
| 24. Exact stop criteria versus incomplete blocked work | PROOF-OPERATIONS | Resource stewardship, planning truth |
| 25. Maintainer JTBD across initial setup/regeneration/failure | DX | Consumer API, onboarding |
| 26. End-user offline/queued/conflict/disabled affordances | DX | Product UX, psychology |
| 27. Accessibility, focus, touch, light/dark/system, motion | DX | Inclusive design, native/web conventions |
| 28. Documentation and output information hierarchy | DX | Developer ergonomics, support |
| 29. Brand applicability and implementation-detail exposure | DX | Creative direction, consumer language |
| 30. Cohesion, dependencies and no-repeat implementation | Integration challenge | Architecture, delivery economics |

## Prompt lineage and precedence

Apply AGENTS.md and the first-adopter ADR ahead of older roadmap/expansion proposals. Apply `brandbook/BRAND-SPEC.md` and canonical semantic tokens ahead of the superseded `prompts/crosswake-brand-book.md`. Older prompts supply architectural lessons and alternatives, not authority to reopen stopped breadth.

Generation research covers OSS DNA, project brief, original/refined OSS library research and architecture/code-walkthrough DNA. Twin research covers runtime architecture and both offline stress-test documents. Proof research covers synthesis, companion ownership and the v22–v24 operational lessons. DX research covers app-type design research, the generic original prompt, current brand specification and maintainer job flows. All prompt files are accounted for in the synthesis's applicability inventory.

## Fan-out and convergence rule

Three independent specialists research generation, twin architecture and proof operations. A second wave covers DX and challenges cross-report conflicts. No automatic nested agent spawning. Additional work is limited to a concrete unresolved decision that could materially change scope, API, trust or verification. Stop when one focused challenge pass yields no new material contradiction; implementation-only unknowns become named experiments with their own pass/fail conditions.

Each report provides current source evidence, primary documentation links, competing designs with worked examples, pros/cons/tradeoffs, a recommendation, footguns, deferred breadth and proposed requirement changes. The final synthesis owns one selected path and a compact roadmap; it does not send a menu of unresolved choices back to the user.

## Preservation

Research writes are confined to `.planning/research/v25/` and private proposal previews. All 1,677 protected historical files retain their bytes and paths. Recovery source/index/HEAD/branch/worktrees remain unchanged; no staging, commits, tags, archive moves or external writes. The original v24 requirements and active routing remain untouched until the revised milestone roadmap reaches its scope gate.
