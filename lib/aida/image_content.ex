defmodule Aida.Message.ImageContent do
  # alias __MODULE__

  @type t :: %__MODULE__{
    source_url: String.t
  }

  defstruct source_url: ""

end
