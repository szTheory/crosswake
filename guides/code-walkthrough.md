# Code walkthrough

This guide begins where the [Architecture guide](architecture.md) stops. We will keep
one real route in view while its values move from Phoenix metadata into policy, a
manifest, an activation decision, and one bounded native command.

Some excerpts show internal modules or private functions to explain the implementation.
Only documented public contracts carry API guarantees. The checked-in example hosts are
executable proof and teaching material, not library API. Every `# ...` or `// ...` marks
a deliberate cut from current source.

## Hold one route in your head

The checked-in Phoenix host declares a LiveView-owned route that may ask for native
sharing and may show cached read-only content when appropriate:

```elixir
# ...
live("/bridge-proof", CrosswakeExample.BridgeProofLive,
  crosswake: [
    id: "bridge-proof",
    runtime: :live_view,
    capabilities: ["share"],
    offline: :cached_read_only,
    security: :standard
  ]
)
# ...
```

Notice the separation already present: LiveView owns the route; `share` is one declared
affordance; cached reads do not create local mutation authority.

## 1. The router attaches policy metadata

`Crosswake.Router`'s internal `__route_options__/3` removes the Crosswake-specific option before it
delegates to Phoenix and attaches the value under route metadata:

```elixir
# ...
def __route_options__(_module, opts_ast, caller) do
  opts = __eval_keyword!(opts_ast, caller)
  {crosswake_options, phoenix_options} = Keyword.pop(opts, :crosswake)

  if is_nil(crosswake_options) do
    phoenix_options
  else
    metadata =
      phoenix_options
      |> Keyword.get(:metadata, %{})
      |> RouterMetadata.attach(crosswake_options)

    Keyword.put(phoenix_options, :metadata, metadata)
  end
end
# ...
```

Phoenix continues to own route compilation. Crosswake gains a stable metadata input
without wrapping the request lifecycle.

## 2. The policy compiler selects managed routes

`Crosswake.Policy.Compiler.compile/2` accepts a router module or route maps, partitions
managed routes, normalizes each one, and combines route-local and cross-route errors:

```elixir
# ...
def compile(source, opts \\ []) do
  routes = routes_from_source(source)
  source_module = source_module(source)

  {managed_routes, unmanaged_routes} =
    Enum.split_with(routes, fn route ->
      route
      |> route_metadata()
      |> Map.has_key?(:crosswake)
    end)

  warnings = build_warnings(unmanaged_routes, source_module, opts)

  {compiled_routes, errors} =
    Enum.reduce(managed_routes, {[], []}, fn route, {compiled, compile_errors} ->
      case normalize_route(route) do
        {:ok, compiled_route} -> {[compiled_route | compiled], compile_errors}
        {:error, error} -> {compiled, [error | compile_errors]}
      end
    end)

  # ...
end
```

Unmanaged Phoenix routes are not errors. Duplicate IDs or invalid managed declarations
become `Crosswake.Policy.Diagnostic` evidence rather than partial runtime truth.

## 3. Route normalization combines shape and meaning

`Crosswake.Policy.Route.new/1` merges defaults, asks
`Crosswake.Policy.Schema.validate/1` (backed by NimbleOptions) to validate shape, then
runs focused semantic checks before constructing the normalized struct:

```elixir
# ...
def new(options) when is_list(options) do
  options
  |> merged_options()
  |> Schema.validate()
  |> case do
    {:ok, validated} ->
      with {:ok, validated} <- validate_offline_contracts(validated),
           {:ok, validated} <- validate_gating_posture(validated),
           {:ok, validated} <- validate_entry_policy(validated),
           {:ok, validated} <- validate_commerce_declaration(validated),
           {:ok, validated} <- validate_auth_return_declaration(validated),
           {:ok, validated} <- validate_auth_posture(validated),
           {:ok, validated} <- validate_pack_requirements(validated),
           {:ok, validated} <- validate_transfer_declarations(validated) do
        {:ok, struct!(__MODULE__, validated)}
      end

    {:error, error} ->
      {:error, error}
  end
end
# ...
```

The output is a `Crosswake.Policy.Route`, not a loose option list. That gives later
builders one predictable value shape.

## 4. Cross-route semantics protect the ownership model

