defmodule CrosswakeExample.SelectiveNative.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "selective_native_submissions" do
    field :status, :string
    field :evidence_data, :string

    belongs_to :claim, CrosswakeExample.SelectiveNative.Claim

    timestamps()
  end

  def changeset(submission, attrs) do
    submission
    |> cast(attrs, [:status, :evidence_data, :claim_id])
    |> validate_required([:status, :claim_id])
    |> validate_inclusion(:status, ["captured locally", "staged", "uploaded", "submitted"])
  end
end
