defmodule CrosswakeExample.Repo.Migrations.CreateFlashcardProgress do
  use Ecto.Migration

  def change do
    create table(:flashcard_progress, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :card_id, references(:flashcard_cards, type: :binary_id, on_delete: :delete_all)
      add :user_id, :string
      add :ease, :float
      add :interval, :integer
      add :next_review_at, :utc_datetime

      timestamps()
    end

    create index(:flashcard_progress, [:card_id])
    create index(:flashcard_progress, [:user_id])
    create unique_index(:flashcard_progress, [:card_id, :user_id])
  end
end