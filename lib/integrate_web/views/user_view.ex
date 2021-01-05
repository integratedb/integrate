defmodule IntegrateWeb.UserView do
  use IntegrateWeb, :view

  alias IntegrateWeb.AuthView
  alias IntegrateWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.id, username: user.username}
  end

  def render("new_user.json", %{user: user, token: token, refresh_token: refresh_token}) do
    assigns = %{
      id: user.id,
      token: token,
      refresh_token: refresh_token
    }

    AuthView.render("show.json", assigns)
  end
end
