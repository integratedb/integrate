defmodule Integrate.Claims do
  @moduledoc """
  The Claims context.
  """

  import Ecto.Query, warn: false
  alias Integrate.Repo

  alias Integrate.Specification.Spec
  alias Integrate.Claims.Claim

  @doc """
  Returns the list of claims.

  ## Examples

      iex> list_claims()
      [%Claim{}, ...]

  """
  def list_claims do
    Repo.all(Claim)
  end

  @doc """
  Gets a single claim.

  Raises `Ecto.NoResultsError` if the Claim does not exist.

  ## Examples

      iex> get_claim!(123)
      %Claim{}

      iex> get_claim!(456)
      ** (Ecto.NoResultsError)

  """
  def get_claim!(id), do: Repo.get!(Claim, id)

  def get_by_spec(%Spec{} = spec) do
    spec = Repo.preload(spec, claims: [:columns])

    spec.claims
  end

  @doc """
  Creates a claim.

  ## Examples

      iex> create_claim(%Spec{} = spec, %{field: value})
      {:ok, %Claim{}}

      iex> create_claim(%Spec{} = spec, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_claim(%Spec{id: spec_id}, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:spec_id, spec_id)

    %Claim{}
    |> Claim.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Initialises a `claim` and its child `columns` at the same time.

  Returns a changeset.

  ## Examples

      iex> init_claim_with_columns([%Column{}], %{field: value})
      %Ecto.Changeset{}

      iex> init_claim_with_columns(%Spec{} = spec, [%Column{}], %{field: value})
      %Ecto.Changeset{}

  """
  def init_claim_with_columns(columns, attrs) do
    %Claim{}
    |> Claim.changeset_with_columns(columns, attrs)
  end

  def init_claim_with_columns(%Spec{id: spec_id}, columns, attrs) do
    attrs =
      attrs
      |> Map.put(:spec_id, spec_id)

    %Claim{}
    |> Claim.changeset_with_columns(columns, attrs)
  end

  @doc """
  Updates a claim.

  ## Examples

      iex> update_claim(claim, %{field: new_value})
      {:ok, %Claim{}}

      iex> update_claim(claim, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_claim(%Claim{} = claim, attrs) do
    claim
    |> Claim.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a claim.

  ## Examples

      iex> delete_claim(claim)
      {:ok, %Claim{}}

      iex> delete_claim(claim)
      {:error, %Ecto.Changeset{}}

  """
  def delete_claim(%Claim{} = claim) do
    Repo.delete(claim)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking claim changes.

  ## Examples

      iex> change_claim(claim)
      %Ecto.Changeset{data: %Claim{}}

  """
  def change_claim(%Claim{} = claim, attrs \\ %{}) do
    Claim.changeset(claim, attrs)
  end

  alias Integrate.Claims.Column

  @doc """
  Returns the list of columns.

  ## Examples

      iex> list_columns()
      [%Column{}, ...]

  """
  def list_columns do
    Repo.all(Column)
  end

  @doc """
  Gets a single column.

  Raises `Ecto.NoResultsError` if the Column does not exist.

  ## Examples

      iex> get_column!(123)
      %Column{}

      iex> get_column!(456)
      ** (Ecto.NoResultsError)

  """
  def get_column!(id), do: Repo.get!(Column, id)

  @doc """
  Creates a column.

  ## Examples

      iex> create_column(%Claim{} = claim, %{field: value})
      {:ok, %Column{}}

      iex> create_column(%Claim{} = claim, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_column(%Claim{id: claim_id}, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:claim_id, claim_id)

    %Column{}
    |> Column.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Initialise a column.

  ## Examples

      iex> init_column(%{field: value})
      %Ecto.Changeset{}

  """
  def init_column(attrs \\ %{}) do
    %Column{}
    |> Column.changeset(attrs)
  end

  @doc """
  Updates a column.

  ## Examples

      iex> update_column(column, %{field: new_value})
      {:ok, %Column{}}

      iex> update_column(column, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_column(%Column{} = column, attrs) do
    column
    |> Column.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a column.

  ## Examples

      iex> delete_column(column)
      {:ok, %Column{}}

      iex> delete_column(column)
      {:error, %Ecto.Changeset{}}

  """
  def delete_column(%Column{} = column) do
    Repo.delete(column)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking column changes.

  ## Examples

      iex> change_column(column)
      %Ecto.Changeset{data: %Column{}}

  """
  def change_column(%Column{} = column, attrs \\ %{}) do
    Column.changeset(column, attrs)
  end
end
