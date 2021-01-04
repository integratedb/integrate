# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :integrate,
  ecto_repos: [Integrate.Repo]

# Configures the endpoint
config :integrate, IntegrateWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "nA/h/J9mkINqqVSMc5E33eWFaKSHnprDsu1AOFsoXPkwelASBugWah7/Jlzvsre6",
  render_errors: [view: IntegrateWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Integrate.PubSub,
  live_view: [signing_salt: "/6qkE4+H"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
