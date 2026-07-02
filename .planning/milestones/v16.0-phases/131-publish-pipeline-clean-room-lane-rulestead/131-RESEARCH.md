# Phase 131: Publish Pipeline & Clean-Room Lane (rulestead) - Research

**Researched:** 2026-06-26
**Domain:** Hex publish pipeline, release-please manifest mode, Elixir tarball mechanics, clean-room CI
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All four decision sets locked 2026-06-25. See CONTEXT.md §Implementation Decisions for the full
text of D-01 through D-20. Summary map:

- **① release-please wiring (D-01–D-05):** Add `packages/crosswake_rulestead` as a standalone
  `packages` entry — `component: "crosswake_rulestead"`, `release-type: "elixir"`,
  `separate-pull-requests: true` — outside the `linked-versions` group. Manifest baseline
  `"packages/crosswake_rulestead": "0.1.0"`. `extra-files: ["packages/crosswake_rulestead/mix.exs"]`
  required. Tag: `crosswake_rulestead-v0.1.0`. D-04 is a planner investigation (resolved below).

- **② Publish job (D-06–D-10):** `publish-hex-rulestead` job added to the EXISTING
  `release-please.yml`. Gate on per-component output `rulestead_release_created` (NOT aggregate
  `releases_created`). Alias slash-path outputs in `release-please` job `outputs:` block (D-08).
  Job shape mirrors `hex-publish.yml` / core `publish-hex` job; working-directory:
  `packages/crosswake_rulestead`; test step = engine-ABSENT plain `mix test`.

- **③ path: → Hex dep pivot (D-11–D-14):** ENV-CONDITIONAL via `crosswake_dep/0` function in
  companion `mix.exs`, gated on `CROSSWAKE_RELEASE=1`. Publish job sets `CROSSWAKE_RELEASE=1`.
  Committed `mix.lock` keeps path dep. D-14 is a planner investigation (resolved below).

- **④ Clean-room (D-15–D-20):** `clean-room-proof-rulestead` job needs `[release-please,
  publish-hex-rulestead]`. Logic in `script/verify_companion_cleanroom.sh`. Throwaway app in
  `$RUNNER_TEMP`, minimal Phoenix host (required by `--router`). Engine-PRESENT happy path
  (not absent) for doctor exit 0. D-20 is a planner investigation (resolved below).

### Claude's Discretion

- Exact CI job/step names, env var name beyond `CROSSWAKE_RELEASE`, propagation poll constants,
  `verify_companion_cleanroom.sh` parameter signature (at minimum: package, version; likely also
  engine package/module for rindle reuse).
- Whether the inline clean-room smoke test is a single-file ExUnit module run via `mix test`,
  a `mix run` assertion script, or a tiny generated `test/`.
- Microcopy for new failure messages (lead `[crosswake]`, "name what happened, what to do next").
- The exact minimal Phoenix host shape the doctor smoke needs.

### Deferred Ideas (OUT OF SCOPE)

- rindle extraction + publish (Phase 132)
- cross-package compat matrix + `guides/companion_compatibility.md` (Phase 132)
- sigra/chimeway extraction (later milestone)
- `Crosswake.Telemetry` public API (Phase 133)
- Richer adopter-facing clean-room beyond resolvability + happy-path doctor
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EXTRACT-05 | `release-please` carries `crosswake_rulestead` as a separate `elixir` release component (independent versioning), explicitly NOT in the core lockstep `linked-versions` group. | D-01/D-02/D-03/D-04 resolved; exact config shape documented below. |
| EXTRACT-06 | A per-companion publish job (`deps.get → compile --warnings-as-errors → test → hex.publish --dry-run → hex.publish`) runs for `crosswake_rulestead`, keyed on its release-please output. | D-06/D-07/D-08/D-09 confirmed from live release-please.yml; exact step sequence verified. |
| PROOF-01 | A clean-room CI lane and `script/verify_companion_cleanroom.sh` creates a throwaway mix project OUTSIDE the monorepo, installs published `crosswake` + companion, compiles, registers, runs tests + `mix crosswake.doctor` smoke check — all green, with Hex-propagation polling. | D-15/D-16/D-17/D-18/D-19/D-20 resolved; engine constraint confirmed from mix.lock. |
| PROOF-02 | No companion package published to Hex until `hex.publish --dry-run` gate and the clean-room/in-monorepo proof lanes are green. | `needs:` dependency graph pattern confirmed from existing `clean-room-proof-ios`/`-android`; SC#4 ordering documented. |
</phase_requirements>

---

## Summary

Phase 131 promotes the `crosswake_rulestead` poncho package from Phase 130's path-dep dress
rehearsal into a live, independently-versioned Hex package. The work is four interlocking
changes: wiring release-please to recognize the companion as a separate component (EXTRACT-05),
adding a gated companion publish job to the existing pipeline (EXTRACT-06), pivoting the
companion's `{:crosswake, path: "../.."}` to an env-conditional resolver that emits a proper
Hex requirement when `CROSSWAKE_RELEASE=1` (so the tarball carries an honest dep), and adding a
post-publish clean-room proof lane (PROOF-01/PROOF-02) that resolves the freshly-published
artifact outside the monorepo and runs `mix crosswake.doctor` with the real rulestead engine
installed.

The three CONTEXT.md "PLANNER INVESTIGATION" items (D-04, D-14, D-20) are all resolved with
repo-grounded facts:
- **D-04:** use `"release-as": "0.1.0"` in the component config for the first cut, remove
  after merge — this is the only way to publish exactly `0.1.0` from a `0.1.0` manifest baseline.
