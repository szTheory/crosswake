defmodule CrosswakeExample.LocalFirst.ReviewEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "review_events" do
    field(:scope_ref, :string)
    field(:client_mutation_id, :string)
    field(:card_id, :integer)
    field(:rating, :string)
    field(:status, :string, default: "accepted")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review_event, attrs) do
    review_event
    |> cast(attrs, [:scope_ref, :client_mutation_id, :card_id, :rating, :status])
    |> validate_required([:scope_ref, :client_mutation_id, :card_id, :rating])
    |> validate_inclusion(:rating, ["good", "hard"])
    |> validate_inclusion(:status, ["accepted", "rejected"])
    |> unique_constraint(:client_mutation_id,
      name: :review_events_client_mutation_id_index,
      message: "idempotency conflict"
    )
    |> unique_constraint([:scope_ref, :client_mutation_id],
      name: :review_events_scope_ref_client_mutation_id_index,
      message: "idempotency conflict"
    )
  end
end
