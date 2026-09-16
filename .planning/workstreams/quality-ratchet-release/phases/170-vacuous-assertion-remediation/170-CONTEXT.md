# Phase 170: Vacuous Assertion Remediation - Context

**Gathered:** 2026-09-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Classify every collection assertion in the test suite whose empty case is not a failure, rewrite
every one confirmed vacuous so an empty collection fails, and establish the per-phase mechanism by
which every new check landed anywhere in milestone v23.0 is measured against the six-shape vacuity
taxonomy before it is allowed to become merge-blocking.

The phase MAY add `script/inventory_collection_assertions.exs` and its committed snapshot, add a
ledger-completeness test, insert non-emptiness guards at confirmed-vacuous call sites across the
test suite, add an itemized structural test and a small number of empty-input regression tests, and
add a `vacuity_taxonomy` section convention to the phase-close VERIFICATION.md template plus a
retroactive addendum covering Phase 169.

The phase does NOT add `absence.collection_assertion_non_empty` (VACG-01) to
`script/check_absence_is_not_success.exs` or to any required-check registry, does NOT add any
merge-blocking guard, does NOT change `lib/` runtime code, does NOT touch `.github/workflows/`, does
NOT address vacuity Shapes B–F (owned by Phases 171/173/174), does NOT change `Enum.all?`'s failure
message ergonomics, and does NOT publish anything.

</domain>

<verified_ground_truth>
## Verified Ground Truth — supersedes SEED-018's and ROADMAP SC#1's arithmetic

**Measured against the live repository on 2026-09-16 by running the greps, not by reading prior
documents.** SEED-018's discovery grep is wrong in BOTH directions. The planner must implement
against the measured numbers below, not against the literal "173".

Reproduction:

```
grep -rnE 'assert Enum\.(all\?|any\?)' test --include='*.exs' | wc -l   # 173
grep -rnE 'assert Enum\.all\?'         test --include='*.exs' | wc -l   #  42
grep -rnE 'assert Enum\.any\?'         test --include='*.exs' | wc -l   # 131
grep -rnE 'refute Enum\.any\?'         test --include='*.exs' | wc -l   #  47
grep -rnE 'refute Enum\.all\?'         test --include='*.exs' | wc -l   #   0
```

| Observation | Result |
|---|---|
| SEED-018's flagged set | **173** sites across **42** test files — the seed's count reproduces exactly |
| …composition | **42** `assert Enum.all?` + **131** `assert Enum.any?` |
| `assert Enum.any?` on an empty collection | `Enum.any?([], f)` is `false`, so the assertion **FAILS**. All 131 are non-vacuous **by construction** |
| `refute Enum.any?` sites, NOT in the flagged 173 | **47**. `refute Enum.any?([], f)` **PASSES** on empty — the identical defect, invisible to the seed's grep |
| `refute Enum.all?` sites | **0** |
| Of the 42 `assert Enum.all?`, preceded within 6 lines by an explicit non-emptiness guard | **13** guarded · **29** unguarded |
| `Enum.filter \|> Enum.all?/any?` compound shape | **0** occurrences in this repo |

**Therefore SEED-018 over-counts by 131 and under-counts by 47.** The true candidate-vacuous
population is 42 + 47 = **89**, of which 13 are already guarded. The audited population this phase
classifies is **220** (173 flagged + 47 unflagged-but-identical).

**The 29 unguarded `assert Enum.all?` sites are themselves heterogeneous.** Sixteen were read
directly during discussion. Findings that change the work:

- `test/crosswake/guides/native_evidence_drift_test.exs:29` iterates `@scanned_paths`, a
  **module-attribute list literal**. It can never be empty. This is a grep false positive, not a
  vacuous assertion — it gets classified `safe`, never "fixed".
- `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs:44,92` and
  `test/crosswake/release_candidate/cleanroom_test.exs:35,36,37` are each **immediately preceded by
  an exact-list equality assertion** (`assert Enum.map(coll, & &1.id) == [<literal list>]`) that
  pins cardinality. They are already guarded — in a shape the 6-line `refute Enum.empty?` heuristic
  does not recognize. Classifying these `needs-fix` would be a false positive.
