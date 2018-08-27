defmodule Aida.FrontDesk do
  alias __MODULE__

  alias Aida.{
    Bot,
    Message,
    Message.TextContent,
    Skill,
    DB.SkillUsage,
    DB.Session,
    Unsubscribe,
    Skill.Utils
  }

  use Aida.ErrorLog

  @type t :: %__MODULE__{
          threshold: float,
          greeting: Bot.message(),
          introduction: Bot.message(),
          not_understood: Bot.message(),
          clarification: Bot.message(),
          unsubscribe: Unsubscribe.t()
        }

  defstruct threshold: 0.5,
            greeting: %{},
            introduction: %{},
            not_understood: %{},
            clarification: %{},
            unsubscribe: %{}

  def threshold(%FrontDesk{threshold: threshold}) do
    threshold
  end

  @spec greet(message :: Message.t()) :: Message.t()
  def greet(%Message{} = message) do
    %{message.session | is_new: false} |> Session.save()

    message
    |> Message.respond(message.bot.front_desk.greeting)
    |> introduction()
  end

  @spec introduction(message :: Message.t()) :: Message.t()
  def introduction(message) do
    log_usage(message.bot.id, message.session.id)

    message
    |> Message.respond(message.bot.front_desk.introduction)
    |> skills_intro
    |> Message.respond(message.bot.front_desk.unsubscribe.introduction_message)
  end

  @spec skills_intro(message :: Message.t()) :: Message.t()
  defp skills_intro(message) do
    Bot.relevant_skills(message)
    |> Enum.reduce(message, fn skill, message ->
      ErrorLog.context skill_id: Skill.id(skill) do
        Skill.explain(skill, message)
      end
    end)
  end

  def clarification(message, skills) do
    message =
      message
      |> Message.respond(message.bot.front_desk.clarification)

    log_usage(message.bot.id, message.session.id)

    skills
    |> Enum.reduce(message, fn skill, message ->
      ErrorLog.context skill_id: Skill.id(skill) do
        Skill.clarify(skill, message)
      end
    end)
  end

  def not_understood(message) do
    message
    |> Message.respond(message.bot.front_desk.not_understood)
    |> introduction()
  end

  defp log_usage(bot_id, session_id) do
    SkillUsage.log_skill_usage(bot_id, "front_desk", session_id)
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot), do: skill

    def clear_state(_skill, message), do: message

    def wake_up(_skill, _bot, _data), do: :ok

    def explain(_explanation, message), do: message

    def clarify(%{unsubscribe: %{introduction_message: introduction_message}}, message) do
      message |> Message.respond(introduction_message)
    end

    def put_response(%{unsubscribe: %{acknowledge_message: acknowledge_message}}, message) do
      message |> Message.set_session_do_not_disturb!(true) |> Message.respond(acknowledge_message)
    end

    def confidence(%{unsubscribe: %{keywords: keywords}}, %{content: %TextContent{}} = message) do
      Utils.confidence_for_keywords(keywords, message)
    end

    def confidence(_, _), do: 0

    def id(_), do: "front_desk"

    def relevant(skill), do: skill.relevant

    def uses_encryption?(_), do: false

    def training_sentences(_), do: nil
  end
end
