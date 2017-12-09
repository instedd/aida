defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
  alias Aida.ChannelRegistry
  alias Aida.BotManager
  alias Aida.Bot
  alias Aida.Message
  alias Aida.Session

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
    page_id = get_page_id_from_params(conn.params)

    channel = find_channel_for_page_id(page_id)

    cond do
      channel == :not_found -> conn |> Plug.Conn.send_resp(200, "ok")
      true -> channel |> Aida.Channel.callback(conn)
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

      body = cond do
        true -> "ok"
      end

      conn
      |> Plug.Conn.send_resp(200, body)
    end

    def callback(_channel, conn) do
      conn
      |> Plug.Conn.send_resp(200, "ok")
    end

    def type(_) do
      "facebook"
    end

    def handle_message(channel, message) do
      text = message["message"]["text"]
      recipient_id = message["recipient"]["id"]
      sender_id = message["sender"]["id"]
      session_id = "#{type(channel)}/#{recipient_id}/#{sender_id}"

      case text do
        "##RESET" ->
          Session.delete(session_id)
          send_message(channel, ["Session was reset"], sender_id)

        nil -> :ok

        _ ->
          bot = BotManager.find(channel.bot_id)
          session = Session.load(session_id)
          reply = Bot.chat(bot, Message.new(text, session))
          reply.session |> Session.save

          send_message(channel, reply.reply, sender_id)
      end
    end

    def send_message(channel, messages, recipient) do
      url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{channel.access_token}"
      headers = [{"Content-type", "application/json"}]

      Enum.each(messages, fn message ->
        json = %{"recipient": %{"id": recipient}, "message": %{"text": message}, "messaging_type": "RESPONSE"}
        HTTPoison.post url, Poison.encode!(json), headers
      end)

    end
  end
end
