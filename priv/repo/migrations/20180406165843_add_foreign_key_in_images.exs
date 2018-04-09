defmodule Aida.Repo.Migrations.AddForeignKeyInImages do
  use Ecto.Migration
  alias Aida.Repo

  def change do
    Repo.query!("DELETE FROM images WHERE session_id NOT IN (SELECT id FROM sessions)")

    alter table(:images) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :string)
    end
  end
end
