defmodule Aida.Repo.Migrations.AddFieldsToImages do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :bot_id, :binary_id
      add :session_id, :string
      add :uuid, :uuid, default: fragment("md5(random()::text || clock_timestamp()::text)::uuid")
    end
  end
end
