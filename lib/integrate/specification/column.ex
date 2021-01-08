defmodule Integrate.Specification.Column do
  use Integrate, :schema

  embedded_schema do
    field :name, :string
    field :type, :string
    field :min_length, :integer
  end

  @doc false
  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [:name, :type, :min_length])
    |> validate_required(:name)

    # |> validate_format()
  end
end
