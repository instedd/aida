defprotocol Aida.Channel do
  @spec start(channel :: Aida.Channel.t) :: :ok
  def start(channel)

  @spec stop(channel :: Aida.Channel.t) :: :ok
  def stop(channel)

  @spec callback(channel :: Aida.Channel.t, conn :: Plug.Conn.t) :: Plug.Conn.t
  def callback(channel, conn)

  @spec type(channel :: Aida.Channel.t) :: String.t
  def type(channel)

  # @spec send_message(channel :: Aida.Channel.t, messages :: ) :: String.t
  def send_message(channel, messages, recipient)
end

defmodule Aida.ChannelProvider do
  @callback init() :: :ok
  @callback new(bot_id :: String.t, config :: map) :: Aida.Channel.t
  @callback callback(conn :: Plug.Conn.t) :: Plug.Conn.t
end
