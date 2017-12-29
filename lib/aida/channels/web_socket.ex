defmodule Aida.Channel.WebSocket do
  alias Aida.Channel.WebSocket

  @behaviour Aida.ChannelProvider
  @type t :: %__MODULE__{
    bot_id: String.t
  }

  defstruct [:bot_id]

  def init do
    :ok
  end

  def new(bot_id, _config \\ nil) do
    %WebSocket{bot_id: bot_id}
  end

  def find_channel(session_id) do
    [bot_id, _provider, _uuid] = session_id |> String.split("/")
    new(bot_id)
  end

  def callback(_channel) do
    raise "not implemented"
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(_channel), do: :ok

    def stop(_channel) do
      # TODO Handle channel disconnects
      # We need to add this to the bot channels, and maybe the manifest
      :ok
    end

    def callback(_channel, _conn) do
      raise "not implemented"
    end

    def send_message(channel, messages, session_id) do
      recipient = session_id |> String.split("/") |> List.last

      messages |> Enum.each(fn message ->
        AidaWeb.Endpoint.broadcast("bot:#{channel.bot_id}", "btu_msg", %{text: message, session: recipient})
      end)
    end
  end
end
