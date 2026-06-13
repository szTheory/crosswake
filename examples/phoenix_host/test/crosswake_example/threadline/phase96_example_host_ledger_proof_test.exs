defmodule CrosswakeExample.Threadline.Phase96ExampleHostLedgerProofTest do
  @moduledoc """
  PROOF-02: Advisory example-host Ecto-backed durable-posture proof.

  Proves that real record_in_multi/3 persistence + mix crosswake.threadline
  reconstruction yields Posture: Durable against a seeded SQLite ledger.

  This test is async: false because ecto_sqlite3 has no async sandbox
  support (D-05). Cleanup runs via Repo.delete_all in setup (before the
  body, not on_exit) to avoid the SQLite serialized-write race (Pitfall 5).
  """
  use ExUnit.Case, async: false

  alias CrosswakeExample.Repo

  setup do
    # FIRST: clean up before the test body — not on_exit.
    # SQLite serialized-write race (Pitfall 5): on_exit cleanup fires after
    # the next test starts, causing write-lock contention on a single-writer DB.
    Repo.delete_all(CrosswakeExample.Audit.Ledger)

    # Save previous audit config so on_exit can restore it cleanly
    prev_repo = Application.get_env(:crosswake, :audit_repo)
    prev_ledger = Application.get_env(:crosswake, :audit_ledger)

    # Wire the example host's Repo and Ledger into the threadline task config
    Application.put_env(:crosswake, :audit_repo, CrosswakeExample.Repo)
    Application.put_env(:crosswake, :audit_ledger, CrosswakeExample.Audit.Ledger)

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

  test "record_in_multi/3 seed + mix crosswake.threadline yields Posture: Durable and reconstructs the seeded event" do
    thread_id = "proof-96-#{System.unique_integer([:positive])}"

    # Seed a durable event via Ecto.Multi + record_in_multi/3 + Repo.transaction.
    # Every null: false column is provided to satisfy validate_required.
    # tier: "phoenix" is set explicitly so the event lands under the Phoenix tier bucket
    # and not "Other (unrecognized tier)" — Pitfall 4.
    attrs = %{
      thread_id: thread_id,
      correlation_id: "corr-proof-96",
      route_id: "/proof/route",
      actor_ref: "proof-actor",
      actor_kind: "user",
      event_class: "auth",
      event_type: "auth.step_up",
      outcome: "allowed",
      provenance: :backend_accepted,
      occurred_at: DateTime.utc_now(),
      recorded_at: DateTime.utc_now(),
      idempotency_key: "proof-96-idem-#{System.unique_integer([:positive])}",
      tier: "phoenix"
    }

    result =
      Ecto.Multi.new()
      |> CrosswakeExample.Audit.Ledger.record_in_multi(:audit_event, attrs)
      |> Repo.transaction()

    assert {:ok, _} = result,
           "Expected transaction to succeed — check that migration ran (mix ecto.migrate)"

    # Capture threadline task output via Mix.Shell.Process.
    # NOT capture_io — subtask stdout bleeds through (D-05).
    Mix.Shell.Process.flush()
    original_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    # Mix.Task.reenable before EVERY Mix.Task.run — Mix once-semantics make
    # second runs return a vacuous :noop instead of executing (Pitfall 3).
    Mix.Task.reenable("crosswake.threadline")
    Mix.Task.run("crosswake.threadline", ["--thread-id", thread_id])

    Mix.shell(original_shell)

    # Collect all :mix_shell messages from the Process mailbox
    messages = collect_shell_messages([])

    assert Enum.any?(messages, &(&1 =~ "Posture: Durable")),
           "Expected 'Posture: Durable' in shell output. Got:\n#{Enum.join(messages, "\n")}"

    # The seeded event must be visible — assert the event_type or actor_ref appears,
    # confirming the reconstruction rendered the specific event we seeded, not just the header.
    assert Enum.any?(messages, &(&1 =~ "auth.step_up" or &1 =~ "proof-actor")),
           "Expected seeded event (auth.step_up / proof-actor) in shell output. Got:\n#{Enum.join(messages, "\n")}"
  end

  # Drains all {:mix_shell, :info, [msg]} messages from the current process mailbox.
  defp collect_shell_messages(acc) do
    receive do
      {:mix_shell, :info, [msg]} ->
        collect_shell_messages([msg | acc])
    after
      0 ->
        Enum.reverse(acc)
    end
  end
end
