defmodule CrosswakeExample.Repo.Migrations.RestoreReviewEventIdempotencyGuard do
  use Ecto.Migration

  def change do
    # Keep pre-scope rows unassigned: their mutation ID remains an authoritative
    # tombstone without claiming ownership for any current scope.
    create(unique_index(:review_events, [:client_mutation_id]))
  end
end
