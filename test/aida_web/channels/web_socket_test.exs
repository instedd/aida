defmodule AidaWeb.Channel.WebSocketTest do
  alias AidaWeb.BotChannel
  alias Aida.{BotManager, ChannelRegistry, SessionStore}
  use AidaWeb.ChannelCase

  @bot_id "ee20683d-d100-4911-9328-61c7b6e01f84"
  @bot Aida.BotParser.parse!(@bot_id, File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!)

  setup do
    SessionStore.start_link
    ChannelRegistry.start_link
    BotManager.start_link
    BotManager.start(@bot)

    {:ok, bot_id: "db_bot.id"}
  end

  test "fail to join if the bot doesn't exist" do
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:2f6dc44d-dad1-4969-b22f-729c3b77f638", %{"access_token" => "1234"})
  end

  test "fail to join if the bot doesn't have a websocket channel" do
    BotManager.start(%{@bot | channels: []})
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
  end

  test "fail to join if the access token is invalid" do
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{@bot_id}", %{"access_token" => "1234"})
  end

  test "join to an existing bot" do
    assert {:ok, _, _} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
  end

  test "start new session" do
    socket()
      |> subscribe_and_join!(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
      |> push("new_session")
      |> assert_reply(:ok, %{session: session_id})

    session_id = "#{@bot_id}/ws/#{session_id}"

    assert {^session_id, _uuid, %{}} = SessionStore.find(session_id)
  end

  test "start new session with data" do
    data = %{"first_name" => "John", "last_name" => "Doe"}

    socket()
      |> subscribe_and_join!(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
      |> push("new_session", %{"data" => data})
      |> assert_reply(:ok, %{session: session_id})

    session_id = "#{@bot_id}/ws/#{session_id}"

    assert {^session_id, _uuid, ^data} = SessionStore.find(session_id)
  end

  test "push data to be merged in the session" do
    data = %{"first_name" => "John", "last_name" => "Doe"}
    new_data = %{"gender" => "male"}

    socket = socket()
      |> subscribe_and_join!(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})

    socket |> push("new_session", %{"data" => data})
      |> assert_reply(:ok, %{session: session_id})

    socket |> push("put_data", %{"session" => session_id, "data" => new_data})
      |> assert_reply(:ok, _)

    session_id = "#{@bot_id}/ws/#{session_id}"
    data = data |> Map.merge(new_data)
    assert {^session_id, _uuid, ^data} = SessionStore.find(session_id)
  end

  test "bot answers a utb message" do
    socket = socket()
      |> subscribe_and_join!(BotChannel, "bot:#{@bot_id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})

    socket |> push("new_session")
      |> assert_reply(:ok, %{session: session_id})

    socket |> push("utb_msg", %{"session" => session_id, "text" => "hi"})

    assert_push("btu_msg", %{session: ^session_id, text: "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'"}, 1000)
  end
end
