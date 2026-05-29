# Phase 30: Hex Page Polish And Tarball Dry-Run - Pattern Map

**Mapped:** 2026-05-28
**Files analyzed:** 2
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mix.exs` | config | config | `mix.exs` | exact |
| `README.md` | docs | config | `README.md` | exact |

## Pattern Assignments

### `mix.exs` (config, config)

**Analog:** `mix.exs`

**Package Files Allowlist pattern** (lines 48-59):
```elixir
  defp package do
    [
      name: "crosswake",
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Documentation" => "https://hexdocs.pm/crosswake",
        "GitHub" => @source_url
      },
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)
    ]
  end
```

**Docs configuration pattern** (lines 61-84):
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
        # ... other guides
      ],
      groups_for_extras: [
        Guides: ~r/guides\//
      ]
    ]
  end
```
*Note: Phase 30 requires expanding `groups_for_extras` and adding `groups_for_modules` to group the sidebar elements.*

---

### `README.md` (docs, config)

**Analog:** `README.md`

**Relative links to guides pattern** (lines 28-32):
```markdown
- [guides/user_flows.md](guides/user_flows.md) for the fastest JTBD and user-flow ramp-up
- [guides/adopter_profiles.md](guides/adopter_profiles.md) for the three target app shapes
- [guides/install.md](guides/install.md) for the public install and proof path
- [guides/support_matrix.md](guides/support_matrix.md) for the current supported baseline
```

**Absolute links to internal/excluded files pattern** (lines 33, 54):
*(Needs to be rewritten from current relative to absolute GitHub URLs in Phase 30)*
```markdown
- [examples/phoenix_host/README.md](https://github.com/szTheory/crosswake/blob/main/examples/phoenix_host/README.md) for the shared exemplar host contract
- [AGENTS.md](https://github.com/szTheory/crosswake/blob/main/AGENTS.md)
```

## Shared Patterns

### Hex Package Hygiene & Elixir OSS DNA
**Source:** `prompts/crosswake-elixir-oss-dna.md` & `30-CONTEXT.md`
**Apply to:** `mix.exs` and `README.md`
- **Docs Map:** "Keep root README as the map, not the whole book. Point users into deeper guides after the first-run path."
- **Strict Allowlist:** Rely on the `mix.exs` `:files` string array allowlist to exclude non-public artifacts (like `examples/`, `prompts/`, `.planning/`) from the tarball, rather than blacklisting via `.hexignore`.
- **Link Rewriting:** Ensure links in `README.md` to tarball-excluded items use absolute GitHub URLs (`https://github.com/szTheory/crosswake/blob/main/...`) so they don't break on Hex.pm.

## No Analog Found

None.

## Metadata

**Analog search scope:** Project root directory
**Files scanned:** 2
**Pattern extraction date:** 2026-05-28
