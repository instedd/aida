defmodule Aida.Skill.KeywordResponder do
  alias Aida.Bot

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
    def explain(_skill, msg) do
      msg
    end

    def clarify(_skill, msg) do
      msg
    end
  end
end
