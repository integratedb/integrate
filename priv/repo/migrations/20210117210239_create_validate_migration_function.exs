defmodule Integrate.Repo.Migrations.CreateValidateMigrationFunction do
  use Ecto.Migration

  defp hardcoded_namespace do
    "integratedb"
  end

  defp configured_namespace do
    Integrate.Config.namespace()
  end

  defp sql_file(name) do
    parts = [
      :code.priv_dir(:integrate),
      "sql",
      name
    ]

    parts
    |> Path.join()
    |> File.read!()
    |> String.replace(" #{hardcoded_namespace()}.", " #{configured_namespace()}.")
    |> String.trim()
  end

  def up do
    create table(:sync, primary_key: false) do
      add :uid, :uuid, null: false
    end

    execute sql_file("integratedb_sync.sql")
    execute sql_file("integratedb_unmet_claims.sql")
    execute sql_file("integratedb_validate_migration.sql")
  end

  def down do
    execute "DROP FUNCTION integratedb_validate_migration"
    execute "DROP FUNCTION integratedb_unmet_claims"
    execute "DROP FUNCTION integratedb_sync"

    drop table(:sync)
  end
end
