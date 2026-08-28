# Phase 162: Physical-iPhone Adoption Proof - Pattern Map

**Mapped:** 2026-08-04  
**Files analyzed:** 12 planned create/modify targets  
**Analogs found:** 12 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/proof_lane/evidence.ex` | model / validator | transform | `lib/crosswake/proof_lane/evidence.ex` | exact extension |
| `lib/crosswake/proof_lane/physical_iphone_preflight.ex` | service | request-response | `lib/crosswake/proof_lane/evidence.ex` | role-match |
| `lib/crosswake/proof_lane/native_promotion.ex` | service | file-I/O | `lib/crosswake/proof_lane/evidence.ex` | data-flow match |
| `test/crosswake/proof_lane/evidence_test.exs` | test | transform | `test/crosswake/proof_lane/evidence_test.exs` | exact extension |
| `test/crosswake/proof_lane/physical_iphone_preflight_test.exs` | test | request-response | `test/crosswake/proof_lane/ios_verifier_test.exs` | role-match |
| `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` | utility / driver | event-driven | `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` | exact extension |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` | test | event-driven | `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` | exact extension |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex` | test | request-response | `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex` | exact extension |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex` | service / adapter | request-response | `examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts` | role-match |
| generated Phoenix host proof fixture/adapter (`priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex`) | test / host adapter | CRUD | `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` | data-flow match |
| host study status/recovery surface (generated host-owned hook) | component | event-driven | `examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift` | role-match |
| `guides/support_matrix.md` | config / documentation | transform | `guides/support_matrix.md` | exact extension |

The generated-host paths are deliberately host-owned. Do not add a generic replication service, conflict resolver, or retained device-artifact bundle; Phase 162 supplies narrow contracts, hooks, and validators.

## Pattern Assignments

### `lib/crosswake/proof_lane/evidence.ex` and `lib/crosswake/proof_lane/native_promotion.ex` (validator/service, transform and file-I/O)

**Analog:** `lib/crosswake/proof_lane/evidence.ex`

**Closed-schema and privacy pattern** (lines 9-37):

```elixir
@schema_keys [
  :schema_version, :crosswake_version, :template_version, :commit_ref,
  :route_id, :assertion_ids, :status, :outcome, :captured_at,
  :retention_label, :device_class, :approved_hashes
]
@outcomes [:passed, :blocked, :unavailable]
@device_classes [:ios, :simulator, :unknown]
@sensitive_terms ~w(answer selected payload account customer credential password secret token
  transcript media archive endpoint device_id screenshot trace console log raw_output xcresult)
```

Extend this exact allowlist rather than adding open metadata. Add `physical_iphone`, the low-cardinality iOS runtime field, and fixed DEVICE assertion vocabulary only after the map/string decoder, sensitive-value scan, canonical serializer, and tests agree. The final artifact must continue to omit raw outputs, paths, device identifiers, `.xcresult`, and binary hashes.

**Validate before hashing/publishing** (lines 51-58, 126-144):

```elixir
with :ok <- atom_keys(input),
     :ok <- exact_keys(input),
     :ok <- no_sensitive_value(input),
     {:ok, hashes} <- source_hashes(input[:approved_hashes]) do
  validate_fields(Map.put(input, :approved_hashes, hashes))
end

with {:ok, evidence} <- normalize(candidate),
     {:ok, sources} <- promotion_sources(candidate),
     :ok <- safe_destination(destination),
     bytes = Jason.encode!(to_map(evidence)),
     :ok <- scan_bytes(bytes, @artifact_name),
     :ok <- verify_sources(evidence.approved_hashes, sources),
     :ok <- Crosswake.ProofLane.NativePromotion.publish(destination, bytes),
     :ok <- check(destination, sources) do
  :ok
end
```

Keep the required ordering: preflight before staging/reset/capture; canonical reparse + approved-source hash verification; final directory scan; native no-replace publication; post-publication recheck. `blocked` is a closed non-promoting result, never a partial evidence record.

**Canonical readback pattern** (lines 398-423):

```elixir
with {:ok, entries} <- enumerate(stage),
     :ok <- ensure_only_evidence(entries),
     {:ok, bytes} <- read_artifact(stage),
     :ok <- verify_complete_marker(stage, bytes),
     {:ok, evidence} <- decode_evidence(bytes, @artifact_name) do
  {:ok, evidence}
end
```

