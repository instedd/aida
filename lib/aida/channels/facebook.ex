defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
  alias Aida.ChannelRegistry
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

  def callback(conn) do
    channel = %Facebook{
      page_id: 12345,
      access_token: "EAAVKXI1Fskc",
      verify_token: "juancete1234"
    }

    channel |> Aida.Channel.callback(conn)
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(channel) do
      ChannelRegistry.register({:facebook, channel.page_id}, channel)
    end

    def stop(channel) do
      ChannelRegistry.unregister({:facebook, channel.page_id})
    end

    def call(%{assigns: %{user: _}} = conn, _params), do: conn

    def callback(channel, %{method: "GET"} = conn) do
      # %{"hub.challenge" => "1636890638", "hub.mode" => "subscribe", "hub.verify_token" => "juancho1234", "provider" => "facebook"}
      #This method is used for the channel registration with Facebook.

      params = conn.params
      mode = params["hub.mode"]
      # verify_token = params["hub.verify_token"]
      # if verify_token != channel.verify_token do
      #   IO.inspect("-------------==================== unauthorized ====================-------------")
      #   conn
      #   # |> Plug.Conn.put_status(403)
      #   |> Plug.Conn.send_resp(403, "unauthorized")
      # else

      body = cond do
        mode == "subscribe" ->  params["hub.challenge"]
        true -> "error"
      end

      conn
      |> Plug.Conn.send_resp(200, body)
      # end
    end

    def callback(channel, %{method: "POST"} = conn) do

      params = conn.params
      mode = params["hub.mode"]

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
      |> Plug.Conn.send_resp(200, "llala")
    end

    def handle_message(channel, message) do
      # [%{"message" => %{"mid" => "mid.$cAANwxwfh-CJl01zCSFfohd535_Ev", "seq" => 4, "text" => "asd"},
      #   "recipient" => %{"id" => "890876714398174"},
      #   "sender" => %{"id" => "1904803459536621"},
      #   "timestamp" => 1510252968520}
      # ]
      text = message["message"]["text"]
      recipient_id = message["recipient"]["id"]
      sender_id = message["sender"]["id"]

      if text do
        send_message(channel, "Did you said #{text} ?", sender_id)
      end
    end

    def send_message(channel, message_text, recipient) do
      url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{channel.access_token}"
      headers = [{"Content-type", "application/json"}]
      json = %{"recipient": %{"id": recipient}, "message": %{"text": message_text}, "messaging_type": "RESPONSE"}

      result = HTTPoison.post url, Poison.encode!(json), headers
    end
  end
end
