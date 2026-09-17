# Pitfalls Research: v23.0 Release Pipeline Repair & Proof-Lane Truth

**Domain:** Generalizing an exact, approval-gated multi-registry release graph (Elixir/Hex core + Hex
companions + SwiftPM mirror + Maven), and making a post-publication byte-exact proof lane run for the
first time.
**Researched:** 2026-09-15
**Confidence:** HIGH on repo-specific findings (drawn directly from TODO-009/010/011/012, SEED-003/004/007/017/018,
`release_status.ex`, `verify_companion_cleanroom.sh`, `check_release_workflow_integrity.exs`); MEDIUM on
named-incident analogies (public, well-documented, but pattern-matched rather than code-read against
Crosswake).

Lens tags: **[SRE]** incident-reviewer, **[SEC]** supply-chain, **[TEST]** verification engineer,
**[ELX]** Elixir/Hex maintainer, **[DX]** maintainer debugging cost.

---

## Critical Pitfalls

### Pitfall 1: Generalizing version while leaving authority as the sole remaining gate

**What goes wrong:** `.github/workflows/release-please.yml` currently gates `publish-hex`,
`publish-ios-core`, `publish-android-core`, and `exact-public-proof` on
`needs.release-please.outputs.version == '0.2.1'`. Removing that literal so any version can publish,
without replacing what it was silently *also* doing — binding the publish to one specific approved
merge — leaves `linked_release` (or equivalent) as the only gate. `linked_release` answers "did
release-please compute a release for this push," not "was this exact head/tree/base approved by the
Phase 168 candidate-receipt machinery." Those are different claims, and the version literal was
accidentally standing in for the second one.

**Why it happens [SRE]:** The literal reads as a version check, so a generalization instinct treats it
as *only* a version check and deletes it wholesale. The authority binding was implicit — riding along
on the fact that only 0.2.1 was ever approved — so there is no separate line of code whose removal
would visibly break authority. The coupling is invisible until it's gone.

**Subtler versions of the same mistake (asked for explicitly in the brief):**
- **Widening the `@coordinates`/`@children`/`@dependencies` pins in `workflow.ex` to be
  version-parameterized without also parameterizing the candidate-receipt artifact name.** The receipt
  is currently named for a specific run/head; if the download step is generalized to "latest receipt"
  instead of "the receipt for *this* release's approved head," a stale or wrong receipt can satisfy the
  `needs:` and the identity gate becomes a rubber stamp.
- **Generalizing the `approved-release-guard`'s `grep -q '@version "0.2.1"'` into `grep -q '@version'`
  (any version present)** rather than "the declared manifest version and the approved-receipt version
  match, and the receipt's head/tree/base match the merge being published." Presence of *a* version
  string is not the same claim as "this version was the one approved."
- **Reusing the interim tripwire's comparison (`manifest version == gate literal`) as the permanent
  authority check.** The tripwire in `check_release_workflow_integrity.exs` was explicitly built to
  catch drift between a *hardcoded* gate and the manifest — it is a scaffold for the current defect,
  not a substitute for per-release identity binding. TODO-009 says to retire it, not promote it.
- **Letting recovery-path publishes (which is how 0.2.1 actually shipped) converge on the ordinary
  graph by weakening what "ordinary" requires,** rather than by making recovery independently satisfy
  the same identity binding. TODO-009's second gap: `exact-public-proof` `needs:` the ordinary
  `publish-*` jobs, so recovery publishes skip it entirely. The naive "fix" — dropping the `needs:` so
  the proof always attempts to run — must not silently accept an unapproved recovery publish as
  legitimate; the proof needs its own approved-manifest input regardless of which path published.

**Prevention:** Replace the version literal with an explicit **per-release identity struct** (approved
head SHA + tree SHA + base SHA + candidate-receipt digest), computed once by the same actor that
computes the version, and require every publish job and the proof job to check *that* struct rather
than a version string. Keep `Workflow.rollup!/1`'s "skipped ≠ success" property explicitly under test
(a regression test that asserts a graph with any job `skipped` never rolls up `COMPLETE`). Add a
`check_release_workflow_integrity.exs` check asserting **no publish or proof job's `if:` condition
contains a bare version-shaped string literal** (regex for `\d+\.\d+\.\d+` inside an `if:` line) —
this is a durable structural guard, not a value comparison, so it survives future version bumps without
being re-authored per release.

**Warning sign:** A publish job's `if:` condition compiles to true for *any* version once the literal
is removed, with nothing else in the condition referencing an approval artifact. Also: the
candidate-receipt artifact name pattern is generalized before its consumer (the download step) is
checked for correctness against multiple concurrent or historical releases.

**Phase to address:** The phase that retires the version weld (closing TODO-009/SEED-017) — this is the
core generalization work and must land the identity-binding replacement in the same change that deletes
the literal, not as a follow-up.

