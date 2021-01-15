defmodule Integrate.Claims.Column do
  @moduledoc """
  Column specs that the information schema must match.
  """
  use Integrate, :schema

  schema "columns" do
    field :name, :string
    field :type, :string
    field :min_length, :integer
    field :is_nullable, :boolean

    belongs_to :claim, Claims.Claim

    timestamps()
  end

  @doc false
  def changeset(column, attrs) do
    column
    |> cast(attrs, [:name, :type, :min_length, :is_nullable, :claim_id])
    |> validate_required([:name, :type, :is_nullable])
    |> Validate.identifier(:name)
    |> assoc_constraint(:claim)
  end
end
