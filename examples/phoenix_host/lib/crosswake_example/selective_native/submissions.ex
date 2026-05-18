defmodule CrosswakeExample.SelectiveNative.Submissions do
  import Ecto.Query
  alias CrosswakeExample.Repo
  alias CrosswakeExample.SelectiveNative.Submission

  def get_submission!(id), do: Repo.get!(Submission, id)

  def create_submission(attrs \\ %{}) do
    %Submission{}
    |> Submission.changeset(attrs)
    |> Repo.insert()
  end

  def update_submission(%Submission{} = submission, attrs) do
    submission
    |> Submission.changeset(attrs)
    |> Repo.update()
  end

  def mark_submitted(%Submission{} = submission, _attrs \\ %{}) do
    submission
    |> Submission.changeset(%{status: "submitted"})
    |> Repo.update()
  end
end
