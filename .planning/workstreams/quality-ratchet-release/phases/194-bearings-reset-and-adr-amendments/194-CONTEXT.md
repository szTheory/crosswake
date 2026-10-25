# Phase 194: Bearings reset and ADR amendments - Context

**Gathered:** 2026-10-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 194 delivers two things:
- Orientation from three short files and one command: ROADMAP-ROLLING.md, BEARINGS.md, PERSONAS.md, a short STATE and `script/bearings-report`.
- One set of governing rule texts that say the same thing about Android (unfrozen for proof and parity of existing contracts) and synthetic profiles (a reversal gate that needs a measured artifact).

It covers PLAN-01..05 and ADR-01..02. Out of scope for 194:
- README and `android_uat.md` content (Phase 197).
- The PROJECT.md split, light-phase mode and seed normalization (LATER).
- Any Android build or test work (Phase 198).
- Any release step (Phase 199).

</domain>

<decisions>
## Implementation Decisions

The user asked for every area to be researched in parallel, with all relevant viewpoints and an adversarial pass, and for the resulting recommendations to be adopted without further questions. Four researchers ran; the decisions below are their merged recommendations, with conflicts resolved.

### PR packaging and landing order
- **D-01:** Two PRs, split at the boundary that SC4 requires to be atomic.
  - **PR1 `docs/v28-adr-amendments`** carries:
    - the two existing milestone-start commits (`839fc06b`, `7e794f01`) and this CONTEXT commit;
    - the ADR-01/ADR-02 amendment;
    - every live "Android frozen" posture surface (D-05), including generator source, regenerated guides, both golden fixtures and the pinning tests;
    - the Android line in AGENTS.md and the posture lines in PROJECT.md.

    Branch it from the current `docs/v28-milestone-start` HEAD, which is on top of `origin/main` `af1f4f67`.
  - **PR2 `docs/v28-bearings-reset`** branches from `origin/main` after PR1 merges, never stacked. It carries:
    - ROLLING, BEARINGS and PERSONAS;
    - the STATE trim and the milestone-start convention edit;
    - the MILESTONE-ARC banner and the PROJECT.md:491 pointer;
    - the full AGENTS.md trim (D-13);
    - `script/bearings-report` with its tests;
    - the persona-tag check.
  - **Reversibility:** reversible.
- **D-02:** Order is PR1 before PR2. BEARINGS invariant 5 and the ROLLING NOW row state "Android unfrozen", which is true only once PR1 is on `main`. That avoids status written before the event.
- **D-03:** Commit prefixes.
  - Use `docs:` for planning, ADR, AGENTS and PROJECT commits.
  - Use `fix(support-matrix):` for the `lib/` wording, regenerated guides and fixtures commit. That change is a user-visible public claim correction, so it should appear in the 0.2.12 notes.
  - Use `chore:` for the bearings-report script and its tests.
  - The planner must check `release-please-config.json` and the linked-versions components first. If touching `packages/crosswake-shell-core-ios/Tests/...Resources` with `fix:` would bump the iOS core component on its own, fall back to `docs:` for that commit and record why.
- **D-04:** Each PR body:
  - says which commit CI ran on (head versus synthetic merge);
  - includes the SC4 grep evidence (PR1);
  - shows the privacy scan run before the first push and after each new commit. The 12 v28 research files have never been pushed; follow `privacy-193.sh` with absolute paths as separate args.

  Each merge needs its own one-use `allow`, and PR1's `allow` never carries over to PR2.

