defmodule Aida.Repo.Migrations.AddForeignKeyInSessions do
  use Ecto.Migration
  alias Aida.Repo

  def up do
    Repo.query!("DELETE FROM sessions WHERE bot_id NOT IN (SELECT id FROM bots)")

    alter table(:sessions) do
      modify :bot_id, references(:bots, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    Repo.query!("ALTER TABLE sessions DROP CONSTRAINT sessions_bot_id_fkey")
  end
end
