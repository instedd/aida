defmodule Aida.Repo.Migrations.SetSessionUuidInMessageLogs do
  use Ecto.Migration

  def up do
   Aida.Repo.query!("UPDATE message_logs SET session_uuid = (SELECT s.uuid from sessions s WHERE message_logs.session_id = s.id) WHERE session_uuid IS NULL")
  end

  def down do
  end
end
