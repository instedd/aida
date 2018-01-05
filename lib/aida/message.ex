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
    new_reply = interpolate_vars(message.session, response)
    %{message | reply: message.reply ++ [new_reply]}
  end

  @spec get_session(message :: t, key :: String.t) :: Session.value
  def get_session(%{session: session}, key) do
    Session.get(session, key)
  end

  @spec put_session(message :: t, key :: String.t, value :: Session.value) :: t
  def put_session(%{session: session} = message, key, value) do
    %{message | session: Session.put(session, key, value)}
  end

  @spec new_session?(message :: t) :: boolean
  def new_session?(%{session: session}) do
    Session.is_new?(session)
  end

  @spec language(message :: t) :: Session.value
  def language(message) do
    get_session(message, "language")
  end

  def words(%{content: content}) do
    Regex.scan(~r/\w+/u, content |> String.downcase) |> Enum.map(&hd/1)
  end

  @spec interpolate_vars(session :: Session.t, text :: String.t) :: String.t
  defp interpolate_vars(session, text) do
    Regex.scan(~r/\$\{\s*([a-z_]*)\s*\}/, text, return: :index)
    |> List.foldr(text, fn (match, text) ->
      [{p_start, p_len}, {v_start, v_len}] = match
      var_name = text |> String.slice(v_start, v_len)
      var_value = session |> Session.lookup_var(var_name) |> to_string
      <<text_before :: binary - size(p_start), _ :: binary - size(p_len), text_after :: binary>> = text
      text_before <> var_value <> text_after
    end)
  end
end
