defmodule Integrate.Release do
  @moduledoc """
  Add migration commands to mix release.

  https://hexdocs.pm/phoenix/releases.html#ecto-migrations-and-custom-commands
  """
  alias Ecto.Migrator
  alias Integrate.Repo

  @app :integratedb

  def migrate do
    load_app()

    {:ok, _, _} = Migrator.with_repo(Repo, &Migrator.run(&1, :up, all: true))
  end

  def seed do
    load_app()

    seeds_file = Path.join(["#{:code.priv_dir(@app)}", "repo", "seeds.exs"])
    {:ok, _, _} = Migrator.with_repo(Repo, fn _ -> Code.eval_file(seeds_file) end)
  end

  def rollback(version) do
    load_app()

    {:ok, _, _} = Migrator.with_repo(Repo, &Migrator.run(&1, :down, to: version))
  end

  defp load_app do
    Application.load(:integratedb)
  end
end
