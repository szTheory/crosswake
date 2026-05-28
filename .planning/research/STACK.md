# Stack Research: v3.3 Release Readiness (hex.pm publication infrastructure)

**Milestone:** v3.3 Release Readiness
**Researched:** 2026-05-27
**Confidence:** HIGH — all versions verified against hex.pm API, GitHub releases API, and canonical oarlock/sigra templates in this repo.

## Scope

This file covers only the NEW infrastructure for v3.3. The existing Elixir/Phoenix/NimbleOptions/Jason stack is unchanged. Do not re-add phoenix, phoenix_live_view, jason, or nimble_options here.

---

## mix.exs Changes Required

### Missing module attribute: `@source_url`

Current `mix.exs` has no `@source_url` module attribute and uses a placeholder URL directly in the `:package` block. The canonical szTheory pattern (verified in oarlock, sigra) is:

```elixir
@version "0.1.0"   # already present — update value for versioning decision
@source_url "https://github.com/szTheory/crosswake"   # ADD: real URL
```

### Missing `project/0` keys

Current `project/0` is missing `name:`, `source_url:`, `homepage_url:`, and `docs:`. Add:

```elixir
name: "crosswake",
source_url: @source_url,
homepage_url: @source_url,
docs: docs()
```

`name:` is required because the OTP atom is `:crosswake` and the Hex package name must be `crosswake` — they match here, but the explicit `name:` in `package/0` is still required or `mix hex.build` will name the tarball after the OTP atom. See bootstrap-elixir-hex-lib gotcha #2.

### `package/0` audit

Current block is missing `:links` richness and `:files` allowlist. Replace with:

```elixir
defp package do
  [
    name: "crosswake",
    licenses: ["Apache-2.0"],   # already set — keep
    links: %{
      "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
      "Documentation" => "https://hexdocs.pm/crosswake",
      "GitHub" => @source_url
    },
    files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
  ]
end
```

`priv/` must be included because Crosswake ships generator templates in `priv/templates/`. Omitting it would produce a broken install for any adopter using `mix crosswake.install`. `guides/` is included because the public guides are part of the product contract. `examples/` is excluded — example apps are not part of the published library surface.

### `docs/0` block (new)

```elixir
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    formatters: ["html"],
    extras: [
      "README.md",
      "CHANGELOG.md",
      "LICENSE",
      "guides/install.md",
      "guides/capabilities.md",
      "guides/bridge.md",
      "guides/offline.md",
      "guides/commerce.md",
      "guides/compatibility.md",
      "guides/support_matrix.md",
      "guides/native_shell.md",
      "guides/packs.md",
      "guides/adopter_profiles.md",
      "guides/user_flows.md"
    ],
    groups_for_extras: [
      Guides: ~r/guides\//
    ]
  ]
end
```

`main: "readme"` makes the README the hexdocs landing page — standard szTheory pattern. `source_ref: "v#{@version}"` wires the "View Source" links on hexdocs to the correct tag.

---

## New Dev Dependency: ex_doc

```elixir
{:ex_doc, "~> 0.38", only: :dev, runtime: false}
```

**Version:** Use `~> 0.38` to allow patch and minor bumps through the current `0.40.x` series (latest confirmed: `0.40.3`, published 2026-05-21). The `~> 0.34` constraint used in oarlock is still valid but unnecessarily restrictive now that 0.40 is stable. Using `~> 0.38` gets the latest HTML/sidebar improvements while staying clear of any theoretical 1.0 breaking change.

**Why ex_doc:** It is the only Elixir documentation generator with first-class hexdocs.pm integration. `mix docs` produces the HTML that hex publish uploads. There is no alternative worth considering for a hex package.

**Classification:** `only: :dev, runtime: false` — ex_doc is never a runtime or test dependency. Including it outside `:dev` would force adopters to compile it.

**Mix tasks:**
- `mix docs` — generates `doc/` directory locally for review
- `mix hex.build` — builds the tarball; ex_doc is not invoked here but must be present for the `mix docs` step in the publish workflow

---

## New Files: release-please configuration

