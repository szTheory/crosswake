# Phase 175: Rehearsal and Publish - Pattern Map

**Mapped:** 2026-10-09
**Current planning boundary:** One distinct, bounded read-scope plan may follow Plan120. This map does not infer current candidate, permission, or policy facts and grants no read or release authority.
**Files analyzed:** 4 likely implementation/test roles; the next plan's final filenames remain planner-defined.
**Analogs found:** 4 / 4 role analogs.

The current Plan105 coordinator and collector already implement the attempt-bound read path. Reuse their patterns where the next plan requires code; do not resume or replay Plan119, transfer its spent ALLOW, or infer that Plan120 made any read. Preserve the separately gated exact-scope ALLOW, fail-closed operation accounting, and no-side-effect behavior after an uncertain split. Any new read requires its own fresh scope and displayed exact card followed by a separate exact ALLOW. Plan106 remains held; no tag action is part of this read scope.

## File Classification

| New/Modified File (likely role; names are planner-defined) | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/release_candidate/plan105_mirror_tag.ex` or a new scoped coordinator | service / operation coordinator | request-response, file-I/O, event-driven | `lib/crosswake/release_candidate/plan105_mirror_tag.ex` | exact role and flow |
| `script/release_candidate/plan105_mirror_tag_collector.mjs` or a new collector entrypoint | utility / bounded collector | request-response, transform, file-I/O | `script/release_candidate/plan105_mirror_tag_collector.mjs` | exact role and flow |
| `test/crosswake/release_candidate/plan105_mirror_tag_test.exs` or a new coordinator test | test | request-response, file-I/O | `test/crosswake/release_candidate/plan105_mirror_tag_test.exs` | exact role and flow |
| `script/release_candidate/plan105_mirror_tag_collector.test.mjs` or a new fake collector test | test | request-response, transform | `script/release_candidate/plan105_mirror_tag_collector.test.mjs` | exact role and flow |

The existing strict Mix task is a command-boundary analog if the plan changes CLI dispatch: `lib/mix/tasks/crosswake.release.mirror_tag_026.ex`. No new endpoint, scope schema, authorization, test, or filename is mandated by this map. Keep generated evidence files attempt-derived under the existing phase evidence area; do not use a latest pointer or overwrite a prior attempt.

## Pattern Assignments

### Fresh read-scope coordinator

**Analog:** `lib/crosswake/release_candidate/plan105_mirror_tag.ex` (tracked).

**Attempt and reservation pattern** (lines 47-83):

```elixir
def new_attempt do
  :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
end

def prepare(root, attempt_id) when is_binary(root) and is_binary(attempt_id) do
  root = Path.expand(root)
  evidence_root = Path.join(root, @evidence_relative)

  with true <- Regex.match?(~r/\A[0-9a-f]{32}\z/, attempt_id),
       :ok <- ensure_evidence_root(root, evidence_root, true),
       {:ok, collector_sha256} <- collector_sha256(root),
       paths <- paths(evidence_root, attempt_id),
       true <- Enum.all?(Map.values(paths), &(not File.exists?(&1))),
       scope <- build_scope(attempt_id, collector_sha256),
       :ok <- write_exclusive_synced(paths.scope, Jason.encode!(scope) <> "\n"),
       {:ok, ^scope} <- read_scope(paths.scope) do
    {:ok, %{attempt_id: attempt_id, scope: scope, paths: public_paths(paths)}}
  else
    _ -> {:error, :attempt_unavailable}
  end
end
```

For a new scope, retain fresh random attempt IDs, path confinement, collision refusal, exclusive synced creation, and readback. Bind the scope to the collector digest and exact bounded operation set. A new scope may be planned only; never use Plan119's attempt or ALLOW.

**Authorization-before-callback pattern** (lines 118-141):

```elixir
with {:ok, scope, path_set} <- load_scope(root, attempt_id),
     true <- Path.expand(authorization_path) == Path.expand(path_set.authorization),
     {:ok, authorization} <- read_json(path_set.authorization),
     true <- valid_read_authorization?(authorization, scope),
     true <- authorization["decision"] == "ALLOW",
     {:ok, "READ_ALLOWED"} <- read_allowed?(path_set, scope),
     {:ok, current_collector_hash} <- collector_sha256(Path.expand(root)),
     true <- current_collector_hash == scope["collector_sha256"],
     :ok <- append_event(path_set, scope, 3, "read-intent", "INTENT", unknown_counts(), authorization["sha256"]) do
  result = safe_collect(adapter, scope)
  seal_preflight(root, path_set, scope, authorization, result)
