defmodule Aida.DB.MessageLog do
  use Ecto.Schema
  alias Aida.Repo
  import Ecto.Changeset
  alias __MODULE__

  schema "message_logs" do
    field :bot_id, :binary_id
    field :session_id, :string
    field :direction, :string
    field :content, :string
    field :content_type, :string

    timestamps()
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
      |> Repo.insert
  end
end
