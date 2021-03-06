defmodule Aida.Channel.FacebookConnTest do
  use Aida.DataCase
  use Phoenix.ConnTest
  import Mock

  alias Aida.{
    ChannelRegistry,
    Crypto,
    BotManager,
    BotParser,
    DB,
    DB.Session,
    ErrorLog,
    ErrorHandler
  }

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

  @incoming_hash_but_not_system_message %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "message" => %{
              "mid" => "mid.$cAAaHH1ei9DNl7dw2H1fvJcC5-hi5",
              "seq" => 493,
              "text" => "##FOO"
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

  @incoming_policy_enforcement_reason "The bot violated our Platform Policies (https://developers.facebook.com/policy/#messengerplatform). Common violations include sending out excessive spammy messages or being non-functional."
  @incoming_policy_enforcement %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "policy-enforcement" => %{
              "action" => "block",
              "reason" => @incoming_policy_enforcement_reason
            },
            "recipient" => %{"id" => "1234567890"},
            "timestamp" => 1_510_697_528_863
          }
        ],
        "time" => 1_510_697_858_540
      }
    ],
    "object" => "page",
    "provider" => "facebook"
  }

  @incoming_policy_enforcement_released %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "policy-enforcement" => %{
              "action" => "unblock"
            },
            "recipient" => %{"id" => "1234567890"},
            "timestamp" => 1_510_697_528_863
          }
        ],
        "time" => 1_510_697_858_540
      }
    ],
    "object" => "page",
    "provider" => "facebook"
  }

  @incoming_unknown_policy_enforcement_data %{
    "action" => "unknown-action",
    "unknown-key" => "unknown key value"
  }
  @incoming_unknown_policy_enforcement %{
    "entry" => [
      %{
        "id" => "1234567890",
        "messaging" => [
          %{
            "policy-enforcement" => @incoming_unknown_policy_enforcement_data,
            "recipient" => %{"id" => "1234567890"},
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
    ChannelRegistry.start_link()
    BotManager.start_link()
    :ok
  end

  describe "with bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json") |> Poison.decode!()

      {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(db_bot.id, manifest)
      BotManager.start(bot)
      [bot: bot]
    end

    test "incoming facebook challenge" do
      challenge = Ecto.UUID.generate()

      params = %{
        "hub.challenge" => challenge,
        "hub.mode" => "subscribe",
        "hub.verify_token" => "qwertyuiopasdfghjklzxcvbnm",
        "provider" => "facebook"
      }

      conn =
        build_conn(:get, "/callback/facebook", params)
        |> Facebook.callback()

      assert response(conn, 200) == challenge
    end

    test "incoming facebook message" do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        assert_message_sent("Hello, I'm a Restaurant bot")
        assert_message_sent("I can do a number of things")
        assert_message_sent("I can give you information about our menu")
        assert_message_sent("I can give you information about our opening hours")
      end
    end

    test "incoming facebook message targets specific bot", %{bot: bot} do
      another_manifest =
        File.read!("test/fixtures/valid_manifest_single_lang_same_page_id.json")
        |> Poison.decode!()

      {:ok, another_db_bot} = DB.create_bot(%{manifest: another_manifest})
      {:ok, another_bot} = BotParser.parse(another_db_bot.id, another_manifest)
      [another_bot: another_bot]

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        assert_message_sent("Hello, I'm not a Restaurant bot")
        assert_message_sent("I can do a number of different things")
      end

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback(bot.id)

        assert response(conn, 200) == "ok"

        assert_message_sent("Hello, I'm a Restaurant bot")
        assert_message_sent("I can do a number of things")
      end
    end

    test "incoming system session id message", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_session_id_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert_message_sent(String.slice(session.id, -7..-1))
      end
    end

    test "incoming system reset message", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_reset_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        assert_message_sent("Session was reset")
      end
    end

    test "incoming non system trick message", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_hash_but_not_system_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        assert_message_sent("Hello, I'm a Restaurant bot")
        assert_message_sent("I can do a number of things")
        assert_message_sent("I can give you information about our menu")
        assert_message_sent("I can give you information about our opening hours")
      end
    end

    test "doesn't send message when receiving a 'read' event" do
      params = %{
        "entry" => [
          %{
            "id" => "1234567890",
            "messaging" => [
              %{
                "read" => %{"seq" => 0, "watermark" => "12345"},
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

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        build_conn(:post, "/callback/facebook", params)
        |> Facebook.callback()

        refute called(FacebookApi.send_message(:_, :_, :_))
      end
    end

    test "doesn't send message when receiving a 'delivery' event" do
      params = %{
        "entry" => [
          %{
            "id" => "1234567890",
            "messaging" => [
              %{
                "delivery" => %{
                  "mids" => ["mid.$cAAFhHf1znQRnXHiKMlhKzNB8Zr8v"],
                  "seq" => 0,
                  "watermark" => "12345"
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

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        build_conn(:post, "/callback/facebook", params)
        |> Facebook.callback()

        refute called(FacebookApi.send_message(:_, :_, :_))
      end
    end

    test "pull profile information", %{bot: bot} do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        conn =
          build_conn(:post, "/callback/facebook", @incoming_message)
          |> Facebook.callback()

        assert response(conn, 200) == "ok"

        recipient_id = Session.encrypt_id("1234", bot.id)

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert Session.get_value(session, "first_name") == "John"
        assert Session.get_value(session, "last_name") == "Doe"
        assert Session.get_value(session, "gender") == "male"

        {:ok, pull_ts, 0} =
          Session.get_value(session, ".facebook_profile_ts") |> DateTime.from_iso8601()

        assert DateTime.diff(DateTime.utc_now(), pull_ts, :second) < 5
      end
    end

    test "profile is not pull if it was already pulled within the last 24hs", %{bot: bot} do
      recipient_id = Session.encrypt_id("1234", bot.id)

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        |> Session.put(".facebook_profile_ts", DateTime.utc_now() |> DateTime.to_iso8601())
        |> Session.save()

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
        |> Session.put(
          ".facebook_profile_ts",
          DateTime.utc_now() |> Timex.add(Timex.Duration.from_hours(-25)) |> DateTime.to_iso8601()
        )
        |> Session.save()

        build_conn(:post, "/callback/facebook", @incoming_message)
        |> Facebook.callback()

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert Session.get_value(session, "first_name") == "John"
        assert Session.get_value(session, "last_name") == "Doe"
        assert Session.get_value(session, "gender") == "male"
      end
    end

    @ok_httpoison_response {:ok, %HTTPoison.Response{status_code: 200}}

    test "logs policy enforcements blocks as errors", %{bot: bot} do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        with_mock HTTPoison, post: fn _url, _body -> @ok_httpoison_response end do
          conn =
            build_conn(:post, "/callback/facebook", @incoming_policy_enforcement)
            |> Facebook.callback()

          assert response(conn, 200) == "ok"

          %{message: message} = ErrorLog |> Repo.one()

          assert message ==
                   "Policy Enforcement Notification - Bot has been blocked.\n\n#{
                     @incoming_policy_enforcement_reason
                   }"

          assert called(
                   HTTPoison.post(
                     "https://example.com/some/notification/endpoint",
                     %{
                       type: :policy_enforcement,
                       data: %{
                         "action" => "block",
                         "reason" => @incoming_policy_enforcement_reason
                       }
                     }
                     |> Poison.encode!()
                   )
                 )
        end
      end
    end

    test "doesn't log policy enforcement unblocks", %{bot: bot} do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        with_mock HTTPoison, post: fn _url, _body -> @ok_httpoison_response end do
          conn =
            build_conn(:post, "/callback/facebook", @incoming_policy_enforcement_released)
            |> Facebook.callback()

          assert response(conn, 200) == "ok"

          assert 0 == ErrorLog |> Repo.count()

          assert called(
                   HTTPoison.post(
                     "https://example.com/some/notification/endpoint",
                     %{type: :policy_enforcement, data: %{"action" => "unblock"}}
                     |> Poison.encode!()
                   )
                 )
        end
      end
    end

    test "logs policy enforcements as errors by default", %{bot: bot} do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        with_mock HTTPoison, post: fn _url, _body -> @ok_httpoison_response end do
          conn =
            build_conn(:post, "/callback/facebook", @incoming_unknown_policy_enforcement)
            |> Facebook.callback()

          assert response(conn, 200) == "ok"

          %{message: message} = ErrorLog |> Repo.one()

          assert message ==
                   "Policy Enforcement Notification - Unknown action: unknown-action.\n\n#{
                     Poison.encode!(@incoming_unknown_policy_enforcement_data)
                   }"

          assert called(
                   HTTPoison.post(
                     "https://example.com/some/notification/endpoint",
                     %{type: :policy_enforcement, data: @incoming_unknown_policy_enforcement_data}
                     |> Poison.encode!()
                   )
                 )
        end
      end
    end

    test "logs notification delivery error when endpoint is not available", %{bot: bot} do
      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        with_mock HTTPoison,
          post: fn _url, _body -> {:ok, %HTTPoison.Response{status_code: 404}} end do
          with_mock ErrorHandler, capture_message: fn _message, _extra -> :ok end do
            conn =
              build_conn(:post, "/callback/facebook", @incoming_policy_enforcement_released)
              |> Facebook.callback()

            assert response(conn, 200) == "ok"

            assert 0 == ErrorLog |> Repo.count()

            assert called(
                     HTTPoison.post(
                       "https://example.com/some/notification/endpoint",
                       %{type: :policy_enforcement, data: %{"action" => "unblock"}}
                       |> Poison.encode!()
                     )
                   )

            assert called(
                     ErrorHandler.capture_message(
                       "Error posting notification to remote endpoint",
                       %{
                         notifications_url: "https://example.com/some/notification/endpoint",
                         notification_type: :policy_enforcement
                       }
                     )
                   )
          end
        end
      end
    end
  end

  describe "encrypt" do
    setup :create_encrypted_bot

    test "encrypt pulled profile information if the bot has public keys", %{
      bot: bot,
      private: private
    } do
      recipient_id = Session.encrypt_id("1234", bot.id)

      with_mock FacebookApi, [:passthrough], @fb_api_mock do
        build_conn(:post, "/callback/facebook", @incoming_message)
        |> Facebook.callback()

        session = Session.find_or_create(bot.id, "facebook", "1234567890/#{recipient_id}")
        assert "John" == Session.get_value(session, "first_name")

        assert "Doe" ==
                 Session.get_value(session, "last_name")
                 |> Crypto.decrypt(private)
                 |> Poison.decode!()

        assert "male" == Session.get_value(session, "gender")

        {:ok, pull_ts, 0} =
          Session.get_value(session, ".facebook_profile_ts") |> DateTime.from_iso8601()

        assert DateTime.diff(DateTime.utc_now(), pull_ts, :second) < 5
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
    assert called(FacebookApi.send_message(api, "1234", message))
  end

  def send_message_mock(_api, _recipient, _message), do: :ok

  def get_profile_mock(_api, _psid),
    do: %{"first_name" => "John", "last_name" => "Doe", "gender" => "male"}
end
