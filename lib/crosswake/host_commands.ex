defmodule Crosswake.HostCommands do
  @moduledoc """
  Shared rules for host-owned `host.*` commands.

  A router declares its host-command set once, with versions, through
  `crosswake_host_commands/1` (or `use Crosswake.Router, host_commands: [...]`).
  Routes then reference a command by name in their `crosswake:` `capabilities:` list.

  This module owns the command-name grammar, the reserved prefixes, the runtimes that
  can carry a host command, and the version range this release supports. The registry
  is checked at compile time; the iOS shell enforces the same version range
  independently at resolve time.
  """

  @grammar ~r/\Ahost\.[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+\z/
  @reserved_prefixes ["host.crosswake.", "host.bridge."]
  @bridge_runtimes [:live_view, :offline_island]
  @seam_version "1.0.0"
  @supported_command_major 1
  @strict_semver ~r/\A\d+\.\d+\.\d+\z/
  @shape "host.<namespace>.<action> (lowercase letters, digits and underscores; 3 or 4 dot-separated segments, for example host.study.audio.play)"

  @type registry :: [{String.t(), String.t()}]

  @doc "Runtimes that carry a web bridge session and may reference host commands."
  @spec bridge_runtimes() :: [atom()]
  def bridge_runtimes, do: @bridge_runtimes

  @doc "The host-command seam version this release emits."
  @spec seam_version() :: String.t()
  def seam_version, do: @seam_version

  @doc "The only supported host-command contract major (compatible with ^1.0.0)."
  @spec supported_command_major() :: non_neg_integer()
  def supported_command_major, do: @supported_command_major

  @doc "Reserved host-command prefixes."
  @spec reserved_prefixes() :: [String.t()]
  def reserved_prefixes, do: @reserved_prefixes

  @doc "The human-readable expected name shape."
  @spec shape() :: String.t()
  def shape, do: @shape

  @doc "True when the name matches the grammar and has 3 or 4 dot segments."
  @spec valid_name?(term()) :: boolean()
  def valid_name?(name) when is_binary(name) do
    Regex.match?(@grammar, name) and length(String.split(name, ".")) in 3..4
  end

  def valid_name?(_name), do: false

  @doc "True when the name starts with a reserved prefix."
  @spec reserved?(term()) :: boolean()
  def reserved?(name) when is_binary(name) do
    Enum.any?(@reserved_prefixes, &String.starts_with?(name, &1))
  end

  def reserved?(_name), do: false

  @doc "True for a strict three-part numeric SemVer string."
  @spec strict_semver?(term()) :: boolean()
  def strict_semver?(version) when is_binary(version) do
    Regex.match?(@strict_semver, version) and match?({:ok, _}, Version.parse(version))
  end

  def strict_semver?(_version), do: false

  @doc "True for strict SemVer whose major equals `supported_command_major/0`."
  @spec supported_command_version?(term()) :: boolean()
  def supported_command_version?(version) do
    strict_semver?(version) and
      match?({:ok, %Version{major: @supported_command_major}}, Version.parse(version))
  end

  @doc """
  Normalizes an evaluated registry into a name-sorted list of `{name, version}` tuples.

  Raises `CompileError` (file and line from `env`) for anything that is not a list of
  well-formed, unique, supported declarations.
  """
  @spec normalize_registry!(term(), Macro.Env.t()) :: registry()
  def normalize_registry!(list, env) when is_list(list) do
    entries = Enum.map(list, &validate_entry!(&1, env))

    entries
    |> Enum.reduce(MapSet.new(), fn {name, _version}, seen ->
      if MapSet.member?(seen, name) do
        fail!(
          env,
          "[crosswake.router.duplicate_host_command] host command #{inspect(name)} is declared " <>
            "more than once.\n\nDeclare each host command once:\n\n    crosswake_host_commands [{#{inspect(name)}, \"1.0.0\"}]"
        )
      else
        MapSet.put(seen, name)
      end
    end)

    Enum.sort_by(entries, &elem(&1, 0))
  end

  def normalize_registry!(other, env) do
    fail!(
      env,
      "[crosswake.router.host_commands_shape] expected a list of {name, version} tuples, got: " <>
        "#{inspect(other)}\n\nDeclare host commands like:\n\n    crosswake_host_commands [{\"host.study.audio.play\", \"1.0.0\"}]"
    )
  end

  defp validate_entry!({name, version} = entry, env)
       when is_binary(name) and is_binary(version) do
    cond do
      reserved?(name) ->
        fail!(
          env,
          "[crosswake.router.reserved_host_command] #{inspect(name)} uses a reserved prefix " <>
            "(#{Enum.join(@reserved_prefixes, ", ")}). Choose a name shaped like #{@shape}."
        )

      not valid_name?(name) ->
        fail!(
          env,
          "[crosswake.router.invalid_host_command] #{inspect(name)} is not a valid host command " <>
            "name. Expected #{@shape}."
        )

      not strict_semver?(version) ->
        fail!(
          env,
          "[crosswake.router.invalid_host_command_version] #{inspect(version)} for " <>
            "#{inspect(name)} is not strict three-part SemVer.\n\nUse a version like:\n\n" <>
            "    {#{inspect(name)}, \"1.0.0\"}"
        )

      not supported_command_version?(version) ->
        fail!(
          env,
          "[crosswake.router.unsupported_host_command_version] #{inspect(version)} for " <>
            "#{inspect(name)} is outside the supported range. This Crosswake release supports " <>
            "host command versions #{@supported_command_major}.x.y (^#{@supported_command_major}.0.0).\n\n" <>
            "Declare the command at a #{@supported_command_major}.x.y version:\n\n" <>
            "    {#{inspect(name)}, \"#{@supported_command_major}.0.0\"}"
        )

      true ->
        entry
    end
  end

  defp validate_entry!(other, env) do
    fail!(
      env,
      "[crosswake.router.host_commands_shape] expected a {name, version} tuple of two strings, " <>
        "got: #{inspect(other)}\n\nDeclare host commands like:\n\n" <>
        "    crosswake_host_commands [{\"host.study.audio.play\", \"1.0.0\"}]"
    )
  end

  defp fail!(env, description) do
    raise CompileError, file: env.file, line: env.line, description: description
  end
end
