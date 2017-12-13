defmodule Aida.Skill.Survey do
  alias __MODULE__
  alias Aida.{BotManager, Repo, Session, Message, Channel, SurveyQuestion}
  alias Aida.DB.SkillUsage
  import Ecto.Query

  @type t :: %__MODULE__{
    id: String.t(),
    bot_id: String.t(),
    name: String.t(),
    schedule: DateTime.t,
    questions: [Aida.SelectQuestion.t() | Aida.InputQuestion.t()]
  }

  defstruct id: "",
            bot_id: "",
            name: "",
            schedule: DateTime.utc_now,
            questions: []

  def delay(skill, now \\ DateTime.utc_now) do
    DateTime.diff(skill.schedule, now, :milliseconds)
  end

  def start_survey(survey, bot, session_id) do
    channel = bot.channels |> hd()
    session = Session.load(session_id)

    if session |> Session.get("language") do
      session = session
        |> Session.put(state_key(survey), %{"step" => 0})

      message = answer(survey, Message.new("", session))

      user_id = session_id |> String.split("/") |> List.last
      channel |> Channel.send_message(message.reply, user_id)

      Session.save(message.session)
    end
  end

  def answer(survey, message) do
    case current_question(survey, message) do
      nil -> message
      question ->
        message |> Message.respond(question.message)
    end
  end

  def state_key(survey), do: "survey/#{survey.id}"
  def answer_key(survey, question), do: "#{state_key(survey)}/#{question.name}"

  def current_question(survey, message) do
    case message |> Message.get_session(state_key(survey)) do
      %{"step" => step} ->
        survey.questions |> Enum.at(step)
      _ -> nil
    end
  end

  def move_to_next_question(survey, message) do
    survey_state = case message |> Message.get_session(state_key(survey)) do
      %{"step" => step} = state ->
        if step + 1 >= Enum.count(survey.questions) do
          nil
        else
          %{state | "step" => step + 1}
        end
      _ -> %{"step" => 0}
    end

    message
    |> Message.put_session(state_key(survey), survey_state)
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, bot) do
      delay = Survey.delay(skill)
      if delay > 0 do
        BotManager.schedule_wake_up(bot, skill, delay)
      end

      skill
    end

    def wake_up(skill, %{id: bot_id} = bot) do
      SkillUsage
        |> where([s], s.bot_id == ^bot_id)
        |> distinct(true)
        |> select([s], s.user_id)
        |> Repo.all
        |> Enum.each(&(Survey.start_survey(skill, bot, &1)))

      :ok
    end

    def explain(%{}, message) do
      message
    end

    def clarify(%{}, message) do
      message
    end

    def put_response(survey, message) do
      question = Survey.current_question(survey, message)
      message = case SurveyQuestion.accept_answer(question, message) do
        :error -> message
        {:ok, answer} ->
          Survey.move_to_next_question(survey, message)
            |> Message.put_session(Survey.answer_key(survey, question), answer)
      end

      Survey.answer(survey, message)
    end

    def confidence(survey, message) do
      case Survey.current_question(survey, message) do
        nil -> 0
        question ->
          if question |> SurveyQuestion.valid_answer?(message) do
            1
          else
            :threshold
          end
      end
    end

    def id(%{id: id}) do
      id
    end
  end
end
