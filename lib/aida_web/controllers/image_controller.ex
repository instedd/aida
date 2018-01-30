defmodule AidaWeb.ImageController do
  use AidaWeb, :controller

  alias Aida.DB
  alias Aida.DB.Image
  action_fallback AidaWeb.FallbackController

  def image(conn, %{"uuid" => uuid}) do
    image = DB.get_image(uuid)

    with %Image{} <- DB.get_image(uuid) do
      conn
        |> put_resp_content_type(image.binary_type, "utf-8")
        |> send_resp(200, image.binary)
    end
  end

end
