defmodule Integrate.Repo.Migrations.SetupReplication do
  use Ecto.Migration

  alias Integrate.Replication.Config

  def up do
    execute "CREATE PUBLICATION #{Config.publication_name()} FOR ALL TABLES"
  end

  def down do
    execute "DROP PUBLICATION #{Config.publication_name()}"
  end
end
