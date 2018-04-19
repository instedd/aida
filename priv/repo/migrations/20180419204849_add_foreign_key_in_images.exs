defmodule Aida.Repo.Migrations.AddForeignKeyInImages do
  use Ecto.Migration
  alias Aida.Repo

  def up do
    Repo.query!("ALTER TABLE images ALTER COLUMN session_id TYPE uuid USING session_id::uuid")
    Repo.query!("DELETE FROM images WHERE session_id NOT IN (SELECT id FROM sessions)")

    alter table(:images) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    Repo.query!("ALTER TABLE images DROP CONSTRAINT images_session_id_fkey")
    Repo.query!("ALTER TABLE images ALTER COLUMN session_id TYPE varchar(255) USING session_id::varchar(255)")
  end
end
