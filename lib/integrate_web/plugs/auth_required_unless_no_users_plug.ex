defmodule IntegrateWeb.AuthRequiredUnlessNoUsersPlug do
  @moduledoc """
  Ensures that we have a `conn.assigns[:current_user]`.

  If not, returns a 401 response with a JSON error payload.

  **Unless** there are no users yet -- which is the case when creating
  the first root user.
  """

  @behaviour Plug

  alias Integrate.Accounts
  alias IntegrateWeb.AuthRequiredPlug

  def init(opts), do: opts

  def call(conn, _opts) do
    conn.assigns
    |> Map.get(:current_user)
    |> authorize(conn)
  end

  def authorize(nil, conn) do
    case Accounts.any_users_exist? do
      true ->
        AuthRequiredPlug.authorize(nil, conn)

      false ->
        conn
    end
  end

  def authorize(_user, conn) do
    conn
  end
end
