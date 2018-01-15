defmodule Aida.Message.ImageContent do
  alias __MODULE__
  alias Aida.DB

  @type t :: %__MODULE__{
    source_url: String.t,
    image_id: nil | pos_integer
  }

  defstruct source_url: "", image_id: nil

  @spec pull_and_store_image(content :: t, bot_id :: String.t, session_id :: String.t) :: t
  def pull_and_store_image(%ImageContent{source_url: source_url, image_id: nil} = content, bot_id, session_id) do
    if source_url != "" do
      %HTTPoison.Response{body: body} = HTTPoison.get!(source_url)

      {:ok, db_image} = DB.create_image(%{binary: body, binary_type: "image/jpeg", source_url: source_url, bot_id: bot_id, session_id: session_id })
      %ImageContent{source_url: source_url, image_id: db_image.uuid}
    else
      content
    end
  end

  def pull_and_store_image(%ImageContent{} = content, _, _) do
    content
  end

end
