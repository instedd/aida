defmodule Aida.Repo.Migrations.CreateAssets do
  use Ecto.Migration

  def change do
    create table(:assets) do
      add :skill_id, :string
      add :session_id, :binary_id
      add :data, :text

      timestamps()
    end
  end
end
