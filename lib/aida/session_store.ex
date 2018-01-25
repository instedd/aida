defmodule Aida.SessionStore do
  use GenServer
  alias Aida.DB
  @server_ref {:global, __MODULE__}
  @type session_data :: map
  @table :sessions

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  @spec find(id :: String.t) :: {String.t, String.t, session_data} | :not_found
  def find(id) do
    case @table |> :ets.lookup(id) do
      [{id, uuid, data}] -> {id, uuid, data}
      [] -> GenServer.call(@server_ref, {:find, id})
    end
  end

  @spec save(id :: String.t, uuid :: String.t, data :: session_data) :: :ok
  def save(id, uuid, data) do
    GenServer.call(@server_ref, {:save, id, uuid, data})
  end

  @spec delete(id :: String.t) :: :ok
  def delete(id) do
    GenServer.call(@server_ref, {:delete, id})
  end

  def init([]) do
    @table |> :ets.new([:named_table])
    {:ok, nil}
  end

  def handle_call({:save, id, uuid, data}, _from, state) do
    @table |> :ets.insert({id, uuid, data})
    DB.save_session(id, uuid, data)
    {:reply, :ok, state}
  end

  def handle_call({:delete, id}, _from, state) do
    @table |> :ets.delete(id)
    DB.delete_session(id)
    {:reply, :ok, state}
  end

  def handle_call({:find, id}, _from, state) do
    result = case @table |> :ets.lookup(id) do
      [{_id, data}] -> data
      [] ->
        case DB.get_session(id) do
          nil -> :not_found
          db_session ->
            @table |> :ets.insert({id, db_session.uuid, db_session.data})
            {db_session.id, db_session.uuid, db_session.data}
        end
    end

    {:reply, result, state}
  end
end
