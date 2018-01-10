defmodule AidaWeb.SessionController do
  import Ecto.Query
  use AidaWeb, :controller
  alias Aida.Repo
  alias Aida.DB.{Session, MessageLog}

  def index(conn, %{"bot_id" => bot_id}) do
    query = Session 
            |> join(:inner, [s], m in MessageLog, m.session_id == s.id) 
            |> where([s], like(s.id, ^"#{bot_id}/%"))

    query = from [s, m] in query, group_by: s.id, select: %{id: s.id, last_message: max(m.inserted_at), first_message: min(m.inserted_at)}

    sessions = Repo.all(query)
    render(conn, "index.json", sessions: sessions)
  end

  def log(conn, %{"session_id" => session_id}) do
    logs = MessageLog 
            |> where([m], m.session_id == ^session_id)
            |> Repo.all
            |> Enum.map(&(%{timestamp: &1.inserted_at, direction: &1.direction, content: &1.content}))
    render(conn, "logs.json", logs: logs)
  end

end
