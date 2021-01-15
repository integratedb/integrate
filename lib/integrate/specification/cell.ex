defmodule Integrate.Specification.Cell do
  use Integrate, :schema

  @derive {Jason.Encoder, only: [:name, :type, :min_length, :is_nullable]}
  embedded_schema do
    field :name, :string
    field :type, :string
    field :min_length, :integer
    field :is_nullable, :boolean, default: false
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :type, :min_length, :is_nullable])
    |> validate_required(:name)

    # |> validate_format()
  end
end
