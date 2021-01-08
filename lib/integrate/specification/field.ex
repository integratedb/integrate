defmodule Integrate.Specification.Field do
  use Integrate, :schema

  embedded_schema do
    field :optional, :boolean

    embeds_many :alternatives, Specification.Column
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:optional])
    |> validate_required([:optional])
    |> cast_embed(:alternatives, required: true)
  end
end
