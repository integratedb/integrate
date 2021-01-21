defmodule Integrate.Specification.Match do
  use Integrate, :schema

  @derive {Jason.Encoder, only: [:alternatives, :optional]}
  embedded_schema do
    field :optional, :boolean, default: false

    embeds_many :alternatives, Specification.MatchAlternative
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:optional])
    |> validate_required([:optional])
    |> cast_embed(:alternatives, required: true)
  end
end
