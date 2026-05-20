# Phase 8: Selective Native Flow Exemplar - Pattern Map

**Mapped:** 2026-05-18  
**Files analyzed:** 20 implied new/modified files  
**Analogs found:** 20 / 20

This map is planning-oriented. The exact Selective Native module names remain discretionary per [08-CONTEXT.md](/Users/jon/projects/crosswake/.planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md:74), but the repository patterns are already clear: compose the existing shared-host lane structure from Phase 7 with the native-capture, pack, transfer, and shell-proof substrate from Phase 5.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/phoenix_host/lib/crosswake_example/router.ex` | route | request-response | `examples/phoenix_host/lib/crosswake_example/router.ex` | exact |
| `examples/phoenix_host/lib/crosswake_example/selective_native/fixtures.ex` | utility | transform | `examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/selective_native/claims.ex` | service | CRUD | `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/selective_native/claims_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/approvals_live.ex` | role-match |
| `examples/phoenix_host/lib/crosswake_example/selective_native/claim_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/account_live.ex` | partial |
| `examples/phoenix_host/lib/crosswake_example/selective_native/capture_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/router.ex` native `/camera` route plus `CrosswakeExample.CameraLive` | compose |
| `examples/phoenix_host/lib/crosswake_example/selective_native/review_live.ex` | component | request-response | `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` | role-match |
| `examples/phoenix_host/README.md` | config | transform | `examples/phoenix_host/README.md` | exact |
| `guides/adopter_profiles.md` | docs | transform | `guides/adopter_profiles.md` | exact |
| `guides/packs.md` | docs | transform | `guides/packs.md` | exact |
| `guides/native_shell.md` | docs | transform | `guides/native_shell.md` | exact |
| `guides/bridge.md` | docs | transform | `guides/bridge.md` | exact |
| `script/verify_adopter_profile_contract.sh` | utility | batch | `script/verify_adopter_profile_contract.sh` | exact |
| `script/verify_phase5_example_hosts.sh` | utility | batch | `script/verify_phase5_example_hosts.sh` | exact |
| `test/crosswake/proof/adopter_profile_contract_test.exs` | test | batch | `test/crosswake/proof/adopter_profile_contract_test.exs` | exact |
| `test/crosswake/proof/phase5_proof_lane_test.exs` | test | batch | `test/crosswake/proof/phase5_proof_lane_test.exs` | exact |
| `test/crosswake/proof/phase8_selective_native_lane_test.exs` | test | batch | `test/crosswake/proof/phase7_saas_lane_test.exs` | role-match |
| `examples/ios_shell_host/Fixtures/route_activation.json` | config | request-response | `examples/ios_shell_host/Fixtures/route_activation.json` | exact |
| `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift` | test | request-response | `examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift` | exact |
| `examples/android_shell_host/app/src/main/assets/route_activation.json` | config | request-response | `examples/android_shell_host/app/src/main/assets/route_activation.json` | exact |
| `examples/android_shell_host/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt` | test | request-response | `examples/android_shell_host/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt` | exact |

## Pattern Assignments

### `examples/phoenix_host/lib/crosswake_example/router.ex` and the new `CrosswakeExample.SelectiveNative.*` lane

**Primary analogs**

- [router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:97)
- [router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:100)
- [router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:127)
- [router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:77)
- [07-PATTERNS.md](/Users/jon/projects/crosswake/.planning/phases/07-phoenix-saas-portal-exemplar/07-PATTERNS.md:29)

**Router grouping pattern**

```elixir
scope "/saas", CrosswakeExample.SaaSPortal do
  pipe_through [:browser, :saas_portal]

  crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
    live_session :saas_portal,
      on_mount: [{CrosswakeExample.SaaSPortal.OnMount, :require_authenticated_member}] do
