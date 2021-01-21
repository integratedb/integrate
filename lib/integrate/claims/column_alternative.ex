defmodule Integrate.Claims.ColumnAlternative do
  @moduledoc """
  Column specs that the information schema must match.
  """
  use Integrate, :schema

  schema "column_alternatives" do
    field :name, :string
    field :type, :string
    field :min_length, :integer
    field :is_nullable, :boolean

    belongs_to :column, Claims.Column

    timestamps()
  end

  @doc false
  def changeset(col_alt, attrs) do
    col_alt
    |> cast(attrs, [:name, :type, :min_length, :is_nullable, :column_id])
    |> validate_required([:name, :type, :is_nullable])
    |> Validate.identifier(:name)
    # |> ... validate type ...
    |> validate_number(:min_length, greater_than_or_equal_to: 0)
    |> assoc_constraint(:column)
  end
end
