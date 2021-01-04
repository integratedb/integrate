defmodule Integrate.Repo.Migrations.EnableLogicalReplication do
  use Ecto.Migration

  def up do
    execute "CREATE PUBLICATION integratedb_publication FOR ALL TABLES"
  end

  def down do
    execute "DROP PUBLICATION integratedb_publication"
  end
end