### Android frozen-text boundary (ADR-01)
- **D-05:** Phase 194 owns every **live** Android posture surface. There is no window where Hex docs, generated manifests and the ADR disagree.
  - `AGENTS.md:52`.
  - `.planning/ADR-FIRST-B2C-ADOPTER.md`: append an amendment and add one Status pointer line. The body and line 123 stay as dated history.
  - `.planning/PROJECT.md:131` and `:506`. Lines `:162`, `:166` and `:493` are milestone history and stay.
  - `lib/crosswake/support_matrix/support_matrix.ex:446,473`.
  - `lib/crosswake/support_matrix/renderer.ex:378,399`. Rename the row "Android during first adopter readiness" to "Android (existing contracts)" after grepping `test/` for the old title. Keep a refute of the old title.
  - `lib/crosswake/capability_map/renderer.ex:163` only. Keep the "Frozen candidates" heading, because it is about native controls.
  - The comment at `lib/crosswake/proof_lane/provenance.ex:39`.
  - Regenerate `guides/support_matrix.md` and `guides/capability_map.md` from source. Never hand-edit them.
  - `guides/native_shell.md:33`, which is hand-written. It moves here from 197 to close the last Hex-docs contradiction; 197 still reviews its content.
  - **Verified in this discussion:** the support-matrix notes are embedded in two golden fixtures, `examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json` (2 hits) and `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json` (4 hits). Regenerate both through their normal generator path, never by hand, and the iOS/macOS jobs must pass on PR1's head.
  - Rewrite the pinning tests so they pin the new truth and refute the old literal. Do not delete them:
    - `test/crosswake/support_matrix/renderer_test.exs` (about lines 56 and 412–419);
    - `test/crosswake/support_matrix/support_matrix_test.exs` (about lines 83–84).

  Phase 197 keeps README (no hits today), `android_uat.md`, and the final zero-hit grep.
  - **Reversibility:** costly. A revert touches the generator, two golden fixtures and the Hex docs.
- **D-06:** Live posture wording for AGENTS.md and PROJECT.md:
  > "Android is unfrozen only for proof and parity of existing contracts: generated-shell, Maven, JVM-hermetic and shared-vector evidence. Claims stop at JVM-hermetic proof; no emulator, device or feature-breadth claim is made until a later phase produces that evidence. Android never gates the first adopter's physical-iPhone proof. Re-freeze if Android work delays any iOS gate by more than one milestone."

  Support-matrix and manifest notes:
  > "Android proof and parity cover existing contracts only. Evidence is `JVM hermetic proof` and shared vectors; there is no emulator, device or new-feature claim."

  Keep the existing "no new Android feature, template, emulator/device or release requirement" boundary at `renderer.ex:399`, adjusted only to remove the word "frozen". Never write "parity achieved" or "emulator verified".
- **D-07:** The SC4 grep is a **one-time phase-evidence command**, not a new CI test. The recurring contract is the rewritten renderer and support_matrix tests, which already run.
  - Pattern: `rg -n -i -P` with `(android[^.\n]{0,80}\b(is|are|remains?|stays?|retains?)\b[^.\n]{0,20}\bfrozen\b)|(\bfrozen\b[^.\n]{0,60}\bandroid\b)|(android[^.\n]{0,60}\bfrozen\b)`.
  - Scope: the D-05 files plus the two golden fixtures.
  - It passes only if the hit set **equals** an explicit allowlist of amendment-history hits, keyed by file plus normalized text rather than line number. Both a new hit and a vanished allowlisted hit fail.
  - It asserts every scanned file exists and that the new posture sentence is present in each live file.
  - Negative control: run it against `git show origin/main:<file>`, which must produce at least 8 hits. An injected "Android is frozen" line must give a non-zero exit.
  - Capture the exit code explicitly; never pipe to `tail`. Record unrelated whole-repo hits as out of scope, for example the SDK pin in `script/run_repository_evidence_environment.sh` and "frozen literal" comments.
- **D-08:** The ADR changes are dated amendment sections **appended to the existing ADR file**, in its existing format (Decision / Why / Alternatives / Status / What would change my mind / Date / Confidence). No new ADR file is created, because `first_adopter_context.ex` and its tests key on this path.
  - A1 (ADR-01) carries the D-06 text. "What would change my mind" is the re-freeze trigger.
  - A2 (ADR-02) sits **alongside** the original reversal condition and does not replace it. The original is two independent active adopters, or a separately funded business-line mandate; keep those pinned phrases and "web-only" verbatim, because `first_adopter_context_test.exs:397-406` asserts them.
  - Under A2, a synthetic-profile proposal must name five things: the profile, the failing criterion, the cited artifact, the smallest slice and the rollback.
  - At most one item can be reopened per milestone.
  - A passing gate permits profile scenario rows over one host only. It never permits generic sync, new companions, native menu or action breadth, or any claim about a real adopter.
  - Profiles stay generic.

