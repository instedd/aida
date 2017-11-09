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
    @table |> :ets.insert({bot.id, bot})
    :ok
  end

  @spec stop(bot :: Bot.t) :: :ok
  def stop(bot) do
    @table |> :ets.delete(bot.id)
    :ok
  end

  @spec find(id :: String.t) :: Bot.t | :not_found
  def find(id) do
    case @table |> :ets.lookup(id) do
      [{_id, bot}] -> bot
      [] -> :not_found
    end
  end
end
