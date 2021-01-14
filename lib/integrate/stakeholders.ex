defmodule Integrate.Stakeholders do
  @moduledoc """
  The Stakeholders context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Integrate.Repo

  alias Integrate.Accounts
  alias Integrate.Util

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
  Initialize a stakeholder.

  ## Examples

      iex> init_stakeholder(%{name: "foo"})
      %Ecto.Changeset{}

  """
  def init_stakeholder(attrs \\ %{}) do
    %Stakeholder{}
    |> Stakeholder.changeset(attrs)
  end

  @doc """
  Creates a stakeholder.

  This inserts a stakeholder, creates a corresponding DDL schema in the database
  and a corresponding database user, with dynamically generated credentials and
  access scoped to the new schema.

  The stakeholder, schema and dbuser are all created with the same name -- and the
  operation will error if this isn't possible. So creating a stakeholder with
  `%{"name" => "foo"}` will create a `foo.*` db schema and a db user called `foo`
  with a dynamically generated password.

  Returns `{:ok, %{stakeholder: %Stakeholder{}, db_user: {username, password}, ddl_schema: name}}`

  ## Examples

      iex> create_stakeholder(user, %{name: "foo"})
      {:ok, %{stakeholder: %Stakeholder{name: "foo"},
              db_user: {"foo", 6ds67f5ds67ds5f7sf675hqx"}, ddl_schema: "foo"}

      iex> create_stakeholder(user, %{name: nil})
      {:error, :stakeholder, %Ecto.Changeset{}, _changes_so_far}

      iex> create_stakeholder(user, %{name: "db-user-taken"})
      {:error, :db_user, exception, _changes_so_far}

      iex> create_stakeholder(user, %{name: "ddl-schema-taken"})
      {:error, :ddl_schema, exception, _changes_so_far}

  """
  def create_stakeholder(%Accounts.User{id: user_id}, attrs \\ %{}) do
    attrs =
      attrs
      |> Util.to_string_keys()
      |> Map.put("user_id", user_id)

    Multi.new()
    |> Multi.insert(:stakeholder, init_stakeholder(attrs))
    |> Multi.run(:db_user, &create_db_user/2)
    |> Multi.run(:ddl_schema, &create_ddl_schema/2)
    |> Repo.transaction()
  end

  defp create_db_user(_repo, %{stakeholder: %Stakeholder{name: name}}) do
    password = generate_db_user_password()

    with {:ok, %{rows: [[database]], num_rows: 1}} <- Repo.query("SELECT current_database()"),
         {:ok, _} <- Repo.query("CREATE ROLE #{name} WITH LOGIN PASSWORD '#{password}'"),
         {:ok, _} <- Repo.query("GRANT CONNECT ON DATABASE #{database} TO #{name}") do
      {:ok, {name, password}}
    else
      err ->
        err
    end
  end

  defp generate_db_user_password do
    :crypto.strong_rand_bytes(12)
    |> Base.encode16(case: :lower)
  end

  defp create_ddl_schema(_repo, %{stakeholder: %Stakeholder{name: name}}) do
    with {:ok, _} <- Repo.query("CREATE SCHEMA IF NOT EXISTS #{name}"),
         {:ok, _} <- Repo.query("GRANT ALL PRIVILEGES ON SCHEMA #{name} TO #{name}") do
      {:ok, name}
    else
      err ->
        err
    end
  end

  @doc """
  Updates a stakeholder.

  This updates the stakeholder and, if necessary, renames the corresponding DDL schema
  and db user in the database.

  As per the following note on https://www.postgresql.org/docs/current/sql-alterrole.html

  > Because MD5-encrypted passwords use the role name as cryptographic salt,
  > renaming a role clears its password if the password is MD5-encrypted.

  If we do rename the role, we regenerate and return a new password for the altered
  db user.

  ## Examples

      iex> update_stakeholder(stakeholder, %{name: "alt"})
      {:ok, %{stakeholder: %Stakeholder{name: "alt"}, db_user: {"alt", new_password}, ddl_schema: "alt"}

      iex> update_stakeholder(%{name: nil})
      {:error, :stakeholder, %Ecto.Changeset{}, _changes_so_far}

      iex> update_stakeholder(%{name: "db-user-taken"})
      {:error, :db_user, exception, _changes_so_far}

      iex> update_stakeholder(%{name: "ddl-schema-taken"})
      {:error, :ddl_schema, exception, _changes_so_far}

  """
  def update_stakeholder(%Stakeholder{name: original_name} = stakeholder, attrs) do
    Multi.new()
    |> Multi.update(:stakeholder, Stakeholder.changeset(stakeholder, attrs))
    |> Multi.run(:db_user, &alter_db_user(&1, &2, original_name))
    |> Multi.run(:ddl_schema, &alter_ddl_schema(&1, &2, original_name))
    |> Repo.transaction()
  end

  defp alter_db_user(_, %{stakeholder: %Stakeholder{name: name}}, original)
       when name == original do
    {:ok, {name, nil}}
  end

  defp alter_db_user(_, %{stakeholder: %Stakeholder{name: name}}, original)
       when name != original do
    password = generate_db_user_password()

    with {:ok, _} <- Repo.query("ALTER ROLE #{original} rename TO #{name}"),
         {:ok, _} <- Repo.query("ALTER ROLE #{name} WITH PASSWORD '#{password}'") do
      {:ok, {name, password}}
    else
      err ->
        err
    end
  end

  defp alter_ddl_schema(_, %{stakeholder: %Stakeholder{name: name}}, original)
       when name == original do
    {:ok, name}
  end

  defp alter_ddl_schema(_, %{stakeholder: %Stakeholder{name: name}}, original)
       when name != original do
    case Repo.query("ALTER SCHEMA #{original} RENAME TO #{name}") do
      {:ok, _} ->
        {:ok, name}

      err ->
        err
    end
  end

  @doc """
  Deletes a stakeholder.

  This deletes the stakeholder and the corresponding db user. It also tries to
  delete the DDL schema, but using `RESTRICT`, so that it will only remove the
  schema if it's empty.

  It's easy for the drop user and drop schema to fail due to dependent objects.
  As a result, we accept a `ensure_all_dropped` flag, defaulting to `false`.
  When false, this tolerates a failure to drop caused by dependent objects and
  indicates the failure to delete by including the db_user and / or ddl_schema
  in the return value.

  When true, we run everything in a transaction, which results in a rollback if
  either drop call fails.

  ## Examples

      iex> delete_stakeholder(stakeholder)
      {:ok, %{stakeholder: %Stakeholder{name: "foo"}, db_user: nil, ddl_schema: nil}

      iex> delete_stakeholder(stakeholder) # schema wasn't empty, wasn't deleted
      {:ok, %{stakeholder: %Stakeholder{name: "foo"}, db_user: nil, ddl_schema: "foo"}

      iex> delete_stakeholder(stakeholder) # role had dependent objects, wasn't deleted
      {:ok, %{stakeholder: %Stakeholder{name: "foo"}, db_user: {"foo", nil}, ddl_schema: "foo"}

      iex> delete_stakeholder(stakeholder)
      {:error, :stakeholder, %Ecto.Changeset{}, _changes_so_far}

      iex> delete_stakeholder(stakeholder)
      {:error, :db_user, exception, _changes_so_far}

      iex> delete_stakeholder(stakeholder)
      {:error, :ddl_schema, exception, _changes_so_far}

  """
  def delete_stakeholder(%Stakeholder{} = stakeholder, ensure_all_dropped \\ false) do
    do_delete_stakeholder(stakeholder, ensure_all_dropped)
  end

  defp do_delete_stakeholder(%Stakeholder{} = stakeholder, true) do
    Multi.new()
    |> Multi.delete(:stakeholder, stakeholder)
    |> Multi.run(:db_user, &drop_db_user/2)
    |> Multi.run(:ddl_schema, &drop_ddl_schema/2)
    |> Repo.transaction()
  end

  defp do_delete_stakeholder(%Stakeholder{} = stakeholder, false) do
    with {:ok, stakeholder} <- Repo.delete(stakeholder),
         {:ok, db_user} <- drop_db_user(Repo, %{stakeholder: stakeholder}),
         {:ok, ddl_schema} <- drop_ddl_schema(Repo, %{stakeholder: stakeholder}) do
      {:ok, %{stakeholder: stakeholder, db_user: db_user, ddl_schema: ddl_schema}}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, :stakeholder, changeset, %{}}

      {:error, %Postgrex.Error{postgres: %{message: <<"role", _::binary>>}} = error} ->
        {:error, :db_user, error, nil}

      {:error, %Postgrex.Error{postgres: %{message: <<"cannot drop schema", _::binary>>}} = error} ->
        {:error, :ddl_schema, error, nil}
    end
  end

  defp drop_db_user(_, %{stakeholder: %Stakeholder{name: name}}) do
    with {:ok, %{rows: [[database]], num_rows: 1}} <- Repo.query("SELECT current_database()"),
         {:ok, _} <- Repo.query("REVOKE CONNECT ON DATABASE #{database} FROM #{name}"),
         {:ok, _} <- Repo.query("REVOKE ALL PRIVILEGES ON SCHEMA #{name} FROM #{name}"),
         {:ok, _} <- Repo.query("DROP ROLE #{name}") do
      {:ok, nil}
    else
      {:error, %Postgrex.Error{postgres: %{code: :dependent_objects_still_exist}}} ->
        {:ok, {name, nil}}

      err ->
        err
    end
  end

  defp drop_ddl_schema(_, %{stakeholder: %Stakeholder{name: name}}) do
    with {:ok, _} <- Repo.query("DROP SCHEMA #{name} RESTRICT") do
      {:ok, nil}
    else
      {:error, %Postgrex.Error{postgres: %{code: :dependent_objects_still_exist}}} ->
        {:ok, name}

      err ->
        err
    end
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
