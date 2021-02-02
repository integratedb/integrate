defmodule Integrate.Repo.Migrations.CreatePublication do
  use Ecto.Migration

  alias Integrate.Config
  alias Integrate.Replication.Config, as: ReplConfig

  defp publication_name do
    ReplConfig.publication_name()
  end

  defp sync_table do
    "#{Config.namespace()}.sync"
  end

  def up do
    execute "CREATE PUBLICATION #{publication_name()} FOR TABLE #{sync_table()}"
  end

  def down do
    execute "DROP PUBLICATION #{publication_name()}"
  end
end

