# Requirements: Crosswake v3.3 Release Readiness

**Milestone goal:** Make Crosswake installable from hex.pm with honest release metadata, CHANGELOG, real `source_url`, and a release-please publication pipeline — turning szTheory's "install truth is product truth" and "release truth matters" anchors into actual product surface before further capability work.

**Research basis:** `.planning/research/SUMMARY.md` + `REC-METADATA.md` + `REC-VERSIONING.md` + `REC-CHANGELOG.md` + `REC-PIPELINE.md` (all 4 deep-research subagents, 2026-05-27). Coherent recommendation approved 2026-05-27.

**Paved path:** `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib` skill (oarlock canonical pattern).

---

## v3.3 Requirements

### A. Package Metadata Truth

- [x] **META-01** Adopter can navigate from the hex.pm package page to the real GitHub repository — `mix.exs` `source_url` replaces the `https://github.com/example/crosswake` placeholder with the real `szTheory/crosswake` repo URL via a `@source_url` module attribute.
- [x] **META-02** The published tarball has the correct OTP name — `:package` block sets `name: "crosswake"` explicitly (prevents OTP-atom tarball-naming footgun from `bootstrap-elixir-hex-lib` skill).
- [x] **META-03** The published tarball ships only adopter-facing files — `:package` declares an explicit `:files` allowlist that includes `lib/`, `priv/`, `mix.exs`, `README.md`, `CHANGELOG.md`, `LICENSE`, and `guides/` and excludes `.planning/`, `prompts/`, `test/`, `.github/`, and `examples/`. Verified by `mix hex.build --unpack`.
- [x] **META-04** The hex.pm package page surfaces three working links — `:package` `:links` provides `"GitHub"` (source repo), `"Docs"` (hexdocs.pm/crosswake), and `"Changelog"` entries.
- [x] **META-05** The published package has a legally honest license — `LICENSE` file exists at repo root and matches the Apache-2.0 declaration in `:package` `:licenses`.
- [x] **META-06** Adopters can browse generated docs at `hexdocs.pm/crosswake` after publish — `mix.exs` defines a `docs/0` function (main README, extras for guides), and `ex_doc ~> 0.38` is declared as a `runtime: false` dev dep.

### B. Versioning Policy

- [ ] **VER-01** The first published hex version is `0.1.0` — `mix.exs` `@version` module attribute is set to `"0.1.0"`. (Survey: 17 of 19 surveyed Elixir OSS libs shipped `0.1.0` or lower first; 0 shipped `1.0.0-rc.0` or `1.0.0` directly. Crosswake has zero external adopters, which SemVer §5 makes a prerequisite for 1.0.)

### C. CHANGELOG

- [ ] **LOG-01** `CHANGELOG.md` exists at repo root, uses Keep-a-Changelog format, and contains a `## [Unreleased]` anchor — required by release-please's insertion regex.
- [ ] **LOG-02** `CHANGELOG.md` contains a single `## [0.1.0]` entry describing what the first published version delivers — 4–5 capability bullets (route policy DSL, manifest + capability ladder, bounded bridge with v3.1 native families, offline contracts, commerce + entitlement seams with reconciliation example) plus explicit non-claims (no provider adapters yet, no first-party companions yet).
- [ ] **LOG-03** `CHANGELOG.md` preamble disambiguates planning milestones from hex versions — explicit note that internal `v1.0`–`v3.2` milestone labels are planning artifacts (in `.planning/MILESTONES.md`), not hex semver versions, and that `0.1.0` is the first hex release.
- [ ] **LOG-04** The `[0.1.0]` entry includes a `### Roadmap traceability` subsection linking `.planning/MILESTONES.md` and `.planning/PROJECT.md` so adopters can trace internal development history without confusing it with hex versions.

### D. Release Pipeline

