# Phase 139: crosswake_threadline Extraction - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 30 new/modified files
**Analogs found:** 28 / 30 (2 have no clean analog — flagged explicitly)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `packages/crosswake_threadline/mix.exs` | config | — | `packages/crosswake_chimeway/mix.exs` | exact (with `"priv"` delta) |
| `packages/crosswake_threadline/mix.lock` | config | — | `packages/crosswake_chimeway/mix.lock` | exact |
| `packages/crosswake_threadline/config/config.exs` | config | — | `packages/crosswake_chimeway/config/config.exs` | exact |
| `packages/crosswake_threadline/README.md` | doc | — | `packages/crosswake_chimeway/README.md` | role-match (s/chimeway/threadline/g) |
| `packages/crosswake_threadline/CHANGELOG.md` | doc | — | `packages/crosswake_chimeway/CHANGELOG.md` | exact |
| `packages/crosswake_threadline/LICENSE` | doc | — | `packages/crosswake_chimeway/LICENSE` | exact |
| `packages/crosswake_threadline/lib/crosswake/threadline/id.ex` | utility | — | `lib/crosswake/threadline/id.ex` | exact (move) |
| `packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex` | service | event-driven | `lib/crosswake/threadline/telemetry.ex` | exact (move) |
| `packages/crosswake_threadline/lib/crosswake/plug/threadline.ex` | middleware | request-response | `lib/crosswake/plug/threadline.ex` | exact (move) |
| `packages/crosswake_threadline/lib/crosswake/live/threadline.ex` | middleware | event-driven | `lib/crosswake/live/threadline.ex` | exact (move) |
| `packages/crosswake_threadline/lib/crosswake/audit/ledger.ex` | model | CRUD | `lib/crosswake/audit/ledger.ex` | exact (move) |
| `packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex` | utility | request-response | `lib/mix/tasks/crosswake.threadline.ex` | exact (move) |
| `packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | utility | file-I/O | `lib/mix/tasks/crosswake.gen.audit.ex` | exact (move + app_dir atom fix) |
| `packages/crosswake_threadline/priv/templates/crosswake/audit/ledger.ex.eex` | utility | file-I/O | `priv/templates/crosswake/audit/ledger.ex.eex` | exact (move + try/rescue addition) |
| `packages/crosswake_threadline/priv/templates/crosswake/audit/migration.exs.eex` | utility | file-I/O | `priv/templates/crosswake/audit/migration.exs.eex` | exact (move) |
| `packages/crosswake_threadline/test/test_helper.exs` | config | — | `packages/crosswake_chimeway/test/test_helper.exs` | exact |
| `packages/crosswake_threadline/test/crosswake/threadline/id_test.exs` | test | — | `test/crosswake/threadline/id_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs` | test | event-driven | `test/crosswake/threadline/telemetry_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/plug/threadline_test.exs` | test | request-response | `test/crosswake/plug/threadline_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/live/threadline_test.exs` | test | event-driven | `test/crosswake/live/threadline_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/audit/ledger_test.exs` | test | — | `test/crosswake/audit/ledger_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/mix/tasks/crosswake.gen.audit_test.exs` | test | file-I/O | `test/mix/tasks/crosswake.gen.audit_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/mix/tasks/crosswake.threadline_test.exs` | test | — | `test/mix/tasks/crosswake.threadline_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | test | — | `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | test | request-response | `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | test | — | `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | exact (move) |
| `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | test | event-driven | `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` | role-match (non-companion canary differs) |
| `lib/crosswake/support_matrix/support_matrix.ex` (decouple SITE 1) | service | — | **NO CLEAN ANALOG** — new pattern | no analog |
| `lib/crosswake/telemetry.ex` (decouple SITE 2) | service | event-driven | **NO CLEAN ANALOG** — new pattern | no analog |
| `release-please-config.json` | config | — | Lines 113-132 (chimeway block) | exact |
| `.release-please-manifest.json` | config | — | Line 8 (`"packages/crosswake_chimeway": "0.1.0"`) | exact |
| `.github/workflows/release-please.yml` (outputs block) | config | — | Lines 62-67 (chimeway outputs) | exact |
| `.github/workflows/release-please.yml` (publish-hex-threadline job) | config | — | Lines 432-522 (publish-hex-chimeway) | exact |
| `.github/workflows/release-please.yml` (clean-room-proof-threadline job) | config | — | Lines 1023-1059 (clean-room-proof-chimeway) | exact |
| `.github/workflows/release-please.yml` (release-as-cleanup + failure-alert patches) | config | — | Lines 1069-1156 | exact |
| `script/verify_companion_cleanroom.sh` (threadline canary patch) | utility | — | Lines 260-296 (chimeway canary) | role-match (companion-behaviour assertions must be suppressed) |
| `examples/phoenix_host/mix.exs` (add threadline path dep) | config | — | Lines 48-51 (rindle/sigra/chimeway path deps) | exact |
| `guides/companion_compatibility.md` (add threadline row) | doc | — | Chimeway row (most recent) | exact |
| `mix.exs` (add threadline test-only path dep) | config | — | `packages/crosswake_chimeway/mix.exs` line 51 (sigra test-only dep) | role-match (core-side mirror) |
| `mix.exs` (`companions.test` alias) | config | — | Lines 73-74 (chimeway lines) | exact |
| `test/crosswake/support_matrix/support_matrix_test.exs` (update frozen-literal assertions) | test | — | `test/crosswake/proof/phase54_sigra_support_truth_test.exs` (post-137 update pattern) | role-match |

