defmodule AidaWeb.SessionController do
  use AidaWeb, :controller
  alias Aida.{DB, Message, BotManager, Bot}
  alias Aida.DB.{Session, MessageLog}

  def index(conn, %{"bot_id" => bot_id}) do
    sessions = MessageLog.session_index_by_bot(bot_id)
    render(conn, "index.json", sessions: sessions)
  end

  def session_data(conn, %{"bot_id" => bot_id, "include_internal" => "true"}) do
    sessions = Session.sessions_by_bot(bot_id)
    render(conn, "session_data_full.json", sessions: sessions)
  end

  def session_data(conn, %{"bot_id" => bot_id, "period" => period}) do
    sessions = Session.sessions_by_bot(bot_id, period)
    render(conn, "session_data_assets.json", sessions: sessions)
  end

  def session_data(conn, %{"bot_id" => bot_id}) do
    sessions = Session.sessions_by_bot(bot_id)
    render(conn, "session_data.json", sessions: sessions)
  end

  def log(conn, %{"session_id" => session_id}) do
    logs = MessageLog.message_logs_by_session(session_id)
    render(conn, "logs.json", logs: logs)
  end

  def send_message(conn, %{"session_id" => session_id, "message" => message}) do
    session = Session.get(session_id)
    bot = BotManager.find(session.bot_id)
    message = Message.new(message, bot, session)
    Bot.send_message(message)
    conn |> send_resp(200, "")
  end

  def attachment(conn, %{"bot_id" => bot_id, "session_id" => session_id, "file" => file}) do
    if (String.starts_with? file.content_type, "image/") do
      {:ok, binary} = File.read(file.path)
      image_attrs = %{
        binary: binary,
        binary_type: file.content_type,
        bot_id: bot_id,
        session_id: session_id
      }
      {:ok, image} = DB.create_image(image_attrs)
      render(conn, "attachment.json", attachment_id: image.uuid)
    else
      conn |> put_status(415) |> json(%{errors: "Unsupported Media Type"}) |> halt
    end
  end
end
