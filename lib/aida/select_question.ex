defmodule Aida.SelectQuestion do
  alias Aida.{Message, Choice}

  @type t :: %__MODULE__{
    type: :select_one | :select_many,
    choices: [Aida.Choice.t],
    name: String.t,
    relevant: nil | Aida.Expr.t,
    message: Aida.Bot.message
  }
  @enforce_keys [:type]

  defstruct type: nil,
            choices: [],
            name: "",
            relevant: nil,
            message: %{}

  defimpl Aida.SurveyQuestion, for: __MODULE__ do
    def valid_answer?(%{type: :select_one} = question, message) do
      language = message |> Message.language()
      response = message.content |> String.downcase

      choice_exists?(question.choices, response, language)
    end

    def valid_answer?(%{type: :select_many} = question, message) do
      language = message |> Message.language()
      responses = message.content |> String.downcase |> String.split(",") |> Enum.map(&String.trim/1)

      responses |> Enum.all?(fn(response) ->
        choice_exists?(question.choices, response, language)
      end)
    end

    def choice_exists?(choices, response, language) do
      find_choice(choices, response, language) != nil
    end

    def find_choice(choices, response, language) do
      choices |> Enum.find(fn(choice) ->
        choice.labels[language]
          |> Enum.map(&String.downcase/1)
          |> Enum.member?(response)
      end)
    end

    def accept_answer(%{type: :select_one} = question, message) do
      if question |> valid_answer?(message) do
        language = message |> Message.language()
        response = message.content |> String.downcase

        choice = find_choice(question.choices, response, language)
        |> Choice.name

        {:ok, choice}
      else
        :error
      end
    end

    def accept_answer(%{type: :select_many} = question, message) do
      if question |> valid_answer?(message) do
        language = message |> Message.language()
        responses = message.content |> String.downcase |> String.split(",") |> Enum.map(&String.trim/1)

        choices = responses |> Enum.map(fn(response) ->
          find_choice(question.choices, response, language)
          |> Choice.name
        end)
        {:ok, choices}
      else
        :error
      end
    end

    def relevant(%{relevant: relevant}), do: relevant
  end
end
