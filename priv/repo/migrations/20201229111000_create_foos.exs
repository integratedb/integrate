defmodule Integrate.Repo.Migrations.CreateFoos do
  use Ecto.Migration

  def change do
    create table(:foos) do
      add :name, :string

      timestamps()
    end
  end
end