`Crosswake.Policy.Validator` runs the invariants that option-shape validation cannot
express:

```elixir
# ...
defp route_errors(route) do
  []
  |> validate_runtime_offline(route)
  |> validate_entry(route)
  |> validate_sync(route)
  |> validate_security(route)
  |> validate_capabilities(route)
  |> validate_commerce(route)
  |> validate_unique_list(route, :capabilities, route.capabilities)
  |> validate_unique_pack_ids(route)
  |> validate_unique_list(route, :sync, route.sync)
  |> validate_unique_transfer_ids(route)
end
# ...
```

This is where the vocabulary becomes architecture: `:live_view` plus
`offline: :local_first`, for example, is rejected because two runtimes would appear to
own mutation.

## 5. Manifest compilation is the boundary

`Crosswake.Manifest.compile/2` does not serialize router metadata directly. It compiles
policy, builds the complete root, then validates the result:

```elixir
# ...
def compile(source, opts \\ []) do
  case Compiler.compile(source, opts) do
    {:ok, %{routes: routes, warnings: warnings}} ->
      managed_routes = managed_routes(source)
      manifest = Builder.build(routes, managed_routes, opts)
      errors = Validator.validate(manifest)

      case errors do
        [] ->
          {:ok, %{manifest: manifest, warnings: warnings}}

        _ ->
          {:error,
           Diagnostic.new(module: source_module(source), errors: errors, warnings: warnings)}
      end

    {:error, diagnostic} ->
      {:error, diagnostic}
  end
end
# ...
```

The native side consumes the resulting versioned document, never Phoenix router
internals.

## 6. The builder preserves route identity

`Crosswake.Manifest.Builder` zips each normalized route with its Phoenix route record
and emits a route entry keyed by the stable Crosswake ID:

```elixir
# ...
defp route_entries(routes, managed_routes, origin) do
  routes
  |> Enum.zip(managed_routes)
  |> Map.new(fn {%Route{} = route, managed_route} ->
    path = Map.fetch!(managed_route, :path)

    entry =
      Types.new_route_entry(
        id: route.id,
        path: path,
        runtime: route.runtime,
        offline: route.offline,
        entry: route.entry,
        capabilities: route.capabilities,
        packs: route_pack_references(route.packs),
        security: route.security,
        allowlisted_origins: [origin]
        # ...
      )

    {route.id, entry}
  end)
end
# ...
```

The actual builder also carries cache/island contracts, commerce, sync, transfers,
gates, auth, and notification-open declarations. They refine this owner record.

## 7. Manifest validation checks the assembled truth

`Crosswake.Manifest.Validator.validate/1` checks top-level contract axes and then the
registries and routes that refer to them:

```elixir
# ...
def validate(%Types.Root{} = manifest) do
  []
  |> validate_top_level_sections(manifest)
  |> validate_compatibility(manifest.compatibility)
  |> validate_support_matrix(manifest.support_matrix)
  |> validate_capability_registry(manifest.capability_registry)
  |> validate_commerce_corridors(manifest.commerce_corridors)
  |> validate_routes(
    manifest.routes,
    manifest.capability_registry,
    manifest.pack_registry,
    manifest.commerce_corridors
  )
end
# ...
```

A route cannot refer to a capability, pack, transfer, or commerce corridor that the
assembled manifest cannot explain.

## 8. Serialization makes equivalent truth stable

`Crosswake.Manifest.Serializer.render/1` recursively orders map keys before Jason
encodes the document:

```elixir
# ...
def render(%Types.Root{} = manifest) do
  manifest
  |> Types.to_map()
  |> ordered()
  |> Jason.encode_to_iodata!(pretty: true)
  |> IO.iodata_to_binary()
  |> Kernel.<>("\n")
end

defp ordered(map) when is_map(map) do
  values =
    map
    |> Enum.sort_by(fn {key, _value} -> key end)
    |> Enum.map(fn {key, value} -> {key, ordered(value)} end)

  %Jason.OrderedObject{values: values}
end

defp ordered(list) when is_list(list), do: Enum.map(list, &ordered/1)
defp ordered(value), do: value
# ...
```

That deterministic byte shape keeps reviews, fixtures, and drift checks meaningful.

## 9. Activation normalizes entry and delegates the decision

