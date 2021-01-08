defmodule IntegrateWeb.Auth do
  @moduledoc """
  Token based authentication logic using `Phoenix.Token`.
  """

  alias Plug.Conn
  alias Phoenix.Token

  alias Integrate.Accounts

  # 2 hours
  @token_max_age 60 * 60 * 4
  @token_salt "integrate::auth::token"

  # 12 hours
  @refresh_token_max_age 60 * 60 * 12
  @refresh_token_salt "integrate::auth::refresh"

  @doc """
  Generate auth tokens for a given `user_id`.

  Returns `{token, refresh_token}`.
  """
  def login(conn, user_id) do
    token = Token.sign(conn, @token_salt, user_id)
    refresh_token = Token.sign(conn, @refresh_token_salt, user_id)

    {token, refresh_token}
  end

  @doc """
  Fetch user from the conn if there's a valid bearer token in
  the authorization header.

  Returns `%User{}` or `nil`.
  """
  def fetch(%Conn{} = conn) do
    user =
      conn
      |> parse_auth_token()
      |> Accounts.get_user()

    {conn, user}
  end

  defp parse_auth_token(conn) do
    with "Bearer " <> token <- fetch_auth_token(conn),
         {:ok, user_id} <- verify_token(conn, token) do
      user_id
    else
      _ ->
        nil
    end
  end

  defp fetch_auth_token(conn) do
    conn
    |> Conn.get_req_header("authorization")
    |> List.first()
  end

  @doc """
  Verify a given candidate `token`.

  Returns `{:ok, user_id}` if valid, otherwise `nil`.
  """
  def verify_token(conn, token) do
    conn
    |> Token.verify(@token_salt, token, max_age: @token_max_age)
  end

  @doc """
  Verify a given candidate `refresh_token`.

  Returns `{:ok, user_id}` if valid, otherwise `nil`.
  """
  def verify_refresh_token(conn, refresh_token) do
    conn
    |> Token.verify(@refresh_token_salt, refresh_token, max_age: @refresh_token_max_age)
  end
end
