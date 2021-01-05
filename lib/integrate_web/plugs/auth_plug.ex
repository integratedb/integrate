defmodule IntegrateWeb.AuthPlug do
  @moduledoc """
  Set `conn.assigns[:current_user]` using the `authorization` header.

  If the current_user is empty, looks in the auth header, tries to parse out
  a valid user_id and uses that to lookup and assign the current_user.
  """

  @behaviour Plug

  alias Plug.Conn
  alias IntegrateWeb.Auth

  def init(opts), do: opts

  def call(conn, _opts) do
    case Map.get(conn.assigns, :current_user) do
      nil ->
        conn
        |> Auth.fetch()
        |> assign_user()

      _user ->
        conn
    end
  end

  defp assign_user({conn, user}) do
    conn
    |> Conn.assign(:current_user, user)
  end
end
