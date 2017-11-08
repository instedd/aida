defmodule AidaWeb.BotController do
  use AidaWeb, :controller

  alias Aida.DB
  alias Aida.DB.Bot

  action_fallback AidaWeb.FallbackController

  def index(conn, _params) do
    bots = DB.list_bots()
    render(conn, "index.json", bots: bots)
  end

  def create(conn, %{"bot" => bot_params}) do
    with {:ok, %Bot{} = bot} <- DB.create_bot(bot_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", bot_path(conn, :show, bot))
      |> render("show.json", bot: bot)
    end
  end

  def show(conn, %{"id" => id}) do
    bot = DB.get_bot!(id)
    render(conn, "show.json", bot: bot)
  end

  def update(conn, %{"id" => id, "bot" => bot_params}) do
    bot = DB.get_bot!(id)

    with {:ok, %Bot{} = bot} <- DB.update_bot(bot, bot_params) do
      render(conn, "show.json", bot: bot)
    end
  end

  def delete(conn, %{"id" => id}) do
    bot = DB.get_bot!(id)
    with {:ok, %Bot{}} <- DB.delete_bot(bot) do
      send_resp(conn, :no_content, "")
    end
  end
end
