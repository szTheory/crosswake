defmodule CrosswakeExample.Flashcards.Card do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "flashcard_cards" do
    field :front_text, :string
    field :back_text, :string
    belongs_to :deck, CrosswakeExample.Flashcards.Deck

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:front_text, :back_text, :deck_id])
    |> validate_required([:front_text, :back_text, :deck_id])
  end
end