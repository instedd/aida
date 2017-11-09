defmodule Aida.Skill.KeywordResponder do
  alias Aida.Bot

  defmodule Response do
    defstruct keywords: %{}, response: %{}
  end

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    responses: []
  }

  defstruct explanation: %{},
            clarification: %{},
            responses: []
end
