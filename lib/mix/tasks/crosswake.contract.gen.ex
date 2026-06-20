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
  # Content builders
  # ---------------------------------------------------------------------------

  defp ios_activation_json(bridge_vsn) do
    json_object([
      {"_generated_by", "mix crosswake.contract.gen"},
      {"bridge_protocol_version", bridge_vsn},
      {"capabilities", json_object([{"camera", "1.0.0"}])},
      {"correlation_id", "ios-example-capture-1"},
      {"declared_pack_requirements", json_object([{"camera_capture_assets", "1.0.0"}])},
      {"installed_packs", json_object([{"camera_capture_assets", "1.0.0"}])},
      {"manifest_source", "bundled"},
      {"native_runtime_version", "1.0.0"},
      {"origin", "https://example.crosswake.invalid"},
      {"route_id", "selective-native-claim-capture"},
      {"source", "cold_start"},
      {"url", "https://example.crosswake.invalid/native/claims/claim-1/capture"}
    ])
  end

  defp android_activation_json(bridge_vsn) do
    json_object([
      {"_generated_by", "mix crosswake.contract.gen"},
      {"bridge_protocol_version", bridge_vsn},
      {"capabilities", json_object([{"camera", "1.0.0"}])},
      {"correlation_id", "android-example-capture-1"},
      {"declared_pack_requirements", json_object([{"camera_capture_assets", "1.0.0"}])},
      {"installed_packs", json_object([{"camera_capture_assets", "1.0.0"}])},
      {"manifest_source", "bundled"},
      {"native_runtime_version", "1.0.0"},
      {"origin", "https://example.crosswake.invalid"},
      {"route_id", "selective-native-claim-capture"},
      {"source", "cold_start"},
      {"url", "https://example.crosswake.invalid/native/claims/claim-1/capture"}
    ])
  end

  defp vectors_json(protocol, bridge_vsn, commands, denial_reasons) do
    json_object([
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
      json_object([
        {"id", "vec-001-version-mismatch-deny"},
        {"description",
         "Request with a stale bridge_protocol_version is denied with compatibility_mismatch"},
        {"request_override", json_object([{"version", "1.0.0"}])},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "compatibility_mismatch"}
      ]),
      json_object([
        {"id", "vec-002-unknown-command-deny"},
        {"description", "Request with an unrecognised command is denied"},
        {"request_override",
         json_object([{"version", bridge_vsn}, {"command", "unknown.command"}])},
        {"expected_outcome", "deny"},
        {"expected_denial_reason", "undeclared_capability"}
      ]),
      json_object([
        {"id", "vec-003-canonical-version-ok"},
        {"description",
         "Request with the canonical bridge_protocol_version and a supported command succeeds"},
        {"request_override", json_object([{"version", bridge_vsn}, {"command", "app.info.get"}])},
        {"expected_outcome", "ok"},
        {"expected_denial_reason", nil}
      ])
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
  # We represent JSON objects as sorted keyword-style lists of {key, value} pairs
  # encoded into a raw JSON string via a recursive builder. This guarantees
  # byte-stable output on consecutive runs regardless of BEAM map ordering.
  # ---------------------------------------------------------------------------

  # Encode a list of {key, value} pairs as a pretty-printed JSON object string.
  # Pairs are sorted by key so re-runs are byte-stable.
  defp json_object(pairs) when is_list(pairs) do
    sorted = Enum.sort_by(pairs, fn {k, _} -> k end)
    entries = Enum.map_join(sorted, ",\n", fn {k, v} -> ~s("#{k}": #{json_value(v)}) end)
    "{\n#{indent_block(entries)}\n}"
  end

  # Scalar values
  defp json_value(s) when is_binary(s), do: Jason.encode!(s)
  defp json_value(nil), do: "null"
  defp json_value(b) when is_boolean(b), do: Jason.encode!(b)
  defp json_value(n) when is_integer(n) or is_float(n), do: Jason.encode!(n)

  # Already-encoded JSON object string (from json_object/1 recursive call)
  defp json_value(s) when is_binary(s), do: s

  # Plain list (JSON array of scalar or already-encoded objects)
  defp json_value(list) when is_list(list) do
    items = Enum.map_join(list, ",\n", &json_value/1)
    "[\n#{indent_block(items)}\n]"
  end

  # Indent a multi-line block by two spaces per level.
  defp indent_block(text) do
    text
    |> String.split("\n")
    |> Enum.map_join("\n", fn line -> "  " <> line end)
  end

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
