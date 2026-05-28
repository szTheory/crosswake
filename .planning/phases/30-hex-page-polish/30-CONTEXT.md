# Phase 30: Hex Page Polish And Tarball Dry-Run - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Confirm `README.md`, `mix docs` output, and the published tarball are clean and adopter-ready before the publish phase can be triggered.
</domain>

<decisions>
## Implementation Decisions

### README.md Link Rewrite Strategy
- **D-01:** Keep links to internal guides (e.g. `[guides/install.md](guides/install.md)`) as **relative**. `ex_doc` automatically transforms these into `.html` links, giving the best native HexDocs experience without breaking GitHub navigation. This is idiomatic Elixir.
- **D-02:** Rewrite links to non-package files (e.g., `examples/`, `script/`, `prompts/`, `AGENTS.md`) to **absolute URLs** pointing to the `main` branch on GitHub: `https://github.com/szTheory/crosswake/blob/main/...`. This prevents 404s on Hex.pm since these files are excluded from the tarball, while keeping examples fresh and accessible.

### Docs Structure / Polish
- **D-03:** Organize the `ex_doc` sidebar into logical module groups using `groups_for_modules` in `mix.exs` (e.g., `:Policy`, `:Bridge`, `:Manifest`, `:Capabilities`).
- **D-04:** Subdivide the `extras` into logical groups using `groups_for_extras` (e.g., `:Setup`, `:Capabilities`, `:Guides`). This provides exceptional developer ergonomics and prevents the sidebar from becoming an overwhelming flat list.

### Tarball Exclusions
- **D-05:** Rely on the strict, explicit `:files` **allowlist** already defined in `mix.exs`: `~w(lib priv .formatter.exs mix.exs README.md LICENSE CHANGELOG.md guides)`. This is the safest approach and inherently excludes all heavy or internal directories (`examples`, `prompts`, `.planning`, `test`, `script`) without needing a messy `.hexignore` blacklist.
- **D-06:** Before concluding, verify the exact tarball contents via `mix hex.build --unpack` to absolutely guarantee zero leakage.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Source Code
- `mix.exs` — Contains the current `docs/0` and `package/0` configurations.
- `README.md` — The target for link rewriting.

### Project Memory
- `prompts/crosswake-elixir-oss-dna.md` — Project principles emphasizing exact public-vs-internal boundaries and clean docs.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `mix.exs` `:files` definition is already tightly scoped, meaning we don't have to delete files; we just have to verify the allowlist is respected.
- `README.md` currently contains many relative links.

</code_context>

<specifics>
## Specific Ideas

- The user requested a cohesive, "one-shot" set of recommendations grounded in Elixir OSS best practices and the project's DNA (as detailed in `prompts/`). The decisions above reflect standard robust Hex package hygiene.
</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope
</deferred>

---

*Phase: 30-hex-page-polish*
*Context gathered: 2026-05-28*
