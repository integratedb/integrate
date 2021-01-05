defmodule Integrate.Repo.Migrations.CreateStakeholders do
  use Ecto.Migration

  def change do
    create table(:stakeholders) do
      add :name, :string, null: false
      add :user_id, references(:users), null: false

      timestamps()
    end

    create index(:stakeholders, [:user_id])
    create unique_index(:stakeholders, [:name])
  end
end
