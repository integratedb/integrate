defmodule Integrate.Foo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "foos" do
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(foo, attrs) do
    foo
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
