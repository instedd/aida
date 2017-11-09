defmodule Aida.Message do
  alias Aida.{Session, Message}
  @type t :: %__MODULE__{
    session: Session.t,
    content: String.t,
    reply: [String.t]
  }

  defstruct session: %Session{},
            content: "",
            reply: []

  @spec new(content :: String.t, session :: Session.t) :: t
  def new(content, session \\ Session.new) do
    %Message{
      session: session,
      content: content
    }
  end
end
