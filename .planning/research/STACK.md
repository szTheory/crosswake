# Canonical Runtime-Contract Version Source — Mechanism Research

**Project:** Crosswake v14.0 Runtime Contract Confidence
**Researched:** 2026-06-20
**Mode:** Feasibility + Comparison — "Which mechanism makes one version drive everything?"

---

## The Concrete Problem

Three Elixir files, two native packages, JSON fixtures, and docs all independently author the same three version strings. They have already drifted:

| Surface | File | Versions Stored |
|---------|------|-----------------|
| Elixir bridge module | `lib/crosswake/bridge/contract.ex:10` | `@version "1.1.0"` |
| Elixir manifest/types | `lib/crosswake/manifest/types.ex:651-653` | `@manifest_schema_version "1.0.0"`, `@bridge_protocol_version "1.0.0"`, `@native_runtime_version "1.0.0"` |
| Elixir shell fixtures | `lib/crosswake/shell/fixtures.ex:82-83` | `bridge_protocol_version: "1.0.0"`, `native_runtime_version: "1.0.0"` |
| iOS fixture JSON | `examples/ios_shell_host/Fixtures/route_activation.json` | `"bridge_protocol_version": "1.0.0"` |
| Android fixture JSON | `examples/android_shell_host/app/src/main/assets/route_activation.json` | `"bridge_protocol_version": "1.0.0"` |
| iOS Swift package | `packages/crosswake-shell-core-ios/` | Reads protocol version from bundled JSON at runtime |
| Android Kotlin package | `packages/crosswake-shell-core-android/ActivationCoordinator.kt:594` | Fallback: `?: "1.0.0"` |
| Docs | `guides/compatibility.md`, `guides/bridge.md` | No literal version constants; references axis names only |
| Tests | `test/mix/tasks/crosswake_doctor_test.exs:108-110` | Hardcoded `"1.0.0"` literals x9 |

The `ActivationCoordinator` on both iOS and Android performs exact-version equality on `bridge_protocol_version` and `native_runtime_version` against the bundled `crosswake_manifest.json`. Because `Crosswake.Bridge.Contract` says `1.1.0` while everything else says `1.0.0`, any otherwise-valid bridge request from a `1.1.0`-generated manifest is denied by a shell that has only seen `1.0.0`.

The fix requires one canonical source and a drift guard. The question is which mechanism best fits an Elixir-first library that lockstep-publishes iOS/Android native packages.

---

## Mechanism Options Compared

Four mechanisms are evaluated. Each section gives: what it is, pros, cons, tradeoffs, and a concrete worked example in Crosswake's specific file layout.

---

### Mechanism 1 — Single Elixir Module Attribute (Collapse the Three Elixir Sources)

**What it is:** Delete `@bridge_protocol_version "1.0.0"` from `manifest/types.ex` and the hardcoded strings from `shell/fixtures.ex`, replace them with calls to `Crosswake.Bridge.Contract.version()`, `Crosswake.Manifest.Types.bridge_protocol_version()` etc., all of which ultimately trace back to one module attribute in `bridge/contract.ex`.

**Worked example:**

```elixir
# lib/crosswake/bridge/contract.ex — THE one source
@bridge_protocol_version "1.0.0"
@manifest_schema_version "1.0.0"
@native_runtime_version "1.0.0"

def bridge_protocol_version, do: @bridge_protocol_version
def manifest_schema_version, do: @manifest_schema_version
def native_runtime_version, do: @native_runtime_version

# lib/crosswake/manifest/types.ex — DELETE the three @-attrs, import from Contract
alias Crosswake.Bridge.Contract
@bridge_protocol_version Contract.bridge_protocol_version()  # compile-time call
# OR reference them at call sites: Contract.bridge_protocol_version()
```

