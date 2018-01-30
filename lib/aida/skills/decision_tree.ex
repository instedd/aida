defmodule Aida.Skill.DecisionTree do
  alias __MODULE__
  alias Aida.{Bot, Message, Message.TextContent, Session, Skill.Utils}
  alias Aida.Skill.DecisionTree.{Question, Answer, Response}

  @type t :: %__MODULE__{
    id: String.t,
    bot_id: String.t,
    name: String.t,
    explanation: Bot.message,
    clarification: Bot.message,
    keywords: %{},
    relevant: nil | Aida.Expr.t,
    root_id: String.t,
    tree: [Question.t | Answer.t]
  }

  defstruct id: "",
            bot_id: "",
            name: "",
            explanation: %{},
            clarification: %{},
            keywords: %{},
            relevant: nil,
            root_id: "",
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

    def valid_answer?(question, message) do
      response = find_response(question, message)
      case response do
        nil -> false
        _ -> true
      end
    end

    def next_question_id(question, message) do
      response = find_response(question, message)
      case response do
        nil -> question.id
        _ -> response.next
      end
    end

    defp find_response(question, message) do
      downcase = String.downcase(Message.text_content(message))
      question.responses |> Enum.find(&Response.matches_string(&1, downcase))
    end
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

    def matches_string(response, string)do
      Enum.any?(Map.values(response.keywords), fn(x) ->
        Enum.member?(x, string)
      end)
    end
  end

  def get_message(%Question{} = question) do
    question.question
  end

  def get_message(%Answer{} = answer) do
    answer.message
  end


  def flatten(tree) do
    [{tree["id"], parse_question(tree)} | internal_flatten(tree["responses"])]
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
    %Response{keywords: downcase_keywords(response["keywords"]), next: response["next"]["id"]}
  end

  def parse_answer(answer) do
    %Answer{id: answer["id"], message: answer["answer"]}
  end

  def downcase_keywords(keywords) do
    keywords
      |> Enum.map(fn {k, v} ->
        {k, Enum.map(v, &String.downcase/1)}
      end)
      |> Enum.into(%{})
  end

  def state_key(decision_tree), do: ".decision_tree/#{decision_tree.id}"
  def answer_key(decision_tree, question), do: "#{state_key(decision_tree)}/#{question.id}"

  def current_question(decision_tree, message) do
    case message |> Message.get_session(state_key(decision_tree)) do
      %{"question" => question} ->
        decision_tree.tree[question]
      _ -> nil
    end
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot) do
      skill
    end

    def wake_up(_skill, _bot, _data) do
      :ok
    end

    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(%{clarification: clarification}, message) do
      message |> Message.respond(clarification)
    end

    def put_response(decision_tree, message) do
      question = DecisionTree.current_question(decision_tree, message)

      {next_question, message} = case question do
        nil ->
          session = message.session
          if session |> Session.get("language") do
            message = message
              |> Message.put_session(DecisionTree.state_key(decision_tree), %{"question" => decision_tree.root_id})

            {decision_tree.tree[decision_tree.root_id], message}
          end
        _ ->
          next_question = decision_tree.tree[Question.next_question_id(question, message)]
          message = case next_question do
            %Question{} -> message
              |> Message.put_session(DecisionTree.state_key(decision_tree), %{"question" => next_question.id})
            %Answer{} -> message
              |> Message.put_session(DecisionTree.state_key(decision_tree), nil)
            nil ->
              message
          end
          {next_question || question, message}
      end

      message |> Message.respond(DecisionTree.get_message(next_question))
    end

    def confidence(decision_tree, %{content: %TextContent{}} = message) do
      case DecisionTree.current_question(decision_tree, message) do
        nil ->
          Utils.confidence_for_keywords(decision_tree.keywords, message)
        question ->
          if question |> Question.valid_answer?(message) do
            1
          else
            :threshold
          end
      end
    end

    def confidence(_, _), do: 0

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant
  end
end
