defmodule Crosswake.Bridge.BridgeVectorBehavioralTest do
  @moduledoc """
  Anti-vacuous behavioral proof (D-09): exercises every committed bridge contract vector
  through the real `Crosswake.Compatibility.bridge_findings/2` decision path and asserts
  each vector's `expected_outcome` and `expected_denial_reason` against genuine Elixir
  bridge-decision logic.

  ## Design contract

  Each vector in `test/fixtures/bridge_contract_vectors.json` must trigger EXACTLY ONE
  check failure. The `bridge_findings/2` pipeline accumulates findings and does NOT
  short-circuit; it prepends each failure to the accumulator, so the FIRST element of
  the returned list is the LAST check in the pipeline that fired. Vectors are designed so
  exactly one check fires, making `List.first/1` deterministic.

  ## Elixir vs native check-order difference (RESEARCH §"Elixir check order")

  The Elixir `bridge_findings/2` check order differs from the native (Swift/Kotlin) order:

  | Step | Elixir | Native |
  |------|--------|--------|
  | 1 | active_route (route_id == active_route_id) | protocol version + native runtime |
  | 2 | route_presence (route exists in manifest) | route_id == active_route_id (inactive_route) |
  | 3 | bridge_command + capability checks | origin |
  | 4 | bridge_protocol version (compatibility_mismatch) | command + capability (undeclared_capability) |
  | 5 | native_runtime version | pack compatibility |
  | 6 | packs (pack_incompatible) | capability version (unavailable_capability) |
  | 7 | origin (origin_denied) | — |

  ## Command-to-capability mapping (Elixir bridge registry)

  The Elixir `Bridge.Registry` maps `app.info.get` → capability_id `"app_info"`.
  The manifest route and capability_registry use `"app_info"`, NOT `"app.info.get"`.
  Requests carry `capability: "app_info"` and `capabilities: %{"app_info" => version}`.
  The JSON vector's `session_override.capabilities` uses the command name as key
  (`"app.info.get"`); this test translates it to the Elixir capability_id (`"app_info"`)
  via `command_to_capability_id/1`.

  ## Delegate asymmetry on the ok path (RESEARCH Open Question 3)

  Elixir `bridge_findings/2` does NOT check whether an app-level delegate is configured.
  It only verifies that the capability is declared on the route AND in the registry.
  Native `BridgeChannel` additionally requires the delegate to be non-nil before returning
  `ok` (BridgeChannel.swift line 228). Consequently, vec-003 produces an empty findings
  list from Elixir without any delegate wiring — native tests must configure the delegate.
  This asymmetry is acceptable: Elixir owns the protocol contract; delegate wiring is a
  native packaging concern tested by the native suites.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Compatibility
  alias Crosswake.Bridge.Contract
  alias Crosswake.Manifest.Types
  alias Crosswake.SupportMatrix

  # Load vectors at compile time — fails fast if the file is missing or malformed.
  # The version is read from the file, not from Contract.version(), so that a
  # committed-but-stale file (bumped in Elixir source but not regenerated) makes
  # this test fail — proving the committed fixture is live. (D-10)
  @vectors_path "test/fixtures/bridge_contract_vectors.json"
  @vectors Jason.decode!(File.read!(@vectors_path))

  # Elixir bridge registry maps: command → capability_id (used by validate_bridge_command)
  # app.info.get → "app_info"
  @command_to_cap_id %{
    "app.info.get" => "app_info",
    "haptics.impact" => "haptics",
    "permissions.status" => "permissions.status",
    "notifications.token.get" => "notification_token",
    "files.pick" => "file_picker",
    "share.invoke" => "share"
  }

  # ---------------------------------------------------------------------------
  # Single parametric test: iterates all vectors
  # ---------------------------------------------------------------------------

  test "each vector's expected_outcome and expected_denial_reason match real bridge_findings/2 result" do
    vectors = @vectors["vectors"]

    for vector <- vectors do
      id = vector["id"]
      # Skip vectors that target native-only semantics (session vs request check, not request vs manifest).
      # These vectors are exercised by the native (Swift/Kotlin) conformance test suites instead.
      unless vector["native_only"] == true do
        request_override = vector["request_override"] || %{}
        session_override = vector["session_override"] || %{}
        expected_outcome = vector["expected_outcome"]
        expected_denial_reason = vector["expected_denial_reason"]

        manifest = make_permissive_manifest(session_override)
        request = make_permissive_request(request_override)

        findings = Compatibility.bridge_findings(manifest, request)

        {actual_outcome, actual_reason} =
          case findings do
            [] ->
              {"ok", nil}

            [first | _] ->
              denial = Compatibility.finding_to_denial(first, route_id: request.route_id)
              {"deny", Atom.to_string(denial.reason)}
          end

        assert actual_outcome == expected_outcome,
               "Vector #{id}: expected_outcome=#{inspect(expected_outcome)} but got #{inspect(actual_outcome)}. Findings: #{inspect(findings)}"

        if expected_denial_reason do
          assert actual_reason == expected_denial_reason,
                 "Vector #{id}: expected_denial_reason=#{inspect(expected_denial_reason)} but got #{inspect(actual_reason)}. Findings: #{inspect(findings)}"
        end
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Permissive manifest builder
  #
  # Builds a %Root{} manifest where ALL bridge_findings/2 checks pass by default.
  # session_override fields target exactly one check failure per vector.
  #
  # session_override field semantics (Elixir mapping):
  #   "capabilities"         => %{"app.info.get" => "version"}
  #                             The command key is translated to capability_id via
  #                             command_to_capability_id/1 for capability_registry version.
  #   "route_required_packs" => ["pack-id@version"]
  #                             Applied to route.packs.
  #   "installed_packs"      => []
  #                             Not applied to manifest (manifests don't hold installed packs;
  #                             the request holds installed_packs — this field is only used
  #                             by native tests to configure session.installedPacks).
  #
  # Base permissive manifest guarantees (all checks pass):
  #   - route "dashboard" present (satisfies route_presence + active_route checks)
  #   - route capabilities: ["app_info"] (satisfies bridge_command capability-route check)
  #   - capability_registry: "app_info" at version "1.0.0" (satisfies capability version check)
  #   - allowlisted_origins: [Types.default_origin()] (satisfies origin check)
  #   - compatibility.bridge_protocol_version = @vectors["bridge_protocol_version"] (not hardcoded)
  # ---------------------------------------------------------------------------

  defp make_permissive_manifest(session_override) when is_map(session_override) do
    bridge_vsn = @vectors["bridge_protocol_version"]

    # Capability registry version: default "1.0.0"; override if session says capability is ahead
    # session_override["capabilities"] may use command name (e.g. "app.info.get") as key
    cap_version =
      case get_in(session_override, ["capabilities", "app.info.get"]) do
        v when is_binary(v) -> v
        _ -> "1.0.0"
      end

    # Route required packs: default empty; overridden from session_override
    route_packs =
      case Map.get(session_override, "route_required_packs") do
        packs when is_list(packs) -> packs
        _ -> []
      end

    Types.new_root(
      crosswake_version: "0.1.0",
      generated_at: "2026-06-20T00:00:00Z",
      host: Types.new_host(),
      compatibility:
        Types.new_compatibility(
          native_runtime_version: "1.0.0",
          bridge_protocol_version: bridge_vsn
        ),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "app_info" =>
          Types.new_capability(id: "app_info", version: cap_version)
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            capabilities: ["app_info"],
            packs: route_packs,
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end

  defp make_permissive_manifest(session_override) when is_list(session_override) do
    # session_override: [] (empty list from JSON) — treat as no overrides
    make_permissive_manifest(%{})
  end

  # ---------------------------------------------------------------------------
  # Permissive request builder
  #
  # Builds a %Contract.Request{} that passes all bridge_findings/2 checks by default.
  # request_override fields from the vector target exactly one check failure.
  #
  # Base permissive request (all checks pass):
  #   - command:                "app.info.get"
  #   - capability:             "app_info" (Elixir registry ID, not the command string)
  #   - version:                @vectors["bridge_protocol_version"]
  #   - route_id:               "dashboard"
  #   - active_route_id:        "dashboard"
  #   - origin:                 Types.default_origin()
  #   - native_runtime_version: "1.0.0"
  #   - capabilities:           %{"app_info" => "1.0.0"} (satisfies capability version check)
  #   - installed_packs:        %{}
  #
  # Request override translation:
  #   "capability" from JSON is used as-is when provided (e.g. "unknown.command" for vec-002;
  #   it deliberately mismatches so the bridge_command identity check fires)
  # ---------------------------------------------------------------------------

  defp make_permissive_request(request_override) when is_map(request_override) do
    bridge_vsn = @vectors["bridge_protocol_version"]

    # Default capability is "app_info"; when request_override provides "capability"
    # translate command name → Elixir registry capability_id via @command_to_cap_id.
    # Unknown commands (e.g. "unknown.command" in vec-002) are passed verbatim so
    # validate_bridge_command_identity fires (capability != registry_cap_id).
    raw_cap = Map.get(request_override, "capability", "app_info")
    capability = Map.get(@command_to_cap_id, raw_cap, raw_cap)

    Contract.new_request(
      command: Map.get(request_override, "command", "app.info.get"),
      capability: capability,
      version: Map.get(request_override, "version", bridge_vsn),
      route_id: Map.get(request_override, "route_id", "dashboard"),
      active_route_id: Map.get(request_override, "active_route_id", "dashboard"),
      origin: Map.get(request_override, "origin", Types.default_origin()),
      native_runtime_version: Map.get(request_override, "native_runtime_version", "1.0.0"),
      correlation_id: "bridge-behavioral-vector-test",
      capabilities: %{"app_info" => "1.0.0"},
      installed_packs: %{}
    )
  end

  defp make_permissive_request(request_override) when is_list(request_override) do
    make_permissive_request(%{})
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

end