---

## Pattern Assignments

### `packages/crosswake_threadline/mix.exs` (config)

**Analog:** `packages/crosswake_chimeway/mix.exs` (lines 1-83)

**Verdict: Adapt — s/chimeway/threadline/g + change `files:` to include `"priv"` + remove sigra test-only dep + update description.**

Key diffs from chimeway:

1. Module name: `CrosswakeThreadline.MixProject`
2. `app: :crosswake_threadline`, `name: "crosswake_threadline"`
3. `deps/0`: single `crosswake_dep()` call — **NO sibling companion dep** (threadline has zero dependency on sigra or chimeway, even in tests; no `{:crosswake_sigra, ...}` line)
4. `description/0`: `"Threadline audit and correlation observer for the Crosswake route-policy system."`
5. `package/0` `files:` **MUST include `"priv"`** — threadline is the only companion package that ships EEX templates

**Critical `files:` delta** (`packages/crosswake_chimeway/mix.exs` line 80):
```elixir
# chimeway (copy-from):
files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)

# threadline (target) — ADD "priv":
files: ~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)
```

**Full `deps/0` block** (chimeway lines 34-53 → threadline simplification):
```elixir
defp deps do
  [
    # D-19: core is a RUNTIME dep of the companion.
    # D-11/D-13: env-conditional resolver — see crosswake_dep/0 below.
    crosswake_dep()
    # NOTE: No sibling companion dep (THREAD-02 invariant).
    # No optional engine dep — threadline uses OTP stdlib only (:crypto, :telemetry).
    # NimbleOptions, Phoenix, Phoenix.LiveView come transitively through crosswake.
  ]
end
```

**`crosswake_dep/0` block** (copy verbatim from chimeway lines 59-62):
```elixir
defp crosswake_dep do
  if System.get_env("CROSSWAKE_RELEASE") == "1",
    do: {:crosswake, "~> 0.1"},
    else: {:crosswake, path: "../.."}
end
```

---

### Source module moves: 7 `.ex` files (THREAD-01)

**Analog for each: its current in-tree location (exact move, no code changes except `crosswake.gen.audit.ex`).**

**Verdict: Move verbatim for 6 of 7 files. `crosswake.gen.audit.ex` requires the `app_dir` atom fix.**

| Target path | Source (analog) | Change |
|---|---|---|
| `packages/crosswake_threadline/lib/crosswake/threadline/id.ex` | `lib/crosswake/threadline/id.ex` | Move verbatim |
| `packages/crosswake_threadline/lib/crosswake/threadline/telemetry.ex` | `lib/crosswake/threadline/telemetry.ex` | Move verbatim |
| `packages/crosswake_threadline/lib/crosswake/plug/threadline.ex` | `lib/crosswake/plug/threadline.ex` | Move verbatim |
| `packages/crosswake_threadline/lib/crosswake/live/threadline.ex` | `lib/crosswake/live/threadline.ex` | Move verbatim |
| `packages/crosswake_threadline/lib/crosswake/audit/ledger.ex` | `lib/crosswake/audit/ledger.ex` | Move verbatim |
| `packages/crosswake_threadline/lib/mix/tasks/crosswake.threadline.ex` | `lib/mix/tasks/crosswake.threadline.ex` | Move verbatim |
| `packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | `lib/mix/tasks/crosswake.gen.audit.ex` | Move + fix lines 23-24 |

**`crosswake.gen.audit.ex` app_dir fix** (`lib/mix/tasks/crosswake.gen.audit.ex` lines 23-24):
```elixir
# BEFORE (current in-tree):
schema_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/ledger.ex.eex")
migration_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/migration.exs.eex")

