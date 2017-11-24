defprotocol Aida.Skill do
  alias Aida.Message

  @spec explain(skill :: t, msg :: Message.t) :: Message.t
  def explain(skill, msg)

  @spec clarify(skill :: t, msg :: Message.t) :: Message.t
  def clarify(skill, msg)

  @spec confidence(skill :: t, msg :: Message.t) :: non_neg_integer
  def confidence(skill, msg)

  @spec respond(skill :: t, msg :: Message.t) :: Message.t
  def respond(skill, message)

  @spec id(skill :: t) :: String.t
  def id(skill)

end
