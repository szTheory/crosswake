# Phase 160: Scoped Replay and Auth Safety - Pattern Map

**Mapped:** 2026-08-02  
**Files analyzed:** 20 likely created or modified files  
**Analogs found:** 19 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/offline/journal.ex` | model | CRUD | same file | exact extension |
| `lib/crosswake/offline/replay.ex` | service/contract | request-response | same file | exact extension |
| `lib/crosswake/offline/runtime.ex` | service | event-driven | same file | role-match |
| `lib/crosswake/offline/safe_observation.ex` | model/utility | transform | `lib/crosswake/offline/telemetry.ex` | role-match |
| `lib/crosswake/offline/telemetry.ex` | service | event-driven | same file | exact replacement seam |
| `test/crosswake/offline/{journal,replay,runtime,telemetry,safe_observation}_test.exs` | test | transform/request-response | existing matching offline tests | exact |
| `packages/crosswake_sigra/lib/crosswake/companions/sigra/{contracts,evaluator}.ex` | service/adapter | request-response | same files | role-match |
| `packages/crosswake_sigra/test/crosswake/companions/sigra/*_test.exs` | test | request-response | `contracts_test.exs` | exact |
| `examples/phoenix_host/priv/static/offline_study.js` | component/client service | event-driven/file-I/O | same file | exact replacement seam |
| `examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex` | controller | request-response | same file | exact replacement seam |
| `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` | service | CRUD/request-response | same file | exact replacement seam |
| `examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex` | model | CRUD | same file | exact extension |
| `examples/phoenix_host/priv/repo/migrations/*_scoped_replay*.exs` | migration | batch/CRUD | `20260518213507_create_review_events.exs` | role-match |
| `examples/phoenix_host/lib/crosswake_example/router.ex` | route/config | request-response | same file | exact extension |
| `examples/phoenix_host/{test,e2e}/**/*sync*_test.*` | test | request-response/event-driven | `e2e/offline_sync.spec.ts` | exact extension |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | utility/test support | file-I/O/event-driven | same file | exact extension |
| `lib/crosswake/proof_lane/evidence.ex` | model/utility | transform/file-I/O | same file | exact extension |
| `test/crosswake/proof_lane/evidence_test.exs` | test | transform/file-I/O | same file | exact extension |
| `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` (if extracted) | service/adapter | request-response | `Crosswake.Compatibility.RouteGate` | partial; host-specific new seam |
| `examples/phoenix_host/test/crosswake_example/local_first/replay_admission_test.exs` (if extracted) | test | request-response | existing controller/context tests | role-match |

## Pattern Assignments

### `lib/crosswake/offline/journal.ex` and `lib/crosswake/offline/replay.ex` (contract models, request-response)

**Analogs:** same files: [`journal.ex`](/Users/jon/projects/crosswake/lib/crosswake/offline/journal.ex:6) and [`replay.ex`](/Users/jon/projects/crosswake/lib/crosswake/offline/replay.ex:8).

**Struct/constructor pattern** (journal lines 9-66; replay lines 11-90):

```elixir
@enforce_keys [:id, :route_id, :sync_seam, :operation, :payload, ...]
defstruct [:id, :route_id, :sync_seam, :operation, :payload, ...]

def new_entry(attrs) when is_list(attrs) do
  struct!(Entry, %{
    id: Keyword.fetch!(attrs, :id),
    route_id: Keyword.fetch!(attrs, :route_id),
    payload: Keyword.get(attrs, :payload, %{}),
    status: Keyword.get(attrs, :status, :queued)
  })
end
```

Extend this typed, keyword-only construction style: require versioned opaque `scope_ref` on `Entry` and `Request`, copy it directly in `request_for_entry/1`, and add `:blocked` to replay outcome status. Keep sensitive maps in the transport-only serializer; do **not** reuse `to_map/1` at an observable egress.

**Sensitive transport serializer to replace at egress boundary** (journal lines 72-85; replay lines 109-133):

```elixir
def to_map(%Request{} = request) do
  %{
    "route_id" => request.route_id,
    "journal_entry_id" => request.journal_entry_id,
    "idempotency_key" => request.idempotency_key,
    "payload" => request.payload
  }
