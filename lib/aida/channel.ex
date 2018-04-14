defprotocol Aida.Channel do
  @spec start(channel :: Aida.Channel.t) :: :ok
  def start(channel)

  @spec stop(channel :: Aida.Channel.t) :: :ok
  def stop(channel)

  @spec callback(channel :: Aida.Channel.t, conn :: Plug.Conn.t) :: Plug.Conn.t
  def callback(channel, conn)

  @spec send_message(channel :: Aida.Channel.t, messages :: [String.t], session :: Aida.DB.Session.t) :: :ok
  def send_message(channel, messages, session_id)
end

defmodule Aida.ChannelProvider do
  alias Aida.Channel.{Facebook, WebSocket}

  @callback init() :: :ok
  @callback new(bot_id :: String.t, config :: map) :: Aida.Channel.t
  @callback callback(conn :: Plug.Conn.t) :: Plug.Conn.t
  @callback find_channel(session :: Aida.DB.Session.t) :: Aida.Channel.t

  def find_channel(session) do
    provider = case session.provider do
      "facebook" -> Facebook
      "ws" -> WebSocket
      "test" -> Aida.TestChannel
    end

    provider.find_channel(session)
  end
end