# AFTER (package-correct):
schema_template = Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/ledger.ex.eex")
migration_template = Application.app_dir(:crosswake_threadline, "priv/templates/crosswake/audit/migration.exs.eex")
```

The fallback at lines 26-27 (`if File.exists?(schema_template), do: schema_template, else: Path.join(File.cwd!(), ...)`) does not need to change — it handles the development case when `app_dir` is not yet resolved.

---

### `priv/templates/crosswake/audit/migration.exs.eex` (move)

**Analog:** `priv/templates/crosswake/audit/migration.exs.eex`

**Verdict: Move verbatim.**

---

### `priv/templates/crosswake/audit/ledger.ex.eex` (move + THREAD-02 hardening)

**Analog:** `priv/templates/crosswake/audit/ledger.ex.eex`

**Verdict: Move + add `try/rescue` pattern to the generated telemetry handler section (THREAD-02).**

The generated audit handler in the EEX template must include crash isolation so a write failure does not cause telemetry to auto-detach the handler (silent audit blackout):

```elixir
# Pattern to add to the generated telemetry handler in ledger.ex.eex:
def handle_event(event, measurements, metadata, _config) do
  try do
    # ... write audit record ...
    :ok
  rescue
    e ->
      Logger.error("Audit ledger write failed for event #{inspect(event)}: #{Exception.message(e)}")
      # Do NOT reraise — reraising causes telemetry to auto-detach this handler,
      # resulting in silent audit blackout. Return :ok to keep handler attached.
      :ok
  end
end
```

---

### Test moves (THREAD-01)

**Analog for each: its current in-tree location.**

**Verdict: Move all verbatim. No content changes — module references remain unchanged (same module names preserved).**

| Target path | Source path |
|---|---|
| `packages/crosswake_threadline/test/crosswake/threadline/id_test.exs` | `test/crosswake/threadline/id_test.exs` |
| `packages/crosswake_threadline/test/crosswake/threadline/telemetry_test.exs` | `test/crosswake/threadline/telemetry_test.exs` |
| `packages/crosswake_threadline/test/crosswake/plug/threadline_test.exs` | `test/crosswake/plug/threadline_test.exs` |
| `packages/crosswake_threadline/test/crosswake/live/threadline_test.exs` | `test/crosswake/live/threadline_test.exs` |
| `packages/crosswake_threadline/test/crosswake/audit/ledger_test.exs` | `test/crosswake/audit/ledger_test.exs` |
| `packages/crosswake_threadline/test/mix/tasks/crosswake.gen.audit_test.exs` | `test/mix/tasks/crosswake.gen.audit_test.exs` |
| `packages/crosswake_threadline/test/mix/tasks/crosswake.threadline_test.exs` | `test/mix/tasks/crosswake.threadline_test.exs` |
| `packages/crosswake_threadline/test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` |
| `packages/crosswake_threadline/test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` |
| `packages/crosswake_threadline/test/crosswake/proof/phase96_threadline_docs_contract_test.exs` | `test/crosswake/proof/phase96_threadline_docs_contract_test.exs` |

---

### `packages/crosswake_threadline/test/test_helper.exs` (config)

**Analog:** `packages/crosswake_chimeway/test/test_helper.exs` (line 1)

**Verdict: Copy verbatim.**

```elixir
ExUnit.start(exclude: [:requires_example_host, :advisory_only])
```

---

### `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` (test, event-driven)

**Analog:** `packages/crosswake_chimeway/test/crosswake/proof/phase138_chimeway_cleanroom_test.exs`

**Verdict: New content — threadline is NOT a `Crosswake.Companion` behaviour implementor. The non-vacuity proof uses module-shipment canaries (Telemetry.event_names/0, Plug.init/1, Ledger.actor_ref/2) instead of companion-registration dispatch.**

Key differences from the chimeway cleanroom test:
- **`async: true`** — threadline does NOT mutate `Application.put_env(:crosswake, :companions, ...)`. No process-global state manipulation, so async is safe (unlike chimeway which requires `async: false`).
- No `setup` block — no companion registration needed.
- Canary asserts module shipment via three distinct public APIs (Telemetry, Plug, Ledger).
- Vacuity guard asserts absence of sigra AND chimeway deps in `Mix.Project.config()[:deps]`.

```elixir
defmodule Crosswake.Proof.Phase139ThreadlineCleanroomTest do
  use ExUnit.Case, async: true
  # threadline is NOT a :companions registrant — no Application.put_env needed.
  # async: true is safe (no process-global state mutation).

  test "Threadline.Telemetry.event_names/0 returns 3 request-span events (canary: Telemetry shipped)" do
    events = Crosswake.Threadline.Telemetry.event_names()
    assert is_list(events) and length(events) == 3,
           "Threadline.Telemetry.event_names/0 must return 3 events — module may be missing from tarball"
    assert [:crosswake, :threadline, :request, :start] in events
    assert [:crosswake, :threadline, :request, :stop] in events
    assert [:crosswake, :threadline, :request, :exception] in events
  end

  test "Plug.Threadline.init/1 returns valid opts (canary: Plug shipped)" do
    opts = Crosswake.Plug.Threadline.init([])
    assert is_list(opts), "Plug.Threadline.init/1 must return a keyword list"
    assert opts[:header_name] == "x-crosswake-thread-id"
  end

  test "Audit.Ledger.actor_ref/2 returns HMAC hex string (canary: Ledger shipped)" do
    result = Crosswake.Audit.Ledger.actor_ref("test-user-id", secret: "test-secret")
    assert is_binary(result) and byte_size(result) == 64,
           "actor_ref/2 must return a 64-char hex string (SHA-256 HMAC)"
  end

  test "clean-room: no sibling companion deps (THREAD-02 vacuity guard)" do
    deps = Mix.Project.config()[:deps]
    dep_names = Enum.map(deps, fn {name, _} -> name; {name, _, _} -> name end)
    refute :crosswake_sigra in dep_names, "crosswake_threadline must NOT depend on crosswake_sigra"
    refute :crosswake_chimeway in dep_names, "crosswake_threadline must NOT depend on crosswake_chimeway"
  end