end
```

This is the wire-map pattern only. It deliberately demonstrates why a separate `SafeObservation` type is required: it contains payload and correlating references and must never feed telemetry, Logger, doctor, inspection, aggregates, or evidence.

### `lib/crosswake/offline/runtime.ex` (lifecycle fence service, event-driven)

**Analog:** [`runtime.ex`](/Users/jon/projects/crosswake/lib/crosswake/offline/runtime.ex:1).

**Existing narrow state-transform pattern** (lines 77-89):

```elixir
@spec queue_entry(StudySession.t(), Journal.Entry.t()) :: {:ok, Journal.Entry.t()}
def queue_entry(%StudySession{journal_mode: :append_only}, %Journal.Entry{} = entry) do
  {:ok, %{entry | status: :queued}}
end
```

Add lifecycle operations alongside this pure typed-contract style: persisted `inactive | active | stopping` plus monotonic epoch, exact-scope activation, fence-before-switch, and lease equality checks. Never make an API that enumerates, activates, or drains every scope.

### `lib/crosswake/offline/safe_observation.ex` and `lib/crosswake/offline/telemetry.ex` (allowlisted transform)

**Analog:** [`telemetry.ex`](/Users/jon/projects/crosswake/lib/crosswake/offline/telemetry.ex:6).

**Closed vocabulary and serializer pattern** (lines 6-17 and 67-99):

```elixir
@metadata_keys [:route_id, :runtime, :offline_mode, ...]
@terminal_outcomes [:accepted, :rejected, :conflict]

def to_map(%Event{} = event) do
  %{ "name" => Atom.to_string(event.name), "route_id" => event.route_id,
     "terminal_outcome" => event.terminal_outcome && Atom.to_string(event.terminal_outcome) }
  |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  |> Map.new()
end
```

Use the closed atoms/list-plus-explicit-map approach, but replace current unsafe metadata (`sync_seam`, `journal_entry_id`, `correlation_id`) with a versioned safe-observation structure whose constructor accepts only closed route/runtime/lifecycle/outcome/denial values and bounded measurements. Test all unknown keys/values and nested canaries before serialization; do not redact arbitrary wire maps.

### `packages/crosswake_sigra/.../evaluator.ex` and `sigra.ex` (optional backend-authority adapter)

**Analogs:** [`evaluator.ex`](/Users/jon/projects/crosswake/packages/crosswake_sigra/lib/crosswake/companions/sigra/evaluator.ex:23) and [`sigra.ex`](/Users/jon/projects/crosswake/packages/crosswake_sigra/lib/crosswake/companions/sigra.ex:75).

**Closed adapter result pattern** (evaluator lines 23-49; facade lines 81-94):

```elixir
@spec evaluate_route_auth(RouteEntry.t() | nil, AuthContext.t() | nil, keyword()) ::
        {:allow, Result.t()} | {:deny, Finding.t()}

case Evaluator.evaluate_route_auth(route, auth_context, opts) do
  {:allow, %Evaluator.Result{status: status, facts: facts}} ->
    {:allow, %{status: status, facts: facts}}
  {:deny, finding} ->
    {:deny, finding}
end
```

Follow the companion’s optional, pure backend-evidence boundary, but add a replay-specific projection that returns only `allow` or `deny` plus a closed safe class. Missing, invalid, incompatible, raised, or timed-out adapter results deny. Do not add scope/account mapping, credentials, tokens, provider values, or auth-session detail to Crosswake core.

### Phoenix host replay: controller, context, schema, migration, and router (request-response / CRUD)

**Analogs:** [`sync_controller.ex`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/local_first/sync_controller.ex:1), [`study.ex`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/local_first/study.ex:9), [`review_event.ex`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/local_first/review_event.ex:1), and [`router.ex`](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:67).

**Controller dispatch pattern** (controller lines 5-20):

```elixir
def sync(conn, %{"events" => events}) when is_list(events) do
  case Study.sync_events(events) do
    {:ok, result} -> json(conn, %{data: result})
    {:error, reason} -> conn |> put_status(:unprocessable_entity) |> json(%{error: to_string(reason)})
  end