### bearings-report build (PLAN-04, PLAN-05/SC5)
- **D-09:** Use Elixir with no new dependency. The logic goes in `script/bearings_report.exs`, run with `elixir`, behind a short bash launcher `script/bearings-report` that does `exec elixir .../bearings_report.exs "$@"` and has no pipes. The prior art is `script/check_absence_is_not_success.exs` and `check_release_version_truth.exs`. Tests go in `test/crosswake/bearings_report_test.exs` (ExUnit; register ownership if `check_exunit_ownership.exs` requires it). It is not wired into a workflow or listed as a required check.
- **D-10:** All external reads go through one injectable `run(cmd, args)` that returns `{:ok, out}` or `{:error, reason}`.
  - Tests inject a fake runner keyed by `{cmd, args}`; no PATH shims and no env magic.
  - Fixtures are **real captured** `gh` and `git` output under `test/fixtures/bearings/`, made once by a capture step. A shape-guard test asserts the expected keys.
  - No test touches live `gh`, `git` or the network.
  - Treat these as UNVERIFIED, never as empty: a non-zero exit, a missing binary, unparseable JSON, an empty result where data is required, or a `gh pr list` result at the limit (truncation).
- **D-11:** Checks, with their read and UNVERIFIED condition:
  - **CI at main:**
    - Reads `git rev-parse origin/main` and `gh run list --branch main --workflow "Crosswake CI" --json headSha,conclusion,status,databaseId`.
    - Prints `CI <conclusion> on <sha7>` with the commit CI actually ran on.
    - Prints "CI has not run on HEAD" when the SHAs differ, and treats an in-progress run as PENDING, never green.
    - *Amended at plan time (2026-10-24, plan 194-06):* the read above cannot work as written. `crosswake-ci.yml` runs only `on: pull_request`, so `gh run list --branch main --workflow "Crosswake CI"` returns `[]` (measured 2026-10-24), and a main tip is never tested directly; only the PR head and a synthetic merge commit are. The check instead resolves the merged PR for the `origin/main` tip (`gh api repos/<slug>/commits/<sha>/pulls`), reads the newest `Crosswake CI` run on that PR's head SHA, and prints `ci: <conclusion> on <head7> (PR #<n> head; main <main7> is its merge commit, tested only as a synthetic merge)`, so the line says its status belongs to the PR head. A main tip with zero or several merged PRs, or no run on the PR head, is UNVERIFIED. The intent above is unchanged: name the commit CI actually ran on, flag HEAD that CI has not run on, and never show PENDING as green. ROADMAP Phase 194 SC3 and REQUIREMENTS PLAN-04 were clarified in the same commit.
  - **Ahead/behind:** `git fetch origin main`, then `rev-list --left-right --count`.
  - **Open PR classes:** release-please, dependabot, feature, and stale (more than 14 days, with an injected clock).
  - **Worktrees, stashes and unlanded branches:** read with porcelain git commands.
  - **Line caps:**
    - ROLLING at most 120, BEARINGS at most 60, workstream STATE at most 40, and AGENTS.md at the D-13 cap.
    - Count by reading the file, not with `wc`.
    - A missing file is UNVERIFIED.
    - Add an advisory PROJECT.md over 250 lines line, which gives the deferred split a receiver.
  - **Seed/debt triggers:**
    - Optionally support a machine `fires_when:` frontmatter field, with the grammar `milestone>=vNN.N` or `phase>=NNN`, evaluated against workstream `state.json` and ROADMAP.
    - Skip shipped, harvested and closed seeds.
    - Print open seeds with no machine trigger as **one counted info line**, not as attention. Today about 20 of 25 seeds have only prose triggers; backfilling them is E7 seed normalization (LATER), and counting them as attention would make Phase 199's exit 0 impossible.
    - UNVERIFIED if zero seeds parse or a `fires_when` value doesn't parse.
    - v27 debt-disposition is prose with no row shape, so report its open-item count as info. Mechanical debt rows wait for the E6 closeout template (LATER).
  - **Persona tags:** per D-12.
