defmodule Crosswake.NativeEscape.Runtime do
  @moduledoc """
  Runtime helpers for the single native media-capture escape hatch.
  """

  alias Crosswake.NativeEscape.Contract
  alias Crosswake.Transfer.Contracts, as: TransferContracts

  @spec capture_local(
          Contract.request(),
          Contract.local_capture(),
          [TransferContracts.declaration()]
        ) :: {:ok, Contract.result()} | {:error, Contract.denial()}
  def capture_local(%Contract.Request{} = request, %Contract.LocalCapture{} = local_capture, declared_transfers)
      when is_list(declared_transfers) do
    with :ok <- validate_runtime(request),
         {:ok, transfer} <- declared_transfer(request.transfer_id, declared_transfers) do
      {:ok,
       Contract.new_result(
         route_id: request.route_id,
         state: :captured_local,
         local_capture: local_capture,
         transfer_handoff:
           Contract.new_transfer_handoff(
             transfer_id: transfer.id,
             transfer_protocol: TransferContracts.protocol(),
             transfer_version: TransferContracts.version(),
             transfer_intent: transfer.intent
           )
       )}
    end
  end

  @spec complete_transfer(Contract.result(), TransferContracts.Result.t()) ::
          {:ok, Contract.result()} | {:error, Contract.denial()}
  def complete_transfer(%Contract.Result{} = result, %TransferContracts.Result{} = transfer_result) do
    cond do
      result.state != :captured_local ->
        {:error,
         Contract.new_denial(
           reason: :invalid_transfer_result,
           message: "native escape transfer completion requires a captured_local result"
         )}

      transfer_result.route_id != result.route_id ->
        {:error,
         Contract.new_denial(
           reason: :invalid_transfer_result,
           message: "transfer completion route does not match the capture route"
         )}

      transfer_result.transfer_id != result.transfer_handoff.transfer_id ->
        {:error,
         Contract.new_denial(
           reason: :invalid_transfer_result,
           message: "transfer completion must match the declared transfer seam"
         )}

      transfer_result.state != :complete ->
        {:error,
         Contract.new_denial(
           reason: :invalid_transfer_result,
           message: "transfer completion requires transfer state :complete"
         )}

      true ->
        {:ok,
         Contract.new_result(
           route_id: result.route_id,
           state: :transfer_complete,
           local_capture: result.local_capture,
           transfer_handoff: result.transfer_handoff,
           transfer_result: transfer_result
         )}
    end
  end

  defp validate_runtime(%Contract.Request{route_runtime: :native_screen}), do: :ok

  defp validate_runtime(%Contract.Request{}) do
    {:error,
     Contract.new_denial(
       reason: :native_screen_required,
       message: "the media-capture native escape hatch is only available to :native_screen routes"
     )}
  end

  defp declared_transfer(transfer_id, transfers) do
    case Enum.find(transfers, &(&1.id == transfer_id and &1.intent == :upload and &1.source == :native_capture)) do
      nil ->
        {:error,
         Contract.new_denial(
           reason: :undeclared_transfer_seam,
           message: "the native capture flow requires a declared upload seam with source :native_capture"
         )}

      transfer ->
        {:ok, transfer}
    end
  end
end