`Crosswake.Shell.Activation` first creates a typed request, then resolves the requested
route and delegates compatibility and gate policy to RouteGate:

```elixir
# ...
def new_request(attrs) when is_list(attrs) do
  url = Keyword.get(attrs, :url)
  origin = Keyword.get_lazy(attrs, :origin, fn -> origin_from_url(url) end)

  struct!(Request, %{
    route_id: Keyword.get(attrs, :route_id),
    url: url,
    source: Keyword.fetch!(attrs, :source),
    origin: origin,
    manifest_source: Keyword.get(attrs, :manifest_source, :bundled),
    bridge_protocol_version: Keyword.fetch!(attrs, :bridge_protocol_version),
    native_runtime_version: Keyword.fetch!(attrs, :native_runtime_version),
    correlation_id: Keyword.fetch!(attrs, :correlation_id)
    # ...
  })
end

def resolve(%Root{} = manifest, %Request{} = request) do
  route_id = request.route_id || route_id_from_url(manifest, request.url)
  decision = RouteGate.evaluate(manifest, route_id, target_from_request(request),
    activation_source: request.source
  )

  # ...
end
```

The omitted branch maps `:allow` to the manifest route's exact runtime and maps `:deny`
to a stable `Crosswake.Shell.Denial`.

## 10. RouteGate keeps restrictions layered and fail-closed

`Crosswake.Compatibility.RouteGate.evaluate/4` converts compatibility findings at the
core boundary and combines them with direct gate and auth denials:

```elixir
# ...
def evaluate(%Root{} = manifest, route_id, %Target{} = target, opts) do
  route = Map.get(manifest.routes, route_id)
  gate_denials = prepend_gate_evaluation_findings([], route, target)
  auth_denials = prepend_auth_evaluation_denials([], route, opts, gate_denials)

  findings =
    manifest
    |> Compatibility.route_findings(route_id, target, opts)
    |> remap_commerce_corridor_findings(route)
    |> prepend_commerce_corridor_findings(route, manifest)

  compatibility_denials =
    Enum.map(
      findings,
      &Compatibility.finding_to_denial(&1, Keyword.put(opts, :route_id, route_id))
    )

  denials = gate_denials ++ auth_denials ++ compatibility_denials
  status = if(denials == [], do: :allow, else: :deny)

  %Decision{
    route_id: route_id,
    status: status,
    denial: List.first(denials),
    denials: denials,
    transition: transition_for(status, route, opts)
  }
end
# ...
```

Companions may add restrictions, but no companion result erases an existing denial.
The first denial provides the primary runtime explanation; the complete list remains
available for diagnostics.

## 11. The bridge vocabulary is closed and correlated

`Crosswake.Bridge.Contract` owns one canonical version and the request/reply envelope.
The current commands are explicit data, not arbitrary JavaScript messages:

```elixir
# ...
@protocol "crosswake.bridge"
@version "1.1.0"
@commands ~w(
  app.info.get
  haptics.impact
  permissions.status
  notifications.token.get
  share.invoke
  files.pick
  transfer.download
  transfer.export
  transfer.import
  transfer.upload.prepare
)

def version, do: @version
def commands, do: @commands

def new_request(attrs) when is_list(attrs) do
  struct!(Request, %{
    protocol: Keyword.get(attrs, :protocol, @protocol),
    version: Keyword.get(attrs, :version, @version),
    command: Keyword.fetch!(attrs, :command),
    correlation_id: Keyword.fetch!(attrs, :correlation_id)
    # ...
  })
end
# ...
```

The full request also requires capability, route, active route, origin, and native
runtime version. Replies preserve the command, route, correlation ID, status, payload,
and optional denial.

## 12. The registry proves the route declared the command

For `share.invoke`, `Crosswake.Bridge.Registry.lookup/4` first recognizes the command,
then finds the route, capability registry entry, and route declaration:

