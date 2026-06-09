defmodule CrosswakeExample.Repo.Migrations.CreateFlashcardCards do
  use Ecto.Migration

  def change do
    create table(:flashcard_cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :deck_id, references(:flashcard_decks, type: :binary_id, on_delete: :delete_all)
      add :front_text, :string
      add :back_text, :string

      timestamps()
    end

    create index(:flashcard_cards, [:deck_id])
  end
end