defmodule Integrate.Repo.Migrations.CreateClaims do
  use Ecto.Migration

  def change do
    create table(:claims) do
      add :optional, :boolean, null: false, default: false

      add :spec_id, references(:specs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:claims, [:optional])
    create index(:claims, [:spec_id])
  end
end
