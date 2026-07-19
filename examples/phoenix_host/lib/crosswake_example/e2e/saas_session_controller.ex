defmodule CrosswakeExample.E2E.SaaSSessionController do
  use Phoenix.Controller, formats: [:json]

  alias CrosswakeExample.SaaSPortal.Auth
  alias CrosswakeExample.SaaSPortal.Fixtures

  def create(conn, params) do
    user_id = Map.get(params, "user_id")

    with true <- is_binary(user_id),
         user when not is_nil(user) <- Fixtures.user_by_id(user_id) do
      conn = Auth.put_user_session(conn, user)

      conn
      |> put_status(:created)
      |> json(%{
        user_id: user.id,
        role: Atom.to_string(user.role),
        account_id: user.account_id
      })
    else
      false ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "fixture user_id is required"})

      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "unknown fixture user"})
    end
  end
end
