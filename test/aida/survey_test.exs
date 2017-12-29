defmodule Aida.SurveyTest do
  alias Aida.{Bot, BotManager, Skill, Skill.Survey, SessionStore, BotParser, TestChannel, Session, DB, Message}
  use Aida.DataCase
  import Mock

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
    skill = %Survey{id: @skill_id, schedule: DateTime.utc_now |> Timex.shift(days: 1)}

    schedule_wake_up_fn = fn(_bot, _skill, delay) ->
      assert_in_delta delay, :timer.hours(24), :timer.seconds(1)
      :ok
    end

    with_mock BotManager, [schedule_wake_up: schedule_wake_up_fn] do
      skill |> Skill.init(bot)
      assert called BotManager.schedule_wake_up(bot, skill, :_)
    end
  end

  test "init doesn't schedule wake_up if the survey is scheduled in the past" do
    bot = %Bot{id: @bot_id}
    skill = %Survey{id: @skill_id, schedule: DateTime.utc_now |> Timex.shift(days: -1)}

    with_mock BotManager, [schedule_wake_up: fn(_bot, _skill, _delay) -> :ok end] do
      skill |> Skill.init(bot)
      refute called BotManager.schedule_wake_up(:_, :_, :_)
    end
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

    test "do not start the survey if the session doesn't have a language", %{bot: bot} do
      channel = TestChannel.new()
      bot = %{bot | channels: [channel]}

      Session.new(@session_id, %{})
      |> Session.save

      DB.create_skill_usage(%{
        bot_id: @bot_id,
        user_id: @session_id,
        last_usage: DateTime.utc_now,
        skill_id: hd(bot.skills) |> Skill.id,
        user_generated: true
      })

      Bot.wake_up(bot, "food_preferences")

      refute_received {:send_message, _, _}
    end

    test "accept user reply", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 0}})

      message = Message.new("Yes", session)
      message = Bot.chat(bot, message)

      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 1}
      assert message.reply == ["How old are you?"]
      assert message |> Message.get_session("survey/food_preferences/opt_in") == "yes"
    end

    test "invalid reply should retry the question", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 2}})

      message = Message.new("bananas", session)
      message = Bot.chat(bot, message)

      assert message.reply == ["At what temperature do your like red wine the best?"]
      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 2}
    end

    test "bot should answer a keyword even if survey is active on highest threshold", %{bot: bot} do
      bot = %{bot | front_desk: %{bot.front_desk | threshold: 0.5}}
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 2}})

      message = Message.new("hours", session)
      message = Bot.chat(bot, message)

      assert message.reply == ["We are open every day from 7pm to 11pm"]
      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 2}
    end

    test "accept user reply on select_many", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 3}})

      message = Message.new("merlot, syrah", session)
      message = Bot.chat(bot, message)

      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 4}
      assert message.reply == ["Any particular requests for your dinner?"]
      assert message |> Message.get_session("survey/food_preferences/wine_grapes") == ["merlot", "syrah"]
    end

    test "clears the store to end the survey", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 4}})

      message = Message.new("No, thanks!", session)
      message = Bot.chat(bot, message)

      assert message |> Message.get_session("survey/food_preferences") == nil
    end

    test "skip questions when the relevant attribute evaluates to false", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 1}})

      message = Message.new("15", session)
      message = Bot.chat(bot, message)

      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 4}
      assert message.reply == ["Any particular requests for your dinner?"]
    end

    test "do not skip questions when the relevant attribute evaluates to false", %{bot: bot} do
      session = Session.new(@session_id, %{"language" => "en", "survey/food_preferences" => %{"step" => 1}})

      message = Message.new("20", session)
      message = Bot.chat(bot, message)

      assert message |> Message.get_session("survey/food_preferences") == %{"step" => 2}
      assert message.reply == ["At what temperature do your like red wine the best?"]
    end
  end
end
