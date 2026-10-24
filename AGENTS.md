# Crosswake Agent Guide

## Project Context

Read these before planning or implementation work:

1. `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing infrastructure decision, reversal conditions,
   privacy boundaries, stop list, and non-goals
2. `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` — RAG-friendly full game plan, surface audit,
   stakeholder lenses, ownership boundaries, proof/media analysis, and dated sequence
3. `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md` — first-adopter route owners and
   physical-iPhone exit test
4. `.planning/PROJECT.md` — project thesis, constraints, history, and decisions
5. `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — active v22 scope and
   traceability
6. `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — active quality/release phase
   ordering
7. `.planning/workstreams/quality-ratchet-release/STATE.md` — active position and next phase
8. `.planning/workstreams/first-b2c-adopter-readiness/STATE.md` — parked v21 position, real
   blocker, and exact resume posture

## Current Priority

Crosswake is infrastructure for the **First B2C Adopter**, not a separate business line. Optimize
for one real Phoenix application on one physical iPhone with one offline mutation island.

Priority order:

1. explicit first-adopter route ownership;
2. host-reusable proof that preserves existing browser tests and fixtures;
3. privacy-safe scoped replay and backend auth authority;
4. real offline pronunciation media through one host-supplied foreground iOS adapter;
5. physical-iPhone offline/replay evidence;
6. only defects demonstrated by that evidence.

If customer Alpha is web-only, Crosswake has no Alpha deliverable. Complete the bounded route
inventory, then pause Crosswake until the public-v1 mobile path is active.

## Working Rules

- Preserve the core thesis: Crosswake is a Phoenix-first route-policy and runtime-contract system,
  not a universal UI framework.
- Keep runtime ownership explicit per route. Do not collapse designs into generic WebView wrapper
  behavior or LiveView-driven native rendering.
- Treat bridge contracts as semantic, typed, versioned, and low-frequency. Continuous client
  authority belongs in an offline island or native screen.
- Keep offline claims honest. Cached read-only is not local mutation. One study island is not
  generic sync.
- Preserve fail-closed explicit denials. Flag any path that can degrade silently.
- Treat diagnostics and proof as product surface, but prefer one-command host proof over new label
  taxonomy.
- Android is frozen at its current generator, Maven, JVM, and vector posture. Do not add Android
  features, templates, device proof, parity work, or release requirements during v21.
- Do not build native menu/action-button breadth, new companions, capture/device packs, commerce
  productionization, a dashboard, brand/showcase polish, generic sync, background sync, or generic
  native storage unless the governing ADR's reversal condition is met.
- For a just-displayed, one-use approval gate, accept a plain-language `allow` or `hold`, bound
  internally to that attempt and its displayed scope. The gate is required for merges to `main`,
  merging the release PR, any Hex, Maven or iOS publish, creating or pushing tags, and deleting a
  remote branch. Local commits and pushes of feature branches need no gate. The user never copies
  hashes. An approval is never standing and never transfers to another attempt.

## Sensitive Data Rules

- Durable codename: **First B2C Adopter** (`first_b2c_adopter`).
- Public guides: say **first adopter**.
- Never record or infer the real adopter name, founder identity, price, geography, customer
  information, proprietary taxonomy, or revealing links.
- Never search git history or external sources to reidentify the adopter.
- Treat offline mutation payloads as sensitive. Raw answers, media, transcripts, credentials,
  account identifiers, tokens, and stable device identifiers must not enter telemetry, doctor
  output, inspection, logs, aggregates, or proof artifacts.
- Require opaque scope references, scope-partitioned outboxes, replay authorization, and fail-closed
  account-switch/logout behavior.

## Workflow

- Resolve the intended workstream explicitly; never infer one from a removed flat
  `.planning/STATE.md`.
- For the active quality lane, read the current phase from
  `.planning/workstreams/quality-ratchet-release/STATE.md` and start it with
  `$gsd-discuss-phase <current-phase> --ws quality-ratchet-release`.
- Use `$gsd-plan-phase <current-phase> --ws quality-ratchet-release` only when discussion is
  intentionally skipped.
- Resume adopter work only with `--ws first-b2c-adopter-readiness` after its recorded external
  gate is genuinely satisfied.
- Default to zero-human verification and UAT. If a claim can be checked by unit, integration, E2E,
  device automation, or artifact inspection, the agent runs that check and treats its result as the
  gate; do not emit `checkpoint:human-verify` or create a UAT handoff for it.
- Reserve human action for unavoidable credentials, external approvals, or irreversible trust
  actions. A physical-device connection may require human setup, but the assertions and evidence
  evaluation remain automated.
- Promote checks into CI only when they protect a recurring contract and provide stable,
  actionable feedback. Keep one-time reconciliation commands in phase evidence rather than
  creating permanent workflow lanes.
- Update requirements, roadmap, state, ADRs, capability/support truth, and guide renderings together
  when a decision changes.
- Keep settled code-local truth in git. Keep fast-changing adopter execution in the codename-only
  Linear issue drafts.
- GSD handoff rule: report the last completed phase, the active phase's status, and the exact next
  command from the workstream STATE and ROADMAP. Do not repeat a completed step. When no command is
  eligible, say so and name the condition that reopens work.
- Keep one active handoff per workstream; move older handoffs to history.
- Continue authorized local planning, diagnosis, implementation, and checks without per-step
  prompts.
- Ask for a fresh decision only for a genuinely new irreversible operation. Never transfer a
  consumed approval to another operation, never retry an uncertain delivery, and never treat
  frustration as permission.
- Retire superseded routes explicitly as not executed.
- Test adapters against the dependency's real output, not invented fixtures.
- A successful local read with a more privileged CLI credential does not prove that a workflow
  credential can read the same route.
- Plain-language status: start with what was checked, what happened, what is unknown and why,
  whether anything changed, and the next action. Explain internal codes after that.

## How changes land

- Work in the one main checkout and branch from current origin/main as `<type>/<topic>`, using the
  conventional prefixes release-please reads.
- Worktrees are allowed for parallel agent runs, never as a home for candidate state under /tmp.
- Every change goes through a PR with Crosswake CI green on the head.
- Merge commit only.
- Say which commit CI actually ran on: for a pull request, GitHub also tests a
  synthetic merge commit, which is not the head.
- Run the privacy scan before every push, and rescan after any new commit.
- When CI is red, fix forward tied to the observed cause.
- Before retrying a write, read and reconcile what the first attempt actually did.
