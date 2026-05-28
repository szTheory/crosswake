# Feature Research: v3.3 Release Readiness (hex.pm publication infrastructure)

**Milestone:** v3.3 Release Readiness
**Domain:** Elixir OSS library hex.pm publication infrastructure
**Researched:** 2026-05-27
**Confidence:** HIGH — sourced from bootstrap-elixir-hex-lib SKILL.md (lived experience from oarlock bootstrap), oarlock and sigra canonical reference repos, crosswake mix.exs and thread audit, hex.pm API verification, and crosswake-elixir-oss-dna.md house-style anchors.

---

## Grounding Facts (from mix.exs and repo audit)

- `mix.exs` version: `0.1.0` (placeholder — no published Hex release yet)
- `mix.exs` source_url: `"https://github.com/example/crosswake"` — placeholder, must be replaced
- `mix.exs` package block: `:licenses` and `:links` present; no `:maintainers`, no `:files` allowlist, no `name:` override, no `docs` block, no `@source_url` module attribute
- `mix.exs` project block: no `name:`, no `homepage_url:`, no `docs:` key
- No `CHANGELOG.md` at repo root
- No `release-please-config.json`, no `.release-please-manifest.json`
- No `.github/workflows/release-please.yml`, no `.github/workflows/hex-publish.yml`
- No `HEX_API_KEY` GitHub secret wiring
- No `LICENSE` file
- No `.tool-versions` file
- `crosswake` package name is available on hex.pm (HTTP 404 confirmed 2026-05-27)
- Existing CI: phase-scoped proof workflows only (`phase5-proof.yml`, `phase10-proof.yml`, `phase18-proof.yml`, `phase23-proof.yml`) — no general CI workflow
- `guides/` directory exists with rich content — eligible for hex tarball inclusion

---

## Feature Landscape

### Category A: Package Metadata Truth

Every hex.pm package page is driven by `mix.exs` project and package blocks. These fields determine how the package renders on hex.pm, what users see in `mix hex.info`, and what ends up in the distributed tarball.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| A-01: Real `source_url` module attribute | Every hex page has a working GitHub link; placeholder `github.com/example/crosswake` breaks the hex page | LOW | None | Replace with actual repo URL; also drives `hexdocs` source link-outs |
| A-02: `@source_url` module attribute + `name:` + `homepage_url:` in `project/0` | Canonical oarlock/sigra pattern — avoids duplicating URL string; `name:` needed only if OTP atom differs from Hex package name | LOW | A-01 | Crosswake's OTP atom `:crosswake` matches Hex package name `crosswake` so `name:` override inside `package/0` is for tarball naming safety not disambiguation |
| A-03: `:maintainers` in `package/0` | Hex page shows maintainer, enables hex.pm ownership claims and transfer flows | LOW | A-01 | Add `["szTheory"]` |
| A-04: `:links` block with Source, Docs, Changelog keys | Standard three-link pattern on hex pages; "Changelog" link lets users read history before installing | LOW | A-01 | Canonical pattern from oarlock: `%{"GitHub" => @source_url, "Documentation" => "https://hexdocs.pm/crosswake", "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"}` |
| A-05: `:files` allowlist in `package/0` | Prevents build artifacts, test files, native shell code, planning files, and CI YAML from ending up in the hex tarball | LOW | None | Canonical: `~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)` — add `guides` since the hex page is richer with guide content; drop `priv` if no priv dir |
| A-06: `docs/0` private function in `mix.exs` | Drives `mix docs` and hexdocs rendering; without it ExDoc uses defaults that often produce a poor hex page | LOW | A-01 | Canonical: `main: "readme"`, `source_ref: "v#{@version}"`, `source_url: @source_url`, `formatters: ["html"]`, `extras:` list of guides |
| A-07: `:ex_doc` dev dependency | ExDoc must be present as dev-only dep for `mix docs` to work; absence causes `mix hex.publish` to silently skip doc generation | LOW | None | `{:ex_doc, "~> 0.34", only: :dev, runtime: false}` — canonical from oarlock |
| A-08: `:description` review and tighten | Current description `"Phoenix-first route policy and runtime contract substrate"` is serviceable but can be sharpened for hex page scan | LOW | None | Should be one declarative sentence, under ~150 characters, no jargon |

### Category B: Versioning Policy

