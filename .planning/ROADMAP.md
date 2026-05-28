# Roadmap: Crosswake

## Milestones

- ✅ **v1.0 Route-Policy Substrate** — Phases 1-5 shipped on 2026-05-17.
- ✅ **v2.0 Adopter Stress Profiles** — Phases 6-10 shipped on 2026-05-19. Full archive: [.planning/milestones/v2.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Capability Contract And Packaging** — Phases 11-14 shipped on 2026-05-20. Full archive: [.planning/milestones/v3.0-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.0-ROADMAP.md)
- ✅ **v3.1 Native Capabilities and Bridge Expansion** — Phases 15-18 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.1-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.1-ROADMAP.md)
- ✅ **v3.2 Commerce And Entitlement Seams** — Phases 19-25 shipped on 2026-05-27. Full archive: [.planning/milestones/v3.2-ROADMAP.md](/Users/jon/projects/crosswake/.planning/milestones/v3.2-ROADMAP.md)
- 🟡 **v3.3 Release Readiness** — Phases 26-32 in progress.

## Phases

<details>
<summary>✅ v3.2 Commerce And Entitlement Seams (Phases 19-25) — SHIPPED 2026-05-27</summary>

- [x] Phase 19: Commerce Route Corridors (3/3 plans) — completed 2026-05-27
- [x] Phase 20: Entitlement Lifecycle Semantics (4/4 plans) — completed 2026-05-27
- [x] Phase 21: Reconciliation Example (2/2 plans) — completed 2026-05-27
- ⊘ Phase 22: Commerce Support, Review, And Proof — decomposed by audit into Phases 23+24 before execution
- [x] Phase 23: Commerce Support And Proof Closure (4/4 plans) — completed 2026-05-27
- [x] Phase 24: Reconciliation Traceability Hardening (3/3 plans) — completed 2026-05-27
- [x] Phase 25: Tech-debt closure (Phase 20 verification text + Phase 24 parity test WR-01/02) (2/2 plans) — completed 2026-05-27

</details>

### v3.3 Release Readiness (Phases 26-32)

- [x] **Phase 26: Package Metadata Audit** — Replace placeholder `source_url`, set explicit OTP/tarball name, declare `:files` allowlist, add three-link `:links`, add `LICENSE`, wire `docs/0` + `ex_doc` dev dep.
- [ ] **Phase 27: Versioning Decision And CHANGELOG Synthesis** — Pin `@version "0.1.0"`, synthesize `CHANGELOG.md` (Keep-a-Changelog, `[Unreleased]` anchor, single `[0.1.0]` capability entry, planning-vs-hex preamble, roadmap traceability footnote).
- [ ] **Phase 28: release-please Configuration Files** — Add `release-please-config.json` (oarlock pattern, `release-as: "0.1.0"` pin, `bootstrap-sha`), `.release-please-manifest.json` baselined at `0.0.0`, `.tool-versions` for reproducible builds.
- [ ] **Phase 29: Release Workflows And Supply-Chain Hardening** — Add `release-please.yml` (oarlock template, NOT sigra), `hex-publish.yml` recovery workflow, SHA-pin all GitHub Actions, add `dependabot.yml` for Actions ecosystem.
- [ ] **Phase 30: Hex Page Polish And Tarball Dry-Run** — Audit `README.md` for absolute URLs, run `mix hex.build --unpack` + `mix docs` + `mix hex.publish --dry-run` clean, with no `.planning/`/`prompts/`/`test/` leakage.
- [ ] **Phase 31: First Hex Publish (Human-Gated)** — Maintainer flips `default_workflow_permissions=write`, installs `HEX_API_KEY` secret, merges release-please's Release PR; `https://hex.pm/packages/crosswake/0.1.0` goes live.
- [ ] **Phase 32: Post-Publish Cleanup** — Remove one-time `release-as` pin, run smoke install from fresh `mix new`, update `guides/install.md` with canonical `{:crosswake, "~> 0.1"}` snippet.

### 📋 Next Milestone (Planning)

To be defined after v3.3 ships. Recommended next per `MILESTONE-ARC.md` and post-v3.2 assessment: **v3.4 Commerce Archetype Proof (ARCH-02)** — re-run a subscription/paywall adopter-shaped exemplar lane against the v3.2 seam using a mocked storefront corridor.

## Phase Details

