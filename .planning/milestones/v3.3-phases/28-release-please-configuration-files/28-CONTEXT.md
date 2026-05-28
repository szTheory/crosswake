# Phase 28: release-please Configuration Files - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the three configuration files required for the `release-please` automation that will be introduced in Phase 29. These files ensure reproducible builds across environments and configure how `release-please` interacts with our repository history.

In scope for this phase:
1. `release-please-config.json` configuration at the root.
2. `.release-please-manifest.json` tracker at the root.
3. `.tool-versions` for `asdf`/`mise` to pin runtime dependencies.

Out of scope for this phase: GitHub Action workflows, package publishing, package metadata updates.

</domain>

<decisions>
## Implementation Decisions

### `release-please-config.json` configuration

- **D-01:** `release-type` is set to `"elixir"`. This matches the ecosystem requirements.
- **D-02:** `bump-minor-pre-major` is set to `false`.
- **D-03:** `bump-patch-for-minor-pre-major` is set to `true`. This follows the oarlock/lattice_stripe pattern for pre-1.0 libraries, ensuring we bump patch instead of minor versions when a `fix:` commit is landed.
- **D-04:** `release-as` is pinned to `"0.1.0"`. This ensures the first release created by `release-please` matches our intent (v0.1.0) regardless of the commit history. (This pin will be removed in Phase 32).
- **D-05:** `bootstrap-sha` is set to `f788e312747e14b157c8498ba710f057534530f5`. This is the commit corresponding to the `v3.2` tag (the last commit before the v3.3 milestone started). Anchoring here prevents `release-please` from walking backward through the 25 prior phases of non-conventional or internal commits.

### `.release-please-manifest.json` tracking

- **D-06:** The manifest MUST contain exactly `{"." : "0.0.0"}`. Initializing with `0.0.0` prevents the off-by-one footgun where `release-please` would immediately try to bump the version to `0.2.0` on its first run if it were initialized at `0.1.0`.

### `.tool-versions` pinning

- **D-07:** The `.tool-versions` file must pin the Elixir and Erlang/OTP versions used across the project's CI and local development. Based on `.github/workflows/phase5-proof.yml`, we will use:
  - `erlang 27.3`
  - `elixir 1.19.5-otp-27`

### Claude's Discretion

- Ensure JSON files are correctly formatted and cleanly indented (2 spaces).
- Do not add trailing commas in JSON files.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone Scope And Phase Contract

- `.planning/ROADMAP.md` §"Phase 28: release-please Configuration Files" — goal, depends-on, requirements list, and success criteria.
- `.planning/REQUIREMENTS.md` §"REL-01, REL-02, REL-09" — the three requirements mapped to Phase 28 in the traceability table.
</canonical_refs>