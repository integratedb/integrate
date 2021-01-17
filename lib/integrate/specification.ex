defmodule Integrate.Specification do
  @moduledoc """
  The Specification context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Ecto.Multi

  alias Integrate.Repo
  alias Integrate.Util

  alias Integrate.Claims
  alias Integrate.Stakeholders.Stakeholder

  alias Integrate.Specification.{
    Spec,
    Match,
    Path,
    Field,
    Cell
  }

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

    changeset =
      attrs
      |> Map.put("stakeholder_id", stakeholder_id)
      |> Map.put("type", type_value)
      |> init_spec()

    case changeset.valid? do
      true ->
        claims =
          changeset
          |> Changeset.apply_changes()
          |> generate_claims()

        changeset =
          changeset
          |> Changeset.put_assoc(:claims, claims)

        Multi.new()
        |> Multi.delete_all(:previous, previous_query)
        |> Multi.insert(:spec, changeset)
        |> Repo.transaction()

      false ->
        {:error, :spec, changeset, %{}}
    end
  end

  defp generate_claims(%Spec{match: matches}) do
    matches
    |> Enum.reduce([], &match_claims/2)
    |> Enum.reverse()
  end

  defp match_claims(%Match{path: %Path{alternatives: paths}, fields: fields}, acc) do
    # The `paths` are reversed so we can pattern match their ending.
    paths
    |> Enum.map(&String.reverse/1)
    |> Enum.reduce(acc, &path_claims(&1, fields, &2))
  end

  defp path_claims("*." <> reversed_schema_name, fields, acc) do
    schema_name = String.reverse(reversed_schema_name)

    query =
      from c in "columns",
        prefix: "information_schema",
        select: c.table_name,
        distinct: true,
        where: c.table_schema == ^schema_name

    query
    |> Repo.all()
    |> Enum.reduce(acc, fn table_name, acc ->
      reversed_table_name = String.reverse(table_name)
      reversed_path_str = "#{reversed_table_name}.#{reversed_schema_name}"

      path_claims(reversed_path_str, fields, acc)
    end)
  end

  defp path_claims(reversed_path_str, fields, acc) do
    [schema_name, table_name] =
      reversed_path_str
      |> String.reverse()
      |> String.split(".")

    attrs = %{
      schema: schema_name,
      table: table_name
    }

    query =
      from c in "columns",
        prefix: "information_schema",
        select: {
          c.column_name,
          c.data_type,
          c.character_maximum_length,
          c.numeric_precision,
          c.is_nullable
        },
        where:
          c.table_schema == ^schema_name and
            c.table_name == ^table_name

    column_map =
      query
      |> Repo.all()
      |> Enum.reduce(%{}, &build_column_map/2)

    columns =
      fields
      |> Enum.reject(fn x -> x.optional end)
      |> Enum.reduce([], &generate_columns(&1, column_map, attrs, &2))
      |> Enum.reverse()

    claim = Claims.init_claim_with_columns(columns, attrs)

    [claim | acc]
  end

  defp build_column_map({name, type, char_max_length, num_precision, is_nullable}, acc) do
    max_length =
      case char_max_length do
        nil -> num_precision
        val -> val
      end

    is_nullable =
      case is_nullable do
        "YES" ->
          true

        "NO" ->
          false
      end

    attrs = %{
      type: type,
      is_nullable: is_nullable,
      max_length: max_length
    }

    acc
    |> Map.put(name, attrs)
  end

  # If field is asterix, use the column map to expand and use the data value.
  defp generate_columns(%Field{alternatives: [%Cell{name: "*"}]}, column_map, _, acc) do
    column_map
    |> Enum.reduce(acc, fn {name, db} ->
      accumulate_column(name, db.type, db.max_length, db.is_nullable, acc)
    end)
  end

  defp generate_columns(%Field{alternatives: cells}, column_map, path_attrs, acc) do
    cells
    |> Enum.reduce(acc, &generate_column(&1, column_map, path_attrs, &2))
  end

  defp generate_column(%Cell{name: name} = cell, column_map, path_attrs, acc) do
    with {:ok, db} <- get_matching_column(column_map, name),
         {:ok, type} <- get_column_type(cell, db),
         {:ok, min_length} <- get_min_length(cell, db),
         {:ok, is_nullable} <- get_is_nullable(cell, db) do
      accumulate_column(name, type, min_length, is_nullable, acc)
    else
      err ->
        accumulate_column_error(cell, err, path_attrs, acc)
    end
  end

  defp get_matching_column(column_map, name) do
    case Map.get(column_map, name) do
      nil ->
        message = """
        specified field `#{name}` does not exist in the database.
        """

        {:error, :name, message}

      val ->
        {:ok, val}
    end
  end

  defp get_column_type(%Cell{} = cell, db) do
    case cell.type do
      nil ->
        {:ok, db.type}

      val ->
        case cell_type_matches(val, db.type) do
          true ->
            {:ok, val}

          false ->
            message = """
            specified value `#{val}` does not match existing column value `#{db.type}`.
            """

            {:error, :type, message}
        end
    end
  end

  defp get_min_length(%Cell{} = cell, db) do
    case cell.min_length do
      nil ->
        {:ok, db.max_length}

      val ->
        case cell_min_length_matches(val, db.max_length) do
          true ->
            {:ok, val}

          false ->
            message = """
            specified value `#{val}` does not match existing column value `#{db.max_length}`.
            """

            {:error, :min_length, message}
        end
    end
  end

  defp get_is_nullable(%Cell{} = cell, db) do
    case cell.is_nullable do
      nil ->
        {:ok, db.is_nullable}

      val ->
        case val == db.is_nullable do
          true ->
            {:ok, val}

          false ->
            message = """
            specified value `#{val}` does not match existing column value `#{db.is_nullable}`.
            """

            {:error, :is_nullable, message}
        end
    end
  end

  # This is not very sophisticated but we need to be able to match directly in
  # the migration validation query, so let's just start with a rigid direct match
  # to get the ball rolling. In future, we can implement aliases, etc.
  defp cell_type_matches(cell_type, db_type) do
    cell_type == db_type
  end

  # The idea is to protect from truncating strings / losing precision. So the
  # spec says "must be at least this max length".
  defp cell_min_length_matches(cell_min_length, db_max_length) do
    cell_min_length <= db_max_length
  end

  defp accumulate_column(name, type, min_length, is_nullable, acc) do
    attrs = %{
      name: name,
      type: type,
      min_length: min_length,
      is_nullable: is_nullable
    }

    [Claims.init_column(attrs) | acc]
  end

  defp accumulate_column_error(
         %Cell{name: name},
         {:error, key, message},
         %{schema: schema, table: table},
         acc
       ) do
    message = "path: `#{schema}.#{table}`, field: `#{name}`: #{String.trim(message)}"

    changeset =
      %Claims.Column{}
      |> Changeset.change()
      |> Changeset.add_error(key, message)

    [changeset | acc]
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
  Initialises a spec.

  ## Examples

      iex> init_spec(%{field: value})
      %Ecto.Changeset{}

  """
  def init_spec(attrs) do
    %Spec{}
    |> Spec.changeset(attrs)
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
