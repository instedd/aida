defmodule Aida.BotManager do
  use GenServer
  alias Aida.{DB, Channel, Bot, BotParser, Logger}
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

  @spec flush() :: :ok
  def flush() do
    GenServer.call(@server_ref, :flush)
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
    |> Enum.map(&parse_bot/1)
    |> Enum.each(&start_bot/1)

    Aida.PubSub.subscribe_bot_changes
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

  def handle_call(:flush, _from, state) do
    {:reply, :ok, state}
  end

  def handle_info({:bot_created, bot_id}, state) do
    reload_bot(bot_id)
    {:noreply, state}
  end

  def handle_info({:bot_updated, bot_id}, state) do
    reload_bot(bot_id)
    {:noreply, state}
  end

  def handle_info({:bot_deleted, bot_id}, state) do
    reload_bot(bot_id)
    {:noreply, state}
  end

  defp parse_bot(db_bot) do
    BotParser.parse(db_bot.id, db_bot.manifest)
  end

  defp start_bot({:ok, bot}) do
    start_bot(bot)
  end
  defp start_bot({:error, errors}) do
    Logger.error(errors)
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

  defp reload_bot(bot_id) do
    stop_bot(bot_id)
    case DB.get_bot(bot_id) do
      nil -> :ignore
      db_bot ->
        db_bot
        |> parse_bot
        |> start_bot
    end
  end
end
