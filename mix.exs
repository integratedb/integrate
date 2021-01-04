defmodule Integrate.MixProject do
  use Mix.Project

  def project do
    [
      app: :integrate,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ] ++ docs()
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Integrate.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:broadway, "~> 0.6"},
      {:ecto_sql, "~> 3.4"},
      {:epgsql, "~> 4.2"},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:pgoutput_decoder, "~> 0.1.0"},
      {:phoenix, "~> 1.5.7"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"}
    ]
  end

  defp docs do
    [
      name: "IntegrateDB",
      source_url: "https://github.com/integratedb/integrate",
      homepage_url: "https://integratedb.org",
      docs: [
        api_reference: false,
        passets: "docs/assets",
        extras: [
          "README.md": [filename: "introduction", title: "Introduction"]
        ],
        formatters: ["html"],
        logo: "docs/assets/square-logo.jpg",
        main: "introduction",
        output: "_build_docs"
      ]
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "db.setup"],
      "db.migrate": ["ecto.migrate", "run priv/repo/seeds.exs"],
      "db.reset": ["ecto.drop", "db.setup"],
      "db.setup": ["ecto.create", "enable_logical_replication"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end