The initial published version is a one-way door. The wrong choice either undersells a mature contract surface (`0.1.0`) or overclaims stability (`1.0.0`) before public adopter validation. This decision must be documented so future contributors understand why the version is what it is.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| B-01: Versioning policy decision document | Adopters and contributors need to know why `0.x.y` vs `1.0.0` — undocumented version choices breed confusion | LOW | None | Decision lives in CHANGELOG.md preamble (see C-01) and in a comment or note in mix.exs |
| B-02: Initial version set to `0.1.0` in mix.exs `@version` | `0.1.0` is the honest first-published-Hex-release signal for a library with no public adopters yet — even though internal planning milestones are at v3.2, hex.pm consumers have never installed a release | LOW | B-01 | Crosswake's internal milestone numbering (`v1.0`–`v3.2`) is a planning artifact, NOT a Hex semver axis; `0.1.0` is the right starting Hex version. The CHANGELOG preamble (C-01) explains the dual-axis distinction. Matches oarlock pattern. |
| B-03: SemVer bump policy for future releases documented | Release-please will auto-bump on conventional commits; maintainer and contributors need to know what `feat:` vs `fix:` vs `feat!:` means for Crosswake | LOW | B-01 | Mirrors oarlock: `bump-minor-pre-major: false` means `feat:` bumps patch (not minor) in 0.x — safe for pre-1.0. Document in CHANGELOG preamble. |

### Category C: CHANGELOG.md

CHANGELOG.md serves three audiences simultaneously: hex.pm adopters deciding whether to upgrade, hexdocs readers navigating release history, and release-please which reads and writes the file for each release.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| C-01: CHANGELOG.md at repo root with Keep-a-Changelog format | Hex page `:links` block points to it; release-please requires a parseable CHANGELOG at `changelog-path`; adopters expect it | LOW | None | Must exist before release-please config is committed or release-please will create a minimal one on first run (acceptable but messier) |
| C-02: "Planning milestones vs Hex releases" disambiguation preamble | Crosswake has internal `v1.0`–`v3.2` planning milestones that are NOT the same as Hex semver releases — this needs explicit disambiguation to prevent confusion | LOW | C-01 | Canonical preamble from oarlock CHANGELOG; adapt to say "planning milestones labeled `v1.0`–`v3.2` describe shipped tranches of work, not a second version axis on Hex" |
| C-03: `[Unreleased]` section with "Initial public release" | release-please reads/writes the `[Unreleased]` section; without it the first release PR may produce a malformed CHANGELOG | LOW | C-01, C-02 | Keep lean — do NOT include a `### Summary` subsection (bootstrap-elixir-hex-lib gotcha #6: sigra-specific, breaks release pipeline) |
| C-04: CHANGELOG synthesizes milestones v1.0 → v3.2 as "Pre-publication development history" | Adopters benefit from knowing the library has substantial pre-publication history even though `0.1.0` is the first Hex release | MEDIUM | C-01, C-02 | Write a compact `## Pre-publication development history` section referencing `.planning/MILESTONES.md` for full detail — do NOT expand every phase; just anchor the breadth so hex adopters trust it |

### Category D: Release Pipeline

The release pipeline converts merged conventional commits into versioned GitHub Releases, git tags, and hex.pm publications automatically. Crosswake uses release-please as the canonical tool (established via bootstrap-elixir-hex-lib skill; validated across oarlock and sigra).

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| D-01: `release-please-config.json` | release-please needs a config file to know release type (elixir), changelog path, tag format, and first-release pin | LOW | C-01 | Canonical: `"release-type": "elixir"`, `"bump-minor-pre-major": false`, `"bump-patch-for-minor-pre-major": true`, `"include-v-in-tag": true`, `"release-as": "0.1.0"` (one-time first-release pin) |
| D-02: `.release-please-manifest.json` baseline at `0.0.0` | release-please uses the manifest to know the last-released version; if set to `0.1.0` it thinks 0.1.0 is already released and will bump to 0.1.1 or 0.2.0 prematurely | LOW | D-01 | **Critical gotcha** from bootstrap-elixir-hex-lib: baseline must be `{"." : "0.0.0"}`. First release with `release-as: "0.1.0"` pin will propose exactly 0.1.0. |
| D-03: `.github/workflows/release-please.yml` with `publish-hex` job | The canonical two-job workflow: `release-please` job opens/updates Release PRs from conventional commits; `publish-hex` job runs on `release_created` output, runs tests, dry-run, then publishes | MEDIUM | D-01, D-02, E-03 | Start from oarlock's release-please.yml (not sigra's — sigra has the sync-release-summary gotcha). Crosswake has no Postgres so omit DB service block. Pin action SHAs as in oarlock. |
| D-04: GitHub Actions can-create-PRs permission set | Default GitHub repo setting blocks release-please from opening Release PRs; the workflow silently does nothing until this is enabled | LOW | D-03 | Run: `gh api -X PUT /repos/szTheory/crosswake/actions/permissions/workflow -f default_workflow_permissions=write -F can_approve_pull_request_reviews=true` — must happen immediately after repo is made public/configured |
| D-05: `.github/workflows/hex-publish.yml` manual recovery workflow | When release-please merge does not trigger CI re-fire (divergent main, force-push, branch protection edge case), maintainer needs a one-off recovery path | LOW | D-03 | Start from oarlock's hex-publish.yml verbatim; substitute crosswake package URL in verify step. Inputs: `tag` (git tag or SHA) and `release_version` (expected @version string). |
| D-06: `HEX_API_KEY` GitHub secret wiring guidance | The publish job cannot run without the API key; human must do this step (Hex does not expose key values after creation) | LOW | D-03 | Cannot be automated. Generate at hex.pm/dashboard/keys with name `crosswake-ci`, permissions: api (write). Store via `gh secret set HEX_API_KEY --repo szTheory/crosswake`. |
| D-07: Remove `release-as` pin after first publish | The `release-as: "0.1.0"` pin in release-please-config.json is one-time only; leaving it causes all future releases to be proposed as 0.1.0 and publish will fail | LOW | D-01, first publish | Commit: `chore: remove release-as pin (0.1.0 shipped, auto-bump henceforth)`. This is a post-first-publish cleanup step, not a pre-publish step. |
| D-08: General CI workflow (mix test + format + compile) | Every hex library needs a baseline CI job on PRs and main; currently Crosswake only has phase-scoped proof workflows | LOW | None | Start from oarlock's ci.yml: ubuntu-latest, `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix test`. No DB block for Crosswake. |

