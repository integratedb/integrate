defmodule Integrate.Specification.MatchAlternative do
  use Integrate, :schema

  @derive {Jason.Encoder, only: [:path, :fields]}
  embedded_schema do
    embeds_one :path, Specification.Path
    embeds_many :fields, Specification.Field
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [])
    |> cast_embed(:path, required: true)
    |> cast_embed(:fields)
  end
end
