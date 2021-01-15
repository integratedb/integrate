defmodule Integrate.Stakeholders.Stakeholder do
  use Integrate, :schema

  schema "stakeholders" do
    field :name, :string

    belongs_to :user, Accounts.User

    has_many :specs, Specification.Spec
    # has_many :claims, Claims.Claim

    timestamps()
  end

  @doc false
  def changeset(stakeholder, attrs) do
    stakeholder
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name])
    |> Validate.normalise_name(:name)
    |> Validate.validate_name(:name)
    |> unique_constraint(:name)
    |> assoc_constraint(:user)
  end
end