else
  _ -> {:error, :preflight_blocked}
end
```

Preserve this ordering: exact scope and fresh authorization must validate before collector/credential/provider callbacks or read intent. Keep read authorization separate from any future exact tag-write decision.

**Lifecycle write pattern** (lines 1596-1604 and 1862-1884):

```elixir
line = Jason.encode!(event(scope, seq, name, state, counts, result_sha256)) <> "\n"
append_synced(path_set.lifecycle, line)

case :file.open(String.to_charlist(path), [:write, :binary, :exclusive]) do
  {:ok, file} ->
    w = :file.write(file, bytes)
    s = if w == :ok, do: :file.sync(file), else: :skip
    c = if s == :ok, do: :file.close(file), else: :skip
    if w == :ok and s == :ok and c == :ok, do: :ok, else: {:error, :write_failed}
  error -> error
end
```

Record intent and observed terminal boundaries durably. If execution/receipt cannot be established, preserve `UNKNOWN`; missing evidence is not proof of zero operations.

### Bounded collector and split timeout

**Analog:** `script/release_candidate/plan105_mirror_tag_collector.mjs` (tracked).

**Stage-aware budget and existing deadline guard** (lines 763-780, 824-841):

```js
if (state.git >= MAX_GIT || Date.now() >= state.deadline) {
  stageFailure(state, "LIMIT", "OPERATION_LIMIT");
  return { started: false, exitObserved: false, status: null, stdout: Buffer.alloc(0),
    stderrNonempty: false, overflow: false, truncated: false };
}
state.git += 1;
const maxProcessMs = state.currentStage === "SUBTREE_SPLIT"
  ? MAX_SUBTREE_SPLIT_PROCESS_MS
  : MAX_PROCESS_MS;
