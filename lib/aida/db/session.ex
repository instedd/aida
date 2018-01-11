defmodule Aida.DB.Session do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Aida.Ecto.Type.JSON
  alias Aida.DB.MessageLog
  alias Aida.Repo
  alias __MODULE__

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string
  schema "sessions" do
    field :data, JSON

    timestamps()
  end

  def session_index_by_bot(bot_id) do
    Session 
      |> join(:inner, [s], m in MessageLog, m.session_id == s.id) 
      |> where([s], like(s.id, ^"#{bot_id}/%"))
      |> group_by([s, m], s.id)
      |> select([s, m], %{id: s.id, first_message: min(m.inserted_at), last_message: max(m.inserted_at)})
      |> Repo.all()
  end

  def message_logs_by_session(session_id) do
    MessageLog 
      |> where([m], m.session_id == ^session_id)
      |> select([m], %{timestamp: m.inserted_at, direction: m.direction, content: m.content, content_type: m.content_type})
      |> Repo.all
  end

  @doc false
  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:id, :data])
    |> validate_required([:id, :data])
  end
end
