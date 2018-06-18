defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
  alias Aida.ChannelRegistry
  alias Aida.BotManager
  alias Aida.Bot
  alias Aida.Message
  alias Aida.DB.Session
  import Aida.ErrorHandler
  require Logger

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

  def find_channel(session) do
    [page_id, _user_id] = session.provider_key |> String.split("/")
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
        capture_exception("Error processing Facebook callback", error, params: conn.params)
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
        sender_id = Session.encrypt_id(sender_id, channel.bot_id)
        recipient_id = message["recipient"]["id"]

        session = Session.find_or_create(channel.bot_id, "facebook", "#{recipient_id}/#{sender_id}")

        case message["message"]["text"] do
          nil ->
            attachment = if message["message"]["attachments"] do
              Enum.at(message["message"]["attachments"], 0)
            else
              %{}
            end

            case attachment["type"] do
              "image" ->
                source_url =
                  if (attachment["payload"] && attachment["payload"]["url"]) do
                    attachment["payload"]["url"]
                  else
                    ""
                  end
                try do
                  handle_by_message_type(channel, session, sender_id, :image, source_url)
                rescue
                  error ->
                    capture_exception("Error obtaining Facebook image", error, bot_id: channel.bot_id, image: source_url)
                    :ok
                end
              nil -> :ok
              _ ->
                handle_by_message_type(channel, session, sender_id, :unknown, "")
            end

          text ->
            if String.slice(text, 0..1) == "##" do
              handle_by_message_type(channel, session, sender_id, :system, text)
            else
              handle_by_message_type(channel, session, sender_id, :text, text)
            end
        end
      rescue
        error ->
          capture_exception("Error processing Facebook message", error, bot_id: channel.bot_id, message: message)
          send_message(channel, ["Oops! Something went wrong"], %{provider_key: sender_id})
      end
    end

    @spec handle_by_message_type(Aida.Channel.t, Session.t, String.t, :text | :image | :unknown | :system, String.t) :: :ok
    defp handle_by_message_type(channel, session, sender_id, message_type, message_string) do
      bot = BotManager.find(channel.bot_id)

      message =
        case message_type do
          :text -> Message.new(message_string, bot, session)
          :image -> Message.new_from_image(message_string, bot, session)
          :system -> Message.new_system(message_string, bot, session)
          :unknown -> Message.new_unknown(bot, session)
        end
        |> pull_profile(channel, sender_id)

      reply = Bot.chat(message)
      reply.session |> Session.save

      send_message(channel, reply.reply, session)
    end

    @spec pull_profile(Message.t(), Aida.Channel.t(), String.t()) :: Message.t()
    defp pull_profile(
           %{bot: %{id: bot_id, public_keys: public_keys}} = message,
           channel,
           sender_id
         ) do
      if must_pull_profile?(message) do
        encrypted = Enum.count(public_keys) > 0

        profile =
          channel.access_token |> FacebookApi.new()
          |> FacebookApi.get_profile(Session.decrypt_id(sender_id, bot_id))

        message
        |> Message.put_session("first_name", profile["first_name"])
        |> Message.put_session("last_name", profile["last_name"], encrypted: encrypted)
        |> Message.put_session("gender", profile["gender"])
        |> Message.put_session(".facebook_profile_ts", DateTime.utc_now() |> DateTime.to_iso8601())
      else
        message
      end
    end

    defp must_pull_profile?(%Message{} = message) do
      message |> Message.get_session(".facebook_profile_ts") |> must_pull_profile?
    end

    defp must_pull_profile?(nil), do: true

    defp must_pull_profile?(ts) do
      {:ok, ts, _} = DateTime.from_iso8601(ts)
      DateTime.diff(DateTime.utc_now(), ts, :second) > 86400
    end

    def send_message(channel, messages, session) do
      recipient = session.provider_key
        |> String.split("/")
        |> List.last
        |> Session.decrypt_id(channel.bot_id)
      api = FacebookApi.new(channel.access_token)

      Enum.each(messages, fn message ->
        api |> FacebookApi.send_message(recipient, message)
      end)
    end
  end
end
