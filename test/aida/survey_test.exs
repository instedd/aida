defmodule Aida.SurveyTest do
  alias Aida.{
    Bot,
    BotManager,
    Crypto,
    Skill,
    Skill.Survey,
    Skill.Survey.InputQuestion,
    BotParser,
    TestChannel,
    Message,
    ChannelProvider
  }
  alias Aida.DB.{Session}

  use Aida.DataCase
  use Aida.SessionHelper
  import Mock

  @bot_id "c4cf6a74-d154-4e2f-9945-ba999b06f8bd"
  @skill_id "e7f2702c-5188-4d12-97b7-274162509ed1"
  @session_id "67227ae9-5750-428d-bf03-203f198faf3e"

  test "init schedules wake_up" do
    bot = %Bot{id: @bot_id}
    schedule = DateTime.utc_now |> Timex.shift(days: 1)
    skill = %Survey{id: @skill_id, schedule: schedule}

    with_mock BotManager, [schedule_wake_up: fn(_bot, _skill, _ts) -> :ok end] do
      skill |> Skill.init(bot)
      assert called BotManager.schedule_wake_up(bot, skill, schedule)
    end
  end

  test "init doesn't schedule wake_up if the survey is scheduled in the past" do
    bot = %Bot{id: @bot_id}
    skill = %Survey{id: @skill_id, schedule: DateTime.utc_now |> Timex.shift(days: -1)}

    with_mock BotManager, [schedule_wake_up: fn(_bot, _skill, _ts) -> :ok end] do
      skill |> Skill.init(bot)
      refute called BotManager.schedule_wake_up(:_, :_, :_)
    end
  end

  describe "wake_up" do
    setup :load_manifest_bot

    test "starts the survey", %{bot: bot} do
      channel = TestChannel.new()

      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}

        session = Session.new({bot.id, "facebook", "1234/5678"})
          |> Session.merge(%{"language" => "en"})
          |> Session.save

        session_id = session.id

        Bot.wake_up(bot, "food_preferences")

        assert_received {:send_message, ["I would like to ask you a few questions to better cater for your food preferences. Is that ok?"], ^session_id}

        session = Session.get(session_id)
        assert session |> Session.get_value(".survey/food_preferences") == %{"step" => 0}
      end
    end

    test "do not start the survey if the session doesn't have a language", %{bot: bot} do
      channel = TestChannel.new()

      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        bot = %{bot | channels: [channel]}
        Session.new({bot.id, "facebook", "1234/5678"}) |> Session.save

        Bot.wake_up(bot, "food_preferences")

        refute_received {:send_message, _, _}
      end
    end

    test "do not start the survey for not relevant sessions" do
      channel = TestChannel.new()
      manifest = File.read!("test/fixtures/valid_manifest_with_skill_relevances.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      bot = %{BotParser.parse!(@bot_id, manifest) | channels: [channel]}

      with_mock ChannelProvider, [find_channel: fn(_session_id) -> channel end] do
        Session.new({bot.id, "facebook", "1234/5678"})
          |> Session.merge(%{"language" => "en", "opt_in" => false})
          |> Session.save

        Bot.wake_up(bot, "food_preferences")

        refute_received {:send_message, _, _}
      end
    end

    test "starts the survey when a keyword matches", %{bot: bot} do
      channel = TestChannel.new()

      bot = %{bot | channels: [channel]}

      session = new_session({@session_id, %{"language" => "en"}}) |> Session.save

      message = Message.new("survey", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 0}
      assert message.reply == ["I would like to ask you a few questions to better cater for your food preferences. Is that ok?"]
    end

    test "accept user reply", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 0}}}) |> Session.save

      message = Message.new("Yes", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 1}
      assert message.reply == ["How old are you?"]
      assert message |> Message.get_session("survey/food_preferences/opt_in") == "yes"
    end

    test "accept user reply case insensitive", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 0}}}) |> Session.save

      message = Message.new("yes", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 1}
      assert message.reply == ["How old are you?"]
      assert message |> Message.get_session("survey/food_preferences/opt_in") == "yes"
    end

    test "invalid reply should retry the question", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 2}}}) |> Session.save

      message = Message.new("bananas", bot, session)
      message = Bot.chat(message)

      assert message.reply == ["Invalid temperature", "At what temperature do your like red wine the best?"]
      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 2}
    end

    test "unknown content should retry the question", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 4}}}) |> Session.save

      message = Message.new_unknown(bot, session)
      message = Bot.chat(message)
      assert message.reply == ["Can we see your home?"]
    end

    test "bot should answer a keyword even if survey is active on highest threshold", %{bot: bot} do
      bot = %{bot | front_desk: %{bot.front_desk | threshold: 0.5}}
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 2}}}) |> Session.save

      message = Message.new("hours", bot, session)
      message = Bot.chat(message)

      assert message.reply == ["We are open every day from 7pm to 11pm"]
      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 2}
    end

    test "accept user reply on select_many", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 3}}}) |> Session.save

      message = Message.new("merlot, syrah", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 4}
      assert message.reply == ["Can we see your home?"]
      assert message |> Message.get_session("survey/food_preferences/wine_grapes") == ["merlot", "syrah"]
    end

    test "clears the store to end the survey", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 5}}}) |> Session.save

      message = Message.new("No, thanks!", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == nil
    end

    test "skip questions when the relevant attribute evaluates to false", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 1}}}) |> Session.save

      message = Message.new("15", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 4}
      assert message.reply == ["Can we see your home?"]
    end

    test "do not skip questions when the relevant attribute evaluates to false", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 1}}}) |> Session.save

      message = Message.new("20", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 2}
      assert message.reply == ["At what temperature do your like red wine the best?"]
    end

    test "validate input responses and continue if the value is valid", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 2}}}) |> Session.save

      message = Message.new("20", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session("survey/food_preferences/wine_temp") == 20.0
      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 3}
      assert message.reply == ["What are your favorite wine grapes?"]
    end

    test "validate input responses and return constraint message when the value is invalid", %{bot: bot} do
      session = new_session({@session_id, %{"language" => "en", ".survey/food_preferences" => %{"step" => 2}}}) |> Session.save

      message = Message.new("200", bot, session)
      message = Bot.chat(message)

      assert message |> Message.get_session("survey/food_preferences/wine_temp") == nil
      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 2}
      assert message.reply == [
        "Invalid temperature",
        "At what temperature do your like red wine the best?"
      ]
    end
  end

  describe "encryption" do
    setup :load_manifest_bot
    setup :create_encrypted_survey
    setup :create_encrypted_survey_bot

    test "marks user reply as sensitive", %{survey: survey, bot: bot} do
      session =
        new_session(
          {@session_id,
           %{"language" => "en", ".survey/encrypted_question" => %{"step" => 0}}}
        )

      message = Skill.put_response(survey, Message.new("19", bot, session))

      assert message.sensitive == true
    end

    test "stores user reply encrypted in session", %{bot: bot, private: private} do
      session =
        new_session(
          {@session_id,
           %{"language" => "en", ".survey/encrypted_question" => %{"step" => 0}}}
        ) |> Session.save

      message = Message.new("19", bot, session)
      message = Bot.chat(message)

      json = message |> Message.get_session("survey/encrypted_question/age")

      assert Crypto.decrypt(json, private) == "19"
    end
  end

  describe "confidence" do
    test "return 0 if the survey is inactive and there are no keywords" do
      skill = %Survey{}
      message =
        Message.new("hello", %Bot{}, new_session({@session_id, %{}}))
        |> Message.put_session("language", "en")

      confidence = skill |> Skill.confidence(message)
      assert confidence == 0
    end

    test "return 0 if the survey is inactive and there are no keywords for the language" do
      skill = %Survey{keywords: %{}}
      message =
        Message.new("hello", %Bot{}, new_session({@session_id, %{}}))
        |> Message.put_session("language", "en")

      confidence = skill |> Skill.confidence(message)
      assert confidence == 0
    end
  end

  defp load_manifest_bot(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json")
      |> Poison.decode!()
      |> Map.put("languages", ["en"])

    {:ok, bot} = BotParser.parse(@bot_id, manifest)

    [bot: bot]
  end

  defp create_encrypted_survey(_context) do
    survey = %Survey{
      id: "encrypted_question",
      bot_id: @bot_id,
      name: "Food Preferences",
      schedule: ~N[2117-12-10 01:40:13] |> DateTime.from_naive!("Etc/UTC"),
      questions: [
        %InputQuestion{
          name: "age",
          type: :integer,
          encrypt: true,
          message: %{
            "en" => "How old are you?",
            "es" => "Qué edad tenés?"
          }
        }
      ]
    }

    [survey: survey]
  end

  defp create_encrypted_survey_bot(%{bot: bot, survey: survey}) do
    {private, public} = Kcl.generate_key_pair()

    bot = %{bot | skills: [ survey ], public_keys: [public]}

    [bot: bot, private: private]
  end
end
