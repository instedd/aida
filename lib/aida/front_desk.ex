defmodule Aida.FrontDesk do
  alias __MODULE__
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

  def threshold(%FrontDesk{threshold: threshold}) do
    threshold
  end
end
