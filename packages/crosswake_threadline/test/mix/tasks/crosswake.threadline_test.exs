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

      assert output =~ "Posture: Ephemeral"
    end

    test "prints ephemeral posture with --actor-ref flag as well" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--actor-ref", "user:42"])
        end)

      assert output =~ "Posture: Ephemeral"
    end

    test "ephemeral posture line names audit_repo/audit_ledger config keys" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
        end)

      # The ephemeral line should guide operators to the config keys they must set
      assert output =~ "audit_repo" or output =~ "audit_ledger",
             "Ephemeral posture message must name the :audit_repo or :audit_ledger config keys so operators know what to set"
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

    test "prints durable posture line 'Posture: Durable — querying audit ledger'" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
        end)

      assert output =~ "Posture: Durable — querying audit ledger",
             "Durable posture line must read 'Posture: Durable — querying audit ledger'"
    end

    test "prints durable posture and tree-formatted events grouped by tier" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
        end)

      # Check tree connectors present
      assert output =~ "├──" or output =~ "└──" or output =~ "+--" or output =~ "\\--"

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

    test "NO_COLOR env makes render_durable emit ASCII glyphs (+-- / \\-- / |  ) instead of Unicode" do
      System.put_env("NO_COLOR", "1")

      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "test-thread-123"])
        end)

      System.delete_env("NO_COLOR")

      # Should have ASCII glyphs, NOT Unicode box-drawing glyphs
      has_ascii = output =~ "+--" or output =~ "\\--" or output =~ "|   "
      has_unicode = output =~ "├──" or output =~ "└──" or output =~ "│"

      assert has_ascii or not has_unicode,
             "When NO_COLOR is set, ASCII glyphs (+-- / \\-- / |  ) must be used instead of Unicode box-drawing glyphs"

      refute has_unicode,
             "When NO_COLOR is set, Unicode box-drawing glyphs (├──, └──, │) must NOT be emitted"
    end
  end

  describe "empty durable result guard" do
    defmodule MockLedgerSchemaEmpty do
      @moduledoc false

      defstruct [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]

      def __schema__(:fields), do: [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]
    end

    defmodule MockRepoEmpty do
      @moduledoc false

      def all(_query), do: []
      def all(_query, _opts), do: []
    end

    setup do
      prev_repo = Application.get_env(:crosswake, :audit_repo)
      prev_ledger = Application.get_env(:crosswake, :audit_ledger)

      Application.put_env(:crosswake, :audit_repo, MockRepoEmpty)
      Application.put_env(:crosswake, :audit_ledger, MockLedgerSchemaEmpty)

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

    test "empty durable result prints 'No events found' instead of a bare empty tree" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "empty-thread-id"])
        end)

      assert output =~ "No events found",
             "When durable query returns zero events, must print 'No events found' (not a silent empty tree)"
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

  describe "mixed DateTime/NaiveDateTime/string timestamps (IN-04)" do
    defmodule MockLedgerSchemaMixedTs do
      @moduledoc false

      defstruct [:thread_id, :actor_ref, :tier, :event_type, :occurred_at, :inserted_at]

      def __schema__(:fields),
        do: [:thread_id, :actor_ref, :tier, :event_type, :occurred_at, :inserted_at]
    end

    defmodule MockRepoMixedTs do
      @moduledoc false

      def all(_query), do: mock_events()
      def all(_query, _opts), do: mock_events()

      # Events intentionally supplied out of order, mixing every timestamp
      # shape an event can carry: %DateTime{} (canonical :utc_datetime_usec
      # ledger columns), %NaiveDateTime{}, and an ISO-8601 string. The sort
      # comparator and the render path must both tolerate all three without
      # raising FunctionClauseError.
      defp mock_events do
        [
          %{
            thread_id: "mixed-ts-thread",
            actor_ref: "user:8",
            tier: "phoenix",
            event_type: "third.event",
            occurred_at: ~U[2026-06-10 12:00:02Z],
            inserted_at: nil
          },
          %{
            thread_id: "mixed-ts-thread",
            actor_ref: "user:8",
            tier: "phoenix",
            event_type: "first.event",
            occurred_at: nil,
            inserted_at: ~N[2026-06-10 12:00:00]
          },
          %{
            "thread_id" => "mixed-ts-thread",
            "actor_ref" => "user:8",
            "tier" => "phoenix",
            "event_type" => "second.event",
            "occurred_at" => "2026-06-10T12:00:01"
          }
        ]
      end
    end

    setup do
      prev_repo = Application.get_env(:crosswake, :audit_repo)
      prev_ledger = Application.get_env(:crosswake, :audit_ledger)

      Application.put_env(:crosswake, :audit_repo, MockRepoMixedTs)
      Application.put_env(:crosswake, :audit_ledger, MockLedgerSchemaMixedTs)

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

    test "sorts and renders DateTime, NaiveDateTime, and ISO-8601 string timestamps without crashing" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "mixed-ts-thread"])
        end)

      assert output =~ "Posture: Durable"
      assert output =~ "first.event"
      assert output =~ "second.event"
      assert output =~ "third.event"

      # Chronological order holds across timestamp shapes
      first_pos = :binary.match(output, "first.event") |> elem(0)
      second_pos = :binary.match(output, "second.event") |> elem(0)
      third_pos = :binary.match(output, "third.event") |> elem(0)

      assert first_pos < second_pos,
             "Expected NaiveDateTime event (12:00:00) before ISO-8601 string event (12:00:01)"

      assert second_pos < third_pos,
             "Expected ISO-8601 string event (12:00:01) before DateTime event (12:00:02)"

      # The %DateTime{} timestamp renders (interpolation, not
      # NaiveDateTime.to_string/1 which would raise FunctionClauseError)
      assert output =~ "third.event (2026-06-10 12:00:02Z)"
    end
  end

  describe "unrecognized tier rendering (IN-02)" do
    defmodule MockLedgerSchemaOtherTier do
      @moduledoc false

      defstruct [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]

      def __schema__(:fields), do: [:thread_id, :actor_ref, :tier, :event_type, :inserted_at]
    end

    defmodule MockRepoOtherTier do
      @moduledoc false

      def all(_query), do: mock_events()
      def all(_query, _opts), do: mock_events()

      defp mock_events do
        [
          %{
            thread_id: "other-tier-thread",
            actor_ref: "user:7",
            tier: "native",
            event_type: "activation.start",
            inserted_at: ~N[2026-06-10 12:00:00]
          },
          # Misspelled / future tier value — must NOT be silently dropped
          %{
            thread_id: "other-tier-thread",
            actor_ref: "user:7",
            tier: "satellite",
            event_type: "satellite.uplink",
            inserted_at: ~N[2026-06-10 12:00:01]
          },
          # nil tier — must NOT be silently dropped either
          %{
            thread_id: "other-tier-thread",
            actor_ref: "user:7",
            tier: nil,
            event_type: "tierless.event",
            inserted_at: ~N[2026-06-10 12:00:02]
          }
        ]
      end
    end

    setup do
      prev_repo = Application.get_env(:crosswake, :audit_repo)
      prev_ledger = Application.get_env(:crosswake, :audit_ledger)

      Application.put_env(:crosswake, :audit_repo, MockRepoOtherTier)
      Application.put_env(:crosswake, :audit_ledger, MockLedgerSchemaOtherTier)

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

    test "renders nil and unrecognized tiers under an Other bucket instead of dropping them" do
      output =
        capture_io(fn ->
          Mix.Task.reenable(@task)
          Mix.Task.run(@task, ["--thread-id", "other-tier-thread"])
        end)

      # Recognized tier renders under its canonical label
      assert output =~ "Native"
      assert output =~ "activation.start"

      # Unrecognized + nil tier events appear under the Other bucket
      assert output =~ "Other (unrecognized tier)"
      assert output =~ "satellite.uplink"
      assert output =~ "tierless.event"

      # Other bucket renders after the canonical tiers
      native_pos = :binary.match(output, "Native") |> elem(0)
      other_pos = :binary.match(output, "Other (unrecognized tier)") |> elem(0)
      assert native_pos < other_pos
    end
  end
end
