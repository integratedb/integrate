defmodule Integrate.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    create table(:claims) do
      add :schema, :string, null: false
      add :table, :string, null: false

      add :spec_id, references(:specs, on_delete: :delete_all)

      timestamps()
    end

    create index(:claims, [:schema, :table])
    create index(:claims, [:spec_id])
  end
end
