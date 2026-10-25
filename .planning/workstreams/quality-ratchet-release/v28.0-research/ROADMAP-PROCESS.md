# Rolling Roadmap, Posture and "Keep Our Bearings" Mechanism

Dimension: roadmap process. Researched 2026-10-24. Read-only research; one output file.
Confidence: diagnosis HIGH (measured from the repo). External-practice claims MEDIUM (from established
sources I know well: Shape Up, Now/Next/Later, PMBOK rolling wave, Nygard ADRs, Rust/Kubernetes/Python
RFC-style projects; not re-fetched this session, so cite-check before quoting). Design HIGH-on-fit, untested.

---

## 0. User decisions applied (2026-10-24, relayed by coordinator)

These supersede conflicting statements below and in AGENTS.md. They are STANDING POSTURE and go in BEARINGS.md and ROADMAP-ROLLING.md.

1. **Android is unfrozen, ASAP.** AGENTS.md "Android is frozen" and the "do not add Android features" rule become false. The rolling roadmap carries Android as a NOW/NEXT item (not DROPPED/PARKED). Prerequisite: an ADR amendment (below) and an AGENTS.md edit in the same PR, so rule text and roadmap agree (project rule: update ADRs, roadmap, state and guides together).
2. **Synthetic adopter profiles may reopen ADR stop-list items** through the ADR's own reversal process. Synthetic profiles are evidence for reversal conditions; they do not bypass the ADR. Each reopened item needs a recorded reversal entry (see ADR-amendment step).
3. **Fix the release pipeline and release on a cadence.** Each publish (Hex, Maven, iOS, tag, release-PR merge) keeps the one-use `allow`/`hold` gate, never standing. Cadence is a roadmap slot, not an authorization.

### ADR-amendment step (new, mandatory in the loop)

Added as step 4b of the new-milestone loop and as a field in ROADMAP-ROLLING:
- Every NEXT/NOW item gets `adr: none | amends <ADR section> | reopens <stop-list item>`.
- If not `none`, the milestone's first phase (or scope-doc approval) lands an **ADR amendment**: item reopened, reversal condition cited (e.g. "synthetic adopter profile P-x demonstrates need"), evidence link, privacy boundaries retained, and the superseded AGENTS.md/PROJECT.md lines edited in the same PR. Template (<=15 lines): `Amendment N | date | stop-list item | reversal condition met by | evidence | scope bound | superseded text | rollback condition`.
- Synthetic profiles stay anonymized, contain no real adopter data, and go through the privacy scan like any artifact. Never infer the real adopter.
- The loop's fit check (step 4) treats an ADR-reopened item without an amendment as ineligible.
- Guard against rubber-stamping: at most one reopened stop-list item per milestone appetite, and the fail-closed, one-island, honest-offline invariants stay in BEARINGS.

### Effects on sections below

