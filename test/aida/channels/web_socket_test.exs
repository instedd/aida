defmodule Aida.Channel.WebSocketTest do
  alias Aida.Channel.WebSocket
  alias Aida.{Channel, ChannelRegistry}
  alias Aida.DB.Session
  use Aida.DataCase

  @bot_id "986a4b66-b3a0-40d5-83b2-c535427dc0f9"

  setup do
    ChannelRegistry.start_link
    :ok
  end

  test "looking for non registered channel returns :not_found" do
    assert WebSocket.find_channel_for_bot(@bot_id) == :not_found
  end

  test "register/unregister channel when it starts/stops" do
    channel = %WebSocket{
      bot_id: @bot_id,
      access_token: "1234"
    }

    channel |> Channel.start
    assert WebSocket.find_channel_for_bot(@bot_id) == channel

    channel |> Channel.stop
    assert WebSocket.find_channel_for_bot(@bot_id) == :not_found
  end

  test "find channel by session id" do
    channel = %WebSocket{
      bot_id: @bot_id,
      access_token: "1234"
    }

    channel |> Channel.start
    session = Session.new({@bot_id, "ws", "4fd60b7f-785a-4dcb-8b1e-c2db4a431864"})

    assert channel == WebSocket.find_channel(session)
    assert channel == Aida.ChannelProvider.find_channel(session)
  end
end
