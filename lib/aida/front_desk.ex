defmodule Aida.FrontDesk do
  alias __MODULE__
  alias Aida.{Bot, Message, Skill, DB.SkillUsage}

  @type t :: %__MODULE__{
    threshold: float,
    greeting: Bot.message,
    introduction: Bot.message,
    not_understood: Bot.message,
    clarification: Bot.message,
  }

  defstruct threshold: 0.5,
            greeting: %{},
            introduction: %{},
            not_understood: %{},
            clarification: %{}

  def threshold(%FrontDesk{threshold: threshold}) do
    threshold
  end

  @spec greet(message :: Message.t, bot :: Bot.t) :: Message.t
  def greet(%Message{} = message, bot) do
    log_usage(bot.id, message.session.id)

    message
      |> Message.respond(bot.front_desk.greeting)
      |> introduction(bot)
  end

  @spec introduction(message :: Message.t, bot :: Bot.t) :: Message.t
  def introduction(message, bot) do
    message = message
      |> Message.respond(bot.front_desk.introduction)

    log_usage(bot.id, message.session.id)

    bot.skills
      |> Enum.reduce(message, fn(skill, message) ->
        !Bot.is_language_detector?(skill) && Skill.explain(skill, message) || message
      end)
  end

  def clarification(message, bot, skills) do
    message = message
      |> Message.respond(bot.front_desk.clarification)

    log_usage(bot.id, message.session.id)

    skills
      |> Enum.reduce(message, fn(skill, message) ->
        Skill.clarify(skill, message)
      end)
  end

  def not_understood(message, bot) do
    log_usage(bot.id, message.session.id)

    message
      |> Message.respond(bot.front_desk.not_understood)
      |> introduction(bot)
  end

  defp log_usage(bot_id, session_id) do
    SkillUsage.log_skill_usage(bot_id, "front_desk", session_id)
  end

end