- The genuinely at-risk subset is the **filtered / file-derived** sites with no preceding guard of
  any shape: `test/crosswake/doctor/doctor_test.exs:731` (an `Enum.filter` over real
  `Doctor.run/1` findings), `test/crosswake/support_matrix/support_matrix_test.exs:187` (an
  `Enum.filter` over release boundaries), `test/crosswake/guides/evidence_manifest_test.exs:110,111,113,118`
  (values read out of a real manifest file), `test/crosswake/guides/release_boundaries_test.exs:101`,
  `test/crosswake/manifest/manifest_test.exs:71`.

**Blast-radius finding.** Three of the 47 unflagged `refute Enum.any?` sites live in release-graph
test files that gate the Phase 175 one-way door:
`test/mix/tasks/crosswake_release_status_test.exs`,
`test/crosswake/release_candidate/coordinate_test.exs`,
`test/crosswake/release_candidate/mirror_test.exs`.
`test/crosswake/release_candidate/cleanroom_test.exs` is the release-critical file already inside
the 173. Leaving the 47 out would leave the highest-consequence sites unaudited by an accident of
which quantifier SEED-018's grep happened to name.

**ROADMAP SC#1's "counting rows against the 173 total" is restated to 220**, preserving its intent
(every candidate site carries a recorded classification) while correcting its arithmetic. This
follows Phase 169's own precedent for a success criterion that is directionally right and
arithmetically wrong: record the ground truth, restate the criterion, defer the roadmap text edit.

</verified_ground_truth>

<decisions>
## Implementation Decisions

### Audited set boundary (VAC-01)

- **D-01:** The audited population is **220 sites** — SEED-018's 173 plus the 47 `refute Enum.any?`
  sites. The grep in SEED-018 was a discovery heuristic, not a definition; the phase goal says
  "every site flagged as a candidate absence-scored-as-success defect," and `refute Enum.any?` on an
  empty collection is the same defect at the same severity. The decisive argument is blast radius,
  not count: three of the 47 sit in the release-graph test files gating Phase 175's irreversible
  publish, and the marginal cost is 47 more rows fixed by the same one-line rewrite already planned
  for the 42. A half-remediated defect class is worse than an unremediated one, because it teaches
  the team the class is closed when it is not — SEED-018 makes this argument itself.
  — **Reversibility:** reversible — 47 extra ledger rows and at most a handful of extra guard lines.

- **D-02:** Stop at 220. Do NOT widen to the broader vacuity family (`Enum.each` without a count
  assertion, `for` comprehensions, `Enum.reduce` boolean accumulators, unforced `Stream` chains).
  `.planning/research/v23/PITFALLS.md` maps Shapes B–F to Phases 171/173/174 and to the VAC-03
  checklist, not to Phase 170, and the one compound shape that would matter most
  (`Enum.filter |> Enum.all?`) has **zero** occurrences here. Pulling those in would violate the
  milestone's own division of labor and repeat the scope-creep failure mode that large-scale-change
  practice (Error Prone's staged rollout, Coccinelle campaigns, Google's LSC discipline) exists to
  prevent: one semantic-patch shape per campaign, fixed completely, independently revertible.

- **D-03:** Do NOT edit ROADMAP.md SC#1's "173" in this phase. The correction lives in
  `<verified_ground_truth>` above; amending the roadmap text is a separate, deferred call, exactly
  as Phase 169 handled its own two wrong success criteria.

### Ledger shape and drift-resistance (VAC-01)

- **D-04:** The ledger is a **regenerable inventory plus a committed snapshot**, not a hand-typed
  table: `script/inventory_collection_assertions.exs` emits the live audited set, a snapshot file is
  committed, and an ExUnit test asserts the regenerated output equals the snapshot **exactly**.
  A static `file:line`-keyed markdown table is rejected outright and is not a considered option — it
  is this milestone's target defect restated as a deliverable. This repository has already shipped
  that bug: `mix test path:63` against a test that moved to line 65 prints "0 tests, 0 failures" and
  exits 0, which is precisely why `absence.open_finding_citation_resolves` exists in
  `script/check_absence_is_not_success.exs`. The in-repo ancestor for the chosen mechanism is one
  phase old: Phase 169's D-04 `release.scanner.roster_exact` asserts the emitted check-ID set equals
  its roster exactly, for the same anti-rot reason, one level up.
  — **Reversibility:** costly — the snapshot format is consumed by the ledger test and by D-06's
  completeness assertion; changing the row schema after the audit lands means regenerating and
  re-reviewing every classification rationale.

