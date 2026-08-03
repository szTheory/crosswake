defmodule CrosswakeExample.LocalFirst.ReplayAuthTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias CrosswakeExample.LocalFirst.ReviewEvent
  alias CrosswakeExample.Repo

  @endpoint CrosswakeExample.Endpoint
  @scope "v1.request_bound_scope_001"

  setup do
    previous = Application.get_env(:crosswake_example, :offline_study_replay_authority)
    Application.put_env(:crosswake_example, :offline_study_replay_authority, TestReplayAuthority)
    Repo.delete_all(ReviewEvent)

    on_exit(fn ->
      if is_nil(previous),
        do: Application.delete_env(:crosswake_example, :offline_study_replay_authority),
        else: Application.put_env(:crosswake_example, :offline_study_replay_authority, previous)

      Repo.delete_all(ReviewEvent)
    end)

    :ok
  end

  test "an authenticated request reaches one persisted event through the host replay boundary" do
    conn =
      build_conn()
      |> init_test_session(%{"replay_authority" => %{"scope_ref" => @scope}})
      |> post("/study/sync", request("accepted-once"))

    assert conn.status == 200
    assert %{"data" => %{"accepted_records" => [%{"client_mutation_id" => "accepted-once"}]}} =
             Jason.decode!(conn.resp_body)

    assert_received :current_session
    assert Repo.aggregate(ReviewEvent, :count, :id) == 1
  end

  for path <- ["/study/sync", "/learnloop/sync"] do
    test "an anonymous request to #{path} is denied before replay admission or persistence" do
      conn = post(build_conn(), unquote(path), request("anonymous-canary"))

      assert conn.status == 403
      assert %{"error" => %{"class" => "auth_required"}} = Jason.decode!(conn.resp_body)
      refute conn.resp_body =~ @scope
      refute conn.resp_body =~ "anonymous-canary"
      assert Repo.aggregate(ReviewEvent, :count, :id) == 0
    end
  end

  defp request(id) do
    %{
      "scope_ref" => @scope,
      "events" => [%{"client_mutation_id" => id, "card_id" => 1, "rating" => "good"}]
    }
  end

  defmodule TestReplayAuthority do
    import Plug.Conn

    alias Crosswake.Manifest.Types.RouteEntry

    def current_session(conn) do
      send(self(), :current_session)

      case get_session(conn, "replay_authority") do
        %{"scope_ref" => scope_ref} when is_binary(scope_ref) ->
          {:ok,
           %{
             scope_ref: scope_ref,
             auth_context: %{actor_id: "test-actor", org_id: "test-org", mfa_level: :mfa, auth_age: 0}
           }}

        _ ->
          {:error, :auth_required}
      end
    end

    def current_route(_conn) do
      {:ok,
       %RouteEntry{
         id: "offline-study",
         path: "/study",
         runtime: :offline_island,
         offline: :local_first,
         gated_by: :offline_study_replay
       }}
    end

    def feature_enabled?(_route, _conn), do: :allow
    def domain_allows?(_route, _session, _event), do: :allow
  end
end
