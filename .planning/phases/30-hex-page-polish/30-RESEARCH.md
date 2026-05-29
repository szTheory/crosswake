<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### README.md Link Rewrite Strategy
- **D-01:** Keep links to internal guides (e.g. `[guides/install.md](guides/install.md)`) as **relative**. `ex_doc` automatically transforms these into `.html` links, giving the best native HexDocs experience without breaking GitHub navigation. This is idiomatic Elixir.
- **D-02:** Rewrite links to non-package files (e.g., `examples/`, `script/`, `prompts/`, `AGENTS.md`) to **absolute URLs** pointing to the `main` branch on GitHub: `https://github.com/szTheory/crosswake/blob/main/...`. This prevents 404s on Hex.pm since these files are excluded from the tarball, while keeping examples fresh and accessible.

### Docs Structure / Polish
- **D-03:** Organize the `ex_doc` sidebar into logical module groups using `groups_for_modules` in `mix.exs` (e.g., `:Policy`, `:Bridge`, `:Manifest`, `:Capabilities`).
- **D-04:** Subdivide the `extras` into logical groups using `groups_for_extras` (e.g., `:Setup`, `:Capabilities`, `:Guides`). This provides exceptional developer ergonomics and prevents the sidebar from becoming an overwhelming flat list.

### Tarball Exclusions
- **D-05:** Rely on the strict, explicit `:files` **allowlist** already defined in `mix.exs`: `~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)`. This is the safest approach and inherently excludes all heavy or internal directories (`examples`, `prompts`, `.planning`, `test`, `script`) without needing a messy `.hexignore` blacklist.
- **D-06:** Before concluding, verify the exact tarball contents via `mix hex.build --unpack` to absolutely guarantee zero leakage.

### the agent's Discretion
None explicitly noted, though standard Elixir OSS grouping names are left for inference.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HEX-01 | `README.md` uses absolute URLs only for non-tarball paths | See Pattern: README Link rewriting (relative -> absolute GitHub URLs) |
| HEX-02 | `mix hex.build --unpack` is run pre-publish and tarball contents inspected | See Validation Architecture and Hex tarball dry run |
| HEX-03 | `mix docs` runs clean locally with zero warnings and produces correct structure | Supported by Docs Structure / Polish D-03, D-04 |
| PRF-01 | `mix hex.publish --dry-run` is run and passes | Native `mix hex.publish` capability documented |
</phase_requirements>

# Phase 30: Hex Page Polish And Tarball Dry-Run - Research

**Researched:** 2026-05-28
**Domain:** Elixir package documentation and Hex distribution
**Confidence:** HIGH

## Summary

This phase finalizes the `mix.exs` configuration and `README.md` to ensure a clean, professional, and correct Hex.pm package release. The focus is on two primary goals: first, ensuring that `ex_doc` generates a clean sidebar with grouped modules and extra pages, and second, ensuring that links inside `README.md` and other documentation do not result in 404s on HexDocs because they point to files omitted from the Hex tarball (like `examples/`).

**Primary recommendation:** Use `groups_for_modules` and `groups_for_extras` in `mix.exs` for grouping documentation, rewrite non-tarball links in `README.md` to absolute GitHub paths, and verify tarball contents locally using `mix hex.build --unpack` and `mix hex.publish --dry-run`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Documentation Generation | Build Tooling (`ex_doc`) | Hex.pm | `ex_doc` compiles markdown/docs to HTML for HexDocs |
| Distribution | Build Tooling (`hex`) | Hex.pm | `mix hex.build` creates the tarball; Hex hosts it |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir `mix` | ~> 1.19 | Package Management | Core Elixir build tool for packaging and publishing |
| `ex_doc` | ~> 0.38 | Doc Generation | The official, standard documentation generator for Elixir projects |
| `hex` | latest | Distribution | The package manager for the Erlang/Elixir ecosystem |

**Version verification:**
`mix.exs` currently specifies `{:ex_doc, "~> 0.38", only: :dev, runtime: false}`. `hex` is bundled with standard Elixir installations.

## Architecture Patterns

### Recommended mix.exs Documentation Pattern

**What:** Structuring `ex_doc` configuration within `mix.exs`.
**When to use:** Whenever a package is published to Hex and has multiple modules or guides.

**Example:**
```elixir
# In mix.exs docs/0 function
defp docs do
  [
    main: "readme",
    source_ref: "v#{@version}",
    source_url: @source_url,
    formatters: ["html"],
    extras: [
      "README.md",
      "CHANGELOG.md",
      "guides/install.md",
      # ... other guides
    ],
    groups_for_modules: [
      Policy: [Crosswake.Policy, Crosswake.Router],
      Bridge: [Crosswake.Bridge],
      Manifest: [Crosswake.Manifest],
      Capabilities: ~r/Crosswake\.(Commerce|Offline|Packs)/
      # Adapt these regexes/lists based on actual lib/ structure
    ],
    groups_for_extras: [
      Setup: ["guides/install.md", "guides/support_matrix.md"],
      Capabilities: ["guides/capabilities.md", "guides/commerce.md", "guides/offline.md", "guides/packs.md"],
      Guides: ~r/guides\//
    ]
  ]
end
```

