defmodule IntegrateWeb.StakeholderController do
  use IntegrateWeb, :controller

  alias Integrate.Stakeholders
  alias Integrate.Stakeholders.Stakeholder

  action_fallback IntegrateWeb.FallbackController

  def index(conn, _params) do
    stakeholders = Stakeholders.list_stakeholders()
    render(conn, "index.json", stakeholders: stakeholders)
  end

  def create(conn, %{"stakeholder" => params}) do
    user = conn.assigns[:current_user]

    with {:ok, %{stakeholder: stakeholder} = assigns} <-
           Stakeholders.create_stakeholder(user, params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.stakeholder_path(conn, :show, stakeholder))
      |> render("new_stakeholder.json", assigns)
    end
  end

  def show(conn, %{"id" => id}) do
    %Stakeholder{} = stakeholder = Stakeholders.get_stakeholder!(id)
    render(conn, "show.json", stakeholder: stakeholder)
  end

  def update(conn, %{"id" => id, "stakeholder" => params}) do
    %Stakeholder{} = stakeholder = Stakeholders.get_stakeholder!(id)

    with {:ok, %{stakeholder: %Stakeholder{} = stakeholder}} <-
          Stakeholders.update_stakeholder(stakeholder, params) do
      render(conn, "show.json", stakeholder: stakeholder)
    end
  end

  def delete(conn, %{"id" => id}) do
    %Stakeholder{} = stakeholder = Stakeholders.get_stakeholder!(id)

    with {:ok, %{stakeholder: %Stakeholder{}}} <- Stakeholders.delete_stakeholder(stakeholder) do
      send_resp(conn, :no_content, "")
    end
  end
end
