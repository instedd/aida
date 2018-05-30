defmodule Aida.Repo.Migrations.AddIsNewToSessions do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :is_new, :boolean
    end
  end
end
