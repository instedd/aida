defmodule Aida.Repo.Migrations.AddForeignKeyInSkillUsage do
  use Ecto.Migration

  def change do
    alter table(:skill_usage) do
      modify :bot_id, references(:bots, on_delete: :delete_all, type: :binary_id)
    end
  end
end
