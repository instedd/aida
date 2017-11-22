defmodule Aida.Skill.KeywordResponder do
  alias Aida.{Bot, Message}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    id: String.t(),
    name: String.t(),
    keywords: %{},
    response: %{}
  }

  defstruct explanation: %{},
            clarification: %{},
            id: "",
            name: "",
            keywords: %{},
            response: %{}

  defimpl Aida.Skill, for: __MODULE__ do
    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(%{clarification: clarification}, message) do
      message |> Message.respond(clarification)
    end

    def respond(%{response: response}, message) do
      message |> Message.respond(response)
    end

    def can_handle?(%{keywords: keywords}, message) do
      Message.content(message)
      |> String.split
      |> Enum.any?(fn(word) ->
        Enum.member?(keywords[Message.language(message)], word)
      end)
    end

    def confidence(%{keywords: keywords}, message) do
      words_in_message = String.replace(Message.content(message), ~r/\p{P}/, "")
      |> String.split

      matches = words_in_message
      |> Enum.filter(fn(word) ->
        Enum.member?(keywords[Message.language(message)], word)
      end)

      word_count = Enum.count(words_in_message)
      case word_count do
        0 -> 0
        _ ->Enum.count(matches)/word_count
      end
    end

    def id(%{id: id}) do
      id
    end
  end
end