- **D-12:** The persona-tag check is a pure function in the same module, exposed two ways:
  - **A bearings-report line on the live active REQUIREMENTS file.** The workstream is resolved by `--ws`, defaulting to `quality-ratchet-release`; the milestone comes from workstream `state.json`. The report never reads a flat `.planning/STATE.md` and never uses `milestone.lock`. The line is UNVERIFIED if the file is missing or the requirement count is 0.
  - **Fixture-based ExUnit tests.** The positive fixture is all tagged; the negative fixture has one untagged requirement.
  - No ExUnit test reads the live REQUIREMENTS file, because that would turn a docs edit into a merge block before its findings are measured.
  - Grammar: `- [ ] **ID** [TAG]:` where TAG is `P[1-7]`, `J[1-5]`, `M`, or a combination such as `P1/J2`.
- **D-12a:** Output is at most 40 lines, and overflow truncates with an overflow count, which is tested.
  - Line 1 is the verdict: `BEARINGS: OK`, `BEARINGS: ATTENTION (n)` or `BEARINGS: UNVERIFIED (n reads failed)`.
  - Exit codes: 0 means all reads verified and nothing needs attention, 1 means attention, 2 means UNVERIFIED (which wins).
  - Never print tokens, env values or raw `gh` stderr; print fixed reason strings instead.
  - Negative controls, one per check:
    - `gh` error gives exit 2;
    - `gh` returning `[]` gives UNVERIFIED;
    - a SHA mismatch is caught;
    - a failed fetch is caught;
    - a 121-line ROLLING breaks the cap;
    - a missing cap file is UNVERIFIED;
    - a 15-day-old PR is classed as stale;
    - a satisfied `fires_when` produces a fired line;
    - an always-`{:ok, ""}` runner never yields OK (the absence-as-success guard).

  For Phase 199 SC4, the report is run locally at close, and a CI run is not taken as proof of the same thing.

