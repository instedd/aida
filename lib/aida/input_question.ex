defmodule Aida.InputQuestion do
  @type t :: %__MODULE__{
    type: :decimal | :integer | :text,
    name: String.t(),
    message: Aida.Bot.message
  }

  defstruct type: "",
            name: "",
            message: %{}

  defimpl Aida.SurveyQuestion, for: __MODULE__ do
    def valid_answer?(%{type: :integer}, message) do
      case Integer.parse(message.content) do
        :error -> false
        {int, ""} -> int >= 0
        _ -> false
      end
    end

    def valid_answer?(%{type: :decimal}, message) do
      case Float.parse(message.content) do
        :error -> false
        {_, ""} -> true
        _ -> false
      end
    end

    def valid_answer?(%{type: :text}, message) do
      String.trim(message.content) != ""
    end

    def accept_answer(_question, message) do
      message
    end
  end
end
