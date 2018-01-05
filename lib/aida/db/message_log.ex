defmodule Aida.DB.MessageLog do
  use Ecto.Schema
  alias Aida.DB
  alias Aida.Repo
  import Ecto.Changeset
  alias __MODULE__

  schema "message_logs" do
    field :bot_id, :binary_id
    field :session_id, :string
    field :direction, :string
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(%MessageLog{} = message_log, attrs) do
    message_log
      |> cast(attrs, [:bot_id, :session_id, :direction, :content])
      |> validate_required([:bot_id, :session_id, :direction, :content])
  end

  def create(bot_id, session_id, content, direction) do
    attrs = %{bot_id: bot_id, session_id: session_id, direction: direction, content: content}

    %MessageLog{}
    |> MessageLog.changeset(attrs)
    |> Repo.insert
  end
end
