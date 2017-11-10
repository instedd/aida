defmodule Aida.Channel.Facebook do
  alias Aida.Channel.Facebook
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
