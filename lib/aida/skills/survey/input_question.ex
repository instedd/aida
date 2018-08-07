defmodule Aida.Skill.Survey.InputQuestion do
  alias Aida.{Expr, Message, Message.ImageContent}

  @type t :: %__MODULE__{
          type: :decimal | :integer | :text | :image,
          name: String.t(),
          encrypt: boolean(),
          relevant: nil | Expr.t(),
          message: Aida.Bot.message(),
          constraint: nil | Expr.t(),
          constraint_message: nil | Aida.Bot.message()
        }

  defstruct type: "",
            name: "",
            relevant: nil,
            encrypt: false,
            message: %{},
            constraint: nil,
            constraint_message: nil

  defimpl Aida.Skill.Survey.Question, for: __MODULE__ do
    def valid_answer?(%{type: :integer}, message) do
      case Integer.parse(Message.text_content(message)) do
        :error -> false
        {int, ""} -> int >= 0
        _ -> false
      end
    end

    def valid_answer?(%{type: :decimal}, message) do
      case Float.parse(Message.text_content(message)) do
        :error -> false
        {_, ""} -> true
        _ -> false
      end
    end

    def valid_answer?(%{type: :text}, message) do
      String.trim(Message.text_content(message)) != ""
    end

    def valid_answer?(%{type: :image}, %{content: %ImageContent{}}) do
      true
    end

    def valid_answer?(%{type: :image}, _) do
      false
    end

    def accept_answer(%{type: :image}, %{content: %ImageContent{}} = message) do
      new_message = Message.pull_and_store_image(message)
      new_id = Message.image_content(new_message).image_id
      {:ok, %{type: :image, id: new_id}}
    end

    def accept_answer(%{type: :image}, _) do
      :error
    end

    def accept_answer(question, message) do
      case parse_answer(question, Message.text_content(message)) do
        {:ok, value} ->
          if validate_constraint(question, message, value) do
            {:ok, value}
          else
            :error
          end

        :error ->
          :error
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

        _ ->
          :error
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

    def validate_constraint(%{constraint: constraint}, message, value) do
      context = message |> Message.expr_context(self: value)
      Expr.eval(constraint, context)
    end

    def relevant(%{relevant: relevant}), do: relevant

    def encrypt?(%{encrypt: encrypt}), do: encrypt
  end
end
