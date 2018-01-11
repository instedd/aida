defmodule Aida.Repo.Migrations.ConvertScheduledMessagesDelayToInteger do
  use Ecto.Migration

  defmodule Bot do
    use Ecto.Schema
    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "bots" do
      field :manifest, Aida.Ecto.Type.JSON
    end
  end


  def up do
    migrate(:up)
  end

  def down do
    migrate(:down)
  end

  defp migrate(dir) do
    Aida.Repo.all(Bot)
    |> Enum.each(fn bot ->
      bot |> update_bot(dir) |> Aida.Repo.update!
    end)
  end

  defp update_bot(%Bot{manifest: manifest} = bot, dir) do
    Ecto.Changeset.change(bot, manifest: update_manifest(manifest, dir))
  end

  defp update_manifest(%{"skills" => skills} = manifest, dir) do
    skills = skills |> Enum.map(&update_skill(&1, dir))
    %{manifest | "skills" => skills}
  end

  defp update_skill(%{"type" => "scheduled_messages", "messages" => messages} = skill, dir) do
    messages = messages |> Enum.map(&update_message(&1, dir))
    %{skill | "messages" => messages}
  end

  defp update_skill(skill, _), do: skill

  defp update_message(%{"delay" => delay} = message, dir) do
    delay =
      case dir do
        :up -> String.to_integer(delay)
        :down -> Integer.to_string(delay)
      end
    %{message | "delay" => delay}
  end

  defp update_message(message, _), do: message
end
