defmodule Aida.Repo.Migrations.CreateBots do
  use Ecto.Migration

  def change do
    create table(:bots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :manifest, :text

      timestamps()
    end
  end
end
