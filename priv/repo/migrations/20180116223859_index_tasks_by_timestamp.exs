defmodule Aida.Repo.Migrations.IndexTasksByTimestamp do
  use Ecto.Migration

  def change do
    create index(:scheduler_tasks, [:ts])
  end
end
