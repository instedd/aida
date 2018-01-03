defmodule Aida.InputQuestion do
  alias Aida.{Session, Expr}

  @type t :: %__MODULE__{
    type: :decimal | :integer | :text,
    name: String.t,
    relevant: nil | Expr.t,
    message: Aida.Bot.message,
    constraint: nil | Expr.t,
    constraint_message: nil | Aida.Bot.message
  }

  defstruct type: "",
            name: "",
            relevant: nil,
            message: %{},
            constraint: nil,
            constraint_message: nil

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

    def accept_answer(question, message) do
      case parse_answer(question, message.content) do
        {:ok, value} ->
          if validate_constraint(question, message.session, value) do
            {:ok, value}
          else
            :error
          end
        :error -> :error
      end
    end

    def parse_answer(%{type: :integer}, answer) do
      case Integer.parse(answer) do
        {int, ""} ->
          if int >= 0 do
            {:ok, int}
          else
            :error
          end
        _ -> :error
      end
    end

    def parse_answer(%{type: :decimal}, answer) do
      case Float.parse(answer) do
        {decimal, ""} -> {:ok, decimal}
        _ -> :error
      end
    end

    def parse_answer(%{type: :text}, answer) do
      case String.trim(answer) do
        "" -> :error
        text -> {:ok, text}
      end
    end

    def validate_constraint(%{constraint: nil}, _, _), do: true

    def validate_constraint(%{constraint: constraint}, session, value) do
      context = session |> Session.expr_context(self: value)
      Expr.eval(constraint, context)
    end

    def relevant(%{relevant: relevant}), do: relevant
  end
end
