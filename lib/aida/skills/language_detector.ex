defmodule Aida.Skill.LanguageDetector do
  alias Aida.{
    Message,
    Message.TextContent
  }

  alias Aida.Skill.LanguageDetector.{
    AwsComprehend,
    UnsupportedLanguageMessage
  }

  import Aida.ErrorHandler

  @type t :: %__MODULE__{
          explanation: String.t(),
          bot_id: String.t(),
          languages: %{}
        }

  defstruct explanation: "",
            bot_id: "",
            languages: %{}

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot) do
      skill
    end

    def wake_up(_skill, _bot, _data) do
      :ok
    end

    def explain(_, message) do
      message
    end

    def clarify(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def put_response(skill, message) do
      matches = matching_languages(message, skill.languages)
      current_lang = Message.language(message)

      case {matches, current_lang} do
        {[], nil} ->
          try_to_detect_language_and_clarify(skill, message)

        {[], _} ->
          message

        {[lang | _], _} ->
          message
          |> Message.put_session("language", lang)
      end
    end

    def try_to_detect_language_and_clarify(skill, message) do
      detected_language = detect_language(message)

      case is_a_supported_language?(skill, detected_language) do
        true -> clarify(skill, message)
        _ -> unsupported_language(skill, message, detected_language)
      end
    end

    def detect_language(message) do
      try do
        detected_languages =
          message
          |> Message.text_content()
          |> AwsComprehend.detect_dominant_language()

        case detected_languages do
          [%{language: lang, score: score} | _] when score > 0.4 ->
            lang

          _ ->
            :not_understood
        end
      rescue
        error ->
          capture_exception(
            "Error trying to detect dominant language",
            error,
            message: Message.text_content(message),
            message_type: Message.type(message),
            session_uuid: message.session.uuid,
            bot_id: message.bot.id
          )
          :not_understood
      end
    end

    def is_a_supported_language?(%{languages: languages}, detected_language) do
      languages
      |> Map.keys()
      |> Enum.member?(detected_language)
    end

    def unsupported_language(%{explanation: explanation}, message, detected_language) do
      message
      |> Message.respond(UnsupportedLanguageMessage.for(detected_language))
      |> Message.respond(explanation)
    end

    def matching_languages(message, languages) do
      Message.words(message)
      |> Enum.reduce([], fn word, acc ->
        match =
          Map.keys(languages)
          |> Enum.find(fn language ->
            Enum.member?(languages[language], word)
          end)

        if match do
          Enum.concat(acc, [match])
        else
          acc
        end
      end)
    end

    def confidence(%{languages: languages}, %{content: %TextContent{}} = message) do
      words_in_message =
        Message.text_content(message)
        |> String.split()

      matches = matching_languages(message, languages)

      word_count = Enum.count(words_in_message)

      cond do
        !Message.language(message) -> 1
        Message.language(message) && word_count == 1 -> Enum.count(matches)
        true -> 0
      end
    end

    def confidence(_, _), do: 0

    def id(_) do
      "language_detector"
    end

    def relevant(_), do: nil

    def uses_encryption?(_), do: false
  end
end
