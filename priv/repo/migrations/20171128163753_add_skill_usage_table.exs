defmodule Aida.Repo.Migrations.AddSkillUsageTable do
  use Ecto.Migration

  def change do
    create table(:skill_usage, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :bot_id, :binary_id
      add :user_id, :string
      add :last_usage, :date
      add :skill_id, :string
      add :user_generated, :boolean

      timestamps()
    end

  end
end
