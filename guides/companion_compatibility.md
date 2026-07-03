# Companion Compatibility Matrix

This guide is the single source of truth for one question: *what core version and
which engine do I need to add a first-party companion package?* Each companion is
published as its own Hex package and versions independently of `crosswake` core.

For how to register a companion and what `mix crosswake.doctor` reports when a
dependency is missing, read [Companion Integrations](companions.md). For the
forward-looking compatibility contract (manifest, bridge, and runtime axes), read
[Compatibility Boundaries](compatibility.md). This matrix does not restate either
guide — it pins the per-package version facts the drift test keeps honest.

The `Requires crosswake` cell below is the verbatim Hex requirement extracted from
each package's `mix.exs`; a merge-blocking drift test
(`test/crosswake/proof/phase132_compat_matrix_drift_test.exs`) fails the build if a
cell drifts from the package source in either direction.

<!-- compat-03 contract: col1=Hex Package, requirement cell = "Requires `crosswake`";
     do not reorder columns without updating phase132_compat_matrix_drift_test.exs -->
<!-- Current Version: do not hand-edit; update this column post-publish from the confirmed hex.pm release page -->
| Hex Package | Companion ID | Current Version | Requires `crosswake` | Engine Dependency | hexdocs |
|---|---|---|---|---|---|
| `crosswake_rulestead` | `:rulestead` | `unpublished` | `~> 0.1` | `{:rulestead, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rulestead](https://hexdocs.pm/crosswake_rulestead) |
| `crosswake_rindle` | `:rindle` | `unpublished` | `~> 0.1` | `{:rindle, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rindle](https://hexdocs.pm/crosswake_rindle) |
| `crosswake_sigra` | `:sigra` | `unpublished` | `~> 0.2` | `{:sigra, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_sigra](https://hexdocs.pm/crosswake_sigra) |
| `crosswake_chimeway` | `:chimeway` | `unpublished` | `~> 0.2` | none (pure-Elixir notification machinery) | [hexdocs.pm/crosswake_chimeway](https://hexdocs.pm/crosswake_chimeway) |
| `crosswake_threadline` | N/A (observer — not a `:companions` registrant) | `unpublished` | `~> 0.2` | none (optional `:plug` + `:phoenix_live_view` for surface modules) | [hexdocs.pm/crosswake_threadline](https://hexdocs.pm/crosswake_threadline) |

The `Current Version` column reads "unpublished" until each package's first Hex
release; after that release lands, the human writes the confirmed number back from
the hex.pm release page (the column is never hand-edited to a guessed value, and the
live number is always whatever each package's hexdocs link reports).

## Threadline wiring

Threadline is the one companion that is **not** a `:companions` registrant — its
`Companion ID` cell reads `N/A (observer)` for that reason. Instead of registering in
`:companions` config, Threadline is wired into a host application through two Phoenix
integration points: the `Crosswake.Plug.Threadline` plug (added to the endpoint or a
router pipeline) and `on_mount: Crosswake.Live.Threadline` (added to a LiveView or
`live_session`). As a pure-OTP audit/correlation observer it has no engine dependency;
`:plug` and `:phoenix_live_view` are optional and needed only for those surface
modules.

## Independent Versioning

These are first-party companion packages, each with its own SemVer line — the version
numbers do not move in lockstep with core or with each other. The `Requires crosswake`
cell declares a **minimum**, not a ceiling, and that minimum now differs by companion.
`rulestead` and `rindle` still declare `~> 0.1`, so adding `crosswake_rindle` `0.1.0`
to a project already on `crosswake` `0.1.2` resolves cleanly without pinning core back.
The three v17.0 companions (`crosswake_sigra`, `crosswake_chimeway`,
`crosswake_threadline`) declare `~> 0.2` and will **not** resolve against a `0.1.x`
core — they require `crosswake` `0.2.0` or later.

## Reading the Requirement Syntax

Two requirement forms are live in the matrix today. `~> 0.1` (`rulestead`, `rindle`)
means `>= 0.1.0 and < 1.0.0` — it admits every `0.x` core release, including `0.1.2`,
and stops at the next major. `~> 0.2` (`sigra`, `chimeway`, `threadline`) means
`>= 0.2.0 and < 1.0.0` — it excludes the entire `0.1.x` line, so those companions
require core `0.2.0` or newer. If a companion ever needs a still tighter floor it will
name a fuller version, and the drift test will require that exact literal in this doc.

## Engine Dependencies

Each companion declares its engine as `optional: true`. An optional dependency is
**not** pulled transitively into an adopter's project — adding `crosswake_rindle`
does not install `rindle`. You add the engine yourself only when you want the
engine-present behavior; absent it, the companion fails closed and
`mix crosswake.doctor` reports `companion.dependency_missing`.

Name the friction honestly. Because `~> 0.1` admits every `0.x` (`>= 0.1.0 and
< 1.0.0`), a companion only hits the cap when its engine reaches `1.0.0`. `rulestead`
is at `1.0.0` — outside `~> 0.1` — so to run it engine-present you must pin the engine
to its `0.1.x` line rather than taking the latest release; widening past the next
major is deferred until the contract is proven against it. `rindle` is at `0.3.0`,
which is still within `~> 0.1`, so it resolves engine-present without pinning.

## Verifying Companion Health

After adding a companion package, run:

```
mix crosswake.doctor
```

The doctor closes the loop on the two ways a companion goes quietly wrong: you added
the package but never registered it in `:companions` config, or you registered it but
never added (or pinned) its engine. In the second case the doctor emits
`companion.dependency_missing` as an `:error` — the live check that this static matrix
cannot perform for you.
