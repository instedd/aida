defmodule Aida.Repo.Migrations.AddSessionUuidToMessageLogs do
  use Ecto.Migration

  def change do
    alter table(:message_logs) do
      add :session_uuid, :binary_id
    end
    create index(:message_logs, [:session_uuid])
  end
end
