defmodule Aida.Repo.Migrations.ReplaceIdWithUUIDInSessions do
  use Ecto.Migration
  alias Aida.Repo

  defmodule Session do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "sessions" do
      field :bot_id, :binary_id
      field :provider, :string
      field :provider_key, :string
    end
  end

  def up do
    Repo.query!("UPDATE sessions SET id=uuid")
    Repo.query!("ALTER TABLE sessions ALTER COLUMN id TYPE uuid USING id::uuid")

    alter table(:sessions) do
      remove :uuid
    end
  end

  def down do
    alter table(:sessions) do
      add :uuid, :binary_id
    end
    create unique_index(:sessions, [:uuid])
    flush()

    Repo.query!("UPDATE sessions SET uuid=id")
    Repo.query!("ALTER TABLE sessions ALTER COLUMN id TYPE varchar(255) USING id::varchar(255)")

    Session |> Repo.all |> Enum.each(fn s ->
      id = Enum.join([s.bot_id, s.provider, s.provider_key], "/")
      Ecto.Changeset.change(s, %{id: id}) |> Repo.update!
    end)
  end
end
