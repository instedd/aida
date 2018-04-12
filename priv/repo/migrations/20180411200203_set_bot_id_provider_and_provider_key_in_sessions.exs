defmodule Aida.Repo.Migrations.SetBotIdProviderAndProviderKeyInSessions do
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
    Session |> Repo.all |> Enum.each(fn s ->
      [bot_id, provider, provider_key] = s.id |> String.split("/", parts: 3)
      Ecto.Changeset.change(s, %{bot_id: bot_id, provider: provider, provider_key: provider_key}) |> Repo.update!
    end)
  end

  def down do
    Session |> Repo.all |> Enum.each(fn s ->
      Ecto.Changeset.change(s, %{bot_id: nil}) |> Repo.update!
    end)
  end
end
