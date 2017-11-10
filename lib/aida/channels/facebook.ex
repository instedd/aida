defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
  alias Aida.ChannelRegistry
  @behaviour Aida.ChannelProvider
  @type t :: %__MODULE__{
    bot_id: String.t,
    page_id: String.t,
    verify_token: String.t,
    access_token: String.t
  }

  defstruct [:bot_id, :page_id, :verify_token, :access_token]

  def init do
    :ok
  end

  def new(_bot_id, _config) do
    %Facebook{}
  end

  def find_channel_for_page_id(page_id) do
    ChannelRegistry.find({:facebook, page_id})
  end

  def callback(conn) do
    conn
  end

  defimpl Aida.Channel, for: __MODULE__ do
    def start(channel) do
      ChannelRegistry.register({:facebook, channel.page_id}, channel)
    end

    def stop(channel) do
      ChannelRegistry.unregister({:facebook, channel.page_id})
    end

    def callback(_channel, conn) do
      conn
    end
  end
end
