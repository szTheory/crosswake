unless Code.ensure_loaded?(Crosswake.ReleaseCandidate) do
  defmodule Crosswake.ReleaseCandidate do
    def evaluate!(_input), do: %{state: :not_implemented}
  end

  defmodule Crosswake.ReleaseCandidate.Receipt do
    def validate!(_receipt), do: raise(ArgumentError, "not implemented")
    def encode!(_receipt), do: "not implemented"
  end

  defmodule Crosswake.ReleaseCandidate.Projection do
    def markdown(_receipt), do: "not implemented"
    def github_summary(_receipt), do: "not implemented"
    def terminal(_receipt, _opts \\ []), do: "not implemented"
  end
end

defmodule Crosswake.ReleaseCandidate.ReceiptTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate
  alias Crosswake.ReleaseCandidate.{Projection, Receipt}

  @sha_a String.duplicate("a", 40)
  @sha_b String.duplicate("b", 40)
  @sha_c String.duplicate("c", 40)
  @digest_a String.duplicate("1", 64)
  @digest_b String.duplicate("2", 64)
  @digest_c String.duplicate("3", 64)
  @privacy_canary "private-token-should-never-appear"

  test "complete reversible proof yields exactly READY FOR APPROVAL" do
    receipt = evaluate()

    assert receipt.state == "READY FOR APPROVAL"
    assert receipt.next_action == "approve_exact_candidate"
    assert receipt.credentials.mirror_write_authority == "PROVEN"
    assert receipt.external_state.changed == false
  end

  test "every bound identity mutation independently makes a ready receipt stale" do
    mutations = [
      version: &put_in(&1, [:version], "0.2.2"),
      ref: &put_in(&1, [:ref], @sha_b),
      head: &put_in(&1, [:head], @sha_b),
      tree: &put_in(&1, [:tree], @sha_b),
      base: &put_in(&1, [:base], @sha_b),
      coordinate: &put_in(&1, [:coordinates, Access.at(0), :coordinate], "crosswake@0.2.2"),
      config_digest: &put_in(&1, [:config_digests, Access.at(0), :sha256], @digest_b),
      workflow_digest: &put_in(&1, [:workflow_digests, Access.at(0), :sha256], @digest_b),
      package_outer_digest:
        &put_in(&1, [:package_digests, Access.at(0), :outer_sha256], @digest_b),
      package_payload_digest:
        &put_in(&1, [:package_digests, Access.at(0), :payload_sha256], @digest_b),
      package_metadata_digest:
        &put_in(&1, [:package_digests, Access.at(0), :metadata_sha256], @digest_b),
      proof_result: &put_in(&1, [:proofs, Access.at(0), :status], "FAIL"),
      proof_digest: &put_in(&1, [:proofs, Access.at(0), :sha256], @digest_b),
      mirror_split: &put_in(&1, [:mirror, :split], @sha_b),
      mirror_main: &put_in(&1, [:mirror, :main], @sha_c),
      mirror_tag: &put_in(&1, [:mirror, :tag], "v0.2.2"),
      mirror_plan_digest: &put_in(&1, [:mirror, :plan_sha256], @digest_b),
      run_id: &put_in(&1, [:run, :id], 5678),
      run_head: &put_in(&1, [:run, :head], @sha_b),
      run_status: &put_in(&1, [:run, :status], "QUEUED"),
      run_conclusion: &put_in(&1, [:run, :conclusion], "FAILURE")
    ]

    for {name, mutate} <- mutations do
      receipt = evaluate(observed_identity: mutate.(identity()))
      assert receipt.state == "STALE", "#{name} remained ready"
      assert receipt.next_action == "recapture_candidate"
    end
  end

  test "the evaluator exposes only the closed five-state transition vocabulary" do
    receipts = [
      evaluate(),
      evaluate(observed_identity: put_in(identity(), [:tree], @sha_b)),
      evaluate(checks: [%{id: "candidate.package", status: "MISSING"}]),
      evaluate(
        external_state: %{
          publication: "PARTIAL",
          successful_coordinates: ["hex:crosswake@0.2.1"],
          failed_step: "ios_mirror",
          changed: true,
          all_linked_proven: false
        }
      ),
      evaluate(
        external_state: %{
          publication: "COMPLETE",
          successful_coordinates: [
            "hex:crosswake@0.2.1",
            "ios:crosswake@0.2.1",
            "maven:crosswake@0.2.1"
          ],
          failed_step: nil,
          changed: true,
          all_linked_proven: true
        }
      )
    ]

    assert Enum.map(receipts, & &1.state) == [
             "READY FOR APPROVAL",
             "STALE",
             "BLOCKED",
             "PARTIAL",
             "COMPLETE"
           ]

    for receipt <- receipts do
      assert Receipt.validate!(receipt) == receipt
      assert receipt.next_action in ~w(
        approve_exact_candidate
        recapture_candidate
        resolve_blocked_evidence
        recover_failed_coordinate
        no_action_required
      )
    end
  end

  test "missing credentials and unresolved evidence fail closed" do
    for authority <- ["NOT CHECKED", "DENIED"] do
      receipt =
        evaluate(credentials: %{mirror_write_authority: authority, exercised: false})

      assert receipt.state == "BLOCKED"
      assert receipt.credentials.mirror_write_authority == authority
    end

    for status <- ["FAIL", "MISSING", "AMBIGUOUS"] do
      receipt = evaluate(checks: [%{id: "candidate.package", status: status}])
      assert receipt.state == "BLOCKED"
    end
  end

  test "unknown, malformed, empty, and contradictory authority fails without echoing input" do
    invalid_inputs = [
      Map.put(input(), :token, @privacy_canary),
      put_in(input(), [:identity, :actor], @privacy_canary),
      put_in(input(), [:identity, :ref], "abc1234"),
      put_in(input(), [:identity, :proofs], []),
      put_in(input(), [:identity, :run, :head], @sha_b),
      put_in(input(), [:checks], []),
      put_in(input(), [:external_state, :failed_step], @privacy_canary),
      put_in(input(), [:credentials, :secret], @privacy_canary)
    ]

    for invalid <- invalid_inputs do
      error = assert_raise ArgumentError, fn -> ReleaseCandidate.evaluate!(invalid) end
      refute Exception.message(error) =~ @privacy_canary
    end

    ready = evaluate()

    for invalid_receipt <- [
          Map.put(ready, :private_url, @privacy_canary),
          Map.put(ready, :state, "PENDING"),
          Map.put(ready, :state, "COMPLETE"),
          put_in(ready, [:identity, :token], @privacy_canary)
        ] do
      error = assert_raise ArgumentError, fn -> Receipt.validate!(invalid_receipt) end
      refute Exception.message(error) =~ @privacy_canary
    end
  end

  test "canonical JSON and all projections are deterministic and privacy-safe" do
    receipt = evaluate()
    json_1 = Receipt.encode!(receipt)
    json_2 = Receipt.encode!(evaluate())
    markdown = Projection.markdown(receipt)
    github = Projection.github_summary(receipt)
    terminal = Projection.terminal(receipt, no_color: true)

    assert json_1 == json_2
    assert Jason.decode!(json_1)["state"] == "READY FOR APPROVAL"

    for projection <- [markdown, github, terminal] do
      assert String.starts_with?(projection, "READY FOR APPROVAL")
      assert projection =~ "approve_exact_candidate"
      assert projection =~ "credentials exercised: yes"
      assert projection =~ "external state changed: no"
      refute projection =~ @privacy_canary
      refute projection =~ IO.ANSI.escape_fragment([:green])
    end

    assert terminal == Projection.terminal(receipt, no_color: false)
  end

  defp evaluate(overrides \\ []) do
    overrides
    |> Enum.reduce(input(), fn {key, value}, acc -> Map.put(acc, key, value) end)
    |> ReleaseCandidate.evaluate!()
  end

  defp input do
    %{
      identity: identity(),
      observed_identity: identity(),
      checks: [%{id: "candidate.package", status: "PASS"}],
      external_state: %{
        publication: "NONE",
        successful_coordinates: [],
        failed_step: nil,
        changed: false,
        all_linked_proven: false
      },
      credentials: %{mirror_write_authority: "PROVEN", exercised: true}
    }
  end

  defp identity do
    %{
      version: "0.2.1",
      ref: @sha_a,
      head: @sha_a,
      tree: @sha_b,
      base: @sha_c,
      coordinates: [
        %{id: "hex-core", coordinate: "crosswake@0.2.1"},
        %{id: "ios-core", coordinate: "crosswake@0.2.1"},
        %{id: "android-core", coordinate: "crosswake@0.2.1"}
      ],
      config_digests: [
        %{id: "release-please-config", sha256: @digest_a},
        %{id: "release-please-manifest", sha256: @digest_b}
      ],
      workflow_digests: [%{id: "release-please", sha256: @digest_c}],
      package_digests: [
        %{
          id: "crosswake",
          outer_sha256: @digest_a,
          payload_sha256: @digest_b,
          metadata_sha256: @digest_c
        }
      ],
      proofs: [%{id: "package-audit", status: "PASS", sha256: @digest_a}],
      mirror: %{
        split: @sha_a,
        main: @sha_b,
        tag: "v0.2.1",
        plan_sha256: @digest_c
      },
      run: %{id: 1234, head: @sha_a, status: "COMPLETED", conclusion: "SUCCESS"}
    }
  end
end
