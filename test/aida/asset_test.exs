defmodule Aida.AssetTest do
  alias Aida.{
    Asset,
    Bot,
    BotParser,
    DB,
    Message,
    Repo
  }

  alias Aida.DB.{Session}

  use Aida.DataCase

  describe "wake_up" do
    setup :load_manifest_bot

    test "clears session data when survey starts", %{bot: bot, session: session} do
      session =
        session
        |> Session.merge(%{
          "language" => "en",
          "survey/food_preferences/request" => "No, thanks",
          "survey/food_preferences/wine_grapes" => ["merlot", "syrah"]
        })
        |> Session.save()

      message = Message.new("survey", bot, session)
      message = Bot.chat(message)

      assert message.reply == [
               "I would like to ask you a few questions to better cater for your food preferences.",
               "May I ask you now?"
             ]

      assert message |> Message.get_session(".survey/food_preferences") == %{"step" => 1}

      assert message |> Message.get_session("survey/food_preferences/request") == nil
      assert message |> Message.get_session("survey/food_preferences/wine_grapes") == nil
    end

    test "creates an asset when the survey ends and keeps the session data", %{
      bot: bot,
      session: %{id: session_id} = session
    } do
      session =
        session
        |> Session.merge(%{
          "language" => "en",
          ".survey/food_preferences" => %{"step" => 7},
          "survey/food_preferences/wine_grapes" => ["merlot", "syrah"]
        })
        |> Session.save()

      message = Message.new("No, thanks!", bot, session)
      message = Bot.chat(message)
      assert message.reply == ["Thank you!"]

      assert message |> Message.get_session(".survey/food_preferences") == nil

      assert message |> Message.get_session("survey/food_preferences/request") == "No, thanks!"

      assert message |> Message.get_session("survey/food_preferences/wine_grapes") == [
               "merlot",
               "syrah"
             ]

      assert %{
               skill_id: "food_preferences",
               session_id: ^session_id,
               data: %{
                 "survey/food_preferences/request" => "No, thanks!",
                 "survey/food_preferences/wine_grapes" => ["merlot", "syrah"]
               }
             } = Asset |> Repo.one()
    end
  end

  defp load_manifest_bot(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json")
      |> Poison.decode!()
      |> Map.put("languages", ["en"])

    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(db_bot.id, manifest)
    session = Session.new({bot.id, "facebook", "1234567890/0987654321"})

    [bot: bot, session: session]
  end
end
