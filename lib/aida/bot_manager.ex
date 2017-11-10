defmodule Aida.BotManager do
  use GenServer
  alias Aida.{DB, Channel, Bot, BotParser}
  @server_ref {:global, __MODULE__}
  @table :bots

  @spec start_link() :: GenServer.on_start
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  @spec start(bot :: Bot.t) :: :ok
  def start(bot) do
    GenServer.call(@server_ref, {:start, bot})
  end

  @spec stop(bot_id :: String.t) :: :ok
  def stop(bot_id) do
    GenServer.call(@server_ref, {:stop, bot_id})
  end

  @spec find(id :: String.t) :: Bot.t | :not_found
  def find(id) do
    case @table |> :ets.lookup(id) do
      [{_id, bot}] -> bot
      [] -> :not_found
    end
  end

  def init([]) do
    @table |> :ets.new([:named_table])
    DB.list_bots
    |> Enum.map(fn db_bot ->
      BotParser.parse(db_bot.id, db_bot.manifest)
    end)
    |> Enum.each(&start_bot/1)

    {:ok, nil}
  end

  def handle_call({:start, bot}, _from, state) do
    start_bot(bot)
    {:reply, :ok, state}
  end

  def handle_call({:stop, bot_id}, _from, state) do
    result = stop_bot(bot_id)
    {:reply, result, state}
  end

  defp start_bot(bot) do
    stop_bot(bot.id)
    @table |> :ets.insert({bot.id, bot})
    bot.channels |> Enum.each(&Channel.start/1)
  end

  defp stop_bot(bot_id) do
    case @table |> :ets.lookup(bot_id) do
      [{_id, bot}] ->
        bot.channels |> Enum.each(&Channel.stop/1)
        @table |> :ets.delete(bot_id)
        :ok
      _ -> :not_found
    end
  end
end
