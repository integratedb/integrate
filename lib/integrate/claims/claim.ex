defmodule Integrate.Claims.Claim do
  @moduledoc """
  Denormalised claims that a stakeholder application has on the structure
  of the database.

  These are updated (deleted and re-writen) whenever:

  a. the user updates their claims or notifications specification
  b. the database structure changes

  This allows for specs like `fields: ["*"]` to be unpacked into claims on
  every field that exists at that time.
  """
  use Integrate, :schema

  schema "claims" do
    field :optional, :boolean, default: false

    has_many :alternatives, Claims.ClaimAlternative
    belongs_to :spec, Specification.Spec

    timestamps()
  end

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:optional, :spec_id])
    |> shared_validations()
  end

  @doc false
  def changeset_with_alternatives(claim, alternatives, attrs) do
    claim
    |> cast(attrs, [:optional, :spec_id])
    |> put_assoc(:alternatives, alternatives)
    |> shared_validations()
  end

  defp shared_validations(changeset) do
    changeset
    |> validate_required([:optional])
    |> assoc_constraint(:spec)
  end
end
