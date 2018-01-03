defmodule Aida.Repo.Migrations.AddTempToBots do
  use Ecto.Migration

  def change do
    alter table(:bots) do
      add :temp, :boolean, default: false
    end
  end
end
