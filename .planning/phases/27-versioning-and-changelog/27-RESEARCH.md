# Phase 27: Versioning and Changelog - Research

**Researched:** 2026-05-28
**Domain:** Documentation and Release Tooling
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** **Keep-a-Changelog + `[Unreleased]` anchor.** `CHANGELOG.md` uses the KaC format and includes an `## [Unreleased]` anchor below the preamble and above the first versioned entry. This is required for release-please insertion logic.
- **D-02:** **Single `[0.1.0]` entry.** Do not create per-milestone headers (`v1.0`, `v3.2`). Synthesize the internal history into a single capability statement for `0.1.0`.
- **D-03:** **Preamble disambiguation.** Add a preamble explaining the difference between internal planning milestones (`v1.0` - `v3.2` in `MILESTONES.md`) and the public Hex semver releases (starting at `0.1.0`).
- **D-04:** **Roadmap traceability.** Add a `### Roadmap traceability` subsection within the `[0.1.0]` entry, linking to `.planning/MILESTONES.md` and `.planning/PROJECT.md`.
- **D-05:** **Explicit capability bullets.** The `[0.1.0]` entry must have 4-5 bullets describing actual runtime capabilities: route policy DSL, manifest + capability ladder, bounded bridge with v3.1 families, offline contracts, commerce + entitlement seams with reconciliation example.
- **D-06:** **Explicit non-claims.** Include a non-claim statement: "no provider adapters yet, no first-party companions yet".
- **D-07:** **Add `"CHANGELOG.md"` to `docs/0` extras.** Phase 26 deferred adding `CHANGELOG.md` to the `mix.exs` `docs/0` extras list. Phase 27 must add this line in the same commit that creates the file.
- **D-08:** `@version "0.1.0"`. `mix.exs` is already pinned to `"0.1.0"`. Leave it as is and confirm it compiles.

### the agent's Discretion
- **Date formatting:** Use the current date for the `[0.1.0]` release date if applicable, or leave a placeholder if preferred by the template.
- **Capability phrasing:** Adopt the bullet phrasing from the `REC-CHANGELOG.md` skeleton verbatim.

### Deferred Ideas (OUT OF SCOPE)
- **Machine-enforced CHANGELOG shape test** — deferred to v3.4 per `REC-CHANGELOG.md`.
</user_constraints>

## Summary

Phase 27 requires establishing a formal `CHANGELOG.md` file for the first published Hex version (0.1.0) of Crosswake. The goal is to produce a Keep-a-Changelog formatted file that is parseable by release-please and includes a single 0.1.0 entry summarizing the capabilities built across all previous internal milestones. This phase also updates `mix.exs` to include `CHANGELOG.md` in the generated ExDoc documentation.

**Primary recommendation:** Create `CHANGELOG.md` at the project root using the exact skeleton provided in `REC-CHANGELOG.md`, filling in the `2026-05-28` date, and append `"CHANGELOG.md"` to the `extras` list in the `docs/0` function of `mix.exs`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CHANGELOG Management | API / Backend (Tooling) | — | Versioning and changelog are package-level tooling responsibilities managed by the library repository structure. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Keep-a-Changelog | 1.1.0 | Changelog format standard | release-please compatible, provides structured versioning. |

## Architecture Patterns

### Recommended Project Structure
```
/
├── CHANGELOG.md    # New file at repo root
├── mix.exs         # Updated to reference CHANGELOG.md in docs
```

### Pattern 1: Keep-a-Changelog with release-please
**What:** Using standard Keep-a-Changelog sections like `## [Unreleased]` and `## [0.1.0]` allows release-please to automatically parse and prepend future release notes directly into the document.
**When to use:** When managing automated releases via release-please in Elixir Hex packages.
**Example:**
```markdown
## [Unreleased]

### Added
* Initial public release.

## [0.1.0] — 2026-05-28
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Changelog structure | Custom markdown list | Keep-a-Changelog | release-please relies on specific KaC regex (`\n###? v?[0-9[]`) to find insertion points. Custom formats break automation. |