### Category E: Hex Page Polish

The hex.pm package page and hexdocs are the primary discovery and documentation surfaces for Elixir library adopters. Poor rendering here is a trust signal against the library.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| E-01: README renders correctly on hex.pm package page | hex.pm renders the repo root README.md as the package page content; relative markdown links like `[guides/install.md](guides/install.md)` become dead links on hex page | MEDIUM | A-05 | Audit README for relative links to files not in the tarball (example host links, native shell code); replace with GitHub absolute links or hexdocs extras links. Current README links to `examples/phoenix_host/README.md` which is NOT in the files allowlist. |
| E-02: `mix docs` produces clean hexdocs output | hexdocs.pm auto-publishes from `mix hex.publish`; broken ExDoc config produces a mostly-empty hexdocs page | LOW | A-06, A-07 | Run `mix docs` locally before publish; verify main module, guides, and extras render; check for broken @doc or @moduledoc references |
| E-03: `mix hex.build` content audit | Verifies the tarball contains only what should be in it; catches build artifacts, oversized files, or missing README/CHANGELOG before publish | LOW | A-05, C-01 | Run `mix hex.build`, inspect output listing; verify tarball is named `crosswake-0.1.0.tar` (not `crosswake_core-0.1.0.tar` or other atom-derived name); clean up `.tar` file after |
| E-04: `LICENSE` file at repo root | hex.pm displays license from `:licenses` key but also expects the LICENSE file to exist in the package; Apache-2.0 is already declared in mix.exs | LOW | A-05 | Create `LICENSE` at repo root with Apache-2.0 text; include in `:files` allowlist |
| E-05: `.tool-versions` at repo root | Required by `erlef/setup-beam@v1` with `version-file: .tool-versions` in CI; without it the workflow must hardcode Elixir/OTP versions and drift over time | LOW | None | Copy from `~/projects/sigra/.tool-versions`: `erlang 28.1`, `elixir 1.19.5-otp-28` |
| E-06: Guide extras wired into ExDoc | The `guides/` directory has rich content that should appear as structured extras in hexdocs, not just as raw files | LOW | A-06 | Add `extras:` list in `docs/0` covering install.md, support_matrix.md, user_flows.md, adopter_profiles.md, compatibility.md, bridge.md, offline.md, packs.md, native_shell.md, commerce.md |
| E-07: `guides/support_matrix.md` and `guides/install.md` reviewed for hex-page accuracy | These guides are the primary landing content for hex adopters; they must not reference placeholder URLs, pre-publication proof scripts, or example_host paths that do not resolve from hexdocs | MEDIUM | E-01, E-06 | Audit for any hardcoded `github.com/example/crosswake` occurrences; update install guide to reference `{:crosswake, "~> 0.1"}` as the install path |

