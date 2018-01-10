defmodule AidaWeb.SessionControllerTest do
  use AidaWeb.ConnCase
  import AidaWeb.Router.Helpers
  alias Aida.{BotParser, SessionStore, DB, Repo}
  alias Aida.DB.{MessageLog, Bot}
  alias Aida.JsonSchema

  setup %{conn: conn} do
    SessionStore.start_link
    create_bot()

    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "list sessions", %{conn: conn} do
      data = %{"foo" => 1, "bar" => 2}
      bot_id = (Bot |> Repo.one).id
      session_id = "#{bot_id}/facebook/1234567890/1234"
      SessionStore.save(session_id, data) 

      first_message_attrs = %{
        bot_id: bot_id, 
        session_id: session_id, 
        direction: "incoming", 
        content: "Hi!",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot_id, 
        session_id: session_id, 
        direction: "outgoing", 
        content: "Hello, I'm a Restaurant bot",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: bot_id, 
        session_id: session_id, 
        direction: "incoming", 
        content: "menu",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      conn = get conn, bot_session_path(conn, :index, bot_id)

      response = json_response(conn, 200)["data"]
      assert response |> Enum.count == 1
      assert (response |> hd)["id"] == session_id
      assert Ecto.DateTime.cast!((response |> hd)["first_message"]) == Ecto.DateTime.cast!("2018-01-08T16:00:00")
      assert Ecto.DateTime.cast!((response |> hd)["last_message"]) == Ecto.DateTime.cast!("2018-01-08T16:30:00")
    end

    test "retrieves empty message dates when session has no messages", %{conn: conn} do
      data = %{"foo" => 1, "bar" => 2}
      bot_id = (Bot |> Repo.one).id
      session_id = "#{bot_id}/facebook/1234567890/1234"
      SessionStore.save(session_id, data) 

      conn = get conn, bot_session_path(conn, :index, bot_id)

      assert json_response(conn, 200)["data"] == []
    end

    test "doesn't get sessions of other bot", %{conn: conn} do
      data = %{"foo" => 1, "bar" => 2}
      first_bot_id = (Bot |> Repo.one).id
      first_session_id = "#{first_bot_id}/facebook/1234567890/1234"
      SessionStore.save(first_session_id, data) 

      first_message_attrs = %{
        bot_id: first_bot_id, 
        session_id: first_session_id, 
        direction: "incoming", 
        content: "Hi!",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: first_bot_id, 
        session_id: first_session_id, 
        direction: "outgoing", 
        content: "Hello, I'm a Restaurant bot",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: first_bot_id, 
        session_id: first_session_id, 
        direction: "incoming", 
        content: "menu",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      bot_id = create_bot()
      second_session_id = "#{bot_id}/facebook/1234567890/1234"
      SessionStore.save(second_session_id, data) 

      conn = get conn, bot_session_path(conn, :index, bot_id)
      response = json_response(conn, 200)["data"]

      assert response == []
    end
  end

  describe "log" do
    test "list all messages of a session", %{conn: conn} do
      data = %{"foo" => 1, "bar" => 2}
      bot_id = (Bot |> Repo.one).id
      session_id = "#{bot_id}/facebook/1234567890/1234"
      SessionStore.save(session_id, data) 

      first_message_attrs = %{
        bot_id: bot_id, 
        session_id: session_id, 
        direction: "incoming", 
        content: "Hi!",
        inserted_at: "2018-01-08T16:00:00",
        updated_at: "2018-01-08T16:00:00"
      }

      second_message_attrs = %{
        bot_id: bot_id, 
        session_id: session_id, 
        direction: "outgoing", 
        content: "Hello, I'm a Restaurant bot",
        inserted_at: "2018-01-08T16:05:00",
        updated_at: "2018-01-08T16:05:00"
      }

      third_message_attrs = %{
        bot_id: bot_id, 
        session_id: session_id, 
        direction: "incoming", 
        content: "menu",
        inserted_at: "2018-01-08T16:30:00",
        updated_at: "2018-01-08T16:30:00"
      }

      create_message_log(first_message_attrs)
      create_message_log(second_message_attrs)
      create_message_log(third_message_attrs)

      conn = get conn, bot_session_session_path(conn, :log, bot_id, session_id)
      response = json_response(conn, 200)["data"]
      assert response |> Enum.count == 3
      assert response |> Enum.any?(&(is_equal?(&1, first_message_attrs)))
      assert response |> Enum.any?(&(is_equal?(&1, second_message_attrs)))
      assert response |> Enum.any?(&(is_equal?(&1, third_message_attrs)))
    end
  end

  defp create_bot() do
    manifest = File.read!("test/fixtures/valid_manifest.json")
                |> Poison.decode!
    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    BotParser.parse(bot.id, manifest)
    bot.id
  end

  # This function is used instead of MessageLog.create in order to
  # set created_at, updated_at properties
  defp create_message_log(attrs) do
    %MessageLog{}
    |> Ecto.Changeset.cast(attrs, [:bot_id, :session_id, :direction, :content, :inserted_at, :updated_at])
    |> Repo.insert
  end

  defp is_equal?(log_message, attrs) do
    Ecto.DateTime.cast!(log_message["timestamp"]) == Ecto.DateTime.cast!(attrs.inserted_at) && log_message["direction"] == attrs.direction && log_message["content"] == attrs.content
  end

end