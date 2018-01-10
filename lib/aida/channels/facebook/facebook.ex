defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
  alias Aida.ChannelRegistry
  alias Aida.BotManager
  alias Aida.Bot
  alias Aida.Message
  alias Aida.Session
  alias Aida.DB.{MessagesPerDay, MessageLog}

  @behaviour Aida.ChannelProvider
  @type t :: %__MODULE__{
    bot_id: String.t,
    page_id: String.t,
    verify_token: String.t,
    access_token: String.t
  }

  defstruct [:bot_id, :page_id, :verify_token, :access_token]

  def init do
    :ok
  end

  def new(_bot_id, _config) do
    %Facebook{}
  end

  @spec find_channel_for_page_id(page_id :: String.t) :: t | :not_found
  def find_channel_for_page_id(page_id) do
    ChannelRegistry.find({:facebook, page_id})
  end

  def find_channel(session_id) do
    [_bot_id, _provider, page_id, _user_id] = session_id |> String.split("/")
    find_channel_for_page_id(page_id)
  end

  def callback(%{method: "GET"} = conn) do
    params = conn.params
    mode = params["hub.mode"]

    body = cond do
      mode == "subscribe" ->  params["hub.challenge"]
      true -> "error"
    end

    conn
    |> Plug.Conn.send_resp(200, body)
  end

  def callback(conn) do
    try do
      page_id = get_page_id_from_params(conn.params)
      case find_channel_for_page_id(page_id) do
        :not_found -> conn |> Plug.Conn.send_resp(200, "ok")
        channel -> channel |> Aida.Channel.callback(conn)
      end
    rescue
      error ->
        Sentry.capture_exception(error, [stacktrace: System.stacktrace(), extra: %{params: conn.params}])
        conn |> Plug.Conn.send_resp(200, "ok")
    end
  end

  def get_page_id_from_params(params) do
    if params["entry"] do
      Enum.at(params["entry"], 0)["id"]
    else
      0
    end
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(channel) do
      ChannelRegistry.register({:facebook, channel.page_id}, channel)
    end

    def stop(channel) do
      ChannelRegistry.unregister({:facebook, channel.page_id})
    end

    def call(%{assigns: %{user: _}} = conn, _params), do: conn

    def callback(channel, %{method: "POST"} = conn) do
      params = conn.params

      if params["object"] == "page" && params["entry"] do
        params["entry"]
          |> Enum.each(fn entry ->
            entry["messaging"]
              |> Enum.each(fn message ->
                handle_message(channel, message)
              end)
          end)
      end

      conn
      |> Plug.Conn.send_resp(200, "ok")
    end

    def callback(_channel, conn) do
      conn
      |> Plug.Conn.send_resp(200, "ok")
    end

    def handle_message(channel, message) do
      sender_id = message["sender"]["id"]

      try do
        text = message["message"]["text"]
        recipient_id = message["recipient"]["id"]
        session_id = "#{channel.bot_id}/facebook/#{recipient_id}/#{sender_id}"

        case text do
          "##RESET" ->
            Session.delete(session_id)
            send_message(channel, ["Session was reset"], session_id)

          nil -> :ok

          _ ->
            MessagesPerDay.log_received_message(channel.bot_id)

            bot = BotManager.find(channel.bot_id)
            session = Session.load(session_id)
              |> pull_profile(channel, sender_id)

            MessageLog.create(channel.bot_id, session_id, text, "incoming")
            reply = Bot.chat(bot, Message.new(text, bot, session))
            reply.session |> Session.save

            send_message(channel, reply.reply, session_id)
        end
      rescue
        error ->
          Sentry.capture_exception(error, [stacktrace: System.stacktrace(), extra: %{bot_id: channel.bot_id, message: message}])
          send_message(channel, ["Oops! Something went wrong"], sender_id)
      end
    end

    defp pull_profile(session, channel, sender_id) do
      must_pull = session |> Session.get("facebook_profile_ts") |> must_pull_profile?

      if must_pull do
        api = FacebookApi.new(channel.access_token)

        profile = api |> FacebookApi.get_profile(sender_id)
        session
          |> Session.put("first_name", profile["first_name"])
          |> Session.put("last_name", profile["last_name"])
          |> Session.put("gender", profile["gender"])
          |> Session.put("facebook_profile_ts", DateTime.utc_now |> DateTime.to_iso8601)
      else
        session
      end
    end

    defp must_pull_profile?(nil), do: true
    defp must_pull_profile?(ts) do
      {:ok, ts, _} = DateTime.from_iso8601(ts)
      DateTime.diff(DateTime.utc_now, ts, :second) > 86400
    end

    def send_message(channel, messages, session_id) do
      recipient = session_id |> String.split("/") |> List.last
      api = FacebookApi.new(channel.access_token)

      Enum.each(messages, fn message ->
        MessageLog.create(channel.bot_id, session_id, message, "outgoing")
        MessagesPerDay.log_sent_message(channel.bot_id)
        api |> FacebookApi.send_message(recipient, message)
      end)
    end
  end
end
