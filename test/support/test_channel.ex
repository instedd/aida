defmodule Aida.TestChannel do
  defstruct [:pid]

  def new(pid \\ self()) do
    %Aida.TestChannel{pid: pid}
  end

  def find_channel(session) do
    pid = session.provider_key
    new(pid |> String.to_atom())
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(channel) do
      send(channel.pid, {:start, channel})
      :ok
    end

    def stop(channel) do
      send(channel.pid, {:stop, channel})
      :ok
    end

    def callback(_channel, conn) do
      conn
    end

    def send_message(channel, messages, session) do
      send(channel.pid, {:send_message, messages, session.id})
    end
  end
end