```elixir
# ...
def lookup(%Root{} = manifest, route_id, command, payload)
    when is_binary(route_id) and is_binary(command) and is_map(payload) do
  with true <- command_supported?(command) || {:error, :unsupported_command},
       %RouteEntry{} = route <- Map.get(manifest.routes, route_id) || {:error, :inactive_route} do
    lookup_entry(manifest, route, command, payload)
  else
    {:error, reason} -> {:error, reason}
  end
end

defp capability_entry(manifest, route, command, capability_id) do
  with %Capability{} = capability <-
         lookup_capability(manifest, capability_id) || {:error, :undeclared_capability},
       true <- capability_declared_on_route?(route, capability) || {:error, :undeclared_capability} do
    {:ok, %Entry{command: command, capability: capability.family,
      version: capability.version, route_id: route.id,
      allowlisted_origins: route.allowlisted_origins}}
  else
    {:error, reason} -> {:error, reason}
    false -> {:error, :undeclared_capability}
    nil -> {:error, :undeclared_capability}
  end
end
# ...
```

Active-route equality is a separate runtime defense in the Swift/Kotlin channel. The
checked-in Phoenix proof currently writes the semantic envelope into a host-owned
message-handler script. It demonstrates today's wire contract; it is not a general
application messaging API.

## 13. The companion contract stays narrow

`Crosswake.Companion` exposes callbacks that let a configured optional package validate
its dependency and restrict a route:

```elixir
# ...
@callback companion_id() :: atom()
@callback enabled?(config :: map()) :: boolean()

@callback route_gated?(route :: RouteEntry.t(), context :: Target.t()) ::
            {:deny, Finding.t()} | :pass

@callback kill_switch_active?(context :: Target.t()) :: boolean()
@callback validate_dependency() :: :ok | {:error, [module()]}
@callback report_state() :: State.t()

@optional_callbacks telemetry_events: 0,
                    forbidden_metadata_keys: 0,
                    denial_codes: 0,
                    evaluate_auth: 3,
                    auth_authority?: 0
# ...
```

Core discovers configured modules at runtime and checks optional callbacks with
`function_exported?/3`; it does not compile against a particular companion. The five
stable companion contract modules are documented by `Crosswake.Companion` itself.

## 14. Installation marks the host ownership boundary

The installer makes an explicit, idempotent marker edit. Shell generation likewise
writes a reviewable baseline once and labels it host-owned; its `--diff` path forks
before any write:

```elixir
# Crosswake.Install.Patcher
# ...
def patch_router(router_path, policy_module) do
  case File.read(router_path) do
    {:ok, contents} ->
      with {:ok, patched_contents, actions} <- ensure_install_block(contents, policy_module) do
        changed? = patched_contents != contents
        if changed?, do: File.write!(router_path, patched_contents)
        {:ok, %{router_file: router_path, changed?: changed?, actions: actions}}
      end

    {:error, reason} ->
      {:error, "could not read router file #{router_path}: #{:file.format_error(reason)}"}
  end
end

# Mix.Tasks.Crosswake.Gen.Shell
# ...
if opts[:diff] do
  Mix.shell().info("[crosswake] diff — read-only, no files changed")
  run_diff(platform, target, router, local)
else
  capabilities = fetch_capabilities(router)
  # ...
end
```

The generated host is an integration surface, not an evergreen implementation that
Crosswake may overwrite. See [Install](install.md) and
[Native shell upgrades](native_shell_upgrade.md).

## 15. Doctor reconnects source truth to operations

`Crosswake.Doctor.run/1` recompiles current truth and aggregates typed findings across
the installed system:

```elixir
# ...
def run(opts \\ []) do
  cwd = Keyword.get(opts, :cwd, File.cwd!())
  install_manifest_path =
    Path.expand(Keyword.get(opts, :install_manifest_path) || @default_install_manifest, cwd)

  {install_manifest, findings} = load_install_manifest(install_manifest_path)
  findings = findings ++ router_and_policy_findings(install_manifest, cwd)
  {manifest, findings} = compile_and_validate_manifest(findings, opts)

  {shells, bridge, support, phase_3_findings} = phase_3_posture(manifest, cwd, opts)
  {offline, phase_4_findings} = phase_4_posture(manifest)
  # ...

  %Report{
    status: if(Enum.any?(findings, &(&1.severity == :error)), do: :error, else: :ok),
    install_manifest: install_manifest,
    manifest: manifest,
    shells: shells,
    bridge: bridge,
    offline: offline,
    support: support,
    findings: findings
    # ...
  }
end
# ...
```

