defmodule IntegrateWeb.AuthController do
  use IntegrateWeb, :controller

  alias Integrate.Accounts
  alias Integrate.Accounts.User

  alias IntegrateWeb.Auth

  action_fallback IntegrateWeb.FallbackController

  def login(conn, %{"data" => params}) do
    with {:ok, credentials} <- Accounts.validate_credentials(params),
         {:ok, %User{id: user_id}} <- Accounts.authenticate(credentials) do
      render_login(conn, user_id)
    else
      nil ->
        {:error, :forbidden}

      val ->
        val
    end
  end

  def renew(conn, %{"data" => param}) do
    with true <- is_binary(param),
        {:ok, user_id} <- Auth.verify_refresh_token(conn, param) do
      render_login(conn, user_id)
    else
      _ ->
        {:error, :forbidden}
    end
  end

  defp render_login(conn, user_id) do
    {token, refresh_token} = Auth.login(conn, user_id)

    assigns = %{
      id: user_id,
      token: token,
      refresh_token: refresh_token
    }

    render(conn, "show.json", assigns)
  end
end
