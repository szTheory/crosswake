defmodule Crosswake.ProofLane.GitPins do
  @moduledoc """
  The one pinned git environment shared by the twin source probe and proof provenance.

  Global and system config, replace objects and attribute sources are ignored, and hooks
  are disabled, so the folder alone decides which tree is read.
  """

  @empty_tree "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  @scrub_names ~w(GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY
                  GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_COMMON_DIR GIT_NAMESPACE
                  GIT_CEILING_DIRECTORIES GIT_CONFIG GIT_CONFIG_COUNT GIT_CONFIG_PARAMETERS
                  GIT_PREFIX GIT_ATTR_SOURCE GIT_EXTERNAL_DIFF GIT_EXEC_PATH)

  @fixed_env %{
    "GIT_CONFIG_GLOBAL" => "/dev/null",
    "GIT_CONFIG_NOSYSTEM" => "1",
    "GIT_NO_REPLACE_OBJECTS" => "1",
    "GIT_ATTR_NOSYSTEM" => "1",
    "GIT_OPTIONAL_LOCKS" => "0",
    "GIT_TERMINAL_PROMPT" => "0",
    "LC_ALL" => "C"
  }

  @env @scrub_names
       |> Map.new(&{&1, nil})
       |> Map.merge(@fixed_env)
       |> Enum.sort()

  @pins [
    "--no-optional-locks",
    "--no-replace-objects",
    "--attr-source=" <> @empty_tree,
    "-c",
    "core.fsmonitor=false",
    "-c",
    "core.filemode=true",
    "-c",
    "core.excludesFile=/dev/null",
    "-c",
    "core.attributesFile=/dev/null",
    "-c",
    "core.quotePath=false",
    "-c",
    "core.ignoreStat=false",
    "-c",
    "status.showUntrackedFiles=all",
    "-c",
    "core.autocrlf=false",
    "-c",
    "core.hooksPath=/dev/null",
    "-c",
    "core.ignorecase=false"
  ]

  @doc "The empty tree object id used as the attribute source."
  @spec empty_tree() :: String.t()
  def empty_tree, do: @empty_tree

  @doc "Sorted `{name, value | nil}` pairs: scrubbed names are nil, fixed values are strings."
  @spec env() :: [{String.t(), String.t() | nil}]
  def env, do: @env

  @doc "The argv pins placed before every git subcommand."
  @spec pins() :: [String.t()]
  def pins, do: @pins

  @doc "Spawn environment: every inherited `GIT_*` name unset, then `env/0` applied, sorted."
  @spec spawn_env() :: [{String.t(), String.t() | nil}]
  def spawn_env do
    inherited = for {"GIT_" <> _ = name, _} <- System.get_env(), into: %{}, do: {name, nil}

    inherited
    |> Map.merge(Map.new(@env))
    |> Enum.sort()
  end
end
