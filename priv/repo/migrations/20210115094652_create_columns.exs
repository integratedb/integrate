defmodule Integrate.Repo.Migrations.CreateColumns do
  use Ecto.Migration

  def change do
    create table(:columns) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :min_length, :integer
      add :is_nullable, :boolean, default: true, null: false

      add :claim_id, references(:claims, on_delete: :delete_all)

      timestamps()
    end

    create unique_index(:columns, [:claim_id, :name])
    create index(:columns, [:claim_id])
  end
end
