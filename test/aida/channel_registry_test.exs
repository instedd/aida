defmodule Aida.ChannelRegistryTest do
  alias Aida.{ChannelRegistry, TestChannel}
  use ExUnit.Case

  setup do
    ChannelRegistry.start_link
    :ok
  end

  test "find non existing channel returns :not_found" do
    assert ChannelRegistry.find({:test, 123}) == :not_found
  end

  test "register and unregister channel" do
    channel = TestChannel.new

    assert ChannelRegistry.register({:test, 123}, channel) == :ok
    assert ChannelRegistry.find({:test, 123}) == channel

    assert ChannelRegistry.unregister({:test, 123}) == :ok
    assert ChannelRegistry.find({:test, 123}) == :not_found
  end
end
