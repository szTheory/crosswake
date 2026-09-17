# Technology Stack — v23.0 Release Pipeline Repair & Proof-Lane Truth

**Project:** Crosswake
**Scope:** Toolchain additions/changes/removals to repair TODO-009 (version weld), TODO-011
(companion clean-room lane never green), TODO-012 (exact-public proof presupposes a linked
six-package release), and SEED-017 (generalize the release graph without loosening authority).
**Researched:** 2026-09-15
**Overall confidence:** MEDIUM-HIGH — the repo-internal findings (file/line citations) are HIGH
confidence (read directly). External claims about GitHub Actions primitives, Hex tarball
determinism, and comparator ecosystems are flagged per-claim; several are marked UNVERIFIED
because effort budget did not extend to exhaustive Context7/doc verification of every version
string.

## Headline Verdict

**Almost nothing needs to be *added* to the toolchain.** The three defects are architectural
(a version literal doing double duty as an authority gate, a legacy proof path that regressed
behind a newer one, and a schema that assumes a release shape the project doesn't use). The
correct fix in every case is to **generalize existing homegrown mechanisms**, not to bolt on
OIDC, environments, cosign, or SLSA tooling. Adding any of those now would consume v23 budget on
problems Crosswake doesn't have yet, while leaving the three named defects unrepaired.

| Option | Verdict | One-line reason |
|---|---|---|
| Fix `approved-release-guard`'s literal-string comparison → cross-file consistency check | **NOW** | This *is* TODO-009. No new tool; a code change in the existing guard job. |
| Collapse the legacy per-package clean-room path into the matrix `--source-mode` path | **NOW** | TODO-011's root cause already has a fix living 700 lines away in the same file. |
| Per-package `candidate_ref` in the approved manifest (TODO-012 option 2) | **NOW** | Matches D-15/D-16; smallest change that preserves byte-exact equality. |
| Rename `phase168-*` artifacts/env constants to release-scoped names | NOW (small) | Permanent supply-chain plumbing should not carry a phase number. |
| Retire `release.version_weld.gates_match_declared_version`, replace with a structural check | NOW (part of closing TODO-009) | A tripwire for a fixed weld is either dead or a footgun if kept. |
| Persist the exact-public proof digest beyond the 14-day artifact TTL | NOW (cheap) | "Proves itself... afterwards" is not durable if the proof evaporates in two weeks. |
| Remove all residual `splitsh-lite` references; standardize on `git subtree split` | NOW (cleanup) | Already the working mechanism; the segfaulting binary is dead weight. |
| GitHub OIDC / `id-token` for Hex publish | **NEVER (today)** | Hex.pm has no OIDC trusted-publishing surface to federate to. |
| GitHub OIDC for Maven Central | **NEVER (today, unverified)** | Central Portal auth is username/token, not OIDC, as far as verified here. |
| GitHub Environments + required reviewers on publish jobs | **LATER, optional, not a fix** | Gates on human click, not on ref/tree identity — weaker than what exists; do not use as a *substitute* for the guard. |
| `actions/attest-build-provenance` (Sigstore/SLSA attestations) | **LATER** | Real value depends on Hex.pm/Maven *consuming* attestations, which they don't yet. Could later replace the homegrown artifact/receipt lookup, but that's a bigger refactor than v23 needs. |
| cosign (raw CLI) | **NEVER** | Redundant with `attest-build-provenance`, which already wraps Sigstore for GH Actions. |
| SLSA provenance as a separate initiative | **NEVER as distinct work** | Subsumed by the attest-build-provenance decision above — same artifact, same verdict. |
| Hex package signing | **NEVER (doesn't exist)** | Hex has no package-signing surface today; nothing to adopt. |
| diffoscope for `digest_mismatch` triage | **LATER, nice-to-have** | Useful for humans debugging a mismatch; must not soften the pass/fail gate itself. |
| npm-provenance-style adopter-facing badge | **NEVER (not applicable)** | Hex.pm has no display/verification surface for it; would be a write-only artifact. |

---

## 1. The core fix is a comparison rewrite, not a new tool (TODO-009 / SEED-017)

**Lens: staff architect + release engineer.**

`approved-release-guard` (`.github/workflows/release-please.yml:74-79`) currently decides "is this
a linked candidate?" by grepping for the literal string `0.2.1` in three files:

```bash
grep -q '@version "0.2.1"' mix.exs &&
grep -q 'version = "0.2.1"' packages/crosswake-shell-core-android/build.gradle.kts &&
jq -e '."." == "0.2.1" and ... == "0.2.1"' .release-please-manifest.json
```

The fix is to replace the three-literal-equality check with a **three-way self-consistency**
check: read the version out of each of the three files and assert they are **equal to each
other**, whatever the value is. That single change is the entire "accept any version" half of
SEED-017. It requires zero new GitHub Actions primitives — it is a `jq`/`grep` rewrite in the
same `guard` step (lines 74-79).

The five job-level `if:` conditions that additionally hardcode `== '0.2.1'`
(`publish-hex:223`, `publish-ios-core:525`, `publish-android-core:571`, `exact-public-proof:728`,
plus the `approved-release-guard` literal itself) should drop the version comparison entirely and
gate on `needs.approved-release-guard.outputs.linked_release == 'true'` alone, combined with the
existing per-path `contains(fromJSON(paths_released), ...)` checks that already exist on
`publish-hex`/`publish-ios-core`/`publish-android-core`. **This is safe, not a weakening**,
because `linked_release` is only ever `true` after the guard has independently verified
head/tree/base parentage and the exact-head candidate receipt (`release-please.yml:81-150`) — the
version equality was never doing authority work; it was doing *scope* work ("is this the linked
release, as opposed to a companion-only release"), and the three-way self-consistency check
preserves that scope test without freezing it to one number.

`lib/crosswake/release_candidate/workflow.ex:7-11` (`@coordinates`) and
`lib/crosswake/release_candidate/cleanroom.ex:236` (`Map.fetch!(by_package, "crosswake").version
== "0.2.1"`) carry the same disease and need the same cure: derive the expected version from the
approved manifest/receipt at runtime instead of a compile-time atom map. `@coordinates` should
interpolate `hex:crosswake@<version>` from the bound version, not hardcode `0.2.1`.

**Do not** reach for GitHub Environments, required reviewers, or OIDC to "generalize the
authority" — none of them encode "this exact head, this exact tree, this exact candidate receipt
digest." They encode "a human with environment-approval permission clicked a button" or "this
workflow run has a federated identity," neither of which is what `approved-release-guard` needs
to keep proving. Swapping the existing mechanism for either would be a **regression** relative to
what's already built, not a generalization of it.

## 2. GitHub Actions primitives, one by one

**Lens: release engineer / DevOps-SRE**, with explicit hold/fail behavior under re-run and
recovery.

### OIDC / `id-token`
Not usable for the Hex publish leg: Hex.pm has no OIDC trusted-publisher registration flow
comparable to PyPI's or npm's (npm's is itself young — provenance via OIDC, not auth-replacing
trusted publishing, since npm still uses tokens for auth). **Unverified but high confidence**:
searches surfaced no `id-token`/OIDC federation endpoint in Hex's publish API as of this
research. For Maven Central (Sonatype Central Portal), publishing still authenticates with a
username/password-shaped Portal token in this codebase
(`ORG_GRADLE_PROJECT_mavenCentralUsername/Password`); no OIDC exchange was found in Central
Portal's current documented flow (**unverified** — worth a 15-minute doc check before committing
to NEVER permanently, but nothing in this repo or in general knowledge suggests it exists today).
**Verdict: NEVER for this milestone.** Revisit only if Hex.pm or Sonatype ship OIDC support —
track as a dormant seed, not v23 scope.

### Environment protection rules + required reviewers
GitHub Environments can force a job to pause for a named reviewer's approval before running.
This is a real, cheap, GitHub-native gate — but it answers a *different* question
("did an authorized human click approve on this deployment") than what `approved-release-guard`
already answers ("is this exact head/tree/base and candidate receipt digest what was approved").
Layering an environment approval on top of the existing guard is **defense-in-depth, not a
substitute**, and it is explicitly out of scope for closing TODO-009/011/012 — none of the three
defects is "we lack a human click," they are "the graph can't run for any version" / "the proof
never exercises what an adopter does" / "the proof assumes a release shape we don't use." **NOW: do
not add. LATER: consider only as a second, independent gate — never as a replacement.**

### `concurrency`
Already correctly used: `group: release-please-${{ github.workflow }}-${{ github.ref }}`,
`cancel-in-progress: false` (`release-please.yml:24-26`). Under a re-run this holds: GitHub Actions
"re-run failed jobs" replays only failed/selected jobs within the *same* run, preserving
succeeded jobs' outputs — the receipt/output-passing pattern below depends on this and it is
already sound. No change needed.

### Artifact attestations (`actions/attest-build-provenance`)
This action wraps Sigstore keyless signing (via GitHub's OIDC-backed Fulcio/Rekor instance for
public repos) to produce an in-toto SLSA provenance predicate bound to a named artifact + digest,
verifiable later with `gh attestation verify`. **This is architecturally the same primitive
Crosswake has hand-rolled**: the `phase168-candidate-receipt-<head>` artifact + the
`gh api .../actions/artifacts` lookup + `sha256sum` binding in `approved-release-guard`
(`release-please.yml:96-140`) is a bespoke, non-transparency-logged version of what
`attest-build-provenance` + `gh attestation verify` give you off the shelf, with a public,
independently-auditable Rekor log entry instead of a private GH Actions artifact API call.
**Verdict: LATER.** It is a legitimate simplification target — it would let
`approved-release-guard` replace ~40 lines of `gh api`/`jq` artifact-hunting with a single
`gh attestation verify` call — but it is a *refactor of a system that currently works*, and v23's
budget is better spent making the graph publish any version and making the proofs actually run.
File as a seed for a future "harden the candidate-receipt mechanism" milestone rather than
attempting it inside this repair.

### Job outputs vs. artifacts
The existing split is correct and should be kept: small identity scalars (`approved_head`,
`approved_tree`, `candidate_receipt` sha256, `merge_oid`) travel as job `outputs`
(`release-please.yml:36-45`), while the full receipt JSON and CI artifacts travel as uploaded
artifacts fetched with `gh run download` keyed by a name containing the head SHA
(`phase168-candidate-receipt-${approved_head}`). This is the idiomatic GitHub Actions pattern
(outputs are size-capped and meant for scalars; artifacts are for bulky/structured payloads) and
it is also the *only* way to bind approval evidence produced in one workflow run
(`workflow_dispatch` of "iOS mirror authority") to a *different* run (the `push`-triggered
release-please run) — job outputs do not survive across separate runs, only within one.

**One concrete change**: drop the `phase168-` prefix from the artifact-name convention
(`phase168-candidate-receipt-<head>`, `phase168-candidate-ci-<head>`, `exact-public-proof-0.2.1`,
`linked-release-status-0.2.1`, `native-release-status`). A phase number baked into a permanent
release-infrastructure naming convention is exactly the kind of literal this milestone is trying
to remove elsewhere; a future maintainer reading `phase168-candidate-receipt-*` five milestones
from now has no reason to know that means "the exact-identity candidate receipt." Rename to
`release-candidate-receipt-<head>` / `release-candidate-ci-<head>` /
`exact-public-proof-<version>` / `linked-release-status-<version>`, parameterizing the version
suffix from the bound version rather than a literal, alongside the TODO-009 fix (SEED-017 already
flags "the candidate-receipt artifact naming convention" as in-scope).

### Behavior under re-run / recovery — the actual second gap
TODO-009's second gap (`exact-public-proof` `needs:` the ordinary `publish-*` jobs, so recovery
publications never run it) is a **workflow-graph shape problem**, not a missing primitive. The
fix: factor the "fetch six packages from the registry and clean-room-prove them" logic (already
isolated behind `verify_companion_cleanroom.sh --source-mode exact-public`) into a **reusable
workflow** (`on: workflow_call`) that both `release-please.yml`'s `exact-public-proof` job and the
recovery workflows (`hex-publish.yml`, `ios-mirror-backfill.yml`) can invoke, gated on "the
approved-guard's `linked_release` output is true and the artifacts are confirmed live on the
registries" rather than on "the ordinary publish jobs in *this* run succeeded." Reusable
workflows are a stock GitHub Actions feature (already implicitly modeled by this repo's separate
recovery workflows); no third-party tool is needed.

## 3. Byte-exact Hex tarball verification

**Lens: Elixir/Hex maintainer + release engineer.**

- `mix hex.build` (shipped in `hex`, invoked internally by `mix hex.publish`) produces a package
  `.tar` with four members: `VERSION`, `CHECKSUM`, `metadata.config`, and `contents.tar.gz`.
  `contents.tar.gz` is the actual `:files` (per `mix.exs`) tarred and gzipped; `metadata.config`
  is an Erlang-term-encoded map of package metadata (name, version, requirements, `:build_tools`,
  elixir-version requirement, etc.), derived from `mix.exs` at build time.
- **What determines the digest, concretely:**
  1. The exact set of files matched by each package's `mix.exs` `:files` list/glob. If a glob
     relies on directory-iteration order rather than a sorted or explicit list, tar member
     ordering can vary across filesystems/OSes even when contents are identical byte-for-byte —
     this is the classic reproducibility footgun (same class as the one Debian's reproducible
     builds project documents for tar-based archives).
  2. Whatever `metadata.config` derives dynamically from the build environment — e.g. an
     `:elixir` requirement computed via `System.version()` instead of a literal string in
     `mix.exs` would make the metadata (and therefore the outer digest) depend on which Elixir ran
     `mix hex.build`. This repo already pins the exact toolchain via `erlef/setup-beam` +
     `.tool-versions` + `version-type: strict` on every publish job — **keep this**; it is the
     correct control for reproducibility across CI re-runs.
  3. `mix_hex_tarball`/`hex_core`'s own tarball construction: Hex's changelog records a fix for
     "package tarballs being reproducible" (confirmed via search; **exact hex version and date
     UNVERIFIED** — worth pinning down before writing a phase plan, but the property exists in
     current `hex`/`hex_core`). Gzip member timestamps and ordering are the two classic leaks this
     kind of fix addresses.
- **What Crosswake already does correctly** (`script/verify_companion_cleanroom.sh`'s
  `matrix_fetch_public_family`, `Crosswake.ReleaseCandidate.Artifact.inspect_cli!`): it compares
  the **outer tarball's sha256** (`payload_digest`) plus a `metadata_digest`, fetched via `mix
  hex.package fetch <pkg> <version> --output <tarball>` (a real `hex` mix task, not a bespoke HTTP
  call) and unpacked via `:mix_hex_tarball.unpack/2` (the same Erlang primitive `hex` itself
  uses). This is the right granularity — compare what Hex actually serves, byte for byte, not a
  reachability check. **Do not weaken this to "compiles" or "resolves."**
- **No off-the-shelf tool does the local-build-vs-registry-served diff for Hex** the way, say,
  `npm diff` or reproducible-builds tooling does for other ecosystems. The homegrown mechanism
  here is the correct scope of tool to have; nothing in the Hex/Elixir ecosystem replaces it.
- **One cheap, concrete addition (NOW):** audit each of the six packages' `mix.exs` `:files` lists
  for reliance on unsorted globs, and add a one-line check (fits naturally in
  `check_release_workflow_integrity.exs`) asserting `:files` entries are either literal file lists
  or use a glob pattern combined with an explicit `Enum.sort/1` in any place that turns the glob
  result into the files list — cheap insurance against a reproducibility footgun that would
  otherwise show up as an intermittent, hard-to-explain `digest_mismatch` months from now.
- **LATER, not NOW:** `diffoscope` (the Debian reproducible-builds diffing tool) as a
  human-readable side channel when `digest_mismatch` fires, to show *what* differs instead of
  just failing closed. Valuable for debugging, not for the gate itself, which must stay exact.

## 4. Provenance/signing options — for each, NOW/LATER/NEVER with reasoning

**Lens: release engineer / supply-chain security**, benchmarked against named comparators.

| Option | Verdict | Reasoning |
|---|---|---|
| Hex package signing / audit | **NEVER** | Does not exist on Hex.pm today; there is nothing to adopt. The closest available control is scoping the `HEX_API_KEY` write secret to exactly the package names it publishes, and rotating it — verify this is already true of the key backing `HEX_API_KEY` in this repo (not confirmed in this research pass). |
| sigstore/cosign (raw CLI signing of the tarball) | **NEVER** | Redundant with `actions/attest-build-provenance`, which already wraps Sigstore for GitHub Actions with less workflow YAML. If cosign is ever adopted, it should be via that action, not the bare CLI. |
| SLSA provenance | **LATER, same artifact as attest-build-provenance** | `attest-build-provenance`'s predicate already is SLSA-shaped in-toto provenance. Treating "adopt SLSA" as separate work from "adopt attest-build-provenance" would be double-counting the same decision. |
| GitHub artifact attestations (`actions/attest-build-provenance` + `gh attestation verify`) | **LATER** | Real, adoptable, and would let the existing hand-rolled candidate-receipt lookup shrink — but it changes a system that currently passes its own tests, and neither TODO-009, TODO-011, nor TODO-012 requires it. Revisit as a follow-on hardening milestone once the version weld and proof-lane defects are closed. |
| npm-provenance-style adopter-facing badge/verification | **NEVER, as currently shaped** | npm provenance's actual value is registry-side: npmjs.com renders a badge and `npm audit signatures`/`npm install` can check it. Hex.pm has no analogous consumption path, so producing an attestation today would be write-only — a private good for Crosswake's own CI, not a public trust signal adopters can check. Worth reconsidering only if Hex.pm ships attestation support (track as a dormant seed, do not build speculative infrastructure against a registry feature that doesn't exist). |

## 5. `splitsh-lite` vs `git subtree split` — durable choice: `git subtree split`

**Lens: DevOps-SRE (blast radius, one-way doors) + release engineer.**

`git subtree split` is already the mechanism actually wired into the trusted publish path
(`release-please.yml:566`: `git subtree split --prefix=packages/crosswake-shell-core-ios
'${{ ... merge_oid }}' | tail -1`, feeding `--expected-new-ref` into `ios_mirror.sh publish`).
This is the right, durable choice:

- It ships with `git` itself — no separate binary to install, pin, or watch for
  segfaults (the observed failure mode of `splitsh-lite v1.0.1` in this repo).
- It produces a deterministic split SHA for a given prefix + ref, which is exactly the property
  the `--expected-new-ref` fast-forward-only push check needs.
- It has no version-currency risk: there's nothing to upgrade or that can drift out from under
  the workflow the way a third-party Go binary release can.

**Action for v23:** grep the tree for any residual `splitsh-lite` references (docs, scripts,
`.tool-versions`-style pins, comments) and remove them. Do not keep `splitsh-lite` installed "as a
fallback" — a segfaulting fallback that nobody exercises is worse than no fallback, because it
will be trusted the one time someone reaches for it. If a script needs comparing against the
mirror's prior state, do it with `git ls-remote` (already used at `release-please.yml:565`) plus
`git subtree split`, both git-native.

## 6. What to remove or simplify (not generalize)

1. **The legacy positional-argument clean-room path in `script/verify_companion_cleanroom.sh`
   (lines ~745-1150, the non-`--source-mode` branch)** is the direct cause of TODO-011. Its
   router stub is *literally* commented `# minimal router stub — no routes required for doctor
   smoke (Open Question 1)` (line 1143) — the same "Open Question 1" SEED-004 already flagged as
   an open assumption. Compare this to the newer `--source-mode candidate-local`/`exact-public`
   matrix path's `matrix_write_host` function (lines 388-412), which already patches a **real**
   route with `metadata: %{crosswake: [...]}` into the router before running doctor — i.e. the
   fix TODO-011 recommends (option 1: "make the clean-room host realistic") **already exists**,
   700 lines away in the same file, built for the candidate/exact-public matrix path. The
   per-package `clean-room-proof-rulestead`/`-rindle`/`-sigra`/`-chimeway`/`-threadline` jobs in
   `release-please.yml` (which `needs: publish-hex-*`, per TODO-011's breadcrumbs) should be
   **deleted and replaced** by invoking the matrix path (parameterized to a single profile, or
   simply always running all five as `exact-public` already does) rather than patched forward.
   Maintaining two proof implementations of the same guarantee at different fidelity is the kind
   of debt that produces exactly this class of defect — one path silently regressed while the
   other advanced. Collapsing to one implementation is a **removal**, not new tooling, and it
   closes TODO-011 for rindle/sigra/threadline simultaneously (their three "separate causes" are
   plausible symptoms of running the weaker of two implementations).
2. **The single global `candidate_ref` requirement** (`verify_companion_cleanroom.sh:207`) and
   the hardcoded six-package expected list baked into both the shell script (lines 151-158, 209)
   and `Crosswake.ReleaseCandidate.Cleanroom.validate_approved_artifacts!/1`
   (`cleanroom.ex:218-240`, including the `.version == "0.2.1"` literal at line 236). Per TODO-012
   recommendation (2): replace the single `candidate_ref` with **one ref per package entry** in
   the approved manifest, dropping the false invariant "all six came from one commit" without
   dropping the true invariant "each one's published bytes match what was approved for it."
   `crates.io`/cargo-release is the relevant comparator here (see §7): crates.io has *no* concept
   of a linked, single-ref multi-crate release at all — every crate publishes and is verified
   independently, which is the shape Crosswake's five companions already have by design (D-15/
   D-16). Crosswake's "linked" invariant should stay scoped to the three coordinates that are
   genuinely one release unit (Hex core, iOS mirror tag, Maven artifact) and not be
   force-fitted onto the five companions that were deliberately built to *not* need it.
3. **`release.version_weld.gates_match_declared_version`**
   (`script/check_release_workflow_integrity.exs`) — TODO-009 already says to retire this as part
   of closing the finding. Do not leave it in place "just in case": once the gates no longer
   compare against a literal, the check's `welded == []` branch will be permanently true and it
   becomes silent, untested scaffolding — replace it with a structural assertion ("no
   `publish-*`/`exact-public-proof` job's `if:` contains a bare semver literal; each depends only
   on `approved-release-guard` outputs and per-path containment") so a future regression back
   toward hardcoding is still caught, without keeping a check that references a version this
   milestone is explicitly retiring.
4. **`phase168-*` / `-0.2.1` naming in artifact names, job names ("Prove exact public 0.2.1
   artifacts", "Linked 0.2.1 release rollup", "Guard exact approved 0.2.1 merge"), and the
   `linked-release-status-0.2.1` / `exact-public-proof-0.2.1` artifact names** — cosmetic, but
   worth doing in the same pass as the literal-comparison fix, because leaving stale version
   numbers in job *names* (as opposed to gate conditions) after generalizing the gates is exactly
   the kind of "right failure, wrong explanation" defect TODO-009 already caught once
   (`Crosswake.ReleaseStatus`'s scanner-id-swallowing bug, noted in TODO-009's addendum). Fix that
   `scanner_ids_result/2` propagation bug (`lib/crosswake/release_status.ex:806-820`) in the same
   milestone — it's the same root habit (a fixed/renamed thing not fully renamed) manifesting one
   layer up the stack, in the operator-facing message rather than the CI gate.
5. **Do not add** GitHub Environments, OIDC, cosign, or a bespoke SLSA pipeline in this
   milestone (see verdict table). Each is either inapplicable to Hex/Maven today or answers a
   question this milestone isn't asking.

## 7. Cross-ecosystem lessons, named

**Lens applied throughout: what did comparator ecosystems get right or build a footgun on.**

- **cargo-release / crates.io** — every crate publishes and is verified independently; there is
  no "linked six-crate release" concept at all. **Lesson:** Crosswake's five independent
  companions matching this shape is correct and battle-tested elsewhere; the mistake was ever
  writing a proof (`exact-public-proof`) that presupposed the *opposite* shape for them. TODO-012
  is Crosswake re-discovering the boundary crates.io drew from day one.
- **npm provenance** — its value is registry-side consumption (npmjs.com badge, `npm audit
  signatures`), not merely production-side signing. **Lesson:** don't adopt a provenance-signing
  step judged by "does GitHub have a nice action for it"; judge it by "does the consuming registry
  do anything with it." Hex.pm doesn't yet, so the ROI for Crosswake today is much lower than
  npm's actual ROI for npm-registry packages.
- **Maven Central staging (`nexus-staging-maven-plugin` / Central Portal validated-upload → drop)**
  — a two-phase upload-then-release flow that lets you verify before the one-way door. **Lesson:**
  Crosswake's `android-publish-fire-drill` job (validated-upload → DROP, dispatch-only,
  `release-please.yml:966-1064+`) already mirrors this correctly. No change needed; this is a
  place the existing toolchain already matches the industry-standard pattern.
- **Go module proxy + sumdb** — an append-only, permanent public transparency log recording the
  first-seen hash of every module version, forever. **Lesson:** Crosswake's
  `exact-public-proof-0.2.1` artifact is retained only 14 days
  (`release-please.yml:759-764`, `retention-days: 14`); a proof designed to demonstrate "this
  release's public bytes matched approval, permanently provable" undercuts its own purpose if the
  evidence expires in two weeks. **Concrete NOW fix:** either raise `retention-days` substantially
  (GitHub Actions supports up to 400 days repo-wide, org policy permitting — **unverified exact
  current cap for this org**, check before committing to a number) or, better, commit the
  resulting digest/state summary to the repository (e.g. a `docs/release-ledger/<version>.json` or
  an entry appended to `CHANGELOG.md`) so the proof outlives any artifact-retention policy — this
  is the durable-record property sumdb has and Crosswake's current design doesn't.
- **PyPI trusted publishing** — pure OIDC, no long-lived publish tokens at all. **Lesson:** this
  is the standard Crosswake's Hex/Maven legs cannot yet reach (§4), but the iOS mirror leg's
  `MIRROR_DEPLOY_KEY` (a static SSH deploy key, per SEED-003) *could* eventually move toward a
  short-lived, auto-rotating GitHub App installation token (minted via
  `actions/create-github-app-token`, itself backed by the workflow's own OIDC identity) instead of
  a long-lived deploy key. That's the one place in this stack where an OIDC-adjacent primitive is
  actually reachable today. **Verdict: LATER** — not blocking any of the three v23 defects, but a
  reasonable follow-on hardening once the deploy-key path (already working per Phase 153) is not
  under active repair.
- **Bazel/Nix reproducibility** — full content-addressed, byte-exact-by-construction build
  systems. **Lesson:** wildly disproportionate for an Elixir Hex library family; Crosswake's
  lightweight "build the tarball, unpack both sides, sha256 compare" approach is the right-sized
  analog and should not be escalated toward a hermetic build system.
- **Elixir-world comparators (Phoenix, Ecto, Nerves, Broadway, Oban)** — all publish via plain
  `mix hex.publish` from CI with an API-key secret and release-please or a hand-maintained
  changelog; none run a post-publish byte-exact re-verification, none bind a cryptographic
  candidate-receipt to the merge that triggered release, and none coordinate a multi-registry
  linked release the way Crosswake's core+iOS+Android bundle does. **Lesson (Elixir/Hex maintainer
  lens):** Crosswake's mechanism is unusually rigorous for this ecosystem — justified by the
  multi-registry fan-out risk that motivated it, but a signal to resist further gold-plating
  (OIDC, environments, attestations) until the three concrete defects are closed. The idiomatic
  Elixir-library move here is "fix the two comparisons and collapse the duplicate proof path,"
  not "adopt a supply-chain framework this ecosystem doesn't use anywhere else."

## 8. File-by-file landing map for the planner

| Fix | File(s) | What changes |
|---|---|---|
| TODO-009 core weld | `.github/workflows/release-please.yml:74-79` | Replace `grep '0.2.1'`/`jq == "0.2.1"` triple with a three-way equality check across the same three files. |
| TODO-009 job gates | `.github/workflows/release-please.yml:223,525,571,728` | Drop `needs.release-please.outputs.version == '0.2.1'`; keep `linked_release == 'true'` + existing `paths_released` containment. |
| TODO-009 coordinates | `lib/crosswake/release_candidate/workflow.ex:7-11` | `@coordinates` interpolates the bound version instead of a literal `0.2.1`. |
| TODO-009 recovery gap | `.github/workflows/release-please.yml:718-728` + `hex-publish.yml` + `ios-mirror-backfill.yml` | Factor the exact-public verification into a `workflow_call` reusable workflow both the ordinary and recovery paths invoke. |
| TODO-009 tripwire retirement | `script/check_release_workflow_integrity.exs` (`release_version_weld`) | Retire the exact-`0.2.1` tripwire; replace with a "no bare version literal in a publish gate" structural check. |
| TODO-009 message-loss follow-on | `lib/crosswake/release_status.ex:806-820` | `scanner_ids_result/2` must propagate a failed scanner's own message instead of reporting "missing IDs." |
| TODO-011 root fix | `script/verify_companion_cleanroom.sh` | Delete the legacy positional-arg path (~L745-1150); route all per-package proof through the `--source-mode` matrix path's `matrix_write_host`/`matrix_write_smoke`. |
| TODO-011 workflow cleanup | `.github/workflows/release-please.yml` (`clean-room-proof-rulestead`/`-rindle`/`-sigra`/`-chimeway`/`-threadline` jobs) | Replace with invocations of the matrix path (or fold into the same reusable workflow as exact-public-proof). |
| TODO-012 schema fix | `script/verify_companion_cleanroom.sh:151-158,206-209` and `lib/crosswake/release_candidate/cleanroom.ex:218-240` | Replace single global `candidate_ref` + hardcoded `.version == "0.2.1"` with a per-package `candidate_ref`/expected-version map. |
| Durable proof record | `.github/workflows/release-please.yml:758-764` | Raise `retention-days` and/or commit the exact-public result summary into the repo (e.g. `docs/release-ledger/`). |
| splitsh-lite cleanup | repo-wide grep for `splitsh-lite` | Remove; `git subtree split` (already used at `release-please.yml:566`) is the sole mechanism. |
| Artifact naming | `release-please.yml` artifact `name:` fields, `workflow.ex` receipt filenames | Drop `phase168-`/`-0.2.1` branding; parameterize by bound version or drop the version suffix entirely where the artifact is inherently single-per-run. |

## 9. Explicitly out of scope for v23 (do not add)

- OIDC/`id-token` federation for Hex or Maven publishing (unsupported by the registries).
- GitHub Environments + required reviewers as a replacement for `approved-release-guard`.
- `actions/attest-build-provenance`, cosign, or a standalone SLSA-provenance initiative — real
  candidates, but for a later hardening milestone, once TODO-009/011/012 are closed and the
  candidate-receipt mechanism is stable enough to be worth refactoring.
- Hex package signing (does not exist).
- Bazel/Nix-style hermetic build systems.
- An npm-provenance-style adopter-facing badge (no Hex.pm consumption surface to render it).

## Sources

- Repo-internal (HIGH confidence, read directly): `.planning/PROJECT.md`,
  `.planning/todos/TODO-009-*.md`, `TODO-011-*.md`, `TODO-012-*.md`,
  `.planning/seeds/SEED-017-*.md`, `SEED-003-*.md`, `SEED-004-*.md`,
  `.github/workflows/release-please.yml`, `script/verify_companion_cleanroom.sh`,
  `lib/crosswake/release_candidate/workflow.ex`, `lib/crosswake/release_candidate/cleanroom.ex`,
  `script/check_release_workflow_integrity.exs`, `docs/COMPANION-PUBLISH-RUNBOOK.md`,
  `prompts/crosswake-elixir-oss-dna.md`.
- [actions/attest-build-provenance](https://github.com/actions/attest-build-provenance) — GitHub
  Marketplace/repo description of the Sigstore-backed SLSA attestation action (v4 wraps
  `actions/attest`). MEDIUM confidence, general web search, not independently verified against
  the org's current Actions marketplace pins.
- [Using artifact attestations to establish provenance for builds — GitHub Docs](https://docs.github.com/actions/security-for-github-actions/using-artifact-attestations/using-artifact-attestations-to-establish-provenance-for-builds) — MEDIUM confidence.
- [hexpm/hex CHANGELOG](https://github.com/hexpm/hex/blob/main/CHANGELOG.md) — confirms a past fix
  for package tarball reproducibility; **exact version/date UNVERIFIED** in this pass.
- [mix hex.build — Hex docs](https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html) — MEDIUM confidence,
  general tarball-structure description.
- General knowledge (not independently re-verified this session, standard/stable facts): cargo/
  crates.io per-crate independent publish model; npm provenance's registry-side consumption
  model; Sonatype Central Portal's validated-upload/release two-phase flow; Go module proxy/sumdb
  transparency-log design; PyPI trusted publishing's OIDC model. Treat any specific version number
  attributed to these outside of the two web-searched citations above as **unverified**.
