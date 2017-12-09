defmodule Aida.BotTest do
  use Aida.DataCase
  alias Aida.{BotParser, Bot, Message, DB, Skill, TestChannel, Session, SessionStore}
  use ExUnit.Case

  @english_restaurant_greet [
    "Hello, I'm a Restaurant bot",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours"
  ]

  @english_not_understood [
    "Sorry, I didn't understand that",
    "I can do a number of things",
    "I can give you information about our menu",
    "I can give you information about our opening hours"
  ]

  @spanish_not_understood [
    "Perdón, no entendí lo que dijiste",
    "Puedo ayudarte con varias cosas",
    "Te puedo dar información sobre nuestro menu",
    "Te puedo dar información sobre nuestro horario"
  ]

  @spanish_restaurant_greet [
    "Hola, soy un bot de Restaurant",
    "Puedo ayudarte con varias cosas",
    "Te puedo dar información sobre nuestro menu",
    "Te puedo dar información sobre nuestro horario"
  ]

  @language_selection_speech [
    "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'"
  ]

  describe "single language bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_single_lang.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "replies with greeting on the first message", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @english_restaurant_greet
    end

    test "replies with explanation when message not understood and is not the first message", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("foobar", response.session))
      assert output.reply == @english_not_understood
    end

    test "replies with clarification when message matches more than one skill and similar confidence", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("food hours", response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For menu options, write 'menu'",
        "For opening hours say 'hours'"
      ]
    end

    test "replies with the skill with more confidence when message matches more than one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("Want time food hours", response.session))
      assert output.reply == [
        "We are open every day from 7pm to 11pm"
      ]
    end

    test "replies with clarification when message matches only one skill but with low confidence", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("I want to know the opening hours for this restaurant", response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For opening hours say 'hours'"
      ]
    end

    test "replies with skill when message matches one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("hours", response.session))
      assert output.reply == [
        "We are open every day from 7pm to 11pm"
      ]
    end
  end

  describe "multiple languages bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "replies with language selection on the first message", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech
    end

    test "selects language when the user sends 'english'", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español'", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "after selecting language it doesn't switch when a phrase includes a different one", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new( "no se hablar english", output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == @spanish_not_understood

    end

    test "after selecting language only switches when just the new language is received", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("english", output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == []

      input4 = Message.new("hello", output3.session)
      output4 = bot |> Bot.chat(input4)
      assert output4.reply == @english_not_understood
    end

    test "selects language when the user sends 'english' in a long sentence", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english please")
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español' in a long sentence", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Quiero hablar en español por favor")
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects language when the user sends 'español' followed by a question mark", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Puedo hablar en español?")
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects the first language when the user sends more than one", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english or spanish o inglés")
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "replies language selection when the user selects a not available language ", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("eu quero falar português", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @language_selection_speech
    end
  end

  describe "scheduled bot" do
    setup do
      SessionStore.start_link

      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!

      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)
      {:ok, bot} = Bot.init(bot)

      %{bot: bot}
    end

    test "sends a message after 3 days", %{bot: bot} do
      channel = TestChannel.new(fn(messages, recipient) ->
        assert messages == ["Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?"]
        assert recipient == "1234"
      end)
      bot = %{bot | channels: [channel]}

      input = Message.new("Hi!", Session.new("test/#{bot.id}/1234"))
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet

      Session.save(output2.session)

      # set the last message time to 3 days back so it falls into the schedule
      DB.create_skill_usage(%{
        bot_id: bot.id,
        user_id: "1234",
        last_usage: Timex.shift(DateTime.utc_now(), days: -3),
        skill_id: (hd(bot.skills) |> Skill.id()),
        user_generated: true
      })

      # force the recurrent function timer so it sends the scheduled message now and we don't have to wait
      Bot.wake_up(bot, "inactivity_check")
    end

    test "sends a message after a month", %{bot: bot} do
      channel = TestChannel.new(fn(messages, recipient) ->
        assert messages == ["Hey, I didn’t hear from you for the last month, is there anything I can help you with?"]
        assert recipient == "1234"
      end)
      bot = %{bot | channels: [channel]}

      input = Message.new("Hi!", Session.new("test/#{bot.id}/1234"))
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet

      Session.save(output2.session)

      # set the last message time to 3 days back so it falls into the schedule
      DB.create_skill_usage(%{
        bot_id: bot.id,
        user_id: "1234",
        last_usage: Timex.shift(DateTime.utc_now(), month: -2),
        skill_id: (hd(bot.skills) |> Skill.id()),
        user_generated: true
      })

      # force the recurrent function timer so it sends the scheduled message now and we don't have to wait
      Bot.wake_up(bot, "inactivity_check")
    end

    test "doesn't send a message if the timer is not yet overdue", %{bot: bot} do
      channel = TestChannel.new(fn(_messages, _recipient) ->
        # if the message is sent we did something wrong
        assert false
      end)
      bot = %{bot | channels: [channel]}

      input = Message.new("Hi!", Session.new("test/#{bot.id}/1234"))
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet

      Session.save(output2.session)

      # set the last message time to now so it doesn't fall into the schedule
      DB.create_skill_usage(%{
        bot_id: bot.id,
        user_id: "1234",
        last_usage: DateTime.utc_now(),
        skill_id: (hd(bot.skills) |> Skill.id()),
        user_generated: true
      })

      # force the recurrent function timer so it sends the scheduled message now and we don't have to wait
      Bot.wake_up(bot, "inactivity_check")
    end

    test "doesn't send a message if the reminder has already been sent", %{bot: bot} do
      channel = TestChannel.new(fn(_messages, _recipient) ->
        # if the message is sent we did something wrong
        assert false
      end)
      bot = %{bot | channels: [channel]}

      input = Message.new("Hi!", Session.new("test/#{bot.id}/1234"))
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet

      Session.save(output2.session)

      DB.create_skill_usage(%{
        bot_id: bot.id,
        user_id: "1234",
        last_usage: Timex.shift(DateTime.utc_now(), days: -3),
        skill_id: (hd(bot.skills) |> Skill.id()),
        user_generated: true
      })

      # set the reminder as sent
      DB.create_skill_usage(%{
        bot_id: bot.id,
        user_id: "1234",
        last_usage: Timex.shift(DateTime.utc_now(), days: -1),
        skill_id: "inactivity_check",
        user_generated: false
      })

      # force the recurrent function timer so it sends the scheduled message now and we don't have to wait
      Bot.wake_up(bot, "inactivity_check")
    end
  end
end
