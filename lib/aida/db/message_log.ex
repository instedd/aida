defmodule Aida.DB.MessageLog do
  use Ecto.Schema
  alias Aida.Repo
  import Ecto.Changeset
  import Ecto.Query
  alias __MODULE__

  @foreign_key_type :string
  schema "message_logs" do
    field :bot_id, :binary_id
    field :session_id, :string
    field :session_uuid, :binary_id
    field :direction, :string
    field :content, :string
    field :content_type, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(%MessageLog{} = message_log, attrs) do
    message_log
      |> cast(attrs, [:bot_id, :session_id, :session_uuid, :direction, :content, :content_type])
      |> validate_required([:bot_id, :session_id, :session_uuid, :direction, :content, :content_type])
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
end
