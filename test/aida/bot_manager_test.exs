defmodule Aida.BotManagerTest do
  use Aida.DataCase
  alias Aida.{DB, Bot, BotManager}

  @uuid "f1168bcf-59e5-490b-b2eb-30a4d6b01e7b"

  describe "with BotManager running" do
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

  test "loads existing bots when it starts" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, bot} = DB.create_bot(%{manifest: manifest})

    BotManager.start_link

    assert BotManager.find(bot.id) == bot
  end
end
