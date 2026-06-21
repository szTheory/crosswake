defmodule Mix.Tasks.Crosswake.Contract.Gen do
  use Mix.Task

  @shortdoc "Regenerates all derived non-Elixir contract surfaces from the canonical bridge version"

  @moduledoc """
  Regenerates the four non-Elixir contract surfaces that derive from
  `Crosswake.Bridge.Contract.version()`:

    1. `examples/ios_shell_host/Fixtures/route_activation.json`
       — iOS example-host activation fixture (bridge_protocol_version axis)
    2. `examples/android_shell_host/app/src/main/assets/route_activation.json`
       — Android example-host activation fixture (bridge_protocol_version axis)
    3. `test/fixtures/bridge_contract_vectors.json`
       — Canonical bridge contract conformance vectors (seed set); consumed by Phase 123
    4. `docs/_contract_snippet.md`
       — Generated documentation snippet carrying the canonical bridge protocol version

  ## Usage

      mix crosswake.contract.gen

  ## Regenerating

  Re-run this task whenever `Crosswake.Bridge.Contract.@version` is bumped.
  The task is hermetic (network-free) and idempotent — a second consecutive run
  produces no `git diff` churn.

  DO NOT EDIT the generated files listed above by hand. Run `mix crosswake.contract.gen`
  to regenerate them.
  """

  @ios_activation_path "examples/ios_shell_host/Fixtures/route_activation.json"
  @android_activation_path "examples/android_shell_host/app/src/main/assets/route_activation.json"
  @vectors_path "test/fixtures/bridge_contract_vectors.json"
  @ios_vectors_path "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json"
  @android_vectors_path "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"
  @docs_snippet_path "docs/_contract_snippet.md"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    bridge_vsn = Crosswake.Bridge.Contract.version()
    protocol = Crosswake.Bridge.Contract.protocol()
    commands = Crosswake.Bridge.Contract.commands()
    denial_reasons = Crosswake.Shell.Denial.reasons() |> Enum.map(&Atom.to_string/1)

    write_if_changed(@ios_activation_path, ios_activation_json(bridge_vsn))
    write_if_changed(@android_activation_path, android_activation_json(bridge_vsn))
    write_if_changed(@vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
    write_if_changed(@ios_vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
    write_if_changed(@android_vectors_path, vectors_json(protocol, bridge_vsn, commands, denial_reasons))
    write_if_changed(@docs_snippet_path, docs_snippet(bridge_vsn))

    Mix.shell().info("""
    crosswake.contract.gen complete — bridge_protocol_version=#{bridge_vsn}
      #{@ios_activation_path}
      #{@android_activation_path}
      #{@vectors_path}
      #{@ios_vectors_path}
      #{@android_vectors_path}
      #{@docs_snippet_path}
    """)
  end

  # ---------------------------------------------------------------------------
  # Content builders — produce Elixir maps/lists (sorted) then Jason-encode
  # ---------------------------------------------------------------------------

  defp ios_activation_json(bridge_vsn) do
    encode_doc([
      {"_generated_by", "mix crosswake.contract.gen"},
      {"bridge_protocol_version", bridge_vsn},
      {"capabilities", [{"camera", "1.0.0"}]},
      {"correlation_id", "ios-example-capture-1"},
      {"declared_pack_requirements", [{"camera_capture_assets", "1.0.0"}]},
      {"installed_packs", [{"camera_capture_assets", "1.0.0"}]},
      {"manifest_source", "bundled"},
      {"native_runtime_version", "1.0.0"},
      {"origin", "https://example.crosswake.invalid"},
      {"route_id", "selective-native-claim-capture"},
      {"source", "cold_start"},
      {"url", "https://example.crosswake.invalid/native/claims/claim-1/capture"}
    ])
  end

  defp android_activation_json(bridge_vsn) do
    encode_doc([
      {"_generated_by", "mix crosswake.contract.gen"},
      {"bridge_protocol_version", bridge_vsn},
      {"capabilities", [{"camera", "1.0.0"}]},
      {"correlation_id", "android-example-capture-1"},
      {"declared_pack_requirements", [{"camera_capture_assets", "1.0.0"}]},
      {"installed_packs", [{"camera_capture_assets", "1.0.0"}]},
      {"manifest_source", "bundled"},
      {"native_runtime_version", "1.0.0"},
      {"origin", "https://example.crosswake.invalid"},
      {"route_id", "selective-native-claim-capture"},
      {"source", "cold_start"},
      {"url", "https://example.crosswake.invalid/native/claims/claim-1/capture"}
    ])
  end

  defp vectors_json(protocol, bridge_vsn, commands, denial_reasons) do
    encode_doc([
      {"_comment",
       "Canonical bridge contract conformance vectors. DO NOT EDIT — regenerate with: mix crosswake.contract.gen"},
      {"_generated_by", "mix crosswake.contract.gen"},
      {"_regenerate", "mix crosswake.contract.gen"},
      {"bridge_protocol_version", bridge_vsn},
      {"commands", commands},
      {"denial_reasons", denial_reasons},
      {"manifest_schema_version", "1.0.0"},
      {"native_runtime_version", "1.0.0"},
      {"protocol", protocol},
      {"vectors", seed_vectors(bridge_vsn)}
    ])
  end

  defp seed_vectors(bridge_vsn) do
    [
      [
        {"id", "vec-001-version-mismatch-deny"},
        {"description",
         "Request with a bridge_protocol_version older than the manifest floor is denied with compatibility_mismatch (Elixir: target.bridge_protocol_version < manifest.bridge_protocol_version). elixir_only: native harnesses check session-provides vs request-demands (opposite direction); vec-009 covers native bridge-version deny."},
        {"request_override", [{"version", "1.0.0"}]},
        {"session_override", []},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "compatibility_mismatch"},
        {"elixir_only", true}
      ],
      [
        {"id", "vec-002-unknown-command-deny"},
        {"description", "Request with an unrecognised command is denied"},
        {"request_override",
         [
           {"capability", "unknown.command"},
           {"command", "unknown.command"},
           {"version", bridge_vsn}
         ]},
        {"session_override", []},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "undeclared_capability"}
      ],
      [
        {"id", "vec-003-canonical-version-ok"},
        {"description",
         "Request with the canonical bridge_protocol_version and a supported command succeeds"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override", [{"capabilities", [{"app.info.get", "1.0.0"}]}]},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil}
      ],
      [
        {"id", "vec-004-inactive-route-deny"},
        {"description", "Request scoped to a different route is denied with inactive_route"},
        {"request_override",
         [
           {"active_route_id", "other-route"},
           {"capability", "app.info.get"},
           {"command", "app.info.get"},
           {"route_id", "other-route"},
           {"version", bridge_vsn}
         ]},
        {"session_override", []},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "inactive_route"}
      ],
      [
        {"id", "vec-005-origin-denied-deny"},
        {"description", "Request from non-allowlisted origin is denied with origin_denied"},
        {"request_override",
         [
           {"capability", "app.info.get"},
           {"command", "app.info.get"},
           {"origin", "https://evil.example.com"},
           {"version", bridge_vsn}
         ]},
        {"session_override", []},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "origin_denied"}
      ],
      [
        {"id", "vec-006-pack-incompatible-deny"},
        {"description",
         "Request when required pack is not installed is denied with pack_incompatible"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override",
         [{"installed_packs", []}, {"route_required_packs", ["test-pack@1.0.0"]}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "pack_incompatible"}
      ],
      [
        {"id", "vec-007-capability-version-deny"},
        {"description",
         "Request where session capability version is ahead of request is denied with unavailable_capability"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override", [{"capabilities", [{"app.info.get", "2.0.0"}]}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "unavailable_capability"}
      ],
      # --- Floor conformance vectors (D-05 / D-06) ---
      # bridge_protocol_version floor — both directions
      # native_only: session.bridgeProtocolVersion override is native-only (Elixir bridge_findings
      # checks request vs manifest semantics, not session vs request).
      [
        {"id", "vec-008-floor-bridge-shell-newer-allow"},
        {"description",
         "Shell providing a newer bridge_protocol_version satisfies a request demanding an older version (floor >=, allow)"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", "1.0.0"}]},
        {"session_override", [{"bridge_protocol_version", bridge_vsn}, {"capabilities", [{"app.info.get", "1.0.0"}]}]},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil},
        {"native_only", true}
      ],
      [
        {"id", "vec-009-floor-bridge-shell-older-deny"},
        {"description",
         "Shell providing an older bridge_protocol_version cannot satisfy a request demanding the current version (floor >=, deny)"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override", [{"bridge_protocol_version", "1.0.0"}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "compatibility_mismatch"},
        {"native_only", true}
      ],
      # native_runtime_version floor — both directions
      # native_only: session.nativeRuntimeVersion + request.native_runtime_version overrides
      # are native-only (Elixir bridge_findings manifest builder does not apply these overrides).
      [
        {"id", "vec-010-floor-native-runtime-shell-newer-allow"},
        {"description",
         "Shell providing a newer native_runtime_version satisfies a request demanding an older version (floor >=, allow)"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}, {"native_runtime_version", "1.0.0"}]},
        {"session_override", [{"native_runtime_version", "2.0.0"}, {"capabilities", [{"app.info.get", "1.0.0"}]}]},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil},
        {"native_only", true}
      ],
      [
        {"id", "vec-011-floor-native-runtime-shell-older-deny"},
        {"description",
         "Shell providing an older native_runtime_version cannot satisfy a request demanding a newer version (floor >=, deny)"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}, {"native_runtime_version", "2.0.0"}]},
        {"session_override", [{"native_runtime_version", "1.0.0"}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "compatibility_mismatch"},
        {"native_only", true}
      ],
      # capability-version floor — both directions
      # Exercised by both Elixir bridge_findings (compatible_version? on capability axis) and native.
      # NOTE: vec-012/vec-013 (manifest_schema floor) were removed — manifest_schema_version is
      # validated by the Elixir Compatibility layer (validate_manifest_schema/2) and has no native
      # bridge/session surface. Native code decodes zero manifest_schema_version fields, so those
      # vectors exercised no real native decode-to-SemVer path (phantom vectors).
      # manifest_schema floor correctness is owned by Elixir tests, not this conformance suite.
      [
        {"id", "vec-014-floor-capability-shell-newer-allow"},
        {"description",
         "Request capability version (1.1.0) newer than session floor (1.0.0) — floor semantics allow (provides=request, demands=session). This vector is DISCRIMINATING: it returns ok under >= floor but would return deny under the pre-fix == equality check, proving the floor is applied."},
        {"request_override",
         [{"capabilities", [{"app.info.get", "1.1.0"}]}, {"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override", [{"capabilities", [{"app.info.get", "1.0.0"}]}]},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil}
      ],
      [
        {"id", "vec-015-floor-capability-shell-older-deny"},
        {"description",
         "Request capability version (1.0.0) below session floor (2.0.0) — floor semantics deny (unavailable_capability). This vector is DISCRIMINATING: the request does not meet the session floor, correctly denied by both >= floor and the pre-fix == equality check."},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override", [{"capabilities", [{"app.info.get", "2.0.0"}]}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "unavailable_capability"}
      ],
      # pack-version floor — both directions
      # native_only: Elixir bridge_findings uses request.installed_packs (always empty in test
      # builder); native BridgeChannel uses session.installedPacks from session_override.
      [
        {"id", "vec-016-floor-pack-shell-newer-allow"},
        {"description",
         "Installed pack version >= required pack version — floor semantics allow"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override",
         [{"installed_packs", [{"test-pack", "2.0.0"}]}, {"route_required_packs", ["test-pack@1.0.0"]}, {"capabilities", [{"app.info.get", "1.0.0"}]}]},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil},
        {"native_only", true}
      ],
      [
        {"id", "vec-017-floor-pack-shell-older-deny"},
        {"description",
         "Installed pack version < required pack version — floor semantics deny (pack_incompatible)"},
        {"request_override",
         [{"capability", "app.info.get"}, {"command", "app.info.get"}, {"version", bridge_vsn}]},
        {"session_override",
         [{"installed_packs", [{"test-pack", "1.0.0"}]}, {"route_required_packs", ["test-pack@2.0.0"]}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "pack_incompatible"},
        {"native_only", true}
      ]
    ]
  end

  defp docs_snippet(bridge_vsn) do
    """
    <!-- DO NOT EDIT — generated by `mix crosswake.contract.gen`. -->
    <!-- Regenerate with: mix crosswake.contract.gen -->

    ## Bridge Protocol Contract

    | Axis | Version |
    |------|---------|
    | `bridge_protocol_version` | `#{bridge_vsn}` |
    | `native_runtime_version` (minimum floor) | `1.0.0` |
    | `manifest_schema_version` | `1.0.0` |

    The authoritative source is `Crosswake.Bridge.Contract.version/0` (`lib/crosswake/bridge/contract.ex`).
    Do not hand-edit this snippet — run `mix crosswake.contract.gen` to regenerate.
    """
  end

  # ---------------------------------------------------------------------------
  # Ordered JSON encoding
  #
  # We represent JSON objects as lists of {key, value} 2-tuples. Keys are sorted
  # before encoding so re-runs produce byte-identical output regardless of BEAM
  # map ordering. Jason.encode_to_iodata! is used on the final sorted structure.
  # ---------------------------------------------------------------------------

  # Top-level entry: encode a pairs list as a pretty JSON document with trailing newline.
  defp encode_doc(pairs) when is_list(pairs) do
    pairs |> pairs_to_map() |> Jason.encode!(pretty: true) |> Kernel.<>("\n")
  end

  # Recursively convert a pairs list (list of {key, value} tuples) into a sorted
  # plain Elixir map, then let Jason emit the result. The idempotency of the
  # emitted JSON depends on every generated object having FEWER THAN 32 keys.
  # Below that threshold BEAM uses a "small map" representation whose key
  # ordering happens to be stable in practice (insertion order is preserved in
  # the runtime's internal structure, so Jason sees keys in the order they were
  # inserted). We exploit that by pre-sorting the pairs before calling Map.new/1,
  # which gives deterministic key order in the JSON output.
  #
  # This is an explicit dependency, not a general guarantee. If any generated
  # object grows to 32 or more keys BEAM promotes it to a hash-array-mapped
  # trie, key ordering becomes non-deterministic, and write_if_changed/2 would
  # churn on every run. At that point the encoding must move to an explicitly
  # ordered structure — for example, encoding the sorted pairs list directly
  # rather than routing through Map.new/1.
  #
  # For nested objects (inner pairs lists) we recurse. For arrays of pairs lists
  # (like `vectors`) we map over each element. Plain scalar values pass through.
  defp pairs_to_map(pairs) when is_list(pairs) do
    if pairs_list?(pairs) do
      pairs
      |> Enum.sort_by(fn {k, _} -> to_string(k) end)
      |> Enum.map(fn {k, v} -> {to_string(k), convert_value(v)} end)
      |> Map.new()
    else
      # Plain list (array of scalars or pre-converted values)
      Enum.map(pairs, &convert_value/1)
    end
  end

  # A pairs list is a non-empty list where the first element is a 2-tuple.
  defp pairs_list?([]), do: false
  defp pairs_list?([{_, _} | _]), do: true
  defp pairs_list?(_), do: false

  defp convert_value(pairs) when is_list(pairs) and pairs != [] do
    if pairs_list?(pairs) do
      pairs_to_map(pairs)
    else
      # Plain array of scalars or inner objects
      Enum.map(pairs, &convert_value/1)
    end
  end

  defp convert_value([]), do: []
  defp convert_value(nil), do: nil
  defp convert_value(v), do: v

  # ---------------------------------------------------------------------------
  # Idempotent write
  # ---------------------------------------------------------------------------

  defp write_if_changed(relative_path, contents) do
    path = Path.expand(relative_path)
    File.mkdir_p!(Path.dirname(path))

    case File.read(path) do
      {:ok, existing} when existing == contents ->
        Mix.shell().info("  unchanged: #{relative_path}")
        :unchanged

      {:ok, _different} ->
        File.write!(path, contents)
        Mix.shell().info("  updated:   #{relative_path}")
        :updated

      {:error, :enoent} ->
        File.write!(path, contents)
        Mix.shell().info("  created:   #{relative_path}")
        :created

      {:error, reason} ->
        Mix.raise("could not write #{relative_path}: #{:file.format_error(reason)}")
    end
  end
end