```

Use the same shape for `/native`: one dedicated scope, one `crosswake_defaults` block, one `live_session :selective_native`, then route-local overrides only where the contract changes.

**Route-local native-screen override pattern**

```elixir
live "/camera", CrosswakeExample.CameraLive, :capture,
  crosswake: [
    id: "camera",
    runtime: :native_screen,
    capabilities: [:camera],
    packs: [[id: :camera_capture_assets, version: "1.0.0", kind: :media]],
    transfers: [
      [
        id: :capture_upload,
        intent: :upload,
        source: :native_capture,
        verification: :required,
        media_types: ["image/*"]
      ]
    ],
    security: :sensitive
  ]
```

Phase 8 should copy this exact metadata composition pattern, but move it under the nested claim capture route. Keep exactly one `:native_screen` route. Keep surrounding routes in the scope on shared `:live_view` defaults.

**Planning implications**

- Copy the SaaS lane scope/session structure.
- Copy the existing native capture route-local pack, transfer, and `security: :sensitive` shape.
- Replace the public generic `/camera` demo with the canonical nested route described in [08-CONTEXT.md](/Users/jon/projects/crosswake/.planning/phases/08-selective-native-flow-exemplar/08-CONTEXT.md:25).

**Anti-patterns to block**

- A flat top-level `/camera` or `/native/capture` public route.
- Multiple native routes in the lane.
- Whole-lane pack gating instead of capture-route-only gating.

---

### `selective_native/fixtures.ex`, `claims.ex`, `claims_live.ex`, `claim_live.ex`, `review_live.ex`

**Primary analogs**

- [fixtures.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/fixtures.ex:1)
- [approvals.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/approvals.ex:1)
- [approval_live.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex:11)
- [phase7_saas_lane_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase7_saas_lane_test.exs:124)

**Minimal fixture pattern**

```elixir
@account %{...}
@users [%{...}, %{...}]
@approvals [%{...}, %{...}, %{...}]

def seed do
  %{account: @account, users: @users, approvals: @approvals}
end
```

Selective Native should keep the same fixture discipline: one small route-local claim/submission fixture set, no vendor semantics, no entitlement fixture graph, no offline draft dataset.

**Minimal service boundary pattern**

```elixir
def list_approvals(account_id) when is_binary(account_id) do
  Fixtures.approvals()
  |> Enum.filter(&(&1.account_id == account_id))
end

def get_approval!(id) when is_binary(id) do
  Enum.find(Fixtures.approvals(), &(&1.id == id)) ||
    raise ArgumentError, "unknown SaaS approval: #{inspect(id)}"
end
```

Copy the “small host-owned service over fixtures” pattern for claims and review state. The new lane should stay fixture-backed and Ecto-shaped in naming only; it does not need broader persistence infrastructure for Phase 8 planning.

**Review screen state-transition pattern**

```elixir
case Approvals.approve(approval, user) do
  {:ok, approved} ->
    {:noreply,
     assign(socket,
       approval: approved,
       approval_notice: "Approval confirmed by #{user.name}. Phoenix remains the authority.",
       approval_error: nil,
       bridge_request: haptics_request(approved.id)
     )}

  {:error, :forbidden} ->
    {:noreply,
     assign(socket,
       approval_notice: nil,
       approval_error: "Approver role required at the action boundary.",
       bridge_request: nil
     )}
