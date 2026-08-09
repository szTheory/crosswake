defmodule CrosswakeExample.Repo.Migrations.ScopeReviewEvents do
  use Ecto.Migration

  def change do
    alter table(:review_events) do
      add(:scope_ref, :string)
    end

    drop(unique_index(:review_events, [:client_mutation_id]))
    create(unique_index(:review_events, [:scope_ref, :client_mutation_id]))
  end
end
