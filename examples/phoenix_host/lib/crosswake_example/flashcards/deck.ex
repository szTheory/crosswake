defmodule CrosswakeExample.Flashcards.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "flashcard_decks" do
    field :title, :string
    field :description, :string
    has_many :cards, CrosswakeExample.Flashcards.Card

    timestamps()
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
  end
end