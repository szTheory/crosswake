defmodule Crosswake.ParityLedger do
  @moduledoc """
  Derived facts behind `guides/parity_ledger.md`.

  The ledger is computed from the shared contract corpora and the generated native
  constants. Nothing about Android is authored here: the Android evidence level is a
  function of the reference checks, validated through
  `Crosswake.SupportMatrix.validate_android_evidence!/1`.

  Two corpus locations are read:

    * the bridge corpus, shared by three byte-identical copies (Elixir test fixture,
      iOS test resource, Android test resource); its vector-set hash is the SHA-256 of
      the raw bytes, never of re-encoded JSON
    * every `priv/contract_vectors/*.json` plus the Swift navigation transition resource;
      each is read from one location, hashed per file and informational only

  All files are read at run time from a root resolved by `repo_root/0`, never from the
  current working directory and never at compile time: Hex consumers compile `lib/`
  without `test/` or `packages/`.

  Fix any reported failure with `mix crosswake.contract.gen && mix crosswake.docs.sync`.
  """

  alias Crosswake.SupportMatrix

  @bridge_corpus "bridge_contract_vectors"

  @bridge_paths [
    "test/fixtures/bridge_contract_vectors.json",
    "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json",
    "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"
  ]

  @contract_vector_glob "priv/contract_vectors/*.json"

  @transition_path "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/navigation_transition_vectors.json"

  @constant_paths %{
    kotlin:
      "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/VectorSetHash.kt",
    swift: "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/VectorSetHash.swift"
  }

  @type constant_result ::
          {:ok, String.t()} | {:error, :missing | :no_match | :multiple}

  @type failure :: %{
          path: String.t(),
          category: atom(),
          actual: term(),
          expected: term()
        }

  @doc """
  Repository root, resolved inside the function so no path is baked in by a compile step.
  """
  @spec repo_root() :: String.t()
  def repo_root, do: Path.expand("../..", __DIR__)

  @doc """
  Reads the corpora and the generated native constants under `root`.
  """
  @spec facts(String.t()) :: map()
  def facts(root \\ repo_root()) do
    %{
      root: root,
      corpora: corpora(root),
      constants: %{
        kotlin: read_constant(root, :kotlin),
        swift: read_constant(root, :swift)
      }
    }
  end

  @doc """
  Id of the one corpus whose copies are shared across Elixir, Swift and Kotlin.
  """
  @spec bridge_corpus_id() :: String.t()
  def bridge_corpus_id, do: @bridge_corpus

  @doc """
  Lowercase hex SHA-256 of the raw bytes.
  """
  @spec sha256(binary()) :: String.t()
  def sha256(bytes) when is_binary(bytes),
    do: Base.encode16(:crypto.hash(:sha256, bytes), case: :lower)

  @doc """
  Parses one native constant text with its anchored, multiline regex.
  """
  @spec parse_constant(:kotlin | :swift, String.t()) :: constant_result()
  def parse_constant(platform, text) when platform in [:kotlin, :swift] and is_binary(text) do
    case Regex.scan(constant_regex(platform), text) do
      [[_whole, hex]] -> {:ok, hex}
      [] -> {:error, :no_match}
      _many -> {:error, :multiple}
    end
  end

  @doc """
  Every reference check, as a list of failures. An empty list means all checks pass.
  """
  @spec compare_references(map()) :: [failure()]
  def compare_references(%{corpora: corpora, constants: constants}) do
    shared = Enum.filter(corpora, & &1.shared)

    shared_count_failures(shared) ++
      Enum.flat_map(corpora, &empty_failures/1) ++
      Enum.flat_map(shared, &copy_failures/1) ++
      constant_failures(constants, expected_hash(shared))
  end

  @doc """
  Android evidence level for the bridge corpus, computed and never authored.

  Returns the typed `:jvm_hermetic` level, validated against the ceiling, only when every
  reference check passes. Otherwise `:not_claimed`.
  """
  @spec android_level(map()) :: atom()
  def android_level(facts) do
    if compare_references(facts) == [] do
      SupportMatrix.validate_android_evidence!(:jvm_hermetic)
    else
      :not_claimed
    end
  end

  # -- corpora ---------------------------------------------------------------

  defp corpora(root) do
    bridge = %{
      id: @bridge_corpus,
      shared: true,
      files: Enum.map(@bridge_paths, &read_file(root, &1))
    }

    others =
      (Path.wildcard(Path.join(root, @contract_vector_glob))
       |> Enum.map(&Path.relative_to(&1, root))
       |> Enum.sort()) ++ [@transition_path]

    [
      bridge
      | Enum.map(others, fn relative ->
          %{
            id: Path.basename(relative, ".json"),
            shared: false,
            files: [read_file(root, relative)]
          }
        end)
    ]
  end

  defp read_file(root, relative) do
    case File.read(Path.join(root, relative)) do
      {:ok, bytes} -> %{path: relative, bytes: bytes, sha256: sha256(bytes)}
      {:error, _reason} -> %{path: relative, bytes: nil, sha256: nil}
    end
  end

  defp read_constant(root, platform) do
    path = Map.fetch!(@constant_paths, platform)

    result =
      case File.read(Path.join(root, path)) do
        {:ok, text} -> parse_constant(platform, text)
        {:error, _reason} -> {:error, :missing}
      end

    %{path: path, result: result}
  end

  defp constant_regex(:kotlin),
    do: ~r/^internal object VectorSet \{ const val SHA256 = "([0-9a-f]{64})" \}$/m

  defp constant_regex(:swift),
    do: ~r/^enum VectorSet \{ static let sha256 = "([0-9a-f]{64})" \}$/m

  # -- reference checks ------------------------------------------------------

  defp shared_count_failures([_one]), do: []

  defp shared_count_failures(shared),
    do: [failure("corpora", :shared_count, length(shared), 1)]

  defp empty_failures(%{files: files}) do
    Enum.flat_map(files, fn file ->
      case emptiness(file.bytes) do
        :ok -> []
        reason -> [failure(file.path, :empty_corpus, reason, :non_empty_vectors)]
      end
    end)
  end

  defp emptiness(nil), do: :missing
  defp emptiness(""), do: :zero_bytes

  defp emptiness(bytes) do
    case Jason.decode(bytes) do
      {:ok, %{"vectors" => [_ | _]}} -> :ok
      {:ok, _other} -> :no_vectors
      {:error, _reason} -> :undecodable
    end
  end

  defp copy_failures(%{files: [first | rest]}) do
    for file <- rest,
        is_binary(first.bytes) and is_binary(file.bytes),
        file.bytes != first.bytes do
      failure(file.path, :copy_mismatch, sha256(file.bytes), sha256(first.bytes))
    end
  end

  defp copy_failures(_corpus), do: []

  defp expected_hash(shared) do
    with [%{files: [%{bytes: bytes} | _]} | _] when is_binary(bytes) <- shared do
      sha256(bytes)
    else
      _ -> nil
    end
  end

  defp constant_failures(constants, expected) do
    per_platform =
      for platform <- [:kotlin, :swift] do
        %{path: path, result: result} = Map.fetch!(constants, platform)

        case result do
          {:ok, ^expected} -> []
          {:ok, hex} -> [failure(path, :constant_mismatch, hex, expected)]
          {:error, :missing} -> [failure(path, :constant_missing, :missing, expected)]
          {:error, :no_match} -> [failure(path, :constant_no_match, :no_match, expected)]
          {:error, :multiple} -> [failure(path, :constant_multiple, :multiple, expected)]
        end
      end

    per_platform = List.flatten(per_platform)

    case {constants.kotlin, constants.swift} do
      {%{result: {:ok, kotlin}}, %{path: path, result: {:ok, swift}}} when kotlin != swift ->
        per_platform ++ [failure(path, :platform_mismatch, swift, kotlin)]

      _same_or_unreadable ->
        per_platform
    end
  end

  defp failure(path, category, actual, expected),
    do: %{path: path, category: category, actual: actual, expected: expected}
end