## Runtime State Inventory

Step 2.5: SKIPPED (no runtime state affected by purely static files and documentation additions)

## Common Pitfalls

### Pitfall 1: Per-milestone headers (`## v1.0`, `## v3.2`)
**What goes wrong:** Release-please inserts new version entries in the wrong place. Adopters think v3.2 is an installable Hex package.
**Why it happens:** Confusing internal planning labels with public SemVer releases.
**How to avoid:** Use a single `[0.1.0]` release header. Detail the internal milestones under a `### Roadmap traceability` subsection.
**Warning signs:** `CHANGELOG.md` contains headers like `## v1.0` or `## v3.0`.

### Pitfall 2: Omitting `## [Unreleased]` anchor
**What goes wrong:** release-please doesn't know where to insert new releases, or prepends them awkwardly.
**Why it happens:** Believing that since this is the first release, "Unreleased" is unnecessary.
**How to avoid:** Always include the `## [Unreleased]` section directly above the first version block.

## Code Examples

### CHANGELOG.md Skeleton Implementation
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v3.2** in **`.planning/MILESTONES.md`** — those labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`MILESTONES.md`** as canonical for milestone dates and archive paths.

## [Unreleased]

### Added

* Initial public release.

## [0.1.0] — 2026-05-28

### Added

* Route policy DSL for declaring per-route runtime ownership: LiveView, offline island, native screen, or adapter. Runtime manifest and compatibility contract generated from route policy declarations.
* Bounded bridge contract for low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `file_picker`) with route-local enforcement and typed command envelopes.
* Offline semantics: cached read-only routes, offline islands with append-only journals, sync endpoints, and server-authoritative reconciliation — each with explicit contract boundaries and doctor diagnostics.
* Commerce corridor declarations with provider-neutral `commerce.corridor.*` denial vocabulary, entitlement lifecycle lane semantics (authority/access/reconciliation/freshness/evidence), and a Phoenix-owned reconciliation inbox example. Provider adapters (StoreKit, Play Billing) are not included; this release operationalizes the seam contract only.
* `mix crosswake.doctor` diagnostics, support matrix, and proof lanes verified against three adopter-shaped exemplar lanes: Phoenix SaaS portal, selective-native flow, and local-first study flow.

### Roadmap traceability

Internal planning milestones v1.0 (Route Policy Foundation), v2.0 (Adopter Stress Profiles), v3.0 (Capability Contract And Packaging), v3.1 (Native Capabilities and Bridge Expansion), and v3.2 (Commerce And Entitlement Seams) are archived in `.planning/MILESTONES.md`. These are not separate Hex releases.

[Unreleased]: https://github.com/szTheory/crosswake/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/szTheory/crosswake/releases/tag/v0.1.0
```

### `mix.exs` update
In the `docs/0` function's `extras` list, append `"CHANGELOG.md"` alongside `"README.md"`:
```elixir
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "guides/install.md",
        # ...
      ],
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom release formats | Keep-a-Changelog with release-please | 2021+ | Automated semantic releases without manual changelog edits |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| (Empty table) | All claims verified via context files | — | — |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOG-01 | CHANGELOG.md exists and valid | manual-only | `mix compile` | ❌ |

### Sampling Rate
- **Per task commit:** `mix compile`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements.

## Sources

### Primary (HIGH confidence)
- `.planning/research/REC-CHANGELOG.md` - CHANGELOG format recommendations and explicit skeleton.
- `.planning/milestones/v3.3-phases/27-versioning-and-changelog/27-CONTEXT.md` - Phase constraints and decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Recommended explicitly by REC-CHANGELOG.md
- Architecture: HIGH - Dictated by context.
- Pitfalls: HIGH - Detailed in REC-CHANGELOG.md

**Research date:** 2026-05-28
**Valid until:** 2026-06-28
