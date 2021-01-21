defmodule Integrate.Repo.Migrations.CreateColumns do
  use Ecto.Migration

  def change do
    create table(:columns) do
      add :optional, :boolean, null: false, default: false

      add :claim_alternative_id, references(:claim_alternatives, on_delete: :delete_all),
        null: false

      timestamps()
    end

    create index(:columns, [:optional])
    create index(:columns, [:claim_alternative_id])
  end
end
