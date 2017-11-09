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
end