- Seed content for ROADMAP-ROLLING: NOW/NEXT include (a) Android unfreeze (ADR amendment + AGENTS edit first; re-baseline generator/Maven/JVM posture, then features), (b) release-pipeline repair plus a release-cadence slot (release PR #236 is no longer an open user decision: it falls under the cadence and a per-publish `allow`), (c) synthetic-profile-driven reopenings, each with its own amendment.
- Section 9 decisions 3 and 4 are resolved by (1) and (3). Decision 2 should now define "outward" to include hermetically proven scenario-matrix cells driven by synthetic profiles, since the real adopter lane stays externally gated.
- Do-not-do list: the Android clause is superseded. Still no dashboard, and no generic/background sync unless an ADR amendment reopens it with evidence.
- Open user decision: define release cadence. Recommendation: trigger-based (main green + release PR non-empty + bearings report green), checked in each loop run, so cadence never forces an empty release. A standing quality-slice item is "release train healthy" (SEED-003 iOS mirror token, SEED-004 clean-room harness, SEED-025 credential masking).
- The inward-streak rule matters more: Android unfreeze and cadence releases count as outward only if they ship user-visible artifacts or move matrix cells.

---

## 1. Diagnosis of the current planning system

### 1.1 Measured bloat (this repo, today)

| Artifact | Measure | Verdict |
|---|---|---|
| quality-ratchet-release STATE.md | 194 lines, ~35 KB, 69 "Superseded" entries in "Handoff history" | Bloat. AGENTS.md says "keep one active handoff, move older to history"; the history stayed inside STATE.md and is a changelog of next-commands nobody re-reads. |
| first-b2c-adopter-readiness STATE.md | 393 lines (parked) | Worse. A parked lane should be about 20 lines: gate, resume command. |
| PROJECT.md | 638 lines; "Current State" alone about 120 lines (L136-259); Key Decisions about 110 lines; 8 stacked "Earlier Completed Milestone" sections | Bloat. Mixes thesis (stable), history (append-only) and current status (volatile). Read-every-time is impossible. |
| RETROSPECTIVE.md | 1061 lines; Cross-Milestone Trends table has about 40 rows, newest at the TOP of a different section than the older table | Good content, unreadable. High-signal lessons are buried among v3.x rows. |
| MILESTONE-ARC.md | 377 lines; still says "v19 showcase, v20 controls" as the current arc | STALE. The strategic horizon doc is about five milestones behind reality. This is the clearest single loss of bearings. |
| Phase folders v189-193 | 117, 58, 127, 93, 114 files; 1.6/0.6/2.8/0.8/1.2 MB; 55 plans for a "land and clean up" milestone | Records per phase far exceed the value of the work. Phase 191 (2.8 MB) was a branch + suite run. |
| .planning total | 71 MB (16 MB live phases, 18 MB archived milestones) | Archive is fine as a cold store; the cost is only paid when it enters the read path. |
| Per-milestone closeout | v27 closeout/ is only 51 lines (CLOSEOUT 21 + debt-disposition 30) | This is the one artifact that is the right size and the most useful. Model on it. |
| Scope docs | vNN-SCOPE.md 29-57 lines | Useful (approval, goal, facts, boundaries) but each re-derives scope from nothing; research v26 spawned 4 researchers + adversary. |

### 1.2 What genuinely helps (keep)

1. **Closeout + debt-disposition with a "Trigger to act" column** (v27). Debt has an owner-condition, not just a list.
2. **Seeds with trigger_when** (25 seeds). Right idea; execution is uneven: SEED-009 has no trigger, SEED-012 says "when relevant", 8 seeds use a `>-` block, 2 are `shipped/harvested` and still sit in the active dir. Half the seeds are residue of reviews (SEED-018..025) rather than ideas.
3. **v-SCOPE.md "Approval and goal"** capturing what the user actually said. Keep, but template it.
4. **Zero-human verification posture, one-use allow/hold gate, "How changes land"** in AGENTS.md. Stable, actionable.
5. **Cross-milestone lessons**, especially "absence scored as success", "deferrals must name a receiver that is allowed to act", "status written ahead of an event goes stale". These are the real compounding assets.
6. **Feasibility gates that stop at a real missing seam** (v25 Phase 180 -> 181/182). Cheap, high payoff; keep as a pattern.

### 1.3 Ceremony / bloat (cut)

- **Handoff history inside STATE.md** (69 entries). A handoff is valid until the next one lands; the old one is git history. Delete, do not "supersede".
- **Per-plan granularity in non-product milestones.** v27 had 55 plans/127 tasks to move 94 commits through one PR. Plans-per-requirement was about 3. The overhead was caused partly by the "freeze + /private/tmp candidate" regime (see 1.4), not by the work.
- **Byte-copy snapshots + sha256 of planning files before each milestone start** (history/vNN-before-vMM-start, v24-v26). Git already does this once planning lives on `main`. It existed because planning files were untracked in a frozen checkout. Now obsolete.
- **Four-researcher + adversary fan-out for every milestone scope** (v26). Justified when scope is genuinely open; waste when the next milestone is already on a horizon list. The new loop should make research conditional.
- **Machine-extracted summaries that undercount** (CLI reported tasks 1 vs 127, 21 vs 96; placeholder one-liner bullets chronic since v3.4). Known for 20+ milestones; the workaround is hand-correcting every time.
- **Parallel planning surfaces**: ROADMAP.md (workstream), ROADMAP.md.orig, MILESTONE-ARC.md, PROJECT.md "Current Milestone Goals", MILESTONES.md (two of them), SCOPE docs, STATE.md "Exact Next Action" and `.continue-here.md`. The next-action is stated in at least four places and they drift (v27 closeout had to "rewrite" a stale STATE, a stale continue-here, stale ROADMAP lines and unticked checkboxes).

### 1.4 Where bearings were lost or work repeated (v22-v27)

| Event | What it shows |
|---|---|
| **Five consecutive inward milestones** (v23 release repair, v24 cleanup, v25 twin proof, v26 harden, v27 land). Nothing since v22 moved the adopter's physical-iPhone exit test. | No standing check of "does this milestone serve the stated priority order in AGENTS.md?" Scope was chosen by the most recent mess. The priority list exists but is not an entry criterion. |
| **v25+v26 product code lived only in `/private/tmp` for about two weeks** (90 commits ahead of main, 4 stashes, 56 branches, 2 worktrees); v27 spent 5 phases and 55 plans landing it. | Unlanded work is the single most expensive recurring failure. "Freeze checkout" rules were invented ad hoc and then needed an entire milestone to unwind. Rule that now exists: branch from main, PR, merge commit. It should be a posture invariant with a mechanical check, not just prose. |
| **Absence-as-success reappeared in each newest layer** (v23 REL-10, v25 twin binding, v26 run tooling, v27 FIX-01..03 scripts that run only from a phase folder). | The lesson is in memory and RETROSPECTIVE but not in the path where new work is planned. It was re-learned four times. A "tripwire list" at plan time is the cure; a longer retrospective is not. |
| **Deferral to a receiver that cannot act** (v26: two items to a no-code freeze phase dropped until audit). | Debt rows need (owner, trigger, receiver-phase-or-milestone). v27's table does this; make it mandatory. |
| **Retroactive bookkeeping** (v3.8, v13, v14, v19, v27: VERIFICATION written by executor, Nyquist skipped). | Chronic for 24 milestones. Move to a phase-close checklist rather than more retrospective text. |
| **SEED-013/014/016 "next milestone touching X" triggers never fired** because nothing evaluated triggers at scoping time. SEED-011 `ready_for_promotion` for months while four non-adopter milestones ran. | Seeds are write-only. Needs a mechanical trigger scan in the new-milestone loop. |
| **Docs claim state before it happens** (stale-on-arrival records, v27 trend). | Write status after the event, derive it from git/CI (a generated "bearings" report), never hand-write "awaiting merge" into STATE. |

Net diagnosis: the system is strong at **rigor within a milestone** and weak at **selection between milestones** and at **keeping the number of places that say "what is next" at one**.

---

## 2. Rolling roadmap artifact

### 2.1 Principle (from the sources)

- **Now/Next/Later** (Bastow/ProdPad): horizons by confidence, not dates; items in Later are intentionally vague.
- **Rolling-wave planning** (PMBOK): detail the near wave, outline the far wave, re-plan at each wave boundary.
- **Shape Up** (Singer/Basecamp): fixed appetite, variable scope; a betting table that re-decides every cycle; no standing backlog; cool-down between cycles; unshipped pitches are not auto-carried (they must be re-pitched). Adopt: appetite and re-pitch. Do NOT adopt: 6-week calendar cycles, a betting table with multiple humans (there is one decision-maker).
- Mature OSS (Rust project goals, K8s KEPs, Python PEPs): the public roadmap is a short list of themes with owners and states, individual designs live in separate numbered docs. The roadmap rarely exceeds a page. Items die explicitly (Withdrawn/Rejected/Deferred) with a reason.

### 2.2 Recommendation R1: one file, `.planning/ROADMAP-ROLLING.md` (project-level, not workstream)

Rationale for project-level: the adopter lane and the quality lane share priorities and the AGENTS.md priority order is project-level. One file avoids per-workstream drift. Workstream ROADMAP.md files stay as phase lists for the active milestone only (as GSD expects).

**Hard max: 120 lines (about 6 KB).** A mechanical check (wc -l, in the hygiene report) fails over 120. Overflow is a signal to cut, not to split.

Template:

```markdown
---
updated: 2026-10-24          # by new-milestone loop only
active_milestone: v28.0
priority_order_ref: AGENTS.md#Current-Priority
---
# Rolling Roadmap
Charter line: <= 2 sentences. Served priority this arc: <#2/#3 from AGENTS.md>.

## NOW  (the milestone in flight or being scoped; exactly 1)
### vNN.0 <name>   appetite: <=N phases / <=N plans   serves: priority #k
- Outcome (one sentence a stranger can verify):
- Exit evidence (command or artifact, not prose):
- In: <=5 bullets. Out (explicit): <=3 bullets.
- Quality slice (mandatory, see 4.3): <hygiene items pulled from debt, <=20% of appetite>
- Kill/stop condition:

## NEXT  (2-3 milestones, outcome + why-now + entry criteria; NO phases)
| ID | Outcome | Serves priority | Entry criteria (all must be true) | Confidence H/M/L |
## LATER (mid: next quarter-ish; one line each, no scope)
| Theme | Why it might matter | Trigger / evidence that promotes it |
## PARKED / EXTERNAL GATE (long-term; adopter lane etc.)
| Lane | Gate (the real external condition) | Resume command | Checked on |
## DROPPED (last 10, one line + reason; older rows deleted, git remembers)
```

### 2.3 Horizons and entry criteria

| Horizon | Meaning | Detail level | Entry criteria to be here | Max items |
|---|---|---|---|---|
| NOW (immediate) | Next/active milestone | Outcome, exit evidence, in/out, appetite, quality slice; phases come from /gsd-new-milestone | Promoted from NEXT when (a) all entry criteria true, (b) bearings report green or exceptions listed, (c) user said yes | 1 |
| NEXT (near, 2-3) | Likely follow-ons | Outcome, why-now, entry criteria, confidence. No phases, no requirement IDs | Serves a priority in AGENTS.md **or** is a repair that blocks one (must name which) | 3 |
| LATER (mid) | Real but unscheduled | One line + promotion trigger | Has a trigger that can be evaluated mechanically or by one glance | 8 |
| PARKED (long) | Gated externally | Gate + resume cmd | Gate is an external fact (adopter public-v1 mobile path, credentials) | 3 |
| DROPPED | Explicitly not doing | Reason | Decision made | rolling 10 |

Decisions about movement:
- **Promotion NEXT->NOW** happens only in the new-milestone loop (section 4). **Demotion** happens when an entry criterion goes false or a milestone slips: item goes back with a one-line reason, never silently re-scoped.
- **No auto-carry**: an item in NOW that ships partially: the remainder is re-pitched into NEXT with fresh appetite or DROPPED (Shape Up rule). This kills "tail debt that rides forever".
- **Staleness rule**: an item in NEXT/LATER with no change in 3 milestones is demoted/dropped by the loop. Each row carries `since: vNN`.
- Confidence in NEXT must be stated; L-confidence items get a feasibility gate (v25 style, S effort) as their first phase, not a research fan-out.

### 2.4 How seeds, debt and todos feed it

- **Seeds** stay in `.planning/seeds/` but gain a normalized frontmatter (R6 below). The loop runs a trigger scan; matches appear in the loop's "Candidates" list; the user disposes each as promote-into-NOW / LATER row / dropped. A seed that matched twice and was never promoted is closed `declined`.
- **Debt** (`debt-disposition.md` Carried table) feeds the **quality slice** of NOW, ranked by "Trigger to act" firing. Items whose trigger did not fire stay carried; items carried 3 milestones are fixed or dropped.
- **Review residue seeds (SEED-018..025)** are not ideas; they are debt. Fold them into debt-disposition rows with triggers and stop minting seeds for review warnings.
- **Todos** (TODO-001..010) older than 3 milestones: close or convert in the loop.

---

## 3. Posture and high-signal takeaways register

### 3.1 Recommendation R2: `.planning/BEARINGS.md`, hard cap 60 lines / about 4 KB

Read at the start of every new-milestone, every discuss-phase and every plan-phase (added to AGENTS.md "Project Context" as item 0). It answers: "what must I not forget and what must I not re-do?"

How it differs:

| Document | Contents | Changes | Size |
|---|---|---|---|
| AGENTS.md | Rules for agent behavior: how to work, approval gate, privacy, landing PRs | Rare, by decision | about 100 lines, fewer after R9 |
| PROJECT.md | Thesis, constraints, key decisions (ADR-style), requirement ledger | Per decision | target <=250 lines |
| Memory (user's) | Cross-session personal preferences and lessons across projects | Whenever | Index only |
| **BEARINGS.md** | Current posture invariants (with mechanical check or owner), tripwires for planning, "do not re-open" list, top lessons | Per milestone close, by the loop | **<=60 lines hard** |
| RETROSPECTIVE.md | Narrative evidence and history | Append-only, cold | Unbounded but not in read path |

Template:

```markdown
# Bearings (read me first; <=60 lines; edited only at milestone close)
## Posture invariants (each: statement | how checked | last verified)
1. main is green and nothing valuable exists only in a local/tmp place. | `hygiene-report` | date
2. Offline claims stay honest; one island is not sync. | docs-contract tests | ...
3. Every milestone serves an AGENTS.md priority or names the repair it blocks.
4. ...(max 8)
## Tripwires: check at plan time (max 10; each has a one-line "how it bit us")
- A check with no negative control passes by asserting nothing (v23, v25, v26, v27).
- Piped checks mask exit codes. Run one command per gate.
- A deferral without a receiver that can act is a drop (v26).
- Status written before the event is stale on arrival; derive, don't hand-write.
- A recurring-gate script living only in a phase folder is not a gate (v27).
## Do not re-open (decisions that are settled; link to PROJECT.md key decision)
- Android frozen. No generic sync. No candidate-in-/tmp regime. (max 8)
## Current open traps (max 5; delete when fixed)
- crosswake-integration-191 unbacked tips; SEED-025 credential masking in CI output.
```

Rules:
- **Entry test** for a line: it must (a) have bitten us at least twice or been expensive once, (b) be actionable in one sentence at plan time, (c) not already be enforced by a failing check. If a CI check enforces it, move it to "how checked" and delete the prose.
- **Pruning**: at each milestone close the loop deletes at least as many lines as it adds once at the cap. Any line not triggered for 4 milestones is archived to RETROSPECTIVE and removed. "Open traps" are removed when fixed.
- **Hard cap is enforced by `wc -l` in the hygiene report** (fail = loop cannot complete until pruned).
- Lessons currently in the ~40-row Cross-Milestone Trends table migrate in ranked form; the table stays in RETROSPECTIVE as cold evidence.

---

## 4. The "automatic new milestone" loop

### 4.1 Recommendation R3: a deterministic scoping runbook, `docs/MILESTONE-LOOP.md` (about 1 page), extending the existing MILESTONE-BOUNDARY-HYGIENE.md

Inputs (each is a file or a generated report, so the loop is mostly reading):

1. `ROADMAP-ROLLING.md` (NOW/NEXT)
2. `BEARINGS.md` (invariants, tripwires)
3. `debt-disposition.md` of the last closeout (+ trigger firing)
4. Seed trigger scan (frontmatter `trigger_when` plus `watch` globs)
5. **Hygiene/bearings report** (generated, R4): main CI status, ahead/behind, open PRs by class, worktrees, stashes, unlanded branches, STATE.md line count, BEARINGS line count, orphan phase dirs, seed/todo age
6. Persona/JTBD doc (`research/JTBD-AND-USER-FLOWS.md`, already exists) and a **scenario coverage matrix** (one table: scenario x status {proven on device, proven hermetic, claimed, absent}). Treat the matrix as the answer to "what product movement has this arc made?" See 4.4.

Steps (the agent runs these; target under 1 hour of agent time, 2 human touchpoints):

1. **Close**: `complete-milestone` + write the 30-line closeout/debt-disposition (existing). Update ROADMAP-ROLLING status of the finished milestone (shipped/partial -> remainder re-pitched or dropped).
2. **Bearings pass**: generate the report; fix red items in the quality slice or record as open trap. If main is red or unlanded work exists, the *only* eligible NOW is repair (the "land before you leap" invariant).
3. **Candidate list** = NEXT[0] + fired seeds + fired debt triggers + matrix gaps closest to the exit test. Deterministic ranking: priority order in AGENTS.md first, then fired-trigger count, then smallest appetite.
4. **Fit check** (one table, auto-filled): does the candidate serve AGENTS.md priority k? Is it inward (repair/hygiene/proof tooling) or outward (moves a matrix cell)? **Inward-streak counter**: after 2 consecutive inward milestones, the next NOW must be outward unless the user explicitly overrides in the scope doc.
5. **Research conditional**: if NEXT entry has confidence H and a sketch exists, skip fan-out. If L, run one S feasibility gate, not four researchers. Fan-out + adversary only for genuinely new surface (decision rule written in the scope doc).
6. **Draft** vNN-SCOPE.md from template (goal, approval record, facts-at-start generated from report, in/out, appetite, quality slice, exit evidence, stop condition) and the ROADMAP-ROLLING NOW block.
7. **Human decision** (single prompt, recommendation first, per memory "research-then-recommend"): approve/modify scope; confirm appetite. Everything else proceeds.
8. `gsd-new-milestone` (requirements + phases) from the approved scope. Phase count follows appetite, not the other way round.
9. **Re-slot**: promote NEXT items, add new NEXT row if fewer than 2 remain, run staleness demotion, prune BEARINGS to cap.

Still needs a human:
- Approving scope/appetite for the NOW milestone (one yes/modify).
- Overriding the inward-streak rule or the "land before you leap" rule.
- Any irreversible op (merge to main, publish, tag, remote branch delete): existing `allow/hold` gate. Unchanged.
- Resuming the adopter lane (an external gate; the agent can check the gate fact but the user declares it satisfied).
- Priority-order changes in AGENTS.md.
- Declining a seed that has fired twice.

### 4.2 Recommendation R4: generated bearings report, one command

`scripts/bearings-report` (or a `gsd_run`/mix task) prints a <=40-line plain-language report: what was checked, results, unknowns. Items: main CI at HEAD (state which commit CI ran on, per AGENTS.md), `origin/main..HEAD` counts, open PR classes (release PR, dependabot, stale feature), `git worktree list`, stash/branch counts not on main, STATE.md/BEARINGS/ROLLING line caps, seeds whose trigger fired, debt rows whose trigger fired, unticked checkboxes in ROADMAP, phases without VERIFICATION. Must follow the posture lessons: each check has a negative control, output counts are asserted non-zero where zero would be absence, and it never pipes to tail. Replaces the manual runbook steps 0-2 of MILESTONE-BOUNDARY-HYGIENE.md; the runbook then shrinks to "what to do about each red line". Effort M.

### 4.3 Standing quality cadence: slice in every milestone, not a separate quality milestone

Recommendation R5: **every milestone carries a quality slice of at most 20% of appetite** (one phase or tail phase, named "Slice: hygiene"), populated mechanically from debt rows whose triggers fired plus bearings-report reds. No dedicated quality milestone on a schedule.

Why: Crosswake's last five milestones were effectively dedicated quality milestones and still re-introduced the same defect class, because quality was a *phase of concern* rather than a standing tax. A scheduled quality milestone every N is a Shape Up "cool-down" in spirit but, with one human and AI agents, becomes the same inward-streak failure. Allowed exception: a quality/repair milestone is eligible only when the bearings report is red on an invariant (main red, unlanded work, release graph broken), and then it is time-boxed to the appetite of the repair, with an exit check that is the report turning green.

Also: "mini cool-down" is already cheap here: the loop itself (closeout + bearings + scope) is the cool-down. Do not add a calendar one.

### 4.4 Scenario matrix and persona doc: inputs, not new products

Do not create new persona/JTBD docs. `JTBD-AND-USER-FLOWS.md` already exists; the loop only needs one table, `.planning/SCENARIO-MATRIX.md` (<=30 rows), mapping first-adopter scenarios (cold launch, route handoff, offline answer, replay after reconnect, logout/account switch scope isolation, denial states) to evidence level. This is the objective answer to "did we move the exit test?" and the source of the inward/outward label. Seed it from ROUTE-POLICY-MAP + ADOPTION-BRIEF, not from scratch. Effort S/M. Scenario names stay anonymized; no adopter identifiers.

---

## 5. Concrete edits to AGENTS.md / PROJECT.md / STATE conventions

| # | Edit | Effort | Horizon |
|---|---|---|---|
| E1 | AGENTS.md: add `.planning/BEARINGS.md` and `.planning/ROADMAP-ROLLING.md` as items 0/1 of Project Context; remove items already stale (v21/v22 references, "active v22 scope", "v21 parked position"). Replace per-version mentions with "read the active workstream's STATE and ROADMAP" only. | S | Immediate |
| E2 | AGENTS.md: collapse "Current Priority" and the "Do not build" list to the BEARINGS "do not re-open" pointer; keep the approval gate paragraph verbatim. Target <=90 lines. | S | Immediate |
| E3 | STATE.md convention: **<=40 lines, frontmatter + Position + Exact Next Action (one handoff) + Carried-debt link**. Delete "Handoff history" (69 entries) entirely; git history keeps it. If a past handoff must be kept, one line in `history/`, not in STATE. Parked workstream STATE <=25 lines (gate + resume command). | S (edit) / M (trim the 393-line adopter STATE carefully) | Immediate |
| E4 | PROJECT.md: split into stable top (What/Core Value/Verification Posture/Constraints/Key Decisions as one-line-per-decision, <=250 lines) and move "Current State", "Earlier Milestone" sections and the completed-milestone paragraphs to `MILESTONES.md`/archive. Keep a link, not a copy. Evolution section stays. | M | Immediate-near |
| E5 | Retire MILESTONE-ARC.md as a live doc: archive its Durable Lessons into BEARINGS (ranked top 10), its Capability Taxonomy into PROJECT.md or ADR, mark the rest historical. ROADMAP-ROLLING replaces its strategic role. | S | Immediate |
| E6 | Closeout template fixed at: CLOSEOUT.md (<=25 lines) + debt-disposition.md with required columns `item | origin | owner | trigger to act | receiver | since`. Mandatory "Re-pitch or drop" line for any unfinished scope. | S | Immediate |
| E7 | Seed frontmatter normalization: `status` in {planted, fired, promoted, declined, harvested}, `trigger_when` one-liner required, optional `watch:` file globs for mechanical firing; move harvested/shipped/declined to `seeds/closed/`; stop creating seeds for review residue (use debt rows). | S/M | Near |
| E8 | Phase record budget: for repair/landing/hygiene milestones allow a "light phase" mode: one PLAN.md with checklist tasks, CONTEXT optional, VERIFICATION required. Phases with a mechanical exit check need no research/patterns/validation trio. Proposal is a convention; GSD tooling may not support it, so verify before relying on it (see decisions). | M | Near |
| E9 | Planning files live on `main` (they now do after v27); delete the `history/vNN-before-vMM-start` + sha256 ritual from the milestone-start convention. | S | Immediate |
| E10 | Phase-close checklist (VERIFICATION by someone other than the executor where feasible, one-liner SUMMARY authored at close, roadmap checkbox parity) so the closeout confirms rather than creates. Matches the recurring "retroactive bookkeeping tax". | S | Near |
| E11 | Add to hygiene report a mechanical "unlanded work" check as a posture invariant, since this was the most costly failure. | S (part of R4) | Immediate |

---

## 6. Proposed file layout

```
AGENTS.md                              # rules, <=90 lines
.planning/
  BEARINGS.md                          # <=60 lines, read-every-time (new)
  ROADMAP-ROLLING.md                   # <=120 lines, NOW/NEXT/LATER/PARKED/DROPPED (new)
  SCENARIO-MATRIX.md                   # <=30 rows, evidence level per first-adopter scenario (new)
  PROJECT.md                           # thesis/constraints/decisions, <=250 lines
  RETROSPECTIVE.md  MILESTONE-ARC.md   # cold history, not in read path
  seeds/ (+closed/)   todos/           # trigger-normalized
  workstreams/<ws>/
    STATE.md                           # <=40 lines (parked <=25)
    ROADMAP.md                         # active milestone phases only
    vNN.0-SCOPE.md                     # from template, <=50 lines
    milestones/vNN.0-closeout/{CLOSEOUT,debt-disposition}.md
docs/MILESTONE-LOOP.md                 # the 9-step loop (new, 1 page)
docs/MILESTONE-BOUNDARY-HYGIENE.md     # shrinks to remediation per red line
scripts/bearings-report                # generated report, one command (new)
```

vNN-SCOPE.md template (short): Approval and goal (user words, date) / Serves priority / Appetite / In / Out / Facts at start (pasted from bearings report) / Research decision (skip|gate|fan-out and why) / Quality slice / Exit evidence / Stop condition.

---

## 7. Ranked recommendations

| Rank | Recommendation | Effort | Horizon | Why |
|---|---|---|---|---|
| 1 | R1 ROADMAP-ROLLING.md with horizons and re-pitch rule, seeded with: NOW = (decision), NEXT = candidates from seeds 011/013/014/016 and adopter gate, PARKED = adopter lane | S | Immediate | Fixes selection-between-milestones; one place for "what next" |
| 2 | E3 trim STATE to <=40 lines, delete handoff history | S | Immediate | Biggest measured bloat, pure deletion |
| 3 | R2 BEARINGS.md <=60 lines with cap check | S | Immediate | Prevents re-learning; costs little |
| 4 | R4 bearings-report command including unlanded-work check | M | Immediate (before the new milestone is scoped, or as its first quality slice) | Replaces hand-written status, turns posture into checks |
| 5 | R3 MILESTONE-LOOP.md with inward-streak and land-before-leap rules | S | Immediate | Makes milestone start "fairly automatic" |
| 6 | E1/E2/E5 AGENTS.md trim, retire MILESTONE-ARC | S | Immediate | Cuts stale pointers |
| 7 | R5 quality slice <=20% per milestone | S (convention) | Immediate | Ends the quality-milestone-as-regime pattern |
| 8 | E4 PROJECT.md split | M | Near | High read-cost relief, low risk |
| 9 | SCENARIO-MATRIX.md | S/M | Near | Objective outward/inward test |
| 10 | E7 seed normalization + closed/ dir | S/M | Near | Makes triggers actually fire |
| 11 | E8 light-phase convention (verify GSD support first) | M | Near/Mid | Cuts per-phase record weight |
| 12 | Trim adopter-lane STATE (393 lines) to a resume stub | M | Mid | Parked; risk of losing the real blocker text, so do carefully with diff review |

---

## 8. Do NOT do

- Do not build a dashboard, roadmap tool, or Linear/Jira mirror of the roadmap. A 120-line markdown file is the whole system.
- Do not add dates or quarters to horizons (no promises to nobody; use confidence + entry criteria).
- Do not create a calendar-driven cool-down or a recurring quality milestone every N.
- Do not let BEARINGS grow above 60 lines "just this once"; prune or fail.
- Do not store lessons in a new place per milestone; RETROSPECTIVE is cold, BEARINGS is hot, nothing else.
- Do not hand-write "awaiting merge/next" statuses before the event; derive from git/CI.
- Do not run 4-researcher + adversary fan-out when NEXT already has an H-confidence entry.
- Do not mint seeds for review warnings; use debt rows with triggers.
- Do not make the bearings report merge-blocking until its findings on `main` are measured (project lesson: measure a check's findings before gating).
- Do not pipe gate commands to tail/head. Do not let a recurring check live only in a phase folder.
- Do not rewrite or delete archived milestone records; archive is cold storage, only the read path shrinks.
- Do not add Android, native-breadth or sync work to any horizon list except as DROPPED/PARKED rows (matches AGENTS.md).

---

## 9. Decisions only the user can make

1. **Appetite model**: accept "appetite in phases/plans per milestone, scope flexes" (recommended: <=4 phases, <=20 plans for non-repair milestones) versus the current "scope drives phase count".
2. **Inward-streak rule**: adopt "2 inward milestones max, then outward unless you override in the scope doc" (recommended). Also decide the meaning of "outward" given the adopter lane is externally gated: is a hermetic proof of a scenario-matrix cell outward, or only a device-proven cell?
3. **Adopter-lane pause**: AGENTS.md says if the customer is web-only, pause Crosswake until public-v1 mobile path is active. Does the rolling roadmap's NOW horizon assume the lane stays parked (then NOW is necessarily maintenance/hardening/seed work, and that should be said honestly) or is there an expected resume date?
4. **Release PR #236**: merge/publish or drop; it blocks a clean "main/PR queue" invariant.
5. **Quality slice size** (20% recommended) and whether bearings-report failures should ever be merge-blocking.
6. **Whether to trim the adopter STATE.md (393 lines) now** versus leaving it untouched until resumption.
7. **Permission to retire MILESTONE-ARC.md** (it contains durable lessons and a capability taxonomy that must be migrated, not just deleted).
8. **Light-phase mode**: ok to deviate from the full GSD per-phase artifact set for repair milestones, if tooling tolerates it.

---

## Sources and confidence

- Repo measurements (wc/du of PROJECT.md, STATE.md files, phases, archives, seeds, closeouts, RETROSPECTIVE trends): HIGH, taken 2026-10-24.
- Shape Up (Ryan Singer, Basecamp; appetite, betting table, cool-down, no-backlog): MEDIUM, recalled, not re-fetched.
- Now/Next/Later (Janna Bastow, ProdPad): MEDIUM, recalled.
- Rolling-wave planning (PMI PMBOK): MEDIUM, recalled.
- ADRs (Michael Nygard, 2011); Rust project goals, Kubernetes KEPs, Python PEPs as roadmap-plus-design-doc patterns: MEDIUM, recalled.
- Lessons from the user's memory index ("absence scored as success", "piped checks mask exit codes", "blocked SUMMARY naming", milestone-boundary hygiene): HIGH, project-specific.
- Not verified: whether the installed GSD tooling supports light phases or a project-level rolling roadmap file without breaking `roadmap.analyze`/progress derivation (research gap; check before E8 and R1 wiring).
