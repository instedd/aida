defmodule Aida.BotManagerTest do
  use Aida.DataCase
  alias Aida.{DB, Bot, BotManager, BotParser, TestChannel}

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

    test "stopping an invalid bot returns :not_found" do
      assert BotManager.stop("44837101-dace-4caa-a816-f0c34d168121") == :not_found
    end

    test "channels are started and stopped with the bot" do
      channel = TestChannel.new()
      bot = %Bot{id: @uuid, channels: [channel]}

      BotManager.start(bot)
      assert_received {:start, ^channel}

      BotManager.stop(bot.id)
      assert_received {:stop, ^channel}
    end

    test "channels are restarted when the bot is started again" do
      channel = TestChannel.new()
      bot = %Bot{id: @uuid, channels: [channel]}

      BotManager.start(bot)
      assert_received {:start, ^channel}

      BotManager.start(bot)
      assert_received {:stop, ^channel}
      assert_received {:start, ^channel}
    end
  end

  test "loads existing bots when it starts" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})

    bot = BotParser.parse(db_bot.id, manifest)

    BotManager.start_link

    assert BotManager.find(bot.id) == bot
  end
end
