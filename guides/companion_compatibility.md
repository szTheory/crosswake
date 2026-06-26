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
| Hex Package | Companion ID | Current Version | Requires `crosswake` | Engine Dependency | hexdocs |
|---|---|---|---|---|---|
| `crosswake_rulestead` | `:rulestead` | `0.1.0` | `~> 0.1` | `{:rulestead, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rulestead](https://hexdocs.pm/crosswake_rulestead) |
| `crosswake_rindle` | `:rindle` | `0.1.0` | `~> 0.1` | `{:rindle, "~> 0.1", optional: true}` | [hexdocs.pm/crosswake_rindle](https://hexdocs.pm/crosswake_rindle) |

The `Current Version` column records the last published line for orientation only;
the live number is whatever each package's hexdocs link reports.

## Independent Versioning

These are first-party companion packages, each with its own SemVer line. A companion
at `0.1.0` runs against core `0.1.2` — the version numbers do not move in lockstep.
The `Requires crosswake` cell declares a **minimum**, not a ceiling: `~> 0.1` means
the companion accepts any core release in the `0.x` line, so adding `crosswake_rindle`
`0.1.0` to a project already on `crosswake` `0.1.2` resolves cleanly without pinning
core back.

## Reading the Requirement Syntax

`~> 0.1` means `>= 0.1.0 and < 1.0.0`. It admits every `0.x` core release and stops
at the next major. That is the only requirement form in the matrix today; if a
companion ever needs a tighter floor it will name a fuller version (for example
`~> 0.2`), and the drift test will require that exact literal in this doc.

## Engine Dependencies

Each companion declares its engine as `optional: true`. An optional dependency is
**not** pulled transitively into an adopter's project — adding `crosswake_rindle`
does not install `rindle`. You add the engine yourself only when you want the
engine-present behavior; absent it, the companion fails closed and
`mix crosswake.doctor` reports `companion.dependency_missing`.

Name the friction honestly: both live engines have a latest release outside the
companion's `~> 0.1` cap. `rulestead` is at `1.0.0` and `rindle` is at `0.3.0`, and
neither satisfies `~> 0.1`. To run a companion with its engine present you must pin
the engine to its `0.1.x` line rather than taking the latest release. Widening the
cap is deferred until the companion's contract is proven against the newer engine.

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
