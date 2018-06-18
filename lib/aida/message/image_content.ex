defmodule Aida.Message.ImageContent do
  alias __MODULE__
  alias Aida.DB

  @type t :: %__MODULE__{
          source_url: String.t(),
          image_id: nil | pos_integer
        }

  defstruct source_url: "", image_id: nil

  @spec pull_and_store_image(content :: t, bot_id :: String.t(), session_id :: String.t()) :: t
  def pull_and_store_image(
        %ImageContent{source_url: source_url, image_id: nil} = content,
        bot_id,
        session_id
      ) do
    if source_url != "" do
      %HTTPoison.Response{body: body, headers: headers} = HTTPoison.get!(source_url)

      binary_type =
        case headers |> Enum.filter(&(&1 |> elem(0) == "Content-Type")) |> hd do
          {"Content-Type", content_type} -> content_type
          _ -> "image/jpeg"
        end

      {:ok, db_image} =
        DB.create_image(%{
          binary: body,
          binary_type: binary_type,
          source_url: source_url,
          bot_id: bot_id,
          session_id: session_id
        })

      %ImageContent{source_url: source_url, image_id: db_image.uuid}
    else
      content
    end
  end

  def pull_and_store_image(%ImageContent{} = content, _, _) do
    content
  end

  defimpl Aida.Message.Content, for: __MODULE__ do
    alias Aida.Message.ImageContent

    def type(_) do
      :image
    end

    def raw(%ImageContent{image_id: image_id, source_url: ""}) do
      "image:#{image_id}"
    end

    def raw(%ImageContent{source_url: source_url}) do
      source_url
    end
  end
end
