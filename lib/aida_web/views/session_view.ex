defmodule AidaWeb.SessionView do
  use AidaWeb, :view
  alias __MODULE__

  def render("session_data.json", %{sessions: sessions}) do
    %{data: render_many(sessions, SessionView, "session.json")}
  end

  def render("session.json", %{session: session}) do
    %{
      id: session.id,
      data: session.data |> hide_internal_data()
    }
  end

  def render("session_data_full.json", %{sessions: sessions}) do
    %{data: render_many(sessions, SessionView, "session_full.json")}
  end

  def render("session_full.json", %{session: session}) do
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
      content: log.content,
      content_type: log.content_type
    }
  end

  def render("attachment.json", %{attachment_id: attachment_id}), do: %{id: attachment_id}

  defp hide_internal_data(data) do
    internal_keys =
      data
      |> Map.keys()
      |> Enum.filter(&String.starts_with?(&1, "."))

    data |> Map.drop(internal_keys)
  end
end