end
```

Retain the thin controller/context separation and JSON envelope, but replace `to_string(reason)` with typed, non-echoing blocked/request-admission responses. The controller must require a closed scoped envelope and resolve backend session authority before the context receives a mutable event.

**Current bulk anti-pattern to replace** (study lines 12-50):

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert_all(:sync, ReviewEvent, Enum.reverse(valid),
  on_conflict: :nothing,
  conflict_target: :client_mutation_id,
  returning: true
)
|> Repo.transaction()
```

Do not copy its batch semantics. Preserve `Ecto.Multi` + `Repo.transaction()` ownership, but move to one event at a time: validate closed envelope, current session/scope equality, route and `gated_by`, Sigra, host authorization, then atomically record the idempotency decision and domain effect. Return explicit accepted/rejected/conflict/blocked results; only accepted is deleteable client-side.

**Schema validation style** (review event lines 15-21):

```elixir
review_event
|> cast(attrs, [:client_mutation_id, :card_id, :rating, :status])
|> validate_required([:client_mutation_id, :card_id, :rating])
|> validate_inclusion(:rating, ["good", "hard"])
|> unique_constraint(:client_mutation_id)
```

Use a host-owned schema/migration for idempotency outcome and scoped replay records if needed. Scope fields must support compound scope/local identity; neither controller error nor schema errors may echo values.

### `examples/phoenix_host/priv/static/offline_study.js` (scoped IndexedDB/replay client)

**Analog:** [`offline_study.js`](/Users/jon/projects/crosswake/examples/phoenix_host/priv/static/offline_study.js:60).

**Existing IndexedDB transaction style** (lines 60-80, 112-165):

```javascript
const request = indexedDB.open(DB_NAME, DB_VERSION);
request.onupgradeneeded = (event) => {
  const db = event.target.result;
  db.createObjectStore(STORE_MUTATIONS, { keyPath: 'id', autoIncrement: true });
};

const tx = db.transaction(STORE_MUTATIONS, 'readonly');
const store = tx.objectStore(STORE_MUTATIONS);
const request = store.getAll();
```

Migrate this one DB with a scoped compound key/index and persisted lifecycle fence. Replace `getAll()`/unscoped `count()` with APIs requiring active `scope_ref`; scope is sensitive and must never reach console/status/error strings. Read only one active scope in journal order.

**Serial response/delete shape** (lines 193-248):

```javascript
const records = await getAllMutations();
response = await fetch(configuredSyncEndpoint(), { method: 'POST', ... });
const acceptedIds = acceptedRecords.map(r => r.client_mutation_id);
await deleteAcceptedMutations(records, acceptedIds);
```

Keep the one-flight guard and `finally` reset, but dispatch a bounded exact-scope batch and re-check scope+epoch before every send and completion mutation. Remove `console.warn('Rejected mutation:', ...)` and all interpolated server/network values. A blocked result must stop the drain, retain queue data, and use calm host-owned paused copy with an accessible status region.

### Existing browser-proof seam (tests and test support)

**Analogs:** [`offline_sync.spec.ts`](/Users/jon/projects/crosswake/examples/phoenix_host/e2e/offline_sync.spec.ts:10) and [`offline_route_proof.ts`](/Users/jon/projects/crosswake/examples/phoenix_host/e2e/support/offline_route_proof.ts:42).

**Proof adapter sequencing pattern** (support lines 42-66):

```typescript
await adapter.navigate();
await context.setOffline(true);
try {
  await adapter.performMutation();
  record = await adapter.readQueuedRecord();
  mutationId = extractMutationId(record, config.mutationIdPath);
} finally {
  await context.setOffline(false);
}
await adapter.reconnect();
await adapter.assertBackendConfirmation(mutationId!);
```

