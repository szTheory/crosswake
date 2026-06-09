defmodule CrosswakeExample.Repo.Migrations.CreateFlashcardDecks do
  use Ecto.Migration

  def change do
    create table(:flashcard_decks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :string

      timestamps()
    end
  end
end