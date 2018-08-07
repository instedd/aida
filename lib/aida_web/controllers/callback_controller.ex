defmodule AidaWeb.CallbackController do
  use AidaWeb, :controller

  def callback(conn, %{"provider" => "facebook", "bot_id" => bot_id}) do
    Aida.Channel.Facebook.callback(conn, bot_id)
  end

  def callback(conn, %{"provider" => "facebook"}) do
    Aida.Channel.Facebook.callback(conn)
  end
end
