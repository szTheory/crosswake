# Phase 110: Native Publish & Lockstep Infrastructure - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 110 builds and wires the **publish machinery + lockstep versioning** for the two native cores, and **proves the publish path without performing a real release**:

- iOS subtree-mirror CI (`splitsh-lite` → `szTheory/crosswake-shell-core-ios`) wired and dry-run-pushed.
- Android Maven Central publish config (Vanniktech `0.31.0` → Central Portal, `io.github.sztheory`) wired and proven via a **validated-upload→drop** dry-run that does NOT burn a version coordinate.
- `release-please` converted to multi-package manifest mode with `linked-versions` so one Release PR advances Hex + iOS tag + Android Maven to identical versions.
- One-time GPG/Sonatype/secrets provisioning **recorded** (SETUP.md) and **verified** by an automated fail-fast preflight.

**The first REAL coordinated publish (all three at `0.1.2`) happens at the END of Phase 111**, after `gen.shell` templates are rewired. This is forced by lockstep: a real native publish in 110 would also cut a Hex release at the same version while `gen.shell` still emits broken coordinates — shipping adopters the exact broken scaffold this milestone exists to fix.

**In scope:** publish config, CI jobs, lockstep manifest, credential setup + verification, dry-run/proof lanes, mirror repo creation + protection.
**Out of scope (Phase 111):** template rewire, clean-room CI proof, `doctor --check-publish` parity check, doc reconciliation, the actual `0.1.2` cut.
</domain>

<decisions>
## Implementation Decisions

Requirements PUB-01, PUB-02, PUB-03, LOCK-01, LOCK-02 are locked by `.planning/REQUIREMENTS.md`. The decisions below resolve the gray areas those requirements left open. All four were deep-researched (ecosystem precedent, footguns, DX); recommendations are mutually coherent.

### A. Version & first-publish sequencing

- **D-01 — Defer the real publish to 111; 110 proves the path.** Phase 110 wires ALL machinery and proves the native publish path via the Central Portal validated-upload→drop (D-07) + an iOS mirror dry-run push. **No real release, no burned coordinate** in 110. The single real coordinated lock-step publish (Hex + iOS tag + Android Maven, all `0.1.2`) is the cut at the end of Phase 111. *Rationale: versioning is lock-step, so any real native publish in 110 forces a same-version Hex release while `gen.shell` still emits broken coordinates → broken scaffold for adopters.*
- **D-02 — Target version is `0.1.2`** (honors REL-01 + existing `mix.exs`), reached via a one-time `release-as: "0.1.2"` pin on the lock-step Release PR. The researcher's "natural math → 0.1.1" is overridden: REL-01, ROADMAP, and `mix.exs` all name `0.1.2`.
- **D-03 — Prerelease canary REJECTED.** A `-rc` tag proves nothing: SwiftPM `from:`/`upToNextMajorVersion` and Hex `~>` both EXCLUDE prereleases from default constraints, and Maven Central burns `-rc` versions permanently. Validated-upload→drop is strictly better (proves the live path, frees the coordinate). Do not introduce prerelease versions on any of the three registries.
- **D-04 — Drift reconciliation (done in 110).** Current drift: `mix.exs`=`0.1.2`, Hex=`0.1.0`, manifest=`0.1.0`. Reconcile by: (1) **revert `mix.exs @version` to `0.1.0`** so release-please can write the correct version at the cut; (2) keep manifest `.`=`0.1.0`, add an Android package entry baselined at `0.1.0`; (3) add `linked-versions` plugin; (4) add one-time `release-as: "0.1.2"` to the `.` entry. The iOS mirror tag is driven by `needs.release-please.outputs.version`/`tag_name`, NOT a manifest entry. **Remove the `release-as` pin in a `chore:` commit immediately after `0.1.2` ships** (Phase 111) — the #1 post-bootstrap footgun is leaving it in.
- **D-05 — Success-criteria reinterpretation for 110.** SC#1/#2/#4 ("resolves/visible at 0.1.2", "one run advances all three") are only *literally* satisfiable at 111's cut. Within 110 the equivalent proof is: validated-upload reaches VALIDATED then dropped; splitsh produces a resolvable tree pushed to the mirror; lockstep manifest configured + a lockstep-truth assertion job green. The verifier must NOT fail 110 for lacking a live `0.1.2` artifact.

