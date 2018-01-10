defprotocol Aida.Channel do
  @spec start(channel :: Aida.Channel.t) :: :ok
  def start(channel)

  @spec stop(channel :: Aida.Channel.t) :: :ok
  def stop(channel)

  @spec callback(channel :: Aida.Channel.t, conn :: Plug.Conn.t) :: Plug.Conn.t
  def callback(channel, conn)

  # @spec send_message(channel :: Aida.Channel.t, messages :: ) :: String.t
  def send_message(channel, messages, session_id)
end

defmodule Aida.ChannelProvider do
  alias Aida.Channel.{Facebook, WebSocket}

  @callback init() :: :ok
  @callback new(bot_id :: String.t, config :: map) :: Aida.Channel.t
  @callback callback(conn :: Plug.Conn.t) :: Plug.Conn.t
  @callback find_channel(session_id :: String.t) :: Aida.Channel.t


  def find_channel(session_id) do
    [_bot_id, provider | _] = session_id |> String.split("/")
    provider = case provider do
      "facebook" -> Facebook
      "ws" -> WebSocket
    end

    provider.find_channel(session_id)
  end
end
