defmodule AidaWeb.ErrorLogControllerTest do
  use AidaWeb.ConnCase
  alias Aida.{
    BotParser,
    DB,
    DB.Session,
    ErrorLog,
    JsonSchema,
    Repo,
  }
  require Aida.ErrorLog

  setup :create_bot
  setup :create_session

  setup %{conn: conn} do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "list error logs", %{conn: conn, bot: bot, session: session} do
      skill_id = "c9ef260b-a746-4986-b11d-07f37dbd0210"

      ErrorLog.context bot_id: bot.id do
        ErrorLog.context session_id: session.id, skill_id: skill_id do
          ErrorLog.write("Some error")
        end
      end

      assert [error_log] = ErrorLog |> Repo.all()
      assert error_log.bot_id == bot.id
      assert error_log.session_id == session.id
      assert error_log.skill_id == skill_id
      assert error_log.message == "Some error"

      conn = get conn, bot_error_log_path(conn, :index, bot.id)

      response = json_response(conn, 200)["data"]
      assert response |> Enum.count == 1

      assert (response |> hd)["session_id"] == session.id
      assert (response |> hd)["message"] == "Some error"
    end
  end

  defp create_bot(_context) do
    manifest = File.read!("test/fixtures/valid_manifest.json")
                |> Poison.decode!
    {:ok, bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(bot.id, manifest)

    [bot: bot]
  end

  defp create_session(%{bot: bot}) do
    session = Session.new({bot.id, "facebook", "1234/5678"})
      |> Session.save

    [session: session]
  end
end
