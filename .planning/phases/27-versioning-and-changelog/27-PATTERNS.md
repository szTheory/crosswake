# Phase 27: Versioning and Changelog - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 2
**Analogs found:** 1 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `CHANGELOG.md` | documentation | N/A | None (use `REC-CHANGELOG.md`) | N/A |
| `mix.exs` | config | config | `mix.exs` (self) | exact |

## Pattern Assignments

### `mix.exs` (config, config)

**Analog:** `mix.exs`

**Docs Extras List Pattern** (lines 49-74):
```elixir
  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      formatters: ["html"],
      extras: [
        "README.md",
        "LICENSE",
        "guides/install.md",
        "guides/support_matrix.md",
        "guides/adopter_profiles.md",
        "guides/user_flows.md",
        "guides/capabilities.md",
        "guides/bridge.md",
        "guides/offline.md",
        "guides/commerce.md",
        "guides/compatibility.md",
        "guides/native_shell.md",
        "guides/packs.md"
      ],
      groups_for_extras: [
        Guides: ~r/guides\//
      ]
    ]
  end
```

---

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `CHANGELOG.md` | documentation | N/A | First release changelog; must copy the exact skeleton from `.planning/research/REC-CHANGELOG.md`. |

### `CHANGELOG.md` (documentation, N/A)

**Source:** `.planning/research/REC-CHANGELOG.md` (lines 173-207)
**Pattern:** Keep-a-Changelog format with preamble, `[Unreleased]` anchor, and synthesized `[0.1.0]` entry.

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

## [0.1.0] — 2026-MM-DD

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

## Shared Patterns

None identified.

## Metadata

**Analog search scope:** Project root files (`mix.exs`, `CHANGELOG.md` equivalent docs)
**Files scanned:** 2
**Pattern extraction date:** 2026-05-28
