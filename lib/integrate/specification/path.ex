defmodule Integrate.Specification.Path do
  use Integrate, :schema

  embedded_schema do
    field :alternatives, {:array, :string}
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:alternatives])
    |> validate_required(:alternatives)

    # |> validate_format()
  end
end
