# Developer Experience Research

**Milestone:** v23.0 "Release Pipeline Repair & Proof-Lane Truth"
**Scope:** CLI output, CI check names/messages, release runbook, manifest/receipt shapes — the
human-facing surface of a release pipeline with no screen UI.
**Confidence:** Findings about current-state defects are HIGH (read directly from source). Naming
and copy proposals are MEDIUM — they are design opinions for the roadmapper to adopt or amend, not
facts. Nothing below claims a fix is implemented; v23.0 has not started.

---

## Domain Vocabulary

*Lens: Technical writer + Interaction designer.* Consistency of nouns is the single highest-leverage
DX fix available here, because the PR #164 defect is fundamentally a vocabulary failure: the system
has the right word (`weld`) sitting in a message string, and a different subsystem re-describes the
same event as "missing scanner IDs" — a different noun, a different mental model, at the exact
moment a maintainer is under time pressure.

### Canonical terms (use these, everywhere, forever)

| Concept | Canonical term | Definition | Reject these synonyms |
|---|---|---|---|
| The git ref + tree + workflow blobs bound to one approval | **candidate** (or **release candidate**) | The exact identity `Crosswake.ReleaseCandidate.Workflow` captures and approves | "the release", "the PR", "the version" when identity (not just version number) is meant |
| The recorded approval of a candidate | **approved manifest** | `.release-please-manifest.json` plus the captured head/tree/base — what `verify_companion_cleanroom.sh --approved-manifest` consumes | "the manifest" alone (ambiguous with the *runtime manifest* domain object Crosswake ships to adopters — see collision below) |
| A publish job hardcoding a version string in its `if:` gate | **weld** / **welded** | Already the term of art in TODO-009, SEED-017, and the scanner's own FAIL line | "pinned", "hardcoded", "gated" — each appears in the codebase for this exact thing (see collisions) |
| Byte-for-byte equality between a rebuilt artifact and what a registry serves | **exact-public proof** | The post-publish job comparing rebuilt digests to Hex/Maven/SwiftPM | "digest check", "artifact verification" — both appear informally |
| A registry not returning what's expected (missing package, wrong version, unreachable) | **partial (registry) availability** | The rollup state `PARTIAL` | "flaky", "registry lag", "not found yet" |
| A minimal reproduction environment that resolves a package the way an adopter would | **clean room** | `verify_companion_cleanroom.sh`; the harness itself | "sandbox", "isolated host", "test harness" — all three appear in comments/scripts for the same thing |
| The publish path used when the primary graph did not run | **recovery (path/publish)** | Manual/exact-ref recovery, e.g. how 0.2.1 shipped | "manual publish", "fallback", "the workaround" |
| A guard whose whole job is to fire loudly the instant a precondition breaks | **tripwire** | `release.version_weld.gates_match_declared_version`; used in TODO-009's own title | "guard", "gate", "check" used interchangeably for this *specific* kind of check |
| The final one-line verdict for a release attempt | **rollup** | `BLOCKED / STALE / READY FOR APPROVAL / PARTIAL / COMPLETE` | "status", "result", "outcome" |
| The four-word rollup vocabulary itself | **rollup states** | see above | "release states", "candidate status" |
| The evidence a single CI job produces (JSON summary the app under test emits) | **receipt** | e.g. `phase168-candidate-receipt-<head>` — currently only aspirational (TODO-012: doesn't exist on any run) | "artifact" (too generic — GitHub Actions artifacts are also called "artifact") — reserve **artifact** for the *published package* (the `.tar`, the `.jar`, the SwiftPM tag) and **receipt** for *evidence about* that artifact |
| One scanner's individual pass/fail line (`[crosswake] OK/FAIL: <id> - <detail>`) | **scanner check** (or **check ID**) | `release.version_weld.gates_match_declared_version` etc. | "assertion" (reserved below), "rule", "test" |
| One item in `PhysicalIphoneContract`'s closed vocabulary | **assertion** | `PI-BRIDGE-HAPTIC-IMPACT` etc. | do not let "check" or "scanner check" bleed into this domain — different subsystem, different owner (`:device_local` vs `:backend_authority`) |

### Flagged inconsistencies (current codebase — fix during v23.0 copy pass)

1. **"manifest" is three different nouns wearing one word.**
   - `.release-please-manifest.json` — the **approved manifest** (release identity/version).
   - Crosswake's own `Manifest` module / `crosswake_manifest.json` — the **runtime manifest**
     (routes, capabilities — what ships to adopters, see `doctor.ex` `manifest_contract`).
   - The clean-room's `MATRIX_APPROVED_MANIFEST` — a third artifact, a manifest *of manifests*
     (six `candidate_ref`s).
   This is not cosmetic. TODO-011's `manifest_contract (manifest_invalid)` failure and TODO-012's
   "approved manifest requires one candidate_ref" are two *completely unrelated* failure classes
   that share the word "manifest" in the exact same runbook. A maintainer skimming a red check
   list cannot tell them apart by name alone.
   **Action:** in all new/changed copy, always qualify: "release manifest" (the approval) vs.
   "runtime manifest" (the route/capability document) vs. "approved-manifest matrix" (the six-entry
   clean-room input). Never write bare "manifest" in a CI message.

2. **"gate" vs. "weld" vs. "pin" for the same mechanism.** TODO-009 calls it a "weld." The scanner's
   own check ID says `gates_match_declared_version`. `release-please.yml` job conditions are called
   "gates" throughout comments (`paths_released` "gate"). Elsewhere "pinned" (`RELEASE_PLEASE_TOKEN`
   pin comment, SHA "pins" in SEED-007). **Decision: "gate" is the mechanism (an `if:` condition,
   value-neutral — the repo already has 20+ legitimate gates that should stay gates). "Weld" is the
   *defect* — a gate that only accepts one hardcoded value instead of derived identity.** Never use
   "weld" for a healthy gate; never call a welded gate merely "a gate" in a diagnostic (that erases
   the finding). "Pin" stays reserved for SHA-pinning of third-party actions (a different, correct,
   security practice — do not let "weld" bleed into that vocabulary or vice versa).

3. **"proof" is used for at least four distinct kinds of thing**, and this milestone touches three
   of them: (a) the `exact-public-proof` job (registry digest equality), (b) `clean-room-proof-*`
   jobs (resolvability + doctor), (c) `PhysicalIphoneContract` proof-lane assertions (device
   evidence), (d) `mix crosswake.proof_lane.verify_navigation_shell` (a fourth, template-fidelity
   proof). Keep "proof" as the umbrella word (it's core brand vocabulary — see OSS-DNA "proof
   lanes are part of the product") but **always compound it** — "exact-public proof," "clean-room
   proof," "physical-device proof," "navigation-shell proof" — never bare "the proof" in a message
   a maintainer reads standalone (e.g. in a Slack alert or issue title), because which proof failed
   is exactly the fact under time pressure.

4. **`checks:` (workflow_integrity map key) vs. `Doctor.Check` struct vs. GitHub "check" (a status
   context) vs. `check/6` (the private helper in `release_status.ex`) is a four-way collision on
   the single most common word in this codebase.** Not fully fixable without an API break, but new
   copy should write "GitHub check" / "status check" for the branch-protection sense, "scanner
   check" for `workflow_integrity.checks`, and "finding" for `Doctor.Check` — `doctor.ex` already
   half-does this (calls its list `findings`); make it consistent everywhere doctor output is
   rendered, including `--format json`.

5. **"digest" vs. "hash" vs. "SHA".** `cleanroom.ex` uses "digest_mismatch"; SEED-007 uses "hash"
   for the same registry-content-equality idea in a different context (dep-lock hashes); git/commit
   identity uses "SHA"/"ref". Keep them apart on purpose: **SHA/ref = git identity. Hash = a
   generic checksum in prose. Digest = specifically the registry-artifact-equality proof output**
   (`digest_mismatch` is already the correct, specific term — do not generalize it to "hash
   mismatch" in new copy, that would blur it back into the git-identity space).

6. **"companion" is safe (don't touch)** — one word, one meaning (`crosswake_*` independently
   versioned Hex package), used identically across brandbook, runbook, and code. Cite as the
   positive example when writing the v23.0 style guide: this is what the other five nouns should
   look like.

### New nouns/verbs this milestone likely needs, named now to avoid inventing more collisions later

| Concept (from TODO-009/011/012) | Proposed term | Why |
|---|---|---|
| The literal `== "0.2.1"` comparisons under repair | **version weld** (noun), **de-weld** (verb, informal only — never in user-facing copy, use "generalize the gate" or "unweld the version gate") | matches existing "weld" usage; "de-weld" is fine in commit messages/TODOs, not in CI text |
| A per-release identity that replaces the version literal | **candidate identity** or **release identity** (NOT "release fingerprint" — brandbook rejects nautical-cosplay/overwrought metaphor; NOT "release token" — collides with `RELEASE_PLEASE_TOKEN`, an actual secret) | must not collide with existing "candidate" (the whole approved unit) — identity is the *binding*, candidate is the *thing bound* |
| A per-package approved ref (TODO-012 option 2) | **per-package candidate ref** | extends existing `candidate_ref` field name already in the approved-manifest schema — reuse, don't rename |
| The scoped-to-core-only exact-public variant (TODO-012 option 1) | **core exact-public proof** (as opposed to **companion exact-public proof**, if TODO-012 option 2 also ships per-companion proof) | parallels "clean-room proof" naming pattern already established |
| A scanner's per-check narrative detail surfacing through to the human-facing message | **scanner detail** (this is not new — `parse_workflow_integrity_output/1` already stores it as `detail`; the fix is *propagating* it, not naming it) | keep code and copy using the same field name |

---

## JTBD & Flows

*Lens: DevRel / user psychology.* Each flow below extends `.planning/research/JTBD-AND-USER-FLOWS.md`
(which is scoped to adopter product jobs) into the **operator** and **contributor** jobs this
milestone actually serves — that file does not cover them, so this is additive, not contradictory.

### JTBD 1 — "A maintainer cuts a release and wants to know it actually published."

- **Who:** the maintainer who merged the release-please PR (today: only one person can, by design).
- **What:** confirmation, in one place, without cross-referencing three registries by hand.
- **How today:** watch the Checks tab; if `PROOF-03c` alerting exists, wait for a Slack/issue
  ping; otherwise run `mix crosswake.release.status --live` manually.
- **What they need:** a single rollup state they already trust (`COMPLETE`/`PARTIAL`/`BLOCKED`)
  plus — new in v23.0 — the *scope* of what that state covers, because after TODO-009/012 land,
  "COMPLETE" for core and "not yet proven" for a companion are both real, simultaneous states.
  A maintainer who reads one `COMPLETE` and assumes it means "everything" is the next version of
  today's defect.
- **What they get today:** a rollup that is either accidentally-correct (0.2.1, published through
  recovery, was never proven at all — TODO-009's "second gap") or literally cannot reach
  `COMPLETE` for the shape Crosswake actually ships (TODO-012 — the family is never one candidate).
- **Domain nouns used correctly:** rollup, candidate, exact-public proof, live registry.
- **v23.0 implication:** the rollup must become **legible about scope** — not just a four-word
  verdict, but which coordinates it verdicts over. See Diagnostic Message Contract, "rollup
  scoping" pattern below.

### JTBD 2 — "A maintainer stares at a red required check and must find the cause in under a minute."

- **Who:** the maintainer, possibly not the one who wrote the failing check, possibly at low
  attention (this is explicitly a 2am/context-switch scenario per the lens brief).
- **What:** the *actual* reason, not a re-description of the symptom one layer removed.
- **How today:** click into the failing GitHub check, read the job log, which for
  `release-candidate-fixtures` currently shows `Crosswake.ReleaseStatus`'s own re-narrated message
  ("missing scanner IDs: ...") rather than the scanner's own FAIL line, which is sitting a few
  layers down in `checks[id].detail` and is never read.
- **What they need:** the message on the **first screen** (the Checks tab summary / the top of the
  job log) to already be the root cause, not a summary of a summary.
- **What they get today:** exactly the PR #164 case in the milestone brief — "the right failure
  carrying the wrong explanation."
- **This is the single highest-priority fix in the milestone.** See Diagnostic Message Contract
  and Example Messages below for the concrete before/after.

### JTBD 3 — "A maintainer hits a PARTIAL rollup and must decide: retry, recover, or stop."

- **Who:** the maintainer, at the moment of maximum consequence — a one-way door (publish) may have
  already fired for *some* coordinates and not others.
- **What:** a decision table, not a diagnosis. By the time `PARTIAL` shows, the maintainer already
  knows something is wrong; what they lack is *which of the three actions is safe*.
- **How today:** `docs/COMPANION-PUBLISH-RUNBOOK.md` says "do not read PARTIAL as a transient
  failure to retry" for the *known* 0.2.1-weld case, but this is a one-off warning embedded in
  prose, not a general decision rule attached to the rollup output itself.
- **What they need:** the rollup's `next_action` field (already a real field in `ReleaseStatus`
  checks — reuse the pattern) elevated to the *rollup* level, not just the per-check level, and
  the decision rule must distinguish **already-published, proof-only PARTIAL** (safe to
  re-run just the proof) from **nothing-published PARTIAL** (safe to fix and re-merge) from
  **some-published PARTIAL** (unsafe to blind-retry — must recover, not repeat).
- **What they get today:** a single `PARTIAL` string with no machine-readable indication of which
  of the three shapes it is. The maintainer has to read `child_states`/`successful_coordinates` by
  hand (they exist in the rollup JSON per `release-please.yml:793` — good, this is real data
  already emitted, just not surfaced as guidance).
- **v23.0 implication:** promote `successful_coordinates` / `failed_step` / `next_action` from
  "present in the JSON if you know to look" to "printed as the first three lines of the human
  rollup," and add the retry/recover/stop verdict as an explicit field, not an inference exercise.

### JTBD 4 — "An adopter upgrades to a new Crosswake version and wants confidence the artifact is what the repo says it is."

- **Who:** an external, unprivileged adopter (not a maintainer) — this job has *no CI access* and
  *no ability to re-run anything*. This is a trust-at-a-distance job, closer to a supply-chain
  question than a debugging one.
- **What:** a way to answer "is `crosswake 0.2.2` on Hex the thing that passed the release
  process, or could it have been tampered with / mis-published?" without operator access.
- **How today:** nothing adopter-facing exists. `exact-public-proof` is a maintainer-facing CI job;
  its result is not published anywhere an adopter would look (not in CHANGELOG, not in a
  release-note field, not queryable via `mix crosswake.release.status` against someone else's
  install).
- **What they need, minimally, for v23.0's scope (repair, not a new adopter feature):** the
  CHANGELOG "Upgrade Impact" discipline (already established per SEED-013's ask) should gain one
  more habitual line per release: *whether the exact-public proof ran and passed for this version*,
  phrased in the negative-honest voice the brandbook requires (e.g. "This release published
  through the ordinary graph; the exact-public proof ran and confirmed the published Hex/Maven/
  SwiftPM artifacts match the approved candidate" vs., for a recovery publish, "This release
  published through the recovery path; the exact-public proof did not run for it — see
  `docs/COMPANION-PUBLISH-RUNBOOK.md`"). This is honesty-about-what's-proven exported to the
  adopter surface, and it's cheap: it's a changelog sentence, not new machinery.
- **Do not overbuild this in v23.0** — a full adopter-facing provenance/attestation feature (e.g.
  Sigstore, SLSA) is out of scope for "repair the release pipeline"; flag it as a future seed
  instead (see Documentation Surface).

### JTBD 5 — "A new contributor reads the runbook and must not publish something by accident."

- **Who:** someone who has never operated this pipeline, reading `COMPANION-PUBLISH-RUNBOOK.md`
  cold.
- **What:** confidence that following the doc cannot trigger the one-way door unintentionally, and
  clear labeling of which commands are read-only vs. which are irreversible.
- **How today:** the runbook already does this reasonably well — "The status and candidate commands
  are read-only" is stated up front (good, matches the brandbook's "no hidden bridge magic" /
  operational-truth principle), and the "STOP" callout for the version-0.2.1 constraint is
  correctly loud.
- **What breaks after v23.0 lands (if the doc isn't updated in lockstep):** the "STOP — this
  pipeline currently publishes exactly one version" section becomes **actively false** the moment
  TODO-009 closes, and a stale STOP warning is worse than none — a contributor who reads "this only
  works for 0.2.1" on a repo now three versions past 0.2.1 will either (a) distrust the whole doc
  (correctly) or (b) attempt an unnecessary manual recovery out of misplaced caution. This doc
  section is a **hard deletion item** for v23.0's Documentation Surface work — see below.
- **v23.0 implication:** every runbook sentence that hardcodes "0.2.1" needs to be re-derived as
  "the declared version" generically, or the runbook itself becomes the next version-welded
  artifact — same defect class, different layer (docs instead of YAML).

---

## Diagnostic Message Contract

*Lens: Technical writer + tools with famously good diagnostics.*

### What a good failure message contains (in order, top to bottom)

1. **What failed** — the specific check ID/name, stated once, unambiguously (not "a check failed,"
   not restated three ways).
2. **What it means** — translated into domain vocabulary from the table above, one sentence,
   *in terms of consequence* ("the release would tag and then publish nothing"), not just
   mechanism ("the values don't match").
3. **What to do next** — one concrete, copy-pasteable action. A command, a file to edit, a
   decision to make. Never "investigate further" with no verb.
4. **Where to look** — the file(s)/line(s)/job(s) that are the source of truth, so the maintainer's
   *next* click is correct the first time.

### What it must never do

- **Never let a wrapping layer discard a failing check's own message and substitute a generic
  re-description of its *symptom*.** This is the PR #164 defect exactly: `scanner_ids_result/2`
  sees "the IDs I was told to require aren't present" and reports *that*, instead of asking "is
  there a check that *did* run and *did* fail, whose message explains why my required IDs never
  showed up?" A message layer is allowed to summarize, but it is never allowed to have *more*
  information available (the `detail` field, already parsed and sitting in memory) and choose not
  to use it.
- **Never report absence as "missing IDs" without first checking for a failure that explains the
  absence.** Absence-of-evidence framed as the primary finding is the "absence scored as success"
  failure class from the retrospective (per the user's own memory of this project) mirrored into
  its opposite: here it's *absence scored as an unexplained new problem*, when a real, specific,
  already-computed problem caused the absence.
- **Never blame the scanner for the release.** "Scanner exited nonzero without parseable failing
  IDs" (the third branch of `scanner_ids_result/2`, `release_status.ex:842`) is the correct fallback
  ONLY when genuinely nothing better is available — but it should never fire when a `FAIL` line
  with a rich `detail` exists elsewhere in the same parsed output. The fallback is currently doing
  work that a lookup should do first.
- **Never bury the real message below a wrapper's own paraphrase.** If a wrapper adds context
  (job name, GitHub check name), it should *prepend*, never *replace*.

### The general fix shape (for `Crosswake.ReleaseStatus.scanner_ids_result/2`)

Today, on failure, the function computes `missing` (required IDs absent from `checks`) and
`failing` (required IDs present with `status: :error`) — but only within the `required_ids` set
passed to *that specific* `scanner_check` call. When the true root cause is a *different* check ID
that isn't in anyone's `required_ids` list (version_weld is not in `@workflow_path_gate_ids`), no
caller's message ever surfaces it, even though `checks` (the full parsed map) already contains it
with a full `detail` string.

Proposed contract: when a scanner run has overall `status: :failed`, before falling back to
"missing IDs" language, **check whether any check ID in the full parsed set (not just the
required subset) has `status: :error`, and if so, surface its `detail` verbatim, prefixed with its
ID** — regardless of whether that ID happens to be one this particular caller's `required_ids`
list cares about. A failing scanner run has *one real root cause*; every `scanner_check` call that
depends on the same scanner subprocess should be able to point at it, not just the call whose
`required_ids` happens to include the failing ID.

This is a small, mechanical, high-value fix — it changes what `scanner_ids_result/2` returns, not
the scanner's own output format, and it directly retires the "near relative of absence-scored-as-
success" defect class TODO-009 names.

---

## Example Messages

Six-to-ten realistic messages for this milestone's real failure classes. Each follows the four-part
contract above. Field names shown match `Crosswake.ReleaseStatus`'s existing check shape
(`status`, `code`, `message`, `next_action`, `source`, `evidence`) — no new shape invented where the
existing one already fits.

### 1. Version weld (the PR #164 case) — BEFORE / AFTER

**BEFORE (what a maintainer sees on `release-candidate-fixtures` today):**
```
root/native publish jobs are not exact path-gated: missing scanner IDs:
release.outputs.paths_released, release.root_hex.path_gate, release.ios.path_gate,
release.android.path_gate
```

**AFTER:**
```
release.workflow_path_gates: FAILED (cause: release.version_weld.gates_match_declared_version)

.release-please-manifest.json declares "0.2.2" but the release graph is welded to
["0.2.1"] (publish-hex accepts 0.2.1; publish-ios-core accepts 0.2.1;
publish-android-core accepts 0.2.1; exact-public-proof accepts 0.2.1).
Those jobs would SKIP, so the release would tag and then publish NOTHING.

next action: fix the version gate before merging this release PR — see TODO-009 /
docs/COMPANION-PUBLISH-RUNBOOK.md "Before releasing any version other than 0.2.1"
source: script/check_release_workflow_integrity.exs
  (release.version_weld.gates_match_declared_version)
```
Note: `release.workflow_path_gates` still reports FAILED (it's true — the path gates
*are* broken, as a downstream consequence) but now names the upstream cause instead of
re-describing its own symptom as a mystery.

### 2. Digest mismatch (exact-public proof)

```
release.exact_public_proof: FAILED (digest_mismatch: crosswake_sigra 0.1.3)

The tarball rebuilt from the approved candidate does not byte-match what Hex is
currently serving for crosswake_sigra 0.1.3.
  rebuilt digest: 3f9a1c…
  published digest (Hex):  7b02de…

This means either the published package was not built from the approved candidate,
or the candidate has drifted since crosswake_sigra 0.1.3 was tagged (packages can
drift independently — see TODO-012).

next action: do not re-publish. Confirm which commit crosswake_sigra 0.1.3 actually
shipped from (`git log --all --grep sigra-v0.1.3`) and open a TODO if the candidate
and the published artifact have genuinely diverged.
source: script/verify_companion_cleanroom.sh --source-mode exact-public
```

### 3. Partial registry availability (rollup)

```
release rollup: PARTIAL (2 of 3 linked coordinates published)

  hex:crosswake@0.2.2            COMPLETE  (published, exact-public proof passed)
  ios:crosswake-shell-core-ios   COMPLETE  (mirror tag v0.2.2 pushed, matches candidate)
  maven:crosswake-shell-core-android  BLOCKED  (Maven Central has not indexed the upload
                                       after 3 polling attempts; last checked 14:02 UTC)

This is not the version-weld failure — the graph ran and two of three coordinates
are provably live. Maven's own indexing delay is outside Crosswake's control.

next action: retry the read-only status check in ~15 minutes
  (`mix crosswake.release.status --live`); Maven has published in the past 20-40
  minutes after upload. Do NOT re-run publish-android-core — the upload already
  succeeded (see evidence.android_upload_receipt); re-running risks a duplicate
  artifact rejection, not a fix.
source: .github/workflows/release-please.yml (native-release-status rollup)
```

### 4. Clean-room doctor block (TODO-011 shape)

```
clean-room-proof-rindle: FAILED (doctor: manifest_contract / manifest_invalid)

mix crosswake.doctor blocked inside the clean-room host for crosswake_rindle 0.1.0:
  "manifest is missing required top-level section :routes"

crosswake_rindle 0.1.0 itself is not implicated — it resolved from Hex, compiled
clean under --warnings-as-errors, and passed its own smoke test. The clean-room
host's router stub declares no routes, so the compiled manifest has none, and
doctor correctly refuses a routeless manifest.

next action: this is a known harness gap (TODO-011) — the clean-room host needs a
real route and a mix crosswake.install run before doctor, matching what an adopter
actually does. Do not weaken doctor's manifest_contract check to make the harness
pass.
source: script/verify_companion_cleanroom.sh (Step 7), lib/crosswake/doctor/doctor.ex
  (manifest_compile_check/1)
```

### 5. Recovery-path proof skipped

```
exact-public-proof: SKIPPED for this release

crosswake 0.2.2 published through the recovery path (exact-ref recovery), not the
ordinary publish-hex / publish-ios-core / publish-android-core graph. The
exact-public proof needs: those jobs, so it did not run for this release.

This release is NOT proven byte-exact against the approved candidate. It is
published, but unverified.

next action: run the exact-public proof manually against the recovery commit before
closing this release out:
  mix crosswake.release.candidate --verify-recovery <recovery-ref>
(this command does not exist yet — TODO-009 "recovery should converge on the same
proof" — until it does, run script/verify_companion_cleanroom.sh --source-mode
exact-public by hand against <recovery-ref> and record the result in the release
issue.)
source: docs/COMPANION-PUBLISH-RUNBOOK.md
  ("Second gap: recovery publications skip the public proof")
```
*(Deliberately shows an honest "this command does not exist yet" — see Microcopy & Voice:
never invent a command that isn't real just to make a message feel complete.)*

### 6. iOS mirror push failure

```
publish-ios-core: FAILED (mirror push rejected)

git subtree split produced 658d6025 for crosswake-shell-core-ios, but pushing
refs/tags/v0.2.2 to the split repo was rejected: the split repo's main has moved
since the last verified backfill.

This is the mirror push failing, not the Hex publish — check
release.rollup before assuming crosswake 0.2.2 itself failed to publish; it may
already be live on Hex while iOS lags.

next action: do NOT force-push the mirror. Re-run
script/verify_ios_mirror_backfill.sh to confirm mirror `main` state, then re-run
the split against current mirror main. If the split repo diverged from an
unexpected commit, stop and escalate — this repo has a documented history of
mirror-push incidents (SEED: "iOS mirror has TWO armed fuses").
source: .github/workflows/release-please.yml (Mirror iOS core to split repo)
```

### 7. Per-package candidate ref conflict (TODO-012, if option 2 ships)

```
release.approved_manifest.candidate_refs: FAILED (crosswake_sigra)

The approved manifest's candidate_ref for crosswake_sigra (a1b2c3d) does not match
any tag or release commit crosswake_sigra 0.1.3 was actually published from.

Companions version independently (see docs/COMPANION-PUBLISH-RUNBOOK.md) — this is
not a single-candidate release. Each companion's candidate_ref must point at ITS
OWN approved commit, not the core release's.

next action: regenerate the approved manifest entry for crosswake_sigra from its own
release-please run, not from the core candidate capture.
source: script/verify_companion_cleanroom.sh (per-package candidate_ref, post-TODO-012)
```

### 8. Version weld tripwire — the "no weld found" happy path (for contrast, so the OK message isn't silent-success either)

```
release.version_weld.gates_match_declared_version: OK

.release-please-manifest.json declares "0.2.2"; no publish job gates on a version
literal (publish-hex, publish-ios-core, publish-android-core, exact-public-proof
all derive their version from the candidate, not a hardcoded string).
```
*(Positive confirmations should still name what was checked and against what evidence —
per the brandbook's "precise, specific" voice and the project's own "absence scored as
success" scar tissue: a bare "OK" with no stated scope is exactly the failure class the
project is trying to eliminate, just inverted.)*

---

## CI Check Naming

*Lens: Interaction designer (scannability) + Elixir/Mix convention + SEED-007's own findings.*

### The situation as it stands

- ~22 required contexts (per SEED-007, confirmed 22/22 registered).
- At least 3 confirmed duplicate required-check **names** emitted by two different workflows
  (`core hermetic proof (merge-blocking)` from both `phase130`/`phase132`; `companion
  engine-absent proof (merge-blocking)` from both; `merge-blocking commerce support proof
  (hermetic)` from `phase23`/`phase34`). Branch protection matches by string only — this is a real
  gate-integrity hole, not a cosmetic one.
- Release-specific names observed in `release-please.yml` are inconsistent in shape: some are
  imperative ("Publish to Hex.pm"), some are declarative ("Guard exact approved 0.2.1 merge"),
  some bake the exact version into the name ("Guard exact approved 0.2.1 merge", "Prove exact
  public 0.2.1 artifacts", "Linked 0.2.1 release rollup") — **these three are themselves a
  version-welded surface**, the same defect class as the workflow gates, just in a check *name*
  instead of an `if:` condition. A check named "Linked 0.2.1 release rollup" that still reports
  that name against a 0.2.2 release is actively misleading, independent of whether the gate itself
  works.

### Proposed convention

`<domain>: <subject> — <qualifier>`, read left to right as "which system, what part, what kind":

- **domain** — one of a small fixed set: `release`, `proof`, `native`, `format`, `compat` (matches
  the vocabulary table's top-level nouns already used in `release_status.ex` check codes like
  `release.lockstep_manifest`, `release.workflow_path_gates`). Reuse the **existing dotted check
  `code` vocabulary from `release_status.ex` as the seed for check *names*** — the codes are
  already good (`release.version_weld.gates_match_declared_version` is precise and greppable);
  the *names* shown in the GitHub Checks UI should be a human-readable rendering of the same
  hierarchy, not an unrelated ad-hoc string invented per-workflow.
- **subject** — the specific thing gated (e.g. "core Hex publish", "iOS mirror push", "exact-public
  digest").
- **qualifier**, only where it changes CI behavior — `(merge-blocking)` vs `(advisory)`. Do **not**
  bake a version number into any check name, ever — that is the naming-layer version weld.

Renames proposed, e.g.:
- `Guard exact approved 0.2.1 merge` → `release: approved-candidate merge guard`
- `Prove exact public 0.2.1 artifacts` → `release: exact-public proof`
- `Linked 0.2.1 release rollup` → `release: linked rollup`
- `Publish crosswake_rindle to Hex.pm` → `release: companion publish (crosswake_rindle)` — note
  the parenthesized package name sorts poorly; prefer `release: crosswake_rindle publish` if
  sort-by-name matters more than domain-grouping (see below — this is a real tradeoff, not free).
- `Clean-room proof — crosswake_rulestead resolvability + doctor` →
  `proof: clean-room (crosswake_rulestead)`

### What to rename vs. leave alone (the branch-protection cost is real)

**Leave alone:** any check name currently *registered as required* in branch protection, unless
it is also one of:
(a) the 3 confirmed duplicate names (must be fixed — a duplicate is an active safety hole, not a
cosmetic one, so the branch-protection churn cost is worth paying here specifically), or
(b) a name with a hardcoded version number in the release graph itself (this milestone's target —
they will *already* need touching to close TODO-009, so renaming them costs nothing extra: the
gate logic and the display name are edited in the same PR, and branch protection is re-registered
once, not twice).

**Do NOT** do a wholesale rename of all ~22 required contexts as part of this milestone. Renaming a
required check means: (1) branch protection's required-status-checks list must be updated in the
same PR (or the old name stays "required" forever, silently never satisfied, and the PR is
permanently blocked — this is a real, previously-observed failure mode per SEED-007's own tooling,
`check_required_checks_registered.sh`), (2) every in-flight PR at rename time sees its check
disappear and reappear under a new name, which can transiently make GitHub report "Expected —
Waiting for status" (SEED-007's own documented trap for `paths:`, same symptom class applies to
renames), and (3) any external tooling/dashboards keyed on the old name breaks silently. **Scope
the rename to only the checks this milestone must edit anyway** (the version-welded ones + the 3
duplicates); leave the other ~17 required contexts' *names* untouched even if their format doesn't
match the new convention — a consistent convention adopted incrementally (new/edited checks follow
it, old ones don't yet) is safer than a global rename PR that risks a self-inflicted queue
deadlock, which SEED-007 already documents as a real, expensive, previously-observed cost (#84,
78 workflow runs / 3 hours for an unrelated docs change).

**Separately, and higher priority than cosmetic renaming:** extend
`check_required_checks_registered.sh` to assert **uniqueness** of names across workflows, not just
presence (SEED-007's own recommended `GATE-*` item). This is a correctness fix, is cheap, and
directly prevents the duplicate-name masking hole — do this regardless of whether the broader
naming convention is adopted.

---

## CLI & Manifest Ergonomics

*Lens: Elixir/Mix convention + interaction designer, "principle of least surprise."*

This milestone's likely CLI/manifest surface changes, from the TODOs:

### 1. `mix crosswake.release.candidate` — likely needs a recovery-proof affordance (TODO-009's "recovery should converge on the same proof")

Today (inferred from the runbook) `mix crosswake.release.candidate` captures/refreshes the
candidate. TODO-009 identifies that a recovery-path publish never gets `exact-public-proof`.
Rather than inventing a new task, extend the existing one — Mix convention favors one task with
flags over a proliferation of near-duplicate tasks (`crosswake.release.status` already
demonstrates this house style: one task, `--json`/`--live` flags, not `crosswake.release.status.json`).

Proposed usage:
```
# read-only, default — unchanged
mix crosswake.release.candidate

# run the exact-public proof against a specific ref that published via recovery,
# instead of only ever running it against the ordinary publish-job outputs
mix crosswake.release.candidate --verify-recovery <ref>

# dry-run affordance for anything that would normally capture/refresh state —
# print what WOULD be captured without writing it
mix crosswake.release.candidate --dry-run
```
- `--verify-recovery` takes a required ref argument (not a flag alone) — least-surprise: a
  one-way-adjacent verification command should force the operator to name exactly what they're
  verifying, never default to "whatever HEAD is."
- Exit codes: 0 = proof passed, 1 = proof ran and found a mismatch (real defect, per SEED-014's
  own CW-REQ-B lesson: **never collapse "ran and found a problem" into the same exit code as
  "could not run"**), 2 = could not run (e.g. ref doesn't exist, registry unreachable).
- `--dry-run` costs little to add and directly serves JTBD 5 (a new contributor must not publish
  something by accident) — every state-mutating Mix task in a release pipeline should have one,
  matching the brandbook's "no hidden bridge magic" and the runbook's existing "read-only vs.
  irreversible" labeling discipline.

### 2. `mix crosswake.release.status` — extend, don't replace, per JTBD 1/3

Current shape (`--json`, `--live`) is already good Mix convention (boolean flags, sensible
default: local-only, fast, deterministic). Proposed addition, directly serving JTBD 3 (retry vs.
recover vs. stop):

```
mix crosswake.release.status --live --explain
```
`--explain` appends, after the existing rollup line, the plain-language retry/recover/stop verdict
described in JTBD 3 — e.g. "2 of 3 coordinates published; safe to retry the status check; do not
re-run publish-android-core." Keep this opt-in (`--explain`) rather than the new default, because
the existing terse rollup output is already relied on by scripts/alerts (PROOF-03c) that parse a
known shape — changing default output format is a breaking change to anything grepping it; adding
a flag is not.

### 3. `script/check_release_workflow_integrity.exs` output — no CLI change needed, but the *consumption contract* needs stating

This script's `[crosswake] OK|FAIL: <id> - <detail>` line format is already good — stable,
greppable, one line per check (see Output Pillars below, this format already satisfies most of
them). The bug is entirely in how `Crosswake.ReleaseStatus` *consumes* this output, not in the
script's own interface. **Do not change the script's output format as part of fixing TODO-009's
message-propagation bug** — the format is fine; `parse_workflow_integrity_output/1` already
extracts `detail` correctly. The fix is downstream (see Diagnostic Message Contract). Flag this
explicitly so a planner doesn't scope unnecessary output-format churn into this script.

### 4. Approved-manifest schema — if TODO-012 option 2 ships (per-package candidate_ref)

Current shape presumably has one `candidate_ref` shared across all six entries (per
`verify_companion_cleanroom.sh:206`'s `unique | length == 1` check). TODO-012 recommends per-entry
refs. Manifest-schema ergonomics:

```jsonc
// BEFORE (implied): one candidate_ref, six entries all must share it
{ "packages": [ { "name": "crosswake", "version": "0.2.2", "candidate_ref": "abc123" }, ... ] }

// AFTER: candidate_ref moves per-entry (already structurally present, just no
// longer collapsed to a forced-unique set)
{
  "packages": [
    { "name": "crosswake", "version": "0.2.2", "candidate_ref": "abc123" },
    { "name": "crosswake_sigra", "version": "0.1.3", "candidate_ref": "def456" }
  ]
}
```
This is a **schema loosening** (removing an artificial uniqueness constraint), not a breaking
addition — existing single-candidate manifests remain valid (all entries' refs happen to be equal).
Bump `manifest_schema_version` per the existing precedent (`1.0.0 → 1.1.0` cited in SEED-013) —
**and this time, name the doctor/manifest finding-set change explicitly in CHANGELOG's Upgrade
Impact section**, per SEED-013's own confirmed-good ask ("a change to doctor's finding set is an
upgrade-impacting change ... adopters pin finding registers").

### General ergonomics checklist applied to all of the above

- **Least surprise:** flags extend existing tasks; no new task where an existing one's flag would
  do (matches `crosswake.release.status`'s own precedent).
- **Elixir/Mix idiom:** `@shortdoc`, `@moduledoc` with a usage-lines code block, `OptionParser.parse(strict: ...)`, `Mix.raise` on invalid options — every new/changed task should look exactly
  like `crosswake.release.status.ex` already does; it is the house style, copy its shape.
- **Good `--help`:** Mix tasks get `--help` "for free" via `@moduledoc`/`@shortdoc` through `mix
  help crosswake.release.candidate` — ensure the moduledoc keeps the "usage lines in a code block"
  pattern `release.status.ex` already uses; do not let a new task ship without one.
- **Sensible defaults:** default to read-only/local-only wherever a live/mutating variant exists
  (established precedent: `--live` opt-in, not opt-out).
- **Dry-run for one-way doors:** any new flag that can influence a publish or recovery decision
  gets a `--dry-run` companion or is itself read-only by default requiring an explicit `--verify-`
  style flag to act.
- **No internal guts exposed:** do not surface `checks` map internals, scanner subprocess exit
  codes, or `parse_workflow_integrity_output/1` implementation details in any user-facing flag or
  output — only the domain vocabulary from the table above.

---

## Microcopy & Voice

*Checked against `brandbook/BRAND-SPEC.md` §6 (Voice and tone) and `prompts/crosswake-elixir-oss-dna.md`.*

The brandbook's own table already assigns error messages to "calm, specific, actionable" and
release notes to "specific, task-first, no drama... lead with what changed, state what broke."
This milestone's copy is squarely inside both rows.

### Do / Don't pairs

| Do | Don't | Why |
|---|---|---|
| "the release would tag and then publish NOTHING" | "the release pipeline is broken" | Brandbook: operational truth over hype/drama; state the mechanism and consequence, not a vague severity label. |
| "crosswake_sigra 0.1.3 itself is not implicated" | (silence — let the reader assume the failing package is broken) | OSS-DNA: "public contract honesty" — actively clear a wrongly-implicated component, don't just report the symptom. |
| "this command does not exist yet — until it does, run X by hand" | inventing a plausible-sounding command that isn't real to make a message feel more complete | Brand: "no hidden bridge magic" / never claim capability that doesn't exist — this generalizes past bridge messages to CLI messages. |
| "PARTIAL (2 of 3 linked coordinates published)" | "PARTIAL" alone | Precision as brand pillar #4 — measurements and verdicts, not bare labels. |
| "Do NOT re-run publish-android-core — the upload already succeeded" | "try again" | Calm and specific; "try again" is exactly the false affordance that risks a duplicate-artifact incident. |
| "next action: fix the version gate before merging — see TODO-009" | "please investigate" | Actionable per the diagnostic contract; also OSS-generous — points at the maintainer's own prior reasoning instead of making them re-derive it. |
| "root/native publish jobs are not exact path-gated" retained ALONGSIDE the real cause | replacing the summary entirely and losing the path-gate framing | Progressive disclosure — the higher-level check still has value as a category label; just never let it be the *only* thing shown. |
| Present tense for what changed: "Adds a per-package candidate_ref" | "This release will add..." / "We're excited to..." | Brandbook's explicit release-note voice rule, verbatim. |
| "Not proven byte-exact against the approved candidate. It is published, but unverified." | "Published successfully" (when the proof didn't run) | This is the core honesty commitment of the milestone — never let "published" imply "proven" when they diverged. |

### Words to avoid in this milestone's copy (brandbook §1, "what Crosswake is not" + §4 avoid-list, applied to release copy)

- "magic," "seamless," "just," "automatically" — a release pipeline claiming something happens
  "automatically" when it in fact silently skipped is the exact failure this milestone repairs;
  don't reintroduce the word even in success-path copy.
- "should be fine" / "probably published" — the brand voice is precise and verdictive
  (`BLOCKED`/`STALE`/`READY FOR APPROVAL`/`PARTIAL`/`COMPLETE`), never hedged prose standing in for
  a real state.
- Nautical metaphor beyond the established set (wake, crossing, seam, channel, island) — a release
  message is not the place to introduce a new metaphor ("the release ran aground," "smooth
  sailing") per §6 "use metaphor sparingly... technical documentation should not become nautical
  cosplay."

---

## Output Pillars

*Lens: Accessibility + interaction design for terminal/CI surfaces.*

Enumerated pillars, each checked against the Example Messages and CLI proposals above:

1. **Colour is never the sole signal.** All example messages above use `OK`/`FAIL`/`BLOCKED`/
   `PARTIAL`/`COMPLETE` words, not colour alone — this is already the house style
   (`[crosswake] OK: ...` / `[crosswake] FAIL: ...` text prefixes exist today). **Check: pass** —
   no proposal above relies on colour to convey a distinct meaning; keep it that way for any
   terminal colourization added on top (colour may *decorate* OK/FAIL, never replace the word).

2. **Works in light, dark, and no-colour terminals; respects `NO_COLOR`.** No existing grep found
   `NO_COLOR` handling in the scanned files. **Gap to flag for planning:** if any new CLI output
   (e.g. `--explain`) adds colour, it must check `System.get_env("NO_COLOR")` before emitting ANSI
   codes — this is a one-line addition, cheap to require as an acceptance criterion on any new
   colourized output in v23.0.

3. **Readable when copy-pasted into an issue.** All Example Messages above are plain text, no
   box-drawing, no dependency on terminal width for meaning (the two-column-ish alignment in
   example 3's rollup table is illustrative — actual code should not rely on fixed-width alignment
   surviving a paste; prefer `key: value` lines over column alignment for anything that must remain
   legible after re-flowing). **Check: mostly pass, one flag** — the "rollup table" in example 3
   should be implemented as repeated `label: STATE (detail)` lines, not an actually-aligned ASCII
   table, specifically so it survives proportional-font rendering in a pasted GitHub issue.

4. **Stable enough to grep.** The `[crosswake] OK|FAIL: <id> - <detail>` format and the dotted
   check `code` values (`release.version_weld.gates_match_declared_version`) are both already
   grep-stable — **preserve this exactly**; any v23.0 change to `scanner_ids_result/2` must keep
   emitting the check `code` as a stable, unchanging token even as the `message` text around it is
   improved. Never rename a check `code` as part of a copy pass — that breaks anyone's saved
   `grep`/dashboard query silently. (This is the message-text equivalent of "don't rename a
   required check casually" from the CI Check Naming section — same principle, cheaper stakes.)

5. **No reliance on Unicode that mangles in CI logs.** Scanned files show no emoji/box-drawing in
   the scanner or `release_status.ex` output — good, keep new copy ASCII-only. (SEED-007's own
   retrospective document is the *one* place in this codebase using 🔴 markers, and that's a
   planning doc, not CI output — do not import that habit into CI-facing text.)

6. **Reasonable line lengths.** GitHub's Checks UI truncates long single lines awkwardly; prefer
   the multi-line message shape used throughout the Example Messages section (short first line =
   the verdict, then wrapped detail, then `next action:`/`source:` as separate labeled lines) over
   one long run-on sentence. This is already how `check_release_workflow_integrity.exs`'s longer
   `welded` message is written (per the source excerpt read for this research) — extend that
   pattern, don't invent a new one.

7. **(Additional pillar) Idempotent re-display.** A maintainer will re-run `mix
   crosswake.release.status` multiple times against the same state while deciding what to do
   (JTBD 3). Output for unchanged state must be byte-identical across runs (no timestamps embedded
   in the *verdict* line, though a timestamp in supporting evidence like "last checked 14:02 UTC"
   in example 3 is fine and useful) — otherwise diffing two runs to confirm "did anything change"
   becomes unreliable.

8. **(Additional pillar) Scope must always be stated, never assumed.** Specific to this milestone
   (JTBD 1's finding): every rollup-level verdict must state what it covers (which coordinates,
   which proof lanes) rather than a bare `COMPLETE`/`PARTIAL`, because after TODO-012 the release
   is *structurally* not one scope any more (core vs. companions). This generalizes pillar 1
   ("colour isn't the only signal") to "a verdict word isn't the only signal either — scope is
   part of the signal."

---

## Documentation Surface

*Lens: Technical writer. "An operator runbook that is wrong is worse than none."*

### `docs/COMPANION-PUBLISH-RUNBOOK.md` — must change

- **Delete outright, don't just soften:** the entire "Before releasing any version other than
  0.2.1 / STOP" section, once TODO-009 closes. A stale STOP warning actively misleads (JTBD 5's
  finding above) — replace it with a short "Version generalization" note stating the graph now
  derives version/identity from the candidate, with a pointer to the closed TODO for history
  (don't delete the historical record — move it, e.g. reference "see TODO-009 (closed) for why
  this constraint existed").
- **Rewrite the "Related: a release completing through exact-ref recovery does not run
  exact-public-proof at all" paragraph** to reflect whichever of TODO-009's fixes lands (either
  "recovery now converges on the same proof via `--verify-recovery`" or, if that scope is deferred,
  an explicit "still open — see TODO-009 follow-up" so the doc doesn't silently imply it's fixed
  when only the weld half is).
- **Add a new "Reading a PARTIAL rollup" section**, directly operationalizing JTBD 3's
  retry/recover/stop decision rule — this doesn't exist today and is exactly the kind of judgment
  call a runbook exists to pre-answer so the maintainer isn't deriving it live under pressure.
  Table form: `PARTIAL shape → safe action`.
- **Add a one-paragraph note on the companion clean-room lane's known-red status** (TODO-011) if
  it is not fully closed by end of milestone — an operator merging a companion release PR needs to
  know "a red `clean-room-proof-*` today is a known harness gap, not necessarily a defect in your
  package" (with the explicit caveat: "check the specific failure reason against TODO-011's list —
  new failure causes are still real defects"). This directly prevents a repeat of the pattern
  TODO-011 documents (three real publishes, three ignored red proofs).
- **If TODO-012's option 2 (per-package candidate_ref) ships:** update the "candidate authority"
  section's framing from "the exact Release Please head, tree, merge base... form the candidate
  identity" (currently implicitly singular) to explicitly state per-package identity applies to
  companions, matching D-15/D-16's already-stated independence — this is fixing the runbook to
  match a design decision (D-15/D-16) it currently only half-reflects.
- **Update every "0.2.1"-specific literal** in the doc (the candidate-authority section names exact
  coordinates for "0.2.1" specifically) to either use the currently-active version dynamically
  (if the doc is templated) or explicitly say "this section names the example current release;
  see `mix crosswake.release.status` for the live version" — a runbook that hardcodes a shipped
  version number is doing, in prose, the exact thing TODO-009 fixes in YAML.

### What to leave alone

- The "Exact seven-step operator sequence" structure and its numbered-step discipline — this is
  good, matches the brandbook's "explicit, calm, technical" voice, and is not touched by any TODO
  in scope. Do not restructure it just because other sections nearby are changing.
- The "read-only vs. irreversible" framing at the top — correct, keep it, extend it (per CLI
  Ergonomics above) rather than replace it.

### New documentation surface this milestone likely needs

- A short **"Message contract" appendix** (could live in `CONTRIBUTING.md` or a new
  `docs/CI-DIAGNOSTICS.md`) codifying the four-part contract from this research (what failed / what
  it means / what to do / where to look) as a standing rule for anyone adding a new scanner check
  or `Doctor.Check` finding in the future — this is the mechanism that prevents the next
  `scanner_ids_result`-shaped defect from being reintroduced by a future contributor who doesn't
  have this research doc in front of them.
- A **vocabulary appendix** (could be the table at the top of this document, trimmed) linked from
  both the runbook and `CONTRIBUTING.md`, so "manifest" (three meanings), "weld" vs. "gate," and
  "proof" (four kinds) are looked up rather than re-guessed per PR.

---

## Sources

All findings above are derived directly from in-repo source read during this research session
(HIGH confidence — primary source, not web search):

- `.planning/todos/TODO-009-release-graph-welded-to-0-2-1.md`
- `.planning/todos/TODO-011-companion-cleanroom-lane-has-never-been-green.md`
- `.planning/todos/TODO-012-exact-public-proof-assumes-a-linked-six-package-release.md`
- `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md`
- `.planning/seeds/SEED-013-adopter-device-proof-lane-reachability.md`
- `.planning/seeds/SEED-007-ci-cd-performance.md`
- `.planning/research/JTBD-AND-USER-FLOWS.md`
- `brandbook/BRAND-SPEC.md`
- `prompts/crosswake-elixir-oss-dna.md`
- `lib/crosswake/release_status.ex` (read in full around `scanner_ids_result/2`,
  `scanner_check/7`, `checks/5`, `workflow_integrity_evidence/1`, `parse_workflow_integrity_output/1`)
- `lib/crosswake/doctor/doctor.ex` (moduledoc, finding shape, `hint:`/`next_action`)
- `script/check_release_workflow_integrity.exs` (version-weld check construction, FAIL message text)
- `script/verify_companion_cleanroom.sh` (referenced via TODO-011/012 line citations)
- `.github/workflows/release-please.yml` (job `name:` fields, grepped in full)
- `docs/COMPANION-PUBLISH-RUNBOOK.md` (read in full)
- `lib/mix/tasks/crosswake.doctor.ex`, `lib/mix/tasks/crosswake.release.status.ex` (existing Mix
  task shape/idiom used as the house-style precedent for CLI ergonomics proposals)

No external web research was used for this document — the question is entirely about this
repository's own interfaces, and the primary source (the code, the TODOs, the brand spec) is
authoritative and sufficient. This is noted explicitly per the research philosophy: citing sources
that were and were not consulted.
