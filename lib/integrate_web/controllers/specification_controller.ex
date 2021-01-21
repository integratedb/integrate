defmodule IntegrateWeb.SpecificationController do
  use IntegrateWeb, :controller

  alias Integrate.Specification
  alias Integrate.Specification.Spec
  alias Integrate.SpecificationData

  action_fallback IntegrateWeb.FallbackController

  @types ["claims", "notifications"]

  def show(conn, %{"id" => stakeholder_id, "type" => type_param}) when type_param in @types do
    type = String.to_existing_atom(type_param)

    case Specification.get_spec(stakeholder_id, type) do
      %Spec{} = spec ->
        render(conn, "show.json", spec: spec)

      nil ->
        render(conn, "show_empty.json", type: type)
    end
  end

  def update(conn, %{"id" => stakeholder_id, "type" => type_param, "data" => data})
      when type_param in @types do
    type = String.to_existing_atom(type_param)

    with {:ok, attrs} <- SpecificationData.validate_and_expand(data),
         {:ok, %{spec: %Spec{} = spec}} <- Specification.set_spec(stakeholder_id, type, attrs) do
      render(conn, "show.json", spec: spec)
    end
  end
end
