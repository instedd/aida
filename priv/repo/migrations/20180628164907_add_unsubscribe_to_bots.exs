defmodule Aida.Repo.Migrations.AddUnsubscribeToBots do
  use Ecto.Migration

  defmodule Bot do
    use Ecto.Schema
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "bots" do
      field(:manifest, Aida.Ecto.Type.JSON)
    end
  end

  def up do
    migrate(:up)
  end

  def down do
    migrate(:down)
  end

  def migrate(dir) do
    Aida.Repo.all(Bot)
    |> Enum.each(fn bot ->
      bot |> update(dir) |> Aida.Repo.update!()
    end)
  end

  defp update(%Bot{manifest: manifest} = bot, dir) do
    manifest =
      case dir do
        :up -> put_new_unsubscribe(manifest)
        :down -> delete_unsubscribe(manifest)
      end

    Ecto.Changeset.change(bot, manifest: manifest)
  end

  defp put_new_unsubscribe(%{"front_desk" => front_desk} = manifest) do
    %{
      manifest
      | "front_desk" => Map.put_new(front_desk, "unsubscribe", unsubscribe(manifest))
    }
  end

  defp delete_unsubscribe(%{"front_desk" => front_desk} = manifest) do
    %{manifest | "front_desk" => Map.delete(front_desk, "unsubscribe")}
  end

  defp unsubscribe(%{"languages" => languages}) do
    %{
      "introduction_message" => messages(languages),
      "keywords" => keywords(languages),
      "acknowledge_message" => acknowledge_messages(languages)
    }
  end

  defp messages(languages) do
    List.foldl(languages, %{}, &put_new_message(&1, &2))
  end

  defp put_new_message(language, messages) do
    Map.put_new(messages, language, "Send UNSUBSCRIBE to stop receiving messages")
  end

  defp acknowledge_messages(languages) do
    List.foldl(languages, %{}, &put_new_acknowledge_message(&1, &2))
  end

  defp put_new_acknowledge_message(language, messages) do
    Map.put_new(messages, language, "I won't send you any further messages")
  end

  defp keywords(languages) do
    List.foldl(languages, %{}, &put_new_keywords(&1, &2))
  end

  defp put_new_keywords(language, messages) do
    Map.put_new(messages, language, ["UNSUBSCRIBE"])
  end
end