### Category F: Proof and Support Truth

Following the hermetic-vs-advisory CI split pattern (graduated default for v3.3+), the publish path itself should have a verifiable proof step, not just a hope-for-the-best publish.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| F-01: `mix hex.publish --dry-run` in release workflow | Catches tarball build errors and metadata validation failures before the real publish; already present in oarlock's canonical workflow | LOW | D-03, E-03 | The dry-run step in `publish-hex` job runs before `mix hex.publish --yes`; fails fast with useful error output |
| F-02: Post-publish hex.pm API verification step in workflow | Confirms hex.pm indexed the release before the workflow reports success; retry loop with timeout as in oarlock | LOW | D-03 | 36-attempt loop, 10s sleep, checks `https://hex.pm/api/packages/crosswake/releases/0.1.0` for `"version"` key |
| F-03: Post-publish hexdocs verification (smoke-test) | Confirms hexdocs.pm rendered correctly after publish; catches ExDoc config issues that pass `mix docs` locally but fail in hexdocs pipeline | LOW | D-03, E-02 | Check `https://hexdocs.pm/crosswake/0.1.0/` resolves after publish; can be a manual step or part of a 24h smoke-test routine |
| F-04: `guides/install.md` updated with `{:crosswake, "~> 0.1"}` as canonical install path | The install guide is the adopter-facing contract; it must reflect actual hex.pm installability, not just `mix deps.get` | LOW | F-02 | Update install guide after first publish confirms hex.pm availability; this is a post-publish truth closure |
| F-05: `.gitignore` updated to exclude tarball build artifacts | `mix hex.build` produces `crosswake-*.tar`; without gitignore entries a developer will accidentally stage the tarball | LOW | E-03 | Append `crosswake-*.tar` and `crosswake_sdk-*.tar` (both OTP atom and Hex name patterns per bootstrap skill gotcha #2) to `.gitignore` |

---

## Feature Dependencies

```
A-01 (real source_url)
  └──enables──> A-02 (module attribute + project keys)
  └──enables──> A-04 (links block)
  └──enables──> A-06 (docs function)
  └──enables──> E-07 (guide accuracy)

A-05 (files allowlist)
  └──enables──> E-01 (README renders)
  └──enables──> E-03 (hex.build audit)

A-06 (docs function)
  └──requires──> A-07 (ex_doc dep)
  └──enables──> E-02 (mix docs clean)
  └──enables──> E-06 (guides in hexdocs)

C-01 (CHANGELOG.md exists)
  └──required by──> D-01 (release-please-config)
  └──required by──> D-02 (manifest baseline)
  └──required by──> D-03 (release workflow)

C-01
  └──requires──> C-02 (disambiguation preamble)
  └──requires──> C-03 (Unreleased section)

D-01 (release-please-config)
  └──requires──> D-02 (manifest at 0.0.0)
  └──enables──> D-03 (workflow)

D-03 (release-please.yml)
  └──requires──> D-04 (GitHub PR permission)
  └──requires──> D-05 (recovery workflow)
  └──requires──> D-06 (HEX_API_KEY secret)
  └──requires──> E-05 (.tool-versions for erlef/setup-beam)
  └──requires──> E-03 (hex.build audit clean)
  └──contains──> F-01 (dry-run step)
  └──contains──> F-02 (post-publish verification)

E-04 (LICENSE file)
  └──requires──> A-05 (must be in files allowlist)

D-07 (remove release-as pin)
  └──requires──> [first publish completed]

F-04 (install guide updated)
  └──requires──> F-02 (hex.pm confirms release)
```

### Dependency Notes

- **C-01 before D-01**: release-please-config.json references `changelog-path: "CHANGELOG.md"` — if CHANGELOG is missing, the first release-please run creates a degenerate one that lacks the disambiguation preamble.
- **D-02 must be `0.0.0`, not `0.1.0`**: manifest at `0.1.0` causes release-please to treat 0.1.0 as already-released and propose `0.1.1` or `0.2.0` on first run (bootstrap-elixir-hex-lib gotcha #4).
- **D-07 is post-publish only**: removing the `release-as` pin before the first publish is catastrophic — the first release-please PR would not pin to 0.1.0 and the heuristic would propose 1.0.0 from accumulated feat: commits (gotcha #5).
- **E-01 and E-07 are correctness gates**: they are not blocking publish but are blocking honest hex page quality — a hex page with dead relative links reflects poorly on the project and undermines "install truth is product truth."

---

## Anti-Features

| Anti-Feature | Why Requested | Why It's Wrong for Crosswake | What to Do Instead |
|--------------|---------------|-----------------------------|--------------------|
| Publish at `1.0.0` on first hex.pm release | "We've shipped 5 milestones, contract is mature, `1.0.0` signals that" | `1.0.0` SemVer signals public adopter-validated stability; Crosswake has ZERO public adopters on hex.pm yet; no one has installed it and filed real issues; `1.0.0` would be a premature stability claim per SemVer convention | Publish at `0.1.0`; the CHANGELOG preamble explains the dual-axis distinction; upgrade to `1.0.0` after real adopter validation (separate future milestone) |
| Use `1.0.0-rc.0` or `1.0.0-pre.1` pre-release tag | "`0.1.0` undersells the contract maturity; `1.0.0-rc.0` signals near-stability" | Pre-release hex versions (`1.0.0-rc.0`) are not resolved by `~> 0.x` version requirements; adopters have to pin exact versions; pre-release tags also complicate release-please automation in elixir release type | Use `0.1.0` with an honest CHANGELOG preamble |
| Auto-publish docs without verifying render locally first | "release-please handles it, it should just work" | hexdocs pipeline can silently produce an empty or broken page if ExDoc extras are misconfigured or guide paths are wrong; the failure is invisible until someone visits hexdocs.pm | Run `mix docs` and `mix hex.build` locally before the first publish; audit guide renders in the local ExDoc output |
| Include `examples/`, `test/`, `.planning/`, `.github/`, `native/` in tarball | "More context is better for adopters" | Bloats the tarball; exposes internal planning artifacts; example hosts contain checked-in iOS/Android native shell code that does not belong in a hex package | Strict `:files` allowlist in `package/0`: only `lib`, `guides`, `mix.exs`, `.formatter.exs`, `README.md`, `LICENSE`, `CHANGELOG.md` |
| Use sigra's release-please.yml as template | "sigra is the most mature szTheory library" | sigra's workflow includes a `sync_release_summary.sh` job that is sigra-specific; it greps for `## [X.Y.Z] → ### Summary` in CHANGELOG; exits 1 for Crosswake; blocks publish job (bootstrap gotcha #6) | Start from oarlock's release-please.yml which has the fix already applied |
| Copy `:package` links block with only `"GitHub"` key | "GitHub link is the important one" | hex.pm page is richer with Source + Docs + Changelog links; adopters who land on hex.pm want the direct hexdocs link without navigating GitHub | Use the three-link canonical pattern: `"GitHub"`, `"Documentation"`, `"Changelog"` |
| Set manifest to `0.1.0` to "match current version" | "The version is 0.1.0 so the manifest should say 0.1.0" | Manifest at `0.1.0` means release-please thinks 0.1.0 is already published; the first Release PR will propose `0.1.1` or `0.2.0` (bootstrap gotcha #4) | Set manifest to `"0.0.0"` with `release-as: "0.1.0"` pin in config — this is the first-release dance |
| Leave `release-as` pin in config permanently | "The pin ensures we always release 0.1.0" | Permanently pinned `release-as` means every future release-please run proposes 0.1.0; re-publish fails because version already exists on hex.pm | Remove pin in the post-first-publish cleanup commit (D-07) |
| Add `HEX_API_KEY` to repo as an env var or committed file | "Secrets management is complicated" | API key in repo or environment variables is a security footgun; hex.pm keys have write access to publish arbitrary versions | Use GitHub Actions secrets only; generate per-repo key at hex.pm dashboard with minimal scope |
| Skip general CI workflow because phase-proof workflows exist | "Phase proof workflows already run tests" | Phase-proof workflows are scoped to specific test files; a general `mix test` + `mix compile --warnings-as-errors` + `mix format` gate on all PRs is a separate concern | Add `ci.yml` as a lightweight general gate; keep phase-proof workflows as specialized named lanes |

---

## Feature Prioritization Matrix

Phase ordering recommendation for the roadmapper: this milestone has clear serial dependencies — metadata + LICENSE must come first, then CHANGELOG, then release-please config, then CI wiring, then tarball audit and README render, then publish, then post-publish cleanup. The "proof" features (F-01, F-02, F-03) are embedded in the pipeline steps, not separate phases.

| Feature | User Value | Implementation Cost | Priority | Phase Cluster |
|---------|------------|---------------------|----------|---------------|
| A-01: Real source_url | HIGH | LOW | P1 | Package Metadata |
| A-02: module attribute + project keys | HIGH | LOW | P1 | Package Metadata |
| A-03: `:maintainers` | MEDIUM | LOW | P1 | Package Metadata |
| A-04: `:links` three-link pattern | HIGH | LOW | P1 | Package Metadata |
| A-05: `:files` allowlist | HIGH | LOW | P1 | Package Metadata |
| A-06: `docs/0` function | HIGH | LOW | P1 | Package Metadata |
| A-07: `:ex_doc` dev dep | HIGH | LOW | P1 | Package Metadata |
| A-08: `:description` tighten | LOW | LOW | P2 | Package Metadata |
| B-01: versioning policy doc | HIGH | LOW | P1 | Versioning |
| B-02: `0.1.0` as initial hex version | HIGH | LOW | P1 | Versioning |
| B-03: bump policy documented | MEDIUM | LOW | P2 | Versioning |
| C-01: CHANGELOG.md | HIGH | LOW | P1 | CHANGELOG |
| C-02: disambiguation preamble | HIGH | LOW | P1 | CHANGELOG |
| C-03: `[Unreleased]` section | HIGH | LOW | P1 | CHANGELOG |
| C-04: pre-publication history summary | MEDIUM | MEDIUM | P2 | CHANGELOG |
| D-01: release-please-config.json | HIGH | LOW | P1 | Release Pipeline |
| D-02: manifest at 0.0.0 | HIGH | LOW | P1 | Release Pipeline |
| D-03: release-please.yml workflow | HIGH | MEDIUM | P1 | Release Pipeline |
| D-04: GitHub Actions PR permission | HIGH | LOW | P1 | Release Pipeline |
| D-05: manual recovery workflow | MEDIUM | LOW | P1 | Release Pipeline |
| D-06: HEX_API_KEY secret guidance | HIGH | LOW | P1 | Release Pipeline |
| D-07: remove release-as pin (post-publish) | HIGH | LOW | P1 | Release Pipeline |
| D-08: general CI workflow | HIGH | LOW | P1 | Release Pipeline |
| E-01: README hex render audit | HIGH | MEDIUM | P1 | Hex Page Polish |
| E-02: mix docs clean output | HIGH | LOW | P1 | Hex Page Polish |
| E-03: mix hex.build content audit | HIGH | LOW | P1 | Hex Page Polish |
| E-04: LICENSE file | HIGH | LOW | P1 | Hex Page Polish |
| E-05: .tool-versions | HIGH | LOW | P1 | Hex Page Polish |
| E-06: guide extras in ExDoc | MEDIUM | LOW | P2 | Hex Page Polish |
| E-07: guide accuracy audit | HIGH | MEDIUM | P1 | Hex Page Polish |
| F-01: dry-run in workflow | HIGH | LOW | P1 | Proof |
| F-02: post-publish API verification | HIGH | LOW | P1 | Proof |
| F-03: hexdocs smoke-test | MEDIUM | LOW | P2 | Proof |
| F-04: install guide updated post-publish | HIGH | LOW | P1 | Proof |
| F-05: .gitignore tarball patterns | LOW | LOW | P1 | Proof |

---

## Sources

- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — canonical paved path for hex publish; oarlock bootstrap gotcha catalog (HIGH confidence — lived experience)
- `/Users/jon/projects/oarlock/.github/workflows/release-please.yml` — canonical two-job release-please workflow (HIGH confidence)
- `/Users/jon/projects/oarlock/.github/workflows/hex-publish.yml` — canonical manual recovery workflow (HIGH confidence)
- `/Users/jon/projects/oarlock/mix.exs` — canonical package metadata structure (HIGH confidence)
- `/Users/jon/projects/oarlock/CHANGELOG.md` — canonical CHANGELOG format with disambiguation preamble (HIGH confidence)
- `/Users/jon/projects/crosswake/mix.exs` — grounding: what is present vs. missing (HIGH confidence)
- `/Users/jon/projects/crosswake/.planning/threads/release-readiness.md` — next-steps enumeration (HIGH confidence)
- `/Users/jon/projects/crosswake/prompts/crosswake-elixir-oss-dna.md` — house-style anchors (HIGH confidence)
- `https://hex.pm/api/packages/crosswake` — confirmed 404: package name available (HIGH confidence, verified 2026-05-27)

---

*Feature research for: v3.3 Release Readiness — hex.pm publication infrastructure for Crosswake*
*Researched: 2026-05-27*
