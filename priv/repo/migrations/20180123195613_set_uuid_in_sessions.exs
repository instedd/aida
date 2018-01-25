defmodule Aida.Repo.Migrations.SetUuidInSessions do
  use Ecto.Migration

  defmodule Session do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    @foreign_key_type :string
    schema "sessions" do
      field :uuid, :binary_id
    end
  end

  def change do
    Aida.Repo.all(Session)
      |> Enum.each(fn session ->
        session
          |> Ecto.Changeset.change(uuid: Ecto.UUID.generate)
          |> Aida.Repo.update!
      end)
  end
end
