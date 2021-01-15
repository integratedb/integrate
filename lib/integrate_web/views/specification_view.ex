defmodule IntegrateWeb.SpecificationView do
  use IntegrateWeb, :view

  alias IntegrateWeb.SpecificationData

  def render("show.json", %{spec: spec}) do
    %{match: matches} = SpecificationData.contract(spec)

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
