defmodule Aida.SkillUsageTest do
  use Aida.DataCase
  alias Aida.{BotParser, Bot, Message}
  # alias Aida.DB.SkillUsage
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

    test "stores an interaction per message", %{bot: bot} do
      input = Message.new("english")
      output = bot |> Bot.chat(input)
      assert Enum.count(DB.list_skill_usages()) == 1

      input2 = Message.new("español", output.session)
      bot |> Bot.chat(input2)
      assert Enum.count(DB.list_skill_usages()) == 2
    end
  end
end
