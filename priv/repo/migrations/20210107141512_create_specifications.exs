defmodule Integrate.Repo.Migrations.CreateSpecs do
  use Ecto.Migration

  def change do
    create table(:specs) do
      add :type, :string, null: false
      add :match, {:array, :map}, default: []

      add :stakeholder_id, references(:stakeholders, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:specs, [:stakeholder_id, :type])
    create index(:specs, [:stakeholder_id])
  end
end
