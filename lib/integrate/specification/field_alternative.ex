defmodule Integrate.Specification.FieldAlternative do
  use Integrate, :schema

  @derive {Jason.Encoder, only: [:name, :type, :min_length, :is_nullable]}
  embedded_schema do
    field :name, :string
    field :type, :string
    field :min_length, :integer
    field :is_nullable, :boolean
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :type, :min_length, :is_nullable])
    |> validate_required(:name)
    |> Validate.identifier(:name)
    # |> ... validate type ...
    |> validate_number(:min_length, greater_than_or_equal_to: 0)
  end
end
