defmodule Aida.Channel.FacebookTest do
  alias Aida.Channel.Facebook
  alias Aida.{Channel, ChannelRegistry, DB, BotParser, BotManager}
  use ExUnit.Case
  use Aida.DataCase
  use Phoenix.ConnTest

  @bot_id "986a4b66-b3a0-40d5-83b2-c535427dc0f9"
  @page_id "1234567890"

  setup do
    ChannelRegistry.start_link
    BotManager.start_link
    :ok
  end

  describe "with bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json") |> Poison.decode!
      {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(db_bot.id, manifest)
      BotManager.start(bot)
      [bot: bot]
    end

    test "looking for channel in nonexistent bot returns :not_found" do
      assert Facebook.find_channel_for_page_id(@page_id, "nonexistent") == :not_found
    end

    test "looking for not registered channel in bot returns :not_found", %{bot: bot} do
      assert Facebook.find_channel_for_page_id("notregistered", bot.id) == :not_found
    end

    test "looking for registered channel for specific bot returns channel", %{bot: bot} do
      channel = Facebook.find_channel_for_page_id(@page_id, bot.id)
      assert channel.bot_id == bot.id
      assert channel.page_id == @page_id
    end
  end

  test "looking for non registered channel returns :not_found" do
    assert Facebook.find_channel_for_page_id(@page_id) == :not_found
  end

  test "register/unregister channel when it starts/stops" do
    channel = %Facebook{
      bot_id: @bot_id,
      page_id: @page_id
    }

    channel |> Channel.start
    assert Facebook.find_channel_for_page_id(@page_id) == channel

    channel |> Channel.stop
    assert Facebook.find_channel_for_page_id(@page_id) == :not_found
  end
end