---

### Pitfall 2: Weakening a guard to make a harness pass ("the harness is wrong" vs "the contract is wrong")

**What goes wrong:** Two concrete, named temptations exist right now:

1. **`doctor`'s `manifest_contract` check**, which requires a compiled manifest to have a `:routes`
   section, blocking on the clean-room host because that host's router stub deliberately has zero
   routes (TODO-011). The tempting "fix" is to make `manifest_contract` tolerant of a routeless host —
   i.e., change the contract everything else in the repo depends on, to make one under-built test
   harness pass.
2. **The `release.version_weld.gates_match_declared_version` tripwire** — once a new version is
   generalized, the naive path to a "green" migration is to adjust the tripwire's comparison (e.g.
   compare against a wildcard, or drop the failing branch) so a bumped manifest reads as compliant,
   instead of fixing the underlying weld it was built to catch.

**Why teams do it anyway [DX] [SRE]:** Both are the path of least resistance under time pressure: the
red is in a script/task the engineer didn't just write, feels tangential to the actual milestone goal
("I'm generalizing a release graph, why do I care that doctor wants routes?"), and the fix-the-harness
direction is usually *fewer lines*. There is also a subtler trap: TODO-011's own harness comment already
records the mistaken assumption ("no routes required — Open Question 1") as if it had been a deliberate,
reviewed decision, which makes it easy for a future contributor to trust the comment instead of
re-deriving whether it's true. A stale rationale comment is more persuasive than an absent one.

**Structural pressure that prevents it (what to build, not just what to avoid):**
- **TODO-011 and TODO-009 both explicitly name the forbidden move and the required decision process**
  ("do not guess it" / "do not weaken X to accommodate Y without deciding Z deliberately"). Roadmap
  phases should require an explicit, recorded decision artifact (a SUMMARY or DECISIONS entry) any time
  a guard's assertion changes, distinct from ordinary code-review approval — i.e., weakening any check
  under `script/check_*` or `lib/crosswake/doctor` requires citing *which* of the two repair paths was
  chosen and why, not just a green CI run.
- **Make the two repair paths genuinely available and comparably costed up front**, so "weaken the
  guard" isn't the only path that fits in the time box. For TODO-011 specifically: budget for making the
  clean-room host realistic (real route + `mix crosswake.install`) as the *default* plan, with "scope
  doctor's route requirement" requiring a named owner sign-off because it touches a contract other
  phases depend on.
- **A guard that changes should require a companion test proving the *old* violation still fails.**
  i.e., when editing `manifest_contract`, add/keep a test asserting a genuinely routeless production
  manifest is still rejected — this makes "I widened the contract to let the harness through" and "I
  fixed the harness" produce different, observable test outcomes instead of both just going green.
- **Named-incident lesson [SEC]:** this is structurally the same failure as weakening a lockfile
  integrity check to unblock a build — e.g., teams disabling `npm audit` or pinning around a flagged
  transitive dependency instead of fixing the actual vulnerable graph after the `event-stream` incident
  (a malicious maintainer added a dependency that exfiltrated wallet keys; the review pressure that let
  it in was exactly "make CI green, don't interrogate why"). The general lesson Crosswake should copy:
  treat "make the check pass" and "make the thing the check protects true" as different tasks with
  different reviewers.

**Warning sign:** A diff that touches `lib/crosswake/doctor/doctor.ex` or
`script/check_release_workflow_integrity.exs` in the same commit as a "make CI green" changelog line,
with no corresponding SUMMARY/DECISIONS explanation of which repair path was chosen.

