defmodule Aida.Repo.Migrations.AddForeignKeyInMessagesPerDay do
  use Ecto.Migration

  def change do
    alter table(:messages_per_day) do
      modify :bot_id, references(:bots, on_delete: :delete_all, type: :binary_id)
    end
  end
end