Extend this existing adapter/spec instead of starting a new proof lane. Keep environment restoration in `finally`, and add two deterministic opaque fixture scopes, inactive relaunch, switch-before-send, switch-during-in-flight, Nth-event blocked halt, retained rejected/conflict, duplicate/lost-response, and canary-absence assertions. Test observation only; never retain raw outbox content or scope references in artifacts.

### `lib/crosswake/proof_lane/evidence.ex` and evidence tests (allowlisted retained evidence)

**Analog:** [`evidence.ex`](/Users/jon/projects/crosswake/lib/crosswake/proof_lane/evidence.ex:9) with [`evidence_test.exs`](/Users/jon/projects/crosswake/test/crosswake/proof_lane/evidence_test.exs:21).

**Exact schema and final-byte-scan pattern** (evidence lines 9-35, 49-56, 247-255):

```elixir
@schema_keys [:schema_version, :crosswake_version, :template_version, :commit_ref,
              :route_id, :assertion_ids, :status, :outcome, :captured_at,
              :retention_label, :device_class, :approved_hashes]
@assertion_ids ~w(browser_offline_island shell_boot auth_continuity ...)

with :ok <- atom_keys(input),
     :ok <- exact_keys(input),
     :ok <- no_sensitive_value(input),
     {:ok, hashes} <- source_hashes(input[:approved_hashes]) do
  validate_fields(Map.put(input, :approved_hashes, hashes))
end
```

Preserve the exact twelve-field schema and byte scanner. Add only named closed Phase 160 assertion IDs; do not add scope, payload, event, idempotency, auth, endpoint, flag, or free-form diagnostic fields. Use the existing negative-canary test pattern (test lines 28-43) for every new egress.

## Shared Patterns

### Fail-closed layered route/auth decisions

**Source:** [`lib/crosswake/compatibility/route_gate.ex`](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex:33)

```elixir
gate_denials = prepend_gate_evaluation_findings([], route, target)
auth_denials = prepend_auth_evaluation_denials([], route, opts, gate_denials)
denials = gate_denials ++ auth_denials ++ compatibility_denials
status = if(denials == [], do: :allow, else: :deny)
```

Apply at host route entry and immediately before each replay event. The host replay adapter must preserve the decision ordering specified in the phase and convert failures to a closed safe class, rather than returning `Denial` details or raw errors.

### Optional auth authority fails closed

**Source:** [`route_gate.ex`](/Users/jon/projects/crosswake/lib/crosswake/compatibility/route_gate.ex:270)

```elixir
[] ->
  Denial.new(reason: :dependency_missing, ...)

result =
  try do
    authority.evaluate_auth(route, auth_context, opts)
  rescue
    _ -> {:deny, Denial.new(reason: :dependency_missing, ...)}
  end
```

Use this existing optional-companion posture for `crosswake_sigra`: absence, invalid evidence, or exception denies replay; core receives no underlying identity/session/token data.

### Tests use typed contracts and deterministic fixtures

**Sources:** [`replay_test.exs`](/Users/jon/projects/crosswake/test/crosswake/offline/replay_test.exs:7), [`contracts_test.exs`](/Users/jon/projects/crosswake/packages/crosswake_sigra/test/crosswake/companions/sigra/contracts_test.exs:7), and [`offline_sync.spec.ts`](/Users/jon/projects/crosswake/examples/phoenix_host/e2e/offline_sync.spec.ts:17).

Add core unit tests beside the contract module, Sigra-only tests inside its package, host integration tests under the example host, and browser proof only through the existing Playwright support adapter. Fixtures must be opaque and synthetic; assertions must not render sensitive fixtures.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` (if extracted) | host-specific admission adapter | request-response | The repository has route activation and Sigra adapters, but no existing per-event host replay-admission callback. Use the RouteGate/Sigra patterns above while keeping Repo, session mapping, feature source, and domain authorization host-owned. |

## Metadata

**Analog search scope:** `lib/crosswake/offline`, `lib/crosswake/compatibility`, `lib/crosswake/proof_lane`, `packages/crosswake_sigra`, `examples/phoenix_host`, and matching tests  
**Files scanned:** 31 source and test files  
**Pattern extraction date:** 2026-08-02
