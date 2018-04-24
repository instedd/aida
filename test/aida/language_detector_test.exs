defmodule Aida.LanguageDetectorTest do
  use Aida.DataCase
  use Aida.LogHelper
  use Aida.SessionHelper

  alias Aida.{
    Bot,
    FrontDesk,
    Skill.LanguageDetector,
    Skill,
    Message,
    Skill.LanguageDetector.AwsComprehend
  }

  import Mock

  @language_selection_explanation "Para hablar en español escribe 'español' o 'spanish'"
  @english_not_understood_message "Sorry, I don't speak English for now"
  @russian_not_understood_message "К сожалению, я не говорю по-русски сейчас"
  @generic_not_understood_message "Sorry, I didn't understand that"

  @bot_id "2c20e05c-74e1-4b9b-923f-10b65a82dbd8"

  setup do
    initial_session = new_session(Ecto.UUID.generate, %{})
    [initial_session: initial_session]
  end

  describe "unsupported language response bot" do
    setup :unsupported_language_response_skill
    setup :bot

    test "sets the language when sending the correct keyword", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("spanish", bot, initial_session)
      output = skill |> Skill.put_response(input)
      assert output.reply == []
      assert output |> Message.get_session("language") == "es"
    end

    test "answers with language explanation if the detected language is supported", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("que bien que anda esto", bot, initial_session)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@language_selection_explanation]
    end

    test "answers not understood message if the language is not supported", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Hi!", bot, initial_session)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@english_not_understood_message, @language_selection_explanation]
    end

    test "translates not understood message to the detected language", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("Здравствуй!", bot, initial_session)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@russian_not_understood_message, @language_selection_explanation]
    end

    test "responds with generic not understood if the language was not detected", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      without_logging do
        input = Message.new("qwertyui", bot, initial_session)
        output = skill |> Skill.put_response(input)
        assert output.reply == [@generic_not_understood_message, @language_selection_explanation]
      end
    end

    test "answers with generic not understood if message cannot be translated", %{
      bot: bot,
      skill: skill,
      initial_session: initial_session
    } do
      without_logging do
        with_mock AwsComprehend,
          detect_dominant_language: fn _ ->
            raise "Error contacting AWS"
          end do
          input = Message.new("hello", bot, initial_session)
          output = skill |> Skill.put_response(input)

          assert output.reply == [
                   @generic_not_understood_message,
                   @language_selection_explanation
                 ]
        end
      end
    end

    test "responds with generic not understood when the message is empty ", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      input = Message.new("", bot, initial_session)
      output = skill |> Skill.put_response(input)
      assert output.reply == [@generic_not_understood_message, @language_selection_explanation]
    end
  end

  describe "simple language response bot" do
    setup :simple_response_skill
    setup :bot

    test "responds with explanation and doesn't try to detect the language", %{
      skill: skill,
      bot: bot,
      initial_session: initial_session
    } do
      with_mock AwsComprehend,
        detect_dominant_language: fn _ ->
          assert false
        end do
        input = Message.new("qwertyui", bot, initial_session)
        output = skill |> Skill.put_response(input)
        assert output.reply == [@language_selection_explanation]
      end
    end
  end

  defp simple_response_skill(_context) do
    skill = %LanguageDetector{
      explanation: @language_selection_explanation,
      bot_id: @bot_id,
      languages: %{
        "es" => ["español", "spanish"]
      }
    }

    [skill: skill]
  end

  defp unsupported_language_response_skill(_context) do
    skill = %LanguageDetector{
      explanation: @language_selection_explanation,
      bot_id: @bot_id,
      languages: %{
        "es" => ["español", "spanish"]
      },
      reply_to_unsupported_language: true
    }

    [skill: skill]
  end

  defp bot(%{skill: skill}) do
    bot = %Bot{
      id: @bot_id,
      languages: ["en", "es"],
      front_desk: %FrontDesk{threshold: 0.3},
      skills: [skill]
    }

    [bot: bot]
  end
end