### Phase 26: Package Metadata Audit
**Goal**: `mix.exs` accurately points to the real GitHub repo and declares an honest, complete `:package` block so the hex.pm page renders without broken links or placeholder text.
**Depends on**: Nothing (first phase of v3.3)
**Requirements**: META-01, META-02, META-03, META-04, META-05, META-06
**Success Criteria** (what must be TRUE):
  1. `grep -n "@source_url" mix.exs` returns a module attribute pointing to `https://github.com/szTheory/crosswake` (NOT `github.com/example/crosswake`). **Human-gated:** the real repo URL is confirmed before this phase can pass.
  2. `mix.exs` `:package` block contains `name: "crosswake"`, `licenses: ["Apache-2.0"]`, an explicit `:files` allowlist including `lib/`, `priv/`, `.formatter.exs`, `mix.exs`, `README.md`, `LICENSE`, `CHANGELOG.md`, `guides/`, and a `:links` map with `"GitHub"`, `"Docs"`, and `"Changelog"` keys.
  3. `LICENSE` file exists at repo root and contains an Apache-2.0 declaration matching the `:licenses` field.
  4. `mix.exs` defines a `docs/0` function with `main: "readme"`, `source_ref: "v#{@version}"`, and an extras list that includes every file in `guides/`.
  5. `{:ex_doc, "~> 0.38", only: :dev, runtime: false}` appears in the `deps/0` list and `mix deps.get && mix compile` succeeds with no warnings.
**Plans**: 4 plans
- [x] 26-01-PLAN.md — Create LICENSE file with canonical Apache-2.0 boilerplate
- [x] 26-02-PLAN.md — Introduce @source_url, extend project/0, replace defp description and defp package with canonical block
- [x] 26-03-PLAN.md — Add docs/0 function and ex_doc dev dependency (NO CHANGELOG.md in extras per D-12)
- [x] 26-04-PLAN.md — Verify mix deps.get && mix compile --warnings-as-errors and run ROADMAP success-criteria final sweep

### Phase 27: Versioning Decision And CHANGELOG Synthesis
**Goal**: Lock the first published hex version at `0.1.0` and produce a `CHANGELOG.md` whose shape release-please can parse and whose content honestly describes what 0.1.0 delivers.
**Depends on**: Phase 26
**Requirements**: VER-01, LOG-01, LOG-02, LOG-03, LOG-04
**Success Criteria** (what must be TRUE):
  1. `mix.exs` `@version` module attribute is set to `"0.1.0"` and `mix compile` succeeds.
  2. `CHANGELOG.md` exists at repo root, uses Keep-a-Changelog format, and contains a `## [Unreleased]` H2 anchor placed above the first versioned entry.
  3. `CHANGELOG.md` contains exactly one `## [0.1.0]` entry with 4–5 capability bullets (route policy DSL, manifest + capability ladder, bounded bridge with v3.1 families, offline contracts, commerce + entitlement seams with reconciliation example) and an explicit "no provider adapters yet, no first-party companions yet" non-claim.
  4. `CHANGELOG.md` preamble explicitly disambiguates internal `v1.0`–`v3.2` planning labels (in `.planning/MILESTONES.md`) from hex semver versions; the `[0.1.0]` entry includes a `### Roadmap traceability` subsection linking `.planning/MILESTONES.md` and `.planning/PROJECT.md`.
**Plans**: TBD

### Phase 28: release-please Configuration Files
**Goal**: Land the three release-please config artifacts on disk so the workflow added in Phase 29 has a manifest, a config, and a tool-versions file to read.
**Depends on**: Phase 27
**Requirements**: REL-01, REL-02, REL-09
**Success Criteria** (what must be TRUE):
  1. `release-please-config.json` exists at repo root with `release-type: "elixir"`, `bump-minor-pre-major: false`, `bump-patch-for-minor-pre-major: true`, a one-time `release-as: "0.1.0"` pin on the `.` package, and a `bootstrap-sha` anchored to a commit before v3.3 to prevent backwards CHANGELOG walk through 25 phases of non-conventional commits.
  2. `.release-please-manifest.json` exists at repo root with exactly `{".": "0.0.0"}` — NOT `"0.1.0"` (prevents the off-by-one footgun where release-please would propose `0.2.0` first).
  3. `.tool-versions` exists at repo root and pins Elixir + Erlang/OTP versions; running `cat .tool-versions` shows lines for both runtimes and `mix compile` works against the pinned versions locally.
**Plans**: 1 plan
- [ ] 28-01-PLAN.md — Create release-please-config.json, .release-please-manifest.json, and .tool-versions

