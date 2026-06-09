# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     CrosswakeExample.Repo.insert!(%CrosswakeExample.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias CrosswakeExample.Repo
alias CrosswakeExample.Flashcards.Deck
alias CrosswakeExample.Flashcards.Card
alias CrosswakeExample.Flashcards

# Clear existing data for idempotency
Repo.delete_all(Card)
Repo.delete_all(Deck)

# Insert "Elixir Basics" deck
{:ok, deck} = Flashcards.create_deck(%{
  title: "Elixir Basics",
  description: "Core concepts of Elixir"
})

# Insert Cards for the deck
{:ok, _card1} = Flashcards.create_card(%{
  deck_id: deck.id,
  front_text: "What is OTP?",
  back_text: "Open Telecom Platform - a collection of middleware, libraries, and tools written in Erlang."
})

{:ok, _card2} = Flashcards.create_card(%{
  deck_id: deck.id,
  front_text: "What is a GenServer?",
  back_text: "A generic server behaviour that abstracts client/server interactions in Elixir/Erlang."
})

{:ok, _card3} = Flashcards.create_card(%{
  deck_id: deck.id,
  front_text: "What is Ecto?",
  back_text: "A database wrapper and query generator for Elixir."
})

IO.puts("Successfully seeded the database with 'Elixir Basics' deck and cards!")
