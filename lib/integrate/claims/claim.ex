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
    field :schema, :string
    field :table, :string

    has_many :columns, Claims.Column
    belongs_to :spec, Specification.Spec

    timestamps()
  end

  @doc false
  def changeset(claim, attrs) do
    claim
    |> cast(attrs, [:schema, :table, :spec_id])
    |> shared_validations()
  end

  @doc false
  def changeset_with_columns(claim, columns, attrs) do
    claim
    |> cast(attrs, [:schema, :table, :spec_id])
    |> put_assoc(:columns, columns)
    |> shared_validations()
  end

  defp shared_validations(changeset) do
    changeset
    |> validate_required([:schema, :table])
    |> Validate.identifier(:schema)
    |> Validate.identifier(:table)
    |> assoc_constraint(:spec)
  end
end
