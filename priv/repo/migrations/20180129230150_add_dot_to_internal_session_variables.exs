defmodule Aida.Repo.Migrations.AddDotToInternalSessionVariables do
  use Ecto.Migration

  defmodule Session do
    use Ecto.Schema
    @primary_key {:id, :string, autogenerate: false}
    @foreign_key_type :string
    schema "sessions" do
      field :data, Aida.Ecto.Type.JSON
    end
  end

  def up do
    Aida.Repo.all(Session)
    |> Enum.each(fn session ->
      session |> update_session() |> Aida.Repo.update!
    end)
  end

  defp update_session(session) do
    data =
      session.data
      |> Enum.map(fn
        {"survey/" <> _ = key, value} when is_map(value) ->
          {"." <> key, value}
        {"facebook_profile_ts", value} ->
          {".facebook_profile_ts", value}
        kv -> kv
      end)
      |> Enum.into(%{})

    Ecto.Changeset.change(session, data: data)
  end
end
