# Phase 111: Generator Rewire, Clean-Room Proof & Release - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 111 makes the v5.0 standalone-package thesis **actually consumable by an outsider** and cuts the first real coordinated release:

- **Rewire `mix crosswake.gen.shell`** so the default (non-`--local`) iOS and Android templates emit *published* coordinates with the version derived at generate-time from `Application.spec(:crosswake)[:vsn]` — no hardcoded version literal, no monorepo relative-path / placeholder-org default.
- **Prove the thesis outside the monorepo** via a clean-room CI lane that scaffolds a host in `$RUNNER_TEMP`, runs `gen.shell`, and confirms `swift build` + `gradle build` resolve the published deps and compile.
- **Add a permanent published-dep parity guard** (sibling to the v10.0 `brand-structural` gate) that prevents the templates from regressing back to broken/monorepo coordinates.
- **Reconcile docs** to the published install truth (no 404 / unresolvable install route).
- **Cut Hex `0.1.2`** last, so the published Hex package and the generated shell deps are mutually consistent — and the iOS mirror tag + Android Maven artifact land at `0.1.2` in the same lockstep run.

**In scope:** template rewire (GEN-01/GEN-02), clean-room CI lane (PROOF-01), permanent parity check (PROOF-02), doc reconciliation (DOCS-01), the real `0.1.2` cut + post-cut `release-as` removal (REL-01).
**Out of scope:** new feature breadth, device/emulator real-hardware proof lanes, SPI submission beyond first-tag existence, companion extraction (all post-v11.0 per REQUIREMENTS Future).
</domain>

<decisions>
## Implementation Decisions

Requirements **GEN-01, GEN-02, PROOF-01, PROOF-02, DOCS-01, REL-01** are locked by `.planning/REQUIREMENTS.md`. Several gray areas were already pre-decided in Phase 110's CONTEXT (D-12, D-13, D-04, D-02) and are **carried forward, not re-asked**. The three decisions below resolve the genuinely-open gray areas surfaced this phase; each was deep-researched (ecosystem precedent + existing codebase infra) and the recommendations are mutually coherent.

