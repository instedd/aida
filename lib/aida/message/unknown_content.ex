defmodule Aida.Message.UnknownContent do
  @type t :: %__MODULE__{}

  defstruct []

  defimpl Aida.Message.Content, for: __MODULE__ do
    def type(_) do
      :unknown
    end

    def raw(_) do
      "unknown"
    end
  end
end
