defmodule CrosswakeExample.Flashcards do
  @moduledoc """
  The Flashcards context.
  """

  import Ecto.Query, warn: false
  alias CrosswakeExample.Repo

  alias CrosswakeExample.Flashcards.Deck
  alias CrosswakeExample.Flashcards.Card
  alias CrosswakeExample.Flashcards.Progress
  alias CrosswakeExample.LocalFirst.ReviewEvent

  @seed_deck %{
    id: "11111111-1111-4111-8111-111111111111",
    title: "Elixir Basics",
    description: "Core concepts of Elixir"
  }

  @seed_cards [
    %{
      id: "22222222-2222-4222-8222-222222222221",
      front_text: "What is OTP?",
      back_text:
        "Open Telecom Platform - a collection of middleware, libraries, and tools written in Erlang."
    },
    %{
      id: "22222222-2222-4222-8222-222222222222",
      front_text: "What is a GenServer?",
      back_text:
        "A generic server behaviour that abstracts client/server interactions in Elixir/Erlang."
    },
    %{
      id: "22222222-2222-4222-8222-222222222223",
      front_text: "What is Ecto?",
      back_text: "A database wrapper and query generator for Elixir."
    }
  ]

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

  def reset_seed! do
    {:ok, counts} =
      Repo.transaction(fn ->
        Repo.delete_all(ReviewEvent)
        Repo.delete_all(Progress)
        Repo.delete_all(Card)
        Repo.delete_all(Deck)

        deck =
          Repo.insert!(%Deck{
            id: @seed_deck.id,
            title: @seed_deck.title,
            description: @seed_deck.description
          })

        Enum.each(@seed_cards, fn attrs ->
          Repo.insert!(%Card{
            id: attrs.id,
            deck_id: deck.id,
            front_text: attrs.front_text,
            back_text: attrs.back_text
          })
        end)

        %{
          browser_state_reset: false,
          decks: 1,
          cards: length(@seed_cards),
          progress: 0,
          synced_reviews: 0
        }
      end)

    counts
  end

  def seed_digest_components do
    [
      "learning_training.deck:#{@seed_deck.id}:#{@seed_deck.title}:#{@seed_deck.description}",
      @seed_cards
      |> Enum.sort_by(& &1.id)
      |> Enum.map_join("|", &"learning_training.card:#{&1.id}:#{&1.front_text}:#{&1.back_text}")
    ]
  end
end