Promotion must reject simulator and unknown device classes and require every fixed DEVICE assertion to be passed. Preserve the existing empty-destination/no-replace ownership in `NativePromotion`; do not replace a prior dated winner.

---

### `lib/crosswake/proof_lane/physical_iphone_preflight.ex` (service, request-response)

**Analog:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex`

**Fail-closed ordered-authority pattern** (lines 15-40):

```elixir
with :ok <- valid_scope(scope_ref),
     :ok <- valid_event(event),
     {:ok, session} <- resolve(:session, conn, opts),
     :ok <- matching_scope(session, scope_ref),
     {:ok, route} <- resolve(:route, conn, opts),
     :ok <- enabled?(route, conn, opts),
     :ok <- sigra_allows?(route, session, opts),
     :ok <- domain_allows?(route, session, event, opts) do
  {:allow, %{route: route}}
else
  {:error, reason} -> {:deny, closed_reason(reason)}
  _ -> {:deny, :authority_unavailable}
end
```

Follow this `with`/closed-result posture for route row, signed host, physical destination, host fixture, media, session/scope, replay, conflict/rejection, and flag prerequisites. Normalize all exceptions to one stable non-echoing blocked rule; never expose the missing input, route, endpoint, device, or account.

**Safe callback boundary** (lines 71-84):

```elixir
case Keyword.get(opts, name) do
  fun when is_function(fun, 1) -> normalize_callback(fun.(conn))
  fun when is_function(fun, 0) -> normalize_callback(fun.())
  _ -> host_resolution(name, conn)
end
```

Use explicit host callbacks for fixture and destination discovery. The library validates the closed result only; it does not infer adopter configuration or own domain fixtures.

---

### Generated Phoenix host adapter and proof fixtures (adapter/test, request-response and CRUD)

**Analog:** `examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts`

**Typed adapter contract** (lines 8-24):

```typescript
export type ProofLaneAdapter = {
  navigate(page: Page, config: ProofLaneConfig): Promise<void>;
  performMutation(page: Page): Promise<void>;
  readQueuedRecord(page: Page, config: ProofLaneConfig): Promise<unknown>;
  reconnect(page: Page, config: ProofLaneConfig): Promise<void>;
  assertBackendConfirmation(mutationId: string, config: ProofLaneConfig): Promise<void>;
  assertOutboxEmpty(page: Page, config: ProofLaneConfig): Promise<void>;
  assertDuplicateIdempotency(mutationId: string, record: unknown, config: ProofLaneConfig): Promise<void>;
};
```

Add host-owned callbacks for approved fixture control and closed Phoenix outcomes; do not put backend authority in XCUITest/WebView or return payloads. A fixture can expose only fixed accepted/duplicate/rejected/conflict/scope-fenced/gated outcomes.

**Preserve offline state until reconnect** (lines 37-55):

```typescript
await context.setOffline(true);
try {
  await adapter.performMutation(page);
  record = await adapter.readQueuedRecord(page, config);
  mutationId = extractMutationId(record, config.mutationIdPath);
} finally {
  await context.setOffline(false);
}

await adapter.reconnect(page, config);
await adapter.assertBackendConfirmation(mutationId!, config);
await adapter.assertOutboxEmpty(page, config);
await adapter.assertDuplicateIdempotency(mutationId!, record!, config);
```

The physical driver adds terminate/relaunch without clearing storage between mutation and replay. Reset only between independent reject/conflict/session/gate cases.

**Backend authorization and error normalization** (lines 92-105, 133-156 of `replay_admission.ex`):

```elixir
if result in [:allow, true, {:ok, :allow}], do: :ok, else: {:error, :feature_disabled}
...
if result in [:allow, {:ok, :allow}], do: :ok, else: {:error, :authorization_denied}
...
defp closed_reason(_), do: :authority_unavailable
```

The generated host test must prove Plug/Phoenix admission and Ecto scoped idempotency independently from the UI. Rejected/conflict rows remain retained; never silently delete, LWW, or auto-retry them.

---

### iOS proof driver and XCUITest templates (utility/test, event-driven)

**Analog:** existing generated proof targets under `priv/templates/crosswake/proof_lane/ios/` and the reference host’s `RequiredPackView.swift`.

**Native status element and accessibility pattern** (`examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift`, lines 68-129):

```swift
Label(model.stateLabel, systemImage: statusSymbol)
    .font(.headline)
    .foregroundStyle(statusColor)
Text(model.learnerMessage)
    .font(.body)
