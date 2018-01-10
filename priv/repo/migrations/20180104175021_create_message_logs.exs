defmodule Aida.Repo.Migrations.CreateMessageLogs do
  use Ecto.Migration

  def change do
    create table(:message_logs) do
      add :bot_id, :binary_id 
      add :session_id, :string
      add :direction, :string
      add :content, :text

      timestamps()
    end

  end
end