### Phase 29: Release Workflows And Supply-Chain Hardening
**Goal**: Land both release workflow files (Release PR creation + manual recovery) and bake in supply-chain hardening so post-CVE-2025-30066 tag-move attacks cannot affect Crosswake's release pipeline.
**Depends on**: Phase 28
**Requirements**: REL-03, REL-04, REL-05, REL-06
**Success Criteria** (what must be TRUE):
  1. `.github/workflows/release-please.yml` exists, was built from the oarlock canonical template (NO `sync_release_summary.sh` job, NO `needs: sync-release-summary` reference), uses the singular `release_created` output, and contains a `publish-hex` job gated on `if: needs.release-please.outputs.release_created == 'true'`.
  2. `.github/workflows/hex-publish.yml` exists as a `workflow_dispatch` manual-recovery backup with `tag` and `release_version` inputs, runs the same `mix compile --warnings-as-errors`/`mix test`/`mix hex.publish --dry-run` sequence as the automated job, and includes the `mix hex.publish --yes` step.
  3. `grep -E "uses: .+@[a-f0-9]{40}" .github/workflows/release-please.yml .github/workflows/hex-publish.yml` lists every external action (`actions/checkout`, `erlef/setup-beam`, `actions/cache`, `googleapis/release-please-action`) pinned to a full commit SHA with a `# vX.Y.Z` comment; no `@vN`-tag references remain in either file.
  4. `.github/dependabot.yml` exists with `package-ecosystem: "github-actions"` so SHA pins surface as PRs when upstream Actions ship updates.
  5. `actionlint .github/workflows/release-please.yml .github/workflows/hex-publish.yml` exits 0 (or both workflows parse cleanly via `gh workflow view` once pushed).
**Plans**: 1 plan
- [ ] 29-01-PLAN.md — Create release workflows and configure Dependabot for supply-chain hardening
**UI hint**: no

### Phase 30: Hex Page Polish And Tarball Dry-Run
**Goal**: Confirm `README.md`, `mix docs` output, and the published tarball are clean and adopter-ready before the publish phase can be triggered.
**Depends on**: Phase 29
**Requirements**: HEX-01, HEX-02, HEX-03, PRF-01
**Success Criteria** (what must be TRUE):
  1. `README.md` audit confirms no relative links to `examples/phoenix_host/README.md`, `guides/`, or other paths that would 404 on hex.pm; all internal references use absolute URLs anchored to `@source_url`.
  2. `mix hex.build --unpack` produces a tarball containing exactly `lib/`, `priv/`, `.formatter.exs`, `mix.exs`, `README.md`, `LICENSE`, `CHANGELOG.md`, and `guides/` — and contains NO `.planning/`, `prompts/`, `test/`, `.github/`, `examples/`, or `native/` paths.
  3. `mix docs` runs locally with zero warnings, produces an `doc/` tree where `index.html` redirects to the README landing page, and every file in `guides/` renders as a navigable extras entry.
  4. `mix hex.publish --dry-run` exits 0 against the audited `mix.exs` and reports correct metadata, license, files allowlist, and version preflight checks.
**Plans**: TBD

### Phase 31: First Hex Publish (Human-Gated)
**Goal**: Complete the irreversible human-gated handoffs (GitHub permissions, `HEX_API_KEY`, Release PR merge) so `crosswake 0.1.0` is live on hex.pm.
**Depends on**: Phase 30
**Requirements**: REL-07, REL-08, PRF-02
**Success Criteria** (what must be TRUE):
  1. **Human-gated:** `gh api repos/szTheory/crosswake/actions/permissions/workflow` returns `default_workflow_permissions: "write"` and `can_approve_pull_request_reviews: true` (verified by the maintainer before any publish attempt).
  2. **Human-gated:** `gh secret list --repo szTheory/crosswake` shows `HEX_API_KEY`; the key was generated at `https://hex.pm/dashboard/keys` with `package:crosswake` (NOT `api:write`) scope and is referenced in `release-please.yml` only via the `env:` block — `grep -n "HEX_API_KEY" .github/workflows/release-please.yml` shows no occurrence in any `with:` block.
  3. release-please opens a Release PR titled `chore(main): release 0.1.0` (NOT `release 0.1.1` and NOT `release 1.0.0`) within 2 minutes of the first push to `main`.
  4. **Human-gated:** the maintainer merges the Release PR, the `publish-hex` job runs to green, and `curl -fsS https://hex.pm/api/packages/crosswake/releases/0.1.0` returns a JSON body with `"version": "0.1.0"`.
  5. The hex.pm package page at `https://hex.pm/packages/crosswake/0.1.0` renders with working GitHub, Docs, and Changelog links; hexdocs at `https://hexdocs.pm/crosswake/0.1.0/` renders the README as the landing page.
