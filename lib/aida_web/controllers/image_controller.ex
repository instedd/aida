defmodule AidaWeb.ImageController do
  use AidaWeb, :controller

  alias Aida.DB

  def image(conn, %{"uuid" => uuid}) do
    case DB.get_image(uuid) do
      nil ->
        conn |> send_resp(:not_found, "")

      image ->
        conn
        |> put_resp_content_type(image.binary_type, "utf-8")
        |> send_resp(200, image.binary)
    end
  end
end
