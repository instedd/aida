defmodule Aida.Repo.Migrations.SetDefaultContentTypeToMessageLogs do
  use Ecto.Migration

  def change do
    Aida.Repo.query!(~s(UPDATE message_logs SET content_type = 'text' WHERE content_type IS NULL))
  end
end
