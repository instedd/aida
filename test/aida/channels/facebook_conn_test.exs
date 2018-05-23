defmodule Aida.Channel.FacebookConnTest do
  use Aida.DataCase
  use Phoenix.ConnTest
  import Mock

  alias Aida.{ChannelRegistry, Crypto, BotManager, BotParser, DB, DB.Session}
  alias Aida.Channel.Facebook

  @fb_api_mock [
    send_message: &__MODULE__.send_message_mock/3,
    get_profile: &__MODULE__.get_profile_mock/2
  ]

  @incoming_message %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "message" => %{
              "mid" => "mid.$cAAaHH1ei9DNl7dw2H1fvJcC5-hi5",
              "seq" => 493,
              "text" => "Test message"
            },
            "recipient" => %{"id" => "1234567890"},
            "sender" => %{"id" => "1234"},
            "timestamp" => 1_510_697_528_863
          }
        ],
        "time" => 1_510_697_858_540
      }
    ],
    "object" => "page",
    "provider" => "facebook"
  }

  @incoming_session_id_message %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "message" => %{
              "mid" => "mid.$cAAaHH1ei9DNl7dw2H1fvJcC5-hi5",
              "seq" => 493,
              "text" => "##SESSION"
            },
            "recipient" => %{"id" => "1234567890"},
            "sender" => %{"id" => "1234"},
            "timestamp" => 1_510_697_528_863
          }
        ],
        "time" => 1_510_697_858_540
      }
    ],
    "object" => "page",
    "provider" => "facebook"
  }

  @incoming_reset_message %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "message" => %{
              "mid" => "mid.$cAAaHH1ei9DNl7dw2H1fvJcC5-hi5",
              "seq" => 493,
              "text" => "##RESET"
            },
            "recipient" => %{"id" => "1234567890"},
            "sender" => %{"id" => "1234"},
            "timestamp" => 1_510_697_528_863
          }
        ],
        "time" => 1_510_697_858_540
      }
    ],
    "object" => "page",
    "provider" => "facebook"
  }

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

    test "incoming facebook challenge" do
      challenge = Ecto.UUID.generate
      params = %{"hub.challenge" => challenge, "hub.mode" => "subscribe", "hub.verify_token" => "qwertyuiopasdfghjklzxcvbnm", "provider" => "facebook"}
      conn = build_conn(:get, "/callback/facebook", params)
        |> Facebook.callback()

      assert response(conn, 200) == challenge
    end

    test "incoming facebook message" do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn = build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        assert_message_sent("Hello, I'm a Restaurant bot")
        assert_message_sent("I can do a number of things")
        assert_message_sent("I can give you information about our menu")
        assert_message_sent("I can give you information about our opening hours")
      end
    end

    test "incoming system session id message", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn = build_conn(:post, "/callback/facebook", @incoming_session_id_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert_message_sent(String.slice(session.id, -7..-1))
      end
    end

    test "incoming system reset message", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn = build_conn(:post, "/callback/facebook", @incoming_reset_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        assert_message_sent("Session was reset")
      end
    end

    test "doesn't send message when receiving a 'read' event" do
      params = %{"entry" => [%{"id" => "1234567890", "messaging" => [%{"read" => %{"seq" => 0, "watermark" => "12345"}, "recipient" => %{"id" => "1234567890"}, "sender" => %{"id" => "1234"}, "timestamp" => 1510697528863}], "time" => 1510697858540}], "object" => "page", "provider" => "facebook"}

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        build_conn(:post, "/callback/facebook", params)
        |> Facebook.callback()

        refute called FacebookApi.send_message(:_, :_, :_)
      end
    end

    test "doesn't send message when receiving a 'delivery' event" do
      params = %{"entry" => [%{"id" => "1234567890", "messaging" => [%{"delivery" => %{"mids" => ["mid.$cAAFhHf1znQRnXHiKMlhKzNB8Zr8v"], "seq" => 0, "watermark" => "12345"}, "recipient" => %{"id" => "1234567890"}, "sender" => %{"id" => "1234"}, "timestamp" => 1510697528863}], "time" => 1510697858540}], "object" => "page", "provider" => "facebook"}

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        build_conn(:post, "/callback/facebook", params)
        |> Facebook.callback()

        refute called FacebookApi.send_message(:_, :_, :_)
      end
    end

    test "pull profile information", %{bot: bot} do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn = build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        recipient_id = Session.encrypt_id("1234", bot.id)

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert Session.get_value(session, "first_name") == "John"
        assert Session.get_value(session, "last_name") == "Doe"
        assert Session.get_value(session, "gender") == "male"

        {:ok, pull_ts, 0} = Session.get_value(session, ".facebook_profile_ts") |> DateTime.from_iso8601
        assert DateTime.diff(DateTime.utc_now, pull_ts, :second) < 5
      end
    end

    test "profile is not pull if it was already pulled within the last 24hs", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
          |> Session.put(".facebook_profile_ts", DateTime.utc_now |> DateTime.to_iso8601)
          |> Session.save

        build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert Session.get_value(session, "first_name") == nil
        assert Session.get_value(session, "last_name") == nil
        assert Session.get_value(session, "gender") == nil
      end
    end

    test "profile is pulled again when the last pull was more than a day ago", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
          |> Session.put("first_name", "---")
          |> Session.put(".facebook_profile_ts", DateTime.utc_now |> Timex.add(Timex.Duration.from_hours(-25)) |> DateTime.to_iso8601)
          |> Session.save

        build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert Session.get_value(session, "first_name") == "John"
        assert Session.get_value(session, "last_name") == "Doe"
        assert Session.get_value(session, "gender") == "male"
      end
    end
  end

  describe "encrypt" do
    setup :create_encrypted_bot

    test "encrypt pulled profile information if the bot has public keys", %{bot: bot, private: private} do
      recipient_id = Session.encrypt_id("1234", bot.id)
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        build_conn(:post, "/callback/facebook", @incoming_message)
        |> Facebook.callback()

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert "John" == Session.get_value(session, "first_name")
        assert "Doe" == Session.get_value(session, "last_name") |> Crypto.decrypt(private) |> Poison.decode!
        assert "male" == Session.get_value(session, "gender")

        {:ok, pull_ts, 0} = Session.get_value(session, ".facebook_profile_ts") |> DateTime.from_iso8601
        assert DateTime.diff(DateTime.utc_now, pull_ts, :second) < 5
      end
    end
  end

  defp create_encrypted_bot(_context) do
    manifest = File.read!("test/fixtures/valid_manifest_single_lang.json") |> Poison.decode!()
    {private, public} = Kcl.generate_key_pair()
    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(db_bot.id, manifest)
    bot = %{bot | public_keys: [public]}
    BotManager.start(bot)

    [bot: bot, private: private]
  end

  defp assert_message_sent(message) do
    api = FacebookApi.new("QWERTYUIOPASDFGHJKLZXCVBNM")
    assert called FacebookApi.send_message(api, "1234", message)
  end

  def send_message_mock(_api, _recipient, _message), do: :ok
  def get_profile_mock(_api, _psid), do: %{"first_name" => "John", "last_name" => "Doe", "gender" => "male"}
end
