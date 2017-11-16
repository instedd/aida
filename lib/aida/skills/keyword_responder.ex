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
  end
end
