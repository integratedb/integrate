defmodule IntegrateWeb.SpecificationController do
  use IntegrateWeb, :controller

  alias Integrate.Specification
  alias Integrate.Specification.Spec
  alias Integrate.SpecificationData

  alias Integrate.Stakeholders
  alias Integrate.Stakeholders.Stakeholder

  action_fallback IntegrateWeb.FallbackController

  @types ["claims", "notifications"]

  def show(conn, %{"id" => stakeholder_id, "type" => type_param}) when type_param in @types do
    type = String.to_existing_atom(type_param)
    context = {:stakeholder, Stakeholders.get_stakeholder(stakeholder_id)}

    with {:stakeholder, %Stakeholder{} = stakeholder} <- context,
         {:spec, %Spec{} = spec} <- {:spec, Specification.get_spec(stakeholder, type)} do
      render(conn, "show.json", spec: spec)
    else
      {:stakeholder, nil} ->
        {:error, :not_found}

      {:spec, nil} ->
        render(conn, "show_empty.json", type: type)

      err ->
        err
    end
  end

  def update(conn, %{"id" => stakeholder_id, "type" => type_param, "data" => data})
      when type_param in @types do
    type = String.to_existing_atom(type_param)
    context = {:stakeholder, Stakeholders.get_stakeholder(stakeholder_id)}

    with {:stakeholder, %Stakeholder{} = stakeholder} <- context,
         {:ok, attrs} <- SpecificationData.validate_and_expand(data),
         {:ok, %{spec: %Spec{} = spec}} <- Specification.set_spec(stakeholder, type, attrs) do
      render(conn, "show.json", spec: spec)
    else
      {:stakeholder, nil} ->
        {:error, :not_found}

      err ->
        err
    end
  end
end
