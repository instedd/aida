defmodule Aida.Repo.Migrations.AddDoNotDisturb do
  use Ecto.Migration

  def change do
    alter table(:sessions) do
      add :do_not_disturb, :boolean, default: false
    end
  end
end
