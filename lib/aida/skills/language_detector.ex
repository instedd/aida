defmodule Aida.Skill.LanguageDetector do
  alias Aida.{Bot, Message}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    languages: %{}
  }

  defstruct explanation: %{},
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

    def can_handle?(%{languages: languages}, message) do
      !Enum.empty?(matching_languages(message, languages))
    end

    def matching_languages(message, languages) do
      Message.content(message)
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

    def confidence(%{keywords: keywords}, message) do
      0
    end

    def id(_) do
      "language_detector"
    end
  end
end
