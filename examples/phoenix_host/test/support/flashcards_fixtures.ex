defmodule CrosswakeExample.FlashcardsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CrosswakeExample.Flashcards` context.
  """

  @doc """
  Generate a deck.
  """
  def deck_fixture(attrs \\ %{}) do
    {:ok, deck} =
      attrs
      |> Enum.into(%{
        title: unique_text("deck"),
        description: unique_text("description")
      })
      |> CrosswakeExample.Flashcards.create_deck()

    deck
  end

  @doc """
  Generate a card.
  """
  def card_fixture(attrs \\ %{}) do
    {:ok, card} =
      attrs
      |> Enum.into(%{
        front_text: unique_text("front"),
        back_text: unique_text("back")
      })
      |> CrosswakeExample.Flashcards.create_card()

    card
  end

  @doc """
  Generate a progress.
  """
  def progress_fixture(attrs \\ %{}) do
    {:ok, progress} =
      attrs
      |> Enum.into(%{
        status: :new,
        next_review_at: DateTime.utc_now()
      })
      |> CrosswakeExample.Flashcards.upsert_progress()

    progress
  end

  defp unique_text(prefix) do
    "#{prefix} #{System.system_time(:nanosecond)} #{System.unique_integer([:positive])}"
  end
end
