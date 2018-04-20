defmodule Aida.SkillUsageTest do
  use Aida.DataCase
  alias Aida.{BotParser, Bot, Message}
  alias Aida.DB

  use ExUnit.Case

  @bot_id "486d6622-225a-42c6-864b-5457687adc30"

  describe "multiple languages bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
      {:ok, bot} = BotParser.parse(@bot_id, manifest)

      %{bot: bot}
    end

    test "stores an interaction per sent message when the front_desk answers", %{bot: bot} do
      input = Message.new("Hi!", bot)
        |> Message.put_session("language", "en")
      Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 1
    end

    test "stores only one interaction per sent message for each skill", %{bot: bot} do
      input = Message.new("english", bot)
      output = Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 2

      input2 = Message.new("español", bot, output.session)
      Bot.chat(input2)
      assert Enum.count(DB.list_skill_usages()) == 2
    end

    test "stores one interaction per sent message for each skill", %{bot: bot} do
      input = Message.new("english", bot)
      output = Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 2

      input2 = Message.new("español", bot, output.session)
      output2 = Bot.chat(input2)
      assert Enum.count(DB.list_skill_usages()) == 2

      input3 = Message.new("menu", bot, output2.session)
      Bot.chat(input3)
      assert Enum.count(DB.list_skill_usages()) == 3

    end

    test "stores an interaction per sent message with the proper data for language_detector", %{bot: bot} do
      input = Message.new("english", bot)
      Bot.chat(input)
      skill_usage = DB.list_skill_usages() |> Enum.find(&(&1.skill_id == "language_detector"))

      assert skill_usage.user_id == input.session.id
      assert skill_usage.bot_id == bot.id
      assert Date.to_string(skill_usage.last_usage) == Date.to_string(Date.utc_today())
      assert skill_usage.user_generated == true
    end

    test "stores an interaction per sent message with the proper data when the front desk answers", %{bot: bot} do
      input = Message.new("Hi!", bot)
        |> Message.put_session("language", "en")
      Bot.chat(input)

      assert Enum.count(DB.list_skill_usages()) == 1

      skill_usage = Enum.at(DB.list_skill_usages(),0)

      assert skill_usage.user_id == input.session.id
      assert skill_usage.bot_id == bot.id
      assert Date.to_string(skill_usage.last_usage) == Date.to_string(Date.utc_today())
      assert skill_usage.skill_id == "front_desk"
      assert skill_usage.user_generated == true
    end

  end
end
