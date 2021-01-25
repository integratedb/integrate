defmodule Integrate.Repo do
  use Ecto.Repo,
    otp_app: :integratedb,
    adapter: Ecto.Adapters.Postgres
end
