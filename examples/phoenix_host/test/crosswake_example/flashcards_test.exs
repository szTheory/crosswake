defmodule CrosswakeExample.FlashcardsTest do
  use ExUnit.Case
  
  import CrosswakeExample.FlashcardsFixtures

  describe "decks" do
    alias CrosswakeExample.Flashcards.Deck

    test "list_decks/0 returns all decks" do
      deck = deck_fixture()
      assert CrosswakeExample.Flashcards.list_decks() == [deck]
    end

    test "create_deck/1 with valid data creates a deck" do
      valid_attrs = %{title: "some title", description: "some description"}
      assert {:ok, %Deck{} = deck} = CrosswakeExample.Flashcards.create_deck(valid_attrs)
      assert deck.title == "some title"
      assert deck.description == "some description"
    end
  end

  describe "cards" do
    alias CrosswakeExample.Flashcards.Card

    test "create_card/1 with valid data creates a card" do
      deck = deck_fixture()
      valid_attrs = %{front: "front text", back: "back text", deck_id: deck.id}
      assert {:ok, %Card{} = card} = CrosswakeExample.Flashcards.create_card(valid_attrs)
      assert card.front == "front text"
      assert card.back == "back text"
    end

    test "list_deck_cards/1 returns cards for a given deck" do
      deck = deck_fixture()
      card = card_fixture(%{deck_id: deck.id})
      assert CrosswakeExample.Flashcards.list_deck_cards(deck.id) == [card]
    end
  end
end