- **D-14:** the dep assertion target is `hex_metadata.config` in the `--unpack` output directory
  (confirmed by live `mix hex.build --unpack`); grep `crosswake` in that file.
- **D-20:** the companion's `mix.lock` already resolves `rulestead` to `0.1.7` which satisfies
  `~> 0.1`; there is no version-cap mismatch for the `0.1.x` line. The engine module is
  `Rulestead` (top-level, confirmed from companion source). Pin `{:rulestead, "~> 0.1"}` in the
  clean-room — no constraint widening needed.

**Primary recommendation:** Implement in this order: (1) env-conditional dep resolver in
`packages/crosswake_rulestead/mix.exs`, (2) release-please config/manifest changes + output
aliases in the CI YAML, (3) `publish-hex-rulestead` job, (4) `script/verify_companion_cleanroom.sh`,
(5) `clean-room-proof-rulestead` CI job.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Companion versioning gate | CI/Release pipeline | config files | release-please determines when to cut; config declares the component |
| Publish job sequencing | CI/Release pipeline | — | GitHub Actions `needs:` graph enforces dry-run → real publish ordering |
| dep pivot (path→Hex) | Companion `mix.exs` | CI env | env-conditional resolver in source; CI sets `CROSSWAKE_RELEASE=1` |
| Tarball dep-presence assertion | `script/verify_companion_package.sh` | CI | script reads `hex_metadata.config` from unpack dir |
| Clean-room proof | `script/verify_companion_cleanroom.sh` | CI job | script body holds the logic; CI runs it post-publish |
| Engine resolution | `mix.lock` + Hex registry | `mix.exs` optional dep | lock already pins `rulestead 0.1.7`; no constraint change needed |
| Doctor smoke check | Throwaway Phoenix host in `$RUNNER_TEMP` | clean-room script | `mix crosswake.doctor --router` requires Phoenix router present |

---

## Resolved Planner Investigations

### D-04: First-Release Bootstrap — `release-as` Shape and Timing

**Finding:** A manifest baseline of `"packages/crosswake_rulestead": "0.1.0"` means release-please
treats `0.1.0` as the ALREADY-RELEASED version. The next conventional-commit-triggered release
would cut `0.1.1` (a patch bump), not `0.1.0`. [VERIFIED: release-please manifest docs + README]

**How `release-as` fixes this:** Adding `"release-as": "0.1.0"` inside the component's package
entry in `release-please-config.json` overrides conventional-commit calculation and forces the
next release PR to target exactly `0.1.0` regardless of commit types. [VERIFIED: release-please manifest docs]

**Exact config shape (goes inside the `packages/crosswake_rulestead` entry):**
```json
{
  "component": "crosswake_rulestead",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_rulestead/mix.exs"],
  "changelog-sections": [...]
}
```

**Must be removed after first cut.** The docs state explicitly: "once the release PR is merged
you should either remove this or update it to a higher version. Otherwise subsequent runs will
continue to use this version even though it was already set." A `"release-as": ""` (empty string)
can be used to explicitly revert to conventional-commit mode. [VERIFIED: release-please manifest docs]