- [ ] **REL-01** `release-please-config.json` exists at repo root and uses the Elixir release-type — config sets `bump-minor-pre-major: false`, `bump-patch-for-minor-pre-major: true` (oarlock/lattice_stripe pattern, NOT sigra's `true`), `bootstrap-sha` anchored to a commit before v3.3 to prevent backwards CHANGELOG walk, and a one-time `release-as: "0.1.0"` pin.
- [ ] **REL-02** `.release-please-manifest.json` exists at repo root with baseline `"0.0.0"` — NOT `"0.1.0"` (prevents off-by-one footgun where release-please would propose `0.2.0` first).
- [ ] **REL-03** `.github/workflows/release-please.yml` exists, built from the oarlock canonical template (NOT the sigra template — sigra's `sync_release_summary.sh` job is repo-specific and would block publish). Uses singular `release_created` output (v4-correct for single-package repo).
- [ ] **REL-04** `.github/workflows/hex-publish.yml` exists as a `workflow_dispatch` manual-recovery backup — covers the case where the automated publish-hex job fails after tag creation but inside the 60-minute hex.pm revert window.
- [ ] **REL-05** All GitHub Actions referenced in both workflows are pinned to a full commit SHA (NOT a tag) — including `googleapis/release-please-action`, `actions/checkout`, `erlef/setup-beam`, `actions/cache`. Prevents CVE-2025-30066-class supply-chain attacks (tj-actions/changed-files tag-move incident, March 2025).
- [ ] **REL-06** `.github/dependabot.yml` exists with `package-ecosystem: "github-actions"` so SHA pins surface as PRs when upstream Actions ship updates — keeps the supply-chain hardening from becoming a maintenance burden.
- [ ] **REL-07** The GitHub repo has `default_workflow_permissions` set to `"write"` — required for release-please to open Release PRs (silent failure if unset). Verified via `gh api repos/szTheory/crosswake/actions/permissions/workflow`.
- [ ] **REL-08** A `HEX_API_KEY` secret is installed in the GitHub repo and wired into `release-please.yml` only via the `env:` block (NOT `with:`, to prevent log leakage). Key is generated at hex.pm dashboard and scoped to writes for the `crosswake` package only.
- [ ] **REL-09** `.tool-versions` exists at repo root pinning Elixir and Erlang/OTP versions — ensures reproducible builds across local development, CI, and release-please workflows.

### E. Hex Page Polish

- [ ] **HEX-01** `README.md` uses absolute URLs only — no relative links to `examples/phoenix_host/README.md`, `guides/`, etc. that would become dead links on the hex.pm package page (which does not ship those paths in the tarball).
- [ ] **HEX-02** `mix hex.build --unpack` is run pre-publish and the resulting tarball contents are inspected against the `:files` allowlist — confirms no `.planning/`, `prompts/`, `test/`, or `.github/` leaked into the published package.
- [ ] **HEX-03** `mix docs` runs clean locally with zero warnings and produces a hexdocs structure where `README.md` is the main page and `guides/` extras render correctly.
- [ ] **HEX-04** `guides/install.md` is updated with the canonical `{:crosswake, "~> 0.1"}` install snippet so adopters discovering Crosswake via hex.pm get a correct copy-paste install line. (Updated post-publish; pre-publish version may use placeholder.)

### F. Proof

- [ ] **PRF-01** `mix hex.publish --dry-run` is run and passes — gates the first publish by verifying metadata, license, files allowlist, and version against hex.pm's preflight checks.
- [ ] **PRF-02** The first hex publish succeeds — release-please opens a Release PR for `0.1.0`, the maintainer merges it, the publish-hex job runs, and `https://hex.pm/packages/crosswake/0.1.0` is live.
- [ ] **PRF-03** Post-publish smoke install — a fresh `mix new` project can add `{:crosswake, "~> 0.1"}` to its deps, run `mix deps.get`, and resolve crosswake from hex.pm successfully.
- [ ] **PRF-04** The one-time `release-as: "0.1.0"` pin is removed from `release-please-config.json` after the first publish is confirmed — allows release-please to handle future version bumps automatically.

---

## Future Requirements

Deferred to v3.4 or later (not in scope for v3.3 but tracked):

- **Machine-enforced CHANGELOG shape test** — cheap ExUnit (`File.read!("CHANGELOG.md") =~ "## [Unreleased]"` + format checks). Graduation candidate from v3.2's machine-enforced parity pattern. Defer to v3.4 — v3.3's enforcement budget is already on SUMMARY frontmatter.
- **`mix crosswake.doctor --check-publish` install-truth surface** — operator-facing diagnostic that reports "is current local version published on hex.pm?", "is `source_url` reachable?", "does mix.exs version match latest hex.pm version?". Graduation candidate after v3.3 publish is live.
- **General-purpose `ci.yml` PR gate** — consolidate per-phase proof lanes (`phase5`, `phase10`, `phase18`, `phase23-proof.yml`) into a single PR check. Quality-of-life cleanup; not blocking for v3.3.
- **Advisory scheduled hex.pm liveness probe** — scheduled GitHub Actions workflow that periodically confirms `https://hex.pm/packages/crosswake` is reachable and the latest version matches `mix.exs`. Hermetic-vs-advisory split puts this on the advisory lane.

---

## Out of Scope

Explicit exclusions for v3.3 with reasoning:

- **`:maintainers` field in `mix.exs` `:package` block** — deprecated in the hex package_metadata spec (verified against the hexpm/specifications repo). hex.pm returns `null` for this field on every major lib that sets it. Ownership signal is the hex.pm "Owners" section, auto-populated from publish auth. Famous libs that set it are carrying forward a pre-deprecation convention; the canonical szTheory template (oarlock) correctly omits it.
- **Provider adapters (StoreKit, Play Billing, RevenueCat, Accrue)** — out-of-arc per existing decisions. Commerce contracts shipped in v3.2 are intentionally provider-neutral and adapter work is deferred to later milestones.
- **New capability families** — v3.3 is an infrastructure milestone. No new bounded bridge families, no new route-policy vocabulary, no new manifest semantics.
- **First-party companions (Rulestead, sigra, rindle, chimeway, threadline)** — blocked on v3.3 publish. v3.5 Rulestead is the recommended first companion milestone post-publish.
- **Tag-driven release flow** — the canonical szTheory pattern is release-please PR-driven, not manual `git tag → publish`. PR-driven gives reviewable Release PRs and machine-enforced CHANGELOG insertion.
- **Initial publish at `1.0.0` or `1.0.0-rc.0`** — Zero external adopters means SemVer §5's "used in production" + "users have come to depend on" prerequisites are not met. `1.0.0-rc.0` additionally breaks `~> 1.0` install constraints (Hex defaults `allow_pre: false`). `1.0.0` is the right version to declare once external adoption validates the contract; the tentative trigger is v3.5 Rulestead companion + documented adopter signals, not v3.3.
- **Bundling release infra into existing phase-proof workflows** — release-please workflow is its own event axis (push to main + merged Release PR) and should not be coupled to per-phase proof lanes.

---

## Traceability

Every v3.3 requirement is mapped to exactly one phase. Coverage: 28/28.

| Requirement | Phase | Status |
|---|---|---|
| META-01 | Phase 26: Package Metadata Audit | Complete |
| META-02 | Phase 26: Package Metadata Audit | Complete |
| META-03 | Phase 26: Package Metadata Audit | Complete |
| META-04 | Phase 26: Package Metadata Audit | Complete |
| META-05 | Phase 26: Package Metadata Audit | Complete |
| META-06 | Phase 26: Package Metadata Audit | Complete |
| VER-01 | Phase 27: Versioning + CHANGELOG | Pending |
| LOG-01 | Phase 27: Versioning + CHANGELOG | Pending |
| LOG-02 | Phase 27: Versioning + CHANGELOG | Pending |
| LOG-03 | Phase 27: Versioning + CHANGELOG | Pending |
| LOG-04 | Phase 27: Versioning + CHANGELOG | Pending |
| REL-01 | Phase 28: release-please Configuration Files | Pending |
| REL-02 | Phase 28: release-please Configuration Files | Pending |
| REL-09 | Phase 28: release-please Configuration Files | Pending |
| REL-03 | Phase 29: Release Workflows + Supply Chain | Pending |
| REL-04 | Phase 29: Release Workflows + Supply Chain | Pending |
| REL-05 | Phase 29: Release Workflows + Supply Chain | Pending |
| REL-06 | Phase 29: Release Workflows + Supply Chain | Pending |
| HEX-01 | Phase 30: Hex Page Polish + Tarball Dry-Run | Pending |
| HEX-02 | Phase 30: Hex Page Polish + Tarball Dry-Run | Pending |
| HEX-03 | Phase 30: Hex Page Polish + Tarball Dry-Run | Pending |
| PRF-01 | Phase 30: Hex Page Polish + Tarball Dry-Run | Pending |
| REL-07 | Phase 31: First Hex Publish (Human-Gated) | Pending |
| REL-08 | Phase 31: First Hex Publish (Human-Gated) | Pending |
| PRF-02 | Phase 31: First Hex Publish (Human-Gated) | Pending |
| PRF-03 | Phase 32: Post-Publish Cleanup | Pending |
| PRF-04 | Phase 32: Post-Publish Cleanup | Pending |
| HEX-04 | Phase 32: Post-Publish Cleanup | Pending |

---

*Last updated: 2026-05-27 — v3.3 traceability filled by roadmapper. Phases 26-32 mapped 1:1 against all 28 requirements with zero orphans and zero double-counts.*
