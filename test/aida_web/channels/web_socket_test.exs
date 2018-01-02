defmodule AidaWeb.Channel.WebSocketTest do
  alias AidaWeb.BotChannel
  alias Aida.{BotManager, ChannelRegistry}
  use AidaWeb.ChannelCase

  @bot_id "ee20683d-d100-4911-9328-61c7b6e01f84"
  @bot Aida.BotParser.parse!(@bot_id, File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!)

  setup do
    ChannelRegistry.start_link
    BotManager.start_link

    {:ok, bot_id: "db_bot.id"}
  end

  test "fail to join if the bot doesn't exist" do
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:2f6dc44d-dad1-4969-b22f-729c3b77f638", %{"access_token" => "1234"})
  end

  test "fail to join if the bot doesn't have a websocket channel" do
    BotManager.start(%{@bot | channels: []})
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{@bot_id}", %{"access_token" => "1234"})
  end

  test "fail to join if the access token is invalid" do
    BotManager.start(@bot)
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{@bot_id}", %{"access_token" => "1234"})
  end

  test "join to an existing bot" do
    BotManager.start(@bot)
    assert {:ok, _, _} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
  end
end