### B. Credential / provisioning ownership

- **D-06 — Pre-provision out-of-band; the plan only verifies (fail-fast).** Human completes all credential setup before execution, guided by a **SETUP.md** that Phase 110 produces. The automated preflight asserts presence and fails fast. *Rationale: the GSD executor is non-interactive (no browser OAuth / TTY / keygen); Maven immutability makes mid-run stalls dangerous; 12-factor "pipelines verify, humans provision."*
- **GPG primary-key-only keypair (footgun caught).** Generate a primary key WITH signing capability and **no signing subkey** (`gpg --quick-generate-key "szTheory <qiksnare13@gmail.com>" rsa4096 sign 0`). Maven Central rejects subkey-only exports with a non-obvious "Invalid signature for file" error. Export with `gpg --export-secret-keys --armor <KEYID>` for `signingInMemoryKey`.
- **Secret layout (8 repo secrets, Vanniktech in-memory convention, Sonatype *user token* not login):** `HEX_API_KEY` (scope `package:crosswake`, already exists), `ORG_GRADLE_PROJECT_mavenCentralUsername`/`…Password` (Central Portal **user token**), `ORG_GRADLE_PROJECT_signingInMemoryKey`/`…KeyId`/`…KeyPassword`, `MIRROR_PUSH_TOKEN` (fine-grained PAT, `Contents:write` on the mirror repo ONLY), `RELEASE_PLEASE_TOKEN`. All repository-scoped, not org.
- **Per-credential verification:** namespace has **no status API** → the validated-upload→drop (D-07) IS the namespace check; GPG key presence via keyserver lookup (`keys.openpgp.org` VKS by-fingerprint + `keyserver.ubuntu.com` HKP); secrets via `gh secret list` name-only comparison. PAT *scope* is not API-checkable → presence-only assert, true scope validated by the first mirror-push run; document the limitation.

### C. Dry-run gate depth (PUB-03)

