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

  @spec wake_up(skill :: t, bot :: Aida.Bot.t, data :: nil | String.t) :: :ok
  def wake_up(skill, bot, data)

  @spec relevant(skill :: t) :: Aida.Expr.t | nil
  def relevant(skill)

  @spec is_relevant?(skill :: t, message :: Message.t) :: boolean
  defdelegate is_relevant?(skill, message), to: Aida.Skill.Utils, as: :is_skill_relevant?

  @spec uses_encryption?(skill :: t) :: boolean
  def uses_encryption?(skill)
end

defmodule Aida.Skill.Utils do
  alias Aida.{Skill, DB.SkillUsage, Message}

  def respond(skill, message) do
    SkillUsage.log_skill_usage(message.bot.id, Skill.id(skill), message.session.id)
    Skill.put_response(skill, message)
  end

  def is_skill_relevant?(skill, message) do
    case skill |> Skill.relevant do
      nil -> true
      expr ->
        try do
          Aida.Expr.eval(expr, message |> Message.expr_context(lookup_raises: true))
        rescue
          Aida.Expr.UnknownVariableError -> false
        end
    end
  end

  def confidence_for_keywords(keywords, message) do
    words_in_message = Message.words(message)

    matches = words_in_message
    |> Enum.filter(fn(word) ->
      Enum.member?(keywords[Message.language(message)], word)
    end)

    word_count = Enum.count(words_in_message)
    case word_count do
      0 -> 0
      _ ->Enum.count(matches)/word_count
    end
  end
end
