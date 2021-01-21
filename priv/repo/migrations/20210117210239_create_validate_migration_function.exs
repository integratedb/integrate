defmodule Integrate.Repo.Migrations.CreateValidateMigrationFunction do
  use Ecto.Migration

  defp sql_file(name) do
    parts = [
      :code.priv_dir(:integrate),
      "sql",
      name
    ]

    parts
    |> Path.join()
    |> File.read!()
    |> String.trim()
  end

  def up do
    execute sql_file("integratedb_unmet_claims.sql")
    execute sql_file("integratedb_validate_migration.sql")
  end

  def down do
    execute "DROP FUNCTION integratedb_validate_migration"
    execute "DROP FUNCTION integratedb_unmet_claims"
  end
end
