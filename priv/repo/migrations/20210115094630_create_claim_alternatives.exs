defmodule Integrate.Repo.Migrations.CreateClaimAlternatives do
  use Ecto.Migration

  def change do
    create table(:claim_alternatives) do
      add :schema, :string, null: false
      add :table, :string, null: false

      add :claim_id, references(:claims, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:claim_alternatives, [:schema, :table])
    create index(:claim_alternatives, [:claim_id])
  end
end