const timeoutMs = Math.min(maxProcessMs, Math.max(1, state.deadline - Date.now()));
```

Plan120 sets `MAX_SUBTREE_SPLIT_PROCESS_MS = 240_000` while other stages retain `MAX_PROCESS_MS = 15_000`; both injected and native process paths use the same unchanged overall deadline. Reuse this exact stage-specific, clipped budget behavior. Do not relax caps for other Git stages or change the overall deadline.

**Process-result uncertainty pattern** (lines 774-779):

```js
try {
  return recordProcessResult(state, await state.processImpl(command, args, options, state, timeoutMs));
} catch {
  state.gitUnknown = true;
  const result = { started: true, exitObserved: false, status: null, stdout: Buffer.alloc(0),
    stderrNonempty: false, overflow: false, truncated: false };
  return recordProcessResult(state, result);
}
```

Keep exception details and process output out of retained diagnostics. A timeout or uncertain exit at `SUBTREE_SPLIT` ends the observation; do not retry, dry-run, or attempt a tag write.

**Injectable collector seam** (lines 905-923):

```js
export async function runPreflight(scope, {
  fetchImpl = globalThis.fetch,
  credentialProvider = configuredCredential,
  processImpl = null,
  credentialHelperImpl = credentialHelperDetails,
  mkdtempImpl = (prefix) => mkdtemp(join(tmpdir(), prefix)),
} = {}) {
  return runPreflightInternal(scope, fetchImpl, credentialProvider, processImpl,
    credentialHelperImpl, mkdtempImpl);
}
```

Use injected fakes and bounded fixed routes/operations for local proof. This seam does not authorize production transport. A later read must use a separately reviewed fresh scope and exact ALLOW.

### Fake Node tests

**Analog:** `script/release_candidate/plan105_mirror_tag_collector.test.mjs` (tracked).

**Budget, clipping, and no-start cases** (lines 861-891):

```js
assert.equal(observed.at(-1).stage, "SUBTREE_SPLIT");
assert.ok(observed.at(-1).timeoutMs > 15_000 && observed.at(-1).timeoutMs <= 240_000);
// A short remaining deadline clips the split budget.
assert.ok(observed.at(-1).timeoutMs > 0 && observed.at(-1).timeoutMs <= 1_000);
// Ordinary process keeps its cap; expired deadline never invokes the runner.
assert.equal(observed[0].timeoutMs, 15_000);
assert.deepEqual(calls, []);
```

**UNKNOWN and redaction assertions** (lines 894-911):

```js
assert.deepEqual(result.diagnostic, {
  stage_key: "SUBTREE_SPLIT",
  failure_class: "PROCESS",
  failure_code: code,
});
assert.equal(gitArgs.filter((args) => args.includes("split")).length, 1);
assert.equal(result.counts.git_operations, "UNKNOWN");
assert.equal(result.counts.dry_run_attempts, 0);
assert.equal(result.counts.tag_attempts, 0);
assert.doesNotMatch(JSON.stringify(result), /split-output-sentinel|split-error-sentinel|\/private\/|credential=/);
```

Continue the focused fake-only pattern: controlled deadlines, injected process runner, assertions for one invocation, unknown accounting, zero follow-on side effects, and sentinel redaction. Do not run tests during this mapping task.

### Coordinator ExUnit tests

**Analog:** `test/crosswake/release_candidate/plan105_mirror_tag_test.exs` (tracked).

Use `async: true`, a unique temporary root, copied collector fixture, and `on_exit` cleanup (lines 1-27). Exercise scope reservation, exact digest/authorization binding, pending/terminal inspection, and zero-operation behavior with fake adapters. Ensure any new attempt produces independent filenames and cannot overwrite prior evidence. Coordinator tests prove local validation and accounting only; they do not establish live candidate or permission facts.

### Mix task boundary, if CLI dispatch changes

**Analog:** `lib/mix/tasks/crosswake.release.mirror_tag_026.ex` (tracked).

The parser rejects invalid/positional options and dispatches enumerated Plan105 modes (lines 53-72). Each mode calls `require_plan105_options!/2`; prepare emits the attempt and scope digest (lines 162-183); preflight requires the supplied attempt and authorization path then raises a safe no-retry message on failure (lines 209-224). Preserve strict option allowlists and safe errors. Never add arbitrary host, method, token, or write authority to a read command.

## Shared Patterns

### Exact scope and separate authorization

**Sources:** `plan105_mirror_tag.ex:88-141`; `crosswake.release.mirror_tag_026.ex:196-223`.

Bind authorization to one fresh attempt and scope digest; validate the exact authorization path, decision, collector digest, and pending lifecycle before read intent. A read ALLOW covers only that read. Plan120 did not create an ALLOW or authorize a provider call.

### Fail-closed accounting and sanitized diagnostics

**Sources:** `plan105_mirror_tag_collector.mjs:763-779`; `plan105_mirror_tag_collector.test.mjs:894-911`.

Use bounded operation counts, closed diagnostic enums, and explicit `UNKNOWN` when a child outcome is uncertain. Exclude raw stdout/stderr, secret-like values, credential details, identities, and local paths from output.

### Split-only timeout

**Source:** `plan105_mirror_tag_collector.mjs:763-780,824-841`.

Only `SUBTREE_SPLIT` receives the up-to-240-second process budget, clipped to the unchanged total deadline. All other Git children remain capped at 15 seconds, and none may start after deadline expiry.

## No Analog Found

| Behavior | Reason | Planner guidance |
|---|---|---|
| A new current-candidate read receipt or current permission/policy fact | Local analogs can validate scope, execution boundaries, and sanitized evidence, but they cannot establish a fresh external fact until a separate exact ALLOW authorizes the read. | Plan only a new bounded read scope. Preserve unknowns until a later authorized observation produces independently inspected evidence. |

## Metadata

**Tracked-source gate:** `git ls-files` returned tracked paths for every source/test analog named above. No ignored install or runtime mirror paths are referenced.
**Analog search scope:** `lib/crosswake/release_candidate/`, `lib/mix/tasks/`, `script/release_candidate/`, and `test/crosswake/release_candidate/`.
**Files scanned:** Plan105 coordinator, Mix task, Node collector, Node fake tests, and coordinator ExUnit test.
**Technical carry-forward:** Plan120’s changed split timeout and fake assertions are current and applicable; older Plan92/Plan93-specific candidate claims, scopes, fixed paths, and authorizations are stale and excluded.
**Pattern extraction date:** 2026-10-09.
