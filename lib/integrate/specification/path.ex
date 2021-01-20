defmodule Integrate.Specification.Path do
  use Integrate, :schema

  @derive {Jason.Encoder, only: [:alternatives]}
  embedded_schema do
    field :alternatives, {:array, :string}
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:alternatives])
    |> validate_required(:alternatives)
    |> Validate.starts_with_same_schema_name(:alternatives)

    # |> validate_format()
  end
end
