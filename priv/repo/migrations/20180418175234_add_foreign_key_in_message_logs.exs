defmodule Aida.Repo.Migrations.AddForeignKeyInMessageLogs do
  use Ecto.Migration
  alias Aida.Repo

  def up do
    Repo.query!("DELETE FROM message_logs WHERE session_id NOT IN (SELECT id FROM sessions)")

    alter table(:message_logs) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    Repo.query!("ALTER TABLE message_logs DROP CONSTRAINT message_logs_session_id_fkey")
  end
end
