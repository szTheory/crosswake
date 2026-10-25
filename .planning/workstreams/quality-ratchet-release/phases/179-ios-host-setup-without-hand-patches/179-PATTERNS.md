# Phase 179: iOS Host Setup Without Hand Patches - Pattern Map

**Mapped:** 2026-10-13  
**Source pin:** `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b` (tree `12a0f1bf3c32ecdde0326f4a288b597b11e33b06`)  
**Files analyzed:** 12 proposed implementation/test/doc outputs  
**Analogs found:** 12 / 12

All paths below describe patterns in the clean independent source pinned above. Analog paths were checked with `git ls-files` in that clone. Names marked **proposed** do not exist in the source tree yet. Preserve the recovery checkout boundary from Phase 179 context.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| **Proposed** `lib/crosswake/shell/ios_host_config.ex` | config/model | transform | `lib/crosswake/proof_lane/config.ex` | role-match |
| `lib/mix/tasks/crosswake.gen.shell.ex` | task/controller | request-response + file-I/O | same file | exact |
| **Proposed** managed-output module under `lib/crosswake/shell/` | service | file-I/O | `lib/crosswake/proof_lane/generator.ex`, `generator_fs.ex` | role-match |
| `lib/crosswake/manifest/manifest.ex`, `builder.ex`, `lib/crosswake/shell/activation.ex` | service/model | transform | same files | exact |
| **Proposed/updated** shell/proof `.pbxproj.eex` templates and managed `.xcconfig.eex` templates | config/templates | transform | existing shell and proof PBX templates | role-match |
| `test/mix/tasks/crosswake_gen_shell_test.exs` | test | file-I/O | same test + proof-lane generator tests | exact |
| `test/mix/tasks/crosswake_gen_shell_diff_test.exs` | test | file-I/O | same test | exact |
| `test/mix/tasks/crosswake_gen_proof_lane_test.exs` | test | file-I/O | same test | exact |
| **Proposed** host config/managed output and Xcode effective-settings tests | test | transform + file-I/O | proof-lane and shell generator tests | role-match |
| `lib/crosswake/support_matrix/renderer.ex`, `lib/crosswake/capability_map/renderer.ex` | renderer | transform | same files | exact |
| `guides/native_shell.md`, `guides/support_matrix.md`, `guides/capability_map.md` | documentation | transform | corresponding renderers and guide contract tests | role-match |

The phase boundary covers IOS-01–IOS-03 only. Phase 180’s twin runner and receipt are excluded. Proposed module names are implementation suggestions from research, not locked APIs.

## Pattern Assignments

### Proposed `Crosswake.Shell.IOSHostConfig` (config/model, transform)

**Analog:** `lib/crosswake/proof_lane/config.ex`

Use a closed struct, exact key allowlist, explicit validation and errors that retain a rule/key/remediation without echoing supplied private values. The existing config accepts map or keyword input and checks duplicates before converting keywords (lines 43–59); exact-key and value validation are centralized (88–123). The new config should normalize once at the Mix boundary; downstream generation receives explicit normalized values.

```elixir
@enforce_keys @keys
defstruct @enforce_keys

def normalize(input) when is_list(input) do
  with :ok <- atom_keys(input), :ok <- no_duplicates(input) do
    normalize(Map.new(input))
  end
end

def normalize(input) when is_map(input) do
  with :ok <- atom_keys(Map.to_list(input)),
       :ok <- exact_keys(input),
       :ok <- validate(input) do
    {:ok, struct!(__MODULE__, input)}
  end
end
```

### `lib/mix/tasks/crosswake.gen.shell.ex` (Mix task, request-response/file-I/O)

**Analog:** same file; configuration/task precedent: `lib/mix/tasks/crosswake.gen.proof_lane.ex`.

The task owns option parsing, environment-selected config lookup, and user-facing safe outcomes. Its existing `run/1` validates switches and dispatches `--diff` before the writing branch (lines 62–103); iOS generation resolves the candidate root and sequences template/fixture/manifest work at lines 371–391. Keep the new compile requirement/config normalization at this boundary and pass values down. Research’s illustrative `@requirements ["compile"]` is a design requirement, not current shell-task behavior.

Current ownership limitation: `generate_ios_shell/4` calls `Fixtures.export("ios")` (373) and writes those fixtures (380), while router compilation at 510–519 only extracts capability IDs. Production route truth must instead flow through `Manifest.compile/2`, builder and serializer. Existing `ensure_file/2` is missing-only (575–589), appropriate for host-owned scaffold, insufficient for managed projections.

### Proposed managed-output module (service, file-I/O)

**Analogs:** `lib/crosswake/proof_lane/generator.ex`, `lib/crosswake/proof_lane/generator_fs.ex`.

`Generator` builds desired output once, exposes separate `generate/1`, nonwriting `check/1`, and `diff/1` APIs (generator lines 34–99). `GeneratorFS` provides contained bounded reads/writes and safe destination classifications (lines 35–83). Preserve those boundaries, but the current generator is missing-only: `ensure_missing/4` never refreshes an existing path (generator lines 101–129), and its interruption seam prevents manifest promotion rather than recovering a multi-file replacement (132–138). Phase 179 needs recognized managed ownership plus staged multi-output recovery; do not copy the missing-only policy as the whole solution.

