defmodule Integrate.Claims.Column do
  @moduledoc """
  One or more alternative column specs.
  """
  use Integrate, :schema

  schema "columns" do
    field :optional, :boolean, default: false

    has_many :alternatives, Claims.ColumnAlternative
    belongs_to :claim_alternative, Claims.ClaimAlternative

    timestamps()
  end

  @doc false
  def changeset(column, attrs) do
    column
    |> cast(attrs, [:optional, :claim_alternative_id])
    |> shared_validations()
  end

  @doc false
  def changeset_with_alternatives(column, alternatives, attrs) do
    column
    |> cast(attrs, [:optional, :claim_alternative_id])
    |> put_assoc(:alternatives, alternatives)
    |> shared_validations()
  end

  defp shared_validations(changeset) do
    changeset
    |> validate_required([:optional])
    |> assoc_constraint(:claim_alternative)
  end
end
