defmodule Aida.Repo.Migrations.ModifySessionIdTypeToMessageLog do
  use Ecto.Migration
  alias Aida.Repo

  def up do
    Repo.query! "UPDATE message_logs AS m SET session_id = session_uuid"

    Repo.query!("ALTER TABLE message_logs ALTER COLUMN session_id TYPE uuid USING session_id::uuid")

    alter table(:message_logs) do
      remove :session_uuid
    end
  end

  def down do
    alter table(:message_logs) do
      add :session_uuid, :binary_id
    end
    create index(:message_logs, [:session_uuid])
    flush()

    Repo.query! "UPDATE message_logs AS m SET session_uuid = session_id"

    Repo.query!("ALTER TABLE message_logs ALTER COLUMN session_id TYPE varchar(255) USING session_id::varchar(255)")

    Repo.query! "UPDATE message_logs AS m SET session_id = s.id
      FROM sessions AS s
      WHERE m.session_id = s.uuid::varchar(255)"
  end
end
