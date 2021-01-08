defmodule Integrate.Repo.Migrations.CreateSchema do
  use Ecto.Migration

  alias Integrate.Config

  def up do
    execute "CREATE SCHEMA #{Config.namespace()}"
  end

  def down do
    execute "DROP SCHEMA #{Config.namespace()}"
  end
end
