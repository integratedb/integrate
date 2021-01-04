defmodule Mix.Tasks.EnableLogicalReplication do
  use Mix.Task

  alias Ecto.Adapters.SQL
  alias Integrate.Repo

  @shortdoc "Enable logical replication in the postgres database."
  def run(_) do
    [:postgrex, :ecto] |> Enum.each(&Application.ensure_all_started/1)
    {:ok, pid} = Repo.start_link

    {:ok, _} = SQL.query(Repo, "ALTER SYSTEM SET wal_level = 'logical'")

    Process.exit(pid, :normal)
    [:postgrex, :ecto] |> Enum.each(&Application.stop/1)

    log_file = "#{System.fetch_env!("PGDATA")}/server.log"
    System.cmd("pg_ctl", ["-l", log_file, "restart"])
  end
end
