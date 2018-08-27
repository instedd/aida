defmodule Aida.Skill.Survey do
  alias __MODULE__
  alias __MODULE__.{Question, SelectQuestion, InputQuestion}
  alias Aida.{Bot, BotManager, Message, Skill.Survey.Question, Skill, Skill.Utils}
  alias Aida.DB.{Session}
  import Aida.ErrorHandler

  @type t :: %__MODULE__{
          id: String.t(),
          bot_id: String.t(),
          name: String.t(),
          schedule: DateTime.t(),
          relevant: nil | Aida.Expr.t(),
          keywords: nil | %{},
          training_sentences: nil | %{},
          questions: [SelectQuestion.t() | InputQuestion.t()]
        }

  defstruct id: "",
            bot_id: "",
            name: "",
            schedule: nil,
            relevant: nil,
            keywords: nil,
            training_sentences: nil,
            questions: []

  def scheduled_start_survey(survey, bot, session_id) do
    session = Session.get(session_id)
    message = Message.new("", bot, session)

    if Skill.is_relevant?(survey, message) do
      if session |> Session.get_value("language") do
        message = Message.clear_state(message)
        message = start_survey(survey, message)

        try do
          Bot.send_message(message)
        rescue
          error ->
            capture_exception(
              "Error starting survey",
              error,
              bot_id: bot.id,
              skill_id: survey.id,
              session_id: session.id
            )
        end
      end
    end
  end

  def start_survey(survey, message) do
    message =
      message
      |> Message.drop_session(prefix(survey))
      |> Message.put_session(state_key(survey), %{"step" => 0})

    answer(survey, message)
  end

  def answer(survey, message) do
    case current_question(survey, message) do
      nil ->
        message

      %{type: :note} = question ->
        message = message |> Message.respond(question.message)
        message = move_to_next_question(survey, message)
        answer(survey, message)

      question ->
        message |> Message.respond(question.message)
    end
  end

  defp prefix(%{id: id}), do: "survey/#{id}"
  def state_key(survey), do: ".#{prefix(survey)}"
  def answer_key(survey, question), do: "#{prefix(survey)}/#{question.name}"

  def current_question(survey, message) do
    case message |> Message.get_session(state_key(survey)) do
      %{"step" => step} ->
        survey.questions |> Enum.at(step)

      _ ->
        nil
    end
  end

  def move_to_next_question(survey, message) do
    survey_state =
      case message |> Message.get_session(state_key(survey)) do
        %{"step" => step} = state ->
          case find_next_question(survey, message, step) do
            nil ->
              Message.extract_to_asset(message, prefix(survey), survey.id)
              nil

            step ->
              %{state | "step" => step}
          end

        _ ->
          %{"step" => 0}
      end

    message
    |> Message.put_session(state_key(survey), survey_state)
  end

  defp find_next_question(survey, message, step) do
    step = step + 1

    if step >= Enum.count(survey.questions) do
      nil
    else
      question = survey.questions |> Enum.at(step)

      if question.relevant == nil do
        step
      else
        context = message |> Message.expr_context()
        relevant = question |> Question.relevant() |> Aida.Expr.eval(context)

        if relevant == false do
          find_next_question(survey, message, step)
        else
          step
        end
      end
    end
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(%{schedule: nil} = skill, _), do: skill

    def init(skill, bot) do
      if DateTime.compare(skill.schedule, DateTime.utc_now()) == :gt do
        BotManager.schedule_wake_up(bot, skill, skill.schedule)
      end

      skill
    end

    def wake_up(skill, %{id: bot_id} = bot, _data) do
      Session.session_ids_by_bot(bot_id)
      |> Enum.each(&Survey.scheduled_start_survey(skill, bot, &1))

      :ok
    end

    def explain(%{}, message) do
      message
    end

    def clarify(%{}, message) do
      message
    end

    def clear_state(survey, message) do
      Message.put_session(message, Survey.state_key(survey), nil)
    end

    def put_response(survey, message) do
      question = Survey.current_question(survey, message)

      if question do
        message =
          if question.encrypt do
            message |> Message.mark_sensitive()
          else
            message
          end

        message =
          case Question.accept_answer(question, message) do
            :error ->
              if question.constraint_message do
                message |> Message.respond(question.constraint_message)
              else
                message
              end

            {:ok, answer} ->
              message =
                Message.put_session(
                  message,
                  Survey.answer_key(survey, question),
                  answer,
                  encrypted: question |> Question.encrypt?()
                )

              Survey.move_to_next_question(survey, message)
          end

        Survey.answer(survey, message)
      else
        Survey.start_survey(survey, message)
      end
    end

    def confidence(survey, message) do
      case Survey.current_question(survey, message) do
        nil ->
          if survey.keywords do
            Utils.confidence_for_keywords(survey.keywords, message)
          else
            0
          end

        question ->
          if question |> Question.valid_answer?(message) do
            1
          else
            :threshold
          end
      end
    end

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant

    def uses_encryption?(%{questions: questions}) do
      questions |> Enum.any?(&Question.encrypt?/1)
    end
  end
end
