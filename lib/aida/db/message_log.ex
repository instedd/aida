defmodule Aida.DB.MessageLog do
  use Ecto.Schema
  alias Aida.{Repo, DB.Session}
  import Ecto.Changeset
  import Ecto.Query
  alias __MODULE__

  schema "message_logs" do
    field :bot_id, :binary_id
    field :session_id, :binary_id
    field :direction, :string
    field :content, :string
    field :content_type, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%MessageLog{} = message_log, attrs) do
    message_log
      |> cast(attrs, [:bot_id, :session_id, :direction, :content, :content_type])
      |> validate_required([:bot_id, :session_id, :direction, :content, :content_type])
  end

  def create(params) do
    %MessageLog{}
      |> MessageLog.changeset(params)
      |> Repo.insert!
  end

  def get_last_incoming(bot_id, session_id) do
    MessageLog
    |> where([m], m.bot_id == ^bot_id and m.session_id == ^session_id)
    |> where([m], m.direction == "incoming")
    |> Repo.aggregate(:max, :inserted_at)
  end

  def session_index_by_bot(bot_id) do
    Session
      |> join(:inner, [s], m in MessageLog, m.session_id == s.id)
      |> where([s], s.bot_id == ^bot_id)
      |> where([_, m], m.direction == "incoming")
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
end
