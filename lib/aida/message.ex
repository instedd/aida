defmodule Aida.Message do
  alias Aida.{Message, Bot}
  alias Aida.DB.{Session}
  alias Aida.Message.{TextContent, ImageContent, UnknownContent, Content, SystemContent, InvalidImageContent}
  use Aida.ErrorLog

  @type t :: %__MODULE__{
    session: Session.t,
    bot: Bot.t,
    content: TextContent.t | ImageContent.t | UnknownContent.t | SystemContent.t,
    sensitive: boolean,
    reply: [String.t]
  }

  defstruct session: %Session{},
            bot: %Bot{},
            content: %TextContent{},
            sensitive: false,
            reply: []

  @spec new(content :: String.t, bot :: Bot.t, session :: Session.t) :: t
  def new(content, %Bot{} = bot, session) do
    %Message{
      session: session,
      bot: bot,
      content: TextContent.new(content)
    }
  end

  @spec new_from_image(image :: %{uuid: String.t}, bot :: Bot.t, session :: Session.t) :: t
  def new_from_image(%{uuid: image_uuid}, %Bot{} = bot, session) do
    %Message{
      session: session,
      bot: bot,
      content: %ImageContent{image_id: image_uuid}
    }
  end

  @spec new_from_image(source_url :: String.t, bot :: Bot.t, session :: Session.t) :: t
  def new_from_image(source_url, %Bot{} = bot, session) do
    %Message{
      session: session,
      bot: bot,
      content: %ImageContent{source_url: source_url}
    }
  end

  def invalid_image(%{uuid: image_uuid}, %Bot{} = bot, session) do
    %Message{
      session: session,
      bot: bot,
      content: %InvalidImageContent{image_id: image_uuid}
    }
  end

  @spec new_unknown(bot :: Bot.t, session :: Session.t) :: t
  def new_unknown(%Bot{} = bot, session) do
    %Message{
      session: session,
      bot: bot,
      content: %UnknownContent{}
    }
  end

  # @spec new_system(text :: String.t, bot :: Bot.t, session :: Session.t) :: t
  def new_system(text, %Bot{} = bot, session) do
    %Message{
      session: session,
      bot: bot,
      content: SystemContent.new(text)
    }
  end

  def text_content(%{content: %TextContent{text: text}}) do
    text
  end

  def text_content(_) do
    ""
  end

  def image_content(%{content: %ImageContent{} = content}) do
    content
  end

  def image_content(_) do
    nil
  end

  def image_id(%{content: %ImageContent{source_url: _, image_id: nil}}) do
    :not_available
  end

  def image_id(%{content: %ImageContent{source_url: _, image_id: image_id}}) do
    image_id
  end

  def image_id(_) do
    :not_image_content
  end

  def pull_and_store_image(%{content: %ImageContent{source_url: _, image_id: nil} = content} = message) do
    %{message | content: ImageContent.pull_and_store_image(content, message.bot.id, message.session.id)}
  end

  def pull_and_store_image(%{content: %ImageContent{source_url: _, image_id: _}} = message) do
    message
  end

  @spec respond(message :: t, response :: String.t | map) :: t
  def respond(message, %{} = response) do
    respond(message, response[language(message)])
  end
  def respond(message, response) do
    response = interpolate_expressions(message, response)
    response = interpolate_vars(message, response)
    add_reply(message, response)
  end

  defp add_reply(message, "") do
    message
  end

  defp add_reply(message, response) do
    %{message | reply: message.reply ++ [response]}
  end

  @spec get_session(message :: t, key :: String.t) :: Session.value
  def get_session(%{session: session}, key) do
    Session.get_value(session, key)
  end

  @spec put_session(message :: t, key :: String.t, value :: Session.value) :: t
  def put_session(%{session: session, bot: bot} = message, key, value, options \\ []) do
    encrypted = Keyword.get(options, :encrypted, false)
    value =
      if encrypted do
        Bot.encrypt(bot, value |> Poison.encode!)
      else
        value
      end

    %{message | session: Session.put(session, key, value)}
  end

  @spec new_session?(message :: t) :: boolean
  def new_session?(%{session: session}) do
    session.is_new
  end

  def clear_state(%{bot: bot} = message) do
    Bot.clear_state(bot, message)
  end

  @spec language(message :: t) :: Session.value
  def language(message) do
    get_session(message, "language")
  end

  def words(%{content: %TextContent{text: text}}) do
    Regex.scan(~r/\w+/u, text |> String.downcase) |> Enum.map(&hd/1)
  end

  def words(_), do: []

  def lookup_var(message, key) do
    case message.bot |> Bot.lookup_var(message, key) do
      nil ->
        message.session |> Session.lookup_var(key)
      var ->
        var[language(message)]
    end
  end

  defp display_var(value) when is_list(value) do
    value |> Enum.join(", ")
  end

  defp display_var(:not_found) do
    ""
  end

  defp display_var(value) do
    value |> to_string
  end

  @spec interpolate_vars(message :: t, text :: String.t) :: String.t
  defp interpolate_vars(message, text, resolved_vars \\ []) do
    Regex.scan(~r/\$\{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*\}/, text, return: :index)
    |> List.foldr(text, fn (match, text) ->
      [{p_start, p_len}, {v_start, v_len}] = match
      var_name = text |> Kernel.binary_part(v_start, v_len)
      var_value =
        if var_name in resolved_vars do
          "..."
        else
          case lookup_var(message, var_name) do
            :not_found ->
              ErrorLog.write("Variable '#{var_name}' was not found")
              ""

            value ->
              display_var(value)
           end
        end
      <<text_before :: binary-size(p_start), _ :: binary-size(p_len), text_after :: binary>> = text
      text_before <> interpolate_vars(message, var_value, [var_name | resolved_vars]) <> text_after
    end)
  end

  @spec interpolate_expressions(message :: t, text :: String.t) :: String.t
  def interpolate_expressions(message, text) do
    Regex.scan(~r/\{\{(.*)\}\}/U, text, return: :index)
    |> List.foldr(text, fn (match, text) ->
      [{p_start, p_len}, {v_start, v_len}] = match
      expr = text |> Kernel.binary_part(v_start, v_len)
      expr_result =
        try do
          Aida.Expr.parse(expr)
          |> Aida.Expr.eval(message |> expr_context(lookup_raises: true))
          |> display_var
        rescue
          error ->
            ErrorLog.write(Exception.message(error))
            "[ERROR: #{Exception.message(error)}]"
        end

      <<text_before :: binary-size(p_start), _ :: binary-size(p_len), text_after :: binary>> = text
      text_before <> expr_result <> text_after
    end)
  end

  def expr_context(message, options \\ []) do
    lookup_raises = options[:lookup_raises]

    var_lookup = fn name ->
      vars = Process.get("lookup_variables", [])

      if Enum.member?(vars, name) do
        raise Aida.Expr.RecursiveVariableDefinitionError.exception(name)
      else
        Process.put("lookup_variables", [name | vars])
      end

      try do
        case Message.lookup_var(message, name) do
          :not_found ->
            if lookup_raises do
              raise Aida.Expr.UnknownVariableError.exception(name)
            else
              nil
            end
          value ->
            value
        end
      after
        Process.put("lookup_variables", vars)
      end
    end

    context = options
      |> Keyword.merge([var_lookup: var_lookup])
      |> Aida.Expr.Context.new

    Bot.expr_context(message.bot, context, options)
  end

  def type(%Message{content: content}) do
    content |> Content.type()
  end

  def raw(%Message{content: content}) do
    content |> Content.raw()
  end

  def mark_sensitive(message) do
    %{message | sensitive: true}
  end
end
