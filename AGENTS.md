# Crosswake Agent Guide

## Project Context

Read these before planning or implementation work, in this order:

1. `.planning/BEARINGS.md` — posture invariants, tripwires, and the do-not-re-open list
2. `.planning/ROADMAP-ROLLING.md` — NOW, NEXT, LATER, PARKED and DROPPED work
3. `.planning/ADR-FIRST-B2C-ADOPTER.md` — governing decision, reversal conditions, privacy, stop list
4. `.planning/PROJECT.md` — project thesis, constraints, history, and decisions
5. The active workstream's `STATE.md` and `ROADMAP.md` (resolve it with `--ws`; never infer one)
6. `.planning/FIRST-B2C-ADOPTER-ADOPTION-BRIEF.md` and `.planning/FIRST-B2C-ADOPTER-ROUTE-POLICY-MAP.md`
   (read when resuming adopter work)

## Current Priority

Crosswake is infrastructure for the **First B2C Adopter**, not a separate business line: one real
Phoenix application, one physical iPhone, one offline mutation island. Priority order: (1) explicit
first-adopter route ownership; (2) host-reusable proof that preserves existing browser tests and
fixtures; (3) privacy-safe scoped replay and backend auth authority; (4) real offline pronunciation
media through one host-supplied foreground iOS adapter; (5) physical-iPhone offline/replay evidence;
(6) only defects demonstrated by that evidence. If customer Alpha is web-only, Crosswake has no
Alpha deliverable: complete the bounded route inventory, then pause until the public-v1 mobile path
is active.

## Working Rules

- Preserve the core thesis: Crosswake is a Phoenix-first route-policy and runtime-contract system,
  not a universal UI framework. Keep runtime ownership explicit per route; no generic WebView
  wrapper behavior or LiveView-driven native rendering.
- Treat bridge contracts as semantic, typed, versioned, and low-frequency; continuous client
  authority belongs in an offline island or native screen. Keep offline claims honest: cached
  read-only is not local mutation, and one study island is not generic sync.
- Preserve fail-closed explicit denials; flag any path that can degrade silently. Treat diagnostics
  and proof as product surface, but prefer one-command host proof over new label taxonomy.
- Android is unfrozen only for proof and parity of existing contracts: generated-shell, Maven,
  JVM-hermetic and shared-vector evidence. Claims stop at JVM-hermetic proof; no emulator, device or
  feature-breadth claim is made until a later phase produces that evidence. Android never gates the
  first adopter's physical-iPhone proof. Re-freeze if Android work delays any iOS gate by more than
  one milestone.
- Do not re-open the stop list in `.planning/BEARINGS.md` (`Do not re-open`) unless the governing
  ADR's reversal condition is met.
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

- Resolve the intended workstream explicitly with `--ws`; never infer one from a removed flat
  `.planning/STATE.md`.
- Default to zero-human verification and UAT: if unit, integration, E2E, device automation, or
  artifact inspection can check a claim, the agent runs it and treats the result as the gate; do
  not emit `checkpoint:human-verify` or create a UAT handoff for it.
- Reserve human action for unavoidable credentials, external approvals, or irreversible trust
  actions; a device connection may need human setup, but assertions and evidence evaluation stay
  automated.
- Promote checks into CI only when they protect a recurring contract with stable, actionable
  feedback; keep one-time reconciliation commands in phase evidence.
- Update requirements, roadmap, state, ADRs, capability/support truth, and guide renderings together
  when a decision changes. Keep settled code-local truth in git and fast-changing adopter execution
  in the codename-only Linear issue drafts.
- GSD handoff rule: report the last completed phase, the active phase's status, and the exact next
  command from the workstream STATE and ROADMAP; do not repeat a completed step; when no command is
  eligible, say so and name the condition that reopens work. Keep one active handoff per workstream;
  move older handoffs to history.
- Continue authorized local work without per-step prompts. Ask for a fresh decision only for a
  genuinely new irreversible operation; never transfer a consumed approval, retry an uncertain
  delivery, or treat frustration as permission.
- Retire superseded routes explicitly as not executed. Test adapters against the dependency's real
  output, not invented fixtures.
- A successful local read with a more privileged CLI credential does not prove that a workflow
  credential can read the same route.
- Plain-language status: start with what was checked, what happened, what is unknown and why,
  whether anything changed, and the next action; explain internal codes after that.

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
