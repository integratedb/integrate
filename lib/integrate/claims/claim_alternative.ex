defmodule Integrate.Claims.ClaimAlternative do
  @moduledoc """
  Table spec that the information schema must match.
  """
  use Integrate, :schema

  schema "claim_alternatives" do
    field :schema, :string
    field :table, :string

    has_many :columns, Claims.Column
    belongs_to :claim, Claims.Claim

    timestamps()
  end

  @doc false
  def changeset(claim_alt, attrs) do
    claim_alt
    |> cast(attrs, [:schema, :table, :claim_id])
    |> shared_validations()
  end

  @doc false
  def changeset_with_columns(claim_alt, columns, attrs) do
    claim_alt
    |> cast(attrs, [:schema, :table, :claim_id])
    |> put_assoc(:columns, columns)
    |> shared_validations()
  end

  defp shared_validations(changeset) do
    changeset
    |> validate_required([:schema, :table])
    |> Validate.identifier(:schema)
    |> Validate.identifier(:table)
    |> assoc_constraint(:claim)
  end
end