**Phase to address:** The phase closing TODO-011 (companion clean-room realism) must record the
decision explicitly (recommended: harden the host, per TODO-011's own recommendation) before code
lands. The phase retiring the version-weld tripwire must delete it as part of the SEED-017 fix, never
edit its comparison logic to keep it green.

---

### Pitfall 3: The right failure carrying the wrong explanation

**What goes wrong:** This already happened, live, on PR #164. The version-weld tripwire correctly
failed CI. But the surfaced failure message — from `release-candidate-fixtures` /
`Crosswake.ReleaseStatus.scanner_ids_result/2` — reads:

```
root/native publish jobs are not exact path-gated: missing scanner IDs:
release.outputs.paths_released, release.root_hex.path_gate, ...
```

It never mentions the weld, the declared version, or SEED-017. `scanner_ids_result/2`
(`lib/crosswake/release_status.ex:806-820`) classifies *any* scanner that exited non-zero uniformly as
"missing IDs" — i.e. it conflates "the scanner didn't run / its expected check IDs are absent from the
output" with "the scanner ran, found a real problem, and reported it." The failing check's own,
carefully worded message (which correctly names the weld) is discarded exactly where a maintainer needs
it.

**Why it happens [TEST]:** `scanner_ids_result/2`'s `%{status: :failed, checks: checks}` clause computes
`missing` (required IDs not present as keys) and `failing` (present keys with `status: :error`) and
prioritizes `missing != []` in its `cond`. When a scanner's failure mode causes *some* of its own checks
to not populate `checks` at all (e.g. because the scanner short-circuits after finding the weld and
never gets to run the path-gate assertions it also owns), the presentation layer sees "these IDs are
absent" and reports absence — even though the scanner in fact ran and did have something specific to say.
The bug is a **classification-priority bug**: absence-of-key and failure-with-message look identical
to the consumer once the underlying script exits non-zero, unless the harness is careful to always
populate every ID it's responsible for, with a status, even on early-exit.

**How this differs from "absence scored as success":** the build does go red — this is not a false
green. It is a **true positive with a false diagnosis**, which is arguably more expensive per
occurrence: it costs the same debugging hour, but it also actively misdirects toward the wrong culprit
("the scanner must be broken") rather than toward the wrong artifact ("nothing published"). Both belong
in the same taxonomy of trust-eroding CI behavior, but the fix differs: absence-scored-as-success needs
a non-emptiness assertion; wrong-explanation needs a message/identity pass-through fix.

**Detection recipe [TEST]:**
1. For every scanner/check aggregator (`scanner_ids_result/2` and any sibling), grep for the shape
   `Enum.reject(required_ids, &Map.has_key?(checks, &1))` combined with a `cond` that checks `missing`
   before `failing`. That ordering is the smoking gun: it means a scanner that fails *after* partially
   populating its own checks map will report "missing" instead of "failing."
2. Add a targeted test: run the real failing scanner (or a fixture reproducing its exact partial output)
   through `scanner_ids_result/2` and assert the returned `evidence`/message **contains the scanner's own
   failure text**, not just a synthesized "missing scanner IDs" string.
3. As a structural fix, require every scanner contract to emit a status for *every* ID it owns on every
   exit path (including early-exit-on-first-failure), so `missing` is only ever true when the scanner
   genuinely never ran (e.g. binary not found) — never when it ran and failed early.

**Prevention:** Fix `scanner_ids_result/2` to propagate the failing scanner's own message and check IDs
whenever any output was produced, reserving the "missing scanner IDs" message strictly for the
zero-output case (scanner crashed before producing any check at all). TODO-009 already scopes this
fold-in explicitly — do not let it slip to a future seed; it is cheap and high-value.

**Phase to address:** Same phase as TODO-009/SEED-017 (explicitly folded in by the TODO itself).

---

### Pitfall 4: Vacuous assertions / absence scored as success — the taxonomy and detection recipes

This is the project's own documented recurring defect class (v22.0 retrospective; SEED-018 catalogs
five independent occurrences in one milestone, four of which were green for months). Treat every shape
below as a first-class code-review checklist item for v23.0, not a one-off cleanup.

**Shape A — `Enum.all?`/`Enum.any?` on a runtime-derived, possibly-empty collection.**
`Enum.all?([], fn _ -> false end)` is `true`. SEED-018 found 173 such call sites, unaudited.
- *Detect:* `grep -rnE 'assert Enum\.(all\?|any\?)' test --include='*.exs'`, then classify each by
  whether its collection is a literal/fixture (safe) or derived from `Path.wildcard`, `File.read!`,
  `Regex.scan`, `Enum.filter`, or an HTTP/registry fetch (suspect).
- *Fix shape:* precede the `Enum.all?` assertion with an explicit non-emptiness assertion:
  `assert [_ | _] = collection` or `refute Enum.empty?(collection)`. This makes "found nothing" a
  distinct, visible failure rather than a silent pass.
