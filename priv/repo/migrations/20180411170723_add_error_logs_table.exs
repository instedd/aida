defmodule Aida.Repo.Migrations.AddErrorLogsTable do
  use Ecto.Migration

  def change do
    create table(:error_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bot_id, references(:bots, type: :binary_id, on_delete: :delete_all), null: false
      add :session_id, :binary_id
      add :skill_id, :string
      add :message, :text

      timestamps(updated_at: false, type: :utc_datetime)
    end
  end
end
