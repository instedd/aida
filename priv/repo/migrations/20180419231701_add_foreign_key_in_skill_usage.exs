defmodule Aida.Repo.Migrations.AddForeignKeyInSkillUsage do
  use Ecto.Migration
  alias Aida.Repo

  def up do
    Repo.query!("DELETE FROM skill_usage WHERE bot_id NOT IN (SELECT id FROM bots)")

    alter table(:skill_usage) do
      modify :bot_id, references(:bots, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    Repo.query!("ALTER TABLE skill_usage DROP CONSTRAINT skill_usage_bot_id_fkey")
  end
end
