defmodule Aida.BotTest do
  alias Aida.{BotParser, Bot, Message}
  use ExUnit.Case

  @bot_id "486d6622-225a-42c6-864b-5457687adc30"
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
      {:ok, bot} = BotParser.parse(@bot_id, manifest)

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
      {:ok, bot} = BotParser.parse(@bot_id, manifest)

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

      input3 = Message.new( "english", output2.session)
      output3 = bot |> Bot.chat(input3)
      assert output3.reply == []

      input4 = Message.new( "hello", output3.session)
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
end