- *Guard (only after remediation, per SEED-018's own sequencing advice):*
  `absence.collection_assertion_non_empty` in `check_absence_is_not_success.exs`, scoped to the
  runtime-derived-collection subset — landing it before remediation produces 173 red findings that get
  waived, which teaches the team red is negotiable (SEED-018's own stated risk).

**Shape B — a job that `needs:` something that skipped.** Exactly `exact-public-proof`'s current
defect: it `needs: publish-hex, publish-ios-core, publish-android-core`, so when those are skipped
(version mismatch) or take the recovery path (never run at all), the proof also skips — and GitHub
Actions reports a skipped `needs:`-dependent job as neutral, not failing, unless the workflow explicitly
checks `needs.*.result`.
- *Detect:* any job whose only gate is a bare `needs:` list with no `if: needs.X.result == 'success'`
  (or a check that a skip is itself a failure) alongside a downstream aggregator that would report
  `PARTIAL` correctly (as Crosswake's `rollup!/1` does) but only if the rollup is even wired to see that
  job — verify the rollup can distinguish "skipped because upstream skipped" from "ran and passed."
- *Fix shape:* the rollup must classify `skipped` as `!= success` (already true here, per
  `Workflow.rollup!/1` — preserve it under an explicit regression test), and any human-facing status
  surface (like `ReleaseStatus`) must render `skipped` distinctly from both `passed` and `failed`, not
  collapse it into "not yet run."

**Shape C — `continue-on-error: true` on anything that gates a one-way door.** Not currently observed
verbatim in the release graph per the required reading, but the advisory clean-room lanes are the
adjacent risk: TODO-011 notes they're `needs: publish-hex-*` so they run *after* the irreversible
publish and "a red proof costs nothing at the moment it matters." Any `continue-on-error: true` or
advisory-only lane touching a one-way-door step should be treated as Shape C by default.
- *Detect:* `grep -rn 'continue-on-error' .github/workflows/`, cross-reference against jobs positioned
  after a `publish-*`/`mirror-*`/`hex.publish` step.
- *Fix shape:* either promote to required once green (TODO-011's option 3), or ensure the
  advisory-failure path produces an *undismissable* signal distinct from routine noise (TODO-011 option
  3's alternative: make `release-failure-alert` distinguish "harness bug" from "package unresolvable" —
  this is itself another instance of Pitfall 3, wrong-explanation, at the alerting layer).

**Shape D — `if:` conditions that silently never match.** The exact defect TODO-009 targets: `if:
needs.release-please.outputs.version == '0.2.1'` never matches for 0.2.2+, and the job simply vanishes
from the run rather than appearing as a red X.
- *Detect:* `check_release_workflow_integrity.exs`'s proposed "no bare version literal in a publish/proof
  gate `if:`" check (already scoped in SEED-017 breadcrumbs) generalizes to: grep every `if:` line for
  literal values that come from a config/manifest file elsewhere in the repo, and assert the workflow
  reads that value dynamically (`needs.X.outputs.Y`) rather than hardcoding it.
- *Fix shape:* replace hardcoded comparisons with dynamic derivation from the same source of truth
  (`.release-please-manifest.json`), and add a coverage test (as TODO-009 did with
  `phase168_release_version_weld_test.exs`) that fails when a new version-gated job appears without the
  dynamic pattern.

**Shape E — a matrix that expands to zero entries.** Not directly evidenced in the required reading, but
structurally identical to Shape D: a `strategy.matrix` computed from a dynamic `fromJSON` expression that
evaluates to `[]` produces zero job runs, no red, and a `needs:`-dependent job sees an empty-but-successful
upstream.
- *Detect:* any workflow computing a matrix from a script/`jq` output rather than a literal list; add an
  explicit assertion step (or a required "matrix-was-non-empty" check) immediately after matrix
  computation.
- *Fix shape:* the matrix-generation step should itself assert `length(matrix) > 0` and fail loudly
  otherwise, mirroring the Shape A fix (non-emptiness before use).

**Shape F — `set -e` not set in a shell step, `grep -q` on empty input, `jq -e` misuse.**
`verify_companion_cleanroom.sh` is the load-bearing example here and is mostly done right (it fails
closed on partial registry fetch, TODO-010), but the pattern to hold the line on generally:
- `grep -q pattern <<< "$maybe_empty_var"` returns non-zero (correctly) on empty input for most
  patterns, but a pattern like `grep -qE '.*'` matches an empty string as true — audit for any
  `grep -q` whose pattern could match zero-length input.
- `jq -e` (exit non-zero on `null`/`false`) is the right idiom and Crosswake's own script uses it
  correctly at `MATRIX_APPROVED_MANIFEST` parsing (`jq -er 'map(.candidate_ref) | unique | if length
  == 1 then .[0] else error(...) end'`) — this is the pattern to copy: `if`/`else error(...)` rather
  than trusting a bare `jq` filter's truthiness.
- Any bash script driving a one-way-door step must have `set -euo pipefail` at the top; audit every
  script under `script/release_candidate/` and every `run:` block that shells into `mix hex.publish`,
  `git push --tags`, or the splitsh mirror push for this explicitly — a silently-continuing pipeline
  after a failed intermediate command in a *publish* script is the highest-consequence instance of this
  whole category.

**Phase to address:** Shapes A/B/D map directly to the SEED-017/TODO-009 phase (release graph). Shape C
maps to the TODO-011 phase (clean-room realism / promotion decision). Shape F is a cross-cutting audit
that should be a checklist item inside whichever phase touches any publish-path shell script — do not
defer it to a separate "harden shell scripts" phase where it will compete for priority and lose.

---

### Pitfall 5: Treating a real 0.2.2 (plus held companion PRs #147/#115) as the first exercise of the repaired graph

**What goes wrong:** Once SEED-017 is closed, the obvious next step is "now merge #164 (0.2.2)." But
that PR is the very first real transaction through machinery that has never fired for any version other
than 0.2.1, and the held companion PRs (#147 `crosswake_rulestead 0.1.1`, #115 `crosswake_chimeway
0.1.1`) are independently a first live exercise of "publish a companion once the clean-room lane is
supposed to be green." Using an irreversible, real publish as integration test #1 for repaired machinery
compounds two risks that would otherwise be independent: a graph bug and a Hex-immutable mistake happen
in the same event, with no rollback for either.

**Why a *fake* one-way door doesn't help:** Hex, SwiftPM tags, and Maven are immutable by design (D-19);
there is no sanctioned "yank and retry cleanly" path that doesn't leave residue (Hex `retire`, not
delete; a yanked crates.io equivalent still shows in the index; a bad SwiftPM tag either has to be a new
tag or an explicit force-push warning to consumers). Building a "fake" registry to rehearse against loses
exactly the properties under test (multi-registry partial-failure behavior, the mirror's credential
scoping, the candidate-receipt digest math against real Hex tarball bytes).

**What rehearsal reduces the risk without a fake door:**
- **Dry-run to the last safe step.** Every job up to and including `mix hex.build` (not `hex.publish`),
  the SwiftPM `splitsh-lite` subtree extraction (not the tag push), and the Maven artifact assembly (not
  `./gradlew publish`) can run for real, against real inputs, with real credentials scoped read-only,
  and be inspected byte-for-byte. This exercises 90%+ of the new graph logic (version derivation,
  identity binding, path gating) without crossing the actual door.
- **Publish to a scratch/throwaway Hex organization or a locally-hosted Hex-compatible registry** (e.g.
  a self-hosted `hexpm`-compatible mirror, or `mix hex.publish --dry-run` where supported) for the
  *shape* of the multi-package graph, reserving the real `hex.pm` publish for the already-rehearsed
  final step.
- **Sequence the two held companion PRs and 0.2.2 so the lowest-blast-radius one goes first.** Per
  STATE.md's own triage, #147/#115 are independently versioned (D-15/D-16) and therefore *not*
  weld-blocked — but per TODO-011/TODO-012 the post-publish proof for companions is structurally broken
  today. The lowest-risk sequencing is: (1) fix and rehearse the graph and the clean-room lane against
  dry-run-only artifacts, (2) publish exactly one companion (smallest blast radius, e.g. whichever of
  #147/#115 has the fewest downstream consumers) as the live fire-drill for the repaired clean-room
  lane, (3) only then attempt 0.2.2, which is higher blast radius because it's core and re-exercises the
  full version-generalized graph end to end.
- **Explicit rollback plan authored *before* the first real publish**, not improvised after: for Hex,
  `mix hex.retire` (not delete) plus a same-day patch release if the artifact is bad; for the SwiftPM
  mirror, a documented "tag was wrong, next tag supersedes it, README notes the retraction" runbook; for
  Maven, the same retire-forward pattern (Maven Central has no delete either, post-OSSRH-sunset the new
  Central Portal is equally immutable). Write this runbook as a phase deliverable, not tribal knowledge.

**Phase to address:** A dedicated "rehearsal" phase (or an explicit rehearsal task inside the graph-repair
phase) must precede the phase that actually merges #164/#147/#115. Do not let "the graph is fixed" and
"we shipped 0.2.2" land in the same phase/plan — the roadmap should force a checkpoint between them.

---

## Moderate Pitfalls

### Pitfall 6: Multi-registry partial publication — the failure matrix

Crosswake publishes to three registries (Hex for Elixir packages, a SwiftPM mirror repo via
`splitsh-lite` subtree + tag push, Maven Central for Android) from one release transaction, plus a
post-publish clean-room proof. This has already partially failed once, exactly as feared: core 0.2.0
published to Hex and Maven but the iOS mirror push 403'd (SEED-003) because the job used the default
`github-actions[bot]` `GITHUB_TOKEN`, which has no cross-repo write access — "rotate the token" (i.e.
regenerate the same *default* token) is not a fix, because the default token was never in scope for the
mirror repo; the actual fix is a distinct PAT/fine-grained-token/App-installation-token with explicit
push scope to the separate mirror repo.

**The partial-failure matrix and correct response per cell:**

| Hex | iOS mirror | Maven | Correct response |
|---|---|---|---|
| ✅ | ✅ | ✅ | Full success — proceed to post-publish proof. |
| ✅ | ❌ (SEED-003 case) | ✅ | **Do not retry Hex/Maven.** They are one-way doors that already succeeded; retrying `mix hex.publish` on the same version is either a no-op-with-warning or an error, never a "redo." Fix the mirror credential/lineage issue and **backfill**: re-run just the mirror job for the already-published version (splitsh-lite + tag push at the correct commit), do not cut a new version to paper over a mirror-only gap. |
| ✅ | ✅ | ❌ | Same principle mirrored: Maven publish failures (signing key rotation, Sonatype/Central Portal outage, GPG key expiry) get a targeted retry of the Maven job only, at the same coordinates, never a version bump. |
| ❌ | — | — | Nothing published; safe to fully retry after fixing root cause (Hex publish failed before any bytes were immutable). This is the *cheap* cell — treat it as "recovery," not "repair." |
| ✅ | ✅/❌ | ✅/❌ **but the mirror is off-lineage `main`** | The specific armed fuse named in project memory: the iOS mirror repo's `main` can diverge from the subtree lineage `splitsh-lite` expects, so a push can *succeed* while landing on the wrong base — producing a tag that resolves to unexpected content for SwiftPM consumers. This is worse than a failed push because it's silently wrong, not loudly absent. Detection: after any mirror push, diff the pushed tree against the source subtree at the release commit, byte-for-byte, as an automated post-push check — do not trust push exit code 0 as sufficient. |
| ✅/partial | — | — | **Recovery-path publish** (how 0.2.1 actually shipped): some registries succeeded via the exact-ref recovery path rather than the ordinary graph. TODO-009's second gap applies — this path must independently trigger the post-publication proof, not silently skip it because it didn't go through `publish-*`. |

**Two armed fuses named explicitly in project memory (do not treat as resolved by rotating credentials
alone):** (1) checkout credential hijack — some workflow step checks out untrusted/PR-controlled code
with a token scoped for push access, creating a window where a malicious or accidental workflow change
could exfiltrate or misuse the mirror-push credential; (2) off-lineage `main` on the mirror repo, as
above. Both require review of the *workflow trust boundary* (what triggers the mirror push, what it
checks out, and with what token), not just "does the token have the right scope."

**Phase to address:** Any phase touching the mirror/Maven publish jobs must explicitly enumerate this
matrix in its plan and add the byte-for-byte post-push verification step; this is squarely inside the
"generalize the release graph" work since the mirror/Maven jobs are exactly the ones currently
version-welded alongside Hex.

---

### Pitfall 7: Byte-exactness traps in the proof lane

**What goes wrong (three concrete, evidenced failure modes):**

1. **Non-determinism in Hex tarball builds.** `Crosswake.ReleaseCandidate.Cleanroom` requires digest
   equality (`digest_mismatch`) between a locally-rebuilt tarball and the one Hex serves. Anything that
   makes `mix hex.build` non-reproducible — timestamps embedded in the tarball metadata, a `:files` glob
   that picks up build-order-dependent directory listings, compiled `.beam` artifacts accidentally
   included, or an OTP/Elixir *patch* version drift between build time and publish time — breaks this
   silently and looks identical to "the package changed" even when it didn't. Concretely mirrors the
   Homebrew bottle-reproducibility problem: bottles built on slightly different Xcode/SDK point releases
   produce different bytes for "the same" formula, which is a known, long-standing Homebrew CI pain
   point.
2. **Drift between a publish tag and HEAD.** TODO-012 measured this directly: `git diff <tag>..HEAD --
   packages/<pkg>` shows real file differences for 3 of 5 companions (chimeway 2 files, threadline 1,
   rulestead 3) even though nothing about their *published* version changed — ordinary repo evolution
   (docs, CI config, unrelated refactors sharing the package directory) drifts the tree out from under a
   tag that's supposed to represent immutable history.
3. **Rebuilding at a ref that no longer produces the published bytes.** The direct consequence of #2:
   there is no single ref — not the tag, not an older commit, not HEAD — that reproduces all six
   packages' published tarballs simultaneously, because they were published from six different commits
   over ten weeks. Reconstructing "one candidate ref for all six" is not merely hard, it's provably
   impossible given how the packages actually shipped (TODO-012's core finding).

**What must NOT be relaxed:** The digest-equality check itself. TODO-012 says this explicitly: "Do not
relax the digest equality check... loosening it turns the proof into a reachability check." A
reachability check (does `hex.pm/api/packages/X` 200?) is a fundamentally weaker claim than "the bytes
Hex serves are exactly what this ref would build," and silently downgrading from one to the other is
itself an instance of Pitfall 2 (weakening a guard to make a harness pass) applied to the proof's core
value proposition.

**What should change instead:** Per-package approved refs (TODO-012 option 2, recommended) — replace
the single `candidate_ref` requirement with one ref per manifest entry, preserving byte-exact comparison
per package while dropping the false assumption that all six ship from one linked transaction. This
matches D-15/D-16 (companions version independently) and the runbook's stated design.

**Named-incident parallel [SEC]:** Go's module checksum database (`sumdb`) exists precisely because
"the bytes at this ref/tag" can drift or be inconsistently served by different proxies/mirrors; a sumdb
mismatch is Go's version of exactly this class of failure, and its fix pattern (pin to a checksum
recorded at first-fetch time, treat any later mismatch as fail-closed and loud, never auto-heal) is the
template Crosswake's per-package approved-ref design should follow.

**Phase to address:** TODO-012's phase (exact-public proof redesign), sequenced after or alongside
TODO-009/SEED-017 since both touch the candidate-receipt/manifest shape.

---

### Pitfall 8: CI cost pressure produces "cheaper" proofs that are actually vacuous

**What goes wrong:** SEED-007 documents ~7h of runner time per push against an 88-second test suite,
dominated by macOS queue time (not compute) plus 39 copy-pasted workflow files. The natural response
under cost pressure — for a milestone literally about making an expensive proof lane finally *run* — is
to make the new/repaired proofs cheap by narrowing their scope, and narrowing scope is exactly how
Pitfalls 1, 2, and 4 get introduced: skip a package to keep the matrix small (TODO-010's forbidden
move), make the clean-room host minimal (TODO-011's actual root cause), or gate a proof behind
`continue-on-error` "for now" (Pitfall 4 / Shape C) to keep it off the critical path while iterating.

**Why this is a real tension, not a strawman:** the exact-public proof genuinely is expensive — it
fetches and rebuilds six Hex tarballs, computing SHA-256 digests, on every candidate. Multiplied across
however many packages get independent per-ref proofs (Pitfall 7's fix), the naive version of "prove
every companion byte-exactly on every release" scales with package count × release frequency, on
infrastructure already measured as mostly-waiting macOS queue time.

**Pitfalls in making proofs thorough without making them unaffordable:**
- **Do not conflate "runs on every PR" with "runs on every release."** SEED-007's own biggest finding is
  that most of the 7h is *PR-time* waste (documentation-only PRs burning 78 workflow runs) unrelated to
  release proofs at all. The exact-public/clean-room proofs already only run post-publish — keep that
  boundary explicit and don't let cost-cutting instinct pull release-time proofs into the PR-time
  budget, or vice versa (don't let "the release proof is slow" justify skipping it on PRs where it never
  ran anyway).
- **Cache what's cacheable without caching what must be exact.** SEED-007 found zero workflows cache
  `deps/`, and cache dimensions that omit the OTP/Elixir version (silently restoring incompatible BEAM
  files across a toolchain bump). The exact-public proof rebuilds real tarballs and must not cache the
  *build output* across toolchain versions — but it can cache `mix.lock`-keyed dependency fetches,
  since the correctness claim is about the package's own bytes, not about how fast dependencies were
  fetched.
- **Prefer per-package granularity over "one big proof job" even under cost pressure.** A single
  monolithic proof job that fails on package 3 of 6 and aborts obscures which packages are actually
  fine — SEED-007's own "preserve proof evidence granularity" decision (evidence classes stay separable
  even as workflow *files* consolidate) is the right pattern to reapply here: consolidate workflow
  files/runner classes, but keep named, individually-inspectable proof results per package.
- **Runner-class discipline specifically for this milestone's new/changed jobs:** SEED-007 found 14/18
  macOS PR jobs need no Apple toolchain at all. Any new proof job this milestone adds should default to
  `ubuntu-latest` unless it genuinely invokes `xcodebuild`/`splitsh-lite` against Apple-specific
  tooling — the iOS mirror parity check specifically was already identified as belonging on Linux.
  Getting this right at authoring time avoids adding to the exact queue-time problem SEED-007 exists to
  fix, in the same milestone that's supposed to be repairing trust in the release graph.

**Warning sign:** A PR description or plan that justifies scope-narrowing ("we'll only clean-room-proof
one companion for now," "we'll skip the byte-exact rebuild and just check resolvability") primarily by
citing CI cost/time rather than a deliberate, recorded design decision (as TODO-010/011/012 model).

**Phase to address:** Should be an explicit non-goal-boundary in whichever phase plan touches proof-lane
scope: state up front which packages/paths are proved byte-exactly vs. reachability-only, and require
that boundary be a decision artifact, not an emergent consequence of "we ran out of time/budget."

---

## Minor Pitfalls

### Pitfall 9: Stale rationale comments outlive the decision they recorded

**What goes wrong:** `crosswake_rindle`'s `mix.exs` trailing comment still says "independently versioned
from core 0.2.0," stale since the 0.2.1 restore (noted in TODO-010's breadcrumbs). The clean-room
harness's router-stub comment ("no routes required — Open Question 1") records an assumption as if
settled, and it was wrong (TODO-011). Comments that assert a design fact rather than linking to the
decision record that established it silently rot and actively mislead future contributors, exactly as
seen twice in the required reading.

**Prevention:** Any comment recording a non-obvious design assumption in a script/manifest touched by
this milestone should cite the decision ID (`D-NN`) or TODO/SEED it derives from, so staleness is
detectable by cross-referencing rather than by re-deriving the assumption from scratch (as TODO-011 had
to do).

**Phase to address:** Low-cost hygiene item to fold into whichever phase touches the affected files
(clean-room harness phase; rindle's `mix.exs` in the same phase that decides its family membership per
TODO-010).

### Pitfall 10: `--admin`/privileged merge paths bypass the graph they're meant to protect

**What goes wrong:** Project memory records that an `--admin` merge is refused in this repo, and that
dispatch-from-branch was needed to break a parity deadlock during the 0.2.1 recovery. Any repaired
release graph that still has an escape hatch (an admin override, a manual workflow_dispatch that skips
the identity-binding checks) reintroduces exactly the authority gap Pitfall 1 describes, via a side door
instead of the front door.

**Prevention:** Audit every `workflow_dispatch` trigger on the release workflow for whether it can reach
a publish job without recomputing the same identity binding the ordinary path requires. If a manual
dispatch path exists for recovery (as it apparently must, since 0.2.1 shipped via recovery), it must
independently satisfy — not bypass — the approved-manifest/candidate-receipt check.

**Phase to address:** Same phase as Pitfall 1 (version-weld generalization) — recovery-path parity is
already named as in-scope by TODO-009/SEED-017.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| Generalize release graph past 0.2.1 (TODO-009/SEED-017) | Deleting version literals without replacing per-release identity binding (Pitfall 1); recovery path still skips proof; escape-hatch dispatch paths (Pitfall 10) | Identity struct (head/tree/base/receipt digest) replacing version comparisons; regression test on `rollup!/1`'s skip-handling; audit all `workflow_dispatch` triggers |
| Fix `scanner_ids_result/2` message propagation | Right-failure-wrong-explanation persists in new scanners added this milestone (Pitfall 3) | Fixture-driven test asserting failing-scanner's own message surfaces; audit ordering of `missing` vs `failing` classification in any new aggregator |
| Companion clean-room realism (TODO-011) | Weakening `doctor`'s `manifest_contract` instead of hardening the host (Pitfall 2); scope-narrowing under CI cost pressure (Pitfall 8) | Record the explicit decision (recommended: harden host + `mix crosswake.install`); keep per-companion proof granularity |
| Exact-public proof redesign (TODO-012) | Relaxing digest equality to "reachability" (Pitfall 7); assuming a single linked candidate ref exists (Pitfall 7) | Per-package approved refs; keep byte-exact comparison; explicit non-goal statement about linked-vs-independent scope |
| Vacuous-assertion remediation (SEED-018) | Landing a merge-blocking guard before remediation, producing a wall of red that gets waived (Pitfall 4, Shape A) | Audit-then-guard sequencing exactly as SEED-018 prescribes; do not add `absence.collection_assertion_non_empty` until count is at zero |
| iOS mirror / Maven publish hardening (SEED-003 adjacent) | Treating "rotate the token" as sufficient; missing off-lineage-`main`/checkout-hijack review (Pitfall 6) | Enumerate the full partial-failure matrix; add byte-for-byte post-push tree verification; review workflow trust boundary, not just token scope |
| First real 0.2.2 + companion PRs through repaired graph | Using a real, irreversible publish as integration test #1 (Pitfall 5) | Dry-run to last safe step; sequence smallest-blast-radius companion before core 0.2.2; write the retire/backfill runbook before any real publish |
| CI/proof cost work overlapping this milestone (SEED-007) | Cost pressure narrowing proof scope invisibly (Pitfall 8) | Explicit, recorded scope boundary (byte-exact vs reachability) per package/path; runner-class discipline on any new job |

---

## Sources

- Primary (repo, HIGH confidence): `.planning/RETROSPECTIVE.md`; `.planning/todos/TODO-009…012`;
  `.planning/seeds/SEED-003, SEED-004, SEED-007, SEED-017, SEED-018`;
  `.planning/workstreams/quality-ratchet-release/ROADMAP.md`, `STATE.md`;
  `lib/crosswake/release_status.ex:770-840`; `script/check_release_workflow_integrity.exs:1-40`;
  `script/verify_companion_cleanroom.sh:190-265`.
- Ecosystem incident analogies (MEDIUM confidence, pattern-matched from public record, not re-verified
  against primary sources this session): `event-stream` npm supply-chain compromise (malicious
  maintainer handoff, wallet-key exfiltration via a trusted-looking dependency added under review
  pressure); Go module checksum database (`sumdb`) fail-closed mismatch handling as the template for
  per-ref byte-exactness; Homebrew bottle reproducibility drift across toolchain point releases;
  Maven Central's post-OSSRH immutability model (Central Portal) as the same "no delete, only
  supersede" pattern Crosswake's D-19 already assumes.
