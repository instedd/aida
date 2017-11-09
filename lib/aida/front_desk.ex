defmodule Aida.FrontDesk do
  alias Aida.Bot

  @type t :: %__MODULE__{
    threshold: float,
    greeting: Bot.message,
    introduction: Bot.message,
    not_understood: Bot.message,
    clarification: Bot.message,
  }

  defstruct threshold: 0.5,
            greeting: %{},
            introduction: %{},
            not_understood: %{},
            clarification: %{}
end
