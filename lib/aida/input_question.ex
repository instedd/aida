defmodule Aida.InputQuestion do
  @type t :: %__MODULE__{
    type: :decimal | :integer | :text,
    name: String.t,
    relevant: nil | Aida.Expr.t,
    message: Aida.Bot.message
  }

  defstruct type: "",
            name: "",
            relevant: nil,
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

    def accept_answer(%{type: :integer}, message) do
      case Integer.parse(message.content) do
        {int, ""} ->
          if int >= 0 do
            {:ok, int}
          else
            :error
          end
        _ -> :error
      end
    end

    def accept_answer(%{type: :decimal}, message) do
      case Float.parse(message.content) do
        {decimal, ""} -> {:ok, decimal}
        _ -> :error
      end
    end

    def accept_answer(%{type: :text}, message) do
      case String.trim(message.content) do
        "" -> :error
        text -> {:ok, text}
      end
    end
  end
end
