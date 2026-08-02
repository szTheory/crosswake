defmodule Crosswake.ProofLane.EvidenceTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.Evidence

  @valid %{
    schema_version: "1",
    crosswake_version: "1.0.0",
    template_version: "1",
    commit_ref: "git-0123456789abcdef0123456789abcdef01234567",
    route_id: "route-0123456789abcdef",
    assertion_ids: ["browser_offline_island"],
    status: :blocked,
    outcome: :blocked,
    captured_at: "2026-07-31T12:00:00Z",
    retention_label: :brief,
    device_class: :ios,
    approved_hashes: []
  }

  test "builds the exact versioned allowlist and explicitly serializes only declared keys" do
    assert {:ok, evidence} = Evidence.build(@valid)

    assert Map.keys(Evidence.to_map(evidence)) |> Enum.sort() ==
             ~w(approved_hashes assertion_ids captured_at commit_ref crosswake_version device_class outcome retention_label route_id schema_version status template_version)
  end

  test "rejects unknown and sensitive key/value injections without echoing canaries" do
    for {key, value} <- [
          {:answer, "CANARY-ANSWER"},
          {:token, "CANARY-TOKEN"},
          {:account_id, "CANARY-ACCOUNT"},
          {:media, "CANARY-MEDIA"},
          {:endpoint, "https://CANARY-ENDPOINT"},
          {:device_id, "CANARY-DEVICE"},
          {:attachment, %{trace: "CANARY-TRACE"}},
          {:metadata, [%{raw_output: "CANARY-OUTPUT"}]}
        ] do
      assert {:error, error} = Evidence.build(Map.put(@valid, key, value))
      rendered = inspect(error)
      refute rendered =~ "CANARY"
      assert error.rule_id =~ "PL-EVIDENCE-"
    end
  end

  test "hashes only reviewed sanitized evidence bytes" do
    assert {:ok, evidence} = Evidence.build(@valid)
    bytes = Jason.encode!(Evidence.to_map(evidence))
    assert {:ok, digest} = Evidence.approved_hash(:evidence_json, bytes)
    assert digest =~ ~r/^[a-f0-9]{64}$/
    assert {:error, _} = Evidence.approved_hash(:unreviewed_binary, "CANARY-TOKEN")
  end

  test "accepts only closed retained identifiers without echoing caller labels" do
    for {field, value, rule_id} <- [
          {:commit_ref, "alice_123", "PL-EVIDENCE-COMMIT"},
          {:commit_ref, "git-0123456789abcdef", "PL-EVIDENCE-COMMIT"},
          {:assertion_ids, ["unreviewed_identifier"], "PL-EVIDENCE-ASSERTION"},
          {:assertion_ids, ["browser_offline_island", "browser_offline_island"],
           "PL-EVIDENCE-ASSERTION"}
        ] do
      assert {:error, error} = Evidence.build(Map.put(@valid, field, value))
      assert error.rule_id == rule_id
      refute inspect(error) =~ "alice_123"
      refute inspect(error) =~ "unreviewed_identifier"
    end
  end

  test "derives retained digests only from approved canonical bytes" do
    assert {:ok, base} = Evidence.build(@valid)
    canonical_bytes = Jason.encode!(Evidence.to_map(base))

    attrs =
      Map.put(@valid, :approved_hashes, [
        %{kind: :evidence_json, canonical_bytes: canonical_bytes}
      ])

    assert {:ok, evidence} = Evidence.build(attrs)
    [hash] = Evidence.to_map(evidence)["approved_hashes"]
    assert hash["digest"] == Base.encode16(:crypto.hash(:sha256, canonical_bytes), case: :lower)

    assert {:error, supplied_digest} =
             Evidence.build(
               Map.put(@valid, :approved_hashes, [
                 %{
                   kind: :evidence_json,
                   canonical_bytes: canonical_bytes,
                   digest: String.duplicate("a", 64)
                 }
               ])
             )

    assert supplied_digest.rule_id == "PL-EVIDENCE-HASH"

    assert {:error, arbitrary_digest} =
             Evidence.build(
               Map.put(@valid, :approved_hashes, [
                 %{kind: :evidence_json, digest: String.duplicate("b", 64)}
               ])
             )

    assert arbitrary_digest.rule_id == "PL-EVIDENCE-HASH"
  end

  test "checks retained non-empty hashes only against matching canonical sources" do
    assert {:ok, base} = Evidence.build(@valid)
    canonical_bytes = Jason.encode!(Evidence.to_map(base))

    assert {:ok, evidence} =
             Evidence.build(
               Map.put(@valid, :approved_hashes, [
                 %{kind: :evidence_json, canonical_bytes: canonical_bytes}
               ])
             )

    with_stage(fn stage ->
      File.write!(
        Path.join(stage, "proof-lane-evidence.json"),
        Jason.encode!(Evidence.to_map(evidence))
      )

      write_complete_marker!(stage)

      assert {:error, missing} = Evidence.check(stage)
      assert missing.rule_id == "PL-EVIDENCE-HASH-SOURCE"

      assert :ok =
               Evidence.check(stage, [%{kind: :evidence_json, canonical_bytes: canonical_bytes}])

      assert {:error, mismatch} =
               Evidence.check(stage, [
                 %{kind: :evidence_json, canonical_bytes: canonical_bytes <> " "}
               ])

      assert mismatch.rule_id == "PL-EVIDENCE-HASH-SOURCE"
    end)
  end

  test "recursively rejects an unexpected staged path after canonical evidence is serialized" do
    with_stage(fn stage ->
      write_canonical!(stage)
      File.mkdir_p!(Path.join(stage, "nested"))
      File.write!(Path.join(stage, "nested/extra.txt"), "safe-looking but unapproved")

      assert {:error, error} = Evidence.scan_stage(stage)
      assert error.rule_id == "PL-EVIDENCE-INTEGRITY"
      refute inspect(error) =~ "safe-looking"
    end)
  end

  test "final scanning rejects malformed closed values without raising or echoing bytes" do
    with_stage(fn stage ->
      write_canonical!(stage)
      path = Path.join(stage, "proof-lane-evidence.json")
      File.write!(path, String.replace(File.read!(path), "\"blocked\"", "\"CANARY-UNKNOWN\""))

      assert {:error, error} = Evidence.scan_stage(stage)
      assert error.rule_id == "PL-EVIDENCE-INTEGRITY"
      refute inspect(error) =~ "CANARY"
    end)
  end

  test "promotion and read-only check retain exactly one canonical artifact" do
    with_destination(fn destination ->
      assert :ok = Evidence.promote(@valid, destination)
      assert :ok = Evidence.check(destination)
      assert File.exists?(Path.join(destination, "proof-lane-evidence.json"))

      marker = Path.join(destination, ".complete")
      artifact = File.read!(Path.join(destination, "proof-lane-evidence.json"))
      assert File.read!(marker) == Base.encode16(:crypto.hash(:sha256, artifact), case: :lower)

      assert {:error, error} = Evidence.promote(@valid, destination)
      assert error.rule_id == "PL-EVIDENCE-COLLISION"
      assert :ok = Evidence.check(destination)
    end)
  end

  test "digest-bound readers reject a retained artifact changed after promotion" do
    with_destination(fn destination ->
      assert :ok = Evidence.promote(@valid, destination)
      artifact = Path.join(destination, "proof-lane-evidence.json")

      File.chmod!(artifact, 0o600)
      File.write!(artifact, File.read!(artifact) <> " ")

      for reader <- [
            &Evidence.scan_stage/1,
            &Evidence.check/1,
            fn path -> Evidence.check(path, []) end
          ] do
        assert {:error, error} = reader.(destination)
        assert error.rule_id == "PL-EVIDENCE-INTEGRITY"
      end
    end)
  end

  test "check/1 consumes the completion-digest-bound snapshot after the artifact is replaced" do
    with_stage(fn stage ->
      write_canonical!(stage)

      with_snapshot_replacement(stage, fn ->
        assert :ok = Evidence.check(stage)
      end)

      assert {:error, error} = Evidence.check(stage)
      assert error.rule_id == "PL-EVIDENCE-INTEGRITY"
    end)
  end

  test "check/2 validates approved sources from the completion-digest-bound snapshot after replacement" do
    assert {:ok, base} = Evidence.build(@valid)
    canonical_bytes = Jason.encode!(Evidence.to_map(base))

    assert {:ok, evidence} =
             Evidence.build(
               Map.put(@valid, :approved_hashes, [
                 %{kind: :evidence_json, canonical_bytes: canonical_bytes}
               ])
             )

    with_stage(fn stage ->
      File.write!(
        Path.join(stage, "proof-lane-evidence.json"),
        Jason.encode!(Evidence.to_map(evidence))
      )

      write_complete_marker!(stage)

      with_snapshot_replacement(stage, fn ->
        assert :ok = Evidence.check(stage, [%{kind: :evidence_json, canonical_bytes: canonical_bytes}])
      end)

      assert {:error, error} = Evidence.check(stage, [%{kind: :evidence_json, canonical_bytes: canonical_bytes}])
      assert error.rule_id == "PL-EVIDENCE-INTEGRITY"
    end)
  end

  test "retained readers reject malformed digest markers without echoing marker bytes" do
    with_destination(fn destination ->
      assert :ok = Evidence.promote(@valid, destination)
      marker = Path.join(destination, ".complete")

      for invalid <- [
            "",
            String.duplicate("A", 64),
            String.duplicate("a", 63),
            String.duplicate("a", 64) <> "\n"
          ] do
        File.chmod!(marker, 0o600)
        File.write!(marker, invalid)
        assert {:error, error} = Evidence.check(destination)
        assert error.rule_id == "PL-EVIDENCE-INTEGRITY"

        if invalid != "", do: refute(inspect(error) =~ invalid)
      end
    end)
  end

  test "failed promotion leaves no destination and check writes nothing" do
    with_destination(fn destination ->
      before = File.ls!(Path.dirname(destination))

      assert {:error, error} =
               Evidence.promote(Map.put(@valid, :token, "CANARY-TOKEN"), destination)

      assert error.rule_id == "PL-EVIDENCE-KEY"
      refute File.exists?(destination)

      stage = destination <> ".check"
      File.mkdir_p!(stage)
      write_canonical!(stage)
      snapshot = File.read!(Path.join(stage, "proof-lane-evidence.json"))
      assert :ok = Evidence.check(stage)
      assert snapshot == File.read!(Path.join(stage, "proof-lane-evidence.json"))

      assert before ==
               File.ls!(Path.dirname(destination)) |> Enum.reject(&(&1 == Path.basename(stage)))
    end)
  end

  test "concurrent promoters preserve one winner and return a stable loser result" do
    with_destination(fn destination ->
      results =
        1..2
        |> Task.async_stream(fn _ -> Evidence.promote(@valid, destination) end, ordered: false)
        |> Enum.map(fn {:ok, result} -> result end)

      assert Enum.count(results, &(&1 == :ok)) == 1
      assert Enum.any?(results, &match?({:error, %{rule_id: "PL-EVIDENCE-COLLISION"}}, &1))
      assert :ok = Evidence.check(destination)
    end)
  end

  test "post-scan collision preserves a concurrent destination byte-for-byte" do
    with_destination(fn destination ->
      sentinel = Path.join(destination, "winner.txt")

      assert {:error, error} =
               Evidence.promote(@valid, destination,
                 before_promote: fn ->
                   File.mkdir_p!(destination)
                   File.write!(sentinel, "concurrent winner")
                 end
               )

      assert error.rule_id == "PL-EVIDENCE-COLLISION"
      assert File.read!(sentinel) == "concurrent winner"
      assert [] == Path.wildcard(destination <> ".stage-*")
    end)
  end

  test "promotion accepts only an :ok lifecycle-hook result and cleans malformed hook failures" do
    with_destination(fn destination ->
      for value <- [
            nil,
            true,
            false,
            {:error, "CANARY-TUPLE"},
            %{canary: "CANARY-MAP"},
            {:error, %{raw_output: "CANARY-NATIVE"}},
            @valid,
            destination,
            42
          ] do
        assert {:error, error} =
                 Evidence.promote(@valid, destination, before_promote: fn -> value end)

        assert_promotion_hook_failure!(error, destination, "CANARY")
        refute inspect(error) =~ @valid.route_id
        refute inspect(error) =~ destination
      end
    end)

    with_destination(fn destination ->
      assert :ok = Evidence.promote(@valid, destination, before_promote: fn -> :ok end)
      assert :ok = Evidence.check(destination)
    end)
  end

  test "promotion normalizes lifecycle-hook raises throws and exits without retaining artifacts" do
    for hook <- [
          fn -> raise "CANARY-RAISE" end,
          fn -> throw({:canary, "CANARY-THROW"}) end,
          fn -> exit({:canary, "CANARY-EXIT"}) end
        ] do
      with_destination(fn destination ->
        assert {:error, error} = Evidence.promote(@valid, destination, before_promote: hook)

        assert_promotion_hook_failure!(error, destination, "CANARY")
      end)
    end
  end

  test "native promotion fails closed for unsupported platforms and compiler seams" do
    alias Crosswake.ProofLane.NativePromotion

    with_destination(fn destination ->
      stage = destination <> ".stage-test"
      File.mkdir_p!(stage)

      assert {:error, unsupported} =
               NativePromotion.rename_noreplace(stage, destination, os_type: {:win32, :nt})

      assert unsupported.rule_id == "PL-EVIDENCE-PROMOTION-UNAVAILABLE"

      assert {:error, compiler} =
               NativePromotion.rename_noreplace(stage, destination, compiler: "missing-compiler")

      assert compiler.rule_id == "PL-EVIDENCE-PROMOTION-UNAVAILABLE"
    end)
  end

  defp write_canonical!(stage) do
    assert {:ok, evidence} = Evidence.build(@valid)

    File.write!(
      Path.join(stage, "proof-lane-evidence.json"),
      Jason.encode!(Evidence.to_map(evidence))
    )

    write_complete_marker!(stage)
  end

  defp write_complete_marker!(stage) do
    artifact = File.read!(Path.join(stage, "proof-lane-evidence.json"))

    File.write!(
      Path.join(stage, ".complete"),
      Base.encode16(:crypto.hash(:sha256, artifact), case: :lower)
    )
  end

  defp assert_promotion_hook_failure!(error, destination, canary) do
    assert error.rule_id == "PL-EVIDENCE-PROMOTE"
    assert error.path == "artifact"
    refute inspect(error) =~ canary
    refute File.exists?(destination)
    assert [] == Path.wildcard(destination <> ".stage-*")
  end

  defp with_snapshot_replacement(stage, fun) do
    artifact = Path.join(stage, "proof-lane-evidence.json")
    test_pid = self()

    Process.put({Evidence, :after_digest_barrier}, fn ->
      File.write!(artifact, "CANARY-REPLACEMENT")
      send(test_pid, :evidence_snapshot_replaced)
      :ok
    end)

    try do
      fun.()
      assert_receive :evidence_snapshot_replaced
    after
      Process.delete({Evidence, :after_digest_barrier})
    end
  end

  defp with_stage(fun) do
    root =
      Path.join(System.tmp_dir!(), "crosswake-evidence-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)

    try do
      fun.(root)
    after
      File.rm_rf(root)
    end
  end

  defp with_destination(fun) do
    root =
      Path.join(System.tmp_dir!(), "crosswake-evidence-#{System.unique_integer([:positive])}")

    File.mkdir_p!(root)
    destination = Path.join(root, "final")

    try do
      fun.(destination)
    after
      File.rm_rf(root)
    end
  end
end
