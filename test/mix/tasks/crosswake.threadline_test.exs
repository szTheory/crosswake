defmodule Mix.Tasks.Crosswake.ThreadlineTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "crosswake.threadline"

  describe "argument validation" do
    test "raises Mix.Error when neither --thread-id nor --actor-ref is provided" do
      assert_raise Mix.Error, ~r/(--thread-id|--actor-ref)/, fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, [])
      end
    end
  end

  describe "ephemeral posture (no ledger configured)" do
    setup do
      # Ensure no audit config is present
      prev_repo = Application.get_env(:crosswake, :audit_repo)
      prev_ledger = Application.get_env(:crosswake, :audit_ledger)
      Application.delete_env(:crosswake, :audit_repo)
      Application.delete_env(:crosswake, :audit_ledger)

      on_exit(fn ->
        if prev_repo do
          Application.put_env(:crosswake, :audit_repo, prev_repo)
        else
          Application.delete_env(:crosswake, :audit_repo)
        end

        if prev_ledger do
          Application.put_env(:crosswake, :audit_ledger, prev_ledger)
        else
          Application.delete_env(:crosswake, :audit_ledger)
        end
      end)

      :ok
    end

    test "prints ephemeral posture message when ledger is not configured" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
        end)

      assert output =~ "Posture: Ephemeral. No ledger configured."
    end

    test "prints ephemeral posture with --actor-ref flag as well" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--actor-ref", "user:42"])
        end)

      assert output =~ "Posture: Ephemeral. No ledger configured."
    end
  end

  describe "durable posture (ledger configured)" do
    defmodule MockLedgerSchema do
      @moduledoc false

      defstruct [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]

      def __schema__(:fields), do: [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]
    end

    defmodule MockRepo do
      @moduledoc false

      def all(_query), do: mock_events()
      def all(_query, _opts), do: mock_events()

      defp mock_events do
        [
          %{
            thread_id: "test-thread-123",
            actor_ref: "user:42",
            tier: "native",
            event_type: "activation.start",
            inserted_at: ~N[2026-06-10 12:00:00]
          },
          %{
            thread_id: "test-thread-123",
            actor_ref: "user:42",
            tier: "bridge",
            event_type: "bridge.handshake",
            inserted_at: ~N[2026-06-10 12:00:01]
          },
          %{
            thread_id: "test-thread-123",
            actor_ref: "user:42",
            tier: "phoenix",
            event_type: "request.start",
            inserted_at: ~N[2026-06-10 12:00:02]
          }
        ]
      end
    end

    setup do
      prev_repo = Application.get_env(:crosswake, :audit_repo)
      prev_ledger = Application.get_env(:crosswake, :audit_ledger)

      Application.put_env(:crosswake, :audit_repo, MockRepo)
      Application.put_env(:crosswake, :audit_ledger, MockLedgerSchema)

      on_exit(fn ->
        if prev_repo do
          Application.put_env(:crosswake, :audit_repo, prev_repo)
        else
          Application.delete_env(:crosswake, :audit_repo)
        end

        if prev_ledger do
          Application.put_env(:crosswake, :audit_ledger, prev_ledger)
        else
          Application.delete_env(:crosswake, :audit_ledger)
        end
      end)

      :ok
    end

    test "prints durable posture and tree-formatted events grouped by tier" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
        end)

      # Check durable posture header
      assert output =~ "Posture: Durable"

      # Check tree connectors present
      assert output =~ "├──" or output =~ "└──"

      # Check tier grouping (Native -> Bridge -> Phoenix)
      assert output =~ "Native"
      assert output =~ "Bridge"
      assert output =~ "Phoenix"

      # Verify ordering: Native appears before Bridge, Bridge before Phoenix
      native_pos = :binary.match(output, "Native") |> elem(0)
      bridge_pos = :binary.match(output, "Bridge") |> elem(0)
      phoenix_pos = :binary.match(output, "Phoenix") |> elem(0)

      assert native_pos < bridge_pos
      assert bridge_pos < phoenix_pos
    end
  end
end
