defprotocol Aida.Skill do
  alias Aida.Message

  @spec explain(skill :: t, msg :: Message.t) :: Message.t
  def explain(skill, msg)

  @spec clarify(skill :: t, msg :: Message.t) :: Message.t
  def clarify(skill, msg)

  @spec can_handle?(skill :: t, msg :: Message.t) :: boolean
  def can_handle?(skill, msg)

  @spec respond(skill :: t, msg :: Message.t) :: Message.t
  def respond(skill, message)
end
