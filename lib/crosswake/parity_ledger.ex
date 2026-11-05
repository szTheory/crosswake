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

  @bridge_channel_path "packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt"

  @scan_trees [
    {:kotlin, "packages/crosswake-shell-core-android/src/test", ".kt"},
    {:swift, "packages/crosswake-shell-core-ios/Tests", ".swift"}
  ]

  @swift_dir "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/"
  @kotlin_dir "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/"

  # Hand-written on purpose: these are checked against the corpus and the native sources by
  # the ledger test, so a drifting count turns a test red instead of regenerating silently.
  @pinned_executions %{loaded: 15, native: 14, elixir: 9, reply_leg: 2}

  @cell_executed %{
    elixir: "ExUnit executed",
    swift: "Swift test executed",
    kotlin: "JVM test executed"
  }
  @cell_not_applicable "not applicable"
  @cell_no_consumer "no consumer"

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
  Reads the corpora, the generated native constants, the declared consumers, a scan of the
  Kotlin and Swift test trees and the Android command list under `root`.
  """
  @spec facts(String.t()) :: map()
  def facts(root \\ repo_root()) do
    corpora = corpora(root)
    consumers = consumer_registry()

    %{
      root: root,
      corpora: corpora,
      constants: %{
        kotlin: read_constant(root, :kotlin),
        swift: read_constant(root, :swift)
      },
      consumers: consumers,
      scanned: scan_consumers(root),
      sources: read_sources(root, consumers),
      commands: %{corpus: corpus_commands(corpora), android: android_commands(root)}
    }
  end

  @doc """
  Hand-written pinned execution counts for the bridge corpus.
  """
  @spec pinned_executions() :: %{
          loaded: non_neg_integer(),
          native: non_neg_integer(),
          elixir: non_neg_integer(),
          reply_leg: non_neg_integer()
        }
  def pinned_executions, do: @pinned_executions

  @doc """
  Counts derived from the bridge corpus itself, comparable with `pinned_executions/0`.
  """
  @spec derived_counts(map()) :: map()
  def derived_counts(facts) do
    json = corpus_json(facts, @bridge_corpus)
    vectors = Map.get(json, "vectors", [])

    %{
      loaded: length(vectors),
      native: Enum.count(vectors, &(&1["elixir_only"] != true)),
      elixir: Enum.count(vectors, &(&1["native_only"] != true)),
      reply_leg: length(Map.get(json, "reply_leg_vectors", []))
    }
  end

  @doc """
  Declared readers of each corpus. `kind` is `:behavioral` (executes vectors and asserts
  outcomes), `:metadata` (reads fields without executing each vector) or `:integrity`
  (loads or verifies the bytes). Only behavioral entries produce an executed cell.
  """
  @spec consumer_registry() :: [map()]
  def consumer_registry do
    bridge = @bridge_corpus
    topology = "navigation_topology_vectors"

    [
      consumer(
        :elixir,
        "test/crosswake/bridge/bridge_behavioral_vector_test.exs",
        bridge,
        :behavioral,
        [:requests]
      ),
      consumer(:swift, @swift_dir <> "BridgeConformanceTests.swift", bridge, :behavioral, [
        :requests
      ]),
      consumer(:swift, @swift_dir <> "BridgeReplyLegTests.swift", bridge, :behavioral, [
        :reply_legs
      ]),
      consumer(:swift, @swift_dir <> "ActivationConformanceTests.swift", bridge, :metadata),
      consumer(:swift, @swift_dir <> "OfflineIslandAdmissionTests.swift", bridge, :metadata),
      consumer(:swift, @swift_dir <> "Phase180TwinFeasibilityTests.swift", bridge, :metadata),
      consumer(:swift, @swift_dir <> "VectorCorpusTests.swift", bridge, :integrity),
      consumer(:kotlin, @kotlin_dir <> "BridgeConformanceTest.kt", bridge, :behavioral, [
        :requests
      ]),
      consumer(:kotlin, @kotlin_dir <> "BridgeReplyLegTest.kt", bridge, :behavioral, [:reply_legs]),
      consumer(:kotlin, @kotlin_dir <> "ActivationConformanceTest.kt", bridge, :metadata),
      consumer(:kotlin, @kotlin_dir <> "VectorCorpus.kt", bridge, :integrity),
      consumer(:kotlin, @kotlin_dir <> "VectorCorpusTest.kt", bridge, :integrity),
      consumer(:kotlin, @kotlin_dir <> "BridgeFixtures.kt", bridge, :integrity),
      consumer(:swift, @swift_dir <> "NavigationCoordinatorTests.swift", topology, :behavioral, [
        :vectors
      ])
    ]
  end

  @doc """
  Scans the Kotlin and Swift test trees for files that name a corpus, so a reader added
  without a registry entry is found. Returns `[%{platform:, path:, corpus:}]`.
  """
  @spec scan_consumers(String.t()) :: [map()]
  def scan_consumers(root \\ repo_root()) do
    ids = corpus_ids(root)

    for {platform, tree, extension} <- @scan_trees,
        path <- Path.wildcard(Path.join([root, tree, "**", "*" <> extension])) |> Enum.sort(),
        text = File.read!(path),
        id <- ids,
        names_corpus?(text, id) do
      %{platform: platform, path: Path.relative_to(path, root), corpus: id}
    end
  end

  @doc """
  Two-sided registry check. A declared consumer must exist and name its corpus; a scanned
  file that names a corpus must be declared.
  """
  @spec compare_registry(map(), [map()]) :: [failure()]
  def compare_registry(%{consumers: consumers, sources: sources}, scanned) do
    declared =
      Enum.flat_map(consumers, fn entry ->
        case Map.get(sources, entry.path) do
          nil ->
            [failure(entry.path, :consumer_missing, :missing, entry.corpus)]

          text ->
            if names_corpus?(text, entry.corpus),
              do: [],
              else: [failure(entry.path, :consumer_not_naming_corpus, :absent, entry.corpus)]
        end
      end)

    declared_keys = MapSet.new(consumers, &{&1.path, &1.corpus})

    undeclared =
      for entry <- scanned, not MapSet.member?(declared_keys, {entry.path, entry.corpus}) do
        failure(entry.path, :consumer_undeclared, entry.corpus, :declared)
      end

    declared ++ undeclared
  end

  @doc """
  Bridge command wire values the Android shell parses that no shared vector lists.
  """
  @spec android_only_commands(map()) :: [String.t()]
  def android_only_commands(%{commands: %{corpus: corpus, android: android}}),
    do: Enum.reject(android, &(&1 in corpus))

  @doc """
  One row per request, reply-leg, topology and transition vector with a cell per platform.
  """
  @spec vector_rows(map()) :: [map()]
  def vector_rows(facts) do
    Enum.flat_map(facts.corpora, fn %{id: id} ->
      json = corpus_json(facts, id)

      if id == @bridge_corpus do
        Enum.map(Map.get(json, "vectors", []), &bridge_request_row(facts, id, &1)) ++
          Enum.map(Map.get(json, "reply_leg_vectors", []), &reply_leg_row(facts, id, &1))
      else
        Enum.map(Map.get(json, "vectors", []), &generic_row(facts, id, &1))
      end
    end)
  end

  @doc """
  Declared consumers of `corpus_id` on `platform`.
  """
  @spec consumers_for(map(), String.t(), :elixir | :swift | :kotlin) :: [map()]
  def consumers_for(%{consumers: consumers}, corpus_id, platform),
    do: Enum.filter(consumers, &(&1.corpus == corpus_id and &1.platform == platform))

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
    if compare_references(facts) == [] and compare_registry(facts, facts.scanned) == [] and
         executes?(facts, @bridge_corpus, :kotlin, :requests) do
      SupportMatrix.validate_android_evidence!(:jvm_hermetic)
    else
      :not_claimed
    end
  end

  # -- registry and cells ----------------------------------------------------

  defp consumer(platform, path, corpus, kind, executes \\ []),
    do: %{platform: platform, path: path, corpus: corpus, kind: kind, executes: executes}

  defp read_sources(root, consumers) do
    Map.new(consumers, fn %{path: path} ->
      case File.read(Path.join(root, path)) do
        {:ok, text} -> {path, text}
        {:error, _reason} -> {path, nil}
      end
    end)
  end

  defp corpus_ids(root) do
    [
      @bridge_corpus
      | root |> corpora() |> Enum.map(& &1.id) |> Enum.reject(&(&1 == @bridge_corpus))
    ]
  end

  defp corpus_tokens(@bridge_corpus),
    do: [@bridge_corpus, "VectorCorpus.loadVerifiedBytes", "VectorCorpus.verifiedData"]

  defp corpus_tokens(id), do: [id]

  defp names_corpus?(text, id), do: Enum.any?(corpus_tokens(id), &String.contains?(text, &1))

  defp corpus_json(facts, id) do
    with %{files: [%{bytes: bytes} | _]} when is_binary(bytes) <-
           Enum.find(facts.corpora, &(&1.id == id)),
         {:ok, %{} = json} <- Jason.decode(bytes) do
      json
    else
      _ -> %{}
    end
  end

  defp corpus_commands(corpora) do
    with %{files: [%{bytes: bytes} | _]} when is_binary(bytes) <-
           Enum.find(corpora, &(&1.id == @bridge_corpus)),
         {:ok, %{"commands" => commands}} when is_list(commands) <- Jason.decode(bytes) do
      commands
    else
      _ -> []
    end
  end

  defp android_commands(root) do
    with {:ok, text} <- File.read(Path.join(root, @bridge_channel_path)),
         [_before, rest] <- String.split(text, "enum class BridgeCommand(", parts: 2),
         [block | _] <- String.split(rest, "val capability", parts: 2) do
      ~r/^\s+[A-Z][A-Z_]*\("([a-z][a-z.]*)"\)[,;]\s*$/m
      |> Regex.scan(block)
      |> Enum.map(&List.last/1)
    else
      _ -> []
    end
  end

  defp executes?(facts, corpus_id, platform, scope) do
    facts
    |> consumers_for(corpus_id, platform)
    |> Enum.any?(&(&1.kind == :behavioral and scope in &1.executes))
  end

  defp bridge_request_row(facts, id, vector) do
    %{
      corpus: id,
      vector: vector["id"],
      expected: vector["expected_outcome"] || "-",
      denial: vector["expected_denial_reason"] || "-",
      elixir: scoped_cell(facts, id, :elixir, :requests, vector["native_only"] == true),
      swift: scoped_cell(facts, id, :swift, :requests, vector["elixir_only"] == true),
      android: scoped_cell(facts, id, :kotlin, :requests, vector["elixir_only"] == true)
    }
  end

  defp reply_leg_row(facts, id, vector) do
    %{
      corpus: id,
      vector: vector["id"],
      expected: get_in(vector, ["reply", "status"]) || "-",
      denial: get_in(vector, ["reply", "denial", "denial", "code"]) || "-",
      elixir: @cell_not_applicable,
      swift: scoped_cell(facts, id, :swift, :reply_legs, false),
      android: scoped_cell(facts, id, :kotlin, :reply_legs, false)
    }
  end

  defp generic_row(facts, id, vector) do
    %{
      corpus: id,
      vector: vector["id"],
      expected: vector["status"] || vector["expected"] || "-",
      denial: "-",
      elixir: by_id_cell(facts, id, :elixir, vector["id"]),
      swift: by_id_cell(facts, id, :swift, vector["id"]),
      android: by_id_cell(facts, id, :kotlin, vector["id"])
    }
  end

  defp scoped_cell(_facts, _id, _platform, _scope, true), do: @cell_not_applicable

  defp scoped_cell(facts, id, platform, scope, false) do
    if executes?(facts, id, platform, scope),
      do: Map.fetch!(@cell_executed, platform),
      else: @cell_no_consumer
  end

  # A topology or transition vector counts as executed only when a declared behavioral
  # consumer names its id, so a reader that skips most vectors cannot claim them all.
  defp by_id_cell(facts, id, platform, vector_id) do
    executed? =
      facts
      |> consumers_for(id, platform)
      |> Enum.any?(fn entry ->
        entry.kind == :behavioral and :vectors in entry.executes and
          String.contains?(Map.get(facts.sources, entry.path) || "", ~s("#{vector_id}"))
      end)

    if executed?, do: Map.fetch!(@cell_executed, platform), else: @cell_no_consumer
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
