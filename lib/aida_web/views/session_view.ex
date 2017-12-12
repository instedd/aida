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
end
