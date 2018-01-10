defmodule AidaWeb.SessionController do
  use AidaWeb, :controller
  alias Aida.DB
  alias Aida.DB.Session

  def index(conn, %{"bot_id" => bot_id}) do
    sessions = Session.session_index_by_bot(bot_id)
    render(conn, "index.json", sessions: sessions)
  end

  def session_data(conn, %{"bot_id" => bot_id}) do
    sessions = DB.sessions_by_bot(bot_id)
    render(conn, "session_data.json", sessions: sessions)
  end

  def log(conn, %{"session_id" => session_id}) do
    logs = Session.message_logs_by_session(session_id)
    render(conn, "logs.json", logs: logs)
  end

end
