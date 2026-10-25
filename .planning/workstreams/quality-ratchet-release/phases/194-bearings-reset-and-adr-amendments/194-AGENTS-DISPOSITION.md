# 194-AGENTS-DISPOSITION

Disposition of every bullet or numbered item of `AGENTS.md` as on `origin/main` (after PR1, 54 items, B-01 to B-54) against the trimmed `AGENTS.md` of plan 194-05. No rule was deleted to reach a number: the file could not reach 90 lines without deleting a rule, so the measured cap 102 is recorded in ROADMAP Phase 194 SC1 and REQUIREMENTS PLAN-02 (decision D-13). Deletions are only the superseded v21/v22 pointers and the quality-lane discuss/plan lines whose receivers are ROLLING and the workstream STATE.

| id | main line | section | bullet start (first 60 chars) | disposition | destination or reason |
|---|---|---|---|---|---|
| B-01 | 7 | ## Project Context | 1. `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing infras | kept (reordered) | new item 3 in Project Context |
| B-02 | 9 | ## Project Context | 2. `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — RAG-f | kept (one line, read when resuming) | new item 6 in Project Context |
| B-03 | 11 | ## Project Context | 3. `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — fir | kept (one line, read when resuming) | new item 6 in Project Context |
| B-04 | 13 | ## Project Context | 4. `.planning/PROJECT.md` — project thesis, constraints, h | kept | new item 4 in Project Context |
| B-05 | 14 | ## Project Context | 5. `.planning/workstreams/quality-ratchet-release/REQUIREMEN | deleted because superseded by the active workstream line | new item 5 names the active workstream STATE and ROADMAP, resolved with --ws |
| B-06 | 16 | ## Project Context | 6. `.planning/workstreams/quality-ratchet-release/ROADMAP.md | deleted because superseded by the active workstream line | new item 5 names the active workstream STATE and ROADMAP, resolved with --ws |
| B-07 | 18 | ## Project Context | 7. `.planning/workstreams/quality-ratchet-release/STATE.md`  | deleted because superseded by the active workstream line | new item 5 names the active workstream STATE and ROADMAP, resolved with --ws |
| B-08 | 19 | ## Project Context | 8. `.planning/workstreams/first-b2c-adopter-readiness/STATE. | deleted because the v21 position pointer is superseded; its resume rule moved to .planning/ROADMAP-ROLLING.md#parked | PARKED row First B2C Adopter readiness carries the blocker and the --ws resume |
| B-09 | 29 | ## Current Priority | 1. explicit first-adopter route ownership; | kept (compressed) | Current Priority paragraph, item (1) |
| B-10 | 30 | ## Current Priority | 2. host-reusable proof that preserves existing browser tests | kept (compressed) | Current Priority paragraph, item (2) |
| B-11 | 31 | ## Current Priority | 3. privacy-safe scoped replay and backend auth authority; | kept (compressed) | Current Priority paragraph, item (3) |
| B-12 | 32 | ## Current Priority | 4. real offline pronunciation media through one host-supplie | kept (compressed) | Current Priority paragraph, item (4) |
| B-13 | 33 | ## Current Priority | 5. physical-iPhone offline/replay evidence; | kept (compressed) | Current Priority paragraph, item (5) |
| B-14 | 34 | ## Current Priority | 6. only defects demonstrated by that evidence. | kept (compressed) | Current Priority paragraph, item (6) |
| B-15 | 41 | ## Working Rules | - Preserve the core thesis: Crosswake is a Phoenix-first rou | kept (compressed) | Working Rules bullet 1 (thesis) |
| B-16 | 43 | ## Working Rules | - Keep runtime ownership explicit per route. Do not collapse | kept (compressed) | Working Rules bullet 1, second sentence |
| B-17 | 45 | ## Working Rules | - Treat bridge contracts as semantic, typed, versioned, and  | kept (compressed) | Working Rules bullet 2 |
| B-18 | 47 | ## Working Rules | - Keep offline claims honest. Cached read-only is not local  | kept (compressed) | Working Rules bullet 2, second sentence |
| B-19 | 49 | ## Working Rules | - Preserve fail-closed explicit denials. Flag any path that  | kept (compressed) | Working Rules bullet 3 |
| B-20 | 50 | ## Working Rules | - Treat diagnostics and proof as product surface, but prefer | kept (compressed) | Working Rules bullet 3, second sentence |
| B-21 | 52 | ## Working Rules | - Android is unfrozen only for proof and parity of existing  | kept (verbatim) | Android bullet exactly as on main (D-06 line from PR1) |
| B-22 | 57 | ## Working Rules | - Do not build native menu/action-button breadth, new compan | moved to .planning/BEARINGS.md#do-not-re-open | one pointer line kept in Working Rules; the reversal-condition clause stays in the pointer |
| B-23 | 60 | ## Working Rules | - For a just-displayed, one-use approval gate, accept a plai | kept (byte-identical) | approval-gate bullet, whole-block containment checked in 194-EVIDENCE/agents-gate-194.txt |
| B-24 | 68 | ## Sensitive Data Rules | - Durable codename: **First B2C Adopter** (`first_b2c_adopte | kept (verbatim) | Sensitive Data Rules section byte-identical |
| B-25 | 69 | ## Sensitive Data Rules | - Public guides: say **first adopter**. | kept (verbatim) | Sensitive Data Rules section byte-identical |
| B-26 | 70 | ## Sensitive Data Rules | - Never record or infer the real adopter name, founder ident | kept (verbatim) | Sensitive Data Rules section byte-identical |
| B-27 | 72 | ## Sensitive Data Rules | - Never search git history or external sources to reidentify | kept (verbatim) | Sensitive Data Rules section byte-identical |
| B-28 | 73 | ## Sensitive Data Rules | - Treat offline mutation payloads as sensitive. Raw answers, | kept (verbatim) | Sensitive Data Rules section byte-identical |
| B-29 | 76 | ## Sensitive Data Rules | - Require opaque scope references, scope-partitioned outboxe | kept (verbatim) | Sensitive Data Rules section byte-identical |
| B-30 | 81 | ## Workflow | - Resolve the intended workstream explicitly; never infer on | kept (compressed) | Workflow bullet 1 (adds --ws) |
| B-31 | 83 | ## Workflow | - For the active quality lane, read the current phase from | deleted because ROLLING NOW and the workstream STATE carry the next command | the quality-lane discuss-phase line; the handoff rule still names STATE and ROADMAP |
| B-32 | 86 | ## Workflow | - Use `$gsd-plan-phase <current-phase> --ws quality-ratchet- | deleted because ROLLING NOW and the workstream STATE carry the next command | depends on the removed discuss-phase line; plan-phase routing is carried by STATE Exact Next Action |
| B-33 | 88 | ## Workflow | - Resume adopter work only with `--ws first-b2c-adopter-read | moved to .planning/ROADMAP-ROLLING.md#parked | PARKED row First B2C Adopter readiness: resume with --ws first-b2c-adopter-readiness after the external gate |
| B-34 | 90 | ## Workflow | - Default to zero-human verification and UAT. If a claim can | kept (compressed) | Workflow bullet 2 |
| B-35 | 93 | ## Workflow | - Reserve human action for unavoidable credentials, external | kept (compressed) | Workflow bullet 3 |
| B-36 | 96 | ## Workflow | - Promote checks into CI only when they protect a recurring  | kept (compressed) | Workflow bullet 4 |
| B-37 | 99 | ## Workflow | - Update requirements, roadmap, state, ADRs, capability/supp | kept (compressed) | Workflow bullet 5 (merged with B-38) |
| B-38 | 101 | ## Workflow | - Keep settled code-local truth in git. Keep fast-changing a | kept (compressed) | Workflow bullet 5 (merged with B-37) |
| B-39 | 103 | ## Workflow | - GSD handoff rule: report the last completed phase, the act | kept (compressed) | Workflow bullet 6 (merged with B-40) |
| B-40 | 106 | ## Workflow | - Keep one active handoff per workstream; move older handoff | kept (compressed) | Workflow bullet 6 (merged with B-39) |
| B-41 | 107 | ## Workflow | - Continue authorized local planning, diagnosis, implementat | kept (compressed) | Workflow bullet 7 (merged with B-42) |
| B-42 | 109 | ## Workflow | - Ask for a fresh decision only for a genuinely new irrevers | kept (compressed) | Workflow bullet 7 (merged with B-41) |
| B-43 | 112 | ## Workflow | - Retire superseded routes explicitly as not executed. | kept (compressed) | Workflow bullet 8 (merged with B-44) |
| B-44 | 113 | ## Workflow | - Test adapters against the dependency's real output, not in | kept (compressed) | Workflow bullet 8 (merged with B-43) |
| B-45 | 114 | ## Workflow | - A successful local read with a more privileged CLI credent | kept (compressed) | Workflow bullet 9 |
| B-46 | 116 | ## Workflow | - Plain-language status: start with what was checked, what h | kept (compressed) | Workflow bullet 10 |
| B-47 | 121 | ## How changes land | - Work in the one main checkout and branch from current orig | kept (verbatim) | How changes land section byte-identical |
| B-48 | 123 | ## How changes land | - Worktrees are allowed for parallel agent runs, never as a  | kept (verbatim) | How changes land section byte-identical |
| B-49 | 124 | ## How changes land | - Every change goes through a PR with Crosswake CI green on  | kept (verbatim) | How changes land section byte-identical |
| B-50 | 125 | ## How changes land | - Merge commit only. | kept (verbatim) | How changes land section byte-identical |
| B-51 | 126 | ## How changes land | - Say which commit CI actually ran on: for a pull request, G | kept (verbatim) | How changes land section byte-identical |
| B-52 | 128 | ## How changes land | - Run the privacy scan before every push, and rescan after a | kept (verbatim) | How changes land section byte-identical |
| B-53 | 129 | ## How changes land | - When CI is red, fix forward tied to the observed cause. | kept (verbatim) | How changes land section byte-identical |
| B-54 | 130 | ## How changes land | - Before retrying a write, read and reconcile what the first | kept (verbatim) | How changes land section byte-identical |
