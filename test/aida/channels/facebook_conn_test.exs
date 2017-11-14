defmodule Aida.Channel.FacebookConnTest do
  use Aida.DataCase
  use Phoenix.ConnTest
  alias Aida.{ChannelRegistry, BotManager}
  alias Aida.Channel.Facebook

  setup do
    ChannelRegistry.start_link
    BotManager.start_link
    :ok
  end

  test "incoming facebook message" do
    challenge = Ecto.UUID.generate
    params = %{"hub.challenge" => challenge, "hub.mode" => "subscribe", "hub.verify_token" => "fb_verify_token", "provider" => "facebook"}
    conn = build_conn(:get, "/callback/facebook", params)
      |> Facebook.callback()
    
    assert response(conn, 200) == challenge
  end

  # describe "with bot" do
  #   setup do
      
  #     BotManager.start()
  #     :ok
  #   end
  # end
end