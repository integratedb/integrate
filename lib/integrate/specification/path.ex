defmodule Integrate.Specification.Path do
  use Integrate, :schema

  @derive {Jason.Encoder, only: [:schema, :table]}
  embedded_schema do
    field :schema, :string
    field :table, :string
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:schema, :table])
    |> validate_required([:schema, :table])
    |> Validate.identifier(:schema)
    |> Validate.identifier(:table)
  end
end
