# Research Summary: v3.3 Release Readiness

**Date:** 2026-05-27

## Stack Additions

- **release-please-action v5.0.0** (`SHA 45996ed`, shipped 2026-04-22) — current stable. v5 uses singular `release_created` output (v4 uses always-true plural `releases_created`).
- **`ex_doc ~> 0.38`** as dev/docs dep (latest 0.40.3 verified on hex.pm 2026-05-21).
- **`.tool-versions`** committed for reproducible Elixir/OTP across local + CI.
- **`crosswake` hex package name is available** (HTTP 404 from hex.pm API on 2026-05-27).
- No new runtime deps; this milestone is infra-only.

## Feature Table Stakes

Six categories drive 32 features across the milestone:

- **A. Package Metadata Truth** — real `source_url`, `name:`, `:files` allowlist (must include `priv/` for installer templates), `:links` (Source/Docs/Changelog), `:maintainers`, audited `:licenses`, `docs/0` function.
- **B. Versioning Policy** — first hex version is `0.1.0` (recommended), not `1.0.0-rc.0`. Internal `v1.0`–`v3.2` milestone labels are planning artifacts, not hex versions.
- **C. CHANGELOG** — Keep-a-Changelog format, `## [Unreleased]` anchor for release-please, preamble disambiguating planning milestones vs hex releases, history folded into one `[0.1.0]` entry.
- **D. Release Pipeline** — release-please config + manifest baselined at `"0.0.0"` (not `"0.1.0"`), one-time `release-as: "0.1.0"` pin, `release-please.yml` workflow (oarlock template), `hex-publish.yml` manual recovery, SHA-pinned actions, `HEX_API_KEY` secret.
- **E. Hex Page Polish** — README absolute-URL audit (no `examples/phoenix_host/README.md` links — those become dead links), `mix docs` clean output, `mix hex.build --unpack` tarball content audit.
- **F. Proof** — dry-run publish (`mix hex.publish --dry-run`), post-publish smoke install via `mix new --hex crosswake`, remove `release-as` pin after first publish.

## Watch Out For

**Critical / irreversible:**

- **Files allowlist gap** — current `mix.exs` has no `:files` key. Setting one carelessly ships `.planning/`, `prompts/`, or `test/` into the tarball; omitting `priv/` breaks `mix crosswake.install` for adopters. Verify with `mix hex.build --unpack`.
- **release-please manifest off-by-one** — baseline at `"0.0.0"` (not `"0.1.0"`), plus explicit `release-as: "0.1.0"` pin, then **remove the pin** after first publish.
- **GitHub Actions PR permission** — flip `default_workflow_permissions=write` immediately after first push or release-please silently produces no Release PRs.
- **Post-publish irreversibility** — version revert window is 1 hour (24h for brand-new packages). After that, version exists permanently. Run dry-runs first.
- **Non-conventional commit history** — 25 phases of internal-style commits would explode the auto-CHANGELOG. Use `bootstrap-sha` anchor in release-please config to prevent backwards walk.
- **`source_url` placeholder** — `https://github.com/example/crosswake` currently in `mix.exs:37-42`. Every "view source" link on hexdocs and hex.pm page will be broken if published as-is.

**Moderate but easy to miss:**

- Don't use sigra's release-please.yml as template — it contains a sigra-specific `sync_release_summary.sh` job that will block publish. Use oarlock's workflow.
- Pin GitHub Action versions by full commit SHA, not by tag (tj-actions incident, March 2025).
- README on hex.pm uses absolute URLs only — relative repo links break.
- `HEX_API_KEY` must be in the workflow `env:` block only, not in `with:` (prevents accidental log leakage).

## Sequencing Constraint

The build order is **strictly sequential** — no parallelization possible across categories:

```
A. Metadata Audit
    ↓
B. Version Decision + C. CHANGELOG Synthesis
    ↓
D. release-please Config (manifest + pin)
    ↓
D. Release Workflows + GitHub Permissions
    ↓
E. Hex Page Polish + Tarball Dry-Run
    ↓
F. HEX_API_KEY Setup → First Publish (human-gated)
    ↓
F. Post-Publish Cleanup (pin removal, smoke install)
```

## Human-Gated Steps

1. **Real GitHub repo URL confirmation** — placeholder `github.com/example/crosswake` must be replaced with the actual `szTheory/crosswake` (or chosen) URL before any phase can proceed past metadata audit.
2. **GitHub repo `default_workflow_permissions` flip** — manual `gh` CLI or web UI step.
3. **`HEX_API_KEY` generation** — must be created at hex.pm dashboard and installed via `gh secret set HEX_API_KEY` by maintainer.
4. **Release PR merge** — the publish event itself is a human-approved merge of release-please's Release PR.

## Out of Scope For v3.3

- Provider adapters (StoreKit, Play Billing) — deferred per existing decisions.
- New capability families — none.
- First-party companions (Rulestead, sigra, etc.) — blocked on v3.3 publish.
- Optional `mix crosswake.doctor --check-publish` install-truth surface — graduation candidate but not required for v3.3 publish.
- General-purpose `ci.yml` PR gate — existing phase-proof lanes remain authoritative for now.
- Advisory scheduled hex.pm liveness probe — optional, defer.

## Primary Sources Consulted

- `bootstrap-elixir-hex-lib` SKILL.md (oarlock post-mortem with 6 documented failures)
- hex.pm API live (package-name availability, publish/revert mechanics)
- release-please official docs + v4→v5 release notes + open issue tracker for output naming
- ExDoc latest version + canonical mix.exs `docs/0` patterns
- oarlock/sigra canonical reference implementations (workflow YAML, manifest format)
- GitHub Actions supply-chain advisories (tj-actions incident March 2025)
- Elixir Library Guidelines (hex.pm guidance, semver expectations)

## Confidence

| Area | Level |
|------|-------|
| Stack (versions, mix tasks, action SHAs) | HIGH — verified live |
| Features (categories, complexity, dependencies) | HIGH — sourced from canonical templates |
| Architecture (component classification, build order) | HIGH — proven sequence in skill + oarlock |
| Pitfalls (6 critical, 8 moderate) | HIGH — oarlock real-failure post-mortem |
