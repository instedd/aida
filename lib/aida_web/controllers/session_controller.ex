defmodule AidaWeb.SessionController do
  use AidaWeb, :controller
  alias Aida.DB

  def session_data(conn, %{"bot_id" => bot_id}) do
    sessions = DB.sessions_by_bot(bot_id)

    render(conn, "session_data.json", sessions: sessions)
  end
end
