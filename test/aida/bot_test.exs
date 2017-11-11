defmodule Aida.BotTest do
  alias Aida.{BotParser, Bot, Message}
  use ExUnit.Case

  @bot_id "486d6622-225a-42c6-864b-5457687adc30"

  describe "single language bot" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])
      bot = BotParser.parse(@bot_id, manifest)

      %{bot: bot}
    end

    test "replies with greeting on the first message", %{bot: bot} do
      input = Message.new("Hi!")
      output = bot |> Bot.chat(input)
      assert output.reply == [
        "Hello, I'm a Restaurant bot",
        "I can do a number of things",
        "I can give you information about our menu",
        "I can give you information about our opening hours"
      ]
    end

    test "replies with explanation when message not understood and is not the first message", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("foobar", response.session))
      assert output.reply == [
        "Sorry, I didn't understand that",
        "I can do a number of things",
        "I can give you information about our menu",
        "I can give you information about our opening hours"
      ]
    end

    test "replies with clarification when message matches more than one skill", %{bot: bot} do
      response = bot |> Bot.chat(Message.new("Hi!"))
      output = bot |> Bot.chat(Message.new("food hours", response.session))
      assert output.reply == [
        "I'm not sure exactly what you need.",
        "For menu options, write 'menu'",
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
end