end
```

---

### `lib/crosswake/support_matrix/support_matrix.ex` — SITE 1 decoupling (NO CLEAN ANALOG)

**Analog:** NONE — this is threadline-novel new work. The nearest precedent is Phase 136 DECOUPLE-03 which created `@notification_support_truth_static` at line 263. That pattern is referenced for structure only; there is no single-file analog to copy from.

**Verdict: No analog — new pattern. Planner must treat this as genuine new work.**

What to change at `lib/crosswake/support_matrix/support_matrix.ex`:
- **Line 16:** Remove `alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry`
- **Lines 285-300 (approximately):** Convert `@audit_ledger_support_truth` (which calls `ThreadlineTelemetry.event_names()`, `ThreadlineTelemetry.metadata_keys()`, `ThreadlineTelemetry.forbidden_metadata_keys()` at module-evaluation time) to `@audit_ledger_support_truth_static` with frozen literal values:

```elixir
# REMOVE: alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry

# RENAME and FREEZE:
@audit_ledger_support_truth_static %{
  # ... all existing fields preserved ...
  telemetry: %{
    status: :shipped,
    # Frozen from Crosswake.Threadline.Telemetry — compile dep removed Phase 139.
    event_names: [
      [:crosswake, :threadline, :request, :start],
      [:crosswake, :threadline, :request, :stop],
      [:crosswake, :threadline, :request, :exception]
    ],
    metadata_keys: [:thread_id, :correlation_id, :route_id, :source],
    forbidden_metadata_keys: [
      :access_token, :actor_id, :actor_ref, :authorization_code, :credential_id,
      :device_id, :email, :id_token, :ip, :nonce, :org_id, :passkey_credential_id,
      :pkce_verifier, :provider_payload, :raw_return_to, :refresh_token, :return_to,
      :session_ref, :subject_ref, :user_agent
    ]
  }
}

def audit_ledger_support_truth, do: [@audit_ledger_support_truth_static]
```

The structural model for this conversion is `@notification_support_truth_static` at `support_matrix.ex:263` and `@auth_contract_truth_static` at `support_matrix.ex:133` — both use the same frozen-literal pattern. Read those lines before writing the threadline version to confirm field structure.

---

### `lib/crosswake/telemetry.ex` — SITE 2 decoupling (NO CLEAN ANALOG)

**Analog:** NONE — this is threadline-novel new work. There is no prior Phase that removed a static `Crosswake.Threadline.Telemetry` call from `telemetry.ex`. The comment at lines 235-237 of `telemetry.ex` explicitly deferred this to Phase 139.

**Verdict: No analog — new pattern. Planner must treat this as genuine new work.**

What to change at `lib/crosswake/telemetry.ex`:
- Expand `@baseline_forbidden_keys` from 10 keys to 21 keys (absorbing threadline's 11 unique keys)
- Replace line 245's `MapSet.new(Crosswake.Threadline.Telemetry.forbidden_metadata_keys() ++ companion_forbidden_keys)` with `MapSet.new(@baseline_forbidden_keys ++ companion_forbidden_keys)`
- Remove the "Threadline stays in-tree for Phase 136" comment at lines 235-237

```elixir
# BEFORE @baseline_forbidden_keys (10 keys):
@baseline_forbidden_keys [
  :access_token, :refresh_token, :id_token, :authorization_code, :token,
  :session_ref, :subject_ref, :actor_id, :ip, :email
]

# AFTER (21 keys — absorbs threadline's unique keys, removes static Threadline.Telemetry dep):
@baseline_forbidden_keys [
  # auth tokens (core baseline)
  :access_token, :refresh_token, :id_token, :authorization_code, :token,
  # identity anchors (core baseline)
  :session_ref, :subject_ref, :actor_id,
  # direct PII (core baseline)
  :ip, :email,
  # auth-flow and identity fields (absorbed from Threadline.Telemetry — Phase 139)
  :actor_ref, :credential_id, :device_id, :nonce, :org_id,
  :passkey_credential_id, :pkce_verifier, :provider_payload,
  :raw_return_to, :return_to, :user_agent
]

