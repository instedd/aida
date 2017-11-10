defmodule Aida.Skill.KeywordResponder do
  alias Aida.{Bot, Message}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    keywords: %{},
    response: %{}
  }

  defstruct explanation: %{},
            clarification: %{},
            keywords: %{},
            response: %{}

  defimpl Aida.Skill, for: __MODULE__ do
    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(_skill, message) do
      message
    end
  end
end
