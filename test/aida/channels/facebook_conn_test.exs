defmodule Aida.Channel.FacebookConnTest do
  use Aida.DataCase
  use Phoenix.ConnTest
  import Mock

  alias Aida.{ChannelRegistry, BotManager, BotParser, SessionStore}
  alias Aida.Channel.Facebook

  @uuid "f1168bcf-59e5-490b-b2eb-30a4d6b01e7b"

  setup do
    ChannelRegistry.start_link
    BotManager.start_link
    SessionStore.start_link
    :ok
  end
  describe "with bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json") |> Poison.decode!

      {:ok, bot} = BotParser.parse(@uuid, manifest)
      BotManager.start(bot)
      :ok
    end

    test "incoming facebook challenge" do
      challenge = Ecto.UUID.generate
      params = %{"hub.challenge" => challenge, "hub.mode" => "subscribe", "hub.verify_token" => "qwertyuiopasdfghjklzxcvbnm", "provider" => "facebook"}
      conn = build_conn(:get, "/callback/facebook", params)
        |> Facebook.callback()

      assert response(conn, 200) == challenge
    end

    test_with_mock "incoming facebook message", HTTPoison, [post: fn(_url,_par1,_par2) -> "<html></html>" end] do
      params = %{"entry" => [%{"id" => "1234567890", "messaging" => [%{"message" => %{"mid" => "mid.$cAAaHH1ei9DNl7dw2H1fvJcC5-hi5", "seq" => 493, "text" => "Test message"}, "recipient" => %{"id" => "1234567890"}, "sender" => %{"id" => "1234"}, "timestamp" => 1510697528863}], "time" => 1510697858540}], "object" => "page", "provider" => "facebook"}

      conn = build_conn(:post, "/callback/facebook", params)
        |> Facebook.callback()

      assert response(conn, 200) == "ok"

      assert_message_sent("Hello, I'm a Restaurant bot")
      assert_message_sent("I can do a number of things")
      assert_message_sent("I can give you information about our menu")
      assert_message_sent("I can give you information about our opening hours")
    end
  end

  defp assert_message_sent(message) do
    headers = [{"Content-type", "application/json"}]
    json = %{message: %{text: message}, messaging_type: "RESPONSE", recipient: %{id: "1234"}}
    assert called HTTPoison.post("https://graph.facebook.com/v2.6/me/messages?access_token=QWERTYUIOPASDFGHJKLZXCVBNM", Poison.encode!(json), headers)
  end
end
