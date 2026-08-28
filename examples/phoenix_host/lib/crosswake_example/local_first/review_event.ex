defmodule CrosswakeExample.LocalFirst.ReviewEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "review_events" do
    field(:scope_ref, :string)
    field(:client_mutation_id, :string)
    field(:card_id, :integer)
    field(:rating, :string)
    # This field belongs only to the reference host's authorized study mutation
    # path. It is deliberately absent from operational projections and reports.
    field(:free_form_answer, :string)
    # An opaque, one-run proof binding. It is host-private and never rendered.
    field(:physical_proof_nonce, :string)
    field(:status, :string, default: "accepted")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review_event, attrs) do
    review_event
    |> cast(attrs, [
      :scope_ref,
      :client_mutation_id,
      :card_id,
      :rating,
      :free_form_answer,
      :physical_proof_nonce
    ])
    |> put_change(:status, "accepted")
    |> validate_required([:scope_ref, :client_mutation_id, :card_id, :rating])
    |> validate_inclusion(:rating, ["good", "hard"])
    |> validate_length(:free_form_answer, max: 4096)
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
