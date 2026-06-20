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
    write_if_changed(@docs_snippet_path, docs_snippet(bridge_vsn))

    Mix.shell().info("""
    crosswake.contract.gen complete — bridge_protocol_version=#{bridge_vsn}
      #{@ios_activation_path}
      #{@android_activation_path}
      #{@vectors_path}
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
         "Request with a stale bridge_protocol_version is denied with compatibility_mismatch"},
        {"request_override", [{"version", "1.0.0"}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "compatibility_mismatch"}
      ],
      [
        {"id", "vec-002-unknown-command-deny"},
        {"description", "Request with an unrecognised command is denied"},
        {"request_override", [{"version", bridge_vsn}, {"command", "unknown.command"}]},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "undeclared_capability"}
      ],
      [
        {"id", "vec-003-canonical-version-ok"},
        {"description",
         "Request with the canonical bridge_protocol_version and a supported command succeeds"},
        {"request_override", [{"version", bridge_vsn}, {"command", "app.info.get"}]},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil}
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
  # plain Elixir map. Because Elixir maps do not preserve insertion order but
  # BEAM sorts atom-key maps lexicographically, we use string keys, which Jason
  # encodes in the order the runtime holds them. To guarantee sort stability we
  # first build a sorted keyword list and convert it to a map — this produces a
  # map whose key insertion order matches the sort, and Jason iterates it in
  # that order on OTP 26+.
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
