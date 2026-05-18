defmodule CrosswakeExample.Repo.Migrations.CreateReviewEvents do
  use Ecto.Migration

  def change do
    create table(:review_events) do
      add :client_mutation_id, :string, null: false
      add :card_id, :integer, null: false
      add :rating, :string, null: false
      add :status, :string, default: "accepted", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:review_events, [:client_mutation_id])
  end
end