The report keeps install posture, compiled manifest, runtime surfaces, and findings
together so an operator can repair the right owner.

## 16. Swift consumes manifest truth before presentation

The reusable iOS shell core loads the manifest before selecting a presentation. This
excerpt shows two early fail-closed checks from `ActivationCoordinator`:

```swift
// ...
public func resolve(request: ActivationRequest, manifest: ShellManifest) -> ShellPresentation {
    guard SemVer.compatible(provides: manifest.compatibility.nativeRuntimeVersion, demands: request.nativeRuntimeVersion) else {
        return .denied(denial(
            reason: .compatibilityMismatch,
            routeID: request.routeID,
            manifest: manifest,
            message: "This route requires a newer shell binary to boot.",
            hint: "This shell binary is below the minimum native runtime version required by the server. Update to a shell at or above the requested native runtime version."
        ))
    }

    guard let route = route(for: request, manifest: manifest) else {
        return .denied(denial(
            reason: .inactiveRoute,
            routeID: request.routeID,
            manifest: manifest,
            message: "This route is not active in the bundled manifest.",
            hint: "Retry after shipping an updated shell manifest."
        ))
    }
    // ...
}
```

The full implementation also checks entry posture and packs before choosing LiveView,
an offline surface, or a native delegate.

## 17. Kotlin enforces the active route at the bridge edge

The reusable Android shell core rejects a bridge envelope that does not match the
mounted session before dispatching a command delegate:

```kotlin
// ...
private fun evaluate(
    request: BridgeRequestEnvelope,
    deferredReply: ((String) -> Unit)? = null
): String? {
    if (request.protocol != PROTOCOL ||
        !SemVer.compatible(provides = session.bridgeProtocolVersion, demands = request.version) ||
        !SemVer.compatible(provides = session.nativeRuntimeVersion, demands = request.nativeRuntimeVersion)) {
        return deny(request, "compatibility_mismatch", "Bridge protocol or runtime mismatch.", "Update the shell before retrying this bridge request.")
    }

    if (request.routeId != session.routeId || request.activeRouteId != session.routeId) {
        return deny(request, "inactive_route", "The bridge request is not scoped to the active route.", "Retry from the current active route only.")
    }
    // ...
}
```

The manifest registry and the mounted native session therefore supply independent
checks: declaration alone is not enough, and a stale page cannot borrow another route's
capability.

## Tests that state the architecture

The most useful tests read like executable design notes:

- Router and policy compiler/schema suites state metadata ownership and invalid route
  combinations.
- Manifest builder/validator suites state registry references and deterministic shape.
- Shell activation suites state owner selection, denial precedence, and transitions.
- Bridge behavioral vectors and contract-drift suites keep Elixir, fixtures, Swift, and
  Kotlin aligned.
- Companion contract-freeze and extraction guards keep the public seam narrow and core
  compile-time independent.
- Doctor and Hex-page suites keep operational truth and the published reading path
  intact.

## Choose your next reading session

- To change route authoring, read `Crosswake.Router` → `Crosswake.Policy.Route` →
  `Crosswake.Policy.Validator` and ask: *which invalid ownership combination must become
  a diagnostic?*
- To change runtime boot, read `Crosswake.Manifest` → `Crosswake.Shell.Activation` →
  `Crosswake.Compatibility.RouteGate` and ask: *which evidence permits one owner, or
  which denial stops it?*
- To change a bounded affordance, read `Crosswake.Bridge.Contract` →
  `Crosswake.Bridge.Registry` → the Swift and Kotlin bridge package surfaces and ask:
  *how do all three sides reject a stale or undeclared request?*
- To change optional integration behavior, read `Crosswake.Companion` → RouteGate → one
  companion package and ask: *does the integration only restrict core truth?*
- To change operational claims, read `Crosswake.Doctor` →
  [Support matrix](support_matrix.md) → [Telemetry](telemetry.md) and ask: *what proof
  class and rebuild posture support this statement?*

Return to the [Architecture guide](architecture.md), or continue with
[Route policy](route_policy.md), [Bridge](bridge.md), [Offline](offline.md),
[Packs](packs.md), [Companion compatibility](companion_compatibility.md), and
[Troubleshooting](troubleshooting.md).