- **D-05:** Rows are keyed by a **content hash of `{enclosing describe/test name, normalized
  assertion expression}`** — never by line number. `file:line` is carried as a human-readable
  *display* field, never as the key. A moved-but-unchanged assertion then produces zero diff noise,
  while a genuinely new or altered one always produces a diff. Precedent: Sobelow's `.sobelow-skips`
  fingerprint hashes and PHPStan's/Psalm's baselines all match on content, not position, for exactly
  this reason. Psalm's documented footgun — hash churn on pure reformatting — is neutralized by
  normalizing (whitespace-stripping the expression, keying on AST shape rather than raw source text)
  before hashing.

- **D-06:** **The ledger test asserts that the LEDGER IS COMPLETE — never that every site is
  guarded.** Concretely: no site in the tree is missing a row, and no row is an orphan. It does NOT
  assert "every `Enum.all?` has a preceding non-emptiness guard." That second assertion *is* VACG-01
  and stays deferred. This is the precise line that lets a tree-wide inventory coexist with SC#3's
  prohibition, and the planner must not blur it.

- **D-07:** Classification is mechanically bucketed first; humans write rationale only for the
  residual. Buckets:

  | Bucket | Population | Basis |
  |---|---|---|
  | `safe-by-construction` | the 131 `assert Enum.any?` | `Enum.any?([], f)` is `false` — fails on empty. Auto-classified, no rationale needed |
  | `safe-compile-time-literal` | e.g. `native_evidence_drift_test.exs:29` | collection is a module attribute or list literal; cannot be empty |
  | `safe-cardinality-pinned` | e.g. `physical_iphone_test.exs:44,92`, `cleanroom_test.exs:35-37` | preceded by an exact-list equality assertion pinning the element set |
  | `safe-guarded` | the 13 detected | explicit `refute Enum.empty?` / `assert [_ \| _]` within the window |
  | `needs-fix` | the residual | genuinely runtime-derived, no guard of any shape |

  The `safe-cardinality-pinned` bucket exists **because** the 6-line heuristic has proven false
  negatives (D-01's ground truth). Every row outside `safe-by-construction` carries a one-line
  rationale **string** — never a bare boolean. A suppression without a stated reason is the
  documented decay mode of every baseline mechanism in the industry (RuboCop todo files, ESLint
  suppressions, mypy baselines).

- **D-08:** The ledger is **scaffolding with a written sunset**, not a permanent artifact. When
  VACG-01 eventually lands as a merge-blocking guard, lift the inventory script's detection core
  into that guard rather than rewriting it, and **delete** the snapshot file and its diff test. Two
  mechanisms that can silently disagree about what counts as "safe" are worse than one. Record the
  sunset trigger in the inventory script's header comment and as a line under Future Requirements,
  so the later deletion is a documented step and not a cold judgment call.

### Rewrite idiom (VAC-02)

- **D-09:** The fix is `refute Enum.empty?(collection)` on the line immediately preceding the
  assertion, applied uniformly to every `needs-fix` row regardless of the collection's origin. It
  costs one line, needs no per-site knowledge of expected cardinality, and is the fix shape
  `.planning/research/v23/PITFALLS.md` Shape A already names.
  — **Reversibility:** reversible — purely additive one-line insertions.

- **D-10:** Rejected alternatives, recorded so they are not relitigated:
  - **A shared custom assertion macro** (`assert_all/2` in test support) — it solves "a future
    contributor forgets the guard," which is precisely VACG-01's job. Solving it locally duplicates
    deferred work in a harder-to-remove form, adds indirection across the whole fix set, and trades
    stdlib ExUnit for a house idiom every contributor must learn.
  - **`assert Enum.count(coll) == expected_n`** as the uniform idiom — strictly stronger, but
    brittle for file- and registry-derived collections that legitimately grow. Use it only where a
    site's sibling assertions already establish exact cardinality, i.e. codify what is already
    implicit; never invent a new expected count.

- **D-11:** Classification strictly precedes rewriting. Sites classified `safe-compile-time-literal`
  or `safe-cardinality-pinned` are recorded as safe and **left untouched** — they are not "fixed."
  Inserting a redundant guard at a site that can never be empty adds diff noise and invites the
  reviewer to distrust the audit.

### Proof that "empty now fails" (VAC-02, SC#2)

- **D-12:** The proof is a **hybrid matched to measured risk**, not one mechanism applied uniformly:

  1. **An itemized, closed-world structural test** over the fixed `needs-fix` list, asserting for
     each entry that the guard exists **and that its argument expression matches the assertion's
     argument expression**. The second half matters: it catches guard-checks-the-wrong-variable,
     which a runtime test cannot reliably catch.
  2. **Genuine empty-input regression tests** at the runtime-derived, highest-blast-radius sites
     only: `test/crosswake/doctor/doctor_test.exs:731`,
     `test/crosswake/support_matrix/support_matrix_test.exs:187`,
     `test/crosswake/guides/evidence_manifest_test.exs:110-118`,
     `test/crosswake/guides/release_boundaries_test.exs:101`, plus the release-critical
     `refute Enum.any?` sites in `crosswake_release_status_test.exs`, `coordinate_test.exs` and
     `mirror_test.exs`.

  A per-site regression test for all ~29+ sites was costed against the actual code and rejected:
  most sites cannot be forced empty without fabricating structs and fixture files that no longer
  exercise the real code path, so the test would assert a property of the harness, not of the guard.

- **D-13:** **Both proof mechanisms are ordinary `mix test` entries, closed-world over this audit's
  fixed list.** Nothing is added to `script/check_absence_is_not_success.exs`'s check list and
  nothing is added to the required-check registry. The structural test enumerates the exact entries
  this audit produced and will NOT fire on a new site added next month — that standing, tree-wide,
  open-world enforcement is VACG-01's job and remains deferred. SC#3 is therefore satisfied by
  construction rather than by inspection.

- **D-14:** Non-vacuity proof per Phase 169's D-23, before anything is trusted: record the measured
  counts on pre-fix `main` (220 audited rows; N classified `needs-fix`), and demonstrate the
  structural test failing against a deliberately un-guarded fixture entry. Those numbers ARE the
  proof the new tests are not themselves vacuous. A proof harness for vacuity that is itself vacuous
  is the failure this phase exists to prevent — and this repository has already been burned by
  exactly that (the `"\\1" <> "0.9.9"` capture-group-10 mutation control that silently did nothing).
  Note in mitigation that "substitute an empty collection" is a direct substitution, not a regex
  replacement, so that specific no-op failure mode does not transfer; the harness must still invoke
  the real guard expression by reference rather than a re-typed copy.

### VAC-03 — six-shape taxonomy checklist mechanism

- **D-15:** The mechanism is a **required `vacuity_taxonomy` section in each phase's
  VERIFICATION.md**, for Phases 169, 171, 172, 173, 174 and 175. For each new check the phase
  landed, it records: the check ID, which of the six shapes it maps to (or an explicit "matches none
  of A–F, because ___"), and a D-23-style **measured** non-vacuity fact. Never a bare yes/no tick —
  a boolean asserted without inspecting what is inside it is Shape A restated at the process layer,
  and would make this phase ship an instance of its own target defect.
  — **Reversibility:** reversible — a planning-artifact template convention.

- **D-16:** **The ROSTER/DONE property is the point.** A phase that landed no new checks must
  **state that explicitly** in the section rather than omitting it, so "there was nothing to check"
  and "we forgot" are never indistinguishable. This is the direct process analogue of Phase 169's
  D-02/D-04: completeness is a positive assertion, never an inference from absence. An auditor can
  then grep every phase's VERIFICATION.md for the section's presence and get a decidable answer.

- **D-17:** Applied by the **phase-close verifier** — not by the executor at plan time (too early;
  a check's shape can still change during execution) and not by a PR reviewer (nothing durably
  records a PR-time judgment across six phases, one of which is already merged). VERIFICATION.md's
  frontmatter contract already gates phase closure, so the field cannot be skipped silently. The
  checklist-design evidence supports this: the mechanisms that produce real scrutiny (Gawande's
  DO-CONFIRM pause point with a designated caller, Google's PRR, Kubernetes KEP graduation criteria)
  all write the answer into the artifact that already gates a state transition; the ones that decay
  into ritual ticking (un-required PR templates, Definition-of-Done checkboxes) do not.

- **D-18:** Taxonomy content is single-sourced at `.planning/research/v23/PITFALLS.md` §"Pitfall 4"
  (Shapes A–F). VERIFICATION.md **links, never copies** — Phase 169's D-16 rule.

- **D-19:** Phase 169 is covered **retroactively via a scoped addendum**, not by editing its already
  closed VERIFICATION.md artifact.

- **D-20:** This is a `.planning/` convention only. No change to `lib/`, `script/`, or
  `.github/workflows/` is made for VAC-03, which satisfies SC#4's "a review checklist item applied
  at the close of each of those phases, not a code change owned by this phase itself." A PR template
  or CONTRIBUTING item was considered and rejected as the primary surface: this repo has no PR
  template convention today, it cannot reach the already-merged Phase 169, and an un-required
  checkbox carries no evidentiary weight. It remains acceptable as a supplementary reminder if a
  later phase wants one.

- **D-21:** The `vacuity_taxonomy` field **outlives this milestone**. VACG-01, when it lands,
  mechanically supersedes Shape A only; Shapes B–F (a job `needs:` something that skipped,
  `continue-on-error` on a lane feeding a one-way door, `if:` conditions that never match, a matrix
  expanding to zero entries, missing `set -e` / misused `grep -q` / `jq -e`) have no proposed
  automated guard at all. Narrow the field to the five remaining shapes at that point; do not retire
  it.

### Claude's Discretion

- The snapshot file's concrete serialization (JSON vs. a deterministic `.exs` term vs. a sorted
  table) and where it lives, provided it diffs legibly in review and the ledger test reads it back
  without re-deriving classifications.
- The exact normalization applied before hashing (D-05), provided pure reformatting produces no
  churn and a genuine expression change always does.
- Whether the itemized structural test (D-12.1) lives in `test/crosswake/proof/` alongside the
  existing `phaseNN_*` corpus or beside the inventory script, and how its entries are expressed.
- Plan decomposition and wave ordering — the classification pass, the rewrites, the proof tests and
  the VAC-03 template change are separable and have no hard ordering constraint between the last two.
- Whether the retroactive Phase 169 addendum (D-19) is its own file or a section appended to a
  phase-170 artifact.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### The defect class and its taxonomy
- `.planning/seeds/SEED-018-vacuous-collection-assertions.md` — the originating seed: the 173-site
  finding, the five independent v22.0 occurrences, and its own sequencing argument for why the guard
  must come AFTER the audit. Its grep-derived count is corrected by `<verified_ground_truth>` above.
- `.planning/research/v23/PITFALLS.md` §"Pitfall 4" — **the six-shape vacuity taxonomy (Shapes A–F)**
  with per-shape detection and fix recipes, and the shape→phase mapping that bounds D-02. This is
  the single source of truth D-18 links to; do not copy its content elsewhere.
- `.planning/research/v23/SUMMARY.md` — adjudicated milestone decision set and build order.
- `.planning/research/v23/DX.md` — developer-experience direction and message shapes for v23.0.

### Phase requirements and criteria
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` §"Phase 170: Vacuous Assertion
  Remediation" — goal, dependencies, and the four success criteria. **SC#1's "173" is restated to
  220 by D-01/D-03**; the roadmap text itself is deliberately left unedited.
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — VAC-01, VAC-02, VAC-03 are this
  phase's requirements; `:93` defines VACG-01 and why it is deferred.
- `.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-CONTEXT.md` —
  the immediately prior phase's locked decisions. Load-bearing here: **D-04** (`roster_exact`, the
  regenerate-and-diff-exact anti-rot pattern D-04/D-06 reuse), **D-02** (ROSTER/DONE — completeness
  as a positive assertion, the model for D-16), **D-16** (documentation single-sourced; link, never
  copy), **D-23** (measure a check's real findings before trusting it; that number IS the
  non-vacuity proof — the basis for D-14), **D-24** (a guard test that reads entry points and
  asserts literal values so a contract cannot drift), and the `<verified_ground_truth>` precedent
  for handling an arithmetically-wrong success criterion.
- `.planning/workstreams/quality-ratchet-release/phases/169-diagnostic-legibility/169-VERIFICATION.md`
  — the frontmatter contract D-15's new section extends, and the artifact D-19's addendum covers.

### Code the phase reads or changes
- `script/check_absence_is_not_success.exs` — the existing two-check scanner. Its narrow-by-design
  philosophy, its `@mutation_hint` heredoc documenting the capture-group-10 burn (D-14), its
  `stale_citations/1` check (the direct ancestor of the `file:line` anti-pattern D-04 rejects), and
  its `[crosswake] FAIL: / where: / what:` output style. **This file is NOT modified by this phase**
  (D-13).
- `test/` — 42 flagged files. The 29 unguarded `assert Enum.all?` sites and the release-critical
  `refute Enum.any?` sites are enumerated in `<verified_ground_truth>`.
- `test/crosswake/release_candidate/cleanroom_test.exs`, `test/mix/tasks/crosswake_release_status_test.exs`,
  `test/crosswake/release_candidate/coordinate_test.exs`, `test/crosswake/release_candidate/mirror_test.exs`
  — the release-graph test files inside Phase 175's blast radius; the reason D-01 widens the set.
- `test/crosswake/proof/` — the existing `phaseNN_*_test.exs` corpus asserting properties of the
  repository itself; the home idiom for D-12.1's structural test.

### Voice and engineering DNA
- `brandbook/BRAND-SPEC.md` — governs microcopy voice (calm, specific, actionable; no drama).
  **Supersedes `prompts/crosswake-brand-book.md`** — do not use the stale copy.
- `prompts/crosswake-elixir-oss-dna.md`, `prompts/ARCHITECTURE-CODE-WALKTHROUGH-DNA.md` — project
  engineering DNA and Elixir idiom; the basis for D-10's preference for stdlib ExUnit assertions
  over a bespoke house macro.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Phase 169's `release.scanner.roster_exact` (D-04)** — the regenerate-and-assert-exact-equality
  pattern is already designed, argued and landed in this repo one phase ago. D-04/D-06 are that
  pattern applied one level down, at call sites instead of check IDs. Reuse the shape and the
  reasoning; do not reinvent either.
- **`script/check_absence_is_not_success.exs`'s `@mutation_hint` / `@citation_hint` heredoc style** —
  the established way this repo teaches a reviewer WHY at the moment of failure. The ledger test's
  failure message should follow it.
- **The `[crosswake] …` + "What to do next:" house style** — already established across the shell
  and `.exs` verifiers. The ledger-stale message follows it, e.g.:
  `[crosswake] FAIL: the committed classification snapshot has 1 site not yet classified and 0 orphan rows.`
  `[crosswake] What to do next: run the inventory script, classify the new row with a one-line rationale, and commit the updated snapshot.`
- **VERIFICATION.md's existing frontmatter contract** (`covered_files`, `deferred`,
  `overrides_applied`) — D-15's `vacuity_taxonomy` section extends an existing gating mechanism
  rather than inventing a new one.

### Established Patterns
- **`assert` is a macro that rewrites the AST to build a good failure message.** `assert Enum.all?(coll, f)`
  defeats that entirely — it collapses to a bare boolean and prints "Expected truthy, got false" with
  no indication of which element failed or why. This is a real DX defect aligned with this
  milestone's legibility thesis, and it is **deliberately deferred** (see Deferred Ideas) because
  fixing it would roughly double the blast radius of the change VAC-01/VAC-02 actually ask for.
- **Exact-list equality as an implicit cardinality guard** — `assert Enum.map(coll, & &1.id) == [<literal>]`
  appears in at least 5 of the flagged sites and already makes emptiness impossible. Any guard
  detector must recognize this shape or it manufactures false positives (D-07's
  `safe-cardinality-pinned` bucket).
- **Narrow-by-design scanners.** Both checks in `check_absence_is_not_success.exs` landed with fewer
  than five real findings and were fixed in the same change that introduced them. A guard with 173
  findings gets waived, and a waived guard is worth less than no guard. This is the whole reason for
  the audit-then-guard ordering, and it constrains D-13.

### Integration Points
- The inventory script joins `script/`'s existing verifier family but is **not** registered as a
  merge-blocking check and is **not** added to `check_absence_is_not_success.exs` (D-13).
- The ledger test and the structural test join the ordinary `mix test` suite, green in CI like every
  other test — which is what keeps SC#3 satisfied.
- The `vacuity_taxonomy` section touches only the phase-close VERIFICATION.md template and the
  retroactive 169 addendum; no runtime, script, or workflow surface (D-20).

</code_context>

<specifics>
## Specific Ideas

- The maintainer asked for one coherent, opinionated recommendation set rather than sequential
  per-area questions, and locked all four areas in a single pass. Treat D-01 through D-21 as a
  mutually-consistent set: in particular D-04 (a tree-wide inventory) and D-13 (no tree-wide
  enforcement) are only compatible because of D-06's line — completeness of the ledger is asserted,
  guardedness of the tree is not. Do not "simplify" by collapsing them.
- The four decisive precedents, all verifiable: Phase 169's D-04 for regenerate-and-diff;
  Sobelow's `.sobelow-skips` and PHPStan/Psalm baselines for content-hash keys over line numbers;
  RuboCop's `--auto-gen-config` for regenerate-don't-hand-edit (but NOT for key stability — it
  counts per-cop-per-file, too coarse for per-site classification); Gawande's DO-CONFIRM pause point
  plus Google PRR / Kubernetes KEP graduation criteria for a checklist that produces real scrutiny.
- Named footguns to design against, each from a real project: baseline rot (RuboCop todo files that
  only ever grow — mitigated by D-08's explicit sunset); suppressions outliving their reason
  (ESLint/mypy baselines with no "why" — mitigated by D-07's mandatory rationale string); hash churn
  on reformatting (Psalm — mitigated by D-05's normalization); checklist ritual-ticking (the WHO
  surgical checklist sites that showed no effect were those without verbal challenge-response —
  mitigated by D-16's explicit null-statement requirement).
- Jest's `expect.assertions(n)` / `expect.hasAssertions()` is the widely-copied cross-language answer
  to the same "a test body that asserted nothing" problem, and pytest's assertion rewriting is the
  precedent for per-element failure detail. Both inform the deferred DX item, not this phase.

</specifics>

<deferred>
## Deferred Ideas

- **`Enum.all?`'s boolean-collapse failure message** — rewriting `assert Enum.all?(coll, f)` as
  `Enum.each(coll, &assert(...))` plus a count assertion would make a failure name the offending
  element instead of printing "Expected truthy, got false." A real problem, squarely aligned with
  this milestone's diagnostic-legibility thesis, but it roughly doubles the diff on every site,
  changes the failure shape of every assertion, and introduces short-circuit/ordering differences
  (`Enum.all?` short-circuits; `Enum.each` does not) — for a concern neither VAC-01 nor VAC-02 asks
  for. Capture as its own seed referencing this research.
- **VACG-01 (`absence.collection_assertion_non_empty` as a merge-blocking guard)** — already tracked
  under Future Requirements, and its absence from this milestone is success criterion #3. When it
  lands, lift the inventory script's detection core into it and delete the snapshot and diff test
  per D-08.
- **Amending ROADMAP.md SC#1's "173" to 220, and REQUIREMENTS.md VAC-01's wording** — the correction
  is recorded in `<verified_ground_truth>` and D-01 so the planner implements the true state;
  whether to edit the roadmap text is a separate call, exactly as Phase 169 left its own SC#2/SC#3
  corrections (D-03).
- **A PR template / CONTRIBUTING checklist item for the six shapes** — rejected as the primary VAC-03
  surface (D-20) but acceptable later as a supplementary reminder, once a PR-template convention
  exists in this repo at all.
- **Vacuity Shapes B–F** — owned by Phases 171 (Shape D), 173 (Shape B), 174 (Shape C) and the
  cross-cutting D-15 checklist (Shape F). Explicitly not this phase (D-02).

</deferred>

---

*Phase: 170-vacuous-assertion-remediation*
*Context gathered: 2026-09-16*
