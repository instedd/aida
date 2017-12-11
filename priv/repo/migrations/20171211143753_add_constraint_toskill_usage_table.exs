defmodule Aida.Repo.Migrations.AddConstraintToSkillUsageTable do
  use Ecto.Migration

  def change do
    create unique_index(:skill_usage, [:bot_id, :user_id, :skill_id, :user_generated])
  end
end
