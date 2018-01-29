defmodule AidaWeb.SessionControllerTest do
  use AidaWeb.ConnCase
  alias Aida.{BotParser, Session, SessionStore, DB, Repo, TestChannel, ChannelProvider}
  alias Aida.DB.{MessageLog}
  alias Aida.JsonSchema
  import Mock

  @uuid "2866807a-49af-454a-bf12-9d1d8e6a3827"
  @uuid2 "e7434880-07f8-4e53-8ad4-06fad2b1c3fc"

  setup :create_bot

  setup %{conn: conn} do
    SessionStore.start_link

    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "list sessions", %{conn: conn, bot: bot} do
      session_id = "#{bot.id}/facebook/1234567890/1234"
      {session_id, @uuid, %{"foo" => 1, "bar" => 2}}
        |> Session.new
        |> Session.save

      first_message_attrs = %{
        bot_id: bot.id,
        session_id: session_id,
        session_uuid: @uuid,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot.id,
        session_id: session_id,
        session_uuid: @uuid,
        direction: "outgoing",
        content: "Hello, I'm a Restaurant bot",
        content_type: "text",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: bot.id,
        session_id: session_id,
        session_uuid: @uuid,
        direction: "incoming",
        content: "menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      conn = get conn, bot_session_path(conn, :index, bot.id)

      response = json_response(conn, 200)["data"]
      assert response |> Enum.count == 1
      assert (response |> hd)["id"] == @uuid
      assert Ecto.DateTime.cast!((response |> hd)["first_message"]) == Ecto.DateTime.cast!("2018-01-08T16:00:00")
      assert Ecto.DateTime.cast!((response |> hd)["last_message"]) == Ecto.DateTime.cast!("2018-01-08T16:30:00")
    end

    test "retrieves empty message dates when session has no messages", %{conn: conn, bot: bot} do
      session_id = "#{bot.id}/facebook/1234567890/1234"
      {session_id, @uuid, %{"foo" => 1, "bar" => 2}}
        |> Session.new
        |> Session.save

      conn = get conn, bot_session_path(conn, :index, bot.id)

      assert json_response(conn, 200)["data"] == []
    end

    test "doesn't get sessions of other bot", %{conn: conn, bot: first_bot} do
      first_session_id = "#{first_bot.id}/facebook/1234567890/1234"
      {first_session_id, @uuid, %{"foo" => 1, "bar" => 2}}
        |> Session.new
        |> Session.save


      first_message_attrs = %{
        bot_id: first_bot.id,
        session_id: first_session_id,
        session_uuid: @uuid,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: first_bot.id,
        session_id: first_session_id,
        session_uuid: @uuid,
        direction: "outgoing",
        content: "Hello, I'm a Restaurant bot",
        content_type: "text",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: first_bot.id,
        session_id: first_session_id,
        session_uuid: @uuid,
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
      second_session_id = "#{second_bot.id}/facebook/1234567890/1234"
      SessionStore.save(second_session_id, @uuid2, %{"foo" => 1, "bar" => 2})

      conn = get conn, bot_session_path(conn, :index, second_bot.id)
      response = json_response(conn, 200)["data"]

      assert response == []
    end
  end

  describe "session_data" do
    test "lists sessions data", %{conn: conn, bot: bot}  do
      data = %{"foo" => 1, "bar" => 2}
      {"#{bot.id}/facebook/1234567890/1234", @uuid, data}
        |> Session.new
        |> Session.save

      conn = get conn, bot_session_path(conn, :session_data, bot.id)
      assert json_response(conn, 200)["data"] == [
        %{
          "id" => @uuid,
          "data" => data
        }
      ]
    end
  end

  describe "log" do
    test "list all messages of a session", %{conn: conn, bot: bot} do
      session_id = "#{bot.id}/facebook/1234567890/1234"
      {session_id, @uuid, %{"foo" => 1, "bar" => 2}}
        |> Session.new
        |> Session.save


      first_message_attrs = %{
        bot_id: bot.id,
        session_id: session_id,
        session_uuid: @uuid,
        direction: "incoming",
        content: "Hi!",
        content_type: "text",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot.id,
        session_id: session_id,
        session_uuid: @uuid,
        direction: "outgoing",
        content: "Hello, I'm a Restaurant bot",
        content_type: "text",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: bot.id,
        session_id: session_id,
        session_uuid: @uuid,
        direction: "incoming",
        content: "menu",
        content_type: "text",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      conn = get conn, bot_session_session_path(conn, :log, bot.id, @uuid)
      response = json_response(conn, 200)["data"]
      assert response |> Enum.count == 3
      assert response |> Enum.any?(&(is_equal?(&1, first_message_attrs)))
      assert response |> Enum.any?(&(is_equal?(&1, second_message_attrs)))
      assert response |> Enum.any?(&(is_equal?(&1, third_message_attrs)))
    end
  end

  describe "send_message" do
    setup do
      channel = TestChannel.new()

      [channel: channel]
    end

    test "sends message to a session", %{conn: conn, bot: bot, channel: channel} do
      session = Session.new("session_id", @uuid)
      session |> Session.save

      with_mock ChannelProvider, [find_channel: fn "session_id" -> channel end] do
        post conn, bot_session_session_path(conn, :send_message, bot.id, session.uuid, message: "Hi!")
        assert_received {:send_message, ["Hi!"], "session_id"}
      end
    end
  end

  defp create_bot(_context \\ nil) do
    manifest = File.read!("test/fixtures/valid_manifest.json")
                |> Poison.decode!
    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(bot.id, manifest)

    [bot: bot]
  end

  # This function is used instead of MessageLog.create in order to
  # set created_at, updated_at properties
  defp create_message_log(attrs) do
    %MessageLog{}
    |> Ecto.Changeset.cast(attrs, [:bot_id, :session_id, :session_uuid, :direction, :content, :content_type, :inserted_at, :updated_at])
    |> Repo.insert
  end

  defp is_equal?(log_message, attrs) do
    Ecto.DateTime.cast!(log_message["timestamp"]) == Ecto.DateTime.cast!(attrs.inserted_at) && log_message["direction"] == attrs.direction && log_message["content"] == attrs.content && log_message["content_type"] == attrs.content_type
  end
end
