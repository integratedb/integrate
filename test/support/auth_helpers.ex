defmodule IntegrateWeb.AuthHelpers do
  @moduledoc """
  Help tests that need to authenticate.
  """

  import ExUnit.Assertions, only: [assert: 1]
  import Phoenix.ConnTest, only: [json_response: 2]

  alias Plug.Conn
  alias IntegrateWeb.Auth

  def authenticate(conn, user) do
    {token, _refresh_token} = Auth.login(conn, user.id)

    conn
    |> Conn.put_req_header("authorization", "Bearer #{token}")
  end

  # Fixture
  def authenticate(%{conn: conn, user: user}) do
    %{
      conn: authenticate(conn, user),
      unauthenticated_conn: conn
    }
  end

  def assert_requires_auth(conn) do
    assert json_response(conn, 401)["errors"] != %{}
  end
end
