defmodule Aida.Repo.Migrations.AddMessagesPerDayTable do
  use Ecto.Migration

  def change do
    create table(:messages_per_day, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bot_id, :binary_id
      add :day, :date
      add :sent_messages, :integer
      add :received_messages, :integer

      timestamps()
    end

    create unique_index(:messages_per_day, [:bot_id, :day])

  end
end
