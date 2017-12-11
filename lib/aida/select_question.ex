defmodule Aida.SelectQuestion do
  alias Aida.Message

  @type t :: %__MODULE__{
    type: :select_one | :select_many,
    choices: [Aida.Choice.t()],
    name: String.t(),
    message: Aida.Bot.message
  }
  @enforce_keys [:type]

  defstruct type: nil,
            choices: [],
            name: "",
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
      choices |> Enum.any?(fn(choice) ->
        choice.labels[language]
          |> Enum.map(&String.downcase/1)
          |> Enum.member?(response)
      end)
    end

    def accept_answer(_question, message) do
      message
    end
  end
end
