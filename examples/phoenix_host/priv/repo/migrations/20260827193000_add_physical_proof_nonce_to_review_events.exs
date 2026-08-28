defmodule CrosswakeExample.Repo.Migrations.AddPhysicalProofNonceToReviewEvents do
  use Ecto.Migration

  def change do
    alter table(:review_events) do
      add(:physical_proof_nonce, :string)
    end
  end
end
