defmodule Aida.Message.SystemContent do
  @type t :: %__MODULE__{
          text: String.t()
        }

  defstruct text: ""

  def new(text) do
    %Aida.Message.SystemContent{text: String.trim(text)}
  end

  defimpl Aida.Message.Content, for: __MODULE__ do
    alias Aida.Message.SystemContent

    def type(_) do
      :system
    end

    def raw(%SystemContent{text: text}) do
      text
    end
  end
end

