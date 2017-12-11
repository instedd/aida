defmodule Aida.Skill.Survey do
  alias __MODULE__
  alias Aida.{BotManager, Repo, Session, Message, Channel}
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
      |> Session.put("survey/#{survey.id}", %{"step" => 0})

    question = survey.questions |> hd()
    message = Message.new("", session)
      |> Message.respond(question.message)

    user_id = session_id |> String.split("/") |> List.last
    channel |> Channel.send_message(message.reply, user_id)

    Session.save(session)
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, bot) do
      time = Survey.delay(skill)
      message = BotManager.wake_up_message(bot, skill)
      Process.send_after(self(), message, time)

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
      state_key = "survey/#{survey.id}"
      survey_state = message |> Message.get_session(state_key)
      survey_state = %{survey_state | "step" => survey_state["step"] + 1}

      question = survey.questions |> Enum.at(survey_state["step"])

      message
        |> Message.put_session(state_key, survey_state)
        |> Message.respond(question.message)
    end

    def confidence(survey, message) do
      case message |> Message.get_session(state_key(survey)) do
        nil -> 0
        _ -> 1
      end
    end

    def id(%{id: id}) do
      id
    end

    defp state_key(survey), do: "survey/#{survey.id}"
  end
end
