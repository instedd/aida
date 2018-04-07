defmodule Aida.Repo.Migrations.AddForeignKeyInMessageLogs do
  use Ecto.Migration

  def change do
    alter table(:message_logs) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :string)
    end
  end
end
