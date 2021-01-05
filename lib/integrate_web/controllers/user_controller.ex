defmodule IntegrateWeb.UserController do
  use IntegrateWeb, :controller

  alias Integrate.Accounts
  alias Integrate.Accounts.User

  alias IntegrateWeb.Auth

  action_fallback IntegrateWeb.FallbackController

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def create(conn, %{"user" => params}) do
    with {:ok, %User{} = user} <- Accounts.create_user(params) do
      location = Routes.user_path(conn, :show, user)

      {token, refresh_token} = Auth.login(conn, user.id)
      assigns = %{user: user, token: token, refresh_token: refresh_token}

      conn
      |> put_status(:created)
      |> put_resp_header("location", location)
      |> render("new_user.json", assigns)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def update(conn, %{"id" => id, "user" => params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