# line 244-245 becomes:
MapSet.new(@baseline_forbidden_keys ++ companion_forbidden_keys)
```

**Planner guard:** Before expanding the baseline, grep for `baseline_forbidden_metadata_keys/0` or `length.*baseline` assertions in `test/crosswake/telemetry_test.exs`. Any test asserting the list has exactly 10 keys must be updated to 21.

---

### `mix.exs` — core test-only path dep for phase133 (Pitfall 6)

**Analog:** `packages/crosswake_chimeway/mix.exs` line 51 — the sigra test-only dep added in Phase 138. Here the pattern is mirrored into CORE's `mix.exs` rather than a companion's.

**Verdict: Adapt — add test-only dep to core `mix.exs`, not a companion `mix.exs`.**

```elixir
# Add to core mix.exs deps (after chimeway or alongside other companion test deps):
{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}
```

Note the path is `"packages/crosswake_threadline"` (relative to repo root, where core `mix.exs` lives), not `"../../packages/..."` (which is the companion-relative path form used in `crosswake_chimeway/mix.exs`).

---

### `mix.exs` — `companions.test` alias update

**Analog:** Core `mix.exs` lines 73-74 (chimeway lines, added in Phase 138)

**Verdict: Copy and adapt — add two threadline lines after the chimeway lines.**

```elixir
# After chimeway lines:
"cmd --cd packages/crosswake_threadline mix deps.get",
"cmd --cd packages/crosswake_threadline mix test"
```

Also update the comment at line 58 (which lists companion package names) to include `crosswake_threadline`.

---

### `test/crosswake/support_matrix/support_matrix_test.exs` — update frozen-literal assertions (STAYS in core)

**Analog:** `test/crosswake/proof/phase54_sigra_support_truth_test.exs` (post-137 split, literals-only form)

**Verdict: Adapt — remove `alias Crosswake.Threadline.Telemetry` and replace dynamic comparisons with frozen-literal assertions.**

```elixir
# BEFORE (lines ~300-317, references Crosswake.Threadline.Telemetry module):
test "entry telemetry.forbidden_metadata_keys matches Crosswake.Threadline.Telemetry" do
  alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  assert entry.telemetry.forbidden_metadata_keys == ThreadlineTelemetry.forbidden_metadata_keys()
end

# AFTER (stays in core; no module dep — frozen literals from Phase 139):
test "entry telemetry.forbidden_metadata_keys is the frozen 20-key threadline denylist (Phase 139)" do
  [entry] = Crosswake.SupportMatrix.audit_ledger_support_truth()
  # Values frozen from Crosswake.Threadline.Telemetry in Phase 139 extraction.
  assert :actor_ref in entry.telemetry.forbidden_metadata_keys
  assert :access_token in entry.telemetry.forbidden_metadata_keys
  assert length(entry.telemetry.forbidden_metadata_keys) == 20
