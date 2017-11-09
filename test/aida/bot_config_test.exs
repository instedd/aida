defmodule Aida.BotConfigTest do
  use ExUnit.Case
  alias Aida.{Bot, BotConfig}

  @uuid "f1168bcf-59e5-490b-b2eb-30a4d6b01e7b"

  setup do
    BotConfig.init
  end

  test "find non existing bot returns nil" do
    assert BotConfig.find(@uuid) == :not_found
  end

  test "start and find bot" do
    bot = %Bot{id: @uuid}
    assert BotConfig.start(bot) == :ok
    assert BotConfig.find(@uuid) == bot
  end

  test "stop bot" do
    bot = %Bot{id: @uuid}
    assert BotConfig.start(bot) == :ok
    assert BotConfig.stop(bot) == :ok
    assert BotConfig.find(@uuid) == :not_found
  end
end
