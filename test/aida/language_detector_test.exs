defmodule Aida.LanguageDetectorTest do
  use Aida.DataCase
  alias Aida.{ Bot, FrontDesk, Skill.LanguageDetector, Skill, Message}

  @language_selection_explanation "Para hablar en español escribe 'español' o 'spanish'"
  @english_not_understood_message "Sorry, I don't speak English for now"
  @russian_not_understood_message "К сожалению, я не говорю по-русски сейчас"
  @generic_not_understood_message "Sorry, I didn't understand that"

  @uuid "2c20e05c-74e1-4b9b-923f-10b65a82dbd8"

  describe "multiple languages bot" do
    setup do
      skill = %LanguageDetector{
        explanation: @language_selection_explanation,
        bot_id: @uuid,
        languages: %{
          "es" => ["español", "spanish"]
        }
      }

      bot = %Bot{
        id: @uuid,
        languages: ["en", "es"],
        front_desk: %FrontDesk{ threshold: 0.3 },
        skills: [skill]
      }

      %{skill: skill, bot: bot}
    end

    test "sets the language when sending the correct keyword", %{skill: skill, bot: bot} do
      input = Message.new("spanish", bot)
      output = skill |> Skill.put_response(input)
      assert output.reply == []
      assert output |> Message.get_session("language") == "es"
    end

    test "answers with language explanation if the detected language is supported", %{skill: skill, bot: bot} do
      input = Message.new("que bien que anda esto", bot)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@language_selection_explanation]
    end

    test "answers not understood message if the language is not supported", %{skill: skill, bot: bot} do
      input = Message.new("detect this!", bot)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@english_not_understood_message, @language_selection_explanation]
    end

    test "translates not understood message to the detected language", %{skill: skill, bot: bot} do
      input = Message.new("Здравствуй!", bot)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@russian_not_understood_message, @language_selection_explanation]
    end

    test "responds with generic not understood if the language was not detected", %{skill: skill, bot: bot} do
      input = Message.new("hello", bot)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@generic_not_understood_message, @language_selection_explanation]
    end

    # test "answers not understood message in english if message cannot be translated" do
    # This only makes sense if we are using google translate online
    # end
  end
end