end
```

---

### `release-please-config.json` (add threadline block)

**Analog:** Lines 113-132 (`"packages/crosswake_chimeway"` block)

**Verdict: Copy and adapt — `s/chimeway/threadline/g` throughout. Update `_TODO_release_as` comment to reference Phase 139.**

```json
"packages/crosswake_threadline": {
  "component": "crosswake_threadline",
  "release-type": "elixir",
  "separate-pull-requests": true,
  "_TODO_release_as": "ONE-SHOT override (Phase 139 / recipe Step 12f / Pitfall 6): remove 'release-as' after the first crosswake_threadline Release PR merges, or subsequent runs keep re-targeting 0.1.0. threadline is independently versioned — intentionally NOT in the linked-versions lockstep group (D-8).",
  "release-as": "0.1.0",
  "extra-files": ["packages/crosswake_threadline/mix.exs"],
  "changelog-sections": [
    { "type": "feat",     "section": "Features" },
    { "type": "fix",      "section": "Bug Fixes" },
    { "type": "perf",     "section": "Performance Improvements" },
    { "type": "deps",     "section": "Dependencies" },
    { "type": "chore",    "section": "Miscellaneous",          "hidden": true },
    { "type": "docs",     "section": "Documentation",          "hidden": true },
    { "type": "test",     "section": "Tests",                  "hidden": true },
    { "type": "ci",       "section": "Continuous Integration", "hidden": true },
    { "type": "refactor", "section": "Refactoring",            "hidden": true },
    { "type": "build",    "section": "Build System",           "hidden": true }
  ]
}
```

---

### `.release-please-manifest.json` (add threadline entry)

**Analog:** Line 8 (`"packages/crosswake_chimeway": "0.1.0"`)

**Verdict: Copy and adapt — add after the chimeway line.**

```json
"packages/crosswake_threadline": "0.1.0"
```

---

### `.github/workflows/release-please.yml` — outputs block

**Analog:** Lines 62-67 (chimeway outputs, `s/chimeway/threadline/g`)

**Verdict: Copy and adapt.**

```yaml
# Companion: crosswake_threadline (Phase 139 — independently versioned, NOT in lockstep)
threadline_release_created: ${{ steps.release.outputs['packages/crosswake_threadline--release_created'] }}
threadline_tag_name: ${{ steps.release.outputs['packages/crosswake_threadline--tag_name'] }}
threadline_version: ${{ steps.release.outputs['packages/crosswake_threadline--version'] }}
```

---

### `.github/workflows/release-please.yml` — `publish-hex-threadline` job

**Analog:** Lines 432-522 (`publish-hex-chimeway` job, `s/chimeway/threadline/g`)

**Verdict: Copy and adapt — all `chimeway` → `threadline` substitutions. Preserve the D-8/D-07 gate comment.**

Key adapted fields (all others copy verbatim from chimeway):
- `if: ${{ needs.release-please.outputs.threadline_release_created == 'true' }}`
- `ref: ${{ needs.release-please.outputs.threadline_tag_name }}`
- Cache path: `packages/crosswake_threadline/deps` + `packages/crosswake_threadline/_build`
- Cache key: `${{ runner.os }}-threadline-${{ hashFiles('packages/crosswake_threadline/mix.lock') }}`
- All `working-directory:` steps: `packages/crosswake_threadline`
- Version grep: `packages/crosswake_threadline/mix.exs`
- Hex poll URL: `https://hex.pm/api/packages/crosswake_threadline/releases/${VERSION}`

---

### `.github/workflows/release-please.yml` — `clean-room-proof-threadline` job

**Analog:** Lines 1023-1059 (`clean-room-proof-chimeway` job, `s/chimeway/threadline/g`)

**Verdict: Copy and adapt. Final `run:` invocation becomes:**

```yaml
run: >
  bash script/verify_companion_cleanroom.sh
  crosswake_threadline
  "${{ needs.release-please.outputs.threadline_version }}"
```

Note: No ENGINE_PACKAGE argument — no-engine mode (identical to chimeway).

---

### `.github/workflows/release-please.yml` — `release-as-cleanup` patch (line 1069)

**Analog:** Lines 1069-1095 (current chimeway additions)

**Verdict: Extend `if:` condition + add strip block.**

Add to the `if:` condition at line 1069:
```yaml
|| needs.release-please.outputs.threadline_release_created == 'true'
```

Add threadline strip block after the chimeway block (after line 1095):
```bash
if [ "${{ needs.release-please.outputs.threadline_release_created }}" = "true" ]; then
  python3 script/strip_release_as.py crosswake_threadline
fi
```

---

### `.github/workflows/release-please.yml` — `release-failure-alert` patch

**Analog:** Lines 1124-1156 (chimeway additions)

**Verdict: Extend `needs:` list + add echo lines.**

Add to `needs:`:
```yaml
- publish-hex-threadline
- clean-room-proof-threadline
```

Add to issue body echo block:
```bash
echo "- publish-hex-threadline: ${{ needs.publish-hex-threadline.result }}"
echo "- clean-room-proof-threadline: ${{ needs.clean-room-proof-threadline.result }}"
```

---

### `script/verify_companion_cleanroom.sh` — threadline canary patch

**Analog:** Lines 260-296 (chimeway-specific canary block)

**Verdict: Adapt — threadline is NOT a Companion behaviour implementor. The canary pattern is completely different from chimeway. Two changes required:**

**Change 1:** Add a threadline-specific canary branch in the smoke test generation block. The chimeway canary (lines 260-296) overrides the default `enabled?(%{})` assertion. The threadline canary instead replaces the ENTIRE companion-behaviour test block with module-shipment canaries:

```bash
$(if [ "$PACKAGE" = "crosswake_threadline" ]; then cat <<'CANARYEOF'
  # threadline-specific: NOT a Crosswake.Companion behaviour implementor.
  # No enabled?/1, companion_id/0, validate_dependency/0 exist on any threadline module.
  # The canary proves the three core modules shipped in the tarball.

  test "Threadline.Telemetry.event_names/0 returns 3 request-span events (canary: Telemetry shipped)" do
    events = Crosswake.Threadline.Telemetry.event_names()
    assert is_list(events) and length(events) == 3,
           "[crosswake] Threadline.Telemetry.event_names/0 should return 3 events — " <>
             "Crosswake.Threadline.Telemetry module may be missing from tarball"
    assert [:crosswake, :threadline, :request, :start] in events
    assert [:crosswake, :threadline, :request, :stop] in events
    assert [:crosswake, :threadline, :request, :exception] in events
  end

  test "Plug.Threadline.init/1 is callable (canary: Plug shipped)" do
    opts = Crosswake.Plug.Threadline.init([])
    assert opts[:header_name] == "x-crosswake-thread-id"
  end

  test "Audit.Ledger.actor_ref/2 returns HMAC hex string (canary: Ledger shipped)" do
    result = Crosswake.Audit.Ledger.actor_ref("test-user-id", secret: "test-secret")
    assert is_binary(result) and byte_size(result) == 64
  end
CANARYEOF
fi)
```

