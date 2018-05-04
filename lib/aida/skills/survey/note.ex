defmodule Aida.Skill.Survey.Note do
  alias Aida.{Expr}

  @type t :: %__MODULE__{
          type: :note,
          name: String.t(),
          relevant: nil | Expr.t(),
          message: Aida.Bot.message()
        }

  defstruct type: "",
            name: "",
            relevant: nil,
            message: %{}

  defimpl Aida.Skill.Survey.Question, for: __MODULE__ do
    def valid_answer?(_, _) do
      false
    end

    def accept_answer(_, _) do
      :error
    end

    def relevant(%{relevant: relevant}), do: relevant

    def encrypt?(_), do: false
  end
end