### AGENTS.md trim and the orientation files
- **D-13:** The full AGENTS.md trim happens in 194 (PR2) through a **recorded roadmap change**. PLAN-02 and 194 SC1 are amended in this discussion's commit, and the requirement count stays at 30.
  - The target is at most 90 lines. If the draft can't reach 90 without dropping a rule, record the measured cap in ROADMAP and REQUIREMENTS instead; a rule is never deleted to hit the number.
  - Guards:
    - a disposition table (kept / moved to X / deleted because Y) for every bullet of `git show main:AGENTS.md`;
    - the approval-gate bullet must be byte-identical (`grep -F` against main's text);
    - a small doc-contract ExUnit test with a negative control. It asserts the gate phrases (`allow`, `hold`, one-use, and the gated action classes) and the ADR path.

  Keep/move/delete map:
  - **Project Context** becomes: BEARINGS (first), ROLLING, ADR, PROJECT, then "the active workstream's STATE and ROADMAP (resolve with `--ws`; never infer)", then one line for the adopter brief and route map, read when resuming. Delete the v21/v22 pointers.
  - **Current Priority** stays, compressed. ROLLING's `priority_order_ref` and the inward-streak rule key on it.
  - **Working Rules** stay, with the Android line per D-06. The "Do not build" list becomes one line plus a pointer to BEARINGS "Do not re-open".
  - **Sensitive Data Rules** and **How changes land** stay verbatim.
  - **Workflow:** drop the quality-lane `$gsd-discuss-phase` line and the adopter-resume line. The adopter resume becomes ROLLING's PARKED row, which gives it a receiver. The rest stays.
- **D-14:** BEARINGS starts from the SYNTHESIS §5 draft, with these corrections:
  - Invariants 4 and 5 become **pointers**, to the AGENTS.md gate and to ADR amendment A1, instead of second copies.
  - Invariant 8's "how checked" becomes "clean-room command (Phase 195)", worded as a rule rather than a fact already checked.
  - "Open traps" keeps only traps that no v28 phase owns, such as twin-05 attesting `a53fbef`. Traps that 195 and 196 own (#236, #210/#211, SEED-025, Muex zero mutants) are dropped, and the report covers them.
  - Every MILESTONE-ARC Durable Lesson gets a line or a recorded drop with a reason:
    - add backend authority, hermetic versus advisory lanes, and docs-contract parity;
    - artifact parity is covered by existing lines;
    - drop install truth, mock-the-provider-boundary and showcase truth, each with its reason.
  - Each "bit us at least twice" tripwire is checked against a source. A tripwire with no source loses the "twice" claim.
  - The 60-line cap must hold.
- **D-15:** ROLLING starts from the SYNTHESIS §4 draft, with these corrections:
  - Keep `priority_order_ref`.
  - The PARKED column "Checked: each loop run" becomes "milestone close (bearings-report)" only if the report really reads it; otherwise drop the column.
  - Mark plan and phase counts as approximate.
  - Add a DROPPED row for the superseded root JTBD ordering (commerce, notification, operator, auth and native families).
  - Add LATER rows for the PROJECT.md split (trigger: bearings-report reports more than 250 lines), seed normalization (E7) and the closeout debt-row template (E6).
  - At most 120 lines.
- **D-16:** PERSONAS.md comes from `v28.0-research/JTBD-PERSONAS.md` §3: P1–P7 and J1–J5, at most one page, all synthetic and generic. The superseded ordering is recorded in **both** places:
  - a dated banner at the top of `.planning/research/JTBD-AND-USER-FLOWS.md` ("Proposed Ordering superseded 2026-10-24 by PERSONAS.md and ROADMAP-ROLLING; not executed");
  - the ROLLING DROPPED row.

  Edit no headings in that file; `test/crosswake/guides/user_flows_test.exs:49-60` asserts them. Notifications survive as a LATER reopen row.
- **D-17:** MILESTONE-ARC.md gets a banner and stays where it is, unmoved.
  - Add a dated blockquote under the H1: HISTORICAL, superseded by ROLLING and BEARINGS, not in the agent read path, with a list of which lessons moved and which were dropped.
  - The body stays unedited. `milestone_arc_closeout_parity_test.exs` and the inbound links depend on it.
  - PROJECT.md:491 ("strategic source of truth") is now false. Point it at ROADMAP-ROLLING.md, and change that one test assertion in the same PR to assert the new pointer and the banner string. The other arc tests stay.
  - The capability taxonomy stays where it is and goes to the PROJECT.md split LATER row.
  - Check that PROJECT.md:586 is still true.
- **D-18:** STATE becomes at most 40 lines: frontmatter, Position, Exact Next Action (one handoff), and a carried-debt link.
  - "Handoff history" and the historical accumulated-context blocks are deleted, and git keeps them.
  - The byte-snapshot ritual (`history/vNN-before-vMM-start` plus sha256) is removed from the milestone-start convention wherever it is defined; the planner should grep the GSD workstream/milestone docs and `.planning` conventions.
  - Trimming the parked adopter STATE stays deferred.

### Claude's Discretion
- Exact sentence-level wording of BEARINGS, ROLLING and PERSONAS within the caps and corrections above.
- The internal module structure of `bearings_report.exs`, and the exact launcher path resolution.
- The plan split inside each PR.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and requirements
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 194 success criteria, as amended by D-13; ordering rules.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — PLAN-01..05 and ADR-01..02.
- `.planning/workstreams/quality-ratchet-release/v28.0-SCOPE.md` — the user's approvals (ADR package, cleanup, ceremony cuts).
- `.planning/workstreams/quality-ratchet-release/v28.0-research/SYNTHESIS.md` — §4 ROLLING draft, §5 BEARINGS draft, §7 decisions, §8 do-not list.
- `.planning/workstreams/quality-ratchet-release/v28.0-research/ROADMAP-PROCESS.md` — E1–E9 (AGENTS, STATE, ARC, ritual).
- `.planning/workstreams/quality-ratchet-release/v28.0-research/JTBD-PERSONAS.md` §3 — persona and job source.
- `.planning/workstreams/quality-ratchet-release/v28.0-research/TWINS-AND-PROFILES.md` — GET-6, profile rows over one host.

### Governing rule texts
- `AGENTS.md` — the approval gate (verbatim), the Android rule at line 52, and Project Context.
- `.planning/ADR-FIRST-B2C-ADOPTER.md` — amendment target; the reversal condition and pinned phrases.
- `.planning/PROJECT.md` — lines 131, 162, 166, 491, 493, 506 and 586.
- `.planning/MILESTONE-ARC.md` — the Durable Lessons to migrate; banner target.
- `.planning/research/JTBD-AND-USER-FLOWS.md` — superseded ordering; banner target.

### Generated posture surfaces and pins
- `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/support_matrix/renderer.ex`, `lib/crosswake/capability_map/renderer.ex`, `lib/crosswake/proof_lane/provenance.ex`
- `guides/support_matrix.md`, `guides/capability_map.md` (generated); `guides/native_shell.md` (hand-written)
- `examples/phoenix_host/native/ios/crosswake_shell/Fixtures/crosswake_manifest.json`, `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/host_command_seam_fixture.json`
- `test/crosswake/support_matrix/renderer_test.exs`, `test/crosswake/support_matrix/support_matrix_test.exs`, `test/crosswake/planning/first_adopter_context_test.exs`, `test/crosswake/planning/milestone_arc_closeout_parity_test.exs`, `test/crosswake/guides/user_flows_test.exs`
- `lib/crosswake/planning/first_adopter_context.ex` — the ADR path glob.

### bearings-report inputs
- `script/check_absence_is_not_success.exs`, `script/check_exunit_ownership.exs` — `.exs` script prior art and the ownership rule.
- `.planning/workstreams/quality-ratchet-release/state.json` — milestone source.
- `.planning/seeds/*.md` — frontmatter shape (`status`, prose `trigger_when`).
- `.planning/workstreams/quality-ratchet-release/milestones/v27.0-closeout/debt-disposition.md` — prose debt list.
- `release-please-config.json` — linked components (D-03 check).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `.exs` scripts under `script/` use `System.cmd` with explicit exit handling. That pattern is reused for `bearings_report.exs`.
- The support-matrix and capability-map renderers already generate the guides. The posture fix lives in their source data, and the guides and manifests are regenerated.

### Established Patterns
- Generated guides and manifests are never hand-edited. Pinning tests assert exact strings, so they are rewritten to pin the new truth and refute the old.
- Doc-contract tests pin ADR phrases, ARC headings and JTBD headings. Banners are added; headings are not edited.
- Changes land through a PR from `<type>/<topic>`, merge commit only, with a one-use `allow` per merge and the privacy scan before each push.

### Integration Points
- Support-matrix notes flow into generated iOS manifests and the Swift seam fixture. PR1 therefore needs the iOS/macOS CI jobs green.
- bearings-report reads workstream `state.json`, REQUIREMENTS, seeds, the line-capped files, `git` and `gh`.

</code_context>

<specifics>
## Specific Ideas

- The user's standing preference is that another copy-paste beats another dependency. bearings-report adds no dependency: it uses a hand-rolled frontmatter `key: value` parser and no YAML library.
- Status must be derived from git, CI or artifacts, never written ahead of the event. That is why ROLLING and BEARINGS land after the ADR PR.

</specifics>

<deferred>
## Deferred Ideas

- Seed frontmatter normalization and backfilling `fires_when` for about 20 prose-only seeds (E7): ROLLING LATER row.
- Closeout debt-row template with owner, trigger and receiver columns (E6): ROLLING LATER row.
- PROJECT.md split (E4) and moving the capability taxonomy: ROLLING LATER row, triggered when the bearings-report PROJECT.md line exceeds 250.
- Relaxing the historical MILESTONE-ARC parity tests: LATER.
- Trimming the parked adopter STATE (393 lines): stays deferred per SYNTHESIS.
- A weekly bearings workflow: v29, as the SYNTHESIS section on "one script now, workflow later" says.

</deferred>

---

*Phase: 194-bearings-reset-and-adr-amendments*
*Context gathered: 2026-10-24*
