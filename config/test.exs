use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :integratedb, Integrate.Repo,
  username: "postgres",
  password: "postgres",
  database: "integrate_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

config :integratedb, Integrate.Replication, producer: Broadway.DummyProducer

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :integratedb, IntegrateWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