- **D-07 — Local asserts THEN Central Portal validated-upload→drop.** First, `./gradlew publishToMavenLocal` and assert `~/.m2` contains the AAR, sources jar, javadoc jar, POM, and a `.asc` for each + POM completeness (name/description/url/license/developers/scm). Then a real Central Portal **USER_MANAGED** upload → poll until `VALIDATED` → **DROP** (`DELETE /api/v1/publisher/deployment/{id}`). *Confirmed authoritatively: immutability is scoped to the PUBLISHED state only; a VALIDATED deployment is droppable and frees the version coordinate.* This is the load-bearing proof that makes D-01 safe.
- **Vanniktech 0.31.0 specifics:** `publishToMavenCentral(SonatypeHost.CENTRAL_PORTAL)` defaults to USER_MANAGED (`automaticRelease=false` → stops at VALIDATED). **Never** `publishAndReleaseToMavenCentral` / `automaticRelease=true` on the first publish. The `mavenCentralAutomaticPublishing` property does NOT exist in 0.31.0 (use `SONATYPE_AUTOMATIC_RELEASE=false` if going the properties route). 0.31.0 does **not log the deployment ID** → retrieve it via the Portal deployments API by deployment name before the DELETE; handle `FAILED` (retain, don't drop) and timeout; ensure no dangling deployment on CI crash.
- **D-08 — Make it a permanent reusable lane.** Wire the validated-upload→drop as a permanent `workflow_dispatch` "fire-drill" lane (separate from the release publish job), reused as the mandatory pre-publish rehearsal before every future release. *House DNA: "proof lanes are part of the product", "recovery-conscious publishing."*

### D. Mirror bootstrap & tag protection

- **D-09 — Empty repo, CI seeds on first release.** Create `szTheory/crosswake-shell-core-ios` as an empty public repo; the first `ios-mirror` CI run seeds it on 111's release (pushing the split SHA to `refs/heads/main` on an empty remote is well-defined — no manual seed needed). The mirror stays empty through 110; idiomatic (Apollo iOS per-release push model). SPI (`SwiftPackageIndex/PackageList`) submission waits until the first real tag exists (Phase 111) — submitting earlier shows a worse "no releases" state.
- **D-10 — Tag immutability: no-`--force` CI is load-bearing; ruleset is defense-in-depth.** The structural guarantee is "CI push command has no `--force` + job gated on `releases_created`" (git rejects non-fast-forward tag updates by default). Add a GitHub **repository ruleset** via `gh api POST /repos/szTheory/crosswake-shell-core-ios/rulesets` (`target: tag`, rules `non_fast_forward` + `deletion`, `enforcement: active`, conditions `refs/tags/*`) as defense-in-depth. This is a **different API surface** than the legacy branch-protection UI that was harness-blocked before; it is free-tier + non-interactive (`--input ruleset.json`). Treat the ruleset as best-effort (don't block the phase on it); the no-`--force` discipline is the durable guard.
- **D-11 — Drop `--scratch`.** PITFALLS.md's recommendation to pass `splitsh-lite --scratch` in CI is **incorrect for stateless GitHub-hosted runners** (`.git/` is rebuilt fresh each run, so the BoltDB cache never exists → `--scratch` is a no-op). Use plain `splitsh-lite --prefix=packages/crosswake-shell-core-ios/`. `--scratch` is recovery-only (local/self-hosted persistent runners after a force-push).

### Cross-cutting DX (adopter JTBD)

- **D-12 — `gen.shell` version sourcing guard (Phase 111 template work, decided now).** Version must be injected at generate-time from the installed Hex package via `Application.spec(:crosswake)[:vsn]`. When run from the Crosswake source checkout (not as an installed dep) this returns `nil` — emit a clear error, never a literal/`nil` version. Use `upToNextMajorVersion`/`from:` (not `exactVersion`, not `branch:`) so adopters get patches without regenerating; `Package.resolved` preserves reproducibility.
- **D-13 — Tag-name format consistency.** Confirm whether release-please emits `v0.1.2` vs bare `0.1.2`; the `ios-mirror` job must tag the mirror with the **same** `tag_name` output the existing `publish-hex` job uses, so lockstep holds. SwiftPM/SPI accept either form — pick one and stay consistent.

### Claude's Discretion
- Exact CI job structure, step ordering, SHA-pins for new actions (house standard: SHA-pin all new actions; `dependabot.yml` for maintenance — see REC-PIPELINE.md), and the precise preflight/assertion script shapes are the planner's/executor's call within the decisions above.
- POM field values and `build.gradle.kts` publish block details follow STACK.md verbatim.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone intent
- `.planning/REQUIREMENTS.md` — PUB-01/02/03, LOCK-01/02 (locked requirements for this phase); Out-of-Scope table (immutable-version reuse, independent versioning, binary distribution).
- `.planning/ROADMAP.md` §"Phase 110" — goal + 5 success criteria (read alongside D-05's reinterpretation).

### Pre-gathered research (HIGH confidence — "no research phase needed")
- `.planning/research/SUMMARY.md` — executive summary, stack, A-before-B phase split, version-propagation + release-trigger flow diagrams, critical pitfalls list.
- `.planning/research/STACK.md` — exact Vanniktech `0.31.0` config block, splitsh CI job, release-please manifest shape, POM metadata (reproduced verbatim — follow it).
- `.planning/research/ARCHITECTURE.md` — the 9 modified + 3 new components, `ios-mirror`/`android-publish` job designs.
- `.planning/research/PITFALLS.md` — burned Maven version, GPG keyserver, re-tag checksum mismatch, `GITHUB_TOKEN` downstream-trigger, hardcoded-satellite-version drift. (NOTE: its `--scratch` recommendation is overridden by D-11.)
- `.planning/research/REC-PIPELINE.md` — release-please footguns (manifest off-by-one, first-release version, Actions PR permissions), SHA-pinning/CVE-2025-30066, HEX_API_KEY scoping, manual-recovery workflow.
- `.planning/research/REC-VERSIONING.md` — versioning policy (`bump-minor-pre-major: false`), lockstep mechanics.
- `.planning/threads/release-distribution-truth.md` — the canonical thread: ecosystem footguns, per-platform distribution how-to, `doctor`/closeout parity-check graduation candidate.

### House style / vision (informs DX + "install truth" posture)
- `prompts/crosswake-elixir-oss-dna.md` — "install truth = product truth", "release truth matters", "recovery-conscious publishing", proof-lanes-are-part-of-the-product.
- `.planning/PROJECT.md` §Key Decisions — v5.0 standalone-package thesis, hermetic-vs-advisory CI split.

### Files this phase touches (verified to exist)
- `mix.exs` (`@version`), `release-please-config.json`, `.release-please-manifest.json`, `.github/workflows/release-please.yml`
- `packages/crosswake-shell-core-android/build.gradle.kts` (add Vanniktech + POM), `packages/crosswake-shell-core-ios/Package.swift`
- Phase-111 template targets (decided here, edited there): `lib/mix/tasks/crosswake.gen.shell.ex`, `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`, `priv/templates/crosswake/shell/android/app/build.gradle.eex`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing `publish-hex` job in `.github/workflows/release-please.yml` already uses the correct `needs: release-please` + `if: release_created` pattern and SHA-pinned actions — the `ios-mirror` and `android-publish` jobs mirror its structure (LOCK-02 compliance comes for free by copying it).
- `release-please-config.json` already has `bootstrap-sha`, `bump-minor-pre-major: false`, `bump-patch-for-minor-pre-major: true`, changelog-sections — extend it (add packages + `linked-versions`), don't rewrite.
- The iOS `Package.swift` is already correctly structured for source distribution (`.library(name: "CrosswakeShellCore", …)`); nothing about the package itself changes — only the mirror repo + CI job are missing. Keep product name `CrosswakeShellCore` coupled to the template reference.

### Established Patterns
- Hermetic-vs-advisory CI split (v3.2 graduation): release-please job = advisory (non-blocking); publish/proof jobs = triggered + deterministic. New jobs follow this.
- SHA-pin all new GitHub Actions; `dependabot.yml` (github-actions ecosystem) bounds the maintenance cost.

### Integration Points
- All native publish jobs attach to the SAME `release-please.yml` workflow under `needs: release-please` so the lock-step release event fans out to Hex + iOS + Android in one run (LOCK-02).
- `mix.exs @version` is the single source of truth; release-please `extra-files` + `Application.spec(:crosswake)[:vsn]` derive everything downstream.
</code_context>

<specifics>
## Specific Ideas

- Exemplars to copy: **Apollo iOS** (git-subtree per-release mirror push), **LiveView Native** (`Application.spec(...)[:vsn]` generate-time injection — and its hardcoded-satellite-version bug as the counter-example to avoid).
- Exemplars' footguns to avoid: Capacitor branch-pinning SPM deps (#7735) and relative-path default (#6040); `release: published` trigger that `GITHUB_TOKEN` silently never fires.
- Central Portal validated-upload→drop is the spiritual successor to OSSRH staging "close → inspect → drop" — keep it as a permanent rehearsal lane (D-08).
</specifics>

<deferred>
## Deferred Ideas

- **GitHub Immutable Releases** (GA Oct 2025) as a third tag-protection layer — only applies if the mirror CI creates GitHub Release objects (not just annotated tags). Optional belt-and-suspenders; not required (D-10's no-`--force` + ruleset suffice). Revisit if a `gh release create` step is added to the mirror job.
- Mirror landing-page README ("read-only distribution mirror; develop at canonical repo; no issues/PRs here") — write it when the mirror is first seeded in Phase 111.
- All Phase 111 scope (template rewire, clean-room CI lane, `doctor --check-publish` parity check, `guides/adoption.md` + `support_matrix.md` reconciliation, the real `0.1.2` cut) — explicitly out of 110.
- Post-v11.0 (already in REQUIREMENTS Future): real device/emulator proof lanes, route-policy-101 / troubleshooting guides, companion extraction.

None of the above is scope creep into 110 — all are correctly downstream.
</deferred>

---

*Phase: 110-native-publish-lockstep-infrastructure*
*Context gathered: 2026-06-14*
