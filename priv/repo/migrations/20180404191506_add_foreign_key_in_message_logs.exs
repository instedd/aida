defmodule Aida.Repo.Migrations.AddForeignKeyInMessageLogs do
  use Ecto.Migration
  alias Aida.Repo

  def change do
    Repo.query!("DELETE FROM message_logs WHERE session_id NOT IN (SELECT id FROM sessions)")

    alter table(:message_logs) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :string)
    end
  end
end
