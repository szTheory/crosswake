defmodule CrosswakeExample.FlashcardsTest do
  use ExUnit.Case

  alias CrosswakeExample.Flashcards
  alias CrosswakeExample.Repo

  setup do
    # Clean up tables
    Repo.delete_all(CrosswakeExample.Flashcards.Progress)
    Repo.delete_all(CrosswakeExample.Flashcards.Card)
    Repo.delete_all(CrosswakeExample.Flashcards.Deck)
    :ok
  end

  describe "decks" do
    test "list_decks/0 returns all decks" do
      assert Flashcards.list_decks() == []
    end
  end

  describe "cards" do
    test "list_cards/0 returns all cards" do
      assert Flashcards.list_cards() == []
    end
  end
end