end
```

For Phase 8, reuse the same “Phoenix remains the authority” interaction pattern, but the side effect becomes an explicit review-to-`transfer.upload.prepare` handoff, not haptics. Keep `captured locally`, `staged`, `uploaded`, and `submitted` visibly distinct in assigns and rendered copy.

**Anti-patterns to block**

- Rich domain modeling beyond route pressure.
- Multi-artifact draft state machines.
- Review UI that implies the upload already happened.

---

### `selective_native/capture_live.ex` and route-local bridge/transfer handoff

**Primary analogs**

- [approval_live.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex:94)
- [contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:9)
- [registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:17)
- [bridge.md](/Users/jon/projects/crosswake/guides/bridge.md:16)
- [packs.md](/Users/jon/projects/crosswake/guides/packs.md:52)

**Bounded request envelope pattern**

```elixir
%{
  "protocol" => @bridge_protocol,
  "version" => @bridge_capability_version,
  "command" => "haptics.impact",
  "capability" => "haptics.impact",
  "route_id" => @bridge_route_id,
  "active_route_id" => @bridge_route_id,
  "origin" => @shell_origin,
  "native_runtime_version" => "1.0.0",
  "correlation_id" => "approval-haptics-#{approval_id}",
  "capabilities" => %{"haptics.impact" => @bridge_capability_version},
  "installed_packs" => %{},
  "payload" => %{"style" => "light"}
}
```

Do not copy the haptics command itself. Copy the envelope discipline: explicit `route_id`, explicit active-route check, explicit capability key, explicit installed-pack inventory, and a semantic payload.

**Transfer seam allowlist pattern**

```elixir
@transfer_commands %{
  "transfer.import" => :import,
  "transfer.export" => :export,
  "transfer.download" => :download,
  "transfer.upload.prepare" => :upload
}
```

Phase 8 should use `transfer.upload.prepare` as the only explicit upload seam. The bridge must stay request/reply-only and semantic. No generic “upload this blob” or “continue workflow” bridge message.

**Native capture truth pattern**

```text
- Media can be captured and staged locally.
- `staged` is not the same as `transferred`.
- A captured file only becomes transferable after an explicit `transfer.upload.prepare`.
```

Copy that vocabulary directly into the lane’s UI, docs, and proof assertions.

**Anti-patterns to block**

- Generic plugin-bus messaging.
- Upload implied by capture success.
- Background or resumable upload promises.

---

### `examples/phoenix_host/README.md`

**Primary analogs**

- [README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:12)
- [README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:23)
- [README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:80)
- [README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:119)

**Shared-host contract pattern**

```markdown
- Keep one shared Phoenix host under `examples/phoenix_host`.
- Keep the checked-in iOS and Android hosts as paired proof artifacts of that same
  shared host.
- Add profile-specific routes, modules, fixtures, and proof checks inside the shared
  host instead of multiplying into separate sample apps.
```

Phase 8 should extend the Selective Native section in-place, not add a separate host README or a second sample-app narrative.

**Lane contract pattern**

```markdown
| Selective Native Flow | Capture one device-heavy artifact while the surrounding product remains Phoenix-owned | 4-6 routes | `:live_view` plus one `:native_screen` | `CrosswakeExample.SelectiveNative.*` isolates the capture route, handoff route, and review route | Keep capture fixtures route-local and generic; no entitlement or vendor fixtures | `pack_incompatible` | No billing or entitlement system, no multiple native-screen families, no generic upload fallback |
```

Update the representative routes and required seams to match the nested claim capture shape from Phase 8. Preserve the route-budget, failure-vocabulary, and non-goal framing.

**Anti-patterns to block**

- Starter-app language.
- Turning README prose into shell internals or capability demos.

---

### `guides/adopter_profiles.md`, `guides/packs.md`, `guides/native_shell.md`, `guides/bridge.md`

**Primary analogs**

- [adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:92)
- [packs.md](/Users/jon/projects/crosswake/guides/packs.md:12)
- [native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:53)
- [bridge.md](/Users/jon/projects/crosswake/guides/bridge.md:49)

**Profile-truth pattern**

```markdown
Read [guides/packs.md](...) for required
pack and transfer semantics, plus
[guides/native_shell.md](...) for
native ownership and denial behavior. Keep
[guides/support_matrix.md](...) as the status source.
```

Docs should explain the lane boundary, then route back to canonical support truth. Keep support status in `guides/support_matrix.md` and proof entry in `guides/install.md`.

**Fail-closed shell pattern**

```text
- `pack_incompatible`, `origin_denied`, `inactive_route`, and compatibility failures
  stay visible instead of degrading silently.
