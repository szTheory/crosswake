defmodule CrosswakeExample.Flashcards do
  @moduledoc """
  The Flashcards context.
  """

  import Ecto.Query, warn: false
  alias CrosswakeExample.Repo

  alias CrosswakeExample.Flashcards.Deck
  alias CrosswakeExample.Flashcards.Card
  alias CrosswakeExample.Flashcards.Progress

  # --- Decks ---

  def list_decks do
    Repo.all(Deck)
  end

  def get_deck!(id), do: Repo.get!(Deck, id)

  def create_deck(attrs \\ %{}) do
    %Deck{}
    |> Deck.changeset(attrs)
    |> Repo.insert()
  end

  def update_deck(%Deck{} = deck, attrs) do
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  def delete_deck(%Deck{} = deck) do
    Repo.delete(deck)
  end

  def change_deck(%Deck{} = deck, attrs \\ %{}) do
    Deck.changeset(deck, attrs)
  end

  # --- Cards ---

  def list_cards do
    Repo.all(Card)
  end

  def get_card!(id), do: Repo.get!(Card, id)

  def create_card(attrs \\ %{}) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  def change_card(%Card{} = card, attrs \\ %{}) do
    Card.changeset(card, attrs)
  end

  def list_deck_cards(deck_id) do
    Card
    |> where([c], c.deck_id == ^deck_id)
    |> order_by([c], asc: c.inserted_at)
    |> Repo.all()
  end

  # --- Progress ---

  def get_progress(card_id, user_id) do
    Repo.get_by(Progress, card_id: card_id, user_id: user_id)
  end

  def upsert_progress(attrs) do
    %Progress{}
    |> Progress.changeset(attrs)
    |> Repo.insert(
      on_conflict: :replace_all,
      conflict_target: [:card_id, :user_id]
    )
  end
end