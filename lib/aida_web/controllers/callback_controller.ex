defmodule AidaWeb.CallbackController do
  use AidaWeb, :controller

  def callback(conn, %{"provider" => "facebook"}) do
    Aida.Channel.Facebook.callback(conn)
  end
end
