defmodule Integrate.Replication.Producer do
  use GenStage

  alias PgoutputDecoder.Messages.{
    Begin,
    Commit,
    Relation,
    Insert,
    Update,
    Delete,
    Truncate,
    Type
  }

  alias Integrate.Replication.Changes.{
    Transaction,
    NewRecord,
    UpdatedRecord,
    DeletedRecord,
    TruncatedRelation
  }

  alias Integrate.Replication.Client
  alias Integrate.Replication.Config

  defmodule State do
    defstruct conn: nil,
              demand: 0,
              queue: nil,
              relations: %{},
              transaction: nil,
              types: %{}
  end

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do
    {:ok, conn} =
      Config.epgsql()
      |> Client.connect()

    slot = Config.slot_name()
    :ok = Client.ensure_replication_slot(conn, slot)

    publication = Config.publication_name()
    :ok = Client.start_replication(conn, publication, slot, self())

    {:producer, %State{conn: conn, queue: :queue.new()}}
  end

  @impl true
  def handle_info({:epgsql, _pid, {:x_log_data, _start_lsn, _end_lsn, binary_msg}}, state) do
    binary_msg
    |> PgoutputDecoder.decode_message()
    |> process_message(state)
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, [], state}
  end

  defp process_message(%Begin{} = msg, state) do
    tx = %Transaction{changes: [], commit_timestamp: msg.commit_timestamp}

    {:noreply, [], %{state | transaction: {msg.final_lsn, tx}}}
  end

  defp process_message(%Type{}, state), do: {:noreply, [], state}

  defp process_message(%Relation{} = msg, state) do
    {:noreply, [], %{state | relations: Map.put(state.relations, msg.id, msg)}}
  end

  defp process_message(%Insert{} = msg, state) do
    relation = Map.get(state.relations, msg.relation_id)

    data = data_tuple_to_map(relation.columns, msg.tuple_data)

    new_record = %NewRecord{relation: {relation.namespace, relation.name}, record: data}

    {lsn, txn} = state.transaction
    txn = %{txn | changes: Enum.reverse([new_record | txn.changes])}

    {:noreply, [], %{state | transaction: {lsn, txn}}}
  end

  defp process_message(%Update{} = msg, state) do
    relation = Map.get(state.relations, msg.relation_id)

    old_data = data_tuple_to_map(relation.columns, msg.old_tuple_data)
    data = data_tuple_to_map(relation.columns, msg.tuple_data)

    updated_record = %UpdatedRecord{
      relation: {relation.namespace, relation.name},
      old_record: old_data,
      record: data
    }

    {lsn, txn} = state.transaction
    txn = %{txn | changes: Enum.reverse([updated_record | txn.changes])}

    {:noreply, [], %{state | transaction: {lsn, txn}}}
  end

  defp process_message(%Delete{} = msg, state) do
    relation = Map.get(state.relations, msg.relation_id)

    data =
      data_tuple_to_map(
        relation.columns,
        msg.old_tuple_data || msg.changed_key_tuple_data
      )

    deleted_record = %DeletedRecord{
      relation: {relation.namespace, relation.name},
      old_record: data
    }

    {lsn, txn} = state.transaction
    txn = %{txn | changes: Enum.reverse([deleted_record | txn.changes])}

    {:noreply, [], %{state | transaction: {lsn, txn}}}
  end

  defp process_message(%Truncate{} = msg, state) do
    truncated_relations =
      for truncated_relation <- msg.truncated_relations do
        relation = Map.get(state.relations, truncated_relation)

        %TruncatedRelation{
          relation: {relation.namespace, relation.name}
        }
      end

    {lsn, txn} = state.transaction
    txn = %{txn | changes: Enum.reverse(truncated_relations ++ txn.changes)}

    {:noreply, [], %{state | transaction: {lsn, txn}}}
  end

  # When we have a new event, enqueue it and see if there's any
  # pending demand we can meet by dispatching events.
  defp process_message(
         %Commit{lsn: commit_lsn, end_lsn: end_lsn},
         %State{transaction: {current_txn_lsn, txn}, conn: conn, queue: queue} = state
       )
       when commit_lsn == current_txn_lsn do
    event = {txn, end_lsn, conn}

    queue = :queue.in(event, queue)
    state = %{state | queue: queue, transaction: nil}

    dispatch_events(state, [])
  end

  # When we have new demand, add it to any pending demand and see if we can
  # meet it by dispatching events.
  @impl true
  def handle_demand(incoming_demand, %{demand: pending_demand} = state) do
    state = %{state | demand: incoming_demand + pending_demand}

    dispatch_events(state, [])
  end

  # When we're done exhausting demand, emit events.
  defp dispatch_events(%{demand: 0} = state, events) do
    emit_events(state, events)
  end

  defp dispatch_events(%{demand: demand, queue: queue} = state, events) do
    case :queue.out(queue) do
      # If the queue has events, recurse to accumulate them
      # as long as there is demand.
      {{:value, event}, queue} ->
        state = %{state | demand: demand - 1, queue: queue}

        dispatch_events(state, [event | events])

      # When the queue is empty, emit any accumulated events.
      {:empty, queue} ->
        state = %{state | queue: queue}

        emit_events(state, events)
    end
  end

  defp emit_events(state, []) do
    {:noreply, [], state}
  end

  defp emit_events(state, events) do
    {:noreply, Enum.reverse(events), state}
  end

  # TODO: Typecast to meaningful Elixir types here later
  defp data_tuple_to_map(_columns, nil), do: %{}

  defp data_tuple_to_map(columns, tuple_data) do
    for {column, index} <- Enum.with_index(columns, 1),
        do: {column.name, :erlang.element(index, tuple_data)},
        into: %{}
  end
end