...
.accessibilityElement(children: .combine)
.accessibilityIdentifier(model.statusAccessibilityIdentifier)
.accessibilityFocused($statusIsFocused)
.accessibilityAddTraits(.updatesFrequently)
...
.frame(minHeight: 44)
```

Copy this system-SwiftUI form for the one in-flow study status row: stable non-sensitive host test identifier, text + SF Symbol + semantic color, Dynamic Type-friendly layout, and 44pt controls. IDs must not contain routes, scopes, mutations, fixtures, or accounts.

**One VoiceOver handoff per transition** (lines 125-137):

```swift
.onChange(of: status.state) { _, _ in
    lifecycleAnnouncementSink(Self.lifecycleAccessibilityEffect(for: status))
}

return LifecycleAccessibilityEffect(
    announcement: "\(presentation.stateLabel). \(presentation.learnerMessage)",
    preserveFocus: true
)
```

Use the locked Phase 162 copy for `saved_locally`, `syncing`, `needs_attention`, and `sync_paused`; do not render technical denial reasons. The XCUITest sequence owns only device-visible/audio/relaunch/recovery assertions and emits fixed IDs/outcomes, while the Phoenix adapter records authority facts separately.

---

### `guides/support_matrix.md` (documentation/config, transform)

**Analog:** `guides/support_matrix.md`, lines 16-31 and 67-71.

```markdown
| emulator evidence | A simulator or emulator run produced advisory platform evidence. | Emulator evidence is not physical-device proof. |
| device evidence | A physical-device run produced platform evidence. | Device evidence is not backend/session authority. |
...
| ios | 17.0 | supported | supported | script/verify_generated_ios_shell.sh | ... | simulator advisory evidence remains distinct, TODO-002/adopter topology is unknown_blocking, and physical-iPhone promotion is Phase 162 only. |
```

Update only after a promoted `physical_iphone` record: one opaque route, one iOS runtime line, and explicit one-flow/iOS-only exclusions. Retain the distinction between device-local evidence and backend/session authority; do not imply Android, simulator, generic sync, or a broader iOS claim.

## Shared Patterns

### Closed outcomes and fail-closed errors

**Sources:** `lib/crosswake/proof_lane/evidence.ex` lines 23-37; `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` lines 146-156.  
**Apply to:** preflight, iOS transcript parsing, host adapter, evidence validator, and promotion.

Use finite assertion IDs/outcomes and stable non-echoing rule IDs. Rescue/catch or malformed callbacks become a closed denial/blocked result, never an inferred pass.

### Privacy-safe canonical evidence

**Source:** `lib/crosswake/proof_lane/evidence.ex` lines 175-224, 398-423.  
**Apply to:** run contract hash input, retained JSON, verifier, and proof command output.

Retain only the approved scalar fields and hashes of reviewed canonical bytes. Reparse canonical JSON and scan final bytes/directory before atomic no-replace publication.

### Dual authority and scoped replay

**Source:** `examples/phoenix_host/lib/crosswake_example/local_first/replay_admission.ex` lines 20-38 and 89-105.  
**Apply to:** generated host fixture adapter and authority evidence endpoint.

XCUITest observes user-visible local state; Phoenix recalculates session, scope, route, feature, Sigra, and domain permission immediately before applying one event. Scope mismatch/disablement must leave queued work fenced and retained.

### Accessible status recovery

**Source:** `examples/ios_shell_host/CrosswakeShell/RequiredPackView.swift` lines 80-114, 125-137.  
**Apply to:** study status/recovery hook and XCUITest selectors.

Use a contextual combined semantic element, color plus icon plus text, system Dynamic Type, 44pt controls, and a single announcement without stealing focus. Keep pack readiness separate from sync status.

## No Analog Found

| File / concern | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/crosswake/proof_lane/physical_iphone_preflight.ex` | service | request-response | No physical-device preflight exists; compose the existing closed evidence and replay-admission patterns. |
| physical-only DEVICE assertion manifest | model | transform | Existing iOS results are advisory/simulator-oriented; Phase 162 is the first promotion vocabulary. |
| sequential signed-device command | utility | event-driven | Generated iOS lane exists, but no prior real-device promotion driver may be reused as evidence. |

## Metadata

**Analog search scope:** `lib/crosswake/proof_lane`, `test/crosswake/proof_lane`, `priv/templates/crosswake/proof_lane`, `examples/phoenix_host`, `examples/ios_shell_host`, `guides/`  
**Files scanned:** 90+ candidate files; 5 primary analogs extracted  
**Pattern extraction date:** 2026-08-04
