defmodule Integrate.Stakeholders.Stakeholder do
  use Integrate, :schema

  schema "stakeholders" do
    field :name, :string

    belongs_to :user, Accounts.User

    timestamps()
  end

  @doc false
  def changeset(stakeholder, attrs) do
    stakeholder
    |> cast(attrs, [:name, :user_id])
    |> validate_required([:name, :user_id])
    |> Validate.normalise_name(:name)
    |> Validate.validate_name(:name)
    |> unique_constraint(:name)
    |> assoc_constraint(:user)
  end
end