**Pros:**
- Zero new files, zero new tooling, zero new CI steps.
- Pure Elixir idiom — module attributes referencing other module attributes via function calls is idiomatic Phoenix (this is exactly how Phoenix's `@protocol_version` has worked since PR #1004).
- Compiler ensures the module exists; a typo is a compile error, not a runtime surprise.
- Works perfectly for `mix crosswake.gen.shell` because `Fixtures.export/1` already calls through `Types.new_compatibility()`, so fixing the source fixes the fixture output.

**Cons:**
- Does NOT reach Swift, Kotlin, or static JSON fixtures. Those continue to read protocol version from the bundled JSON manifest emitted by Elixir; so they are only as correct as the manifest generation.
- Leaves the iOS/Android native `ActivationCoordinator` hardcoded fallback `?: "1.0.0"` in Kotlin.
- Tests that hardcode `"1.0.0"` still drift when the version bumps.
- Does not provide a drift guard — there is nothing stopping someone from adding a new `@bridge_protocol_version` attribute elsewhere in the future.

**Tradeoff:** Necessary but not sufficient. This step eliminates the within-Elixir drift (the most urgent bug) but does not achieve "cannot drift" across languages. It is a required prerequisite for any of the other mechanisms.

---

### Mechanism 2 — Canonical Data File + Mix Codegen Task + `git diff --exit-code` CI Guard

**What it is:** One committed JSON (or `.exs`) file at `priv/contract/runtime_contract.json` holds the three version strings as the single canonical fact. Elixir reads it at compile time via `@external_resource` + `File.read!`. A mix task (`mix crosswake.contract.gen`) renders Swift constants, Kotlin constants, and a docs snippet from that file. Generated output is committed. CI runs the task and then `git diff --exit-code` to confirm nothing drifted.

**Worked example — canonical file:**

```json
{
  "_comment": "Canonical source. Edit here, then run: mix crosswake.contract.gen",
  "bridge_protocol_version": "1.0.0",
  "manifest_schema_version": "1.0.0",
  "native_runtime_version": "1.0.0"
}
```

**Elixir reader:**

```elixir
# lib/crosswake/bridge/contract.ex
@contract_path "priv/contract/runtime_contract.json"
@external_resource @contract_path
@contract Jason.decode!(File.read!(Path.join(
  :code.priv_dir(:crosswake) |> to_string(),
  "contract/runtime_contract.json"
)))

@bridge_protocol_version @contract["bridge_protocol_version"]
@manifest_schema_version @contract["manifest_schema_version"]
@native_runtime_version  @contract["native_runtime_version"]
```

**Mix codegen task (sketch):**

```elixir
defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task
  @shortdoc "Regenerate Swift/Kotlin constants from priv/contract/runtime_contract.json"

  def run(_args) do
    contract = Jason.decode!(File.read!("priv/contract/runtime_contract.json"))
    bridge_vsn   = contract["bridge_protocol_version"]
    manifest_vsn = contract["manifest_schema_version"]
    runtime_vsn  = contract["native_runtime_version"]

    write_if_changed(swift_path(), swift_output(bridge_vsn, manifest_vsn, runtime_vsn))
    write_if_changed(kotlin_path(), kotlin_output(bridge_vsn, manifest_vsn, runtime_vsn))

    Mix.shell().info("contract.gen complete (bridge=#{bridge_vsn})")
  end
  # ... helpers ...
end
```

**CI step:**

```yaml
- name: Verify contract artifacts are up to date
  run: |
    mix crosswake.contract.gen
    git diff --exit-code || \
      (echo "Contract drift: run mix crosswake.contract.gen" && exit 1)
```

**Pros:**
- The single file is the "one obvious place to look." Version bumps are atomic: change `runtime_contract.json`, run `mix crosswake.contract.gen`, commit everything.
- `@external_resource` makes Elixir recompile automatically when the file changes — no manual cache busting.
- The `git diff --exit-code` pattern is proven (Go's `go generate` discipline, `buf generate` for protobuf, Crosswake's own `brand-structural` gate uses exactly this pattern).
- Swift and Kotlin get generated constants instead of relying on parsing runtime JSON; this eliminates the hardcoded fallback `?: "1.0.0"` footgun in Kotlin.
- Generated output is committed: contributors can see what changed in a version bump without running any tool, and PR diffs show all surfaces changed atomically.
- Aligns with the existing `generator_coordinate_parity` pattern already in `lib/crosswake/doctor/publish_readiness.ex`.

**Cons:**
- One new file (`priv/contract/runtime_contract.json`) and one new mix task add surface area to the library.
- Requires discipline: `mix crosswake.contract.gen` must be run before committing a version change, or the CI step fails. The CI step is the safety net for that discipline lapse.
- Does not prevent someone from hand-editing the generated Swift/Kotlin constants if they bypass the task. The CI check is the only guard against this.
- `@external_resource` path is relative to the project root (`File.cwd!` at compile time), not the file declaring it — a minor footgun documented in Elixir's Module docs.

**Tradeoff:** This is the "boring canonical" solution. It is exactly the shape Crosswake already uses for brand tokens (`tokens.css` as canonical source, `compile-tokens.js` as the codegen task, `check-consumer-drift.mjs` + `git diff` as the CI guard). The pattern is already proven in this repo.

---

### Mechanism 3 — Codegen-from-Elixir (Elixir as Source, Task Emits Swift/Kotlin/JSON)

**What it is:** The Elixir source module is the canonical authority — no separate JSON file. A mix task introspects `Crosswake.Bridge.Contract.bridge_protocol_version()` at task-run time and emits Swift constants, Kotlin constants, and fixture JSON. This is the direction the existing `mix crosswake.gen.shell` goes for the Hex version (it calls `Application.spec(:crosswake, :vsn)` at generate time, as established in v11.0).

**Worked example:**

```elixir
defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task

  def run(_args) do
    Mix.Task.run("app.start")  # ensure Contract module is loaded
    bridge_vsn = Crosswake.Bridge.Contract.bridge_protocol_version()
    # ...
    write_if_changed(swift_path(), swift_output(bridge_vsn, ...))
  end
end
```

**Pros:**
- No extra JSON file. The module attribute in `bridge/contract.ex` remains the source.
- Aligns with the existing `fetch_version!()` pattern in `mix crosswake.gen.shell` (which calls `Application.spec(:crosswake, :vsn)` already).
- Fewer files overall — the priv JSON file from Mechanism 2 is eliminated.

**Cons:**
- Requires `Mix.Task.run("app.start")` (or equivalent), which means the task has an application dependency. This can fail in minimal CI environments or during bootstrapping.
- No `@external_resource` equivalent: if someone changes the Elixir attribute and forgets to run the task, the Swift/Kotlin constants drift. The CI check catches it, but there is no compile-time signal.
- In the Mechanism 2 shape, a contributor editing `runtime_contract.json` sees a simple JSON file and knows to run one task. In Mechanism 3, a contributor editing `bridge/contract.ex` must know that this Elixir file also triggers a codegen task — a less-obvious connection.
- If the Elixir module is ever refactored (renamed, split), the task silently breaks without a file-dependency tracking signal.

**Tradeoff:** Slightly simpler file layout, slightly more fragile contributor experience. The lack of an explicit canonical data file makes the "where do I change the version?" question harder to answer for a new contributor compared to a file named `runtime_contract.json`.

---

### Mechanism 4 — Schema/IDL-First (Protobuf / JSON Schema / Custom DSL)

**What it is:** Define the bridge contract in a neutral schema language — `.proto`, JSON Schema, or a custom YAML/TOML DSL — and compile it to Elixir, Swift, Kotlin, and JSON artifact via a code-generation pipeline (`buf` for protobuf, `openapi-generator` for JSON Schema, or a bespoke mix task).

**Worked example (protobuf shape):**

```protobuf
// priv/contract/crosswake_bridge.proto
syntax = "proto3";

// Version options would be custom extensions
message ActivationRequest {
  string bridge_protocol_version = 1;
  string native_runtime_version = 2;
  string route_id = 3;
}
```

Running `buf generate` emits Elixir structs, Swift models, Kotlin data classes with breaking-change detection built in.

**Pros:**
- True schema-first: proto / JSON Schema is the unambiguous source; every surface is generated.
- Breaking-change detection (`buf breaking --against .git#branch=main`) catches incompatible field renames or type changes automatically, not just version string drift.
- Industry precedent: gRPC/Protobuf is the reference implementation; Smithy is AWS's variant; OpenAPI-generator produces multi-language SDKs from one YAML. All proven at scale.
- A custom JSON Schema source (rather than proto) avoids protobuf wire encoding and can target a simpler output (just constants + typed structs).

**Cons:**
- The bridge contract is currently JSON-over-WebSocket/Phoenix Channel, not protobuf wire. Adopting `.proto` means generating Elixir structs from proto, which adds `protobuf` as a build dep and changes how the `Crosswake.Bridge.Contract.Request` struct is defined — a significant architectural change that goes well beyond the versioning problem.
- `buf` adds a non-Elixir toolchain dependency. Contributors need Go + buf installed, which is not the `mix`-first world that Crosswake operates in.
- A JSON Schema approach for constants only (not full message encoding) adds ceremony without the type-safety or wire-format guarantee of protobuf.
- The contract surface today is three version strings, not a rich schema with many message types. An IDL is proportionate for gRPC-style APIs; it is overengineering for this problem.
- Conflicts with the "boring, canonical, hard to drift" principle — the toolchain is neither boring nor well-known to Elixir contributors.

**Tradeoff:** Appropriate if Crosswake's bridge contract were a rich API with many message types and independent client tooling. It is not. The bridge contract is a single JSON envelope with three version fields and a small command vocabulary. IDL-first adds 5x the toolchain surface for 1x the problem. Avoid.

---

## External Precedent Analysis

### 1. Phoenix Channels Wire Protocol (`vsn` Parameter)

**What they did:** `Phoenix.Transport` defines `@protocol_version "1.0.0"` as a single module attribute (added in PR #1004). Clients append `?vsn=2.0.0` to the socket URL. The server's `Version.match?/2` validates that the client vsn is compatible with the server's protocol version. The JS client defines `CHAN_VSN = "~> 1.0.0"` matching the server constant.

**Key structure:**
- Server authority: one Elixir module attribute in `Phoenix.Transport`.
- Client knowledge: the JS client hardcodes a compatible range string (`"~> 1.0.0"`).
- Cross-language sync: manually synced when protocol versions change — the JS client is published from the same Phoenix repo, so the Elixir+JS bump lands in one commit.
- No codegen: the JS constant is maintained by hand because Phoenix's JS client is co-located in the same repo and updated in the same PR as the Elixir server.

**Do this:** Single module attribute as the Elixir authority. Cross-language surfaces that live in the same monorepo can hardcode a matching constant in one atomic commit. The `Version.match?/2` negotiation is idiomatic Elixir.

**Avoid this:** If your native clients are published as separate packages (as Crosswake's iOS/Android packages are), hand-maintaining a JS constant in the same repo becomes hand-maintaining a Swift constant in a separate repo — which breaks the "same commit" guarantee. Phoenix sidesteps this because `phoenix.js` ships from the same repo. Crosswake cannot sidestep it without codegen.

**Lesson for Crosswake:** Elixir module attribute is the right authority source. The difference is that Crosswake must codegen the matching Swift/Kotlin constants because the native packages are separately published artifacts, not co-located JS code. The Phoenix pattern works for `phoenix.js` because it is in the same repo. Crosswake's iOS/Android packages are published independently via the lockstep pipeline.

Source: [PR #1004](https://github.com/phoenixframework/phoenix/pull/1004/files), [Writing a Channels Client](https://phoenix.hexdocs.pm/writing_a_channels_client.html)

---

### 2. Hotwire Native / Strada Bridge Components

**What they did:** Hotwire Native (the Rails-facing side) defines bridge component names as string constants in JavaScript Stimulus controllers. The iOS/Android sides match those string names. There is no version negotiation protocol — components match by name only, and the contract evolves by releasing new versions of all three packages simultaneously. Joe Masilotti's bridge-components library works by copy-paste: contributors paste Swift/Kotlin files alongside the JS file, accepting that they must update all three manually when a component's interface changes.

**Do this:** The three-sided copy-paste model works when components are simple and changes are infrequent. For Hotwire's use case (UI components, not protocol versioning), the coupling is loose enough that manual sync is tolerable.

**Avoid this:** Copy-paste is explicitly the model they chose to avoid tooling complexity. But it means version drift IS the intended failure mode — they tolerate it because the consequence is a component not rendering, not a hard denial. Crosswake's activation coordinator does an exact-version equality check, which means drift causes a hard denial rather than a silent degradation. You cannot tolerate copy-paste drift with an exact-equality gate.

**Lesson for Crosswake:** Crosswake's exact-equality protocol check is stricter than Hotwire's name-based matching. Hotwire's "copy-paste and manually maintain" approach is insufficient for a system that hard-denies on version mismatch.

Sources: [Strada iOS](https://github.com/hotwired/strada-ios), [Hotwire Native iOS bridge components](https://native.hotwired.dev/ios/bridge-components), [Joe Masilotti bridge-components](https://github.com/joemasilotti/bridge-components)

---

### 3. gRPC / Protocol Buffers + buf

**What they did:** One `.proto` file is the canonical source of truth. `buf generate` (with a `buf.gen.yaml` config checked into the repo) produces Go, TypeScript, Java, Kotlin, Swift, Python stubs. Generated output is committed. CI runs `buf generate` followed by `git diff --exit-code`. `buf breaking --against .git#branch=main` detects wire-breaking changes before they merge.

**Do this:**
- Commit generated output, verify in CI with `git diff --exit-code`. This is the key discipline. Contributors see all generated artifacts in PR diffs. The CI step is the safety net.
- Check the canonical source into the repo (`.proto` file, or in Crosswake's case, `priv/contract/runtime_contract.json`). Treat it as the owned fact.
- Wire-breaking change detection as a first-class CI concern.

**Avoid this:**
- Adopting `.proto` encoding itself if your wire format is already JSON-over-WebSocket. The canonical-source + codegen pattern is portable; the protobuf wire encoding is not required.
- Generating code in CI without committing it. If you run codegen in the build step but don't commit, contributors can't see what changed and rollback is ambiguous.

**Lesson for Crosswake:** The pattern is: one canonical data file + one codegen task + commit generated output + `git diff --exit-code` in CI. This is fully portable to Elixir/Mix without adopting `.proto` encoding. Crosswake already uses this exact pattern for brand tokens (`compile-tokens.js` → `tokens.css` → `check-consumer-drift.mjs`).

Sources: [buf generate docs](https://buf.build/docs/generate/), [buf breaking change detection](https://buf.build/docs/breaking/)

---

### 4. Stripe API Versioning

**What they did:** Every Stripe SDK pins a specific dated API version at compile time (e.g., `"2025-04-30.basil"`). Each SDK release ships with one embedded API version constant. The SDK and the API version bump independently, but the SDK's embedded version is the contract it was built and tested against.

**Do this:** Pin the protocol version inside the library at compile/build time, not at request time. This is exactly what Crosswake does for the native packages — the Swift/Kotlin packages should embed their compatible protocol version as a constant.

**Avoid this:** Stripe's approach separates SDK versioning from API versioning entirely (SemVer for SDK, date strings for API). This is appropriate for a REST API where thousands of customers have independently pinned versions. Crosswake's contract is much tighter: a single app ships one Hex version, one iOS package version, one Android package version, all lockstep. Crosswake does not need Stripe's elaborate multi-version server-side maintenance. Overkill.

**Lesson for Crosswake:** Embed the protocol version in the native package at build time via a generated constant, not via runtime JSON parsing with a fallback default. Eliminate the `?: "1.0.0"` fallback in Kotlin. A fallback defeats the purpose of a strict version gate — the fallback itself is a silent version assumption.

Sources: [Stripe — APIs as infrastructure](https://stripe.com/blog/api-versioning), [Stripe SDK versioning docs](https://docs.stripe.com/sdks/versioning)

---

### 5. Capacitor Native Bridge Version Contract

**What they did:** Capacitor publishes `@capacitor/core`, `@capacitor/ios`, `@capacitor/android` on npm/CocoaPods/Maven with matching major versions. The `cap sync` CLI copies the bridge JS and configuration, ensuring all three are on the same version. The version itself comes from the npm package version. There is no separate protocol version string — the package version IS the contract version.

**Do this:** For a lockstep-released suite of packages, the package version is often sufficient as the compatibility signal. Crosswake already uses this model for the Hex package version via `Application.spec(:crosswake, :vsn)`. The bridge and manifest axes are SEPARATE from the package version because they evolve independently — but the principle that the package version is the source for lockstep artifacts (dep coordinates in generated shell templates) is proven.

**Avoid this:** Making the native CLI the single source of truth for version management. Crosswake does not have a CLI equivalent of `cap sync` and should not need one. Capacitor's tight coupling between CLI, package version, and bridge version works because they ship all three from one team's release process. Crosswake's axes are intentionally separate.

**Lesson for Crosswake:** For artifacts where the package version IS the right signal (dep coordinates in generated shell templates), use `Application.spec(:crosswake, :vsn)` as already established in `mix crosswake.gen.shell`. For the three protocol-version axes (which are distinct from the package version), a separate canonical source is still needed.

Source: [Capacitor development workflow](https://capacitorjs.com/docs/basics/workflow)

---

### 6. Smithy / OpenAPI-Generator

**What they did:** A single `.smithy` model (or `openapi.yaml`) defines all API operations and data shapes. AWS uses Smithy to generate Go, TypeScript, Ruby, Python, Swift, Kotlin SDKs plus test fixtures from one source. The generation process is a multi-stage pipeline ensuring consistency across all languages. Generated code may or may not be committed depending on team discipline; teams who commit it validate with `git diff`.

**Do this:** The model-driven approach is architecturally correct for a rich API surface with many message types. The "commit generated output, verify with `git diff` in CI" pattern is universal across all of these systems.

**Avoid this:** Adopting Smithy or OpenAPI-generator for a three-field version contract. It is substantial toolchain overhead for a narrow problem. The pattern is right; the specific tool is wrong at this scale.

**Lesson for Crosswake:** Validate "commit generated output, `git diff --exit-code` in CI" as the universal CI discipline. Apply it with a simple Mix task rather than an IDL toolchain.

Sources: [Smithy.io](https://smithy.io/), [AWS Smithy TypeScript](https://aws.amazon.com/blogs/devops/smithy-server-and-client-generator-for-typescript/)

---

## Comparison Table

| Criterion | M1: Single Attr | M2: Canonical JSON + codegen | M3: Codegen-from-Elixir | M4: IDL (proto) |
|-----------|-----------------|------------------------------|--------------------------|-----------------|
| Fixes Elixir-internal drift | Yes | Yes | Yes | Yes |
| Fixes Swift/Kotlin drift | No | Yes (generated constants) | Yes (generated constants) | Yes (generated structs) |
| Fixes JSON fixture drift | Partially (via Fixtures.export) | Yes (baseline fixture generated) | Yes | Yes |
| New toolchain required | None | None | None | Go + buf / protoc |
| Contributor DX: "where do I change it?" | Edit `bridge/contract.ex` | Edit `runtime_contract.json`, run `mix crosswake.contract.gen` | Edit `bridge/contract.ex`, run `mix crosswake.contract.gen` | Edit `.proto`, run buf |
| Compile-time file tracking | Module attr (implicit) | `@external_resource` (explicit, recompiles on file change) | Module attr (implicit) | Generated Elixir module |
| CI drift guard possible | No (just tests) | Yes (`git diff --exit-code`) | Yes (`git diff --exit-code`) | Yes (`git diff --exit-code`) |
| Matches existing Crosswake patterns | Yes (gen.shell uses spec/vsn) | Yes (brand tokens + coordinate parity patterns) | Yes (gen.shell pattern) | No (new toolchain) |
| Aligns with lockstep release pipeline | Yes | Yes | Yes | Yes (but more steps) |
| Works in Hex release (no repo) | Yes | Yes (`priv/` ships in Hex package) | Yes | No (requires proto toolchain) |
| Risk of future drift | High (no guard) | Low (CI guard) | Low (CI guard) | Low (CI guard + schema type-check) |
| Maintenance burden on version bump | Low | Low (edit JSON, run task, commit diff) | Low (edit Elixir, run task, commit diff) | Medium (edit proto, run buf, commit diff) |
| Appropriate for Crosswake? | Prerequisite only | **Recommended** | Acceptable alternative | Overengineering |

---

## RECOMMENDATION

**Adopt Mechanism 2: Canonical JSON file + `mix crosswake.contract.gen` + `git diff --exit-code` CI guard.**

Mechanism 1 alone does not close the drift gap across Swift/Kotlin/JSON. Mechanisms 3 and 4 are either slightly more fragile (M3) or disproportionate in toolchain cost (M4). Mechanism 2 is the right shape.

### Rationale

**1. It matches the existing Crosswake discipline exactly.** The brand-token system already follows this pattern: `tokens.css` is the canonical source, `compile-tokens.js` regenerates consumers, `check-consumer-drift.mjs` + CI `git diff` is the guard. The `generator_coordinate_parity` doctor check follows the same pattern for Hex version coordinates. Crosswake contributors already know how to read this shape. Adding the same pattern for the runtime contract means zero new mental models.

**2. The canonical JSON file is the right scope of authority.** `priv/contract/runtime_contract.json` answers "what version is this?" with a single, human-readable, diffable file. A version bump shows up as a three-line JSON diff, one Swift constant diff, one Kotlin constant diff, and updated test literals — all in one PR. That is the strongest possible signal in a PR review.

**3. `@external_resource` makes Elixir recompile automatically.** When `runtime_contract.json` changes, every module that declares `@external_resource "priv/contract/runtime_contract.json"` recompiles. The compiler enforces freshness. This is Elixir's canonical pattern for this use case (documented in `Module` hexdocs, used by `Plug.Conn.Status` for status code definitions).

**4. Generated Swift/Kotlin constants eliminate the hardcoded fallback.** The Kotlin `ActivationCoordinator.kt:594` fallback `?: "1.0.0"` is a latent drift source — a silent version assumption embedded in a fallback path. A generated `ContractVersions.kt` with a compile-time constant removes the implicit assumption. The fallback then points to the generated constant rather than a bare string literal.

**5. `git diff --exit-code` in CI is the proven drift guard.** It is the same pattern as `go generate` discipline, `buf generate` discipline, and Crosswake's own `brand-structural` workflow. The CI step fails loudly if anyone changes the canonical JSON but forgets to run `mix crosswake.contract.gen`.

**6. The canonical JSON ships in the Hex package.** `priv/` is included in the Hex package files list in `mix.exs`. `priv/contract/runtime_contract.json` travels with the library installation. An adopter's `mix crosswake.doctor` can read it and confirm the version at install-verify time.

### What Mechanism 1 Still Does (It Is Required First)

Before introducing the canonical JSON file, collapse the three Elixir sources into one. `lib/crosswake/bridge/contract.ex` becomes the single Elixir home for the three version module attributes. `lib/crosswake/manifest/types.ex` and `lib/crosswake/shell/fixtures.ex` import from `Contract` instead of defining their own constants. This fixes the immediate `1.1.0` vs `1.0.0` production bug and is a prerequisite for Mechanism 2 (the JSON file and the Elixir module must agree; the easiest way is to have the Elixir module read from the JSON file via `@external_resource`).

The right order: fix the version to one agreed-upon value, consolidate Elixir sources (M1), then introduce the JSON canonical file and codegen task (M2). Both steps belong in the same milestone.

---

## Concrete Implementation Shape

### File Layout

```
priv/
  contract/
    runtime_contract.json          <- THE canonical source (human edits happen here)

lib/
  crosswake/
    bridge/
      contract.ex                  <- reads from runtime_contract.json via @external_resource
    manifest/
      types.ex                     <- calls Contract.bridge_protocol_version() etc (no own @attrs)
    shell/
      fixtures.ex                  <- calls Contract.bridge_protocol_version() etc (no own @attrs)
  mix/
    tasks/
      crosswake.contract.gen.ex    <- new mix task: reads JSON, writes Swift/Kotlin constants

packages/
  crosswake-shell-core-ios/
    Sources/CrosswakeShellCore/
      ContractVersions.swift       <- GENERATED (do not edit); committed
  crosswake-shell-core-android/
    src/main/java/dev/crosswake/shell/core/
      ContractVersions.kt          <- GENERATED (do not edit); committed
```

### `priv/contract/runtime_contract.json`

```json
{
  "_comment": "Canonical source for all three version axes. Edit here, then run: mix crosswake.contract.gen",
  "bridge_protocol_version": "1.0.0",
  "manifest_schema_version": "1.0.0",
  "native_runtime_version": "1.0.0"
}
```

### Updated `bridge/contract.ex` (key changes only)

```elixir
defmodule Crosswake.Bridge.Contract do
  @contract_path "priv/contract/runtime_contract.json"
  @external_resource @contract_path

  # Read at compile time via priv_dir for Hex-installed compatibility
  @contract Jason.decode!(File.read!(
    Path.join(:code.priv_dir(:crosswake) |> to_string(), "contract/runtime_contract.json")
  ))

  @bridge_protocol_version @contract["bridge_protocol_version"]
  @manifest_schema_version @contract["manifest_schema_version"]
  @native_runtime_version  @contract["native_runtime_version"]

  def bridge_protocol_version, do: @bridge_protocol_version
  def manifest_schema_version, do: @manifest_schema_version
  def native_runtime_version,  do: @native_runtime_version
end
```

Note: `Path.join(:code.priv_dir(:crosswake) |> to_string(), ...)` works both in the source checkout (where `priv/` is relative to `mix.exs`) and in a Hex-installed release (where `priv/` is under the OTP application directory). The `@external_resource` declaration still uses the relative path form, which is relative to the project root at compile time.

### Generated `ContractVersions.swift`

```swift
// AUTO-GENERATED — do not edit. Source: priv/contract/runtime_contract.json
// Regenerate with: mix crosswake.contract.gen
public enum CrosswakeContractVersions {
    public static let bridgeProtocolVersion = "1.0.0"
    public static let manifestSchemaVersion = "1.0.0"
    public static let nativeRuntimeVersion  = "1.0.0"
}
```

### Generated `ContractVersions.kt`

```kotlin
// AUTO-GENERATED — do not edit. Source: priv/contract/runtime_contract.json
// Regenerate with: mix crosswake.contract.gen
package dev.crosswake.shell.core

object ContractVersions {
    const val BRIDGE_PROTOCOL_VERSION = "1.0.0"
    const val MANIFEST_SCHEMA_VERSION = "1.0.0"
    const val NATIVE_RUNTIME_VERSION  = "1.0.0"
}
```

After generation, `ActivationCoordinator.kt:594` becomes:

```kotlin
val nativeRuntimeVersion = compatibilityJson?.getString("native_runtime_version")
    ?: ContractVersions.NATIVE_RUNTIME_VERSION
```

This eliminates the bare `"1.0.0"` string fallback. The fallback now points to the generated constant.

### The One Mix Task

```elixir
# lib/mix/tasks/crosswake.contract.gen.ex
defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task

  @shortdoc "Regenerate Swift/Kotlin constants from priv/contract/runtime_contract.json"
  @moduledoc """
  Reads `priv/contract/runtime_contract.json` and regenerates:
  - `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ContractVersions.swift`
  - `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ContractVersions.kt`

  Generated files are committed. CI verifies they are current with:
      mix crosswake.contract.gen && git diff --exit-code

  Run after any change to `priv/contract/runtime_contract.json`.
  """

  @contract_path "priv/contract/runtime_contract.json"

  @impl Mix.Task
  def run(_args) do
    contract = Jason.decode!(File.read!(@contract_path))
    bridge_vsn   = contract["bridge_protocol_version"]
    manifest_vsn = contract["manifest_schema_version"]
    runtime_vsn  = contract["native_runtime_version"]

    write_if_changed(swift_path(), swift_output(bridge_vsn, manifest_vsn, runtime_vsn))
    write_if_changed(kotlin_path(), kotlin_output(bridge_vsn, manifest_vsn, runtime_vsn))

    Mix.shell().info("contract.gen complete " <>
      "(bridge=#{bridge_vsn} manifest=#{manifest_vsn} runtime=#{runtime_vsn})")
  end

  defp swift_path,
    do: "packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/ContractVersions.swift"

  defp kotlin_path,
    do: "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ContractVersions.kt"

  defp swift_output(bridge, manifest, runtime) do
    """
    // AUTO-GENERATED — do not edit. Source: priv/contract/runtime_contract.json
    // Regenerate with: mix crosswake.contract.gen
    public enum CrosswakeContractVersions {
        public static let bridgeProtocolVersion = "#{bridge}"
        public static let manifestSchemaVersion = "#{manifest}"
        public static let nativeRuntimeVersion  = "#{runtime}"
    }
    """
  end

  defp kotlin_output(bridge, manifest, runtime) do
    """
    // AUTO-GENERATED — do not edit. Source: priv/contract/runtime_contract.json
    // Regenerate with: mix crosswake.contract.gen
    package dev.crosswake.shell.core

    object ContractVersions {
        const val BRIDGE_PROTOCOL_VERSION = "#{bridge}"
        const val MANIFEST_SCHEMA_VERSION = "#{manifest}"
        const val NATIVE_RUNTIME_VERSION  = "#{runtime}"
    }
    """
  end

  defp write_if_changed(path, content) do
    File.mkdir_p!(Path.dirname(path))
    case File.read(path) do
      {:ok, ^content} -> Mix.shell().info("unchanged: #{path}")
      _ ->
        File.write!(path, content)
        Mix.shell().info("wrote: #{path}")
    end
  end
end
```

### The CI Step

```yaml
# .github/workflows/contract-drift.yml
name: Contract Drift Guard
# contract-drift-guard is a required branch-protection context.
# Enforces that priv/contract/runtime_contract.json is the only place a
# contributor changes protocol versions, and that generated Swift/Kotlin
# constants are always current.

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  contract-drift-guard:
    name: contract-drift-guard
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.19'
          otp-version: '27'
      - run: mix deps.get
      - run: mix crosswake.contract.gen
      - name: Verify no drift
        run: |
          git diff --exit-code || \
            (echo "Contract drift detected. Run: mix crosswake.contract.gen" && exit 1)
```

### Contributor Experience — The Complete Version-Bump Ceremony

1. Edit `priv/contract/runtime_contract.json` — change the version strings. This is the ONE obvious place.
2. Run `mix crosswake.contract.gen` — Swift/Kotlin constants regenerate in `packages/`.
3. `git add priv/contract/runtime_contract.json packages/...` — commit everything together.
4. Update test assertions that hardcode `"1.0.0"` to use `Crosswake.Bridge.Contract.bridge_protocol_version()` (or leave them as-is if the version change is intentional and tests need to assert the new value explicitly — that is fine, the tests are the proof).
5. CI passes because `git diff --exit-code` is clean after the committed generated output.
6. Hex version bump in `mix.exs` is a separate, independent axis driven by release-please — unchanged.

That is the complete version-bump ceremony. One file to edit. One task to run. One commit. CI is the safety net.

### Integration With Lockstep Release Pipeline

The lockstep release-please pipeline (Hex + iOS tag + Maven, established in v11.0) is unchanged. That pipeline bumps `@version "0.x.y"` in `mix.exs` and triggers native publish jobs. The runtime contract axes (`bridge_protocol_version` etc.) are semantically independent from the Hex package version — they can change without a Hex version bump and can stay the same across many Hex versions.

When a contract version bump accompanies a Hex release, the generated `ContractVersions.swift` and `ContractVersions.kt` are committed in the same PR as the `priv/contract/runtime_contract.json` change. The native packages pick them up when published in the lockstep release job. No changes to `.github/workflows/release-please.yml` are needed.

---

## Doctor Check Extension

The existing `generator_coordinate_parity` doctor check in `lib/crosswake/doctor/publish_readiness.ex` should gain a sibling: `contract_version_parity` that reads `priv/contract/runtime_contract.json` and verifies that `Crosswake.Bridge.Contract.bridge_protocol_version()` returns the same value. If someone hand-edits the Elixir module without running the task, the doctor check catches it locally before CI does.

```elixir
defp contract_version_parity_check do
  contract = Jason.decode!(File.read!("priv/contract/runtime_contract.json"))
  bridge_json   = contract["bridge_protocol_version"]
  manifest_json = contract["manifest_schema_version"]
  runtime_json  = contract["native_runtime_version"]

  bridge_module   = Crosswake.Bridge.Contract.bridge_protocol_version()
  manifest_module = Crosswake.Bridge.Contract.manifest_schema_version()
  runtime_module  = Crosswake.Bridge.Contract.native_runtime_version()

  passed? = bridge_json == bridge_module
         && manifest_json == manifest_module
         && runtime_json == runtime_module

  result_check(
    id: "contract.version_parity",
    category: :contract_version_parity,
    passed?: passed?,
    message: if(passed?,
      do: "priv/contract/runtime_contract.json and Bridge.Contract module agree on all three axes",
      else: "version mismatch: JSON(#{bridge_json}/#{manifest_json}/#{runtime_json}) vs " <>
            "module(#{bridge_module}/#{manifest_module}/#{runtime_module})"
    ),
    hint: "Run mix crosswake.contract.gen after editing priv/contract/runtime_contract.json",
    proof_class: :merge_blocking,
    claim_scope: "Runtime contract version parity"
  )
end
```

---

## Pitfalls to Avoid

| Pitfall | Why It Happens | Prevention |
|---------|----------------|------------|
| `@external_resource` path pitfall | Path is relative to project root (`File.cwd!` at compile time), not the declaring file. This is documented in Elixir's Module hexdocs. | Use `@external_resource "priv/contract/runtime_contract.json"` for the declaration; use `Path.join(:code.priv_dir(:crosswake) \|> to_string(), ...)` for the actual `File.read!` call |
| Kotlin fallback `?: "1.0.0"` remains after adding `ContractVersions.kt` | The bare string fallback is not updated in the same PR | Change the fallback to `?: ContractVersions.NATIVE_RUNTIME_VERSION` in the same PR as introducing the generated file |
| Tests still hardcode `"1.0.0"` after the fix | Test authors copy-paste version strings | Replace hardcoded version strings in `crosswake_doctor_test.exs` and `compatibility_test.exs` with `Crosswake.Bridge.Contract.bridge_protocol_version()` calls. The CI drift guard does not catch test string literals directly — this requires discipline in test authoring. |
| `mix crosswake.contract.gen` not run after JSON edit | Contributor forgets | CI `git diff --exit-code` step is the safety net; doctor `contract_version_parity` check catches it locally during `mix crosswake.doctor` |
| `runtime_contract.json` grows beyond version strings | Feature creep into the contract file | Explicitly scope the file to the three version axes and a `_comment` field only; command vocabulary lives in `bridge/contract.ex` |
| `priv/contract/` omitted from `files` in `mix.exs` | `files: ~w(lib priv mix.exs ...)` already includes `priv/` — the subdirectory is covered | Verify with `mix hex.build --dry-run` that `priv/contract/runtime_contract.json` appears in the tarball listing before first publish after adding this file |
| Swift/Kotlin generated files get hand-edited | Developer does not notice the `AUTO-GENERATED` comment | The CI drift check catches it on the next `mix crosswake.contract.gen` run; the `AUTO-GENERATED` comment is the first line of both files |
| Version bumped in `mix.exs` but not in `runtime_contract.json` | Confusion between Hex package version and contract protocol version | These are independent axes. Document this explicitly in `guides/compatibility.md`: "The Hex package version and the contract protocol versions are independent axes. Edit `priv/contract/runtime_contract.json` to bump protocol versions." |

---

## Summary

The current drift between `1.1.0` in `Crosswake.Bridge.Contract` and `1.0.0` everywhere else is a production-confidence bug. The root cause is that three Elixir files, two native packages, and JSON fixtures all independently author the same strings.

The recommended fix:
1. **Immediate:** Decide the correct version (likely `1.0.0` to match the published artifacts), collapse the three Elixir `@-version` attrs into one in `bridge/contract.ex`, consuming `priv/contract/runtime_contract.json` via `@external_resource`. Delete duplicate attrs from `manifest/types.ex` and `shell/fixtures.ex`.
2. **Core:** Ship `mix crosswake.contract.gen` — reads the JSON, emits `ContractVersions.swift` and `ContractVersions.kt`.
3. **Guard:** Add `contract-drift-guard` CI job (`mix crosswake.contract.gen && git diff --exit-code`) wired as a required branch-protection check.
4. **Clean up:** Replace hardcoded `"1.0.0"` test literals with `Crosswake.Bridge.Contract.bridge_protocol_version()` calls. Update the Kotlin fallback to use `ContractVersions.NATIVE_RUNTIME_VERSION`.
5. **Doctor:** Add `contract_version_parity` doctor check as a sibling to `generator_coordinate_parity`.

This gives one obvious place to change the version (`priv/contract/runtime_contract.json`), one obvious task to run (`mix crosswake.contract.gen`), one obvious CI gate that fails loudly on drift, and zero new toolchain dependencies. It is the same pattern Crosswake already uses for brand-token drift prevention and generator coordinate parity — which means it is both idiomatic for this repo and already understood by the maintainer.

---

## Sources

- [Phoenix PR #1004 — Version channel transport contract](https://github.com/phoenixframework/phoenix/pull/1004/files)
- [Phoenix — Writing a Channels Client](https://phoenix.hexdocs.pm/writing_a_channels_client.html)
- [Phoenix Channels hexdocs](https://hexdocs.pm/phoenix/channels.html)
- [Elixir Module docs — @external_resource](https://hexdocs.pm/elixir/Module.html)
- [Learn Elixir — Making Elixir Recompile When External Files Change](https://learn-elixir.dev/blogs/making-elixir-recompile-when-external-files-change)
- [TIL about @external_resource module attribute in Elixir](https://jordanelver.co.uk/blog/2020/04/23/til-about-the-external-resource-module-attribute-in-elixir/)
- [Hotwire Strada iOS](https://github.com/hotwired/strada-ios)
- [Hotwire Native iOS bridge components](https://native.hotwired.dev/ios/bridge-components)
- [Joe Masilotti bridge-components](https://github.com/joemasilotti/bridge-components)
- [buf — Generating code](https://buf.build/docs/generate/)
- [buf — Breaking change detection](https://buf.build/docs/breaking/)
- [bufbuild/buf GitHub](https://github.com/bufbuild/buf)
- [Stripe — APIs as infrastructure: future-proofing with versioning](https://stripe.com/blog/api-versioning)
- [Stripe SDK versioning docs](https://docs.stripe.com/sdks/versioning)
- [Capacitor development workflow](https://capacitorjs.com/docs/basics/workflow)
- [Smithy.io](https://smithy.io/)
- [AWS — Smithy TypeScript client code generation](https://aws.amazon.com/blogs/devops/smithy-server-and-client-generator-for-typescript/)
- [Should generated files be committed? (templ discussion)](https://github.com/a-h/templ/discussions/419)
