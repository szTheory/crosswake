defmodule CrosswakeExample.E2E.TwinFaultControllerTest do
  use ExUnit.Case, async: false

  import Ecto.Query, warn: false
  import Phoenix.ConnTest

  alias CrosswakeExample.E2E.TwinFaultController
  alias CrosswakeExample.LocalFirst.ReviewEvent
  alias CrosswakeExample.Repo

  @endpoint CrosswakeExample.Endpoint

  @table :crosswake_twin_run_state
  @scope "v1.scope_fixture_alpha_01"

  # Frozen once from the tracked public reference fixture and recorded in 180-IDENTITY.json.
  @media_size 33_706
  @media_sha256 "5d8b3f72beb26205032d764bc7979f5658c7c9f262427bce2d814f2bf0fabf5b"

  setup do
    reset_table()
    delete_test_rows()

    on_exit(fn ->
      reset_table()
      delete_test_rows()
    end)

    :ok
  end

  defp reset_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ok

      _ref ->
        owner = :ets.info(@table, :owner)
        Process.exit(owner, :kill)
        wait_until(fn -> :ets.whereis(@table) == :undefined end)
    end
  end

  defp wait_until(fun, attempts \\ 100) do
    cond do
      fun.() -> :ok
      attempts == 0 -> flunk("condition not reached")
      true -> Process.sleep(10) && wait_until(fun, attempts - 1)
    end
  end

  defp delete_test_rows do
    Repo.delete_all(from(r in ReviewEvent, where: like(r.client_mutation_id, "twin-test-%")))
  end

  defp event(suffix, card \\ 1),
    do: %{
      "client_mutation_id" => "twin-test-#{System.unique_integer([:positive])}-#{suffix}",
      "card_id" => card,
      "rating" => "good"
    }

  defp api_conn do
    Phoenix.ConnTest.build_conn() |> Plug.Conn.put_req_header("accept", "application/json")
  end

  defp session_conn do
    api_conn()
    |> post("/_e2e/replay-session", %{"action" => "establish"})
    |> recycle()
    |> Plug.Conn.put_req_header("accept", "application/json")
  end

  defp prepare(kind, extra \\ %{}) do
    conn = post(api_conn(), "/_e2e/twin/fault", Map.put(extra, "kind", kind))
    assert conn.status == 204
  end

  defp sync(events) do
    conn = post(session_conn(), "/study/sync", %{"scope_ref" => @scope, "events" => events})
    {conn.status, Jason.decode!(conn.resp_body)}
  end

  defp observe do
    conn = get(api_conn(), "/_e2e/twin/observe")
    assert conn.status == 200
    Jason.decode!(conn.resp_body)["data"]
  end

  defp stored(id), do: Repo.get_by(ReviewEvent, client_mutation_id: id)

  test "fault preparation accepts the closed kinds with 204 and rejects anything else with a closed error id" do
    for kind <-
          ~w(replay_reject replay_conflict entry_disable replay_disable media_missing media_corrupt clear) do
      prepare(kind)
    end

    conn = post(api_conn(), "/_e2e/twin/fault", %{"kind" => "grant_authority"})
    assert conn.status == 422
    assert %{"error" => %{"class" => "invalid_fault_kind"}} = Jason.decode!(conn.resp_body)

    conn = post(api_conn(), "/_e2e/twin/fault", %{})
    assert conn.status == 422
  end

  test "replay_reject yields a rejected record from the real Study path and never an accepted row" do
    event = event("reject")
    prepare("replay_reject", %{"card_id" => 1})

    assert {200, %{"data" => data}} = sync([event])
    assert data["halted"] == "rejected"
    assert data["accepted_records"] == []
    assert [%{"client_mutation_id" => id, "outcome" => "rejected"}] = data["rejected"]
    assert id == event["client_mutation_id"]

    row = stored(event["client_mutation_id"])
    assert row.status == "rejected"

    assert Repo.aggregate(
             from(r in ReviewEvent,
               where: r.client_mutation_id == ^row.client_mutation_id and r.status == "accepted"
             ),
             :count,
             :id
           ) == 0

    other = event("other-card", 2)

    assert {200, %{"data" => %{"accepted_records" => [%{"outcome" => "accepted"}]}}} =
             sync([other])
  end

  test "replay_conflict yields the real scope_conflict outcome and retains no accepted row" do
    event = event("conflict")
    prepare("replay_conflict")

    assert {200, %{"data" => data}} = sync([event])
    assert data["halted"] == "transaction_failed"
    assert data["rejected"] == [%{"class" => "scope_conflict"}]
    assert data["accepted_records"] == []
    refute stored(event["client_mutation_id"]).scope_ref == @scope
    assert observe()["scope_conflict"] == 1
  end

  test "entry_disable and replay_disable make the owners deny and write no ReviewEvent row" do
    entry = event("entry")
    prepare("entry_disable")
    assert {403, %{"error" => %{"class" => "feature_disabled"}}} = sync([entry])
    assert stored(entry["client_mutation_id"]) == nil

    prepare("clear")
    replay = event("replay")
    prepare("replay_disable")
    assert {403, %{"error" => %{"class" => "authorization_denied"}}} = sync([replay])
    assert stored(replay["client_mutation_id"]) == nil

    counters = observe()
    assert counters["feature_disabled"] == 1
    assert counters["authorization_denied"] == 1
  end

  test "clear lifts every prepared fault and the real path accepts again" do
    prepare("entry_disable")
    prepare("clear")
    event = event("cleared")

    assert {200, %{"data" => %{"accepted_records" => [%{"outcome" => "accepted"}]}}} =
             sync([event])

    assert stored(event["client_mutation_id"]).status == "accepted"
  end

  test "reference media is served with the frozen identity and can be prepared missing or corrupt" do
    conn = get(Phoenix.ConnTest.build_conn(), "/_e2e/twin/media/pronunciation")
    assert conn.status == 200
    bytes = conn.resp_body
    assert byte_size(bytes) == @media_size
    assert Base.encode16(:crypto.hash(:sha256, bytes), case: :lower) == @media_sha256

    prepare("media_missing")
    assert get(Phoenix.ConnTest.build_conn(), "/_e2e/twin/media/pronunciation").status == 404
    prepare("clear")

    prepare("media_corrupt")
    corrupt = get(Phoenix.ConnTest.build_conn(), "/_e2e/twin/media/pronunciation")
    assert corrupt.status == 200
    assert byte_size(corrupt.resp_body) == byte_size(bytes)
    assert corrupt.resp_body != bytes

    differing =
      Enum.count(
        Enum.zip(:binary.bin_to_list(bytes), :binary.bin_to_list(corrupt.resp_body)),
        fn {a, b} -> a != b end
      )

    assert differing == 1

    assert get(Phoenix.ConnTest.build_conn(), "/_e2e/twin/media/unknown").status == 404
  end

  test "observe returns only closed integer counters and counts duplicate deliveries without exposing ids" do
    prepare("clear")
    event = event("counted")
    assert {200, _} = sync([event])
    assert {200, _} = sync([event])

    body = get(api_conn(), "/_e2e/twin/observe")
    assert body.status == 200
    data = Jason.decode!(body.resp_body)["data"]

    assert Enum.all?(Map.values(data), &is_integer/1)

    assert Enum.sort(Map.keys(data)) ==
             Enum.sort(~w(admitted duplicate_delivery rejected scope_conflict transaction_failed
                          invalid_envelope scope_mismatch feature_disabled sigra_denied
                          authorization_denied authority_unavailable
                          synthetic_authority_admitted other_authority_admitted))

    assert data["admitted"] == 2
    assert data["duplicate_delivery"] == 1
    assert data["synthetic_authority_admitted"] == 2
    assert data["other_authority_admitted"] == 0
    refute String.contains?(body.resp_body, event["client_mutation_id"])
  end

  test "observe_result is a no-op when the run-owned table does not exist" do
    assert :ets.whereis(@table) == :undefined
    assert TwinFaultController.observe_result(event("noop"), :accepted) == :ok
    assert TwinFaultController.fault_active?("replay_disable") == false
    assert :ets.whereis(@table) == :undefined
  end

  test "build identity is one sha256 over the sorted module md5s of the application" do
    conn = get(api_conn(), "/_e2e/twin/build")
    assert conn.status == 200
    assert %{"data" => %{"build_sha256" => sha}} = Jason.decode!(conn.resp_body)
    assert sha =~ ~r/\A[0-9a-f]{64}\z/

    expected =
      :crosswake_example
      |> Application.spec(:modules)
      |> Enum.map(&(&1.module_info(:md5) |> Base.encode16(case: :lower)))
      |> Enum.sort()
      |> Enum.join("\n")
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)

    assert sha == expected
  end

  test "twin routes exist only inside the single compile-time /_e2e guard" do
    routes = Phoenix.Router.routes(CrosswakeExample.Router)

    for {verb, path} <- [
          {:post, "/_e2e/twin/fault"},
          {:get, "/_e2e/twin/media/:asset"},
          {:get, "/_e2e/twin/observe"},
          {:get, "/_e2e/twin/build"}
        ] do
      assert Enum.any?(routes, &(&1.verb == verb and &1.path == path)),
             "#{verb} #{path} missing in test"
    end

    source = File.read!(Path.expand("../../../lib/crosswake_example/router.ex", __DIR__))
    guard = "if Mix.env() in [:test, :e2e] do"
    assert length(String.split(source, guard)) == 2, "exactly one guard block"

    [_before, guarded] = String.split(source, guard)

    for needle <- [
          ~s|post("/fault", TwinFaultController|,
          ~s|get("/media/:asset", TwinFaultController|,
          ~s|get("/observe", TwinFaultController|,
          ~s|get("/build", TwinFaultController|
        ] do
      assert String.contains?(guarded, needle)
      refute String.contains?(hd(String.split(source, guard)), needle)
    end
  end
end
