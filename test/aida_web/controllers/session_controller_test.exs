defmodule AidaWeb.SessionControllerTest do
  use AidaWeb.ConnCase

  alias Aida.{
    Asset,
    BotParser,
    ChannelProvider,
    DB,
    DB.MessageLog,
    DB.Session,
    JsonSchema,
    Repo,
    BotManager,
    TestChannel
  }

  import Mock

  setup :create_bot
  setup :create_session

  setup %{conn: conn} do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref())
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "list sessions", %{conn: conn, bot: bot, session: session} do
      first_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "outgoing",
        content: "Hello, I'm a Restaurant bot",
        content_type: "text",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "incoming",
        content: "menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      conn = get(conn, bot_session_path(conn, :index, bot.id))

      response = json_response(conn, 200)["data"]
      assert response |> Enum.count() == 1
      assert (response |> hd)["id"] == session.id

      assert Ecto.DateTime.cast!((response |> hd)["first_message"]) ==
               Ecto.DateTime.cast!("2018-01-08T16:00:00")

      assert Ecto.DateTime.cast!((response |> hd)["last_message"]) ==
               Ecto.DateTime.cast!("2018-01-08T16:30:00")
    end

    test "considers only incoming messages to calculate first and last messages", %{
      conn: conn,
      bot: bot,
      session: session
    } do
      first_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "outgoing",
        content: "Hello, I can give you information about the menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:01:00",
        updated_at: "2018-01-08T16:01:00"
      }

      third_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "incoming",
        content: "menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:02:00",
        updated_at: "2018-01-08T16:02:00"
      }

      fourth_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "outgoing",
        content: "we have barbecue and pasta and a exclusive selection of wines",
        content_type: "text",
        inserted_at: "2018-01-08T16:03:00",
        updated_at: "2018-01-08T16:03:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)
      create_message_log(fourth_message_attrs)

      conn = get(conn, bot_session_path(conn, :index, bot.id))

      response = json_response(conn, 200)["data"]

      assert Ecto.DateTime.cast!((response |> hd)["first_message"]) ==
               Ecto.DateTime.cast!("2018-01-08T16:00:00")

      assert Ecto.DateTime.cast!((response |> hd)["last_message"]) ==
               Ecto.DateTime.cast!("2018-01-08T16:02:00")
    end

    test "retrieves empty message dates when session has no messages", %{conn: conn, bot: bot} do
      conn = get(conn, bot_session_path(conn, :index, bot.id))

      assert json_response(conn, 200)["data"] == []
    end

    test "doesn't get sessions of other bot", %{
      conn: conn,
      bot: first_bot,
      session: first_session
    } do
      first_message_attrs = %{
        bot_id: first_bot.id,
        session_id: first_session.id,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: first_bot.id,
        session_id: first_session.id,
        direction: "outgoing",
        content: "Hello, I'm a Restaurant bot",
        content_type: "text",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: first_bot.id,
        session_id: first_session.id,
        direction: "incoming",
        content: "menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      [bot: second_bot] = create_bot()
      Session.new({second_bot.id, "facebook", "1234567890/1234"}) |> Session.save()

      conn = get(conn, bot_session_path(conn, :index, second_bot.id))
      response = json_response(conn, 200)["data"]

      assert response == []
    end
  end

  describe "session_data" do
    test "lists sessions data", %{conn: conn, bot: bot, session: session} do
      data = %{"foo" => 1, "bar" => 2}
      session |> Session.merge(data) |> Session.save()

      conn = get(conn, bot_session_path(conn, :session_data, bot.id))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => session.id,
                 "data" => data
               }
             ]
    end

    test "do not include variables starting with dot", %{conn: conn, bot: bot, session: session} do
      data = %{"foo" => 1, "bar" => 2, ".internal" => %{"state" => 1}}
      session = session |> Session.merge(data) |> Session.save()

      conn = get(conn, bot_session_path(conn, :session_data, bot.id))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => session.id,
                 "data" => Map.delete(data, ".internal")
               }
             ]
    end

    test "include variables starting with dot if requested", %{
      conn: conn,
      bot: bot,
      session: session
    } do
      data = %{"foo" => 1, "bar" => 2, ".internal" => %{"state" => 1}}
      session = session |> Session.merge(data) |> Session.save()

      conn = get(conn, bot_session_path(conn, :session_data, bot.id, include_internal: true))

      assert json_response(conn, 200)["data"] == [
               %{
                 "id" => session.id,
                 "data" => data
               }
             ]
    end

    test "include assets for a requested period", %{
      conn: conn,
      bot: bot,
      session: %{id: session_id} = session
    } do
      data = %{"foo" => 1, "bar" => 2, ".internal" => %{"state" => 1}}
      result_data = Map.delete(data, ".internal")

      asset_data = %{
        "survey/food_preferences/request" => "No, thanks!",
        "survey/food_preferences/wine_grapes" => ["merlot", "syrah"]
      }

      session = session |> Session.merge(data) |> Session.save()

      {:ok, _} =
        Asset.create(%{
          skill_id: "food_preferences",
          session_id: session.id,
          data: asset_data
        })

      conn = get(conn, bot_session_path(conn, :session_data, bot.id, period: "this_week"))
      [response] = json_response(conn, 200)["data"]

      assert %{
               "id" => ^session_id,
               "data" => ^result_data,
               "assets" => [
                 %{
                   "skill_id" => "food_preferences",
                   "data" => ^asset_data,
                   "timestamp" => ts
                 }
               ]
             } = response

      with {:ok, ts} <- NaiveDateTime.from_iso8601(ts),
           {:ok, ts} <- DateTime.from_naive(ts, "Etc/UTC") do
        assert_in_delta DateTime.diff(ts, DateTime.utc_now()), 0, 5
      end
    end
  end

  describe "log" do
    test "list all messages of a session", %{conn: conn, bot: bot, session: session} do
      first_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "outgoing",
        content: "Hello, I'm a Restaurant bot",
        content_type: "text",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: bot.id,
        session_id: session.id,
        direction: "incoming",
        content: "menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      conn = get(conn, bot_session_session_path(conn, :log, bot.id, session.id))
      response = json_response(conn, 200)["data"]
      assert response |> Enum.count() == 3
      assert response |> Enum.any?(&is_equal?(&1, first_message_attrs))
      assert response |> Enum.any?(&is_equal?(&1, second_message_attrs))
      assert response |> Enum.any?(&is_equal?(&1, third_message_attrs))
    end
  end

  describe "send_message" do
    setup do
      channel = TestChannel.new()

      [channel: channel]
    end

    test "sends message to a session", %{conn: conn, bot: bot, channel: channel, session: session} do
      with_mock ChannelProvider, find_channel: fn _ -> channel end do
        session_id = session.id

        with_mock BotManager, find: fn _id -> bot end do
          post(
            conn,
            bot_session_session_path(conn, :send_message, bot.id, session_id, message: "Hi!")
          )

          assert called(BotManager.find(bot.id))
        end

        assert_received {:send_message, ["Hi!"], ^session_id}
      end
    end
  end

  describe "attachment" do
    test "sends an image to a session", %{conn: conn, bot: bot, session: session} do
      upload = %Plug.Upload{
        content_type: "image/png",
        path: "test/fixtures/file_upload_test.png",
        filename: "file_upload_test.png"
      }

      path = bot_session_session_path(conn, :attachment, bot.id, session.id)
      conn = conn |> post(path, %{:file => upload})

      %{"id" => attachment_id} = json_response(conn, 200)

      assert DB.get_image(attachment_id)
      {:ok, binary} = File.read("test/fixtures/file_upload_test.png")
      assert DB.get_image(attachment_id).binary == binary
      assert DB.get_image(attachment_id).bot_id == bot.id
      assert DB.get_image(attachment_id).session_id == session.id
      assert DB.get_image(attachment_id).binary_type == "image/png"
      assert DB.get_image(attachment_id).source_url == nil
    end

    test "does not send other file types to a session", %{conn: conn, bot: bot, session: session} do
      upload = %Plug.Upload{
        content_type: "text/plain",
        path: "test/fixtures/file_upload_test.txt",
        filename: "test_file_upload.txt"
      }

      path = bot_session_session_path(conn, :attachment, bot.id, session.id)

      conn = conn |> post(path, %{:file => upload})

      %{"errors" => errors} = json_response(conn, 415)
      assert errors == "Unsupported Media Type"
    end
  end

  defp create_bot(_context \\ nil) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json")
      |> Poison.decode!()

    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(bot.id, manifest)

    [bot: bot]
  end

  defp create_session(%{bot: bot}) do
    session =
      Session.new({bot.id, "facebook", "1234/5678"})
      |> Session.save()

    [session: session]
  end

  # This function is used instead of MessageLog.create in order to
  # set inserted_at, updated_at properties
  defp create_message_log(attrs) do
    %MessageLog{}
    |> Ecto.Changeset.cast(attrs, [
      :bot_id,
      :session_id,
      :direction,
      :content,
      :content_type,
      :inserted_at,
      :updated_at
    ])
    |> Repo.insert()
  end

  defp is_equal?(log_message, attrs) do
    Ecto.DateTime.cast!(log_message["timestamp"]) == Ecto.DateTime.cast!(attrs.inserted_at) &&
      log_message["direction"] == attrs.direction && log_message["content"] == attrs.content &&
      log_message["content_type"] == attrs.content_type
  end
end
