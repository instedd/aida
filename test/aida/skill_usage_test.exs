defmodule Aida.SkillUsageTest do
  use Aida.DataCase
  alias Aida.{BotParser, Bot, Message, DB, DB.Session}
  use Aida.SessionHelper
  use ExUnit.Case

  describe "multiple languages bot" do
    setup do
      manifest =
        File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!()

      {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(db_bot.id, manifest)
      initial_session = Session.new({bot.id, "facebook", "1234/5678"})

      %{bot: bot, initial_session: initial_session}
    end

    test "stores an interaction per sent message when the front_desk answers", %{
      bot: bot,
      initial_session: initial_session
    } do
      input =
        Message.new("Hi!", bot, initial_session)
        |> Message.put_session("language", "en")

      Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 1
    end

    test "stores only one interaction per sent message for each skill", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("english", bot, initial_session)
      output = Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 2

      input2 = Message.new("español", bot, output.session)
      Bot.chat(input2)
      assert Enum.count(DB.list_skill_usages()) == 2
    end

    test "stores one interaction per sent message for each skill", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("english", bot, initial_session)
      output = Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 2

      input2 = Message.new("español", bot, output.session)
      output2 = Bot.chat(input2)
      assert Enum.count(DB.list_skill_usages()) == 2

      input3 = Message.new("menu", bot, output2.session)
      Bot.chat(input3)
      assert Enum.count(DB.list_skill_usages()) == 3
    end

    test "stores an interaction per sent message with the proper data for language_detector", %{
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("english", bot, initial_session)
      Bot.chat(input)
      skill_usage = DB.list_skill_usages() |> Enum.find(&(&1.skill_id == "language_detector"))

      assert skill_usage.user_id == input.session.id
      assert skill_usage.bot_id == bot.id
      assert Date.to_string(skill_usage.last_usage) == Date.to_string(Date.utc_today())
      assert skill_usage.user_generated == true
    end

    test "stores an interaction per sent message with the proper data when the front desk answers",
         %{bot: bot, initial_session: initial_session} do
      input =
        Message.new("Hi!", bot, initial_session)
        |> Message.put_session("language", "en")

      Bot.chat(input)

      assert Enum.count(DB.list_skill_usages()) == 1

      skill_usage = Enum.at(DB.list_skill_usages(), 0)

      assert skill_usage.user_id == input.session.id
      assert skill_usage.bot_id == bot.id
      assert Date.to_string(skill_usage.last_usage) == Date.to_string(Date.utc_today())
      assert skill_usage.skill_id == "front_desk"
      assert skill_usage.user_generated == true
    end
  end
end
