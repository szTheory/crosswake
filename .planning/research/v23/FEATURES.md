# Feature Landscape: Trustworthy Release + Post-Publication Proof

**Domain:** Multi-package OSS release engineering (Hex + SwiftPM mirror + Maven Central), for a
mature library family that already has an approval-gated candidate pipeline and a fail-closed
rollup.
**Milestone:** v23.0 Release Pipeline Repair & Proof-Lane Truth
**Researched:** 2026-09-15

This is not "what should a release pipeline have in general." Crosswake already has the hard
parts most projects never build: an exact-identity approval gate, a fail-closed rollup, a
clean-room harness, a doctor task, a support matrix. The gap is narrower and sharper: **the
post-publication proof lane has never executed, for three structurally distinct reasons**, and
one live defect hides the truth about *why* when it does fail. Every feature below is scoped to
closing that gap without touching the things that already work.

---

## Table Stakes

What any serious multi-package OSS library family must have. Crosswake's status is called out
per row — most of column 2 exists; the gap is almost entirely in "does it run for every
release" and "does it explain itself when it fails," not "does the mechanism exist."

| Feature | Expected behavior (observable outcome) | Complexity | Depends on | Crosswake status |
|---|---|---|---|---|
| **Version-parametric release graph** | A release of any semver (not just one hardcoded value) runs the full publish→proof→rollup graph without a workflow edit. `release-please.yml`'s job `if:` conditions accept `needs.release-please.outputs.version`, not a literal. | Medium | `release_please` outputs, `ReleaseCandidate.Workflow.@coordinates` | **Missing** — TODO-009/SEED-017. Welded to `0.2.1` in 15 places, 5 of them job gates. |
| **Exact per-release identity binding** (Release engineer / supply-chain lens) | Publication authority is bound to *this* release's approved head/tree/base/candidate-receipt digest, not to a version string. Two releases never share an identity gate; a stale or wrong-head PR cannot publish even if its version number matches. | Medium | `PHASE168_*` pinned-identity gates, candidate receipt schema | **Partial** — the identity gate exists and is exact for `0.2.1` specifically; it must become "exact for whichever release this is," which is the actual content of TODO-009's fix, not an add-on. |
| **Fail-closed rollup semantics** (SRE lens: what a maintainer sees at 2am) | `skipped`, `unknown`, and "job never ran" all count as `!= success`. A rollup can be `COMPLETE`, `PARTIAL`, or `BLOCKED` — never `COMPLETE` by omission. | Small (already built) | `Workflow.rollup!/1` | **Have.** This is the one property every fix in this milestone must preserve, verbatim, per TODO-009/SEED-017/SEED-018. |
| **Post-publication proof runs on every publish path** | Whether a release ships via the ordinary graph or via exact-ref recovery, the same proof executes afterward and feeds the same rollup. No path to "published, never checked." | Medium | rollup, recovery workflow (`ios-mirror-backfill.yml` recovery mode), `exact-public-proof` job `needs:` | **Missing** — this is the single most important row in this table. `0.2.1`, Crosswake's only real release under this design, shipped via recovery and the proof never ran. Every other row in this document is downstream of fixing this one. |
| **Byte-exact published-artifact verification** | The bits an adopter's `mix deps.get`/`swift build`/Gradle actually pulls are compared, by digest, against what the approved candidate produced — not merely "the version number matches" or "it resolves." | Medium (exists for Hex-shaped tarballs; needs generalizing) | `ReleaseCandidate.Cleanroom.validate_public_artifacts!/3`, `digest_mismatch` | **Have the mechanism, wrong shape.** TODO-012: the check assumes one `candidate_ref` for six packages. The *guarantee* (byte-exact digest equality) must survive; the *scope* it applies to must change to match how packages are actually versioned. |
| **A realistic clean-room consumer proof, not a resolvability ping** | The proof reproduces what an adopter does: generate a host, declare a route, run the install step, run doctor — not just "the package compiles in an empty project." | Medium | `verify_companion_cleanroom.sh`, `mix crosswake.install`, `mix crosswake.doctor` | **Split personality.** The newer `--source-mode` matrix path (used by the Phase 168 candidate pipeline) already writes a real route with `crosswake:` route metadata into the generated router. The older positional-argument path (the one release-please's per-companion `clean-room-proof-*` jobs actually call) still writes a routeless "no routes required" stub and never runs `mix crosswake.install`. TODO-011 is specifically about the second, live-in-CI copy. |
| **A proof result the maintainer can act on without opening a log** | A failing check's own diagnostic message reaches the top-level status output; a maintainer never has to guess whether the harness is broken or the release is. | Small | `Crosswake.ReleaseStatus.scanner_ids_result/2`, `check_release_workflow_integrity.exs` output | **Broken today**, confirmed live on PR #164: the version-weld tripwire correctly fails CI with the exact right diagnostic (declared `0.2.2` vs. welded `0.2.1`), but `release_status.ex:806-820` reports the unrelated string `"missing scanner IDs: ..."` because the failing check produced no entry for the *other* IDs this call site happened to be asking about. The right failure, wrong explanation — see dedicated section below. |
| **Independent companion versioning without a shared release train** | Six packages (core + 5 companions) publish on their own schedules from their own commits, each carrying its own floor requirement on core, with no requirement that they share a ref. | Small (already the design) | `docs/COMPANION-PUBLISH-RUNBOOK.md`, D-15/D-16 | **Have, and it's the right call** — see Differentiators. The bug is that the *proof* (TODO-012) still assumes the opposite shape. |
| **A recovery path that is a first-class, reviewed operation — not an escape hatch** | Recovery (exact-ref republish of one missing coordinate after a `PARTIAL`) is bound to the same approved identity as the release it's recovering, requires the same review, and is exercised by CI/fire-drill before it's ever used for real. | Medium (mostly built) | `ios-mirror-backfill.yml` recovery mode, `recovery.ios.exact_identity_gate` | **Have**, per the runbook's "Scope of the iOS mirror recovery mode" section and the SEED-012 fire-drill lineage. This is a template for what TODO-009's generalized version-binding should look like. |
| **A single, discoverable release status command** | `mix crosswake.release.status [--json] [--live]` gives one bounded answer covering lockstep, compatibility floors, workflow guard posture, and (advisory) live registry truth. | Small (already built) | — | **Have.** Already v18.0 work; this milestone should extend its inputs, not its shape. |
| **Doctor as the shared consumer/CI diagnostic surface** | The same `mix crosswake.doctor` a real adopter runs is the one the clean-room proof runs, with no special-cased leniency for CI. | Small (already built, needs a stronger host) | `lib/crosswake/doctor/doctor.ex` | **Have the tool; the harness underuses it** (TODO-011). Do not narrow doctor to make the harness pass — SEED-014/TODO-011 both call this out explicitly as the wrong direction. |

**Cross-ecosystem grounding for this table:**

- **npm provenance / Sigstore attestations** and **PyPI Trusted Publishing** both moved the
  industry from "trust the publisher's laptop" to "cryptographically bind the published artifact
  to the exact CI run and source commit that produced it." Crosswake's `PHASE168_*` pinned
  identity + candidate receipt digest is the same idea implemented without a third-party
  transparency log — the mechanism (exact ref/tree/digest binding, not merely a version number)
  is the load-bearing part, and it's already right; TODO-009 is "keep this mechanism, stop
  hardcoding its one instance."
- **cargo-dist** (used by many Rust CLI projects) treats "build once, verify the same artifact
  ships to every channel" as the whole point of the tool — its `dist plan`/`dist build` separation
  mirrors Crosswake's `candidate-local` vs. `exact-public` split almost exactly. The lesson taken
  from cargo-dist: never rebuild-to-verify against a drifted source tree; verify the *actual
  published bytes*, which is exactly what `exact-public` fetches from Hex rather than rebuilding
  locally.
- **Go module checksum database (sumdb)** is the sharpest table-stakes lesson for "byte-exact
  proof": it does not attempt to prove *provenance* (who built it, from what commit) at all — it
  only proves *the bytes you got today are the same bytes everyone else got*, forever, via an
  append-only transparency log. That is a materially weaker and cheaper guarantee than
  Crosswake's approach, and it's worth knowing Crosswake is choosing the harder, better one
  (identity-bound, not just consistency-bound). Don't accidentally downgrade to sumdb's weaker
  guarantee while trying to make TODO-012 tractable.

---

## Differentiators

Where Crosswake's stated character — **honesty about what is proven, refusal to average mixed
results into success** — can produce a release story genuinely better than peer Elixir/Hex
projects, not just adequate.

| Feature | Value proposition | Complexity | Depends on |
|---|---|---|---|
| **A rollup vocabulary with five states, not two** (`BLOCKED`/`STALE`/`READY FOR APPROVAL`/`PARTIAL`/`COMPLETE`) surfaced identically whether the release used the ordinary path or recovery | Most Hex libraries (and most GitHub Actions release workflows generally) have exactly two visible states: green and red. A `PARTIAL` state that names which of six coordinates is live and which is not, with one bounded next action, is strictly more useful than a red X — and it's the natural fallback for TODO-012's structural problem rather than a workaround for it. | Small (the vocabulary exists; extend its inputs) | `COMPANION-PUBLISH-RUNBOOK.md` states table, `Workflow.rollup!/1` |
| **Per-package byte-exact proof scoped to each package's own approved ref** (TODO-012's option 2) | Turns "we cannot prove the family because it isn't one release" into "we prove each package byte-exactly against *its own* truth, and prove the *compatibility floors between them* separately." This is a stronger and more honest claim than most multi-package ecosystems make. Cargo workspaces and npm monorepos with independent-versioning tools (Lerna/Changesets in independent mode) do not typically attempt cross-package byte-exact proof at all — they settle for "each package individually verified, floors declared in manifests, trust the resolver." Crosswake can do both: byte-exact per package *and* a drift-tested compat matrix (already built) proving the floors are honest. | Medium | `verify_companion_cleanroom.sh` matrix path, `crosswake.release.candidate`, existing compat-matrix drift test |
| **The honest fallback when byte-exactness is structurally unattainable: prove reachability + compatibility instead of silently declaring success** | When a package's source has drifted from its publish tag (chimeway 2 files, threadline 1, rulestead 3, per TODO-012) and no ref can reproduce the exact published bytes, the correct answer is not "loosen the digest check" — it's "this package's byte-exact proof is `not_applicable: source_drifted_since_publish`, and its *reachability + compatibility-floor* proof runs instead, visibly labeled as the weaker claim it is." No averaging the two into one green checkmark. This is the same "PARTIAL never rolls back to look atomic" discipline already in the runbook, applied to proof strength rather than publish coordinates. | Medium | `Cleanroom.validate_public_artifacts!/3`, a new tri-state result type (`byte_exact` / `reachable_and_compatible` / `unproven`) | 
| **Recovery publications prove exactly as hard as ordinary ones — same proof, explicitly labeled by path** | Most projects' "oh no, the publish half-failed, let's manually push the missing artifact" moment is exactly the moment verification gets skipped, because whoever is doing the manual recovery is already under pressure and the tooling wasn't built for it. Crosswake's own only real release (`0.2.1`) proves this is a real failure mode, not a hypothetical. Making `exact-public-proof` run identically after recovery — with a `published_via: ordinary | recovery` field carried into the receipt — turns the exact scenario that skipped the proof into the scenario the proof is *designed for*. | Medium | rollup input schema, `ios-mirror-backfill.yml` recovery job, `exact-public-proof` `needs:` |
| **A realistic clean-room host that proves the install step, not just the compile step** (TODO-011's recommended option 1) | Declaring a real route + running `mix crosswake.install` before `doctor` means the proof exercises the actual first-hour adopter path the OSS-DNA doc calls out as the single strongest differentiator across the maintainer's whole portfolio ("install truth is product truth"). A green run after this change is evidence an adopter's first fifteen minutes will work — not evidence that `mix compile` doesn't crash. | Medium | `mix crosswake.install`, router metadata declaration (already present in the matrix path — needs porting to the positional path release-please actually calls) | 
| **Failure messages that name the actual failing check, every time, no exceptions** | This turns every proof lane into training material instead of noise. Given the specific, confirmed defect on PR #164 (right failure, wrong explanation), fixing `scanner_ids_result/2` to propagate the failing check's own message — not just its ID, not "missing" when it in fact ran and failed — is a small, mechanical, and disproportionately high-leverage fix: it is the seam through which *every future proof failure* in this pipeline will be read by a human. | Small | `lib/crosswake/release_status.ex:806-846` |
| **A closed loop from "found a gap in production" back into the release-proof vocabulary** | SEED-014 records six adopter-surfaced fidelity gaps that all reduce to the same root cause as TODO-011: a proof harness or diagnostic collapsing structured detail into something the caller can't act on. Treating "evidence surface fidelity" as one ongoing property (structured details survive to JSON, exit codes distinguish failure kinds, provenance fields are always real values or an explicit unknown sentinel — never a placeholder that looks real) is a differentiator most libraries never name explicitly, let alone hold as a standing bar. | Medium (partly a policy, partly the several small CW-REQ fixes) | SEED-014 items B/C/E/F |

**Lesson-with-mechanism, not just precedent:**

- **Oban** (Elixir job-processing library) is the closest in-ecosystem peer for "a library family
  the maintainer treats release discipline as a product feature." Oban Web/Pro's licensing and
  release notes are explicit about what version pairs are supported together — the mechanism
  worth copying is *publishing the compatibility matrix as a first-class, versioned artifact*,
  which Crosswake already does (the compat matrix + doctor rebuild-guidance from v14.0). Extend
  that same instinct to the release-proof vocabulary itself: publish what got byte-exact proof vs.
  reachability-only proof, per release, not just per package.
- **Broadway** and **Nerves** both ship "core + adapters/plugins" as separately versioned Hex
  packages with floor requirements, exactly like Crosswake's core+companions. Neither attempts a
  cross-package byte-exact linked release — they rely on Hex's own immutability + semver
  resolution. This is direct evidence that TODO-012's "independent companion versioning" design is
  the ecosystem-idiomatic choice, not a compromise Crosswake backed into.

---

## Anti-Features

Things that look like release rigor and are actually harmful. Each names a real project or
mechanism that learned this the hard way — not a hypothetical.

| Anti-feature | Why it's harmful | What actually happened | Instead |
|---|---|---|---|
| **Loosening byte-exact digest equality to "resolves and compiles"** | Turns the strongest guarantee Crosswake has into a reachability check indistinguishable from `mix deps.get` succeeding. TODO-012 explicitly forbids this ("do not relax the digest equality check... loosening it turns the proof into a reachability check"). | **event-stream (npm, 2018):** a maintainer transferred ownership of a widely-depended-on package to an unknown party who added a crypto-stealing payload; nothing about *compiling successfully* or *resolving from the registry* would have caught it — only artifact/provenance verification against a trusted baseline would have. npm's post-mortem response was **more** provenance binding (npm provenance attestations, 2023), not less. | Keep byte-exact equality wherever a stable candidate ref exists; where it structurally cannot (TODO-012's drifted-source case), label the weaker check honestly as weaker — see Differentiators — rather than quietly redefining "proof" downward. |
| **Making a single approved candidate ref cover multiple independently-released packages** (TODO-012 option 3, "genuinely link the family") | Solves the proof's shape problem by breaking the release design instead. Forces companion maintainers back onto a lockstep train Phase 141/16.0/17.0 deliberately tore apart, re-creating the "everyone waits on everyone else's release" bottleneck that led to companion extraction in the first place. | **Ecto** briefly considered (and community discussion repeatedly re-raises) fully lockstepping `ecto` + `ecto_sql` + adapters; the community consensus reason it doesn't is exactly this — a security patch to one adapter would force a version bump and re-release of every sibling, or worse, block on it. Crosswake's own `docs/COMPANION-PUBLISH-RUNBOOK.md` documents having already gone through this: "the five `crosswake_*` packages are independent companions... not members of the linked approval," stated as design, not aspiration. | TODO-012 option (2): per-package approved refs, one candidate_ref per manifest entry, proven byte-exactly against its own truth. |
| **Marking a proof that has never passed as non-blocking/advisory to make CI green** | Converts "we haven't proven this" into "green," which is indistinguishable from actually proven to anyone who doesn't read the runbook. TODO-011 explicitly forbids this: "Do not mark the lane non-blocking or delete the failing jobs. A proof that has never passed is a finding, not noise." | This is the exact failure mode the v22.0 retrospective names — **absence scored as success** — cataloged five separate times in SEED-018 (release-graph skip, moved-test citation exiting 0, negative-control regex no-op, exact-public proof's `needs:` skip, and a would-be globally-resolved inventory-path receipt check). Every one of those was green for months before being found. | Fix the harness (make the clean-room host realistic — TODO-011 option 1), then let the lane go green on its own merits. If it can't be fixed this milestone, leave it **red and named**, not muted. |
| **Weakening `doctor`'s `manifest_contract` check so a routeless clean-room stub passes** (TODO-011 option 2) | Narrows a real adopter-facing contract to accommodate a test harness — the harness stops testing the thing it exists to test. TODO-011 calls this "the same anti-pattern recorded in TODO-009" (weakening the check that gates the real behavior instead of fixing the thing being gated). | Directly analogous to **early PyPI package-name-squatting incidents** where registries loosened namespace validation to reduce upload friction, then had to re-tighten it after the loosened rule was exploited — weakening a validation gate to reduce friction for a benign case (here: a lazy test harness) opens the same gate for the actual failure the check exists to catch (a route-less manifest reaching a real adopter). | Make the clean-room host declare a real route and run `mix crosswake.install`, per TODO-011's recommended option 1 — the harness gets stronger, not the contract weaker. |
| **A merge-blocking "every collection assertion must be non-empty" guard shipped before the 173 existing sites are triaged** | A guard that immediately produces 173 findings does not get fixed — it gets waived, and "waived guard" teaches the team red is negotiable, which is strictly worse than no guard. SEED-018 states this directly as the reason it deliberately was NOT landed at v22.0 close, contrasting it with two sibling checks that shipped the same milestone with under five real findings each, fixed in the same change. | This is the general "boy who cried wolf" failure mode familiar from any **flaky-test suite that gets globally muted** rather than triaged — once a red signal is routinely ignored because acting on it is too expensive, the team stops looking at it at all, including on the one occasion it's catching something real. | Audit-then-guard, exactly as SEED-018 prescribes: classify the 173 sites, fix the ones derived from a wildcard/parse/filter at runtime, and only then add `absence.collection_assertion_non_empty`, scoped narrowly to those derivation shapes. Out of scope for v23.0 itself but a hazard to name if this milestone's own new proof checks are tempted to skip straight to "merge-blocking." |
| **A recovery mode with an unconstrained "old ref" input, justified as "we need flexibility for the unexpected recovery scenario"** | Recovery inherently deals with an unknown prior state (the runbook: "mirror `main` has diverged to a commit that cannot be known in advance") — the temptation is to make the whole operation permissive to match. That converts the one truly dangerous, irreversible operation in the pipeline (force-push over a public mirror) into the least-constrained one. | This is the generic shape of nearly every **"the emergency deploy button skips the checks" incident** — e.g., publicly documented outages where a break-glass/hotfix path bypassed the normal approval gate specifically because "we needed speed," and the bypass path became the one that shipped the bad change (widely discussed pattern in SRE postmortem culture; CrowdStrike's 2024 channel-file incident is the highest-profile recent instance of an emergency/rapid-deploy path skipping the validation the ordinary path had). | Crosswake's own mirror-recovery design gets this right today and should be the template: constrain everything *except* the one input that's genuinely unknowable (the lease/`expected_old_ref`, constrained by *shape* — 40-char lowercase object id, distinct from the new ref — rather than by value), and gate the identity check *before* checkout and *before* credential load. Any new recovery-adjacent surface this milestone touches (e.g. converging recovery onto the same exact-public proof) must keep this ordering. |
| **Treating a `BLOCKED` live-status probe (Hex/registry API unreachable) as equivalent to a confirmed-absent artifact** | Conflates "we don't know" with "it's not there." The runbook already names this distinction explicitly ("`missing` is a definite public absence; `unavailable` is an unknown after bounded retries... the operator copy must not call an unavailable probe a confirmed absence") and `check_release_version_truth.exs`'s `BLOCKED` state (shallow checkout, no tags visible) is a second instance of the same discipline. | Generic footgun in any registry-polling system — Maven Central's staging/close/release workflow has a long history of transient 5xx/timeout responses during propagation that naive tooling misreads as "not published," triggering redundant or destructive re-publish attempts. | Any new check this milestone adds (recovery-path proof, per-package byte-exact proof) must reuse the existing three-way vocabulary (`ok`/`fail`/`blocked`-as-unknown) rather than collapsing to boolean pass/fail. |

---

## The Four Carried-Forward Questions, Answered Directly

### 1. What "byte-exact" should mean operationally, and the honest fallback

**Operationally (Release engineer / supply-chain lens):** byte-exact means the SHA-256 (or
equivalent) digest of the exact tarball/artifact a real `mix deps.get` / `swift package resolve` /
Gradle dependency fetch pulls from the public registry/mirror is compared against the digest of
the artifact the *approved candidate* built from its recorded ref — not a digest computed by
rebuilding from `HEAD` today, and not a "same version number" check. Crosswake's
`Cleanroom.validate_public_artifacts!/3` already implements exactly this comparison; the defect is
scope (TODO-012), not mechanism.

**The honest fallback (Adopter-consumer lens: what can the adopter still trust?):** when the
approved-ref precondition cannot hold — because a package's source has drifted since its own
publish tag, which TODO-012 shows is already true for three of five companions — byte-exactness
against *that specific historical ref* is unattainable by definition, not by bug. The honest
fallback is not "rebuild at whatever ref is closest and accept a looser match." It is a
**named, weaker, separately-reported claim**: prove (a) the published artifact is reachable and
installs cleanly (resolvability — TODO-011's territory) and (b) its declared `crosswake` floor is
satisfiable and compatible per the existing drift-tested compat matrix — and report this as
`reachable_and_compatible`, distinct from and never merged into `byte_exact`. A maintainer or
adopter reading a release's proof summary should be able to tell, per package, which of the two
claims was made. This is the direct application of "never average mixed results into success"
(already a runbook principle for coordinate-level `PARTIAL`) to proof-*strength* rather than
proof-*coordinate*.

### 2. What a recovery publication must still prove, and how both paths converge

A recovery publication is not a lesser release — it is the release path most likely to be exactly
the one carrying a real defect, because something already went wrong once (that's why recovery
triggered). It must be required to run **the identical `exact-public-proof`** the ordinary path
runs: the same six-artifact fetch (or per-package fetch, post-TODO-012), the same five-profile
clean-room matrix, the same digest comparison against the same approved manifest, feeding the same
`Workflow.rollup!/1`.

Convergence mechanism (SRE lens — what happens at 2am when a release half-publishes): today
`exact-public-proof` `needs:` the *ordinary* `publish-hex`/`publish-ios-core`/`publish-android-core`
jobs, so recovery — which does not run those jobs, per the runbook's "Ordinary publication and
recovery" section — never satisfies the dependency and the proof silently skips. The fix is to
change what the proof `needs:` from "the ordinary publish jobs ran" to "the coordinates this
release is claiming to have published are, in fact, publicly live" — a condition both the ordinary
path and a completed recovery satisfy. Concretely: `exact-public-proof` should gate on the
rollup's own `successful_coordinates` output (which is already computed identically regardless of
path) rather than on which specific upstream jobs executed. The receipt should also carry a
`published_via: ordinary | recovery` field purely for operator legibility — it changes nothing
about what gets proven, only how the eventual `COMPLETE`/`PARTIAL` result is explained.

### 3. What the realistic clean-room host should do, step by step, and what each step proves

TODO-011 recommends option 1 (make the host realistic) over option 2 (narrow doctor), and SEED-014
independently arrives at the same conclusion for a sibling defect. Below is the step sequence,
each proving something the previous step could not, following the pattern already partially built
in the `--source-mode` matrix path (`matrix_write_host`) but missing from the legacy positional
path release-please's `clean-room-proof-*` jobs actually invoke:

1. **Resolve the published package from Hex against published core** (already done). *Proves:*
   the dependency graph is satisfiable by a real resolver hitting the real registry — not the
   monorepo's local paths.
2. **Compile the generated host with `--warnings-as-errors`** (already done). *Proves:* the
   package's public interface compiles cleanly outside the monorepo's own compile context (no
   accidental reliance on sibling test helpers, dev deps, or monorepo-only config).
3. **Declare a real Crosswake route in the generated router**, carrying real `crosswake:` route
   metadata (runtime mode, offline policy, security posture) — not a routeless stub. *Proves:*
   the manifest compiler can produce a non-empty `:routes` section from adopter-shaped input,
   which is the exact precondition `doctor`'s `manifest_contract` check requires and the exact
   thing the current routeless stub cannot supply (this is precisely the rindle failure TODO-011
   diagnoses).
4. **Run `mix crosswake.install`** before anything else touches config. *Proves:* the actual
   first-command an adopter runs — the one the OSS-DNA doc calls the single strongest
   differentiator pattern across the maintainer's whole portfolio ("install truth is product
   truth") — succeeds against the published artifact, including whatever config/runtime wiring
   `install` performs that a hand-written `config/runtime.exs` edit (today's shortcut) papers
   over or skips.
5. **Run the public-seam smoke test** (already done, per-profile). *Proves:* the package's
   documented public API behaves as its own contract claims — orthogonal to whether it installs.
6. **Run `mix crosswake.doctor --router <RealRouter>`** and require exit 0. *Proves:* the
   diagnostic surface a real adopter runs when something looks wrong agrees that everything set
   up in steps 3–5 is coherent — this is the step that currently fails, honestly, because steps 3
   and 4 were skipped. Fixing 3–4 should make this pass for its own right reasons rather than by
   loosening what doctor checks.
7. **Assert zero path-lock deps and a pinned exact companion version in `mix.lock`** (already
   done in the matrix path). *Proves:* the install pulled from the registry, not from a local
   path — i.e., that steps 1–6 tested what they claim to test and not an accidental monorepo
   leak.

The `--source-mode` matrix path already implements steps 1, 2, 3 (route declaration), 5, and 7. It
is missing step 4 (`mix crosswake.install`) and needs to be the version release-please's
per-companion `clean-room-proof-*` jobs actually call — today those jobs call the older positional
interface, which regressed to a routeless stub. **Porting the existing matrix-path host into the
per-companion CI jobs, then adding the missing `mix crosswake.install` step, closes TODO-011**
without touching `doctor` itself.

### 4. What the maintainer should SEE when any of this fails

**Confirmed live defect (Release engineer + SRE lens):** on PR #164, the version-weld tripwire
fires correctly — CI goes red — but `release-candidate-fixtures` reports `"root/native publish
jobs are not exact path-gated: missing scanner IDs: release.outputs.paths_released,
release.root_hex.path_gate, release.ios.path_gate, release.android.path_gate"`. That message never
mentions the weld, the declared version, or `SEED-017`. The maintainer sees a message about
missing scanner IDs and has every reason to suspect the scanner itself is broken, not the release.

**Root cause:** `Crosswake.ReleaseStatus.scanner_ids_result/2` (`lib/crosswake/release_status.ex:
806-846`), when the underlying `check_release_workflow_integrity.exs` run fails, classifies any
`required_id` this particular call site asked about — but that the script's output never got far
enough to emit — as **"missing,"** rather than checking whether the *script itself* reported a
different, already-failing check (the version weld) whose message explains why nothing downstream
ran.

**What the fix must produce, as an observable outcome:** when `workflow_integrity` carries
`%{status: :failed, checks: checks}` and none of `required_ids` appear in `checks` *because an
earlier, unrelated check already failed and the script stopped*, the reported message must lead
with that failing check's own id and message — e.g. `"release.version_weld.gates_match_declared_
version failed: .release-please-manifest.json declares \"0.2.2\" but the release graph is welded
to [\"0.2.1\"]..."` — with the originally-requested-but-unreached IDs listed afterward as
context ("also unreached: release.outputs.paths_released, ..."), not as the headline. A maintainer
reading the top-level status should be able to fix the actual problem without ever opening the
raw script log. This is a small, mechanical, high-leverage fix (propagate a message that already
exists one level down) — not a new capability — and it is the seam every other proof-failure this
milestone produces will be read through, so it should land early, ahead of or alongside TODO-009's
main fix, so that fix's own failure modes are legible while being built and tested.

---

## Feature Dependencies

```
TODO-009 (version-parametric release graph + per-release identity binding)
  └─→ enables: exact-public-proof running for any version (table stakes row 1, 5)
  └─→ enables: recovery-convergence fix (Q2) — needs the rollup's coordinate-based
      gating this same change should introduce
  └─→ must preserve: fail-closed rollup semantics (unchanged; verify with existing
      Phase 168 proof-test pattern)

release_status.ex scanner-message fix (Q4)
  └─→ should land early / in parallel — every other check this milestone adds surfaces
      through the same seam; fixing it first makes every subsequent fix's own CI
      failures debuggable without extra log-spelunking

TODO-011 (realistic clean-room host)
  └─→ independent of TODO-009/TODO-012 — can land first or in parallel
  └─→ depends on: porting the existing --source-mode matrix host (route + install
      steps) into the per-companion positional-path jobs release-please calls
  └─→ do NOT depend on: weakening doctor's manifest_contract check (explicitly ruled
      out by both TODO-011 and the anti-features table)

TODO-012 (per-package byte-exact scope)
  └─→ depends on: TODO-009's generalized identity binding — TODO-012's "per-package
      approved refs" replaces the single candidate_ref the same way TODO-009 replaces
      the single hardcoded version
  └─→ produces: the tri-state proof-strength vocabulary (byte_exact /
      reachable_and_compatible / unproven) that also answers Q1
  └─→ interacts with: TODO-011's realistic host — the reachable_and_compatible
      fallback IS effectively TODO-011's clean-room proof, run against a package
      whose byte-exact proof isn't attainable

SEED-018 (vacuous collection assertions)
  └─→ NOT in v23.0 scope directly, but any new merge-blocking check this milestone
      adds must avoid the same anti-pattern (audit-then-guard, not guard-then-waive)
```

**Recommended sequencing for a roadmapper:** (1) the `release_status.ex` message-propagation fix,
because it's small and makes every subsequent CI failure this milestone produces legible; (2)
TODO-011's realistic clean-room host, because it's independently landable and de-risks the harness
before it's asked to prove more; (3) TODO-009's version-parametric graph + per-release identity
binding, because TODO-012 depends on its generalized-identity pattern; (4) TODO-012's per-package
byte-exact scoping plus the recovery-convergence fix (Q2), since both consume TODO-009's output and
can likely land together as they touch the same `exact-public-proof` job and receipt schema.

---

## Sources

- `.planning/PROJECT.md` — milestone history, v22.0 closeout note on the unproven post-publication
  lane (HIGH confidence — primary project record)
- `.planning/todos/TODO-009-release-graph-welded-to-0-2-1.md`,
  `TODO-011-companion-cleanroom-lane-has-never-been-green.md`,
  `TODO-012-exact-public-proof-assumes-a-linked-six-package-release.md` — HIGH confidence, primary
  findings with line-level evidence
- `.planning/seeds/SEED-017-release-graph-version-generalization.md`,
  `SEED-004-cleanroom-proof-harness.md`, `SEED-014-proof-lane-and-doctor-fidelity.md`,
  `SEED-018-vacuous-collection-assertions.md` — HIGH confidence, primary project record
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` ("Carried into v23.0") — HIGH
  confidence
- `docs/COMPANION-PUBLISH-RUNBOOK.md` — HIGH confidence, current operator contract
- `script/verify_companion_cleanroom.sh` — HIGH confidence, read directly (both the
  `--source-mode` matrix path and the legacy positional path)
- `lib/crosswake/release_status.ex` (`scanner_ids_result/2`, lines ~806-846) and
  `lib/crosswake/release_candidate/workflow.ex` (`rollup!/1`) — HIGH confidence, read directly
- `prompts/crosswake-elixir-oss-dna.md` — HIGH confidence, primary project-character source
  ("install truth is product truth," "public contract honesty beats breadth," "proof lanes are
  part of the product")
- Cross-ecosystem lessons (npm provenance/event-stream 2018 incident, PyPI Trusted Publishing,
  cargo-dist plan/build split, Go sumdb transparency-log model, Ecto/ecto_sql independent
  versioning, Maven Central staging propagation delays, CrowdStrike 2024 channel-file incident as
  an instance of the emergency-bypass anti-pattern) — MEDIUM confidence, general industry
  knowledge rather than freshly fetched sources for this pass; directionally reliable and each
  cited for a specific mechanism rather than as a vague appeal to authority.
