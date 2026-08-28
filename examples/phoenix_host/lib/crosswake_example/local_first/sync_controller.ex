defmodule CrosswakeExample.LocalFirst.SyncController do
  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.LocalFirst.{PhysicalIphoneAuthority, ReplayAdmission, Study}

  def sync(conn, %{"scope_ref" => scope_ref, "events" => events}) when is_list(events) do
    if ReplayAdmission.valid_batch?(events) do
      case sync_events(conn, scope_ref, events) do
        {:ok, result} ->
          json(conn, %{data: result})

        {:blocked, reason} ->
          conn
          |> put_status(:forbidden)
          |> json(%{error: %{class: reason}})
      end
    else
      blocked(conn, :invalid_envelope, :bad_request)
    end
  end

  def sync(conn, _params), do: blocked(conn, :invalid_envelope, :bad_request)

  @doc false
  def sync_events(conn, scope_ref, events, admission_opts \\ []) do
    initial = %{accepted_records: [], rejected: [], halted: nil}

    case Enum.reduce_while(events, {:ok, initial}, fn event, {:ok, result} ->
           case ReplayAdmission.authorize(conn, scope_ref, event, admission_opts) do
             {:allow, authority} ->
               case Study.apply_one(scope_ref, event, authority) do
                 {:ok, %{outcome: :accepted} = accepted} ->
                   PhysicalIphoneAuthority.observe_device_result(event, :accepted)

                   {:cont,
                    {:ok, %{result | accepted_records: result.accepted_records ++ [accepted]}}}

                 {:ok, %{outcome: :rejected} = rejected} ->
                   PhysicalIphoneAuthority.observe_device_result(event, :rejected)

                   {:halt,
                    {:ok, %{result | halted: :rejected, rejected: result.rejected ++ [rejected]}}}

                 {:error, reason} ->
                   PhysicalIphoneAuthority.observe_device_result(event, :transaction_failed)

                   {:halt,
                    {:ok, %{result | halted: :transaction_failed, rejected: [%{class: reason}]}}}
               end

             {:deny, reason} when result.accepted_records == [] ->
               PhysicalIphoneAuthority.observe_device_result(event, reason)
               {:halt, {:blocked, reason}}

             {:deny, reason} ->
               PhysicalIphoneAuthority.observe_device_result(event, reason)
               {:halt, {:ok, %{result | halted: reason}}}
           end
         end) do
      {:ok, result} -> {:ok, result}
      {:blocked, reason} -> {:blocked, reason}
    end
  end

  defp blocked(conn, reason, status) do
    conn
    |> put_status(status)
    |> json(%{error: %{class: reason}})
  end
end
