defprotocol Aida.Skill do
  alias Aida.Message

  @spec explain(skill :: t, msg :: Message.t) :: Message.t
  def explain(skill, msg)

  @spec clarify(skill :: t, msg :: Message.t) :: Message.t
  def clarify(skill, msg)

  @spec confidence(skill :: t, msg :: Message.t) :: non_neg_integer
  def confidence(skill, msg)

  @spec put_response(skill :: t, msg :: Message.t) :: Message.t
  def put_response(skill, message)

  @spec id(skill :: t) :: String.t
  def id(skill)

  @spec respond(skill :: t, msg :: Message.t) :: Message.t
  defdelegate respond(skill, message), to: Aida.Utils

end

defmodule Aida.Utils do
  alias Aida.DB.SkillUsage
  def respond(skill, message) do
    SkillUsage.log_skill_usage(skill, message)
    Aida.Skill.put_response(skill, message)
  end
end
