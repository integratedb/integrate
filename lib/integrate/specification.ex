defmodule Integrate.Specification do
  @moduledoc """
  The Specification context.
  """

  import Ecto.Query, warn: false

  alias Integrate.Repo
  alias Integrate.Stakeholders
  alias Integrate.Util

  alias Integrate.Specification.Spec

  @doc """
  Returns the list of specs.

  ## Examples

      iex> list_specs()
      [%Spec{}, ...]

  """
  def list_specs do
    Repo.all(Spec)
  end

  @doc """
  Gets a single spec.

  Raises `Ecto.NoResultsError` if the Spec does not exist.

  ## Examples

      iex> get_spec!(123)
      %Spec{}

      iex> get_spec!(456)
      ** (Ecto.NoResultsError)

  """
  def get_spec!(id), do: Repo.get!(Spec, id)

  @doc """
  Creates a spec.

  ## Examples

      iex> create_spec(stakeholder, %{field: value})
      {:ok, %Spec{}}

      iex> create_spec(stakeholder, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_spec(%Stakeholders.Stakeholder{id: stakeholder_id}, attrs) do
    attrs =
      attrs
      |> Util.coerce_atom_keys_to_string_keys()
      |> Map.put("stakeholder_id", stakeholder_id)

    %Spec{}
    |> Spec.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a spec.

  ## Examples

      iex> update_spec(spec, %{field: new_value})
      {:ok, %Spec{}}

      iex> update_spec(spec, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_spec(%Spec{} = spec, attrs) do
    spec
    |> Spec.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a spec.

  ## Examples

      iex> delete_spec(spec)
      {:ok, %Spec{}}

      iex> delete_spec(spec)
      {:error, %Ecto.Changeset{}}

  """
  def delete_spec(%Spec{} = spec) do
    Repo.delete(spec)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking spec changes.

  ## Examples

      iex> change_spec(spec)
      %Ecto.Changeset{data: %Spec{}}

  """
  def change_spec(%Spec{} = spec, attrs \\ %{}) do
    Spec.changeset(spec, attrs)
  end
end
