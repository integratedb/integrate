defmodule Integrate.Replication.Client do
  @moduledoc """
  Database replication client.

  Uses `:epgsql` for it's `start_replication` function. Borrows the connection
  config from the Integrate.Repo is need be. Note that epgsql doesn't support
  connecting via a unix socket.
  """

  alias Integrate.Replication.Config

  @doc """
  Create a database connection.

  Uses the Integrate.Repo config as default, can be overriden by passing in
  epqsql `config` directly `opts`.

  Returns `{:ok, conn}` or `{:error, reason}`.
  """
  def connect(nil) do
    Config.parse_repo_config_into_epgsql_config()
    |> connect()
  end

  def connect(%{} = config) do
    config
    |> Map.put(:replication, 'database')
    |> :epgsql.connect()
  end

  @doc """
  Execute a query / sql statement.

  Returns `{:ok, cols, rows}` or `{:error, error}`.
  """
  def execute(conn, query) do
    conn
    |> :epgsql.squery(query)
  end

  @doc """
  Ensure there is a replication slot called `name`.

  Returns `:ok` on success.
  """
  def ensure_replication_slot(conn, slot) do
    case has_existing_slot(conn, slot) do
      true -> :ok
      false -> create_slot(conn, slot)
    end
  end

  defp has_existing_slot(conn, slot) do
    query = """
    SELECT COUNT(*) >= 1 \
    FROM pg_replication_slots \
    WHERE slot_name = '#{slot}'
    """

    {:ok, _, [{result}]} = execute(conn, query)

    case result do
      "t" -> true
      "f" -> false
    end
  end

  defp create_slot(conn, slot) do
    command = """
    CREATE_REPLICATION_SLOT #{slot} \
    LOGICAL pgoutput \
    NOEXPORT_SNAPSHOT
    """

    case execute(conn, command) do
      {:ok, _, _} -> :ok
      err -> err
    end
  end

  @doc """
  Start consuming logical replication feed using a given `publication` and `slot`.

  The handler can be a pid or a module implementing the `handle_x_log_data` callback.

  Returns `:ok` on success.
  """
  def start_replication(conn, publication, slot, handler) do
    opts = 'proto_version \'1\', publication_names \'#{publication}\''

    conn
    |> :epgsql.start_replication(slot, handler, [], '0/0', opts)
  end

  @doc """
  Confirm successful processing of a WAL segment.

  Returns `:ok` on success.
  """
  def acknowledge_lsn(conn, {xlog, offset} = _lsn_tup) do
    <<decimal_lsn::integer-64>> = <<xlog::integer-32, offset::integer-32>>

    :epgsql.standby_status_update(conn, decimal_lsn, decimal_lsn)
  end
end
