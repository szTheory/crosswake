defmodule CrosswakeExample.SelectiveNative.Claims do
  import Ecto.Query
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Claim

  def list_claims do
    Repo.all(Claim)
  end

  def get_claim!(id), do: Repo.get!(Claim, id)

  def create_claim(attrs \\ %{}) do
    %Claim{}
    |> Claim.changeset(attrs)
    |> Repo.insert()
  end

  def mark_captured_locally(%Claim{} = claim, _attrs \\ %{}) do
    claim
    |> Claim.changeset(%{status: "captured locally"})
    |> Repo.update()
  end

  def mark_staged(%Claim{} = claim, _attrs \\ %{}) do
    claim
    |> Claim.changeset(%{status: "staged"})
    |> Repo.update()
  end

  def mark_uploaded(%Claim{} = claim, _attrs \\ %{}) do
    claim
    |> Claim.changeset(%{status: "uploaded"})
    |> Repo.update()
  end
end
