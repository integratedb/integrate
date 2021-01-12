defmodule IntegrateWeb.SpecificationView do
  use IntegrateWeb, :view

  alias IntegrateWeb.SpecificationData

  def render("show.json", %{spec: spec}) do
    %{data: SpecificationData.contract(%{match: spec.match})}
  end
end
