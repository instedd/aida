defmodule Aida.HumanOverrideTest do
  alias Aida.{BotParser, Message, Skill}
  use ExUnit.Case
  use Aida.SessionHelper

  @bot_id "486d6622-225a-42c6-864b-5457687adc30"
  @human_override_id "human_override_skill"

  describe "human override confidence" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_with_human_override.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      {:ok, bot} = BotParser.parse(@bot_id, manifest)
      initial_session = new_session(Ecto.UUID.generate, %{})

      %{bot: bot, initial_session: initial_session}
    end

    test "replies with the proper confidence 1", %{bot: bot, initial_session: initial_session} do
      message = Message.new("message that says available between words", bot, initial_session)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, @human_override_id)

      assert confidence == 1/6
    end
  end

  def get_confidence_from_skill_id(skills, message, id) do
    skills = skills
    |> Enum.filter(fn(skill) ->
      skill.id == id
    end)

    case skills do
      [skill] ->
        Skill.confidence(skill, message)
      _ ->
        assert false
    end
  end
end
