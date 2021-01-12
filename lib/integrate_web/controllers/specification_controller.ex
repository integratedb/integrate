defmodule IntegrateWeb.SpecificationController do
  use IntegrateWeb, :controller

  alias Integrate.Specification
  alias Integrate.Specification.Spec

  alias IntegrateWeb.SpecificationData

  action_fallback IntegrateWeb.FallbackController

  def show(conn, %{"id" => stakeholder_id, "type" => type_param}) do
    type = String.to_existing_atom(type_param)

    with {:ok, %Spec{} = spec} <- Specification.get_spec(stakeholder_id, type) do
      render(conn, "show.json", spec: spec)
    end
  end

  def update(conn, %{"id" => stakeholder_id, "type" => type_str, "data" => data}) do
    type = String.to_existing_atom(type_str)

    with {:ok, attrs} <- SpecificationData.validate_and_expand(data),
         {:ok, %{spec: %Spec{} = spec}} <- Specification.set_spec(stakeholder_id, type, attrs) do
      render(conn, "show.json", spec: spec)
    end
  end
end
