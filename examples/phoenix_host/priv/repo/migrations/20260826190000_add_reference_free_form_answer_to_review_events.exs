defmodule CrosswakeExample.Repo.Migrations.AddReferenceFreeFormAnswerToReviewEvents do
  use Ecto.Migration

  def change do
    alter table(:review_events) do
      add(:free_form_answer, :text)
    end
  end
end
