defmodule IntegrateWeb.StakeholderView do
  use IntegrateWeb, :view
  alias IntegrateWeb.StakeholderView

  def render("index.json", %{stakeholders: stakeholders}) do
    %{data: render_many(stakeholders, StakeholderView, "stakeholder.json")}
  end

  def render("show.json", %{stakeholder: stakeholder}) do
    %{data: render_one(stakeholder, StakeholderView, "stakeholder.json")}
  end

  def render("stakeholder.json", %{stakeholder: stakeholder}) do
    %{id: stakeholder.id, name: stakeholder.name}
  end

  def render("new_stakeholder.json", %{stakeholder: stakeholder, db_user: {username, password}}) do
    %{
      data: %{
        id: stakeholder.id,
        name: stakeholder.name,
        credentials: %{
          username: username,
          password: password
        }
      }
    }
  end
end