```

Selective Native docs should elevate `pack_incompatible` as the primary degraded-path vocabulary for capture activation, not as a generic app readiness state.

**Transfer semantics pattern**

```text
- `transfer.upload.prepare` means staged local media is ready to enter a foreground-first upload path.
```

Use that exact semantic boundary. The review screen prepares upload; it does not assert upload completion.

**Anti-patterns to block**

- Duplicating support-matrix detail.
- Describing the bridge as navigation authority.
- Collapsing pack readiness into a global app state.

---

### `script/verify_adopter_profile_contract.sh`, `script/verify_phase5_example_hosts.sh`, `test/crosswake/proof/*.exs`

**Primary analogs**

- [verify_phase5_example_hosts.sh](/Users/jon/projects/crosswake/script/verify_phase5_example_hosts.sh:8)
- [verify_adopter_profile_contract.sh](/Users/jon/projects/crosswake/script/verify_adopter_profile_contract.sh:117)
- [phase5_proof_lane_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase5_proof_lane_test.exs:23)
- [phase7_saas_lane_test.exs](/Users/jon/projects/crosswake/test/crosswake/proof/phase7_saas_lane_test.exs:36)

**Proof layering pattern**

```bash
mix test \
  test/mix/tasks/crosswake_install_test.exs \
  test/crosswake/proof/phase5_proof_lane_test.exs \
  test/crosswake/proof/adopter_profile_contract_test.exs \
  test/crosswake/proof/phase7_saas_lane_test.exs
```

Phase 8 should append its proof lane to the existing entrypoint instead of introducing a new script root.

**Contract-script pattern**

```bash
grep -Fq "pack_incompatible" "$GUIDE" || {
  echo "guide must preserve the selective-native failure vocabulary" >&2
  exit 1
}
```

Copy this style for nested route shape, staged-before-upload language, and explicit `transfer.upload.prepare` references across README/guide surfaces.

**Focused lane-test pattern**

```elixir
test "shared example host exposes exactly the locked SaaS route set under /saas" do
  assert {:ok, %{manifest: manifest}} = Manifest.compile(CrosswakeExample.Router)
  ...
end
```

Create `phase8_selective_native_lane_test.exs` as a sibling to the Phase 7 test:

- assert exactly four `/native` routes
- assert exactly one `:native_screen` route
- assert only capture has packs and upload transfer seam
- assert claim list/detail stay `security: :standard`
- assert capture and review are `security: :sensitive`
- assert staged-before-upload truth in fixtures/rendered copy

**Anti-patterns to block**

- A parallel proof harness outside `verify_phase5_example_hosts.sh`
- Assertions that only inspect docs and ignore manifest/router truth
- Tests that imply upload completion on capture

---

### Checked-in iOS and Android shell proof fixtures

**Primary analogs**

- [ActivationCoordinatorTests.swift](/Users/jon/projects/crosswake/examples/ios_shell_host/CrosswakeShellTests/ActivationCoordinatorTests.swift:42)
- [route_activation.json iOS](/Users/jon/projects/crosswake/examples/ios_shell_host/Fixtures/route_activation.json:1)
- [crosswake_manifest.json iOS](/Users/jon/projects/crosswake/examples/ios_shell_host/Fixtures/crosswake_manifest.json:55)
- [route_activation.json Android](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/main/assets/route_activation.json:1)
- [LiveViewBootInstrumentedTest.kt](/Users/jon/projects/crosswake/examples/android_shell_host/app/src/androidTest/java/dev/crosswake/shell/LiveViewBootInstrumentedTest.kt:17)

**Pack-denial fixture pattern**

```swift
guard case let .requiredPack(requiredPack) = coordinator.presentation else {
    return XCTFail("expected required pack presentation")
}

XCTAssertEqual(requiredPack.routeID, "library")
XCTAssertEqual(requiredPack.status.state, .stale)
```

That is the shell-side analog for Phase 8’s `pack_incompatible` proof. Reuse the same presentation-test structure, but target the selective-native capture route and its required pack.

**Activation request fixture pattern**

```json
{
  "declared_pack_requirements": {},
  "installed_packs": {},
  "route_id": "saas-approval",
  "url": "https://example.crosswake.invalid/saas/approvals/approval-1"
}
```

Phase 8 should add route activation fixtures that explicitly carry declared pack requirements and the nested `/native/claims/:id/capture` URL. Do not rely on hidden client state.

**Manifest fixture pattern**

```json
"camera": {
  "packs": ["camera_capture_assets@1.0.0"],
  "runtime": "native_screen",
  "security": "sensitive",
  "transfers": [{ "id": "capture_upload", "intent": "upload" }]
}
```

Copy this shape for the selective-native capture route. The shell fixtures should reflect the manifest truth, not ad hoc shell-only behavior.

**Anti-patterns to block**

- Shell fixtures that bypass manifest-declared pack requirements.
- Platform-specific route shapes that drift from the Phoenix host.
- Native tests that prove generic WebView fallback instead of fail-closed activation.

## Shared Patterns

### Shared example-host extension
**Source:** [examples/phoenix_host/README.md](/Users/jon/projects/crosswake/examples/phoenix_host/README.md:14)

Apply to all Phase 8 host work. Extend the one shared Phoenix host and paired native hosts. Do not add a new sample app or forked proof lane.

### Route-local pack and transfer truth
**Source:** [router.ex](/Users/jon/projects/crosswake/examples/phoenix_host/lib/crosswake_example/router.ex:77), [guides/packs.md](/Users/jon/projects/crosswake/guides/packs.md:31)

Apply to the capture route and review flow. Packs and transfers belong to the specific route that needs them. `staged` is not `transferred`.

### Fail-closed runtime activation
**Source:** [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:49)

Apply to docs, proof, and shell fixtures. Activation checks compatibility, origin, packs, and capabilities before runtime mount. Denials stay visible.

### Bounded bridge and semantic transfer commands
**Source:** [lib/crosswake/bridge/contract.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/contract.ex:107), [lib/crosswake/bridge/registry.ex](/Users/jon/projects/crosswake/lib/crosswake/bridge/registry.ex:101)

Apply to any native handoff. Use explicit request envelopes and semantic commands like `transfer.upload.prepare`. No generic message bus.

### Proof layering over the existing Phase 5 entrypoint
**Source:** [script/verify_phase5_example_hosts.sh](/Users/jon/projects/crosswake/script/verify_phase5_example_hosts.sh:8)

Apply to all verification work. Add Phase 8 assertions into the established script/test stack instead of creating parallel proof machinery.

### Docs route back to support truth
**Source:** [guides/adopter_profiles.md](/Users/jon/projects/crosswake/guides/adopter_profiles.md:118), [guides/native_shell.md](/Users/jon/projects/crosswake/guides/native_shell.md:102)

Apply to README and guide updates. Explain the lane boundary, then link back to `guides/support_matrix.md` and `guides/install.md`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| None | — | — | The exact Selective Native lane does not exist yet, but every required pattern already exists as a composition of the Phase 7 SaaS lane and the Phase 5 native-capture substrate. |

## Anti-Patterns To Preserve In Planning

- Do not widen the lane into billing, entitlement, OCR, scanner, or permission-broker scope.
- Do not keep the generic `/camera` demo as the public exemplar shape.
- Do not let the bridge become a workflow bus, upload broker, or navigation authority.
- Do not imply capture equals upload.
- Do not make pack readiness a whole-app mode.
- Do not add a separate proof harness or separate example app.
- Do not duplicate support truth that already belongs in `guides/support_matrix.md`.

## Metadata

**Analog search scope:** `examples/phoenix_host`, `guides`, `lib/crosswake/bridge`, `script`, `test/crosswake/proof`, checked-in iOS/Android example hosts  
**Files scanned:** 21  
**Pattern extraction date:** 2026-05-18
