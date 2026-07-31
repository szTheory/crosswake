defmodule Crosswake.ProofLane.EvidenceTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.Evidence

  @valid %{
    schema_version: "1",
    crosswake_version: "1.0.0",
    template_version: "1",
    commit_ref: "commit-abc123",
    route_id: "route-0123456789abcdef",
    assertion_ids: ["offline_island"],
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
end
