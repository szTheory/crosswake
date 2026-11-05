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
     columns are Hex Package | Companion ID | Latest on Hex | Requires `crosswake` | Engine Dependency;
     do not reorder columns without updating phase132_compat_matrix_drift_test.exs -->
| Hex Package | Companion ID | Latest on Hex | Requires `crosswake` | Engine Dependency |
|---|---|---|---|---|
| `crosswake_rulestead` | `:rulestead` | [hex.pm/packages/crosswake_rulestead](https://hex.pm/packages/crosswake_rulestead) | `~> 0.2` | `{:rulestead, "~> 0.1", optional: true}` |
| `crosswake_rindle` | `:rindle` | [hex.pm/packages/crosswake_rindle](https://hex.pm/packages/crosswake_rindle) | `~> 0.2` | `{:rindle, "~> 0.1", optional: true}` |
| `crosswake_sigra` | `:sigra` | [hex.pm/packages/crosswake_sigra](https://hex.pm/packages/crosswake_sigra) | `~> 0.2` | none (pure-Elixir auth machinery) |
| `crosswake_chimeway` | `:chimeway` | [hex.pm/packages/crosswake_chimeway](https://hex.pm/packages/crosswake_chimeway) | `~> 0.2` | none (pure-Elixir notification machinery) |
| `crosswake_threadline` | N/A (observer — not a `:companions` registrant) | [hex.pm/packages/crosswake_threadline](https://hex.pm/packages/crosswake_threadline) | `~> 0.2` | none (optional `:plug` + `:phoenix_live_view` for surface modules) |

This matrix does not list package versions: a copied version goes stale the moment a
release ships. The `Latest on Hex` link is the registry's own page for each package,
which names the current release and links its documentation.

For public registry truth, run `mix crosswake.release.status --live`; that command is
allowed to report a package version as configured locally while still warning that Hex,
Maven Central, or the SwiftPM mirror has not propagated it yet.

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
cell declares a **minimum**, not a ceiling. Every current companion declares `~> 0.2`
and will **not** resolve against a `0.1.x` core. Each companion still owns that floor
independently and can raise it without moving its package version or any sibling
companion in lockstep.

## Reading the Requirement Syntax

The current requirement form is `~> 0.2`, meaning `>= 0.2.0 and < 1.0.0`. It
excludes the entire `0.1.x` line, so every current companion requires core `0.2.0`
or newer. If a companion ever needs a tighter floor it will name a fuller version,
and the drift test will require that exact literal in this doc.

## Release Integrity Boundaries

Release integrity work keeps the train honest without changing these
compatibility floors: Release Please Release PR merge is the human approval
boundary, CI owns happy-path Hex publishing, and manual dispatch is exact-ref Hex
recovery only. Clean-room exactness, SwiftPM/Maven recovery, and iOS mirror
backfill are separate release-ops evidence surfaces. `mix crosswake.release.status`
is the current text/JSON status surface for local graph truth and optional live
registry presence. This guide remains the floor contract; live registry presence is
a separate status concern and does not couple independent companion version lines.

## Engine Dependencies

`crosswake_sigra` is the exception to the engine-dependency pattern: it has no
dependency on the `sigra` Hex package. It supplies Crosswake's pure-Elixir auth
projection seam, while the host projects its verified Sigra session into that seam.
Consequently it does not constrain Sigra's package version: a host on Sigra `1.4.x`,
or on a separately sourced `1.5.0`, has no Mix-solver conflict with
`crosswake_sigra`. This is version decoupling, not a claim that the companion replaces
or directly exercises every Sigra release.

Companions that do declare an engine use `optional: true`. An optional dependency is
**not** pulled transitively into an adopter's project — adding `crosswake_rindle`
does not install `rindle`. You add the engine yourself only when you want the
engine-present behavior; absent it, the companion fails closed and
`mix crosswake.doctor` reports `companion.dependency_missing`.

Name the friction honestly. Because `~> 0.1` admits every `0.x` (`>= 0.1.0 and
< 1.0.0`), a companion only hits the cap when its engine reaches `1.0.0`. Check the
engine's latest release on hex.pm: while it is still a `0.x` release it resolves
engine-present without pinning, and once it is at `1.0.0` or later you must pin the
engine to its `0.1.x` line to run it engine-present rather than taking the latest
release. Widening past the next major is deferred until the contract is proven against
it.

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
