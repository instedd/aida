defmodule Aida.Skill.LanguageDetector do
  alias Aida.{Message, Message.TextContent}

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

    def wake_up(_skill, _bot) do
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
          clarify(skill, message)
        {[], _} ->
          message
        {[lang | _], _} ->
          message
          |> Message.put_session("language", lang)
      end
    end

    def matching_languages(message, languages) do
      Message.words(message)
      |> Enum.reduce([], fn(word, acc) ->
        match = Map.keys(languages) |> Enum.find(fn(language) ->
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
      words_in_message = Message.text_content(message)
      |> String.split

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
  end
end