### Pattern: README Link rewriting

Files that aren't included in the `hex` tarball (because they aren't in the `:files` allowlist in `mix.exs`) will trigger 404s if users click them on HexDocs.

- Internal guide links (e.g. `[Install](guides/install.md)`) → **Keep relative**. `ex_doc` transforms them to `.html`.
- Excluded repo paths (e.g. `[Examples](examples/phoenix_host/README.md)`) → **Rewrite to absolute GitHub main URLs**: `[Examples](https://github.com/szTheory/crosswake/blob/main/examples/phoenix_host/README.md)`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Package exclusion lists | `.hexignore` blacklist | `mix.exs` `:files` allowlist | Blacklists are brittle and leak secrets/large files easily. Allowlists guarantee exactly what goes into the tarball. |
| Doc sidebar structuring | Custom HTML/markdown sidebars | `groups_for_modules` and `groups_for_extras` | `ex_doc` natively supports logical grouping; hand-rolling breaks HexDocs indexing and native styling. |

## Common Pitfalls

### Pitfall 1: Broken Links on HexDocs
**What goes wrong:** Users click a link to a file like `examples/demo.exs` from the README on HexDocs, and get a 404.
**Why it happens:** The `examples/` directory is (correctly) omitted from the Hex release, so HexDocs doesn't have the file. The relative markdown link is preserved but points to a non-existent path on `hexdocs.pm`.
**How to avoid:** Rewrite all links to non-packaged paths in `README.md` to point to `https://github.com/szTheory/crosswake/blob/main/path`.

### Pitfall 2: Overwhelming Flat Doc Sidebar
**What goes wrong:** A package with dozens of modules or guides displays them all in a single, unstructured alphabetical list.
**Why it happens:** Failing to configure `groups_for_modules` and `groups_for_extras`.
**How to avoid:** Explicitly cluster related modules into groups (e.g., `:Policy`, `:Core`, `:Manifest`) in `mix.exs`.

### Pitfall 3: Leaking files into the tarball
**What goes wrong:** The published `.tar` file is tens of megabytes, containing git history, `.planning`, or test binaries.
**Why it happens:** Relying on `.hexignore` and forgetting to ignore new heavy directories.
**How to avoid:** Use an explicit `:files` allowlist (`~w(lib priv mix.exs README.md LICENSE CHANGELOG.md guides)`). Verify with `mix hex.build --unpack` before publishing.

## Code Examples

### Hex tarball dry run

```bash
# Safely verify exactly what is going to Hex
mix hex.build --unpack

# Then examine the unpacked directory
ls crosswake-0.1.0/

# Verify pre-publish checks
mix hex.publish --dry-run
```

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / `mix` | Package generation | ✓ | ~> 1.19 | — |
| `mix hex.build` | Tarball validation | ✓ | standard | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | bash script (dry run manual testing) |
| Config file | `mix.exs` |
| Quick run command | `mix hex.build --unpack && find crosswake-* -type f` |
| Full suite command | `mix docs && open doc/index.html` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HEX-01 | README absolute URLs | static | `grep -E '\[.*\]\(.*examples/.*\)' README.md` | ✅ Wave 0 |
| HEX-02 | Tarball unpacked and verified | unit | `mix hex.build --unpack && ls -R crosswake-*/` | ❌ Wave 0 |
| HEX-03 | Clean docs build | smoke | `mix docs 2>&1 | grep -q "warning:" && exit 1 || exit 0` | ✅ Wave 0 |
| PRF-01 | Dry-run publish passes | smoke | `mix hex.publish --dry-run --yes` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] No dedicated automated test script for checking the unpacked Hex build contents. The planner will need to schedule a step to manually run and inspect the dry-run output or script it.

## Sources

### Primary (HIGH confidence)
- Official Elixir documentation for `ex_doc`: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
- Mix hex.build documentation: https://hexdocs.pm/hex/Mix.Tasks.Hex.Build.html

### Secondary (MEDIUM confidence)
- Current project's `mix.exs` and `README.md`

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir tooling handles this exclusively.
- Architecture: HIGH - Direct configurations supported by `ex_doc` and `hex`.
- Pitfalls: HIGH - Common documented issues in Hex releases.

**Research date:** 2026-05-28
**Valid until:** 6 months (tooling is stable)