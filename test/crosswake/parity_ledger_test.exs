defmodule Crosswake.ParityLedgerTest do
  use ExUnit.Case, async: true

  alias Crosswake.ParityLedger

  @repo_root Path.expand("../..", __DIR__)

  @fix "run `mix crosswake.contract.gen && mix crosswake.docs.sync`"

  @bridge_copies [
    "test/fixtures/bridge_contract_vectors.json",
    "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json",
    "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"
  ]

  @kotlin_constant "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/VectorSetHash.kt"
  @swift_constant "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/VectorSetHash.swift"

  @kotlin_regex ~r/^internal object VectorSet \{ const val SHA256 = "([0-9a-f]{64})" \}$/m
  @swift_regex ~r/^enum VectorSet \{ static let sha256 = "([0-9a-f]{64})" \}$/m

  @transition_copy "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/navigation_transition_vectors.json"
  @topology_copy "priv/contract_vectors/navigation_topology_vectors.json"

  @other_hex String.duplicate("a", 64)

  @forbidden_vocabulary [
    "emulator",
    "device-verified",
    "supported on Android",
    ~r/Phase [0-9]+/,
    ":ios_host",
    "1.2.0"
  ]

  defp read!(relative), do: File.read!(Path.join(@repo_root, relative))

  defp corpus_hash, do: ParityLedger.sha256(read!(hd(@bridge_copies)))

  test "three bridge corpus copies are byte-equal" do
    [canonical | copies] = Enum.map(@bridge_copies, &read!/1)

    assert byte_size(canonical) > 0

    for {copy, path} <- Enum.zip(copies, tl(@bridge_copies)) do
      assert copy == canonical, "#{path} differs from the canonical corpus; #{@fix}"
    end
  end

  test "each native constant has exactly one anchored match equal to the corpus hash" do
    for {path, regex} <- [{@kotlin_constant, @kotlin_regex}, {@swift_constant, @swift_regex}] do
      matches = Regex.scan(regex, read!(path))
      assert length(matches) == 1, "#{path} must hold exactly one anchored constant; #{@fix}"
      [[_whole, hex]] = matches
      assert hex == corpus_hash(), "#{path} differs from the corpus bytes; #{@fix}"
    end
  end

  test "compare_references on the real facts is empty" do
    assert ParityLedger.compare_references(ParityLedger.facts()) == [], @fix
  end

  test "checked-in ledger shows the raw-bytes sha256" do
    guide = read!("guides/parity_ledger.md")
    assert guide =~ "sha256:" <> corpus_hash(), "guides/parity_ledger.md is stale; #{@fix}"
  end

  test "computed bridge Android evidence is jvm_hermetic" do
    assert ParityLedger.android_level(ParityLedger.facts()) == :jvm_hermetic
  end

  # -- helpers for the controls ---------------------------------------------

  defp categories(failures), do: Enum.map(failures, & &1.category)

  # Fails the control itself when a mutation changed nothing, so a vacuous control cannot pass.
  defp mutate!(input, fun) do
    mutated = fun.(input)
    refute mutated == input, "control mutation changed nothing"
    mutated
  end

  defp constant_text(:kotlin, hex),
    do: ~s(internal object VectorSet { const val SHA256 = "#{hex}" })

  defp constant_text(:swift, hex),
    do: ~s(enum VectorSet { static let sha256 = "#{hex}" })

  defp put_constant(facts, platform, text) do
    update_in(facts, [:constants, platform, :result], fn _ ->
      ParityLedger.parse_constant(platform, text)
    end)
  end

  defp put_bridge_bytes(facts, bytes) do
    update_in(facts, [:corpora], fn [bridge | rest] ->
      [%{bridge | files: Enum.map(bridge.files, &%{&1 | bytes: bytes})} | rest]
    end)
  end

  defp tmp_root!(tag) do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-parity-#{tag}-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp copy_into!(root, relative) do
    destination = Path.join(root, relative)
    File.mkdir_p!(Path.dirname(destination))
    File.write!(destination, read!(relative))
  end

  defp reference_tree!(tag) do
    root = tmp_root!(tag)

    for relative <-
          @bridge_copies ++
            [@topology_copy, @transition_copy, @kotlin_constant, @swift_constant] do
      copy_into!(root, relative)
    end

    root
  end

  defp forbidden_hits(text) do
    Enum.filter(@forbidden_vocabulary, fn
      %Regex{} = pattern -> Regex.match?(pattern, text)
      literal -> String.contains?(text, literal)
    end)
  end

  test "control: Swift constant differs from Kotlin" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_references(facts) == []

    mutated = mutate!(facts, &put_constant(&1, :swift, constant_text(:swift, @other_hex)))
    found = categories(ParityLedger.compare_references(mutated))

    assert :platform_mismatch in found, @fix
  end

  test "control: a constant differs from the corpus" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_references(facts) == []

    mutated =
      facts
      |> mutate!(&put_constant(&1, :kotlin, constant_text(:kotlin, @other_hex)))
      |> mutate!(&put_constant(&1, :swift, constant_text(:swift, @other_hex)))

    found = categories(ParityLedger.compare_references(mutated))

    assert found == [:constant_mismatch, :constant_mismatch], @fix
    refute :platform_mismatch in found
  end

  test "control: a constant file is missing" do
    root = reference_tree!("missing-constant")
    assert ParityLedger.compare_references(ParityLedger.facts(root)) == []

    File.rm!(Path.join(root, @kotlin_constant))
    failures = ParityLedger.compare_references(ParityLedger.facts(root))

    assert [%{category: :constant_missing, path: @kotlin_constant}] = failures, @fix
  end

  test "control: a constant text with zero anchored matches" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_references(facts) == []

    unanchored = [
      # not a hex digest
      constant_text(:kotlin, "not-a-hex-digest"),
      # indented, so the line anchor does not match
      "  " <> constant_text(:kotlin, corpus_hash()),
      ""
    ]

    for text <- unanchored do
      assert ParityLedger.parse_constant(:kotlin, text) == {:error, :no_match}
      mutated = mutate!(facts, &put_constant(&1, :kotlin, text))

      assert :constant_no_match in categories(ParityLedger.compare_references(mutated)), @fix
    end
  end

  test "control: a constant text with two anchored matches" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_references(facts) == []

    line = constant_text(:swift, corpus_hash())
    twice = line <> "\n" <> line

    assert ParityLedger.parse_constant(:swift, line) == {:ok, corpus_hash()}
    assert ParityLedger.parse_constant(:swift, twice) == {:error, :multiple}

    mutated = mutate!(facts, &put_constant(&1, :swift, twice))

    assert :constant_multiple in categories(ParityLedger.compare_references(mutated)), @fix
  end

  test "control: an empty corpus" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_references(facts) == []

    for bytes <- ["", ~s({"vectors": []}), "not json"] do
      mutated = mutate!(facts, &put_bridge_bytes(&1, bytes))

      assert :empty_corpus in categories(ParityLedger.compare_references(mutated)), @fix
    end
  end

  test "control: one mutated byte in a corpus copy" do
    root = reference_tree!("mutated-copy")
    assert ParityLedger.compare_references(ParityLedger.facts(root)) == []

    ios_copy = Enum.at(@bridge_copies, 1)
    path = Path.join(root, ios_copy)
    original = File.read!(path)
    mutated = String.replace(original, ~s("1.1.0"), ~s("1.1.7"), global: false)
    refute mutated == original, "control mutation changed nothing"
    File.write!(path, mutated)

    failures = ParityLedger.compare_references(ParityLedger.facts(root))

    assert Enum.any?(failures, &(&1.category == :copy_mismatch and &1.path == ios_copy)), @fix
  end

  test "control: a second shared corpus" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_references(facts) == []

    second =
      mutate!(facts, fn facts ->
        [bridge | _] = facts.corpora
        %{facts | corpora: facts.corpora ++ [%{bridge | id: "second_shared"}]}
      end)

    assert :shared_count in categories(ParityLedger.compare_references(second)), @fix

    none =
      mutate!(facts, fn facts ->
        %{facts | corpora: Enum.map(facts.corpora, &%{&1 | shared: false})}
      end)

    assert :shared_count in categories(ParityLedger.compare_references(none)), @fix
  end

  test "control: a declared consumer that is missing or does not name its corpus" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_registry(facts, facts.scanned) == []

    ghost = %{
      platform: :kotlin,
      path:
        "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/GhostTest.kt",
      corpus: ParityLedger.bridge_corpus_id(),
      kind: :behavioral,
      executes: [:requests]
    }

    missing = mutate!(facts, &%{&1 | consumers: &1.consumers ++ [ghost]})

    assert [%{category: :consumer_missing, path: ghost_path}] =
             ParityLedger.compare_registry(missing, missing.scanned)

    assert ghost_path == ghost.path

    [declared | _] = facts.consumers

    silent =
      mutate!(facts, fn facts ->
        %{facts | sources: Map.put(facts.sources, declared.path, "// reads nothing relevant")}
      end)

    assert [%{category: :consumer_not_naming_corpus, path: silent_path}] =
             ParityLedger.compare_registry(silent, silent.scanned)

    assert silent_path == declared.path
  end

  test "control: a scanned consumer that is not declared" do
    facts = ParityLedger.facts()
    assert ParityLedger.compare_registry(facts, facts.scanned) == []

    stray = %{
      platform: :kotlin,
      path:
        "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/StrayTest.kt",
      corpus: ParityLedger.bridge_corpus_id()
    }

    failures = ParityLedger.compare_registry(facts, facts.scanned ++ [stray])
    assert [%{category: :consumer_undeclared, path: stray_path}] = failures
    assert stray_path == stray.path

    # The scan itself finds a reader that nobody declared.
    root = tmp_root!("stray-consumer")
    assert ParityLedger.scan_consumers(root) == []

    stray_file = Path.join(root, stray.path)
    File.mkdir_p!(Path.dirname(stray_file))
    File.write!(stray_file, "val bytes = VectorCorpus.loadVerifiedBytes()")

    assert [%{platform: :kotlin, path: found, corpus: corpus}] = ParityLedger.scan_consumers(root)
    assert found == stray.path
    assert corpus == ParityLedger.bridge_corpus_id()
  end

  test "android_level is not_claimed with a reference failure or without a declared Kotlin behavioral consumer" do
    facts = ParityLedger.facts()
    assert ParityLedger.android_level(facts) == :jvm_hermetic

    failing = mutate!(facts, &put_constant(&1, :swift, constant_text(:swift, @other_hex)))
    assert ParityLedger.compare_references(failing) != []
    assert ParityLedger.android_level(failing) == :not_claimed

    # Demote the Kotlin behavioral consumers to metadata readers: references and registry stay
    # clean, so only the missing behavioral consumer can withdraw the claim.
    demoted =
      mutate!(facts, fn facts ->
        consumers =
          Enum.map(facts.consumers, fn
            %{platform: :kotlin, kind: :behavioral} = entry -> %{entry | kind: :metadata}
            entry -> entry
          end)

        %{facts | consumers: consumers}
      end)

    assert ParityLedger.compare_references(demoted) == []
    assert ParityLedger.compare_registry(demoted, demoted.scanned) == []
    assert ParityLedger.android_level(demoted) == :not_claimed

    # A broken registry also withdraws the claim.
    undeclared =
      mutate!(facts, fn facts ->
        stray = %{
          platform: :kotlin,
          path: "StrayTest.kt",
          corpus: ParityLedger.bridge_corpus_id()
        }

        %{facts | scanned: facts.scanned ++ [stray]}
      end)

    assert ParityLedger.android_level(undeclared) == :not_claimed
  end

  test "derived corpus counts equal the hand-written pins and native sources carry the expected markers" do
    facts = ParityLedger.facts()

    # Hand-written literals, independent of the module's own pin.
    assert ParityLedger.derived_counts(facts) == %{
             loaded: 15,
             native: 14,
             elixir: 9,
             reply_leg: 2
           }

    assert ParityLedger.pinned_executions() == %{loaded: 15, native: 14, elixir: 9, reply_leg: 2}

    kotlin =
      read!(
        "packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt"
      )

    swift =
      read!(
        "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift"
      )

    for {name, source} <- [kotlin: kotlin, swift: swift] do
      assert source =~ "CW-VECTOR-LOADED expected 15", "#{name} source lost its loaded marker"

      assert source =~ "CW-VECTOR-COMPLETED expected 14",
             "#{name} source lost its completed marker"
    end

    # The count is derived, so dropping a vector from the corpus changes it.
    shorter =
      mutate!(facts, fn facts ->
        bytes = hd(hd(facts.corpora).files).bytes
        json = Jason.decode!(bytes)
        put_bridge_bytes(facts, Jason.encode!(%{json | "vectors" => tl(json["vectors"])}))
      end)

    refute ParityLedger.derived_counts(shorter) == ParityLedger.pinned_executions()
  end

  test "exactly one shared corpus" do
    shared = Enum.filter(ParityLedger.facts().corpora, & &1.shared)

    assert length(shared) == 1,
           "a second shared corpus needs a deliberate hashing decision, not an implicit one; #{@fix}"

    assert [%{id: "bridge_contract_vectors"}] = shared
  end

  test "android_only_commands is exactly the two server commands" do
    facts = ParityLedger.facts()

    assert ParityLedger.android_only_commands(facts) == [
             "server.event.push",
             "server.state.update"
           ]

    # The list is derived: a shell that parses no commands yields none.
    empty = mutate!(facts, &put_in(&1, [:commands, :android], []))
    assert ParityLedger.android_only_commands(empty) == []
  end

  test "rendered ledger carries no forbidden vocabulary" do
    facts = ParityLedger.facts()
    rendered = Crosswake.ParityLedger.Renderer.render(facts)

    assert forbidden_hits(rendered) == []
    assert forbidden_hits(read!("guides/parity_ledger.md")) == []

    # The check is not vacuous: each forbidden term is caught when present.
    for sample <- [
          "emulator",
          "device-verified",
          "supported on Android",
          "Phase 198",
          ":ios_host",
          "1.2.0"
        ] do
      assert forbidden_hits("text " <> sample <> " text") != [], "#{sample} was not detected"
    end
  end
end
