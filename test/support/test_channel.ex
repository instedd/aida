defmodule Aida.TestChannel do
  defstruct [:pid]

  def new() do
    %Aida.TestChannel{pid: self()}
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
  end
end
