defmodule IntegrateWeb.AuthView do
  use IntegrateWeb, :view

  def render("show.json", %{id: user_id, token: token, refresh_token: refresh_token}) do
    %{
      data: %{
        id: user_id,
        token: token,
        refreshToken: refresh_token
      }
    }
  end
end
