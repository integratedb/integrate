defmodule IntegrateWeb.SpecificationView do
  use IntegrateWeb, :view

  alias IntegrateWeb.SpecificationData

  def render("show.json", %{spec: spec}) do
    matches = SpecificationData.contract(spec.match)

    %{
      data: %{
        type: spec.type,
        match: matches
      }
    }
  end

  def render("show_empty.json", %{type: type}) do
    %{
      data: %{
        type: type,
        match: []
      }
    }
  end
end
