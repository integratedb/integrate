defmodule IntegrateWeb.AuthHelpers do
  @moduledoc """
  Help tests that need to authenticate.
  """

  import ExUnit.Assertions, only: [assert: 1]
  import Phoenix.ConnTest, only: [json_response: 2]

  alias Plug.Conn
  alias IntegrateWeb.Auth

  defp put_token(conn, token) do
    conn
    |> Conn.put_req_header("authorization", "Bearer #{token}")
  end

  def authenticate(conn, user) do
    {token, _refresh_token} = Auth.login(conn, user.id)

    put_token(conn, token)
  end

  # Fixture
  def authenticate(%{conn: conn, user: user}) do
    {token, refresh_token} = Auth.login(conn, user.id)

    %{
      conn: put_token(conn, token),
      unauthenticated_conn: conn,
      bearer_token: token,
      refresh_token: refresh_token
    }
  end

  def assert_requires_auth(conn) do
    assert json_response(conn, 401)["errors"] != %{}
  end
end
