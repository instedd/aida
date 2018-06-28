defmodule Aida.FrontDesk do
  alias __MODULE__
  alias Aida.{Bot, Message, Skill, DB.SkillUsage, DB.Session}
  use Aida.ErrorLog

  @type t :: %__MODULE__{
    threshold: float,
    greeting: Bot.message,
    introduction: Bot.message,
    not_understood: Bot.message,
    clarification: Bot.message,
    unsubscribe: Bot.message
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

  @spec greet(message :: Message.t) :: Message.t
  def greet(%Message{} = message) do
    log_usage(message.bot.id, message.session.id)

    %{message.session | is_new: false} |> Session.save

    message
      |> Message.respond(message.bot.front_desk.greeting)
      |> introduction()

    end

  @spec introduction(message :: Message.t) :: Message.t
  def introduction(message) do
    message = message
      |> Message.respond(message.bot.front_desk.introduction)

    log_usage(message.bot.id, message.session.id)

    Bot.relevant_skills(message)
      |> Enum.reduce(message, fn(skill, message) ->
        ErrorLog.context(skill_id: Skill.id(skill)) do
          Skill.explain(skill, message)
        end
      end)
      |> unsubscribe()
  end

  def clarification(message, skills) do
    message = message
      |> Message.respond(message.bot.front_desk.clarification)

    log_usage(message.bot.id, message.session.id)

    skills
      |> Enum.reduce(message, fn(skill, message) ->
        ErrorLog.context(skill_id: Skill.id(skill)) do
          Skill.clarify(skill, message)
        end
      end)
  end

  def not_understood(message) do
    log_usage(message.bot.id, message.session.id)

    message
      |> Message.respond(message.bot.front_desk.not_understood)
      |> introduction()
  end

  @spec unsubscribe(message :: Message.t) :: Message.t
  def unsubscribe(message) do
    log_usage(message.bot.id, message.session.id)

    message
      |> Message.respond(message.bot.front_desk.unsubscribe)
  end

  defp log_usage(bot_id, session_id) do
    SkillUsage.log_skill_usage(bot_id, "front_desk", session_id)
  end
end