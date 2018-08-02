defmodule Aida.Repo.Migrations.AddInHoursToHumanOverrideSkillsInManifests do
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
        :up -> manifest_with_default_human_override_in_hours(manifest)
        :down -> manifest_without_human_override_in_hours(manifest)
      end

    Ecto.Changeset.change(bot, manifest: manifest)
  end

  @always_in_hours %{
    "hours" => [
      %{ "day" => "mon" },
      %{ "day" => "tue" },
      %{ "day" => "wed" },
      %{ "day" => "thu" },
      %{ "day" => "fri" },
      %{ "day" => "sat" },
      %{ "day" => "sun" },
    ],
    "timezone" => "Etc/UTC"
  }

  defp default_human_override_in_hours(%{"type" => "human_override"} = human_override_skill) do
    Map.put(human_override_skill, "in_hours", @always_in_hours)
  end
  defp default_human_override_in_hours(non_human_override_skill), do: non_human_override_skill

  defp manifest_with_default_human_override_in_hours(%{"skills" => skills} = manifest) do
    %{
      manifest | "skills" => Enum.map(skills, fn skill -> default_human_override_in_hours(skill) end)
    }
  end

  defp human_override_without_in_hours(%{"type" => "human_override"} = human_override_skill) do
    Map.delete(human_override_skill, "in_hours")
  end
  defp human_override_without_in_hours(non_human_override_skill), do: non_human_override_skill

  defp manifest_without_human_override_in_hours(%{"skills" => skills} = manifest) do
    %{
      manifest | "skills" => Enum.map(skills, fn skill -> human_override_without_in_hours(skill) end)
    }
  end
end
