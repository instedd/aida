defmodule Aida.TestChannel do
  defstruct [:pid, :send_message_assertion]

  def new(send_message_assertion \\ fn(_,_) -> :ok end) do
    %Aida.TestChannel{pid: self(), send_message_assertion: send_message_assertion}
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(channel) do
      send channel.pid, {:start, channel}
      :ok
    end

    def stop(channel) do
      send channel.pid, {:stop, channel}
      :ok
    end

    def callback(_channel, conn) do
      conn
    end

    def type(_) do
      "test"
    end

    def send_message(%{send_message_assertion: send_message_assertion}, messages, recipient) do
      send_message_assertion.(messages, recipient)
    end
  end
end
