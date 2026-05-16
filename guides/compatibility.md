# Crosswake Compatibility Boundaries

Crosswake Phase 3 keeps the same route-first compatibility rule from Phase 2 and
extends it into real shell activation, route unavailable surfaces, and bounded bridge
execution. Runtime ownership stays explicit per route: LiveView stays server-owned,
offline islands stay local-first by contract, and native screens stay native-owned.

## Compatibility Axes

Crosswake evaluates compatibility through separate contract axes:

- `manifest_schema_version`
- `bridge_protocol_version`
- `native_runtime_version`

The shell may parse a manifest and still refuse activation or bridge execution if a
route requires a newer shell runtime, a newer bridge major, a missing declared pack,
or an unavailable capability version. Crosswake does not silently downgrade those
cases into generic WebView behavior.

## Manifest Sources

Crosswake recognizes `bundled`, `cached`, and `remote` manifest sources.

- `bundled` is guaranteed boot truth shipped in the binary.
- `cached` is previously trusted manifest truth retained by the app.
- `remote` may refine behavior only inside the shipped native runtime and versioned
  compatibility contract.

Remote updates stay constrained to versioned replacement or explicitly versioned
companion data. Overlay-style rule patches, path-order rewrites, and unversioned
config fragments are outside the contract because they can silently change route
meaning.

## Failure Posture

Crosswake activation is fail-closed.

- Route activation runs manifest-first and native-first before any web container loads.
- Unsupported or unsafe routes land on a Crosswake-owned `route unavailable` surface.
- Bridge execution is request/reply-only and denies side effects on
  `compatibility_mismatch`, `origin_denied`, `inactive_route`,
  `undeclared_capability`, `unavailable_capability`, and `pack_incompatible`.

## Proof Boundary

Shell support claims are blocked until both generated-project proof hooks pass on the
same host-owned artifacts adopters ship:

- `script/verify_generated_ios_shell.sh`
- `script/verify_generated_android_shell.sh`

Run `mix crosswake.doctor` for manifest and shell posture, then run
`mix crosswake.doctor --native-checks` to execute the proof hooks and move support
from `verification required` to `supported`.

## Rough Edges

- Crosswake shell support remains narrow and mechanically checkable.
- Native-screen breadth, offline journals, reconciliation, and pack-management UI are
  still later-phase work.
- The bounded bridge stays limited to `app.info.get`, `haptics.impact`, and
  `files.pick`.

## Non-Goals

- Generic WebView-wrapper positioning
- High-frequency bridge-driven state loops
- Broad support claims beyond the current proof-oriented matrix

Read [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md) for
the shell contract, [guides/bridge.md](/Users/jon/projects/crosswake/guides/bridge.md)
for bridge behavior, and `mix crosswake.doctor` for the current support posture.
