# Phase 159: Host-Reusable Proof Lane - Pattern Map

**Mapped:** 2026-07-31  
**Files analyzed:** 13 planned file groups  
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` | config / controller | request-response, file-I/O | `lib/mix/tasks/crosswake.gen.shell.ex` | exact lifecycle match |
| `lib/crosswake/proof_lane/config.ex` | model / utility | transform | `lib/crosswake/shell/diagnostic_export.ex` | role match |
| `lib/crosswake/proof_lane/generator.ex` | service | file-I/O | `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` | exact lifecycle match |
| `lib/crosswake/proof_lane/evidence.ex` | service | file-I/O, transform | `lib/crosswake/shell/diagnostic_export.ex` | role match |
| `priv/templates/crosswake/proof_lane/**` | config / template | transform | `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` | role match |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | utility | request-response, event-driven | same file | exact semantic match |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | utility / template | request-response, event-driven | `examples/phoenix_host/e2e/support/offline_route_proof.ts` | exact extraction match |
| `priv/templates/crosswake/proof_lane/test/proof_lane_test.exs.eex` | test / template | CRUD, request-response | `test/mix/tasks/crosswake_gen_shell_diff_test.exs` | role match |
| `test/mix/tasks/crosswake_gen_proof_lane_test.exs` | test | file-I/O | `test/mix/tasks/crosswake_gen_shell_diff_test.exs` | exact lifecycle match |
| `test/crosswake/proof_lane/config_test.exs` | test | transform | `test/crosswake/shell/diagnostic_export_test.exs` | role match |
| `test/crosswake/proof_lane/evidence_test.exs` | test | file-I/O, transform | `test/crosswake/planning/first_adopter_context_test.exs` | role match |
| `script/verify_generated_ios_shell.sh` | utility / config | batch | same file | exact extension match |
| generated XCTest/XCUITest sources and proof-owned Xcode wiring | test / config | event-driven | iOS project template | partial (new UI target required) |

## Pattern Assignments

### `lib/mix/tasks/crosswake.gen.proof_lane.ex` (Mix task, request-response + file-I/O)

**Analog:** `lib/mix/tasks/crosswake.gen.shell.ex`

Copy the strict option parse and action fork. `--check` and `--diff` must branch before every write, as `--diff` does here (lines 61-103):

```elixir
{opts, argv, invalid} = OptionParser.parse(args, strict: @switches)

if invalid != [] do
  Mix.raise("invalid options: #{inspect(invalid)}")
end

if opts[:diff] do
  Mix.shell().info("[crosswake] diff — read-only, no files changed")
  run_diff(platform, target, router, local)
else
  # generation branch
end
```

**Diff pattern:** lines 109-244 read the manifest, render desired templates in memory, report missing/different files, and never call a write function. Adapt the report to disclose only safe relative paths and template versions; do not print normalized configuration values or contents.

### `lib/crosswake/proof_lane/config.ex` (closed config model, transform)

**Analog:** `lib/crosswake/shell/diagnostic_export.ex`

Use module attributes as the one closed vocabulary and a typed struct, not an open map (lines 43-105 and 111-193):

```elixir
@enforce_keys [:schema_version, :layer, :platform, :native_runtime_version,
               :kind, :correlation_id, :observed_at]
defstruct [:schema_version, :layer, :platform, :native_runtime_version,
           :kind, :correlation_id, :observed_at, native_diagnostic: nil]
```

Normalize once and fail closed. The relevant sanitizer at lines 312-334 rejects forbidden or unexpected keys rather than dropping them:

```elixir
cond do
  Enum.any?(normalized_keys, &(&1 in @forbidden_keys)) ->
    {:error, :redaction_failed}

  Enum.any?(normalized_keys, &(&1 not in @envelope_fields)) ->
    {:error, :redaction_failed}

  true ->
    case new_envelope(input) do
      {:ok, envelope} -> {:ok, envelope}
      {:error, _} -> {:error, :redaction_failed}
    end
end
```

For proof-lane config, return stable `{rule_id, safe_key_or_path}` errors instead of `inspect/1` of a rejected value. Validate the exact D-06 key set, host-local paths, field-path grammar, and destination containment in this module only; pass its struct to all manifest/template code.

### `lib/crosswake/proof_lane/generator.ex` (missing-only generation service, file-I/O)

**Analog:** `lib/mix/tasks/crosswake.gen.native_controls_ui.ex`

Use its stamped provenance and no-clobber structure. Its task expands the root and renders stamped bytes before calling `ensure_file/2` (lines 68-93); its containment guard expands both operands (lines 143-151); and its write branch reads first (lines 153-189):

```elixir
case File.read(path) do
  {:ok, _contents} ->
    Mix.shell().info("  reused #{relative_path(path)} (host-owned; the generator never clobbers your copy)")
    :reused

  {:error, :enoent} ->
    write_new_file(path, contents)

  {:error, reason} ->
    Mix.raise("could not read #{path}: #{:file.format_error(reason)}")
end
```

Create a versioned desired-state manifest alongside provenance stamps. Existing generated files remain host-owned and advisory in diff; neither generation nor check may merge or overwrite them. Check should instead fail for missing required paths, unsafe/stale provenance, and unsatisfiable collisions.

### `lib/crosswake/proof_lane/evidence.ex` (evidence compiler/scanner, transform + file-I/O)

**Primary analog:** `lib/crosswake/shell/diagnostic_export.ex`.

Use allowlist-by-construction, nested-map coercion, and generic rejection. The constructor pipeline at lines 368-410 validates before constructing, while the explicit serialization at lines 337-362 emits only string-keyed declared fields. Do not derive a generic JSON encoder over an open structure.

**Scanner/error analog:** `lib/crosswake/planning/first_adopter_context.ex` lines 99-141 and 270-301. Its public scanner returns rule/path records, and its containment/error branches replace unsafe candidates with a safe path label. Maintain that output shape: no matched value, serialized candidate, stdout/stderr, endpoint, or hash input may be returned.

Implement the locked sequence: typed allowlist build → sibling staging directory → recursively enumerate every staged path → scan all final candidates → atomic rename. Hash only separately approved sanitized bytes. On any rule failure, leave no final artifact.

### `priv/templates/crosswake/proof_lane/**` (host-owned templates, transform)

**Analog:** `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`.

The current iOS project template declares explicit file references/build files (lines 9-43), a separate unit-test target (lines 143-178), links it through `TestTargetID` (lines 181-217), and gives tests explicit source phases (lines 236-253). Follow this declarative, static-template pattern for a proof-owned XCTest target and a distinct XCUITest target. Do not add project-manager tooling or modify an adopter-owned project in place.

Use EEx assigns as in `crosswake.gen.shell` lines 400-415, where all templates receive one canonical set of assigns. Template surfaces must be rendered from normalized config, but retained evidence and CLI output must never include that config.

### Browser helper and generated Playwright helper (utility, event-driven + request-response)

**Analog:** `examples/phoenix_host/e2e/offline_sync.spec.ts` and `examples/phoenix_host/e2e/support/offline_route_proof.ts`.

Preserve this exact browser semantic order from `offline_sync.spec.ts` lines 17-67:

```typescript
await context.setOffline(true);
await page.click('#btn-flip');
await page.click('#btn-good');
const mutations = await readQueuedOfflineMutations(page);
await context.setOffline(false);
await page.evaluate(() => window.dispatchEvent(new Event('online')));
await page.waitForResponse(r => r.url().includes('/study/sync') && r.status() === 200);
await expectSyncedReview(page.request, capturedId);
await expectOutboxEmpty(page);
```

Parameterize only host-owned route path, selectors, IndexedDB database/store, mutation-ID field path, sync/evidence paths, and adapter hooks. Keep browser inspection observational: helper lines 210-237 reset/read IndexedDB through `page.addInitScript` and `page.evaluate`, while lines 240-259 assert the backend result and opaque app-generated mutation identifier. Do not template LearnLoop domain fields, fixture taxonomy, copy, or Ecto assumptions.

### Tests (ExUnit, file-I/O + transform)

**Mix-task analog:** `test/mix/tasks/crosswake_gen_shell_diff_test.exs`.

Copy the recursive before/after snapshot at lines 24-36 and byte-identical assertion at lines 44-80 to prove `--diff` and `--check` write nothing. Extend it with generated-file stamps, partial-tree repair, collision failure, safe diff output, and manifest compatibility checks.

**Config/evidence analogs:** `test/crosswake/shell/diagnostic_export_test.exs` and `test/crosswake/planning/first_adopter_context_test.exs`.

Use table/loop negative controls like the diagnostic exporter’s forbidden-key tests (lines 190-215), and assert that `inspect(error)` lacks injected secret/sensitive fixture text as in `first_adopter_context_test.exs` lines 138-148 and 160-212. Include anti-vacuity assertions that newly generated staged paths are discovered/scanned.

### `script/verify_generated_ios_shell.sh` (batch verification)

**Analog:** same file. Retain its tool preflight (lines 14-15), scheme/destination discovery and simulator fallback (lines 94-131), and build-for-testing invocation (lines 200-209). Extend the current configured shell verification to compile both proof test targets; leave simulator launch/test execution advisory and never turn it into a physical-device CI lane.

## Shared Patterns

### Host ownership and no-clobber

**Sources:** `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` lines 153-189; `lib/mix/tasks/crosswake.gen.shell.ex` lines 333-415.

Every copied adapter/template gets a provenance stamp and is created only on `:enoent`. A rerun fills absent files, reports `reused` for existing ones, and never offers force/merge behavior.

### Read-only action modes

**Source:** `lib/mix/tasks/crosswake.gen.shell.ex` lines 79-83 and 109-244.

Fork `--check`/`--diff` before generation and enforce no-write snapshots in tests. Diff is advisory for host-owned bytes; check validates the required scaffold rather than claiming ownership of edits.

### Closed, non-echoing privacy failures

**Sources:** `lib/crosswake/shell/diagnostic_export.ex` lines 296-334; `lib/crosswake/planning/first_adopter_context.ex` lines 124-141, 270-301.

All config/evidence rejection returns only a stable rule ID plus safe key/path. Use typed allowlists and final artifact scans; never retain or print values, raw payloads, endpoints, credentials, identity data, `.xcresult`, screenshots, traces, or raw output.

### Browser versus device authority

**Sources:** `examples/phoenix_host/e2e/offline_sync.spec.ts` lines 17-67; `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex` lines 143-178.

Playwright remains the primary proof of UI mutation, IndexedDB observation, app-driven reconnect, backend confirmation, empty outbox, and idempotency. XCTest validates deterministic config/schema/driver contracts; XCUITest alone owns launch, accessibility navigation, terminate/relaunch, and low-cardinality observable outcome. No Android additions.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Generated proof-driver protocol/adaptor source | provider | request-response | No current iOS proof-driver protocol exists; model it as a closed test-only outcome contract (`passed`, `blocked`, `unavailable`) using the typed-envelope precedent. |
| Generated XCUITest source | test | event-driven | Current project has only a unit-test target. Use the static PBX target pattern, but add the separate UI-test target and accessibility-only lifecycle behavior required by Phase 159. |

## Metadata

**Analog search scope:** `lib/mix/tasks`, `lib/crosswake`, `test`, `examples/phoenix_host/e2e`, `priv/templates/crosswake/shell/ios`, `script`  
**Files scanned:** 15  
**Pattern extraction date:** 2026-07-31
