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

  describe "chronological sort across month boundary" do
    # Events supplied OUT OF ORDER: Feb first, then Dec, then Jan.
    # All in "phoenix" tier so tier grouping does not influence order.
    # Erlang structural term order (alphabetical key order: :day, :month, :year)
    # would misplace Dec-20 (day=20) before Jan-15 (day=15) since 20 > 15 structurally,
    # making Dec appear AFTER Jan. A correct NaiveDateTime comparator must fix this.
    defmodule MockLedgerSchemaBoundary do
      @moduledoc false

      defstruct [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]

      def __schema__(:fields), do: [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]
    end

    defmodule MockRepoBoundary do
      @moduledoc false

      def all(_query), do: mock_events()
      def all(_query, _opts), do: mock_events()

      # Events intentionally supplied in non-chronological order:
      # Feb 2026 first, then Dec 2025, then Jan 2026.
      defp mock_events do
        [
          %{
            thread_id: "boundary-thread",
            actor_ref: "user:99",
            tier: "phoenix",
            event_type: "feb.event",
            inserted_at: ~N[2026-02-03 08:00:00]
          },
          %{
            thread_id: "boundary-thread",
            actor_ref: "user:99",
            tier: "phoenix",
            event_type: "dec.event",
            inserted_at: ~N[2025-12-20 09:00:00]
          },
          %{
            thread_id: "boundary-thread",
            actor_ref: "user:99",
            tier: "phoenix",
            event_type: "jan.event",
            inserted_at: ~N[2026-01-15 10:00:00]
          }
        ]
      end
    end

    setup do
      prev_repo = Application.get_env(:crosswake, :audit_repo)
      prev_ledger = Application.get_env(:crosswake, :audit_ledger)

      Application.put_env(:crosswake, :audit_repo, MockRepoBoundary)
      Application.put_env(:crosswake, :audit_ledger, MockLedgerSchemaBoundary)

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

    test "renders out-of-order cross-month events oldest-first (Dec 2025, Jan 2026, Feb 2026)" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "boundary-thread"])
        end)

      assert output =~ "dec.event", "Expected dec.event in output"
      assert output =~ "jan.event", "Expected jan.event in output"
      assert output =~ "feb.event", "Expected feb.event in output"

      # Chronological order: Dec 2025 < Jan 2026 < Feb 2026
      dec_pos = :binary.match(output, "dec.event") |> elem(0)
      jan_pos = :binary.match(output, "jan.event") |> elem(0)
      feb_pos = :binary.match(output, "feb.event") |> elem(0)

      assert dec_pos < jan_pos,
             "Expected dec.event (Dec 2025) to appear before jan.event (Jan 2026) in output"

      assert jan_pos < feb_pos,
             "Expected jan.event (Jan 2026) to appear before feb.event (Feb 2026) in output"
    end
  end
end
