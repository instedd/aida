defmodule Aida.Repo.Migrations.AddForeignKeyInMessagesPerDay do
  use Ecto.Migration
  alias Aida.Repo

  def change do
    Repo.query!("DELETE FROM messages_per_day WHERE bot_id NOT IN (SELECT id FROM bots)")

    alter table(:messages_per_day) do
      modify :bot_id, references(:bots, on_delete: :delete_all, type: :binary_id)
    end
  end
end