**Plans**: TBD

### Phase 32: Post-Publish Cleanup
**Goal**: Close out the milestone by removing the one-time `release-as` pin, smoke-testing the install path from an external project, and shipping the canonical install snippet adopters will paste into their `mix.exs`.
**Depends on**: Phase 31
**Requirements**: PRF-03, PRF-04, HEX-04
**Success Criteria** (what must be TRUE):
  1. `release-please-config.json` no longer contains a `"release-as"` key; `grep -n release-as release-please-config.json` returns nothing, and the removing commit is on `main`.
  2. A fresh scratch project created via `mix new crosswake_smoke` with `{:crosswake, "~> 0.1"}` in its deps runs `mix deps.get` and resolves `crosswake 0.1.0` from hex.pm successfully; `mix compile` against the resolved dep succeeds.
  3. `guides/install.md` contains the canonical `{:crosswake, "~> 0.1"}` install snippet matching the published version, with no `0.0.0` or placeholder version strings remaining.
  4. After the cleanup commit lands, the next release-please run produces a Release PR proposing a version derived from accumulated conventional commits (NOT pinned to `0.1.0`), confirming the auto-bump pipeline is healthy.
**Plans**: TBD

## Progress

| Phase | Milestone | Plans Complete | Status   | Completed  |
| ----- | --------- | -------------- | -------- | ---------- |
| 19. Commerce Route Corridors             | v3.2 | 3/3 | Complete   | 2026-05-27 |
| 20. Entitlement Lifecycle Semantics      | v3.2 | 4/4 | Complete   | 2026-05-27 |
| 21. Reconciliation Example               | v3.2 | 2/2 | Complete   | 2026-05-27 |
| 22. Commerce Support, Review, And Proof  | v3.2 | n/a | Decomposed | 2026-05-27 |
| 23. Commerce Support And Proof Closure   | v3.2 | 4/4 | Complete   | 2026-05-27 |
| 24. Reconciliation Traceability Hardening| v3.2 | 3/3 | Complete   | 2026-05-27 |
| 25. Address tech debt (Phase 20+24)      | v3.2 | 2/2 | Complete   | 2026-05-27 |
| 26. Package Metadata Audit               | v3.3 | 4/4 | Complete   | 2026-05-28 |
| 27. Versioning + CHANGELOG               | v3.3 | 0/0 | Not started | —         |
| 28. release-please Configuration Files   | v3.3 | 0/0 | Not started | —         |
| 29. Release Workflows + Supply Chain     | v3.3 | 1/1 | Planned     | —         |
| 30. Hex Page Polish + Tarball Dry-Run    | v3.3 | 0/0 | Not started | —         |
| 31. First Hex Publish (Human-Gated)      | v3.3 | 0/0 | Not started | —         |
| 32. Post-Publish Cleanup                 | v3.3 | 0/0 | Not started | —         |

## Architecture Notes

**Hermetic-vs-advisory CI compatibility:** release-please is a push-event-driven workflow with two job lanes — the release-please job (PR creation, advisory in the sense that it never gates merges) and the publish-hex job (hermetic, runs only on `release_created == 'true'` from a tagged commit). Neither lane conflicts with the existing per-phase proof workflows (`phase5-proof.yml`, `phase18-proof.yml`, `phase23-proof.yml`). The new release lanes should be explicitly excluded from required branch checks; existing hermetic merge-blocking lanes remain authoritative.

**Irreversibility window:** Once Phase 31 publish succeeds, hex.pm gives 1 hour to republish a version with the same number (24 hours for a brand-new package). After that the version is immutable. Phases 26–30 collectively gate the publish phase so dry-run, tarball audit, and render checks ALL pass before the human-gated merge in Phase 31.

**Human-gated steps** (called out in their phase's success criteria):
- META-01 verification (Phase 26): real GitHub repo URL confirmation.
- REL-07 (Phase 31): GitHub `default_workflow_permissions=write` flip.
- REL-08 (Phase 31): `HEX_API_KEY` generation + `gh secret set`.
- PRF-02 (Phase 31): Release PR merge to trigger first publish.
