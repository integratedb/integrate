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

  @doc """
  Gets the associated claims for a spec, preloaded with their
  child associations.

  ## Examples

      iex> get_by_spec(%Spec{})
      [%Claim{}, ...]

  """
  def get_by_spec(%Spec{} = spec) do
    associations = [
      claims: [
        alternatives: [
          columns: [
            :alternatives
          ]
        ]
      ]
    ]

    spec = Repo.preload(spec, associations)
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
  Initialises a `claim` with its `alternatives`.

  Returns a changeset.

  ## Examples

      iex> init_claim_with_alternatives([%ClaimAlternative{}])
      %Ecto.Changeset{}

  """
  def init_claim_with_alternatives(alternatives, attrs \\ %{}) do
    %Claim{}
    |> Claim.changeset_with_alternatives(alternatives, attrs)
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

  alias Integrate.Claims.ClaimAlternative

  @doc """
  Returns the list of claim alternatives.

  ## Examples

      iex> list_claim_alternatives()
      [%ClaimAlternative{}, ...]

  """
  def list_claim_alternatives do
    Repo.all(ClaimAlternative)
  end

  @doc """
  Gets a single claim alternative.

  Raises `Ecto.NoResultsError` if the ClaimAlternative does not exist.

  ## Examples

      iex> get_claim_alternative!(123)
      %ClaimAlternative{}

      iex> get_claim_alternative!(456)
      ** (Ecto.NoResultsError)

  """
  def get_claim_alternative!(id), do: Repo.get!(ClaimAlternative, id)

  @doc """
  Creates a claim alternative.

  ## Examples

      iex> create_claim_alternative(%Claim{}, %{field: value})
      {:ok, %ClaimAlternative{}}

      iex> create_claim_alternative(%Claim{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_claim_alternative(%Claim{id: claim_id}, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:claim_id, claim_id)

    %ClaimAlternative{}
    |> ClaimAlternative.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Initialises a `claim_alternative` and its child `columns` at the same time.

  Returns a changeset.

  ## Examples

      iex> init_claim_alternative_with_columns([%Column{}], %{field: value})
      %Ecto.Changeset{}

      iex> init_claim_alternative_with_columns(%Claim{}, [%Column{}], %{field: value})
      %Ecto.Changeset{}

  """
  def init_claim_alternative_with_columns(columns, attrs) do
    %ClaimAlternative{}
    |> ClaimAlternative.changeset_with_columns(columns, attrs)
  end

  def init_claim_alternative_with_columns(%Claim{id: claim_id}, columns, attrs) do
    attrs =
      attrs
      |> Map.put(:claim_id, claim_id)

    %ClaimAlternative{}
    |> ClaimAlternative.changeset_with_columns(columns, attrs)
  end

  @doc """
  Updates a claim alternative.

  ## Examples

      iex> update_claim_alternative(claim, %{field: new_value})
      {:ok, %ClaimAlternative{}}

      iex> update_claim_alternative(claim, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_claim_alternative(%ClaimAlternative{} = claim_alternative, attrs) do
    claim_alternative
    |> ClaimAlternative.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a claim alternative.

  ## Examples

      iex> delete_claim_alternative(claim)
      {:ok, %ClaimAlternative{}}

      iex> delete_claim_alternative(claim)
      {:error, %Ecto.Changeset{}}

  """
  def delete_claim_alternative(%ClaimAlternative{} = claim_alternative) do
    Repo.delete(claim_alternative)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking claim changes.

  ## Examples

      iex> change_claim(claim)
      %Ecto.Changeset{data: %ClaimAlternative{}}

  """
  def change_claim_alternative(%ClaimAlternative{} = claim_alternative, attrs \\ %{}) do
    ClaimAlternative.changeset(claim_alternative, attrs)
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
  def create_column(%ClaimAlternative{id: claim_alternative_id}, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:claim_alternative_id, claim_alternative_id)

    %Column{}
    |> Column.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Initialise a column.

  ## Examples

      iex> init_column_with_alternatives([%ColumnAlternative{}])
      %Ecto.Changeset{}

  """
  def init_column_with_alternatives(alternatives, attrs \\ %{}) do
    %Column{}
    |> Column.changeset_with_alternatives(alternatives, attrs)
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

  alias Integrate.Claims.ColumnAlternative

  @doc """
  Returns the list of column_alternatives.

  ## Examples

      iex> list_column_alternatives()
      [%ColumnAlternative{}, ...]

  """
  def list_column_alternatives do
    Repo.all(ColumnAlternative)
  end

  @doc """
  Gets a single column_alternative.

  Raises `Ecto.NoResultsError` if the ColumnAlternative does not exist.

  ## Examples

      iex> get_column_alternative!(123)
      %ColumnAlternative{}

      iex> get_column_alternative!(456)
      ** (Ecto.NoResultsError)

  """
  def get_column_alternative!(id), do: Repo.get!(ColumnAlternative, id)

  @doc """
  Creates a column_alternative.

  ## Examples

      iex> create_column_alternative(%Column{} = column, %{field: value})
      {:ok, %ColumnAlternative{}}

      iex> create_column_alternative(%Column{} = column, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_column_alternative(%Column{id: column_id}, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.put(:column_id, column_id)

    %ColumnAlternative{}
    |> ColumnAlternative.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Initialise a column_alternative.

  ## Examples

      iex> init_column_alternative(%{field: value})
      %Ecto.Changeset{}

  """
  def init_column_alternative(attrs) do
    %ColumnAlternative{}
    |> ColumnAlternative.changeset(attrs)
  end

  @doc """
  Updates a column_alternative.

  ## Examples

      iex> update_column_alternative(column_alternative, %{field: new_value})
      {:ok, %ColumnAlternative{}}

      iex> update_column_alternative(column_alternative, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_column_alternative(%ColumnAlternative{} = column_alternative, attrs) do
    column_alternative
    |> ColumnAlternative.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a column_alternative.

  ## Examples

      iex> delete_column_alternative(column_alternative)
      {:ok, %ColumnAlternative{}}

      iex> delete_column_alternative(column_alternative)
      {:error, %Ecto.Changeset{}}

  """
  def delete_column_alternative(%ColumnAlternative{} = column_alternative) do
    Repo.delete(column_alternative)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking column_alternative changes.

  ## Examples

      iex> change_column_alternative(column_alternative)
      %Ecto.Changeset{data: %ColumnAlternative{}}

  """
  def change_column_alternative(%ColumnAlternative{} = column_alternative, attrs \\ %{}) do
    ColumnAlternative.changeset(column_alternative, attrs)
  end

  @doc """
  Coerce a list of claims to a `{schema, table}: column_names` map.

  ## Examples

      iex> to_columns_map([%Claim{}])
      %{{schema, table}: [column_name, ...], ...}

  """
  def to_columns_map(claims) do
    claims
    |> Enum.reduce(%{}, fn %Claim{} = claim, acc ->
      claim.alternatives
      |> Enum.reduce(acc, fn %ClaimAlternative{} = claim_alt, acc ->
        key = {claim_alt.schema, claim_alt.table}
        val = Map.get(acc, key, %{})

        val =
          claim_alt.columns
          |> Enum.reduce(val, fn %Column{} = col, acc ->
            col.alternatives
            |> Enum.reduce(acc, fn %ColumnAlternative{} = col_alt, acc ->
              Map.put(acc, col_alt.name, true)
            end)
          end)

        Map.put(acc, key, val)
      end)
    end)
  end

  def column_grants_for(name, privilege \\ "SELECT") do
    query =
      from g in "role_column_grants",
        prefix: "information_schema",
        select: {
          g.table_schema,
          g.table_name,
          g.column_name
        },
        where:
          g.grantee == ^name and
            g.privilege_type == ^privilege

    query
    |> Repo.all()
  end

  def to_grants_map(results) do
    results
    |> Enum.reduce(%{}, fn {schema_name, table_name, column_name}, acc ->
      key = {schema_name, table_name}

      val =
        acc
        |> Map.get(key, %{})
        |> Map.put(column_name, true)

      acc
      |> Map.put(key, val)
    end)
  end
end
