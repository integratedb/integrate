defmodule Integrate.Stakeholders do
  @moduledoc """
  The Stakeholders context.
  """

  import Ecto.Query, warn: false
  alias Integrate.Repo

  alias Integrate.Stakeholders.Stakeholder

  @doc """
  Returns the list of stakeholders.

  ## Examples

      iex> list_stakeholders()
      [%Stakeholder{}, ...]

  """
  def list_stakeholders do
    Repo.all(Stakeholder)
  end

  @doc """
  Gets a single stakeholder.

  Raises `Ecto.NoResultsError` if the Stakeholder does not exist.

  ## Examples

      iex> get_stakeholder!(123)
      %Stakeholder{}

      iex> get_stakeholder!(456)
      ** (Ecto.NoResultsError)

  """
  def get_stakeholder!(id), do: Repo.get!(Stakeholder, id)

  @doc """
  Creates a stakeholder.

  ## Examples

      iex> create_stakeholder(%{field: value})
      {:ok, %Stakeholder{}}

      iex> create_stakeholder(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_stakeholder(attrs \\ %{}) do
    %Stakeholder{}
    |> Stakeholder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a stakeholder.

  ## Examples

      iex> update_stakeholder(stakeholder, %{field: new_value})
      {:ok, %Stakeholder{}}

      iex> update_stakeholder(stakeholder, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_stakeholder(%Stakeholder{} = stakeholder, attrs) do
    stakeholder
    |> Stakeholder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a stakeholder.

  ## Examples

      iex> delete_stakeholder(stakeholder)
      {:ok, %Stakeholder{}}

      iex> delete_stakeholder(stakeholder)
      {:error, %Ecto.Changeset{}}

  """
  def delete_stakeholder(%Stakeholder{} = stakeholder) do
    Repo.delete(stakeholder)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking stakeholder changes.

  ## Examples

      iex> change_stakeholder(stakeholder)
      %Ecto.Changeset{data: %Stakeholder{}}

  """
  def change_stakeholder(%Stakeholder{} = stakeholder, attrs \\ %{}) do
    Stakeholder.changeset(stakeholder, attrs)
  end
end
