defmodule AidaWeb.ErrorLogView do
  use AidaWeb, :view
  alias __MODULE__

  def render("index.json", %{error_logs: error_logs}) do
    %{
      data: render_many(error_logs, ErrorLogView, "error_log.json", as: :error_log)
    }
  end

  def render("error_log.json", %{error_log: error_log}) do
    %{
      timestamp: error_log.inserted_at,
      bot_id: error_log.bot_id,
      session_id: error_log.session_id,
      skill_id: error_log.skill_id,
      message: error_log.message
    }
  end
end
