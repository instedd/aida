defmodule Aida.Repo.Migrations.CreateSchedulerTasks do
  use Ecto.Migration

  def change do
    create table(:scheduler_tasks) do
      add :name, :string
      add :ts, :utc_datetime
      add :handler, :string

      timestamps()
    end
  end
end
