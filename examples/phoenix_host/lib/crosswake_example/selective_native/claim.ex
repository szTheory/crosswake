defmodule CrosswakeExample.SelectiveNative.Claim do
  use Ecto.Schema
  import Ecto.Changeset

  schema "selective_native_claims" do
    field :title, :string
    field :status, :string, default: "pending"
    
    has_many :submissions, CrosswakeExample.SelectiveNative.Submission

    timestamps()
  end

  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:title, :status])
    |> validate_required([:title, :status])
  end
end
