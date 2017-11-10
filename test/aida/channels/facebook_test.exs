defmodule Aida.Channel.FacebookTest do
  alias Aida.Channel.Facebook
  alias Aida.{Channel, ChannelRegistry}
  use ExUnit.Case

  @bot_id "986a4b66-b3a0-40d5-83b2-c535427dc0f9"
  @page_id "1234567890"

  setup do
    Facebook.init
    ChannelRegistry.start_link
    :ok
  end

  test "looking for non registered channel returns :not_found" do
    assert Facebook.find_channel_for_page_id(@page_id) == :not_found
  end

  test "register/unregister channel when it starts/stops" do
    channel = %Facebook{
      bot_id: @bot_id,
      page_id: @page_id
    }

    channel |> Channel.start
    assert Facebook.find_channel_for_page_id(@page_id) == channel

    channel |> Channel.stop
    assert Facebook.find_channel_for_page_id(@page_id) == :not_found
  end
end
