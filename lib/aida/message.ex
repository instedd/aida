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

  def content(%{content: content}) do
    content
  end

  @spec respond(message :: t, response :: String.t | map) :: t
  def respond(message, %{} = response) do
    respond(message, response[language(message)])
  end
  def respond(message, response) do
    %{message | reply: message.reply ++ [response]}
  end

  @spec get_session(message :: t, key :: String.t) :: String.t | nil
  def get_session(%{session: session}, key) do
    Session.get(session, key)
  end

  @spec put_session(message :: t, key :: String.t, value :: String.t) :: t
  def put_session(%{session: session} = message, key, value) do
    %{message | session: Session.put(session, key, value)}
  end

  @spec new_session?(message :: t) :: boolean
  def new_session?(%{session: session}) do
    Session.is_new?(session)
  end

  @spec language(message :: t) :: String.t | nil
  def language(message) do
    get_session(message, "language")
  end

  def curated_message(message) do
    String.replace(Message.content(message), ~r/\p{P}/, "")
  end
end
