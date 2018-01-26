defmodule AidaWeb.SessionController do
  use AidaWeb, :controller
  alias Aida.{DB, DB.Session, ChannelProvider, Channel}

  def index(conn, %{"bot_id" => bot_id}) do
    sessions = Session.session_index_by_bot(bot_id)
    render(conn, "index.json", sessions: sessions)
  end

  def session_data(conn, %{"bot_id" => bot_id}) do
    sessions = DB.sessions_by_bot(bot_id)
    render(conn, "session_data.json", sessions: sessions)
  end

  def log(conn, %{"session_id" => session_uuid}) do
    logs = Session.message_logs_by_session(session_uuid)
    render(conn, "logs.json", logs: logs)
  end

  def send_message(conn, %{"session_id" => session_uuid, "message" => message}) do
    session_id = DB.get_session_by_uuid(session_uuid).id

    ChannelProvider.find_channel(session_id)
    |> Channel.send_message([message], session_id)

    conn |> send_resp(200, "")
  end
end
