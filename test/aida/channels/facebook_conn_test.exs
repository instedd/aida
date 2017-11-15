defmodule Aida.Channel.FacebookConnTest do
  use Aida.DataCase
  use Phoenix.ConnTest
  alias Aida.{ChannelRegistry, BotManager, BotParser}
  alias Aida.Channel.Facebook

  @uuid "f1168bcf-59e5-490b-b2eb-30a4d6b01e7b"

  setup do
    ChannelRegistry.start_link
    BotManager.start_link
    :ok
  end
  describe "with bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json") |> Poison.decode!

      bot = BotParser.parse(@uuid, manifest)
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

    test "incoming facebook message" do
      challenge = Ecto.UUID.generate
      params = %{"entry" => [%{"id" => "1234567890", "messaging" => [%{"message" => %{"mid" => "mid.$cAAaHH1ei9DNl7dw2H1fvJcC5-hi5", "seq" => 493, "text" => "Test message"}, "recipient" => %{"id" => "1234567890"}, "sender" => %{"id" => "1234"}, "timestamp" => 1510697528863}], "time" => 1510697858540}], "object" => "page", "provider" => "facebook"}

      conn = build_conn(:post, "/callback/facebook", params)
        |> Facebook.callback()

      assert response(conn, 200) == "ok"
    end
  end
end
