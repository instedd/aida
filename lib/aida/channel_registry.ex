defmodule Aida.ChannelRegistry do
  alias Aida.Channel
  @server_ref {:global, __MODULE__}
  @table :channels

  @typep key :: {provider :: atom, id :: any}

  @spec start_link() :: GenServer.on_start()
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  @spec find(key :: key) :: Channel.t() | :not_found
  def find({_provider, _id} = key) do
    case @table |> :ets.lookup(key) do
      [{_id, channel}] -> channel
      [] -> :not_found
    end
  end

  @spec register(key :: key, channel :: Channel.t()) :: :ok
  def register({_provider, _id} = key, channel) do
    GenServer.call(@server_ref, {:register, key, channel})
  end

  @spec unregister(key :: key) :: :ok
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