**Change 2:** Add a guard to SUPPRESS the default companion-behaviour assertions block (`validate_dependency/0`, `companion_id/0`, `enabled?/1`) for threadline. The standard no-engine smoke test body (lines 308-328) calls these functions — they will cause `UndefinedFunctionError` for threadline. The guard pattern:

```bash
if [ "$PACKAGE" != "crosswake_threadline" ]; then
  # standard companion-behaviour assertions (validate_dependency/0, companion_id/0, enabled?/1)
  # ... existing block ...
fi
```

Planner must read the script from line 260 to line 330 to see exactly where to insert both changes before editing.

---

### `examples/phoenix_host/mix.exs` (add threadline path dep)

**Analog:** `examples/phoenix_host/mix.exs` — the chimeway line (most recently added, after sigra)

**Verdict: Copy and adapt — add after the chimeway line.**

```elixir
{:crosswake_threadline, path: "../../packages/crosswake_threadline"},
```

Also update the comment at the top of the deps block to mention `crosswake_threadline`.

---

### `guides/companion_compatibility.md` (add threadline row)

**Analog:** The chimeway row (most recently added)

**Verdict: Copy and adapt. Note threadline has no companion ID (not a `:companions` registrant) and is wired via Plug/LiveView, not the registry.**

```markdown
| `crosswake_threadline` | N/A (not a `:companions` registrant — wired via `plug Crosswake.Plug.Threadline` + `on_mount: Crosswake.Live.Threadline`) | `0.1.0` | `~> 0.1` | none (pure-OTP audit/correlation machinery; no engine dep) | [hexdocs.pm/crosswake_threadline](https://hexdocs.pm/crosswake_threadline) |
```

---

## Shared Patterns

### `async: true` for threadline ExUnit tests (DIFFERS from chimeway/sigra)

**Source:** Research finding — threadline is NOT a `:companions` registrant; no `Application.put_env(:crosswake, :companions, ...)` mutation is needed.

**Apply to:** `phase139_threadline_cleanroom_test.exs`

```elixir
use ExUnit.Case, async: true
# No setup block needed — no companion registration
```

Contrast with chimeway (`async: false`, requires `setup` + `on_exit`).

### `CROSSWAKE_RELEASE=1` env var for publish jobs

**Source:** `.github/workflows/release-please.yml` line 447 (`publish-hex-chimeway`)

```yaml
env:
  CROSSWAKE_RELEASE: "1"
```

**Apply to:** `publish-hex-threadline` job — activates `crosswake_dep/0` to emit `{:crosswake, "~> 0.1"}` rather than path dep in the tarball.

### Per-component output gate (not aggregate `releases_created`)

**Source:** `.github/workflows/release-please.yml` lines 435-439

```yaml
# D-8 / D-07: Gate on the PER-COMPONENT output, never the aggregate `releases_created`.
# `releases_created` is true if ANY package released — gating on it would publish the
# companion on every core-only release. `chimeway_release_created` is set only when
# release-please cuts a crosswake_chimeway release PR.
if: ${{ needs.release-please.outputs.chimeway_release_created == 'true' }}
```

**Apply to:** `publish-hex-threadline` and `clean-room-proof-threadline` — use `threadline_release_created`, never `releases_created`.

### No-engine mode for `verify_companion_cleanroom.sh`

**Source:** Chimeway CI job invocation at `release-please.yml` lines 1056-1059

```yaml
run: >
  bash script/verify_companion_cleanroom.sh
  crosswake_chimeway
  "${{ needs.release-please.outputs.chimeway_version }}"
```

**Apply to:** `clean-room-proof-threadline` job — invoke as `bash script/verify_companion_cleanroom.sh crosswake_threadline "${{ ... }}"` (no ENGINE_PACKAGE argument → no-engine mode, identical to chimeway).

### Zero-sibling-dep invariant grep (structural test gate)

**Source:** RESEARCH.md § Zero-Sibling-Dep Verification

```bash
grep -rn "Crosswake\.Companions\.Sigra\|crosswake_sigra\|Crosswake\.Companions\.Chimeway\|crosswake_chimeway" \
  packages/crosswake_threadline/lib/ && echo FAIL || echo CLEAN
```

