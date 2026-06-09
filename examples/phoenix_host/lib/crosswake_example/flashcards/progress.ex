defmodule CrosswakeExample.Flashcards.Progress do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "flashcard_progress" do
    field :user_id, :string
    field :ease, :float
    field :interval, :integer
    field :next_review_at, :utc_datetime
    belongs_to :card, CrosswakeExample.Flashcards.Card

    timestamps()
  end

  @doc false
  def changeset(progress, attrs) do
    progress
    |> cast(attrs, [:user_id, :ease, :interval, :next_review_at, :card_id])
    |> validate_required([:user_id, :card_id])
    |> unique_constraint([:card_id, :user_id])
  end
end