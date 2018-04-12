defmodule Aida.Repo.Migrations.AddBotIdProviderAndProviderKeyToSessions do
  use Ecto.Migration

  def up do
    alter table(:sessions) do
      add :bot_id, :binary_id
      add :provider, :string
      add :provider_key, :string
    end
  end

  def down do
    alter table(:sessions) do
      remove :bot_id
      remove :provider
      remove :provider_key
    end
  end
end
