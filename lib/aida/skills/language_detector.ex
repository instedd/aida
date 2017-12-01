defmodule Aida.Skill.LanguageDetector do
  alias Aida.Message

  @type t :: %__MODULE__{
    explanation: String.t(),
    languages: %{}
  }

  defstruct explanation: "",
            languages: %{}

  defimpl Aida.Skill, for: __MODULE__ do
    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(_, message) do
      message
    end

    def respond(skill, message) do
      message
      |> Message.put_session("language", matching_languages(message, skill.languages) |> List.first)
    end

    def matching_languages(message, languages) do
      Message.curated_message(message)
      |> String.split
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

    def confidence(%{languages: languages}, message) do
      words_in_message = Message.content(message)
      |> String.split

      matches = matching_languages(message, languages)

      word_count = Enum.count(words_in_message)

      cond do
        Message.language(message) && word_count != 1 -> 0
        word_count == 0 -> 0
        true -> Enum.count(matches)/word_count
      end
    end

    def id(_) do
      "language_detector"
    end
  end
end
