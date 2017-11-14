defmodule Aida.SessionStore do
  use GenServer
  alias Aida.DB
  @server_ref {:global, __MODULE__}
  @type session_data :: map
  @table :sessions

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  @spec find(id :: String.t) :: session_data | :not_found
  def find(id) do
    case @table |> :ets.lookup(id) do
      [{_id, data}] -> data
      [] -> GenServer.call(@server_ref, {:find, id})
    end
  end

  @spec save(id :: String.t, data :: session_data) :: :ok
  def save(id, data) do
    GenServer.call(@server_ref, {:save, id, data})
  end

  def init([]) do
    @table |> :ets.new([:named_table])
    {:ok, nil}
  end

  def handle_call({:save, id, data}, _from, state) do
    @table |> :ets.insert({id, data})
    DB.save_session(id, data)
    {:reply, :ok, state}
  end

  def handle_call({:find, id}, _from, state) do
    result = case @table |> :ets.lookup(id) do
      [{_id, data}] -> data
      [] ->
        case DB.get_session(id) do
          nil -> :not_found
          db_session ->
            @table |> :ets.insert({id, db_session.data})
            db_session.data
        end
    end

    {:reply, result, state}
  end

end
