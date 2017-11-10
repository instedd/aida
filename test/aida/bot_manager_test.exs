defmodule Aida.BotManagerTest do
  use ExUnit.Case
  alias Aida.{Bot, BotManager}

  @uuid "f1168bcf-59e5-490b-b2eb-30a4d6b01e7b"

  setup do
    BotManager.start_link
    :ok
  end

  test "find non existing bot returns :not_found" do
    assert BotManager.find(@uuid) == :not_found
  end

  test "start and find bot" do
    bot = %Bot{id: @uuid}
    assert BotManager.start(bot) == :ok
    assert BotManager.find(@uuid) == bot
  end

  test "stop bot" do
    bot = %Bot{id: @uuid}
    assert BotManager.start(bot) == :ok
    assert BotManager.stop(@uuid) == :ok
    assert BotManager.find(@uuid) == :not_found
  end
end
