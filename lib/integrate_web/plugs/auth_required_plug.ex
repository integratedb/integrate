defmodule IntegrateWeb.AuthRequiredPlug do
  @moduledoc """
  Ensures that we have a `conn.assigns[:current_user]`.

  If not, returns a 401 response with a JSON error payload.
  """

  @behaviour Plug

  alias Plug.Conn
  alias Phoenix.Controller

  @error_message %{
    error: %{
      code: 401,
      message: "Unauthorized"
    }
  }

  def init(opts), do: opts

  def call(conn, _opts) do
    conn.assigns
    |> Map.get(:current_user)
    |> authorize(conn)
  end

  def authorize(nil, conn) do
    conn
    |> Conn.put_status(401)
    |> Controller.json(@error_message)
    |> Conn.halt()
  end

  def authorize(_user, conn) do
    conn
  end
end
