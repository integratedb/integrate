defmodule Integrate.Specification.PathItem do
  @moduledoc """
  Represents a parsed path item like
  """

  use Integrate, :schema

  @types %{
    asterix: "ASTERIX",
    literal: "LITERAL"
  }

  def types(key) do
    Map.fetch!(@types, key)
  end

  embedded_schema do
    field :type, :string
    field :value, :string
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:type, :value])
    |> validate_required([:type, :value])
    |> validate_inclusion(:type, Map.values(@types))
  end
end
