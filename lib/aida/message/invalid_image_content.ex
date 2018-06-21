defmodule Aida.Message.InvalidImageContent do
  alias __MODULE__

  @type t :: %__MODULE__{
          image_id: nil | pos_integer
        }

  defstruct image_id: nil

  defimpl Aida.Message.Content, for: __MODULE__ do
    alias Aida.Message.InvalidImageContent

    def type(_) do
      :image
    end

    def raw(%InvalidImageContent{image_id: image_id}) do
      "invalid_image:#{image_id}"
    end
  end
end
