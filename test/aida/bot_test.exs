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
        "I can do a number of things"
      ]
    end
  end
end
