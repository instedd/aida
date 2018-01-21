defmodule Aida.BotManager do
  use GenServer
  alias Aida.{DB, Channel, Bot, Skill, BotParser, Logger, Scheduler}
  @server_ref {:global, __MODULE__}
  @table :bots
  @behaviour Aida.Scheduler.Handler

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

  @spec schedule_wake_up(Bot.t, Skill.t, nil | String.t, DateTime.t) :: :ok
  def schedule_wake_up(bot, skill, data \\ nil, ts) do
    task_name =
      if data do
        "#{bot.id}/#{skill.id}/#{data}"
      else
        "#{bot.id}/#{skill.id}"
      end
    Scheduler.appoint(task_name, ts, __MODULE__)
  end

  def handle_scheduled_task(name, _ts) do
    [bot_id, skill_id | data] = String.split(name, "/", parts: 3)
    data = List.first(data)

    bot = find(bot_id)
    if bot != :not_found do
      Logger.debug("Waking up bot: #{bot_id}, skill: #{skill_id}")
      try do
        Bot.wake_up(bot, skill_id, data)
      rescue
        error ->
          Sentry.capture_exception(error, [stacktrace: System.stacktrace(), extra: %{bot_id: bot_id, skill_id: skill_id}])
      end
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
    {:ok, bot} = Bot.init(bot)
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
