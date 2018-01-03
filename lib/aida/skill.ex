defprotocol Aida.Skill do
  alias Aida.Message

  @spec explain(skill :: t, msg :: Message.t) :: Message.t
  def explain(skill, msg)

  @spec clarify(skill :: t, msg :: Message.t) :: Message.t
  def clarify(skill, msg)

  @spec confidence(skill :: t, msg :: Message.t) :: non_neg_integer | :threshold
  def confidence(skill, msg)

  @spec put_response(skill :: t, msg :: Message.t) :: Message.t
  def put_response(skill, message)

  @spec id(skill :: t) :: String.t
  def id(skill)

  @spec respond(skill :: t, msg :: Message.t) :: Message.t
  defdelegate respond(skill, message), to: Aida.Skill.Utils

  @spec init(skill :: t, bot :: Aida.Bot.t) :: t
  def init(skill, bot)

  @spec wake_up(skill :: t, bot :: Aida.Bot.t) :: :ok
  def wake_up(skill, bot)

  @spec relevant(skill :: t) :: Aida.Expr.t | nil
  def relevant(skill)

  @spec is_relevant?(skill :: t, session :: Aida.Session.t) :: boolean
  defdelegate is_relevant?(skill, session), to: Aida.Skill.Utils, as: :is_skill_relevant?
end

defmodule Aida.Skill.Utils do
  alias Aida.{Skill, DB.SkillUsage, Session}

  def respond(skill, message) do
    SkillUsage.log_skill_usage(skill.bot_id, Skill.id(skill), message.session.id)
    Skill.put_response(skill, message)
  end

  def is_skill_relevant?(skill, session) do
    case skill |> Skill.relevant do
      nil -> true
      expr ->
        try do
          Aida.Expr.eval(expr, session |> Session.expr_context(lookup_raises: true))
        rescue
          Aida.Expr.UnknownVariable -> false
        end
    end
  end
end
