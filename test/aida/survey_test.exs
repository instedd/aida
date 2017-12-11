defmodule Aida.SurveyTest do
  alias Aida.{Bot, BotManager, Skill, Skill.Survey, SessionStore, BotParser, TestChannel, Session, DB, Message}
  use Aida.DataCase

  @bot_id "c4cf6a74-d154-4e2f-9945-ba999b06f8bd"
  @skill_id "e7f2702c-5188-4d12-97b7-274162509ed1"
  @session_id "facebook/1234567890/0987654321"

  test "calculate wake_up delay" do
    now = DateTime.utc_now
    survey = %Survey{schedule: now |> Timex.shift(hours: 10)}
    assert Survey.delay(survey, now) == :timer.hours(10)
  end

  test "init schedules wake_up" do
    bot = %Bot{id: @bot_id}
    skill = %Survey{id: @skill_id, schedule: DateTime.utc_now |> Timex.shift(milliseconds: 100)}
      |> Skill.init(bot)

    refute_received _
    :timer.sleep(100)

    message = BotManager.wake_up_message(bot, skill)
    assert_received ^message
  end

  describe "wake_up" do
    setup do
      SessionStore.start_link

      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])

      {:ok, bot} = BotParser.parse(@bot_id, manifest)
      %{bot: bot}
    end

    test "starts the survey", %{bot: bot} do
      channel = TestChannel.new()
      bot = %{bot | channels: [channel]}

      Session.new(@session_id, %{"language" => "en"})
      |> Session.save

      DB.create_skill_usage(%{
        bot_id: @bot_id,
        user_id: @session_id,
        last_usage: DateTime.utc_now,
        skill_id: hd(bot.skills) |> Skill.id,
        user_generated: true
      })

      Bot.wake_up(bot, "food_preferences")

      assert_received {:send_message, ["I would like to ask you a few questions to better cater for your food preferences. Is that ok?"], "0987654321"}

      session = Session.load(@session_id)
      assert session |> Session.get("survey/food_preferences") == %{"step" => 0}
    end

    test "accept user reply", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 0}})

      message = Message.new("yes", session)
      message = Bot.chat(bot, message)

      assert message.reply == ["How old are you?"]
      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 1}
    end
  end
end
