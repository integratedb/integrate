defmodule Integrate.Specification do
  @moduledoc """
  The Specification context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi

  alias Integrate.Repo
  alias Integrate.Util

  alias Integrate.Stakeholders.Stakeholder
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
  Gets either the claims or the notifications spec for a given stakeholder.

  ## Examples

      iex> get_spec(123, :claims)
      %Spec{type: "CLAIMS"}

      iex> get_spec(456, :notifications)
      nil

  """
  def get_spec(stakeholder_id, type) do
    Spec
    |> Repo.get_by(stakeholder_id: stakeholder_id, type: Spec.types(type))
  end

  @doc """
  Sets the claims or notifications spec for a given stakeholder.

  ## Examples

      iex> set_spec(stakeholder_id, :claims, attrs)
      {:ok, %{spec: %Spec{} = spec}}

      iex> update_spec(spec, %{field: bad_value})
      {:error, :spec, %Ecto.Changeset{}}

  """
  def set_spec(stakeholder_id, type, %{"match" => _} = attrs) do
    type_value = Spec.types(type)

    previous_query =
      from(s in Spec, where: s.stakeholder_id == ^stakeholder_id and s.type == ^type_value)

    attrs =
      attrs
      |> Map.put("stakeholder_id", stakeholder_id)
      |> Map.put("type", type_value)

    Multi.new()
    |> Multi.delete_all(:previous, previous_query)
    |> Multi.insert(:spec, Spec.changeset(%Spec{}, attrs))
    # |> Multi.insert_all(:claims, Claim, &generate_claims/1)
    |> Repo.transaction()
  end

  defp generate_claims(%{spec: %Spec{id: spec_id, match: matches}}) do
    throw({:NotImplemented, :set_claims, spec_id, matches})
  end

  @doc """
  Creates a spec.

  ## Examples

      iex> create_spec(stakeholder, %{field: value})
      {:ok, %Spec{}}

      iex> create_spec(stakeholder, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_spec(%Stakeholder{id: stakeholder_id}, attrs) do
    attrs =
      attrs
      |> Util.to_string_keys()
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