### `release-please-config.json`

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "release-type": "elixir",
  "bump-minor-pre-major": false,
  "bump-patch-for-minor-pre-major": true,
  "packages": {
    ".": {
      "changelog-path": "CHANGELOG.md",
      "include-v-in-tag": true,
      "release-as": "0.1.0"
    }
  }
}
```

`release-as: "0.1.0"` is the **one-time first-release pin**. Remove it after `v0.1.0` ships (see bootstrap-elixir-hex-lib gotcha #5: without the pin, release-please's "first stable release" heuristic proposes 1.0.0 when accumulated `feat:` commits cross the threshold). Remove the pin in the post-publish cleanup step.

`bump-minor-pre-major: false` keeps breaking changes as patch bumps inside 0.x, matching the oarlock/lattice_stripe pattern. Flip to `true` only if the versioning decision lands on sigra-style minor bumps for features pre-1.0.

`release-type: "elixir"` — release-please's Elixir strategy updates `@version "..."` in `mix.exs` using a regex match on `@version "[A-Za-z0-9_\-+.~]+"` (verified from `src/updaters/elixir/elixir-mix-exs.ts`). The current `mix.exs` already uses `@version "0.1.0"` — this pattern is compatible with no changes required.

### `.release-please-manifest.json`

```json
{
  ".": "0.0.0"
}
```

Baseline at `0.0.0` (bootstrap-elixir-hex-lib gotcha #4: if manifest says `0.1.0`, release-please treats 0.1.0 as already released and will propose 0.1.1 or 0.2.0). The `release-as: "0.1.0"` pin in config overrides the bump so the Release PR title is `chore(main): release 0.1.0`.

---

## New Files: GitHub Action workflows

### `.github/workflows/release-please.yml`

Use `googleapis/release-please-action@v5.0.0` (SHA `45996ed1f6d02564a971a2fa1b5860e934307cf7`). v5 shipped 2026-04-22 with Node 24 upgrade and release-please bump to 17.6.0; it is stable (non-prerelease) and the current canonical version.

**Do NOT use v4** for new wiring — v4.4.1 was released 2026-04-13, one week before v5.0.0, which means the existing oarlock pin (`@v4`) will continue to work but new projects should start on v5. The only breaking change in v5 is the Node 24 runner requirement, which GitHub-hosted runners satisfy.

Key structure (mirror oarlock, substituting `crosswake` for `oarlock` in the verify step):

```yaml
jobs:
  release-please:
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0
        with:
          token: ${{ secrets.RELEASE_PLEASE_TOKEN || github.token }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json

  publish-hex:
    needs: release-please
    if: ${{ needs.release-please.outputs.release_created == 'true' }}
    steps:
      - uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          ref: ${{ needs.release-please.outputs.tag_name }}
      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93 # v1.24.0
        with:
          version-file: .tool-versions
          version-type: strict
      - uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830 # v4.3.0
      # ... compile, test, dry-run publish, publish, verify
```

**No DB service block.** Crosswake has no Ecto/Postgrex dependency. The oarlock pattern omits the Postgres services block for non-DB libs.

**No sync-release-summary job.** That job is sigra-specific (bootstrap-elixir-hex-lib gotcha #6). Using sigra's workflow verbatim would break because Crosswake's CHANGELOG.md will not follow sigra's `### Summary` subsection convention.

**Verify step URL:** `https://hex.pm/api/packages/crosswake/releases/${VERSION}` (replace oarlock's URL).

### `.github/workflows/hex-publish.yml`

Manual recovery workflow — copy oarlock's `hex-publish.yml` verbatim, update only the verify step URL to `crosswake`. Used when the automated release-please trigger doesn't fire (e.g., divergent main after merge).

### Integration with existing CI pattern

Crosswake already has phase-specific proof workflows (`phase5-proof.yml`, `phase18-proof.yml`, `phase23-proof.yml`, `phase10-proof.yml`) using the hermetic-vs-advisory split. The new `release-please.yml` workflow is a separate concern — it does not replace or conflict with these. The publish-hex job runs the full `mix test` suite (hermetic only, no advisory provider lanes), which is the correct bar for a library publish.

A new `ci.yml` (oarlock-pattern, no DB block) should also be added as the general PR/push merge gate. Currently crosswake has no `ci.yml` — this is a gap. The existing phase proof workflows are per-milestone artifacts, not a general CI gate.

---

## New Files: release scaffolding

### `CHANGELOG.md`

Synthesized from `.planning/MILESTONES.md`. The file must follow Keep a Changelog 1.1.0 format with Semantic Versioning headings. Key structure:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses Semantic Versioning headings like `[0.1.0]` for published Hex releases.
Separately, maintainers track planning milestones in `.planning/MILESTONES.md` —
those labels describe shipped tranches of work, not a second installable version axis on Hex.

## [Unreleased]

### Added

* Initial public release.
```

The `## Planning milestones vs Hex releases` section is mandatory — without it, readers will be confused by the gap between "v3.2 Commerce" milestone labels and `0.1.0` Hex version. Do NOT add a `### Summary` subsection (bootstrap-elixir-hex-lib gotcha #6).

release-please will maintain this file automatically after first publish.

### `LICENSE`

Currently missing from the repo root. Must be added before publish. Use MIT (Apache-2.0 is set in `package/0 :licenses` but crosswake's actual license file is absent). **Decision needed:** confirm whether Apache-2.0 or MIT is correct for Crosswake. Current `mix.exs` says `Apache-2.0`. Use Apache-2.0 consistently — create the `LICENSE` file with Apache-2.0 text, year 2026, holder `sztheory`. Do not change the `:licenses` field to MIT without a deliberate decision.

### `.tool-versions`

Currently absent from the repo. Required for `erlef/setup-beam` with `version-type: strict` in all CI workflows. Copy from oarlock:

```
erlang 28.1
elixir 1.19.5-otp-28
```

`mix.exs` already requires `elixir: "~> 1.19"` — this is consistent. The `.tool-versions` pin ensures CI uses the exact same runtime as local dev. `version-type: strict` prevents silent version drift.

---

## Mix task invocations (phase reference)

| Task | When | Purpose |
|------|------|---------|
| `mix hex.build` | Package metadata audit phase | Inspect tarball name (must be `crosswake-X.Y.Z.tar`, not `crosswake-X.Y.Z.tar` from `:crosswake` atom — names match here but always verify), audit included files |
| `mix hex.publish --dry-run --yes` | Before first real publish | Validates all metadata, checks for conflicts, does not push to hex.pm |
| `mix hex.publish --yes` | Automated via CI on release tag | Actual publish; `--yes` skips interactive confirmation for CI |
| `mix docs` | Hex page polish phase | Generates `doc/` locally; review that README renders correctly and no broken links |
| `mix deps.unlock --check-unused` | CI gate | Catches phantom deps in `mix.lock` — already used in oarlock CI, add to crosswake `ci.yml` |

---

## Versioning decision

**Recommendation: start at `0.1.0` on hex.pm.**

Rationale: Crosswake has shipped 5 internal planning milestones (v1.0–v3.2) with 11.5k LOC. Those are planning labels, not published Hex versions. The first published Hex version signals "installable and trustworthy enough to pin" — `0.1.0` is the honest claim for a library that has never been published and whose API surface has not been validated by external adopters. `1.0.0-rc.0` would signal API stability guarantees that haven't been tested outside the repo. The thread note in `release-readiness.md` suggests `1.0.0-rc.0` as a "contract maturity signal" — but contract maturity in planning milestones does not equal published API stability. The oarlock/sigra precedent also starts at `0.1.0` regardless of internal milestone count.

If v3.3 ships and community adopters validate the install path without API breakage, bumping to `1.0.0` in a subsequent milestone is straightforward. Going backward from `1.0.0-rc.0` is harder to communicate.

**hex.pm name availability:** `crosswake` returns HTTP 404 from `https://hex.pm/api/packages/crosswake` — name is available. No need for fallback names (`crosswake_sdk`, `ex_crosswake`).

---

## Alternatives Considered

| Decision | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Release pipeline | release-please | Tag-driven manual release | release-please automates CHANGELOG, version bump, and GitHub release creation from conventional commits. Manual tag-driven release requires maintaining CHANGELOG by hand and is inconsistent with szTheory house style. |
| Release pipeline version | v5.0.0 (`@45996ed`) | v4.4.1 | v5 is stable (non-prerelease, 2026-04-22), only breaking change is Node 24 runner which GitHub provides. New projects should start on current version. |
| CHANGELOG generator | release-please | git-cliff, towncrier | release-please handles both CHANGELOG and version bumps atomically. Adding a separate CHANGELOG generator creates two tools where one suffices. |
| Documentation | ex_doc ~> 0.38 | ex_doc ~> 0.34 (oarlock pin) | ~> 0.38 picks up improvements through 0.40.x (current: 0.40.3, 2026-05-21). 0.34 still works but is more restrictive than needed. |
| Initial Hex version | 0.1.0 | 1.0.0-rc.0 | 0.1.0 is the honest first-publish signal. 1.0.0-rc.0 implies external API stability guarantees not yet tested by real adopters. |

---

## What NOT to add

| Avoid | Why |
|-------|-----|
| `git-cliff` or `auto-changelog` | release-please already manages CHANGELOG — a second tool creates divergence |
| `mix_test_watch` or similar in publish workflow | Dev convenience tooling; not relevant to release pipeline |
| Postgrex / Ecto service blocks in CI | Crosswake has no DB dependency — adding a Postgres block adds unnecessary build time |
| `ex_doc` outside `only: :dev` | Would force adopters to compile documentation tooling at install time |
| `RELEASE_PLEASE_TOKEN` as a hard requirement | It is optional — `github.token` suffices unless branch protection rules block the default token from creating PRs. Wire as `secrets.RELEASE_PLEASE_TOKEN || github.token` so it degrades gracefully. |

---

## SHA pin reference

All SHA pins verified from GitHub API as of 2026-05-27.

| Action | Tag | SHA |
|--------|-----|-----|
| `googleapis/release-please-action` | v5.0.0 | `45996ed1f6d02564a971a2fa1b5860e934307cf7` |
| `actions/checkout` | v6.0.2 | `de0fac2e4500dabe0009e67214ff5f5447ce83dd` |
| `erlef/setup-beam` | v1.24.0 | `fc68ffb90438ef2936bbb3251622353b3dcb2f93` |
| `actions/cache` | v4.3.0 | `0057852bfaa89a56745cba8c7296529d2fc39830` |

`actions/checkout`, `erlef/setup-beam`, and `actions/cache` SHA pins are taken directly from the oarlock canonical template (already verified and in production). Only the `release-please-action` pin changes (v4 → v5).

---

## Sources

- `https://hex.pm/api/packages/ex_doc` — confirmed latest ex_doc 0.40.3, published 2026-05-21
- `https://hex.pm/api/packages/crosswake` — HTTP 404, name available
- `https://api.github.com/repos/googleapis/release-please-action/releases` — confirmed v5.0.0 stable, 2026-04-22
- `https://api.github.com/repos/googleapis/release-please-action/tags` — SHA `45996ed1f6d02564a971a2fa1b5860e934307cf7` for v5.0.0
- `https://raw.githubusercontent.com/googleapis/release-please/main/README.md` — confirmed `release-type: "elixir"` is a supported type
- `https://api.github.com/repos/googleapis/release-please/contents/src/updaters/elixir/elixir-mix-exs.ts` — verified `@version "..."` regex pattern that release-please uses to update mix.exs
- `/Users/jon/projects/oarlock/.github/workflows/release-please.yml` — canonical template (in-repo, HIGH confidence)
- `/Users/jon/projects/oarlock/mix.exs` — canonical package/docs block pattern (in-repo, HIGH confidence)
- `/Users/jon/projects/oarlock/.tool-versions` — erlang 28.1 / elixir 1.19.5-otp-28 (in-repo, HIGH confidence)
- `/Users/jon/.claude/skills/bootstrap-elixir-hex-lib/SKILL.md` — paved-path skill with 6 verified gotchas

---
*Stack research for: hex.pm publication infrastructure (v3.3 Release Readiness)*
*Researched: 2026-05-27*
