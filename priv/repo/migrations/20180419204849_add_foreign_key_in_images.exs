defmodule Aida.Repo.Migrations.AddForeignKeyInImages do
  use Ecto.Migration
  import Ecto.Query
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
    defmodule Image do
      use Ecto.Schema

      schema "images" do
        field :session_id, :string
      end
    end

    Image |> Repo.all |> Enum.each(fn image ->
      [bot_id, provider, provider_key] = image.session_id |> String.split("/", parts: 3)
      sessions = Repo.all(from s in Session, where: (s.bot_id == ^bot_id) and (s.provider == ^provider) and (s.provider_key == ^provider_key))
      updated_session_id = case sessions do
        [session] -> elem(Ecto.UUID.load(session.id), 1)
        _ -> nil
      end
      Ecto.Changeset.change(image, %{session_id: updated_session_id}) |> Repo.update!
    end)

    Repo.query!("ALTER TABLE images ALTER COLUMN session_id TYPE uuid USING session_id::uuid")
    Repo.query!("DELETE FROM images WHERE session_id IS NULL OR session_id NOT IN (SELECT id FROM sessions)")

    alter table(:images) do
      modify :session_id, references(:sessions, on_delete: :delete_all, type: :binary_id)
    end
  end

  def down do
    defmodule Image do
      use Ecto.Schema

      schema "images" do
        field :session_id, :string
      end
    end

    Repo.query!("ALTER TABLE images DROP CONSTRAINT images_session_id_fkey")
    Repo.query!("ALTER TABLE images ALTER COLUMN session_id TYPE varchar(255) USING session_id::varchar(255)")
    images = Image |> Repo.all
    images |> Enum.each(fn image ->
      {:ok, session_uuid} = Ecto.UUID.dump(image.session_id)
      session = Repo.one(from s in Session, where: s.id == ^session_uuid)
      old_session_id = "#{session.bot_id}/#{session.provider}/#{session.provider_key}"
      Ecto.Changeset.change(image, %{session_id: old_session_id}) |> Repo.update!
    end)
  end
end
