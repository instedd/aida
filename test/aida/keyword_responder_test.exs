defmodule Aida.KeywordResponderTest do
  alias Aida.{BotParser, SessionStore, Message, Skill}
  use Aida.DataCase

  @bot_id "486d6622-225a-42c6-864b-5457687adc30"

  describe "keyword responder" do
    setup do
      SessionStore.start_link
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      {:ok, bot} = BotParser.parse(@bot_id, manifest)

      %{bot: bot}
    end

    test "replies with the proper confidence 1", %{bot: bot} do
      message = Message.new("message that says hours between words", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 1/6
    end

    test "replies with the proper confidence 2", %{bot: bot} do
      message = Message.new("message that says hours between more words than before", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 1/9
    end

    test "replies with the proper confidence when there is a comma", %{bot: bot} do
      message = Message.new("message that says hours, and has a comma,", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 1/8
    end

    test "replies with the proper confidence when there is a question mark", %{bot: bot} do
      message = Message.new("message that says hours? yes, and it is a question", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 1/10
    end

    test "does not give an exception with an empty message", %{bot: bot} do
      message = Message.new("", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 0
    end

    test "returns 0 when there is no match", %{bot: bot} do
      message = Message.new("message that says a lot of different words", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 0
    end

    test "replies with the proper confidence when there is more than 1 match", %{bot: bot} do
      message = Message.new("message that says hours and also says time", bot)
      |> Message.put_session("language", "en")

      confidence = get_confidence_from_skill_id(bot.skills, message, "this is a different id")

      assert confidence == 2/8
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
