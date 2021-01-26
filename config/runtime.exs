# This file is executed after the code compilation on all environments
# (dev, test, and prod) - for both Mix and releases.
#
# We use it for runtime configuration of releases in production --
# because that allows us to read environment variables at runtime
# rather than compile time.

import Config

if config_env() == :prod do
  # Configure production database to:
  # - connect to the postgres connection string set as the `DATABASE_URL` env var
  # - using SSL
  # - with a `DATABASE_POOL_SIZE` pool of database connections
  database_pool_size = System.get_env("DATABASE_POOL_SIZE", "5") |> String.to_integer()
  database_url = System.fetch_env!("DATABASE_URL")
  config :integratedb, Integrate.Repo,
    adapter: Ecto.Adapters.Postgres,
    migration_lock: nil,
    pool_size: database_pool_size,
    ssl: true,
    start_apps_before_migration: [:ssl],
    url: database_url

  # Configure production web server endpoint to:
  # - listen on `PORT`
  # - use `HOST` when constructing any full URLs
  # - use `SECRET_KEY_BASE` as the base for encrypting and signing data
  host = System.fetch_env!("HOST")
  port = System.fetch_env!("PORT")
  secret_key_base = System.fetch_env!("SECRET_KEY_BASE")
  config :integratedb, IntegrateWeb.Endpoint,
    http: [
      port: port
    ],
    load_from_system_env: true,
    secret_key_base: secret_key_base,
    server: true,
    url: [
      port: 443,
      host: host
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to the previous section:
  #
  #     config :integratedb, IntegrateWeb.Endpoint,
  #       ...
  #       https: [
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH"),
  #         transport_options: [socket_opts: [:inet6]]
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
end