**Decision:** Use `release-as: "0.1.0"` (0.1.0-exact is the coherent default since D-22 set
`@version 0.1.0` in the companion's `mix.exs`). Plan must include a follow-on task to REMOVE
`release-as` after the first release PR merges, or set it to `""`.

---

### D-14: `hex.build --unpack` Dep-Presence Assertion — File Location and Grep Target

**Finding from live `mix hex.build --unpack` run on the root `crosswake` package:**

The unpack directory contains `hex_metadata.config` as a direct file (not inside a subdirectory,
alongside the source files). The file is in Erlang external term format. [VERIFIED: live tool run]

```
/tmp/crosswake_root_unpack/
  hex_metadata.config      ← dependency requirements live here
  lib/
  mix.exs
  README.md
  ...
```

**`hex_metadata.config` structure for dependencies:**
```erlang
{<<"requirements">>,
 [[{<<"name">>,<<"jason">>},
   {<<"app">>,<<"jason">>},
   {<<"optional">>,false},
   ...],
  [{<<"name">>,<<"nimble_options">>},
  ...
```

**Exact grep to assert `crosswake` is in the built companion package's deps:**
```bash
grep -q "crosswake" "$UNPACK_DIR/hex_metadata.config"
```

If `crosswake` appears in `<<"requirements">>` entries, it was recorded as a Hex dep.
If it is absent, the path dep was silently dropped. [VERIFIED: live tool run]

**Behavior confirmation:** With the current path dep (`{:crosswake, path: "../.."}`), `mix hex.build`
STOPS with an error: `"Dependencies excluded from the package (only Hex packages can be
dependencies): crosswake"`. This means `hex.build --dry-run` DOES error on path deps (contrary
to what D-12 in CONTEXT.md states — see note below). [VERIFIED: live tool run]

**Important correction to D-12:** The CONTEXT.md states "hex.publish does NOT error on a path dep —
it SILENTLY drops it." The live test shows `mix hex.build` (which `hex.publish` calls internally)
DOES error when a path dep is present. This means:
1. The `verify_companion_package.sh` dress-rehearsal code path for `HAS_PATH_DEP=true` is correct —
   it skips `hex.build --unpack` precisely because it would fail.
2. After the env-conditional pivot, `CROSSWAKE_RELEASE=1 mix hex.build` succeeds and records
   the dep — but only for `rulestead ~> 0.1 (optional)`, NOT for `crosswake` (since without
   `CROSSWAKE_RELEASE=1`, the crosswake dep stays `path:`).
3. The publish job MUST set `CROSSWAKE_RELEASE=1` for the dep to appear in the tarball at all.
   Without it, the build FAILS (not silently drops).

**So Step 2 of `verify_companion_package.sh` now needs to:**
```bash
# Full mode (Phase 131+): hex.build --unpack tarball inspection
UNPACK_DIR="/tmp/${PACKAGE}_unpack"
mix hex.build --unpack -o "$UNPACK_DIR"

# Assert crosswake appears in hex_metadata.config requirements
if ! grep -q '"crosswake"' "$UNPACK_DIR/hex_metadata.config" && \
   ! grep -q '<<"crosswake">>' "$UNPACK_DIR/hex_metadata.config"; then
  echo "[crosswake] FAIL: crosswake not found in $UNPACK_DIR/hex_metadata.config — " \
       "path: dep was not pivoted to Hex dep. Set CROSSWAKE_RELEASE=1 to publish."
  exit 1
fi
echo "[crosswake] Step 2 OK: crosswake present in hex_metadata.config"
```

Note: the grep pattern needs to handle both the Erlang binary term format
`<<"crosswake">>` and any human-readable form — grepping for `crosswake` (bare) handles both.
[VERIFIED: live tool run showing `<<"name">>,<<"jason">>` format]

---

### D-20: Engine Identity + Version-Cap — No Mismatch for 0.1.x Line

**Finding 1 — Existing mix.lock already resolves to `rulestead 0.1.7`:**
The `packages/crosswake_rulestead/mix.lock` already contains:
```
"rulestead": {:hex, :rulestead, "0.1.7", ...}
```
The constraint `{:rulestead, "~> 0.1", optional: true}` in `mix.exs` resolves to `0.1.7`
today. `~> 0.1` in Elixir means `>= 0.1.0 and < 1.0.0`, which includes `0.1.7` but excludes
`1.0.0`. [VERIFIED: live Elixir version check + live mix.lock read]

**Finding 2 — Hex registry confirms 0.1.7 is the latest 0.1.x version:**
```
Hex API: rulestead latest = 1.0.0
0.1.x versions available: [0.1.7, 0.1.6, 0.1.5, 0.1.4, 0.1.3, 0.1.2, 0.1.1]
```
There is a `1.0.0` on Hex but it does NOT satisfy `~> 0.1`. The constraint as written in
`mix.exs` is correct for the 0.1.x line. [VERIFIED: Hex API]

**Finding 3 — No constraint widening needed.** The clean-room dep is `{:rulestead, "~> 0.1"}`
(no exact pin needed beyond the `~> 0.1` semver range, since `deps.get` will resolve to `0.1.7`).
The CONTEXT.md's "e.g. `~> 0.1.6`" is an acceptable alternative pin but not required — `"~> 0.1"`
already works. [VERIFIED: mix.lock + Hex API]

**Finding 4 — Engine top-level module is `Rulestead`.** The companion's `validate_dependency/0`
checks `Code.ensure_loaded?(Rulestead)`. The Hex API confirms the app name is `:rulestead`
(atom) and by Elixir convention the top-level module for app `:rulestead` is `Rulestead`.
The companion source at
`packages/crosswake_rulestead/lib/crosswake/companions/rulestead.ex` line 127 confirms:
`if Code.ensure_loaded?(Rulestead) do` — this is the exact probe used. [VERIFIED: live source read]

**Concrete clean-room engine dep:**
```elixir
{:rulestead, "~> 0.1"}
```
This resolves to `0.1.7` today (no fallback needed — no version-cap mismatch exists).

**D-20 fallback is not required.** The happy-path (engine-present, doctor exit 0) is fully
achievable with `{:rulestead, "~> 0.1"}`. The fallback (prove both absent and present states)
only applies "if the engine cannot be cleanly resolved/installed" — it can be.

---

## CI Pipeline: Exact Step Sequences from Live Files

### `release-please` Job — `outputs:` Block to Extend

Current `outputs:` block (lines 38–42 of `release-please.yml`):
```yaml
outputs:
  releases_created: ${{ steps.release.outputs.releases_created }}
  tag_name: ${{ steps.release.outputs.tag_name }}
  version: ${{ steps.release.outputs.version }}
```

**D-08 aliases to ADD for the companion:**
```yaml
  # Companion: crosswake_rulestead
  # release-please-action v4 path outputs use <path>--<name> with double-dash.
  # GitHub Actions if: cannot index slash-containing keys directly; alias here.
  rulestead_release_created: ${{ steps.release.outputs['packages/crosswake_rulestead--release_created'] }}
  rulestead_tag_name: ${{ steps.release.outputs['packages/crosswake_rulestead--tag_name'] }}
  rulestead_version: ${{ steps.release.outputs['packages/crosswake_rulestead--version'] }}
```
[VERIFIED: release-please-action README — path outputs use `<path>--<name>` format, slash
paths accessed via bracket notation `steps.release.outputs['packages/my-module--release_created']`]

### `publish-hex` Core Job — Template to Mirror (lines 58–129 of `release-please.yml`)

Step sequence from the existing `publish-hex` job (the companion job mirrors this):
1. `actions/checkout` at `ref: tag_name`
2. `erlef/setup-beam` with `.tool-versions`
3. `actions/cache` for `deps` + `_build`
4. `mix local.hex --force && mix local.rebar --force`
5. `mix deps.get`
6. `mix compile --warnings-as-errors`
7. Verify `@version "$VERSION"` grep in `mix.exs`
8. `mix test --exclude requires_example_host` (core excludes host tests)
9. `mix hex.publish --dry-run --yes`
10. `mix hex.publish --yes`
11. Poll `hex.pm/api/packages/crosswake/releases/$VERSION` — MAX_ATTEMPTS=36, DELAY=10s

**Companion job differences:**
- `ref:` = `${{ needs.release-please.outputs.rulestead_tag_name }}`
- `working-directory: packages/crosswake_rulestead` for all mix steps
- `VERSION` = `${{ needs.release-please.outputs.rulestead_version }}`
- Version-grep target: `packages/crosswake_rulestead/mix.exs`
- Test step: `mix test` (NO `--exclude requires_example_host` — that is a core-only tag)
- Poll URL: `hex.pm/api/packages/crosswake_rulestead/releases/$VERSION`
- Env: `CROSSWAKE_RELEASE: "1"` on all mix steps (so env-conditional resolver activates)
- `if:` condition: `needs.release-please.outputs.rulestead_release_created == 'true'`

[VERIFIED: live `release-please.yml` read]

### `hex-publish.yml` — Manual Recovery Template

Step sequence (lines 28–77 of `hex-publish.yml`), confirms the core publish job pattern:
checkout → setup-beam → cache deps+_build → install hex+rebar → verify @version grep →
deps.get → compile --warnings-as-errors → test --exclude requires_example_host →
dry-run → publish. [VERIFIED: live `hex-publish.yml` read]

### `phase130-proof.yml` — PRE-Publish Gate (Merge-Blocking)

`companion-engine-absent-proof` job (lines 82–121):
- `working-directory: packages/crosswake_rulestead` for deps.get + compile + test
- `mix companions.test` (root alias) for the hermetic test run
- `bash script/verify_companion_package.sh crosswake_rulestead`

These two jobs (`core-hermetic-proof` + `companion-engine-absent-proof`) are the
merge-blocking PRE-publish gate. They run on every PR/push-to-main. Phase 131 does NOT
modify these jobs — they continue as-is. [VERIFIED: live `phase130-proof.yml` read]

### `clean-room-proof-ios`/`-android` Jobs — Pattern to Mirror (lines 200–311)

The companion's `clean-room-proof-rulestead` follows the same `needs: [release-please, publish-hex-rulestead]`
pattern. The Android clean-room uses MAX_ATTEMPTS=40, DELAY=45s (30 min timeout). The
companion poll should use MAX_ATTEMPTS=36, DELAY=10s (matching the core `publish-hex`
propagation poll — 6 minutes), which is sufficient for Hex.pm (much faster than Maven Central).
[VERIFIED: live `release-please.yml` read]

---

## `script/verify_companion_package.sh` — Step 2 Activation

**Current state (Phase 130):** Step 2 is gated via `HAS_PATH_DEP` check. With a path dep,
it skips `hex.build --unpack` and only inspects `mix.exs` directly.

**Phase 131 activation:** After the env-conditional dep pivot, `HAS_PATH_DEP=false` because
`mix.exs` no longer contains a bare `path:` in the `deps/0` function body. The script
`grep -q 'path:' mix.exs` check then returns false, enabling the full unpack path.

However: the script must be run with `CROSSWAKE_RELEASE=1` to get a valid tarball.
Without it, `mix hex.build` will fail (path dep error on the `crosswake` dep since
the `crosswake_dep/0` function will return path:). The script or CI step must set this env var.

**Updated Step 2 logic for verify_companion_package.sh:**
```bash
# Step 2: hex.build --unpack + dep-presence grep (D-14, D-12)
echo "[crosswake] Step 2: hex.build --unpack -> $UNPACK_DIR"
rm -rf "$UNPACK_DIR"
CROSSWAKE_RELEASE=1 mix hex.build --unpack -o "$UNPACK_DIR"

if [ ! -f "$UNPACK_DIR/hex_metadata.config" ]; then
  echo "[crosswake] FAIL: hex_metadata.config not found in $UNPACK_DIR"
  exit 1
fi

if ! grep -q "crosswake" "$UNPACK_DIR/hex_metadata.config"; then
  echo "[crosswake] FAIL: crosswake not found in $UNPACK_DIR/hex_metadata.config — " \
       "CROSSWAKE_RELEASE=1 must be set when publishing. path: dep was silently excluded."
  exit 1
fi
echo "[crosswake] Step 2 OK: crosswake present in hex_metadata.config"
```

Note: the existing dry-run call (`mix hex.publish --dry-run`) in the current Step 2 should be
REMOVED from `verify_companion_package.sh` since it requires `HEX_API_KEY` to be set (it
contacts Hex.pm to validate). The dep-presence grep in `hex_metadata.config` is the correct
assertion for this script. The actual `--dry-run` gate belongs in the CI publish job.

[VERIFIED: live script read + live `mix hex.build --unpack` run]

---

## `packages/crosswake_rulestead/mix.exs` — Env-Conditional Dep Pivot

**Current state (from live read):**
```elixir
defp deps do
  [
    {:crosswake, path: "../.."},
    {:rulestead, "~> 0.1", optional: true}
  ]
end
```

**Phase 131 change:** Add `crosswake_dep/0` private function and call it in `deps/0`:
```elixir
defp deps do
  [
    crosswake_dep(),
    {:rulestead, "~> 0.1", optional: true}
  ]
end

defp crosswake_dep do
  # Local dev + in-tree CI: test against LOCAL core (high fidelity, D-11).
  # Publish job sets CROSSWAKE_RELEASE=1 → records an honest Hex requirement.
  # (hex.publish errors if a path: dep is present — this resolver prevents the error.)
  if System.get_env("CROSSWAKE_RELEASE") == "1",
    do: {:crosswake, "~> 0.1"},
    else: {:crosswake, path: "../.."}
end
```

**After this change:** `grep -q 'path:' mix.exs` in `verify_companion_package.sh` returns
TRUE (the string `path:` still appears inside `crosswake_dep/0`). The `HAS_PATH_DEP` check
needs to be made smarter — look for `path:` in the `deps/0` function body specifically, or
check the `deps` function for a bare non-functional `path:` tuple. The simpler fix is to
change the gating logic: run `mix hex.build --unpack` regardless and let it fail if path: is
still active, OR check the `CROSSWAKE_RELEASE` env var explicitly. The cleanest approach:
run the full Step 2 path unconditionally (remove the `HAS_PATH_DEP` gate), always set
`CROSSWAKE_RELEASE=1` for the verify call, and let `hex.build` report if anything is wrong.

[VERIFIED: live `packages/crosswake_rulestead/mix.exs` read]

---

## `release-please-config.json` — Exact Changes

**Current state (from live read):** Three packages (`"."`, `"packages/crosswake-shell-core-ios"`,
`"packages/crosswake-shell-core-android"`). `linked-versions` plugin components:
`["hex", "ios-core", "android-core"]`. No `crosswake_rulestead` entry.

**Phase 131 addition:**
```json
"packages/crosswake_rulestead": {
  "component": "crosswake_rulestead",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_rulestead/mix.exs"],
  "changelog-sections": [
    { "type": "feat",     "section": "Features" },
    { "type": "fix",      "section": "Bug Fixes" },
    { "type": "perf",     "section": "Performance Improvements" },
    { "type": "deps",     "section": "Dependencies" },
    { "type": "chore",    "section": "Miscellaneous",         "hidden": true },
    { "type": "docs",     "section": "Documentation",         "hidden": true },
    { "type": "test",     "section": "Tests",                 "hidden": true },
    { "type": "ci",       "section": "Continuous Integration","hidden": true },
    { "type": "refactor", "section": "Refactoring",           "hidden": true },
    { "type": "build",    "section": "Build System",          "hidden": true }
  ]
}
```

`"crosswake_rulestead"` must NOT appear in the `linked-versions` plugin's `components` array.
[VERIFIED: live `release-please-config.json` read]

---

## `.release-please-manifest.json` — Exact Change

**Current state:** `{"." : "0.1.2", "packages/crosswake-shell-core-ios": "0.1.2", "packages/crosswake-shell-core-android": "0.1.2"}`

**Phase 131 addition:**
```json
"packages/crosswake_rulestead": "0.1.0"
```

Combined result:
```json
{
  ".": "0.1.2",
  "packages/crosswake-shell-core-ios": "0.1.2",
  "packages/crosswake-shell-core-android": "0.1.2",
  "packages/crosswake_rulestead": "0.1.0"
}
```

The `release-as: "0.1.0"` in config overrides the baseline for the first cut to produce
exactly `crosswake_rulestead-v0.1.0`. [VERIFIED: live `.release-please-manifest.json` read]

---

## `script/verify_companion_cleanroom.sh` — Body Design

**Template:** `verify_companion_package.sh` and `verify_hex_tarball.sh` house style:
`set -euo pipefail`, `[crosswake]`-prefixed failures, parameterized by `$1`/`$2`.

**Signature (minimum):**
```bash
# Usage: ./script/verify_companion_cleanroom.sh PACKAGE VERSION [ENGINE_PACKAGE ENGINE_MODULE]
# Defaults: PACKAGE=crosswake_rulestead VERSION=required ENGINE_PACKAGE=rulestead ENGINE_MODULE=Rulestead
PACKAGE="${1:-crosswake_rulestead}"
VERSION="${2:?[crosswake] FAIL: VERSION required as \$2}"
ENGINE_PACKAGE="${3:-rulestead}"
ENGINE_MODULE="${4:-Rulestead}"
```

**Body steps:**

**Step 1: Poll Hex propagation**
```bash
MAX_ATTEMPTS=36
DELAY=10
for i in $(seq 1 "$MAX_ATTEMPTS"); do
  if curl -fsS "https://hex.pm/api/packages/${PACKAGE}/releases/${VERSION}" | grep -q '"version"'; then
    echo "[crosswake] Hex.pm lists ${PACKAGE} ${VERSION}"
    break
  fi
  echo "[crosswake] waiting for Hex propagation... ($i/$MAX_ATTEMPTS)"
  sleep "$DELAY"
done
```
(Mirror of core `publish-hex` job's propagation poll — MAX_ATTEMPTS=36, DELAY=10.)

**Step 2: Create throwaway Phoenix host in `$RUNNER_TEMP`**
```bash
CLEAN_ROOM_DIR="${RUNNER_TEMP:-/tmp}/clean-room-${PACKAGE}"
rm -rf "$CLEAN_ROOM_DIR"
mkdir -p "$CLEAN_ROOM_DIR"
cd "$CLEAN_ROOM_DIR"
mix new clean_room_host --sup

# Add Phoenix deps + companion deps to mix.exs
# (script patches the mix.exs in place)
```

The throwaway app must declare:
```elixir
{:phoenix, "~> 1.8"},
{:phoenix_live_view, "~> 1.2"},
{:crosswake, "~> 0.1"},
{:"#{PACKAGE}", "~> 0.1"},
{:"#{ENGINE_PACKAGE}", "~> 0.1"}
```

**Step 3: deps.get + compile**
```bash
mix deps.get
mix compile --warnings-as-errors
```

**Step 4: Inline smoke test**
Create a minimal `test/smoke_test.exs` in the throwaway project:
```elixir
defmodule CleanRoom.SmokeTest do
  use ExUnit.Case
  alias Crosswake.Companions.Rulestead

  test "validate_dependency/0 returns :ok (engine present)" do
    assert Rulestead.validate_dependency() == :ok
  end

  test "companion_id/0 returns :rulestead" do
    assert Rulestead.companion_id() == :rulestead
  end

  test "enabled?/1 respects config" do
    refute Rulestead.enabled?(%{})
    assert Rulestead.enabled?(%{enabled: true})
  end
end
```
Run: `mix test test/smoke_test.exs`

Note: `MockFlagSource` is not in the Hex tarball (`test/` excluded per D-24). The smoke test
uses only public callbacks. [VERIFIED: live `packages/crosswake_rulestead/mix.exs` read]

**Step 5: config + doctor**
```bash
# Inject companion registration into config/runtime.exs
cat >> config/runtime.exs <<'EOF'
import Config
config :crosswake, :companions, [Crosswake.Companions.Rulestead]
config :crosswake, :rulestead, enabled: true
EOF

# Run doctor with a minimal router stub
# The throwaway app needs a router module for --router flag
mix crosswake.doctor --router CleanRoomHost.Router
```

The `mix crosswake.doctor --router` flag requires that the named module defines Phoenix routes
(or at least is loaded). The minimal router:
```elixir
defmodule CleanRoomHost.Router do
  use Phoenix.Router
  # minimal router — no routes required for doctor smoke
end
```

[VERIFIED: live `lib/mix/tasks/crosswake.doctor.ex` read — `router_module!(opts[:router])` parses
the `--router` arg; exits non-zero via `Mix.raise` if report.status == :error]

---

## Common Pitfalls

### Pitfall 1: Aggregate Output Gate (`releases_created` vs per-component)
**What goes wrong:** Gating `publish-hex-rulestead` on `needs.release-please.outputs.releases_created == 'true'`
publishes on every core-only release.
**Why it happens:** `releases_created` is the aggregate — true if ANY package released. Documented
in the existing workflow comment (lines 33–38).
**How to avoid:** Use `rulestead_release_created == 'true'` exclusively.
**Warning signs:** The companion job fires when only core commits land.

### Pitfall 2: Unaliased Slash-Path Output
**What goes wrong:** `${{ needs.release-please.outputs['packages/crosswake_rulestead--release_created'] }}`
in a downstream job `if:` silently evaluates to empty string (not `'true'`) — job is skipped.
**Why it happens:** GitHub Actions `if:` cannot index object keys with slashes directly; bracket
notation only works within the SAME job's `steps.*.outputs`.
**How to avoid:** Alias in the `release-please` job's `outputs:` block as `rulestead_release_created`.
Then downstream uses `needs.release-please.outputs.rulestead_release_created == 'true'`.

### Pitfall 3: Missing `CROSSWAKE_RELEASE=1` in Publish Job
**What goes wrong:** `mix hex.build` (called internally by `mix hex.publish`) fails with
"Dependencies excluded from the package: crosswake" — publish aborts.
**Why it happens:** The env-conditional resolver returns `{:crosswake, path: "../.."}` when
`CROSSWAKE_RELEASE` is unset.
**How to avoid:** Set `CROSSWAKE_RELEASE: "1"` in the publish job's `env:` block, covering all
mix steps (deps.get through hex.publish).

### Pitfall 4: `HAS_PATH_DEP` Check in verify script breaks after pivot
**What goes wrong:** `verify_companion_package.sh` grep `'path:'` in `mix.exs` still matches
the string inside `crosswake_dep/0` body, so `HAS_PATH_DEP=true` and Step 2 is skipped even
after the pivot.
**How to avoid:** Update the gate condition. The simplest fix: always run Step 2 with
`CROSSWAKE_RELEASE=1` and remove the `HAS_PATH_DEP` conditional, letting `hex.build` report
naturally.

### Pitfall 5: Doctor Fails in Clean-Room (Engine Absent)
**What goes wrong:** `mix crosswake.doctor` exits non-zero → clean-room lane RED.
**Why it happens:** If `{:rulestead, "~> 0.1"}` is not in the throwaway project's deps,
`Code.ensure_loaded?(Rulestead)` returns false → `validate_dependency/0` returns `{:error, [Rulestead]}`
→ doctor emits `companion.dependency_missing` `:error` finding → `Mix.raise` → exit non-zero.
**How to avoid:** Include `{:rulestead, "~> 0.1"}` in the throwaway project's deps explicitly.
Do not rely on transitive deps — the companion declares it `optional: true`.

### Pitfall 6: `release-as` Left in Config After First Cut
**What goes wrong:** Subsequent release-please runs still target `0.1.0` — can't cut `0.1.1`.
**How to avoid:** Plan must include a task to remove `"release-as": "0.1.0"` (or set to `""`)
from the component config immediately after the first `crosswake_rulestead-v0.1.0` release PR merges.

### Pitfall 7: `mix crosswake.doctor` without `--router`
**What goes wrong:** Doctor fails with "missing required option --router" or silently skips
route-policy checks.
**How to avoid:** The throwaway app MUST include a minimal `use Phoenix.Router` module and pass
its full module name as `--router FullModuleName`.

---

## Validation Architecture (Nyquist)

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `packages/crosswake_rulestead/test/test_helper.exs` |
| Quick run | `mix companions.test` (root alias) |
| Full suite | `mix test --exclude requires_example_host --exclude advisory_only` |
| Companion package | `cd packages/crosswake_rulestead && mix test` |

### Phase Requirements → Validation Map

| Req ID | Success Criterion | Validation Type | Testable In-Tree? | Automated Command |
|--------|------------------|-----------------|-------------------|-------------------|
| EXTRACT-05 | `release-please-config.json` has `crosswake_rulestead` entry outside `linked-versions` | Static assertion | YES — grep/JSON parse | `grep crosswake_rulestead release-please-config.json` + confirm not in linked-versions array |
| EXTRACT-05 | `.release-please-manifest.json` has `"packages/crosswake_rulestead": "0.1.0"` | Static assertion | YES | `python3 -c "import json; d=json.load(open('.release-please-manifest.json')); assert 'packages/crosswake_rulestead' in d"` |
| EXTRACT-06 | Publish job exists in release-please.yml, gated on per-component output | Static assertion | YES — CI YAML check | `grep rulestead_release_created .github/workflows/release-please.yml` |
| EXTRACT-06 | Publish job runs `deps.get → compile --warnings-as-errors → test → dry-run → publish` | Dry-run test | YES — `--dry-run` only | `mix hex.publish --dry-run --yes` in `packages/crosswake_rulestead` with `CROSSWAKE_RELEASE=1` |
| EXTRACT-06 | `hex_metadata.config` contains `crosswake` dep after env-conditional pivot | Script assertion | YES | `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead` |
| PROOF-01 | Clean-room script exits 0 + doctor exits 0 | Post-publish CI | NO (requires live Hex publish) — IRREVERSIBLE | `bash script/verify_companion_cleanroom.sh crosswake_rulestead 0.1.0` (post-publish only) |
| PROOF-02 | No `hex.publish` until both dry-run gate and clean-room are green | CI job ordering (`needs:` graph) | YES — inspect YAML `needs:` | Review `release-please.yml` `needs:` declarations |
| PROOF-02 | `crosswake_rulestead` live and resolvable on Hex | Post-publish | NO — IRREVERSIBLE | Hex API: `curl -f https://hex.pm/api/packages/crosswake_rulestead/releases/0.1.0` |

### Irreversible Steps (Cannot Be Dry-Run Validated)

1. **`mix hex.publish` (real publish)** — the tarball is immutable once published; recovery
   is `mix hex.retire crosswake_rulestead 0.1.0`. The `--dry-run` gate is the in-tree proof.
2. **Post-publish Hex resolvability** — only verifiable after real publish; the clean-room
   CI lane provides this proof automatically after the publish job completes.
3. **The release-please Release PR merge** — generates the tag + version; cannot be replicated
   in dry-run. The `lockstep-truth` job pattern (existing `workflow_dispatch` job in
   `release-please.yml`) can verify version coordinate consistency before merging the Release PR.

### Sampling Rate

- **Per task commit:** `mix companions.test` (companion engine-absent tests, < 30s)
- **Per wave merge:** `mix test --exclude requires_example_host --exclude advisory_only` + `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead`
- **Phase gate / pre-publish:** `mix hex.publish --dry-run --yes` in `packages/crosswake_rulestead` with `CROSSWAKE_RELEASE=1`

### Wave 0 Gaps

- [ ] `script/verify_companion_cleanroom.sh` — new file, no pre-existing test
- [ ] `test/smoke_test.exs` in throwaway project — generated by the cleanroom script itself
- [ ] No new test files required in the companion package test suite for this phase

*(Existing `phase130-proof.yml` merge-blocking lanes are sufficient PRE-publish proof.
The clean-room script is the only new test artifact.)*

---

## Security Domain

The companion publish pipeline handles `HEX_API_KEY`. No new auth surface beyond what
`publish-hex` (core) already uses.

| ASVS Category | Applies | Control |
|---------------|---------|---------|
| V2 Authentication | no | HEX_API_KEY is an existing Actions secret — no new secret |
| V5 Input Validation | yes — script params | `bash set -euo pipefail` + explicit param validation in cleanroom script |
| V6 Cryptography | no | Hex.pm manages package signing; no app-level crypto |

**No new ASVS categories introduced.** The only new secret surface is `HEX_API_KEY` reuse
(already present in the repo). The cleanroom script should validate its `$VERSION` argument
looks like a semver string before using it in `curl` URL construction (prevents injection).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` / Elixir | All compile/test steps | Yes | Mix 1.19.5, OTP 28 | — |
| `curl` | Hex propagation poll | Yes (standard) | — | — |
| `python3` | JSON manipulation in lock-step assertions | Yes | — | `jq` |
| `HEX_API_KEY` | Real publish | CI secret (not verified locally) | — | Dry-run only |
| Hex.pm `crosswake_rulestead` | clean-room proof | Not yet (phase goal) | — | Phase creates it |
| `rulestead 0.1.7` on Hex | clean-room engine dep | Yes | 0.1.7 | 0.1.6 as fallback |

**Missing dependencies with no fallback:** None beyond the `crosswake_rulestead` publish itself.

---

## `script/extract_companion.md` — Update Required (D-05)

**Step 12 (current):** "Do NOT touch release-please config/manifest."

**Phase 131 update:** Rename Step 12 from "DON'T touch release-please" to
"Register the release-please component (Phase 131+ only)" and describe the exact recipe:
1. Add component entry to `release-please-config.json` with `release-as: "0.1.0"` for first cut.
2. Add `"packages/crosswake_{companion}": "0.1.0"` to `.release-please-manifest.json`.
3. Add output aliases to the `release-please` job `outputs:` block.
4. Add `publish-hex-{companion}` job to `release-please.yml`.
5. Add `clean-room-proof-{companion}` job.
6. Remove `release-as` after first Release PR merges.

Also add a **"Phase 131 lock pivot"** note to Step 4 (companion mix.exs): replace the comment
`# Phase 131: Hex dep pivot (AFTER publish)` with the actual `crosswake_dep/0` function pattern.

---

## Open Questions

1. **Minimal Phoenix host shape for clean-room doctor**
   - What we know: `mix crosswake.doctor --router <Module>` requires the module to be loaded
     and Phoenix router-like. The throwaway `mix new clean_room_host --sup` + a minimal
     `use Phoenix.Router` module satisfies this.
   - What's unclear: Does `Crosswake.Doctor.router_module!/1` call `Module.Info` or route
     introspection, or just check `Code.ensure_loaded?`? If deeper, the router stub needs routes.
   - Recommendation: Start with a minimal `use Phoenix.Router` stub; add a `scope "/"` block
     if the doctor task fails with a router-inspection error.

2. **`verify_companion_package.sh` HAS_PATH_DEP gate update**
   - What we know: After the env-conditional pivot, `path:` string still appears in `mix.exs`
     inside the `crosswake_dep/0` body.
   - What's unclear: Whether to update the grep to check only the `deps/0` function block, or
     to remove the gate entirely.
   - Recommendation: Remove the `HAS_PATH_DEP` conditional entirely and always run Step 2 with
     `CROSSWAKE_RELEASE=1`. This is simpler and more robust for rindle reuse.

---

## Sources

### Primary (HIGH confidence)
- Live repo read: `.github/workflows/release-please.yml` — exact `outputs:` block, `publish-hex` job steps, `clean-room-proof-*` job patterns, propagation poll constants (MAX_ATTEMPTS=36, DELAY=10)
- Live repo read: `.github/workflows/hex-publish.yml` — step sequence template for companion publish job
- Live repo read: `.github/workflows/phase130-proof.yml` — PRE-publish gate jobs, `companion-engine-absent-proof` test step template
- Live repo read: `script/verify_companion_package.sh` — house style, unpack path, Step 2 activation trigger
- Live repo read: `packages/crosswake_rulestead/mix.exs` — current dep shape, `files:` allowlist, `@version` marker
- Live repo read: `packages/crosswake_rulestead/mix.lock` — confirms `rulestead 0.1.7` already resolved
- Live repo read: `release-please-config.json` — current packages structure, linked-versions plugin
- Live repo read: `.release-please-manifest.json` — current baseline versions
- Live tool run: `mix hex.build --unpack` on root `crosswake` package — confirmed `hex_metadata.config` location, Erlang term format, `<<"requirements">>` structure
- Live tool run: `mix hex.build` on `crosswake_rulestead` with `CROSSWAKE_RELEASE=1` — confirmed path dep causes failure, Hex dep pivot behavior
- Live Elixir version check: confirmed `~> 0.1` = `>= 0.1.0 and < 1.0.0`, `0.1.7` satisfies, `1.0.0` does not
- Live Hex API: confirmed rulestead `latest=1.0.0`, `0.1.x` versions available up to `0.1.7`

### Secondary (MEDIUM confidence)
- release-please-action README (official): confirmed `<path>--<name>` output format, bracket-notation access, `release-as` behavior and post-merge removal requirement

### Tertiary (LOW confidence — ASSUMED)
- Clean-room smoke test ExUnit shape and doctor router stub shape: based on reading of source files and Elixir idiom; exact behavior of `router_module!/1` not traced to terminal

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `mix crosswake.doctor --router CleanRoomHost.Router` works with a minimal `use Phoenix.Router` module with no routes | Clean-room body design | Doctor fails in clean-room; fix by adding a `scope "/"` block or tracing `router_module!/1` |
| A2 | `"rulestead ~> 0.1"` in the throwaway project resolves to `0.1.7` (not `1.0.0`) without an explicit pin | D-20 | `deps.get` picks up `1.0.0` if Hex starts advertising it in the `~> 0.1` range — impossible by definition since `~> 0.1` excludes `1.x`, so risk is zero |
| A3 | `mix hex.publish --dry-run` in the CI publish job does NOT require `HEX_API_KEY` to be set | Pitfall 3 note | Dry-run contacts Hex API for package existence check; if it requires auth, the dry-run step needs `HEX_API_KEY: ${{ secrets.HEX_API_KEY }}` in its env (as the existing `publish-hex` job already does) |

**Note on A3:** The existing `publish-hex` job (line 107) sets `HEX_API_KEY` on the `--dry-run`
step — so it likely does require auth. The companion job should match this pattern.

---

## Metadata

**Confidence breakdown:**
- Release-please config shape: HIGH — verified from live config files + official docs
- CI job structure: HIGH — mirrored from existing live jobs
- D-04 (`release-as` bootstrap): HIGH — verified from release-please official docs
- D-14 (`hex_metadata.config` location + format): HIGH — verified by live `mix hex.build --unpack`
- D-20 (engine version + module): HIGH — verified from mix.lock + Hex API + source read
- Clean-room script body: MEDIUM — shape confirmed from existing verify scripts + source reads; `--router` exact behavior has one [ASSUMED] item

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 (release-please-action and Hex package format are stable; rulestead 0.1.7 pinned in lock)
