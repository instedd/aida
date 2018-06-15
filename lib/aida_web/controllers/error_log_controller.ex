defmodule AidaWeb.ErrorLogController do
  use AidaWeb, :controller
  alias Aida.{ErrorLog}

  def index(conn, %{"bot_id" => bot_id}) do
    error_logs = ErrorLog.by_bot(bot_id)
    render(conn, "index.json", error_logs: error_logs)
  end
end
