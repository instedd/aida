defmodule Aida.FrontDesk do
  alias __MODULE__
  alias Aida.{Bot, Message, Skill, DB.SkillUsage, DB.Session, Unsubscribe}
  use Aida.ErrorLog

  @type t :: %__MODULE__{
    threshold: float,
    greeting: Bot.message,
    introduction: Bot.message,
    not_understood: Bot.message,
    clarification: Bot.message,
    unsubscribe: Unsubscribe.t
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
    %{message.session | is_new: false} |> Session.save

    message
      |> Message.respond(message.bot.front_desk.greeting)
      |> introduction()
  end

  @spec introduction(message :: Message.t) :: Message.t
  def introduction(message) do
    log_usage(message.bot.id, message.session.id)

    message
      |> Message.respond(message.bot.front_desk.introduction)
      |> skills_intro
      |> Message.respond(message.bot.front_desk.unsubscribe.introduction_message)
  end

  @spec skills_intro(message :: Message.t) :: Message.t
  defp skills_intro(message) do
    Bot.relevant_skills(message)
      |> Enum.reduce(message, fn(skill, message) ->
        ErrorLog.context(skill_id: Skill.id(skill)) do
          Skill.explain(skill, message)
        end
      end)
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
    message
      |> Message.respond(message.bot.front_desk.not_understood)
      |> introduction()
  end

  def handle_unsubscribe(message) do
    message = set_session_do_not_disturb(message)

    if is_unsubscribe_keyword(message) do
      Message.respond(message, message.bot.front_desk.unsubscribe.acknowledge_message)
    else
      message
    end
  end

  defp set_session_do_not_disturb(message) do
    %{
      message
      | session:
          Session.save(%{message.session | do_not_disturb: is_unsubscribe_keyword(message)})
    }
  end

  defp is_unsubscribe_keyword(message) do
    cond do
      Map.has_key?(message.bot.front_desk.unsubscribe, :keywords) &&
        message.bot.front_desk.unsubscribe.keywords[Message.language(message)] &&
          Enum.member?(
            message.bot.front_desk.unsubscribe.keywords[Message.language(message)],
            Message.text_content(message)
          ) ->
        true

      true ->
        false
    end
  end

  defp log_usage(bot_id, session_id) do
    SkillUsage.log_skill_usage(bot_id, "front_desk", session_id)
  end
end
