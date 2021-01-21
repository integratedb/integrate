defmodule Integrate.Repo.Migrations.CreateColumnAlternatives do
  use Ecto.Migration

  def change do
    create table(:column_alternatives) do
      add :name, :string, null: false
      add :type, :string, null: false
      add :min_length, :integer
      add :is_nullable, :boolean, default: true, null: false

      add :column_id, references(:columns, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:column_alternatives, [:column_id])
    create index(:column_alternatives, [:name])
  end
end
