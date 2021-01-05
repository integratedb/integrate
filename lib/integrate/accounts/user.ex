defmodule Integrate.Accounts.User do
  use Integrate, :schema

  schema "users" do
    field :username, :string

    field :password, :string, virtual: true
    field :password_hash, :string

    has_many :stakeholders, Stakeholders.Stakeholder

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :password])
    |> validate_required([:username, :password])
    |> Validate.normalise_name(:username)
    |> Validate.validate_name(:username)
    |> validate_length(:password, min: 10, max: 16384)
    |> put_pass_hash()
    |> unique_constraint(:username)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    changeset
    |> change(Argon2.add_hash(password))
  end

  defp put_pass_hash(changeset) do
    changeset
  end
end
