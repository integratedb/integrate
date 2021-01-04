defmodule Integrate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  # alias Cainophile.Adapters.Postgres, as: WalPublisher

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Integrate.Repo,

      # # Start the Telemetry supervisor
      # IntegrateWeb.Telemetry,

      # # Start the PubSub system
      # {Phoenix.PubSub, name: Integrate.PubSub},

      # # Start the Endpoint (http/https)
      # IntegrateWeb.Endpoint,

      # Start Broadway pipeline ingesting and processing the postgres database's
      # logical replication feed.
      Integrate.Replication
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Integrate.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    IntegrateWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
