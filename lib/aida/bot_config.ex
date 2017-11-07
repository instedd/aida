defmodule Aida.BotConfig do
  alias Aida.Bot
  @table :bots

  @spec init() :: :ok
  def init do
    @table |> :ets.new([:named_table])
    :ok
  end

  @spec start(bot :: Bot.t) :: :ok
  def start(bot) do
    @table |> :ets.insert({bot.uuid, bot})
    :ok
  end

  @spec stop(bot :: Bot.t) :: :ok
  def stop(bot) do
    @table |> :ets.delete(bot.uuid)
    :ok
  end

  @spec find(uuid :: String.t) :: Bot.t | :not_found
  def find(uuid) do
    case @table |> :ets.lookup(uuid) do
      [{_uuid, bot}] -> bot
      [] -> :not_found
    end
  end
end
