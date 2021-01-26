use Mix.Config

# Force SSL / HSTS.
config :integratedb, IntegrateWeb.Endpoint,
  force_ssl: [
    hsts: true,
    expires: 31536000,
    preload: true,
    rewrite_on: [:x_forwarded_proto],
    subdomains: true
  ]

# Do not print debug messages in production
config :logger, level: :info
