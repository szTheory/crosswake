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
end
