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
    MatchAlternative,
    Path,
    Field,
    FieldAlternative
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

      iex> get_spec(%Stakeholder{}, :claims)
      %Spec{type: "CLAIMS"}

      iex> get_spec(%Stakeholder{}, :notifications)
      nil

  """
  def get_spec(%Stakeholder{id: stakeholder_id}, type) do
    Spec
    |> Repo.get_by(stakeholder_id: stakeholder_id, type: Spec.types(type))
  end

  @doc """
  Sets the claims or notifications spec for a given stakeholder.

  ## Examples

      iex> set_spec(%Stakeholder{}, :claims, attrs)
      {:ok, %{spec: %Spec{} = spec}}

      iex> set_spec(%Stakeholder{}, :claims, %{field: bad_value})
      {:error, :spec, %Ecto.Changeset{}}

  """
  def set_spec(
        %Stakeholder{id: stakeholder_id, name: name} = stakeholder,
        type,
        %{"match" => _} = attrs
      ) do
    type_value = Spec.types(type)

    changeset =
      attrs
      |> Map.put("stakeholder_id", stakeholder_id)
      |> Map.put("type", type_value)
      |> init_spec()

    case changeset.valid? do
      true ->
        Multi.new()
        |> Multi.run(:previous_spec, &previous_spec(&1, &2, stakeholder, type))
        |> Multi.run(:previous_claims, &previous_claims/2)
        |> Multi.run(:delete_previous_spec, &delete_previous_spec/2)
        |> Multi.run(:claims, &prepare_claims(&1, &2, changeset))
        |> Multi.insert(:spec, &prepare_spec(&1, changeset))
        |> Multi.run(:permissions, &sync_permissions(&1, &2, name))
        |> Repo.transaction()

      false ->
        {:error, :spec, changeset, %{}}
    end
  end

  defp previous_spec(_repo, _context, %Stakeholder{} = stakeholder, type) do
    {:ok, get_spec(stakeholder, type)}
  end

  defp previous_claims(_repo, %{previous_spec: nil}) do
    {:ok, []}
  end

  defp previous_claims(_repo, %{previous_spec: %Spec{} = spec}) do
    {:ok, Claims.get_by_spec(spec)}
  end

  defp delete_previous_spec(_repo, %{previous_spec: nil}) do
    {:ok, nil}
  end

  defp delete_previous_spec(_repo, %{previous_spec: %Spec{} = spec}) do
    Repo.delete(spec)
  end

  defp prepare_claims(_repo, _context, changeset) do
    claims =
      changeset
      |> Changeset.apply_changes()
      |> generate_claims()

    {:ok, claims}
  end

  defp prepare_spec(%{claims: claims}, changeset) do
    changeset
    |> Changeset.put_assoc(:claims, claims)
  end

  defp generate_claims(%Spec{match: matches}) do
    matches
    |> Enum.reduce([], &accumulate_claims/2)
    |> Enum.reverse()
  end

  # If the match is for a wildcard path, then unpack the wildcard
  # into all matching tables and accumulate claims for all of them.
  defp accumulate_claims(
         %Match{
           alternatives: [
             %MatchAlternative{path: %Path{schema: schema_name, table: "*"} = path} = match_alt
           ],
           optional: optional
         } = match,
         acc
       ) do
    query =
      from c in "columns",
        prefix: "information_schema",
        select: c.table_name,
        distinct: true,
        where: c.table_schema == ^schema_name

    query
    |> Repo.all()
    |> Enum.reduce(acc, fn table_name, acc ->
      path = %{path | table: table_name}
      match_alt = %{match_alt | path: path}
      match = %{match | alternatives: [match_alt], optional: optional}

      accumulate_claims(match, acc)
    end)
  end

  defp accumulate_claims(%Match{alternatives: alternatives, optional: optional}, acc) do
    attrs = %{
      optional: optional
    }

    claim =
      alternatives
      |> Enum.map(&init_claim_alternative/1)
      |> Claims.init_claim_with_alternatives(attrs)

    [claim | acc]
  end

  defp init_claim_alternative(%MatchAlternative{
         path: %Path{schema: schema_name, table: table_name} = path,
         fields: fields
       }) do
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

    attrs = Map.from_struct(path)

    fields
    |> Enum.reduce([], &accumulate_columns(&1, column_map, path, &2))
    |> Enum.reverse()
    |> Claims.init_claim_alternative_with_columns(attrs)
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

  # If field is asterisk, use the column map to expand and use the data value.
  defp accumulate_columns(
         %Field{alternatives: [%FieldAlternative{name: "*"}], optional: optional},
         column_map,
         _,
         acc
       ) do
    column_map
    |> Enum.reduce(acc, fn {name, db} ->
      alt_attrs = %{
        name: name,
        type: db.type,
        min_length: db.max_length,
        is_nullable: db.is_nullable
      }

      alternatives = [
        Claims.init_column_alternative(alt_attrs)
      ]

      col_attrs = %{
        optional: optional
      }

      column =
        alternatives
        |> Claims.init_column_with_alternatives(col_attrs)

      [column | acc]
    end)
  end

  defp accumulate_columns(
         %Field{alternatives: alternatives, optional: optional},
         column_map,
         %Path{} = path,
         acc
       ) do
    attrs = %{
      optional: optional
    }

    column =
      alternatives
      |> Enum.map(&init_column_alternative(&1, column_map, path))
      |> Claims.init_column_with_alternatives(attrs)

    [column | acc]
  end

  defp init_column_alternative(%FieldAlternative{name: name} = field_alt, column_map, %Path{
         schema: schema_name,
         table: table_name
       }) do
    with {:ok, db} <- get_matching_column(column_map, name),
         {:ok, type} <- get_column_type(field_alt, db),
         {:ok, min_length} <- get_min_length(field_alt, db),
         {:ok, is_nullable} <- get_is_nullable(field_alt, db) do
      attrs = %{
        name: name,
        type: type,
        min_length: min_length,
        is_nullable: is_nullable
      }

      Claims.init_column_alternative(attrs)
    else
      {:error, key, message} ->
        message =
          "path: `#{schema_name}.#{table_name}`, field: `#{name}`: #{String.trim(message)}"

        %Claims.ColumnAlternative{}
        |> Changeset.change()
        |> Changeset.add_error(key, message)
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

  defp get_column_type(%FieldAlternative{type: type}, db) do
    case type do
      nil ->
        {:ok, db.type}

      val ->
        case field_alt_type_matches(val, db.type) do
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

  defp get_min_length(%FieldAlternative{min_length: min_length}, db) do
    case min_length do
      nil ->
        {:ok, db.max_length}

      val ->
        case field_alt_min_length_matches(val, db.max_length) do
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

  defp get_is_nullable(%FieldAlternative{is_nullable: is_nullable}, db) do
    case is_nullable do
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
  defp field_alt_type_matches(field_alt_type, db_type) do
    field_alt_type == db_type
  end

  # The idea is to protect from truncating strings / losing precision. So the
  # spec says "must be at least this max length".
  defp field_alt_min_length_matches(field_alt_min_length, db_max_length) do
    field_alt_min_length <= db_max_length
  end

  defp sync_permissions(_repo, %{claims: claims, previous_claims: previous_claims}, name) do
    previously_claimed_map =
      previous_claims
      |> Claims.to_columns_map()

    existing_grant_map =
      name
      |> Claims.column_grants_for()
      |> Claims.to_grants_map()

    newly_claimed_map =
      claims
      |> Enum.map(&Changeset.apply_changes/1)
      |> Claims.to_columns_map()

    # Find all the columns no longer claimed and revoke permission on them.
    should_revoke =
      previously_claimed_map
      |> Util.drop_matching(newly_claimed_map)
      |> Util.take_matching(existing_grant_map)

    # Find all the columns now newly claimed and grant permission on them.
    should_grant =
      newly_claimed_map
      |> Util.drop_matching(previously_claimed_map)
      |> Util.drop_matching(existing_grant_map)

    with {:ok, num_revoked} <- apply_claim_permissions(should_revoke, :revoke, name),
         {:ok, num_granted} <- apply_claim_permissions(should_grant, :grant, name) do
      {:ok, {num_revoked, num_granted}}
    else
      err ->
        err
    end
  end

  defp apply_claim_permissions(items, action, name) when action in [:grant, :revoke] do
    state = %{
      counter: 0,
      error: nil
    }

    result =
      items
      |> Enum.reduce(state, &apply_claim_permission(action, &1, name, &2))

    case result do
      %{counter: counter, error: nil} ->
        {:ok, counter}

      %{error: error} ->
        {:error, error}
    end
  end

  defp apply_claim_permission(_, _, _, %{error: error} = state) when not is_nil(error), do: state
  defp apply_claim_permission(_, {_, columns}, _, state) when columns == %{}, do: state

  defp apply_claim_permission(
         action,
         {{schema, table}, columns},
         grantee,
         %{error: nil, counter: counter} = state
       ) do
    apply = String.upcase("#{action}")

    preposition =
      case action do
        :grant -> "TO"
        :revoke -> "FROM"
      end

    column_list =
      columns
      |> Map.keys()
      |> Enum.join(", ")

    command =
      "#{apply} SELECT (#{column_list}) ON TABLE #{schema}.#{table} #{preposition} #{grantee}"

    case Repo.query(command) do
      {:ok, %Postgrex.Result{columns: nil, command: ^action}} ->
        %{state | counter: counter + Enum.count(columns)}

      {:error, error} ->
        %{state | error: error}
    end
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
