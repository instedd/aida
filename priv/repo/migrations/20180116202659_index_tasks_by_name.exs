defmodule Aida.Repo.Migrations.IndexTasksByName do
  use Ecto.Migration

  def change do
    create unique_index(:scheduler_tasks, [:name])
  end
end