### Carried forward from Phase 110 (do NOT re-litigate)
- **D-12 (110) — Version sourcing.** Inject version at generate-time from `Application.spec(:crosswake)[:vsn]`. When run from the Crosswake source checkout (not an installed dep) this returns `nil` → emit a clear error, never a literal/`nil` version. iOS uses `upToNextMajorVersion`/`from:` (NOT `exactVersion`, NOT `branch:`). This is the GEN-01/GEN-02 implementation contract.
- **D-13 (110) — Tag-name format consistency.** The `ios-mirror` job tags the mirror with the **same** `tag_name` output the `publish-hex` job uses (whatever release-please emits — `v0.1.2` vs bare `0.1.2`); pick one form, stay consistent across all three registries.
- **D-02 (110) — Target version is `0.1.2`** via the one-time `release-as: "0.1.2"` pin already in the release-please manifest.
- **D-04 (110) — Remove the `release-as` pin** in a `chore:` commit *immediately after* `0.1.2` ships (the #1 post-bootstrap footgun). This removal belongs to REL-01's tail.

### A. Clean-room proof sequencing (PROOF-01) — **verify-after-publish, permanent release-time lane**
- **D-01 — Verify-after, not gate-before.** Gate-before is logically incoherent: clean-room resolution requires the artifact to already exist on a registry, and every workaround (synthetic Hex pkg, fake mirror tag, tunneled Maven Local) would prove a *fake* path — violating the "install truth = product truth" DNA. The lane runs **after** the coordinated publish as the proof the cut actually produced resolvable, buildable artifacts.
- **D-01a — Wiring.** New `clean-room-proof.yml` (follows the `phaseNN-proof.yml` house precedent) attached to the release run: `needs: [release-please, publish-hex, ios-mirror, android-publish]`, gated `if: needs.release-please.outputs.releases_created`. Scaffolds a host project in `$RUNNER_TEMP` **outside** the monorepo (no `--local`, no `packages/` access), runs `mix crosswake.gen.shell ios` and `... android`, then `swift build` (macOS runner) + `gradle build` (ubuntu runner) to confirm the published deps resolve and compile.
- **D-01b — Pin to the just-cut version.** Pin resolution to `needs.release-please.outputs.version`, NOT `latest` — so a racing future release cannot cause a false pass.
- **D-01c — Registry propagation patience.** Maven Central propagation can take up to ~30 min after publish → poll with exponential backoff (mirroring the existing `publish-hex` hex.pm availability poll precedent). SwiftPM git-tag resolution is near-instant post-mirror-push but add a short retry for clock skew.
- **D-01d — Release-time only, not per-PR.** The clean-room lane requires live published coordinates, so its first green run happens right after the `0.1.2` cut. Per-merge regression protection is **D-02 (the static parity guard)**, not this lane — the two are complementary, not redundant. (Verifier note: success-criterion #2 is only literally satisfiable after REL-01's cut, which is in-phase; do NOT fail the phase for a lane that has no published artifact to resolve until the cut completes.)

### B. Published-dep parity check (PROOF-02) — **new static `ReadinessCheck` in existing `--check-publish` + test assertion**
- **D-02 — Extend existing doctor infra, don't build a standalone workflow.** `mix crosswake.doctor --check-publish` already exists (`Crosswake.Doctor.PublishReadiness`, `ReadinessCheck` struct with `blocking`/`proof_class`/`claim_scope`, wired via `check_publish?` + `build_checks/4`). A standalone CI workflow would duplicate the "render generator into tmp dir + parse coordinates" logic and add ~3 min BEAM startup for a ~100 ms assertion, with no structural benefit over a `blocking: true` / `proof_class: :merge_blocking` ReadinessCheck.
- **D-02a — Static parse, not live resolution.** Add a `generator_coordinate_parity` ReadinessCheck that `EEx.eval_file`s **both** `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` and `priv/templates/crosswake/shell/android/app/build.gradle.eex` with `local: false` and the live `Application.spec(:crosswake)[:vsn]`, then asserts the rendered output: (1) contains `github.com/szTheory/crosswake-shell-core-ios`; (2) contains `io.github.sztheory:crosswake-shell-core-android`; (3) contains the live `crosswake` version string; (4) contains **no** `XCLocalSwiftPackageReference` and **no** `project(':crosswake` (no monorepo/local leak). Live network resolution stays solely in the clean-room lane (D-01) — this guard is the cheap deterministic per-merge layer.
- **D-02b — Dual surface.** Mirror the same coordinate assertions in `test/.../crosswake_gen_shell_test.exs` so a plain `mix test` catches regressions locally (not only `--check-publish` in CI). This is the permanent brand-structural sibling fixture.

### C. Doc reconciliation (DOCS-01) — **`install.md` canonical; surgically fix `adoption.md`**
- **D-03 — `guides/install.md` stays canonical.** It already owns the numbered install walkthrough, is already in `PublishReadiness.@allowed_docs`, and is enforced by the existing `docs_support_parity_check`. No new `quickstart.md` — that adds surface and cross-link rot without solving the actual contradiction.
- **D-03a — Whitelist fix.** Add `"guides/adoption.md"` to `PublishReadiness.@allowed_docs` — it's already a `mix.exs` extra, so the whitelist is currently inconsistent with what's published.
- **D-03b — Reframe the one contradictory sentence.** `adoption.md` §1 currently says "Avoid generating host-owned shell code." Reframe (don't delete) to: the generated shell is a **thin host-owned wrapper** whose native deps (SPM + Maven) resolve from **published registries**, not vendored code — the eject trap is eliminated by the published-core architecture, *not* by avoiding generation. This makes the standalone-deps claim and the gen.shell thesis simultaneously true.
- **D-03c — Cross-links + truth pass.** `adoption.md` gains a header note pointing to `install.md` for the definitive install sequence; `install.md` gains a one-line back-reference to `adoption.md` for offline-sync architecture context. Reconcile `guides/support_matrix.md` and `CHANGELOG.md` to published truth (both already whitelisted). Zero 404 / unresolvable install routes anywhere.

### Claude's Discretion
- Exact CI job/step structure, runner matrix (macOS for `swift build`, ubuntu for `gradle build`), SHA-pins for any new actions (house standard: SHA-pin all new actions + `dependabot.yml`), and the precise poll/backoff script shapes — planner's/executor's call within D-01.
- The generated app's own `versionName`/`MARKETING_VERSION` (the adopter's *app* version, distinct from the Crosswake *dep* coordinate) is NOT a "satellite version" under GEN-01 — leave a sensible default; only the **dep coordinate version** must derive from `Application.spec`.
- Exact wording of the `adoption.md` reframe and cross-link copy, within D-03b/D-03c intent.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone intent
- `.planning/REQUIREMENTS.md` — GEN-01, GEN-02, PROOF-01, PROOF-02, DOCS-01, REL-01 (locked requirements for this phase); Out-of-Scope table.
- `.planning/ROADMAP.md` §"Phase 111" — goal + 5 success criteria.
- `.planning/PROJECT.md` §"Current Milestone: v11.0" — milestone goal + target features.

### Prior-phase decisions carried forward
- `.planning/phases/110-native-publish-lockstep-infrastructure/110-CONTEXT.md` — D-12 (version sourcing + `upToNextMajorVersion`/`from:`), D-13 (tag-name format), D-02 (`0.1.2` target), D-04 (`release-as` removal post-cut), D-01/D-05 (publish deferred to 111, success-criteria reinterpretation).
- `.planning/phases/110-native-publish-lockstep-infrastructure/110-HUMAN-UAT.md` — 4 deferred human-UAT items (Android fire-drill, lockstep-truth lane, GPG keyserver, Sonatype namespace) whose live execution gates the real `0.1.2` cut.

### Pre-gathered research (HIGH confidence)
- `.planning/research/SUMMARY.md` — version-propagation + release-trigger flow, A-before-B phase split, critical pitfalls.
- `.planning/research/STACK.md` — exact config blocks (Vanniktech, splitsh, release-please manifest, POM).
- `.planning/research/ARCHITECTURE.md` — component map, `ios-mirror`/`android-publish` job designs.
- `.planning/research/PITFALLS.md` — burned Maven version, hardcoded-satellite-version drift, `GITHUB_TOKEN` downstream-trigger.
- `.planning/research/REC-PIPELINE.md` — release-please footguns (release-as removal, first-release version), SHA-pinning/CVE-2025-30066.
- `.planning/threads/release-distribution-truth.md` — the canonical thread: per-platform distribution how-to, `doctor`/closeout parity-check graduation candidate.

### House style / vision
- `prompts/crosswake-elixir-oss-dna.md` — "install truth = product truth", "proof lanes are part of the product", "recovery-conscious publishing".

### Files this phase touches (verified to exist)
- Generator + templates: `lib/mix/tasks/crosswake.gen.shell.ex` (add version assign + nil-guard), `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` (lines ~53–62: fix org → `szTheory`, `exactVersion 0.1.0` → `upToNextMajorVersion`/`from:` + `<%= @version %>`), `priv/templates/crosswake/shell/android/app/build.gradle.eex` (line ~54: `dev.crosswake:shell-core-android:0.1.0` → `io.github.sztheory:crosswake-shell-core-android:<%= @version %>`).
- Parity guard: `lib/crosswake/doctor/publish_readiness.ex` (new ReadinessCheck + `@allowed_docs` add), `lib/crosswake/doctor/doctor.ex` (already wires `check_publish?`), `test/.../crosswake_gen_shell_test.exs` (coordinate assertions).
- Clean-room lane: new `.github/workflows/clean-room-proof.yml` (analog: `phaseNN-proof.yml`, `phase75-closeout-gate.yml`); `.github/workflows/release-please.yml` (existing publish jobs it `needs`).
- Docs: `guides/adoption.md`, `guides/install.md`, `guides/support_matrix.md`, `CHANGELOG.md`.
- Release: `mix.exs` (`@version` driven by release-please), `release-please-config.json`, `.release-please-manifest.json` (`release-as` removal post-cut).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`mix crosswake.doctor --check-publish` already exists** — `Crosswake.Doctor.PublishReadiness` with a `ReadinessCheck` struct (`id`/`code`/`category`/`severity`/`result`/`blocking`/`proof_class`/`claim_scope`/`docs_reference`/…) and a `build_checks/4` pipeline already wired into `doctor.ex` via `check_publish?`. The new parity guard is a NEW ReadinessCheck in this suite, not new infrastructure. Reuse `blocking: true` + `proof_class: :merge_blocking`.
- **`@allowed_docs` whitelist + `docs_support_parity_check`** in `publish_readiness.ex` already machine-checks guide presence (includes `install.md`, `support_matrix.md`, `CHANGELOG.md`; missing `adoption.md`).
- **`publish-hex` job in `release-please.yml`** already polls hex.pm for release availability post-publish — the propagation-poll precedent the clean-room lane copies for Maven Central.
- **`phaseNN-proof.yml` + `phase75-closeout-gate.yml` + `brandbook-verify.yml`** — the house CI-proof / closeout-gate / structural-gate patterns the clean-room lane and parity guard mirror.
- **`crosswake_gen_shell_test.exs`** already renders the generator into a tmp dir — coordinate assertions slot directly in.

### Established Patterns
- `render_template/3` in `gen.shell.ex` passes `assigns: [capabilities:, local:]` — add a `version:` assign here (fetched from `Application.spec(:crosswake)[:vsn]`, nil-guarded per D-12). Templates already branch on `<%= if @local do %>`.
- Hermetic-vs-advisory CI split: release/publish/proof jobs are triggered + deterministic. The clean-room lane is deterministic and gated on `releases_created`.
- SHA-pin all new GitHub Actions; `dependabot.yml` bounds maintenance.

### Integration Points
- The clean-room lane attaches to the SAME release run (`needs: [release-please, publish-hex, ios-mirror, android-publish]`) so it observes all three registries live at the just-cut version.
- `mix.exs @version` (release-please-driven) → `Application.spec(:crosswake)[:vsn]` is the single source for both the generated dep coordinates and the parity guard's expected version — one source, no drift.
</code_context>

<specifics>
## Specific Ideas

- Counter-example to avoid: **LiveView Native's hardcoded-satellite-version bug** — never hardcode a native dep version that can drift from the Hex version; derive both from `Application.spec`.
- Exemplar for verify-after: the existing `publish-hex` hex.pm availability poll → replicate the patience-loop shape for Maven Central (up to ~30 min propagation).
- Broken-state landmarks the rewire must eliminate: iOS template `repositoryURL = "https://github.com/crosswake/..."` + `kind = exactVersion; version = 0.1.0;`; Android `implementation 'dev.crosswake:shell-core-android:0.1.0'`.
- The clean-room lane proves the adopter JTBD literally: add Hex dep → `gen.shell` (default) → `swift build` + `gradle build` green, with zero manual coordinate correction.
</specifics>

<deferred>
## Deferred Ideas

- **Per-PR clean-room variant** — running live resolution+compile on every PR (not just release-time). Deferred: requires pre-published artifacts that don't exist between releases; the static parity guard (D-02) covers per-merge regression. Revisit only if release-time-only proves too coarse.
- **GitHub Immutable Releases / mirror landing-page README** — belt-and-suspenders carried from 110's deferred list; write the mirror README when the mirror is first seeded at the `0.1.2` cut.
- **Real device/emulator proof lanes, route-policy-101 / troubleshooting guides, companion extraction, SPI submission** — post-v11.0 (REQUIREMENTS Future).

None of the above is scope creep into 111 — all are correctly downstream or already covered by an in-phase guard.
</deferred>

---

*Phase: 111-generator-rewire-clean-room-proof-release*
*Context gathered: 2026-06-14*
