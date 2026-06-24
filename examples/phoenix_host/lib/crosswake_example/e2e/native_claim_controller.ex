defmodule CrosswakeExample.E2E.NativeClaimController do
  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.SelectiveNative.Claims

  def create(conn, params) do
    title = Map.get(params, "title", "Route Tour Claim")
    status = Map.get(params, "status", "pending")

    case Claims.create_claim(%{title: title, status: status}) do
      {:ok, claim} ->
        json(conn, %{id: claim.id, title: claim.title, status: claim.status})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: inspect(changeset.errors)})
    end
  end
end
