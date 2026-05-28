# Phase 29: Release Workflows And Supply-Chain Hardening - Context

## Goal
Land both release workflow files (Release PR creation + manual recovery) and bake in supply-chain hardening so post-CVE-2025-30066 tag-move attacks cannot affect Crosswake's release pipeline.

## Requirements
- **REL-03:** `.github/workflows/release-please.yml` exists, built from the oarlock canonical template (no `sync_release_summary.sh` job). Uses the singular `release_created` output. Contains a `publish-hex` job gated on `if: needs.release-please.outputs.release_created == 'true'`.
- **REL-04:** `.github/workflows/hex-publish.yml` exists as a `workflow_dispatch` manual-recovery backup with `tag` and `release_version` inputs.
- **REL-05:** Every external action (`actions/checkout`, `erlef/setup-beam`, `actions/cache`, `googleapis/release-please-action`) is pinned to a full commit SHA with a `# vX.Y.Z` comment. No `@vN`-tag references remain.
- **REL-06:** `.github/dependabot.yml` exists with `package-ecosystem: "github-actions"` so SHA pins surface as PRs when upstream Actions ship updates.

## Source Materials
- `~/projects/oarlock/.github/workflows/release-please.yml` (Canonical template)
- `~/projects/oarlock/.github/workflows/hex-publish.yml` (Manual recovery template)
- `.planning/research/REC-PIPELINE.md`

## Out of Scope
- A general `ci.yml` PR gate. (REQUIREMENTS.md explicitly marks this as a non-blocking quality-of-life cleanup for v3.3).
