defmodule Aida.DB.MessagesPerDay do
  use Ecto.Schema
  alias Aida.DB
  import Ecto.Changeset
  alias __MODULE__
  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "messages_per_day" do
    field(:bot_id, :binary_id)
    field(:day, :date)
    field(:sent_messages, :integer, default: 0)
    field(:received_messages, :integer, default: 0)

    timestamps()
  end

  @doc false
  def changeset(%MessagesPerDay{} = messagesPerDay, attrs) do
    messagesPerDay
    |> cast(attrs, [:bot_id, :day, :sent_messages, :received_messages])
    |> validate_required([:bot_id, :day, :sent_messages, :received_messages])
  end

  def log_received_message(bot_id) do
    changeset = %{bot_id: bot_id, day: Date.utc_today(), received_messages: 1}
    DB.create_or_update_messages_per_day_received(changeset)
  end

  def log_sent_message(bot_id) do
    changeset = %{bot_id: bot_id, day: Date.utc_today(), sent_messages: 1}
    DB.create_or_update_messages_per_day_sent(changeset)
  end
end
