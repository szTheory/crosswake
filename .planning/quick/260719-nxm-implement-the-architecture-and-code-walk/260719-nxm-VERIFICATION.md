---
quick_id: 260719-nxm
status: passed
verified: 2026-07-19
human_needed: false
---

# Quick Task 260719-nxm Verification

## Result

Passed. The committed implementation satisfies every declared truth, artifact, and key link.
No runtime contract, support claim, generated bridge surface, or publication boundary changed.

## Must-have evidence

### Truths

- The two guides teach one consistent route declaration → validated policy → versioned manifest
  → owner-or-denial activation → bounded affordance path. The architecture guide keeps the
  required 13-section order; the walkthrough ends with concrete source-reading sequences.
- Claims match current source: per-route ownership and fail-closed denials stay central,
  cached read-only remains distinct from local-first mutation, examples are described as
  proof/host plumbing, and neither guide mentions the planned `Crosswake.Bridge.push/3` API.
- The package map distinguishes core, SwiftPM/Maven shell cores, five independently versioned
  in-repo companions, and host-owned/generated proof surfaces. Publication truth is delegated
  to `mix crosswake.release.status --live`.
- `guides/architecture.md` contains exactly four Mermaid blocks and four `accTitle`/`accDescr`
  pairs. Fresh browser checks rendered four titled/described SVGs in light and dark themes,
  replaced them without duplicates after a live `body.dark` mutation, contained narrow-screen
  overflow, and left all four raw source blocks visible when Mermaid was unavailable.
- ExDoc retains README as `main`, README/See It Run at indices 0/1, the new guides at 2/3,
  Route Policy/Install immediately afterward in Start, and the original seven group keys in
  their original order.
- `brandbook/logo/favicon.svg` is configured while the existing logo path is unchanged.
  Generated `doc/assets/favicon.svg` is byte-identical and both generated pages link it.
- The focused contract test guards guide order, reader lanes, heading/diagram structure,
  12–18 excerpts, parseable Elixir, live exports, portable links, mutual navigation, favicon,
  pinned renderer hooks, fallback behavior, and empty EPUB callbacks.

### Artifacts

- `guides/architecture.md`: present, 13 required sections, four accessible diagrams.
- `guides/code-walkthrough.md`: present, 18 representative excerpts (16 Elixir, one Swift,
  one Kotlin); every Elixir fence parses.
- `mix.exs`: registers both guides, canonical favicon, Mermaid 11.15.0 with the declared SRI,
  strict mode, brand light/dark variables, serialized rendering, ExDoc navigation/theme hooks,
  and source-preserving failure fallback.
- `README.md` and `CHANGELOG.md`: intended evaluation/maintainer lanes, guide-map entries, and
  an explicitly documentation-only Unreleased entry.
- `test/crosswake/guides/architecture_code_walkthrough_test.exs`: present and passing. The
  source-derived Phase 52 fixture update reflects only the two extras and Documentation heading.

### Key links

- Current source and excerpts agree across `Crosswake.Router`, Policy Compiler/Route/Validator,
  and Manifest Builder/Validator/Serializer; the focused Router/Policy/Manifest tests pass.
- Current Activation delegates to RouteGate and maps to the declared owner or stable denial;
  focused activation, companion restriction, and fail-closed tests pass.
- Bridge Contract/Registry retain the closed versioned vocabulary and route declaration checks;
  inspected Swift/Kotlin sources independently enforce active-route/session equality.
- Generated HTML contains the fenced source, pinned strict renderer, brand themes,
  `exdoc:loaded` hook, class observer, and readable no-renderer fallback verified in-browser.
- The new documentation contract, focused behavioral suites, full Elixir regression, Swift
  package tests, ExDoc build, and Hex tarball gate all agree with the guide claims.

## Fresh verification

- Documentation path: **27 tests, 0 failures**.
- Focused source-anchor behavior: **167 tests, 0 failures**.
- Full hermetic Elixir regression: **1,024 tests, 0 failures (61 excluded)**.
- Swift shell core: **6 tests, 0 failures**.
- `mix docs`: succeeded; architecture, walkthrough, and favicon outputs exist.
- `bash script/verify_hex_tarball.sh`: passed and packaged both guides.
- `git diff --check ccd8f20a^..bc79dde1`: clean.
- Desktop light/dark and 390 px dark screenshots were inspected; no page-level overflow or
  illegible diagram state was found. Offline browser proof showed 0 SVG/output containers and
  4 visible raw Mermaid sources.

## Non-blocking environment/tooling notes

- A fresh Android Gradle rerun could not start because this verifier environment has no Java
  runtime. The execution summary records the prior successful Android JVM run; current Kotlin
  source was inspected directly and the fresh shared contract-drift/behavioral suites passed.
  This is an environment limitation, not an implementation gap.
- The plan's bare `mix format --check-formatted` remains unusable because repository formatter
  inputs are not configured. An explicit check reports only three pre-existing `mix.exs`
  transformations outside this task's changed lines; the new test file is formatted and the
  committed diff is whitespace-clean.
