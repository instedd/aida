defmodule AidaWeb.BotControllerTest do
  use AidaWeb.ConnCase

  alias Aida.DB
  alias Aida.DB.Bot
  alias Aida.JsonSchema

  @valid_localized_string %{"en" => ""}
  @valid_message %{"message" => @valid_localized_string}
  @valid_front_desk %{
    "greeting" => @valid_message,
    "introduction" => @valid_message,
    "not_understood" => @valid_message,
    "clarification" => @valid_message,
    "threshold" => 0.1
  }
  @valid_localized_keywords %{"en" => [""]}
  @valid_keyword_responder %{
    "type" => "keyword_responder",
    "explanation" => @valid_localized_string,
    "clarification" => @valid_localized_string,
    "keywords" => @valid_localized_keywords,
    "response" => @valid_localized_string
  }
  @valid_manifest %{
    "version" => 1,
    "languages" => ["en"],
    "front_desk" => @valid_front_desk,
    "skills" => [@valid_keyword_responder],
    "variables" => [],
    "channels" => []
  }

  @updated_manifest %{
    "version" => 1,
    "languages" => ["es"],
    "front_desk" => @valid_front_desk,
    "skills" => [@valid_keyword_responder],
    "variables" => [],
    "channels" => []
  }

  @create_attrs %{manifest: @valid_manifest}
  @update_attrs %{manifest: @updated_manifest}
  @invalid_attrs %{manifest: nil}

  def fixture(:bot) do
    {:ok, bot} = DB.create_bot(@create_attrs)
    bot
  end

  setup %{conn: conn} do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all bots", %{conn: conn} do
      conn = get conn, bot_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create bot" do
    test "renders bot when data is valid", %{conn: conn} do
      conn = post conn, bot_path(conn, :create), bot: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, bot_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "manifest" => @valid_manifest}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, bot_path(conn, :create), bot: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update bot" do
    setup [:create_bot]

    test "renders bot when data is valid", %{conn: conn, bot: %Bot{id: id} = bot} do
      conn = put conn, bot_path(conn, :update, bot), bot: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, bot_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "manifest" => @updated_manifest}
    end

    test "renders errors when data is invalid", %{conn: conn, bot: bot} do
      conn = put conn, bot_path(conn, :update, bot), bot: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete bot" do
    setup [:create_bot]

    test "deletes chosen bot", %{conn: conn, bot: bot} do
      conn = delete conn, bot_path(conn, :delete, bot)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, bot_path(conn, :show, bot)
      end
    end
  end

  defp create_bot(_) do
    bot = fixture(:bot)
    {:ok, bot: bot}
  end
end
