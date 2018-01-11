defmodule Aida.Repo.Migrations.AddContentTypeToMessageLogs do
  use Ecto.Migration

  def change do
    alter table(:message_logs) do
      add :content_type, :string
    end
  end
end