Concrete regression patterns in `test/mix/tasks/crosswake_gen_proof_lane_test.exs`: preserve edited host bytes on rerun (45–60), fail provenance checks (62–92), byte-for-byte read-only check/diff (114–134), deny incomplete interrupted generation (136–143), and verify concurrent runs (146–162). Extend with stale managed-output, ownership conflict, and recoverable mixed-generation cases.

### Manifest and activation (service/model, transform)

**Analogs:** `lib/crosswake/manifest/manifest.ex`, `builder.ex`, `lib/crosswake/shell/activation.ex`.

`Manifest.compile/2` compiles policy routes, derives managed routes, builds a typed manifest and validates it (manifest lines 17–37). `Builder.build/3` accepts explicit `:origin`, uses it to construct host truth, and puts compiled route entries into the root (builder lines 40–83). Render the result through `Manifest.render/1` (manifest lines 39–43); avoid a second serializer or mixing in `Fixtures.export/1`.

`Activation.resolve/2` evaluates a typed request against the manifest route gate and returns allow/deny (activation lines 94–124). Reuse only the static route/activation contract. Build-time activation must not manufacture session, account, scope, media, or replay authority.

### Proposed `.xcconfig` and existing PBX templates (config/templates, transform)

**Analogs:** `priv/templates/crosswake/shell/ios/CrosswakeShell.xcodeproj/project.pbxproj.eex`; `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex`.

Shell PBX declares app and unit-test targets at lines 143–178. Proof PBX declares proof app, unit-test and UI-test targets at lines 41–45; its Debug/Release settings, including current hard-coded identity and signing values, are at 71–79. The five verified target names are `CrosswakeShell`, `CrosswakeShellTests`, `CrosswakeProofLane`, `CrosswakeProofLaneTests`, and `CrosswakeProofLaneUITests`. The shell template path includes `ios/` between `shell/` and `CrosswakeShell.xcodeproj`; some research citations omit this directory and should not be copied.

Use templates for initial wiring; keep arbitrary PBX edits host-owned. Test resolved Xcode settings for each target/configuration/SDK class without supplying expected identity values as command-line overrides. Template text checks alone cannot detect higher-precedence target settings.

### Tests (test, transform/file-I/O)

**Analogs:** `test/mix/tasks/crosswake_gen_shell_test.exs`, `crosswake_gen_shell_diff_test.exs`, `crosswake_gen_shell_stamp_test.exs`, and `test/mix/tasks/crosswake_gen_proof_lane_test.exs`.

Keep existing scaffold, diff and stamp regressions. Add behavioral assertions for host config normalization; missing-only native preservation; managed-output stale/conflict/recovery behavior; no writes from check/diff; router-derived manifest and entry route; and effective Xcode values including a higher-precedence masking negative control. Do not equate rendered strings or the reference fixture with host integration proof.

### Guide updates (renderer/docs, transform)

**Analogs:** `lib/crosswake/support_matrix/renderer.ex` and `lib/crosswake/capability_map/renderer.ex`; rendered outputs `guides/support_matrix.md` and `guides/capability_map.md`.

The support renderer writes its generated Markdown and documents regeneration through `mix crosswake.docs.sync` (lines 19–35, 86–100). Capability map renderer establishes the same deterministic render/write pattern and guide owner (lines 25–53, 79–108). Update canonical source/renderer first, then regenerate rendered guides and preserve their renderer parity tests. `guides/native_shell.md` is hand-maintained; use its existing guide tests as the style/contract analog rather than inventing a new docs generation path.

## Shared Patterns

- **One config owner:** ordinary `config :crosswake, :ios_host`, selected by normal `MIX_ENV`; task normalizes after compile and passes explicit inputs. Do not call `app.config`, start the app, or fetch global config from generator functions.
- **Ownership:** preserve host-native files; create scaffold only when absent. Refresh only recognized Crosswake-managed projections. Validate every input and destination before writes; make checks/diffs inspect actual output without creating artifacts.
- **Privacy-safe diagnostics:** report safe path/field/status, cause, and one repair. Never echo origin, bundle/team values, credentials, raw `xcodebuild` output, or low-entropy hashes.
- **Truth boundaries:** selected router and origin feed canonical manifest and static activation. Fixtures remain sample/dev data. Activation remains route/runtime configuration, not runtime authority.
- **Xcode evidence:** inspect effective settings across the five template targets, Debug/Release, simulator/device SDK classes; retain only safe pass/fail categories. Settings wiring does not prove signing, installation, or physical support.
- **Documentation:** update canonical support/capability truth only if behavior changes, render via the existing docs sync path, and keep guide tests aligned.

## No Analog Found

None for the classified roles. No current analog implements replaceable managed projections with multi-file recovery or an effective Xcode settings matrix; those are new behaviors built on the bounded analogs above.

## Metadata

**Analog search scope:** Mix tasks, shell/proof-lane modules, manifest and activation, iOS templates, task tests, support/capability renderers and guides in the pinned clone.  
**Source tracked-path check:** every named source analog/template/test/renderer/guide path was verified with `git ls-files`; proposed files are explicitly labeled.  
**Pattern extraction date:** 2026-10-13

## PATTERN MAPPING COMPLETE