**Apply to:** Wave 1 commit gate. Unlike chimeway (which needed a `files: allowlist` for a test-only sigra dep), threadline has zero sibling deps anywhere — no allowlist needed.

### Core compile gate (structural test gate — threadline-novel)

After both core decoupling changes (support_matrix SITE 1 + telemetry SITE 2), gate Wave 1 with:

```bash
mix compile --warnings-as-errors
```

Run from repo root. A compile failure here means one of the two decoupling changes is incomplete.

---

## No Analog Found

Two files have no clean analog in the codebase. The planner must treat these as genuine new work requiring careful implementation, not copy-paste:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/crosswake/support_matrix/support_matrix.ex` (SITE 1 decoupling) | service | — | No prior phase removed a static `@module_attribute` calling `Crosswake.Threadline.Telemetry.*()` at compile time. Nearest structural model is `@notification_support_truth_static` at line 263 and `@auth_contract_truth_static` at line 133 (same pattern, applied to different data), but no direct copy source. Planner must read lines 263-300 of `support_matrix.ex` before writing the frozen-literal conversion. |
| `lib/crosswake/telemetry.ex` (SITE 2 decoupling) | service | event-driven | No prior phase expanded `@baseline_forbidden_keys` or removed a static `Crosswake.Threadline.Telemetry.forbidden_metadata_keys()` call. The fix is well-specified in RESEARCH.md but there is no existing codebase example to copy from. Planner must audit `telemetry_test.exs` for any assertion that freezes the baseline list length at 10 before expanding to 21. |

---

## Key Differences from Chimeway (Phase 138)

| Aspect | Chimeway (Phase 138) | Threadline (Phase 139) |
|--------|----------------------|------------------------|
| Companion behaviour implementor | YES — `@behaviour Crosswake.Companion`, has `companion_id/0`, `enabled?/1`, `route_gated?/2`, `validate_dependency/0` | NO — not a `:companions` registrant; wired via Plug/LiveView |
| Clean-room proof `async:` | `async: false` (needs `Application.put_env`) | `async: true` (no env mutation needed) |
| Clean-room non-vacuity mechanism | Telemetry aggregation (`ChimewayTelemetry.event_names()` in core catalog) | Module-shipment canaries (Telemetry.event_names/0, Plug.init/1, Ledger.actor_ref/2) |
| `verify_companion_cleanroom.sh` smoke test | Overrides `enabled?(%{})` assertion to `assert` (true) instead of `refute` | SUPPRESSES all companion-behaviour assertions; substitutes module-shipment canaries |
| Sibling dep in package | `{:crosswake_sigra, path: "...", only: :test}` (for phase71 proof test) | NONE — zero sibling deps anywhere |
| `files:` in `package/0` | `~w(lib mix.exs README.md LICENSE CHANGELOG.md)` | `~w(lib priv mix.exs README.md LICENSE CHANGELOG.md)` — **`"priv"` required** |
| Source files to move | 7 sub-modules + companion facade (`companions/chimeway.ex` + `companions/chimeway/*.ex`) | 7 source files (`threadline/*.ex`, `plug/threadline.ex`, `live/threadline.ex`, `audit/ledger.ex`, 2 mix tasks) — no companion facade |
| Template files | None | 2 EEX templates in `priv/templates/crosswake/audit/` |
| `app_dir` atom fix | Not applicable | `app_dir(:crosswake → :crosswake_threadline)` in `gen.audit.ex` lines 23-24 |
| Core decoupling sites | None (chimeway was not compile-coupled into core at SITE level) | 2 sites: `support_matrix.ex:16,285-300` (SITE 1) + `telemetry.ex:245` (SITE 2) |
| Core test-only dep addition | Added `{:crosswake_sigra, ..., only: :test}` to `crosswake_chimeway/mix.exs` | Add `{:crosswake_threadline, path: "packages/crosswake_threadline", only: :test}` to **core** `mix.exs` (for phase133) |
| `StubAbsentCompanion` | `StubChimewayAbsentCompanion` (implements `@behaviour Crosswake.Companion`) | NOT needed — threadline is not a companion |
| Finding-boundary refactor | Not required | Not required |

---

## Metadata

**Analog search scope:** `packages/crosswake_chimeway/`, `packages/crosswake_sigra/`, `lib/crosswake/support_matrix/support_matrix.ex`, `lib/crosswake/telemetry.ex`, `lib/mix/tasks/crosswake.gen.audit.ex`, `.github/workflows/release-please.yml`, `release-please-config.json`, `.release-please-manifest.json`, `script/verify_companion_cleanroom.sh`, `examples/phoenix_host/mix.exs`, `guides/companion_compatibility.md`, `mix.exs`
**Files scanned:** 14
**Pattern extraction date:** 2026-07-02
