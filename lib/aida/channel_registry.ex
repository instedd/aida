defmodule Aida.ChannelRegistry do
  @server_ref {:global, __MODULE__}
  @table :channels

  @spec start_link() :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  def find({_provider, _id} = key) do
    case @table |> :ets.lookup(key) do
      [{_id, channel}] -> channel
      [] -> :not_found
    end
  end

  def register({_provider, _id} = key, channel) do
    GenServer.call(@server_ref, {:register, key, channel})
  end

  def unregister({_provider, _id} = key) do
    GenServer.call(@server_ref, {:unregister, key})
  end

  def init([]) do
    @table |> :ets.new([:named_table])
    {:ok, nil}
  end

  def handle_call({:register, key, channel}, _from, state) do
    @table |> :ets.insert({key, channel})
    {:reply, :ok, state}
  end

  def handle_call({:unregister, key}, _from, state) do
    @table |> :ets.delete(key)
    {:reply, :ok, state}
  end
end
