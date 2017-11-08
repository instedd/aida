defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
  @behaviour Aida.ChannelProvider
  @type t :: %__MODULE__{
  }

  defstruct []

  def init do
    :ok
  end

  def new(_bot_id, _config) do
    %Facebook{}
  end

  def callback(conn) do
    conn
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(_channel) do
      :ok
    end

    def stop(_channel) do
      :ok
    end

    def callback(_channel, conn) do
      conn
    end
  end
end
