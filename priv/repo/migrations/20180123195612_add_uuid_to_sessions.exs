defmodule Aida.Repo.Migrations.AddUuidToSessions do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :uuid, :binary_id
    end

    create unique_index(:sessions, [:uuid])
  end
end
