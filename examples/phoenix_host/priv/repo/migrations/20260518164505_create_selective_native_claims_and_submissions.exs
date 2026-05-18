defmodule CrosswakeExample.Repo.Migrations.CreateSelectiveNativeClaimsAndSubmissions do
  use Ecto.Migration

  def change do
    create table(:selective_native_claims) do
      add :title, :string, null: false
      add :status, :string, null: false, default: "pending"

      timestamps()
    end

    create table(:selective_native_submissions) do
      add :claim_id, references(:selective_native_claims, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :evidence_data, :string

      timestamps()
    end

    create index(:selective_native_submissions, [:claim_id])
  end
end
