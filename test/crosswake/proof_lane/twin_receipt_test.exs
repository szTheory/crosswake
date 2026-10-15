defmodule Crosswake.ProofLane.TwinReceiptTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.TwinReceipt

  @run_id "twin-0123456789abcdef"
  @head String.duplicate("a", 40)
  @tree String.duplicate("b", 40)
  @digest String.duplicate("c", 64)

  defp expectations(extra \\ %{}) do
    {:ok, expectations} =
      TwinReceipt.freeze_expectations(
        Map.merge(
          %{
            run_id: @run_id,
            candidate_head: @head,
            candidate_tree: @tree,
            lock_digests: [@digest],
            resource_digests: [String.duplicate("d", 64)],
            fixture_digests: [String.duplicate("e", 64)]
          },
          extra
        )
      )

    expectations
  end

  defp obs(id, owner, attrs \\ %{}) do
    base = %{id: id, owner: owner, run_id: @run_id, outcome: :passed, measure: nil, cause: nil}
    TwinReceipt.observation(Map.merge(base, attrs))
  end

  defp all_observations(overrides \\ %{}) do
    for %{sub_observations: subs} <- TwinReceipt.roster(),
        %{id: id, owner: owner} <- subs,
        id != "TW-T10-02" do
      attrs = Map.get(overrides, id, %{})
      {:ok, o} = obs(id, owner, attrs)
      o
    end
  end

  defp observed(exp), do: exp.joins

  test "complete roster bound to one run derives passed" do
    exp = expectations()
    assert {:ok, receipt} = TwinReceipt.derive(exp, observed(exp), all_observations())
    assert receipt.overall_status == :passed
    assert receipt.evidence_class == "virtual_twin"
    assert Enum.map(receipt.groups, & &1.id) == ~w(T01 T02 T03 T04 T05 T06 T07 T08 T09 T10)
    assert length(receipt.groups) == 10
    assert Enum.all?(receipt.groups, &(&1.status == :passed))
    assert length(TwinReceipt.roster_ids()) == 49
    assert hd(TwinReceipt.roster_ids()) == "TW-T01-01"
    assert List.last(TwinReceipt.roster_ids()) == "TW-T10-08"
    assert TwinReceipt.exit_status_for(TwinReceipt.status(receipt)) == 0
  end

  test "missing observation derives blocked; contradiction wins over unavailable" do
    exp = expectations()
    missing = Enum.reject(all_observations(), &(&1.id == "TW-T06-03"))
    assert {:ok, receipt} = TwinReceipt.derive(exp, observed(exp), missing)
    assert receipt.overall_status == :blocked

    entry =
      receipt.groups |> Enum.flat_map(& &1.sub_observations) |> Enum.find(&(&1.id == "TW-T06-03"))

    assert %{outcome: :blocked, cause: :observation_missing} = entry
    assert %{id: "TW-T06-03", cause: :observation_missing} = TwinReceipt.first_cause(receipt)

    overrides = %{"TW-T03-01" => %{outcome: :failed, cause: :contradiction_observed}}
    mixed = all_observations(overrides) |> Enum.reject(&(&1.id == "TW-T06-03"))
    assert {:ok, failed} = TwinReceipt.derive(exp, observed(exp), mixed)
    assert failed.overall_status == :failed
    assert TwinReceipt.exit_status_for(TwinReceipt.status(failed)) == 1
    assert %{id: "TW-T03-01"} = TwinReceipt.first_cause(failed)
  end

  test "fabricated owner, stale run, reused run and duplicates are rejected" do
    exp = expectations()
    assert {:error, %{rule_id: "TW-OBS-OWNER"}} = obs("TW-T03-01", :host_adapter)

    other = "twin-fedcba9876543210"
    {:ok, stale} = obs("TW-T01-01", :host_adapter, %{run_id: other})

    assert {:error, %{rule_id: "TW-OBS-STALE"}} =
             TwinReceipt.derive(exp, observed(exp), [stale | all_observations()])

    reused_exp = expectations(%{consumed_run_ids: [@run_id]})

    assert {:error, %{rule_id: "TW-OBS-REUSED"}} =
             TwinReceipt.derive(reused_exp, observed(reused_exp), all_observations())

    [first | _] = all_observations()

    assert {:error, %{rule_id: "TW-OBS-DUPLICATE"}} =
             TwinReceipt.derive(exp, observed(exp), [first | all_observations()])

    tampered = %{first | owner: :runner}

    assert {:error, %{rule_id: "TW-OBS-OWNER"}} =
             TwinReceipt.derive(exp, observed(exp), [tampered])
  end

  test "mismatched frozen identities derive failed and unknown ones block TW-T10-02" do
    exp = expectations()

    for join <- TwinReceipt.identity_joins() do
      wrong = Map.put(observed(exp), join, String.duplicate("0", 64))
      assert {:ok, receipt} = TwinReceipt.derive(exp, wrong, all_observations())
      assert receipt.overall_status == :failed

      entry =
        receipt.groups
        |> Enum.flat_map(& &1.sub_observations)
        |> Enum.find(&(&1.id == "TW-T10-02"))

      assert %{outcome: :failed, cause: :identity_mismatch} = entry
      assert Enum.find(receipt.identity_joins, &(&1.id == join)).outcome == :failed
    end

    unknown = Map.delete(observed(exp), :installed_media)
    assert {:ok, receipt} = TwinReceipt.derive(exp, unknown, all_observations())
    assert receipt.overall_status == :blocked

    assert {:error, %{rule_id: "TW-IDENT-KEY"}} =
             TwinReceipt.derive(exp, Map.put(observed(exp), :bogus, @digest), all_observations())
  end

  test "extra keys, open values, bounds and sensitive field names are rejected at source" do
    base = %{
      id: "TW-T03-01",
      owner: :webview,
      run_id: @run_id,
      outcome: :passed,
      measure: 2,
      cause: nil
    }

    assert {:ok, _} = TwinReceipt.observation(base)
    assert {:error, %{rule_id: "TW-OBS-KEY"}} = TwinReceipt.observation(Map.put(base, :note, "x"))

    assert {:error, %{rule_id: "TW-OBS-OUTCOME"}} =
             TwinReceipt.observation(%{base | outcome: "passed"})

    assert {:error, %{rule_id: "TW-OBS-CAUSE"}} =
             TwinReceipt.observation(%{base | outcome: :failed, cause: :free_text})

    assert {:error, %{rule_id: "TW-OBS-CAUSE"}} =
             TwinReceipt.observation(%{base | cause: :host_denied})

    assert {:error, %{rule_id: "TW-OBS-MEASURE"}} =
             TwinReceipt.observation(%{base | measure: 1_000_001})

    assert {:error, %{rule_id: "TW-OBS-MEASURE"}} = TwinReceipt.observation(%{base | measure: -1})
    assert {:ok, _} = TwinReceipt.observation(%{base | measure: 1_000_000})
    assert {:ok, _} = TwinReceipt.observation(%{base | measure: 0})

    assert {:error, %{rule_id: "TW-OBS-MEASURE"}} =
             TwinReceipt.observation(%{base | measure: 1.5})

    for key <- [
          :answer,
          :transcript,
          :token,
          :credential,
          :account_id,
          :scope_ref,
          :device_id,
          :media_bytes
        ] do
      assert {:error, %{rule_id: "TW-OBS-SENSITIVE"}} =
               TwinReceipt.observation(Map.put(base, key, "x"))
    end

    assert TwinReceipt.safe_cause("anything unsafe") == :cause_not_retained
    assert TwinReceipt.safe_cause(:child_timeout) == :child_timeout
  end

  test "source_dirty is a retained cause and the fidelity limits name the edit-then-revert gap" do
    assert TwinReceipt.safe_cause(:source_dirty) == :source_dirty

    assert TwinReceipt.fidelity_limits() == [
             "simulator not physical speaker",
             "simulator not signed device",
             "synthetic_test_authority not real adopter",
             "trusted local runner not cryptographic certification",
             "source edit made and reverted during a run not detected"
           ]
  end

  test "physical and adopter relabels and promotion fields are rejected" do
    exp = expectations()

    base = %{
      id: "TW-T03-01",
      owner: :webview,
      run_id: @run_id,
      outcome: :passed,
      measure: nil,
      cause: nil
    }

    assert {:error, %{rule_id: "TW-OBS-RELABEL"}} =
             TwinReceipt.observation(Map.put(base, :evidence_class, "physical_iphone"))

    assert {:error, %{rule_id: "TW-OBS-RELABEL"}} =
             TwinReceipt.observation(Map.put(base, :promotion, true))

    {:ok, receipt} = TwinReceipt.derive(exp, observed(exp), all_observations())

    for class <- ["physical_iphone", "adopter"] do
      assert {:error, %{rule_id: "TW-RCPT-RELABEL"}} =
               TwinReceipt.validate(%{receipt | evidence_class: class})
    end

    assert {:error, %{rule_id: "TW-OBS-RELABEL"}} =
             TwinReceipt.validate(Map.put(receipt, :promotion, %{}))

    assert {:error, %{rule_id: "TW-OBS-RELABEL"}} =
             TwinReceipt.validate(Map.put(receipt, :physical_iphone, true))
  end

  test "structure: missing, extra, duplicated, reordered groups and entries are rejected" do
    exp = expectations()
    {:ok, receipt} = TwinReceipt.derive(exp, observed(exp), all_observations())

    assert {:error, _} = TwinReceipt.validate(%{receipt | groups: tl(receipt.groups)})

    assert {:error, _} =
             TwinReceipt.validate(%{receipt | groups: receipt.groups ++ [hd(receipt.groups)]})

    assert {:error, _} = TwinReceipt.validate(%{receipt | groups: Enum.reverse(receipt.groups)})
    assert {:error, _} = TwinReceipt.validate(%{receipt | groups: []})

    [g1 | rest] = receipt.groups
    dropped = %{g1 | sub_observations: tl(g1.sub_observations)}
    assert {:error, _} = TwinReceipt.validate(%{receipt | groups: [dropped | rest]})
    dup = %{g1 | sub_observations: [hd(g1.sub_observations) | g1.sub_observations]}
    assert {:error, _} = TwinReceipt.validate(%{receipt | groups: [dup | rest]})
    swapped = %{g1 | sub_observations: Enum.reverse(g1.sub_observations)}
    assert {:error, _} = TwinReceipt.validate(%{receipt | groups: [swapped | rest]})
    assert {:error, _} = TwinReceipt.validate(%{receipt | overall_status: :failed})

    assert {:error, _} =
             TwinReceipt.validate(%{receipt | groups: [%{g1 | status: :blocked} | rest]})

    assert {:error, _} = TwinReceipt.validate(Map.put(receipt, :extra, 1))
    assert {:error, _} = TwinReceipt.validate(%{})
  end

  test "serialize, re-read and validate round-trips unchanged" do
    exp = expectations()

    overrides = %{
      "TW-T07-02" => %{outcome: :blocked, cause: :unavailable_observation, measure: 7}
    }

    {:ok, receipt} = TwinReceipt.derive(exp, observed(exp), all_observations(overrides))
    bytes = TwinReceipt.encode!(receipt)
    assert {:ok, ^receipt} = TwinReceipt.decode(bytes)
    assert bytes == TwinReceipt.encode!(receipt)
    assert {:error, _} = TwinReceipt.decode("{}")
    assert {:error, _} = TwinReceipt.decode("not json")
    refute bytes =~ ~r/B2C/i
  end

  test "project/2 returns exactly the pinned closed key set" do
    exp = expectations()
    {:ok, receipt} = TwinReceipt.derive(exp, observed(exp), all_observations())
    assert {:ok, projection} = TwinReceipt.project(receipt, 0)
    decoded = projection |> Jason.encode!() |> Jason.decode!()

    assert decoded |> Map.keys() |> Enum.sort() ==
             Enum.sort(~w(schema run_id exit_status overall_status groups identity_joins
                          fidelity_limits residual_external_gates receipt_sha256))

    assert decoded["schema"] == "crosswake.twin_result/1"
    assert decoded["exit_status"] == 0
    assert decoded["overall_status"] == "passed"
    assert length(decoded["groups"]) == 10
    assert Enum.map(decoded["groups"], & &1["id"]) == ~w(T01 T02 T03 T04 T05 T06 T07 T08 T09 T10)

    for g <- decoded["groups"] do
      assert g |> Map.keys() |> Enum.sort() == ["id", "status", "sub_observations"]

      for e <- g["sub_observations"] do
        assert e |> Map.keys() |> Enum.sort() == ["cause", "id", "outcome", "owner"]
      end
    end

    assert decoded["receipt_sha256"] =~ ~r/\A[0-9a-f]{64}\z/
    assert decoded["receipt_sha256"] == TwinReceipt.receipt_sha256(receipt)
    assert {:error, %{rule_id: "TW-PROJ-EXIT"}} = TwinReceipt.project(receipt, 1)
  end

  test "exit status mapping degrades unknown values to 2" do
    assert TwinReceipt.exit_status_for(:passed) == 0
    assert TwinReceipt.exit_status_for(:failed) == 1
    assert TwinReceipt.exit_status_for(:blocked) == 2
    assert TwinReceipt.exit_status_for("TW-UNKNOWN-RULE") == 2
    assert TwinReceipt.exit_status_for(nil) == 2
  end

  test "module is independent of the physical-device contract and public text avoids the codename" do
    source = File.read!("lib/crosswake/proof_lane/twin_receipt.ex")
    refute source =~ "PhysicalIphoneContract"
    refute source =~ "Evidence.promote"
    refute source =~ "B2C"
  end
end
