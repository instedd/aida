defmodule Aida.BotTest do
  use Aida.DataCase
  alias Aida.{BotParser, Bot, Message, DB, Session}

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
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @english_restaurant_greet
    end

    test "replies with explanation when message not understood and is not the first message", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("foobar", bot, response.session))
      assert output.reply == @english_not_understood
    end

    test "replies with clarification when message matches more than one skill and similar confidence", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("food hours", bot, response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For menu options, write 'menu'",
        "For opening hours say 'hours'"
      ]
    end

    test "replies with the skill with more confidence when message matches more than one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("Want time food hours", bot, response.session))
      assert output.reply == [
        "We are open every day from 7pm to 11pm"
      ]
    end

    test "replies with clarification when message matches only one skill but with low confidence", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("I want to know the opening hours for this restaurant", bot, response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For opening hours say 'hours'"
      ]
    end

    test "replies with skill when message matches one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!", bot))
      output = bot |> Bot.chat(Message.new("hours", bot, response.session))
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
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech
    end

    test "selects language when the user sends 'english'", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("english", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español'", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "after selecting language it doesn't switch when a phrase includes a different one", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("no se hablar english", bot, output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == @spanish_not_understood

    end

    test "after selecting language only switches when just the new language is received", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("español", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet

      input3 = Message.new("english", bot, output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == []

      input4 = Message.new("hello", bot, output3.session)
      output4 = bot |> Bot.chat(input4)
      assert output4.reply == @english_not_understood
    end

    test "selects language when the user sends 'english' in a long sentence", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english please", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "selects language when the user sends 'español' in a long sentence", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Quiero hablar en español por favor", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects language when the user sends 'español' followed by a question mark", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("Puedo hablar en español?", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @spanish_restaurant_greet
    end

    test "selects the first language when the user sends more than one", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("I want to speak in english or spanish o inglés", bot)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @english_restaurant_greet
    end

    test "replies language selection when the user selects a not available language ", %{bot: bot} do
      input = Message.new("Hi!", bot)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech

      input2 = Message.new("eu quero falar português", bot, output.session)
      output2 = bot |> Bot.chat(input2)
      assert output2.reply == @language_selection_speech
    end

    test "reset language when the session already has a language not understood by the bot", %{bot: bot} do
      session = Session.new("sid", %{"language" => "jp"})
      input = Message.new("Hi!", bot, session)
      output = bot |> Bot.chat(input)
      assert output.reply == @language_selection_speech
      assert output |> Message.get_session("language") == nil
    end
  end

  describe "bot with skill relevances" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_with_skill_relevances.json")
        |> Poison.decode!
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "introduction message includes only relevant skills", %{bot: bot} do
      session = Session.new("sid", %{"language" => "en", "age" => 14})
      input = Message.new("Hi!", bot, session)
      output = bot |> Bot.chat(input)

      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our opening hours"
      ]
    end

    test "only relevant skills receive the message", %{bot: bot} do
      session = Session.new("sid", %{"language" => "en", "age" => 14})
      input = Message.new("menu", bot, session)
      output = bot |> Bot.chat(input)

      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our opening hours"
      ]
    end

    test "relevance expressions containing undefined variables are considered false", %{bot: bot} do
      session = Session.new("sid", %{"language" => "en"})
      input = Message.new("menu", bot, session)
      output = bot |> Bot.chat(input)

      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our opening hours"
      ]
    end
  end

  describe "bot variables" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
      {:ok, bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(bot.id, manifest)

      %{bot: bot}
    end

    test "lookup", %{bot: bot} do
      session = Session.new("sid")
      value = bot |> Bot.lookup_var(session, "food_options")
      assert value["en"] == "barbecue and pasta"
    end

    test "lookup non existing variable returns nil", %{bot: bot} do
      session = Session.new("sid")
      value = bot |> Bot.lookup_var(session, "foo")
      assert value == nil
    end

    test "lookup variabe evaluate overrides", %{bot: bot} do
      session = Session.new("sid", %{"age" => 20})
      value = bot |> Bot.lookup_var(session, "food_options")
      assert value["en"] == "barbecue and pasta and a exclusive selection of wines"

      session = Session.new("sid", %{"age" => 15})
      value = bot |> Bot.lookup_var(session, "food_options")
      assert value["en"] == "barbecue and pasta"
    end
  end
end
