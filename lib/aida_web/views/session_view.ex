defmodule AidaWeb.SessionView do
  use AidaWeb, :view
  alias __MODULE__

  def render("session_data.json", %{sessions: sessions}) do
    %{data: render_many(sessions, SessionView, "session.json")}
  end

  def render("session.json", %{session: session}) do
    %{
      id: session.id,
      data: session.data
    }
  end

  def render("index.json", %{sessions: sessions}) do
    %{data: render_many(sessions, SessionView, "session_index.json")}
  end

  def render("session_index.json", %{session: session}) do
    %{
      id: session.id,
      first_message: session.first_message,
      last_message: session.last_message
    }
  end

  def render("logs.json", %{logs: logs}) do
    %{
      data: render_many(logs, SessionView, "log.json", as: :log)
    }
  end

  def render("log.json", %{log: log}) do
    %{
      timestamp: log.timestamp,
      direction: log.direction,
      content: log.content
    }
  end

end
