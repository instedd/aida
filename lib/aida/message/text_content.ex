defmodule Aida.Message.TextContent do
  @type t :: %__MODULE__{
          text: String.t()
        }

  defstruct text: ""

  defimpl Aida.Message.Content, for: __MODULE__ do
    alias Aida.Message.TextContent

    def type(_) do
      :text
    end

    def raw(%TextContent{text: text}) do
      text
    end
  end
end
