defmodule Aida.Repo.Migrations.AddForeignKeyInImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :string)
    end
  end
end
