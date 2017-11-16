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

    def respond(%{response: response}, message) do
      message |> Message.respond(response)
    end


    def can_handle?(%{languages: languages}, message) do
      Message.content(message)
      |> String.split
      |> Enum.any?(fn(word) ->
        # Enum.member?(languages[Message.language(message)], word)
        languages |> Enum.any?(fn(language) ->
          Enum.member?(language, word)
        end)
      end)
    end
  end
end
