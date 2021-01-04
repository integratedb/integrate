defmodule Integrate.Repo do
  use Ecto.Repo,
    otp_app: :integrate,
    adapter: Ecto.Adapters.Postgres
end
