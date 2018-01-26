defmodule Aida.Skill.DecisionTree do
  alias __MODULE__
  alias Aida.Skill.DecisionTree.{Question, Answer, Response}

  @type t :: %__MODULE__{
    id: String.t,
    bot_id: String.t,
    name: String.t,
    relevant: nil | Aida.Expr.t,
    tree: [Question.t | Answer.t]
  }

  defstruct id: "",
            bot_id: "",
            name: "",
            relevant: nil,
            tree: %{}

  defmodule Question do
    @type t :: %__MODULE__{
      id: String.t,
      question: Aida.Bot.message,
      responses: [Response.t]
    }

    defstruct id: "",
              question: %{},
              responses: []
  end

  defmodule Answer do
    @type t :: %__MODULE__{
      id: String.t,
      message: Aida.Bot.message
    }

    defstruct id: "",
              message: %{}
  end

  defmodule Response do
    @type t :: %__MODULE__{
      keywords: %{},
      next: String.t
    }

    defstruct keywords: %{},
              next: ""
  end


  def flatten(tree) do
    [{"root", parse_question(tree)} | internal_flatten(tree["responses"])]
      |> Enum.into(%{})
  end

  defp internal_flatten([_ | _] = responses) do
    responses |> Enum.map(fn response ->
      internal_flatten(response["next"])
    end)
      |> List.flatten()
  end

  defp internal_flatten(%{"answer" => _} = answer) do
    {answer["id"], parse_answer(answer)}
  end

  defp internal_flatten(question) do
    [{question["id"], parse_question(question)} | internal_flatten(question["responses"])]
  end

  def parse_question(question) do
    %Question{id: question["id"], question: question["question"], responses: parse_responses(question["responses"])}
  end

  def parse_responses(responses) do
    responses |> Enum.map(fn response ->
      parse_response(response)
    end)
  end

  def parse_response(response) do
    %Response{keywords: response["keywords"], next: response["next"]["id"]}
  end

  def parse_answer(answer) do
    %Answer{id: answer["id"], message: answer["answer"]}
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, bot) do
      skill
    end

    def wake_up(_skill, _bot, _data) do
      :ok
    end

    def explain(%{}, message) do
      message
    end

    def clarify(%{}, message) do
      message
    end

    def put_response(survey, message) do
      message
    end

    def confidence(survey, message) do
      0
    end

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant
  end
end
